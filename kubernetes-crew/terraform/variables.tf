# Core Configuration
variable "teammate_name" {
  description = "Name of the Kubernetes crew teammate"
  type        = string
}

variable "kubiya_runner" {
  description = "Runner for the teammate"
  type        = string
}

variable "teammate_description" {
  description = "Description of the Kubernetes crew teammate"
  type        = string
  default     = "AI-powered Kubernetes operations assistant"
}

# Access Control
variable "users" {
  description = "List of users who can interact with the teammate"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "List of groups who can interact with the teammate"
  type        = list(string)
  default     = ["Admin"]
}

# Notifications
variable "notification_slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#kubernetes-alerts"
}

variable "log_level" {
  description = "Logging level (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cronjob_start_time" {
  description = "Default start time for cron jobs"
  type        = string
  default     = "09:00"
}

variable "cronjob_repeat_scenario_one" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "daily"
}

variable "cronjob_repeat_scenario_two" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "weekly"
}
variable "cronjob_repeat_scenario_three" {
  description = "Default repeat interval for cron jobs"
  type        = string
  default     = "monthly"
}

# Add this to the existing variables.tf
variable "cluster_type" {
  description = "Type of Kubernetes cluster (EKS, GKE, AKS, or custom)"
  type        = string
  default     = ""
  validation {
    condition     = contains(["EKS", "GKE", "AKS", "custom"], var.cluster_type)
    error_message = "Cluster type must be one of: EKS, GKE, AKS, or custom"
  }
}

################DEFAULT DESCRIPTIONS######################


variable "scheduled_task_health_check_description" {
  description = "Description for the health check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Cluster Health Check

Please perform a comprehensive health check of the Kubernetes cluster:

1. Node Health Assessment:
   - Check node status and conditions
   - Monitor node resource utilization (CPU, Memory, Disk)
   - Verify node readiness and availability

2. Pod Health Verification:
   - Identify pods in CrashLoopBackOff or Error states
   - Check for pods with high restart counts
   - List pods with resource pressure
   - Verify pod scheduling and distribution

3. Workload Status:
   - Check deployment rollout status
   - Verify replicaset health
   - Monitor statefulset status
   - Check daemonset status

4. Resource Utilization:
   - Review resource requests vs limits
   - Check for resource quota violations
   - Monitor namespace resource usage
   - Identify resource constraints

5. Actions:
   - Generate detailed health report
   - Prioritize issues by severity
   - Recommend immediate actions
   - Alert on critical issues
   - Document findings in thread 
EOT
}