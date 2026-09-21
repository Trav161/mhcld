# Getting Started

This guide covers the setup required to run the MH-CLD SQL Data Warehouse project.

The warehouse follows:

**Bronze → Silver → Gold → Analysis**

---

## 1. Download the Project

From the GitHub repository:

**Code → Download ZIP**

Extract the project folder to your computer.

---


## 2. Install Required Software

Install:
- Visual Studio Code
- DuckDB support for VS Code

Open Visual Studio Code after installation.

## 3. Unzip CSV

The project folder includes the 2024 SAMHSA MH-CLD CSV archive in:

data/raw/MH-CLD-2024-DS0001-bndl-data-csv_v1

Extract the zip file inside the same folder.

The extracted CSV may remain inside its generated subfolder. The Bronze script searches for CSV files within data/raw/.
---

## 4. Open the Project

In VS Code:

**File → Open Folder**

Select the extracted MH-CLD project folder.

The project should resemble:

mhcld/
├── data/
│   └── raw/MH-CLD-2024-DS0001-bndl-data-csv_v1\mhcld_puf_2024.csv
├── docs/
├── sql/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── analysis/
├── tests/
├── warehouse/
├── getting_started.md
└── README.md

## 5. Get DuckDB environment ready

## 6. Start building the [bronze layer](sql/bronze/00_build_bronze.sql)



