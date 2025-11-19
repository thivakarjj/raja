terraform {
  backend "azurerm" {
    resource_group_name  = "devops-giri"
    storage_account_name = "azureblobstorage08"
    container_name       = "tfstate"
    key                  = "vmss-dev.tfstate"
  }
}
