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
--   * Produce a final gld build summary
--
-- PORTABILITY NOTE:
--   DuckDB is used as the reference database for this project.
--   ATTACH / USE and schema creation may need to be adapted
--   when using another SQL platform.
--
--   TIMESTAMP is appropriate for DuckDB and PostgreSQL.
--   SQL Server should use DATETIME for CREATE_DATE columns.
-- ============================================================


-- ============================================================
-- 1. CREATE / OPEN DATABASE
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
-- Gold is fully reproducible from Silver.
--
-- Views are dropped first because they depend on tables.
-- Bridge tables are dropped before the central fact table.
-- Dimension tables are dropped last.
-- ============================================================

DROP VIEW IF EXISTS gold.vw_client_service_analysis;
DROP VIEW IF EXISTS gold.vw_client_diagnosis_flag_analysis;
DROP VIEW IF EXISTS gold.vw_client_diagnosis_analysis;
DROP VIEW IF EXISTS gold.vw_client_year_analysis;

DROP TABLE IF EXISTS gold.bridge_client_service;
DROP TABLE IF EXISTS gold.bridge_client_diagnosis_flag;
DROP TABLE IF EXISTS gold.bridge_client_diagnosis;
DROP TABLE IF EXISTS gold.fact_client_year;

DROP TABLE IF EXISTS gold.dim_living_arrangement;
DROP TABLE IF EXISTS gold.dim_veteran_status;
DROP TABLE IF EXISTS gold.dim_not_in_labor_force;
DROP TABLE IF EXISTS gold.dim_employment_status;
DROP TABLE IF EXISTS gold.dim_substance_diagnosis;
DROP TABLE IF EXISTS gold.dim_substance_use_status;
DROP TABLE IF EXISTS gold.dim_smised_status;
DROP TABLE IF EXISTS gold.dim_marital_status;
DROP TABLE IF EXISTS gold.dim_sex;
DROP TABLE IF EXISTS gold.dim_race;
DROP TABLE IF EXISTS gold.dim_ethnicity;
DROP TABLE IF EXISTS gold.dim_education;
DROP TABLE IF EXISTS gold.dim_age;
DROP TABLE IF EXISTS gold.dim_service;
DROP TABLE IF EXISTS gold.dim_diagnosis;
DROP TABLE IF EXISTS gold.dim_geography;




-- ============================================================
-- 4. CREATE AGE DIMENSION
-- ============================================================

CREATE TABLE gold.dim_age (

    AGE_CODE INTEGER,
    AGE_GROUP VARCHAR(30),
    AGE_MIN_YEARS INTEGER,
    AGE_MAX_YEARS INTEGER,
    AGE_SORT_ORDER INTEGER

);

INSERT INTO gold.dim_age
    (AGE_CODE, AGE_GROUP, AGE_MIN_YEARS, AGE_MAX_YEARS, AGE_SORT_ORDER)
VALUES
    (1,  '0-11 years',        0,  11,  1),
    (2,  '12-14 years',      12,  14,  2),
    (3,  '15-17 years',      15,  17,  3),
    (4,  '18-20 years',      18,  20,  4),
    (5,  '21-24 years',      21,  24,  5),
    (6,  '25-29 years',      25,  29,  6),
    (7,  '30-34 years',      30,  34,  7),
    (8,  '35-39 years',      35,  39,  8),
    (9,  '40-44 years',      40,  44,  9),
    (10, '45-49 years',      45,  49, 10),
    (11, '50-54 years',      50,  54, 11),
    (12, '55-59 years',      55,  59, 12),
    (13, '60-64 years',      60,  64, 13),
    (14, '65 years and older', 65, NULL, 14);


-- ============================================================
-- 5. CREATE DEMOGRAPHIC DIMENSIONS
-- ============================================================

CREATE TABLE gold.dim_education (

    EDUCATION_CODE INTEGER,
    EDUCATION_LABEL VARCHAR(50),
    EDUCATION_SORT_ORDER INTEGER

);

INSERT INTO gold.dim_education
    (EDUCATION_CODE, EDUCATION_LABEL, EDUCATION_SORT_ORDER)
