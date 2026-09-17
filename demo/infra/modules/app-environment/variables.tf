variable "env_key" {
  description = "Chave do ambiente (ex.: main, TESC-001). Normalizada para minúsculas."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{3,20}$", var.env_key))
    error_message = "env_key deve ter de 3 a 20 caracteres: letras, números e hífen."
  }
}

variable "env_type" {
  description = "main ou preview."
  type        = string

  validation {
    condition     = contains(["main", "preview"], var.env_type)
    error_message = "env_type deve ser main ou preview."
  }
}

variable "branch" {
  type = string
}

variable "created_by" {
  description = "Quem criou o ambiente (github.actor). Gravado só na criação."
  type        = string
}

variable "ttl_days" {
  description = "Dias até o preview ser considerado vencido. 0 = nunca expira."
  type        = number
  default     = 7
}

variable "workload" {
  type = string
}

variable "unique_suffix" {
  type = string
}

variable "location" {
  type = string
}

variable "service_plan_id" {
  type = string
}

variable "foundry_account_id" {
  type = string
}

variable "foundry_account_name" {
  description = "Nome/subdomínio do Foundry resource compartilhado."
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "agent_name" {
  type = string
}

variable "dotnet_version" {
  type    = string
  default = "10.0"
}

variable "budget_amount" {
  description = "Orçamento mensal do resource group (moeda da subscription). 0 desliga."
  type        = number
  default     = 0
}

variable "budget_contact_emails" {
  type    = list(string)
  default = []
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
