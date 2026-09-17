# Root module de TODOS os ambientes da aplicação.
# O que muda entre main e tesc-001 é só a env_key — e a chave do state:
#   terraform init -backend-config="key=app/<env_key>.tfstate"

terraform {
  required_version = ">= 1.9"

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

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      # O RG do ambiente é efêmero e dedicado: o destroy apaga tudo, inclusive recursos criados
      # implicitamente pelo Azure (ex.: action group de Smart Detection do Application Insights).
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

locals {
  shared_resource_group = "rg-${var.workload}-shared"
  env_type              = lower(var.env_key) == "main" ? "main" : "preview"
}

# Recursos compartilhados são descobertos por convenção de nome — sem acoplamento de state.
data "azurerm_service_plan" "shared" {
  name                = "asp-${var.workload}-shared"
  resource_group_name = local.shared_resource_group
}

data "azurerm_cognitive_account" "foundry" {
  name                = "aif-${var.workload}-${var.unique_suffix}"
  resource_group_name = local.shared_resource_group
}

data "azurerm_log_analytics_workspace" "shared" {
  name                = "log-${var.workload}-shared"
  resource_group_name = local.shared_resource_group
}

module "environment" {
  source = "../../modules/app-environment"

  env_key    = var.env_key
  env_type   = local.env_type
  branch     = var.branch
  created_by = var.created_by
  ttl_days   = local.env_type == "main" ? 0 : var.ttl_days

  workload      = var.workload
  unique_suffix = var.unique_suffix
  location      = data.azurerm_service_plan.shared.location

  service_plan_id            = data.azurerm_service_plan.shared.id
  foundry_account_id         = data.azurerm_cognitive_account.foundry.id
  foundry_account_name       = data.azurerm_cognitive_account.foundry.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.shared.id
  agent_name                 = var.agent_name

  budget_amount         = local.env_type == "preview" ? var.preview_budget_amount : 0
  budget_contact_emails = var.budget_contact_emails
}
