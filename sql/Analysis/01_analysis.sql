-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- 01_gold_analysis_examples.sql
--
-- PURPOSE:
--   Provide example analysis queries using the Gold layer.
--
-- These queries are not part of the warehouse build process.
-- They are examples that show how the Gold model can be used
-- for client-year, diagnosis, service, and QA analysis.
-- ============================================================


-- ============================================================
-- 1. CREATE / OPEN DATABASE
-- ============================================================

ATTACH IF NOT EXISTS
    'warehouse/mhcld.duckdb'
    AS mhcld;

USE mhcld;


-- ============================================================
-- 2. CLIENT YEAR RECORD COUNTS BY YEAR
--
-- WHY:
-- Confirms the number of client-year records available for
-- analysis by reporting year.
-- ============================================================

SELECT
    YEAR,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    YEAR

ORDER BY
    YEAR;


-- ============================================================
-- 3. CLIENT RECORDS BY AGE GROUP
--
-- WHY:
-- Shows the distribution of client year records by age group.
-- ============================================================

SELECT
    AGE_CODE,
    AGE_GROUP,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    AGE_CODE,
    AGE_GROUP

ORDER BY
    AGE_CODE;


-- ============================================================
-- 4. CLIENT RECORDS BY REGION
--
-- WHY:
-- Summarizes client year records by Census region.
-- ============================================================

SELECT
    REGION,
    REGION_NAME,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    REGION,
    REGION_NAME

ORDER BY
    REGION;


-- ============================================================
-- 5. CLIENT RECORDS BY STATE
--
-- WHY:
-- Summarizes client year records by state.
-- ============================================================

SELECT
    STATEFIP,
    STATE_NAME,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    STATEFIP,
    STATE_NAME

ORDER BY
    client_records DESC;


-- ============================================================
-- 6. CLIENT RECORDS BY SMI / SED STATUS
--
-- WHY:
-- Shows how client year records are distributed by serious
-- mental illness or serious emotional disturbance status.
-- ============================================================

SELECT
    SMISED_CODE,
    SMISED_LABEL,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    SMISED_CODE,
    SMISED_LABEL

ORDER BY
    client_records DESC;


-- ============================================================
-- 7. CLIENT RECORDS BY EMPLOYMENT STATUS
--
-- WHY:
-- Shows client year records by employment status.
-- ============================================================

SELECT
    EMPLOYMENT_STATUS_CODE,
    EMPLOYMENT_STATUS_LABEL,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

GROUP BY
    EMPLOYMENT_STATUS_CODE,
    EMPLOYMENT_STATUS_LABEL

ORDER BY
    client_records DESC;


-- ============================================================
-- 8. DIAGNOSIS PREVALENCE BY FLAG
--
-- WHY:
-- Uses diagnosis flags to count whether each diagnosis category
-- was reported for a client year record.
--
-- This is the preferred view for diagnosis prevalence counts
-- because it counts diagnosis presence rather than diagnosis
-- position.
-- ============================================================

SELECT
    DIAGNOSIS_NAME,
    SUM(DIAGNOSIS_FLAG_COUNT) AS diagnosis_records

FROM gold.vw_client_diagnosis_flag_analysis

GROUP BY
    DIAGNOSIS_NAME

ORDER BY
    diagnosis_records DESC;


-- ============================================================
-- 9. POSITIONAL DIAGNOSIS COUNTS
--
-- WHY:
-- Counts diagnoses from MH1, MH2, and MH3 while preserving
-- diagnosis position.
--
-- Use this when diagnosis placement matters.
-- ============================================================

SELECT
    DIAGNOSIS_POSITION,
    DIAGNOSIS_NAME,
    SUM(DIAGNOSIS_COUNT) AS diagnosis_records

FROM gold.vw_client_diagnosis_analysis

GROUP BY
    DIAGNOSIS_POSITION,
    DIAGNOSIS_NAME

ORDER BY
    DIAGNOSIS_POSITION,
    diagnosis_records DESC;


