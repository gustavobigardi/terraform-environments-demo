---
mode: agent
description: Painel dos preview environments ativos (Azure + GitHub)
---

Monte um painel dos ambientes de preview deste repositório.

1. Com o **Azure MCP**, liste os resource groups com a tag `environment-type=preview` e leia as tags `environment-key`, `branch`, `created-by` e `expires-at`.
2. Com o **GitHub MCP**, para cada `environment-key`, verifique:
   - se a branch `preview/<environment-key>` ainda existe e a data do último commit;
   - a última execução do workflow `Deploy` nessa branch (status e data);
   - PRs abertos com base ou head nessa branch.
3. Descubra a URL da Web App `app-supportagent-*-<environment-key>`.

Responda com uma tabela: **Chave | Branch | Dono | Último deploy | PRs abertos | Expira em | URL**.

Abaixo da tabela, destaque:
- previews **vencidos** (`expires-at` no passado);
- previews **ociosos** (sem deploy há mais de 3 dias);
- **órfãos**: resource group sem branch ou branch sem resource group.

Sugira a ação para cada caso (renovar TTL, abrir PR para `main` ou rodar `preview-environment` com `destroy`), mas **não execute nada** sem confirmação.
