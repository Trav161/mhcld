-- ============================================================
-- GOLD ANALYSIS READY VIEWS
--
-- PURPOSE:
-- These views sit on top of the Gold dimensional model.
-- They do not replace the fact, dimension, or bridge tables.
-- Instead, they make the model easier to query by reattaching
-- readable labels and preserving the intended analytical meaning
-- of each structure.
-- ============================================================

DROP VIEW IF EXISTS gold.vw_client_diagnosis_all_analysis;
DROP VIEW IF EXISTS gold.vw_client_diagnosis_all;
DROP VIEW IF EXISTS gold.vw_client_service_analysis;
DROP VIEW IF EXISTS gold.vw_client_diagnosis_flag_analysis;
DROP VIEW IF EXISTS gold.vw_client_diagnosis_analysis;
DROP VIEW IF EXISTS gold.vw_client_year_analysis;

-- ============================================================
-- VIEW: gold.vw_client_year_analysis
--
-- PURPOSE:
-- Provides one readable client year record by joining the main
-- fact table to demographic, clinical, social, and geography
-- dimensions.
--
-- USE WHEN:
-- Analyzing client counts by age, race, sex, region, employment,
-- veteran status, living arrangement, or other client attributes.
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

-- ============================================================
-- VIEW: gold.vw_client_diagnosis_analysis
--
-- PURPOSE:
-- Provides readable diagnosis records from the positional diagnosis
-- bridge while preserving whether the diagnosis came from MH1, MH2,
-- or MH3.
--
-- USE WHEN:
-- Analyzing diagnosis position, primary/secondary/tertiary diagnosis
-- patterns, or diagnosis records where placement matters.
-- ============================================================
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

-- ============================================================
-- VIEW: gold.vw_client_diagnosis_flag_analysis
--
-- PURPOSE:
-- Provides readable diagnosis flag records showing whether a diagnosis
-- category was reported for a client year record.
--
-- USE WHEN:
-- Counting diagnosis category presence without caring about MH1, MH2,
-- or MH3 position.
-- ============================================================

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

-- ============================================================
-- VIEW: gold.vw_client_diagnosis_all
--
-- PURPOSE:
-- Combines positional diagnoses and diagnosis flags into one shared
-- diagnosis stream while preserving the source type.
--
-- USE WHEN:
-- Comparing diagnosis structures or validating whether MH1/MH2/MH3
-- align with diagnosis flag fields.
--
-- NOTE:
-- This view should not be used as the default diagnosis count because
-- positional diagnoses and flags can overlap.
-- ============================================================
CREATE VIEW gold.vw_client_diagnosis_all AS
SELECT
    YEAR,
    CASEID,
    DIAGNOSIS_CODE,
    DIAGNOSIS_POSITION,
    'POSITIONAL' AS DIAGNOSIS_SOURCE,
    DIAGNOSIS_COUNT AS DIAGNOSIS_RECORD_COUNT,
    CREATE_DATE
FROM gold.bridge_client_diagnosis

UNION ALL

SELECT
    YEAR,
    CASEID,
    DIAGNOSIS_CODE,
    NULL AS DIAGNOSIS_POSITION,
    'FLAG' AS DIAGNOSIS_SOURCE,
    DIAGNOSIS_FLAG_COUNT AS DIAGNOSIS_RECORD_COUNT,
    CREATE_DATE
FROM gold.bridge_client_diagnosis_flag;

-- ============================================================
-- VIEW: gold.vw_client_diagnosis_all_analysis
--
-- PURPOSE:
-- Adds readable diagnosis names to the combined diagnosis comparison
-- view.
--
-- USE WHEN:
-- Performing QA or comparison checks between positional diagnoses and
-- diagnosis flags.
--
-- NOTE:
-- Use this for validation and comparison, not default prevalence counts.
-- For prevalence counts, use vw_client_diagnosis_flag_analysis.
-- For diagnosis position analysis, use vw_client_diagnosis_analysis.
-- ============================================================
CREATE VIEW gold.vw_client_diagnosis_all_analysis AS

SELECT
    d.YEAR,
    d.CASEID,
    d.DIAGNOSIS_CODE,
    diagnosis_dim.DIAGNOSIS_NAME,
    d.DIAGNOSIS_POSITION,
    d.DIAGNOSIS_SOURCE,
    d.DIAGNOSIS_RECORD_COUNT,
    d.CREATE_DATE

FROM gold.vw_client_diagnosis_all AS d

LEFT JOIN gold.dim_diagnosis AS diagnosis_dim
    ON d.DIAGNOSIS_CODE = diagnosis_dim.DIAGNOSIS_CODE;

-- ============================================================
-- VIEW: gold.vw_client_service_analysis
--
-- PURPOSE:
-- Provides readable service records from the service bridge by joining
-- service codes to service names.
--
-- USE WHEN:
-- Analyzing which mental health services were reported for client year
-- records.
-- ============================================================
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