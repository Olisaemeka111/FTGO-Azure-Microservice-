# Load Balancer Module

resource "azurerm_public_ip" "lb" {
  name                = "${var.load_balancer_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.sku == "Standard" ? "Static" : "Dynamic"
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_lb" "main" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.main.id
}

# Health Probe for Kubernetes API Server
resource "azurerm_lb_probe" "api_server" {
  name            = "probe-api-server"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Tcp"
  port            = 6443
}

# Load Balancing Rule for Kubernetes API Server
resource "azurerm_lb_rule" "api_server" {
  name                           = "rule-api-server"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.api_server.id
  enable_floating_ip             = false
  disable_outbound_snat          = var.sku == "Standard" ? true : false
  idle_timeout_in_minutes        = 4
}

# Health Probe for HTTPS
resource "azurerm_lb_probe" "https" {
  name            = "probe-https"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Tcp"
  port            = 443
}

# Load Balancing Rule for HTTPS
resource "azurerm_lb_rule" "https" {
  name                           = "rule-https"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.https.id
  enable_floating_ip             = false
  disable_outbound_snat          = var.sku == "Standard" ? true : false
  idle_timeout_in_minutes        = 4
}

# Health Probe for HTTP
resource "azurerm_lb_probe" "http" {
  name            = "probe-http"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Tcp"
  port            = 80
}

# Load Balancing Rule for HTTP
resource "azurerm_lb_rule" "http" {
  name                           = "rule-http"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
  enable_floating_ip             = false
  disable_outbound_snat          = var.sku == "Standard" ? true : false
  idle_timeout_in_minutes        = 4
}

# Outbound Rule for NAT
resource "azurerm_lb_outbound_rule" "main" {
  count                   = var.sku == "Standard" ? 1 : 0
  name                    = "outbound-rule"
  loadbalancer_id         = azurerm_lb.main.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id

  frontend_ip_configuration {
    name = "LoadBalancerFrontEnd"
  }
}

