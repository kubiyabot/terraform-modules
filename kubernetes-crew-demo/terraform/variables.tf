# Core Configuration
variable "teammate_name" {
  description = "Name of the Kubernetes crew teammate"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner for the teammate"
  type        = string
}

variable "teammate_description" {
  description = "Description of the Kubernetes crew teammate"
  type        = string
  default     = "AI-powered Kubernetes operations assistant"
}

# Access Control
variable "kubiya_users" {
  description = "List of users who can interact with the teammate"
  type        = list(string)
  default     = []
}

variable "kubiya_groups" {
  description = "List of groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Notifications
variable "notification_slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#kubernetes-alerts"
}

variable "scheduled_task_slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#kubernetes-alerts"
}

variable "log_level" {
  description = "Logging level (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cronjob_start_time" {
  description = "Default start time for cron jobs"
  type        = string
  default     = "2024-11-05T08:00:00"
}

variable "cronjob_repeat_scenario_one" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "daily"
}

// Scheduled Tasks Configuration
variable "enable_health_check_task" {
  description = "🏥 Enable scheduled health check task"
  type        = bool
  default     = true
}
