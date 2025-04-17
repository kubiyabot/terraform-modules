terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Slack Tooling - Allows the History Analyzer to use Slack tools
resource "kubiya_source" "slack_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/slack"
}

# Configure the Slack History Analyzer agent
resource "kubiya_agent" "slack_historian" {
  name         = "slack-historian"
  runner       = var.kubiya_runner
  description  = "AI-powered assistant that analyzes Slack channel history and thread replies to generate daily summary reports of key discussions, decisions, and action items."
  instructions = ""
  sources      = [kubiya_source.slack_tooling.name]
  
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  is_debug_mode = var.debug_mode
}

# Schedule daily summary task
resource "kubiya_scheduled_task" "daily_summary" {
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "10m"))
  repeat         = "daily"
  channel_id     = var.execution_channel
  agent          = kubiya_agent.slack_historian.name
  description    = <<-EOT
Perform all the following steps autonomously without the need for user input. Using slack_get_channel_history with 'oldest' set to '1d' and 'channel' set to '${var.source_channel}', read all messages from the last 24 hours. For each message that has a thread, use slack_get_thread_replies to fetch the thread replies. Create a concise summary in the following format:

**Summary of Recent Slack Activity**
1. Total message and thread counts
2. For each main thread/discussion:
   - Thread Title/Topic
   - Brief (1-2 line) description of the initial message
   - Concise summary of key outcomes from the thread, focusing on:
     * Decisions made
     * Action items agreed upon
     * Important updates or changes
     * Final resolutions
   - Note: Do not include full message quotes. Summarize the key points in 1-2 sentences.
3. Ignore threads that are purely acknowledgments or don't contain substantial information

Format the summary in a clear, readable markdown structure. Then use slack_send_message to post this summary to the ${var.report_channel} channel.
EOT
}

# Output the agent details
output "slack_historian" {
  sensitive = true
  value = {
    name       = kubiya_agent.slack_historian.name
    debug_mode = var.debug_mode
  }
}