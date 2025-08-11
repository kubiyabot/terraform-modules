terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}


provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Update the tooling source to use Slack instead of Confluence
resource "kubiya_source" "slack_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/slack"
}

# Configure the Query Assistant agent
resource "kubiya_agent" "ask_kubiya_confluence" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered assistant that answers user queries using knowledge imported from Confluence documentation"
  instructions = <<-EOT
Your role is to answer user questions using the attached knowledge sources.

1. Search the knowledge sources for relevant information
2. Compose your answer following these principles:
   - Be concise: Lead with the direct answer in 1-2 sentences
   - Be complete: Include critical details or steps the user needs
   - Be actionable: Use lists or numbered steps when explaining procedures
   - Be clear: Avoid jargon and define terms when needed

If no relevant information is found, say so directly and ask for clarification if needed.
EOT
  sources      = [kubiya_source.slack_tooling.name]
  
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  
  is_debug_mode = var.debug_mode
}

variable "CONFLUENCE_API_TOKEN" {
  type        = string
  sensitive   = true
  description = "API token for Confluence authentication"
}

# Create secret using provider
resource "kubiya_secret" "confluence_api_token" {
  name        = "CONFLUENCE_API_TOKEN"
  value       = var.CONFLUENCE_API_TOKEN
  description = "Confluence API token for the CI/CD Maintainer"
}

# Fetch Confluence content using data source
data "external" "confluence_content" {
  program = ["python3", "${path.module}/import_confluence.py"]

  # Set parameters for the Python script
  query = {
    CONFLUENCE_URL = var.confluence_url
    CONFLUENCE_USERNAME = var.confluence_username
    CONFLUENCE_API_TOKEN = var.CONFLUENCE_API_TOKEN
    space_key = var.confluence_space_key
    include_blogs = var.import_confluence_blogs ? "true" : "false"
  }
}

# Create knowledge items for each piece of content
resource "kubiya_knowledge" "confluence_content" {
  for_each = { for item in jsondecode(data.external.confluence_content.result.items) : item.id => item }

  name             = each.value.title
  groups           = var.kubiya_groups_allowed_groups
  description      = "Imported from Confluence space: ${var.confluence_space_key}"
  labels           = concat(
    ["confluence", "space-${var.confluence_space_key}"],
    each.value.type == "blog" ? ["blog"] : [],
    split(",", each.value.labels)
  )
  supported_agents = [kubiya_agent.ask_kubiya_confluence.name]
  
  # Use the content directly from the Python script
  content = each.value.content
}

# Output the agent details
output "ask_kubiya_confluence" {
  sensitive = true
  value = {
    name       = kubiya_agent.ask_kubiya_confluence.name
    debug_mode = var.debug_mode
  }
}