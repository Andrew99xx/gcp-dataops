-- models/clinical_trials_parquet.sql

-- 1) MODEL DDL with only metadata
MODEL (
  name curated.clinical_trials,
  kind FULL
);

-- 3) Main transformation query (must end with semicolon if any post‑statements follow)
SELECT *
FROM curated.clinical_trials_clean;

-- 4) Post‑statements (must end with semicolon)
COPY (
  SELECT * FROM @this_model
)
TO 'gcs://{{ var("DUCKLAKE_BUCKET") }}/clinical_trials'
(FORMAT PARQUET, PARTITION_BY (OverallStatus));
