terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

# Local variables for shell scripts and tools - jsonencode handles escaping automatically  
locals {
  # Read shell scripts and substitute variables
  normalize_channel_script = file("${path.module}/scripts/normalize-channel-name.sh")
  
  post_investigation_start_script = file("${path.module}/scripts/post-investigation-start.sh")
  
  prepare_investigator_prompt_script = replace(
    file("${path.module}/scripts/prepare-investigator-prompt.sh"),
    "$${REGION}", var.region
  )
  
  # Load tool definitions
  markdown_uploader_tool_def = jsondecode(file("${path.module}/kubiya_tools/markdown_uploader/tool_definition.json"))
  markdown_uploader_script = file("${path.module}/kubiya_tools/markdown_uploader/upload_results.py")
  
  # Create the final workflow using jsonencode to ensure proper JSON data types
  workflow_json = jsonencode({
    name = "${var.region}-incident-workflow-dag"
    description = "${title(var.region)} Production incident response workflow with AI investigation and Slack integration"
    params = {
      incident_id = "$INCIDENT_PUBLIC_ID"
      incident_title = "$INCIDENT_TITLE"
      incident_severity = "$INCIDENT_SEVERITY"
      incident_priority = var.incident_priority
      incident_body = "$INCIDENT_MSG"
      incident_url = "$INCIDENT_URL"
      incident_source = "datadog"
      incident_owner = var.incident_owner
      slack_channel_id = "#inc-$INCIDENT_PUBLIC_ID-$INCIDENT_TITLE"
      notification_channels = var.notification_channels
      escalation_channel = var.escalation_channel
      investigation_timeout = var.investigation_timeout
      max_retries = var.max_retries
      customer_impact = "UNKNOWN"
      affected_services = "NA"
      dd_environment = var.dd_environment
      k8s_environment = var.k8s_environment
      region = var.region
      agent_uuid = var.agent_uuid
      normalize_channel_name = "true"
    }
    env = {
      KUBIYA_USER_EMAIL = "$${KUBIYA_USER_EMAIL}"
      KUBIYA_API_KEY = var.kubiya_api_key
      KUBIYA_USER_ORG = "$${KUBIYA_USER_ORG}"
      KUBIYA_AUTOMATION = "1"
      INCIDENT_SEVERITY = var.default_incident_severity
      INCIDENT_PRIORITY = var.default_incident_priority
    }
    steps = [
      {
        name = "normalize-channel-name"
        description = "Normalize the channel name by replacing spaces with underscores and converting to lower case"
        command = local.normalize_channel_script
        depends = []
        executor = {
          type = "command"
          config = {}
        }
        output = "NORMALIZED_CHANNEL_NAME"
        continueOn = {
          failure = true
        }
      },
      {
        name = "setup-slack-integration"
        description = "Initialize Slack integration for incident communications"
        executor = {
          type = "kubiya"
          config = {
            url = "api/v1/integration/slack/token/1"
            method = "GET"
            silent = false
          }
        }
        depends = ["normalize-channel-name"]
        output = "slack_token"
      },
      {
        name = "post-investigation-start"
        command = local.post_investigation_start_script
        description = "Send investigation start notification to Slack"
        executor = {
          type = "command"
          config = {}
        }
        depends = ["setup-slack-integration"]
        output = "investigation_start_message"
        continueOn = {
          failure = true
        }
      },
      {
        name = "prepare-investigator-prompt"
        command = local.prepare_investigator_prompt_script
        description = "Prepare interactive prompt for follow-up agent investigation"
        executor = {
          type = "command"
          config = {}
        }
        depends = ["setup-slack-integration"]
        output = "investigator_interactive_prompt"
      },
      {
        name = "investigate-cluster-health"
        description = "AI-powered cluster investigation for production incident response"
        executor = {
          type = "agent"
          config = {
            agent_id = var.agent_uuid
            use_cli = true
            message = "INVESTIGATE INCIDENT $${incident_id} - $${incident_title} (${var.region} $${dd_environment})\\n\\nIMMEDIATE TASK: Return only investigation findings, NO explanations.\\n\\nSERVICES: $${affected_services}\\nSEVERITY: $${incident_severity}\\n\\nFOCUS AREAS:\\n1. Service status and errors\\n2. TLS/Certificate issues\\n3. Resource constraints\\n4. Recent failures\\n\\nREQUIRED OUTPUT FORMAT:\\n- Root cause (if found)\\n- Error patterns\\n- Failed services\\n- Resource issues\\n- Remediation steps\\n\\nDO NOT explain what you're doing. Return findings immediately."
            vars = {
              incident_id = "$${incident_id}"
              incident_title = "$${incident_title}"
              incident_severity = "$${incident_severity}"
              affected_services = "$${affected_services}"
              customer_impact = "$${customer_impact}"
              incident_priority = "$${incident_priority}"
            }
          }
        }
        depends = ["post-investigation-start", "prepare-investigator-prompt"]
        output = "cluster_results"
        continueOn = {
          failure = true
          output = [
            "ERROR: Sorry, I had an issue",
            "Agent-manager not found",
            "Stream error",
            "INTERNAL_ERROR",
            "stream ID",
            "received from peer",
            "re:stream error.*INTERNAL_ERROR",
            "exit code 1",
            "API key",
            "command failed",
            "Kubiya CLI"
          ]
          markSuccess = false
        }
      },
      {
        name = "create-executive-summary"
        description = "Create executive summary and TLDR from investigation results using inline agent"
        executor = {
          type = "agent"
          config = {
            agent_id = var.agent_uuid
            use_cli = true
            message = "TASK: Create executive summary from investigation results. NO explanations.\\n\\nINCIDENT: $${incident_id} - $${incident_title} (${var.region} $${incident_severity})\\nSERVICES: $${affected_services}\\n\\nINVESTIGATION RESULTS:\\n$${cluster_results}\\n\\nOUTPUT REQUIRED:\\n1. Executive Summary (2-3 sentences)\\n2. Key Findings (bullet points)\\n3. Root Cause (if found)\\n4. Impact Assessment\\n5. Immediate Actions\\n6. Recommendations\\n\\nEnd with: **SLACK_SUMMARY:** [3-5 line summary]\\n\\nReturn summary immediately, no process explanation."
          }
        }
        depends = ["investigate-cluster-health"]
        output = "executive_summary"
        continueOn = {
          failure = true
        }
      },
      {
        name = "upload-investigation-results"
        description = "Upload investigation results and post completion summary to Slack with buttons"
        depends = ["create-executive-summary", "investigate-cluster-health"]
        executor = {
          type = "tool"
          config = {
            tool_def = merge(local.markdown_uploader_tool_def, {
              with_files = [
                {
                  destination = "/tmp/upload_results.py"
                  content = local.markdown_uploader_script
                }
              ]
            })
            args = {
              slack_token = "$${slack_token.token}"
              channel = "$${NORMALIZED_CHANNEL_NAME}"
              incident_id = "$${incident_id}"
              incident_title = "$${incident_title}"
              incident_severity = "$${incident_severity}"
              affected_services = "$${affected_services}"
              executive_summary = "$${executive_summary}"
              cluster_results = "$${cluster_results}"
              agent_uuid = "$${agent_uuid}"
              investigator_interactive_prompt = "$${investigator_interactive_prompt}"
              region = "$${region}"
              dd_environment = "$${dd_environment}"
              k8s_environment = "$${k8s_environment}"
            }
          }
        }
        output = "upload_summary_status"
        continueOn = {
          failure = true
        }
      }
    ]
  })
}

