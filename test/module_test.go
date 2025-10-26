package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSQLDatabaseModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name":      "rg-test-sql-basic",
			"location":                "westeurope",
			"environment":             "test",
			"administrator_login":     "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"databases": map[string]interface{}{
				"testdb": map[string]interface{}{
					"sku_name": "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_server.main")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_database.databases")
}

func TestSQLDatabaseModuleWithSecurity(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name":      "rg-test-sql-security",
			"location":                "westeurope",
			"environment":             "test",
			"administrator_login":     "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"public_network_access_enabled": false,
			"enable_advanced_threat_protection": true,
			"enable_vulnerability_assessment": true,
			"enable_extended_auditing_policy": true,
			"databases": map[string]interface{}{
				"securedb": map[string]interface{}{
					"sku_name": "GP_Gen5_2",
					"max_size_gb": 32,
					"zone_redundant": true,
					"transparent_data_encryption": map[string]interface{}{
						"enabled": true,
					},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_server_security_alert_policy.main")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_server_vulnerability_assessment.main")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_server_extended_auditing_policy.main")
}

func TestSQLDatabaseModuleWithPrivateEndpoint(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name":      "rg-test-sql-pe",
			"location":                "westeurope",
			"environment":             "test",
			"administrator_login":     "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"public_network_access_enabled": false,
			"private_endpoints": map[string]interface{}{
				"sql_server": map[string]interface{}{
					"subnet_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet",
				},
			},
			"databases": map[string]interface{}{
				"pedb": map[string]interface{}{
					"sku_name": "GP_Gen5_2",
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_private_endpoint.sql_server")
}

func TestSQLDatabaseModuleNamingConvention(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name":      "rg-test-sql-naming",
			"location":                "westeurope",
			"environment":             "prod",
			"naming_prefix":           "sqlprod",
			"administrator_login":     "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	resourceChanges := terraform.GetResourceChanges(t, planStruct)

	for _, change := range resourceChanges {
		if change.Type == "azurerm_mssql_server" && change.Change.After != null {
			afterMap := change.Change.After.(map[string]interface{})
			if name, ok := afterMap["name"]; ok {
				sqlName := name.(string)
				assert.Contains(t, sqlName, "prod", "SQL Server name should contain environment")
			}
		}
	}
}

func TestSQLDatabaseModuleWithFailoverGroup(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/failover",

		Vars: map[string]interface{}{
			"resource_group_name":      "rg-test-sql-failover",
			"location":                "westeurope",
			"environment":             "test",
			"administrator_login":     "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"failover_group": map[string]interface{}{
				"name": "sql-failover-group",
				"partner_server_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Sql/servers/partner-sql-server",
				"read_write_endpoint_failover_policy": map[string]interface{}{
					"mode": "Automatic",
					"grace_minutes": 60,
				},
			},
			"databases": map[string]interface{}{
				"failoverdb": map[string]interface{}{
					"sku_name": "GP_Gen5_2",
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_mssql_failover_group.main")
}