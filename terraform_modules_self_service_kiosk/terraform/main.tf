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


# Configure the source for the Terraform modules
resource "kubiya_source" "terraform_modules" {
  url           = "https://github.com/kubiyabot/community-tools/tree/main/terraform_module_tools"
  dynamic_config = var.tf_modules_config_json
}

# Create knowledge resources for modules with provided knowledge
resource "kubiya_knowledge" "organizational_knowledge" {
  name        = "Organizational Knowledge"
  groups      = var.kubiya_groups_allowed_groups
  description = "Organizational knowledge for Terraform Modules Self-Service Kiosk"
  content     = var.organizational_knowledge_multiline
  labels      = ["terraform", "module", "knowledge", "self-service", "kiosk"]
}

# Configure the Terraform Kiosk teammate
resource "kubiya_agent" "terraform_kiosk" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Terraform Modules Self-Service Kiosk"
  model        = "gpt-4o"
  instructions = ""

  sources = [kubiya_source.terraform_module_tools.id]

  integrations = var.kubiya_integrations
  groups       = var.kubiya_groups_allowed_groups
  secrets      = var.kubiya_secrets

  is_debug_mode = var.debug_mode
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