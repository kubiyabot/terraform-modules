variable "repositories" {
  description = "Comma-separated list of repositories to monitor in 'org/repo' format (e.g., 'mycompany/backend-api,mycompany/frontend-app'). Ensure you have appropriate permissions."
  type        = string
}

variable "webhook_url" {
  description = "The URL to which GitHub will send webhook payloads"
  type        = string
}

variable "github_token" {
  description = "GitHub token with permissions to create webhooks"
  type        = string
  sensitive   = true
}

variable "events" {
  description = "List of GitHub events that trigger the webhook"
  type        = list(string)
  default     = ["check_run", "workflow_run"]
} 