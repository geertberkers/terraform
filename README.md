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

## SSH Access

```bash
ssh azureuser@<public_ip>
```

Public IPs are printed after `terraform apply` via the `public_ips` output, or retrieved anytime with:

```bash
terraform output public_ips
```