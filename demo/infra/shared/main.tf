# Recursos compartilhados por TODOS os ambientes (main + previews).
# Tudo que é caro, lento para criar ou limitado por cota fica aqui.

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  foundry_user_role_id = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
  foundry_name         = "aif-${var.workload}-${var.unique_suffix}"

  tags = {
    project            = var.workload
    "environment-type" = "shared"
    "managed-by"       = "terraform"
  }
}

resource "azurerm_resource_group" "shared" {
  name     = "rg-${var.workload}-shared"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "shared" {
  name                = "log-${var.workload}-shared"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Um único plano hospeda as Web Apps de todos os ambientes: preview não soma custo de compute.
resource "azurerm_service_plan" "shared" {
  name                = "asp-${var.workload}-shared"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}

# Foundry resource compartilhado; cada ambiente ganha o seu PROJETO (isolamento de agentes/dados).
resource "azurerm_cognitive_account" "foundry" {
  name                       = local.foundry_name
  resource_group_name        = azurerm_resource_group.shared.name
  location                   = azurerm_resource_group.shared.location
  kind                       = "AIServices"
  sku_name                   = "S0"
  custom_subdomain_name      = local.foundry_name
  project_management_enabled = true
  local_auth_enabled         = false
  tags                       = local.tags

  identity {
    type = "SystemAssigned"
  }
}

# Deployment de modelo também é compartilhado: a cota de TPM é por subscription/região.
resource "azurerm_cognitive_deployment" "chat" {
  name                 = var.model_deployment_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = var.model_name
    version = var.model_version
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.model_capacity
  }
}

# A pipeline publica agentes/vector stores (data plane) em qualquer projeto do Foundry.
data "azurerm_user_assigned_identity" "github" {
  name                = "id-${var.workload}-github"
  resource_group_name = "rg-${var.workload}-tfstate"
}

resource "azurerm_role_assignment" "github_foundry_user" {
  scope              = azurerm_cognitive_account.foundry.id
  role_definition_id = "${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_id}"
  principal_id       = data.azurerm_user_assigned_identity.github.principal_id
  principal_type     = "ServicePrincipal"
}

# Quem aplica o shared localmente consegue rodar a app e o AgentSync na própria máquina.
resource "azurerm_role_assignment" "operator_foundry_user" {
  scope              = azurerm_cognitive_account.foundry.id
  role_definition_id = "${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_id}"
  principal_id       = data.azurerm_client_config.current.object_id
}
