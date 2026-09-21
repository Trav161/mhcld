-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- 00_build_bronze.sql
--
-- PURPOSE:
--   Build the Bronze layer from scratch using one or more
--   compatible annual MH-CLD CSV files.
--
-- This script will:
--   * Create / open the DuckDB warehouse
--   * Create the Bronze schema
--   * Recreate the raw MH-CLD table
--   * Load all compatible CSV files from data/raw/
--   * Display the number of records loaded by year
--   * Display the source CSV files detected
--
-- IMPORTANT:
--   This is the FRESH BUILD option.
--
--   Running this file recreates bronze.mhcld
--   Bronze will contain only the data currently available
--   in data/raw/.
--
-- Place CSV files in:
--   data/raw/
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
-- 2. CREATE BRONZE SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS bronze;


-- ============================================================
-- 3. BEGIN FRESH BUILD
-- ============================================================

BEGIN TRANSACTION;


-- ============================================================
-- 4. CREATE RAW TABLE
--
-- The Bronze table contains only the original MH-CLD columns.
--
-- CREATE OR REPLACE makes this a fresh build.
-- Existing Bronze records are removed when the table
-- is recreated.
-- ============================================================

CREATE OR REPLACE TABLE bronze.mhcld (

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
    SEX INTEGER
);


-- ============================================================
-- 5. LOAD RAW MH-CLD DATA
--
-- Loads every compatible CSV found in data/raw/
-- and its subfolders.
--
-- One year or multiple years can be used.
-- ============================================================

INSERT INTO bronze.mhcld

SELECT

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
    SEX

FROM read_csv(
    'data/raw/**/*.csv',
    header = true
);


-- ============================================================
-- 6. COMPLETE FRESH BUILD
-- ============================================================

COMMIT;


-- ============================================================
-- 7. LOAD SUMMARY
-- ============================================================

SELECT
    YEAR,
    COUNT(*) AS total_rows
FROM bronze.mhcld
GROUP BY YEAR
ORDER BY YEAR;


-- ============================================================
-- 8. SOURCE FILE CHECK
--
-- Shows the CSV files detected inside data/raw/
-- and its subfolders.
-- ============================================================

SELECT *
FROM glob('data/raw/**/*.csv');
