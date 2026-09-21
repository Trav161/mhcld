-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- quality_checks_gold.sql
--
-- PURPOSE:
--   Validate the integrity, consistency, and relationships
--   of the Gold dimensional model.
--
-- USAGE:
--   Run after 00_build_gold.sql.
--
-- Expected results:
--   * Client-year records should be unique
--   * Fact records should match their parent client records
--   * Fact codes should match their dimension tables
--   * Geography keys should match the geography dimension
--   * Silver and Gold client-level row counts should match
-- ============================================================


-- ============================================================
-- 1. CREATE / OPEN DATABASE
-- ============================================================

ATTACH IF NOT EXISTS
    'warehouse/mhcld.duckdb'
    AS mhcld;

USE mhcld;


-- ============================================================
-- 2. CLIENT-YEAR DUPLICATE CHECK
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Duplicate client-year records' AS check_name,
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
-- 3. DIAGNOSIS -> CLIENT RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Diagnosis without matching client' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_diagnosis d

LEFT JOIN gold.fact_client_year c
    ON d.YEAR = c.YEAR
   AND d.CASEID = c.CASEID

WHERE c.CASEID IS NULL;


-- ============================================================
-- 4. DIAGNOSIS -> DIAGNOSIS DIMENSION
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Diagnosis code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_diagnosis f

LEFT JOIN gold.dim_diagnosis d
    ON f.DIAGNOSIS_CODE = d.DIAGNOSIS_CODE

WHERE d.DIAGNOSIS_CODE IS NULL;


-- ============================================================
-- 5. SERVICE -> CLIENT RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Service without matching client' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_service s

LEFT JOIN gold.fact_client_year c
    ON s.YEAR = c.YEAR
   AND s.CASEID = c.CASEID

WHERE c.CASEID IS NULL;


-- ============================================================
-- 6. SERVICE -> SERVICE DIMENSION
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'Service code without dimension match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_service f

LEFT JOIN gold.dim_service s
    ON f.SERVICE_CODE = s.SERVICE_CODE

WHERE s.SERVICE_CODE IS NULL;


-- ============================================================
-- 7. CLIENT -> GEOGRAPHY RELATIONSHIP
--
-- Expected:
-- issue_count = 0
-- ============================================================

SELECT
    'State code without geography match' AS check_name,
    COUNT(*) AS issue_count

FROM gold.fact_client_year c

LEFT JOIN gold.dim_geography g
    ON c.STATEFIP = g.STATEFIP

WHERE c.STATEFIP IS NOT NULL
  AND g.STATEFIP IS NULL;


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

    (SELECT COUNT(*)
     FROM silver.mhcld_clean)
        AS silver_rows,

    (SELECT COUNT(*)
     FROM gold.fact_client_year)
        AS gold_client_rows,

    (SELECT COUNT(*)
     FROM gold.fact_client_year)

    -

    (SELECT COUNT(*)
     FROM silver.mhcld_clean)
        AS row_difference;