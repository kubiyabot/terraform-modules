# Required Core Configuration
variable "teammate_name" {
  description = "Name of your CI/CD maintainer teammate (e.g., 'cicd-crew' or 'pipeline-guardian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "cicd-crew"
}

variable "repositories" {
  description = "Comma-separated list of repositories to monitor in 'org/repo' format (e.g., 'mycompany/backend-api,mycompany/frontend-app'). Ensure you have appropriate permissions."
  type        = string
}

# Slack Configuration
variable "pipeline_notification_channel" {
  description = "The Slack channel to send pipeline notifications to and engage with the CI/CD maintainer. Must be a valid Slack channel name (e.g., '#general' or '#engineering') and the Kubiya Slack App must be invited to the channel."
  type        = string
  default     = "#pipeline-alerts"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string
}

# Webhook Filter Configuration
variable "monitor_pr_workflow_runs" {
  description = "Listen for workflow runs that are associated with pull requests"
  type        = bool
  default     = true
}

variable "monitor_push_workflow_runs" {
  description = "Listen for workflow runs triggered by push events"
  type        = bool
  default     = true
}

variable "monitor_failed_runs_only" {
  description = "Only monitor failed workflow runs (if false, will monitor all conclusions)"
  type        = bool
  default     = true
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)"
  type        = bool
  default     = false
}

variable "organizational_knowledge_multiline" {
  description = "Additional organizational knowledge for the CI/CD maintainer in markdown format - useful for providing context and best practices, common issues, and more to help the teammate understand the organization and its workflows."
  type        = string
  default     = "<no additional knowledge base content provided - please provide your own>"
}
