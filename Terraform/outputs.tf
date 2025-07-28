output "raw_bucket" {
  description = "GCS bucket for raw clinical trial data"
  value       = google_storage_bucket.raw.name
}

output "ducklake_bucket" {
  description = "GCS bucket for DuckLake Parquet output"
  value       = google_storage_bucket.ducklake.name
}

output "artifact_repo" {
  description = "Artifact Registry Docker repository"
  value       = google_artifact_registry_repository.docker_repo.id
}

output "cloud_run_url" {
  description = "URL of the deployed Cloud Run API"
  value       = google_cloud_run_service.api.status[0].url
}
