# Azure Private DNS zone with virtual-network links, fully self-contained: it
# creates its own resource group, an (optional) virtual network, the private DNS
# zone, the zone<->VNet link(s) and any A/CNAME record sets. One `tofu apply`
# yields a resolvable private zone; `tofu destroy` removes everything (incl. the
# resource group).
#
# Notes on posture:
# - Private DNS zones are inherently private — they are only resolvable from
#   linked virtual networks, never from the public internet. There is no public
#   access toggle to harden.
# - Auto-registration (registration_enabled) is OFF by default: opt in per link,
#   and remember a zone may auto-register from at most ONE linked VNet.
# - The module owns its resource group, so destroy is clean and self-contained.

locals {
  resource_group_name = coalesce(var.resource_group_name, "rg-${var.name}")
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# Optional self-created VNet — the simplest way to get a link target without any
# pre-existing infrastructure.
resource "azurerm_virtual_network" "this" {
  count = var.create_virtual_network ? 1 : 0

  name                = "vnet-${var.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# The private DNS zone (global — no location argument).
resource "azurerm_private_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# Link the self-created VNet to the zone so it can resolve the zone's records.
resource "azurerm_private_dns_zone_virtual_network_link" "self" {
  count = var.create_virtual_network ? 1 : 0

  name                  = "link-${var.name}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = var.registration_enabled
  tags                  = var.tags
}

# Link any pre-existing virtual networks (keys + IDs come from input — no
# computed values in the for_each key, so this is plan-safe).
resource "azurerm_private_dns_zone_virtual_network_link" "additional" {
  for_each = var.virtual_network_links

  name                  = "link-${each.key}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = var.a_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = var.tags
}

resource "azurerm_private_dns_cname_record" "this" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = var.tags
}
