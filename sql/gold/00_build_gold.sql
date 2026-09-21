-- ============================================================
-- MH-CLD DATA WAREHOUSE
-- 00_build_gold.sql
--
-- PURPOSE:
--   Transform the cleaned Silver data into an
--   analysis ready Gold layer.
--
-- Gold will:
--   * Add readable labels to important coded fields
--   * Create dimension tables
--   * Create the main client year fact table
--   * Create diagnosis and service relationship tables
--   * Produce a final Gold build summary
--
-- PORTABILITY NOTE:
--   DuckDB is used as the reference database for this project.
--
--   ATTACH / USE and schema creation may need to be adapted
--   when using another SQL platform.
--
--   TIMESTAMP is appropriate for DuckDB and PostgreSQL.
--   SQL Server should use DATETIME for CREATE_DATE columns.
--
--   The core transformation logic uses broadly portable
--   SQL patterns.
-- ============================================================
-- 1. CREATE / OPEN DATABASE
--
-- WHY:
-- Silver and Gold need to exist inside the same warehouse.
-- This opens the DuckDB file created during Bronze.
--
-- ATTACH / USE is the DuckDB specific part of this script.
-- The transformation SQL below uses common SQL patterns.
-- ============================================================

ATTACH IF NOT EXISTS
    'warehouse/mhcld.duckdb'
    AS mhcld;

USE mhcld;


-- ============================================================
-- 2. CREATE GOLD SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS gold;


-- ============================================================
-- 3. CLEAR PREVIOUS GOLD BUILD
--
-- WHY:
-- Gold is completely reproducible from Silver.
--
-- DROP TABLE IF EXISTS allows this script to be rerun
-- without continuously adding duplicate Gold records.
--
-- Relationship tables are dropped first, followed by
-- the main fact and dimension tables.
-- ============================================================

DROP TABLE IF EXISTS gold.fact_client_service;
DROP TABLE IF EXISTS gold.fact_client_diagnosis;
DROP TABLE IF EXISTS gold.fact_client_year;

DROP TABLE IF EXISTS gold.dim_service;
DROP TABLE IF EXISTS gold.dim_diagnosis;
DROP TABLE IF EXISTS gold.dim_geography;


-- ============================================================
-- 4. CREATE GEOGRAPHY DIMENSION
--
-- WHY:
-- STATEFIP, DIVISION, and REGION are coded values.
--
-- Rather than repeating state, division, and region names
-- millions of times inside the fact table, we store those
-- descriptions once in a small dimension table.
--
-- Relationship:
--
-- fact_client_year.STATEFIP
--              ↓
-- dim_geography.STATEFIP
-- ============================================================

CREATE TABLE gold.dim_geography (

    STATEFIP INTEGER,
    STATE_NAME VARCHAR(50),

    DIVISION INTEGER,
    DIVISION_NAME VARCHAR(50),

    REGION INTEGER,
    REGION_NAME VARCHAR(50)

);


INSERT INTO gold.dim_geography (

    STATEFIP,
    STATE_NAME,
    DIVISION,
    DIVISION_NAME,
    REGION,
    REGION_NAME

)

