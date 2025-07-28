-- name: overallstatus_valid
SELECT *
FROM {{ ref('curated.clinical_trials_clean') }}
WHERE OverallStatus NOT IN ('COMPLETED','RECRUITING','TERMINATED','OTHER');
