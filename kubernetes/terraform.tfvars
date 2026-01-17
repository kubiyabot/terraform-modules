agent_name  = "Kubernetes Administrator"
runners     = "aks-dev"
description = "This agent can perform various Kubernetes tasks using kubectl"
instructions = "You are an AI agent specialized in managing Kubernetes clusters using kubectl. Your tasks include monitoring pod statuses, scaling deployments, updating container images, and reporting issues to JIRA."

model        = "azure/gpt-4"
image        = "kubiya/base-agent:latest"
secrets      = ""
integrations = "github,jira,aws"
users        = "shaked@kubiya.ai"
groups       = "Admin"
links        = ""

starters = [
  {
    display_name = "Check pod status"
    command      = "kubectl get pods"
  },
  {
    display_name = "Scale deployment"
    command      = "kubectl scale deployment my-deployment --replicas=3"
  }
]

tasks = [
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

env_vars = {
  DEBUG      = "1"
  LOG_LEVEL  = "INFO"
}