SELECT DISTINCT

    STATEFIP,

    CASE STATEFIP
        WHEN 1  THEN 'Alabama'
        WHEN 2  THEN 'Alaska'
        WHEN 4  THEN 'Arizona'
        WHEN 5  THEN 'Arkansas'
        WHEN 6  THEN 'California'
        WHEN 8  THEN 'Colorado'
        WHEN 9  THEN 'Connecticut'
        WHEN 10 THEN 'Delaware'
        WHEN 11 THEN 'District of Columbia'
        WHEN 12 THEN 'Florida'
        WHEN 13 THEN 'Georgia'
        WHEN 15 THEN 'Hawaii'
        WHEN 16 THEN 'Idaho'
        WHEN 17 THEN 'Illinois'
        WHEN 18 THEN 'Indiana'
        WHEN 19 THEN 'Iowa'
        WHEN 20 THEN 'Kansas'
        WHEN 21 THEN 'Kentucky'
        WHEN 22 THEN 'Louisiana'
        WHEN 23 THEN 'Maine'
        WHEN 24 THEN 'Maryland'
        WHEN 25 THEN 'Massachusetts'
        WHEN 26 THEN 'Michigan'
        WHEN 27 THEN 'Minnesota'
        WHEN 28 THEN 'Mississippi'
        WHEN 29 THEN 'Missouri'
        WHEN 30 THEN 'Montana'
        WHEN 31 THEN 'Nebraska'
        WHEN 32 THEN 'Nevada'
        WHEN 33 THEN 'New Hampshire'
        WHEN 34 THEN 'New Jersey'
        WHEN 35 THEN 'New Mexico'
        WHEN 36 THEN 'New York'
        WHEN 37 THEN 'North Carolina'
        WHEN 38 THEN 'North Dakota'
        WHEN 39 THEN 'Ohio'
        WHEN 40 THEN 'Oklahoma'
        WHEN 41 THEN 'Oregon'
        WHEN 42 THEN 'Pennsylvania'
        WHEN 44 THEN 'Rhode Island'
        WHEN 45 THEN 'South Carolina'
        WHEN 46 THEN 'South Dakota'
        WHEN 47 THEN 'Tennessee'
        WHEN 48 THEN 'Texas'
        WHEN 49 THEN 'Utah'
        WHEN 50 THEN 'Vermont'
        WHEN 51 THEN 'Virginia'
        WHEN 53 THEN 'Washington'
        WHEN 54 THEN 'West Virginia'
        WHEN 55 THEN 'Wisconsin'
        WHEN 56 THEN 'Wyoming'
        WHEN 72 THEN 'Puerto Rico'
        WHEN 99 THEN 'Other jurisdictions'
        ELSE 'Unmapped'
    END,

    DIVISION,

    CASE
        WHEN DIVISION IS NULL THEN NULL
        WHEN DIVISION = 0 THEN 'Other jurisdictions'
        WHEN DIVISION = 1 THEN 'New England'
        WHEN DIVISION = 2 THEN 'Middle Atlantic'
        WHEN DIVISION = 3 THEN 'East North Central'
        WHEN DIVISION = 4 THEN 'West North Central'
        WHEN DIVISION = 5 THEN 'South Atlantic'
        WHEN DIVISION = 6 THEN 'East South Central'
        WHEN DIVISION = 7 THEN 'West South Central'
        WHEN DIVISION = 8 THEN 'Mountain'
        WHEN DIVISION = 9 THEN 'Pacific'
        ELSE 'Unmapped'
    END,

    REGION,

    CASE
        WHEN REGION IS NULL THEN NULL
        WHEN REGION = 0 THEN 'Other jurisdictions'
        WHEN REGION = 1 THEN 'Northeast'
        WHEN REGION = 2 THEN 'Midwest'
        WHEN REGION = 3 THEN 'South'
        WHEN REGION = 4 THEN 'West'
        ELSE 'Unmapped'
    END

FROM silver.mhcld

WHERE STATEFIP IS NOT NULL;


-- ============================================================
-- 5. CREATE DIAGNOSIS DIMENSION
--
-- WHY:
-- MH1, MH2, and MH3 all use the same diagnosis codes.
--
-- Instead of repeatedly writing CASE statements for those
-- three columns, we create one small lookup table.
--
-- One diagnosis code = one diagnosis name.
-- ============================================================

CREATE TABLE gold.dim_diagnosis (

    DIAGNOSIS_CODE INTEGER,
    DIAGNOSIS_NAME VARCHAR(100)

);


INSERT INTO gold.dim_diagnosis
    (DIAGNOSIS_CODE, DIAGNOSIS_NAME)

VALUES

    (1,  'Trauma and stressor related disorders'),
    (2,  'Anxiety disorders'),
    (3,  'Attention deficit/hyperactivity disorder (ADHD)'),
    (4,  'Conduct disorders'),
    (5,  'Delirium/dementia disorders'),
    (6,  'Bipolar disorders'),
    (7,  'Depressive disorders'),
    (8,  'Oppositional defiant disorders'),
    (9,  'Pervasive developmental disorders'),
    (10, 'Personality disorders'),
    (11, 'Schizophrenia or other psychotic disorders'),
    (12, 'Alcohol or substance related disorders'),
    (13, 'Other disorders/conditions');

-- ============================================================
-- 6. CREATE SERVICE DIMENSION
--
-- WHY:
-- The source contains five different service columns.
--
-- We create one lookup table describing those service types.
--
-- Later, fact_client_service will connect clients to the
-- services they actually received.
-- ============================================================

