-- models/staging_clinical_trials.sql

-- Stage the raw clinical trial JSON
MODEL (
  name raw.clinical_trials,       -- schema.table
  kind VIEW
);

-- read the JSON file and explode the "items" array
SELECT *
FROM read_json_auto(
  'gcs://{{ var("RAW_BUCKET") }}/clinical_trials.json'
);
