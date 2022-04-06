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


## Create the user_data file
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
AZURE_VAULT_URL=${var.azure_vault_url}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

resource "local_file" "user-data-file" {
  content  = local.userdata
  filename = "user_data"
}


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

# Create Public IP for NAT Gateway
resource "azurerm_public_ip" "nat-pip" {
  name                    = "${var.name_prefix}-public-ip1-${random_string.suffix.result}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30

  tags = map(
     "environment", var.environment,
  )
}

# Create NAT Gateway
resource "azurerm_nat_gateway" "nat-gw1" {
  name                    = "${var.name_prefix}-nat-gw1-${random_string.suffix.result}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  idle_timeout_in_minutes = 10
  tags = map(
     "environment", var.environment,
  )
}

# Associate Public IP to NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat-gw-association1" {
  nat_gateway_id       = azurerm_nat_gateway.nat-gw1.id
  public_ip_address_id = azurerm_public_ip.nat-pip.id
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


# 4. CC VMs
# Create Management Subnet
resource "azurerm_subnet" "cc-subnet" {
  name                 = "${var.name_prefix}-ec-snet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.cc_subnet]
}

# Associate Cloud Connector Subnet to NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec" {
  subnet_id      = azurerm_subnet.cc-subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat-gw1.id
}


# Cloud Connector Module variables
module "cc-vm1" {
  source                                = "../modules/terraform-zscc-azure"
  name_prefix                           = var.name_prefix
  resource_tag                          = random_string.suffix.result
  resource_group                        = azurerm_resource_group.main.name
  mgmt_subnet_id                        = azurerm_subnet.cc-subnet.id
  service_subnet_id                     = azurerm_subnet.cc-subnet.id
  ssh_key                               = tls_private_key.key.public_key_openssh
  cc_vm_managed_identity_name           = var.cc_vm_managed_identity_name
  cc_vm_managed_identity_resource_group = var.cc_vm_managed_identity_resource_group
  user_data                             = local.userdata
  ccvm_instance_size                    = var.ccvm_instance_size

  ccvm_image_publisher                  = var.ccvm_image_publisher
  ccvm_image_offer                      = var.ccvm_image_offer
  ccvm_image_sku                        = var.ccvm_image_sku
  ccvm_image_version                    = var.ccvm_image_version

  depends_on = [
    azurerm_subnet_nat_gateway_association.subnet-nat-association-ec,
    local_file.user-data-file,
  ]
}

# Create Workload Route Table to send to Cloud Connector
resource "azurerm_route_table" "server-rt1" {
  count               = var.subnet_count
  name                = "${var.name_prefix}-server-rt-${count.index+1}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  disable_bgp_route_propagation = true

  route {
    name                   = "route-${count.index+1}"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.cc-vm1.service-ip
  }
}

# Associate Route Table with Workload Subnet
resource "azurerm_subnet_route_table_association" "server-rt-assoc" {
  count          = var.subnet_count
  subnet_id      = azurerm_subnet.server-subnet[count.index].id
  route_table_id = azurerm_route_table.server-rt1[count.index].id
}






############################################################################################################################################
####### Legacy code for reference if customer desires to break cloud connector mgmt and service interfaces out into separate subnets #######
############################################################################################################################################

#resource "azurerm_subnet" "cc-mgmt-subnet" {
#  count                = 1
#  name                 = "${var.name_prefix}-ec-mgmt-snet-${count.index+1}-${random_string.suffix.result}"
#  resource_group_name  = azurerm_resource_group.main.name
#  virtual_network_name = azurerm_virtual_network.vnet1.name
#  address_prefixes     = [cidrsubnet(var.network_address_space, 12, (count.index*16)+3936)]
#}

# Create Service Subnet
#resource "azurerm_subnet" "cc-service-subnet" {
#  count                = 1
#  name                 = "${var.name_prefix}-ec-service-snet-${count.index+1}-${random_string.suffix.result}"
#  resource_group_name  = azurerm_resource_group.main.name
#  virtual_network_name = azurerm_virtual_network.vnet1.name
#  address_prefixes     = [cidrsubnet(var.network_address_space, 12, (count.index*16)+4000)]
#}

# Associate Management Subnet to NAT Gateway
#resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec-mgmt" {
#  subnet_id      = azurerm_subnet.cc-mgmt-subnet[0].id
#  nat_gateway_id = azurerm_nat_gateway.nat-gw1.id
#}

# Associate Service Subnet to NAT Gateway
#resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association-ec-service" {
#  subnet_id      = azurerm_subnet.cc-service-subnet[0].id
#  nat_gateway_id = azurerm_nat_gateway.nat-gw1.id
#}