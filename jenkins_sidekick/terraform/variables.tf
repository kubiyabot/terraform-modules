# 🔌 Jenkins Configuration
variable "jenkins_url" {
  description = "🌐 Jenkins server URL (e.g., http://jenkins.example.com:8080)"
  type        = string

  validation {
    condition     = can(regex("^(http|https)://", var.jenkins_url))
    error_message = "🚫 Jenkins URL must start with http:// or https://"
  }
}

variable "jenkins_username" {
  description = "👤 Jenkins admin username for API access"
  type        = string
  default     = "admin"
}

variable "jenkins_token_name" {
  description = "🗝️ Name of the Kubiya secret to store the Jenkins token"
  type        = string
  default     = "jenkins-api-token"
}

variable "jenkins_token_secret" {
  description = "🔑 Jenkins API token for authentication (sensitive)"
  type        = string
  sensitive   = true
}



# 🎯 Job Configuration
variable "sync_all_jobs" {
  description = "🔄 Whether to sync all available Jenkins jobs (true) or use include list (false)"
  type        = bool
  default     = true
}

variable "include_jobs" {
  description = "📋 List of specific Jenkins jobs to include (only used if sync_all_jobs is false)"
  type        = list(string)
  default     = []
}

variable "exclude_jobs" {
  description = "🚫 List of Jenkins jobs to exclude (applied even if sync_all_jobs is true)"
  type        = list(string)
  default     = []
}

# ⚙️ Execution Settings
variable "stream_logs" {
  description = "📝 Enable real-time log streaming for job execution"
  type        = bool
  default     = true
}

variable "poll_interval" {
  description = "⏱️ Job status polling interval in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.poll_interval >= 10 && var.poll_interval <= 300
    error_message = "🚫 Poll interval must be between 10 and 300 seconds"
  }
}

variable "long_running_threshold" {
  description = "⏳ Threshold in seconds after which a job is considered long-running"
  type        = number
  default     = 300

  validation {
    condition     = var.long_running_threshold >= 60
    error_message = "🚫 Long running threshold must be at least 60 seconds"
  }
}

# 🤖 Assistant Configuration
variable "name" {
  description = "🏷️ Name for your Jenkins conversational proxy"
  type        = string
  default     = "jenkins-proxy"
}

variable "kubiya_runner" {
  description = "🏃 Infrastructure runner that will execute the Jenkins operations"
  type        = string
  default     = "kubiya-hosted"
}

variable "kubiya_integrations" {
  description = "🔗 Where should your Jenkins proxy be available?"
  type        = list(string)
  default     = ["slack"]
}

variable "kubiya_groups_allowed_groups" {
  description = "🔒 Which groups should have access to the Jenkins proxy?"
  type        = list(string)
  default     = ["Admin"]
} 