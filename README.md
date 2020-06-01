# Accurics GitHub Action

## Description
The Accurics GitHub action runs an Accurics CLI scan against the IaC (Infrastructure-as-Code) files found within the applied repository.
This action can be used to fail a pipeline build when violations or errors are found.
The CLI results can be viewed in the pipeline results or in the Accurics Console itself at https://www.accurics.com

## Setup

- Download the config file settings from the Accurics Console and place them into a file called "config" under the repository.
- If not using the latest Terraform version, specify the terraform-version within the build step.
- If variables are used, add them in the plan-args setting, along with any other command line parameters that should be passed when running "terraform plan"
and plan-args settings (see the example below)

## Example Usage

```yaml
    steps:
      - name: Accurics
        uses: actions/accurics@1
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          terraform-version: 0.12.24
          plan-args: '-var public_key_path=terraform-poc01.pub -var key_name=terraform-poc01'
```

## Input Settings

### All Settings are Optional

| Setting | Description | Default |
| -------------------- | ----------------------------------------------------------- | --------- |
| terraform-version | The Terraform version used to process the files in this repository | latest | 
| plan-args | The Terraform version used to process the files in this repository | | 
| directories | A list of directories to scan within this repository separated by a space | ./ | 
| fail-on-violations | Allows the Accurics Action to fail the build when violations are found | true |
| fail-on-all-errors | Allows the Accurics Action to fail the build when any errors are encountered | true |

### Notes
- When specifying a list of directories, a config file must be checked into the repo at that same location.
- Variable values within the plan-args setting should be stripped of double-quote (") characters

### The following settings can be used instead of checking in a config file
| Setting | Description | Default |
| ------------------ | ----------------------------------------------------------- | --------- |
| env-id | Environment ID for Accurics to scan. Also requires the Application ID to be set | | 
| app-id | Accurics CLI Application Token ID. Also requires the Environment ID to be set | |


## Outputs

| Name | Variable Name  |
| ---------------- | --------------- |
| env-name | $env_name |
| env-id | $env_id |
| num-violations | $num_violations |
| summary | $summary |
| has-errors | $has_errors |

## Notes
- When 
