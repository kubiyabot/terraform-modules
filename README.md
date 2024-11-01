# 🏗️ Kubiya Terraform Modules

This repository contains Terraform modules for deploying and configuring Kubiya AI teammates and their associated resources. These modules enable you to manage your Kubiya platform configuration as code, making it easy to version, replicate, and maintain your AI-powered automation setup.

## 📚 Repository Structure

Each module in this repository represents a complete use case that can be deployed via Terraform or the [Kubiya Web UI](https://app.kubiya.ai):

```
terraform-modules/
├── databricks-solution-engineering/    # Databricks operations use case
│   ├── terraform/                     # IaC configuration
│   │   ├── knowledge/                 # AI knowledge base
│   │   └── prompts/                   # Task prompts
│   └── README.md                      # Use case documentation
│
├── kubernetes-crew/                    # Kubernetes operations use case
│   ├── terraform/                     # IaC configuration
│   │   ├── knowledge/                 # AI knowledge base
│   │   └── prompts/                   # Task prompts
│   └── README.md                      # Use case documentation
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