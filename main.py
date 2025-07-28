# main.py (FastAPI + DuckDB query service)

import logging
import os

import duckdb
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel

# ─── Setup ─────────────────────────────────────────────────────────────────────
load_dotenv()

# Basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("clinical-api")

# Ensure required env vars
for var in ("GCS_HMAC_KEY_ID", "GCS_HMAC_SECRET", "DUCKLAKE_BUCKET"):
    if var not in os.environ:
        raise RuntimeError(f"Missing required env var: {var}")

# ─── FastAPI & Models ──────────────────────────────────────────────────────────
app = FastAPI(title="Clinical Trials Query API")


class QueryRequest(BaseModel):
    sql: str


# ─── DuckDB Initialization ─────────────────────────────────────────────────────
conn = duckdb.connect(database=":memory:")

# Install & load HTTPFS for GCS access
conn.execute("INSTALL httpfs;")
conn.execute("LOAD httpfs;")

# Register GCS HMAC credentials
gcs_key = os.environ["GCS_HMAC_KEY_ID"]
gcs_secret = os.environ["GCS_HMAC_SECRET"]
conn.execute(
    f"""
CREATE OR REPLACE SECRET gcs_creds (
  TYPE gcs,
  KEY_ID '{gcs_key}',
  SECRET '{gcs_secret}'
);
"""
)

# Define a view over all Parquet partitions
ducklake_bucket = os.environ["DUCKLAKE_BUCKET"]
conn.execute(
    f"""
CREATE OR REPLACE VIEW ducklake AS
SELECT *
FROM read_parquet(
  'gcs://{ducklake_bucket}/clinical_trials/**/*.parquet'
);
"""
)


# ─── Helper to enforce only SELECT queries ──────────────────────────────────────
def sanitize_sql(sql: str) -> str:
    sql = sql.strip()
    if not sql.lower().startswith("select"):
        raise ValueError("Only SELECT statements are allowed")
    return f"SELECT * FROM ({sql}) AS _sub"


# ─── API Endpoint ──────────────────────────────────────────────────────────────
@app.post("/query")
async def query_endpoint(request: QueryRequest, http_request: Request):
    client_ip = http_request.client.host
    logger.info(f"Received query from {client_ip}: {request.sql}")
    try:
        safe_sql = sanitize_sql(request.sql)
        cur = conn.execute(safe_sql)
        columns = [col[0] for col in cur.description]
        rows = cur.fetchall()
        return [{columns[i]: row[i] for i in range(len(columns))} for row in rows]
    except ValueError as ve:
        logger.warning(f"Bad request: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Query failed: {e}")
        raise HTTPException(status_code=500, detail="Internal query error")
