variable "teammate_email" {
  description = "Email address of the Kubiya teammate"
  type        = string
}

variable "teammate_role" {
  description = "Role for the Kubiya teammate"
  type        = string
  default     = "user"
}

variable "teammate_first_name" {
  description = "First name of the Kubiya teammate"
  type        = string
}

variable "teammate_last_name" {
  description = "Last name of the Kubiya teammate"
  type        = string
}

variable "agent_name" {
  description = "Name of the Kubiya agent"
  type        = string
}

variable "agent_description" {
  description = "Description of the Kubiya agent"
  type        = string
  default     = ""
}

variable "agent_runner" {
  description = "Runner for the Kubiya agent"
  type        = string
}

variable "agent_instructions" {
  description = "Instructions for the Kubiya agent"
  type        = string
}

variable "source_name" {
  description = "Name of the Kubiya source"
  type        = string
}

variable "source_url" {
  description = "URL for the Kubiya source"
  type        = string
}

variable "source_type" {
  description = "Type of the Kubiya source"
  type        = string
}

variable "source_description" {
  description = "Description of the Kubiya source"
  type        = string
  default     = ""
}

variable "source_config" {
  description = "Configuration for the Kubiya source"
  type        = map(string)
}

variable "webhook_name" {
  description = "Name of the Kubiya webhook"
  type        = string
}

variable "webhook_destination" {
  description = "Destination for the webhook"
  type        = string
}

variable "webhook_prompt" {
  description = "Prompt for the webhook"
  type        = string
}

variable "webhook_description" {
  description = "Description of the Kubiya webhook"
  type        = string
  default     = ""
}

variable "webhook_url" {
  description = "URL for the webhook endpoint"
  type        = string
}

variable "webhook_events" {
  description = "List of events to trigger the webhook"
  type        = list(string)
}

variable "webhook_secret" {
  description = "Secret for webhook signature verification"
  type        = string
  sensitive   = true
}

variable "webhook_enabled" {
  description = "Whether the webhook is enabled"
  type        = bool
  default     = true
} 