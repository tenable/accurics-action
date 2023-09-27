#!/bin/sh -l

REPORT_NAME=accurics_report.json

process_args() {
  # Input from command line
  INPUT_DEBUG_MODE=$1
  INPUT_TERRAFORM_VERSION=$2
  INPUT_DIRECTORIES=$3
  INPUT_PLAN_ARGS=$4
  INPUT_ENV_ID=$5
  INPUT_APP_ID=$6
  INPUT_REPO_NAME=$7
  INPUT_URL=$8
  INPUT_FAIL_ON_VIOLATIONS=$9
  INPUT_FAIL_ON_ALL_ERRORS=${10}
  INPUT_SCAN_MODE=${11}
  INPUT_PIPELINE=${12}
  INPUT_RUN_MODE=${13}
  INPUT_TERRAGRUNT_VERSION=${14}

  # If all config parameters are specified, use the config params passed in instead of the config file checked into the repository
  [ "$INPUT_ENV_ID" = "" ]    && echo "Error: The env-id parameter is required and not set." && exit 1
  [ "$INPUT_APP_ID" = "" ]    && echo "Error: The app-id parameter is required and not set." && exit 2
  [ "$INPUT_URL" = "" ]       && echo "Error: The url parameter is required and not set."    && exit 3
  [ "$INPUT_REPO_NAME" = "" ] && INPUT_REPO_NAME=__empty__

  export ACCURICS_URL=$INPUT_URL
  export ACCURICS_ENV_ID=$INPUT_ENV_ID
  export ACCURICS_APP_ID=$INPUT_APP_ID
  export ACCURICS_REPO_NAME=$INPUT_REPO_NAME
}

install_terragrunt() {
  local tgVersion=$1
  local url
  url="https://github.com/gruntwork-io/terragrunt/releases/download/${tgVersion}/terragrunt_linux_amd64"

  echo "Downloading Terragrunt ${tgVersion}"
  curl -s -S -L -o /tmp/terragrunt ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download Terragrunt ${tgVersion}"
    exit 1
  fi
  echo "Successfully downloaded Terragrunt ${tgVersion}"

  echo "Moving Terragrunt ${tgVersion} to PATH"
  chmod +x /tmp/terragrunt
  mv /tmp/terragrunt /usr/local/bin/terragrunt 
  if [ "${?}" -ne 0 ]; then
    echo "Failed to move Terragrunt ${tgVersion}"
    exit 1
  fi
  echo "Successfully moved Terragrunt ${tgVersion}"

}
install_terraform() {
  local terraform_ver=$1
  local url

  [ "$terraform_ver" = "latest" ] && terraform_ver=`curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1`

  url="https://releases.hashicorp.com/terraform/$terraform_ver/terraform_${terraform_ver}_linux_amd64.zip"

  echo "Downloading Terraform: $terraform_ver from $url"
  curl -s -S -L -o /tmp/terraform_${terraform_ver}_linux_amd64.zip ${url}

  [ "$?" -ne 0 ] && echo "Error while downloading Terraform $terraform_ver" && exit 150

  unzip -d /usr/local/bin /tmp/terraform_${terraform_ver}_linux_amd64.zip
  [ "$?" -ne 0 ] && echo "Error while unzipping Terraform $terraform_ver" && exit 151
}

run_accurics() {
  local params=$1
  local plan_args=$2
  
  touch config
  terrascan version
  
  local runMode="plan"
  local pipeline_mode=""
   
  if [ "$INPUT_SCAN_MODE" = "scan" ]; then
     echo "running scan mode"
     runMode="scan"
  else
     echo "running plan mode"
     accurics init
  fi
  
   
  if [ "$INPUT_PIPELINE" = true ]; then
     echo "INPUT_PIPELINE="$INPUT_PIPELINE
     echo "running pipeline mode"
     pipeline_mode="-mode=pipeline"
  else
     echo "INPUT_PIPELINE="$INPUT_PIPELINE
  fi
  
  # Run accurics plan
  accurics $INPUT_RUN_MODE $params $plan_args $pipeline_mode
  ACCURICS_PLAN_ERR=$?
}

process_errors() {
  # Default error code
  EXIT_CODE=0

  # If INPUT_FAIL_ON_ALL_ERRORS is set and accurics plan returns an error, propagate that error
  [ "$INPUT_FAIL_ON_ALL_ERRORS" = "true" ] && [ "$ACCURICS_PLAN_ERR" -ne 0 ] && EXIT_CODE=100

  # If INPUT_FAIL_ON_VIOLATIONS is set and violations are found, return an error
  VIOLATIONS=`grep violation $REPORT_NAME | head -1 | awk '{ print $2 }' |cut -d, -f1`
  [ "$INPUT_FAIL_ON_VIOLATIONS" = "true" ] && [ "$VIOLATIONS" != "null" ] && [ "$VIOLATIONS" -gt 0 ] && EXIT_CODE=101
}

process_output() {
  num_violations=$VIOLATIONS
  repo=$ACCURICS_REPO_NAME
  env_name=`grep envName $REPORT_NAME | head -1 | cut -d\" -f4`
  num_resources=`grep resources $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  high=`grep high $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  medium=`grep medium $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  low=`grep low $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  native=`grep native $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  inherited=`grep inherit $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  drift=`grep drift $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  iac_drift=`grep iacdrift $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  cloud_drift=`grep clouddrift $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`
  has_errors=`grep HasErrors $REPORT_NAME | head -1 | awk '{ print $2 }' | cut -d, -f1`

  echo "::set-output name=env-name::$env_name"
  echo "::set-output name=repo::$repo"
  echo "::set-output name=num-violations::$num_violations"
  echo "::set-output name=num-resources::$num_resources"
  echo "::set-output name=high::$high"
  echo "::set-output name=medium::$medium"
  echo "::set-output name=low::$low"
  echo "::set-output name=native::$native"
  echo "::set-output name=inherited::$inherited"
  echo "::set-output name=drift::$drift"
  echo "::set-output name=iacdrift::$iacdrift"
  echo "::set-output name=clouddrift::$clouddrift"
  echo "::set-output name=has-errors::$has_errors"
}

INPUT_DEBUG_MODE=$1
[ "$INPUT_DEBUG_MODE" = "true" ] && set -x

process_args "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}"

install_terraform $INPUT_TERRAFORM_VERSION

if [[ "${INPUT_RUN_MODE}" == "tgplan" ]]; then
  echo "line 156" $?
  echo "Installing kubegrunt and terragrunt"
  install_terragrunt $INPUT_TERRAGRUNT_VERSION
fi

#2.35.2 github update
git config --global --add safe.directory "$GITHUB_WORKSPACE"

for d in $INPUT_DIRECTORIES; do
  cd $d

  run_params=""

  echo "======================================================================"
  echo " Running the Accurics Action for directory: "
  echo "   $d"
  echo " Github_workspace  $GITHUB_WORKSPACE"
  echo "======================================================================"

  run_accurics "$run_params" "$INPUT_PLAN_ARGS"

  echo "======================================================================"
  echo " Done!"
  echo "======================================================================"

  process_errors
  process_output
  
  cd -

  [ "$EXIT_CODE" -ne 0 ] && break
done

exit $EXIT_CODE

