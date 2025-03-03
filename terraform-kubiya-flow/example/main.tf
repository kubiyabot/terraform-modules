terraform {
  required_providers {
    kubiya = {
      source = "kubiya/kubiya"
    }
  }
}

provider "kubiya" {
  api_key = var.kubiya_api_key
}

module "kubiya" {
  source = "../"

  # Teammate configuration
  teammate_email     = var.teammate_email
  teammate_role      = var.teammate_role
  teammate_first_name = var.teammate_first_name
  teammate_last_name  = var.teammate_last_name

  # Source configuration
  source_name        = var.source_name
  source_type        = var.source_type
  source_description = var.source_description
  source_config      = var.source_config

  # Webhook configuration
  webhook_name        = var.webhook_name
  webhook_description = var.webhook_description
  webhook_url         = var.webhook_url
  webhook_events      = var.webhook_events
  webhook_secret      = var.webhook_secret
  webhook_enabled     = var.webhook_enabled
} 