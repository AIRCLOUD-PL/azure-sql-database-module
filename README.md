<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-sql-database-module

**Azure SQL Database Terraform module — parameterised, azurerm 4.x, CI-validated.**

[![CI](https://github.com/AIRCLOUD-PL/azure-sql-database-module/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-sql-database-module/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-sql-database-module?sort=semver)](https://github.com/AIRCLOUD-PL/azure-sql-database-module/releases)

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

Pin the module to a release tag:

```hcl
module "sql_database" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-sql-database-module.git?ref=v1.0.0"

  # required inputs
  environment         = "..."
  location            = "..."
  resource_group_name = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

### Basic Example

```hcl
module "sql_database" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-sql-database-module.git?ref=v1.0.0"

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
  source = "git::https://github.com/AIRCLOUD-PL/azure-sql-database-module.git?ref=v1.0.0"

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
  source = "git::https://github.com/AIRCLOUD-PL/azure-sql-database-module.git?ref=v1.0.0"

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
  source = "git::https://github.com/AIRCLOUD-PL/azure-sql-database-module.git?ref=v1.0.0"

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

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.sql_databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_monitor_diagnostic_setting.sql_databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_mssql_database.databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_database_extended_auditing_policy.databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database_extended_auditing_policy) | resource |
| [azurerm_mssql_failover_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_failover_group) | resource |
| [azurerm_mssql_firewall_rule.firewall_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) | resource |
| [azurerm_mssql_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_server_extended_auditing_policy.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_extended_auditing_policy) | resource |
| [azurerm_mssql_server_security_alert_policy.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_security_alert_policy) | resource |
| [azurerm_mssql_server_vulnerability_assessment.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_vulnerability_assessment) | resource |
| [azurerm_mssql_virtual_network_rule.vnet_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_virtual_network_rule) | resource |
| [azurerm_private_endpoint.sql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group_policy_assignment.sql_auditing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.sql_encryption](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.sql_public_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.sql_threat_detection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Administrator login name | `string` | `null` | no |
| <a name="input_administrator_login_password"></a> [administrator\_login\_password](#input\_administrator\_login\_password) | Administrator login password | `string` | `null` | no |
| <a name="input_auditing_policy_log_monitoring_enabled"></a> [auditing\_policy\_log\_monitoring\_enabled](#input\_auditing\_policy\_log\_monitoring\_enabled) | Enable log monitoring for auditing | `bool` | `true` | no |
| <a name="input_auditing_policy_retention_in_days"></a> [auditing\_policy\_retention\_in\_days](#input\_auditing\_policy\_retention\_in\_days) | Retention days for auditing logs | `number` | `30` | no |
| <a name="input_auditing_policy_storage_account_access_key"></a> [auditing\_policy\_storage\_account\_access\_key](#input\_auditing\_policy\_storage\_account\_access\_key) | Storage account access key for auditing | `string` | `null` | no |
| <a name="input_auditing_policy_storage_account_access_key_is_secondary"></a> [auditing\_policy\_storage\_account\_access\_key\_is\_secondary](#input\_auditing\_policy\_storage\_account\_access\_key\_is\_secondary) | Use secondary storage account access key | `bool` | `false` | no |
| <a name="input_auditing_policy_storage_endpoint"></a> [auditing\_policy\_storage\_endpoint](#input\_auditing\_policy\_storage\_endpoint) | Storage endpoint for auditing policy | `string` | `null` | no |
| <a name="input_azuread_administrator"></a> [azuread\_administrator](#input\_azuread\_administrator) | Azure AD administrator configuration | <pre>object({<br/>    login_username              = string<br/>    object_id                   = string<br/>    azuread_authentication_only = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Map of databases to create | <pre>map(object({<br/>    collation                      = optional(string, "SQL_Latin1_General_CP1_CI_AS")<br/>    license_type                   = optional(string, "LicenseIncluded")<br/>    max_size_gb                    = optional(number, 32)<br/>    sku_name                       = optional(string, "GP_Gen5_2")<br/>    zone_redundant                 = optional(bool, false)<br/>    read_scale                     = optional(bool, false)<br/>    read_replica_count             = optional(number, 0)<br/>    auto_pause_delay_in_minutes    = optional(number)<br/>    min_capacity                   = optional(number)<br/>    maintenance_configuration_name = optional(string, "SQL_Default")<br/>    ledger_enabled                 = optional(bool, false)<br/><br/>    transparent_data_encryption = optional(object({<br/>      enabled = bool<br/>    }))<br/><br/>    short_term_retention_policy = optional(object({<br/>      retention_days           = number<br/>      backup_interval_in_hours = optional(number)<br/>    }))<br/><br/>    long_term_retention_policy = optional(object({<br/>      weekly_retention  = optional(string)<br/>      monthly_retention = optional(string)<br/>      yearly_retention  = optional(string)<br/>      week_of_year      = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | Diagnostic settings configuration | <pre>object({<br/>    logs = list(object({<br/>      category = string<br/>    }))<br/>    metrics = list(object({<br/>      category = string<br/>      enabled  = bool<br/>    }))<br/>  })</pre> | <pre>{<br/>  "logs": [<br/>    {<br/>      "category": "SQLSecurityAuditEvents"<br/>    },<br/>    {<br/>      "category": "SQLInsights"<br/>    },<br/>    {<br/>      "category": "AutomaticTuning"<br/>    },<br/>    {<br/>      "category": "QueryStoreRuntimeStatistics"<br/>    },<br/>    {<br/>      "category": "QueryStoreWaitStatistics"<br/>    },<br/>    {<br/>      "category": "Errors"<br/>    },<br/>    {<br/>      "category": "DatabaseWaitStatistics"<br/>    },<br/>    {<br/>      "category": "Timeouts"<br/>    },<br/>    {<br/>      "category": "Blocks"<br/>    },<br/>    {<br/>      "category": "Deadlocks"<br/>    }<br/>  ],<br/>  "metrics": [<br/>    {<br/>      "category": "Basic",<br/>      "enabled": true<br/>    },<br/>    {<br/>      "category": "InstanceAndAppAdvanced",<br/>      "enabled": true<br/>    },<br/>    {<br/>      "category": "WorkloadManagement",<br/>      "enabled": true<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_enable_advanced_threat_protection"></a> [enable\_advanced\_threat\_protection](#input\_enable\_advanced\_threat\_protection) | Enable Advanced Threat Protection | `bool` | `true` | no |
| <a name="input_enable_diagnostic_settings"></a> [enable\_diagnostic\_settings](#input\_enable\_diagnostic\_settings) | Enable diagnostic settings for SQL Server and databases | `bool` | `true` | no |
| <a name="input_enable_extended_auditing_policy"></a> [enable\_extended\_auditing\_policy](#input\_enable\_extended\_auditing\_policy) | Enable extended auditing policy | `bool` | `true` | no |
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Enable Azure Policy assignments for SQL Database security | `bool` | `true` | no |
| <a name="input_enable_resource_lock"></a> [enable\_resource\_lock](#input\_enable\_resource\_lock) | Enable resource lock for SQL Server and databases | `bool` | `false` | no |
| <a name="input_enable_vulnerability_assessment"></a> [enable\_vulnerability\_assessment](#input\_enable\_vulnerability\_assessment) | Enable vulnerability assessment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| <a name="input_failover_group"></a> [failover\_group](#input\_failover\_group) | Failover group configuration | <pre>object({<br/>    name              = string<br/>    partner_server_id = string<br/>    read_write_endpoint_failover_policy = object({<br/>      mode          = string<br/>      grace_minutes = optional(number)<br/>    })<br/>    readonly_endpoint_failover_policy = optional(object({<br/>      mode = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | Map of firewall rules | <pre>map(object({<br/>    start_ip_address = string<br/>    end_ip_address   = string<br/>  }))</pre> | `{}` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | List of User Assigned Identity IDs | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Type of Managed Identity | `string` | `"SystemAssigned"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_lock_level"></a> [lock\_level](#input\_lock\_level) | Resource lock level: CanNotDelete or ReadOnly | `string` | `"CanNotDelete"` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for diagnostic settings | `string` | `null` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version | `string` | `"1.2"` | no |
| <a name="input_naming_prefix"></a> [naming\_prefix](#input\_naming\_prefix) | Prefix for SQL Server naming | `string` | `"sql"` | no |
| <a name="input_primary_user_assigned_identity_id"></a> [primary\_user\_assigned\_identity\_id](#input\_primary\_user\_assigned\_identity\_id) | Primary user assigned identity ID | `string` | `null` | no |
| <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints) | Private endpoint configurations | <pre>object({<br/>    sql_server = optional(object({<br/>      subnet_id            = string<br/>      private_dns_zone_ids = optional(list(string))<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable public network access | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_security_alert_policy_disabled_alerts"></a> [security\_alert\_policy\_disabled\_alerts](#input\_security\_alert\_policy\_disabled\_alerts) | Disabled alerts for security policy | `list(string)` | `[]` | no |
| <a name="input_security_alert_policy_email_account_admins"></a> [security\_alert\_policy\_email\_account\_admins](#input\_security\_alert\_policy\_email\_account\_admins) | Email account admins for security alerts | `bool` | `true` | no |
| <a name="input_security_alert_policy_email_addresses"></a> [security\_alert\_policy\_email\_addresses](#input\_security\_alert\_policy\_email\_addresses) | Email addresses for security alerts | `list(string)` | `[]` | no |
| <a name="input_security_alert_policy_retention_days"></a> [security\_alert\_policy\_retention\_days](#input\_security\_alert\_policy\_retention\_days) | Retention days for security alerts | `number` | `30` | no |
| <a name="input_sql_server_name"></a> [sql\_server\_name](#input\_sql\_server\_name) | Name of the SQL Server. If null, will be auto-generated. | `string` | `null` | no |
| <a name="input_sql_version"></a> [sql\_version](#input\_sql\_version) | SQL Server version | `string` | `"12.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_rules"></a> [virtual\_network\_rules](#input\_virtual\_network\_rules) | Map of virtual network rules | <pre>map(object({<br/>    subnet_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_vulnerability_assessment_email_subscription_admins"></a> [vulnerability\_assessment\_email\_subscription\_admins](#input\_vulnerability\_assessment\_email\_subscription\_admins) | Email subscription admins for vulnerability scans | `bool` | `true` | no |
| <a name="input_vulnerability_assessment_emails"></a> [vulnerability\_assessment\_emails](#input\_vulnerability\_assessment\_emails) | Email addresses for vulnerability scans | `list(string)` | `[]` | no |
| <a name="input_vulnerability_assessment_recurring_scans_enabled"></a> [vulnerability\_assessment\_recurring\_scans\_enabled](#input\_vulnerability\_assessment\_recurring\_scans\_enabled) | Enable recurring vulnerability scans | `bool` | `true` | no |
| <a name="input_vulnerability_assessment_storage_account_access_key"></a> [vulnerability\_assessment\_storage\_account\_access\_key](#input\_vulnerability\_assessment\_storage\_account\_access\_key) | Storage account access key for vulnerability assessment | `string` | `null` | no |
| <a name="input_vulnerability_assessment_storage_container_path"></a> [vulnerability\_assessment\_storage\_container\_path](#input\_vulnerability\_assessment\_storage\_container\_path) | Storage container path for vulnerability assessment | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_administrator_login"></a> [administrator\_login](#output\_administrator\_login) | Administrator login name |
| <a name="output_database_ids"></a> [database\_ids](#output\_database\_ids) | Map of database names to database IDs |
| <a name="output_databases"></a> [databases](#output\_databases) | Map of database names to database objects |
| <a name="output_failover_group_id"></a> [failover\_group\_id](#output\_failover\_group\_id) | Failover group ID |
| <a name="output_firewall_rules"></a> [firewall\_rules](#output\_firewall\_rules) | Created firewall rules |
| <a name="output_identity"></a> [identity](#output\_identity) | Managed identity block |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | Principal ID of the system-assigned managed identity |
| <a name="output_private_endpoint_sql_server_id"></a> [private\_endpoint\_sql\_server\_id](#output\_private\_endpoint\_sql\_server\_id) | SQL Server private endpoint ID |
| <a name="output_sql_server_fqdn"></a> [sql\_server\_fqdn](#output\_sql\_server\_fqdn) | SQL Server fully qualified domain name |
| <a name="output_sql_server_id"></a> [sql\_server\_id](#output\_sql\_server\_id) | SQL Server resource ID |
| <a name="output_sql_server_name"></a> [sql\_server\_name](#output\_sql\_server\_name) | SQL Server name |
| <a name="output_virtual_network_rules"></a> [virtual\_network\_rules](#output\_virtual\_network\_rules) | Created virtual network rules |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