VALUES
    (1, 'Special education', 1),
    (2, '0 to 8',            2),
    (3, '9 to 11',           3),
    (4, '12 or GED',         4),
    (5, 'More than 12',      5);


CREATE TABLE gold.dim_ethnicity (

    ETHNICITY_CODE INTEGER,
    ETHNICITY_LABEL VARCHAR(50)

);

INSERT INTO gold.dim_ethnicity
    (ETHNICITY_CODE, ETHNICITY_LABEL)
VALUES
    (1, 'Mexican'),
    (2, 'Puerto Rican'),
    (3, 'Other Hispanic or Latino origin'),
    (4, 'Not of Hispanic or Latino origin');


CREATE TABLE gold.dim_race (

    RACE_CODE INTEGER,
    RACE_LABEL VARCHAR(60)

);

INSERT INTO gold.dim_race
    (RACE_CODE, RACE_LABEL)
VALUES
    (1, 'American Indian/Alaska Native'),
    (2, 'Asian'),
    (3, 'Black or African American'),
    (4, 'Native Hawaiian or Other Pacific Islander'),
    (5, 'White'),
    (6, 'Some other race alone/two or more races');


CREATE TABLE gold.dim_sex (

    SEX_CODE INTEGER,
    SEX_LABEL VARCHAR(20)

);

INSERT INTO gold.dim_sex
    (SEX_CODE, SEX_LABEL)
VALUES
    (1, 'Male'),
    (2, 'Female');


CREATE TABLE gold.dim_marital_status (

    MARITAL_STATUS_CODE INTEGER,
    MARITAL_STATUS_LABEL VARCHAR(30)

);

INSERT INTO gold.dim_marital_status
    (MARITAL_STATUS_CODE, MARITAL_STATUS_LABEL)
VALUES
    (1, 'Never married'),
    (2, 'Now married'),
    (3, 'Separated'),
    (4, 'Divorced, widowed');


-- ============================================================
-- 6. CREATE CLINICAL AND SOCIAL DIMENSIONS
-- ============================================================

CREATE TABLE gold.dim_smised_status (

    SMISED_CODE INTEGER,
    SMISED_LABEL VARCHAR(50)

);

INSERT INTO gold.dim_smised_status
    (SMISED_CODE, SMISED_LABEL)
VALUES
    (1, 'SMI'),
    (2, 'SED and/or at risk for SED'),
    (3, 'Not SMI/SED');


CREATE TABLE gold.dim_substance_use_status (

    SUBSTANCE_USE_STATUS_CODE INTEGER,
    SUBSTANCE_USE_DISORDER_LABEL VARCHAR(20)

);

INSERT INTO gold.dim_substance_use_status
    (SUBSTANCE_USE_STATUS_CODE, SUBSTANCE_USE_DISORDER_LABEL)
VALUES
    (1, 'Yes'),
    (2, 'No');


CREATE TABLE gold.dim_substance_diagnosis (

    SUBSTANCE_DIAGNOSIS_CODE INTEGER,
    SUBSTANCE_DIAGNOSIS_LABEL VARCHAR(60)

);

INSERT INTO gold.dim_substance_diagnosis
    (SUBSTANCE_DIAGNOSIS_CODE, SUBSTANCE_DIAGNOSIS_LABEL)
VALUES
    (1,  'Alcohol induced disorder'),
    (2,  'Alcohol intoxication'),
    (3,  'Substance induced disorder'),
    (4,  'Alcohol dependence'),
    (5,  'Cocaine dependence'),
    (6,  'Cannabis dependence'),
    (7,  'Opioid dependence'),
    (8,  'Other substance dependence'),
    (9,  'Alcohol abuse'),
    (10, 'Cocaine abuse'),
    (11, 'Cannabis abuse'),
    (12, 'Opioid abuse'),
    (13, 'Other substance related conditions');


CREATE TABLE gold.dim_employment_status (

    EMPLOYMENT_STATUS_CODE INTEGER,
    EMPLOYMENT_STATUS_LABEL VARCHAR(100)

);

INSERT INTO gold.dim_employment_status
    (EMPLOYMENT_STATUS_CODE, EMPLOYMENT_STATUS_LABEL)
