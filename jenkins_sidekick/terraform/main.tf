terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

# Store Jenkins token in Kubiya secrets via API
resource "null_resource" "jenkins_token_secret" {
  triggers = {
    secret_name = var.jenkins_token_secret
    secret_value = var.jenkins_token
  }

  # Create or update secret
  provisioner "local-exec" {
    command = <<-EOT
      # Check if secret exists
      SECRET_EXISTS=$(curl -s -o /dev/null -w "%%{http_code}" \
        -H "Authorization: Bearer $KUBIYA_API_KEY" \
        "https://api.kubiya.ai/api/v2/secrets/${var.jenkins_token_secret}")

      if [ "$SECRET_EXISTS" = "200" ]; then
        # Update existing secret
        curl -X PUT \
          -H "Authorization: Bearer $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "value": "${var.jenkins_token}"
          }' \
          "https://api.kubiya.ai/api/v2/secrets/${var.jenkins_token_secret}"
      else
        # Create new secret
        curl -X POST \
          -H "Authorization: Bearer $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "${var.jenkins_token_secret}",
            "value": "${var.jenkins_token}"
          }' \
          "https://api.kubiya.ai/api/v2/secrets"
      fi
    EOT
  }

  # Delete secret on destroy
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      curl -X DELETE \
      -H "Authorization: Bearer $KUBIYA_API_KEY" \
      "https://api.kubiya.ai/api/v2/secrets/${self.triggers.secret_name}"
    EOT
  }
}

# Configure the source for Jenkins jobs proxy
resource "kubiya_source" "jenkins_proxy" {
  name = "jenkins-proxy"
  url  = "https://github.com/kubiyabot/community-tools/tree/main/jenkins"
  
  dynamic_config = {
    jenkins = {
      url                   = var.jenkins_url
      username             = var.jenkins_username
      token                = var.jenkins_token
      token_secret         = var.jenkins_token_secret
      sync_all             = var.sync_all_jobs
      include_jobs         = var.include_jobs
      exclude_jobs         = var.exclude_jobs
      stream_logs          = var.stream_logs
      poll_interval        = var.poll_interval
      long_running_timeout = var.long_running_threshold
    }
  }

  depends_on = [null_resource.jenkins_token_secret]
}

# Create the Jenkins proxy assistant
resource "kubiya_agent" "jenkins_proxy" {
  name         = var.name
  runner       = var.kubiya_runner
  description  = "Jenkins Jobs Conversational Proxy"
  instructions = "I am a Jenkins jobs execution proxy. I can help you trigger and monitor Jenkins jobs, stream logs, and manage job executions."
  
  sources = [kubiya_source.jenkins_proxy.id]
  secrets = [var.jenkins_token_secret]
  groups  = var.allowed_groups
  integrations = var.integrations

  depends_on = [null_resource.jenkins_token_secret]
}

# Output the proxy details
output "jenkins_proxy_details" {
  value = {
    name         = kubiya_agent.jenkins_proxy.name
    runner       = kubiya_agent.jenkins_proxy.kubiya_runner
    integrations = kubiya_agent.jenkins_proxy.supported_agents
    jenkins_url  = var.jenkins_url
  }
  description = "Details about the deployed Jenkins conversational proxy"
} 