# ingest.py

import io
import math
import os
import time
import zipfile

import requests
from dotenv import load_dotenv
from google.cloud import storage
from tqdm import tqdm  # pip install tqdm

load_dotenv()

# === Configuration ===
RAW_BUCKET = os.environ["RAW_BUCKET"]  # e.g. "alice-clinical-trials-raw"
DOWNLOAD_URL = "https://clinicaltrials.gov/api/v2/studies/download?format=json.zip"
# GCP_CREDENTIALS  = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")

# if not GCP_CREDENTIALS:
#     raise RuntimeError("Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path")


def download_and_extract():
    """
    Download the ZIP from ClinicalTrials.gov with a progress bar,
    then return the JSON bytes (we ignore the original filename).
    """
    resp = requests.get(DOWNLOAD_URL, stream=True)
    resp.raise_for_status()

    total_size = int(resp.headers.get("content-length", 0))
    chunk_size = 8192
    num_chunks = math.ceil(total_size / chunk_size)

    buffer = io.BytesIO()
    for chunk in tqdm(
        resp.iter_content(chunk_size=chunk_size),
        total=num_chunks,
        unit="chunk",
        desc="Downloading JSON ZIP",
    ):
        buffer.write(chunk)

    buffer.seek(0)
    with zipfile.ZipFile(buffer) as z:
        for name in z.namelist():
            if name.lower().endswith(".json"):
                return z.read(name)

    raise RuntimeError("No JSON file found in ZIP")


def upload_to_gcs(blob_name: str, data: bytes, bucket_name: str, max_retries: int = 3):
    """
    Upload bytes to GCS, with simple retry logic on transient failures.
    """
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    for attempt in range(1, max_retries + 1):
        try:
            print(
                f"[{attempt}/{max_retries}] Uploading {blob_name} to gs://{bucket_name}/{blob_name} …"
            )
            # For large files, streaming via open() can be more memory‑efficient:
            with blob.open("wb") as f:
                f.write(data)
            print("Upload complete!")
            return
        except Exception as e:
            print(f"Upload attempt {attempt} failed: {e}")
            if attempt < max_retries:
                time.sleep(2**attempt)
            else:
                raise


def main():
    # 1) Download and extract JSON bytes
    json_bytes = download_and_extract()

    # 2) Upload as a fixed filename
    upload_to_gcs(
        blob_name="clinical_trials.json", data=json_bytes, bucket_name=RAW_BUCKET
    )


if __name__ == "__main__":
    main()
