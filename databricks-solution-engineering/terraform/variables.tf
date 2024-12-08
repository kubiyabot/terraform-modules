variable "kubiya_runner" {
  description = "🤖 Name of the Kubiya runner that will power your Databricks engineer"
  type        = string
}

variable "notification_slack_channel" {
  description = "📢 Slack channel where your Databricks engineer will send important updates and notifications"
  type        = string
  default     = "#databricks-ops"
}

variable "kubiya_users" {
  description = "👥 Users who can interact with the teammate"
  type        = list(string)
}

variable "kubiya_groups" {
  description = "👥 Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Feature Toggles
variable "enable_azure_integration" {
  description = "☁️ Enable Azure integration for workspace creation and management capabilities"
  type        = bool
  default     = false
}

variable "enable_workspace_creation" {
  description = "🏗️ Enable workspace creation capabilities (requires Azure integration to be enabled)"
  type        = bool
  default     = false
}

variable "enable_unity_catalog" {
  description = "📚 Enable Unity Catalog management capabilities for data governance and discovery"
  type        = bool
  default     = true
}

variable "enable_mlflow_tracking" {
  description = "🔬 Enable MLflow experiment and model tracking capabilities for ML workflows"
  type        = bool
  default     = true
}

# Knowledge Content Overrides
variable "prompt_cluster_management" {
  description = "💻 Custom knowledge for cluster management operations (leave empty to use default knowledge base)"
  type        = string
  default     = ""
}

variable "prompt_workspace_management" {
  description = "🏢 Custom knowledge for workspace management operations (leave empty to use default knowledge base)"
  type        = string
  default     = ""
}

variable "prompt_unity_catalog" {
  description = "📊 Custom knowledge for Unity Catalog operations (leave empty to use default knowledge base)"
  type        = string
  default     = ""
}

variable "prompt_mlflow_operations" {
  description = "🧪 Custom knowledge for MLflow operations and experiment tracking (leave empty to use default knowledge base)"
  type        = string
  default     = ""
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
} 