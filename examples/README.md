# SQL Database Module Examples

This directory contains examples demonstrating how to use the SQL Database module with various configurations.

## Examples

### Basic Example

The [basic example](./basic/) demonstrates a simple SQL Database deployment with:
- Single SQL Server with private endpoint
- Two databases with different configurations
- Transparent Data Encryption (TDE)
- Backup retention policies
- Security features (Advanced Threat Protection, Auditing)
- Diagnostic settings with Log Analytics
- Resource locks

**Key Features:**
- Private networking with Private DNS Zone
- Comprehensive security configuration
- Monitoring and diagnostics
- Resource protection

### High Availability Example

The [high-availability example](./high-availability/) demonstrates a production-ready SQL Database deployment with:
- Primary and secondary SQL Servers across regions
- Zone-redundant databases with read replicas
- Automatic failover group for disaster recovery
- Comprehensive security and compliance features
- Advanced monitoring and diagnostics
- Vulnerability assessment
- Enterprise-grade backup and retention policies

**Key Features:**
- Cross-region high availability
- Automatic failover capabilities
- Business continuity planning
- Advanced security posture
- Comprehensive monitoring
- Enterprise compliance

## Usage

To use these examples:

1. Navigate to the desired example directory
2. Review the `main.tf` file
3. Update variables as needed for your environment
4. Initialize Terraform:
   ```bash
   terraform init
   ```
5. Plan the deployment:
   ```bash
   terraform plan
   ```
6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Requirements

- Terraform >= 1.5.0
- AzureRM provider >= 3.80.0
- Azure subscription with appropriate permissions
- Go 1.21+ (for running tests)

## Testing

Each example can be tested using the Terratest framework:

```bash
cd examples/basic
go test -v
```

Or for the high availability example:

```bash
cd examples/high-availability
go test -v
```

## Security Considerations

These examples include enterprise-grade security features:
- Private endpoints for secure connectivity
- Advanced Threat Protection
- Transparent Data Encryption
- Extended auditing policies
- Vulnerability assessment
- Resource locks for protection against accidental deletion

## Cost Considerations

- Business Critical tier databases are expensive
- Cross-region replication doubles storage costs
- Log Analytics workspace has ingestion costs
- Private endpoints have hourly costs

## Cleanup

To clean up resources:

```bash
terraform destroy
```

**Note:** Some resources may take time to delete due to dependencies.