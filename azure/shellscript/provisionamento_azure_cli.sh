#!/bin/bash

# ================================
# Script de Provisionamento Azure (CLI)
# Autor: Edgard
# Objetivo: Criar infraestrutura básica com VMs Windows e Linux
# ================================

# 1. Autenticação
echo "🔐 Autenticando no Azure..."
az login
subscriptionId="e4482ebd-f542-49d0-86ea-ec573eb36505"
az account set --subscription $subscriptionId
echo "✅ Assinatura definida: $subscriptionId"

# 2. Variáveis de Configuração
resourceGroup="RG-LabCloud"
location="eastus"
vnetName="VNET-LabCloud"
subnetName="Subnet-LabCloud"
nsgName="NSG-LabCloud"
storageAccountName="labcloudstorage$RANDOM"
vmWindowsName="VM-Windows"
vmLinuxName="VM-Linux"
adminUsername="edgardadmin"
adminPassword="SenhaForte123!"

# 3. Resource Group
echo "📦 Criando Resource Group..."
az group create --name $resourceGroup --location $location

# 4. NSG e Regras
echo "🛡️ Criando NSG e regras..."
az network nsg create --resource-group $resourceGroup --name $nsgName --location $location

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Allow-RDP   --protocol Tcp --direction Inbound --priority 1000 --source-address-prefix '*'   --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access Allow

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Allow-SSH   --protocol Tcp --direction Inbound --priority 1001 --source-address-prefix '*'   --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access Allow

# 5. VNet e Subnet
echo "🌐 Criando VNet e Subnet..."
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16   --subnet-name $subnetName --subnet-prefix 10.0.0.0/24 --location $location

az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName   --name $subnetName --network-security-group $nsgName

# 6. Storage Account
echo "💾 Criando Storage Account..."
az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location   --sku Standard_LRS --kind StorageV2

# 7. IPs Públicos e NICs
echo "🌐 Criando IPs públicos e NICs..."
az network public-ip create --name ${vmWindowsName}-pip --resource-group $resourceGroup --location $location --allocation-method Static
az network nic create --name ${vmWindowsName}-nic --resource-group $resourceGroup --location $location   --subnet $subnetName --vnet-name $vnetName --public-ip-address ${vmWindowsName}-pip

az network public-ip create --name ${vmLinuxName}-pip --resource-group $resourceGroup --location $location --allocation-method Static
az network nic create --name ${vmLinuxName}-nic --resource-group $resourceGroup --location $location   --subnet $subnetName --vnet-name $vnetName --public-ip-address ${vmLinuxName}-pip

# 8. Criação das VMs
echo "🖥️ Criando VM Windows..."
az vm create --resource-group $resourceGroup --name $vmWindowsName --location $location   --nics ${vmWindowsName}-nic --image Win2019Datacenter --admin-username $adminUsername --admin-password $adminPassword   --size Standard_B2s

echo "🐧 Criando VM Linux..."
az vm create --resource-group $resourceGroup --name $vmLinuxName --location $location   --nics ${vmLinuxName}-nic --image UbuntuLTS --admin-username $adminUsername --admin-password $adminPassword   --size Standard_B2s

# 9. Validação Final
echo "✅ Infraestrutura provisionada:"
az vm list -g $resourceGroup -o table
az network public-ip list -g $resourceGroup -o table
