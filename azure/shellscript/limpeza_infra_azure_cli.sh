#!/bin/bash

# ================================
# Script de Limpeza da Infraestrutura Azure
# Autor: Edgard
# Objetivo: Remover VMs, NICs, IPs, VNet, NSG e Storage Account
# ================================

# Autenticação
echo "🔐 Autenticando no Azure..."
az login

# Variáveis
resourceGroup="RG-LabCloud"
vmWindowsName="VM-Windows"
vmLinuxName="VM-Linux"
nicWindowsName="${vmWindowsName}-nic"
nicLinuxName="${vmLinuxName}-nic"
pipWindowsName="${vmWindowsName}-pip"
pipLinuxName="${vmLinuxName}-pip"
vnetName="VNET-LabCloud"
nsgName="NSG-LabCloud"

# Remover VMs
echo "🧹 Removendo VMs..."
az vm delete --name "$vmWindowsName" --resource-group "$resourceGroup" --yes --no-wait
az vm delete --name "$vmLinuxName" --resource-group "$resourceGroup" --yes --no-wait

# Remover NICs
echo "🧹 Removendo NICs..."
az network nic delete --name "$nicWindowsName" --resource-group "$resourceGroup"
az network nic delete --name "$nicLinuxName" --resource-group "$resourceGroup"

# Remover IPs Públicos
echo "🧹 Removendo IPs públicos..."
az network public-ip delete --name "$pipWindowsName" --resource-group "$resourceGroup"
az network public-ip delete --name "$pipLinuxName" --resource-group "$resourceGroup"

# Remover VNet
echo "🧹 Removendo VNet..."
az network vnet delete --name "$vnetName" --resource-group "$resourceGroup"

# Remover NSG
echo "🧹 Removendo NSG..."
az network nsg delete --name "$nsgName" --resource-group "$resourceGroup"

# Remover Storage Accounts
echo "🧹 Removendo Storage Accounts..."
storageAccounts=$(az storage account list --resource-group "$resourceGroup" --query "[].name" -o tsv)
for sa in $storageAccounts; do
    az storage account delete --name "$sa" --resource-group "$resourceGroup" --yes
done

echo "✅ Limpeza concluída."