VALUES
    (1, 'Full-time'),
    (2, 'Part-time'),
    (3, 'Employed full-time/part-time not differentiated'),
    (4, 'Unemployed'),
    (5, 'Not in labor force');


CREATE TABLE gold.dim_not_in_labor_force (

    NOT_IN_LABOR_FORCE_CODE INTEGER,
    NOT_IN_LABOR_FORCE_LABEL VARCHAR(100)

);

INSERT INTO gold.dim_not_in_labor_force
    (NOT_IN_LABOR_FORCE_CODE, NOT_IN_LABOR_FORCE_LABEL)
VALUES
    (1, 'Retired, disabled'),
    (2, 'Student'),
    (3, 'Homemaker'),
    (4, 'Sheltered/non-competitive employment'),
    (5, 'Other');


CREATE TABLE gold.dim_veteran_status (

    VETERAN_STATUS_CODE INTEGER,
    VETERAN_STATUS_LABEL VARCHAR(20)

);

INSERT INTO gold.dim_veteran_status
    (VETERAN_STATUS_CODE, VETERAN_STATUS_LABEL)
VALUES
    (1, 'Yes'),
    (2, 'No');


CREATE TABLE gold.dim_living_arrangement (

    LIVING_ARRANGEMENT_CODE INTEGER,
    LIVING_ARRANGEMENT_LABEL VARCHAR(30)

);

INSERT INTO gold.dim_living_arrangement
    (LIVING_ARRANGEMENT_CODE, LIVING_ARRANGEMENT_LABEL)
VALUES
    (1, 'Homeless'),
    (2, 'Private residence'),
    (3, 'Other');


-- ============================================================
-- 7. CREATE GEOGRAPHY DIMENSION
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
    END AS STATE_NAME,

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
    END AS DIVISION_NAME,

    REGION,

    CASE
        WHEN REGION IS NULL THEN NULL
        WHEN REGION = 0 THEN 'Other jurisdictions'
        WHEN REGION = 1 THEN 'Northeast'
        WHEN REGION = 2 THEN 'Midwest'
        WHEN REGION = 3 THEN 'South'
        WHEN REGION = 4 THEN 'West'
        ELSE 'Unmapped'
    END AS REGION_NAME

FROM silver.mhcld
WHERE STATEFIP IS NOT NULL;


-- ============================================================
-- 8. CREATE DIAGNOSIS DIMENSION
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
-- 9. CREATE SERVICE DIMENSION
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
-- 10. CREATE CENTRAL CLIENT YEAR FACT TABLE
--
-- GRAIN:
--   One record = one MH-CLD client record for one reporting year.
--
-- DESIGN:
--   This table stores dimensional keys and measures.
--   Repeated descriptive labels are intentionally kept in
--   dimension tables instead of being repeated here.
-- ============================================================

CREATE TABLE gold.fact_client_year (

    YEAR INTEGER,
    CASEID BIGINT,

    AGE_CODE INTEGER,
    EDUCATION_CODE INTEGER,
    ETHNICITY_CODE INTEGER,
    RACE_CODE INTEGER,
    SEX_CODE INTEGER,
    MARITAL_STATUS_CODE INTEGER,

    SMISED_CODE INTEGER,
    SUBSTANCE_USE_STATUS_CODE INTEGER,
    SUBSTANCE_DIAGNOSIS_CODE INTEGER,
    EMPLOYMENT_STATUS_CODE INTEGER,
    NOT_IN_LABOR_FORCE_CODE INTEGER,
    VETERAN_STATUS_CODE INTEGER,
    LIVING_ARRANGEMENT_CODE INTEGER,

    STATEFIP INTEGER,

    NUM_MENTAL_HEALTH_DIAGNOSES INTEGER,
    CLIENT_RECORD_COUNT INTEGER,

    CREATE_DATE TIMESTAMP,
    SOURCE_TABLE VARCHAR(100)

);

