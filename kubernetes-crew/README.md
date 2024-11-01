# 🚀 Kubernetes Crew

*Your intelligent Kubernetes companion within the Kubiya platform that makes cluster management a breeze. Whether you're a Kubernetes expert or just getting started, **Kubernetes Crew** provides an intuitive interface to manage, monitor, and maintain your clusters effectively.*

![Kubernetes Banner](https://github.com/user-attachments/assets/02d35010-a05a-4b36-b912-2417aba6575d)

## 🎯 Overview

Kubernetes Crew is an AI-powered teammate that helps you manage Kubernetes clusters through natural language. What makes it unique is its ability to:
- Learn and adapt from every interaction
- Handle complex operations through simple conversations
- Execute scheduled tasks automatically
- Integrate with your existing tools and workflows

## 🚀 Getting Started

### 1. 🎨 Kubiya Web Interface

The fastest way to get started:

1. Navigate to **Teammates** → **Use Cases** in Kubiya
2. Click **New Use Case** and select **Kubernetes Crew**
3. Configure your deployment preferences
4. Start interacting via Slack or scheduled tasks!

### 2. 🏗️ Terraform Deployment

For infrastructure-as-code deployment:
```bash
git clone https://github.com/kubiyabot/terraform-modules
cd terraform-modules/kubernetes-crew
```

2. Create a minimal `terraform.tfvars`:
```hcl
kubiya_runner              = "my-cluster-runner"
notification_slack_channel = "#k8s-alerts"
```

3. Deploy:
```bash
terraform init
terraform apply
```

## 🗣️ Interaction Methods

### 1. Summoning Your Crew

There are three ways to interact with your Kubernetes Crew:

#### Via Slack Channels
1. **Add Kubiya to your channel**: Invite the Kubiya app to your desired Slack channel
2. **Summon the crew**: Use any of these methods:
   - Natural language: `@Kubiya check cluster health`
   - Direct crew summon: `@Kubiya crew check cluster health`
   - Force execution: `@Kubiya !crew list all pods in production`

> 💡 Using the `!` prefix bypasses the classifier and forces the crew to handle your request

#### Scheduled Tasks
The crew can be configured to automatically run tasks on a schedule:
```plaintext
Every morning at 9 AM:
> Running daily health check...
> ✓ Cluster status: Healthy
> ✓ Resource usage: Normal
> ✓ Pending alerts: None
```

#### Event-Triggered Tasks
The crew responds automatically to:
- Webhook events
- Monitoring alerts
- CI/CD triggers
- Custom events

### 2. Interaction Examples

```plaintext
# Natural language
@Kubiya how's our cluster doing?

# Direct crew summon
@Kubiya crew scale the frontend deployment

# Force execution
@Kubiya !crew get pods in kube-system namespace
```

## 🎯 Built-in Capabilities

The crew comes with pre-configured knowledge and prompts for common operations:

### Application Lifecycle
```plaintext
@Kubiya I need to deploy a new microservice
> I'll help you set up the new application. Let me ask a few questions:
> 1. What type of application is this?
> 2. What resources will it need?
> 3. Any specific security requirements?
```

### Capacity Planning
```plaintext
@Kubiya Analyze cluster capacity for next month
> I'll check:
> ✓ Current resource usage trends
> ✓ Growth patterns
> ✓ Optimization opportunities
> Would you like a detailed report?
```

### Health Monitoring
```plaintext
@Kubiya Check production namespace health
> Running comprehensive health check:
> ✓ Node status
> ✓ Pod health
> ✓ Resource utilization
> ✓ Network connectivity
```

## 🧠 Extensible Knowledge

### Adding Custom Knowledge

1. Create markdown files in the `knowledge` directory:
```bash
kubernetes-crew/
└── knowledge/
    ├── runbooks/
    ├── procedures/
    └── best_practices/
```

2. The crew automatically incorporates this knowledge into its responses and recommendations.

### Custom Prompts

Define new capabilities in the `prompts` directory:
```bash
kubernetes-crew/
└── prompts/
    ├── app_creation.md
    ├── capacity_check.md
    ├── deployment_monitor.md
    └── health_check.md
```

## 🔄 Continuous Learning

The crew improves through:
- Learning from your feedback
- Understanding your cluster's patterns
- Adapting to your team's practices
- Building context about your applications

## 🛠️ Integration Capabilities

Seamlessly works with:
- GitOps workflows (Argo CD, Flux)
- CI/CD pipelines
- Monitoring tools
- Security scanners
- Custom webhooks

## 📚 Additional Resources

- [How to Use Your Teammate](https://docs.kubiya.ai/docs/get-started/use-your-teammate)
- [Slack Integration Guide](https://docs.kubiya.ai/docs/integrations/slack)
- [Detailed Documentation](https://docs.kubiya.ai/kubernetes-crew)
- [Community Support](https://slack.kubiya.ai)

---

Ready to transform your Kubernetes operations? Deploy **Kubernetes Crew** today! 🚀