-- ============================================================
-- 10. PRIMARY DIAGNOSIS COUNTS
--
-- WHY:
-- Looks only at diagnosis position 1, which represents the
-- first listed mental health diagnosis field.
-- ============================================================

SELECT
    DIAGNOSIS_NAME,
    SUM(DIAGNOSIS_COUNT) AS diagnosis_records

FROM gold.vw_client_diagnosis_analysis

WHERE DIAGNOSIS_POSITION = 1

GROUP BY
    DIAGNOSIS_NAME

ORDER BY
    diagnosis_records DESC;


-- ============================================================
-- 11. SERVICE UTILIZATION
--
-- WHY:
-- Counts reported mental health services by service type.
-- ============================================================

SELECT
    SERVICE_NAME,
    SUM(SERVICE_COUNT) AS service_records

FROM gold.vw_client_service_analysis

GROUP BY
    SERVICE_NAME

ORDER BY
    service_records DESC;


-- ============================================================
-- 12. SERVICES BY SMI / SED STATUS
--
-- WHY:
-- Combines the service bridge with the client year view to
-- compare service use by SMI / SED status.
-- ============================================================

SELECT
    c.SMISED_LABEL,
    s.SERVICE_NAME,
    SUM(s.SERVICE_COUNT) AS service_records

FROM gold.vw_client_service_analysis AS s

INNER JOIN gold.vw_client_year_analysis AS c
    ON s.YEAR = c.YEAR
   AND s.CASEID = c.CASEID

GROUP BY
    c.SMISED_LABEL,
    s.SERVICE_NAME

ORDER BY
    c.SMISED_LABEL,
    service_records DESC;


-- ============================================================
-- 13. DIAGNOSIS PREVALENCE BY REGION
--
-- WHY:
-- Combines diagnosis flags with client geography to compare
-- diagnosis category presence by region.
-- ============================================================

SELECT
    c.REGION_NAME,
    d.DIAGNOSIS_NAME,
    SUM(d.DIAGNOSIS_FLAG_COUNT) AS diagnosis_records

FROM gold.vw_client_diagnosis_flag_analysis AS d

INNER JOIN gold.vw_client_year_analysis AS c
    ON d.YEAR = c.YEAR
   AND d.CASEID = c.CASEID

GROUP BY
    c.REGION_NAME,
    d.DIAGNOSIS_NAME

ORDER BY
    c.REGION_NAME,
    diagnosis_records DESC;


-- ============================================================
-- 14. SERVICE UTILIZATION BY DIAGNOSIS CATEGORY
--
-- WHY:
-- Shows which services were reported among client year records
-- with each diagnosis category.
--
-- Uses diagnosis flags so diagnosis presence is counted once
-- per client year diagnosis category.
-- ============================================================

SELECT
    d.DIAGNOSIS_NAME,
    s.SERVICE_NAME,
    SUM(s.SERVICE_COUNT) AS service_records

FROM gold.vw_client_diagnosis_flag_analysis AS d

INNER JOIN gold.vw_client_service_analysis AS s
    ON d.YEAR = s.YEAR
   AND d.CASEID = s.CASEID

GROUP BY
    d.DIAGNOSIS_NAME,
    s.SERVICE_NAME

ORDER BY
    d.DIAGNOSIS_NAME,
    service_records DESC;


-- ============================================================
-- 15. DIAGNOSIS STRUCTURE COMPARISON
--
-- WHY:
-- Compares positional diagnoses with diagnosis flags.
--
-- This query validates whether MH1/MH2/MH3 align with the
-- diagnosis flag fields at the client year diagnosis level.
-- ============================================================

