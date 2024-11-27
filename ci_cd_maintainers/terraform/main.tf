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
  github_events = concat(
    var.monitor_push_events ? ["push"] : [],
    var.monitor_pull_requests ? ["pull_request", "pull_request_review", "pull_request_review_comment"] : [],
    var.monitor_pipeline_events ? ["check_run", "check_suite", "workflow_job", "workflow_run"] : [],
    var.monitor_deployment_events ? ["deployment", "deployment_status"] : [],
    var.monitor_security_events ? ["repository_vulnerability_alert"] : [],
    var.monitor_issue_events ? ["issues", "issue_comment"] : [],
    var.monitor_release_events ? ["release"] : [],
    var.monitor_check_run_events ? ["check_run"] : [],
    var.monitor_check_suite_events ? ["check_suite"] : [],
    var.monitor_code_scanning_events ? ["code_scanning_alert"] : [],
    var.monitor_dependabot_events ? ["dependabot_alert"] : [],
    var.monitor_deployment_status_events ? ["deployment_status"] : [],
    var.monitor_secret_scanning_events ? ["secret_scanning_alert", "secret_scanning_alert_location"] : []
  )

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")

  # Define JMESPath filters for different event types
  webhook_filters = {
    workflow_run = "event.workflow_run[?conclusion in ['failure', 'cancelled', 'timed_out']]"
    check_suite  = "event.check_suite[?conclusion in ['failure', 'cancelled', 'timed_out']]"
    deployment   = "event.deployment_status[?state in ['failure', 'error']]"
    pull_request = "event.pull_request[?action in ['opened', 'reopened', 'synchronize', 'closed']]"
    push         = "event[?ref in ['refs/heads/main', 'refs/heads/master']]"
    security     = "event.alert[?state == 'open']"
    issues       = "event.issue[?state == 'open' && (contains(labels[*].name, 'bug') || contains(labels[*].name, 'security') || contains(labels[*].name, 'critical'))]"
  }

  # Build dynamic filter based on enabled event types
  dynamic_filter = join(" || ", compact([
    var.monitor_pipeline_events ? local.webhook_filters.workflow_run : "",
    var.monitor_pipeline_events ? local.webhook_filters.check_suite : "",
    var.monitor_deployment_events ? local.webhook_filters.deployment : "",
    var.monitor_pull_requests ? local.webhook_filters.pull_request : "",
    var.monitor_push_events ? local.webhook_filters.push : "",
    var.monitor_security_events ? local.webhook_filters.security : "",
    var.monitor_issue_events ? local.webhook_filters.issues : ""
  ]))
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
  model        = "azure/gpt-4"
  instructions = ""
  
  sources = [
    kubiya_source.github_tooling.name
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    ["slack"],
    var.github_enable_oauth ? ["github"] : []
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    REPOSITORIES = var.repositories
    #SOURCE_CONTROL_TYPE = local.source_control_type
    #MAX_CONCURRENT_FIXES = tostring(var.max_concurrent_fixes)
    #SCAN_INTERVAL = var.scan_interval
    GITHUB_OAUTH_ENABLED = tostring(var.github_enable_oauth)
    KUBIYA_TOOL_TIMEOUT = "300"
  }
}

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  filter = local.dynamic_filter
  
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  prompt      = <<-EOT
    Analyze this GitHub event and determine if action is needed:
    Event: {{.event}}
    
    If this is a pipeline failure:
    1. Analyze the failure cause
    2. Check for common patterns
    3. Suggest potential fixes
    4. If auto-fix is enabled and the fix is safe, apply it
    
    If this is a security alert:
    1. Assess the severity
    2. Check if it affects other repositories
    3. Propose remediation steps
    
    Comment on the PR with the relevant findings
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
    url          = kubiya_webhook.source_control_webhook[0].url
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
resource "kubiya_knowledge" "pipeline_management" {
  name             = "Pipeline Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for pipeline management and optimization"
  labels           = ["cicd", "pipeline", "optimization"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = data.http.pipeline_management.response_body
}

# Add this data source near the other HTTP data sources at the top of the file
data "http" "pipeline_management" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/pipeline_management.md"
}
