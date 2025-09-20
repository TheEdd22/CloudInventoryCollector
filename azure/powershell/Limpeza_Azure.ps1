# ================================
# Script de Limpeza da Infraestrutura Azure
# Autor: Edgard
# Objetivo: Remover VMs, NICs, IPs, VNet, NSG e Storage Account
# ================================

# Autenticação
Connect-AzAccount

# Variáveis
$resourceGroup = "RG-LabCloud"
$vmWindowsName = "VM-Windows"
$vmLinuxName = "VM-Linux"
$nicWindowsName = "${vmWindowsName}-nic"
$nicLinuxName = "${vmLinuxName}-nic"
$pipWindowsName = "${vmWindowsName}-pip"
$pipLinuxName = "${vmLinuxName}-pip"
$vnetName = "VNET-LabCloud"
$nsgName = "NSG-LabCloud"

# Remover VMs
Write-Host "Removendo VMs..."
Remove-AzVM -Name $vmWindowsName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue
Remove-AzVM -Name $vmLinuxName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue

# Remover NICs
Write-Host "Removendo NICs..."
Remove-AzNetworkInterface -Name $nicWindowsName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue
Remove-AzNetworkInterface -Name $nicLinuxName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue

# Remover IPs Públicos
Write-Host "Removendo IPs públicos..."
Remove-AzPublicIpAddress -Name $pipWindowsName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue
Remove-AzPublicIpAddress -Name $pipLinuxName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue

# Remover VNet
Write-Host "Removendo VNet..."
Remove-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue

# Remover NSG
Write-Host "Removendo NSG..."
Remove-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue

# Remover Storage Account
Write-Host "Removendo Storage Account..."
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $resourceGroup
foreach ($sa in $storageAccounts) {
    Remove-AzStorageAccount -Name $sa.StorageAccountName -ResourceGroupName $resourceGroup -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ Limpeza concluída." -ForegroundColor Green
