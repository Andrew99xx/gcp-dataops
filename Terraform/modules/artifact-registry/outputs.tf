output "full_name" {
  description = "Full resource path of the repository"
  # THIS is the full path you need:
  value       = google_artifact_registry_repository.this.id
}

# (optional) still keep the short ID if you want it:
output "short_name" {
  description = "Short repository ID"
  value       = google_artifact_registry_repository.this.repository_id
}
