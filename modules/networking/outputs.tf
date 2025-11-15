# Networking Module Outputs

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = azurerm_subnet.management.id
}

output "workload_subnet_id" {
  description = "ID of the workload subnet"
  value       = azurerm_subnet.workload.id
}

output "management_nsg_id" {
  description = "ID of the management network security group"
  value       = azurerm_network_security_group.management.id
}

output "workload_nsg_id" {
  description = "ID of the workload network security group"
  value       = azurerm_network_security_group.workload.id
}

