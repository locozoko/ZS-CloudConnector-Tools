data "azurerm_resource_group" "selected" {
  name = var.resource_group
}

resource "azurerm_network_security_group" "bastion-nsg" {
  name                = "${var.name_prefix}-bastion-nsg-${var.resource_tag}"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name

  security_rule {
    name                       = "${var.name_prefix}-sec-rule-ssh-${var.resource_tag}"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = map(
     "environment", var.deployment_tag,
  )
}

resource "azurerm_public_ip" "bastion-pip" {
  name                    = "${var.name_prefix}-bastion-public-ip-${var.resource_tag}"
  location                = data.azurerm_resource_group.selected.location
  resource_group_name     = data.azurerm_resource_group.selected.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = map(
     "environment", var.deployment_tag,
  )
}

resource "azurerm_network_interface" "bastion-nic" {
  name                      = "${var.name_prefix}-bastion-nic-${var.resource_tag}"
  location                  = data.azurerm_resource_group.selected.location
  resource_group_name       = data.azurerm_resource_group.selected.name

  ip_configuration {
    name                          = "${var.name_prefix}-bastion-nic-conf-${var.resource_tag}"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion-pip.id
  }

  tags = map(
     "environment", var.deployment_tag,
  )
}

resource "azurerm_network_interface_security_group_association" "bastion-nic-association" {
  network_interface_id      = azurerm_network_interface.bastion-nic.id
  network_security_group_id = azurerm_network_security_group.bastion-nsg.id
}

resource "azurerm_linux_virtual_machine" "bastion-vm" {
  name                         = "${var.name_prefix}-bastion-vm-${var.resource_tag}"
  location                     = data.azurerm_resource_group.selected.location
  resource_group_name          = data.azurerm_resource_group.selected.name
  network_interface_ids        = [azurerm_network_interface.bastion-nic.id]
  size                         = var.instance_size
  admin_username               = var.server_admin_username
  computer_name                = "${var.name_prefix}-bastion-${var.resource_tag}"
  admin_ssh_key {
    username   = var.server_admin_username
    public_key = "${trimspace(var.ssh_key)} ${var.server_admin_username}@me.io"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.instance_image_publisher
    offer     = var.instance_image_offer
    sku       = var.instance_image_sku
    version   = var.instance_image_version
  }

  tags = map(
     "environment", var.deployment_tag,
  )

  depends_on = [
    azurerm_network_interface.bastion-nic,
    azurerm_network_interface_security_group_association.bastion-nic-association
  ]
}