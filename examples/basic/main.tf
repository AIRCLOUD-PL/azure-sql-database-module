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
  name     = "rg-sql-basic-example"
  location = "East US"
}

# Virtual Network for Private Endpoint
resource "azurerm_virtual_network" "example" {
  name                = "vnet-sql-example"
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
  name                = "log-sql-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# SQL Database Module
module "sql_database" {
  source = "../.."

  sql_server_name     = "sql-basic-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  environment         = "example"

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

  # Database Configuration
  databases = {
    appdb = {
      sku_name    = "GP_Gen5_2"
      max_size_gb = 32
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      # Transparent Data Encryption
      transparent_data_encryption = {
        enabled = true
      }

      # Short-term retention policy
      short_term_retention_policy = {
        retention_days           = 7
        backup_interval_in_hours = 24
      }

      # Long-term retention policy
      long_term_retention_policy = {
        weekly_retention  = "P4W"
        monthly_retention = "P12M"
        yearly_retention  = "P5Y"
        week_of_year      = 1
      }
    }

    reporting = {
      sku_name    = "GP_Gen5_2"
      max_size_gb = 64
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      transparent_data_encryption = {
        enabled = true
      }
    }
  }

  # Security Features
  enable_advanced_threat_protection     = true
  security_alert_policy_email_addresses = ["security@example.com"]
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
      },
      {
        category = "InstanceAndAppAdvanced"
        enabled  = true
      }
    ]
  }

  # Resource Lock
  enable_resource_lock = true
  lock_level           = "CanNotDelete"

  # Tags
  tags = {
    Environment = "Example"
    Project     = "SQL Database Module"
    Owner       = "Platform Team"
  }
}

output "sql_server_id" {
  description = "The ID of the SQL Server"
  value       = module.sql_database.sql_server_id
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = module.sql_database.sql_server_fqdn
}

output "database_ids" {
  description = "The IDs of the created databases"
  value       = module.sql_database.database_ids
}

output "private_endpoint_ids" {
  description = "The IDs of the created private endpoints"
  value       = module.sql_database.private_endpoint_ids
}