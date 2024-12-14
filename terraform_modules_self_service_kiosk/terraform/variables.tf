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

# Secrets (Kubiya Secrets)
variable "kubiya_secrets" {
  description = "List of secrets to pass to the teammate (e.g., AWS credentials)."
  type        = list(string)
  default     = []
}

# Additional Module Knowledge (Optional)
variable "organizational_knowledge_multiline" {
  description = "Additional organizational knowledge we should use to help the teammate understand the Terraform modules."
  type        = string
  # Example:
  default     = "Try to adjust to the module names and descriptions to find the best match for user requests when it comes to infrastructure requests."
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}

variable "tf_modules_urls" {
  description = "Comma-separated list of terraform module URLs to sync and create tools from. Must be a valid URL containing valid Terraform code (variables.tf, main.tf, etc.)"
  type        = string
  default     = "https://github.com/terraform-aws-modules/terraform-aws-sqs/tree/master"
}
