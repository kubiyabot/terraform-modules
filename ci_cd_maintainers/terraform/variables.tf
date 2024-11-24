# Required Core Configuration
variable "teammate_name" {
  description = <<-EOT
    Name of your CI/CD maintainer teammate. This will be used to identify the teammate in logs, 
    notifications, and webhooks.
    Example: "cicd-crew" or "pipeline-guardian"
  EOT
  type        = string
  default     = "cicd-crew"
}

variable "repositories" {
  description = <<-EOT
    Comma-separated list of repositories to monitor. Must include organization/username.
    Format: 'org/repo1,org/repo2' or 'username/repo1,username/repo2'
    Example: 'mycompany/backend-api,mycompany/frontend-app'
    Note: Ensure you have appropriate permissions for all listed repositories
  EOT
  type        = string
}

variable "notification_channel" {
  description = <<-EOT
    Primary Slack channel for notifications. All alerts will be sent here unless overridden.
    Must include '#' prefix for Slack channels.
    Example: '#cicd-alerts' or '#engineering-pipeline'
    Note: Bot must be invited to this channel to send notifications
  EOT
  type        = string
}

# Authentication (at least one required)
variable "github_token" {
  description = <<-EOT
    GitHub Personal Access Token (PAT) with necessary permissions:
    - repo: Full control of private repositories
    - admin:repo_hook: Full control of repository webhooks
    
    Required when monitoring GitHub repositories.
    Generate at: https://github.com/settings/tokens
    Note: Token should have sufficient permissions for all monitored repositories
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_token" {
  description = <<-EOT
    GitLab Personal Access Token with necessary permissions:
    - api: Read/Write API access
    - read_repository: Read repository access
    - write_repository: Write repository access
    
    Required when monitoring GitLab repositories.
    Generate at: https://gitlab.com/-/profile/personal_access_tokens
    Note: Token should have sufficient permissions for all monitored repositories
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

# Optional Configuration
variable "auto_fix_enabled" {
  description = <<-EOT
    Enable automatic fixing of minor issues. When enabled, the teammate will:
    - Automatically update non-breaking dependencies
    - Fix minor security vulnerabilities
    - Apply standardized fixes to common pipeline issues
    
    Default: false (manual approval required for all changes)
    Recommended: Start with false and enable after reviewing fix patterns
  EOT
  type        = bool
  default     = false
}

variable "pipeline_notification_channel" {
  description = <<-EOT
    Dedicated Slack channel for pipeline-specific notifications:
    - Build failures and successes
    - Performance degradation alerts
    - Pipeline optimization suggestions
    
    Optional: Defaults to notification_channel if not set
    Example: '#pipeline-alerts'
  EOT
  type        = string
  default     = ""
}

variable "security_notification_channel" {
  description = <<-EOT
    Dedicated Slack channel for security-related notifications:
    - Dependency vulnerabilities
    - Security patches needed
    - Access control issues
    - Secret exposure alerts
    
    Optional: Defaults to notification_channel if not set
    Example: '#security-alerts'
    Note: Consider restricting access to this channel
  EOT
  type        = string
  default     = ""
}

variable "scan_interval" {
  description = <<-EOT
    Interval between repository scans for:
    - Security vulnerabilities
    - Outdated dependencies
    - Pipeline performance issues
    
    Format: Time duration (e.g., "30m", "1h", "6h")
    Default: "1h" (hourly scans)
    Note: Shorter intervals increase API usage
  EOT
  type        = string
  default     = "1h"
}

variable "max_concurrent_fixes" {
  description = <<-EOT
    Maximum number of automatic fixes that can be applied simultaneously.
    Prevents overwhelming repositories with too many changes at once.
    
    Default: 3 concurrent fixes
    Recommended: 2-5 based on team size and review capacity
    Note: Only applies when auto_fix_enabled is true
  EOT
  type        = number
  default     = 3
}

# Event Monitoring Configuration
variable "monitor_push_events" {
  description = <<-EOT
    Monitor repository push events to detect:
    - Direct commits to protected branches
    - Large commits that might need review
    - Commit message policy violations
    
    Default: true (recommended for maintaining branch policies)
  EOT
  type        = bool
  default     = true
}

variable "monitor_pull_requests" {
  description = <<-EOT
    Monitor pull request/merge request events for:
    - Code review status
    - CI pipeline results
    - Merge conflicts
    - Automated checks status
    
    Default: true (recommended for maintaining code quality)
  EOT
  type        = bool
  default     = true
}

variable "monitor_pipeline_events" {
  description = <<-EOT
    Monitor CI/CD pipeline events to detect:
    - Build failures
    - Test failures
    - Performance degradation
    - Resource utilization issues
    
    Default: true (recommended for CI/CD health monitoring)
  EOT
  type        = bool
  default     = true
}

# Hidden Configuration (advanced users)
variable "kubiya_runner" {
  description = <<-EOT
    Kubiya runner configuration for executing teammate tasks.
    Default: "default" (standard runner)
    Advanced: Change only if using custom runners
  EOT
  type        = string
  default     = "default"
}

variable "kubiya_groups_allowed_groups" {
  description = <<-EOT
    Groups allowed to interact with the teammate.
    Controls access to teammate commands and configurations.
    Default: ["Admin"] (restricted access)
    Example: ["Admin", "DevOps", "Engineering"]
  EOT
  type        = list(string)
  default     = ["Admin"]
}

variable "webhook_enabled" {
  description = "Enable webhook creation for repositories"
  type        = bool
  default     = true
}

variable "security_scan_enabled" {
  description = "Enable security scanning for repositories"
  type        = bool
  default     = true
}

variable "security_scan_repeat" {
  description = "Interval between security scans"
  type        = string
  default     = "daily"
}

variable "dependency_check_enabled" {
  description = "Enable dependency checking for repositories"
  type        = bool
  default     = true
}

variable "dependency_check_repeat" {
  description = "Interval between dependency checks"
  type        = string
  default     = "daily"
}

variable "webhook_content_type" {
  description = "Content type for webhook notifications"
  type        = string
  default     = "json"
}

variable "pipeline_health_check_enabled" {
  description = "Enable pipeline health check for repositories"
  type        = bool
  default     = true
}

variable "pipeline_health_check_repeat" {
  description = "Interval between pipeline health checks"
  type        = string
  default     = "hourly"
}

variable "monitor_deployment_events" {
  description = "Monitor deployment events for repositories"
  type        = bool
  default     = true
}

variable "monitor_security_events" {
  description = "Monitor security events for repositories"
  type        = bool
  default     = true
}

variable "monitor_issue_events" {
  description = "Monitor issue events for repositories"
  type        = bool
  default     = false
}

variable "monitor_release_events" {
  description = "Monitor release events for repositories"
  type        = bool
  default     = false
}

# Add this new variable
variable "github_enable_oauth" {
  description = <<-EOT
    Enable GitHub OAuth integration with Kubiya.
    When enabled and GitHub token is provided, allows:
    - Direct repository access
    - Enhanced GitHub API capabilities
    - Seamless authentication flow
    
    Default: true (recommended for full GitHub integration)
    Set to false if using token-only access
  EOT
  type        = bool
  default     = true
}
 