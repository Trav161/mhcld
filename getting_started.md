# Getting Started

This guide covers the setup required to run the MH-CLD SQL Data Warehouse project.

The warehouse follows:

**Bronze → Silver → Gold Tables → Gold Views → Analysis**

---

## 1. Download the Project

From the GitHub repository:

**Code → Download ZIP**

Extract the project folder to your computer.

---

## 2. Install Required Software

Install:

* Visual Studio Code
* DuckDB support for VS Code

Open Visual Studio Code after installation.

---

## 3. Download the Source Data

This project does not include the raw MH-CLD ZIP file.

Download the data directly from SAMHSA:

1. Visit the official [SAMHSA MH-CLD Data Files page](https://www.samhsa.gov/data/data-we-collect/mh-cld-mental-health-client-level-data/datafiles).

2. Download the **Mental Health Client-Level Data (MH-CLD)** delimited or CSV public-use file.

   Direct download: [MH-CLD-2024-DS0001-bndl-data-csv_v1.zip](https://www.samhsa.gov/data/system/files/media-puf-file/MH-CLD-2024-DS0001-bndl-data-csv_v1.zip)

3. Extract the ZIP file into:

```text
data/raw/
```

The Bronze script is designed to search recursively inside `data/raw/`, so the extracted folder structure can remain as downloaded.

---

## 4. Open the Project

In VS Code:

**File → Open Folder**

Select the extracted MH-CLD project folder.

The project should resemble:

```text
mhcld/
├── data/
│   └── raw/
│       └── extracted MH-CLD CSV files
├── docs/
├── sql/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── analysis/
├── tests/
├── warehouse/
├── getting_started.md
└── readme.md
```

---

## 5. Get the DuckDB Environment Ready

Open the Bronze script in VS Code:

```text
sql/bronze/00_build_bronze.sql
```

Run the script to create or open the local DuckDB warehouse and load the raw MH-CLD CSV data into the Bronze layer.

---

## 6. Build and Validate the Warehouse

Run the SQL scripts in this order:

```text
1. sql/bronze/00_build_bronze.sql
2. sql/silver/00_build_silver.sql
3. tests/quality_checks_silver.sql
4. sql/gold/00_build_gold.sql
5. sql/gold/01_build_gold_views.sql
6. tests/quality_checks_gold.sql
7. sql/Analysis/01_analysis.sql

The warehouse is designed so additional analytical questions can be added without modifying the raw source layer.
