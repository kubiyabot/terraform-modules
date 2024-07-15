resource "kubiya_agent" "agent" {

  //Mandatory Fields
  name         = var.agent_name
  runner       = var.agent_runners
  description  = var.agent_description
  instructions = var.agent_ai_instructions

  //Optional fields, String
  model = var.agent_llm_model // If not provided, Defaults to "azure/gpt-4"
  //If not provided, Defaults to "ghcr.io/kubiyabot/kubiya-agent:stable"
  image = var.agent_image

  //Optional Fields (omitting will retain the current values): 
  secrets      = var.agent_secrets
  integrations = var.agent_integrations
  users        = var.agent_users
  groups       = var.agent_groups
  links        = var.agent_links
  tool_sources = var.agent_tool_sources

  //Objects
  starters = var.agent_starters

  tasks = var.agent_tasks

  environment_variables = var.agent_environment_variables
}

# output "agent" {
#   value = kubiya_agent.agent
# }

resource "kubiya_webhook" "webhook" {
  name = var.webhook_name
  //Please specify the source of the webhook - e.g: 'pull request opened on repository foo'
  source = var.webhook_source
  //Provide AI instructions prompt for the agent to follow upon incoming webhook. use {{.event.}} syntax for dynamic parsing of the event
  prompt = var.webhook_prompt
  //Select an Agent which will perform the task and receive the webhook payload
  agent = kubiya_agent.agent.name
  //Please provide a destination that starts with `#` or `@`
  destination = var.webhook_destination
  //optional fields
  //Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org
  filter = var.webhook_filter
}

# output "webhook" {
#   value = kubiya_webhook.webhook
# }