output "name" {
  description = "The Cloud Run service name"
  value       = google_cloud_run_service.this.name
}

# modules/cloud-run-service/outputs.tf
output "url" {
  description = "HTTPS endpoint"
  value       = google_cloud_run_service.this.status[0].url
}