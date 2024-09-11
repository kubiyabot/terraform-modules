variable "teammate_name" {
  description = "Name of the Kubernetes Sidekick teammate"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "teammate_description" {
  description = "Description of the Kubernetes Sidekick teammate"
  type        = string
}

variable "use_custom_kubeconfig" {
  description = "Whether to use a custom kubeconfig - only relevant if use_in_cluster_context is false"
  type        = bool
  default     = false
}

variable "custom_kubeconfig" {
  description = "Custom kubeconfig as a string (only if use_custom_kubeconfig is relevant)"
  type        = string
  default     = ""
}

variable "use_in_cluster_context" {
  description = "Whether to use in-cluster context"
  type        = bool
  default     = true
}

variable "enable_cluster_health_monitoring" {
  description = "Enable cluster health monitoring"
  type        = bool
  default     = true
}

variable "cluster_health_check_interval" {
  description = "Interval for cluster health checks"
  type        = string
  default     = "1h"
}

variable "enable_intelligent_event_scraping" {
  description = "Enable intelligent event scraping"
  type        = bool
  default     = true
}

variable "enable_kubectl_access" {
  description = "Enable kubectl access"
  type        = bool
  default     = true
}

variable "enable_helm_chart_application" {
  description = "Enable applying Helm charts"
  type        = bool
  default     = false
}

variable "enable_argo_cd_integration" {
  description = "Enable Argo CD integration"
  type        = bool
  default     = false
}

variable "notification_slack_channel" {
  description = "In case we want to send notifications to a slack channel, which channel to use (optional)"
  type        = string
  default     = "#k8s-notifications"
}

variable "users" {
  description = "Explicit list of users who can interact with the teammate by default"
  type        = list(string)
}

variable "groups" {
  description = "Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "integrations" {
  description = "Which integrations to enable on the teammate (usually kubernetes and slack)"
  type        = list(string)
  default     = ["kubernetes", "slack"]
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "INFO"
}

variable "debug" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

variable "dry_run" {
  description = "Enable dry run mode"
  type        = bool
  default     = false
}
