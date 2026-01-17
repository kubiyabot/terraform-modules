terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "0.2.3"
    }
  }
}

provider "kubiya" {
  api_key = "" // Required Field, can be an empty string. 
  // If empty, Your Kubiya API Key will be taken from the 
  // environment variable KUBIYA_API_KEY
  // To set the key, please use export KUBIYA_API_KEY={{replace with UserKey}}
}

resource "kubiya_agent" "agent" {

  // Mandatory Fields
  name         = var.agent_name
  runners      = var.runners
  description  = var.description
  instructions = var.instructions

  // Optional Fields
  model        = var.model
  image        = var.image
  secrets      = var.secrets
  integrations = var.integrations
  users        = var.users
  groups       = var.groups
  links        = var.links
  
  // Optional Fields: Strings that represents an escaped JSON 
  // JSON Array for starters
  starters = jsonencode(var.starters)
  
  // JSON Array for tasks
  tasks = jsonencode(var.tasks)
  
  // JSON Object for environment variables
  env_vars = jsonencode(var.env_vars)
}

output "agent" {
  value = kubiya_agent.agent
}
