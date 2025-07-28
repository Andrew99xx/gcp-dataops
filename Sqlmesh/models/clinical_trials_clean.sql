-- models/clinical_trials_clean.sql

MODEL (
  name curated.clinical_trials_clean,  -- schema.table
  kind FULL
);

SELECT
  -- NCT identifier
  protocolSection.identificationModule.nctId                                AS NCTId,
  -- Human‐readable title
  protocolSection.identificationModule.briefTitle                           AS BriefTitle,
  -- First condition listed
  protocolSection.conditionsModule.conditions[1]                            AS Condition,
  -- First intervention’s name
  protocolSection.armsInterventionsModule.interventions[1].name             AS InterventionName,
  -- Trial status and dates
  protocolSection.statusModule.overallStatus                                AS OverallStatus,
  CAST(
    CASE
      WHEN LENGTH(protocolSection.statusModule.startDateStruct.date) = 7
      THEN protocolSection.statusModule.startDateStruct.date || '-01'
      ELSE protocolSection.statusModule.startDateStruct.date
    END
  AS DATE)                                                                    AS StartDate,

  CAST(
    CASE
      WHEN LENGTH(protocolSection.statusModule.primaryCompletionDateStruct.date) = 7
      THEN protocolSection.statusModule.primaryCompletionDateStruct.date || '-01'
      ELSE protocolSection.statusModule.primaryCompletionDateStruct.date
    END
  AS DATE)                                                                    AS PrimaryCompletionDate

FROM raw.clinical_trials;