INSERT INTO gold.fact_client_year (
    YEAR,
    CASEID,
    AGE_CODE,
    EDUCATION_CODE,
    ETHNICITY_CODE,
    RACE_CODE,
    SEX_CODE,
    MARITAL_STATUS_CODE,
    SMISED_CODE,
    SUBSTANCE_USE_STATUS_CODE,
    SUBSTANCE_DIAGNOSIS_CODE,
    EMPLOYMENT_STATUS_CODE,
    NOT_IN_LABOR_FORCE_CODE,
    VETERAN_STATUS_CODE,
    LIVING_ARRANGEMENT_CODE,
    STATEFIP,
    NUM_MENTAL_HEALTH_DIAGNOSES,
    CLIENT_RECORD_COUNT,
    CREATE_DATE,
    SOURCE_TABLE
)
SELECT
    YEAR,
    CASEID,
    AGE AS AGE_CODE,
    EDUC AS EDUCATION_CODE,
    ETHNIC AS ETHNICITY_CODE,
    RACE AS RACE_CODE,
    SEX AS SEX_CODE,
    MARSTAT AS MARITAL_STATUS_CODE,
    SMISED AS SMISED_CODE,
    SAP AS SUBSTANCE_USE_STATUS_CODE,
    SUB AS SUBSTANCE_DIAGNOSIS_CODE,
    EMPLOY AS EMPLOYMENT_STATUS_CODE,
    DETNLF AS NOT_IN_LABOR_FORCE_CODE,
    VETERAN AS VETERAN_STATUS_CODE,
    LIVARAG AS LIVING_ARRANGEMENT_CODE,
    STATEFIP,
    NUMMHS AS NUM_MENTAL_HEALTH_DIAGNOSES,
    1 AS CLIENT_RECORD_COUNT,
    CURRENT_TIMESTAMP AS CREATE_DATE,
    'silver.mhcld' AS SOURCE_TABLE
FROM silver.mhcld;


-- ============================================================
-- 12. CREATE CLIENT DIAGNOSIS BRIDGE TABLE
--
-- WHY:
-- MH1, MH2, and MH3 store diagnoses horizontally in slver.
-- The bridge converts them into rows so each client year can
-- connect to multiple diagnosis dimension rows.
--
-- GRAIN:
--   One record = one diagnosis position for one client year.
-- ============================================================

CREATE TABLE gold.bridge_client_diagnosis (

    YEAR INTEGER,
    CASEID BIGINT,
    DIAGNOSIS_CODE INTEGER,
    DIAGNOSIS_POSITION INTEGER,
    DIAGNOSIS_COUNT INTEGER,
    CREATE_DATE TIMESTAMP

);

INSERT INTO gold.bridge_client_diagnosis (
    YEAR,
    CASEID,
    DIAGNOSIS_CODE,
    DIAGNOSIS_POSITION,
    DIAGNOSIS_COUNT,
    CREATE_DATE
)
SELECT
    YEAR,
    CASEID,
    MH1 AS DIAGNOSIS_CODE,
    1 AS DIAGNOSIS_POSITION,
    1 AS DIAGNOSIS_COUNT,
    CURRENT_TIMESTAMP AS CREATE_DATE
FROM silver.mhcld
WHERE MH1 IS NOT NULL

UNION ALL

SELECT
    YEAR,
    CASEID,
    MH2 AS DIAGNOSIS_CODE,
    2 AS DIAGNOSIS_POSITION,
    1 AS DIAGNOSIS_COUNT,
    CURRENT_TIMESTAMP AS CREATE_DATE
FROM silver.mhcld
WHERE MH2 IS NOT NULL

UNION ALL

SELECT
    YEAR,
    CASEID,
    MH3 AS DIAGNOSIS_CODE,
    3 AS DIAGNOSIS_POSITION,
    1 AS DIAGNOSIS_COUNT,
    CURRENT_TIMESTAMP AS CREATE_DATE
FROM silver.mhcld
WHERE MH3 IS NOT NULL;


-- ============================================================
-- 13. CREATE CLIENT DIAGNOSIS FLAG BRIDGE TABLE
--
-- WHY:
-- The source includes diagnosis flag columns such as ANXIETYFLG,
-- DEPRESSFLG, and SCHIZOFLG. Keeping these as wide columns makes
-- analysis harder as more conditions are compared.
--
-- This bridge converts each active flag into one row so analysts
-- can group, filter, and trend flags through dim_diagnosis.
--
-- GRAIN:
--   One record = one active diagnosis flag for one client year.
-- ============================================================

