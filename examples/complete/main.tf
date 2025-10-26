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

resource "azurerm_resource_group" "example" {
  name     = "rg-sql-complete-example"
  location = "westeurope"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-sql-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

module "sql_database" {
  source = "../.."

  sql_server_name     = "sql-complete-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  environment         = "test"

  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  # Security
  public_network_access_enabled     = false
  minimum_tls_version               = "1.2"
  enable_advanced_threat_protection = true
  enable_vulnerability_assessment   = true
  enable_extended_auditing_policy   = true

  # Identity
  identity_type = "SystemAssigned"

  # Private Endpoints
  private_endpoints = {
    sql_server = {
      subnet_id = azurerm_subnet.database.id
      private_dns_zone_ids = [
        azurerm_private_dns_zone.sql.id
      ]
    }
  }

  # Databases
  databases = {
    "appdb" = {
      sku_name       = "GP_Gen5_4"
      max_size_gb    = 100
      zone_redundant = true
      read_scale     = true

      transparent_data_encryption = {
        enabled = true
      }

      short_term_retention_policy = {
        retention_days           = 35
        backup_interval_in_hours = 12
      }

      long_term_retention_policy = {
        weekly_retention  = "P1W"
        monthly_retention = "P1M"
        yearly_retention  = "P1Y"
      }
    }

    "reporting" = {
      sku_name           = "HS_Gen5_2"
      max_size_gb        = 512
      read_replica_count = 1
    }
  }

  # Firewall Rules (for maintenance)
  firewall_rules = {
    "azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  # Virtual Network Rules
  virtual_network_rules = {
    "app-subnet" = {
      subnet_id = azurerm_subnet.database.id
    }
  }

  tags = {
    Example = "Complete"
  }
}

output "sql_server_id" {
  value = module.sql_database.sql_server_id
}

output "sql_server_name" {
  value = module.sql_database.sql_server_name
}

output "sql_server_fqdn" {
  value = module.sql_database.sql_server_fqdn
}

output "database_ids" {
  value = module.sql_database.database_ids
}

output "identity_principal_id" {
  value = module.sql_database.identity_principal_id
}

output "private_endpoint_sql_server_id" {
  value = module.sql_database.private_endpoint_sql_server_id
}