# Kubiya Terraform Module

This module creates Kubiya resources including an agent, source, and webhook.

## Usage

```hcl
module "kubiya" {
  source = "./terraform-kubiya-flow"

  # Agent configuration
  agent_name         = "my-agent"
  agent_description  = "My Kubiya agent"
  agent_runner       = "my-runner"
  agent_instructions = "My agent instructions"

  # Source configuration
  source_url = "https://example.com/source"

  # Webhook configuration
  webhook_name        = "my-webhook"
  webhook_destination = "https://example.com/webhook"
  webhook_prompt      = "My webhook prompt"
}
```

## Environment Variables

The module supports different environments through environment-specific variable files in the `env_tfvars` directory:

- `cicd.tfvars`: For CICD pipeline
- `development.tfvars`: For development environment
- `staging.tfvars`: For staging environment
- `production.tfvars`: For production environment

See the `env_tfvars/README.md` for more information about using environment-specific variables.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| kubiya | >= 0.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_name | Name of the Kubiya agent | string | n/a | yes |
| agent_description | Description of the Kubiya agent | string | "" | no |
| agent_runner | Runner for the Kubiya agent | string | n/a | yes |
| agent_instructions | Instructions for the Kubiya agent | string | n/a | yes |
| source_url | URL for the Kubiya source | string | n/a | yes |
| webhook_name | Name of the Kubiya webhook | string | n/a | yes |
| webhook_destination | Destination for the webhook | string | n/a | yes |
| webhook_prompt | Prompt for the webhook | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| agent_id | ID of the created Kubiya agent |
| source_id | ID of the created Kubiya source |
| webhook_id | ID of the created Kubiya webhook | 