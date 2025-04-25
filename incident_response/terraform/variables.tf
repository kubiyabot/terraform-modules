# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Incident Response teammate (e.g., 'incident-responder' or 'alert-detective'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "incident-responder"
}

variable "notification_channel" {
  description = "The channel to send incident notifications to. For Slack, use channel name (e.g., '#incidents'). For Teams, don't use prefix (#)"
  type        = string
  default     = "#incident-response"
}

variable "ms_teams_notification" {
  description = "Whether to send notifications using MS Teams (if false, notifications will be sent to Slack)"
  type        = bool
  default     = false
}

variable "ms_teams_team_name" {
  description = "If MS Teams is selected, please provide the team name to send notifications to (channel is based on the notification channel variable)"
  type        = string
  default     = "TEAMS"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps', 'SRE'])."
  type        = list(string)
  default     = ["Admin", "SRE"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string
}

# Debug Mode
variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)"
  type        = bool
  default     = false
}

# Datadog Configuration
variable "DATADOG_API_KEY" {
  type        = string
  sensitive   = true
  description = "Datadog API key for accessing monitoring data"
}

variable "DATADOG_APP_KEY" {
  type        = string
  sensitive   = true
  description = "Datadog application key for API access"
}

variable "datadog_site" {
  type        = string
  description = "Datadog site URL (e.g., 'datadoghq.com', 'datadoghq.eu')"
  default     = "datadoghq.com"
}

# Observe Configuration
variable "OBSERVE_API_KEY" {
  type        = string
  sensitive   = true
  description = "Observe API key for accessing log data"
}

variable "OBSERVE_DATASET_ID" {
  type        = string
  description = "Observe dataset ID for the logs to access"
}

# ArgoCD Configuration
variable "ARGOCD_TOKEN" {
  type        = string
  sensitive   = true
  description = "ArgoCD token for accessing deployment information"
}

variable "ARGOCD_DOMAIN" {
  type        = string
  description = "ArgoCD domain URL (e.g., 'argocd.example.com')"
}