CREATE TABLE gold.bridge_client_diagnosis_flag (

    YEAR INTEGER,
    CASEID BIGINT,
    DIAGNOSIS_CODE INTEGER,
    DIAGNOSIS_FLAG_COUNT INTEGER,
    CREATE_DATE TIMESTAMP

);

INSERT INTO gold.bridge_client_diagnosis_flag (
    YEAR,
    CASEID,
    DIAGNOSIS_CODE,
    DIAGNOSIS_FLAG_COUNT,
    CREATE_DATE
)
SELECT YEAR, CASEID, 1,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE TRAUSTREFLG = 1
UNION ALL
SELECT YEAR, CASEID, 2,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE ANXIETYFLG = 1
UNION ALL
SELECT YEAR, CASEID, 3,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE ADHDFLG = 1
UNION ALL
SELECT YEAR, CASEID, 4,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE CONDUCTFLG = 1
UNION ALL
SELECT YEAR, CASEID, 5,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE DELIRDEMFLG = 1
UNION ALL
SELECT YEAR, CASEID, 6,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE BIPOLARFLG = 1
UNION ALL
SELECT YEAR, CASEID, 7,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE DEPRESSFLG = 1
UNION ALL
SELECT YEAR, CASEID, 8,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE ODDFLG = 1
UNION ALL
SELECT YEAR, CASEID, 9,  1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE PDDFLG = 1
UNION ALL
SELECT YEAR, CASEID, 10, 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE PERSONFLG = 1
UNION ALL
SELECT YEAR, CASEID, 11, 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE SCHIZOFLG = 1
UNION ALL
SELECT YEAR, CASEID, 12, 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE ALCSUBFLG = 1
UNION ALL
SELECT YEAR, CASEID, 13, 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE OTHERDISFLG = 1;


-- ============================================================
-- 14. CREATE CLIENT SERVICE BRIDGE TABLE
--
-- WHY:
-- The source stores service participation across five columns.
-- This bridge converts each received service into a row.
--
-- GRAIN:
--   One record = one service received by one client-year.
-- ============================================================

CREATE TABLE gold.bridge_client_service (

    YEAR INTEGER,
    CASEID BIGINT,
    SERVICE_CODE VARCHAR(3),
    SERVICE_COUNT INTEGER,
    CREATE_DATE TIMESTAMP

);

INSERT INTO gold.bridge_client_service (
    YEAR,
    CASEID,
    SERVICE_CODE,
    SERVICE_COUNT,
    CREATE_DATE
)
SELECT YEAR, CASEID, 'SPH', 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE SPHSERVICE = 1
UNION ALL
SELECT YEAR, CASEID, 'CMP', 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE CMPSERVICE = 1
UNION ALL
SELECT YEAR, CASEID, 'OPI', 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE OPISERVICE = 1
UNION ALL
SELECT YEAR, CASEID, 'RTC', 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE RTCSERVICE = 1
UNION ALL
SELECT YEAR, CASEID, 'IJS', 1, CURRENT_TIMESTAMP FROM silver.mhcld WHERE IJSSERVICE = 1;


-- ============================================================
-- 15. CREATE ANALYST VIEWS
--
-- WHY:
-- The base model is dimensional. These views reattach readable
-- labels for quick querying and dashboard development.
-- ============================================================

