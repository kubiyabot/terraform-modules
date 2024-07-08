variable "agent_secrets" {
  type        = list(string)
  description = "List of secrets to be used by the agent"
  default = [""]
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
  default     = "kubiya/base-agent:tools-v4"
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
  type        = list(string)
  description = "List of starters to be added to the agent"
  default     = [""]
}

variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default     = {
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
  default     = ["https://gist.githubusercontent.com/EvgeniyReich/24865746c00a1eaf1a87044465f0ecf1/raw/840d04733a1eb53857d2d4b376c76e8458c21e60/argocd-tool-diff-gist.yaml"
]
}