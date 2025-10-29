# Outputs for ${project_name} Integration

output "integration_resources" {
  description = "Integration resources created by the module"
  value = {
    storage_account_name = module.integration_resources.storage_account_name
    storage_account_id   = module.integration_resources.storage_account_id
    key_vault_id         = module.integration_resources.key_vault_id
    key_vault_uri        = module.integration_resources.key_vault_uri
  }
}