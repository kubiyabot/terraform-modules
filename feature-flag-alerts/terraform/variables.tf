# Required Core Configuration
variable "teammate_name" {
  description = "Name of your CI/CD maintainer teammate (e.g., 'cicd-crew' or 'pipeline-guardian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "alerts-watcher"
}

# Slack Configuration
variable "alert_notification_channel" {
  description = "The Slack channel to send alert notifications to and engage with the Alerts Watcher. Must be a valid Slack channel name (e.g., '#general' or '#engineering') and the Kubiya Slack App must be invited to the channel."
  type        = string
  default     = "#alerts"
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

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)"
  type        = bool
  default     = false
}

variable "organizational_knowledge_multiline" {
  description = "Additional organizational knowledge for the Alerts Watcher in markdown format - useful for providing context and best practices, common issues, and more to help the teammate understand the organization and its workflows."
  type        = string
  default     = "<no additional knowledge base content provided - please provide your own>"
}

variable "PROJECT_KEY" {
  type        = string
  description = "LaunchDarkly Project Key"
}

variable "DD_SITE" {
  type        = string
  description = "Datadog Site (e.g. datadoghq.com)"
}

variable "DD_API_KEY" {
  type        = string
  sensitive   = true
  description = "Datadog API Key"
}

variable "DD_APP_KEY" {
  type        = string
  sensitive   = true
  description = "Datadog Application Key"
}

variable "LD_API_KEY" {
  type        = string
  sensitive   = true
  description = "LaunchDarkly API Key"
}