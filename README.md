# Accurics GitHub Action

## Description
The Accurics GitHub action runs an Accurics CLI scan against the IaC (Infrastructure-as-Code) files found within the applied repository.
This action can be used to fail a pipeline build when violations or errors are found.
The CLI results can be viewed in the pipeline results or in the Accurics Console itself at https://www.accurics.com

See examples below.

## Setup

- Create GitHub secrets to store the Environment ID and Application Token. Open your Repository Settings->Secrets tab->New Secret. Create two secrets called "ACCURICS_CLI_APP_ID" and "ACCURICS_CLI_ENV_ID" filled with values copied from the Accurics UI in the Environment details page.
- Add corresponding entries called "env-id" and "app-id" referring to the newly-created GitHub secrets. See examples below for more info.
- If not using the latest Terraform version, specify the terraform-version within the build step.
- If variables are used, add them in the plan-args setting, along with any other command line parameters that should be passed when running "terraform plan" (see the example below)

## Cost

The Accurics GitHub action runs as a Linux container, which means it accumulates minutes while running at the same rate Linux containers are charged by GitHub. Please refer to the GitHub action billing page for more detailed information.

## Input Settings

### These settings are required
| Setting | Description | Default |
| -------------------- | ----------------------------------------------------------- | --------- |
| app-id | ${ACCURICS_CLI_APP_ID} |
| env-id | ${ACCURICS_CLI_ENV_ID} |

### All of the following settings are optional

| Setting | Description | Default |
| -------------------- | ----------------------------------------------------------- | --------- |
| terraform-version | The Terraform version used to process the files in this repository | latest | 
| plan-args | The Terraform version used to process the files in this repository | | 
| directories | A list of directories to scan within this repository separated by a space | ./ | 
| fail-on-violations | Allows the Accurics Action to fail the build when violations are found | true |
| fail-on-all-errors | Allows the Accurics Action to fail the build when any errors are encountered | true |

### Notes
- Variable values within the plan-args setting should be stripped of double-quote (") characters

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
      # Required to checkout the files in the current repository
      - name: Checkout
        uses: actions/checkout@v2
      - name: Accurics
        uses: accurics-dev/accurics-action@v1.0
        env: 
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_CLI_APP_ID }}
          env-id: ${{ secrets.ACCURICS_CLI_ENV_ID }}
          # Optional args
          terraform-version: 0.12.24
          plan-args: '-var myvar1=val1 -var myvar2=val2'
```

### Example 2:
This example configures an Accurics Scan using the latest Terraform version, custom variables, and instructs the action not to fail when any violations are found. This is helpful when first introducing the action into a new codebase and working through a large number of violations. Once the number of violations is manageable, the option can be set back to true (or removed).
```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Accurics
        uses: accurics-dev/accurics-action@v1.0
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_CLI_APP_ID }}
          env-id: ${{ secrets.ACCURICS_CLI_ENV_ID }}
          # Optional args
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          fail-on-violations: false
```

### Example 3:
This is the same configuration as before, but it now includes an extra build step to display the output scan status.
```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Accurics
        uses: accurics-dev/accurics-action@v1.0
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_CLI_APP_ID }}
          env-id: ${{ secrets.ACCURICS_CLI_ENV_ID }}
          # Optional args
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

