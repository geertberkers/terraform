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
