variable "agent_secrets" {
  type        = list(string)
  description = "List of secrets to be used by the agent"
  default     = ["ARGOCD_PASSWORD", "APPROVING_USERS", "ARGOCD_SERVER", "ARGOCD_USERNAME"]
}

variable "agent_name" {
  type        = string
  description = "Name of the agent"
  default     = ""
}

variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = ""
}

variable "agent_image" {
  type        = string
  description = "Docker image for the agent"
  default     = "kubiya/base-agent:tools-v5"
}

variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on"
  default     = ""
}

variable "agent_links" {
  type        = list(string)
  description = "List of links to be added to the agent"
  default     = [""]
}

variable "agent_starters" {
  type        = list(object)
  description = "List of starters to be added to the agent"
  default     = []
}

variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL = "INFO"
  }
}

variable "agent_integrations" {
  type        = list(string)
  description = "List of integrations to be added to the agent"
  default     = [""]
}

variable "agent_llm_model" {
  type        = string
  description = "LLM model to be used by the agent"
  default     = "azure/gpt-4"
}

variable "agent_ai_instructions" {
  type        = string
  description = "AI instructions for the agent"
  default     = ""
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

variable "agent_links" {
  description = "List of links to be added to the agent"
  type        = list(string)
  default     = []
}


variable "agent_tasks" {
  description = "List of tasks to be added to the agent"
  type        = list(object)
  default     = []
}

variable "webhook_name" {
  description = "Name of the webhook"
  type        = string
  default     = "tf-webhook-github-argocd"
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

variable "webhook_promhhhpt" {
  description = "Provide AI instructions prompt for the agent to follow upon incoming webhook."
  type        = string
  default     = "Run argo diff against the following revision: {{.event.pull_request.head.ref}}"
}

variable "webhook_destination" {
  description = "Please provide a destination that starts with `#` or `@`."
  type        = string
  default     = "#devops"
}

variable "webhook_filter" {
  description = "Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org."
  type        = string
  default     = "pull_request[?state == 'open']"
}