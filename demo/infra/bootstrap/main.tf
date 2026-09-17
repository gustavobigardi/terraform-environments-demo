# Bootstrap: executado UMA vez, localmente, por quem administra a subscription.
# Cria o backend remoto do Terraform e a identidade que o GitHub Actions usa via OIDC.
# O state deste diretório é local (não versionado) — guarde-o com cuidado ou migre depois.

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  foundry_user_role_id = "53ca6127-db72-4b80-b1b0-d745d6d5456d" # Foundry User (antigo Azure AI User)

  tags = {
    project      = var.workload
    component    = "bootstrap"
    "managed-by" = "terraform"
  }

  # Um federated credential por "contexto" de execução no GitHub.
  github_subjects = {
    "github-env-main"     = "repo:${var.github_repository}:environment:main"
    "github-env-preview"  = "repo:${var.github_repository}:environment:preview"
    "github-pull-request" = "repo:${var.github_repository}:pull_request"
  }

  # Permite que a pipeline crie/remova role assignments SOMENTE do papel Foundry User
  # (usado pela managed identity de cada Web App). Menor privilégio via ABAC.
  rbac_admin_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.foundry_user_role_id}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.foundry_user_role_id}}
     )
    )
  EOT
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.workload}-tfstate"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "st${var.workload}tf${var.unique_suffix}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# Quem roda o bootstrap também precisa ler/gravar state (execuções locais).
resource "azurerm_role_assignment" "operator_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-${var.workload}-github"
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = local.github_subjects

  name                      = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = each.value
}

resource "azurerm_role_assignment" "github_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_rbac_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = local.rbac_admin_condition
  description          = "Pipeline pode atribuir apenas o papel Foundry User."
}

resource "azurerm_role_assignment" "github_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}
