terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // Your Kubiya API Key will be taken from the
  // environment variable KUBIYA_API_KEY
  // To set the key, please use export KUBIYA_API_KEY="YOUR_API_KEY"
}

resource "kubiya_agent" "agent" {
  name         = var.agent_name
  runner       = var.kubiya_runner
  description  = var.agent_description
  instructions = var.agent_instructions
  model        = var.llm_model
  image        = var.agent_image

  secrets      = var.secrets
  integrations = var.integrations
  users        = var.users
  groups       = var.groups
  links        = var.links
  tool_sources = var.agent_tool_sources
  
  environment_variables = merge(
    {
      LOG_LEVEL = var.log_level
    },
    var.debug ? { DEBUG = "1", KUBIYA_DEBUG = "1" } : {},
    var.environment_variables,
    {
      APPROVING_USERS        = join(",", var.approving_users)
      APPROVAL_SLACK_CHANNEL = var.approval_slack_channel
    }
  )
}

output "agent" {
  value = kubiya_agent.agent
}
