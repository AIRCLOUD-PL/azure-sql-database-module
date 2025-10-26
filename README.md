# Azure SQL Database Terraform Module

Enterprise-grade Azure SQL Database module with comprehensive security, compliance, and performance features.

## Features

✅ **High Availability** - Zone redundancy, geo-redundancy, failover groups, read replicas  
✅ **Advanced Security** - TDE, auditing, threat detection, vulnerability assessment, Azure Policy  
✅ **Network Security** - Private endpoints, VNet integration, firewall rules, service endpoints  
✅ **Backup & Recovery** - Automated backups, retention policies, point-in-time restore, LTR  
✅ **Performance** - Multiple service tiers, auto-scaling, performance insights, query store  
✅ **Compliance** - Azure Policy integration, audit logging, data classification  
✅ **Identity** - Azure AD authentication, managed identities, RBAC  
✅ **Monitoring** - Advanced diagnostics, Log Analytics, Application Insights integration  
✅ **Testing** - Comprehensive Terratest suite with security and performance validation  

## Usage

### Basic Example

```hcl
module "sql_database" {
  source = "./modules/database/sql-database"

  sql_server_name           = "sql-prod-westeurope-001"
  location                  = "East US"
  resource_group_name       = "rg-production"
  environment               = "prod"

  administrator_login       = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  databases = {
    "appdb" = {
      sku_name    = "GP_Gen5_2"
      max_size_gb = 32
    }
  }

  tags = {
    Environment = "Production"
  }
}
```

### Enterprise Example with Full Security

```hcl
module "sql_database" {
  source = "./modules/database/sql-database"

  sql_server_name           = "sql-prod-westeurope-001"
  location                  = "East US"
  resource_group_name       = "rg-production"
  environment               = "prod"

  # Authentication
  administrator_login       = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  azuread_administrator = {
    login_username = "sql-admin@domain.com"
    object_id      = "00000000-0000-0000-0000-000000000000"
  }

  # Security Configuration
  public_network_access_enabled = false
  minimum_tls_version          = "1.2"
  enable_advanced_threat_protection = true
  enable_vulnerability_assessment  = true
  enable_extended_auditing_policy  = true

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

  # High Availability Databases
  databases = {
    "appdb" = {
      sku_name        = "BC_Gen5_4"
      max_size_gb     = 100
      zone_redundant  = true
      read_scale      = true
      read_replica_count = 1

      transparent_data_encryption = {
        enabled = true
      }

      short_term_retention_policy = {
        retention_days = 35
        backup_interval_in_hours = 12
      }

      long_term_retention_policy = {
        weekly_retention  = "P12W"
        monthly_retention = "P60M"
        yearly_retention  = "P10Y"
        week_of_year      = 1
      }
    }

    "reporting" = {
      sku_name    = "HS_Gen5_2"
      max_size_gb = 512
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
      subnet_id = azurerm_subnet.application.id
    }
  }

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

  # Resource Protection
  enable_resource_lock = true
  lock_level           = "CanNotDelete"

  tags = {
    Environment = "Production"
    DataClass   = "Confidential"
    Compliance  = "SOX"
    Owner       = "Platform Team"
  }
}
```

### High Availability with Failover Group

