data "azurerm_key_vault_secret" "azuredevops_pat" {
  name         = var.agent_pat_secret_name
  key_vault_id = var.azuredevops_pat_key_vault_id
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "azuredevops" {
  org_service_url       = var.azuredevops_org_service_url
  personal_access_token = data.azurerm_key_vault_secret.azuredevops_pat.value
}
