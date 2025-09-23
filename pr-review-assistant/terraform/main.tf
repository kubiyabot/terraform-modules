terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key via KUBIYA_API_KEY env var
}

# Single tool source
resource "kubiya_source" "simple_pr_reviewer" {
  url    = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/pr-review-assistant/tools"
  runner = var.kubiya_runner
}

# Kubiya Webhook that receives GitHub webhook events
resource "kubiya_webhook" "github_pr_webhook" {
  name        = "${var.agent_name}-webhook"
  source      = "github"
  agent       = kubiya_agent.simple_pr_reviewer.name
  destination = var.default_slack_channel
  filter      = var.github_repository_filter != "" ? "repository.full_name == '${var.github_repository_filter}'" : ""
  
  # Define how to invoke the agent
  prompt = <<-EOT
    A pull request event was received from GitHub.
    
    Event: {{ .action }}
    PR URL: {{ .pull_request.html_url }}
    PR Number: {{ .pull_request.number }}
    Repository: {{ .repository.full_name }}
    Author: {{ .pull_request.user.login }}
    Title: {{ .pull_request.title }}
    
    Please review this pull request by:
    1. Analyzing the code changes for security and quality issues
    2. Posting a comment on the PR with your recommendation
    3. Sending a notification to Slack channel ${var.default_slack_channel}
    
    Use the review_and_notify_pr tool with the PR URL.
  EOT
}

# Configure environment variables for the agent
resource "null_resource" "agent_env_setup" {
  triggers = {
    agent_id   = kubiya_agent.simple_pr_reviewer.id
    webhook_id = kubiya_webhook.github_pr_webhook.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X PUT \
      -H "Authorization: UserKey $KUBIYA_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "uuid": "${kubiya_agent.simple_pr_reviewer.id}",
        "environment_variables": {
          "GITHUB_TOKEN": "${var.github_token}",
          "SLACK_TOKEN": "${var.slack_token}",
          "SLACK_CHANNEL": "${var.default_slack_channel}",
          "LOG_LEVEL": "${var.log_level}"
        }
      }' \
      "https://api.kubiya.ai/api/v1/agents/${kubiya_agent.simple_pr_reviewer.id}"
    EOT
  }
  
  depends_on = [
    kubiya_webhook.github_pr_webhook,
    kubiya_agent.simple_pr_reviewer
  ]
}

# Simple PR Review Agent
resource "kubiya_agent" "simple_pr_reviewer" {
  name         = var.agent_name
  runner       = var.kubiya_runner
  description  = "Simple PR reviewer that analyzes GitHub PRs and notifies via Slack"
  
  instructions = <<-EOT
    I automatically analyze GitHub pull requests when they are opened or updated.
    
    My workflow:
    1. Triggered by GitHub webhook on PR events
    2. Fetch PR details from GitHub
    3. Identify reviewers and repository owner
    4. Analyze code changes for security and quality issues
    5. Post a detailed comment on the PR with my recommendation
    6. Send a Slack notification with full analysis details
    
    I tag relevant users in both GitHub comments and Slack messages.
  EOT
  
  model        = var.ai_model
  integrations = ["github", "slack"]
  users        = var.kubiya_users
  groups       = var.kubiya_groups
  sources      = [kubiya_source.simple_pr_reviewer.name]
  
  is_debug_mode = var.debug_mode
  
  lifecycle {
    ignore_changes = [
      environment_variables
    ]
  }
}