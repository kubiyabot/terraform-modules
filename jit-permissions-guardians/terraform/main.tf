terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Load knowledge sources
data "http" "jit_access_knowledge" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/jit-permissions-guardians/terraform/knowledge/jit_access.md"
}

# Configure sources
resource "kubiya_source" "enforcer_source" {
  url    = "https://github.com/kubiyabot/community-tools/tree/CORE-748-setup-jit-usecase-with-the-enforcer-being-setup-automatically-with-memory-on-cloud-policy-pulled-dynamic-config-refactor-to-opal/just_in_time_access_proactive"
  runner = var.kubiya_runner
  dynamic_config = jsonencode({
    dd_enabled          = var.dd_enabled
    okta_enabled        = var.okta_enabled
    opa_runner_name    = var.kubiya_runner
    dd_site             = var.dd_enabled ? var.dd_site : ""
    dd_api_key          = var.dd_enabled ? var.dd_api_key : ""
    idp_provider        = var.okta_enabled ? "okta" : "kubiya"
    okta_base_url       = var.okta_enabled ? var.okta_base_url : ""
    okta_client_id      = var.okta_enabled ? var.okta_client_id : ""
    okta_private_key    = var.okta_enabled ? var.okta_private_key : ""
    okta_token_endpoint = var.okta_enabled ? "${var.okta_base_url}/oauth2/v1/token" : ""
    opa_default_policy = <<-EOT
package kubiya.tool_manager

# Default deny all access
default allow = false

# List of admin-only functions and tools
admin_tools = {
    "approve_access_tool",
    "describe_access_request_tool",
    "list_active_access_requests_tool",
    "request_access_tool",
    "view_user_requests_tool",
    "s3_revoke_data_lake_read_4",
    "jit_session_revoke_database_access_to_staging",
    "jit_session_revoke_power_user_access_to_sandbox",
    "jit_session_revoke_database_access_to_staging"
}

restricted_tools = {
    "s3_grant_data_lake_read_4",
    "jit_session_grant_database_access_to_staging",
    "jit_session_grant_power_user_access_to_sandbox",
}

# Allow Administrators to run admin tools
allow {
    group := input.user.groups[_].name
    group == "${var.opa_group_name}"
    admin_tools[input.tool.name]
}

# Allow Administrators to run revoke tools (s3_revoke_*, jit_session_revoke_*)
allow {
    group := input.user.groups[_].name
    group == "${var.opa_group_name}"
    not restricted_tools[input.tool.name]
}

# Allow everyone to run everything except:
# - admin tools
# - grant/revoke prefixed tools
allow {
    not admin_tools[input.tool.name]
    not restricted_tools[input.tool.name]
}
EOT
  })
}

# Configure auxiliary request tools
resource "kubiya_source" "aws_jit_tools" {
  url            = "https://github.com/kubiyabot/community-tools/tree/main/aws_jit_tools"
  dynamic_config = var.config_json
  runner         = var.kubiya_runner
}

# Create knowledge base
resource "kubiya_knowledge" "jit_access" {
  name        = "JIT Access Management Guide"
  groups      = var.kubiya_groups_allowed_groups
  description = "Knowledge base for JIT access management and troubleshooting"
  labels = ["aws", "jit", "access-management"]
  supported_agents = [kubiya_agent.jit_guardian.name]
  content     = data.http.jit_access_knowledge.response_body
}

resource "null_resource" "runner_env_setup" {
  triggers = {
    runner     = var.kubiya_runner
    webhook_id = kubiya_webhook.webhook.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X PUT \
      -H "Authorization: UserKey $KUBIYA_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "uuid": "${kubiya_agent.jit_guardian.id}",
        "environment_variables": {
          "KUBIYA_TOOL_TIMEOUT": "${var.kubiya_tool_timeout}",
          "REQUEST_ACCESS_WEBHOOK_URL": "${kubiya_webhook.webhook.url}"
        }
      }' \
      "https://api.kubiya.ai/api/v1/agents/${kubiya_agent.jit_guardian.id}"
    EOT
  }
  depends_on = [
    kubiya_webhook.webhook
  ]
}

