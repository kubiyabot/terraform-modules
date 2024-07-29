variable "agent_name" {
  type        = string
  description = "Name of the agent"
  default     = "slack-demo-agent"
}

variable "agent_runners" {
  type        = string
  description = "Name of the Local Runners for the agent to be deployed on"
  default     = "slack-approve-runner"
}

variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "Agent for Slack demo"
}

variable "agent_ai_instructions" {
  type        = string
  description = "AI instructions for the agent"
  default     = <<EOF
Execute the commands given by the user on the aws cli.
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
  default     = "ghcr.io/kubiyabot/agent-costa:evgeniyreich"
}

variable "agent_secrets" {
  type        = list(string)
  description = "List of existing secrets to be used by the agent"
  default = [
     # Configure this secret on Kubiya web app before deploying the agent.
  ]
}

variable "agent_environment_variables" {
  type        = map(string)
  description = "Environment variables to be set for the agent"
  default = {
    LOG_LEVEL       = "INFO",
    AWS_PROFILE     = "default",
    AWS_SECRET_ACCESS_KEY = "test",
    AWS_ACCESS_KEY_ID = "test",
    AWS_DEFAULT_REGION = "us-east-1",
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
  default     = [""]
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






