# Jenkins CI/CD Maintainer - Terraform Module

This Terraform module creates a Jenkins CI/CD maintainer that monitors Jenkins jobs and pipelines, analyzes failures, and provides detailed solutions to help resolve issues quickly.

## 🚀 Quick Start

### Prerequisites

1. **Kubiya Platform Access**
   - Active Kubiya account
   - Kubiya API key configured

2. **Jenkins Instance**
   - Jenkins server with API access
   - Jenkins API token for authentication
   - Appropriate permissions for job monitoring

3. **Notification Platform** (Optional)
   - Slack workspace with webhook URL
   - Microsoft Teams with webhook URL

### Setup Steps

1. **Configure Jenkins Credentials**
   ```bash
   # Generate Jenkins API token
   # Go to: Jenkins > Manage Jenkins > Manage Users > [Your User] > Configure > API Token
   ```

2. **Set Required Variables**
   ```hcl
   # Required variables
   teammate_name = "jenkins-crew"
   jenkins_jobs = "my-app-build,my-app-deploy,integration-tests"
   kubiya_runner = "your-runner-name"
   
   # Jenkins configuration
   JENKINS_URL = "https://jenkins.company.com"
   JENKINS_USERNAME = "your-username"
   JENKINS_API_TOKEN = "your-api-token"
   
   # Notification configuration
   notification_channel = "#jenkins-alerts"
   enable_slack_notifications = true
   ```

3. **Deploy the Module**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📋 Configuration Options

### Core Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `teammate_name` | Name of the Jenkins CI/CD maintainer | `jenkins-crew` | No |
| `jenkins_jobs` | Comma-separated list of Jenkins jobs to monitor | `""` | No |
| `kubiya_runner` | Kubiya runner to use | - | Yes |

### Jenkins Configuration

| Variable | Description | Required |
|----------|-------------|----------|
| `JENKINS_URL` | Jenkins server URL | Yes |
| `JENKINS_USERNAME` | Jenkins username for API access | Yes |
| `JENKINS_API_TOKEN` | Jenkins API token | Yes |

### Notification Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `notification_channel` | Channel for notifications | `#jenkins-cicd-maintainers-crew` |
| `enable_slack_notifications` | Enable Slack notifications | `true` |
| `enable_teams_notifications` | Enable Teams notifications | `false` |
| `ms_teams_notification` | Use MS Teams for notifications | `false` |

### Advanced Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `monitor_failed_builds_only` | Only monitor failed builds | `true` |
| `enable_branch_filter` | Enable branch filtering | `false` |
| `branch_filter` | Branch name to filter on | `null` |
| `enable_detailed_analysis` | Enable detailed build analysis | `true` |
| `enable_security_scanning` | Enable security scanning | `true` |
| `enable_performance_metrics` | Enable performance metrics | `true` |

## 🛠️ Features

### Automated Analysis
- **Real-time Monitoring**: Monitors Jenkins jobs for failures
- **Log Analysis**: Analyzes build logs and error patterns
- **Root Cause Identification**: Identifies common failure causes
- **Performance Metrics**: Tracks build performance and bottlenecks

### Smart Solutions
- **Contextual Fixes**: Provides specific solutions based on error patterns
- **Code Examples**: Includes code snippets and configuration examples
- **Best Practices**: Suggests Jenkins best practices and optimizations
- **Security Recommendations**: Provides security improvement suggestions

### Integration Capabilities
- **Jenkins API**: Full integration with Jenkins REST API
- **Slack/Teams**: Real-time notifications to your team channels
- **Knowledge Base**: Customizable knowledge base for your organization
- **Secure Credentials**: Secure management of Jenkins credentials

## 📚 Knowledge Base

The module includes comprehensive knowledge bases:

1. **Jenkins Best Practices** (`jenkins_best_practices.md`)
   - Pipeline design principles
   - Security best practices
   - Performance optimization
   - Plugin management

2. **Jenkins Troubleshooting** (`jenkins_troubleshooting.md`)
   - Common build failures
   - Pipeline-specific issues
   - Authentication problems
   - Performance issues

3. **Jenkins Pipeline Optimization** (`jenkins_pipeline_optimization.md`)
   - Performance optimization strategies
   - Resource optimization
   - Advanced techniques
   - Monitoring and metrics

4. **Jenkins Security Practices** (`jenkins_security_practices.md`)
   - Authentication and authorization
   - Credential management
   - Pipeline security
   - Network security

## 🔧 Customization

### Custom Webhook Prompts

You can customize the webhook prompt by providing a custom template:

```hcl
variable "custom_webhook_prompt" {
  description = "Custom prompt template for webhook processing"
  type        = string
  default     = <<-EOT
    Analyze the Jenkins build failure and provide:
    1. Root cause analysis
    2. Specific fix recommendations
    3. Prevention strategies
    4. Related documentation links
  EOT
}
```

### Environment Variables

The module supports various environment variables for fine-tuning:

```hcl
environment_variables = {
  KUBIYA_TOOL_TIMEOUT        = "500"
  ENABLE_DETAILED_ANALYSIS   = "true"
  ENABLE_SECURITY_SCANNING   = "true"
  ENABLE_PERFORMANCE_METRICS = "true"
  LOG_LEVEL                  = "INFO"
}
```

## 🔒 Security Considerations

### Credential Management
- Jenkins credentials are stored securely in Kubiya secrets
- API tokens are masked in logs and outputs
- Use least privilege principle for Jenkins user permissions

### Network Security
- Ensure Jenkins server is accessible from Kubiya
- Use HTTPS for all communications
- Consider VPN or private network access

### Access Control
- Configure appropriate Kubiya user and group access
- Regular review of permissions
- Monitor access logs

## 📊 Monitoring and Troubleshooting

### Health Checks
- Monitor Jenkins API connectivity
- Check webhook delivery status
- Verify notification delivery

### Common Issues

1. **Jenkins API Connection Issues**
   - Verify Jenkins URL and credentials
   - Check network connectivity
   - Ensure API token has required permissions

2. **Webhook Not Working**
   - Verify webhook filter configuration
   - Check Jenkins webhook plugin
   - Review webhook delivery logs

3. **Notification Issues**
   - Verify Slack/Teams webhook URLs
   - Check channel permissions
   - Review notification settings

## 🤝 Support

For issues and questions:
- [Kubiya Support Portal](https://support.kubiya.ai)
- [Community Discord](https://discord.gg/kubiya)
- Email: support@kubiya.ai

## 📄 License

This module is licensed under the same terms as the parent project.
