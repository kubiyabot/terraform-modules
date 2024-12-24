terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

# Store Jenkins token in Kubiya secrets via API
resource "null_resource" "jenkins_token_name" {
  triggers = {
    secret_name = var.jenkins_token_name
    secret_value = var.jenkins_token_secret
  }

  # Create or update secret
  provisioner "local-exec" {
    command = <<-EOT
      # Check if secret exists
      SECRET_EXISTS=$(curl -s -o /dev/null -w "%%{http_code}" \
        -H "Authorization: Bearer $KUBIYA_API_KEY" \
        "https://api.kubiya.ai/api/v2/secrets/${var.jenkins_token_name}")

      if [ "$SECRET_EXISTS" = "200" ]; then
        # Update existing secret
        curl -X PUT \
          -H "Authorization: Bearer $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "value": "${var.jenkins_token_secret}"
          }' \
          "https://api.kubiya.ai/api/v2/secrets/${var.jenkins_token_name}"
      else
        # Create new secret
        curl -X POST \
          -H "Authorization: Bearer $KUBIYA_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "${var.jenkins_token_name}",
            "value": "${var.jenkins_token_secret}"
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
  url  = "https://github.com/kubiyabot/community-tools/tree/jenkins-operations/jenkins_ops"
  
  dynamic_config = jsonencode({
  jenkins_url = var.jenkins_url
  auth = {
    username     = var.jenkins_username
    password_env = var.jenkins_token_name
  }
  jobs = {
    sync_all = tostring(var.sync_all_jobs)
    include  = var.include_jobs
    exclude  = var.exclude_jobs
  }
  defaults = {
    poll_interval            = var.poll_interval
    long_running_threshold   = var.long_running_threshold
    stream_logs              = tostring(var.stream_logs)
  }
})
  runner = var.kubiya_runner
  depends_on = [null_resource.jenkins_token_name]
}

# Create the Jenkins proxy assistant
resource "kubiya_agent" "jenkins_proxy" {
  name         = var.name
  runner       = var.kubiya_runner
  description  = "Jenkins Jobs Conversational Proxy"
  instructions = "I am a Jenkins jobs execution proxy. I can help you trigger and monitor Jenkins jobs, stream logs, and manage job executions."
  
  sources = [kubiya_source.jenkins_proxy.id]
  secrets = [var.jenkins_token_name]
  groups  = var.kubiya_groups_allowed_groups
  integrations = var.kubiya_integrations

  depends_on = [null_resource.jenkins_token_name]
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