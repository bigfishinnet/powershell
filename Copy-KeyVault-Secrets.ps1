<#PSScriptInfo
.VERSION 1.1
.GUName 48b4b27a-b77e-41e6-8a37-b3767da5caee
.AUTHOR Nicholas Rogoff

.RELEASENOTES
Initial version.
#>
<# 
.SYNOPSIS 
Copy Key Vault Secrets from one Vault to another. 
 
.DESCRIPTION 
Loops through all secrets and copies them or fills them with a 'Needs Configuration'.

PRE-REQUIREMENT
---------------
Run 'Import-Module Az.Accounts'
Run 'Import-Module Az.KeyVault'
You need to be logged into Azure and have the access necessary rights to both Key Vaults.

.INPUTS
None. You cannot pipe objects to this!

.OUTPUTS
None.

.PARAMETER SrcSubscriptionName
This is the Source Subscription Name

.PARAMETER SrcKvName
The name of the Source Key Vault

.PARAMETER DestSubscriptionName
This is the destination Subscription Name

.PARAMETER DestKvName
The name of the destination Key Vault

.PARAMETER NameOnly
Set to only copy across the secret name and NOT the actual secret. The secret will be populated with 'Needs Configuration'

.NOTES
  Version:        1.1
  Author:         Nicholas Rogoff
  Creation Date:  2021-08-09
  Purpose/Change: Refined for publication
   
.EXAMPLE 
PS> .\Copy-KeyVault-Secrets.ps1 -SrcSubscriptionName $srcSubscriptionName -SrcKvName $srcKvName -DestSubscriptionName $destSubscriptionName -DestKvName $destKvName -NameOnly
This will copy across only the secret names, filling the secret with 'Needs Configuration'
#>
#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true, HelpMessage = "This is the Source Subscription Name")]
  [string] $SrcSubscriptionName,
  [Parameter(Mandatory = $true, HelpMessage = "The name of the Source Key Vault")]
  [string] $SrcKvName,
  [Parameter(Mandatory = $false, HelpMessage = "This is the destination Subscription Name. If not set or blank then same subscription is assumed")]
  [string] $DestSubscriptionName,
  [Parameter(Mandatory = $true, HelpMessage = "The name of the destination Key Vault")]
  [string] $DestKvName,
  [Parameter(Mandatory = $false, HelpMessage = "Only copy across the secret name and NOT the actual secret. The secret will be populated with 'Needs Configuration'")]
  [switch] $NameOnly
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
Write-Host ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') + " Starting copying from " + $SrcKvName + " to " + $DestKvName + "... ") -ForegroundColor Blue

# Set Error Action to Silently Continue
$ErrorActionPreference = 'Continue'

#----------------------------------------------------------[Declarations]----------------------------------------------------------
# Any Global Declarations go here

#----------------------------------------------------------[Functions]----------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

$success = 0
$failed = 0

# ensure source subscription is selected
Select-AzSubscription -Subscription $SrcSubscriptionName

$Tags = @{ 'Migrated' = 'true'; 'Source Key Vault' = $SrcKvName }

$sourceSecrets = Get-AzKeyVaultSecret -VaultName $SrcKvName
if ($DestSubscriptionName) {
  #Need to switch subscriptions
  Select-AzSubscription -Subscription $DestSubscriptionName
}

ForEach ($sourceSecret in $sourceSecrets) {
  $Error.clear()

  $name = $sourceSecret.Name
  $tags = $sourceSecret.Tags
  $secret = Get-AzKeyVaultSecret -VaultName $srckvName -Name $name


  Write-Host "Adding SecretName: $name ..."
  if ($NameOnly) {
    $value = ConvertTo-SecureString 'Needs Configuration' -AsPlainText -Force
  }
  else {
    $value = $secret.SecretValue
  }
  $secret = Set-AzKeyVaultSecret -VaultName $destkvName -Name $sourceSecret.Name -SecretValue $value -ContentType $sourceSecret.ContentType -Tags $tags 
  
  if (!$Error[0]) {
    $success += 1
  }
  else {
    $failed += 1
    Write-Error "!! Failed to copy secret $name"
  }
}

Write-Output "================================="
Write-Output "Completed Key Vault Secrets Copy"
Write-Output "Succeeded: $success"
Write-Output "Failed: $failed"
Write-Output "================================="