terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "0.3.8"
    }
  }
}

provider "kubiya" {
}
