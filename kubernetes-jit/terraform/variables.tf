variable "teammate_name" {
  description = "Name of the virtual entity that binds the JIT permissions logic"
  type        = string
  default     = "k8s-jit-guardian"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "approves_group_name" {
  description = "Approves group name"
  type        = string
  default     = "Admin"
}

variable "approvers_slack_channel" {
  description = "Slack channel for approval requests (must start with #)"
  type        = string
  default     = "#devops-oncall"
  validation {
    condition     = can(regex("^#", var.approvers_slack_channel))
    error_message = "Approvers Slack channel must start with #"
  }
}

variable "kubiya_groups_allowed_groups" {
  description = "Kubiya groups who can request access through the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "kubiya_integrations" {
  description = "List of Kubiya integrations to enable. Supports multiple values."
  type        = list(string)
  default     = ["slack"]
}


variable "okta_enabled" {
  description = "Enable Okta Integration"
  type        = bool
  default     = false
}

variable "okta_base_url" {
  description = "Your Okta domain URL"
  type        = string
  default     = "https://org.okta.com"
}

variable "okta_client_id" {
  description = "Okta application client ID"
  type        = string
  default     = "Okta application client ID"
}

variable "okta_private_key" {
  description = "Private key for Okta authentication"
  type        = string
  default     = "Private key for Okta authentication"
}

variable "dd_enabled" {
  description = "Enable DataDog Integration"
  type        = bool
  default     = false
}

variable "dd_site" {
  description = "DataDog site"
  type        = string
  default     = "us5.datadoghq.com"
}

variable "dd_api_key" {
  description = "DataDog API key"
  type        = string
  default     = "DataDog API key"
}

variable "kubiya_tool_timeout" {
  description = "Timeout for Kubiya tools in seconds, if you have long running tools you may need to increase this"
  type        = number
  default     = 500
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}

variable "restricted_tools" {
  description = "Tools to be restricted by the policy"
  type        = list(string)
  default     = []
}

variable "tool_validation_rules" {
  description = "Validation rules for tools that require specific parameter validation. For the match_type field, only 'contains' and 'exact' are valid values."
  type = map(object({
    description = string
    parameters = list(object({
      name             = string
      required_pattern = string
      match_type       = string /* Only "contains" or "exact" are valid values */
      description      = string
    }))
  }))
  default = {
    "kubectl" = {
      description = "Rules for kubectl commands"
      parameters = [
        {
          name             = "command"
          required_pattern = "-n kubiya"
          match_type       = "contains"
          description      = "Kubectl commands must specify the kubiya namespace"
        }
      ]
    }
    "resource_usage" = {
      description = "Rules for resource usage commands"
      parameters = [
        {
          name             = "resource_type"
          required_pattern = "nodes"
          match_type       = "exact"
          description      = "Resource type must be nodes"
        }
      ]
    }
  }

  validation {
    condition = alltrue([
      for tool_key, tool in var.tool_validation_rules :
      alltrue([
        for param in tool.parameters :
        contains(["contains", "exact"], param.match_type)
      ])
    ])
    error_message = "The match_type field must be either 'contains' or 'exact'."
  }
}
