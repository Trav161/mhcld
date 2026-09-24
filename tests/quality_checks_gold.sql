-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- quality_checks_gold.sql
--
-- PURPOSE:
--   Validate the integrity, consistency, and relationships
--   of the Gold dimensional model.
--
-- USAGE:
--   1. sql/gold/00_build_gold.sql
--   2. sql/gold/01_build_gold_views.sql
--
-- Expected results:
--   * Client year records should be unique
--   * Diagnosis records should match their parent client records
--   * Diagnosis codes should match the diagnosis dimension
--   * Service records should match their parent client records
--   * Service codes should match the service dimension
--   * Geography keys should match the geography dimension
--   * Silver and Gold client level records should match
-- ============================================================


-- ============================================================
-- 1. CREATE / OPEN DATABASE
-- ============================================================

ATTACH IF NOT EXISTS
    'warehouse/mhcld.duckdb'
    AS mhcld;

USE mhcld;


-- ============================================================
-- 2. CLIENT YEAR DUPLICATE CHECK
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Duplicate client year records' AS check_name,
    COUNT(*) AS issue_count

FROM (

    SELECT
        YEAR,
        CASEID

    FROM gold.fact_client_year

    GROUP BY
        YEAR,
        CASEID

    HAVING COUNT(*) > 1

) AS duplicate_records;


-- ============================================================
-- 3. POSITIONAL DIAGNOSIS -> CLIENT RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Positional diagnosis without matching client' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_diagnosis AS d

LEFT JOIN gold.fact_client_year AS c
    ON d.YEAR = c.YEAR
   AND d.CASEID = c.CASEID

WHERE c.YEAR IS NULL;


-- ============================================================
-- 4. DIAGNOSIS FLAG -> CLIENT RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Diagnosis flag without matching client' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_diagnosis_flag AS df

LEFT JOIN gold.fact_client_year AS c
    ON df.YEAR = c.YEAR
   AND df.CASEID = c.CASEID

WHERE c.YEAR IS NULL;


-- ============================================================
-- 5. POSITIONAL DIAGNOSIS -> DIAGNOSIS DIMENSION
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Positional diagnosis code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_diagnosis AS d

LEFT JOIN gold.dim_diagnosis AS diagnosis_dim
    ON d.DIAGNOSIS_CODE = diagnosis_dim.DIAGNOSIS_CODE

WHERE diagnosis_dim.DIAGNOSIS_CODE IS NULL;


-- ============================================================
-- 6. DIAGNOSIS FLAG -> DIAGNOSIS DIMENSION
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Diagnosis flag code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_diagnosis_flag AS df

LEFT JOIN gold.dim_diagnosis AS diagnosis_dim
    ON df.DIAGNOSIS_CODE = diagnosis_dim.DIAGNOSIS_CODE

WHERE diagnosis_dim.DIAGNOSIS_CODE IS NULL;


-- ============================================================
-- 7. SERVICE -> CLIENT RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Service without matching client' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_service AS s

LEFT JOIN gold.fact_client_year AS c
    ON s.YEAR = c.YEAR
   AND s.CASEID = c.CASEID

WHERE c.YEAR IS NULL;


-- ============================================================
-- 8. SERVICE -> SERVICE DIMENSION
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Service code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_service AS s

LEFT JOIN gold.dim_service AS service_dim
    ON s.SERVICE_CODE = service_dim.SERVICE_CODE

WHERE service_dim.SERVICE_CODE IS NULL;


-- ============================================================
-- 9. CLIENT -> GEOGRAPHY RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'State code without geography match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS c

LEFT JOIN gold.dim_geography AS g
    ON c.STATEFIP = g.STATEFIP

WHERE g.STATEFIP IS NULL;


-- ============================================================
-- 10. CLIENT ATTRIBUTE DIMENSION CHECKS
--
-- WHY:
-- Each coded field in fact_client_year should map to its
-- related dimension table.
--
-- Expected:
-- issue_count = 0 for every check
-- ============================================================

