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

# Store Jenkins token in Kubiya secrets via API
resource "kubiya_secret" "jenkins_token" {
    name     = "JENKINS_API_TOKEN"
    value    = "${var.jenkins_token_secret}"
    description = "Jenkins API token for authentication"
}

# Configure the source for Jenkins jobs proxy
resource "kubiya_source" "jenkins_source" {
  url  = "https://github.com/kubiyabot/community-tools/tree/main/jenkins"
  runner = var.kubiya_runner
  
  dynamic_config = jsonencode({
    jenkins = {
      url      = var.jenkins_url
      username = var.jenkins_username
      password = var.jenkins_token_secret
      jobs = {
        sync_all = var.sync_all_jobs
        include  = var.include_jobs
        exclude  = var.exclude_jobs
      }
      defaults = {
        long_running_threshold = var.long_running_threshold
        poll_interval          = var.poll_interval
        stream_logs            = var.stream_logs
      }
    }
  })
}

# Create the Jenkins proxy assistant
resource "kubiya_agent" "jenkins_proxy" {
  name         = var.name
  runner       = var.kubiya_runner
  description  = "Jenkins Jobs Conversational Proxy"
  instructions = "I am a Jenkins jobs execution proxy. I can help you trigger and monitor Jenkins jobs, stream logs, and manage job executions."
  environment_variables = {
    JENKINS_URL = var.jenkins_url
  }
  sources = [kubiya_source.jenkins_source.name]
  secrets = ["JENKINS_API_TOKEN"]
  groups  = var.kubiya_groups_allowed_groups
  integrations = var.kubiya_integrations

  depends_on = [kubiya_source.jenkins_source]
}

# Output the teammate jenkins_proxy 
output "jenkins_proxy" {
  value = {
    name         = kubiya_agent.jenkins_proxy.name
    runner       = var.kubiya_runner
    integrations = var.kubiya_integrations
  }
  description = "Details about the deployed Jenkins conversational proxy"
} 