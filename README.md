# Azure Infrastructure — Terraform Module (VMs + Databases)

## 📁 Documentation & Walkthroughs
- [Database & Security Fixes](file:///c:/Users/geert/Projects/GITHUB/geertberkers/terraform/readme/WALKTHROUGH-DATABASE-FIXES.md) — Steps taken to fix database connections and implement Key Vault.

This repository contains a reusable Terraform setup for deploying:

- 2 Linux Virtual Machines (per region)
- Azure networking (VNet, Subnet, NICs, Public IPs)
- Managed Azure databases (PostgreSQL, MySQL, Azure SQL, Cosmos DB)
- CI/CD pipeline using GitHub Actions

It is designed to be modular and reusable across multiple Azure regions (e.g. Sweden Central, Switzerland North).

---

# 🧱 Infrastructure Overview

```
Resource Group
└── Virtual Network (10.0.0.0/16)
    └── Subnet (10.0.1.0/24)
        ├── Public IP [0]  ──► NIC [0] ──► VM [0]
        ├── Public IP [1]  ──► NIC [1] ──► VM [1]
        └── Databases (optional module)
            ├── PostgreSQL Flexible Server
            ├── MySQL Flexible Server
            ├── Azure SQL Database
            └── Cosmos DB
```

---

# 🖥️ Virtual Machines

Each VM runs:

- Ubuntu Server 22.04 LTS
- SSH authentication via public key
- Static public IP
- Dedicated NIC per VM

---

# 📦 Resources Created

| Resource | Count | Notes |
|---|---|---|
| azurerm_resource_group | 1 | Per region |
| azurerm_virtual_network | 1 | 10.0.0.0/16 |
| azurerm_subnet | 1 | 10.0.1.0/24 |
| azurerm_public_ip | 2 | Static |
| azurerm_network_interface | 2 | One per VM |
| azurerm_linux_virtual_machine | 2 | Ubuntu 22.04 |
| azurerm_postgresql_flexible_server | optional | PostgreSQL DB |
| azurerm_mysql_flexible_server | optional | MySQL DB |
| azurerm_mssql_server | optional | Azure SQL |
| azurerm_cosmosdb_account | optional | Cosmos DB |

---

# 🗄️ Database Module

The `databases/` module provisions managed Azure databases.

## Supported Databases

### PostgreSQL Flexible Server
- PostgreSQL 14+
- Automated backups
- Optional public access

### MySQL Flexible Server
- MySQL 8.0
- UTF8MB4 encoding
- Managed backups

### Azure SQL Database
- Fully managed SQL Server
- Basic tier included
- Auto patching & backups

### Cosmos DB
- Global NoSQL database
- Serverless option
- High scalability

---

## 📁 Database Structure

```
terraform/
└── databases/
    ├── main.tf
    ├── postgres.tf
    ├── mysql.tf
    ├── sql.tf
    ├── cosmos.tf
    ├── variables.tf
    └── outputs.tf
```

---

# ⚙️ Variables

## Core

| Name | Required | Description |
|---|---|---|
| resource_group_name | yes | Azure RG |
| location | yes | Azure region |
| prefix | yes | Resource prefix |
| vm_sizes | yes | VM sizes |
| ssh_public_key | yes | SSH key |

## Database

| Name | Required |
|---|---|
| pg_admin_user | no |
| pg_admin_password | no |
| mysql_admin_user | no |
| mysql_admin_password | no |
| sql_admin_user | no |
| sql_admin_password | no |

---

# 📤 Outputs

- public_ips
- postgres_fqdn
- mysql_fqdn
- sql_server_name
- cosmos_endpoint

---

# 🚀 Usage Example

## VM Module

```hcl
module "sweden" {
  source              = "./modules/vm-pair"
  resource_group_name = "rg-sweden"
  location            = "swedencentral"
  prefix              = "se"
  vm_sizes            = ["Standard_B2s", "Standard_B2s"]
  ssh_public_key      = var.ssh_public_key
}
```

---

## Database Module

```hcl
module "databases" {
  source = "./databases"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  env                 = "dev"

  pg_admin_user       = var.pg_admin_user
  pg_admin_password   = var.pg_admin_password

  mysql_admin_user    = var.mysql_admin_user
  mysql_admin_password = var.mysql_admin_password

  sql_admin_user      = var.sql_admin_user
  sql_admin_password  = var.sql_admin_password
}
```

---

# 🔄 Terraform Commands

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

# 🌿 Branch Strategy

| Event | Action |
|---|---|
| Push to main | Plan + Apply (production) |
| Pull Request | Plan only |

PRs are safe previews. Only merging to main deploys infrastructure.

---

# 🔐 GitHub Secrets

Configure in GitHub → Settings → Secrets:

| Secret | Description |
|---|---|
| ARM_CLIENT_ID | Azure Service Principal |
| ARM_CLIENT_SECRET | Azure secret |
| ARM_SUBSCRIPTION_ID | Azure subscription |
| ARM_TENANT_ID | Azure tenant |
| SSH_PUBLIC_KEY | SSH key |

REPO="OWNER/REPO"

gh secret set MYSQL_ADMIN_USER --body 'adminuser' --repo $REPO
gh secret set MYSQL_ADMIN_PASSWORD --body 'MySql!2026Secure' --repo $REPO

gh secret set SQL_ADMIN_USER --body 'sqladmin' --repo $REPO
gh secret set SQL_ADMIN_PASSWORD --body 'Sql!2026Secure' --repo $REPO

gh secret set PG_ADMIN_USER --body 'pgadmin' --repo $REPO
gh secret set PG_ADMIN_PASSWORD --body 'Pg!2026Secure' --repo $REPO

---

# ⚙️ setup_github_secrets.sh

Automates Azure + GitHub setup.

```bash
chmod +x setup_github_secrets.sh
./setup_github_secrets.sh
```

Features:
- Creates Azure Service Principal
- Pushes GitHub secrets
- Handles existing credentials safely

---

# 🔐 SSH Access

```bash
ssh azureuser@<public_ip>
```

```bash
terraform output public_ips
```

---

# 🧪 sync script

If resources already exist:

```bash
chmod +x synch.sh
./synch.sh
```

Used to import existing Azure NICs into Terraform state.

---

# 📈 CI/CD Pipeline

GitHub Actions automatically:

- Validates Terraform
- Plans changes
- Applies on main branch
- Comments PR plans

---

# 🚀 Recommended Upgrades

- Private endpoints for databases
- Azure Key Vault integration
- VM scale sets + load balancer
- Monitoring (Azure Monitor + Logs)
- Cost optimization (free-tier setup)
