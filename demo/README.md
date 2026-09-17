# Preview Environments no Azure com Terraform

Demo da palestra **"Ambientes dinâmicos no Azure com Terraform"** (Data Saturday Vitória 2026).

Um chat de suporte em **Blazor Server** conversa com um agente do **Microsoft Foundry** que usa *file search* sobre os manuais da (fictícia) Contoso Café. Cada tarefa ganha um **ambiente de preview isolado**: Web App, Application Insights e um **projeto Foundry próprio**, com agente e base de conhecimento. Esse ambiente é criado, atualizado e destruído por **Terraform + GitHub Actions**.

```
main ───────────────●────────────────────────●──── deploy main
                     \                      /
preview/tesc-001      ●── create ── ● PR ──●         → destroy
                                     \
feature/melhora-busca                 ● instructions v2
```

## Como funciona

| Conceito | Implementação |
|---|---|
| Chave do ambiente | `env_key`: `main` ou a tarefa em minúsculas (`tesc-001`) |
| Branch como contrato | `main` → ambiente `main`; `preview/<env_key>` → ambiente `<env_key>` ([resolve-environment](.github/actions/resolve-environment/action.yml)) |
| Um módulo, N ambientes | [`infra/modules/app-environment`](infra/modules/app-environment/main.tf) cria main e previews |
| State por ambiente | `terraform init -backend-config="key=app/<env_key>.tfstate"` ([tf-init.sh](scripts/tf-init.sh)) |
| Compartilhado vs. isolado | Compartilhados: App Service Plan, Log Analytics, Foundry e deployment do modelo. Isolados por ambiente: Web App, App Insights e projeto Foundry |
| Prompt como código | [`agent/instructions.md`](agent/instructions.md) e a [base](agent/knowledge), publicados pelo [AgentSync](src/SupportAgent.AgentSync) a cada deploy |
| Governança de custo | Tags `environment-key`/`expires-at` em todos os recursos, [janitor](.github/workflows/preview-janitor.yml) e budget por RG, opcional (ligado quando `budget_contact_emails` é informado) |
| Gestão assistida | Copilot + [Azure/GitHub/Terraform MCP](.vscode/mcp.json) e [prompt files](.github/prompts) |

### Workflows

| Workflow | Gatilho | O que faz |
|---|---|---|
| [preview-environment](.github/workflows/preview-environment.yml) | manual (`env_key`, `create`/`destroy`, `ttl_days`) | Cria a infra e a branch `preview/<env_key>` e dispara o primeiro deploy; ou limpa o agente, destrói a infra, remove o state e apaga a branch |
| [deploy](.github/workflows/deploy.yml) | push em `main` e `preview/**` | `terraform apply` do ambiente da branch → deploy da Web App → publica agente e base → smoke test |
| [pr-validation](.github/workflows/pr-validation.yml) | PR para `main` ou `preview/**` | Build, `fmt`/`validate` e `plan` do ambiente de **destino**, com comentário no PR |
| [preview-janitor](.github/workflows/preview-janitor.yml) | dias úteis 08:00 BRT | Lista previews com `expires-at` vencido e abre uma issue ou destrói |

## Estrutura

```
agent/                      agente versionado: agent.json, instructions.md, knowledge/
infra/bootstrap/            state remoto + identidade OIDC do GitHub (roda 1x, local)
infra/shared/               recursos compartilhados
infra/modules/app-environment/
infra/environments/app/     root module de todos os ambientes
src/SupportAgent.Web/       Blazor Server (chat)
src/SupportAgent.AgentSync/ publica/remove agente, vector store e arquivos no projeto Foundry
scripts/                    tf-init.sh, configure-github.sh
```

## Pré-requisitos

- Subscription Azure com permissão de **Owner** (ou Contributor + RBAC Administrator) para o bootstrap.
- Cota do modelo `gpt-5-mini` (GlobalStandard) na região escolhida. O padrão é `eastus2`, que precisa suportar o Foundry Agent Service.
- Terraform ≥ 1.9, Azure CLI, GitHub CLI, .NET SDK 10, `jq`.
- Para o MCP: Node.js (Azure MCP) e Docker (Terraform MCP).

## Setup (uma vez)

```bash
# 1. Bootstrap: storage do state + identidade do GitHub (state local, não versionado)
cp infra/bootstrap/terraform.tfvars.example infra/bootstrap/terraform.tfvars   # edite os valores
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap apply

# 2. Variáveis e environments do repositório
scripts/configure-github.sh <owner>/<repo>

# 3. Recursos compartilhados
export TFSTATE_RESOURCE_GROUP=$(terraform -chdir=infra/bootstrap output -json github_variables | jq -r .TFSTATE_RESOURCE_GROUP)
export TFSTATE_STORAGE_ACCOUNT=$(terraform -chdir=infra/bootstrap output -json github_variables | jq -r .TFSTATE_STORAGE_ACCOUNT)
scripts/tf-init.sh infra/shared shared.tfstate
terraform -chdir=infra/shared apply -var unique_suffix=<sufixo> -var subscription_id=<id>

# 4. Ambiente main: basta um push na main (ou rodar o workflow Deploy com env_key=main)
```

## Ciclo de um preview

1. **Actions → Preview environment → Run workflow**, com `env_key=TESC-001` e `action=create`.
2. Crie `feature/...` a partir de `preview/tesc-001` e abra o PR contra `preview/tesc-001`. O `pr-validation` mostra o plan e o diff do agente.
3. Merge → o `deploy` atualiza **só** o `tesc-001`: app, agente e base.
4. Validado: PR `preview/tesc-001` → `main`.
5. **Preview environment** com `action=destroy`.

## Rodando localmente

```bash
az login
dotnet run --project src/SupportAgent.Web \
  --Foundry:ProjectEndpoint=https://aif-supportagent-<sufixo>.services.ai.azure.com/api/projects/proj-main \
  --Foundry:AgentName=contoso-cafe-suporte
```

Sem `Foundry:ProjectEndpoint`, a app sobe e mostra o aviso "Foundry não configurado". Para publicar o agente num projeto a partir da sua máquina:

```bash
dotnet run --project src/SupportAgent.AgentSync -- sync \
  --endpoint https://aif-supportagent-<sufixo>.services.ai.azure.com/api/projects/proj-main \
  --env-key main --agent-dir agent
```

## Custos e armadilhas

- **Compartilhe o que é caro ou tem cota.** O plano B1 e o deployment do modelo atendem todos os ambientes; um preview custa praticamente só o consumo.
- **Tokens aparecem no Foundry compartilhado**, não no RG do preview. Para ratear, use o `environment-key` nos metadados/telemetria.
- **Dados do agente persistem** (arquivos, vector stores, versões) até serem apagados. Por isso o `destroy` roda `AgentSync cleanup` antes do Terraform.
- **Foundry resource tem soft delete**; projetos não. O provider está com `purge_soft_delete_on_destroy`.
- **Nomes globais têm limite.** Mantenha `unique_suffix` com até 8 caracteres e `env_key` com até 20.
- **Tags não são herdadas** do RG no Cost Management por padrão, por isso o módulo aplica tags em todos os recursos.
- A identidade do pipeline só pode atribuir o papel **Foundry User** (condição ABAC no bootstrap).
