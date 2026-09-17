#!/usr/bin/env bash
# Cadastra no repositório GitHub as variáveis produzidas pelo bootstrap e cria os environments.
#
#   scripts/configure-github.sh owner/repo
#
# Requer: gh autenticado e o state local de infra/bootstrap (terraform apply já executado).
set -euo pipefail

repo=${1:?uso: $0 owner/repo}
root="$(cd "$(dirname "$0")/.." && pwd)"

outputs="$(terraform -chdir="$root/infra/bootstrap" output -json github_variables)"

echo "Variáveis do repositório:"
for name in $(jq -r 'keys[]' <<< "$outputs"); do
  value="$(jq -r --arg k "$name" '.[$k]' <<< "$outputs")"
  gh variable set "$name" --repo "$repo" --body "$value"
  echo "  $name"
done

# Os environments definem o "subject" do token OIDC (repo:<owner>/<repo>:environment:<nome>).
for environment in main preview; do
  gh api --method PUT "repos/$repo/environments/$environment" --silent
  echo "Environment '$environment' pronto."
done

echo
echo "Opcional: em Settings → Environments → main, exija revisores antes do deploy."
