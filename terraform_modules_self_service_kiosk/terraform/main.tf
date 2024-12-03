terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  # API key is set as an environment variable KUBIYA_API_KEY
}

# Configure the source for the Terraform module tools
resource "kubiya_source" "terraform_module_tools" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/terraform_module_tools/terraform_module_tools"
}

# Parse the YAML configurations
locals {
  tf_module_config = yamldecode(var.tf_module_config_yaml)
  module_knowledge = yamldecode(var.module_knowledge_yaml)
}

# Create knowledge resources for modules with provided knowledge
resource "kubiya_knowledge" "module_specific" {
  for_each = local.module_knowledge

  name             = "Knowledge for ${each.key}"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Organizational knowledge for ${each.key} module."
  labels           = ["terraform", "module", each.key]
  supported_agents = [kubiya_agent.terraform_kiosk.name]
  content          = each.value
}

# Configure the Terraform Kiosk teammate
resource "kubiya_agent" "terraform_kiosk" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Terraform Modules Self-Service Kiosk"
  model        = "azure/gpt-4"
  instructions = ""

  # Include knowledge sources if any
  sources = concat(
    [kubiya_source.terraform_module_tools.name],
    [for k in keys(kubiya_knowledge.module_specific) : kubiya_knowledge.module_specific[k].name]
  )

  integrations = var.kubiya_integrations
  users        = []
  groups       = var.kubiya_groups_allowed_groups

  environment_variables = {
    # Convert the parsed YAML to JSON for the environment variable
    TF_MODULE_CONFIG_FILE = jsonencode(local.tf_module_config)
  }

  secrets = var.kubiya_secrets
}

# Output the teammate details
output "terraform_kiosk_details" {
  value = {
    name         = kubiya_agent.terraform_kiosk.name
    runner       = kubiya_agent.terraform_kiosk.runner
    integrations = var.kubiya_integrations
    groups       = var.kubiya_groups_allowed_groups
  }
} 