variable "kubiya_runner" {
  description = "Name of the Kubiya runner to use"
  type        = string
}

variable "notification_slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#databricks-ops"
}

variable "users" {
  description = "List of users who can interact with the engineer"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "List of groups who can interact with the engineer"
  type        = list(string)
  default     = ["Admin"]
}

# Feature Toggles
variable "enable_azure_integration" {
  description = "Enable Azure integration for workspace creation capabilities"
  type        = bool
  default     = false
}

variable "enable_workspace_creation" {
  description = "Enable workspace creation capabilities (requires Azure integration)"
  type        = bool
  default     = false
}

variable "enable_unity_catalog" {
  description = "Enable Unity Catalog management capabilities"
  type        = bool
  default     = true
}

variable "enable_mlflow_tracking" {
  description = "Enable MLflow experiment and model tracking capabilities"
  type        = bool
  default     = true
}

# Knowledge Overrides
variable "prompt_cluster_management" {
  description = "Custom knowledge for cluster management operations"
  type        = string
  default     = null
}

variable "prompt_workspace_management" {
  description = "Custom knowledge for workspace management"
  type        = string
  default     = null
}

variable "prompt_unity_catalog" {
  description = "Custom knowledge for Unity Catalog operations"
  type        = string
  default     = null
}

variable "prompt_mlflow_operations" {
  description = "Custom knowledge for MLflow operations"
  type        = string
  default     = null
}

variable "prompt_job_management" {
  description = "Custom knowledge for job management"
  type        = string
  default     = null
}

variable "prompt_security_management" {
  description = "Custom knowledge for security operations"
  type        = string
  default     = null
}

variable "prompt_cost_optimization" {
  description = "Custom knowledge for cost optimization"
  type        = string
  default     = null
}

variable "prompt_troubleshooting" {
  description = "Custom knowledge for troubleshooting procedures"
  type        = string
  default     = null
}
