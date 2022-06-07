[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $RoleDefinitionName,

    [Parameter(Mandatory=$true)]
    [string]
    $Scope,

    [Parameter(Mandatory=$true)]
    [string]
    $ObjectId
)
$TimeStart = Get-Date
$TimeEnd = $timeStart.addminutes(1)
Write-Host "Start Time: $TimeStart"
write-host "End Time:   $TimeEnd"

Do {
    Write-Host "Checking RBAC $RoleDefinitionName Permissions"
    $TimeNow = Get-Date
    if ($TimeNow -ge $TimeEnd) {
        Write-host "Setting RBAC Permissions for $RoleDefinitionName has timed out."
        break
    } else {
        Write-Host "RBAC permissions not set, it's only $TimeNow"
    }
    Start-Sleep -Seconds 10
}
while (-not ($testRBAC = $(Get-AzRoleAssignment -RoleDefinitionName $RoleDefinitionName -Scope $Scope | Where-Object { $_.ObjectId -eq $ObjectId } | Measure-Object).Count -eq 1))
Write-Host "RBAC permissions $RoleDefinitionName set,"