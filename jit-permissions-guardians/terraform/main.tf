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
  url = "https://github.com/kubiyabot/community-tools/tree/shaked/just-in-time-tooling/just_in_time_access"
}

# AWS dynamic policy generation tool (automatically included)
resource "kubiya_source" "aws_policy_generator" {
  url = "https://github.com/kubiyabot/terraform-modules/tree/main/jit-permissions-guardians/tools/aws/policy_generator"
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

# Configure the JIT Guardian agent
resource "kubiya_agent" "jit_guardian" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered AWS JIT permissions guardian"
  model        = "azure/gpt-4"
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
    APPROVAL_SLACK_CHANNEL = var.approvers_slack_channel
    AVAILABLE_POLICIES    = var.available_policies_yaml
    KUBIYA_TOOL_TIMEOUT   = var.kubiya_tool_timeout
  }
}

# Output the teammate details
output "jit_guardian" {
  value = {
    name                    = kubiya_agent.jit_guardian.name
    approvers_slack_channel = var.approvers_slack_channel
  }
}