resource "kubiya_webhook" "webhook" {
  //mandatory fields
  //Please specify a unique name to identify this webhook
  name = "${var.teammate_name} JIT webhook"
  //Please specify the source of the webhook - e.g: 'pull request opened on repository foo'
  source = "JIT"
  //Provide AI instructions prompt for the agent to follow upon incoming webhook. use {{.event.}} syntax for dynamic parsing of the event
  prompt = "Sum up this just in time access request. Here is all the relevant data (no need to run describe tool).. request_id: {{.event.request_id}}, requested_by: {{ .event.user_email}}, requested to run tool {{.event.tool_name}} with parameters {{.event.tool_params}}. requested for a duration of {{.event.requested_ttl}}"
  //Select an Agent which will perform the task and receive the webhook payload
  agent = kubiya_agent.jit_guardian.name
  //Please provide a destination that starts with `#` or `@`
  destination = var.approvers_slack_channel
  //optional fields
  //Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org
  filter      = ""

}

# Configure the JIT Guardian agent
resource "kubiya_agent" "jit_guardian" {
  name          = var.teammate_name
  runner        = var.kubiya_runner
  description   = "AI-powered AWS JIT permissions guardian"
  model         = "azure/gpt-4o"
  instructions  = ""
  sources = [kubiya_source.enforcer_source.name, kubiya_source.aws_jit_tools.name]
  integrations  = var.kubiya_integrations
  users = []
  groups        = var.kubiya_groups_allowed_groups
  is_debug_mode = var.debug_mode

  lifecycle {
    ignore_changes = [
      environment_variables
    ]
  }
}

# Output the teammate details
output "jit_guardian" {
  value = {
    name                       = kubiya_agent.jit_guardian.name
    approvers_slack_channel    = var.approvers_slack_channel
    request_access_webhook_url = kubiya_webhook.webhook.url
  }
}


