output "matomo_url" {
  value       = "http://localhost:8081"
  description = "URL para acceder a Matomo desde el host"
}

output "namespace" {
  value       = kubernetes_namespace.analytics.metadata[0].name
  description = "Namespace donde se desplegaron los recursos"
}

output "mariadb_service" {
  value       = kubernetes_service.mariadb.metadata[0].name
  description = "Nombre del servicio de MariaDB"
}

output "matomo_service" {
  value       = kubernetes_service.matomo.metadata[0].name
  description = "Nombre del servicio de Matomo"
}

output "mariadb_pvc" {
  value       = kubernetes_persistent_volume_claim.mariadb_pvc.metadata[0].name
  description = "PVC de MariaDB (datos persistentes)"
}

output "matomo_pvc" {
  value       = kubernetes_persistent_volume_claim.matomo_pvc.metadata[0].name
  description = "PVC de Matomo (datos persistentes)"
}

output "db_secret" {
  value       = kubernetes_secret.db_credentials.metadata[0].name
  description = "Secret que contiene las credenciales de la BD"
  sensitive   = true
}
