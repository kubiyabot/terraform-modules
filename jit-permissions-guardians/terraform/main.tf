terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Load knowledge sources
data "http" "jit_access_knowledge" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/jit-permissions-guardians/terraform/knowledge/jit_access.md"
}

# Configure sources
resource "kubiya_source" "jit_approval_workflow_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/jit_access_v2/just_in_time_access"
}

# AWS dynamic policy generation tool (automatically included)
resource "kubiya_source" "aws_policy_generator" {
  url = "https://github.com/kubiyabot/community-tools/tree/jit_access_v2/aws_jit_tools"
}

# Configure auxiliary request tools
resource "kubiya_source" "request_tools" {
  for_each = toset(var.request_tools_sources)
  url      = each.value
}

# Create knowledge base
resource "kubiya_knowledge" "jit_access" {
  name             = "JIT Access Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for JIT access management and troubleshooting"
  labels           = ["aws", "jit", "access-management"]
  supported_agents = [kubiya_agent.jit_guardian.name]
  content          = data.http.jit_access_knowledge.response_body
}

resource "kubiya_webhook" "webhook" {
  //mandatory fields
  //Please specify a unique name to identify this webhook
  name = "jit-request-access"
  //Please specify the source of the webhook - e.g: 'pull request opened on repository foo'
  source = "JIT"
  //Provide AI instructions prompt for the agent to follow upon incoming webhook. use {{.event.}} syntax for dynamic parsing of the event
  prompt = "Sum up this just in time access request. Ask if the user wants to approve or reject the request. request: {{.event}}"
  //Select an Agent which will perform the task and receive the webhook payload
  agent = kubiya_agent.jit_guardian.name
  //Please provide a destination that starts with `#` or `@`
  destination = var.approvers_slack_channel
  //optional fields
  //Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org
  filter = ""
  depends_on = [
    kubiya_agent.jit_guardian
  ]
}

# Configure the JIT Guardian agent
resource "kubiya_agent" "jit_guardian" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered AWS JIT permissions guardian"
  model        = "azure/gpt-4o"
  instructions = ""
  sources      = concat(
    [
      kubiya_source.aws_policy_generator.name,
      kubiya_source.jit_approval_workflow_tooling.name
    ],
    [for source in kubiya_source.request_tools : source.name]
  )

  integrations = var.kubiya_integrations
  users        = []
  groups       = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT   = var.kubiya_tool_timeout
    REQUEST_ACCESS_WEBHOOK_URL = kubiya_webhook.webhook.url
  }
}

# Output the teammate details
output "jit_guardian" {
  value = {
    name                    = kubiya_agent.jit_guardian.name
    approvers_slack_channel = var.approvers_slack_channel
  }
}
