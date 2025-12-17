name: Terraform Deploy - ${project_name}

on: workflow_dispatch

permissions:
  id-token: write
  contents: read

env:
  ARM_CLIENT_ID: $${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: $${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: $${{ secrets.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true

jobs:
  terraform:
    name: 'Terraform'
    runs-on: '${runner_label}'
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
        terraform_version: ~1.9.0

    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: $${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: $${{ secrets.AZURE_TENANT_ID }}
        subscription-id: $${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Configure Git for private module access
      shell: bash
      env:
        GITHUB_TOKEN: $${{ secrets.GH_INTEGRATION_TOKEN }}
      run: |
        # Replace :// with ://<token>@ to include the token in the URL
        git config --global url."$${GITHUB_SERVER_URL/:\/\//://$GITHUB_TOKEN@}/".insteadOf "$GITHUB_SERVER_URL/"

    - name: Terraform Format Check
      id: fmt
      run: terraform fmt -check
      continue-on-error: true

    - name: Debug Backend Configuration
      run: |
        echo "Backend configuration:"
        echo "Resource Group: $${{ vars.TF_STATE_RESOURCE_GROUP }}"
        echo "Storage Account: $${{ vars.TF_STATE_STORAGE_ACCOUNT }}"  
        echo "Container: $${{ vars.TF_STATE_CONTAINER }}"
        echo "Key: ${spoke_name}-integration.tfstate"
        # Check if variables are properly set
        if [ -z "$${{ vars.TF_STATE_RESOURCE_GROUP }}" ]; then
          echo "ERROR: TF_STATE_RESOURCE_GROUP variable is not set!"
          exit 1
        fi
        if [ -z "$${{ vars.TF_STATE_STORAGE_ACCOUNT }}" ]; then
          echo "ERROR: TF_STATE_STORAGE_ACCOUNT variable is not set!"
          exit 1
        fi
        if [ -z "$${{ vars.TF_STATE_CONTAINER }}" ]; then
          echo "ERROR: TF_STATE_CONTAINER variable is not set!"
          exit 1
        fi
        echo "All backend configuration variables are properly set"

    - name: Terraform Init
      id: init
      run: |
        terraform init \
          -backend-config="resource_group_name=$${{ vars.TF_STATE_RESOURCE_GROUP }}" \
          -backend-config="storage_account_name=$${{ vars.TF_STATE_STORAGE_ACCOUNT }}" \
          -backend-config="container_name=$${{ vars.TF_STATE_CONTAINER }}" \
          -backend-config="key=${spoke_name}-integration.tfstate" \
          -backend-config="use_azuread_auth=true"

    - name: Terraform Validate
      id: validate
      run: terraform validate -no-color

    - name: Terraform Plan
      id: plan
      run: terraform plan -var-file="spoke-outputs.tfvars" -no-color -input=false -out=tfplan

    - name: Terraform Plan Status
      run: |
        echo "Plan completed with status: $${{ steps.plan.outcome }}"
        if [ "$${{ steps.plan.outcome }}" == "failure" ]; then
          echo "❌ Terraform plan failed"
          exit 1
        else
          echo "✅ Terraform plan succeeded"
        fi

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'workflow_dispatch' && steps.plan.outcome == 'success'
      run: terraform apply tfplan

    - name: Terraform Output
      if: github.ref == 'refs/heads/main' && github.event_name == 'workflow_dispatch' && steps.plan.outcome == 'success'
      id: output
      run: |
        echo "Terraform outputs:"
        terraform output -json