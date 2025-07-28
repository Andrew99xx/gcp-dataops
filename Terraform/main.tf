terraform {
  required_version = ">= 1.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_secret_manager_secret_version" "hmac_key_id" {
  secret  = "hmac-key-id"
  version = "latest"
}

data "google_secret_manager_secret_version" "hmac_secret" {
  secret  = "hmac-secret"
  version = "latest"
}
# 1. Create raw data bucket
resource "google_storage_bucket" "raw" {
  name                        = var.raw_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# 2. Create ducklake bucket
resource "google_storage_bucket" "ducklake" {
  name                        = var.ducklake_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# 3. Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google
  location      = var.region
  repository_id = var.artifact_repo_id
  format        = "DOCKER"
  description   = "Docker repo for clinical-trials query API"
}

# 4. Service Account for Cloud Run
resource "google_service_account" "run_sa" {
  account_id   = "clinical-trials-run-sa"
  display_name = "Cloud Run SA for Clinical Trials API"
}

# 5. IAM: allow SA to read from ducklake bucket only
resource "google_storage_bucket_iam_member" "ducklake_reader" {
  bucket = google_storage_bucket.ducklake.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.run_sa.email}"
}

# 6. Grant SA permission to pull from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "repo_reader" {
  repository = google_artifact_registry_repository.docker_repo.name
  location   = var.region
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.run_sa.email}"
}

# 7. Cloud Run service placeholder
#    (you'll fill in 'image' once you build & push your container)
resource "google_cloud_run_service" "api" {
  name     = var.cloud_run_service
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.run_sa.email
      containers {
        image = var.image_uri # e.g. "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_id}/image:tag"
        env {
          name  = "GCS_HMAC_KEY_ID"
          value = data.google_secret_manager_secret_version.hmac_key_id.secret_data
        }
        env {
          name  = "GCS_HMAC_SECRET"
          value = data.google_secret_manager_secret_version.hmac_secret.secret_data
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

# 8. Allow public (allUsers) to invoke the API
resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = google_cloud_run_service.api.location
  project  = var.project_id
  service  = google_cloud_run_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
