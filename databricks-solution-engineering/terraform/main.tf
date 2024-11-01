terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  # API key is set via KUBIYA_API_KEY environment variable
}

# Databricks tools source
resource "kubiya_source" "databricks_tools" {
  name = "databricks-tools"
  url  = "https://github.com/kubiyabot/community-tools/tree/shaked/databricks-kickass-demo-p2/databricks"
}

# The Databricks Engineer teammate
resource "kubiya_agent" "databricks_engineer" {
  name         = "databricks-engineer"
  runner       = var.kubiya_runner
  description  = "Your AI-powered Databricks operations engineer"
  instructions = "I am your Databricks operations expert, ready to help with workspace management, cluster operations, jobs, and MLflow."
  model        = "azure/gpt-4"
  integrations = compact(["databricks", "slack", var.enable_azure_integration ? "azure" : ""])
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.databricks_tools.name]

  environment_variables = {
    LOG_LEVEL            = "INFO"
    NOTIFICATION_CHANNEL = var.notification_slack_channel
    ENABLE_WORKSPACE_CREATION = var.enable_workspace_creation
    ENABLE_UNITY_CATALOG = var.enable_unity_catalog
    ENABLE_MLFLOW_TRACKING = var.enable_mlflow_tracking
  }
}

# Knowledge resources with override support
resource "kubiya_knowledge" "cluster_management" {
  name             = "databricks-cluster-management"
  description      = "Knowledge for Databricks cluster operations"
  groups           = var.groups
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_cluster_management != null ? var.prompt_cluster_management : file("${path.module}/knowledge/cluster_management.md")
}

resource "kubiya_knowledge" "workspace_management" {
  name             = "databricks-workspace-management"
  description      = "Knowledge for Databricks workspace operations"
  groups           = var.groups
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_workspace_management != null ? var.prompt_workspace_management : file("${path.module}/knowledge/workspace_management.md")
}

resource "kubiya_knowledge" "unity_catalog" {
  count            = var.enable_unity_catalog ? 1 : 0
  name             = "databricks-unity-catalog"
  description      = "Knowledge for Unity Catalog operations"
  groups           = var.groups
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_unity_catalog != null ? var.prompt_unity_catalog : file("${path.module}/knowledge/unity_catalog.md")
}

resource "kubiya_knowledge" "mlflow_operations" {
  count            = var.enable_mlflow_tracking ? 1 : 0
  name             = "databricks-mlflow"
  description      = "Knowledge for MLflow operations"
  groups           = var.groups
  supported_agents = [kubiya_agent.databricks_engineer.name]
  content          = var.prompt_mlflow_operations != null ? var.prompt_mlflow_operations : file("${path.module}/knowledge/mlflow_operations.md")
}

output "databricks_engineer" {
  value = {
    name = kubiya_agent.databricks_engineer.name
    id   = kubiya_agent.databricks_engineer.id
  }
}
