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

# Grant AKS permission to use the Public IP
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Deploy NGINX Ingress Controller
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

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

  depends_on = [kubernetes_namespace.ingress_nginx, azurerm_role_assignment.aks_network]
}

locals {
  ingress_public_ip    = azurerm_public_ip.ingress.ip_address
  ingress_public_ip_id = azurerm_public_ip.ingress.id
}
