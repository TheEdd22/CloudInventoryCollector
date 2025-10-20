#!/bin/bash

# ================================
# Script de Limpeza da Infraestrutura Azure - Versão Aprimorada
# Autor: Edgard (com apoio do Copilot)
# ================================

# Autenticação
echo "🔐 Autenticando no Azure..."
az login

# Variáveis
resourceGroup="RG-LabCloud"
vmLinuxName="VM-Linux"
nicLinuxName="${vmLinuxName}-nic"
pipLinuxName="${vmLinuxName}-pip"
vnetName="VNET-LabCloud"
subnetName="Subnet-LabCloud"
nsgName="NSG-LabCloud"
storagePrefix="labcloudstorage"


# Função para verificar existência
resource_exists() {
    az resource show --name "$1" --resource-group "$resourceGroup" --resource-type "$2" &> /dev/null
}

# Desassociar IPs das NICs
echo "🔄 Desassociando IPs públicos das NICs..."
for nic in "$nicLinuxName"; do
    az network nic ip-config update \
        --name ipconfig1 \
        --nic-name "$nic" \
        --resource-group "$resourceGroup" \
        --remove publicIpAddress
    echo "✅ IP desassociado da NIC $nic."
done

# Remover VMs
echo "🧹 Removendo VMs..."
for vm in "$vmWindowsName" "$vmLinuxName"; do
    if az vm show --name "$vm" --resource-group "$resourceGroup" &> /dev/null; then
        az vm delete --name "$vm" --resource-group "$resourceGroup" --yes --no-wait
        echo "✅ VM $vm removida."
    else
        echo "⚠️ VM $vm não encontrada."
    fi
done
# Aguardar liberação de recursos
echo "⏳ Aguardando liberação de recursos..."
sleep 30

# Remover Discos
echo "🧹 Removendo discos..."
for disk in $(az disk list --resource-group "$resourceGroup" --query "[].name" -o tsv); do
    az disk delete --name "$disk" --resource-group "$resourceGroup" --yes
    echo "✅ Disco $disk removido."
done
# Remover IPs Públicos
echo "🧹 Removendo IPs públicos..."
for pip in "$pipLinuxName"; do
    if az network public-ip show --name "$pip" --resource-group "$resourceGroup" &> /dev/null; then
        az network public-ip delete --name "$pip" --resource-group "$resourceGroup"
        echo "✅ IP público $pip removido."
    else
        echo "⚠️ IP público $pip não encontrado."
    fi
done

# Remover NICs
echo "🧹 Removendo NICs..."
for nic in "$nicLinuxName"; do
    if az network nic show --name "$nic" --resource-group "$resourceGroup" &> /dev/null; then
        az network nic delete --name "$nic" --resource-group "$resourceGroup"
        echo "✅ NIC $nic removida."
    else
        echo "⚠️ NIC $nic não encontrada."
    fi
done

# Desassociar NSG da Subnet
echo "🔄 Desassociando NSG da Subnet..."
az network vnet subnet update \
    --name "$subnetName" \
    --vnet-name "$vnetName" \
    --resource-group "$resourceGroup" \
    --remove networkSecurityGroup
echo "✅ NSG desassociado da Subnet."

# Remover Subnet
echo "🧹 Removendo Subnet..."
az network vnet subnet delete --name "$subnetName" --vnet-name "$vnetName" --resource-group "$resourceGroup"
echo "✅ Subnet $subnetName removida."

# Remover NSG
echo "🧹 Removendo NSG..."
az network nsg delete --name "$nsgName" --resource-group "$resourceGroup"
echo "✅ NSG $nsgName removido."

# Remover VNet
echo "🧹 Removendo VNet..."
az network vnet delete --name "$vnetName" --resource-group "$resourceGroup"
echo "✅ VNet $vnetName removida."

# Remover Storage Accounts
echo "🧹 Removendo Storage Accounts..."
for sa in $(az storage account list --resource-group "$resourceGroup" --query "[?starts_with(name, '$storagePrefix')].name" -o tsv); do
    az storage account delete --name "$sa" --resource-group "$resourceGroup" --yes
    echo "✅ Storage Account $sa removida."
done

# Remover Resource Group
echo "🧹 Removendo Resource Group..."
az group delete --name "$resourceGroup" --yes --no-wait
echo "✅ Resource Group $resourceGroup removido."

echo "🏁 Limpeza concluída com sucesso."
