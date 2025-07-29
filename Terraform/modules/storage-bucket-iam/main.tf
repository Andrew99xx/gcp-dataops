resource "google_storage_bucket_iam_member" "this" {
  bucket = var.bucket
  role   = var.role
  member = var.member
}
