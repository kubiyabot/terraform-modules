terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

locals {
  # Parse the repository list into a proper list format
  repository_list = compact(split(",", var.repositories))
  
  # Generate repository details for use in the script
  repository_details = [
    for repo in local.repository_list : {
      owner = trim(split("/", repo)[0], " ")
      name  = trim(split("/", repo)[1], " ")
    }
  ]
}

# Create a file containing the list of repositories
resource "local_file" "repository_list" {
  content  = join("\n", local.repository_list)
  filename = "${path.module}/repositories.txt"
}

# Resource to manage webhooks using external script
resource "null_resource" "github_webhooks_manager" {
  triggers = {
    repositories = var.repositories
    webhook_url  = var.webhook_url
    events       = join(",", var.events)
    script_path  = "${path.module}/../../scripts/manage_webhooks.sh"
    repos_file   = local_file.repository_list.filename
  }

  # Create webhooks using the script
  provisioner "local-exec" {
    command = "${self.triggers.script_path} ${var.github_token} ${var.webhook_url} ${self.triggers.events} ${self.triggers.repos_file} create"
  }

  # Delete webhooks when the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.script_path} ${var.github_token} ${self.triggers.webhook_url} ${self.triggers.events} ${self.triggers.repos_file} delete"
  }

  depends_on = [local_file.repository_list]
} 