CREATE TABLE gold.dim_service (

    SERVICE_CODE VARCHAR(3),
    SERVICE_NAME VARCHAR(100)

);


INSERT INTO gold.dim_service
    (SERVICE_CODE, SERVICE_NAME)

VALUES

    ('SPH', 'State psychiatric hospital'),
    ('CMP', 'Community based program'),
    ('OPI', 'Other psychiatric inpatient'),
    ('RTC', 'Residential treatment center'),
    ('IJS', 'Justice system institution');

-- ============================================================
-- 7. CREATE MAIN CLIENT-YEAR FACT TABLE
--
-- WHY:
-- This is the center of the Gold model.
--
-- Grain:
--   One record = one MH-CLD client record for one
--   reporting year.
--
-- YEAR + CASEID is our working record key.
--
-- We preserve the original coded values and add readable
-- labels beside important fields.
--
-- This gives us both:
--
--   SEX = 1
--   SEX_LABEL = Male
--
-- The codes remain available for validation.
-- The labels make analysis easier to read.
-- ============================================================

CREATE TABLE gold.fact_client_year (

    YEAR INTEGER,
    CASEID BIGINT,

    AGE INTEGER,
    AGE_GROUP VARCHAR(30),

    EDUC INTEGER,
    EDUCATION_LABEL VARCHAR(50),

    ETHNIC INTEGER,
    ETHNICITY_LABEL VARCHAR(50),

    RACE INTEGER,
    RACE_LABEL VARCHAR(60),

    SEX INTEGER,
    SEX_LABEL VARCHAR(20),

    MARSTAT INTEGER,
    MARITAL_STATUS_LABEL VARCHAR(30),

    SMISED INTEGER,
    SMISED_LABEL VARCHAR(50),

    SAP INTEGER,
    SUBSTANCE_USE_DISORDER_LABEL VARCHAR(20),

    SUB INTEGER,
    SUBSTANCE_DIAGNOSIS_LABEL VARCHAR(60),

    EMPLOY INTEGER,
    EMPLOYMENT_STATUS_LABEL VARCHAR(100),

    DETNLF INTEGER,
    NOT_IN_LABOR_FORCE_LABEL VARCHAR(100),

    VETERAN INTEGER,
    VETERAN_STATUS_LABEL VARCHAR(20),

    LIVARAG INTEGER,
    LIVING_ARRANGEMENT_LABEL VARCHAR(30),

    NUMMHS INTEGER,

    MH1 INTEGER,
    MH2 INTEGER,
    MH3 INTEGER,

    SPHSERVICE INTEGER,
    CMPSERVICE INTEGER,
    OPISERVICE INTEGER,
    RTCSERVICE INTEGER,
    IJSSERVICE INTEGER,

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

    CREATE_DATE TIMESTAMP,
    SOURCE_TABLE VARCHAR(100)

);


INSERT INTO gold.fact_client_year (

    YEAR,
    CASEID,

    AGE,
    AGE_GROUP,

    EDUC,
    EDUCATION_LABEL,

    ETHNIC,
    ETHNICITY_LABEL,

    RACE,
    RACE_LABEL,

    SEX,
    SEX_LABEL,

    MARSTAT,
    MARITAL_STATUS_LABEL,

    SMISED,
    SMISED_LABEL,

    SAP,
    SUBSTANCE_USE_DISORDER_LABEL,

    SUB,
    SUBSTANCE_DIAGNOSIS_LABEL,

    EMPLOY,
    EMPLOYMENT_STATUS_LABEL,

    DETNLF,
    NOT_IN_LABOR_FORCE_LABEL,

    VETERAN,
    VETERAN_STATUS_LABEL,

    LIVARAG,
    LIVING_ARRANGEMENT_LABEL,

    NUMMHS,

    MH1,
    MH2,
    MH3,

    SPHSERVICE,
    CMPSERVICE,
    OPISERVICE,
    RTCSERVICE,
    IJSSERVICE,

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

    CREATE_DATE,
    SOURCE_TABLE

)

