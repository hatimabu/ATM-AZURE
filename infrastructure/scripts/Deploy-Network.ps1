# ATM Azure Network Infrastructure Deployment Script
# This script deploys the network infrastructure (VNet, subnets, NSGs) for the ATM Azure project

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$Location,

    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",

    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🌐 Starting ATM Network Infrastructure Deployment" -ForegroundColor Blue
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Check if Azure CLI is installed and user is logged in
try {
    $azAccount = az account show 2>$null | ConvertFrom-Json
    Write-Host "[SUCCESS] Azure CLI authenticated as: $($azAccount.user.name)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI not authenticated. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Verify resource group exists
Write-Host "[INFO] Checking resource group..." -ForegroundColor Blue
try {
    $rgExists = az group exists --name $ResourceGroupName
    if ($rgExists -eq "false") {
        Write-Host "[ERROR] Resource group '$ResourceGroupName' does not exist. Please create it first." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "[SUCCESS] Resource group '$ResourceGroupName' exists" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to check resource group: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get the directory of this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateDir = Join-Path $scriptDir "..\templates"
$templateFile = Join-Path $templateDir "network.json"
$parametersFile = Join-Path $templateDir "network.parameters.json"

# Check if template files exist
if (!(Test-Path $templateFile)) {
    Write-Host "[ERROR] Template file not found: $templateFile" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $parametersFile)) {
    Write-Host "[ERROR] Parameters file not found: $parametersFile" -ForegroundColor Red
    exit 1
}

Write-Host "[DEPLOY] Deploying network ARM template..." -ForegroundColor Blue

# Prepare deployment parameters
$deploymentParams = @{
    "environmentName" = $Environment
    "location" = $Location
}

# Convert parameters to JSON for az deployment
$deploymentParamsJson = $deploymentParams | ConvertTo-Json -Compress

# Deploy or validate the template
try {
    if ($ValidateOnly) {
        Write-Host "[VALIDATE] Validating network template..." -ForegroundColor Blue
        $validationResult = az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --parameters $parametersFile `
            --parameters $deploymentParamsJson

        Write-Host "[SUCCESS] Network template validation completed successfully!" -ForegroundColor Green
        Write-Host "Validation Result:" -ForegroundColor Cyan
        $validationResult | ConvertFrom-Json | ConvertTo-Json -Depth 10
    } else {
        $deploymentResult = az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --parameters $parametersFile `
            --parameters $deploymentParamsJson `
            --output json

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Network infrastructure deployment completed successfully!" -ForegroundColor Green

            # Parse and display outputs
            $outputs = ($deploymentResult | ConvertFrom-Json).properties.outputs

            Write-Host "`n[OUTPUT] Network Deployment Outputs:" -ForegroundColor Cyan
            Write-Host "Virtual Network: $($outputs.vnetName.value)" -ForegroundColor White
            Write-Host "Address Space: $($outputs.vnetAddressSpace.value)" -ForegroundColor White
            Write-Host "Frontend Subnet: $($outputs.frontendSubnetName.value) ($($outputs.frontendSubnetPrefix.value))" -ForegroundColor White
            Write-Host "Backend Subnet: $($outputs.backendSubnetName.value) ($($outputs.backendSubnetPrefix.value))" -ForegroundColor White
            Write-Host "Frontend NSG: $($outputs.frontendNsgName.value)" -ForegroundColor White
            Write-Host "Backend NSG: $($outputs.backendNsgName.value)" -ForegroundColor White

            # Save deployment outputs
            $outputFile = Join-Path $scriptDir "network-deployment-outputs-$Environment.json"
            $outputs | ConvertTo-Json -Depth 10 | Out-File $outputFile
            Write-Host "`n[SAVE] Network deployment outputs saved to: $outputFile" -ForegroundColor Yellow

            # Verify deployment
            Write-Host "`n[VERIFY] Verifying network resources..." -ForegroundColor Blue

            $vnetName = $outputs.vnetName.value
            $frontendNsg = $outputs.frontendNsgName.value
            $backendNsg = $outputs.backendNsgName.value

            # Check VNet
            Write-Host "Checking Virtual Network: $vnetName" -ForegroundColor Blue
            az network vnet show --resource-group $ResourceGroupName --name $vnetName --query "{name:name, location:location, addressSpace:addressSpace.addressPrefixes}" --output table

            # Check subnets
            Write-Host "Checking subnets:" -ForegroundColor Blue
            az network vnet subnet list --resource-group $ResourceGroupName --vnet-name $vnetName --query "[].{name:name, prefix:addressPrefix, nsg:networkSecurityGroup.id}" --output table

            # Check NSGs
            Write-Host "Checking Frontend NSG: $frontendNsg" -ForegroundColor Blue
            az network nsg show --resource-group $ResourceGroupName --name $frontendNsg --query "{name:name, location:location, rulesCount:length(securityRules)}" --output table

            Write-Host "Checking Backend NSG: $backendNsg" -ForegroundColor Blue
            az network nsg show --resource-group $ResourceGroupName --name $backendNsg --query "{name:name, location:location, rulesCount:length(securityRules)}" --output table

            Write-Host "`n[SUCCESS] Network infrastructure deployment and verification completed!" -ForegroundColor Green
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "1. Deploy Azure Key Vault for secrets management" -ForegroundColor White
            Write-Host "2. Deploy Azure SQL Database" -ForegroundColor White
            Write-Host "3. Deploy App Service Plan and Web Apps" -ForegroundColor White
            Write-Host "4. Configure monitoring and logging" -ForegroundColor White

        } else {
            Write-Host "[ERROR] Network template deployment failed" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "[ERROR] Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
