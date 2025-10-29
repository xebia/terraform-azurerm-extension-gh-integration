# Outputs for Integration Module

output "integration_repository_name" {
  description = "The name of the created integration repository"
  value       = github_repository.integration_repo.name
}

output "integration_repository_url" {
  description = "The URL of the integration repository"
  value       = github_repository.integration_repo.html_url
}

output "integration_repository_clone_url" {
  description = "The clone URL of the integration repository"
  value       = github_repository.integration_repo.git_clone_url
}

output "federated_credential_main_id" {
  description = "The ID of the federated identity credential for the main branch"
  value       = azuread_application_federated_identity_credential.integration_main.id
}