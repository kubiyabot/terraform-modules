<!-- # create a readme in MD format with example of how to use the module:  module "kubiya_module" {
  # source = "git@github.com:kubiyabot/terraform-modules.git//argocd/argocd-agent-module?ref=DEV-949-akamai-argocd-github-use-case"
  source = "/Users/costa/Documents/kubiya/terraform-modules/argocd/argocd-agent-module/"

  agent_name          = "argocd-agent-test"
  create_webhook      = "true"
  webhook_destination = "#devops"
}
 -->

# argocd-agent-module

## Usage

```hcl
module "argocd_agent" {
  source = "git@github.com:kubiyabot/terraform-modules.git//argocd/argocd-agent-module"
  agent_name          = "argocd-agent-test"
  create_webhook      = "true"
  webhook_destination = "#devops"
}
```

<!-- note that the followong secrets should be created before  running terraform: APPROVING_USERS ARGOCD_PASSWORD 
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
  default     = "kubiya/base-agent:tools-v5"
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


-->

## Inputs

| Name                | Description                                                                 | Type   | Default | Required |
|---------------------|-----------------------------------------------------------------------------|--------|---------|----------|
| agent_runners       | Name of the Local Runners for the agent to be deployed on. REQUIRED!                   | string |  ""     | yes       |
| agent_name          | The name of the argocd agent to be created                                  | string |argocd-agent| no      |
| create_webhook      | Whether to create a webhook or not                                         | string |false| no      |
| webhook_destination | The destination of the webhook                                              | string |#general| no      |
| agent_description   | Description of the agent                                                   | string |Agent for ArgoCD| no       |
| agent_ai_instructions | AI instructions for the agent                                             | string |1. You are an intelligent agent able to give the diff between a live argocd app state and a specified revision using the argocd CLI diff command and sync it when asked using the argocd CLI command <br>  2. you are an intelligent agent able sync  a live argocd app state and a specified revision using the argocd CLI sync command.
| no       |
| agent_llm_model     | LLM model to be used by the agent                                          | string |azure/gpt-4| no       |
| agent_image         | Docker image for the agent                                                  | string |kubiya/base-agent:tools-v5| no       |
| agent_secrets       | List of **existing** secrets to be used by the agent                           | list(string) | ARGOCD_PASSWORD, APPROVING_USERS | yes       |
| agent_environment_variables | Environment variables to be set for the agent                      | map(string) |LOG_LEVEL,ARGOCD_SERVER,ARGOCD_USERNAME| yes       |
| agent_integrations  | List of integrations to be added to the agent                              | list(string) |   [""]    | no       |
| agent_links         | List of links to be added to the agent                                      | list(any) |[]| no       |
| agent_starters      | List of starters to be added to the agent                                   | list(any) |[]| no       |
| agent_tasks         | List of tasks to be added to the agent                                      | list(any) |  []   | no       |
| agent_tool_sources  | Sources (can be URLs such as GitHub repositories or gist URLs) for the tools accessed by the agent | list(string) |[""]| no       |
| agent_users         | List of users to be added to the agent                                      | list(string) |""| no       |
| agent_groups        | List of groups to be added to the agent                                     | list(string) |Admin| yes       |
| webhook_name        | Name of the webhook                                                         | string |github-argocd-pr-webhook| no       |
| webhook_source      | Source of the webhook - e.g: 'pull request opened on repository foo         | string |Github pull request opened on repository 'deployments'| no       |
| webhook_prompt      | Provide AI instructions prompt for the agent to follow upon incoming webhook | string |Run argo diff against the following revision: {{.event.pull_request.head.ref}}| no       |
| webhook_filter      | Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org | string |pull_request[?state == 'open']| no       |
