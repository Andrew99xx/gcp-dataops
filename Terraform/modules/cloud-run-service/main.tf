resource "google_cloud_run_service" "this" {
  name     = var.name
  location = var.location

  template {

     metadata {
      annotations = {
        # Tell Cloud Run to hit /health for readiness/liveness checks
        "run.googleapis.com/health-check-path"                     = "/health"
        # Optional tuning:
        "run.googleapis.com/health-check-interval"                 = "30s"
        "run.googleapis.com/health-check-timeout"                  = "5s"
        "run.googleapis.com/health-check-success-threshold"        = "1"
        "run.googleapis.com/health-check-failure-threshold"        = "3"
      }
    }
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



