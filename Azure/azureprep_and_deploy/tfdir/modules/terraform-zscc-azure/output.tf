output "private-ip" {
  value = azurerm_network_interface.cc-mgmt-nic.private_ip_address
}

output "service-ip" {
  value = azurerm_network_interface.cc-service-nic.private_ip_address
}

output "cc-hostname" {
  value = azurerm_linux_virtual_machine.cc-vm.computer_name
}

output "cc-pid" {
  value = azurerm_linux_virtual_machine.cc-vm.identity[0].principal_id
}