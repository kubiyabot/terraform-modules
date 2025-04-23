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

# Slack Tools - For channel monitoring and notifications
resource "kubiya_source" "slack_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/michaelg/new_tools_v2/slack"
}

# Configure the Alert Investigation agent
resource "kubiya_agent" "alert_investigator" {
  name         = "alert-investigator"
  runner       = var.kubiya_runner
  description  = "AI-powered assistant that correlates alerts with feature flags and deployments"
  instructions = <<-EOT
Your role is to help investigate alerts by analyzing error metrics, feature flag changes, and deployment activities.
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

# Schedule deployment alert monitoring task
resource "kubiya_scheduled_task" "monitor_deployment_alerts" {
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "10m"))
  repeat = "*/15 * * * *"
  channel_id     = var.execution_channel
  agent          = kubiya_agent.alert_investigator.name
  description    = <<-EOT
Monitor alert channels for Datadog deployment failure alerts and analyze feature flag correlations:

1. For each alert channel in ${jsonencode(var.alert_source_channels)}:
   - Use slack_get_channel_history to fetch recent messages within the last ${var.lookback_period}
   - Filter for Datadog alerts containing keywords like "deployment", "failed deployment", "faulty deployment"
   - For each failure alert:
     * Check all feature flag channels ${jsonencode(var.feature_flags_channels)} for changes within the last ${var.lookback_period}
     * Analyze potential correlations between the deployment failure and flag changes
     * Format a summary in markdown:
       ```
       ## Deployment Failure Alert Investigation
       **Alert Details**
       - Time: [alert timestamp]
       - Service: [from alert]
       - Deployment Status: Failed
       
       **Recent Feature Flag Changes**
       - [List of changes with timestamps]
       
       **Analysis**
       - [Correlation analysis between deployment and flag changes]
       - [Potential impact assessment]
       
       **Original Alert**
       > [Quote of the original alert message]
       ```
     * Use slack_send_message to post this summary to the ${var.report_channel} channel

Focus on identifying feature flag changes that might have contributed to the deployment failure.
EOT
}


# Schedule error rate alert monitoring task
resource "kubiya_scheduled_task" "monitor_error_alerts" {
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "15m"))
  repeat = "*/15 * * * *"
  channel_id     = var.execution_channel
  agent          = kubiya_agent.alert_investigator.name
  description    = <<-EOT
Monitor alert channels for Datadog error rate alerts and perform comprehensive analysis:

1. For each alert channel in ${jsonencode(var.alert_source_channels)}:
   - Use slack_get_channel_history to fetch recent messages within the last ${var.lookback_period}
   - Filter for Datadog alerts containing keywords like "error rate", "error spike", "number of errors"
   - For each error rate alert:
     * Use the compare_error_rates tool to compare current week's error rates with previous week
     * Check all feature flag channels ${jsonencode(var.feature_flags_channels)} for changes within the last ${var.lookback_period}
     * Check the '${var.deployment_channel}' channel for any ArgoCD deployment messages within the last ${var.lookback_period}
     * Analyze correlations between error rates, feature flags, and deployments
     * Format a summary in markdown:
       ```
       ## Error Rate Alert Investigation
       **Alert Details**
       - Time: [alert timestamp]
       - Service: [from alert]
       - Error Type: [from alert]
       
       **Error Rate Comparison**
       - Current Week: [metrics]
       - Previous Week: [metrics]
       - Change: [percentage]
       
       **Recent Changes**
       Feature Flags:
       - [List of changes with timestamps]
       
       ArgoCD Deployments:
       - [List of deployments with timestamps]
       
       **Analysis**
       - [Error rate trend analysis]
       - [Correlation with feature flags and deployments]
       - [Potential root cause assessment]
       
       **Original Alert**
       > [Quote of the original alert message]
       ```
     * Use slack_send_message to post this summary to the ${var.report_channel} channel

Focus on providing actionable insights about what might have caused the error rate increase, considering both feature flag changes and deployment activities.
EOT
}

# Output the agent details
output "alert_investigator" {
  sensitive = true
  value = {
    name              = kubiya_agent.alert_investigator.name
    debug_mode        = var.debug_mode
    monitored_channels = var.alert_source_channels
  }
}