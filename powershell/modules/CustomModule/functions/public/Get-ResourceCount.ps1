<#
.SYNOPSIS
    Retrieves and counts resources in a specified Azure resource group using a user-assigned managed identity.

.DESCRIPTION
    This function connects to Azure using a user-assigned managed identity and retrieves the number of resources within a specified resource group. It requires the Azure Az module to be installed and the managed identity to have appropriate permissions to access the resources in the specified resource group.

.PARAMETER ResourceGroupName
    The name of the Azure resource group from which to retrieve the resources.

.PARAMETER ManagedIdentityClientId
    The client ID of the user-assigned managed identity used for authentication.

.EXAMPLE
    Get-ResourceCount -ResourceGroupName "MyResourceGroup" -ManagedIdentityClientId "12345678-abcd-1234-efgh-1234567890ab"

    This example retrieves and outputs the number of resources in the resource group named "MyResourceGroup" using the specified managed identity. 
#>
function Get-ResourceCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$ManagedIdentityClientId
    )

    # Ensure the Az module is imported
    if (-not (Get-Module -ListAvailable -Name Az)) {
        Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Az

    # Connect to Azure using the managed identity
    Connect-AzAccount -Identity -AccountId $ManagedIdentityClientId

    # Retrieve resources in the specified resource group
    try {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        if ($resources.Count -eq 0) {
            Write-Output "No resources found in the resource group '$ResourceGroupName'."
        }
        else {
            Write-Output "There are $($resources.Count) resources in the resource group '$ResourceGroupName'."
        }
    }
    catch {
        Write-Error "Failed to retrieve resources. Error: $_"
    }
}
