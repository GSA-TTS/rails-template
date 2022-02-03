#!/usr/bin/env bash

if [[ ! -f "secrets.auto.tfvars" ]]; then
  cf target -s prod

  # create space deployer service
  cf create-service cloud-gov-service-account space-deployer config-bootstrap-deployer

  # create service key
  cf create-service-key config-bootstrap-deployer space-deployer-key

  # get service key
  creds=`cf service-key config-bootstrap-deployer space-deployer-key | tail -n 4`
  username=`echo $creds | jq '.username'`
  password=`echo $creds | jq '.password'`

  # output to secrets.auto.tfvars
  echo "cf_user = $username" > secrets.auto.tfvars
  echo "cf_password = $password" >> secrets.auto.tfvars
fi

if [[ $# -gt 0 ]]; then
  echo "Running terraform $@"
  terraform $@
else
  echo "Not running terraform"
fi
