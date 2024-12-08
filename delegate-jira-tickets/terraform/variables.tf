variable "teammate_name" {
  description = "Name of the JIRA Ticket Solver teammate"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "teammate_description" {
  description = "Description of the JIRA Ticket Solver teammate"
  type        = string
}

variable "jira_project_name" {
  description = "JIRA project name or ID"
  type        = string
}

variable "issue_description" {
  description = "Natural language description of issues to look for"
  type        = string
}

variable "jira_jql" {
  description = "Optional JQL for filtering issues"
  type        = string
  default     = ""
}

variable "issues_check_interval" {
  description = "Interval for checking issues"
  type        = string
  default     = "10m"
}

variable "on_solve_action" {
  description = "Action to take when an issue is solved"
  type        = string
  default     = "move to done"
  validation {
    condition     = contains(["move to done", "move to in progress", "custom field"], var.on_solve_action)
    error_message = "Invalid on_solve_action. Must be 'move to done', 'move to in progress', or 'custom field'."
  }
}

variable "custom_field_name" {
  description = "Custom field name for on_solve_action if 'custom field' is selected"
  type        = string
  default     = ""
}

variable "on_failure_action" {
  description = "Action to take when resolution fails"
  type        = string
  default     = "comment"
  validation {
    condition     = contains(["comment", "do nothing", "send slack message"], var.on_failure_action)
    error_message = "Invalid on_failure_action. Must be 'comment', 'do nothing', or 'send slack message'."
  }
}

variable "slack_notification_channel" {
  description = "Slack channel for notifications on failure"
  type        = string
  default     = ""
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}