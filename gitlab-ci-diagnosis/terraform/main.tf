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

resource "kubiya_source" "ci_cd_diagnosis_tools" {
  url = "https://github.com/kubiyabot/community-tools/ci-cd-diagnosis"
}

resource "kubiya_agent" "ci_cd_diagnosis" {
  name         = var.agent_name
  runner       = var.kubiya_runner
  description  = var.agent_description
  instructions = var.diagnosis_instructions
  model        = "azure/gpt-4o"
  integrations = concat(
    var.enabled_integrations,
    var.create_jira_ticket ? ["jira"] : []
  )
  users        = var.kubiya_users
  groups       = var.kubiya_groups
  sources      = [kubiya_source.ci_cd_diagnosis_tools.name]

  environment_variables = {
    REPOSITORY_URL           = var.repository_url
    WATCH_EVENTS             = join(",", var.watch_events)
    SLACK_CHANNEL_ID         = var.slack_channel_id
    LOG_LEVEL                = var.log_level
    KUBIYA_TOOL_TIMEOUT      = var.tool_timeout
    TROUBLESHOOTING_DOCS_URL = var.troubleshooting_docs_url
    GITHUB_API_TOKEN         = var.github_api_token
    GITLAB_API_TOKEN         = var.gitlab_api_token
    BITBUCKET_API_TOKEN      = var.bitbucket_api_token
    UPDATE_SLACK             = var.update_slack
    CREATE_JIRA_TICKET       = var.create_jira_ticket
    JIRA_PROJECT_KEY         = var.jira_project_key
    JIRA_ISSUE_TYPE          = var.jira_issue_type
  }
}

output "agent" {
  value = kubiya_agent.ci_cd_diagnosis
}