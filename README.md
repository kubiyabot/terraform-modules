# 🚀 K8s Crew: Your Kubernetes Companion

![K8s Crew Icon](https://example.com/k8s-crew-icon.png)

Welcome to **K8s Crew**, your intelligent Kubernetes companion within the Kubiya platform that makes cluster management a breeze. Whether you're a Kubernetes expert or just getting started, **K8s Crew** provides an intuitive interface to manage, monitor, and maintain your clusters effectively.

## 🎯 Deploy in Minutes

Choose your preferred deployment method:

### 1. 🎨 Kubiya Web Interface

The fastest way to get started:

1. Navigate to **Teammates** → **Use Cases** in the Kubiya Web Interface.
2. Click **New Use Case**.
3. Select **K8s Crew**.
4. Click **Continue**.
5. Fill in the configuration variables through our intuitive UI.
6. **Ready to roll!**

> **Prerequisites**: Before deployment, ensure you have a [Local Runner](https://docs.kubiya.ai/docs/kubiya-resources/local-runners/installation) configured. This enables Kubiya to securely integrate with your Kubernetes cluster.

### 2. 🏗️ Terraform Deployment

For infrastructure-as-code enthusiasts:

1. **Clone the official modules repository:**
   ```bash
   git clone https://github.com/kubiyabot/terraform-modules
   cd terraform-modules/kubernetes-crew   ```

2. **Create a `terraform.tfvars` file with minimal configuration:**
   ```hcl
   kubiya_runner              = "my-cluster-runner"
   notification_slack_channel = "#k8s-alerts"   ```

   > The teammate name is now set to **"K8s Crew"** by default.

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan

   # Example output:
   # Terraform will perform the following actions:
   #   + kubiya_agent.kubernetes_crew
   #   + kubiya_integration.kubernetes
   #   + kubiya_notification.slack
   # Plan: 3 to add, 0 to change, 0 to destroy

   terraform apply   ```

## 🌟 Key Features

- 🩺 **Cluster Health Monitoring**: Real-time health checks and proactive issue detection.
- 🕵️ **Intelligent Event Scraping**: Smart event analysis and correlation.
- 🎛️ **Natural Language kubectl**: Execute kubectl commands using plain English.
- ⛵ **Helm Chart Management**: Deploy and manage Helm releases effortlessly.
- 🚢 **Argo CD Integration**: Seamless GitOps workflow integration.
- 🔐 **Flexible Authentication**: Support for custom kubeconfig and in-cluster context.
- 🏠 **Multi-Cluster Support**: Manage multiple clusters from a single interface.
- 💬 **Smart Notifications**: Configurable alerts via Slack.

## 🧠 Knowledge Base Integration

Leverage the power of Kubiya's [Knowledge Resources](https://docs.kubiya.ai/docs/kubiya-resources/knowledge) to provide valuable context to the **K8s Crew** about your Kubernetes environment. You can extend the default knowledge to include specific information on how you manage **your** cluster.

### Customizing Knowledge Resources

- **Create Custom Knowledge**: Add personalized documentation, procedures, and best practices.
- **Override Defaults**: Tailor the knowledge base to fit your organization's needs.
- **Enhance Capabilities**: Provide the crew with deeper insights into your specific cluster setup.

## ⚙️ Customization and Overrides

### Override Default Values

You have the flexibility to override default settings and provide detailed configurations:

- **Prompts and Tasks**: Customize prompts in the `prompts` directory to suit your operational requirements.
- **Environment Variables**: Adjust environment variables to modify behavior.

### Example: Custom Health Check Prompt