CREATE VIEW gold.vw_client_year_analysis AS
SELECT
    f.YEAR,
    f.CASEID,

    f.AGE_CODE,
    age_dim.AGE_GROUP,

    f.EDUCATION_CODE,
    education_dim.EDUCATION_LABEL,

    f.ETHNICITY_CODE,
    ethnicity_dim.ETHNICITY_LABEL,

    f.RACE_CODE,
    race_dim.RACE_LABEL,

    f.SEX_CODE,
    sex_dim.SEX_LABEL,

    f.MARITAL_STATUS_CODE,
    marital_status_dim.MARITAL_STATUS_LABEL,

    f.SMISED_CODE,
    smised_dim.SMISED_LABEL,

    f.SUBSTANCE_USE_STATUS_CODE,
    substance_use_dim.SUBSTANCE_USE_DISORDER_LABEL,

    f.SUBSTANCE_DIAGNOSIS_CODE,
    substance_diagnosis_dim.SUBSTANCE_DIAGNOSIS_LABEL,

    f.EMPLOYMENT_STATUS_CODE,
    employment_dim.EMPLOYMENT_STATUS_LABEL,

    f.NOT_IN_LABOR_FORCE_CODE,
    not_in_labor_force_dim.NOT_IN_LABOR_FORCE_LABEL,

    f.VETERAN_STATUS_CODE,
    veteran_dim.VETERAN_STATUS_LABEL,

    f.LIVING_ARRANGEMENT_CODE,
    living_arrangement_dim.LIVING_ARRANGEMENT_LABEL,

    f.STATEFIP,
    geography_dim.STATE_NAME,
    geography_dim.DIVISION,
    geography_dim.DIVISION_NAME,
    geography_dim.REGION,
    geography_dim.REGION_NAME,

    f.NUM_MENTAL_HEALTH_DIAGNOSES,
    f.CLIENT_RECORD_COUNT,
    f.CREATE_DATE,
    f.SOURCE_TABLE

FROM gold.fact_client_year AS f

LEFT JOIN gold.dim_age AS age_dim
    ON f.AGE_CODE = age_dim.AGE_CODE

LEFT JOIN gold.dim_education AS education_dim
    ON f.EDUCATION_CODE = education_dim.EDUCATION_CODE

LEFT JOIN gold.dim_ethnicity AS ethnicity_dim
    ON f.ETHNICITY_CODE = ethnicity_dim.ETHNICITY_CODE

LEFT JOIN gold.dim_race AS race_dim
    ON f.RACE_CODE = race_dim.RACE_CODE

LEFT JOIN gold.dim_sex AS sex_dim
    ON f.SEX_CODE = sex_dim.SEX_CODE

LEFT JOIN gold.dim_marital_status AS marital_status_dim
    ON f.MARITAL_STATUS_CODE = marital_status_dim.MARITAL_STATUS_CODE

LEFT JOIN gold.dim_smised_status AS smised_dim
    ON f.SMISED_CODE = smised_dim.SMISED_CODE

LEFT JOIN gold.dim_substance_use_status AS substance_use_dim
    ON f.SUBSTANCE_USE_STATUS_CODE = substance_use_dim.SUBSTANCE_USE_STATUS_CODE

LEFT JOIN gold.dim_substance_diagnosis AS substance_diagnosis_dim
    ON f.SUBSTANCE_DIAGNOSIS_CODE = substance_diagnosis_dim.SUBSTANCE_DIAGNOSIS_CODE

LEFT JOIN gold.dim_employment_status AS employment_dim
    ON f.EMPLOYMENT_STATUS_CODE = employment_dim.EMPLOYMENT_STATUS_CODE

LEFT JOIN gold.dim_not_in_labor_force AS not_in_labor_force_dim
    ON f.NOT_IN_LABOR_FORCE_CODE = not_in_labor_force_dim.NOT_IN_LABOR_FORCE_CODE

LEFT JOIN gold.dim_veteran_status AS veteran_dim
    ON f.VETERAN_STATUS_CODE = veteran_dim.VETERAN_STATUS_CODE

LEFT JOIN gold.dim_living_arrangement AS living_arrangement_dim
    ON f.LIVING_ARRANGEMENT_CODE = living_arrangement_dim.LIVING_ARRANGEMENT_CODE

LEFT JOIN gold.dim_geography AS geography_dim
    ON f.STATEFIP = geography_dim.STATEFIP;


CREATE VIEW gold.vw_client_diagnosis_analysis AS
SELECT
    d.YEAR,
    d.CASEID,
    d.DIAGNOSIS_CODE,
    diagnosis_dim.DIAGNOSIS_NAME,
    d.DIAGNOSIS_POSITION,
    d.DIAGNOSIS_COUNT,
    d.CREATE_DATE
