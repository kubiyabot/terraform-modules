provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Slack Tooling - Allows the agent to use Slack tools
resource "kubiya_source" "slack_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/michaelg/new_tools_v2/slack"
}

# Configure the Query Assistant agent
resource "kubiya_agent" "query_assistant" {
  name         = "query-assistant"
  runner       = var.kubiya_runner
  description  = "AI-powered assistant that answers user queries by searching through Slack conversation history"
  instructions = <<-EOT
Your primary role is to assist users by answering their questions using information found in Slack conversations from the channel '${var.source_channel}'. You should:

- Search through Slack channel messages and their associated thread replies to find relevant information
- Use slack_get_channel_history with 'channel' set to '${var.source_channel}' and 'limit' set to 20 to fetch recent messages
- For any relevant messages that have threads, use slack_get_thread_replies to get the full context
- Provide comprehensive answers based on the discovered content
- Include context and references to the original Slack messages when possible
- Clearly communicate when relevant information cannot be found

Your goal is to be a helpful bridge between users and the knowledge contained within Slack conversations in the specified channel.
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

# Output the agent details
output "query_assistant" {
  sensitive = true
  value = {
    name       = kubiya_agent.query_assistant.name
    debug_mode = var.debug_mode
  }
}