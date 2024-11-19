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
  description = "YAML formatted string containing available policies structure"
  type        = string
  default     = <<-EOT
    policies:
      - policy_name: "ReadOnlyAccess"
        aws_account_id: "123456789012"
        request_name: "Read Only Access"
      - policy_name: "PowerUserAccess"
        aws_account_id: "123456789012"
        request_name: "Power User Access"
      - policy_name: "SystemAdministrator"
        aws_account_id: "123456789012"
        request_name: "System Administrator Access"
  EOT
}

variable "whitelisted_tools_yaml" {
  description = "YAML formatted string containing whitelisted tool definitions"
  type        = string
  default     = <<-EOT
    tools:
      - name: "list_access_requests"
        allowed: true
        description: "List all access requests"
      - name: "view_access_request"
        allowed: true
        description: "View details of a specific access request"
      - name: "cancel_access_request"
        allowed: true
        description: "Cancel an existing access request"
  EOT
}

variable "allowed_groups" {
  description = "Groups who can request access through the teammate"
  type        = list(string)
  default     = ["Developers", "Operations"]
}
