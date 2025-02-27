terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "example" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

locals {
  name = module.naming.machine_learning_workspace.name_unique
  tags = {
    scenario = "default AI Foundry"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.example.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.example.name
}

resource "azurerm_key_vault" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

module "ai_services" {
  source                             = "Azure/avm-res-cognitiveservices-account/azurerm"
  version                            = "0.6.0"
  resource_group_name                = azurerm_resource_group.example.name
  kind                               = "AIServices"
  name                               = module.naming.cognitive_account.name_unique
  location                           = var.location
  enable_telemetry                   = var.enable_telemetry
  sku_name                           = "S0"
  public_network_access_enabled      = true # required for AI Foundry
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
  tags                               = local.tags
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "aihub" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                = azurerm_resource_group.example.location
  name                    = local.name
  resource_group_name     = azurerm_resource_group.example.name
  kind                    = "Hub"
  workspace_friendly_name = "AI Studio Hub"

  workspace_connections = {
    ai = {
      target   = module.ai_services.endpoint
      category = "AIServices"
      metadata = {
        ResourceId = module.ai_services.resource_id
        ApiType    = "Azure"
      }
      auth_type     = "AAD"
      shared_by_all = true
      tags = merge(local.tags, {
        connectionType = "AIServices"
      })
    }
  }

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = false
  }

  key_vault = {
    resource_id = azurerm_key_vault.example.id
  }

  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }

  enable_telemetry = var.enable_telemetry
  tags             = local.tags
}