SELECT

    YEAR,
    CASEID,


    -- --------------------------------------------------------
    -- AGE
    -- --------------------------------------------------------

    AGE,

    CASE
        WHEN AGE IS NULL THEN NULL
        WHEN AGE = 1  THEN '0-11 years'
        WHEN AGE = 2  THEN '12-14 years'
        WHEN AGE = 3  THEN '15-17 years'
        WHEN AGE = 4  THEN '18-20 years'
        WHEN AGE = 5  THEN '21-24 years'
        WHEN AGE = 6  THEN '25-29 years'
        WHEN AGE = 7  THEN '30-34 years'
        WHEN AGE = 8  THEN '35-39 years'
        WHEN AGE = 9  THEN '40-44 years'
        WHEN AGE = 10 THEN '45-49 years'
        WHEN AGE = 11 THEN '50-54 years'
        WHEN AGE = 12 THEN '55-59 years'
        WHEN AGE = 13 THEN '60-64 years'
        WHEN AGE = 14 THEN '65 years and older'
        ELSE 'Unmapped'
    END AS AGE_GROUP,


    -- --------------------------------------------------------
    -- EDUCATION
    -- --------------------------------------------------------

    EDUC,

    CASE
        WHEN EDUC IS NULL THEN NULL
        WHEN EDUC = 1 THEN 'Special education'
        WHEN EDUC = 2 THEN '0 to 8'
        WHEN EDUC = 3 THEN '9 to 11'
        WHEN EDUC = 4 THEN '12 or GED'
        WHEN EDUC = 5 THEN 'More than 12'
        ELSE 'Unmapped'
    END AS EDUCATION_LABEL,


    -- --------------------------------------------------------
    -- ETHNICITY
    -- --------------------------------------------------------

    ETHNIC,

    CASE
        WHEN ETHNIC IS NULL THEN NULL
        WHEN ETHNIC = 1 THEN 'Mexican'
        WHEN ETHNIC = 2 THEN 'Puerto Rican'
        WHEN ETHNIC = 3 THEN 'Other Hispanic or Latino origin'
        WHEN ETHNIC = 4 THEN 'Not of Hispanic or Latino origin'
        ELSE 'Unmapped'
    END AS ETHNICITY_LABEL,


    -- --------------------------------------------------------
    -- RACE
    -- --------------------------------------------------------

    RACE,

    CASE
        WHEN RACE IS NULL THEN NULL
        WHEN RACE = 1 THEN 'American Indian/Alaska Native'
        WHEN RACE = 2 THEN 'Asian'
        WHEN RACE = 3 THEN 'Black or African American'
        WHEN RACE = 4 THEN 'Native Hawaiian or Other Pacific Islander'
        WHEN RACE = 5 THEN 'White'
        WHEN RACE = 6 THEN 'Some other race alone/two or more races'
        ELSE 'Unmapped'
    END AS RACE_LABEL,


    -- --------------------------------------------------------
    -- SEX
    -- --------------------------------------------------------

    SEX,

    CASE
        WHEN SEX IS NULL THEN NULL
        WHEN SEX = 1 THEN 'Male'
        WHEN SEX = 2 THEN 'Female'
        ELSE 'Unmapped'
    END AS SEX_LABEL,


    -- --------------------------------------------------------
    -- MARITAL STATUS
    -- --------------------------------------------------------

    MARSTAT,

    CASE
        WHEN MARSTAT IS NULL THEN NULL
        WHEN MARSTAT = 1 THEN 'Never married'
        WHEN MARSTAT = 2 THEN 'Now married'
        WHEN MARSTAT = 3 THEN 'Separated'
        WHEN MARSTAT = 4 THEN 'Divorced, widowed'
        ELSE 'Unmapped'
    END AS MARITAL_STATUS_LABEL,


    -- --------------------------------------------------------
    -- SMI / SED STATUS
    -- --------------------------------------------------------

    SMISED,

    CASE
        WHEN SMISED IS NULL THEN NULL
        WHEN SMISED = 1 THEN 'SMI'
        WHEN SMISED = 2 THEN 'SED and/or at risk for SED'
        WHEN SMISED = 3 THEN 'Not SMI/SED'
        ELSE 'Unmapped'
    END AS SMISED_LABEL,


    -- --------------------------------------------------------
    -- SUBSTANCE USE
    -- --------------------------------------------------------

    SAP,

    CASE
        WHEN SAP IS NULL THEN NULL
        WHEN SAP = 1 THEN 'Yes'
        WHEN SAP = 2 THEN 'No'
        ELSE 'Unmapped'
    END AS SUBSTANCE_USE_DISORDER_LABEL,

    SUB,

    CASE
        WHEN SUB IS NULL THEN NULL
        WHEN SUB = 1  THEN 'Alcohol induced disorder'
        WHEN SUB = 2  THEN 'Alcohol intoxication'
        WHEN SUB = 3  THEN 'Substance induced disorder'
        WHEN SUB = 4  THEN 'Alcohol dependence'
        WHEN SUB = 5  THEN 'Cocaine dependence'
        WHEN SUB = 6  THEN 'Cannabis dependence'
        WHEN SUB = 7  THEN 'Opioid dependence'
        WHEN SUB = 8  THEN 'Other substance dependence'
        WHEN SUB = 9  THEN 'Alcohol abuse'
        WHEN SUB = 10 THEN 'Cocaine abuse'
        WHEN SUB = 11 THEN 'Cannabis abuse'
        WHEN SUB = 12 THEN 'Opioid abuse'
        WHEN SUB = 13 THEN 'Other substance related conditions'
        ELSE 'Unmapped'
    END AS SUBSTANCE_DIAGNOSIS_LABEL,


    -- --------------------------------------------------------
    -- EMPLOYMENT
    -- --------------------------------------------------------

    EMPLOY,

    CASE
        WHEN EMPLOY IS NULL THEN NULL
        WHEN EMPLOY = 1 THEN 'Full-time'
        WHEN EMPLOY = 2 THEN 'Part-time'
        WHEN EMPLOY = 3 THEN 'Employed full-time/part-time not differentiated'
        WHEN EMPLOY = 4 THEN 'Unemployed'
        WHEN EMPLOY = 5 THEN 'Not in labor force'
        ELSE 'Unmapped'
    END AS EMPLOYMENT_STATUS_LABEL,

    DETNLF,

    CASE
        WHEN DETNLF IS NULL THEN NULL
        WHEN DETNLF = 1 THEN 'Retired, disabled'
        WHEN DETNLF = 2 THEN 'Student'
        WHEN DETNLF = 3 THEN 'Homemaker'
        WHEN DETNLF = 4 THEN 'Sheltered/non-competitive employment'
        WHEN DETNLF = 5 THEN 'Other'
        ELSE 'Unmapped'
    END AS NOT_IN_LABOR_FORCE_LABEL,


    -- --------------------------------------------------------
    -- VETERAN STATUS
    -- --------------------------------------------------------

    VETERAN,

    CASE
        WHEN VETERAN IS NULL THEN NULL
        WHEN VETERAN = 1 THEN 'Yes'
        WHEN VETERAN = 2 THEN 'No'
        ELSE 'Unmapped'
    END AS VETERAN_STATUS_LABEL,


    -- --------------------------------------------------------
    -- LIVING ARRANGEMENT
    -- --------------------------------------------------------

    LIVARAG,

    CASE
        WHEN LIVARAG IS NULL THEN NULL
        WHEN LIVARAG = 1 THEN 'Homeless'
        WHEN LIVARAG = 2 THEN 'Private residence'
        WHEN LIVARAG = 3 THEN 'Other'
        ELSE 'Unmapped'
    END AS LIVING_ARRANGEMENT_LABEL,


    -- --------------------------------------------------------
    -- CLINICAL COMPLEXITY
    -- --------------------------------------------------------

    NUMMHS,


    -- --------------------------------------------------------
    -- ORIGINAL MENTAL HEALTH DIAGNOSIS COLUMNS
    -- --------------------------------------------------------

    MH1,
    MH2,
    MH3,


    -- --------------------------------------------------------
    -- ORIGINAL SERVICE COLUMNS
    -- --------------------------------------------------------

    SPHSERVICE,
    CMPSERVICE,
    OPISERVICE,
    RTCSERVICE,
    IJSSERVICE,


    -- --------------------------------------------------------
    -- DIAGNOSIS FLAGS
    -- --------------------------------------------------------

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


    -- --------------------------------------------------------
    -- GEOGRAPHY KEY
    -- --------------------------------------------------------

    STATEFIP,


    -- --------------------------------------------------------
    -- GOLD METADATA
    -- --------------------------------------------------------

    CURRENT_TIMESTAMP AS CREATE_DATE,

    'silver.mhcld' AS SOURCE_TABLE


