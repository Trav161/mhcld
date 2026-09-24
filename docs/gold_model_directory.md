# Gold Model Directory

## Purpose

This document explains the Gold layer of the MH-CLD SQL Data Warehouse.

The Gold layer organizes cleaned Silver data into a dimensional model designed for analysis. It includes dimension tables, a central fact table, bridge tables, and analysis-ready views.

The goal is to make the data easier to understand, validate, and query without losing the structure of the original MH-CLD source file.

---

## Gold Layer Structure

The Gold layer is organized into four main groups:

| Group            | Purpose                                                 |
| ---------------- | ------------------------------------------------------- |
| Dimension tables | Store readable labels for coded fields                  |
| Fact table       | Stores one client-year record per client                |
| Bridge tables    | Convert repeated diagnosis and service fields into rows |
| Views            | Provide readable analysis-ready access to the model     |

---

# Dimension Tables

Dimension tables translate coded source values into readable labels.

They make the model easier to query and reduce the need to repeat label logic across analysis queries.

---

## `gold.dim_age`

Stores age group codes and readable age group labels.

Use this table when analyzing client records by age group.

---

## `gold.dim_education`

Stores education level codes and readable education labels.

Use this table when analyzing client records by education level.

---

## `gold.dim_ethnicity`

Stores ethnicity codes and readable ethnicity labels.

Use this table when analyzing client records by ethnicity.

---

## `gold.dim_race`

Stores race codes and readable race labels.

Use this table when analyzing client records by race.

---

## `gold.dim_sex`

Stores sex codes and readable sex labels.

Use this table when analyzing client records by sex.

---

## `gold.dim_marital_status`

Stores marital status codes and readable marital status labels.

Use this table when analyzing client records by marital status.

---

## `gold.dim_smised_status`

Stores SMI/SED status codes and readable labels.

Use this table when analyzing whether client records were associated with serious mental illness or serious emotional disturbance status.

---

## `gold.dim_substance_use_status`

Stores substance use disorder status codes and readable labels.

Use this table when analyzing whether a substance use disorder was reported.

---

## `gold.dim_substance_diagnosis`

Stores substance diagnosis codes and readable labels.

Use this table when analyzing the type of substance diagnosis reported.

---

## `gold.dim_employment_status`

Stores employment status codes and readable labels.

Use this table when analyzing client records by employment status.

---

## `gold.dim_not_in_labor_force`

Stores codes explaining why a client was not in the labor force.

Use this table when analyzing labor force status among clients who were not employed or not actively in the labor force.

---

## `gold.dim_veteran_status`

Stores veteran status codes and readable labels.

Use this table when analyzing client records by veteran status.

---

## `gold.dim_living_arrangement`

Stores living arrangement codes and readable labels.

Use this table when analyzing client records by living situation.

---

## `gold.dim_geography`

Stores state, division, and region information.

Use this table when analyzing client records by geography.

---

## `gold.dim_diagnosis`

Stores mental health diagnosis codes and readable diagnosis names.

Use this table when analyzing diagnosis records from the diagnosis bridge tables.

---

## `gold.dim_service`

Stores mental health service codes and readable service names.

Use this table when analyzing reported services.

---

# Fact Table

## `gold.fact_client_year`

Stores one record per client-year.

This is the central fact table of the Gold model. It contains the main client-year identifiers, coded dimension keys, diagnosis count information, and basic pipeline metadata.

Use this table when analyzing client-level records by demographic, clinical, social, or geographic attributes.

Grain:

```text
One row = one client record for one reporting year
```

Common use cases:

* Count client records by year
* Count client records by age group
* Count client records by geography
* Analyze client characteristics across demographic or social dimensions
* Join to dimension tables for readable labels

---

# Bridge Tables

Bridge tables convert repeated source fields into row-based structures.

They are used when the original source file stores multiple related values across separate columns.

---

## `gold.bridge_client_diagnosis`

Stores diagnosis records from the positional diagnosis fields: `MH1`, `MH2`, and `MH3`.

This table preserves diagnosis position, so analysis can distinguish between diagnosis slot 1, diagnosis slot 2, and diagnosis slot 3.

Grain:

```text
One row = one diagnosis position for one client-year
```

Use this table when diagnosis placement matters.

Common use cases:

* Analyze primary, secondary, and tertiary diagnosis patterns
* Count diagnoses by diagnosis position
* Review how diagnoses are distributed across MH1, MH2, and MH3

Important note:

The same diagnosis category can appear in more than one positional diagnosis field for the same client-year. Because of this, this table should not always be used as the default diagnosis prevalence count.

---

## `gold.bridge_client_diagnosis_flag`

Stores diagnosis category flags as row-based records.

Diagnosis flags indicate whether a diagnosis category was reported for a client-year record.

Grain:

```text
One row = one reported diagnosis category for one client-year
```

Use this table when diagnosis presence matters, rather than diagnosis position.

Common use cases:

