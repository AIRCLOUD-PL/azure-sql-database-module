package test

import (
	"testing"
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSQLDatabaseBasic(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-test-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-test-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"databases": map[string]interface{}{
				"testdb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
					"collation":  "SQL_Latin1_General_CP1_CI_AS",
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	sqlServer := azure.GetSQLServer(t, sqlServerName, resourceGroupName, "")
	assert.Equal(t, "12.0", sqlServer.Version)
	assert.Equal(t, "1.2", sqlServer.MinTLSVersion)

	// Verify SQL Database
	databaseExists := azure.SQLDatabaseExists(t, "testdb", sqlServerName, resourceGroupName, "")
	require.True(t, databaseExists, "SQL Database should exist")

	database := azure.GetSQLDatabase(t, "testdb", sqlServerName, resourceGroupName, "")
	assert.Equal(t, "GP_Gen5_2", database.Sku.Name)
	assert.Equal(t, int32(32), database.MaxSizeGB)
}

func TestSQLDatabaseWithSecurity(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-sec-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-sec-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"minimum_tls_version":    "1.2",
			"public_network_access_enabled": false,
			"enable_advanced_threat_protection": true,
			"security_alert_policy_email_addresses": []string{"admin@example.com"},
			"enable_extended_auditing_policy": true,
			"databases": map[string]interface{}{
				"securedb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
					"transparent_data_encryption": map[string]interface{}{
						"enabled": true,
					},
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server with security features
	sqlServer := azure.GetSQLServer(t, sqlServerName, resourceGroupName, "")
	assert.Equal(t, "1.2", sqlServer.MinTLSVersion)
	assert.False(t, sqlServer.PublicNetworkAccess)

	// Verify security alert policy exists
	// Note: Azure SDK may not have direct methods for security policies
}

func TestSQLDatabaseWithPrivateEndpoint(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-pe-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-pe-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"private_endpoints": map[string]interface{}{
				"sql_server": map[string]interface{}{
					"subnet_id": "dummy-subnet-id", // Would need actual subnet in real test
					"private_dns_zone_ids": []string{"dummy-dns-zone-id"},
				},
			},
			"databases": map[string]interface{}{
				"pedb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify private endpoint exists
	privateEndpoints := azure.ListPrivateEndpoints(t, resourceGroupName)
	assert.Greater(t, len(privateEndpoints), 0, "At least one private endpoint should exist")

	sqlPEExists := false
	for _, pe := range privateEndpoints {
		if strings.Contains(pe.Name, "sql") {
			sqlPEExists = true
			break
		}
	}
	assert.True(t, sqlPEExists, "SQL Server private endpoint should exist")
}

func TestSQLDatabaseWithBackupRetention(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-backup-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-backup-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"databases": map[string]interface{}{
				"backupdb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
					"short_term_retention_policy": map[string]interface{}{
						"retention_days":           14,
						"backup_interval_in_hours": 12,
					},
					"long_term_retention_policy": map[string]interface{}{
						"weekly_retention":  "P4W",
						"monthly_retention": "P12M",
						"yearly_retention":  "P5Y",
						"week_of_year":      1,
					},
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify database exists
	databaseExists := azure.SQLDatabaseExists(t, "backupdb", sqlServerName, resourceGroupName, "")
	require.True(t, databaseExists, "SQL Database should exist")
}

func TestSQLDatabaseWithFirewallRules(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-fw-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-fw-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"public_network_access_enabled": true,
			"firewall_rules": map[string]interface{}{
				"office": map[string]interface{}{
					"start_ip_address": "203.0.113.0",
					"end_ip_address":   "203.0.113.255",
				},
				"home": map[string]interface{}{
					"start_ip_address": "198.51.100.0",
					"end_ip_address":   "198.51.100.0",
				},
			},
			"databases": map[string]interface{}{
				"fwdb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify firewall rules exist
	firewallRules := azure.ListSQLFirewallRules(t, sqlServerName, resourceGroupName, "")
	assert.GreaterOrEqual(t, len(firewallRules), 2, "At least 2 firewall rules should exist")
}

func TestSQLDatabaseHighAvailability(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-ha-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-ha-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"databases": map[string]interface{}{
				"hadb": map[string]interface{}{
					"sku_name":          "BC_Gen5_2",
					"max_size_gb":       50,
					"zone_redundant":    true,
					"read_scale":        true,
					"read_replica_count": 1,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify database exists
	databaseExists := azure.SQLDatabaseExists(t, "hadb", sqlServerName, resourceGroupName, "")
	require.True(t, databaseExists, "SQL Database should exist")

	database := azure.GetSQLDatabase(t, "hadb", sqlServerName, resourceGroupName, "")
	assert.Equal(t, "BC_Gen5_2", database.Sku.Name)
	assert.True(t, database.ZoneRedundant)
}

func TestSQLDatabaseInputValidation(t *testing.T) {
	t.Parallel()

	// Test invalid SQL version
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       "test-invalid-version",
			"resource_group_name":    "rg-test",
			"location":               "East US",
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"sql_version":            "99.0",
			"databases": map[string]interface{}{
				"testdb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},
		ExpectFailure: true,
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	require.Error(t, err, "Should fail with invalid SQL version")
	assert.Contains(t, err.Error(), "sql_version", "Error should mention sql_version validation")
}

func TestSQLDatabaseResourceLock(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-lock-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-lock-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"enable_resource_lock":   true,
			"lock_level":             "CanNotDelete",
			"databases": map[string]interface{}{
				"lockdb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify resource lock exists
	locks := azure.ListManagementLocks(t, resourceGroupName)
	lockExists := false
	for _, lock := range locks {
		if lock.Level == "CanNotDelete" {
			lockExists = true
			break
		}
	}
	assert.True(t, lockExists, "Resource lock should exist")
}

func TestSQLDatabaseVulnerabilityAssessment(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueId := random.UniqueId()
	location := "East US"
	resourceGroupName := fmt.Sprintf("rg-sql-va-%s", uniqueId)
	sqlServerName := fmt.Sprintf("sql-va-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"sql_server_name":       sqlServerName,
			"resource_group_name":    resourceGroupName,
			"location":               location,
			"environment":            "test",
			"administrator_login":    "sqladmin",
			"administrator_login_password": "P@ssw0rd123!",
			"enable_vulnerability_assessment": true,
			"vulnerability_assessment_storage_container_path": "https://storage.blob.core.windows.net/container",
			"vulnerability_assessment_storage_account_access_key": "dummy-key",
			"vulnerability_assessment_recurring_scans_enabled": true,
			"vulnerability_assessment_emails": []string{"security@example.com"},
			"databases": map[string]interface{}{
				"vadb": map[string]interface{}{
					"sku_name":    "GP_Gen5_2",
					"max_size_gb": 32,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify SQL Server exists
	sqlServerExists := azure.SQLServerExists(t, sqlServerName, resourceGroupName, "")
	require.True(t, sqlServerExists, "SQL Server should exist")

	// Verify security alert policy exists (required for vulnerability assessment)
	// Note: Azure SDK may not have direct methods for vulnerability assessment
}