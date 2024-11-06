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
variable "kubiya_users" {
  description = "List of users who can interact with the teammate"
  type        = list(string)
  default     = []
}

variable "kubiya_groups" {
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
  default     = "2024-11-05T08:00:00"
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

variable "enable_resource_check_task" {
  description = "📊 Enable scheduled resource optimization task"
  type        = bool
  default     = true
}

// Scheduled Tasks Configuration
variable "enable_health_check_task" {
  description = "🏥 Enable scheduled health check task"
  type        = bool
  default     = true
}

variable "enable_cleanup_task" {
  description = "🧹 Enable scheduled cleanup task"
  type        = bool
  default     = true
}

variable "enable_network_check_task" {
  description = "🌐 Enable scheduled network check task"
  type        = bool
  default     = true
}

variable "enable_security_check_task" {
  description = "🔒 Enable scheduled security check task"
  type        = bool
  default     = true
}

variable "enable_backup_check_task" {
  description = "💾 Enable scheduled backup verification task"
  type        = bool
  default     = true
}

variable "enable_cost_analysis_task" {
  description = "💰 Enable scheduled cost analysis task"
  type        = bool
  default     = true
}

variable "enable_compliance_check_task" {
  description = "✅ Enable scheduled compliance check task"
  type        = bool
  default     = true
}

variable "enable_update_check_task" {
  description = "🔄 Enable scheduled update check task"
  type        = bool
  default     = true
}

variable "enable_capacity_check_task" {
  description = "📈 Enable scheduled capacity planning task"
  type        = bool
  default     = true
}

variable "enable_upgrade_check_task" {
  description = "🚀 Enable upgrade check monitoring task"
  type        = bool
  default     = true
}


################DEFAULT DESCRIPTIONS######################
variable "scheduled_task_description_health_check" {
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

variable "scheduled_task_description_resource_check" {
  description = "Description for the resource optimization task"
  type        = string
  default     = <<-EOT
  # Kubernetes Resource Optimization Check

Please perform a comprehensive resource analysis:

1. Resource Usage Analysis:
   - CPU utilization patterns
   - Memory consumption trends
   - Storage usage metrics
   - Network bandwidth utilization
   - Pod resource requests vs limits

2. Efficiency Assessment:
   - Identify resource bottlenecks
   - Check for over-provisioned resources
   - Analyze resource quotas
   - Review QoS classes
   - Monitor resource constraints

3. Cost Optimization:
   - Identify idle resources
   - Review pod scheduling efficiency
   - Check for unused PVCs
   - Analyze node utilization
   - Review namespace quotas

4. Performance Impact:
   - Application response times
   - Pod startup latency
   - Resource contention issues
   - Throttling incidents
   - OOMKill events

5. Recommendations:
   - Resource right-sizing suggestions
   - Quota adjustment proposals
   - Scaling recommendations
   - Cost optimization strategies
   - Performance improvement tips
EOT 
}

variable "scheduled_task_description_cleanup" {
  description = "Description for the cleanup task"
  type        = string
  default     = <<-EOT
  # Kubernetes Cluster Cleanup Task

Please perform a comprehensive cleanup analysis:

1. Resource Identification:
   - Unused deployments
   - Orphaned PVCs
   - Terminated pods
   - Unused configmaps/secrets
   - Stale namespaces

2. Image Cleanup:
   - Unused images
   - Old image versions
   - Dangling images
   - Image pull policies
   - Registry cleanup

3. Network Resources:
   - Unused services
   - Stale endpoints
   - Obsolete network policies
   - Unused ingress rules
   - Orphaned load balancers

4. Configuration Cleanup:
   - Outdated configs
   - Unused secrets
   - Stale RBAC rules
   - Deprecated API objects
   - Old custom resources

5. Action Plan:
   - Prioritized cleanup list
   - Resource recovery estimates
   - Backup recommendations
   - Execution timeline
   - Validation steps 
EOT
}

variable "scheduled_task_description_network_check" {
  description = "Description for the network check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Network Health Assessment

Please perform a comprehensive network analysis:

1. Connectivity Check:
   - Pod-to-pod communication
   - Service accessibility
   - Ingress/egress traffic
   - DNS resolution
   - Load balancer health

2. Network Policy Audit:
   - Policy enforcement status
   - Rule effectiveness
   - Coverage gaps
   - Default policies
   - Isolation compliance

3. Performance Analysis:
   - Network latency
   - Bandwidth utilization
   - Connection timeouts
   - Packet loss
   - TCP retransmissions

4. Security Assessment:
   - Exposed services
   - Network policy compliance
   - TLS configuration
   - Certificate validation
   - Port security

5. Recommendations:
   - Policy updates
   - Performance improvements
   - Security enhancements
   - Architecture changes
   - Monitoring suggestions 
EOT
}

variable "scheduled_task_description_security_check" {
  description = "Description for the security check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Security Assessment

Please perform a comprehensive security audit:

1. Access Control Review:
   - RBAC configuration
   - Service account usage
   - Pod security policies
   - Network policies
   - Admission controllers

2. Workload Security:
   - Container security context
   - Image vulnerabilities
   - Runtime security
   - Privileged containers
   - Resource isolation

3. Network Security:
   - Network policy enforcement
   - TLS configuration
   - API server access
   - Ingress/egress rules
   - Service mesh security

4. Data Protection:
   - Secret management
   - Storage encryption
   - Backup security
   - PV/PVC security
   - Data access controls

5. Compliance Check:
   - CIS benchmark status
   - Security best practices
   - Compliance violations
   - Audit logging
   - Security patches
EOT

}

variable "scheduled_task_description_backup_check" {
  description = "Description for the backup verification task"
  type        = string
  default     = <<-EOT
  # Kubernetes Backup Verification

Please perform a comprehensive backup assessment:

1. Backup Status:
   - Backup completion status
   - Backup integrity
   - Storage consumption
   - Retention compliance
   - Schedule adherence

2. Coverage Analysis:
   - Critical workloads
   - Persistent volumes
   - Configuration data
   - Custom resources
   - Cluster state

3. Recovery Testing:
   - Restore procedures
   - Recovery time objectives
   - Data consistency
   - Application integrity
   - Service continuity

4. Compliance Verification:
   - Retention policies
   - Security requirements
   - Encryption status
   - Access controls
   - Audit trails

5. Recommendations:
   - Process improvements
   - Coverage gaps
   - Tool updates
   - Policy adjustments
  ing schedule 
EOT
}

variable "scheduled_task_description_cost_analysis" {
  description = "Description for the cost analysis task"
  type        = string
  default     = <<-EOT
  # Kubernetes Cost Analysis

Please perform a comprehensive cost assessment:

1. Resource Cost Analysis:
   - Compute costs
   - Storage expenses
   - Network charges
   - License fees
   - Support costs

2. Usage Patterns:
   - Peak usage times
   - Resource efficiency
   - Idle resources
   - Scaling patterns
   - Waste identification

3. Optimization Opportunities:
   - Resource right-sizing
   - Reservation options
   - Spot instance usage
   - Storage optimization
   - License optimization

4. Cost Attribution:
   - Namespace costs
   - Team allocation
   - Project expenses
   - Service costs
   - Environment costs

5. Recommendations:
   - Cost reduction strategies
   - Resource optimization
   - Architecture changes
   - Policy updates
   - Budget planning
EOT
}

variable "scheduled_task_description_compliance_check" {
  description = "Description for the compliance check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Compliance Assessment

Please perform a comprehensive compliance check:

1. Security Standards:
   - CIS benchmark compliance
   - SOC 2 requirements
   - PCI DSS controls
   - HIPAA guidelines
   - ISO 27001 controls

2. Configuration Audit:
   - RBAC compliance
   - Network policies
   - Pod security standards
   - Secret management
   - Encryption status

3. Operational Compliance:
   - Change management
   - Incident response
   - Backup procedures
   - Disaster recovery
   - Access controls

4. Documentation Review:
   - Policy documentation
   - Procedure guides
   - Audit trails
   - Training materials
   - Incident records

5. Recommendations:
   - Compliance gaps
   - Required actions
   - Policy updates
   - Control improvements
   - Documentation needs 
EOT
}

variable "scheduled_task_description_update_check" {
  description = "Description for the update check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Update Assessment

Please perform a comprehensive update analysis:

1. Version Analysis:
   - Component versions
   - Dependency status
   - API compatibility
   - Feature requirements
   - Security patches

2. Impact Assessment:
   - Breaking changes
   - Deprecated features
   - Performance impact
   - Security implications
   - Downtime requirements

3. Update Prerequisites:
   - Resource requirements
   - Backup status
  ing environment
   - Rollback plan
   - Documentation needs

4. Update Strategy:
   - Update sequence
  ing approach
   - Validation steps
   - Rollback procedures
   - Communication plan

5. Recommendations:
   - Update priority
   - Risk mitigation
   - Resource allocation
   - Timeline proposal
   - Success criteria 
EOT
}

variable "scheduled_task_description_capacity_check" {
  description = "Description for the capacity planning task"
  type        = string
  default     = <<-EOT
  # Kubernetes Capacity Planning Analysis

Perform a comprehensive capacity analysis:

1. Current Resource Usage:
   - Analyze cluster-wide CPU and memory usage trends
   - Review storage utilization across all PVs
   - Check network bandwidth consumption
   - Monitor node capacity limits

2. Growth Patterns:
   - Analyze historical resource usage trends
   - Identify peak usage patterns
   - Calculate growth rates per namespace
   - Project future resource needs

3. Optimization Opportunities:
   - Identify underutilized resources
   - Review resource request vs actual usage
   - Check for oversized deployments
   - Analyze scaling patterns

4. Recommendations:
   - Suggest cluster scaling needs
   - Recommend resource quota adjustments
   - Propose optimization strategies
   - Outline capacity expansion timeline

5. Report Generation:
   - Create capacity planning report
   - Include growth projections
   - List recommended actions
   - Highlight critical capacity concerns 
EOT
}

variable "scheduled_task_description_upgrade_check" {
  description = "Description for the upgrade check task"
  type        = string
  default     = <<-EOT
  # Kubernetes Cluster Upgrade Assessment

Please perform a comprehensive upgrade readiness check:

1. Version Analysis:
   - Current cluster version
   - Target version compatibility
   - Component version matrix
   - API deprecation impact

2. Workload Assessment:
   - API version usage
   - Custom resource definitions
   - Storage version compatibility
   - Network policy compatibility

3. Resource Requirements:
   - Node capacity planning
   - Downtime estimation
   - Rollback requirements
   - Backup verification

4. Pre-upgrade Tasks:
   - Backup critical components
   - Update manifests
   environment validation
   - Document rollback procedure

5. Upgrade Strategy:
   - Control plane upgrade steps
   - Worker node upgrade order
   - Workload migration plan
   - Monitoring requirements 
EOT
}

variable "scheduled_task_description_scaling_check" {
   description = "Description for the scaling check task"
   type        = string
   default     = <<-EOT
   # Application Scaling Assessment

Please perform a comprehensive scaling analysis:

1. Current State Assessment:
   - Pod resource utilization
   - HPA configuration
   - Service metrics
   - Load patterns

2. Scaling Requirements:
   - Peak load analysis
   - Resource headroom
   - Performance targets
   - Cost constraints

3. Scaling Strategy:
   - Horizontal vs Vertical
   - Custom metrics
   - Scaling thresholds
   - Buffer capacity

4. Implementation Plan:
   - HPA configuration
   - Resource adjustments
   - Service updates
   - Monitoring setup

5. Validation:
   - Load testing
   - Metric verification
   - Alert configuration
   - Performance checks 
EOT
}