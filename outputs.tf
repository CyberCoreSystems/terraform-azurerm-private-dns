output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "private_dns_zone_name" {
  description = "Name (FQDN) of the private DNS zone."
  value       = azurerm_private_dns_zone.this.name
}

output "number_of_record_sets" {
  description = "Current number of record sets in the zone (includes the auto-created SOA/NS)."
  value       = azurerm_private_dns_zone.this.number_of_record_sets
}

output "resource_group_name" {
  description = "Name of the resource group this module created."
  value       = azurerm_resource_group.this.name
}

output "virtual_network_id" {
  description = "Resource ID of the self-created virtual network (null when create_virtual_network = false)."
  value       = var.create_virtual_network ? azurerm_virtual_network.this[0].id : null
}

output "virtual_network_name" {
  description = "Name of the self-created virtual network (null when create_virtual_network = false)."
  value       = var.create_virtual_network ? azurerm_virtual_network.this[0].name : null
}

output "virtual_network_link_ids" {
  description = "Map of VNet-link key to its resource ID (the self link uses key \"self\"; additional links use their input map keys)."
  value = merge(
    { for k, v in azurerm_private_dns_zone_virtual_network_link.self : "self" => v.id },
    { for k, v in azurerm_private_dns_zone_virtual_network_link.additional : k => v.id },
  )
}

output "a_record_ids" {
  description = "Map of A-record name to its resource ID."
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.id }
}

output "cname_record_ids" {
  description = "Map of CNAME-record name to its resource ID."
  value       = { for k, v in azurerm_private_dns_cname_record.this : k => v.id }
}
