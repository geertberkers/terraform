# Azure VM Deployment — Terraform Module

Deploys **2 Linux virtual machines** in an Azure region, each with its own Network Interface Card (NIC) and static public IP. Designed to be reused as a module per region (e.g. Sweden Central, Switzerland North).

---

## Infrastructure Overview

```
Resource Group
└── Virtual Network (10.0.0.0/16)
    └── Subnet (10.0.1.0/24)
        ├── Public IP [0]  ──►  NIC [0]  ──►  VM [0]
        └── Public IP [1]  ──►  NIC [1]  ──►  VM [1]
```

Each VM runs **Ubuntu Server 22.04 LTS** and is accessible via SSH using a provided public key.

---

## Resources Created

| Resource | Count | Notes |
|---|---|---|
| `azurerm_resource_group` | 1 | Per region |
| `azurerm_virtual_network` | 1 | CIDR `10.0.0.0/16` |
| `azurerm_subnet` | 1 | CIDR `10.0.1.0/24` |
| `azurerm_public_ip` | 2 | Static, Standard SKU |
| `azurerm_network_interface` | 2 | One per VM, dynamic private IP |
| `azurerm_linux_virtual_machine` | 2 | Ubuntu 22.04 LTS, SSH auth |

> **Note:** Public IPs have `prevent_destroy = true` to protect against accidental deletion.

---

## Variables

| Name | Required | Default | Description |
|---|---|---|---|
| `resource_group_name` | ✅ | — | Name of the Azure resource group |
| `location` | ✅ | — | Azure region (e.g. `swedencentral`) |
| `prefix` | ✅ | — | Short name prefix for all resources (e.g. `se`, `ch`) |
| `vm_sizes` | ✅ | — | List of 2 VM sizes, one per VM |
| `ssh_public_key` | ✅ | — | SSH public key for `azureuser` login |
| `vnet_cidr` | ❌ | `10.0.0.0/16` | Address space for the virtual network |
| `subnet_cidr` | ❌ | `10.0.1.0/24` | Address prefix for the subnet |

---

## Outputs

| Name | Description |
|---|---|
| `public_ips` | List of the two static public IP addresses |

---

## Usage

```hcl
module "sweden" {
  source              = "./modules/vm-pair"
  resource_group_name = "rg-sweden-central"
  location            = "swedencentral"
  prefix              = "se"
  vm_sizes            = ["Standard_B2s", "Standard_B2s"]
  ssh_public_key      = var.ssh_public_key
}

module "switzerland" {
  source              = "./modules/vm-pair"
  resource_group_name = "rg-switzerland-north"
  location            = "switzerlandnorth"
  prefix              = "ch"
  vm_sizes            = ["Standard_B2s", "Standard_B2s"]
  ssh_public_key      = var.ssh_public_key
}
```

Then apply:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## `synch.sh` — Import Existing NICs into Terraform State

If the NICs already exist in Azure (e.g. created manually or outside of Terraform), `synch.sh` imports them into the Terraform state so Terraform can manage them going forward.

It targets both the Sweden Central and Switzerland North deployments:

```
Sweden Central:    nic-se-0, nic-se-1
Switzerland North: nic-ch-0, nic-ch-1
```

Run it once to sync remote state before applying changes:

```bash
chmod +x synch.sh
./synch.sh
```

> **When to use this:** Run `synch.sh` when resources were created outside of Terraform and you need to bring them under Terraform management without recreating them. You do **not** need to run it on a fresh deployment.

---

## CI/CD — GitHub Actions

The workflow at `.github/workflows/terraform.yml` runs automatically when `.tf` files are changed.

### Branch strategy

| Event | What happens |
|---|---|
| Push to `main` | Validate → Plan → **Apply** (real deployment) |
| Pull Request | Validate → Plan only (no deploy, plan posted as PR comment) |

This means you can open a PR to preview exactly what Terraform will change before it touches real infrastructure. Only merging to `main` triggers an actual deployment.

### Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** in your repo and add:

| Secret | How to get it |
|---|---|
| `ARM_CLIENT_ID` | Azure Service Principal App ID |
| `ARM_CLIENT_SECRET` | Azure Service Principal password |
| `ARM_SUBSCRIPTION_ID` | Your Azure Subscription ID |
| `ARM_TENANT_ID` | Your Azure Active Directory Tenant ID |
| `SSH_PUBLIC_KEY` | Contents of your `id_rsa.pub` (or equivalent) |

To create a Service Principal with the right permissions:

```bash
az ad sp create-for-rbac \
  --name "github-terraform" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id>
```

This outputs the `appId` (CLIENT_ID), `password` (CLIENT_SECRET), and `tenant` (TENANT_ID) you need.

### Production environment gate (optional but recommended)

The `deploy` job targets a GitHub Environment called `production`. In **Settings → Environments → production** you can add required reviewers, so every deploy to `main` needs a manual approval before Terraform applies. Useful for catching anything the plan might have missed.

---

## SSH Access

```bash
ssh azureuser@<public_ip>
```

Public IPs are printed after `terraform apply` via the `public_ips` output, or retrieved anytime with:

```bash
terraform output public_ips
```