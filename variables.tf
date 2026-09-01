variable "name" {
  description = "Base name for the deployment; prefixes the resource group (when derived), the self-created virtual network and the VNet link. Keep it short and DNS-safe."
  type        = string
  default     = "privatedns"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,38}[a-z0-9]$", var.name))
    error_message = "name must be 2-40 chars: lowercase letters, digits and hyphens; start and end alphanumeric."
  }
}

variable "location" {
  description = "Azure region for the resource group and the (optional) self-created virtual network. Private DNS zones themselves are global, so this only governs the regional resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create. Null derives \"rg-<name>\". This module is self-contained and creates (and on destroy removes) this resource group, the private DNS zone and any VNet links/records."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Private DNS zone
# -----------------------------------------------------------------------------

variable "zone_name" {
  description = <<-EOT
    REQUIRED. Fully-qualified name of the private DNS zone. Use a custom internal
    domain (e.g. "corp.internal", "example.private") or an Azure Private Link zone
    (e.g. "privatelink.blob.core.windows.net"). Must be a multi-label DNS name —
    single-label zones are not permitted.
  EOT
  type        = string

  validation {
    condition     = length(var.zone_name) <= 253 && can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.zone_name))
    error_message = "zone_name must be a valid multi-label DNS name <= 253 chars (e.g. \"corp.internal\" or \"privatelink.blob.core.windows.net\")."
  }
}

# -----------------------------------------------------------------------------
# Self-created virtual network (the simplest, fully self-contained topology)
# -----------------------------------------------------------------------------

variable "create_virtual_network" {
  description = "Create a virtual network in this module and link the zone to it. Set false to only manage the zone and link pre-existing VNets via virtual_network_links."
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "Address space for the self-created virtual network (only used when create_virtual_network = true). Private address ranges are recommended."
  type        = list(string)
  default     = ["10.30.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for c in var.vnet_address_space : can(cidrnetmask(c))])
    error_message = "vnet_address_space must be a non-empty list of valid IPv4 CIDR blocks (e.g. [\"10.30.0.0/16\"])."
  }
}

variable "registration_enabled" {
  description = "Enable auto-registration of VM DNS records in the zone for the self-created VNet link. Off by default (a single zone may have auto-registration enabled on only one linked VNet). Ignored when create_virtual_network = false."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Additional links to pre-existing virtual networks
# -----------------------------------------------------------------------------

variable "virtual_network_links" {
  description = <<-EOT
    Map of links to EXISTING virtual networks, keyed by a short link name. Each
    value carries the target VNet's resource ID and whether auto-registration is
    enabled for that link. Remember: at most one linked VNet (across this map and
    the self-created VNet) may have registration_enabled = true.
  EOT
  type = map(object({
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.virtual_network_links) :
      can(regex("^/subscriptions/.+/virtualNetworks/.+$", v.virtual_network_id))
    ])
    error_message = "each virtual_network_links[*].virtual_network_id must be a full VNet resource ID (/subscriptions/.../virtualNetworks/<name>)."
  }
}

# -----------------------------------------------------------------------------
# Record sets (optional)
# -----------------------------------------------------------------------------

variable "a_records" {
  description = "A records to create in the zone, keyed by record name (use \"@\" for the apex). Each value sets a TTL (seconds) and one or more IPv4 addresses."
  type = map(object({
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.a_records) :
      r.ttl >= 1 && r.ttl <= 2147483647 && length(r.records) > 0
    ])
    error_message = "each a_records[*] needs a ttl in 1..2147483647 and at least one IPv4 address."
  }
}

variable "cname_records" {
  description = "CNAME records to create in the zone, keyed by record name. Each value sets a TTL (seconds) and a single canonical target name."
  type = map(object({
    ttl    = optional(number, 300)
    record = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.cname_records) :
      r.ttl >= 1 && r.ttl <= 2147483647 && length(r.record) > 0
    ])
    error_message = "each cname_records[*] needs a ttl in 1..2147483647 and a non-empty canonical name."
  }
}

variable "tags" {
  description = "Tags applied to all resources (resource group, virtual network, zone, links and records)."
  type        = map(string)
  default     = {}
}
