terraform {
  backend "azurerm" {
    storage_account_name = "tfstate25604"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
