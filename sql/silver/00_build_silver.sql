-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- 00_build_silver.sql
--
-- PURPOSE:
--   Create a cleaned Silver layer from the raw Bronze data.
--
-- Silver will:
--   * Preserve the original record structure
--   * Convert documented -9 missing values to NULL
--   * Keep valid source codes unchanged
--   * Add basic pipeline metadata
--   
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
-- 2. CREATE SILVER SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS silver;


-- ============================================================
-- 3. CREATE SILVER TABLE
--
-- WHY:
-- Silver keeps the original MH-CLD structure but stores
-- cleaned values and basic pipeline metadata.
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.mhcld (

    YEAR INTEGER,
    AGE INTEGER,
    EDUC INTEGER,
    ETHNIC INTEGER,
    RACE INTEGER,

    SPHSERVICE INTEGER,
    CMPSERVICE INTEGER,
    OPISERVICE INTEGER,
    RTCSERVICE INTEGER,
    IJSSERVICE INTEGER,

    MH1 INTEGER,
    MH2 INTEGER,
    MH3 INTEGER,

    SUB INTEGER,
    MARSTAT INTEGER,
    SMISED INTEGER,
    SAP INTEGER,
    EMPLOY INTEGER,
    DETNLF INTEGER,
    VETERAN INTEGER,
    LIVARAG INTEGER,
    NUMMHS INTEGER,

    TRAUSTREFLG INTEGER,
    ANXIETYFLG INTEGER,
    ADHDFLG INTEGER,
    CONDUCTFLG INTEGER,
    DELIRDEMFLG INTEGER,
    BIPOLARFLG INTEGER,
    DEPRESSFLG INTEGER,
    ODDFLG INTEGER,
    PDDFLG INTEGER,
    PERSONFLG INTEGER,
    SCHIZOFLG INTEGER,
    ALCSUBFLG INTEGER,
    OTHERDISFLG INTEGER,

    STATEFIP INTEGER,
    DIVISION INTEGER,
    REGION INTEGER,

    CASEID BIGINT,
    SEX INTEGER,

    CREATE_DATE TIMESTAMP,
    SOURCE_SYSTEM VARCHAR(100),
    SOURCE_TABLE VARCHAR(100)
);


-- ============================================================
-- 4. BEGIN SILVER BUILD
--
-- WHY:
-- Silver is completely rebuilt from the current Bronze table.
-- Bronze itself remains untouched.
-- ============================================================

BEGIN TRANSACTION;

-- ============================================================
-- 5. CLEAR EXISTING SILVER DATA - OPTIONAL
--
-- Silver is rebuilt from the current Bronze table each time.
-- ============================================================

DELETE FROM silver.mhcld;


-- ============================================================
-- 6. LOAD AND CLEAN BRONZE DATA

-- WHY:
-- MH-CLD uses -9 to represent missing, unknown, not collected,
-- or invalid values in many coded fields.
--
-- NULLIF(column, -9):
--
--   -9 becomes NULL
--   every other value remains unchanged
--
-- Example:
--
--   AGE = -9  -> NULL
--   AGE = 7   -> 7
--
-- ============================================================

INSERT INTO silver.mhcld (

    YEAR,
    AGE,
    EDUC,
    ETHNIC,
    RACE,

    SPHSERVICE,
    CMPSERVICE,
    OPISERVICE,
    RTCSERVICE,
    IJSSERVICE,

    MH1,
    MH2,
    MH3,

    SUB,
    MARSTAT,
    SMISED,
    SAP,
    EMPLOY,
    DETNLF,
    VETERAN,
    LIVARAG,
    NUMMHS,

    TRAUSTREFLG,
    ANXIETYFLG,
    ADHDFLG,
    CONDUCTFLG,
    DELIRDEMFLG,
    BIPOLARFLG,
    DEPRESSFLG,
    ODDFLG,
    PDDFLG,
    PERSONFLG,
    SCHIZOFLG,
    ALCSUBFLG,
    OTHERDISFLG,

    STATEFIP,
    DIVISION,
    REGION,

    CASEID,
    SEX,

    CREATE_DATE,
    SOURCE_SYSTEM,
    SOURCE_TABLE
)

SELECT

    YEAR,

    NULLIF(AGE, -9),
    NULLIF(EDUC, -9),
    NULLIF(ETHNIC, -9),
    NULLIF(RACE, -9),

    NULLIF(SPHSERVICE, -9),
    NULLIF(CMPSERVICE, -9),
    NULLIF(OPISERVICE, -9),
    NULLIF(RTCSERVICE, -9),
    NULLIF(IJSSERVICE, -9),

    NULLIF(MH1, -9),
    NULLIF(MH2, -9),
    NULLIF(MH3, -9),

    NULLIF(SUB, -9),
    NULLIF(MARSTAT, -9),
    NULLIF(SMISED, -9),
    NULLIF(SAP, -9),
    NULLIF(EMPLOY, -9),
    NULLIF(DETNLF, -9),
    NULLIF(VETERAN, -9),
    NULLIF(LIVARAG, -9),

    NUMMHS,

    TRAUSTREFLG,
    ANXIETYFLG,
    ADHDFLG,
    CONDUCTFLG,
    DELIRDEMFLG,
    BIPOLARFLG,
    DEPRESSFLG,
    ODDFLG,
    PDDFLG,
    PERSONFLG,
    SCHIZOFLG,
    ALCSUBFLG,
    OTHERDISFLG,

    NULLIF(STATEFIP, -9),
    NULLIF(DIVISION, -9),
    NULLIF(REGION, -9),

    CASEID,

    NULLIF(SEX, -9),

    CURRENT_TIMESTAMP,
    'SAMHSA MH-CLD',
    'bronze.mhcld'

FROM bronze.mhcld;


-- ============================================================
-- 7. COMPLETE SILVER BUILD
-- ============================================================

COMMIT;

-- ============================================================
-- 8. SILVER SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS rows_loaded,
    MAX(CREATE_DATE) AS load_timestamp
FROM silver.mhcld;
