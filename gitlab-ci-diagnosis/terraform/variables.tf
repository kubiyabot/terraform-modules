variable "agent_name" {
  description = "Name of the CI/CD diagnosis agent"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner for the agent"
  type        = string
}

variable "agent_description" {
  description = "Description of the CI/CD diagnosis agent"
  type        = string
}

variable "diagnosis_instructions" {
  description = "Instructions for the agent to follow when diagnosing CI/CD issues"
  type        = string
  default     = "Analyze CI/CD pipeline failures, identify common issues, and suggest solutions."
}

variable "enabled_integrations" {
  description = "List of enabled integrations for the agent"
  type        = list(string)
  default     = ["github", "gitlab", "bitbucket", "slack"]
}

variable "kubiya_users" {
  description = "List of users who can interact with the agent"
  type        = list(string)
}

variable "kubiya_groups" {
  description = "List of groups who can interact with the agent"
  type        = list(string)
  default     = ["DevOps", "Developers"]
}

variable "repository_url" {
  description = "URL of the repository to monitor"
  type        = string
}

variable "watch_events" {
  description = "List of events to watch for triggering diagnosis"
  type        = list(string)
  default     = ["PR_OPEN", "PR_CLOSE", "WORKFLOW_FAILED", "PIPELINE_FAILED"]
}

variable "slack_channel_id" {
  description = "Slack channel ID for notifications"
  type        = string
}

variable "log_level" {
  description = "Log level for the agent"
  type        = string
  default     = "INFO"
}

variable "tool_timeout" {
  description = "Timeout for Kubiya tools"
  type        = string
  default     = "5m"
}

variable "troubleshooting_docs_url" {
  description = "URL for troubleshooting documentation"
  type        = string
  default     = ""
}

variable "github_api_token" {
  description = "GitHub API token"
  type        = string
  default     = ""
}

variable "gitlab_api_token" {
  description = "GitLab API token"
  type        = string
  default     = ""
}

variable "bitbucket_api_token" {
  description = "Bitbucket API token"
  type        = string
  default     = ""
}

variable "update_slack" {
  description = "Whether to send updates to Slack"
  type        = bool
  default     = true
}

variable "create_jira_ticket" {
  description = "Whether to create a JIRA ticket for diagnosed issues"
  type        = bool
  default     = false
}

variable "jira_project_key" {
  description = "JIRA project key for creating tickets"
  type        = string
  default     = ""
}

variable "jira_issue_type" {
  description = "JIRA issue type for created tickets"
  type        = string
  default     = "Bug"
}