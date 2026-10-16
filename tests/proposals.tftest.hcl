mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "github" {
  mock_data "github_repository" {
    defaults = {
      full_name = "workloads/crm"
      name      = "crm"
    }
  }
}

variables {
  github_repository_name    = "crm"
  integration_module_source = "git::https://github.com/workloads/integration-modules.git?ref=v1"
  spoke_name                = "crm"
  subscription_id           = "00000000-0000-0000-0000-000000000002"
  key_vault_id              = "/subscriptions/test/resourceGroups/test/providers/Microsoft.KeyVault/vaults/test"
  key_vault_name            = "test"
  github_api_url            = "https://enterprise.example/api/v3"
}

run "dev_proposal" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(local.proposal_files) == 10
    error_message = "The proposal must contain eight starter files and two environment files."
  }

  assert {
    condition     = local.proposal_files["main.tf"].bootstrap && !local.proposal_files["config/spoke-outputs-dev.tfvars"].bootstrap
    error_message = "Shared workload code must be bootstrap-only; environment changes must be reviewable."
  }

  assert {
    condition     = local.proposal_manifest.owner == "workloads" && local.actual_repository_name == "crm"
    error_message = "Read and write repository identities must match the provider repository."
  }

  assert {
    condition     = local.proposal_manifest.identity == "crm-dev" && !contains(keys(local.proposal_files), "config/acc.azurerm.tfbackend")
    error_message = "Dev must not publish another environment's configuration."
  }
}

run "acc_proposal" {
  command = plan

  variables {
    environment = "acc"
  }

  assert {
    condition     = contains(keys(local.proposal_files), "config/acc.azurerm.tfbackend") && contains(keys(local.proposal_files), "config/spoke-outputs-acc.tfvars")
    error_message = "The acc spoke must publish acc paths, without normalizing to acceptance."
  }

  assert {
    condition     = local.proposal_manifest.identity == "crm-acc" && !contains(keys(local.proposal_files), "config/dev.azurerm.tfbackend")
    error_message = "Acc must have a different proposal identity and must not publish dev configuration."
  }
}

run "invalid_environment" {
  command = plan

  variables {
    environment = "../dev"
  }

  expect_failures = [var.environment]
}