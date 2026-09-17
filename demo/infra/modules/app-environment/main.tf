# Um "ambiente" completo da aplicação, identificado por env_key.
# O MESMO módulo cria o main e cada preview — é isso que garante a paridade entre eles.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

data "azurerm_subscription" "current" {}

# Data de expiração calculada UMA vez (na criação) e estável entre execuções:
# deploys posteriores não mexem no expires-at, mesmo sem repassar ttl_days.
# Para renovar um preview, rode `terraform apply -replace=module.environment.time_offset.expiration`.
resource "time_offset" "expiration" {
  offset_days = var.ttl_days

  triggers = {
    created_by = var.created_by
  }

  lifecycle {
    ignore_changes = [triggers, offset_days]
  }
}

locals {
  env_key              = lower(var.env_key)
  foundry_user_role_id = "53ca6127-db72-4b80-b1b0-d745d6d5456d"

  names = {
    resource_group  = "rg-${var.workload}-${local.env_key}"
    web_app         = "app-${var.workload}-${var.unique_suffix}-${local.env_key}"
    app_insights    = "appi-${var.workload}-${local.env_key}"
    foundry_project = "proj-${local.env_key}"
  }

  foundry_project_endpoint = "https://${var.foundry_account_name}.services.ai.azure.com/api/projects/${local.names.foundry_project}"

  # Tags em TODOS os recursos: o Cost Management não herda tags do resource group por padrão.
  tags = merge(var.extra_tags, {
    project            = var.workload
    "environment-key"  = local.env_key
    "environment-type" = var.env_type
    branch             = var.branch
    "created-by"       = time_offset.expiration.triggers["created_by"]
    "expires-at"       = var.ttl_days > 0 ? time_offset.expiration.rfc3339 : "never"
    "managed-by"       = "terraform"
  })
}

resource "azurerm_resource_group" "env" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

resource "azurerm_application_insights" "env" {
  name                = local.names.app_insights
  resource_group_name = azurerm_resource_group.env.name
  location            = azurerm_resource_group.env.location
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  tags                = local.tags
}

# Projeto isolado dentro do Foundry compartilhado: agentes, arquivos e vector stores próprios.
resource "azurerm_cognitive_account_project" "env" {
  name                 = local.names.foundry_project
  cognitive_account_id = var.foundry_account_id
  location             = var.location
  display_name         = "Support Agent (${local.env_key})"
  description          = "Ambiente ${var.env_type} ${local.env_key} — branch ${var.branch}"
  tags                 = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_linux_web_app" "env" {
  name                    = local.names.web_app
  resource_group_name     = azurerm_resource_group.env.name
  location                = azurerm_resource_group.env.location
  service_plan_id         = var.service_plan_id
  https_only              = true
  client_affinity_enabled = true # Blazor Server mantém o circuito SignalR na mesma instância
  tags                    = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    websockets_enabled                = true
    http2_enabled                     = true
    ftps_state                        = "Disabled"
    minimum_tls_version               = "1.2"
    health_check_path                 = "/healthz"
    health_check_eviction_time_in_min = 10

    application_stack {
      dotnet_version = var.dotnet_version
    }
  }

  app_settings = {
    "Environment__Key"                      = local.env_key
    "Environment__Type"                     = var.env_type
    "Environment__Branch"                   = var.branch
    "Foundry__ProjectEndpoint"              = local.foundry_project_endpoint
    "Foundry__ProjectName"                  = local.names.foundry_project
    "Foundry__AgentName"                    = var.agent_name
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.env.connection_string
  }
}

# A Web App conversa com o agente do SEU projeto — e só dele.
resource "azurerm_role_assignment" "web_app_foundry_user" {
  scope              = azurerm_cognitive_account_project.env.id
  role_definition_id = "${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_id}"
  principal_id       = azurerm_linux_web_app.env.identity[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_consumption_budget_resource_group" "env" {
  count = var.budget_amount > 0 && length(var.budget_contact_emails) > 0 ? 1 : 0

  name              = "budget-${local.env_key}"
  resource_group_id = azurerm_resource_group.env.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", time_offset.expiration.base_rfc3339)
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
