resource "google_artifact_registry_repository_iam_member" "this" {
  repository = var.repository
  location   = var.location
  role       = var.role
  member     = var.member
}
