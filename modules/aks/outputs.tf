output "resource_group_name" {
  value       = azurerm_resource_group.aks_rg.name
  description = "Name of the resource group containing the AKS cluster"
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Name of the AKS cluster"
}

output "kube_config_raw" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "Raw Kubernetes config for cluster access"
}
