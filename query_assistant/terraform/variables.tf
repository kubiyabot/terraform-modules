# Required Core Configuration
variable "teammate_name" {
  description = "Name of your Query Assistant teammate (e.g., 'ask-kubiya'). Used to identify the teammate in logs and notifications."
  type        = string
  default     = "ask-kubiya"
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
variable "kubiya_api_key" {
  description = "API key for Kubiya"
  type        = string
  sensitive   = true
}

variable "search_window" {
  description = "Window for searching Slack messages. Supports various time formats like '30m' (30 minutes), '1h' (1 hour), '2d' (2 days), '72h' (72 hours), etc."
  type        = string
  default     = "90d"
}

variable "use_dedicated_channel" {
  description = "If true, the Teammate will be the default teammate for the source channel, and will always answer questions on this channel, wihtout abillity to select other teammates"
  type        = bool
  default     = true
}