FROM gold.bridge_client_diagnosis AS d
LEFT JOIN gold.dim_diagnosis AS diagnosis_dim
    ON d.DIAGNOSIS_CODE = diagnosis_dim.DIAGNOSIS_CODE;


CREATE VIEW gold.vw_client_diagnosis_flag_analysis AS
SELECT
    df.YEAR,
    df.CASEID,
    df.DIAGNOSIS_CODE,
    diagnosis_dim.DIAGNOSIS_NAME,
    df.DIAGNOSIS_FLAG_COUNT,
    df.CREATE_DATE
FROM gold.bridge_client_diagnosis_flag AS df
LEFT JOIN gold.dim_diagnosis AS diagnosis_dim
    ON df.DIAGNOSIS_CODE = diagnosis_dim.DIAGNOSIS_CODE;


CREATE VIEW gold.vw_client_service_analysis AS
SELECT
    s.YEAR,
    s.CASEID,
    s.SERVICE_CODE,
    service_dim.SERVICE_NAME,
    s.SERVICE_COUNT,
    s.CREATE_DATE
FROM gold.bridge_client_service AS s
LEFT JOIN gold.dim_service AS service_dim
    ON s.SERVICE_CODE = service_dim.SERVICE_CODE;


-- ============================================================
-- 16. GOLD TABLE SUMMARY
-- ============================================================

SELECT
    'fact_client_year' AS table_name,
    COUNT(*) AS total_rows
FROM gold.fact_client_year

UNION ALL

SELECT
    'bridge_client_diagnosis',
    COUNT(*)
FROM gold.bridge_client_diagnosis

UNION ALL

SELECT
    'bridge_client_diagnosis_flag',
    COUNT(*)
FROM gold.bridge_client_diagnosis_flag

UNION ALL

SELECT
    'bridge_client_service',
    COUNT(*)
FROM gold.bridge_client_service

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
FROM gold.dim_service

UNION ALL

SELECT
    'dim_age',
    COUNT(*)
FROM gold.dim_age

UNION ALL

SELECT
    'dim_education',
    COUNT(*)
FROM gold.dim_education

UNION ALL

SELECT
    'dim_ethnicity',
    COUNT(*)
FROM gold.dim_ethnicity

UNION ALL

SELECT
    'dim_race',
    COUNT(*)
FROM gold.dim_race

UNION ALL

SELECT
    'dim_sex',
    COUNT(*)
FROM gold.dim_sex

UNION ALL

SELECT
    'dim_marital_status',
    COUNT(*)
FROM gold.dim_marital_status

UNION ALL

SELECT
    'dim_smised_status',
    COUNT(*)
FROM gold.dim_smised_status

UNION ALL

SELECT
    'dim_substance_use_status',
    COUNT(*)
FROM gold.dim_substance_use_status

UNION ALL

SELECT
    'dim_substance_diagnosis',
    COUNT(*)
FROM gold.dim_substance_diagnosis

UNION ALL

SELECT
    'dim_employment_status',
    COUNT(*)
FROM gold.dim_employment_status

UNION ALL

SELECT
    'dim_not_in_labor_force',
    COUNT(*)
FROM gold.dim_not_in_labor_force

UNION ALL

SELECT
    'dim_veteran_status',
    COUNT(*)
FROM gold.dim_veteran_status

UNION ALL

SELECT
    'dim_living_arrangement',
    COUNT(*)
FROM gold.dim_living_arrangement;


-- ============================================================
-- 17. GOLD BUILD SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_client_year_records,
    SUM(CLIENT_RECORD_COUNT) AS total_client_record_count,
    COUNT(DISTINCT YEAR) AS years_loaded,
    MIN(YEAR) AS earliest_year,
    MAX(YEAR) AS latest_year,
    COUNT(DISTINCT STATEFIP) AS reporting_geographies,
    MAX(CREATE_DATE) AS gold_load_timestamp
FROM gold.fact_client_year;


-- ============================================================
-- 18. GOLD DIMENSION KEY VALIDATION
--
-- WHY:
-- These checks identify fact records with coded values that do
-- not match a Gold dimension row. Nonzero counts mean either a
-- source code was not mapped or the source documentation needs
-- to be reviewed.
-- ============================================================

