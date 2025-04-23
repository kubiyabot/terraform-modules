# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Alert Investigation teammate"
  type        = string
  default     = "alert-investigator"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate"
  type        = list(string)
  default     = ["Admin", "Users"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate"
  type        = string
}

# Channel Configuration
variable "alert_source_channels" {
  description = "List of Slack channels to monitor for Datadog alerts. Accepts channel names with or without '#' prefix (e.g., '#alerts', 'alerts') or channel IDs (e.g., 'C43914184')"
  type        = list(string)
}

variable "feature_flags_channels" {
  description = "List of Slack channels where feature flag changes are logged from Eppo and LaunchDarkly. Accepts channel names with or without '#' prefix (e.g., '#feature-flags', 'feature-flags') or channel IDs (e.g., 'C43914184')"
  type        = list(string)
}

variable "lookback_period" {
  description = "Duration to look back for feature flag changes (e.g., '30m', '2h', '2d')"
  type        = string
  default     = "30m"
}

variable "debug_mode" {
  description = "Enable debug mode for detailed logging"
  type        = bool
  default     = false
}

variable "deployment_channel" {
  description = "Slack channel where ArgoCD deployment messages are posted. Accepts channel name with or without '#' prefix (e.g., '#deployments', 'deployments') or channel ID (e.g., 'C43914184')"
  type        = string
}

variable "report_channel" {
  description = "Slack channel where alert investigation reports should be posted. Accepts channel name with or without '#' prefix (e.g., '#reports', 'reports') or channel ID (e.g., 'C43914184')"
  type        = string
}

variable "execution_channel" {
  description = "Slack channel where scheduled tasks are executed from. Accepts channel name with or without '#' prefix (e.g., '#tasks', 'tasks') or channel ID (e.g., 'C43914184')"
  type        = string
}