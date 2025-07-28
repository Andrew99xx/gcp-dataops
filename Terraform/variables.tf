variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run and Artifact Registry"
  type        = string
  default     = "us-central1"
}

variable "raw_bucket_name" {
  type        = string
  description = "GCS bucket to hold raw JSON (must be globally unique)"
  validation {
    condition     = can(regex("^[-a-z0-9]{3,63}$", var.raw_bucket_name))
    error_message = "Bucket names must be 3–63 lowercase letters, numbers or hyphens."
  }
}


variable "ducklake_bucket_name" {
  description = "Name of the GCS bucket to hold parquet (DuckLake) data"
  type        = string
  validation {
    condition     = can(regex("^[-a-z0-9]{3,63}$", var.ducklake_bucket_name))
    error_message = "Bucket names must be 3–63 lowercase letters, numbers or hyphens."
  }
}

variable "artifact_repo_id" {
  description = "Artifact Registry Docker repo ID"
  type        = string
  default     = "clinical-trials-api-repo"
}

variable "image_uri" {
  description = "The full Docker image URI to deploy (e.g. us-central1-docker.pkg.dev/<PROJECT>/<REPO>/<IMAGE>:tag)"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}


variable "cloud_run_service" {
  description = "Cloud Run service name for the query API"
  type        = string
  default     = "clinical-trials-api"
}

