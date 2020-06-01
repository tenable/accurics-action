# Accurics GitHub Action

## Description
The Accurics GitHub action runs an Accurics CLI scan against the IaC (Infrastructure-as-Code) files found within the applied repository.
This action can be used to fail a pipeline build when violations or errors are found.
The CLI results can be viewed in the pipeline results or in the Accurics Console itself at https://www.accurics.com

See examples below.

## Setup

- Download the config file settings from the Accurics Console and place them into a file called "config" under the repository.
- If not using the latest Terraform version, specify the terraform-version within the build step.
- If variables are used, add them in the plan-args setting, along with any other command line parameters that should be passed when running "terraform plan" (see the example below)

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
These config file settings can be set globally, but if one is specified, all must be specified.
| Setting | Description | Default |
| ------------------ | ----------------------------------------------------------- | --------- |
| env-id | Environment ID for Accurics to scan | | 
| app-id | Accurics CLI Application Token ID | |


## Outputs

| Name | Variable Name  |
| ---------------- | --------------- |
| env-name | $env_name |
| env-id | $env_id |
| num-violations | $num_violations |
| summary | $summary |
| has-errors | $has_errors |

## Examples

### Example 1:
This example configures an Accurics Scan with a custom Terraform version and variables. It will also fail the build on any violations or errors found.

```yaml
    steps:
      - name: Accurics
        uses: actions/accurics@v1.0
        env: 
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          terraform-version: 0.12.24
          plan-args: '-var myvar1=val1 -var myvar2=val2'
```

### Example 2:
This example configures an Accurics Scan using the latest Terraform version, custom variables, and instructs the action not to fail when any violations are found. This is helpful when first introducing the action into a new codebase and working through a large number of violations. Once the number of violations is manageable, the option can be set back to true (or removed).
```yaml
    steps:
      - name: Accurics
        uses: actions/accurics@v1.0
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          fail-on-violations: false
```

### Example 3:
This is the same configuration as before, but it now includes an extra build step to display the output scan status.
```yaml
    steps:
      - name: Accurics
        uses: actions/accurics@v1.0
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          fail-on-violations: false
      - name: Display statistics
        run: '
            echo "Env Name    : ${{ steps.accurics.outputs.env-name }}";
            echo "Env ID      : ${{ steps.accurics.outputs.env-id }}";
            echo "Scan ID     : ${{ steps.accurics.outputs.scan-id }}";
            echo "Violations  : ${{ steps.accurics.outputs.num-violations }}";
            echo "Summary     : ${{ steps.accurics.outputs.summary }}";
          '
```

