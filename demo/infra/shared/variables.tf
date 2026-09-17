variable "subscription_id" {
  description = "Subscription alvo. Se nulo, usa ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "location" {
  description = "Região com suporte ao Foundry Agent Service e ao modelo escolhido."
  type        = string
  default     = "eastus2"
}

variable "workload" {
  type    = string
  default = "supportagent"
}

variable "unique_suffix" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.unique_suffix))
    error_message = "Use de 3 a 8 caracteres minúsculos/numéricos."
  }
}

variable "app_service_sku" {
  description = "SKU do plano compartilhado. B1 suporta Always On e WebSockets (Blazor Server)."
  type        = string
  default     = "B1"
}

variable "model_name" {
  type    = string
  default = "gpt-5-mini"
}

variable "model_version" {
  type    = string
  default = "2025-08-07"
}

variable "model_deployment_name" {
  description = "Nome do deployment referenciado pelos agentes (agent/agent.json)."
  type        = string
  default     = "gpt-5-mini"
}

variable "model_capacity" {
  description = "Capacidade em milhares de tokens por minuto, compartilhada por todos os ambientes."
  type        = number
  default     = 50
}