SELECT
    'Age code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_age AS d
    ON f.AGE_CODE = d.AGE_CODE

WHERE d.AGE_CODE IS NULL

UNION ALL

SELECT
    'Education code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_education AS d
    ON f.EDUCATION_CODE = d.EDUCATION_CODE

WHERE d.EDUCATION_CODE IS NULL

UNION ALL

SELECT
    'Ethnicity code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_ethnicity AS d
    ON f.ETHNICITY_CODE = d.ETHNICITY_CODE

WHERE d.ETHNICITY_CODE IS NULL

UNION ALL

SELECT
    'Race code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_race AS d
    ON f.RACE_CODE = d.RACE_CODE

WHERE d.RACE_CODE IS NULL

UNION ALL

SELECT
    'Sex code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_sex AS d
    ON f.SEX_CODE = d.SEX_CODE

WHERE d.SEX_CODE IS NULL

UNION ALL

SELECT
    'Marital status code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_marital_status AS d
    ON f.MARITAL_STATUS_CODE = d.MARITAL_STATUS_CODE

WHERE d.MARITAL_STATUS_CODE IS NULL

UNION ALL

SELECT
    'SMISED code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_smised_status AS d
    ON f.SMISED_CODE = d.SMISED_CODE

WHERE d.SMISED_CODE IS NULL

UNION ALL

SELECT
    'Substance use status code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_substance_use_status AS d
    ON f.SUBSTANCE_USE_STATUS_CODE = d.SUBSTANCE_USE_STATUS_CODE

WHERE d.SUBSTANCE_USE_STATUS_CODE IS NULL

UNION ALL

SELECT
    'Substance diagnosis code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_substance_diagnosis AS d
    ON f.SUBSTANCE_DIAGNOSIS_CODE = d.SUBSTANCE_DIAGNOSIS_CODE

WHERE d.SUBSTANCE_DIAGNOSIS_CODE IS NULL

UNION ALL

SELECT
    'Employment status code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_employment_status AS d
    ON f.EMPLOYMENT_STATUS_CODE = d.EMPLOYMENT_STATUS_CODE

WHERE d.EMPLOYMENT_STATUS_CODE IS NULL

UNION ALL

SELECT
    'Not in labor force code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_not_in_labor_force AS d
    ON f.NOT_IN_LABOR_FORCE_CODE = d.NOT_IN_LABOR_FORCE_CODE

WHERE d.NOT_IN_LABOR_FORCE_CODE IS NULL

UNION ALL

SELECT
    'Veteran status code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_veteran_status AS d
    ON f.VETERAN_STATUS_CODE = d.VETERAN_STATUS_CODE

WHERE d.VETERAN_STATUS_CODE IS NULL

UNION ALL

SELECT
    'Living arrangement code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_living_arrangement AS d
    ON f.LIVING_ARRANGEMENT_CODE = d.LIVING_ARRANGEMENT_CODE

WHERE d.LIVING_ARRANGEMENT_CODE IS NULL;


-- ============================================================
-- 11. SILVER / GOLD ROW RECONCILIATION
--
-- WHY:
-- fact_client_year should preserve the same client level
-- grain as Silver.
--
-- Expected:
-- row_difference = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM silver.mhcld) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_client_year) AS gold_client_rows,
    (SELECT COUNT(*) FROM gold.fact_client_year)
        -
    (SELECT COUNT(*) FROM silver.mhcld) AS row_difference;


-- ============================================================
-- 12. GOLD RECORD SUMMARY
--
-- WHY:
-- Provides a final summary of the main Gold tables.
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM gold.fact_client_year) AS client_year_records,
    (SELECT COUNT(*) FROM gold.bridge_client_diagnosis) AS positional_diagnosis_records,
    (SELECT COUNT(*) FROM gold.bridge_client_diagnosis_flag) AS diagnosis_flag_records,
    (SELECT COUNT(*) FROM gold.bridge_client_service) AS service_records;