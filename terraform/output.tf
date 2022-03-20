# ----------------------------------------------------------------------------------------------------------------------
# OUTPUT DESIRED VALUES
# ----------------------------------------------------------------------------------------------------------------------
output "la_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.container_insights.id
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
