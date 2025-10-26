/**
 * Security configurations and policies for SQL Database
 */

# Azure Policy - Require encryption at rest
resource "azurerm_resource_group_policy_assignment" "sql_encryption" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_mssql_server.main.name}-encryption"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/83cef61d-dbd1-4b20-a4fc-5fbc7da10833"
  display_name         = "SQL databases should use transparent data encryption"
  description          = "Ensures TDE is enabled for SQL databases"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy - Require auditing
resource "azurerm_resource_group_policy_assignment" "sql_auditing" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_mssql_server.main.name}-auditing"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/856febd9-8b03-4581-907f-88c791e2e69e"
  display_name         = "SQL servers should have auditing enabled"
  description          = "Ensures auditing is enabled for SQL servers"

  parameters = jsonencode({
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

# Azure Policy - Require threat detection
resource "azurerm_resource_group_policy_assignment" "sql_threat_detection" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_mssql_server.main.name}-threat-detection"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3e7e4b24-2c0a-4c0c-9c6b-2b4e7e7b2e2e"
  display_name         = "SQL servers should have threat detection enabled"
  description          = "Ensures threat detection is enabled for SQL servers"

  parameters = jsonencode({
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

# Azure Policy - Disable public network access
resource "azurerm_resource_group_policy_assignment" "sql_public_access" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_mssql_server.main.name}-public-access"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/28b0b1e5-17ba-4963-a7a4-5a1ab4400a0b"
  display_name         = "SQL servers should not allow public network access"
  description          = "Ensures public network access is disabled for SQL servers"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}