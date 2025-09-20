
# ================================
# Script de Provisionamento Azure
# Autor: Edgard
# Objetivo: Criar infraestrutura básica com VMs Windows e Linux
# ================================

# 1. Autenticação
Connect-AzAccount

# 2. Validação da Assinatura
$subscriptionId = "e4482ebd-f542-49d0-86ea-ec573eb36505"
$subscription = Get-AzSubscription -SubscriptionId $subscriptionId

if (-not $subscription) {
    Write-Host "❌ Assinatura não encontrada. Verifique o ID." -ForegroundColor Red
    exit
}
Set-AzContext -SubscriptionId $subscriptionId
Write-Host "✅ Assinatura validada: $($subscription.Name)" -ForegroundColor Green

# 3. Variáveis de Configuração
$resourceGroup = "RG-LabCloud"
$location = "eastus"
$vnetName = "VNET-LabCloud"
$subnetName = "Subnet-LabCloud"
$nsgName = "NSG-LabCloud"
$storageAccountName = "labcloudstorage$(Get-Random)"
$vmWindowsName = "VM-Windows"
$vmLinuxName = "VM-Linux"
$adminUsername = "edgardadmin"
$adminPassword = ConvertTo-SecureString "SenhaForte123!" -AsPlainText -Force

# 4. Criação do Resource Group
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
    Write-Host "✅ Resource Group criado: $resourceGroup" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Resource Group já existe: $resourceGroup" -ForegroundColor Yellow
}

# 5. NSG com regras básicas
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Protocol "Tcp" -Direction "Inbound" -Priority 1000 `
    -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 3389 -Access "Allow"

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" -Protocol "Tcp" -Direction "Inbound" -Priority 1001 `
    -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 22 -Access "Allow"

if (-not (Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue)) {
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName -SecurityRules $nsgRuleRDP, $nsgRuleSSH
    Write-Host "✅ NSG criado: $nsgName" -ForegroundColor Green
} else {
    Write-Host "ℹ️ NSG já existe: $nsgName" -ForegroundColor Yellow
    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup
}

# 6. Recupera ou cria VNet e Sub-rede
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
if (-not $vnet) {
    $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"
    $vnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet -NetworkSecurityGroup $nsg
    $vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
    Write-Host "✅ VNet e Sub-rede criadas" -ForegroundColor Green
} else {
    Write-Host "ℹ️ VNet já existe: $vnetName" -ForegroundColor Yellow
}

# 7. Conta de Armazenamento
if (-not (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -ErrorAction SilentlyContinue)) {
    New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -Location $location -SkuName "Standard_LRS" -Kind "StorageV2"
    Write-Host "✅ Storage Account criada: $storageAccountName" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Storage Account já existe: $storageAccountName" -ForegroundColor Yellow
}

# 8. IPs Públicos e NICs
$pipWin = New-AzPublicIpAddress -Name "${vmWindowsName}-pip" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
$nicWin = New-AzNetworkInterface -Name "${vmWindowsName}-nic" -ResourceGroupName $resourceGroup -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pipWin.Id

$pipLinux = New-AzPublicIpAddress -Name "${vmLinuxName}-pip" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
$nicLinux = New-AzNetworkInterface -Name "${vmLinuxName}-nic" -ResourceGroupName $resourceGroup -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pipLinux.Id

Write-Host "✅ NICs e IPs públicos criados" -ForegroundColor Green

# 9. Criação das VMs
# Verifica se VM já existe
if (-not (Get-AzVM -ResourceGroupName $resourceGroup -Name $vmWindowsName -ErrorAction SilentlyContinue)) {
    $vmConfigWin = New-AzVMConfig -VMName $vmWindowsName -VMSize "Standard_B2s" |
        Set-AzVMOperatingSystem -Windows -ComputerName $vmWindowsName -Credential (New-Object PSCredential($adminUsername, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
        Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" |
        Add-AzVMNetworkInterface -Id $nicWin.Id

    New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfigWin
    Write-Host "✅ VM Windows criada: $vmWindowsName" -ForegroundColor Green
} else {
    Write-Host "⚠️ VM Windows já existe: $vmWindowsName" -ForegroundColor Yellow
}

if (-not (Get-AzVM -ResourceGroupName $resourceGroup -Name $vmLinuxName -ErrorAction SilentlyContinue)) {
    $vmConfigLinux = New-AzVMConfig -VMName $vmLinuxName -VMSize "Standard_B2s" |
        Set-AzVMOperatingSystem -Linux -ComputerName $vmLinuxName -Credential (New-Object PSCredential($adminUsername, $adminPassword)) |
        Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts" -Version "latest" |
        Add-AzVMNetworkInterface -Id $nicLinux.Id

    New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfigLinux
    Write-Host "✅ VM Linux criada: $vmLinuxName" -ForegroundColor Green
} else {
    Write-Host "⚠️ VM Linux já existe: $vmLinuxName" -ForegroundColor Yellow
}

# 10. Validação Final
Write-Host "`n📦 Recursos provisionados:"
Get-AzVM -ResourceGroupName $resourceGroup
Get-AzPublicIpAddress -ResourceGroupName $resourceGroup
