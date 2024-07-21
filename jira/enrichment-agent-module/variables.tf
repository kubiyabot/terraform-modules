variable "agent_name" {
  type        = string
  description = "Name of the agent"
  default     = "jira-enrichment-agent"
}

variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on"
  default     = "aks-dev"
}

variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "Agent for Jira enrichment"
}

variable "agent_ai_instructions" {
  type        = string
  description = "AI instructions for the agent"
  default     = ""
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
    "AUTH0_MANAGEMENT_API_TOKEN",
    "JIRA_AUTH_TOKEN"
  ]
}

variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL       = "INFO",
    AUTH0_DOMAIN = "kubiya-dev.us.auth0.com"
    JIRA_BASE_URL = "api.atlassian.com/ex/jira/bfc30b91-e9ae-4dc7-a21d-e70197efd2db"
    PROJECT = "KFI"
    JIRA_ISSUE_TYPE_NAME = "Issue"
    AF_CUSTOMER = "Kubiya"
    ISSUE_CAT = "Regression"
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
  default     = ["https://raw.githubusercontent.com/kubiyabot/terraform-modules/DEV-948-convert-the-solution-to-tools/jira/jira-tools/jira-enrichment-tool.yaml"]
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
variable "create_webhook" {
  description = "Create a webhook"
  type        = string
  default     = "false"
}

variable "webhook_name" {
  description = "Name of the webhook"
  type        = string
  default     = "jira-enrichment-webhook"
}

variable "webhook_source" {
  description = "Source of the webhook - e.g: 'An issue was created in project  'foo'"
  type        = string
  default     = "An issue was created in Jira project 'Customer issues'"
}

variable "webhook_prompt" {
  description = "Provide AI instructions prompt for the agent to follow upon incoming webhook."
  type        = string
  default     = "pass the following variables to the jira-enrichment-tool: original_issue_key = {{ .event.key}}, summary =  {{ .event.fields.summary}} , description = {{ .event.fields.description}} , display_name = {{ .event.fields.creator.displayName}}"
}

variable "webhook_destination" {
  description = "Slack channel for notifications, should start with `#` or `@`."
  type        = string
  default     = "#devops"
}

variable "webhook_filter" {
  description = "Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org."
  type        = string
  default     = ""
}

