output "public_ips" {
  value = azurerm_public_ip.ip[*].ip_address
}

output "public_ip" {
  value = azurerm_public_ip.ip.ip_address
}

output "ssh_commands" {
  value = [
    "ssh azureuser@${azurerm_public_ip.ip.ip_address} -p 5000",
    "ssh azureuser@${azurerm_public_ip.ip.ip_address} -p 5001"
  ]
}