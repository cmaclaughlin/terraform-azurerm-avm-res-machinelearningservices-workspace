# AzAPI AI Services Connection
resource "azapi_resource" "connection" {
  for_each = var.workspace_connections

  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-10-01"
  body = {
    properties = {
      category       = each.value.category
      expiryTime     = each.value.expiry_time
      isSharedToAll  = each.value.shared_by_all
      target         = each.value.target
      sharedUserList = each.value.shared_user_list
      authType       = each.value.auth_type
      credentials    = each.value.credentials
      metadata       = each.value.metadata
    }
  }
  name                      = each.value.name != null ? each.value.name : "${local.aml_resource.name}${each.value.category}"
  parent_id                 = local.aml_resource.id
  response_export_values    = ["*"]
  schema_validation_enabled = false # authType & credentials have too much variety
}
