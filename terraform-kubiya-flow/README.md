# Kubiya Terraform Module

This module creates Kubiya resources including a teammate, source, and webhook.

## Usage

```hcl
module "kubiya" {
  source = "./kubiya-module"

  # Teammate configuration
  teammate_email     = "user@example.com"
  teammate_role      = "user"
  teammate_first_name = "John"
  teammate_last_name  = "Doe"

  # Source configuration
  source_name        = "my-source"
  source_type        = "github"
  source_description = "GitHub source for my project"
  source_config      = {
    repository = "owner/repo"
    branch     = "main"
  }

  # Webhook configuration
  webhook_name        = "my-webhook"
  webhook_description = "Webhook for notifications"
  webhook_url         = "https://example.com/webhook"
  webhook_events      = ["event1", "event2"]
  webhook_secret      = "your-secret"
  webhook_enabled     = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| kubiya | >= 0.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| teammate_email | Email address of the Kubiya teammate | string | n/a | yes |
| teammate_role | Role for the Kubiya teammate | string | "user" | no |
| teammate_first_name | First name of the Kubiya teammate | string | n/a | yes |
| teammate_last_name | Last name of the Kubiya teammate | string | n/a | yes |
| source_name | Name of the Kubiya source | string | n/a | yes |
| source_type | Type of the Kubiya source | string | n/a | yes |
| source_description | Description of the Kubiya source | string | "" | no |
| source_config | Configuration for the Kubiya source | map(string) | n/a | yes |
| webhook_name | Name of the Kubiya webhook | string | n/a | yes |
| webhook_description | Description of the Kubiya webhook | string | "" | no |
| webhook_url | URL for the webhook endpoint | string | n/a | yes |
| webhook_events | List of events to trigger the webhook | list(string) | n/a | yes |
| webhook_secret | Secret for webhook signature verification | string | n/a | yes |
| webhook_enabled | Whether the webhook is enabled | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| teammate_id | ID of the created Kubiya teammate |
| source_id | ID of the created Kubiya source |
| webhook_id | ID of the created Kubiya webhook | 