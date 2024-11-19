variable "teammate_name" {
  description = "Name of the JIT permissions teammate"
  type        = string
  default     = "jit-guardian"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "approvers_slack_channel" {
  description = "Slack channel for approval requests (must start with #)"
  type        = string
  validation {
    condition     = can(regex("^#", var.approvers_slack_channel))
    error_message = "Approvers Slack channel must start with #"
  }
}

variable "multiline_available_policies" {
  description = "JSON formatted string containing available policies structure"
  type        = string
  default     = jsonencode({
    "policies": [
      {
        "policy_name": "ReadOnlyAccess",
        "aws_account_id": "123456789012",
        "request_name": "Read Only Access"
      },
      {
        "policy_name": "PowerUserAccess",
        "aws_account_id": "123456789012",
        "request_name": "Power User Access"
      },
      {
        "policy_name": "SystemAdministrator",
        "aws_account_id": "123456789012",
        "request_name": "System Administrator Access"
      }
    ]
  })
  validation {
    condition     = can(jsondecode(var.multiline_available_policies))
    error_message = "Available policies must be a valid JSON string"
  }
}

variable "kubiya_groups_allowed_groups" {
  description = "Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "log_level" {
  description = "Log level for the teammate"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR"
  }
}
