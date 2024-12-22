# 🔌 Module Configuration
variable "tf_modules_urls" {
  description = "🎯 List of Terraform module URLs to sync from (comma-separated). These modules will be available for self-service deployment! Eg: https://github.com/terraform-aws-modules/terraform-aws-vpc"
  type        = string
  default     = "https://github.com/terraform-aws-modules/terraform-aws-sqs/tree/master"

  validation {
    condition     = can(regex("^(https://[^,]+)(,https://[^,]+)*$", var.tf_modules_urls))
    error_message = "🚫 Module URLs must be a comma-separated list of valid HTTPS URLs. Each URL must start with 'https://'."
  }
}

variable "tf_modules_config_json" {
  description = "Configuration for Terraform modules, including source locations and optional manual configurations"
  type        = string
  default     = <<-EOT
    {
      "aws_vpc": {
        "source": "terraform-aws-modules/vpc/aws",
        "version": "5.0.0",
        "auto_discover": true
      },
      "aws_eks": {
        "source": "terraform-aws-modules/eks/aws",
        "version": "19.15.3",
        "auto_discover": false,
        "instructions": "This module creates an EKS cluster. Ask for the cluster name, region, and desired number of nodes. Default to t3.medium instances if not specified.",
        "variables": {
          "cluster_name": {
            "description": "Name of the EKS cluster",
            "type": "string",
            "required": true
          },
          "cluster_version": {
            "description": "Kubernetes version to use",
            "type": "string",
            "default": "1.27"
          },
          "instance_type": {
            "description": "Type of EC2 instances to use",
            "type": "string",
            "default": "t3.medium"
          },
          "desired_size": {
            "description": "Desired number of worker nodes",
            "type": "number",
            "default": 2
          }
        }
      }
    }
  EOT
}

# 🤖 Teammate Configuration
variable "teammate_name" {
  description = "🏷️ Give your IaC assistant a name! This will be used in logs, notifications, and webhooks"
  type        = string
  default     = "iac-self-service-manager"
}

variable "kubiya_runner" {
  description = "🏃 Infrastructure runner that will execute the Terraform operations. Must have access to required cloud providers"
  type        = string
  default     = "kubiya-hosted"
}

variable "kubiya_integrations" {
  description = "🔗 Which integrations to expose to the IaC assistant? Will be used for provider configuration"
  type        = list(string)
  default     = ["slack"]
}

variable "kubiya_groups_allowed_groups" {
  description = "🔒 Which groups should have access to the IaC assistant? (e.g., ['DevOps', 'Platform', 'Developers'])"
  type        = list(string)
  default     = ["Admin"]
}

# 🔐 Secrets Configuration
variable "kubiya_secrets" {
  description = "🗝️ List of secrets needed for deployment (e.g., cloud credentials, API tokens)"
  type        = list(string)
  default     = []
}

# 🧠 Knowledge Configuration
variable "organizational_knowledge_multiline" {
  description = "📚 Help your assistant understand your organization's specific needs and preferences for infrastructure deployment"
  type        = string
  default     = "Try to adjust to the module names and descriptions to find the best match for user requests when it comes to infrastructure requests."
}

# 🛠️ Debug Configuration
variable "debug_mode" {
  description = "🐛 Enable detailed logging and outputs for troubleshooting"
  type        = bool
  default     = false
}
