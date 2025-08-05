terraform {
  required_providers {
    kubiya = {
      source = "hashicorp.com/edu/kubiya"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

provider "kubiya" {}


# Kubiya Webhook with inline workflow definition
resource "kubiya_webhook" "datadog_incident_response" {
  name   = var.webhook_name
  source = "datadog"
  prompt = "Process Datadog incident with AI investigation and Slack integration"
  filter = ""

  workflow = jsonencode({
    name        = "${var.region}-incident-workflow-dag"
    description = "${title(var.region)} Production incident response workflow with AI investigation and Slack integration"
    steps = [
      {
        name        = "normalize-channel-name"
        description = "Normalize the channel name by replacing spaces with underscores and converting to lower case"
        executor = {
          type = "tool"
          config = {
            tool_def = {
              name        = "normalize-channel"
              description = "Normalize channel name for Slack"
              type        = "docker"
              image       = "bash:5.1-alpine"
              with_files = [
                {
                  destination = "/tmp/normalize.sh"
                  content     = file("${path.module}/scripts/normalize-channel-name.sh")
                }
              ]
              content = "chmod +x /tmp/normalize.sh && /tmp/normalize.sh"
            }
          }
        }
        output = "NORMALIZED_CHANNEL_NAME"
      },
      {
        name        = "setup-slack-integration"
        description = "Initialize Slack integration for incident communications"
        depends     = ["normalize-channel-name"]
        executor = {
          type = "kubiya"
          config = {
            url    = "api/v1/integration/slack/token/1"
            method = "GET"
            silent = false
          }
        }
        output = "slack_token"
      },
      {
        name        = "post-investigation-start"
        description = "Send investigation start notification to Slack"
        depends     = ["setup-slack-integration"]
        executor = {
          type = "tool"
          config = {
            tool_def = {
              name        = "post-investigation-start"
              description = "Post investigation start message to Slack"
              type        = "docker"
              image       = "bash:5.1-alpine"
              with_files = [
                {
                  destination = "/tmp/post-start.sh"
                  content     = file("${path.module}/scripts/post-investigation-start.sh")
                }
              ]
              content = "chmod +x /tmp/post-start.sh && /tmp/post-start.sh"
            }
          }
        }
        output = "investigation_start_message"
      },
      {
        name        = "prepare-investigator-prompt"
        description = "Prepare interactive prompt for follow-up agent investigation"
        depends     = ["setup-slack-integration"]
        executor = {
          type = "tool"
          config = {
            tool_def = {
              name        = "prepare-prompt"
              description = "Prepare investigator prompt"
              type        = "docker"
              image       = "bash:5.1-alpine"
              with_files = [
                {
                  destination = "/tmp/prepare-prompt.sh"
                  content     = replace(file("${path.module}/scripts/prepare-investigator-prompt.sh"), "$${REGION}", var.region)
                }
              ]
              content = "chmod +x /tmp/prepare-prompt.sh && /tmp/prepare-prompt.sh"
            }
          }
        }
        output = "investigator_interactive_prompt"
      },
      {
        name        = "investigate-cluster-health"
        description = "AI-powered cluster investigation for production incident response"
        depends     = ["post-investigation-start", "prepare-investigator-prompt"]
        executor = {
          type = "agent"
          config = {
            agent_id = var.agent_uuid
            use_cli  = true
            message  = "INVESTIGATE INCIDENT $INCIDENT_PUBLIC_ID - $INCIDENT_TITLE (${var.region} ${var.dd_environment})\n\nIMMEDIATE TASK: Return only investigation findings, NO explanations.\n\nSERVICES: $AFFECTED_SERVICES\nSEVERITY: $INCIDENT_SEVERITY\n\nFOCUS AREAS:\n1. Service status and errors\n2. TLS/Certificate issues\n3. Resource constraints\n4. Recent failures\n\nREQUIRED OUTPUT FORMAT:\n- Root cause (if found)\n- Error patterns\n- Failed services\n- Resource issues\n- Remediation steps\n\nDO NOT explain what you're doing. Return findings immediately."
            vars = {
              incident_id       = "$INCIDENT_PUBLIC_ID"
              incident_title    = "$INCIDENT_TITLE"
              incident_severity = "$INCIDENT_SEVERITY"
              affected_services = "$AFFECTED_SERVICES"
              customer_impact   = "UNKNOWN"
              incident_priority = var.incident_priority
            }
          }
        }
        output = "cluster_results"
      },
      {
        name        = "create-executive-summary"
        description = "Create executive summary and TLDR from investigation results using inline agent"
        depends     = ["investigate-cluster-health"]
        executor = {
          type = "agent"
          config = {
            agent_id = var.agent_uuid
            use_cli  = true
            message  = "TASK: Create executive summary from investigation results. NO explanations.\n\nINCIDENT: $INCIDENT_PUBLIC_ID - $INCIDENT_TITLE (${var.region} $INCIDENT_SEVERITY)\nSERVICES: $AFFECTED_SERVICES\n\nINVESTIGATION RESULTS:\n$${cluster_results}\n\nOUTPUT REQUIRED:\n1. Executive Summary (2-3 sentences)\n2. Key Findings (bullet points)\n3. Root Cause (if found)\n4. Impact Assessment\n5. Immediate Actions\n6. Recommendations\n\nEnd with: **SLACK_SUMMARY:** [3-5 line summary]\n\nReturn summary immediately, no process explanation."
          }
        }
        output = "executive_summary"
      },
      {
        name        = "upload-investigation-results"
        description = "Upload investigation results and post completion summary to Slack with buttons"
        depends     = ["create-executive-summary", "investigate-cluster-health"]
        executor = {
          type = "tool"
          config = {
            tool_def = merge(jsondecode(file("${path.module}/kubiya_tools/markdown_uploader/tool_definition.json")), {
              with_files = [
                {
                  destination = "/tmp/upload_results.py"
                  content     = file("${path.module}/kubiya_tools/markdown_uploader/upload_results.py")
                }
              ]
            })
            args = {
              slack_token                     = "$${slack_token.token}"
              channel                         = "$${NORMALIZED_CHANNEL_NAME}"
              incident_id                     = "$INCIDENT_PUBLIC_ID"
              incident_title                  = "$INCIDENT_TITLE"
              incident_severity               = "$INCIDENT_SEVERITY"
              affected_services               = "$AFFECTED_SERVICES"
              executive_summary               = "$${executive_summary}"
              cluster_results                 = "$${cluster_results}"
              agent_uuid                      = var.agent_uuid
              investigator_interactive_prompt = "$${investigator_interactive_prompt}"
              region                          = var.region
              dd_environment                  = var.dd_environment
              k8s_environment                 = var.k8s_environment
            }
          }
        }
        output = "upload_summary_status"
      }
    ]
  })

  runner = var.kubiya_runner
}

# Datadog Monitor for Environment-Based Incident Detection
# This creates a monitor that will trigger the webhook when incidents occur with specific environment tags
resource "datadog_monitor" "incident_environment_monitor" {
  count = var.create_notification_rule ? 1 : 0

  name    = "${var.region}-incident-environment-monitor"
  type    = "event-v2 alert"
  message = "Incident detected in ${var.region}-${var.dd_environment} environment @webhook-${kubiya_webhook.datadog_incident_response.name}"

  # Query for incidents with specific environment tags
  query = "events(\"sources:datadog priority:all env:${var.dd_environment}\").rollup(\"count\").last(\"5m\") > 0"

  # Monitor configuration
  monitor_thresholds {
    critical = 0
  }

  # Notification settings
  notify_no_data      = false
  notify_audit        = false
  timeout_h           = 0
  include_tags        = true
  require_full_window = false

  # Tag the monitor
  tags = [
    "env:${var.dd_environment}",
    "team:${var.team_name}",
    "service:incident-response",
    "automation:kubiya",
    "region:${var.region}"
  ]
}

# Optional: Create a Datadog Service for the webhook
resource "datadog_service_definition_yaml" "kubiya_incident_service" {
  count = var.create_service_definition ? 1 : 0
  service_definition = yamlencode({
    schema-version = "v2.2"
    dd-service     = var.service_name
    team           = var.team_name
    description    = "Kubiya AI-powered incident response service"
    tier           = "1"
    type           = "automation"
    languages      = ["terraform"]
    tags = [
      "env:${var.dd_environment}",
      "team:${var.team_name}",
      "service:incident-response",
      "automation:kubiya"
    ]
    integrations = {
      kubiya = {
        webhook-url = kubiya_webhook.datadog_incident_response.url
      }
    }
    contacts = var.service_contacts
  })
}