terraform {
  backend "azurerm" {
    resource_group_name  = "devops-giri"
    storage_account_name = "azureblobstorage09"
    container_name       = "tfstate"
    key                  = "vmss-prod.tfstate"
  }
}
