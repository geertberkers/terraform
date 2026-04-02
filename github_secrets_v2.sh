#!/bin/bash

set -e

echo "=== Azure GitHub Actions Setup ==="
echo ""

# ── Args ───────────────────────────────────────────────────────────────────────
# Usage: ./setup_github_secrets.sh <github-repo>
# Example: ./setup_github_secrets.sh myorg/my-repo
GITHUB_REPO="${1:-}"
SP_NAME="github-terraform"

# ── Checks ─────────────────────────────────────────────────────────────────────
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI not found."
  echo "       Install: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "ERROR: GitHub CLI not found."
  echo "       Install: https://cli.github.com"
  exit 1
fi

# ── Azure login ────────────────────────────────────────────────────────────────
if ! az account show &> /dev/null; then
  echo "Not logged in to Azure. Running az login..."
  az login
fi

# ── GitHub login ───────────────────────────────────────────────────────────────
if ! gh auth status &> /dev/null; then
  echo "Not logged in to GitHub. Running gh auth login..."
  gh auth login
fi

# ── Resolve repo ───────────────────────────────────────────────────────────────
if [ -z "$GITHUB_REPO" ]; then
  GITHUB_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
  if [ -z "$GITHUB_REPO" ]; then
    echo ""
    read -rp "Enter your GitHub repo (e.g. myorg/my-repo): " GITHUB_REPO
  else
    echo "Detected repo: $GITHUB_REPO"
  fi
fi

# ── Azure IDs ─────────────────────────────────────────────────────────────────
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)
SUB_NAME=$(az account show --query name -o tsv)

echo ""
echo "Subscription : $SUB_NAME"
echo "Subscription ID : $SUB_ID"
echo "Tenant ID       : $TENANT_ID"
echo ""

# ── Service Principal ─────────────────────────────────────────────────────────
EXISTING_APP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)

if [ -n "$EXISTING_APP_ID" ] && [ "$EXISTING_APP_ID" != "None" ]; then
  echo "Service principal '$SP_NAME' already exists (appId: $EXISTING_APP_ID)."
  echo "Options:"
  echo "  1) Reset its credentials (generates a new secret)"
  echo "  2) Abort and use existing credentials manually"
  echo ""
  read -rp "Choose [1/2]: " CHOICE

  case "$CHOICE" in
    1)
      echo "Resetting credentials for '$SP_NAME'..."
      SP_JSON=$(az ad sp credential reset --id "$EXISTING_APP_ID" --output json)
      CLIENT_ID=$(echo "$SP_JSON" | grep -o '"appId": *"[^"]*"' | cut -d'"' -f4)
      CLIENT_SECRET=$(echo "$SP_JSON" | grep -o '"password": *"[^"]*"' | cut -d'"' -f4)
      echo "Credentials reset."
      ;;
    2)
      echo ""
      echo "Aborted. Re-run the script after removing the SP, or reset credentials manually:"
      echo "  az ad sp credential reset --id $EXISTING_APP_ID"
      exit 0
      ;;
    *)
      echo "Invalid choice. Aborting."
      exit 1
      ;;
  esac
else
  echo "Creating service principal '$SP_NAME'..."
  SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role Contributor \
    --scopes "/subscriptions/$SUB_ID" \
    --output json)

  CLIENT_ID=$(echo "$SP_JSON" | grep -o '"appId": *"[^"]*"' | cut -d'"' -f4)
  CLIENT_SECRET=$(echo "$SP_JSON" | grep -o '"password": *"[^"]*"' | cut -d'"' -f4)
  echo "Service principal created."
fi

# ── Push secrets to GitHub ────────────────────────────────────────────────────
echo ""
echo "Pushing secrets to $GITHUB_REPO..."

gh secret set ARM_SUBSCRIPTION_ID --body "$SUB_ID"        --repo "$GITHUB_REPO"
gh secret set ARM_TENANT_ID       --body "$TENANT_ID"     --repo "$GITHUB_REPO"
gh secret set ARM_CLIENT_ID       --body "$CLIENT_ID"     --repo "$GITHUB_REPO"
gh secret set ARM_CLIENT_SECRET   --body "$CLIENT_SECRET" --repo "$GITHUB_REPO"

echo ""
echo "================================================"
echo "  All 4 secrets set on $GITHUB_REPO"
echo "================================================"
echo ""
echo "  Don't forget to also add SSH_PUBLIC_KEY:"
echo ""
echo "  gh secret set SSH_PUBLIC_KEY --body \"\$(cat ~/.ssh/id_rsa.pub)\" --repo $GITHUB_REPO"
echo ""
