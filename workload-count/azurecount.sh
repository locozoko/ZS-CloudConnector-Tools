#!/bin/bash
set -e

azurecount=$(az vm list --output tsv | wc -l)
azuretenant=$(az account show --query tenantId --output tsv)
azuresub=$(az account show --query id --output tsv)
current=$(date)
echo ""
echo "----------------------------------" | tee -a azurecount.log
echo "Timestamp: $current" | tee -a azurecount.log
echo "Azure Tenant: $azuretenant" | tee -a azurecount.log
echo "Azure Subscription: $azuresub" | tee -a azurecount.log
echo "Azure Virtual Machines: $azurecount" | xargs | tee -a azurecount.log
echo "----------------------------------" | tee -a azurecount.log
echo ""
