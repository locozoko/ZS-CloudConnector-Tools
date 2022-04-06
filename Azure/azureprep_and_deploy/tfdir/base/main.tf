# generate a random string
resource "random_string" "suffix" {
  length = 8
  upper = false
  special = false
}


############################################################################################################################
#### The following lines generates a new SSH key pair and stores the PEM file locally. The public key output is used    ####
#### as the ssh_key passed variable to the cc_vm module for admin_ssh_key public_key authentication                     ####
#### This is not recommended for production deployments. Please consider modifying to pass your own custom              ####
#### public key file located in a secure location                                                                       ####
############################################################################################################################
# private key for login
resource "tls_private_key" "key" {
  algorithm   = var.tls_key_algorithm
}

# save the private key
resource "null_resource" "save-key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "${tls_private_key.key.private_key_pem}" > ${var.name_prefix}-key-${random_string.suffix.result}.pem
      chmod 0600 ${var.name_prefix}-key-${random_string.suffix.result}.pem
EOF
  }
}

###########################################################################################################################
###########################################################################################################################

# 1. Network Infra
# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg-${random_string.suffix.result}"
  location = var.arm_location
  tags = map(
     "environment", var.environment,
  )
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.name_prefix}-vnet1-${random_string.suffix.result}"
  address_space       = [
    var.network_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = map(
     "environment", var.environment,
  )
}

# Create Bastion Host subnet
resource "azurerm_subnet" "bastion-subnet" {
  count                = 1
  name                 = "${var.name_prefix}-bastion-snet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [cidrsubnet(var.network_address_space, 8, count.index+101)]
}

# Create Workload Subnet
resource "azurerm_subnet" "server-subnet" {
  count                = var.subnet_count
  name                 = "${var.name_prefix}-server-snet-${count.index+1}-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [cidrsubnet(var.network_address_space, 8, count.index+1)]
}

# 2. Bastion Host
module "bastion" {
  source           = "../modules/terraform-zsbastion-azure"
  name_prefix      = var.name_prefix
  resource_tag     = random_string.suffix.result
  resource_group   = azurerm_resource_group.main.name
  public_subnet_id = azurerm_subnet.bastion-subnet[0].id

  ssh_key          = tls_private_key.key.public_key_openssh
}

# 3. Workload
module "workload1" {
  vm_count       = 1
  source         = "../modules/terraform-zsworkload-azure"
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  resource_group = azurerm_resource_group.main.name
  subnet_id      = azurerm_subnet.server-subnet[0].id
  ssh_key        = tls_private_key.key.public_key_openssh
}