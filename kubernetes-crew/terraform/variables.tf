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

variable "kubiya_groups_allowed_groups" {
  description = "Groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Environment Settings
variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "critical_namespaces" {
  description = "String of critical Kubernetes namespaces"
  type        = string
  default     = "kube-system,kubiya"
}

# Resource Thresholds
variable "cpu_threshold" {
  description = "CPU usage threshold percentage"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory usage threshold percentage"
  type        = number
  default     = 85
}

variable "pod_threshold" {
  description = "Pod count threshold percentage"
  type        = number
  default     = 90
}

# Logging
variable "log_level" {
  description = "Log level for the teammate"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR"
  }
}

# Task Schedule Settings
variable "health_check_enabled" {
  description = "Enable health check task"
  type        = bool
  default     = true
}

variable "health_check_repeat" {
  description = "Health check repeat interval"
  type        = string
  default     = "daily"
}

variable "security_scan_enabled" {
  description = "Enable security scan task"
  type        = bool
  default     = true
}


variable "security_scan_repeat" {
  description = "Security scan repeat interval"
  type        = string
  default     = "weekly"
}

# Feature Flags
variable "enable_auto_remediation" {
  description = "Enable automatic remediation"
  type        = bool
  default     = false
}

variable "enable_cost_reporting" {
  description = "Enable cost reporting"
  type        = bool
  default     = true
}

variable "enable_drift_detection" {
  description = "Enable configuration drift detection"
  type        = bool
  default     = true
}

# Resource Check Task Settings
variable "resource_check_enabled" {
  description = "Enable resource check task"
  type        = bool
  default     = true
}

variable "resource_check_repeat" {
  description = "Resource check repeat interval"
  type        = string
  default     = "daily"
}

# Backup Verification Task Settings
variable "backup_verify_enabled" {
  description = "Enable backup verification task"
  type        = bool
  default     = true
}

variable "backup_verify_repeat" {
  description = "Backup verification repeat interval"
  type        = string
  default     = "daily"
}

# Compliance Audit Task Settings
variable "compliance_audit_enabled" {
  description = "Enable compliance audit task"
  type        = bool
  default     = true
}


variable "compliance_audit_repeat" {
  description = "Compliance audit repeat interval"
  type        = string
  default     = "weekly"
}

# Network Check Task Settings
variable "network_check_enabled" {
  description = "Enable network check task"
  type        = bool
  default     = true
}

variable "network_check_repeat" {
  description = "Network check repeat interval"
  type        = string
  default     = "daily"
}

# Scaling Analysis Task Settings
variable "scaling_analysis_enabled" {
  description = "Enable scaling analysis task"
  type        = bool
  default     = true
}

variable "scaling_analysis_repeat" {
  description = "Scaling analysis repeat interval"
  type        = string
  default     = "daily"
}