/*

https://github.com/kubiyabot/community-tools/tree/CORE-748-setup-jit-usecase-with-the-enforcer-being-setup-automatically-with-memory-on-cloud-policy-pulled-dynamic-config-refactor-to-opal/just_in_time_access_proactive

{
  "dd_api_key": "27be3b25f8885aa55231f0fb0417354a",
  "dd_enabled": true,
  "dd_site": "us5.datadoghq.com",
  "idp_provider": "okta",
  "okta_base_url": "https://dev-58224024.okta.com",
  "okta_client_id": "0oal7hlra2S6TGaNI5d7",
  "okta_enabled": true,
  "okta_private_key": "-----BEGIN PRIVATE KEY----- MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDOhzwqD4JGSsdM H56QwT5o+Fxy6Dx64gPhsZCnEBHM+lkv4PSHPx3PTgFq/JpGBYECOGoCX8+aF8fV 6fTdvm+BGgpy1EJqSGam/T6unzOiu/nu7XpdAThXfmTBbext3kADX7jhGYXlVhyo r2fdd03uwt8er9JunIvrD6SOWv1P7WjrbyKWO5MYVZVTILFgeTn5DDYmos04Rgxk TvZPs1OW65ub9LkvJmHg1plb+7nRgSSffNkMRP0llK9QXAvM1CLtvVDjQwCxfQX6 eqbSPFmPomLQmZ6j8jKPoCqE5x5i6ogJkqrlUFkoEpQt9oqoX9hTwtiiVvlj2aKZ hXgqcrajAgMBAAECggEAJcbHwvvGPPxFmw93jgvC0imHo38GPQXlZt13U4+VafRq 5t6Ta7+oQLiIetzMjT1JfTH7dga3bvylkWOzZfIE7Ezql1lq8ozetfHBiuhU5hHT JBhtFuD3wM0+OcFVCz2pYNSb+RSVkL7hDBvVeEVvzFn5vN+1MoVQ9ISOeXl8Nyem A5BP5Lr23i5R+w+GVVageAjb2NZgXv+xdCqdTeRBn9/f0ZU1kEjutah3b/RpZmuA FfhxOqQvKWAxIbIraxw3V9+DEIwojDk7jWvzj2S0oIFU8pea1l4mqBNpqI3rX88T HRcP1xjnvZ9YEpLRbCV279uzCO43erQlNSh28NVtwQKBgQD2qSPsxGEP/zHv1gIZ jv5R94WaxNIRP3ELghJp3c7ugYqHYjbUd5IQkC2yUUkkLjyQzrWynYOiynkG/bIO A4QPoNNdIrvc+zNfFTH7kRF1yG+RG9vRjRss/5RlhoMlPg9W01TQsLvMu98/w8p7 zCbJFNjkrBdd/1P8FZ7Wrt+gQQKBgQDWWRg2yl8YmwJZghWltoe8ApCzMzZ1BVAh SzgV/vy38LuqTYQ1eS2uztBohbg5uhlf/HXNbnVJ4PfKaKdiLwQPqwfvzM12HXYQ ziqXC3lUD64jUWeiA/5u1IVqo5MCqecOkdI+O0UesnVjma4Pao9rc8bWBMPPhfkR jbiFoPBd4wKBgQD0iMLA2/+OKGWNbBEw3X5sLIQb57yKtOaRjiZLJkccVPjNNyU8 hj4chZOIEOX+JIiO1x9zMI1sOma585EuK3YlOD/TObgdYDyRqyWeTTeOGWPh7EiE +utSNR8dd7lUlq4GWgTf0Bae5jJxuN1o1gAtoalVKvcPjS3p4FVUaJHzAQKBgQCe dZUKBEeTCB0PkLRyImNr4TWZ1LVgg0H+qv3WfP/U95m0x8OCSIg2H9xAOQK9Yk+Z /ygTa6I3sKFeuEltszY8YwLmCzClLhh3SgKAUVIri7//ihGj23H/+wp6kFyA7pvK 0JBtwyFRFTrlG9pquSs3k4qd8z3Sr8c2a9/KofSwYwKBgEoNuB8leeoKvrrFmMuh z8YAuZWwC+Od1NdhAle8yJMEhiAV4zS2wc8qcHb4s7pEZaYthkpvkHwRGSabhKMr D9mYquEjLLG901MypwyrsTA0H/WCh4nn7/1ldNT54LcHy+hTnBNfqlrcj+vBFE5B D4Rq/DTtWiRqI+OjNys6QZwC -----END PRIVATE KEY-----",
  "okta_token_endpoint": "https://dev-58224024.okta.com/oauth2/v1/token",
  "opa_default_policy": "    package kubiya.tool_manager\n\n    # Default deny all access\n    default allow = false\n\n    # List of admin-only functions and tools\n    admin_tools = {\n        \"list_active_access_requests\",\n        \"search_access_requests\",\n        \"approve_tool_access_request\",\n        \"get_user\",\n        \"search_users\",\n        \"create_group\",\n        \"update_group\",\n        \"delete_group\",\n        \"get_group\",\n        \"list_members\",\n        \"add_member\",\n        \"remove_member\",\n        \"jit_session_revoke_database_access_to_staging\",\n        \"s3_revoke_data_lake_read\"\n    }\n\n    restricted_tools = {\n        \"list_users\",\n        \"list_groups\",\n        \"jit_session_grant_database_access_to_staging\",\n        \"s3_grant_data_lake_read\"\n    }\n\n    # Allow Administrators to run admin tools\n    allow {\n        group := input.user.groups[_].name\n        group == \"Admin\"\n        admin_tools[input.tool.name]\n    }\n\n    # Allow Administrators to run revoke tools (s3_revoke_*, jit_session_revoke_*)\n    allow {\n        group := input.user.groups[_].name\n        group == \"Admin\"\n        not restricted_tools[input.tool.name]\n    }\n\n    # Allow everyone to run everything except:\n    # - admin tools\n    # - grant/revoke prefixed tools\n    allow {\n        not admin_tools[input.tool.name]\n        not restricted_tools[input.tool.name]\n    }",
  "opa_runner_name": "mevratm"
}


msg":"Enforce request:","request":

{
  "user":{
    "email":"mevrat.avraham@kubiya.ai",
    "groups":[
      {"id":"a1c68f8f-5090-46a8-9ce0-dd71ac4630f8","name":"Admin"},
      {"id":"b1d43f48-2b63-475c-a3ee-b78c63388683","name":"Users"},
      {"id":"50044d12-1e4b-42c7-b206-03d91d4cfda1","name":"group-for-tasks-1"},
      {"id":"69abda0c-2bc9-402e-a36e-810bb589310b","name":"TestEnforcer"}
    ]
  },
  "tool":{
    "source_url":"",
    "name":"view_user_requests",
    "parameters":{
      "user_email":"mevrat.avraham@kubiya.ai"
      }
  },
  "source":{
    "url":"https://github.com/kubiyabot/community-tools/tree/CORE-748-setup-jit-usecase-with-the-enforcer-being-setup-automatically-with-memory-on-cloud-policy-pulled-dynamic-config-refactor-to-opal/just_in_time_access_proactive",
    "id":"391b64f8-32a0-45ec-aa57-96b4248f4556"
    }
  }
}
{"time":"2025-01-12T14:47:44.583030009Z","level":"INFO","msg":"Valid request:","approved_request":null}
{"time":"2025-01-12T14:47:44.606028861Z","level":"INFO","msg":"checking opa policy"}
{"time":"2025-01-12T14:47:44.606194697Z","level":"ERROR","msg":"failed to evaluate policy","email":"mevrat.avraham@kubiya.ai","error":"cannot evaluate empty query"}
[GIN] 2025/01/12 - 14:47:44 | 500 | 145.182394ms | 10.224.2.223 | POST "/enforce"
{"time":"2025-01-12T14:47:52.632436457Z","level":"INFO","msg":"start to clean up expired requests"}
{"time":"2025-01-12T14:47:53.009697234Z","level":"INFO","msg":"finished to clean up expired requests"}
{"time":"2025-01-12T14:48:01.036134133Z","level":"INFO","msg":"Enforce request:","request":{"user":{"email":"mevrat.avraham@kubiya.ai","groups":[{"id":"a1c68f8f-5090-46a8-9ce0-dd71ac4630f8","name":"Admin"},{"id":"b1d43f48-2b63-475c-a3ee-b78c63388683","name":"Users"},{"id":"50044d12-1e4b-42c7-b206-03d91d4cfda1","name":"group-for-tasks-1"},{"id":"69abda0c-2bc9-402e-a36e-810bb589310b","name":"TestEnforcer"}]},"tool":{"source_url":"","name":"request_tool_access","parameters":{"request_id":"view_user_requests_error_policy_enforcement","ttl":"1h"}},"source":{"url":"https://github.com/kubiyabot/community-tools/tree/CORE-748-setup-jit-usecase-with-the-enforcer-being-setup-automatically-with-memory-on-cloud-policy-pulled-dynamic-config-refactor-to-opal/just_in_time_access_proactive","id":"391b64f8-32a0-45ec-aa57-96b4248f4556"}}}
{"time":"2025-01-12T14:48:01.059026756Z","level":"INFO","msg":"Valid request:","approved_request":null}
{"time":"2025-01-12T14:48:01.081867081Z","level":"INFO","msg":"checking opa policy"}
{"time":"2025-01-12T14:48:01.082015339Z","level":"ERROR","msg":"failed to evaluate policy","email":"mevrat.avraham@kubiya.ai","error":"cannot evaluate empty query"}
 */