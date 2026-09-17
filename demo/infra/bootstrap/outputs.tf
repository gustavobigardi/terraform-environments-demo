output "github_variables" {
  description = "Variáveis a cadastrar no repositório (gh variable set). Nenhuma é segredo."
  value = {
    AZURE_CLIENT_ID         = azurerm_user_assigned_identity.github.client_id
    AZURE_TENANT_ID         = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID   = data.azurerm_client_config.current.subscription_id
    TFSTATE_RESOURCE_GROUP  = azurerm_resource_group.tfstate.name
    TFSTATE_STORAGE_ACCOUNT = azurerm_storage_account.tfstate.name
    TFSTATE_CONTAINER       = azurerm_storage_container.tfstate.name
    WORKLOAD                = var.workload
    UNIQUE_SUFFIX           = var.unique_suffix
    LOCATION                = var.location
  }
}
