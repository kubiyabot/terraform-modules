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

resource "kubiya_source" "databricks_tools" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/databricks"
}

resource "kubiya_agent" "databricks_engineer" {
  name         = "databricks-engineer"
  runner       = var.kubiya_runner
  description  = "Your AI-powered Databricks operations engineer"
  instructions = "I am your Databricks operations expert, ready to help with workspace management, cluster operations, jobs, and MLflow."
  model        = "azure/gpt-4"
  integrations = ["slack"]
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.databricks_tools.name]

  environment_variables = {
    LOG_LEVEL                = "INFO"
    NOTIFICATION_CHANNEL     = var.notification_slack_channel
    ENABLE_WORKSPACE_CREATION = tostring(var.enable_workspace_creation)
    ENABLE_UNITY_CATALOG     = tostring(var.enable_unity_catalog)
    ENABLE_MLFLOW_TRACKING   = tostring(var.enable_mlflow_tracking)
  }
}

# Knowledge resources
resource "kubiya_knowledge" "cluster_management" {
  name             = "Databricks Cluster Management"
  groups           = var.groups
  description      = "Knowledge base for Databricks cluster operations"
  labels           = ["databricks", "clusters"]
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_cluster_management != null ? var.prompt_cluster_management : file("${path.module}/knowledge/cluster_management.md")
}

resource "kubiya_knowledge" "workspace_management" {
  name             = "Databricks Workspace Management"
  groups           = var.groups
  description      = "Knowledge base for Databricks workspace operations"
  labels           = ["databricks", "workspace"]
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_workspace_management != null ? var.prompt_workspace_management : file("${path.module}/knowledge/workspace_management.md")
}

resource "kubiya_knowledge" "unity_catalog" {
  count            = var.enable_unity_catalog ? 1 : 0
  name             = "Databricks Unity Catalog"
  groups           = var.groups
  description      = "Knowledge base for Unity Catalog operations"
  labels           = ["databricks", "unity-catalog"]
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_unity_catalog != null ? var.prompt_unity_catalog : file("${path.module}/knowledge/unity_catalog.md")
}

resource "kubiya_knowledge" "mlflow_operations" {
  count            = var.enable_mlflow_tracking ? 1 : 0
  name             = "Databricks MLflow Operations"
  groups           = var.groups
  description      = "Knowledge base for MLflow operations"
  labels           = ["databricks", "mlflow"]
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_mlflow_operations != null ? var.prompt_mlflow_operations : file("${path.module}/knowledge/mlflow_operations.md")
}

output "databricks_engineer" {
  value = kubiya_agent.databricks_engineer
}
