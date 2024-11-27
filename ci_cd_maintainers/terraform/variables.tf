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

# Authentication Tokens
variable "github_token" {
  description = "GitHub Personal Access Token with repo and admin:repo_hook permissions. Required for GitHub repositories. Generate at: https://github.com/settings/tokens"
  type        = string
}

# Optional Configuration
variable "github_enable_oauth" {
  description = "Enable GitHub OAuth integration for enhanced API capabilities and direct repository access. Default: true"
  type        = bool
  default     = true
}

#variable "max_concurrent_fixes" {
#  description = "Maximum number of automatic fixes that can be applied simultaneously. Default: 3"
#  type        = number
#  default     = 3
#}

#variable "scan_interval" {
#  description = "Interval between repository scans (e.g., '30m', '1h', '6h'). Default: 1h"
#  type        = string
#  default     = "1h"
#}

# Channel Configuration
variable "pipeline_notification_channel" {
  description = "Dedicated Slack channel for pipeline alerts. Falls back to notification_channel if not set (must start with #)."
  type        = string
  default     = ""
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps']). Default: ['Admin']"
  type        = list(string)
  default     = ["Admin"]
}

variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners. Default: default"
  type        = string
  default     = "default"
}

# Event Monitoring Configuration
variable "monitor_push_events" {
  description = "Monitor repository push events for direct commits and policy violations. Default: true"
  type        = bool
  default     = true
}

variable "monitor_pull_requests" {
  description = "Monitor pull request/merge request events for reviews and CI status. Default: true"
  type        = bool
  default     = true
}

variable "monitor_pipeline_events" {
  description = "Monitor CI/CD pipeline events for failures and performance issues. Default: true"
  type        = bool
  default     = true
}

variable "monitor_deployment_events" {
  description = "Monitor deployment events and status changes. Default: true"
  type        = bool
  default     = true
}

variable "monitor_security_events" {
  description = "Monitor security alerts and vulnerability notifications. Default: true"
  type        = bool
  default     = true
}

variable "monitor_issue_events" {
  description = "Monitor repository issue events and comments. Default: false"
  type        = bool
  default     = false
}

variable "monitor_release_events" {
  description = "Monitor repository release events. Default: false"
  type        = bool
  default     = false
}

variable "monitor_create_events" {
  description = "Monitor repository create events. Default: false"
  type        = bool
  default     = false
}

variable "monitor_delete_events" {
  description = "Monitor repository delete events. Default: false"
  type        = bool
  default     = false
}

variable "monitor_branch_protection_events" {
  description = "Monitor repository branch protection events. Default: false"
  type        = bool
  default     = false
}

variable "monitor_check_run_events" {
  description = "Monitor repository check run events"
  type        = bool
  default     = true
}

variable "monitor_check_suite_events" {
  description = "Monitor repository check suite events"
  type        = bool
  default     = true
}

variable "monitor_code_scanning_events" {
  description = "Monitor repository code scanning events"
  type        = bool
  default     = true
}

variable "monitor_dependabot_events" {
  description = "Monitor Dependabot alerts"
  type        = bool
  default     = true
}

variable "monitor_deployment_status_events" {
  description = "Monitor deployment status events"
  type        = bool
  default     = true
}

variable "monitor_secret_scanning_events" {
  description = "Monitor secret scanning alerts and events"
  type        = bool
  default     = true
}

variable "webhook_filter" {
  description = "JMESPath filter expressions for GitHub webhook events. See https://jmespath.org for syntax."
  type        = string
  default     = "workflow_run.conclusion in ['failure', 'timed_out', 'startup_failure', 'stale', 'skipped'] && {status: workflow_run.conclusion, job_name: workflow_run.name, branch: workflow_run.head_branch, commit: workflow_run.head_commit.message, actor: workflow_run.actor.login}"
}
