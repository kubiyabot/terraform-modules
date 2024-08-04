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
    "ARM_CLIENT_ID_KUBI",     # Configure this secret on Kubiya web app before deploying the agent.
    "ARM_CLIENT_SECRET_KUBI",
    "ARM_SUBSCRIPTION_ID_KUBI",
    "ARM_TENANT_ID_KUBI",
    "DB_ACCOUNT_CLIENT_ID",
    "DB_ACCOUNT_CLIENT_SECRET",
    "DB_ACCOUNT_ID",
    "PAT",
    "AWS_ACCESS_KEY_ID_KUBI",
    "AWS_SECRET_ACCESS_KEY_KUBI",
    "AWS_DEFAULT_REGION_KUBI",
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
  default     = ["https://raw.githubusercontent.com/kubiyabot/terraform-modules/POC-22-conditional-one-tool/databricks/kubiya/tools/terraform-apply-tool.yaml"]
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
