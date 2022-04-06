locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}:/home/${var.server_admin_username}/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}

3) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.workload1.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"

Resource Group:    ${azurerm_resource_group.main.name}
Bastion Public IP: ${module.bastion.public_ip}

TB
}

output "testbedconfig" {
  value = local.testbedconfig
}