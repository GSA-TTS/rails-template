#!/usr/bin/env bash

if ! command -v terraform &> /dev/null
then
  echo "terraform must be installed before running this script"
  exit 1
fi

if [ -z "$GITLAB_PROJECT_ID" ] || [ -z "$GITLAB_HOSTNAME" ]; then
  echo "GITLAB_PROJECT_ID or GITLAB_HOSTNAME has not been set. Run ./setup_shadowenv.sh first"
  exit 1
fi

set -e

# ensure we're logged in via cli
cf spaces &> /dev/null || cf login -a api.fr.cloud.gov --sso

tf_state_address="https://$GITLAB_HOSTNAME/api/v4/projects/$GITLAB_PROJECT_ID/terraform/state/bootstrap"
terraform init \
  -backend-config="address=$tf_state_address" \
  -backend-config="lock_address=$tf_state_address/lock" \
  -backend-config="unlock_address=$tf_state_address/lock"

terraform apply "$@"
