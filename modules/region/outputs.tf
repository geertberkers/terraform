output "public_ips" {
  value = azurerm_public_ip.ip[*].ip_address
}
