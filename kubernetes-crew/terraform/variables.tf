variable "teammate_name" {
  description = "Name of the Kubernetes Crew teammate"
  type        = string
  default     = "k8s-crew"
}

variable "kubiya_runner" {
  description = "Name of the Kubiya runner to use"
  type        = string
}

variable "notification_slack_channel" {
  description = "Slack channel for notifications"
  type        = string
}

variable "users" {
  description = "List of users who can interact with the crew"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "List of groups who can interact with the crew"
  type        = list(string)
  default     = ["Admin"]
}

variable "log_level" {
  description = "Logging level"
  type        = string
  default     = "INFO"
}

variable "scheduled_tasks" {
  description = "Map of scheduled tasks to create"
  type = map(object({
    enabled       = bool
    start_time    = string
    repeat        = string
    custom_prompt = optional(string)
  }))
  default = {
    health_check = {
      enabled    = true
      start_time = "2024-01-01T09:00:00Z"
      repeat     = "daily"
    }
    capacity_check = {
      enabled    = true
      start_time = "2024-01-01T10:00:00Z"
      repeat     = "weekly"
    }
  }
}
