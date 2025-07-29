output "raw_bucket" {
  description = "Name of the raw data bucket"
  value       = module.raw_bucket.name
}

output "ducklake_bucket" {
  description = "Name of the ducklake data bucket"
  value       = module.ducklake_bucket.name
}


output "artifact_repo" {
  description = "Artifact Registry Docker repository"
  value       = module.docker_repo.full_name
}

output "cloud_run_url" {
  description = "URL of the deployed Cloud Run API"
  value       = module.cloud_run.url
}
