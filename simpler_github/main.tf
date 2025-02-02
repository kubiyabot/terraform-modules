terraform {
  required_providers {
    github = {
      source = "hashicorp/github"
      version = "6.4.0"
    }
  }
}

data "github_user" "current" {
  username = "" # Leaving empty will return the authenticated user
}

output "current_github_user" {
  value = data.github_user.current.login
}
