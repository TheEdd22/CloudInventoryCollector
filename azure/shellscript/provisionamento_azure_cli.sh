#!/bin/bash

# ================================
# Script de Provisionamento Azure (CLI) - Versão Final
# Autor: Edgard (com apoio do Copilot)
# Objetivo: Criar infraestrutura básica com Linux (Ubuntu2204)
# ================================

# Função para executar comandos com validação
run_command() {
    local cmd="$1"
    local msg="$2"
    echo "🔧 $msg..."
    eval "$cmd"
    if [ $? -eq 0 ]; then
        echo "✅ $msg concluído."
    else
        echo "❌ Erro ao executar: $msg"
        exit 1
    fi
}

# 1. Autenticação
echo "🔐 Autenticando no Azure..."
az login
subscriptionId="e4482ebd-f542-49d0-86ea-ec573eb36505"
az account set --subscription $subscriptionId
echo "✅ Assinatura definida: $subscriptionId"

# 2. Variáveis de Configuração
resourceGroup="RG-LabCloud" #Cria o grupo de recursos
location="eastus"
vnetName="VNET-LabCloud"
subnetName="Subnet-LabCloud"
nsgName="NSG-LabCloud"
storageAccountName="labcloudstorage$RANDOM"
vmLinuxName="VM-Linux"
adminUsername="edgardadmin"
adminPassword="${VM_ADMIN_PASSWORD}" # Defina como variável de ambiente ou use Key Vault

# 3. Resource Group
run_command "az group create --name $resourceGroup --location $location" "Criando Resource Group"

# 4. NSG e Regras
run_command "az network nsg create --resource-group $resourceGroup --name $nsgName --location $location" "Criando NSG"
run_command "az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Allow-RDP --protocol Tcp --direction Inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access Allow" "Criando regra RDP"
run_command "az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Allow-SSH --protocol Tcp --direction Inbound --priority 1001 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access Allow" "Criando regra SSH"
run_command "az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Allow-SQL --protocol Tcp --direction Inbound --priority 1002 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 1433 --access Allow" "Criando regra SQL Server"

# 5. VNet e Subnet
run_command "az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 --subnet-name $subnetName --subnet-prefix 10.0.0.0/24 --location $location" "Criando VNet e Subnet"

run_command "az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetName --network-security-group $nsgName" "Associando NSG à Subnet"

# 6. Storage Account
run_command "az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location --sku Standard_LRS --kind StorageV2" "Criando Storage Account"

# 7. IPs Públicos e NICs
run_command "az network public-ip create --name ${vmLinuxName}-pip --resource-group $resourceGroup --location $location --allocation-method Static" "Criando IP público para VM Linux"
run_command "az network nic create --name ${vmLinuxName}-nic --resource-group $resourceGroup --location $location --subnet $subnetName --vnet-name $vnetName --public-ip-address ${vmLinuxName}-pip" "Criando NIC para VM Linux"

# 8. Criação das VMs
run_command "az vm create --resource-group $resourceGroup --name $vmLinuxName --location $location --nics ${vmLinuxName}-nic --image Ubuntu2204 --admin-username $adminUsername --admin-password $adminPassword --size Standard_B2s" "Criando VM Linux"

# 9. Validação Final
echo "📋 Infraestrutura provisionada:"
az vm list -g $resourceGroup -o table
az network public-ip list -g $resourceGroup -o table
