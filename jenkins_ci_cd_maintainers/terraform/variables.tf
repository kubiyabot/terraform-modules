# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Jenkins CI/CD maintainer teammate (e.g., 'jenkins-crew' or 'pipeline-guardian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "jenkins-crew"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.teammate_name))
    error_message = "Teammate name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "jenkins_jobs" {
  description = "Comma-separated list of Jenkins jobs to monitor (e.g., 'my-app-build,my-app-deploy,integration-tests'). Leave empty to monitor all jobs."
  type        = string
  default     = ""

  validation {
    condition = var.jenkins_jobs == "" || length(compact(split(",", var.jenkins_jobs))) > 0
    error_message = "If jenkins_jobs is specified, it must contain at least one job name."
  }
}

variable "notification_channel" {
  description = "The channel to send pipeline notifications to. For Slack, use channel name (e.g., '#general'). For Teams, don't use prefix (#)."
  type        = string
  default     = "#jenkins-cicd-maintainers-crew"
}

variable "enable_summary_channel" {
  description = "Whether to enable summary channel notifications. Currently only supported for Slack notifications (not available for MS Teams)."
  type        = bool
  default     = true
}

variable "summary_channel" {
  description = "The channel to send summary notifications to. Slack only, use channel name."
  type        = string
  default     = "#jenkins-cicd-maintainers-crew-summary"
}

# Notification Platform Configuration
variable "ms_teams_notification" {
  description = "Whether to send notifications using MS Teams (if false, notifications will be sent to Slack)."
  type        = bool
  default     = false
}

variable "ms_teams_team_name" {
  description = "If MS Teams is selected, please provide the team name to send notifications to (channel is based on the notification channel variable)."
  type        = string
  default     = "TEAMS"
}

variable "enable_slack_notifications" {
  description = "Enable Slack integration for notifications."
  type        = bool
  default     = true
}

variable "enable_teams_notifications" {
  description = "Enable Microsoft Teams integration for notifications."
  type        = bool
  default     = false
}

# Access Control
variable "kubiya_users" {
  description = "List of users allowed to interact with the teammate (e.g., ['user1@company.com', 'user2@company.com'])."
  type        = list(string)
  default     = []
}

variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string

  validation {
    condition     = var.kubiya_runner != ""
    error_message = "Kubiya runner must be specified."
  }
}

# AI Model Configuration
variable "llm_model" {
  description = "Large Language Model to use for the agent (e.g., 'azure/gpt-4', 'azure/gpt-4-turbo')."
  type        = string
  default     = "azure/gpt-4"

  validation {
    condition = contains([
      "azure/gpt-4",
      "azure/gpt-4-turbo",
      "azure/gpt-35-turbo",
      "openai/gpt-4",
      "openai/gpt-4-turbo-preview"
    ], var.llm_model)
    error_message = "LLM model must be one of the supported models."
  }
}

# Jenkins Webhook Filter Configuration
variable "monitor_failed_builds_only" {
  description = "Only monitor failed builds (if false, will monitor all build results)."
  type        = bool
  default     = true
}

variable "enable_branch_filter" {
  description = "Whether to enable branch filtering for webhook events."
  type        = bool
  default     = false
}

variable "branch_filter" {
  description = "The branch name to filter webhook events on. Only used when enable_branch_filter is true."
  type        = string
  default     = null

  validation {
    condition     = var.branch_filter == null || can(regex("^[a-zA-Z0-9-_.]+$", var.branch_filter))
    error_message = "branch_filter must be either null or a valid branch name containing only alphanumeric characters, hyphens, underscores, and dots."
  }
}

# Advanced Configuration
variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)."
  type        = bool
  default     = false
}

variable "tool_timeout" {
  description = "Timeout in seconds for tool execution."
  type        = number
  default     = 500

  validation {
    condition     = var.tool_timeout > 0 && var.tool_timeout <= 3600
    error_message = "Tool timeout must be between 1 and 3600 seconds."
  }
}

variable "log_level" {
  description = "Log level for the agent (DEBUG, INFO, WARNING, ERROR)."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR."
  }
}

# Feature Flags
variable "enable_detailed_analysis" {
  description = "Enable detailed build analysis including performance metrics and optimization suggestions."
  type        = bool
  default     = true
}

variable "enable_security_scanning" {
  description = "Enable security scanning and vulnerability analysis for builds and pipelines."
  type        = bool
  default     = true
}

variable "enable_performance_metrics" {
  description = "Enable performance metrics collection and analysis for builds."
  type        = bool
  default     = true
}

# Custom Prompt Configuration
variable "custom_webhook_prompt" {
  description = "Custom prompt template for webhook processing. If not provided, the default template will be used."
  type        = string
  default     = null
}
