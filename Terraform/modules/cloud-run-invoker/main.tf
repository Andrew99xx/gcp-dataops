resource "google_cloud_run_service_iam_member" "this" {
  location = var.location
  project  = var.project
  service  = var.service
  role     = var.role
  member   = var.member
}
