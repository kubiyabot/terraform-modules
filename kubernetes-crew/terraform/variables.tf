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

variable "cronjob_repeat_scenario_two" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "weekly"
}
variable "cronjob_repeat_scenario_three" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "monthly"
}

variable "enable_resource_check_task" {
  description = "📊 Enable scheduled resource optimization task"
  type        = bool
  default     = true
}

// Scheduled Tasks Configuration
variable "enable_health_check_task" {
  description = "🏥 Enable scheduled health check task"
  type        = bool
  default     = true
}

variable "enable_cleanup_task" {
  description = "🧹 Enable scheduled cleanup task"
  type        = bool
  default     = true
}

variable "enable_network_check_task" {
  description = "🌐 Enable scheduled network check task"
  type        = bool
  default     = true
}

variable "enable_security_check_task" {
  description = "🔒 Enable scheduled security check task"
  type        = bool
  default     = true
}

variable "enable_backup_check_task" {
  description = "💾 Enable scheduled backup verification task"
  type        = bool
  default     = true
}

variable "enable_cost_analysis_task" {
  description = "💰 Enable scheduled cost analysis task"
  type        = bool
  default     = true
}

variable "enable_compliance_check_task" {
  description = "✅ Enable scheduled compliance check task"
  type        = bool
  default     = true
}

variable "enable_update_check_task" {
  description = "🔄 Enable scheduled update check task"
  type        = bool
  default     = true
}

variable "enable_capacity_check_task" {
  description = "📈 Enable scheduled capacity planning task"
  type        = bool
  default     = true
}

variable "enable_upgrade_check_task" {
  description = "🚀 Enable upgrade check monitoring task"
  type        = bool
  default     = true
}