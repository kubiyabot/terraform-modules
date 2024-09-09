variable "agent_name" {
  description = "Name of the agent"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner for the agent"
  type        = string
}

variable "agent_description" {
  description = "Description of the agent"
  type        = string
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
  description = "Users for the agent"
  type        = list(string)
}

variable "kubiya_groups" {
  description = "Groups for the agent"
  type        = list(string)
}

variable "links" {
  description = "Links for the agent"
  type        = list(string)
}

variable "approval_slack_channel" {
  description = "Slack channel for approval notifications"
  type        = string
}

variable "kubiya_users_approving_users" {
  description = "List of users who can approve"
  type        = list(string)
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "INFO"
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