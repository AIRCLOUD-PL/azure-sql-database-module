/**
 * # Azure SQL Database Module
 *
 * Enterprise-grade Azure SQL Database module with comprehensive security, compliance, and performance features.
 *
 * ## Features
 * - SQL Server and Database provisioning
 * - High availability and disaster recovery
 * - Advanced security (TDE, auditing, threat detection)
 * - Private endpoints and VNet integration
 * - Backup and retention policies
 * - Performance monitoring and alerting
 * - Azure Policy integration
 * - Geo-redundancy and failover groups
 */

locals {
  # Auto-generate SQL Server name if not provided
  sql_server_name = var.sql_server_name != null ? var.sql_server_name : "${var.naming_prefix}${var.environment}${replace(var.location, "-", "")}sql"

  # Default tags
  default_tags = {
    ManagedBy   = "Terraform"
    Module      = "azure-sql-database"
    Environment = var.environment
  }

  tags = merge(local.default_tags, var.tags)
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                          = local.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.sql_version
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  # Administrator
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password

  # Azure AD Authentication
  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      azuread_authentication_only = try(azuread_administrator.value.azuread_authentication_only, false)
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Primary user defined identity
  primary_user_assigned_identity_id = var.primary_user_assigned_identity_id

  tags = local.tags
}

# SQL Databases
resource "azurerm_mssql_database" "databases" {
  for_each = var.databases

  name           = each.key
  server_id      = azurerm_mssql_server.main.id
  collation      = try(each.value.collation, "SQL_Latin1_General_CP1_CI_AS")
  license_type   = try(each.value.license_type, "LicenseIncluded")
  max_size_gb    = try(each.value.max_size_gb, 32)
  sku_name       = try(each.value.sku_name, "GP_Gen5_2")
  zone_redundant = try(each.value.zone_redundant, false)

  # Read scale
  read_scale = try(each.value.read_scale, false)

  # Read replica count
  read_replica_count = try(each.value.read_replica_count, 0)

  # Auto-pause
  auto_pause_delay_in_minutes = try(each.value.auto_pause_delay_in_minutes, null)

  # Minimum capacity
  min_capacity = try(each.value.min_capacity, null)

  # Maintenance configuration
  maintenance_configuration_name = try(each.value.maintenance_configuration_name, "SQL_Default")

  # Ledger
  ledger_enabled = try(each.value.ledger_enabled, false)

  # Short-term retention policy
  dynamic "short_term_retention_policy" {
    for_each = try(each.value.short_term_retention_policy, null) != null ? [each.value.short_term_retention_policy] : []
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = try(short_term_retention_policy.value.backup_interval_in_hours, null)
    }
  }

  # Long-term retention policy
  dynamic "long_term_retention_policy" {
    for_each = try(each.value.long_term_retention_policy, null) != null ? [each.value.long_term_retention_policy] : []
    content {
      weekly_retention  = try(long_term_retention_policy.value.weekly_retention, null)
      monthly_retention = try(long_term_retention_policy.value.monthly_retention, null)
      yearly_retention  = try(long_term_retention_policy.value.yearly_retention, null)
      week_of_year      = try(long_term_retention_policy.value.week_of_year, null)
    }
  }

  tags = local.tags
}

# Server Security Alert Policy (Advanced Threat Protection)
resource "azurerm_mssql_server_security_alert_policy" "main" {
  count = var.enable_advanced_threat_protection ? 1 : 0

  resource_group_name  = var.resource_group_name
  server_name          = azurerm_mssql_server.main.name
  state                = "Enabled"
  email_account_admins = var.security_alert_policy_email_account_admins
  email_addresses      = var.security_alert_policy_email_addresses
  retention_days       = var.security_alert_policy_retention_days
  disabled_alerts      = var.security_alert_policy_disabled_alerts
}