SELECT
    'age_unmatched_dimension_key' AS validation_check,
    COUNT(*) AS issue_count
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_age AS d
    ON f.AGE_CODE = d.AGE_CODE
WHERE f.AGE_CODE IS NOT NULL
  AND d.AGE_CODE IS NULL

UNION ALL

SELECT
    'education_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_education AS d
    ON f.EDUCATION_CODE = d.EDUCATION_CODE
WHERE f.EDUCATION_CODE IS NOT NULL
  AND d.EDUCATION_CODE IS NULL

UNION ALL

SELECT
    'ethnicity_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_ethnicity AS d
    ON f.ETHNICITY_CODE = d.ETHNICITY_CODE
WHERE f.ETHNICITY_CODE IS NOT NULL
  AND d.ETHNICITY_CODE IS NULL

UNION ALL

SELECT
    'race_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_race AS d
    ON f.RACE_CODE = d.RACE_CODE
WHERE f.RACE_CODE IS NOT NULL
  AND d.RACE_CODE IS NULL

UNION ALL

SELECT
    'sex_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_sex AS d
    ON f.SEX_CODE = d.SEX_CODE
WHERE f.SEX_CODE IS NOT NULL
  AND d.SEX_CODE IS NULL

UNION ALL

SELECT
    'marital_status_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_marital_status AS d
    ON f.MARITAL_STATUS_CODE = d.MARITAL_STATUS_CODE
WHERE f.MARITAL_STATUS_CODE IS NOT NULL
  AND d.MARITAL_STATUS_CODE IS NULL

UNION ALL

SELECT
    'smised_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_smised_status AS d
    ON f.SMISED_CODE = d.SMISED_CODE
WHERE f.SMISED_CODE IS NOT NULL
  AND d.SMISED_CODE IS NULL

UNION ALL

SELECT
    'substance_use_status_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_substance_use_status AS d
    ON f.SUBSTANCE_USE_STATUS_CODE = d.SUBSTANCE_USE_STATUS_CODE
WHERE f.SUBSTANCE_USE_STATUS_CODE IS NOT NULL
  AND d.SUBSTANCE_USE_STATUS_CODE IS NULL

UNION ALL

SELECT
    'substance_diagnosis_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_substance_diagnosis AS d
    ON f.SUBSTANCE_DIAGNOSIS_CODE = d.SUBSTANCE_DIAGNOSIS_CODE
WHERE f.SUBSTANCE_DIAGNOSIS_CODE IS NOT NULL
  AND d.SUBSTANCE_DIAGNOSIS_CODE IS NULL

UNION ALL

SELECT
    'employment_status_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_employment_status AS d
    ON f.EMPLOYMENT_STATUS_CODE = d.EMPLOYMENT_STATUS_CODE
WHERE f.EMPLOYMENT_STATUS_CODE IS NOT NULL
  AND d.EMPLOYMENT_STATUS_CODE IS NULL

UNION ALL

SELECT
    'not_in_labor_force_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_not_in_labor_force AS d
    ON f.NOT_IN_LABOR_FORCE_CODE = d.NOT_IN_LABOR_FORCE_CODE
WHERE f.NOT_IN_LABOR_FORCE_CODE IS NOT NULL
  AND d.NOT_IN_LABOR_FORCE_CODE IS NULL

UNION ALL

SELECT
    'veteran_status_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_veteran_status AS d
    ON f.VETERAN_STATUS_CODE = d.VETERAN_STATUS_CODE
WHERE f.VETERAN_STATUS_CODE IS NOT NULL
  AND d.VETERAN_STATUS_CODE IS NULL

UNION ALL

SELECT
    'living_arrangement_unmatched_dimension_key',
    COUNT(*)
FROM gold.fact_client_year AS f
LEFT JOIN gold.dim_living_arrangement AS d
    ON f.LIVING_ARRANGEMENT_CODE = d.LIVING_ARRANGEMENT_CODE
WHERE f.LIVING_ARRANGEMENT_CODE IS NOT NULL
  AND d.LIVING_ARRANGEMENT_CODE IS NULL;
