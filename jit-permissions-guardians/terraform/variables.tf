variable "teammate_name" {
  description = "Name of the virtual entity that binds the JIT permissions logic"
  type        = string
  default     = "jit-guardian"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "opa_policy" {
  description = "opa policy"
  type        = string
  default     = <<-EOT
    package kubiya.tool_manager

    # Default deny all access
    default allow = false

    # List of admin-only functions and tools
    admin_tools = {
        "list_active_access_requests",
        "search_access_requests",
        "approve_tool_access_request",
        "get_user",
        "search_users",
        "create_group",
        "update_group",
        "delete_group",
        "get_group",
        "list_members",
        "add_member",
        "remove_member",
        "jit_session_revoke_database_access_to_staging",
        "s3_revoke_data_lake_read"
    }

    restricted_tools = {
        "list_users",
        "list_groups",
        "jit_session_grant_database_access_to_staging",
        "s3_grant_data_lake_read"
    }

    # Allow Administrators to run admin tools
    allow {
        group := input.user.groups[_].name
        group == "Admin"
        admin_tools[input.tool.name]
    }

    # Allow Administrators to run revoke tools (s3_revoke_*, jit_session_revoke_*)
    allow {
        group := input.user.groups[_].name
        group == "Admin"
        not restricted_tools[input.tool.name]
    }

    # Allow everyone to run everything except:
    # - admin tools
    # - grant/revoke prefixed tools
    allow {
        not admin_tools[input.tool.name]
        not restricted_tools[input.tool.name]
    }
  EOT
}

variable "approvers_slack_channel" {
  description = "Slack channel for approval requests (must start with #)"
  type        = string
  default     = "#mevrat-devops-oncall"
  validation {
    condition = can(regex("^#", var.approvers_slack_channel))
    error_message = "Approvers Slack channel must start with #"
  }
}

variable "kubiya_groups_allowed_groups" {
  description = "Kubiya groups who can request access through the teammate"
  type = list(string)
  default = ["Admin"]
}

variable "kubiya_integrations" {
  description = "List of Kubiya integrations to enable. Supports multiple values. \n For AWS integration, the main account must be provided."
  type = list(string)
  default = ["slack"]
}

variable "config_json" {
  description = "List of Kubiya integrations to enable. Supports multiple values. For AWS integration, the main account must be provided."
  type        = string
  default     = <<-EOT
    {
        "access_configs": {
            "DB Access to Staging": {
                "name": "Database Access to Staging",
                "description": "Grants access to all staging RDS databases",
                "account_id": "***",
                "permission_set": "ECRReadOnly",
                "session_duration": "PT1H"
            },
            "Power User to SandBox": {
                "name": "Power User Access to SandBox",
                "description": "Grants poweruser permissions on Sandbox",
                "account_id": "****",
                "permission_set": "PowerUserAccess",
                "session_duration": "PT1H"
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

variable "okta_enabled" {
  description = "Enable Okta Integration"
  type        = bool
  default     = false
}

variable "okta_base_url" {
  description = "Your Okta domain URL"
  type        = string
  default     = "https://org.okta.com"
}

variable "okta_client_id" {
  description = "Okta application client ID"
  type        = string
  default     = "Okta application client ID"
}

variable "okta_private_key" {
  description = "Private key for Okta authentication"
  type        = string
  default     = "Private key for Okta authentication"
}

variable "dd_enabled" {
  description = "Enable DataDog Integration"
  type        = bool
  default     = false
}

variable "dd_site" {
  description = "DataDog site"
  type        = string
  default     = "us5.datadoghq.com"
}

variable "dd_api_key" {
  description = "DataDog API key"
  type        = string
  default     = "DataDog API key"
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