# Server Vulnerability Assessment
resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  count = var.enable_vulnerability_assessment ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main[0].id
  storage_container_path          = var.vulnerability_assessment_storage_container_path
  storage_account_access_key      = var.vulnerability_assessment_storage_account_access_key

  recurring_scans {
    enabled                   = var.vulnerability_assessment_recurring_scans_enabled
    email_subscription_admins = var.vulnerability_assessment_email_subscription_admins
    emails                    = var.vulnerability_assessment_emails
  }
}

# Server Auditing
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  count = var.enable_extended_auditing_policy ? 1 : 0

  server_id                               = azurerm_mssql_server.main.id
  storage_endpoint                        = var.auditing_policy_storage_endpoint
  storage_account_access_key              = var.auditing_policy_storage_account_access_key
  storage_account_access_key_is_secondary = var.auditing_policy_storage_account_access_key_is_secondary
  retention_in_days                       = var.auditing_policy_retention_in_days
  log_monitoring_enabled                  = var.auditing_policy_log_monitoring_enabled
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${azurerm_mssql_server.main.name}-diagnostics"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.logs
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_databases" {
  for_each = var.enable_diagnostic_settings ? var.databases : {}

  name                       = "${each.key}-diagnostics"
  target_resource_id         = azurerm_mssql_database.databases[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.logs
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

# Resource Locks
resource "azurerm_management_lock" "sql_server" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${azurerm_mssql_server.main.name}-lock"
  scope      = azurerm_mssql_server.main.id
  lock_level = var.lock_level
  notes      = "Resource lock for SQL Server"
}

resource "azurerm_management_lock" "sql_databases" {
  for_each = var.enable_resource_lock ? var.databases : {}

  name       = "${each.key}-lock"
  scope      = azurerm_mssql_database.databases[each.key].id
  lock_level = var.lock_level
  notes      = "Resource lock for SQL Database"
}

# SQL Database Extended Auditing Policies
resource "azurerm_mssql_database_extended_auditing_policy" "databases" {
  for_each = var.enable_extended_auditing_policy ? var.databases : {}

  database_id                             = azurerm_mssql_database.databases[each.key].id
  storage_endpoint                        = var.auditing_policy_storage_endpoint
  storage_account_access_key              = var.auditing_policy_storage_account_access_key
  storage_account_access_key_is_secondary = var.auditing_policy_storage_account_access_key_is_secondary
  retention_in_days                       = var.auditing_policy_retention_in_days
  log_monitoring_enabled                  = var.auditing_policy_log_monitoring_enabled

  depends_on = [
    azurerm_mssql_database.databases
  ]
}

# Private Endpoints
resource "azurerm_private_endpoint" "sql_server" {
  count = var.private_endpoints.sql_server != null ? 1 : 0

  name                = "${azurerm_mssql_server.main.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.sql_server.subnet_id

  private_service_connection {
    name                           = "${azurerm_mssql_server.main.name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoints.sql_server.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "sql-server-dns-zone-group"
      private_dns_zone_ids = var.private_endpoints.sql_server.private_dns_zone_ids
    }
  }

  tags = local.tags
}

# Failover Group
resource "azurerm_mssql_failover_group" "main" {
  count = var.failover_group != null ? 1 : 0

  name      = var.failover_group.name
  server_id = azurerm_mssql_server.main.id
  databases = [for db in azurerm_mssql_database.databases : db.id]

  partner_server {
    id = var.failover_group.partner_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = var.failover_group.read_write_endpoint_failover_policy.mode
    grace_minutes = try(var.failover_group.read_write_endpoint_failover_policy.grace_minutes, null)
  }

  tags = local.tags

  depends_on = [
    azurerm_mssql_server.main,
    azurerm_mssql_database.databases
  ]
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "firewall_rules" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Virtual Network Rules
resource "azurerm_mssql_virtual_network_rule" "vnet_rules" {
  for_each = var.virtual_network_rules

  name      = each.key
  server_id = azurerm_mssql_server.main.id
  subnet_id = each.value.subnet_id
}