resource "kubiya_agent" "agent" {

  //Mandatory Fields
  name         = var.agent_name
  runner       = var.agent_runners
  description  = var.agent_description
  instructions = ""

  //Optional fields, String
  model = var.agent_llm_model // If not provided, Defaults to "azure/gpt-4"
  //If not provided, Defaults to "ghcr.io/kubiyabot/kubiya-agent:stable"
  # image = var.agent_image

  //Optional Fields (omitting will retain the current values): 
  secrets               = var.agent_secrets
  environment_variables = var.agent_environment_variables
  integrations          = var.agent_integrations
  links                 = var.agent_links
  starters              = var.agent_starters
  tasks                 = var.agent_tasks
  tool_sources          = var.agent_tool_sources
  //Access Control
  users  = var.agent_users
  groups = var.agent_groups


}
