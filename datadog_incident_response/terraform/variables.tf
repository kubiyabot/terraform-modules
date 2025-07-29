# Datadog Provider Configuration
variable "datadog_api_key" {
  description = "Datadog API Key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application Key"
  type        = string
  sensitive   = true
}

variable "datadog_api_url" {
  description = "Datadog API URL (e.g., https://api.datadoghq.com/ or https://your-org.datadoghq.com/)"
  type        = string
  default     = "https://api.datadoghq.com/"
}

# Core Webhook Configuration
variable "webhook_name" {
  description = "Name for the Datadog webhook"
  type        = string
  default     = "kubiya-incident-response-webhook"
}

variable "region" {
  description = "Deployment region (eu, na, us, etc.)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,3}$", var.region))
    error_message = "Region must be 2-3 lowercase letters (e.g., eu, na, us)."
  }
}

variable "kubiya_webhook_url" {
  description = "Kubiya API webhook URL for workflow execution"
  type        = string
  default     = "https://api.kubiya.ai/api/v1/workflow?runner=gke-integration&operation=execute_workflow"
}

variable "kubiya_api_key" {
  description = "Kubiya API key for authentication (UserKey token). Can be set via KUBIYA_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
  
  validation {
    condition     = var.kubiya_api_key != null && var.kubiya_api_key != ""
    error_message = "Kubiya API key is required. Set it via the kubiya_api_key variable or KUBIYA_API_KEY environment variable."
  }
}

# Workflow Configuration
variable "workflow_name" {
  description = "Name of the incident response workflow"
  type        = string
  default     = "eu-incident-workflow-dag"
}

variable "workflow_description" {
  description = "Description of the incident response workflow"
  type        = string
  default     = "EU Production incident response workflow with AI investigation and Slack integration"
}

# Incident Response Configuration
variable "incident_priority" {
  description = "Default incident priority level"
  type        = string
  default     = "High"
  validation {
    condition     = contains(["Low", "Medium", "High", "Critical"], var.incident_priority)
    error_message = "Incident priority must be one of: Low, Medium, High, Critical."
  }
}

variable "incident_owner" {
  description = "Default incident owner/team"
  type        = string
  default     = "devops"
}

# Slack Integration Configuration
variable "notification_channels" {
  description = "Slack channels for incident notifications"
  type        = string
  default     = "#incident-alerts"
}

variable "escalation_channel" {
  description = "Slack channel for incident escalation"
  type        = string
  default     = "#sre-escalation"
}

# Investigation Configuration
variable "investigation_timeout" {
  description = "Timeout for investigation in seconds"
  type        = string
  default     = "1200"
}

variable "max_retries" {
  description = "Maximum retries for investigation steps"
  type        = string
  default     = "3"
}

# Environment Configuration
variable "dd_environment" {
  description = "Datadog environment identifier"
  type        = string
  default     = "production"
}

variable "k8s_environment" {
  description = "Kubernetes environment identifier"
  type        = string
  default     = "prod-cluster"
}

variable "agent_uuid" {
  description = "Kubiya agent UUID for incident response"
  type        = string
}

# Service Definition Configuration
variable "create_service_definition" {
  description = "Whether to create a Datadog service definition"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Name for the Datadog service definition"
  type        = string
  default     = "kubiya-incident-response"
}

variable "team_name" {
  description = "Team responsible for the incident response service"
  type        = string
  default     = "sre"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "service_contacts" {
  description = "Service contacts for incident response"
  type = list(object({
    name    = string
    type    = string
    contact = string
  }))
  default = [
    {
      name    = "SRE Team"
      type    = "slack"
      contact = "#sre-alerts"
    },
    {
      name    = "On-Call Engineer"
      type    = "email"
      contact = "oncall@example.com"
    }
  ]
}

# Environment Variables for Workflow
variable "default_incident_severity" {
  description = "Default incident severity for environment variables"
  type        = string
  default     = "medium"
  validation {
    condition     = contains(["critical", "high", "medium", "low"], var.default_incident_severity)
    error_message = "Default incident severity must be one of: critical, high, medium, low."
  }
}

variable "default_incident_priority" {
  description = "Default incident priority for environment variables"
  type        = string
  default     = "medium"
  validation {
    condition     = contains(["critical", "high", "medium", "low"], var.default_incident_priority)
    error_message = "Default incident priority must be one of: critical, high, medium, low."
  }
}

# Agent Configuration removed - only using agent_uuid

# Cluster Topology Context
variable "cluster_topology_context" {
  description = "Kubernetes cluster topology context for agent guidance"
  type        = string
  default     = "CLUSTER TOPOLOGY CONTEXT: Production Kubernetes cluster architecture - External Gateway: ingress-nginx namespace (NGINX Ingress Controller), Application Layer: default/app namespaces with microservices, Core Infrastructure: kube-system for DNS/metrics, Observability: monitoring/logging namespaces, Supporting: cert-manager, argocd, kafka. Triage Guidelines: API/Gateway Issues → check ingress-nginx namespace, Application Issues → focus on app namespaces, Infrastructure Issues → DNS in kube-system, certificates in cert-manager, Performance Issues → analyze metrics and ingress latencies. Be proactive with tools, reference actual pod names and metrics, use cluster topology knowledge for intelligent investigation."
}

# Notification Rule Configuration
variable "create_notification_rule" {
  description = "Whether to create a Datadog webhook integration for environment-based incident triggering"
  type        = bool
  default     = true
}

# Additional Configuration
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}