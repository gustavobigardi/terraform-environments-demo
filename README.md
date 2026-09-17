# Ambientes dinâmicos no Azure com Terraform

Materiais da palestra apresentada no **Data Saturday Vitória 2026** por Gustavo Bigardi.

O repositório contém o código completo da demo e uma versão em PDF dos slides. A palestra mostra como criar ambientes de preview efêmeros no Azure usando Terraform e GitHub Actions, com um agente de suporte no Microsoft Foundry e gestão assistida por GitHub Copilot e MCP.

## Conteúdo

| Pasta/arquivo | O que é |
|---|---|
| [`demo/`](demo) | Código da demo: Terraform, Blazor, Microsoft Foundry, GitHub Actions e MCP |
| [`slides.pdf`](slides.pdf) | PDF com o conteúdo dos slides |

## A história em uma frase

Features não aprovadas "contaminavam" o Dev compartilhado e travavam a release. Com **preview environments**, cada tarefa ganha uma cópia efêmera do ambiente, identificada por uma chave (`TESC-001`), alimentada pela branch `preview/tesc-001` e destruída quando o trabalho termina. Só o que foi aprovado chega ao `main`.
