resource "kubiya_agent" "agent" {
  name         = var.agent_name
  description  = var.agent_description
  runner       = var.agent_runner
  instructions = var.agent_instructions
}

resource "kubiya_source" "source" {
  url = var.source_url
}

resource "kubiya_webhook" "webhook" {
  name        = var.webhook_name
  source      = kubiya_source.source.id
  agent       = kubiya_agent.agent.id
  destination = var.webhook_destination
  prompt      = var.webhook_prompt
} 