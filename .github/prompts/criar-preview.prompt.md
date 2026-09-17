---
mode: agent
description: Cria um preview environment para uma tarefa
---

Quero um ambiente de preview para a tarefa **${input:envKey:Chave da tarefa, ex.: TESC-001}**.

1. Valide a chave: de 3 a 20 caracteres, letras, números e hífen.
2. Com o **GitHub MCP**, confira se a branch `preview/<chave em minúsculas>` já existe. Se existir, avise e pare.
3. Com o **Azure MCP**, confira se já existe o resource group `rg-supportagent-<chave em minúsculas>`. Se existir, avise e pare.
4. Mostre o que será criado (resource group, Web App, Application Insights, projeto Foundry, branch e validade de ${input:ttlDays:7} dias) e **peça confirmação**.
5. Depois da confirmação, dispare o workflow `preview-environment.yml` na branch `main` com `env_key`, `action=create` e `ttl_days`.
6. Acompanhe a execução e, ao terminar, informe a URL do ambiente e o link do run.
