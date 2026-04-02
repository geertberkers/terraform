#!/bin/bash

set -e

echo "=== Azure GitHub Actions Setup ==="
echo ""

# Check az cli is installed
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI not found. Install it from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check logged in
if ! az account show &> /dev/null; then
  echo "Not logged in. Running az login..."
  az login
fi

# Get tenant and subscription
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)
SUB_NAME=$(az account show --query name -o tsv)

echo "Subscription : $SUB_NAME"
echo "Subscription ID : $SUB_ID"
echo "Tenant ID       : $TENANT_ID"
echo ""

# Create the service principal
echo "Creating service principal 'github-terraform'..."
SP_JSON=$(az ad sp create-for-rbac \
  --name "github-terraform" \
  --role Contributor \
  --scopes "/subscriptions/$SUB_ID" \
  --output json)

CLIENT_ID=$(echo "$SP_JSON" | grep -o '"appId": *"[^"]*"' | cut -d'"' -f4)
CLIENT_SECRET=$(echo "$SP_JSON" | grep -o '"password": *"[^"]*"' | cut -d'"' -f4)

echo ""
echo "================================================"
echo "  Add these as GitHub Actions secrets:"
echo "================================================"
echo ""
echo "  ARM_SUBSCRIPTION_ID  =  $SUB_ID"
echo "  ARM_TENANT_ID        =  $TENANT_ID"
echo "  ARM_CLIENT_ID        =  $CLIENT_ID"
echo "  ARM_CLIENT_SECRET    =  $CLIENT_SECRET"
echo ""
echo "================================================"
echo "  CLIENT_SECRET is only shown once!"
echo "  Copy it now before closing this terminal."
echo "================================================"
