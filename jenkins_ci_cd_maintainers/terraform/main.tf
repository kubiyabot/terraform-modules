terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "~> 1.0"
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
  # Jenkins job list handling
  jenkins_job_list = compact(split(",", var.jenkins_jobs))

  # Construct webhook filter based on variables
  webhook_filter_conditions = concat(
    # Base condition for build events
    ["build.result != null"],

    # Failed builds condition
    var.monitor_failed_builds_only ? ["build.result != 'SUCCESS' && build.result != 'ABORTED'"] : [],

    # Job filtering if specified
    length(local.jenkins_job_list) > 0 ? [format("(%s)",
      join(" || ",
        [for job in local.jenkins_job_list : "build.job_name == '${job}'"]
      )
    )] : [],

    # Branch filtering if enabled and specified
    var.enable_branch_filter && var.branch_filter != null ? ["build.branch == '${var.branch_filter}'"] : []
  )

  webhook_filter = join(" && ", local.webhook_filter_conditions)
}

variable "JENKINS_URL" {
  type        = string
  description = "Jenkins server URL (e.g., https://jenkins.company.com)"
}

variable "JENKINS_USERNAME" {
  type        = string
  description = "Jenkins username for API access"
}

variable "JENKINS_API_TOKEN" {
  type        = string
  sensitive   = true
  description = "Jenkins API token for authentication. Generate from Jenkins user settings."
}

variable "teams_webhook_url" {
  type        = string
  default     = ""
  description = "Microsoft Teams webhook URL for notifications (optional)"
}

# Jenkins Tooling - Allows the CI/CD Maintainer to use Jenkins tools
resource "kubiya_source" "jenkins_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/jenkins"
  description = "Jenkins community tools for CI/CD operations"
}

# Optional: Additional tooling sources for enhanced capabilities
resource "kubiya_source" "git_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/git"
  description = "Git tools for repository operations"
}

resource "kubiya_source" "docker_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/docker"
  description = "Docker tools for containerized CI/CD workflows"
}

# Create secrets for Jenkins credentials
resource "kubiya_secret" "jenkins_url" {
  name        = "JENKINS_URL"
  value       = var.JENKINS_URL
  description = "Jenkins server URL for the CI/CD Maintainer"
}

resource "kubiya_secret" "jenkins_username" {
  name        = "JENKINS_USERNAME"
  value       = var.JENKINS_USERNAME
  description = "Jenkins username for API access"
}

resource "kubiya_secret" "jenkins_api_token" {
  name        = "JENKINS_API_TOKEN"
  value       = var.JENKINS_API_TOKEN
  description = "Jenkins API token for authentication"
}

# Configure the Jenkins CI/CD Maintainer agent
resource "kubiya_agent" "jenkins_cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Jenkins CI/CD maintainer that monitors Jenkins jobs and pipelines, analyzes failures, and provides detailed solutions to help resolve issues quickly."
  instructions = "You are a Jenkins CI/CD expert specializing in Jenkins job and pipeline analysis and troubleshooting. Your primary role is to investigate failed builds, analyze build logs, identify root causes, and provide comprehensive solutions with actionable recommendations for both Freestyle and Pipeline jobs."
  model        = var.llm_model

  secrets = [
    kubiya_secret.jenkins_url.name,
    kubiya_secret.jenkins_username.name,
    kubiya_secret.jenkins_api_token.name,
  ]

  sources = [
    kubiya_source.jenkins_tooling.name,
    kubiya_source.git_tooling.name,
    kubiya_source.docker_tooling.name,
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    var.enable_slack_notifications ? ["slack"] : [],
    var.enable_teams_notifications ? ["teams"] : []
  )

  users  = var.kubiya_users
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT        = tostring(var.tool_timeout)
    DESTINATION_CHANNEL        = var.summary_channel
    ENABLE_DETAILED_ANALYSIS   = tostring(var.enable_detailed_analysis)
    ENABLE_SECURITY_SCANNING   = tostring(var.enable_security_scanning)
    ENABLE_PERFORMANCE_METRICS = tostring(var.enable_performance_metrics)
    LOG_LEVEL                  = var.log_level
    JENKINS_JOB_FILTER         = join(",", local.jenkins_job_list)
  }

  is_debug_mode = var.debug_mode

  labels = ["ci-cd", "jenkins", "devops", "pipeline-analysis"]
}

# Knowledge base for Jenkins best practices
resource "kubiya_knowledge" "jenkins_best_practices" {
  name             = "Jenkins Best Practices"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Comprehensive knowledge base covering Jenkins best practices, common patterns, and troubleshooting guidelines"
  labels           = ["jenkins", "best-practices", "troubleshooting"]
  supported_agents = [kubiya_agent.jenkins_cicd_maintainer.name]
  content          = file("${path.module}/knowledge/jenkins_best_practices.md")
}

# Knowledge base for Jenkins troubleshooting
resource "kubiya_knowledge" "jenkins_troubleshooting" {
  name             = "Jenkins Troubleshooting"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Detailed troubleshooting guide for common Jenkins issues and error patterns"
  labels           = ["jenkins", "troubleshooting", "error-patterns"]
  supported_agents = [kubiya_agent.jenkins_cicd_maintainer.name]
  content          = file("${path.module}/knowledge/jenkins_troubleshooting.md")
}

# Knowledge base for Jenkins pipeline optimization
resource "kubiya_knowledge" "jenkins_pipeline_optimization" {
  name             = "Jenkins Pipeline Optimization"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Performance optimization techniques for Jenkins pipelines and jobs"
  labels           = ["optimization", "performance", "jenkins-pipeline"]
  supported_agents = [kubiya_agent.jenkins_cicd_maintainer.name]
  content          = file("${path.module}/knowledge/jenkins_pipeline_optimization.md")
}

# Knowledge base for Jenkins security best practices
resource "kubiya_knowledge" "jenkins_security_practices" {
  count            = var.enable_security_scanning ? 1 : 0
  name             = "Jenkins Security Best Practices"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Security guidelines and best practices for Jenkins CI/CD pipelines"
  labels           = ["security", "jenkins", "compliance"]
  supported_agents = [kubiya_agent.jenkins_cicd_maintainer.name]
  content          = file("${path.module}/knowledge/jenkins_security_practices.md")
}

# Enhanced webhook configuration for Jenkins
resource "kubiya_webhook" "jenkins_webhook" {
  filter    = local.webhook_filter
  name      = "${var.teammate_name}-jenkins-webhook"
  source    = "Jenkins"
  method    = var.ms_teams_notification ? "teams" : "Slack"
  team_name = var.ms_teams_notification ? var.ms_teams_team_name : null

  prompt = var.custom_webhook_prompt != null ? var.custom_webhook_prompt : templatefile("${path.module}/prompts/jenkins_build_analysis.tpl", {
    enable_summary_channel     = var.enable_summary_channel
    enable_detailed_analysis   = var.enable_detailed_analysis
    enable_security_scanning   = var.enable_security_scanning
    enable_performance_metrics = var.enable_performance_metrics
  })

  agent       = kubiya_agent.jenkins_cicd_maintainer.name
  destination = var.notification_channel

  labels = ["ci-cd", "jenkins-webhook", "build-monitoring"]
}
