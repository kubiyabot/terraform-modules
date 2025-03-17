# Feature Flag Alert Analysis Module

This Terraform module creates an AI-powered assistant that automatically investigates the relationship between Datadog alerts and LaunchDarkly feature flag changes. It helps teams quickly identify if recent feature flag changes might be related to deployment issues or error spikes.

## Overview

The module creates:
- A Kubiya AI agent specialized in analyzing alerts and feature flags
- Webhook endpoints for Datadog alerts
- Necessary integrations with Datadog, LaunchDarkly, and Slack
- Secure storage for API keys and sensitive data

## Use Cases

### 1. Deployment Failure Analysis
When a deployment issue occurs, the system:
- Receives the Datadog alert via webhook
- Automatically queries LaunchDarkly for recent feature flag changes
- Analyzes potential correlations
- Provides actionable insights including:
  - Recently modified feature flags
  - Change timestamps
  - Who made the changes
  - Potential relationship to the deployment failure

### 2. Error Spike Investigation
When an error spike is detected, the system:
- Receives the Datadog error alert
- Compares current error metrics with historical data
- Identifies recent feature flag changes
- Analyzes correlations between error patterns and flag modifications
- Provides comprehensive analysis including:
  - Error rate comparisons
  - Feature flag changes
  - Temporal correlation analysis
  - Potential mitigation strategies

## Setup Instructions

### Prerequisites
- Datadog account with API and Application keys
- LaunchDarkly account with API key
- Slack workspace with Kubiya app installed
- Terraform >= 1.0

### Installation

1. Include the module in your Terraform configuration:

```hcl
module "feature_flag_alerts" {
  source = "path/to/feature-flag-alerts"
  
  teammate_name             = "alerts-watcher"
  alert_notification_channel = "#alerts"
  kubiya_runner            = "your-runner"
  
  DD_API_KEY  = var.datadog_api_key
  DD_APP_KEY  = var.datadog_app_key
  DD_SITE     = "datadoghq.com"
  LD_API_KEY  = var.launchdarkly_api_key
  PROJECT_KEY = var.launchdarkly_project_key
}
```

2. Initialize and apply the Terraform configuration:
```bash
terraform init
terraform apply
```

### Integrating with Existing Datadog Monitors

This module intentionally does not create new Datadog monitors, instead providing webhook endpoints to integrate with your existing monitoring setup. To connect your monitors:

1. Get the webhook URLs from the Terraform outputs:
```bash
terraform output webhook_urls
```

2. Add the webhook URL to your existing Datadog monitor notifications using the `@webhook` notation:
```
@webhook-{deployment_alert_webhook_url}  # For deployment monitors
@webhook-{error_spike_webhook_url}       # For error rate monitors
```

## Configuration Options

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `teammate_name` | Name for the AI assistant | No | "alerts-watcher" |
| `alert_notification_channel` | Slack channel for notifications | No | "#alerts" |
| `kubiya_runner` | Kubiya runner to use | Yes | - |
| `DD_API_KEY` | Datadog API Key | Yes | - |
| `DD_APP_KEY` | Datadog Application Key | Yes | - |
| `DD_SITE` | Datadog site (e.g., datadoghq.com) | Yes | - |
| `LD_API_KEY` | LaunchDarkly API Key | Yes | - |
| `PROJECT_KEY` | LaunchDarkly Project Key | Yes | - |

## Security Considerations

- All sensitive keys are stored securely using Kubiya's secret management
- Communication between services uses encrypted channels
- Access to the AI assistant can be restricted using the `kubiya_groups_allowed_groups` variable

## Support

For issues, questions, or contributions, please contact [support contact information].
