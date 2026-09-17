output "env_key" {
  value = local.env_key
}

output "resource_group_name" {
  value = azurerm_resource_group.env.name
}

output "web_app_name" {
  value = azurerm_linux_web_app.env.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.env.default_hostname}"
}

output "foundry_project_name" {
  value = azurerm_cognitive_account_project.env.name
}

output "foundry_project_endpoint" {
  value = local.foundry_project_endpoint
}

output "agent_name" {
  value = var.agent_name
}

output "expires_at" {
  value = local.tags["expires-at"]
}
