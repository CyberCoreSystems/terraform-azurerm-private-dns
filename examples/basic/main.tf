provider "azurerm" {
  features {}
  # Subscription is read from ARM_SUBSCRIPTION_ID; do not hardcode it here.
}

# Minimal, self-contained example: creates a resource group, a virtual network,
# the private DNS zone, the zone<->VNet link and a couple of record sets.
module "private_dns" {
  source = "../.."

  name      = "iacbazaar-pdns"
  location  = var.location
  zone_name = var.zone_name

  # Records resolvable from the linked VNet.
  a_records = {
    "app" = { ttl = 300, records = ["10.30.1.10"] }
  }
  cname_records = {
    "www" = { ttl = 300, record = "app.${var.zone_name}" }
  }

  tags = {
    environment = "example"
    managed_by  = "iac-bazaar"
  }
}
