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
Your primary role is to assist users by answering their questions using the knowledge sources attached to you.

When responding to user queries:
1. Search through your knowledge sources to find relevant information.
2. Provide clear, concise answers based on the information you find.
3. Include context and references to the original Confluence pages when possible.
4. If you can't find relevant information in your knowledge sources, clearly communicate this to the user.

Your goal is to be a helpful bridge between users and the knowledge contained within the Confluence documentation that has been imported as knowledge sources.
EOT
  sources      = [kubiya_source.slack_tooling.name]
  
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }

  # Only set dedicated_channels if the list is not empty
  dedicated_channels = length(var.dedicated_channels) > 0 ? var.dedicated_channels : null

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