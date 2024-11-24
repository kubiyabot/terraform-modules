
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
  description = "Primary Slack channel for notifications with '#' prefix (e.g., '#cicd-alerts'). Bot must be invited to this channel."
  type        = string
}

# Authentication Tokens
variable "github_token" {
  description = "GitHub Personal Access Token with repo and admin:repo_hook permissions. Required for GitHub repositories. Generate at: https://github.com/settings/tokens"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_token" {
  description = "GitLab Personal Access Token with api, read_repository, and write_repository permissions. Required for GitLab repositories. Generate at: https://gitlab.com/-/profile/personal_access_tokens"
  type        = string
  default     = ""
  sensitive   = true
}

# Optional Configuration
variable "github_enable_oauth" {
  description = "Enable GitHub OAuth integration for enhanced API capabilities and direct repository access. Default: true"
  type        = bool
  default     = true
}

variable "webhook_enabled" {
  description = "Enable webhook creation for repositories to receive real-time events. Default: true"
  type        = bool
  default     = true
}

variable "webhook_content_type" {
  description = "Content type for webhook payloads (json/form). Default: json"
  type        = string
  default     = "json"
}

variable "auto_fix_enabled" {
  description = "Enable automatic fixing of minor issues like non-breaking dependency updates and common pipeline problems. Default: false"
  type        = bool
  default     = false
}

variable "max_concurrent_fixes" {
  description = "Maximum number of automatic fixes that can be applied simultaneously. Default: 3"
  type        = number
  default     = 3
}

variable "scan_interval" {
  description = "Interval between repository scans (e.g., '30m', '1h', '6h'). Default: 1h"
  type        = string
  default     = "1h"
}

# Channel Configuration
variable "pipeline_notification_channel" {
  description = "Dedicated Slack channel for pipeline alerts. Falls back to notification_channel if not set."
  type        = string
  default     = ""
}

variable "security_notification_channel" {
  description = "Dedicated Slack channel for security alerts. Falls back to notification_channel if not set."
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

# Task Schedule Settings
variable "pipeline_health_check_enabled" {
  description = "Enable regular pipeline health check task. Default: true"
  type        = bool
  default     = true
}

variable "pipeline_health_check_repeat" {
  description = "How often to run pipeline health checks. Default: hourly"
  type        = string
  default     = "hourly"
}

variable "security_scan_enabled" {
  description = "Enable regular security scanning task. Default: true"
  type        = bool
  default     = true
}

variable "security_scan_repeat" {
  description = "How often to run security scans. Default: daily"
  type        = string
  default     = "daily"
}

variable "dependency_check_enabled" {
  description = "Enable regular dependency checking task. Default: true"
  type        = bool
  default     = true
}

variable "dependency_check_repeat" {
  description = "How often to check for dependency updates. Default: daily"
  type        = string
  default     = "daily"
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