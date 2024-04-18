terraform {
  backend "azurerm" {
    storage_account_name = "tfstate25604"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    access_key           = var.access_key
  }
}

variable "access_key" {
  type        = string
  description = "Access key for storage account"
}

provider "azurerm" {
  features {}
}
