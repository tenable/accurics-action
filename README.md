# Accurics GitHub Action

## Description
The Accurics GitHub action runs an Accurics scan against the IaC (Infrastructure-as-Code) files found within the applied repository.
This action can be used to fail a pipeline build when violations or errors are found.
The scan results can be viewed in the pipeline results or in the Accurics Console itself at https://app.accurics.com

See examples below.

## Setup

```yaml
    steps:
      - name: Accurics
        uses: accurics/accurics-action@v1.3.1
        id: accurics
        with:
          app-id: ${{ secrets.ACCURICS_APP_ID }}
          env-id: ${{ secrets.ACCURICS_ENV_ID }}
```

- Create GitHub secrets to store the Environment ID and Application Token. Open your Repository Settings->Secrets tab->New Secret. Create two secrets called "ACCURICS_APP_ID" and "ACCURICS_ENV_ID" filled with the "app" and "env" values copied from the config file downloaded from the Accurics UI environment tab.
- Add "app-id" and "env-id" parameters referencing the respective GitHub secrets. See the examples below for more info.
- Add a "repo" parameter that contains the remote repo location.
- If not using the latest Terraform version, specify the "terraform-version" parameter within the build step.
- If variables are used, add them in the "plan-args" parameter, along with any other command line parameters that should be passed when running "terraform plan" (see the example below)

## Cost

The Accurics GitHub action runs as a Linux container, which means it accumulates minutes while running at the same rate Linux containers are charged by GitHub. Please refer to the GitHub action billing page for more detailed information.

## Input Settings

### These settings are required
| Setting | Description |
| -------------------- | ----------------------------------------------------------- |
| app-id | The application token ID |
| env-id | The environment ID |
| repo   | The repository location URL |

### All of the following settings are optional

| Setting | Description | Default |
| -------------------- | ----------------------------------------------------------- | --------- |
| terraform-version | The Terraform version used to process the files in this repository | latest | 
| plan-args | The Terraform version used to process the files in this repository | | 
| directories | A list of directories to scan within this repository separated by a space | ./ | 
| fail-on-violations | Allows the Accurics Action to fail the build when violations are found | true |
| fail-on-all-errors | Allows the Accurics Action to fail the build when any errors are encountered | true |
| scan-mode | Allows the Accurics Action to use either terraform or terrascan for scanning(plan/scan) | plan |
| url | Allows the Accurics Action to point to different target endpoint of the product e.g. https://cloud.tenable.com/cns | https://app.accurics.com |
| pipeline | Allows the Accurics Action to choose mode as pipeline | false |


### Notes
- Variable values within the plan-args setting should be stripped of double-quote (") characters

## Outputs

| Name | Variable Name  |
| ---------------- | --------------- |
| Environment Name | $env_name |
| Violation Count | $num_violations |
| Resource Count | $num_resources |
| High-Severity Violations | $high |
| Medium-Severity Violations | $medium |
| Low-Severity Violations | $low |
| Native Resources | $native |
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
        uses: accurics/accurics-action@v1.3.1
        id: accurics
        env: 
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          REPO_URL: ${{ github.repositoryUrl }}
          GIT_BRANCH:  ${{ github.ref_name }}
          GIT_COMMIT:  ${{ github.sha }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_APP_ID }}
          env-id: ${{ secrets.ACCURICS_ENV_ID }}
          # Optional args
          terraform-version: 0.14.7
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          url: "https://cloud.tenable.com/cns"
```

### Example 2:
This example configures an Accurics Scan using the latest Terraform version, custom variables, and instructs the action not to fail when any violations are found. This is helpful when first introducing the action into a new codebase and working through a large number of violations. Once the number of violations is manageable, the option can be set back to true (or removed).
```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Accurics
        uses: accurics/accurics-action@v1.3.1
        id: accurics
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          REPO_URL: ${{ github.repositoryUrl }}
          GIT_BRANCH:  ${{ github.ref_name }}
          GIT_COMMIT:  ${{ github.sha }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_APP_ID }}
          env-id: ${{ secrets.ACCURICS_ENV_ID }}
          repo: "https://bitbucket.org/myrepo/reponame.git"
          # Optional args
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          fail-on-violations: false
          url: "https://cloud.tenable.com/cns"
          scan-mode: "plan"
          pipeline: true
