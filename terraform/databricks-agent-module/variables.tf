variable "agent_name" {
  type        = string
  description = "Name of the agent"
  default     = "databricks-tf-agent"
}
variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on"
  default     = "classicv1"
}
variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "Uses the terraform-azure-apply-tool tool to apply a terraform module to azure."
}
variable "agent_ai_instructions" {
  type        = string
  description = "AI instructions for the agent"
  default     = <<EOF
  Use the tool terraform-apply-tool to apply the terraform module.
EOF
}
variable "agent_llm_model" {
  type        = string
  description = "LLM model to be used by the agent"
  default     = "azure/gpt-4"
}
variable "agent_image" {
  type        = string
  description = "Docker image for the agent"
  default     = "kubiya/base-agent:tools-v6"
}
variable "agent_secrets" {
  type        = list(string)
  description = "List of existing secrets to be used by the agent"
  default = [
    "ARM_CLIENT_ID",     # Configure this secret on Kubiya web app before deploying the agent.
    "ARM_CLIENT_SECRET",
    "ARM_SUBSCRIPTION_ID",
    "ARM_TENANT_ID",
    "DB_ACCOUNT_CLIENT_ID",
    "DB_ACCOUNT_CLIENT_SECRET",
    "DB_ACCOUNT_ID",
    "PAT",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "AWS_DEFAULT_REGION",
  ]
}
variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL       = "INFO",
    BRANCH          = "POC-15-task-build-the-scneario",
    DIR             = "~/test",
    GIT_REPO        = "deployments",
    GIT_ORG         = "kubiyabot",
    KUBIYA_TOOL_TIMEOUT = "10m",
  }
}

variable "agent_integrations" {
  type        = list(string)
  description = "List of integrations to be added to the agent"
  default     = []
}
variable "agent_links" {
  description = "List of links to be added to the agent"
  type        = list(any)
  default     = []
}
variable "agent_starters" {
  type        = list(any)
  description = "List of starters to be added to the agent"
  default     = []
}
variable "agent_tasks" {
  description = "List of tasks to be added to the agent"
  type        = list(any)
  default     = []
}
variable "agent_tool_sources" {
  description = "Sources (can be URLs such as GitHub repositories or gist URLs) for the tools accessed by the agent"
  type        = list(string)
  default     = ["https://raw.githubusercontent.com/kubiyabot/terraform-modules/POC-22-create-a-terraform-for-the-agent/terraform/terraform-tools-databricks/terraform-apply-tool.yaml"]
}

variable "agent_users" {
  description = "List of users to be added to the agent"
  type        = list(string)
  default     = []
}
variable "agent_groups" {
  description = "List of groups to be added to the agent"
  type        = list(string)
  default     = ["Admin"]
}
################# Webhook Variables #################
# variable "create_webhook" {
#   description = "Create a webhook"
#   type        = string
#   default     = "false"
# }
# variable "webhook_name" {
#   description = "Name of the webhook"
#   type        = string
#   default     = "github-argocd-pr-webhook"
# }
# variable "webhook_source" {
#   description = "Source of the webhook - e.g: 'pull request opened on repository foo"
#   type        = string
#   default     = "Github pull request opened on repository 'deployments'"
# }
# variable "webhook_prompt" {
#   description = "Provide AI instructions prompt for the agent to follow upon incoming webhook."
#   type        = string
#   default     = "Run argo diff against the following revision: {{.event.pull_request.head.ref}}"
# }

# variable "webhook_destination" {
#   description = "Slack channel for notifications, should start with `#` or `@`."
#   type        = string
#   default     = "#general"
# }

# variable "webhook_filter" {
#   description = "Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org."
#   type        = string
#   default     = "pull_request[?state == 'open']"
# }

