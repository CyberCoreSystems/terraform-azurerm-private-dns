variable "location" {
  description = "Azure region for the resource group and self-created virtual network."
  type        = string
  default     = "eastus"
}

variable "zone_name" {
  description = "Fully-qualified name of the private DNS zone to create."
  type        = string
  default     = "corp.internal"
}
