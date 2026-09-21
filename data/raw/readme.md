# Add the MH-CLD Source Data Here

The raw MH-CLD source archive is not included in this repository.

To run the project locally:

1. Go to the official [SAMHSA MH-CLD Data Files page](https://www.samhsa.gov/data/data-we-collect/mh-cld-mental-health-client-level-data/datafiles).

2. Download the **SAMHSA Mental Health Client Level Data (MH-CLD)** delimited or CSV public-use file.

   Direct download: [MH-CLD-2024-DS0001-bndl-data-csv_v1.zip](https://www.samhsa.gov/data/system/files/media-puf-file/MH-CLD-2024-DS0001-bndl-data-csv_v1.zip)

3. Extract the downloaded ZIP file.

4. Place the extracted CSV files inside this folder:

```text
data/raw/
```

Expected local structure:

```text
data/
└── raw/
    └── extracted MH-CLD CSV files
```

No files need to be renamed. The Bronze script searches recursively for CSV files within `data/raw/`.

