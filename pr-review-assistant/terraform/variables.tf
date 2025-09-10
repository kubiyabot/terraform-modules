variable "agent_name" {
  description = "Name of the simple PR review agent"
  type        = string
  default     = "simple-pr-reviewer"
}

variable "kubiya_runner" {
  description = "Runner for the agent"
  type        = string
}

variable "kubiya_groups" {
  description = "Groups that can use the reviewer"
  type        = list(string)
  default     = ["Developers"]
}

variable "kubiya_users" {
  description = "Individual users who can use the reviewer"
  type        = list(string)
  default     = []
}

variable "github_token" {
  description = "GitHub API token"
  type        = string
  sensitive   = true
}

variable "slack_token" {
  description = "Slack API token"
  type        = string
  sensitive   = true
}

variable "default_slack_channel" {
  description = "Default Slack channel for PR notifications"
  type        = string
  default     = "#pr-reviews"
  validation {
    condition     = can(regex("^#", var.default_slack_channel))
    error_message = "Slack channel must start with #"
  }
}

variable "github_repository_filter" {
  description = "Optional: Filter webhook to specific repositories (e.g., 'org/repo')"
  type        = string
  default     = ""
}

variable "ai_model" {
  description = "AI model to use"
  type        = string
  default     = "azure/gpt-4"
}

variable "log_level" {
  description = "Logging level"
  type        = string
  default     = "INFO"
}

variable "debug_mode" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}