# Core Configuration
variable "teammate_name" {
  description = "Name of the Kubernetes crew teammate"
  type        = string
  default     = "k8s-crew"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

# Notification Settings
variable "notification_channel" {
  description = "Primary Slack channel for notifications"
  type        = string
  default     = "#devops-oncall"
}

variable "security_channel" {
  description = "Slack channel for security alerts"
  type        = string
  default     = "#security-alerts"
}

variable "compliance_channel" {
  description = "Slack channel for compliance reports"
  type        = string
  default     = "#compliance"
}

# Access Control
variable "allowed_users" {
  description = "Users who can interact with the teammate"
  type        = list(string)
  default     = []
}

variable "allowed_groups" {
  description = "Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Schedule Configuration
variable "task_schedules" {
  description = "Schedule configuration for tasks"
  type = object({
    health_check = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    security_scan = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    resource_check = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    backup_verify = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    compliance_audit = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    network_check = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
    scaling_analysis = object({
      enabled    = bool
      start_time = string
      repeat     = string
    })
  })
  default = {
    health_check = {
      enabled    = true
      start_time = "2024-01-01T08:00:00"
      repeat     = "daily"
    }
    security_scan = {
      enabled    = true
      start_time = "2024-01-01T09:00:00"
      repeat     = "weekly"
    }
    resource_check = {
      enabled    = true
      start_time = "2024-01-01T10:00:00"
      repeat     = "daily"
    }
    backup_verify = {
      enabled    = true
      start_time = "2024-01-01T00:00:00"
      repeat     = "daily"
    }
    compliance_audit = {
      enabled    = true
      start_time = "2024-01-01T10:00:00"
      repeat     = "monthly"
    }
    network_check = {
      enabled    = true
      start_time = "2024-01-01T12:00:00"
      repeat     = "daily"
    }
    scaling_analysis = {
      enabled    = true
      start_time = "2024-01-01T06:00:00"
      repeat     = "daily"
    }
  }
}

# Cluster-Specific Knowledge
variable "cluster_context" {
  description = "Additional context about the cluster for the crew"
  type = object({
    environment         = string
    critical_namespaces = string
    resource_thresholds = object({
      cpu_threshold     = number
      memory_threshold  = number
      pod_threshold     = number
      storage_threshold = number
    })
    backup_config = object({
      backup_schedule = string
      retention_days  = number
      critical_apps   = list(string)
    })
    monitoring_config = object({
      alert_threshold_minutes = number
      log_retention_days      = number
    })
    scaling_config = object({
      min_replicas = number
      max_replicas = number
      cpu_target   = number
    })
  })
  default = {
    environment         = "production"
    critical_namespaces = "kube-system,kubiya"
    resource_thresholds = {
      cpu_threshold     = 80
      memory_threshold  = 85
      pod_threshold     = 90
      storage_threshold = 75
    }
    backup_config = {
      backup_schedule = "0 1 * * *"
      retention_days  = 30
      critical_apps   = ["database", "api", "auth-service"]
    }
    monitoring_config = {
      alert_threshold_minutes = 15
      log_retention_days      = 14
    }
    scaling_config = {
      min_replicas = 2
      max_replicas = 10
      cpu_target   = 70
    }
  }
}

# Logging Configuration
variable "log_level" {
  description = "Log level for the teammate"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR"
  }
}

# Feature Flags
variable "features" {
  description = "Feature flags for additional functionality"
  type = object({
    enable_auto_remediation = bool
    enable_cost_reporting   = bool
    enable_drift_detection  = bool
  })
  default = {
    enable_auto_remediation = false
    enable_cost_reporting   = true
    enable_drift_detection  = true
  }
}
