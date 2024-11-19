variable "teammate_name" {
  description = "Name of the virtual entity that binds the JIT permissions logic"
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

variable "available_policies_yaml" {
  description = "YAML formatted string containing list of IAM policies for which Kubiya will generate virtual access request tools (up to 30 policies supported)"
  type        = string
  default     = <<-EOT
    policies:
      - policy_name: "AWSReadOnlyAccess"
        aws_account_id: "123456789012"
        request_name: "Read Only Access"
      - policy_name: "AWSPowerUserAccess"
        aws_account_id: "123456789012"
        request_name: "Power User Access"
      - policy_name: "AWSSystemAdministrator"
        aws_account_id: "123456789012"
        request_name: "System Administrator Access"
  EOT
  validation {
    condition = length(yamldecode(var.available_policies_yaml).policies) <= 30
    error_message = "Maximum of 30 policies supported for virtual tool generation"
  }
}

variable "kubiya_groups_allowed_groups" {
  description = "Kubiya groups who can request access through the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "request_tools_sources" {
  description = "List of source URLs for auxiliary request-related tools (AWS policy generator tool is automatically included and cannot be modified)"
  type        = list(string)
  default     = [
    "https://github.com/kubiyabot/community-tools/tree/main/aws",
  ]
}

variable "kubiya_integrations" {
  description = "List of Kubiya integrations to enable (AWS integrations must include account ID)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for integration in var.kubiya_integrations :
      can(regex("^aws-\\d{12}$", integration)) || !startswith(integration, "aws")
    ])
    error_message = "AWS integrations must include a 12-digit account ID (format: aws-123456789012)"
  }
}

variable "kubiya_tool_timeout" {
  description = "Timeout for Kubiya tools in seconds, if you have long running tools you may need to increase this"
  type        = number
  default     = 500
}