FROM silver.mhcld;


-- ============================================================
-- 8. CREATE CLIENT DIAGNOSIS FACT TABLE
--
-- WHY:
-- MH1, MH2, and MH3 store multiple diagnoses horizontally.
--
-- Analytical questions become easier when diagnoses are
-- represented vertically as rows.
--
-- Example:
--
-- MH1 = 7
-- MH2 = 2
-- MH3 = NULL
--
-- becomes:
--
-- YEAR | CASEID | DIAGNOSIS_CODE | POSITION
-- 2024 | 1001   | 7              | 1
-- 2024 | 1001   | 2              | 2
--
-- UNION ALL is used because we want to preserve every
-- diagnosis reported in every position.
-- ============================================================

CREATE TABLE gold.fact_client_diagnosis (

    YEAR INTEGER,
    CASEID BIGINT,
    DIAGNOSIS_CODE INTEGER,
    DIAGNOSIS_POSITION INTEGER,
    CREATE_DATE TIMESTAMP

);


INSERT INTO gold.fact_client_diagnosis (

    YEAR,
    CASEID,
    DIAGNOSIS_CODE,
    DIAGNOSIS_POSITION,
    CREATE_DATE

)

SELECT
    YEAR,
    CASEID,
    MH1 AS DIAGNOSIS_CODE,
    1 AS DIAGNOSIS_POSITION,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE MH1 IS NOT NULL


