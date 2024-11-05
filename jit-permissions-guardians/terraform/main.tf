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
resource "kubiya_source" "source1" {
  url = "https://github.com/kubiyabot/terraform-modules/tree/main/aws-jit-permissions-workflow/tools/approval_workflow/*"
}

resource "kubiya_source" "source2" {
  url = "https://github.com/kubiyabot/terraform-modules/tree/main/aws-jit-permissions-workflow/tools/aws/*"
}
resource "kubiya_agent" "agent" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4o"
  secrets      = var.kubiya_secrets
  integrations = var.kubiya_integrations
  users        = var.kubiya_users
  groups       = var.kubiya_groups
  sources = [kubiya_source.source1.name, kubiya_source.source2.name]
  
  environment_variables = merge(
    {
      LOG_LEVEL = var.log_level,
      APPROVING_USERS = join(",", var.kubiya_users_approving_users)
      APPROVAL_SLACK_CHANNEL = var.approval_slack_channel
    },
    var.debug ? { DEBUG = "1", KUBIYA_DEBUG = "1" } : {},
    var.dry_run ? { DRY_RUN_ENABLED = "1" } : {}
  )
}

output "agent" {
  value = kubiya_agent.agent
}
