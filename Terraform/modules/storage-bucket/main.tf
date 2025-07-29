resource "google_storage_bucket" "this" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = var.lifecycle_days }
    action    { type = "Delete" }
  }
}
