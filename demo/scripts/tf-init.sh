#!/usr/bin/env bash
# Inicializa um stack Terraform apontando para a chave de state do ambiente.
#
#   scripts/tf-init.sh infra/shared shared.tfstate
#   scripts/tf-init.sh infra/environments/app app/tesc-001.tfstate
#
# Requer: TFSTATE_RESOURCE_GROUP, TFSTATE_STORAGE_ACCOUNT (e opcional TFSTATE_CONTAINER).
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "uso: $0 <diretório-do-stack> <state-key>" >&2
  exit 1
fi

stack_dir=$1
state_key=$2

: "${TFSTATE_RESOURCE_GROUP:?defina TFSTATE_RESOURCE_GROUP}"
: "${TFSTATE_STORAGE_ACCOUNT:?defina TFSTATE_STORAGE_ACCOUNT}"

terraform -chdir="$stack_dir" init -input=false -reconfigure \
  -backend-config="resource_group_name=${TFSTATE_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TFSTATE_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TFSTATE_CONTAINER:-tfstate}" \
  -backend-config="key=${state_key}" \
  -backend-config="use_azuread_auth=true"
