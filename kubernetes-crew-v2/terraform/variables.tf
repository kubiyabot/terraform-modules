# Core Configuration
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

variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Watcher Configuration
variable "watch_namespaces" {
  description = "List of Kubernetes namespaces to monitor"
  type        = list(string)
  default     = ["default", "kube-system"]
}

variable "watch_pod" {
  description = "Enable Pod monitoring"
  type        = bool
  default     = true
}

variable "watch_node" {
  description = "Enable Node monitoring"
  type        = bool
  default     = true
}

variable "watch_deployment" {
  description = "Enable Deployment monitoring"
  type        = bool
  default     = true
}

variable "watch_event" {
  description = "Enable Event monitoring"
  type        = bool
  default     = true
}

variable "dedup_interval" {
  description = "Alert deduplication interval (e.g., '10m', '1h')"
  type        = string
  default     = "10m"
}

variable "include_labels" {
  description = "Include Kubernetes labels in alerts"
  type        = bool
  default     = true
}

variable "pod_error_patterns" {
  description = "List of Pod error patterns to watch for"
  type        = list(string)
  default     = ["*BackOff*", "*Error*", "*Failed*"]
}

variable "node_error_patterns" {
  description = "List of Node error patterns to watch for"
  type        = list(string)
  default     = ["*NotReady*", "*Pressure*"]
}

variable "debug_mode" {
  description = "Enable debug mode for detailed logging"
  type        = bool
  default     = false
}

variable "enable_auto_pilot" {
  description = "Enable auto-pilot mode (BETA) - Attempts to automatically diagnose and fix issues without human intervention"
  type        = bool
  default     = false
}