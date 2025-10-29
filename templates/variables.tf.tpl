# Variables for ${project_name} Integration

variable "spoke_name" {
  description = "The name of the spoke deployment"
  type        = string
  default     = "${spoke_name}"
}

variable "spoke_resource_group_name" {
  description = "The resource group name from the spoke deployment"
  type        = string
  default     = "${spoke_resource_group_name}"
}

variable "spoke_location" {
  description = "The location of the spoke deployment"
  type        = string
  default     = "${spoke_location}"
}

variable "spoke_tags" {
  description = "Tags from the spoke deployment"
  type        = map(string)
  default     = ${spoke_tags}
}

variable "spoke_subnet_id" {
  description = "Subnet ID from the spoke deployment for private endpoints"
  type        = string
  default     = "${spoke_subnet_id}"
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = "${tenant_id}"
}

# Additional variables for integration-specific configuration
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "${environment}"
}

variable "integration_purpose" {
  description = "Purpose of this integration deployment"
  type        = string
  default     = "Additional resources for ${spoke_name}"
}