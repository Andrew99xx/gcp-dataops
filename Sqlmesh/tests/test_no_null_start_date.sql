-- name: no_null_start_date
SELECT *
FROM {{ ref('curated.clinical_trials_clean') }}
WHERE StartDate IS NULL;
