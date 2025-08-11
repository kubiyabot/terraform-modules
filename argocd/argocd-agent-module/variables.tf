variable "agent_name" {
  type        = string
  description = "Name of the agent"
  default     = "argocd-agent"
}
variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on"
  default     = ""
}
variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "Agent for ArgoCD"
}
variable "agent_ai_instructions" {
  type        = string
  description = "AI instructions for the agent"
  default     = <<EOF
1.You are an intelligent agent able to give the diff between a live argocd app state
and a specified revision using the argocd CLI diff command and sync it when asked using the argocd CLI command.
2.you are an intelligent agent able sync  a live argocd app state and a specified revision using the argocd CLI sync command.
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
    "ARGOCD_PASSWORD",
    "APPROVING_USERS" # Configure this secret on Kubiya web app before deploying the agent.
  ]
}
variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL       = "INFO",
    ARGOCD_SERVER   = "argocd-server.argocd",
    ARGOCD_USERNAME = "admin",
  }
}

variable "agent_integrations" {
  type        = list(string)
  description = "List of integrations to be added to the agent"
  default     = [""]
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
  default     = [""]
}

variable "agent_users" {
  description = "List of users to be added to the agent"
  type        = list(string)
  default     = [""]
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
  default     = "github-argocd-pr-webhook"
}
variable "webhook_source" {
  description = "Source of the webhook - e.g: 'pull request opened on repository foo"
  type        = string
  default     = "Github pull request opened on repository 'deployments'"
}
variable "webhook_prompt" {
  description = "Provide AI instructions prompt for the agent to follow upon incoming webhook."
  type        = string
  default     = "Run argo diff against the following revision: {{.event.pull_request.head.ref}}"
}

variable "webhook_destination" {
  description = "Slack channel for notifications, should start with `#` or `@`."
  type        = string
  default     = "#general"
}

variable "webhook_filter" {
  description = "Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org."
  type        = string
  default     = "pull_request[?state == 'open']"
}

