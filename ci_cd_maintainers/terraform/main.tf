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
  #concat(
   # var.monitor_pipeline_events ? ["check_run", "workflow_run"] : [],
    #var.monitor_push_events ? ["push"] : [],
    #var.monitor_pull_requests ? ["pull_request", "pull_request_review", "pull_request_review_comment"] : [],
    #var.monitor_deployment_events ? ["deployment", "deployment_status"] : [],
    #var.monitor_security_events ? ["repository_vulnerability_alert"] : [],
    #var.monitor_issue_events ? ["issues", "issue_comment"] : [],
    #var.monitor_release_events ? ["release"] : [],
    #var.monitor_check_suite_events ? ["check_suite"] : [],
    #var.monitor_code_scanning_events ? ["code_scanning_alert"] : [],
    #var.monitor_dependabot_events ? ["dependabot_alert"] : [],
    #var.monitor_deployment_status_events ? ["deployment_status"] : [],
    #var.monitor_secret_scanning_events ? ["secret_scanning_alert", "secret_scanning_alert_location"] : []
  #)

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")
}

# Configure providers
provider "github" {
  token = var.github_token
  owner = local.github_organization
}

resource "kubiya_source" "github_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered CI/CD maintenance assistant"
  model        = "azure/gpt-4o"
  instructions = ""
  secrets      = var.kubiya_secrets
  sources = [
    kubiya_source.github_tooling.name
  ]

  # Dynamic integrations based on configuration
  integrations = ["slack]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "300"
  }
}

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  filter = var.webhook_filter
  
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  prompt      = <<-EOT
    Your Goal: Analyze GitHub Actions workflow logs.
    Workflow ID: {{.event.workflow_run.id}}
    PR Number: {{.event.workflow_run.pull_requests[0].number}}
    Repository: {{.event.repository.full_name}}

    Instructions:

    1. Use workflow_run_logs_failed to fetch failed logs for Workflow ID {{.event.workflow_run.id}}. Wait until this step finishes.

    2. Analyze logs to identify:
    Build Failure Analysis:
    Failure Point: Broken step.
    Error Details: Key error messages/stack traces.
    Issue History: New or recurring?
    Root Cause Assessment:
    Source: Code, infra, config, or environment.
    Dependencies: Related issues.
    Permissions: Security concerns.
    Recommended Actions:
    Fix, Prevention, Docs (with links).
    Priority Level: Impact, Urgency, Notify stakeholders.

    3. Format insights clearly with headers/bullets.

    4. Use github_pr_comment to comment on PR #{{.event.workflow_run.pull_requests[0].number}} with these findings.
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
  }
}

# Add additional knowledge base
# resource "kubiya_knowledge" "pipeline_management" {
#   name             = "Pipeline Management Guide"
#   groups           = var.kubiya_groups_allowed_groups
#   description      = "Knowledge base for pipeline management and optimization"
#   labels           = ["cicd", "pipeline", "optimization"]
#   supported_agents = [kubiya_agent.cicd_maintainer.name]
#   content          = data.http.pipeline_management.response_body
# }

# Add this data source near the other HTTP data sources at the top of the file
# data "http" "pipeline_management" {
#   url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/pipeline_management.md"
# }
