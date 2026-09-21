-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- quality_checks_silver.sql
--
-- PURPOSE:
--   Validate the quality, consistency, and integrity of the
--   Silver layer after data has been loaded from Bronze.
--
-- USAGE:
--   Run after 00_build_silver.sql.
--
-- Expected results:
--   * Bronze and Silver row counts should match
--   * YEAR + CASEID should contain no duplicate records
--   * Required record identifiers should not be NULL
--   * Documented -9 missing values should not remain in fields
--     cleaned during the Silver transformation
--   * Pipeline metadata should be populated
--
-- ============================================================


-- ============================================================
-- 1. CREATE / OPEN DATABASE
-- ============================================================

ATTACH IF NOT EXISTS
    'warehouse/mhcld.duckdb'
    AS mhcld;

USE mhcld;


-- ============================================================
-- 2. BRONZE / SILVER ROW RECONCILIATION
--
-- WHY:
-- Cleaning should not change the number of client records.
--
-- Expected:
-- row_difference = 0
-- ============================================================

SELECT

    (SELECT COUNT(*)
     FROM bronze.mhcld)
        AS bronze_rows,

    (SELECT COUNT(*)
     FROM silver.mhcld)
        AS silver_rows,

    (SELECT COUNT(*)
     FROM silver.mhcld)

    -

    (SELECT COUNT(*)
     FROM bronze.mhcld)
        AS row_difference;


-- ============================================================
-- 3. DUPLICATE RECORD CHECK
--
-- YEAR + CASEID is the working client record key.
--
-- Expected:
-- No rows returned.
-- ============================================================

SELECT
    YEAR,
    CASEID,
    COUNT(*) AS record_count

FROM silver.mhcld

GROUP BY
    YEAR,
    CASEID

HAVING COUNT(*) > 1;


-- ============================================================
-- 4. REQUIRED KEY CHECK
--
-- YEAR and CASEID identify each client record.
--
-- Expected:
-- Both values should equal 0.
-- ============================================================

SELECT

    SUM(
        CASE
            WHEN YEAR IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_year_records,

    SUM(
        CASE
            WHEN CASEID IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_caseid_records

FROM silver.mhcld;


-- ============================================================
-- 5. REMAINING -9 CHECK
--
-- WHY:
-- Fields cleaned with NULLIF(column, -9) should no longer
-- contain -9 in Silver.
--
-- Expected:
-- records_with_negative_9 = 0
-- ============================================================

SELECT
    COUNT(*) AS records_with_negative_9

FROM silver.mhcld

WHERE
       AGE = -9
    OR EDUC = -9
    OR ETHNIC = -9
    OR RACE = -9
    OR SPHSERVICE = -9
    OR CMPSERVICE = -9
    OR OPISERVICE = -9
    OR RTCSERVICE = -9
    OR IJSSERVICE = -9
    OR MH1 = -9
    OR MH2 = -9
    OR MH3 = -9
    OR SUB = -9
    OR MARSTAT = -9
    OR SMISED = -9
    OR SAP = -9
    OR EMPLOY = -9
    OR DETNLF = -9
    OR VETERAN = -9
    OR LIVARAG = -9
    OR STATEFIP = -9
    OR DIVISION = -9
    OR REGION = -9
    OR SEX = -9;


-- ============================================================
-- 6. PIPELINE METADATA CHECK
--
-- Expected:
-- All values should equal 0.
-- ============================================================

SELECT

    SUM(
        CASE
            WHEN CREATE_DATE IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_create_date,

    SUM(
        CASE
            WHEN SOURCE_SYSTEM IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_source_system,

    SUM(
        CASE
            WHEN SOURCE_TABLE IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_source_table

FROM silver.mhcld;


-- ============================================================
-- 7. SILVER QUALITY SUMMARY
-- ============================================================

SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT YEAR) AS years_loaded,

    MIN(YEAR) AS earliest_year,

    MAX(YEAR) AS latest_year,

    MAX(CREATE_DATE) AS load_timestamp,

    (
        SELECT COUNT(*)
        FROM (
            SELECT
                YEAR,
                CASEID

            FROM silver.mhcld

            GROUP BY
                YEAR,
                CASEID

            HAVING COUNT(*) > 1
        ) AS duplicates
    ) AS duplicate_keys

FROM silver.mhcld;