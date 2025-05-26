# Required Core Configuration
variable "teammate_name" {
  description = "Name of your CI/CD maintainer teammate (e.g., 'cicd-crew' or 'pipeline-guardian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "cicd-crew"
}

variable "repositories" {
  description = "Comma-separated list of repositories to monitor in 'org/repo' format (e.g., 'mycompany/backend-api,mycompany/frontend-app'). Ensure you have appropriate permissions."
  type        = string
}

variable "notification_channel" {
  description = "The channel to send pipeline notifications to. For Slack, use channel name (e.g., '#general'.). For Teams, don't use prefix (#)"
  type        = string
  default     = "#ci-cd-maintainers-crew"
}

variable "summary_channel" {
  description = "The channel to send summary notifications to. Slack Only, use channel name."
  type        = string
  default     = "#ci-cd-maintainers-crew-summary"
}


variable "ms_teams_notification" {
  description = "Wether to send notifications using MS Teams (if false, notifications will be sent to Slack)"
  type        = bool
  default     = false
}

variable "ms_teams_team_name" {
  description = "If MS Teams is selected, please provide the team name to send notifications to (channel is based on the notification channel variable)"
  type        = string
  default     = "TEAMS"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string
}

# Webhook Filter Configuration
variable "monitor_pr_workflow_runs" {
  description = "Listen for workflow runs that are associated with pull requests"
  type        = bool
  default     = true
}

variable "monitor_push_workflow_runs" {
  description = "Listen for workflow runs triggered by push events"
  type        = bool
  default     = true
}

variable "monitor_failed_runs_only" {
  description = "Only monitor failed workflow runs (if false, will monitor all conclusions)"
  type        = bool
  default     = true
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)"
  type        = bool
  default     = false
}

variable "enable_branch_filter" {
  description = "Whether to enable branch filtering for webhook events"
  type        = bool
  default     = false
}

variable "head_branch_filter" {
  description = "The branch name to filter webhook events on. Only used when enable_branch_filter is true."
  type        = string
  default     = "go-failure"
  validation {
    condition     = var.head_branch_filter == null || can(regex("^[a-zA-Z0-9-_.]+$", var.head_branch_filter))
    error_message = "head_branch_filter must be either null or a valid branch name containing only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "use_github_app" {
  type        = bool
  description = "Whether to use GitHub App integration instead of the personal token provided under secrets. if selected, make sure to set Github app integration under integrations."
  default     = true
}