* Count how many client-year records had a specific diagnosis category
* Compare diagnosis category prevalence
* Validate diagnosis flags against positional diagnosis fields

---

## `gold.bridge_client_service`

Stores reported mental health services as row-based records.

This table converts service indicator fields into a cleaner structure for service analysis.

Grain:

```text
One row = one reported service for one client year
```

Use this table when analyzing which services were reported for clients.

Common use cases:

* Count service use by service type
* Analyze services by diagnosis, geography, or client attributes
* Compare service patterns across groups

---

# Analysis Ready Views

Views sit on top of the Gold model.

They do not replace the fact, dimension, or bridge tables. They make the model easier to query by reattaching readable labels and preserving the intended analytical meaning of each structure.

---

## `gold.vw_client_year_analysis`

Provides one readable client year record by joining the main fact table to demographic, clinical, social, and geography dimensions.

Use this view when analyzing client counts by age, race, sex, region, employment, veteran status, living arrangement, or other client attributes.

This is the main view for client year analysis.

---

## `gold.vw_client_diagnosis_analysis`

Provides readable diagnosis records from the positional diagnosis bridge while preserving whether the diagnosis came from `MH1`, `MH2`, or `MH3`.

Use this view when analyzing diagnosis position, primary/secondary/tertiary diagnosis patterns, or diagnosis records where placement matters.

---

## `gold.vw_client_diagnosis_flag_analysis`

Provides readable diagnosis flag records showing whether a diagnosis category was reported for a client year record.

Use this view when counting diagnosis category presence without caring about `MH1`, `MH2`, or `MH3` position.

This is the preferred view for diagnosis prevalence counts.

---

## `gold.vw_client_diagnosis_all`

Combines positional diagnoses and diagnosis flags into one shared diagnosis stream while preserving the source type.

Use this view when comparing diagnosis structures or validating whether `MH1`, `MH2`, and `MH3` align with the diagnosis flag fields.

This view should not be used as the default diagnosis count because positional diagnoses and flags can overlap.

---

## `gold.vw_client_diagnosis_all_analysis`

Adds readable diagnosis names to the combined diagnosis comparison view.

Use this view for QA or comparison checks between positional diagnoses and diagnosis flags.

Project validation showed that diagnosis flags align with the positional diagnosis fields at the client year diagnosis level. A small count difference exists for `Other disorders/conditions` because 101 client year records contain that same diagnosis category more than once across `MH1`, `MH2`, and `MH3`, creating 103 extra positional records.

Use this view for validation and comparison, not default prevalence counts.

---

## `gold.vw_client_service_analysis`

Provides readable service records from the service bridge by joining service codes to service names.

Use this view when analyzing which mental health services were reported for client year records.

Common use cases:

* Count service use by service type
* Analyze service patterns by diagnosis
* Analyze service patterns by geography or client characteristics

---

# Recommended View Usage

| Question                                                         | Recommended view                         |
| ---------------------------------------------------------------- | ---------------------------------------- |
| How many client year records are in the dataset?                 | `gold.vw_client_year_analysis`           |
| How many clients are in each age group?                          | `gold.vw_client_year_analysis`           |
| How many clients are in each region?                             | `gold.vw_client_year_analysis`           |
| What diagnoses appear in MH1, MH2, and MH3?                      | `gold.vw_client_diagnosis_analysis`      |
| What diagnosis categories were reported for client year records? | `gold.vw_client_diagnosis_flag_analysis` |
| Do diagnosis flags align with MH1, MH2, and MH3?                 | `gold.vw_client_diagnosis_all_analysis`  |
| What services were reported?                                     | `gold.vw_client_service_analysis`        |

---

# Modeling Notes

## Unknown Values

The Silver layer converts documented missing values to `NULL`.

The Gold layer maps missing dimension keys to `-1`, which represents `Unknown / Not Reported` or a similar unknown category in the related dimension table.

This makes missing values explicit and allows validation checks to confirm that every fact table key maps to a dimension record.

---

## Diagnosis Modeling

The MH-CLD source file contains diagnosis information in two related structures:

| Source structure      | Meaning                                |
| --------------------- | -------------------------------------- |
| `MH1`, `MH2`, `MH3`   | Positional diagnosis fields            |
| Diagnosis flag fields | Diagnosis category presence indicators |

The Gold model keeps these structures separate because they answer different analytical questions.

Positional diagnosis fields preserve where the diagnosis appeared. Diagnosis flags show whether a diagnosis category was reported for the client year record.

Validation showed that the two structures align at the client year diagnosis level. The only count difference identified came from duplicate placement of `Other disorders/conditions` across the positional diagnosis fields.

---

## Service Modeling

Service fields are converted into a bridge table because a single client year record can include multiple reported services.

This allows service use to be analyzed by service type, client attributes, diagnosis, and geography.

---

# Summary

The Gold model is designed to balance structure and usability.

The base tables preserve a dimensional warehouse design. The bridge tables normalize repeated diagnosis and service fields. The analysis ready views make the model easier to query without hiding the underlying structure.
