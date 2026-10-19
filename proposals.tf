locals {
  proposal_files = merge(
    { for file, content in {
      "main.tf"                         = local.main_tf_content
      "variables.tf"                    = local.variables_tf_content
      "outputs.tf"                      = local.outputs_tf_content
      "versions.tf"                     = local.versions_tf_content
      "providers.tf"                    = local.providers_tf_content
      "backend.tf"                      = local.backend_tf_content
      "README.md"                       = local.readme_content
      ".github/workflows/terraform.yml" = local.terraform_workflow_content
    } : file => { content = content, bootstrap = true } },
    { for file, content in {
      "config/spoke-outputs-${local.actual_environment}.tfvars" = local.spoke_outputs_tfvars_content
      "config/${local.actual_environment}.azurerm.tfbackend"    = local.backend_config_content
    } : file => { content = content, bootstrap = false } }
  )

  proposal_manifest = {
    owner      = split("/", data.github_repository.integration_repo.full_name)[0]
    repository = var.github_repository_name
    identity   = "${local.actual_spoke_name}-${local.actual_environment}"
    revision   = var.proposal_revision
    files      = local.proposal_files
  }
}

resource "terraform_data" "repository_proposal" {
  triggers_replace = [timestamp()]

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Za-z0-9_-]+$", local.actual_environment))
      error_message = "The resolved spoke environment must be a single path-safe name."
    }
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command"]
    command     = "& $env:XMS_PROPOSAL_SCRIPT"
    environment = {
      XMS_PROPOSAL_SCRIPT   = abspath("${path.module}/scripts/Publish-IntegrationProposal.ps1")
      XMS_PROPOSAL_MANIFEST = base64encode(jsonencode(local.proposal_manifest))
      XMS_GITHUB_API_URL    = var.github_api_url
    }
  }
}

removed {
  from = github_repository_file.spoke_outputs_tfvars
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.backend_config
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.workflow_terraform
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.main_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.variables_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.outputs_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.versions_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.providers_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.backend_tf
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.readme
  lifecycle {
    destroy = false
  }
}