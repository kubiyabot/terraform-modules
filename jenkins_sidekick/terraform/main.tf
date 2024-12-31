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
resource "null_resource" "jenkins_token" {
  triggers = {
    jenkins_token_name = "JENKINS_API_TOKEN"
  }
  
  # Create or update secret
  provisioner "local-exec" {
    command = <<-EOT
      # Check if secret exists
      SECRET_EXISTS=$(curl -s -o /dev/null -w "%%{http_code}" \
        -H "Authorization: UserKey $KUBIYA_API_KEY" \
        "https://api.kubiya.ai/api/v2/secrets/${self.triggers.jenkins_token_name}")

      if [ "$SECRET_EXISTS" = "200" ]; then
        # Update existing secret
        curl -X PUT \
          -H "Authorization: UserKey $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "value": "${var.jenkins_token_secret}"
          }' \
          "https://api.kubiya.ai/api/v2/secrets/${self.triggers.jenkins_token_name}"
      else
        # Create new secret
        curl -X POST \
          -H "Authorization: UserKey $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "${self.triggers.jenkins_token_name}",
            "value": "${var.jenkins_token_secret}"
          }' \
          "https://api.kubiya.ai/api/v2/secrets"
      fi
    EOT
  }


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

  depends_on = [ kubiya_source.jenkins_source ]
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