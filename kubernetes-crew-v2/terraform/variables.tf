# Required Core Configuration
variable "teammate_name" {
  description = "Name of the Kubernetes crew teammate"
  type        = string
  default     = "k8s-watcher"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "notification_channel" {
  description = "Primary Slack channel for notifications"
  type        = string
  default     = "#devops-oncall"
}


# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

//variable "webhook_filter" {
  //description = "JMESPath filter expressions for GitHub webhook events. See https://jmespath.org for syntax."
  //type        = string
  //default     = "workflow_run.conclusion != null && workflow_run.conclusion != 'success' && (workflow_run.event == 'pull_request' || (workflow_run.event == 'push' && workflow_run.pull_requests[0] != null ))"
//}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}