```

### Example 3:
This is the same configuration as before, but it now includes an extra build step to display the output scan status, also sets scan mode to terrascan scan.
```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Accurics
        uses: accurics/accurics-action@v1.3.1
        id: accurics
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          REPO_URL: ${{ github.repositoryUrl }}
          GIT_BRANCH:  ${{ github.ref_name }}
          GIT_COMMIT:  ${{ github.sha }}
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_APP_ID }}
          env-id: ${{ secrets.ACCURICS_ENV_ID }}
          repo: "https://bitbucket.org/myrepo/reponame.git"
          # Optional args
          plan-args: '-var myvar1=val1 -var myvar2=val2'
          fail-on-violations: false
          url: "https://cloud.tenable.com/cns"
          scan-mode: "scan"
          pipeline: true
      - name: Display statistics
        run: '
            echo ""
            echo "Environment Name           : ${{ steps.accurics.outputs.env-name }}";
            echo "Repository                 : ${{ steps.accurics.outputs.repo }}";
            echo "Violation Count            : ${{ steps.accurics.outputs.num-violations }}";
            echo "Resource Count             : ${{ steps.accurics.outputs.num-resources }}";
            echo ""
            echo "Native Resources           : ${{ steps.accurics.outputs.native }}";
            echo "Inherited Resources        : ${{ steps.accurics.outputs.inherited }}";
            echo ""
            echo "High-Severity Violations   : ${{ steps.accurics.outputs.high }}";
            echo "Medium-Severity Violations : ${{ steps.accurics.outputs.medium }}";
            echo "Low-Severity Violations    : ${{ steps.accurics.outputs.low }}";
            echo ""
            echo "Drift                      : ${{ steps.accurics.outputs.drift }}";
            echo "IaC Drift                  : ${{ steps.accurics.outputs.iacdrift }}";
            echo "Cloud Drift                : ${{ steps.accurics.outputs.clouddrift }}";
            echo ""
          '
```
### Example 4: This is the example to check number of violations and fail the build in case not satisfied.
```yaml
    steps:
      - run: touch config
      - run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
      - run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v2
      - run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."
      - run: echo "🖥️ The workflow is now ready to test your code on the runner."
      - name: List files in the repository
        run: |
          ls ${{ github.workspace }}
      - name: Get git branch
        run: |
          git branch
      - name: Accurics
        
        uses: accurics/accurics-action@v2.25
        id: accurics
        env:
          # Required by Terraform
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          REPO_URL: ${{ github.repositoryUrl }}
          GIT_BRANCH:  ${{ github.ref_name }}
          GIT_COMMIT:  ${{ github.sha }}
         
        with:
          # Required by Accurics
          app-id: ${{ secrets.ACCURICS_APP_ID }}
          env-id: ${{ secrets.ACCURICS_ENV_ID }}
          repo: "your-repo-name-from-web-console"
          url: "https://cloud.tenable.com/cns"
          fail-on-violations: false
          scan-mode: "plan"
          pipeline: false
      - name: Display statistics
        run: '
            echo ""
            echo "Environment Name           : ${{ steps.accurics.outputs.env-name }}";
            echo "Repository                 : ${{ steps.accurics.outputs.repo }}";
            echo "Violation Count            : ${{ steps.accurics.outputs.num-violations }}";
            echo "Resource Count             : ${{ steps.accurics.outputs.num-resources }}";
            echo ""
            echo "Native Resources           : ${{ steps.accurics.outputs.native }}";
            echo "Inherited Resources        : ${{ steps.accurics.outputs.inherited }}";
            echo ""
            echo "High-Severity Violations   : ${{ steps.accurics.outputs.high }}";
            echo "Medium-Severity Violations : ${{ steps.accurics.outputs.medium }}";
            echo "Low-Severity Violations    : ${{ steps.accurics.outputs.low }}";
            echo ""
            echo "Drift                      : ${{ steps.accurics.outputs.drift }}";
            echo "IaC Drift                  : ${{ steps.accurics.outputs.iacdrift }}";
            echo "Cloud Drift                : ${{ steps.accurics.outputs.clouddrift }}";
            echo ""
          '
      - name: Check Number Of violations
        if: ${{ steps.accurics.outputs.num-violations > 10 }}
        uses: actions/github-script@v3
        with:
          script: |
              core.setFailed('Coverage test below tolerance')

```

