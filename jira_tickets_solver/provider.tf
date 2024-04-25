terraform {
  backend "azurerm" {
    storage_account_name = "tfstate25604"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "0.1.5"
    }
  }
}

provider "kubiya" {
  user_key = var.KUBIYA_API_KEY
}

provider "azurerm" {
  features {}
}
