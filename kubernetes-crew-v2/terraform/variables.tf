# Required Core Configuration
variable "teammate_name" {
  description = "Name of the Kubernetes crew teammate"
  type        = string
  default     = "k8s-watcher"
}

variable "kubiya_runner" {
  description = "Runner (cluster) to use for the teammate"
  type        = string
}

variable "notification_channel" {
  description = "Primary Slack channel for notifications"
  type        = string
  default     = "#devops-oncall"
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps'])."
  type        = list(string)
  default     = ["Admin"]
}

variable "config_map_yaml" {
  description = "Configuration file for the watcher on the K8S level"
  type        = string
  default     = <<YAML
version: "1"
filter:
  watch_for:
    - kind: Pod
      reasons:
        - "*BackOff*"
        - "*Error*"
        - "*Failed*"
      severity: critical
      prompt: |
        🔥 Issue detected with Pod {{.Name}} in {{.Namespace}}
        Status: {{.Phase}}
        Issue: {{.WaitingReason}}
        Details: {{.WaitingMessage}}
        Container State: {{.ContainerState}}
        Restart Count: {{.RestartCount}}
        {{if .ExitCode}}Exit Code: {{.ExitCode}}{{end}}
        {{if .LastTerminationReason}}Last Termination: {{.LastTerminationReason}}
        Last Termination Message: {{.LastTerminationMessage}}{{end}}
    - kind: Node
      reasons:
        - "*NotReady*"
        - "*Pressure*"
      severity: critical
      prompt: |
        ⚠️ Node Issue Detected
        Node: {{.Name}}
        Status: {{.Reason}}
        Message: {{.Message}}
        Time: {{.Timestamp}}
        Count: {{.Count}}
  namespaces:
    - default
    - kubiya
    - staging
    - kube-system
  settings:
    dedup_interval: 10m
    include_labels: true
handler:
  webhook:
    url: "https://webhooksource-kubiya.hooks.kubiya.ai:8443/webhook"
    cert: ""
    tlsSkip: true
resource:
  pod: true
  node: true
  deployment: true
  event: true
YAML
}

variable "debug_mode" {
  description = "Debug mode allows you to see more detailed information and outputs during runtime"
  type        = bool
  default     = false
}