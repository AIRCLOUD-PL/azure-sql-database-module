package test

import (
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// SQLDatabaseTestHelper provides helper functions for SQL Database testing
type SQLDatabaseTestHelper struct {
	ResourceGroupName string
	SQLServerName     string
	Location          string
}

// NewSQLDatabaseTestHelper creates a new test helper instance
func NewSQLDatabaseTestHelper(resourceGroupName, sqlServerName, location string) *SQLDatabaseTestHelper {
	return &SQLDatabaseTestHelper{
		ResourceGroupName: resourceGroupName,
		SQLServerName:     sqlServerName,
		Location:          location,
	}
}

// ValidateSQLServer validates basic SQL Server properties
func (h *SQLDatabaseTestHelper) ValidateSQLServer(expectedVersion string, expectedTLSVersion string) error {
	sqlServer := azure.GetSQLServer(nil, h.SQLServerName, h.ResourceGroupName, "")
	if sqlServer.Version != expectedVersion {
		return fmt.Errorf("expected SQL Server version %s, got %s", expectedVersion, sqlServer.Version)
	}
	if sqlServer.MinTLSVersion != expectedTLSVersion {
		return fmt.Errorf("expected TLS version %s, got %s", expectedTLSVersion, sqlServer.MinTLSVersion)
	}
	return nil
}

// ValidateSQLDatabase validates basic SQL Database properties
func (h *SQLDatabaseTestHelper) ValidateSQLDatabase(databaseName, expectedSKU string, expectedMaxSizeGB int32) error {
	database := azure.GetSQLDatabase(nil, databaseName, h.SQLServerName, h.ResourceGroupName, "")
	if database.Sku.Name != expectedSKU {
		return fmt.Errorf("expected SKU %s, got %s", expectedSKU, database.Sku.Name)
	}
	if database.MaxSizeGB != expectedMaxSizeGB {
		return fmt.Errorf("expected max size %d GB, got %d GB", expectedMaxSizeGB, database.MaxSizeGB)
	}
	return nil
}

// ValidatePrivateEndpoint validates that a private endpoint exists for SQL Server
func (h *SQLDatabaseTestHelper) ValidatePrivateEndpoint() error {
	privateEndpoints := azure.ListPrivateEndpoints(nil, h.ResourceGroupName)
	for _, pe := range privateEndpoints {
		if strings.Contains(strings.ToLower(pe.Name), "sql") {
			return nil
		}
	}
	return fmt.Errorf("no SQL Server private endpoint found")
}

// ValidateFirewallRules validates that firewall rules exist
func (h *SQLDatabaseTestHelper) ValidateFirewallRules(minRules int) error {
	firewallRules := azure.ListSQLFirewallRules(nil, h.SQLServerName, h.ResourceGroupName, "")
	if len(firewallRules) < minRules {
		return fmt.Errorf("expected at least %d firewall rules, got %d", minRules, len(firewallRules))
	}
	return nil
}

// ValidateResourceLock validates that a resource lock exists
func (h *SQLDatabaseTestHelper) ValidateResourceLock(expectedLevel string) error {
	locks := azure.ListManagementLocks(nil, h.ResourceGroupName)
	for _, lock := range locks {
		if lock.Level == expectedLevel {
			return nil
		}
	}
	return fmt.Errorf("no resource lock with level %s found", expectedLevel)
}

// GetTerraformOptions creates terraform options for SQL Database module
func GetTerraformOptions(resourceGroupName, sqlServerName, location string, additionalVars map[string]interface{}) *terraform.Options {
	baseVars := map[string]interface{}{
		"sql_server_name":       sqlServerName,
		"resource_group_name":    resourceGroupName,
		"location":               location,
		"environment":            "test",
		"administrator_login":    "sqladmin",
		"administrator_login_password": "P@ssw0rd123!",
	}

	// Merge additional variables
	for key, value := range additionalVars {
		baseVars[key] = value
	}

	return &terraform.Options{
		TerraformDir: "../",
		Vars:         baseVars,
	}
}

// GetBasicDatabaseConfig returns a basic database configuration for testing
func GetBasicDatabaseConfig() map[string]interface{} {
	return map[string]interface{}{
		"databases": map[string]interface{}{
			"testdb": map[string]interface{}{
				"sku_name":    "GP_Gen5_2",
				"max_size_gb": 32,
				"collation":  "SQL_Latin1_General_CP1_CI_AS",
			},
		},
	}
}

// GetSecureDatabaseConfig returns a secure database configuration for testing
func GetSecureDatabaseConfig() map[string]interface{} {
	return map[string]interface{}{
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
	}
}

// GetHighAvailabilityDatabaseConfig returns a high availability database configuration
func GetHighAvailabilityDatabaseConfig() map[string]interface{} {
	return map[string]interface{}{
		"databases": map[string]interface{}{
			"hadb": map[string]interface{}{
				"sku_name":          "BC_Gen5_2",
				"max_size_gb":       50,
				"zone_redundant":    true,
				"read_scale":        true,
				"read_replica_count": 1,
			},
		},
	}
}