WITH diagnosis_compare AS (

    SELECT
        YEAR,
        CASEID,
        DIAGNOSIS_CODE,
        DIAGNOSIS_NAME,

        MAX(
            CASE
                WHEN DIAGNOSIS_SOURCE = 'POSITIONAL' THEN 1
                ELSE 0
            END
        ) AS has_positional_diagnosis,

        MAX(
            CASE
                WHEN DIAGNOSIS_SOURCE = 'FLAG' THEN 1
                ELSE 0
            END
        ) AS has_diagnosis_flag

    FROM gold.vw_client_diagnosis_all_analysis

    GROUP BY
        YEAR,
        CASEID,
        DIAGNOSIS_CODE,
        DIAGNOSIS_NAME
)

SELECT
    DIAGNOSIS_NAME,

    SUM(
        CASE
            WHEN has_positional_diagnosis = 1
             AND has_diagnosis_flag = 1
            THEN 1 ELSE 0
        END
    ) AS matched_in_both,

    SUM(
        CASE
            WHEN has_positional_diagnosis = 1
             AND has_diagnosis_flag = 0
            THEN 1 ELSE 0
        END
    ) AS positional_only,

    SUM(
        CASE
            WHEN has_positional_diagnosis = 0
             AND has_diagnosis_flag = 1
            THEN 1 ELSE 0
        END
    ) AS flag_only

FROM diagnosis_compare

GROUP BY
    DIAGNOSIS_NAME

ORDER BY
    positional_only DESC,
    flag_only DESC,
    matched_in_both DESC;


-- ============================================================
-- 16. DUPLICATE POSITIONAL DIAGNOSIS CHECK
--
-- WHY:
-- Identifies client year records where the same diagnosis category
-- appears more than once across MH1, MH2, and MH3.
--
-- This helps explain count differences between positional diagnosis
-- records and diagnosis flag records.
-- ============================================================

SELECT
    DIAGNOSIS_NAME,
    COUNT(*) AS client_years_with_duplicate_positional_diagnosis,
    SUM(positional_occurrences - 1) AS extra_positional_records

FROM (
    SELECT
        YEAR,
        CASEID,
        DIAGNOSIS_CODE,
        DIAGNOSIS_NAME,
        COUNT(*) AS positional_occurrences

    FROM gold.vw_client_diagnosis_analysis

    GROUP BY
        YEAR,
        CASEID,
        DIAGNOSIS_CODE,
        DIAGNOSIS_NAME

    HAVING COUNT(*) > 1
) AS duplicate_diagnoses

GROUP BY
    DIAGNOSIS_NAME

ORDER BY
    extra_positional_records DESC;


-- ============================================================
-- 17. UNKNOWN VALUE SUMMARY
--
-- WHY:
-- Reviews how often unknown or not reported values appear in
-- selected client year dimensions.
-- ============================================================

SELECT
    'AGE_GROUP' AS field_name,
    AGE_GROUP AS field_value,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

WHERE AGE_CODE = -1

GROUP BY
    AGE_GROUP

UNION ALL

SELECT
    'VETERAN_STATUS' AS field_name,
    VETERAN_STATUS_LABEL AS field_value,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

WHERE VETERAN_STATUS_CODE = -1

GROUP BY
    VETERAN_STATUS_LABEL

UNION ALL

SELECT
    'EMPLOYMENT_STATUS' AS field_name,
    EMPLOYMENT_STATUS_LABEL AS field_value,
    SUM(CLIENT_RECORD_COUNT) AS client_records

FROM gold.vw_client_year_analysis

WHERE EMPLOYMENT_STATUS_CODE = -1

GROUP BY
    EMPLOYMENT_STATUS_LABEL

ORDER BY
    field_name,
    client_records DESC;


-- ============================================================
-- 18. BASIC GOLD ANALYSIS SUMMARY
--
-- WHY:
-- Provides a summary of the Gold analysis layer.
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM gold.fact_client_year) AS client_year_records,
    (SELECT COUNT(*) FROM gold.bridge_client_diagnosis) AS positional_diagnosis_records,
    (SELECT COUNT(*) FROM gold.bridge_client_diagnosis_flag) AS diagnosis_flag_records,
    (SELECT COUNT(*) FROM gold.bridge_client_service) AS service_records;