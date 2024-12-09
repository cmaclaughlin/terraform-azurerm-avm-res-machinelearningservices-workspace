output "ai_services" {
  description = <<DESCRIPTION
The AI Services resource, if created, otherwise null.

- `id`: The ID of the AI Services resource. *This will be deprecated in favor of `resource_id` in the next release.
- `resource_id`: The ID of the AI Services resource.
- `name`: The ID of the AI Services resource.
- `endpoint`: The endpoint of the AI Services resource.
- `identity_id`: If there is an associated identity, the Service Principal ID for the AI Services resource identity.
DESCRIPTION
  value = var.aiservices.create_new ? {
    id          = jsondecode(azapi_resource.aiservice[0].output).id
    resource_id = jsondecode(azapi_resource.aiservice[0].output).id
    name        = jsondecode(azapi_resource.aiservice[0].output).name
    endpoint    = jsondecode(azapi_resource.aiservice[0].output).properties.endpoint
    identity_id = try(jsondecode(azapi_resource.aiservice[0].output).identity.principalId, null)
  } : null
}

output "ai_services_service_connection" {
  description = <<DESCRIPTION
The service connection between the AIServices and the workspace, if created, otherwise null.

- `id`: The ID of the Service Connection resource. *This will be deprecated in favor of `resource_id` in the next release.
- `resource_id`: The ID of the Service Connection resource.
- `name`: The name of the Service Connection.
- `target`: The target of the Service Connection. This is usually the endpoint of the associated service.
- `is_shared`: Whether or not the Service Connection is for use by all workspace users.
- `use_workspace_managed_identity`: Whether or not the workspace managed identity is used.
  DESCRIPTION
  value = var.aiservices.create_service_connection ? {
    id                             = jsondecode(azapi_resource.aiserviceconnection[0].output).id
    resource_id                    = jsondecode(azapi_resource.aiserviceconnection[0].output).id
    name                           = jsondecode(azapi_resource.aiserviceconnection[0].output).name
    target                         = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.target
    is_shared                      = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.isSharedToAll
    use_workspace_managed_identity = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.useWorkspaceManagedIdentity
  } : null
}

output "application_insights" {
  description = <<DESCRIPTION
The Application Insights resource, if created, otherwise null.

- `resource_id`: The ID of the Application Insights resource.
- `name`: The name of the Application Insights resource.
- `app_id`: The App ID of the Application Insights resource.
- `connection_string`: The connection string for the Application Insights resource.
- `instrumentation_key`: The instrumentation key for the Application Insights resource.
  DESCRIPTION
  value = length(module.avm_res_insights_component) == 1 ? {
    resource_id         = module.avm_res_insights_component[0].resource_id
    name                = module.avm_res_insights_component[0].name
    app_id              = module.avm_res_insights_component[0].app_id
    connection_string   = module.avm_res_insights_component[0].connection_string
    instrumentation_key = module.avm_res_insights_component[0].instrumentation_key
  } : null
}

output "container_registry" {
  description = <<DESCRIPTION
The Azure Container Registry resource, if created, otherwise null.

- `resource_id`: The ID of the Container Registry resource.
- `name`: The name of the Container Registry resource.
DESCRIPTION
  value = length(module.avm_res_containerregistry_registry) == 1 ? {
    resource_id = module.avm_res_containerregistry_registry[0].resource_id
    name        = module.avm_res_containerregistry_registry[0].name
  } : null
}

output "key_vault" {
  description = <<DESCRIPTION
The Azure Key Vault resource, if created, otherwise null.

- `resource_id`: The ID of the Key Vault resource.
- `uri`: The URI to perform operations on the keys and secrets within the Key Vault resource.
DESCRIPTION
  value = length(module.avm_res_keyvault_vault) == 1 ? {
    resource_id = module.avm_res_keyvault_vault[0].resource_id
    uri         = module.avm_res_keyvault_vault[0].uri
  } : null
}

output "private_endpoints" {
  description = "A map of the private endpoints created for the Azure Machine Learning Workspace."
  value       = azurerm_private_endpoint.this
}

# Guidance change to prohibit output of resource as an object. This will be a breaking change next major release.
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "The full Azure Machine Learning Workspace. *This will be deprecated in favor of the `workspace` output in the next major release."
  value       = local.aml_resource
}

output "resource_id" {
  description = "The ID of the Azure Machine Learning Workspace."
  value       = local.aml_resource.id
}

output "storage_account" {
  description = <<DESCRIPTION
The Storage Account resource, if created, otherwise null.

- `resource_id`: The ID of the Storage Account resource.
- `name`: The name of the Storage Account resource.
  DESCRIPTION
  value = length(module.avm_res_storage_storageaccount) == 1 ? {
    resource_id = module.avm_res_storage_storageaccount[0].resource_id
    name        = module.avm_res_storage_storageaccount[0].name
  } : null
}

output "workspace" {
  description = <<DESCRIPTION
The Azure Machine Learning Workspace created.

- `name`: The name of the Azure Machine Learning Workspace.
- `container_registry_id`: The ID of the associated container registry, if applicable.
- `storage_account_id`: The ID of the associated storage account.
- `key_vault_id`: The ID of the associated key vault.
- `application_insights_id`: The ID of the associated app. insights, if applicable.
DESCRIPTION
  value = {
    name                    = local.aml_resource.name
    container_registry_id   = try(jsondecode(local.aml_resource.body).properties.containerRegistry, null)
    storage_account_id      = try(jsondecode(local.aml_resource.body).properties.storageAccount, null)
    key_vault_id            = try(jsondecode(local.aml_resource.body).properties.keyVault, null)
    application_insights_id = try(jsondecode(local.aml_resource.body).properties.applicationInsights, null)
  }
}

output "workspace_identity" {
  description = <<DESCRIPTION
The identity for the created workspace.

- `principal_id`: The Service Principal ID for the identity.
- `type`: The type of identity (system-assigned, user-assigned, etc.)
DESCRIPTION
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
