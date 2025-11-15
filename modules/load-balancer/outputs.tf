# Load Balancer Module Outputs

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = azurerm_lb.main.id
}

output "load_balancer_name" {
  description = "Name of the load balancer"
  value       = azurerm_lb.main.name
}

output "frontend_ip_address" {
  description = "Frontend IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "backend_address_pool_id" {
  description = "ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.main.id
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = azurerm_public_ip.lb.id
}

