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

variable "kubiya_groups_allowed_groups" {
  description = "Kubiya groups who can request access through the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "request_tools_sources" {
  description = "List of source URLs for auxiliary request-related tools (AWS policy generator tool is automatically included and cannot be modified)"
  type        = list(string)
  default     = ["https://github.com/kubiyabot/community-tools/tree/main/aws_jit_tools"]
}

variable "kubiya_integrations" {
  description = "List of Kubiya integrations to enable. Supports multiple values. \n For AWS integration, the main account must be provided."
  type        = list(string)
  default     = ["slack"]
}

variable "kubiya_tool_timeout" {
  description = "Timeout for Kubiya tools in seconds, if you have long running tools you may need to increase this"
  type        = number
  default     = 500
}