UNION ALL


SELECT
    YEAR,
    CASEID,
    MH2 AS DIAGNOSIS_CODE,
    2 AS DIAGNOSIS_POSITION,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE MH2 IS NOT NULL


UNION ALL


SELECT
    YEAR,
    CASEID,
    MH3 AS DIAGNOSIS_CODE,
    3 AS DIAGNOSIS_POSITION,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE MH3 IS NOT NULL;


-- ============================================================
-- 9. CREATE CLIENT SERVICE FACT TABLE
--
-- WHY:
-- The source stores five service types as separate columns.
--
-- Convert services received into rows.
-- ============================================================

CREATE TABLE gold.fact_client_service (

    YEAR INTEGER,
    CASEID BIGINT,
    SERVICE_CODE VARCHAR(3),
    CREATE_DATE TIMESTAMP

);


INSERT INTO gold.fact_client_service (

    YEAR,
    CASEID,
    SERVICE_CODE,
    CREATE_DATE

)

SELECT
    YEAR,
    CASEID,
    'SPH' AS SERVICE_CODE,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE SPHSERVICE = 1


UNION ALL


SELECT
    YEAR,
    CASEID,
    'CMP' AS SERVICE_CODE,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE CMPSERVICE = 1


UNION ALL


SELECT
    YEAR,
    CASEID,
    'OPI' AS SERVICE_CODE,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE OPISERVICE = 1


UNION ALL


SELECT
    YEAR,
    CASEID,
    'RTC' AS SERVICE_CODE,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE RTCSERVICE = 1


UNION ALL


SELECT
    YEAR,
    CASEID,
    'IJS' AS SERVICE_CODE,
    CURRENT_TIMESTAMP AS CREATE_DATE

FROM gold.fact_client_year

WHERE IJSSERVICE = 1;

-- ============================================================
-- 10. GOLD TABLE SUMMARY
--
-- WHY:
-- Shows what the Gold build actually produced.
-- ============================================================

SELECT
    'fact_client_year' AS table_name,
    COUNT(*) AS total_rows
FROM gold.fact_client_year

UNION ALL

SELECT
    'fact_client_diagnosis',
    COUNT(*)
FROM gold.fact_client_diagnosis

UNION ALL

SELECT
    'fact_client_service',
    COUNT(*)
FROM gold.fact_client_service

UNION ALL

SELECT
    'dim_geography',
    COUNT(*)
FROM gold.dim_geography

UNION ALL

SELECT
    'dim_diagnosis',
    COUNT(*)
FROM gold.dim_diagnosis

UNION ALL

SELECT
    'dim_service',
    COUNT(*)
FROM gold.dim_service;


-- ============================================================
-- 11. GOLD BUILD SUMMARY
-- ============================================================

SELECT

    COUNT(*) AS total_client_records,

    COUNT(DISTINCT YEAR) AS years_loaded,

    MIN(YEAR) AS earliest_year,

    MAX(YEAR) AS latest_year,

    COUNT(DISTINCT STATEFIP) AS reporting_geographies,

    MAX(CREATE_DATE) AS gold_load_timestamp

FROM gold.fact_client_year;
