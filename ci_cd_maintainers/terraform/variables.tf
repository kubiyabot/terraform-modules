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
  description = "Primary Slack channel for notifications"
  type        = string
}

variable "pipeline_notification_channel" {
  description = "Slack channel for pipeline alerts"
  type        = string
}

variable "security_notification_channel" {
  description = "Slack channel for security alerts"
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