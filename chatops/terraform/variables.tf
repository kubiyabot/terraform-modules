# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Slack History Analyzer teammate (e.g., 'slack-historian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "slack-historian"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'Users'])."
  type        = list(string)
  default     = ["Admin", "Users"]
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

variable "source_channel" {
  description = "The Slack channel ID to analyze messages from"
  type        = string
}

variable "report_channel" {
  description = "The Slack channel ID to post summary reports to"
  type        = string
}

variable "execution_channel" {
  description = "The Slack channel ID where the scheduled task will be executed"
  type        = string
}