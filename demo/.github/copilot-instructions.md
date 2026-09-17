# Contexto do repositório para o GitHub Copilot

Este repositório demonstra **ambientes dinâmicos (preview environments)** no Azure com Terraform e GitHub Actions. A aplicação é um chat de suporte em Blazor Server que usa um agente do Microsoft Foundry com file search.

## Convenções que você deve respeitar

- **Chave do ambiente (`env_key`)**: `main` para o ambiente principal; a chave da tarefa em minúsculas para previews (ex.: `tesc-001`).
- **Branch como contrato**: `main` → ambiente `main`; `preview/<env_key>` → ambiente `<env_key>`. PRs usam o ambiente da branch de destino.
- **Nomes de recursos** (`workload` = `supportagent`, `unique_suffix` nas variáveis do repo):
  - Resource group do ambiente: `rg-supportagent-<env_key>`
  - Web App: `app-supportagent-<unique_suffix>-<env_key>`
  - Application Insights: `appi-supportagent-<env_key>`
  - Projeto Foundry: `proj-<env_key>` dentro de `aif-supportagent-<unique_suffix>`
  - Compartilhados: `rg-supportagent-shared`, `asp-supportagent-shared`, `log-supportagent-shared`
- **Tags presentes em todos os recursos de ambiente**: `project`, `environment-key`, `environment-type` (`main|preview`), `branch`, `created-by`, `expires-at` (ISO 8601 ou `never`), `managed-by`.
- **State do Terraform**: `app/<env_key>.tfstate` no container `tfstate` (variáveis `TFSTATE_*`).
- **Agente**: definido em `agent/agent.json`, prompt em `agent/instructions.md`, base de conhecimento em `agent/knowledge/`. Publicado por `src/SupportAgent.AgentSync` no deploy.

## Como responder sobre ambientes

- Para **listar ambientes**, consulte resource groups com a tag `environment-type=preview` (Azure MCP / Resource Graph) e cruze com as branches `preview/*` e as últimas execuções do workflow `Deploy` (GitHub MCP).
- Para **custos**, agrupe por tag `environment-key`. Lembre que o consumo de tokens do modelo aparece no Foundry compartilhado (`aif-supportagent-*`), não no resource group do preview.
- Um preview é **ocioso** quando não tem deploy há mais de 3 dias ou quando a branch não recebe commits nesse período.
- Para **criar ou destruir** previews, use sempre o workflow `preview-environment.yml`. Nunca rode `terraform destroy` nem apague resource groups diretamente.
- Nunca proponha alterações no ambiente `main` fora de um PR para a branch `main`.
