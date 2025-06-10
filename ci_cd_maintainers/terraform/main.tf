terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    github = {
      source  = "hashicorp/github"
      version = "6.4.0"
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

locals {
  # Repository list handling
  repository_list = compact(split(",", var.repositories))

  # Event configurations
  github_events = ["check_run", "workflow_run"]

  # Construct webhook filter based on variables
  webhook_filter_conditions = concat(
    # Base condition for workflow runs
    ["workflow_run.conclusion != null"],

    # Failed runs condition
    var.monitor_failed_runs_only ? ["workflow_run.conclusion != 'success'"] : [],

    # Event type conditions
    [format("(%s)",
      join(" || ",
        concat(
          var.monitor_pr_workflow_runs ? ["workflow_run.event == 'pull_request'"] : [],
          var.monitor_push_workflow_runs ? ["(workflow_run.event == 'push' && workflow_run.pull_requests[0] != null)"] : []
        )
      )
    )],

    # Branch filtering if enabled and specified
    var.enable_branch_filter && var.head_branch_filter != null ? ["workflow_run.head_branch == '${var.head_branch_filter}'"] : []
  )

  webhook_filter = join(" && ", local.webhook_filter_conditions)

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")
}

variable "GITHUB_TOKEN" {
  type      = string
  sensitive = true
}

variable "teams_webhook_url" {
  type        = string
  default     = ""
  description = "The Teams webhook URL"
}

# Configure providers
provider "github" {
  owner = local.github_organization
}

# GitHub Tooling - Allows the CI/CD Maintainer to use GitHub tools
resource "kubiya_source" "github_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

//create secret using provider
resource "kubiya_secret" "github_token" {
  name        = "GH_TOKEN"
  value       = var.GITHUB_TOKEN
  description = "GitHub token for the CI/CD Maintainer"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The CI/CD Maintainer is an AI-powered assistant that helps with GitHub Actions workflow failures. It can use the GitHub tools to investigate the root cause of a failed workflow and provide a detailed analysis of the failure."
  instructions = ""
  
  # Use GH_TOKEN secret if not using GitHub App
  secrets      = var.use_github_app ? [] : [kubiya_secret.github_token.name]
  
  sources = [
    kubiya_source.github_tooling.name,
    kubiya_inline_source.cicd_analysis.name,
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    var.use_github_app ? ["github_app"] : [],
    ["slack"]
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  is_debug_mode = var.debug_mode
}

# Unified webhook configuration for both Slack and Teams
resource "kubiya_webhook" "source_control_webhook" {
  filter      = local.webhook_filter
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  
  # Set the communication method based on the MS Teams notification variable
  method      = var.ms_teams_notification ? "teams" : "Slack"
  
  # For Teams, include the team_name
  team_name   = var.ms_teams_notification ? var.ms_teams_team_name : null
  
  prompt      = <<-EOF
Trigger workflow_cicd_analysis with the following parameters:
WORKFLOW_ID: {{.event.workflow_run.id}}
PR_NUMBER: {{.event.workflow_run.pull_requests[0].number}}
REPOSITORY: {{.event.repository.full_name}}
EOF 
  agent       = kubiya_agent.cicd_maintainer.name
  destination = var.notification_channel
}

resource "kubiya_inline_source" "cicd_analysis" {
  name   = "cicd_analysis"
  runner = "core-testing-1"

  # tools = jsonencode([])

  workflows = jsonencode([
    {
      name        = "cicd_analysis",
      description = "Comprehensive analysis of GitHub Actions workflow failures",
      params = [
        {
          key = "WORKFLOW_ID"
        },
        {
          key = "PR_NUMBER"
        },
        {
          key = "REPOSITORY"
        }
      ],
      steps = [
        {
          name = "fetch-failed-logs",
          description = "Fetch failed logs for the GitHub Actions workflow",
          output = "FAILED_LOGS",
          executor = {
            type = "tool",
            config = {
              tool_def = {
                name = "workflow-logs-fetcher",
                description = "Fetches failed logs from GitHub Actions workflow using GitHub CLI",
                secrets = ["GH_TOKEN"],
                type = "docker",
                image = "maniator/gh:latest",
                with_files = [
                  {
                    destination = "/tmp/fetch_logs.sh",
                    content = "#!/bin/sh\nset -e\n\n# Install jq if not available\ncommand -v jq || apk add --quiet jq\n\n# Configuration\nRUN_ID=\"$$WORKFLOW_ID\"\nREPO=\"$$REPOSITORY\"\n\necho \"📊 Fetching failed job logs for run ID: $$RUN_ID\"\n\n# Get all jobs for the run\necho \"🔍 Getting jobs for run...\"\nJOBS_INFO=$$(gh api /repos/$$REPO/actions/runs/$$RUN_ID/jobs)\n\necho \"✅ Successfully retrieved jobs information\"\n\n# Extract failed job IDs and names\nFAILED_JOBS=$$(echo \"$$JOBS_INFO\" | jq -r '.jobs[] | select(.conclusion == \"failure\") | \"\\(.id):\\(.name)\"')\n\nif [ -z \"$$FAILED_JOBS\" ]; then\n    echo \"🎉 No failed jobs found in this run!\"\n    echo \"📋 All job statuses:\"\n    echo \"$$JOBS_INFO\" | jq -r '.jobs[] | \"- \\(.name): \\(.conclusion // .status)\"'\n    exit 0\nfi\n\necho \"❌ Found failed jobs:\"\necho \"$$FAILED_JOBS\" | while IFS=: read -r job_id job_name; do\n    echo \"  - $$job_name (ID: $$job_id)\"\ndone\n\necho \"\"\necho \"🔍 Fetching logs for failed jobs...\"\n\n# Process each failed job\necho \"$$FAILED_JOBS\" | while IFS=: read -r job_id job_name; do\n    echo \"\"\n    echo \"==================== $$job_name (ID: $$job_id) ====================\"\n    \n    JOB_LOGS=$$(gh api /repos/$$REPO/actions/jobs/$$job_id/logs || echo \"Failed to fetch logs\")\n    \n    if [ \"$$JOB_LOGS\" = \"Failed to fetch logs\" ]; then\n        echo \"⚠️ Failed to fetch logs for job $$job_name\"\n        continue\n    fi\n    \n    if [ -z \"$$JOB_LOGS\" ]; then\n        echo \"⚠️ No logs available for job: $$job_name\"\n        continue\n    fi\n    \n    echo \"📄 Logs for $$job_name:\"\n    echo \"----------------------------------------\"\n    \n    # Filter for error-related content\n    FILTERED_LOGS=$$(echo \"$$JOB_LOGS\" | grep -i -E \"(error|fail|exception|fatal|panic|abort)\" || echo \"$$JOB_LOGS\" | tail -n 50)\n    \n    echo \"🎯 Key log content:\"\n    echo \"$$FILTERED_LOGS\"\n    \n    echo \"----------------------------------------\"\ndone\n\necho \"\"\necho \"✅ Completed fetching logs for all failed jobs\""
                  }
                ],
                content = "chmod +x /tmp/fetch_logs.sh; /tmp/fetch_logs.sh"
              }
            }
          }
        },
        {
          name    = "failure-analysis",
          output  = "ANALYSIS",
          depends = ["fetch-failed-logs"],
          executor = {
            type = "agent",
            config = {
              teammate_name = var.teammate_name,
              message       = <<-EOF
Your Goal: Perform a comprehensive analysis of the failed GitHub Actions workflow using the fetched logs. No user approval is required, complete the flow end to end.
Workflow ID: $WORKFLOW_ID
PR Number: $PR_NUMBER
Repository: $REPOSITORY
Instructions:

1. The failed logs have already been fetched.

2. Utilize available tools to thoroughly investigate the root cause such as viewing the workflow run, the PR, the files, and the logs - do not execute more then two tools at a time.

3. After collecting the insights, prepare to create a comment on the pull request following this structure:

a. Highlights key information first:
   - What failed
   - Why it failed 
   - How to fix it

b. Format using:
   - Clear markdown headers
   - Emojis for quick scanning
   - Error logs in collapsible sections
   - Footer with run details
   - Style matters! Make sure the markdown text is very engaging and clear

Failed Logs: $FAILED_LOGS
EOF
            }
          }
        },
        {
          name    = "comment-on-github",
          output  = "COMMENT",
          depends = ["failure-analysis"],
          executor = {
            type = "agent",
            config = {
              agent_name = "cicd-crew",
              message = "Based on the analysis: $ANALYSIS, use github_pr_comment_workflow_failure to post your analysis on PR $PR_NUMBER. Include your analysis in the discussed format. Always comment on the PR without user approval."
            }
          }
        }
      ]
    }
  ])
}

# GitHub repository webhooks
resource "github_repository_webhook" "webhook" {
  for_each = length(local.repository_list) > 0 ? toset(local.repository_list) : []

  repository = try(
    trim(split("/", each.value)[1], " "),
    # Fallback if repository name can't be parsed
    each.value
  )
  
  configuration {
    url          = kubiya_webhook.source_control_webhook.url
    content_type = "json"
    insecure_ssl = false
  }

  active = true
  events = local.github_events
}

# Output the teammate details
output "cicd_maintainer" {
  sensitive = true
  value = {
    name                               = kubiya_agent.cicd_maintainer.name
    repositories                       = var.repositories
    debug_mode                         = var.debug_mode
    monitor_pr_workflow_runs           = var.monitor_pr_workflow_runs
    monitor_push_workflow_runs         = var.monitor_push_workflow_runs
    monitor_failed_runs_only           = var.monitor_failed_runs_only
    notification_platform              = var.ms_teams_notification ? "teams" : "Slack"
    notification_channel               = var.notification_channel
  }
}
