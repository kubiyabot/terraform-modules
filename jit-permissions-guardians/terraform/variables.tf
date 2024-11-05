variable "teammate_name" {
  description = "🤖 Name of the Kubernetes Sidekick teammate"
  type        = string
}

variable "kubiya_runner" {
  description = "🏃 Runner (cluster) to use for the teammate"
  type        = string
}

variable "teammate_description" {
  description = "📝 Description of the Kubernetes Sidekick teammate"
  type        = string
  default     = "Kubernetes operations and maintenance assistant"
}

variable "kubiya_secrets" {
  description = "Secrets for the agent"
  type        = list(string)
}

variable "kubiya_integrations" {
  description = "Integrations for the agent"
  type        = list(string)
}

variable "kubiya_users" {
  description = "👥 Users who can interact with the teammate"
  type        = list(string)
}

variable "kubiya_groups" {
  description = "👥 Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "log_level" {
  description = "📊 Log level for debugging and monitoring"
  type        = string
  default     = "INFO"
}

variable "kubiya_users_approving_users" {
  description = "👥 Users who can interact with the teammate"
  type        = list(string)
}

variable "approval_slack_channel" {
  description = "💬 Slack channel for notifications"
  type        = string
}

variable "debug" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

variable "dry_run" {
  description = "Enable dry run mode (no changes will be made to infrastructure from the agent)"
  type        = bool
  default     = false
}
