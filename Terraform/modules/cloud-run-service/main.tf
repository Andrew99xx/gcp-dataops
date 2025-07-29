resource "google_cloud_run_service" "this" {
  name     = var.name
  location = var.location

  template {
    spec {
      service_account_name = var.service_account_email

      containers {
        image = var.image

        env {
          name  = "GCS_HMAC_KEY_ID"
          value = var.hmac_key_id
        }
        env {
          name  = "GCS_HMAC_SECRET"
          value = var.hmac_secret
        }
        env {
          name  = "DUCKLAKE_BUCKET"
          value = var.ducklake_bucket_name
        }
        env {
          name  = "RAW_BUCKET"
          value = var.raw_bucket_name
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# If you want an output URL:



