# ---------------------------------------------------------------------------------------------------------------------
# AZURE RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "arc_benchmark" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

# --------------------------------------------------------------------------------------------------------------------
# LOG ANALYTICS - FOR CONTAINER INSIGHTS
# --------------------------------------------------------------------------------------------------------------------
# Random ID generator
resource "random_id" "workspace" {
  keepers = {
    group_name = azurerm_resource_group.arc_benchmark.name
  }
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "container_insights" {
  name                = "k8s-workspace-${random_id.workspace.hex}"
  location            = azurerm_resource_group.arc_benchmark.location
  resource_group_name = azurerm_resource_group.arc_benchmark.name
  sku                 = "PerGB2018"

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.arc_benchmark.location
  resource_group_name   = azurerm_resource_group.arc_benchmark.name
  workspace_resource_id = azurerm_log_analytics_workspace.container_insights.id
  workspace_name        = azurerm_log_analytics_workspace.container_insights.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

# --------------------------------------------------------------------------------------------------------------------
# AKS - WITH CONTAINER INSIGHTS
# --------------------------------------------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  depends_on          = [azurerm_log_analytics_solution.container_insights]
  name                = "aks-benchmark"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks"

  default_node_pool {
    name                = "agentpool"
    node_count          = 2
    vm_size             = "Standard_DS3_v2"
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    min_count           = null
    max_count           = null
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      # Commenting out ignores changes to nodes
      # default_node_pool[0].node_count
    ]
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.container_insights.id
    }
  }

  tags = var.tags
}
# --------------------------------------------------------------------------------------------------------------------
# AKS - larger nodepool
# --------------------------------------------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "aks_nodepool_big" {
  name                  = "bigpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS5_v2"
  node_count            = 2
  enable_auto_scaling   = false
  min_count             = null
  max_count             = null

  tags = var.tags
}
