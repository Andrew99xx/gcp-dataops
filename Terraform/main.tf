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

# Secrets (stay in root)
data "google_secret_manager_secret_version" "hmac_key_id" {
  secret  = "hmac-key-id"
  version = "latest"
}
data "google_secret_manager_secret_version" "hmac_secret" {
  secret  = "hmac-secret"
  version = "latest"
}

# 1 & 2. Buckets
module "raw_bucket" {
  source         = "./modules/storage-bucket"
  bucket_name    = var.raw_bucket_name
  location       = var.region
  lifecycle_days = 90
}
module "ducklake_bucket" {
  source         = "./modules/storage-bucket"
  bucket_name    = var.ducklake_bucket_name
  location       = var.region
  lifecycle_days = 365
}

# 3. Artifact Registry
module "docker_repo" {
  source        = "./modules/artifact-registry"
  repository_id = var.artifact_repo_id
  location      = var.region
  description   = "Docker repo for clinical-trials query API"
}

# 4. Service Account
module "run_sa" {
  source       = "./modules/service-account"
  account_id   = var.run_service_account_id
  display_name = "Cloud Run SA for Clinical Trials API"

}

# 5 & 6. IAM bindings
module "ducklake_reader" {
  source = "./modules/storage-bucket-iam"
  bucket = module.ducklake_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.run_sa.email}"
}
module "repo_reader" {
  source     = "./modules/artifact-registry-iam"
  repository = var.artifact_repo_id
  location   = var.region
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.run_sa.email}"
}

# 7. Cloud Run Service
module "cloud_run" {
  source                = "./modules/cloud-run-service"
  name                  = var.cloud_run_service
  location              = var.region
  image                 = var.image_uri
  service_account_email = module.run_sa.email
  hmac_key_id           = data.google_secret_manager_secret_version.hmac_key_id.secret_data
  hmac_secret           = data.google_secret_manager_secret_version.hmac_secret.secret_data
  ducklake_bucket_name  = var.ducklake_bucket_name
  raw_bucket_name       = var.raw_bucket_name
}

# 8. Public invoker
module "public_invoker" {
  source   = "./modules/cloud-run-invoker"
  service  = var.cloud_run_service
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
