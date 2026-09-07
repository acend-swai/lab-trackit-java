output "backend_url" {
  description = "Public URL of the TrackIt backend."
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "database_fqdn" {
  description = "PostgreSQL host. Reachable only from inside the virtual network."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "resource_group" {
  description = "Resource group holding every resource in this configuration."
  value       = azurerm_resource_group.this.name
}
