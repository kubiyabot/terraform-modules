resource "kubiya_agent" "agent" {
  secrets = var.agent_secrets

  integrations = var.agent_integrations
  links                 = var.agent_links
  starters              = var.agent_starters
  environment_variables = var.agent_environment_variables
  llm_model       = var.agent_llm_model
  name            = var.agent_name
  description     = var.agent_description
  runners         = var.agent_runners
  image           = var.agent_image
  ai_instructions = var.agent_ai_instructions
}

output "agent" {
  value = kubiya_agent.agent
}
