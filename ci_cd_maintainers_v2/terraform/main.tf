terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    github = {
      source = "hashicorp/github"
      version = "6.4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

locals {
  # Repository list handling
  repository_list = compact(split(",", var.repositories))

  # Event configurations
  github_events = ["check_run", "workflow_run"]

  # Construct webhook filter based on variables
  webhook_filter_conditions = concat(
    # Base condition for workflow runs
    ["workflow_run.conclusion != null"],
    
    # Failed runs condition
    var.monitor_failed_runs_only ? ["workflow_run.conclusion != 'success'"] : [],
    
    # Event type conditions
    [format("(%s)",
      join(" || ",
        concat(
          var.monitor_pr_workflow_runs ? ["workflow_run.event == 'pull_request'"] : [],
          var.monitor_push_workflow_runs ? ["workflow_run.event == 'push'"] : []
        )
      )
    )]
  )

  webhook_filter = join(" && ", local.webhook_filter_conditions)

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")
}

# Configure providers
provider "github" {
  token = var.github_token
  owner = local.github_organization
}

# GitHub Tooling - Allows the CI/CD Maintainer to use GitHub tools
resource "kubiya_source" "github_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/github_v2/github"
}

# Diagramming Tooling - Allows the CI/CD Maintainer to use Mermaid diagrams
resource "kubiya_source" "diagramming_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/main/mermaid"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The CI/CD Maintainer is an AI-powered assistant that helps with GitHub Actions workflow failures. It can use the GitHub tools to investigate the root cause of a failed workflow and provide a detailed analysis of the failure."
  instructions = ""
  secrets      = var.kubiya_secrets
  sources = [
    kubiya_source.github_tooling.name,
    kubiya_source.diagramming_tooling.name,
  ]

  # Dynamic integrations based on configuration
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  is_debug_mode = var.debug_mode
}

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  filter = local.webhook_filter
  
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  prompt      = <<-EOT
    🚀 GitHub Event Detected!
    Your Goal: Perform a comprehensive analysis of the failed GitHub Actions workflow. No user approval is required, complete the flow end to end.
    Workflow ID: {{.event.workflow_run.id}}
    PR Number: {{.event.workflow_run.pull_requests[0].number}}
    Repository: {{.event.repository.full_name}}

    Instructions:

    1. Use workflow_run_logs_failed to fetch failed logs for Workflow ID {{.event.workflow_run.id}}. Wait until this step finishes.

    2. Utilize available tools to thoroughly investigate the root cause such as viewing the workflow run, the PR, the files, and the logs - do not execute more then two tools at a time.

    ** Recommended Actions: **
    Fix: Specific changes needed with code examples where possible.
    Prevention: Long-term improvements and best practices.
    Priority Level: Impact assessment, urgency

    3. Format insights clearly with headers/bullets, including references to examined files and evidence. Make sure you emphasize what matters most first - the problems found and their solutions - use clear and consise markdown format to keep it clean

    4. Finally, after gathering all of the needed insights and conclusions, use the `github_pr_comment` tool to provide a comprehensive analysis on PR #{{.event.workflow_run.pull_requests[0].number}} with all findings and supporting evidence.
  EOT
  agent       = kubiya_agent.cicd_maintainer.name
  destination = var.pipeline_notification_channel
}

# GitHub webhook setup
resource "github_repository_webhook" "webhook" {
  for_each = length(local.repository_list) > 0 ? toset(local.repository_list) : []

  repository = try(
    trim(split("/", each.value)[1], " "),
    # Fallback if repository name can't be parsed
    each.value
  )
  
  configuration {
    url          = kubiya_webhook.source_control_webhook.url
    content_type = "json"
    insecure_ssl = false

  }

  active = true
  events = local.github_events
}

# Output the teammate details
output "cicd_maintainer" {
  sensitive = true
  value = {
    name                         = kubiya_agent.cicd_maintainer.name
    repositories                 = var.repositories
    organizational_knowledge_multiline = var.organizational_knowledge_multiline
    debug_mode                   = var.debug_mode
    monitor_pr_workflow_runs    = var.monitor_pr_workflow_runs
    monitor_push_workflow_runs  = var.monitor_push_workflow_runs
    monitor_failed_runs_only    = var.monitor_failed_runs_only
    pipeline_notification_channel = var.pipeline_notification_channel
  }
}

# Add additional knowledge base
resource "kubiya_knowledge" "pipeline_management" {
  name             = "Organization-specific Knowledge Base for GitHub Actions"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Common issues, best practices, and solutions for GitHub Actions workflows in our organization."
  labels           = ["github", "actions", "pipeline", "cicd", "optimization"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = var.organizational_knowledge_multiline
}
