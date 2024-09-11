terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

resource "kubiya_source" "sources" {
  count = length(var.kubiya_sources)
  url   = var.kubiya_sources[count.index]
}

resource "kubiya_agent" "jira_ticket_solver" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4o"
  integrations = [var.jira_integration_instance, "slack"]
  sources      = kubiya_source.sources[*].name

  environment_variables = {
    JIRA_PROJECT_NAME        = var.jira_project_name
    JIRA_INTEGRATION         = var.jira_integration_instance
    ISSUE_DESCRIPTION        = var.issue_description
    JIRA_JQL                 = var.jira_jql
    ISSUES_CHECK_INTERVAL    = var.issues_check_interval
    ON_SOLVE_ACTION          = var.on_solve_action
    CUSTOM_FIELD_NAME        = var.custom_field_name
    ON_FAILURE_ACTION        = var.on_failure_action
    SLACK_NOTIFICATION_CHANNEL = var.slack_notification_channel
  }
}

output "jira_ticket_solver" {
  value = kubiya_agent.jira_ticket_solver
}