```hcl
module "sql_database_primary" {
  source = "./modules/database/sql-database"

  sql_server_name           = "sql-prod-primary"
  location                  = "East US"
  resource_group_name       = "rg-production"
  environment               = "prod"

  administrator_login       = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  databases = {
    "appdb" = {
      sku_name    = "BC_Gen5_4"
      max_size_gb = 100
      zone_redundant = true
    }
  }
}

module "sql_database_secondary" {
  source = "./modules/database/sql-database"

  sql_server_name           = "sql-prod-secondary"
  location                  = "West US"
  resource_group_name       = "rg-production"
  environment               = "prod"

  administrator_login       = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  databases = {
    "appdb" = {
      sku_name    = "BC_Gen5_4"
      max_size_gb = 100
    }
  }
}

# Failover Group
resource "azurerm_mssql_failover_group" "example" {
  name         = "sql-failover-group"
  server_id    = module.sql_database_primary.sql_server_id
  databases    = [module.sql_database_primary.database_ids["appdb"]]

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
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |
| go | >= 1.21 (for testing) |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| sql_server_name | Name of the SQL Server | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| administrator_login | SQL admin login | `string` | n/a | yes |
| administrator_login_password | SQL admin password | `string` | n/a | yes |
| sql_version | SQL Server version | `string` | `"12.0"` | no |
| minimum_tls_version | Minimum TLS version | `string` | `"1.2"` | no |
| public_network_access_enabled | Enable public network access | `bool` | `false` | no |
| databases | Database configurations | `map(object)` | `{}` | no |
| private_endpoints | Private endpoint configurations | `object` | `{}` | no |
| firewall_rules | Firewall rules | `map(object)` | `{}` | no |
| virtual_network_rules | Virtual network rules | `map(object)` | `{}` | no |
| azuread_administrator | Azure AD administrator config | `object` | `{}` | no |
| identity_type | Managed identity type | `string` | `"SystemAssigned"` | no |
| enable_advanced_threat_protection | Enable Advanced Threat Protection | `bool` | `false` | no |
| enable_vulnerability_assessment | Enable vulnerability assessment | `bool` | `false` | no |
| enable_extended_auditing_policy | Enable extended auditing | `bool` | `false` | no |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `false` | no |
| enable_resource_lock | Enable resource lock | `bool` | `false` | no |
| lock_level | Resource lock level | `string` | `"CanNotDelete"` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sql_server_id | SQL Server resource ID |
| sql_server_name | SQL Server name |
| sql_server_fqdn | SQL Server fully qualified domain name |
| database_ids | Map of database names to resource IDs |
| database_names | List of database names |
| private_endpoint_ids | Map of private endpoint names to resource IDs |
| identity_principal_id | Managed identity principal ID |
| identity_tenant_id | Managed identity tenant ID |

## Examples

- [Basic](./examples/basic/) - Simple SQL Database with private endpoint
- [High Availability](./examples/high-availability/) - Production-ready HA setup with failover groups

## Security Features

### Data Protection
- **Transparent Data Encryption (TDE)** - Always encrypted data at rest
- **Advanced Threat Protection** - Real-time security monitoring and alerts
- **Vulnerability Assessment** - Automated security scanning with email notifications
- **Extended Auditing** - Comprehensive audit logging to storage/Log Analytics

### Network Security
- **Private Endpoints** - Secure private connectivity without public exposure
- **VNet Integration** - Network isolation and service endpoints
- **Firewall Rules** - Granular IP-based access control
- **TLS 1.2 Minimum** - Secure data in transit encryption

### High Availability & Disaster Recovery
- **Zone Redundancy** - Cross-availability zone replication
- **Geo-Redundancy** - Cross-region failover with automatic failover groups
- **Read Replicas** - Read scale-out for performance optimization
- **Automated Backups** - Point-in-time restore with configurable retention

### Compliance & Governance
- **Azure Policy Integration** - Automated compliance enforcement
- **Azure AD Integration** - Modern authentication with conditional access
- **Managed Identity** - Secure service-to-service authentication
- **Resource Locks** - Protection against accidental deletion
- **Diagnostic Settings** - Comprehensive monitoring and alerting

## Testing

The module includes comprehensive Terratest suites:

```bash
# Run all tests
cd test
go test -v

# Run specific test
go test -run TestSQLDatabaseBasic -v

# Run with parallel execution
go test -parallel 4 -v
```

Test scenarios include:
- Basic SQL Server and database creation
- Security features validation
- Private endpoint connectivity
- High availability configurations
- Backup and retention policies
- Firewall rules and network security
- Resource locks and protection
- Input validation and error handling

## Version

Current version: **v1.0.0**

## Contributing

1. Follow the established patterns for enterprise security
2. Include comprehensive tests for new features
3. Update documentation and examples
4. Ensure backward compatibility

## License

MIT