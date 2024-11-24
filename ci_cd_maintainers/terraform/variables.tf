# Core Configuration
variable "teammate_name" {
  description = "Name of the CI/CD maintainer teammate"
  type        = string
  default     = "cicd-crew"
}

variable "kubiya_runner" {
  description = "Runner to use for the teammate"
  type        = string
}

variable "source_control_type" {
  description = "Source control platform to use (github/gitlab)"
  type        = string
  validation {
    condition     = contains(["github", "gitlab"], var.source_control_type)
    error_message = "Source control type must be either 'github' or 'gitlab'"
  }
}

variable "repositories" {
  description = "Comma-separated list of repositories to monitor"
  type        = string
}

# Notification Settings
variable "notification_channel" {
  description = "Primary Slack channel for notifications (e.g. #cicd-alerts)"
  type        = string
}

variable "pipeline_notification_channel" {
  description = "Slack channel for pipeline alerts (e.g. #ci-cd-alerts)"
  type        = string
}

variable "security_notification_channel" {
  description = "Slack channel for security alerts (e.g. #security-alerts)"
  type        = string
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Feature Flags
variable "webhook_enabled" {
  description = "Enable webhook creation for repositories"
  type        = bool
  default     = true
}

variable "auto_fix_enabled" {
  description = "Enable automatic fixing of issues"
  type        = bool
  default     = false
}

variable "max_concurrent_fixes" {
  description = "Maximum number of concurrent auto-fixes"
  type        = number
  default     = 3
}

# Scan Settings
variable "scan_interval" {
  description = "Interval between repository scans"
  type        = string
  default     = "1h"
}

# Task Schedule Settings
variable "pipeline_health_check_enabled" {
  description = "Enable pipeline health check task"
  type        = bool
  default     = true
}

variable "pipeline_health_check_repeat" {
  description = "Pipeline health check repeat interval"
  type        = string
  default     = "hourly"
}

variable "security_scan_enabled" {
  description = "Enable security scan task"
  type        = bool
  default     = true
}

variable "security_scan_repeat" {
  description = "Security scan repeat interval"
  type        = string
  default     = "daily"
}

variable "dependency_check_enabled" {
  description = "Enable dependency check task"
  type        = bool
  default     = true
}

variable "dependency_check_repeat" {
  description = "Dependency check repeat interval"
  type        = string
  default     = "daily"
}

# Source Control Authentication
variable "github_token" {
  description = "GitHub Personal Access Token for webhook setup (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_token" {
  description = "GitLab Personal Access Token for webhook setup (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Add these webhook event control variables...

variable "monitor_push_events" {
  description = "Monitor repository push events"
  type        = bool
  default     = true
}

variable "monitor_pull_requests" {
  description = "Monitor pull request/merge request events"
  type        = bool
  default     = true
}

variable "monitor_pipeline_events" {
  description = "Monitor CI/CD pipeline events"
  type        = bool
  default     = true
}

variable "monitor_deployment_events" {
  description = "Monitor deployment events"
  type        = bool
  default     = true
}

variable "monitor_security_events" {
  description = "Monitor security alerts and vulnerabilities"
  type        = bool
  default     = true
}

variable "monitor_issue_events" {
  description = "Monitor issue events"
  type        = bool
  default     = false
}

variable "monitor_release_events" {
  description = "Monitor release events"
  type        = bool
  default     = false
}

variable "webhook_content_type" {
  description = "Content type for webhook payloads"
  type        = string
  default     = "json"
} 