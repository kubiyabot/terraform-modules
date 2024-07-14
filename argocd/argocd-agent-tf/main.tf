resource "kubiya_agent" "agent" {

  //Mandatory Fields
  name         = var.agent_name
  runner       = var.agent_runners
  description  = var.agent_description
  instructions = var.agent_ai_instructions

  //Optional fields, String
  model = var.agent_llm_model // If not provided, Defaults to "azure/gpt-4"
  //If not provided, Defaults to "ghcr.io/kubiyabot/kubiya-agent:stable"
  image = var.agent_image

  //Optional Fields (omitting will retain the current values): 
  secrets      = ["ARGOCD_PASSWORD"]
  integrations = var.agent_integrations
  users        = ["evgeniy.reichelson@kubiya.ai"]
  groups       = ["Admin"]
  links        = []
  tool_sources = var.agent_tool_sources

  //Objects
  # starters = [
  #   {
  #     name = "Check pod status"
  #     command      = "kubectl get pods"
  #   },
  #   {
  #     name = "Scale deployment"
  #     command      = "kubectl scale deployment my-deployment --replicas=3"
  #   }
  # ]

  # tasks = [
  #   {
  #     name        = "Check Container Image Backoff"
  #     prompt      = "Check all namespaces for pods in ImagePullBackOff state using 'kubectl get pods --all-namespaces'. If found, report them to JIRA."
  #     description = "Use kubectl to find pods in ImagePullBackOff state and report them to JIRA."
  #   },
  #   {
  #     name        = "Update Container Image"
  #     prompt      = "Ask the user for the deployment name and the new image. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, update the deployment's container image using 'kubectl set image deployment/<deployment-name> <container-name>=<new-image>'."
  #     description = "Use kubectl to update the container image for the specified deployment."
  #   },
  #   {
  #     name        = "Scale Deployment"
  #     prompt      = "Ask the user for the deployment name and the desired number of replicas. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, scale the deployment using 'kubectl scale deployment/<deployment-name> --replicas=<number-of-replicas>'."
  #     description = "Use kubectl to scale the specified deployment."
  #   },
  #   {
  #     name        = "Get Deployment Details"
  #     prompt      = "Ask the user for the deployment name. If a specific namespace is provided, filter deployments by that namespace using 'kubectl get deployments -n <namespace>'. Then, get details of the deployment using 'kubectl describe deployment/<deployment-name>'."
  #     description = "Use kubectl to get details of the specified deployment."
  #   }
  # ]

  environment_variables = var.agent_environment_variables
}

output "agent" {
  value = kubiya_agent.agent
}

resource "kubiya_webhook" "webhook" {
  name = "tf-webhook-github-argocd"
  //Please specify the source of the webhook - e.g: 'pull request opened on repository foo'
  source = "Github pull request opened on repository 'deployments'"
  //Provide AI instructions prompt for the agent to follow upon incoming webhook. use {{.event.}} syntax for dynamic parsing of the event
  prompt = "Run argo diff against the following revision: {{.event.pull_request.head.ref}}"
  //Select an Agent which will perform the task and receive the webhook payload
  agent = kubiya_agent.agent.name
  //Please provide a destination that starts with `#` or `@`
  destination = "#devops"
  //optional fields
  //Insert a JMESPath expression to filter by, for more information reach out to https://jmespath.org
  filter = "pull_request[?state == 'open']"
}

output "webhook" {
  value = kubiya_webhook.webhook
}