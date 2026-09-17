output "resource_group_name" {
  value = azurerm_resource_group.shared.name
}

output "service_plan_id" {
  value = azurerm_service_plan.shared.id
}

output "foundry_account_name" {
  value = azurerm_cognitive_account.foundry.name
}

output "foundry_endpoint" {
  value = "https://${azurerm_cognitive_account.foundry.custom_subdomain_name}.services.ai.azure.com"
}

output "model_deployment_name" {
  value = azurerm_cognitive_deployment.chat.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.shared.id
}
