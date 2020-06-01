#!/bin/sh -l

process_args() {
  INPUT_DEBUG_MODE=$1
  INPUT_TERRAFORM_VERSION=$2
  INPUT_DIRECTORIES=$3
  INPUT_PLAN_ARGS=$4
  INPUT_ENV_ID=$5
  INPUT_APP_ID=$6
  INPUT_APP_URL=$7
  INPUT_FAIL_ON_VIOLATIONS=$8
  INPUT_FAIL_ON_ALL_ERRORS=$9

  USE_WORKFLOW_CONFIG=0

  # If all config parameters are specified, use the config params passed in instead of the config file checked into the repository
  if [ "$INPUT_ENV_ID" != "" ] && [ "$INPUT_APP_ID" != "" ] && [ "$INPUT_APP_URL" != "" ]; then
    echo "{\"target\":\"$INPUT_APP_URL\",\"env\":\"$INPUT_ENV_ID\",\"app\":\"$INPUT_APP_ID\"}" > .accurics-config
    USE_WORKFLOW_CONFIG=1
  fi
}

install_terraform() {
  local terraform_ver=$1
  local url="https://releases.hashicorp.com/terraform/$terraform_ver/terraform_${terraform_ver}_linux_amd64.zip"
  [ "$terraform_ver" = "latest" ] && terraform_ver=`curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1`

  echo "Downloading Terraform: $terraform_ver"
  curl -s -S -L -o /tmp/terraform_${terraform_ver}_linux_amd64.zip ${url}

  [ "$?" -ne 0 ] && echo "Error while downloading Terraform $terraform_ver" && exit 150

  unzip -d /usr/local/bin /tmp/terraform_${terraform_ver}_linux_amd64.zip
  [ "$?" -ne 0 ] && echo "Error while unzipping Terraform $terraform_ver" && exit 151
}

run_accurics() {
  local params=$1
  local plan_args=$2

  accurics init

  # Run accurics plan
  accurics plan $params $plan_args
  ACCURICS_PLAN_ERR=$?
}

process_errors() {
  # Default error code
  EXIT_CODE=0

  # If INPUT_FAIL_ON_ALL_ERRORS is set and accurics plan returns an error, propagate that error
  [ "$INPUT_FAIL_ON_ALL_ERRORS" = "true" ] && [ "$ACCURICS_PLAN_ERR" -ne 0 ] && EXIT_CODE=100

  # If INPUT_FAIL_ON_VIOLATIONS is set and violations are found, return an error
  VIOLATIONS=`grep violations accurics_report.json |awk '{ print $2 }' |cut -d, -f1`
  [ "$INPUT_FAIL_ON_VIOLATIONS" = "true" ] && [ "$VIOLATIONS" != "null" ] && [ "$VIOLATIONS" -gt 0 ] && EXIT_CODE=101
}

process_output() {
  num_violations=$VIOLATIONS
  env_id=`grep envId accurics_report.json |awk '{ print $2 }' |cut -d, -f1`
  env_name=`grep envName accurics_report.json |awk '{ print $2 }' |cut -d, -f1`
  summary=`grep summary accurics_report.json |awk '{ print $2 }' |cut -d, -f1`
  has_errors=`grep hasErrors accurics_report.json |awk '{ print $2 }' |cut -d, -f1`
  echo "::set-output name=env-name::$env_name"
  echo "::set-output name=env-id::$env_id"
  echo "::set-output name=num-violations::$num_violations"
  echo "::set-output name=summary::$summary"
  echo "::set-output name=has-errors::$has_errors"
}

INPUT_DEBUG_MODE=$1
[ "$INPUT_DEBUG_MODE" = "true" ] && set -x

process_args "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"

install_terraform $INPUT_TERRAFORM_VERSION

for d in $INPUT_DIRECTORIES; do
  cd $d

  run_params=""
  [ "$USE_WORKFLOW_CONFIG" -eq 1 ] && run_params="-config=.accurics-config"

  echo "======================================================================"
  echo " Running the Accurics Action for directory: "
  echo "   $d"
  echo "======================================================================"

  run_accurics "$run_params" "$INPUT_PLAN_ARGS"

  echo "======================================================================"
  echo " Done!"
  echo "======================================================================"

  cd -

  process_errors
  process_output

  [ "$EXIT_CODE" -ne 0 ] && break
done

exit $EXIT_CODE

