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
  storage_use_azuread = true
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "cmk" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "crypto" {
  principal_id       = azurerm_user_assigned_identity.cmk.principal_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603" # Key Vault Crypto Officer
}

# create a keyvault for storing the credential with RBAC for the deployment user
module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "~> 0.9"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483" # Key Vault Administrator
      principal_id               = data.azurerm_client_config.current.object_id
    }

    cosmos_db = {
      role_definition_id_or_name       = "/providers/Microsoft.Authorization/roleDefinitions/e147488a-f6f5-4113-8e2d-b22465e65bf6" # Key Vault Crypto Service Encryption User
      principal_id                     = "a232010e-820c-4083-83bb-3ace5fc29d0b"                                                    # CosmosDB **FOR AZURE GOV** use "57506a73-e302-42a9-b869-6f12d9ec29e9"
      skip_service_principal_aad_check = true                                                                                      # because it isn't a traditional SP
    }

    uai = {
      role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603" # Key Vault Crypto Officer
      principal_id               = azurerm_user_assigned_identity.cmk.principal_id
    }
  }

  wait_for_rbac_before_key_operations = {
    create = "70s"
  }
}

# create a Customer Managed Key for a Storage Account.
resource "azurerm_key_vault_key" "cmk" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = module.naming.key_vault_key.name_unique
  key_size     = 2048

  depends_on = [module.avm_res_keyvault_vault]
}

module "avm_res_storage_storageaccount" {
  source                        = "Azure/avm-res-storage-storageaccount/azurerm"
  version                       = "~> 0.3"
  enable_telemetry              = var.enable_telemetry
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  public_network_access_enabled = true

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.cmk.id]
  }

  customer_managed_key = {
    key_name              = azurerm_key_vault_key.cmk.name
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.cmk.id
    }
  }

  depends_on = [azurerm_key_vault_key.cmk]
}

# This is the module call
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.machine_learning_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name

  application_insights = {
    create_new = true
    log_analytics_workspace = {
      create_new = true
    }
  }

  storage_account = {
    create_new  = false
    resource_id = module.avm_res_storage_storageaccount.resource_id
  }

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.cmk.id]
  }

  customer_managed_key = {
    key_name              = azurerm_key_vault_key.cmk.name
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.cmk.id
    }
  }

  primary_user_assigned_identity = {
    resource_id = azurerm_user_assigned_identity.cmk.id
  }

  enable_telemetry = var.enable_telemetry

  depends_on = [module.avm_res_storage_storageaccount]
}
