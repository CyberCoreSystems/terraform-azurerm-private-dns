output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = module.private_dns.private_dns_zone_id
}

output "private_dns_zone_name" {
  description = "FQDN of the private DNS zone."
  value       = module.private_dns.private_dns_zone_name
}

output "virtual_network_link_ids" {
  description = "Map of VNet-link key to resource ID."
  value       = module.private_dns.virtual_network_link_ids
}
