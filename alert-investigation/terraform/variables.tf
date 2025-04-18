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
  description = "List of Slack channels to monitor for Datadog alerts (in #channel format)"
  type        = list(string)
}

variable "feature_flags_channels" {
  description = "List of Slack channels where feature flag changes are logged from Eppo and LaunchDarkly (in #channel format)"
  type        = list(string)
}

variable "lookback_period_hours" {
  description = "Number of hours to look back for feature flag changes"
  type        = number
  default     = 24
}

variable "debug_mode" {
  description = "Enable debug mode for detailed logging"
  type        = bool
  default     = false
}

variable "deployment_channel" {
  description = "Slack channel where ArgoCD deployment messages are posted (in #channel format)"
  type        = string
}

variable "report_channel" {
  description = "Slack channel where alert investigation reports should be posted (in #channel format)"
  type        = string
}

variable "execution_channel" {
  description = "Slack channel where scheduled tasks are executed from (in #channel format)"
  type        = string
}