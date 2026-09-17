# Ambientes dinâmicos no Azure com Terraform

**Data Saturday Vitória 2026** · Gustavo Bigardi

> Nesta palestra vamos discutir e experimentar insights sobre a criação e manutenção de ambientes dinâmicos no Azure, utilizando Terraform e GitHub Actions, focando em ganhos de qualidade e redução de custos no processo de desenvolvimento de software, utilizando ferramentas como GitHub Copilot e MCP servers para monitoramento dos ambientes, custos, toda a gestão do processo.

## Conteúdo

| Pasta/arquivo | O que é |
|---|---|
| [palestra/ambientes-dinamicos-azure-terraform.pptx](palestra/ambientes-dinamicos-azure-terraform.pptx) | Deck no template do evento, com notas do apresentador |
| [palestra/roteiro.md](palestra/roteiro.md) | Roteiro cronometrado com as falas-chave |
| [palestra/demo-runbook.md](palestra/demo-runbook.md) | Passo a passo da demo ao vivo, checklist da véspera e plano B |
| [palestra/diagramas/](palestra/diagramas) | Fontes Mermaid (`.mmd`) e PNGs usados no deck |
| [palestra/demo-assets/](palestra/demo-assets) | Material para a demo (prompt v2 do agente) |
| [palestra/template/](palestra/template) | Template oficial do evento (intocado) |
| [demo/](demo) | Código da demo: Terraform, Blazor + Foundry, GitHub Actions, MCP. Vira um repositório próprio no GitHub |

## A história em uma frase

Features não aprovadas "contaminavam" o Dev compartilhado e travavam a release. Com **preview environments**, cada tarefa ganha uma cópia efêmera do ambiente, identificada por uma chave (`TESC-001`), alimentada pela branch `preview/tesc-001` e destruída quando o trabalho termina. Só o que foi aprovado chega ao `main`.

## Regerar os diagramas

```bash
cd palestra/diagramas
for f in *.mmd; do npx -y @mermaid-js/mermaid-cli@11 -i "$f" -o "png/${f%.mmd}.png" -b transparent -s 3 -w 1600; done
```
