from fastapi import FastAPI, HTTPException, Request
import duckdb, os, logging
from pydantic import BaseModel
from dotenv import load_dotenv

# ─── Setup ─────────────────────────────────────────────────────────────────────
load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("clinical-api")

for var in ("GCS_HMAC_KEY_ID","GCS_HMAC_SECRET","DUCKLAKE_BUCKET"):
    if var not in os.environ:
        raise RuntimeError(f"Missing required env var: {var}")

app = FastAPI(title="Clinical Trials Query API")

class QueryRequest(BaseModel):
    sql: str

# ─── DuckDB Initialization ─────────────────────────────────────────────────────
conn = duckdb.connect(database=":memory:")
conn.execute("INSTALL httpfs;")
conn.execute("LOAD httpfs;")

# register GCS HMAC creds
gcs_key, gcs_secret = os.environ["GCS_HMAC_KEY_ID"], os.environ["GCS_HMAC_SECRET"]
conn.execute(f"""
CREATE OR REPLACE SECRET gcs_creds (
  TYPE gcs,
  KEY_ID '{gcs_key}',
  SECRET '{gcs_secret}'
);
""")

# attempt to create the 'ducklake' view, but don’t crash if it fails
ducklake_bucket = os.environ["DUCKLAKE_BUCKET"]
try:
    conn.execute(f"""
    CREATE OR REPLACE VIEW ducklake AS
    SELECT *
    FROM read_parquet(
      'gcs://{ducklake_bucket}/clinical_trials/**/*.parquet'
    );
    """)
except Exception as e:
    logger.warning(f"Could not initialize ducklake view (import‐time): {e}")

def sanitize_sql(sql: str) -> str:
    if not sql.strip().lower().startswith("select"):
        raise ValueError("Only SELECT statements are allowed")
    return f"SELECT * FROM ({sql}) AS _sub"

@app.post("/query")
async def query_endpoint(request: QueryRequest, http_request: Request):
    logger.info(f"Query from {http_request.client.host}: {request.sql}")
    try:
        cur = conn.execute(sanitize_sql(request.sql))
        cols = [c[0] for c in cur.description]
        rows = cur.fetchall()
        return [dict(zip(cols, r)) for r in rows]
    except ValueError as ve:
        raise HTTPException(400, str(ve))
    except Exception as e:
        logger.error(f"Query error: {e}")
        raise HTTPException(500, "Internal query error")
