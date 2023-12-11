resource "random_password" "this" {
  length  = 16
  special = false
}

resource "azurerm_postgresql_server" "this" {
  name                             = var.name
  resource_group_name              = var.rg.name
  location                         = var.rg.location
  sku_name                         = var.sku_name
  storage_mb                       = var.storage
  backup_retention_days            = var.backup_retention_days
  geo_redundant_backup_enabled     = false
  auto_grow_enabled                = var.auto_grow
  administrator_login              = var.admin_username
  administrator_login_password     = random_password.this.result
  version                          = var.psql_version
  ssl_enforcement_enabled          = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.ssl_minimal_tls_version_enforced
  public_network_access_enabled    = var.public_access
  tags                             = var.tags
  lifecycle {
    ignore_changes = [
      storage_mb,
      tags["business_unit"],
      tags["environment"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}

resource "azurerm_postgresql_firewall_rule" "this" {
  for_each            = var.allowed_sources
  name                = each.key
  resource_group_name = azurerm_postgresql_server.this.resource_group_name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = each.value.start_address
  end_ip_address      = try(each.value.end_address, each.value.start_address)
}

resource "azurerm_private_endpoint" "this" {
  name                = azurerm_postgresql_server.this.name
  location            = azurerm_postgresql_server.this.location
  resource_group_name = azurerm_postgresql_server.this.resource_group_name
  subnet_id           = var.subnet_id
  private_service_connection {
    name                           = "${azurerm_postgresql_server.this.name}-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_server.this.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["environment"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}
