variable "agent_name" {
  description = "Name of the Kubernetes agent"
  type        = string
  default     = "Kubernetes Admin"
}

variable "runners" {
  description = "Runners for the Kubernetes agent"
  type        = string
  default     = "aks-dev"
}

variable "description" {
  description = "Description of the Kubernetes agent"
  type        = string
  default     = "This agent can perform various Kubernetes tasks using kubectl"
}

variable "instructions" {
  description = "Instructions for the Kubernetes agent"
  type        = string
  default     = "You are an AI agent specialized in managing Kubernetes clusters using kubectl. Your tasks include monitoring pod statuses, scaling deployments, updating container images, and reporting issues to JIRA."
}

variable "model" {
  description = "Model to use for the agent"
  type        = string
  default     = "azure/gpt-4"
}

variable "image" {
  description = "Image for the Kubernetes agent"
  type        = string
  default     = "kubiya/base-agent:latest"
}

variable "secrets" {
  description = "Secrets for the Kubernetes agent"
  type        = string
  default     = "JIRA_API_KEY,GITHUB_API_KEY"
}

variable "integrations" {
  description = "Integrations for the Kubernetes agent"
  type        = string
  default     = "github,jira,aws"
}

variable "users" {
  description = "Users for the Kubernetes agent"
  type        = string
  default     = "shaked@kubiya.ai"
}

variable "groups" {
  description = "Groups for the Kubernetes agent"
  type        = string
  default     = "Admin"
}

variable "links" {
  description = "Links for the Kubernetes agent"
  type        = string
  default     = ""
}

variable "starters" {
  description = "Starters for the Kubernetes agent"
  type        = list(object({
    display_name = string
    command      = string
  }))
  default = [
    {
      display_name = "Check pod status"
      command      = "kubectl get pods"
    },
    {
      display_name = "Scale deployment"
      command      = "kubectl scale deployment my-deployment --replicas=3"
    }
  ]
}

variable "tasks" {
  description = "Tasks for the Kubernetes agent"
  type        = list(object({
    name        = string
    prompt      = string
    description = string
  }))
  default = [
    {
      name        = "Check Container Image Backoff"
      prompt      = "Check all namespaces for pods in ImagePullBackOff state using 'kubectl get pods --all-namespaces'. If found, report them to JIRA."
      description = "Use kubectl to find pods in ImagePullBackOff state and report them to JIRA."
    },
    {
      name        = "Update Container Image"
      prompt      = "Ask the user for the deployment name and the new image. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, update the deployment's container image using 'kubectl set image deployment/<deployment-name> <container-name>=<new-image>'."
      description = "Use kubectl to update the container image for the specified deployment."
    },
    {
      name        = "Scale Deployment"
      prompt      = "Ask the user for the deployment name and the desired number of replicas. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, scale the deployment using 'kubectl scale deployment/<deployment-name> --replicas=<number-of-replicas>'."
      description = "Use kubectl to scale the specified deployment."
    },
    {
      name        = "Get Deployment Details"
      prompt      = "Ask the user for the deployment name. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, get details of the deployment using 'kubectl describe deployment/<deployment-name>'."
      description = "Use kubectl to get details of the specified deployment."
    }
  ]
}

variable "env_vars" {
  description = "Environment variables for the Kubernetes agent"
  type        = map(string)
  default = {
    DEBUG      = "1"
    LOG_LEVEL  = "INFO"
  }
}
