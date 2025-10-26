output "sql_server_id" {
  description = "SQL Server resource ID"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "databases" {
  description = "Map of database names to database objects"
  value       = azurerm_mssql_database.databases
}

output "database_ids" {
  description = "Map of database names to database IDs"
  value       = { for k, v in azurerm_mssql_database.databases : k => v.id }
}

output "administrator_login" {
  description = "Administrator login name"
  value       = azurerm_mssql_server.main.administrator_login
}

output "identity" {
  description = "Managed identity block"
  value       = var.identity_type != null ? azurerm_mssql_server.main.identity : null
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.identity_type != null ? azurerm_mssql_server.main.identity[0].principal_id : null
}

output "private_endpoint_sql_server_id" {
  description = "SQL Server private endpoint ID"
  value       = var.private_endpoints.sql_server != null ? azurerm_private_endpoint.sql_server[0].id : null
}

output "failover_group_id" {
  description = "Failover group ID"
  value       = var.failover_group != null ? azurerm_mssql_failover_group.main[0].id : null
}

output "firewall_rules" {
  description = "Created firewall rules"
  value       = azurerm_mssql_firewall_rule.firewall_rules
}

output "virtual_network_rules" {
  description = "Created virtual network rules"
  value       = azurerm_mssql_virtual_network_rule.vnet_rules
}