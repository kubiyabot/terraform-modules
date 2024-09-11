terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}


# Add a source with tools and usecases
# for the teammate to interact with
resource "kubiya_source" "source" {
  url = "https://github.com/kubiyabot/community-agents/tree/main/kubernetes"
}

resource "kubiya_agent" "kubernetes_sidekick" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4o"
  integrations = var.integrations
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.source.name]

  environment_variables = {
    LOG_LEVEL                        = var.log_level
    USE_CUSTOM_KUBECONFIG            = var.use_custom_kubeconfig ? "1" : "0"
    CUSTOM_KUBECONFIG                = var.custom_kubeconfig
    USE_IN_CLUSTER_CONTEXT           = var.use_in_cluster_context ? "1" : "0"
    ENABLE_CLUSTER_HEALTH_MONITORING = var.enable_cluster_health_monitoring ? "1" : "0"
    CLUSTER_HEALTH_CHECK_INTERVAL    = var.cluster_health_check_interval
    ENABLE_INTELLIGENT_EVENT_SCRAPING = var.enable_intelligent_event_scraping ? "1" : "0"
    ENABLE_KUBECTL_ACCESS            = var.enable_kubectl_access ? "1" : "0"
    ENABLE_HELM_CHART_APPLICATION    = var.enable_helm_chart_application ? "1" : "0"
    ENABLE_ARGO_CD_INTEGRATION       = var.enable_argo_cd_integration ? "1" : "0"
    NOTIFICATION_SLACK_CHANNEL       = var.notification_slack_channel
    KUBIYA_DEBUG                     = var.debug ? "1" : "0"
    DRY_RUN_ENABLED                  = var.dry_run ? "1" : "0"
  }
}

output "kubernetes_sidekick" {
  value = kubiya_agent.kubernetes_sidekick
}
