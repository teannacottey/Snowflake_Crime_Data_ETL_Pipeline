/*
    Police crime source setup for Snowflake

    Purpose:
    - Connect Snowflake to the raw and clean S3 locations.
    - Create the database objects required by the police cleaning notebook.
    - Load the raw street-crime CSV files into CRIME_ETL_DB.RAW.STREET_CRIME.

    Important:
    - This script does not alter or remove files from the raw S3 location.
    - CREATE and COPY operations only create Snowflake objects and read the source files.
    - The storage integration may already exist. If it does, ALTER is used to retain
      the complete list of approved S3 locations.
*/

/* Account-level objects and permissions require ACCOUNTADMIN. */
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS CRIME_S3_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::559852958324:role/SnowflakeCrimeS3Role'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://rockborne-ch19-g1-crime/raw/uk-police/',
        's3://rockborne-ch19-g1-crime/clean/uk-police/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/population/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/england/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/wales/'
    );

/* Ensure the existing integration has the same complete allow-list. */
ALTER STORAGE INTEGRATION CRIME_S3_INTEGRATION
    SET STORAGE_ALLOWED_LOCATIONS = (
        's3://rockborne-ch19-g1-crime/raw/uk-police/',
        's3://rockborne-ch19-g1-crime/clean/uk-police/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/population/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/england/',
        's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/wales/'
    );

GRANT USAGE ON INTEGRATION CRIME_S3_INTEGRATION TO ROLE SYSADMIN;

/* Create the project database and allow SYSADMIN to create its schemas. */
CREATE DATABASE IF NOT EXISTS CRIME_ETL_DB;
GRANT USAGE ON DATABASE CRIME_ETL_DB TO ROLE SYSADMIN;
GRANT CREATE SCHEMA ON DATABASE CRIME_ETL_DB TO ROLE SYSADMIN;

/* All remaining project objects are owned or operated by SYSADMIN. */
USE ROLE SYSADMIN;
USE DATABASE CRIME_ETL_DB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS DATA_QUALITY;
CREATE SCHEMA IF NOT EXISTS CLEAN;

USE SCHEMA RAW;

/*
    Police.uk street-crime files contain one header row.
    Blank fields are converted to NULL and quoted commas are handled correctly.
*/
CREATE FILE FORMAT IF NOT EXISTS CRIME_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

/* External stage used to read the untouched police files in S3. */
CREATE STAGE IF NOT EXISTS CRIME_S3_STAGE
    URL = 's3://rockborne-ch19-g1-crime/raw/uk-police/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION
    FILE_FORMAT = CRIME_CSV_FORMAT;

/* Confirm that Snowflake can see the source files before loading them. */
LIST @CRIME_ETL_DB.RAW.CRIME_S3_STAGE;

/*
    Raw landing table expected by Police_Crime_Snowflake_Cleaning_Validation.ipynb.
    Text is retained for most source fields so cleaning and type validation happen
    in the cleaning layer rather than silently changing the source values on load.
*/
CREATE TABLE IF NOT EXISTS CRIME_ETL_DB.RAW.STREET_CRIME (
    "Crime ID" TEXT,
    "Month" TEXT,
    "Reported by" TEXT,
    "Falls within" TEXT,
    "Longitude" TEXT,
    "Latitude" TEXT,
    "Location" TEXT,
    "LSOA code" TEXT,
    "LSOA name" TEXT,
    "Crime type" TEXT,
    "Last outcome category" TEXT,
    "Context" TEXT
);

/*
    Load only the four police forces included in this project.
    PATTERN searches file paths and names case-insensitively.
    FORCE = FALSE avoids reloading files already recorded in Snowflake load history.
*/
COPY INTO CRIME_ETL_DB.RAW.STREET_CRIME
FROM @CRIME_ETL_DB.RAW.CRIME_S3_STAGE
FILE_FORMAT = (FORMAT_NAME = CRIME_ETL_DB.RAW.CRIME_CSV_FORMAT)
PATTERN = '.*(metropolitan|west-midlands|south-wales|sussex).*street\\.csv'
ON_ERROR = 'CONTINUE'
FORCE = FALSE;

/* Basic checks after the load. */
SELECT COUNT(*) AS RAW_ROWS
FROM CRIME_ETL_DB.RAW.STREET_CRIME;

SELECT
    "Falls within" AS FORCE_NAME,
    COUNT(*) AS RAW_ROWS
FROM CRIME_ETL_DB.RAW.STREET_CRIME
GROUP BY "Falls within"
ORDER BY FORCE_NAME;

/*
    Shared clean external stage used by both notebooks for their CSV exports.
    Creating a stage does not write anything to S3; COPY INTO the stage performs
    the export later.
*/
USE SCHEMA CLEAN;

CREATE STAGE IF NOT EXISTS CRIME_CLEAN_STAGE
    URL = 's3://rockborne-ch19-g1-crime/clean/uk-police/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION;

LIST @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE;

