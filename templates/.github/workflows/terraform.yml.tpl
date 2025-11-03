name: Terraform Deploy - ${project_name}

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      runnerGroup:
        description: "Specify the runner group to use"
        required: false
        default: "XMMSRunnerGroup"
        type: string

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  ARM_CLIENT_ID: $${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: $${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: $${{ secrets.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true

jobs:
  terraform:
    name: 'Terraform'
    runs-on:
      group: $${{ github.event_name == 'workflow_dispatch' && inputs.runnerGroup || 'XMMSRunnerGroup' }}
    environment: ${environment}

    defaults:
      run:
        shell: bash

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ~1.5.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: $${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: $${{ secrets.AZURE_TENANT_ID }}
        subscription-id: $${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Configure Git for private module access
      run: |
        git config --global url."https://$${{ secrets.GH_INTEGRATION_TOKEN }}@xebia-partner-dr.ghe.com/".insteadOf "https://xebia-partner-dr.ghe.com/"
        git config --global user.email "terraform@automation.local"
        git config --global user.name "Terraform Automation"

    - name: Terraform Format Check
      id: fmt
      run: terraform fmt -check
      continue-on-error: true

    - name: Debug Backend Configuration
      run: |
        echo "Backend configuration:"
        echo "Resource Group: [redacted for security]"
        echo "Storage Account: [redacted for security]"  
        echo "Container: $${{ secrets.TF_STATE_CONTAINER }}"
        echo "Key: ${spoke_name}-integration.tfstate"
        # Check if secrets are properly set (without revealing values)
        if [ -z "$${{ secrets.TF_STATE_RESOURCE_GROUP }}" ]; then
          echo "ERROR: TF_STATE_RESOURCE_GROUP is empty!"
          exit 1
        fi
        if [ -z "$${{ secrets.TF_STATE_STORAGE_ACCOUNT }}" ]; then
          echo "ERROR: TF_STATE_STORAGE_ACCOUNT is empty!"
          exit 1
        fi
        echo "All backend configuration secrets are properly set"

    - name: Terraform Init
      id: init
      run: |
        terraform init \
          -backend-config="resource_group_name=$${{ secrets.TF_STATE_RESOURCE_GROUP }}" \
          -backend-config="storage_account_name=$${{ secrets.TF_STATE_STORAGE_ACCOUNT }}" \
          -backend-config="container_name=$${{ secrets.TF_STATE_CONTAINER }}" \
          -backend-config="key=${spoke_name}-integration.tfstate" \
          -backend-config="use_azuread_auth=true"

    - name: Terraform Validate
      id: validate
      run: terraform validate -no-color

    - name: Terraform Plan
      id: plan
      if: github.event_name == 'pull_request'
      run: terraform plan -no-color -input=false
      continue-on-error: true

    - name: Update Pull Request
      uses: actions/github-script@v7
      if: github.event_name == 'pull_request'
      env:
        PLAN: "terraform\n$${{ steps.plan.outputs.stdout }}"
      with:
        github-token: $${{ secrets.GITHUB_TOKEN }}
        script: |
          const output = `#### Terraform Format and Style 🖌\`$${{ steps.fmt.outcome }}\`
          #### Terraform Initialization ⚙️\`$${{ steps.init.outcome }}\`
          #### Terraform Validation 🤖\`$${{ steps.validate.outcome }}\`
          #### Terraform Plan 📖\`$${{ steps.plan.outcome }}\`

          <details><summary>Show Plan</summary>

          \`\`\`\n
          $${{ env.PLAN }}
          \`\`\`

          </details>

          *Pushed by: @$${{ github.actor }}, Action: \`$${{ github.event_name }}\`*`;

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: output
          })

    - name: Terraform Plan Status
      if: steps.plan.outcome == 'failure'
      run: exit 1

    # TEMPORARILY COMMENTED OUT - Only testing the workflow flow without applying infrastructure
    # - name: Terraform Apply
    #   if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    #   run: terraform apply -auto-approve -input=false

    # - name: Terraform Output
    #   if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    #   id: output
    #   run: |
    #     echo "Terraform outputs:"
    #     terraform output -json

    - name: Update Deployment Status
      if: always() && github.ref == 'refs/heads/main'
      uses: actions/github-script@v7
      with:
        github-token: $${{ secrets.GITHUB_TOKEN }}
        script: |
          const status = '$${{ job.status }}' === 'success' ? 'success' : 'failure';
          const deployment = await github.rest.repos.createDeployment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            ref: context.sha,
            environment: '${environment}',
            required_contexts: [],
            auto_merge: false
          });
          
          await github.rest.repos.createDeploymentStatus({
            owner: context.repo.owner,
            repo: context.repo.repo,
            deployment_id: deployment.data.id,
            state: status,
            description: status === 'success' ? 'Deployment successful' : 'Deployment failed',
            environment: '${environment}'
          });