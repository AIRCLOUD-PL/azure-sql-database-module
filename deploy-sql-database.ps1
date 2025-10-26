# SQL Database Module Deployment Script
# This script provides automation for deploying, testing, and managing the SQL Database module

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "deploy",

    [Parameter(Mandatory=$false)]
    [string]$Environment = "test",

    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "",

    [Parameter(Mandatory=$false)]
    [string]$SQLServerName = "",

    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,

    [Parameter(Mandatory=$false)]
    [switch]$Cleanup
)

# Configuration
$ModulePath = Join-Path $PSScriptRoot "..\modules\database\sql-database"
$TestPath = Join-Path $ModulePath "test"
$ExamplesPath = Join-Path $ModulePath "examples"

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." $Cyan

    # Check Terraform
    try {
        $tfVersion = terraform version
        Write-ColorOutput "✓ Terraform installed: $tfVersion" $Green
    } catch {
        Write-ColorOutput "✗ Terraform not found. Please install Terraform >= 1.5.0" $Red
        exit 1
    }

    # Check Go
    try {
        $goVersion = go version
        Write-ColorOutput "✓ Go installed: $goVersion" $Green
    } catch {
        Write-ColorOutput "✗ Go not found. Please install Go >= 1.21" $Red
        exit 1
    }

    # Check Azure CLI
    try {
        $azVersion = az version --query '"azure-cli"' -o tsv
        Write-ColorOutput "✓ Azure CLI installed: $azVersion" $Green
    } catch {
        Write-ColorOutput "✗ Azure CLI not found. Please install Azure CLI" $Red
        exit 1
    }

    Write-ColorOutput "Prerequisites check completed." $Green
}

function Initialize-Module {
    Write-ColorOutput "Initializing SQL Database module..." $Cyan

    Push-Location $ModulePath

    try {
        Write-ColorOutput "Running terraform init..." $Yellow
        terraform init -backend=false

        Write-ColorOutput "Running terraform validate..." $Yellow
        terraform validate

        Write-ColorOutput "✓ Module initialized successfully" $Green
    } catch {
        Write-ColorOutput "✗ Module initialization failed: $_" $Red
        Pop-Location
        exit 1
    }

    Pop-Location
}

function Invoke-Tests {
    if ($SkipTests) {
        Write-ColorOutput "Skipping tests as requested." $Yellow
        return
    }

    Write-ColorOutput "Running Terratest suite..." $Cyan

    Push-Location $TestPath

    try {
        Write-ColorOutput "Installing Go dependencies..." $Yellow
        go mod download

        Write-ColorOutput "Running Go vet..." $Yellow
        go vet ./...

        Write-ColorOutput "Running Go fmt check..." $Yellow
        $fmtResult = gofmt -s -l .
        if ($fmtResult) {
            Write-ColorOutput "✗ Go code formatting issues found:" $Red
            Write-ColorOutput $fmtResult $Red
            exit 1
        }

        Write-ColorOutput "Compiling tests..." $Yellow
        go test -c -o sql_database_test

        Write-ColorOutput "✓ Tests compiled successfully" $Green
        Write-ColorOutput "Note: Actual test execution requires Azure authentication and resources" $Yellow
    } catch {
        Write-ColorOutput "✗ Test execution failed: $_" $Red
        Pop-Location
        exit 1
    }

    Pop-Location
}

function Deploy-Example {
    param(
        [string]$ExampleName = "basic"
    )

    $examplePath = Join-Path $ExamplesPath $ExampleName

    if (!(Test-Path $examplePath)) {
        Write-ColorOutput "✗ Example '$ExampleName' not found" $Red
        return
    }

    Write-ColorOutput "Deploying example: $ExampleName" $Cyan

    Push-Location $examplePath

    try {
        Write-ColorOutput "Initializing Terraform..." $Yellow
        terraform init -backend=false

        Write-ColorOutput "Planning deployment..." $Yellow
        terraform plan -out=tfplan

        if (!$WhatIf) {
            $confirmation = Read-Host "Do you want to apply this plan? (y/N)"
            if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                Write-ColorOutput "Applying deployment..." $Yellow
                terraform apply tfplan

                Write-ColorOutput "✓ Example deployed successfully" $Green
            } else {
                Write-ColorOutput "Deployment cancelled by user" $Yellow
            }
        }
    } catch {
        Write-ColorOutput "✗ Deployment failed: $_" $Red
        Pop-Location
        exit 1
    }

    Pop-Location
}

function Remove-Resources {
    param(
        [string]$ExampleName = "basic"
    )

    $examplePath = Join-Path $ExamplesPath $ExampleName

    if (!(Test-Path $examplePath)) {
        Write-ColorOutput "✗ Example '$ExampleName' not found" $Red
        return
    }

    Write-ColorOutput "Cleaning up example: $ExampleName" $Cyan

    Push-Location $examplePath

    try {
        Write-ColorOutput "Planning destruction..." $Yellow
        terraform plan -destroy -out=tfplan-destroy

        $confirmation = Read-Host "Do you want to destroy these resources? (y/N)"
        if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
            Write-ColorOutput "Destroying resources..." $Yellow
            terraform apply tfplan-destroy

            Write-ColorOutput "✓ Resources destroyed successfully" $Green
        } else {
            Write-ColorOutput "Cleanup cancelled by user" $Yellow
        }
    } catch {
        Write-ColorOutput "✗ Cleanup failed: $_" $Red
    }

    Pop-Location
}

function Show-Usage {
    Write-ColorOutput @"
SQL Database Module Automation Script

USAGE:
    .\sql-database.ps1 [options]

ACTIONS:
    -Action <action>          Action to perform (deploy, test, validate, cleanup)
                              Default: deploy

OPTIONS:
    -Environment <env>        Environment name (test, dev, staging, prod)
                              Default: test
    -Location <location>      Azure region
                              Default: East US
    -ResourceGroupName <rg>   Resource group name (optional)
    -SQLServerName <server>   SQL Server name (optional)
    -SkipTests               Skip running tests
    -Cleanup                 Clean up resources after deployment

EXAMPLES:
    # Deploy basic example
    .\sql-database.ps1 -Action deploy

    # Run tests only
    .\sql-database.ps1 -Action test

    # Validate module
    .\sql-database.ps1 -Action validate

    # Deploy high availability example
    .\sql-database.ps1 -Action deploy -Example high-availability

    # Clean up resources
    .\sql-database.ps1 -Action cleanup

"@ -Color White
}

# Main execution
switch ($Action.ToLower()) {
    "deploy" {
        Test-Prerequisites
        Initialize-Module
        Invoke-Tests
        Deploy-Example -ExampleName "basic"
    }
    "test" {
        Test-Prerequisites
        Invoke-Tests
    }
    "validate" {
        Test-Prerequisites
        Initialize-Module
    }
    "cleanup" {
        Remove-Resources -ExampleName "basic"
    }
    "deploy-ha" {
        Test-Prerequisites
        Initialize-Module
        Invoke-Tests
        Deploy-Example -ExampleName "high-availability"
    }
    "cleanup-ha" {
        Remove-Resources -ExampleName "high-availability"
    }
    default {
        Write-ColorOutput "Unknown action: $Action" $Red
        Show-Usage
        exit 1
    }
}

Write-ColorOutput "Script execution completed." $Green