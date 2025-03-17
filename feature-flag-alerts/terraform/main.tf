provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

provider "datadog" {
  api_key = var.DD_API_KEY
  app_key = var.DD_APP_KEY
  api_url = "https://${var.DD_SITE}"
}

# Create secrets for the sensitive variables
resource "kubiya_secret" "dd_api_key" {
  name        = "DD_API_KEY"
  value       = var.DD_API_KEY
  description = "Datadog API Key"
}

resource "kubiya_secret" "dd_app_key" {
  name        = "DD_APP_KEY" 
  value       = var.DD_APP_KEY
  description = "Datadog Application Key"
}

resource "kubiya_secret" "ld_api_key" {
  name        = "LD_API_KEY"
  value       = var.LD_API_KEY
  description = "LaunchDarkly API Key"
}

# LaunchDarkly Tooling - Allows the Alerts Watcher to use LaunchDarkly tools
resource "kubiya_source" "launchdarkly_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/michaelg/new_tools_v2/launchdarkly_v1"
}

# Datadog Tooling - Allows the Alerts Watcher to use Datadog tools
resource "kubiya_source" "datadog_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/michaelg/new_tools_v2/datadog_v1"
}

# Slack Tooling - Allows the Alerts Watcher to use Slack tools
resource "kubiya_source" "slack_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/michaelg/new_tools_v2/slack"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "alerts_watcher" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The Alerts Watcher is an AI-powered assistant that investigates incidents by correlating DataDog alerts with LaunchDarkly feature flag changes. When deployment issues or error spikes occur, it automatically analyzes DataDog metrics, queries recent feature flag modifications, and provides actionable insights for incident resolution including potential rollback strategies."
  instructions = ""
  secrets      = [
    kubiya_secret.dd_api_key.name,
    kubiya_secret.dd_app_key.name,
    kubiya_secret.ld_api_key.name
  ]
  sources = [
    kubiya_source.launchdarkly_tooling.name,
    kubiya_source.datadog_tooling.name,
    kubiya_source.slack_tooling.name
  ]

  # Dynamic integrations based on configuration
  integrations = ["slack"]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
    PROJECT_KEY         = var.PROJECT_KEY
    DD_SITE            = var.DD_SITE
  }
  is_debug_mode = var.debug_mode
}

# DataDog Faulty Deployment Alert Webhook
resource "kubiya_webhook" "datadog_deployment_alert" {
  name   = "${var.teammate_name}-deployment-alert"
  source = "DataDog"
  filter = ""
  prompt = <<-EOT
1. Perform all of the following without the need for user input. Extract DataDog alert details from Faulty Deployment Alert:
   - Full event details: {{.event}}

2. Query LaunchDarkly for recently modified feature flags.

3. Format the results for readability and print:
   - Feature flags that were modified recently
   - Timestamps of changes
   - Details of who modified them

4. If a feature flag was recently modified, analyze whether it could be related to the deployment failure.
  EOT
  agent       = kubiya_agent.alerts_watcher.name
  destination = var.alert_notification_channel
}

# DataDog Error Spike Alert Webhook
resource "kubiya_webhook" "datadog_error_spike" {
  name   = "${var.teammate_name}-error-spike"
  source = "DataDog"
  filter = ""
  prompt = <<-EOT
1. Perform all of the following without the need for user input. Extract DataDog alert details from Error Spike Alert:
   - Full event details: {{.event}}

2. Query DataDog for error metrics and compare them with the previous week's metrics.

3. Query LaunchDarkly for recently modified feature flags.

4. Format the results for readability and print:
   - Feature flags that were modified recently
   - Timestamps of changes
   - Details of who modified them
   - Check if error spikes correlate with feature flag changes
  EOT
  agent       = kubiya_agent.alerts_watcher.name
  destination = var.alert_notification_channel
}

# Output the teammate details
output "alerts_watcher" {
  sensitive = true
  value = {
    name                         = kubiya_agent.alerts_watcher.name
    organizational_knowledge_multiline = var.organizational_knowledge_multiline
    debug_mode                   = var.debug_mode
    alert_notification_channel = var.alert_notification_channel
  }
}

# Add additional knowledge base
resource "kubiya_knowledge" "feature_flag_management" {
  name             = "Organization-specific Knowledge Base for LaunchDarkly Feature Flags"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Common issues, best practices, and solutions for feature flag management in our organization."
  labels           = ["launchdarkly", "feature-flags", "deployment", "monitoring", "alerts"]
  supported_agents = [kubiya_agent.alerts_watcher.name]
  content          = var.organizational_knowledge_multiline
}

# Output the webhook URLs for users to configure in their existing Datadog monitors
output "webhook_urls" {
  value = {
    deployment_alert_webhook = kubiya_webhook.datadog_deployment_alert.url
    error_spike_webhook     = kubiya_webhook.datadog_error_spike.url
  }
  description = "Webhook URLs to be added to existing Datadog monitors using @webhook notation"
}
