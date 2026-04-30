terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.name_prefix}-aks"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_B2s_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable OIDC issuer to prevent disablement issues
  oidc_issuer_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

locals {
  kube_config = yamldecode(azurerm_kubernetes_cluster.aks.kube_config_raw)
}

provider "kubernetes" {
  host                   = local.kube_config.clusters[0].cluster.server
  client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.clusters[0].cluster.server
    client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
    client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
  }
}

resource "azurerm_public_ip" "ingress" {
  name                = "${var.name_prefix}-ingress-ip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NOTE: Manual role assignment for "Network Contributor" on this Resource Group
# is required for the AKS Identity to bind the Public IP. 
# Terraform attempt failed with 403 (insufficient permissions of the runner).

# Deploy NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  recreate_pods    = true
  replace          = true # Force replacement if name is already in use
  timeout          = 900  # Increase timeout to 15 minutes for LoadBalancer IP assignment

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress.ip_address
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Deploy cert-manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.13.1"
  force_update     = true
  cleanup_on_fail  = true
  atomic           = true
  replace          = true # Force replacement if resources already exist

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]
  create_duration = "60s"
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "info@gb-coding.nl"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [time_sleep.wait_for_cert_manager]
}

locals {
  ingress_public_ip    = azurerm_public_ip.ingress.ip_address
  ingress_public_ip_id = azurerm_public_ip.ingress.id
}
