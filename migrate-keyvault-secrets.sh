#!/bin/bash

# Check for dependencies
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI not found and needs to be installed."
  exit 101
fi

current_subscription=$(az account list --query "[?isDefault].name" -o tsv)
# Set the names of the source and destination key vaults
read -p "What is the source key vault name? " source_kv_name
read -p "What is the destination key vault name? " destination_kv_name

check_source=$(az keyvault list --query "[?name == '$source_kv_name'].name" -o tsv)
check_destination=$(az keyvault list --query "[?name == '$destination_kv_name'].name" -o tsv)

# Check for valid key vaults in current subscription
if [ -z "$check_source" ] || [ -z "$check_destination" ]
then
  echo "Could not find either the source or destination key vaults. Check your key vault names and your current subscription and try again."
  echo "Source key vault set to: $source_kv_name"
  echo "Desintation key vault set to: $destination_kv_name"
  echo "Current Azure subscription: $current_subscription"
  exit 102
fi

read -p "You will now copy secrets from $source_kv_name to $destination_kv_name. Would you like to proceed? (type Y/y to confirm)" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
  # Get a list of secrets from the source key vault
  secrets=$(az keyvault secret list --vault-name "${source_kv_name}" --query "[].name" -o tsv)

  # Loop through each secret and copy it to the destination key vault
  for secret_name in $secrets; do
    echo "Copying secret ${secret_name}..."
    secret_value=$(az keyvault secret show --vault-name "${source_kv_name}" --name "${secret_name}" --query "value" -o tsv)
    az keyvault secret set --vault-name "${destination_kv_name}" --name "${secret_name}" --value $secret_value > /dev/null 2>&1
  done

  echo "Secret copy complete!"

else
  echo "Exiting script..."
  exit 100
fi
