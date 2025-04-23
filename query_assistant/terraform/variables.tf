# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Query Assistant teammate (e.g., 'query-assistant'). Used to identify the teammate in logs and notifications."
  type        = string
  default     = "query-assistant"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'Users'])."
  type        = list(string)
  default     = ["Admin", "Users"]
}

# Kubiya Runner Configuration
variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners."
  type        = string
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime (shows all outputs and logs when conversing with the teammate)"
  type        = bool
  default     = false
}

variable "source_channel" {
  description = "The Slack channel ID to search for answers to user queries"
  type        = string
}

# New variables for LiteLLM configuration
variable "litellm_api_key" {
  description = "API key for LiteLLM service"
  type        = string
  sensitive   = true
}

variable "search_window" {
  description = "Window for searching Slack messages. Supports various time formats like '30m' (30 minutes), '1h' (1 hour), '2d' (2 days), '72h' (72 hours), etc."
  type        = string
  default     = "72h"
}