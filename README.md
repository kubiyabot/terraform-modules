# 🏗️ Kubiya Terraform Modules

This repository contains Terraform modules for deploying and configuring Kubiya AI teammates and their associated resources. These modules enable you to manage your Kubiya platform configuration as code, making it easy to version, replicate, and maintain your AI-powered automation setup.

## 📚 Available Modules

### 🎯 Core Modules
| Module | Description | Status |
|--------|-------------|--------|
| `ci_cd_maintainers` | AI-powered CI/CD maintainer for GitHub Actions workflows | ✅ Production Ready |
| `datadog_incident_response` | Automated incident response with Datadog integration | ✅ Production Ready |
| `multi-kubernetes-cluster-orchestration` | Multi-cluster Kubernetes management and orchestration | ✅ Production Ready |
| `query_assistant` | SQL query assistant for database operations | ✅ Production Ready |
| `databricks-solution-engineering` | Databricks platform operations and management | ✅ Production Ready |

### 🔧 Integration Modules
| Module | Description | Status |
|--------|-------------|--------|
| `ask-kubiya-confluence` | Confluence integration for knowledge management | ✅ Production Ready |
| `delegate-jira-tickets` | JIRA ticket delegation and automation | ✅ Production Ready |
| `jenkins_sidekick` | Jenkins CI/CD integration assistant | ✅ Production Ready |

### 🚀 Specialized Modules
| Module | Description | Status |
|--------|-------------|--------|
| `jit-permissions-guardians` | Just-in-time permission management | ✅ Production Ready |
| `pr-review-assistant-full` | Comprehensive PR review automation | 🆕 New |
| `pr-review-assistant-simple` | Lightweight PR review assistant | 🆕 New |
| `terraform_modules_self_service_kiosk` | Self-service Terraform module deployment | ✅ Production Ready |

## 📁 Repository Structure

Each module follows a standardized structure:

```
<module-name>/
├── terraform/
│   ├── main.tf           # Core resource definitions
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── knowledge/        # AI knowledge base (markdown files)
│   ├── prompts/          # Task-specific prompts
│   └── scripts/          # Helper scripts (for webhooks)
└── README.md             # Module documentation
```

## 🚀 Getting Started

1. **Prerequisites**:
   - Terraform installed
   - Kubiya API key
   - Access to Kubiya platform

2. **Configuration**:
```hcl
terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  # API key is set via KUBIYA_API_KEY environment variable
}
```

## 📋 Recent Updates

### January 2025
- ✨ **Module Upgrades**:
  - Enhanced `ci_cd_maintainers` with outputs.tf for better resource tracking
  - Upgraded `datadog_incident_response` with improved webhook configurations
  - Added outputs.tf to `query_assistant` module
  - Renamed `kubernetes-crew` to `multi-kubernetes-cluster-orchestration` with enhanced multi-cluster capabilities
  
- 🗑️ **Deprecated Modules Removed**:
  - Removed `kubernetes-crew-v2` (replaced by multi-kubernetes-cluster-orchestration)
  - Removed `incident_response` (replaced by datadog_incident_response)
  - Removed `chatops` (functionality integrated into other modules)

## 🤝 Contributing

We welcome contributions to expand and improve our use cases! Please follow these guidelines:

1. **Module Structure**:
   - Each use case should have its own directory
   - Include complete Terraform configuration
   - Provide knowledge base and prompts
   - Include comprehensive README

2. **Documentation**:
   - Clear description of the use case
   - Setup instructions
   - Configuration options
   - Example usage

3. **Testing**:
   - Test your configuration
   - Verify knowledge base accuracy
   - Ensure prompts work as expected

4. **Pull Requests**:
   - Create a feature branch
   - Follow existing code style
   - Include documentation updates
   - Add relevant tests

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [Kubiya Documentation](https://docs.kubiya.ai)
- [Kubiya Web UI](https://app.kubiya.ai)
- [Community Support](https://slack.kubiya.ai)

---

Built with ❤️ by [Kubiya.ai](https://kubiya.ai)