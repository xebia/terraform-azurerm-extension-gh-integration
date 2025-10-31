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