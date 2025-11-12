# Outputs for ${project_name} Integration

# Basic integration information
output "integration_info" {
  description = "Basic information about the integration deployment"
  value = {
    spoke_name    = var.spoke_name
    environment   = var.environment
    location      = var.spoke_location
  }
}