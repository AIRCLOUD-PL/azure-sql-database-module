terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-sql-ha-example"
  location = "East US"
}

# Virtual Network for Private Endpoints
resource "azurerm_virtual_network" "example" {
  name                = "vnet-sql-ha-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "sql" {
  name                 = "subnet-sql"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

# Log Analytics Workspace for Diagnostics
resource "azurerm_log_analytics_workspace" "example" {
  name                = "log-sql-ha-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# Secondary Region Resources for Failover Group
resource "azurerm_resource_group" "secondary" {
  name     = "rg-sql-ha-secondary"
  location = "West US"
}

resource "azurerm_virtual_network" "secondary" {
  name                = "vnet-sql-ha-secondary"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
}

resource "azurerm_subnet" "sql_secondary" {
  name                 = "subnet-sql"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.secondary.name
  address_prefixes     = ["10.1.1.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

resource "azurerm_private_dns_zone" "sql_secondary" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.secondary.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_secondary" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.secondary.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_secondary.name
  virtual_network_id    = azurerm_virtual_network.secondary.id
}

# Primary SQL Database Module
module "sql_database_primary" {
  source = "../.."

  sql_server_name     = "sql-ha-primary"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  environment         = "production"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  sql_version         = "12.0"
  minimum_tls_version = "1.2"

  public_network_access_enabled = false

  # Private Endpoint Configuration
  private_endpoints = {
    sql_server = {
      subnet_id            = azurerm_subnet.sql.id
      private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
    }
  }

  # High Availability Database Configuration
  databases = {
    appdb = {
      sku_name           = "BC_Gen5_4"
      max_size_gb        = 100
      collation          = "SQL_Latin1_General_CP1_CI_AS"
      zone_redundant     = true
      read_scale         = true
      read_replica_count = 1

      # Transparent Data Encryption
      transparent_data_encryption = {
        enabled = true
      }

      # Backup retention policies
      short_term_retention_policy = {
        retention_days           = 35
        backup_interval_in_hours = 12
      }

      long_term_retention_policy = {
        weekly_retention  = "P12W"
        monthly_retention = "P60M"
        yearly_retention  = "P10Y"
        week_of_year      = 1
      }
    }

    reporting = {
      sku_name       = "BC_Gen5_2"
      max_size_gb    = 50
      collation      = "SQL_Latin1_General_CP1_CI_AS"
      zone_redundant = true
      read_scale     = false

      transparent_data_encryption = {
        enabled = true
      }

      short_term_retention_policy = {
        retention_days           = 14
        backup_interval_in_hours = 24
      }
    }
  }

  # Security Features
  enable_advanced_threat_protection     = true
  security_alert_policy_email_addresses = ["security@example.com", "dba@example.com"]
  enable_extended_auditing_policy       = true

  # Vulnerability Assessment
  enable_vulnerability_assessment                     = true
  vulnerability_assessment_storage_container_path     = "https://examplestorage.blob.core.windows.net/vulnerability-assessment"
  vulnerability_assessment_storage_account_access_key = "dummy-key-for-example"
  vulnerability_assessment_recurring_scans_enabled    = true
  vulnerability_assessment_emails                     = ["security@example.com"]

  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  diagnostic_settings = {
    logs = [
      {
        category = "SQLSecurityAuditEvents"
        enabled  = true
      },
      {
        category = "SQLInsights"
        enabled  = true
      },
      {
        category = "AutomaticTuning"
        enabled  = true
      },
      {
        category = "QueryStoreRuntimeStatistics"
        enabled  = true
      },
      {
        category = "QueryStoreWaitStatistics"
        enabled  = true
      },
      {
        category = "Errors"
        enabled  = true
      },
      {
        category = "DatabaseWaitStatistics"
        enabled  = true
      },
      {
        category = "Timeouts"
        enabled  = true
      },
      {
        category = "Blocks"
        enabled  = true
      },
      {
        category = "Deadlocks"
        enabled  = true
      }
    ]
    metrics = [
      {
        category = "Basic"
        enabled  = true
      },
      {
        category = "InstanceAndAppAdvanced"
        enabled  = true
      },
      {
        category = "WorkloadManagement"
        enabled  = true
      }
    ]
  }

  # Resource Lock
  enable_resource_lock = true
  lock_level           = "CanNotDelete"

  # Tags
  tags = {
    Environment  = "Production"
    Project      = "SQL Database HA Module"
    Owner        = "Platform Team"
    BusinessUnit = "IT"
    CostCenter   = "INFRA-001"
    DataClass    = "Confidential"
  }
}

# Secondary SQL Database Module
module "sql_database_secondary" {
  source = "../.."

  sql_server_name     = "sql-ha-secondary"
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location
  environment         = "production"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  sql_version         = "12.0"
  minimum_tls_version = "1.2"

  public_network_access_enabled = false

  # Private Endpoint Configuration
  private_endpoints = {
    sql_server = {
      subnet_id            = azurerm_subnet.sql_secondary.id
      private_dns_zone_ids = [azurerm_private_dns_zone.sql_secondary.id]
    }
  }

  # Secondary databases (will be created as secondaries via failover group)
  databases = {
    appdb = {
      sku_name    = "BC_Gen5_4"
      max_size_gb = 100
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      transparent_data_encryption = {
        enabled = true
      }
    }

    reporting = {
      sku_name    = "BC_Gen5_2"
      max_size_gb = 50
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      transparent_data_encryption = {
        enabled = true
      }
    }
  }

  # Security Features
  enable_advanced_threat_protection     = true
  security_alert_policy_email_addresses = ["security@example.com", "dba@example.com"]
  enable_extended_auditing_policy       = true

  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  diagnostic_settings = {
    logs = [
      {
        category = "SQLSecurityAuditEvents"
        enabled  = true
      },
      {
        category = "SQLInsights"
        enabled  = true
      }
    ]
    metrics = [
      {
        category = "Basic"
        enabled  = true
      }
    ]
  }

  # Resource Lock
  enable_resource_lock = true
  lock_level           = "CanNotDelete"

  # Tags
  tags = {
    Environment  = "Production"
    Project      = "SQL Database HA Module"
    Owner        = "Platform Team"
    BusinessUnit = "IT"
    CostCenter   = "INFRA-001"
    DataClass    = "Confidential"
  }
}

# Failover Group for High Availability
resource "azurerm_mssql_failover_group" "example" {
  name      = "sql-ha-failover-group"
  server_id = module.sql_database_primary.sql_server_id
  databases = [module.sql_database_primary.database_ids["appdb"]]

  partner_server {
    id = module.sql_database_secondary.sql_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = {
    Environment = "Production"
    Project     = "SQL Database HA"
  }
}

output "primary_sql_server_id" {
  description = "The ID of the primary SQL Server"
  value       = module.sql_database_primary.sql_server_id
}

output "primary_sql_server_fqdn" {
  description = "The fully qualified domain name of the primary SQL Server"
  value       = module.sql_database_primary.sql_server_fqdn
}

output "secondary_sql_server_id" {
  description = "The ID of the secondary SQL Server"
  value       = module.sql_database_secondary.sql_server_id
}

output "secondary_sql_server_fqdn" {
  description = "The fully qualified domain name of the secondary SQL Server"
  value       = module.sql_database_secondary.sql_server_fqdn
}

output "database_ids" {
  description = "The IDs of the created databases"
  value       = module.sql_database_primary.database_ids
}

output "failover_group_id" {
  description = "The ID of the failover group"
  value       = azurerm_mssql_failover_group.example.id
}

output "private_endpoint_ids" {
  description = "The IDs of the created private endpoints"
  value = merge(
    module.sql_database_primary.private_endpoint_ids,
    module.sql_database_secondary.private_endpoint_ids
  )
}