/*
    Supplementary source setup for Snowflake

    Datasets:
    - Police-force-area population data
    - England Index of Multiple Deprivation (IMD)
    - Wales Index of Multiple Deprivation (WIMD)

    The supplementary cleaning notebook reads these external stages directly.
    It does not require separate raw Snowflake tables.

    Important:
    - The raw S3 files remain untouched.
    - This script only creates file formats and references to the S3 locations.
    - The source files must be CSV files before the notebook is run.
*/

/* Update the complete storage-integration allow-list as ACCOUNTADMIN. */
USE ROLE ACCOUNTADMIN;

ALTER STORAGE INTEGRATION CRIME_S3_INTEGRATION
    SET STORAGE_ALLOWED_LOCATIONS = (
        's3://rockborne-ch19-g1-crime/raw/uk-police/',
        's3://rockborne-ch19-g1-crime/clean/uk-police/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/population/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/england/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/wales/'
    );

GRANT USAGE ON INTEGRATION CRIME_S3_INTEGRATION TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE CRIME_ETL_DB TO ROLE SYSADMIN;
GRANT CREATE SCHEMA ON DATABASE CRIME_ETL_DB TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE CRIME_ETL_DB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS DATA_QUALITY;
CREATE SCHEMA IF NOT EXISTS CLEAN;

USE SCHEMA RAW;

/*
    Keep the header rows available to the notebook. Its parsing logic explicitly
    identifies and excludes headers while retaining source-row visibility.
*/
CREATE FILE FORMAT IF NOT EXISTS POPULATION_CSV_FORMAT
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    SKIP_HEADER = 0
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE FILE FORMAT IF NOT EXISTS DEPRIVATION_ENGLAND_CSV_FORMAT
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    SKIP_HEADER = 0
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE FILE FORMAT IF NOT EXISTS DEPRIVATION_WALES_CSV_FORMAT
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    SKIP_HEADER = 0
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

/*
    Population stage expected by the notebook.
    The original workbook must be exported to CSV and placed in this /csv/ folder.
*/
CREATE STAGE IF NOT EXISTS POPULATION_S3_STAGE
    URL = 's3://rockborne-ch19-g1-crime/raw/enrichment/population/csv/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION
    FILE_FORMAT = POPULATION_CSV_FORMAT;

/* England IMD stage expected by the notebook. */
CREATE STAGE IF NOT EXISTS DEPRIVATION_ENGLAND_S3_STAGE
    URL = 's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/england/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION
    FILE_FORMAT = DEPRIVATION_ENGLAND_CSV_FORMAT;

/* Wales WIMD stage expected by the notebook. */
CREATE STAGE IF NOT EXISTS DEPRIVATION_WALES_S3_STAGE
    URL = 's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/wales/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION
    FILE_FORMAT = DEPRIVATION_WALES_CSV_FORMAT;

/* Confirm that Snowflake can see the files in each source location. */
LIST @CRIME_ETL_DB.RAW.POPULATION_S3_STAGE;
LIST @CRIME_ETL_DB.RAW.DEPRIVATION_ENGLAND_S3_STAGE;
LIST @CRIME_ETL_DB.RAW.DEPRIVATION_WALES_S3_STAGE;

/*
    Preview the population source. The notebook expects:
    $1 = police-force-area code
    $2 = police-force-area name
    $3 = year
    $4 to $175 = female and male population counts by age.
*/
SELECT
    METADATA$FILENAME AS FILE_NAME,
    METADATA$FILE_ROW_NUMBER AS ROW_NUMBER,
    t.$1 AS PFA_CODE,
    t.$2 AS FORCE_NAME,
    t.$3 AS YEAR,
    t.$4 AS FIRST_POPULATION_FIELD,
    t.$175 AS LAST_POPULATION_FIELD
FROM @CRIME_ETL_DB.RAW.POPULATION_S3_STAGE t
LIMIT 30;

/*
    Preview the England IMD source.
    The notebook uses 56 columns, beginning with the 2021 LSOA fields.
*/
SELECT
    METADATA$FILENAME AS FILE_NAME,
    METADATA$FILE_ROW_NUMBER AS ROW_NUMBER,
    t.$1 AS LSOA_CODE,
    t.$2 AS LSOA_NAME,
    t.$3 AS LOCAL_AUTHORITY_CODE,
    t.$4 AS LOCAL_AUTHORITY_NAME,
    t.$5 AS IMD_SCORE,
    t.$6 AS IMD_RANK,
    t.$7 AS IMD_DECILE,
    t.$56 AS WORKING_AGE_POPULATION
FROM @CRIME_ETL_DB.RAW.DEPRIVATION_ENGLAND_S3_STAGE t
LIMIT 30;

/*
    Preview the Wales WIMD long-format source.
    The notebook uses the six analytical fields shown below and ignores the
    reference, sorting and hierarchy metadata fields.
*/
SELECT
    METADATA$FILENAME AS FILE_NAME,
    METADATA$FILE_ROW_NUMBER AS ROW_NUMBER,
    t.$1 AS DATA_VALUE,
    t.$3 AS DATA_DESCRIPTION,
    t.$7 AS AREA_CODE,
    t.$11 AS AREA_NAME,
    t.$15 AS DOMAIN,
    t.$19 AS NOTES
FROM @CRIME_ETL_DB.RAW.DEPRIVATION_WALES_S3_STAGE t
LIMIT 30;

/*
    Recreate the shared clean stage if the police setup script has not already
    created it. Both notebooks export their cleaned CSV files to this location.
*/
USE SCHEMA CLEAN;

CREATE STAGE IF NOT EXISTS CRIME_CLEAN_STAGE
    URL = 's3://rockborne-ch19-g1-crime/clean/uk-police/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION;

LIST @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE;

