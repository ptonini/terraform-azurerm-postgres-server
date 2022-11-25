output "this" {
  value = azurerm_postgresql_server.this
}

output "credentials" {
  value = {
    host = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
    port = 5432
    username = "${var.admin_username}@${var.name}"
    password = random_password.this.result
    database_username = var.admin_username
  }
}