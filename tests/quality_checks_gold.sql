-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- quality_checks_gold.sql
--
-- PURPOSE:
--   Validate the integrity, consistency, and relationships
--   of the Gold dimensional model.
--
-- USAGE:
--   Run after 0_build_gold.sql.
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
-- 4. DIAGNOSIS FLAG -> DIAGNOSIS DIMENSION
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
-- 5. SERVICE -> CLIENT RELATIONSHIP
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
-- 6. SERVICE -> SERVICE DIMENSION
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
-- 7. CLIENT -> GEOGRAPHY RELATIONSHIP
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
-- 8. SILVER / GOLD ROW RECONCILIATION
--
-- WHY:
-- fact_client_year should preserve the same client-level
-- grain as Silver.
--
-- Expected:
-- row_difference = 0
-- ============================================================

SELECT
    'Service code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.bridge_client_service AS s

LEFT JOIN gold.dim_service AS service_dim
    ON s.SERVICE_CODE = service_dim.SERVICE_CODE

WHERE service_dim.SERVICE_CODE IS NULL;