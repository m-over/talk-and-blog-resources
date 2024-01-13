resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-weu-01"
  location            = "westeurope"
  resource_group_name = "XXX"
  dns_prefix          = "aks-weu-01"


  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_D2_v2"
    zones               = [1, 2, 3]
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Owner = "mover"
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "example" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  vm_size               = "Standard_DS2_v2"
  zones                 = [1, 2, 3]
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 3

  tags = {
    Owner = "mover"
  }
}
