---
mode: agent
description: Custo dos ambientes por environment-key e oportunidades de economia
---

Analise os custos da demo nos **últimos 30 dias** com o **Azure MCP** (Cost Management).

1. Custo total agrupado pela tag `environment-key` (inclua `main` e os previews).
2. Custo dos recursos compartilhados em `rg-supportagent-shared`, separando:
   - o App Service Plan `asp-supportagent-shared` (compute dividido por todos os ambientes);
   - o Foundry `aif-supportagent-*` (tokens do modelo e file search, **somados para todos os projetos**).
3. Para cada preview, custo diário médio × dias até `expires-at`, ou seja, quanto ainda vai custar se ninguém destruir.

Entregue:
- uma tabela **Ambiente | Custo 30d | Custo/dia | Dias restantes | Custo projetado**;
- a comparação "e se cada preview tivesse o próprio App Service Plan B1 e o próprio Foundry com deployment de modelo?", usando a lista de preços pública e deixando as premissas explícitas;
- as 3 principais ações de economia, por ordem de impacto.

Se os dados de custo ainda não estiverem disponíveis (recursos com menos de 24–48 h), diga isso claramente e mostre apenas o inventário.
