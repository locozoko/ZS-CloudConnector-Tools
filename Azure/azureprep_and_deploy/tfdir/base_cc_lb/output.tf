locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}:/home/${var.server_admin_username}/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}

3) SSH to the EC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private-ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm.private-ip[1]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"

4) SSH to the server host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.workload1.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.workload1.private_ip[1]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"

Resource Group: ${azurerm_resource_group.main.name}
LB IP         : ${module.cc-vm.lb-ip}
CC VM1 Mgmt IP : ${module.cc-vm.private-ip[0]}
CC VM1 Svc IP  : ${module.cc-vm.service-ip[0]}
CC VM2 Mgmt IP : ${module.cc-vm.private-ip[1]}
CC VM2 Svc IP  : ${module.cc-vm.service-ip[1]}
NAT GW IP     : ${azurerm_public_ip.nat-pip.ip_address}
Bastion Public IP: ${module.bastion.public_ip}



TB

testbedconfigpyats = <<TBP
testbed:
  name: azure-${random_string.suffix.result}

devices:
  WORKER1:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.SshClientConnector
        via: fast
      fast:
        hostname: ${module.workload1.private_ip[0]}
        port: 22
        username: ubuntu
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_ip}
            username: ubuntu
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  WORKER2:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.SshClientConnector
        via: fast
      fast:
        hostname: ${module.workload1.private_ip[1]}
        port: 22
        username: ubuntu
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_ip}
            username: ubuntu
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  EC1:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private-ip[0]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_ip}
            username: ubuntu
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
  EC2:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm.private-ip[1]}
        port: 22
        username: zsroot
        key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_ip}
            username: ubuntu
            port: 22
            key_filename: ${var.name_prefix}-key-${random_string.suffix.result}.pem
TBP
}

output "testbedconfig" {
  value = local.testbedconfig
}

resource "local_file" "testbed" {
  content = local.testbedconfigpyats
  filename = "testbed.yml"
}