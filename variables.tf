variable "sql_server_name" {
  description = "Name of the SQL Server. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "naming_prefix" {
  description = "Prefix for SQL Server naming"
  type        = string
  default     = "sql"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
  validation {
    condition     = contains(["2.0", "12.0"], var.sql_version)
    error_message = "SQL version must be 2.0 or 12.0."
  }
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "Administrator login password"
  type        = string
  default     = null
  sensitive   = true
}

variable "azuread_administrator" {
  description = "Azure AD administrator configuration"
  type = object({
    login_username              = string
    object_id                   = string
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "identity_type" {
  description = "Type of Managed Identity"
  type        = string
  default     = "SystemAssigned"
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of User Assigned Identity IDs"
  type        = list(string)
  default     = []
}

variable "primary_user_assigned_identity_id" {
  description = "Primary user assigned identity ID"
  type        = string
  default     = null
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    collation                      = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type                   = optional(string, "LicenseIncluded")
    max_size_gb                    = optional(number, 32)
    sku_name                       = optional(string, "GP_Gen5_2")
    zone_redundant                 = optional(bool, false)
    read_scale                     = optional(bool, false)
    read_replica_count             = optional(number, 0)
    auto_pause_delay_in_minutes    = optional(number)
    min_capacity                   = optional(number)
    maintenance_configuration_name = optional(string, "SQL_Default")
    ledger_enabled                 = optional(bool, false)

    transparent_data_encryption = optional(object({
      enabled = bool
    }))

    short_term_retention_policy = optional(object({
      retention_days           = number
      backup_interval_in_hours = optional(number)
    }))

    long_term_retention_policy = optional(object({
      weekly_retention  = optional(string)
      monthly_retention = optional(string)
      yearly_retention  = optional(string)
      week_of_year      = optional(number)
    }))
  }))
  default = {}
}

variable "enable_advanced_threat_protection" {
  description = "Enable Advanced Threat Protection"
  type        = bool
  default     = true
}

variable "security_alert_policy_email_account_admins" {
  description = "Email account admins for security alerts"
  type        = bool
  default     = true
}

variable "security_alert_policy_email_addresses" {
  description = "Email addresses for security alerts"
  type        = list(string)
  default     = []
}

variable "security_alert_policy_retention_days" {
  description = "Retention days for security alerts"
  type        = number
  default     = 30
}

variable "security_alert_policy_disabled_alerts" {
  description = "Disabled alerts for security policy"
  type        = list(string)
  default     = []
}

variable "enable_vulnerability_assessment" {
  description = "Enable vulnerability assessment"
  type        = bool
  default     = true
}

variable "vulnerability_assessment_storage_container_path" {
  description = "Storage container path for vulnerability assessment"
  type        = string
  default     = null
}

variable "vulnerability_assessment_storage_account_access_key" {
  description = "Storage account access key for vulnerability assessment"
  type        = string
  default     = null
  sensitive   = true
}

variable "vulnerability_assessment_recurring_scans_enabled" {
  description = "Enable recurring vulnerability scans"
  type        = bool
  default     = true
}

variable "vulnerability_assessment_email_subscription_admins" {
  description = "Email subscription admins for vulnerability scans"
  type        = bool
  default     = true
}

variable "vulnerability_assessment_emails" {
  description = "Email addresses for vulnerability scans"
  type        = list(string)
  default     = []
}

variable "enable_extended_auditing_policy" {
  description = "Enable extended auditing policy"
  type        = bool
  default     = true
}

variable "auditing_policy_storage_endpoint" {
  description = "Storage endpoint for auditing policy"
  type        = string
  default     = null
}

variable "auditing_policy_storage_account_access_key" {
  description = "Storage account access key for auditing"
  type        = string
  default     = null
  sensitive   = true
}

variable "auditing_policy_storage_account_access_key_is_secondary" {
  description = "Use secondary storage account access key"
  type        = bool
  default     = false
}

variable "auditing_policy_retention_in_days" {
  description = "Retention days for auditing logs"
  type        = number
  default     = 30
}

variable "auditing_policy_log_monitoring_enabled" {
  description = "Enable log monitoring for auditing"
  type        = bool
  default     = true
}

variable "private_endpoints" {
  description = "Private endpoint configurations"
  type = object({
    sql_server = optional(object({
      subnet_id            = string
      private_dns_zone_ids = optional(list(string))
    }))
  })
  default = {}
}

variable "failover_group" {
  description = "Failover group configuration"
  type = object({
    name              = string
    partner_server_id = string
    read_write_endpoint_failover_policy = object({
      mode          = string
      grace_minutes = optional(number)
    })
    readonly_endpoint_failover_policy = optional(object({
      mode = string
    }))
  })
  default = null
}

variable "firewall_rules" {
  description = "Map of firewall rules"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "virtual_network_rules" {
  description = "Map of virtual network rules"
  type = map(object({
    subnet_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for SQL Server and databases"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type = object({
    logs = list(object({
      category = string
    }))
    metrics = list(object({
      category = string
      enabled  = bool
    }))
  })
  default = {
    logs = [
      { category = "SQLSecurityAuditEvents" },
      { category = "SQLInsights" },
      { category = "AutomaticTuning" },
      { category = "QueryStoreRuntimeStatistics" },
      { category = "QueryStoreWaitStatistics" },
      { category = "Errors" },
      { category = "DatabaseWaitStatistics" },
      { category = "Timeouts" },
      { category = "Blocks" },
      { category = "Deadlocks" }
    ]
    metrics = [
      { category = "Basic", enabled = true },
      { category = "InstanceAndAppAdvanced", enabled = true },
      { category = "WorkloadManagement", enabled = true }
    ]
  }
}

variable "enable_resource_lock" {
  description = "Enable resource lock for SQL Server and databases"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Resource lock level: CanNotDelete or ReadOnly"
  type        = string
  default     = "CanNotDelete"
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be CanNotDelete or ReadOnly."
  }
}

variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for SQL Database security"
  type        = bool
  default     = true
}