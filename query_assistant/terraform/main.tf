terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Slack Tooling - Allows the agent to use Slack tools
resource "kubiya_source" "slack_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/michaelg/query-assistant/query_assistant"
}

# Create secrets for LiteLLM configuration
resource "kubiya_secret" "litellm_api_key" {
  name        = "LITELLM_API_KEY"
  value       = var.litellm_api_key
  description = "API key for LiteLLM service"
}

# Configure the Query Assistant agent
resource "kubiya_agent" "query_assistant" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered assistant that answers user queries by searching through Slack conversation history"
  instructions = <<-EOT
Your primary role is to assist users by answering their questions using information found in Slack conversations from the channel '${var.source_channel}'. You should:

- Use slack_search_messages with:
  - 'channel' set to '${var.source_channel}'
  - 'query' set to the user's EXACT question or query - do not modify, rephrase, summarize, or interpret it in any way
  - 'oldest' set to '${var.search_window}' to search messages from the last ${var.search_window}
- The tool will automatically include thread replies for any message that has them. You do not need to call slack_get_thread_replies separately.
- Provide comprehensive answers based on the discovered content, considering both main messages and their thread replies.
- Include context and references to the original Slack messages when possible.
- Clearly communicate when relevant information cannot be found.

IMPORTANT: Always use the user's query VERBATIM as the search query. Do not attempt to improve or modify it in any way, as this could miss relevant results.

Your goal is to be a helpful bridge between users and the knowledge contained within Slack conversations in the specified channel.
EOT
  sources      = [kubiya_source.slack_tooling.name]
  
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }

  secrets = ["LITELLM_API_KEY"]

  is_debug_mode = var.debug_mode
}

# Output the agent details
output "query_assistant" {
  sensitive = true
  value = {
    name       = kubiya_agent.query_assistant.name
    debug_mode = var.debug_mode
  }
}