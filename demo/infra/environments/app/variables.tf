variable "subscription_id" {
  description = "Subscription alvo. Se nulo, usa ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "env_key" {
  description = "main para o ambiente principal; a chave da tarefa (ex.: TESC-001) para previews."
  type        = string
}

variable "branch" {
  description = "Branch que alimenta o ambiente (main ou preview/<env_key>)."
  type        = string
}

variable "created_by" {
  type    = string
  default = "local"
}

variable "ttl_days" {
  description = "Validade do preview em dias (ignorado para main)."
  type        = number
  default     = 7
}

variable "workload" {
  type    = string
  default = "supportagent"
}

variable "unique_suffix" {
  type = string
}

variable "agent_name" {
  description = "Deve coincidir com agent/agent.json."
  type        = string
  default     = "contoso-cafe-suporte"
}

variable "preview_budget_amount" {
  type    = number
  default = 10
}

variable "budget_contact_emails" {
  type    = list(string)
  default = []
}
