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

variable "agent_instructions" {
  description = "Instructions for the agent"
  type        = string
}

variable "llm_model" {
  description = "Model to be used by the agent"
  type        = string
}

variable "agent_image" {
  description = "Image for the agent"
  type        = string
}

variable "secrets" {
  description = "Secrets for the agent"
  type        = list(string)
}

variable "integrations" {
  description = "Integrations for the agent"
  type        = list(string)
}

variable "users" {
  description = "Users for the agent"
  type        = list(string)
}

variable "groups" {
  description = "Groups for the agent"
  type        = list(string)
}

variable "agent_tool_sources" {
  description = "Sources (can be URLs such as GitHub repositories or gist URLs) for the tools accessed by the agent"
  type        = list(string)
  default     = ["https://github.com/kubiyabot/community-tools"]
}

variable "links" {
  description = "Links for the agent"
  type        = list(string)
  default     = []
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "INFO"
}

variable "grace_period" {
  description = "Grace period for nagging reminders"
  type        = string
  default     = "5h"
}

variable "max_ttl" {
  description = "Maximum TTL for a request"
  type        = string
  default     = "30d"
}

variable "approval_slack_channel" {
  description = "Slack channel for approval notifications"
  type        = string
}

variable "tf_modules_urls" {
  description = "URLs for the Terraform modules"
  type        = list(string)
  default     = []
}

variable "allowed_vendors" {
  description = "Allowed cloud vendors"
  type        = string
  default     = "aws"
}

variable "extension_period" {
  description = "Extension period for resource TTL"
  type        = string
  default     = "1w"
}

variable "approving_users" {
  description = "List of users who can approve"
  type        = list(string)
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