# Datadog Webhook Integration for Kubiya Incident Response
resource "datadog_webhook" "kubiya_incident_response" {
  name = var.webhook_name
  url  = var.kubiya_webhook_url

  # Payload containing the incident response workflow
  payload = local.workflow_json

  # Headers for Kubiya API integration
  custom_headers = jsonencode({
    "Authorization" = "UserKey ${var.kubiya_api_key}",
    "Accept" = "text/event-stream",
    "Content-Type" = "application/json"
  })

  # Encode variables for webhook payload
  encode_as = "json"
}

# Optional: Create a Datadog Service for the webhook
resource "datadog_service_definition_yaml" "kubiya_incident_service" {
  count           = var.create_service_definition ? 1 : 0
  service_definition = yamlencode({
    schema-version = "v2.2"
    dd-service     = var.service_name
    team           = var.team_name
    description    = "Kubiya AI-powered incident response service"
    tier           = "1"
    type           = "automation"
    languages      = ["terraform"]
    tags = [
      "env:${var.environment}",
      "team:${var.team_name}",
      "service:incident-response",
      "automation:kubiya"
    ]
    integrations = {
      kubiya = {
        webhook-url = datadog_webhook.kubiya_incident_response.url
      }
    }
    contacts = var.service_contacts
  })
}