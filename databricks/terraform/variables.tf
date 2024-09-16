variable "agent_name" {
  type        = string
  description = "Name of the agent."
  default     = "databricks-tf-agent"
}
variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on."
  default     = "runnerv2-5-vcluster"
}
variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "use the tools to apply a terraform module to the specified provider."
}

variable "agent_llm_model" {
  type        = string
  description = "LLM model to be used by the agent."
  default     = "azure/gpt-4o"
}

variable "agent_secrets" {
  type        = list(string)
  description = "List of existing secrets to be used by the agent."
  default = [
    # "ARM_CLIENT_ID",     # Configure this secret on Kubiya web app before deploying the agent.
    # "ARM_CLIENT_SECRET",
    # "ARM_SUBSCRIPTION_ID",
    # "ARM_TENANT_ID",
    # "DB_ACCOUNT_CLIENT_ID",
    # "DB_ACCOUNT_CLIENT_SECRET",
    # "DB_ACCOUNT_ID",
    # "PAT",
    # "AWS_ACCESS_KEY_ID",
    # "AWS_SECRET_ACCESS_KEY",
    # "AWS_DEFAULT_REGION",
    # "SLACK_CHANNEL_ID",
    # "SLACK_THREAD_TS",  
    # "SLACK_API_TOKEN"

  ]
}
variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL       = "INFO",
    BRANCH          = "POC-23-adding-backend",
    DIR             = "~/test",
    GIT_REPO        = "deployments",
    GIT_ORG         = "kubiyabot",
    KUBIYA_TOOL_TIMEOUT = "20m",
  }
}

variable "agent_integrations" {
  type        = list(string)
  description = "List of integrations to be added to the agent"
  default     = ["slack"]
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
  description = "List of tasks to be added to the agent."
  type        = list(any)
  default     = []
}
variable "agent_tool_sources" {
  description = "Sources (can be URLs such as GitHub repositories or gist URLs) for the tools accessed by the agent."
  type        = list(string)
  default     = ["databricks-azure-apply"]
}

variable "agent_users" {
  description = "List of users to be added to the agent."
  type        = list(string)
  default     = []
}
variable "agent_groups" {
  description = "List of groups to be added to the agent."
  type        = list(string)
  default     = ["Admin"]
}
