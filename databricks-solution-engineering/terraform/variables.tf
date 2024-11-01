variable "kubiya_runner" {
  description = "🤖 Name of the Kubiya runner that will power your Databricks engineer"
  type        = string
}

variable "notification_slack_channel" {
  description = "📢 Slack channel where your Databricks engineer will send important updates and notifications"
  type        = string
  default     = "#databricks-ops"
}

variable "users" {
  description = "👥 List of specific users who can interact with your Databricks engineer (leave empty to allow all users)"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "🔑 List of groups who can interact with your Databricks engineer (defaults to Admin group)"
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
