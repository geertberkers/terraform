# -------------------------
# RESOURCE GROUP
# -------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -------------------------
# NETWORK
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.prefix}"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# -------------------------
# NSG (SSH access to VM via LB)
# -------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -------------------------
# SINGLE PUBLIC IP
# -------------------------
resource "azurerm_public_ip" "ip" {
  name                = "ip-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -------------------------
# LOAD BALANCER
# -------------------------
resource "azurerm_lb" "lb" {
  name                = "lb-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool"
}

# -------------------------
# NICs (NO public IP)
# -------------------------
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-${var.prefix}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# -------------------------
# NIC → Backend Pool association (FIX)
# -------------------------
resource "azurerm_network_interface_backend_address_pool_association" "pool_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool.id
}

# -------------------------
# NAT RULES (SSH per VM)
# -------------------------
resource "azurerm_lb_nat_rule" "ssh" {
  count                          = 2
  name                           = "ssh-${count.index}"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 5000 + count.index
  backend_port                   = 22
  frontend_ip_configuration_name = "public"
}

resource "azurerm_network_interface_nat_rule_association" "ssh" {
  count                 = 2
  network_interface_id  = azurerm_network_interface.nic[count.index].id
  ip_configuration_name = "ipconfig"
  nat_rule_id           = azurerm_lb_nat_rule.ssh[count.index].id
}

# -------------------------
# VMs
# -------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  count               = 2
  name                = "vm-${var.prefix}-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_sizes[count.index]

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}