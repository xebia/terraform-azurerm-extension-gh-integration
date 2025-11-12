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

variable "spoke_virtual_networks" {
  description = "Complete virtual network information from the spoke deployment"
  type = map(object({
    name          = string
    id            = string
    address_space = list(string)
    subnets = map(object({
      name             = string
      id               = string
      address_prefixes = list(string)
    }))
  }))
  default = ${spoke_virtual_networks}
}

variable "spoke_subnets" {
  description = "All subnet information in simplified format for easy access"
  type = list(object({
    vnet_name        = string
    vnet_key         = string
    subnet_name      = string
    subnet_key       = string
    subnet_id        = string
    address_prefixes = list(string)
  }))
  default = ${spoke_subnets}
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