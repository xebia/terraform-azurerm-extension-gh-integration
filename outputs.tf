# Outputs for Integration Module

output "integration_repository_name" {
  description = "The name of the created integration repository"
  value       = data.github_repository.integration_repo.name
}

output "integration_repository_url" {
  description = "The URL of the integration repository"
  value       = data.github_repository.integration_repo.html_url
}

output "integration_repository_clone_url" {
  description = "The clone URL of the integration repository"
  value       = data.github_repository.integration_repo.git_clone_url
}

# Note: federated_credential_main_id output removed since the federated identity credential
# is now managed by the gh-repo extension, not the integration module

# Feature flags status - useful for consumers to know what was enabled
output "features_enabled" {
  description = "Map of enabled features in this module instance"
  value = {
    integration_templates        = var.enable_integration_templates
    spoke_outputs_tfvars         = var.enable_spoke_outputs_tfvars
    github_workflow              = var.enable_github_workflow
    terraform_base_files         = var.enable_terraform_base_files
    github_environment_variables = var.enable_github_environment_variables
    readme                       = var.enable_readme
  }
}