#!/usr/bin/env bash

if ! command -v terraform &> /dev/null
then
  echo "terraform must be installed before running this script"
  exit 1
fi

if [ ! -f terraform.tfstate ] && [ -f recreate_state.sh ]; then
  ./recreate_state.sh
  exit $?
fi

set -e

terraform init
terraform apply "$@"
