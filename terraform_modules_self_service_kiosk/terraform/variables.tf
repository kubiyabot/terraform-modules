# Teammate Configuration
variable "teammate_name" {
  description = "Name of your Terraform Kiosk teammate (e.g., 'tf-kiosk'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "iac-self-service-manager"
}

variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string
  default     = "default"
}

variable "kubiya_integrations" {
  description = "List of integrations required for the teammate (e.g., ['slack', 'github'])."
  type        = list(string)
  default     = ["slack"]
}

variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

# Terraform Module Configuration in YAML format
variable "tf_module_config_yaml" {
  description = "Terraform module configuration in YAML format."
  type        = string
  default     = "aws_sqs:\n  name: \"AWS SQS\"\n  description: \"Creates an SQS queue with all configurations\"\n  source:\n    location: \"https://github.com/terraform-aws-modules/terraform-aws-sqs\"\n    version: \"master\"\n\naws_s3:\n  name: \"AWS S3\"\n  description: \"Creates an S3 bucket with optional configurations\"\n  source:\n    location: \"https://github.com/terraform-aws-modules/terraform-aws-s3-bucket\"\n    version: \"master\""
}

# Secrets (Kubiya Secrets)
variable "kubiya_secrets" {
  description = "List of secrets to pass to the teammate (e.g., AWS credentials)."
  type        = list(string)
  default     = [
    # Example secrets
    "MY_TOOL_SECRET"
  ]
}

# Additional Module Knowledge (Optional)
variable "module_knowledge_yaml" {
  description = "Additional organizational knowledge we should use to help the teammate understand the Terraform modules."
  type        = string
  # Example:
  default     = "Try to adjust to the module names and descriptions to find the best match for user requests when it comes to infrastructure requests."
}
