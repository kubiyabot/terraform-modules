resource "kubiya_teammate" "teammate" {
  email     = var.teammate_email
  role      = var.teammate_role
  first_name = var.teammate_first_name
  last_name  = var.teammate_last_name
}

resource "kubiya_source" "source" {
  name        = var.source_name
  type        = var.source_type
  description = var.source_description
  config      = var.source_config
}

resource "kubiya_webhook" "webhook" {
  name        = var.webhook_name
  description = var.webhook_description
  url         = var.webhook_url
  events      = var.webhook_events
  secret      = var.webhook_secret
  enabled     = var.webhook_enabled
} 