# Azure Databricks Apply Tool

This tool automates the creation and configuration of a Databricks workspace in Azure using Terraform.

## Description

The Azure Databricks Apply tool is a Docker-based utility that clones a specified Git repository, initializes Terraform, and applies the configuration to create a Databricks workspace in Azure. It also sends a notification to a Slack channel with the workspace URL and state file location upon completion.

## Prerequisites

- Azure subscription and necessary permissions
- Git repository with Terraform configuration for Databricks
- Slack workspace and bot token (for notifications)
- Docker environment to run the tool

## Environment Variables

The following environment variables must be set:

- `DB_ACCOUNT_ID`: Databricks account ID
- `DB_ACCOUNT_CLIENT_ID`: Databricks account client ID
- `DB_ACCOUNT_CLIENT_SECRET`: Databricks account client secret
- `GIT_ORG`: GitHub organization name
- `GIT_REPO`: GitHub repository name
- `BRANCH`: Git branch to use
- `DIR`: Directory to clone the repository into
- `ARM_CLIENT_ID`: Azure client ID
- `ARM_CLIENT_SECRET`: Azure client secret
- `ARM_TENANT_ID`: Azure tenant ID
- `ARM_SUBSCRIPTION_ID`: Azure subscription ID
- `PAT`: Personal Access Token for Git repository
- `SLACK_CHANNEL_ID`: Slack channel ID for notifications
- `SLACK_THREAD_TS`: Slack thread timestamp for notifications
- `SLACK_API_TOKEN`: Slack API token for sending notifications

## Arguments

The tool accepts various arguments to customize the Databricks workspace configuration. Key arguments include:

- `workspace_name`: Name of the Databricks workspace (required)
- `region`: Azure region for the workspace (required)
- `storage_account_name`: Name of the storage account for Terraform backend (required)
- `container_name`: Name of the container for Terraform backend (required)
- `resource_group_name`: Name of the resource group for Terraform backend (required)

Additional optional arguments are available for advanced configuration, such as encryption settings, networking options, and update preferences.

## Usage

To use this tool, ensure all required environment variables are set and provide the necessary arguments. The tool will then:

1. Clone the specified Git repository
2. Initialize Terraform with the provided backend configuration
3. Apply the Terraform configuration to create the Databricks workspace
4. Send a Slack notification with the workspace URL and state file location

## Output

Upon successful execution, the tool will output:

- The Databricks workspace URL
- The location of the Terraform state file

This information will also be sent as a message to the specified Slack channel and thread.





# AWS Databricks Apply Tool

This tool automates the creation and configuration of a Databricks workspace in AWS using Terraform.

## Description

The AWS Databricks Apply tool is a Docker-based utility that clones a specified Git repository, initializes Terraform, and applies the configuration to create a Databricks workspace in AWS. It also sends a notification to a Slack channel with the workspace URL upon completion.

## Prerequisites

- AWS account and necessary permissions
- Git repository with Terraform configuration for Databricks
- Slack workspace and bot token (for notifications)
- Docker environment to run the tool

## Environment Variables

The following environment variables must be set:

- `DB_ACCOUNT_ID`: Databricks account ID
- `DB_ACCOUNT_CLIENT_ID`: Databricks account client ID
- `DB_ACCOUNT_CLIENT_SECRET`: Databricks account client secret
- `GIT_ORG`: GitHub organization name
- `GIT_REPO`: GitHub repository name
- `BRANCH`: Git branch to use
- `DIR`: Directory to clone the repository into
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `AWS_DEFAULT_REGION`: AWS default region
- `PAT`: Personal Access Token for Git repository
- `SLACK_CHANNEL_ID`: Slack channel ID for notifications
- `SLACK_THREAD_TS`: Slack thread timestamp for notifications
- `SLACK_API_TOKEN`: Slack API token for sending notifications

## Arguments

The tool accepts various arguments to customize the Databricks workspace configuration. Key arguments include:

- `workspace_name`: Name of the Databricks workspace (required)
- `aws_region`: AWS region for the workspace (required)
- `backend_bucket`: Name of the S3 bucket for Terraform backend (required)
- `backend_region`: AWS region for Terraform backend (required)

Additional optional arguments are available for advanced configuration:

- `enable_vpc`: Enable VPC creation (default: true)
- `enable_privatelink`: Enable PrivateLink (default: false)
- `enable_firewall`: Enable firewall (default: false)
- `enable_hub_and_spoke`: Enable hub and spoke configuration (default: false)

## Usage

To use this tool, ensure all required environment variables are set and provide the necessary arguments. The tool will then:

1. Clone the specified Git repository
2. Initialize Terraform with the provided backend configuration
3. Apply the Terraform configuration to create the Databricks workspace
4. Send a Slack notification with the workspace URL

## Output

Upon successful execution, the tool will output:

- The Databricks workspace URL

This information will also be sent as a message to the specified Slack channel and thread.