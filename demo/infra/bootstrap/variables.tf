variable "subscription_id" {
  description = "Subscription onde a demo será criada."
  type        = string
}

variable "location" {
  description = "Região padrão dos recursos."
  type        = string
  default     = "eastus2"
}

variable "workload" {
  description = "Prefixo lógico usado em todos os nomes."
  type        = string
  default     = "supportagent"
}

variable "unique_suffix" {
  description = "Sufixo curto para nomes globalmente únicos (storage, Foundry, Web Apps)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.unique_suffix))
    error_message = "Use de 3 a 8 caracteres minúsculos/numéricos."
  }
}

variable "github_repository" {
  description = "Repositório no formato owner/repo que receberá o OIDC."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Informe no formato owner/repo."
  }
}
