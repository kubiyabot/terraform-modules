variable "teammate_name" {
  description = "Name of the virtual entity that binds the JIT permissions logic"
  type        = string
  default     = "jit-guardian"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "approvers_slack_channel" {
  description = "Slack channel for approval requests (must start with #)"
  type        = string
  validation {
    condition     = can(regex("^#", var.approvers_slack_channel))
    error_message = "Approvers Slack channel must start with #"
  }
}

variable "kubiya_groups_allowed_groups" {
  description = "Kubiya groups who can request access through the teammate"
  type        = list(string)
  default     = ["Admin"]
}

variable "kubiya_integrations" {
  description = "List of Kubiya integrations to enable. Supports multiple values. \n For AWS integration, the main account must be provided."
  type        = list(string)
  default     = ["slack"]
}

variable "config_json" {
  description = "List of Kubiya integrations to enable. Supports multiple values. \n For AWS integration, the main account must be provided."
  type        = string
  default     = <<-EOT
    {
        "access_configs": {
            "DB Access to Staging": {
                "name": "Database Access to Staging 4",
                "description": "Grants access to all staging RDS databases",
                "account_id": "876809951775",
                "permission_set": "ECRReadOnly",
                "session_duration": "PT5M"
            },
            "Power User to SandBox": {
                "name": "Database Access to SandBox",
                "description": "Grants poweruser permissions on Sandbox",
                "account_id": "110327817829",
                "permission_set": "PowerUserAccess",
                "session_duration": "PT5M"
            }
        },
        "s3_configs": {
            "Data Lake Read Access": {
                "name": "data_lake_read 4",
                "description": "Grants read-only access to data lake buckets",
                "buckets": [
                    "company-data-lake-prod",
                    "company-data-lake-staging"
                ],
                "policy_template": "S3ReadOnlyPolicy",
                "session_duration": "PT1H"
            }
        }
    }
  EOT
}

variable "kubiya_tool_timeout" {
  description = "Timeout for Kubiya tools in seconds, if you have long running tools you may need to increase this"
  type        = number
  default     = 500
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}