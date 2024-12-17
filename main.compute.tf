
# Azure Machine Learning Compute Instance
resource "azapi_resource" "computeinstance" {
  count = var.create_compute_instance ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/computes@2024-07-01-preview"
  body = {
    properties = {
      computeLocation  = local.aml_resource.location
      computeType      = "ComputeInstance"
      disableLocalAuth = true
      properties = {
        enableNodePublicIp = false
        vmSize             = "STANDARD_DS2_V2"
      }
    }
  }
  location               = local.aml_resource.location
  name                   = "ci-${var.name}"
  parent_id              = local.aml_resource.id
  response_export_values = ["*"]

  identity {
    type = "SystemAssigned"
  }
}