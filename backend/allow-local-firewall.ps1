# Run in an administrator PowerShell. Allows only the local subnet.
#Requires -RunAsAdministrator
param([string]$BindAddress = '192.168.123.34')
$ErrorActionPreference = 'Stop'
$ruleName = 'StopScam-Local-Backend'
if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
    Write-Host 'StopScam firewall rule already exists. No changes made.'
} else {
    New-NetFirewallRule -Name $ruleName -DisplayName 'StopScam local backend' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -LocalAddress $BindAddress -RemoteAddress LocalSubnet | Out-Null
    Write-Host "Allowed local-subnet connections to ${BindAddress}:8000."
}
