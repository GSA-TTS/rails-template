#!/usr/bin/env bash

if ! command -v terraform &> /dev/null
then
  echo "terraform must be installed before running this script"
  exit 1
fi

set -e

terraform init
terraform apply "$@"
