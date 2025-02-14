output "ai_services_service_connection" {
  description = "DEPRECATED. The service connection between the AIServices and the workspace, if created."
  value       = null
}

output "name" {
  description = "The name of the created machine learning workspace."
  value       = local.aml_resource.name
}

output "private_endpoints" {
  description = "A map of the private endpoints created."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "The ID of the created machine learning workspace."
  value       = local.aml_resource.id
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system-assigned managed identity for the created workspace, if created."
  value       = var.managed_identities.system_assigned ? try(local.aml_resource.identity[0].principal_id, null) : null
}

output "workspace" {
  description = "The machine learning workspace created."
  value = {
    name                    = local.aml_resource.name
    container_registry_id   = try(local.aml_resource.body.properties.containerRegistry, null)
    storage_account_id      = try(local.aml_resource.body.properties.storageAccount, null)
    key_vault_id            = try(local.aml_resource.body.properties.keyVault, null)
    application_insights_id = try(local.aml_resource.body.properties.applicationInsights, null)
  }
}

output "workspace_identity" {
  description = "The identity for the created workspace."
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
