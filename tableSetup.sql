CREATE DATABASE IF NOT EXISTS CRIME_ETL_DB;

CREATE SCHEMA IF NOT EXISTS CLEAN;

USE DATABASE CRIME_ETL_DB;
USE SCHEMA CLEAN;

CREATE FILE FORMAT IF NOT EXISTS CLEAN_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL', 'null');

CREATE STAGE IF NOT EXISTS CRIME_CLEAN_STAGE
    URL = 's3://rockborne-ch19-g1-crime/clean/uk-police/'
    STORAGE_INTEGRATION = CRIME_S3_INTEGRATION
    FILE_FORMAT = CLEAN_CSV_FORMAT;

-- Creating the table for the cleaned crime data
CREATE OR REPLACE TABLE CRIME_DATA_CLEAN (
    CRIME_ID VARCHAR,
    YEAR VARCHAR,
    MONTH VARCHAR,
    REPORTED_BY VARCHAR,
    FALLS_WITHIN VARCHAR,
    LONGITUDE FLOAT,
    LATITUDE FLOAT,
    LOCATION VARCHAR,
    LSOA_CODE VARCHAR,
    LSOA_NAME VARCHAR,
    CRIME_TYPE VARCHAR
);

-- Copying the cleaned Sussex crime data from the Amazon s3 bucket to the table
COPY INTO CRIME_DATA_CLEAN (
    CRIME_ID,
    YEAR,
    MONTH,
    REPORTED_BY,
    FALLS_WITHIN,
    LONGITUDE,
    LATITUDE,
    LOCATION,
    LSOA_CODE,
    LSOA_NAME,
    CRIME_TYPE
)
FROM (
    SELECT 
        $1,                     
        $3,                     
        $4,
        $5,                      
        $6,                        
        TRY_CAST($7 AS FLOAT),     
        TRY_CAST($8 AS FLOAT),    
        $9,                        
        $10,                       
        $11,                      
        $12                       
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/sussex_police_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Copying the cleaned South Wales crime data from the Amazon s3 bucket to the table
COPY INTO CRIME_DATA_CLEAN (
    CRIME_ID,
    YEAR,
    MONTH,
    REPORTED_BY,
    FALLS_WITHIN,
    LONGITUDE,
    LATITUDE,
    LOCATION,
    LSOA_CODE,
    LSOA_NAME,
    CRIME_TYPE
)
FROM (
    SELECT 
        $1,                        -- CRIME_ID
        $3,                        -- MONTH
        $4,
        $5,                        -- REPORTED_BY ("Metropolitan Police Service")
        $6,                        -- FALLS_WITHIN ("Metropolitan Police Service")
        TRY_CAST($7 AS FLOAT),     -- LONGITUDE (0.177936)
        TRY_CAST($8 AS FLOAT),     -- LATITUDE (51.45086)
        $9,                        -- LOCATION
        $10,                       -- LSOA_CODE
        $11,                       -- LSOA_NAME
        $12                       -- CRIME_TYPE
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/south_wales_police_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Copying the cleaned West Midlands crime data from the Amazon s3 bucket to the table
COPY INTO CRIME_DATA_CLEAN (
    CRIME_ID,
    YEAR,
    MONTH,
    REPORTED_BY,
    FALLS_WITHIN,
    LONGITUDE,
    LATITUDE,
    LOCATION,
    LSOA_CODE,
    LSOA_NAME,
    CRIME_TYPE
)
FROM (
    SELECT 
        $1,                        -- CRIME_ID
        $3,                        -- MONTH
        $4,
        $5,                        -- REPORTED_BY ("Metropolitan Police Service")
        $6,                        -- FALLS_WITHIN ("Metropolitan Police Service")
        TRY_CAST($7 AS FLOAT),     -- LONGITUDE (0.177936)
        TRY_CAST($8 AS FLOAT),     -- LATITUDE (51.45086)
        $9,                        -- LOCATION
        $10,                       -- LSOA_CODE
        $11,                       -- LSOA_NAME
        $12                       -- CRIME_TYPE
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/west_midlands_police_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Copying the cleaned Metropolitan crime data from the Amazon s3 bucket to the table
COPY INTO CRIME_DATA_CLEAN (
    CRIME_ID,
    YEAR,
    MONTH,
    REPORTED_BY,
    FALLS_WITHIN,
    LONGITUDE,
    LATITUDE,
    LOCATION,
    LSOA_CODE,
    LSOA_NAME,
    CRIME_TYPE
)
FROM (
    SELECT 
        $1,                        -- CRIME_ID
        $3,                        -- MONTH
        $4,
        $5,                        -- REPORTED_BY ("Metropolitan Police Service")
        $6,                        -- FALLS_WITHIN ("Metropolitan Police Service")
        TRY_CAST($7 AS FLOAT),     -- LONGITUDE (0.177936)
        TRY_CAST($8 AS FLOAT),     -- LATITUDE (51.45086)
        $9,                        -- LOCATION
        $10,                       -- LSOA_CODE
        $11,                       -- LSOA_NAME
        $12                       -- CRIME_TYPE
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/metropolitan_police_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Creating the table for the cleaned population
create or replace TABLE POPULATION_CLEAN (
	PFA_CODE VARCHAR,
	FORCE_NAME VARCHAR,
	YEAR NUMBER,
	TOTAL_POPULATION NUMBER
);

-- Copying the cleaned population data from the Amazon s3 bucket to the table
COPY INTO POPULATION_CLEAN (
	PFA_CODE,
	FORCE_NAME,
	YEAR,
	TOTAL_POPULATION
)
FROM (
    SELECT 
        $1,                        
        $2,                        
        $3,
        $4
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/population_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Creating the table for the cleaned Welsh deprivation data
CREATE OR REPLACE TABLE DEPRIVATION_WALES_CLEAN (
	LSOA_CODE VARCHAR,
	LSOA_NAME VARCHAR,
	WIMD_RANK NUMBER,
	WIMD_DECILE NUMBER,
	INCOME_RANK NUMBER,
	INCOME_DECILE NUMBER,
	EMPLOYMENT_RANK NUMBER,
	EMPLOYMENT_DECILE NUMBER,
	EDUCATION_RANK NUMBER,
	EDUCATION_DECILE NUMBER,
	HEALTH_RANK NUMBER,
	HEALTH_DECILE NUMBER,
	ACCESS_TO_SERVICES_RANK NUMBER,
	ACCESS_TO_SERVICES_DECILE NUMBER,
	HOUSING_RANK NUMBER,
	HOUSING_DECILE NUMBER,
	PHYSICAL_ENVIRONMENT_RANK NUMBER,
	PHYSICAL_ENVIRONMENT_DECILE NUMBER,
	COMMUNITY_SAFETY_RANK NUMBER,
	COMMUNITY_SAFETY_DECILE NUMBER
);

-- Copying the cleaned Welsh deprivation data data from the Amazon s3 bucket to the table
COPY INTO DEPRIVATION_WALES_CLEAN (
	LSOA_CODE,
	LSOA_NAME,
	WIMD_RANK,
	WIMD_DECILE,
	INCOME_RANK,
	INCOME_DECILE,
	EMPLOYMENT_RANK,
	EMPLOYMENT_DECILE,
	EDUCATION_RANK,
	EDUCATION_DECILE,
	HEALTH_RANK,
	HEALTH_DECILE,
	ACCESS_TO_SERVICES_RANK,
	ACCESS_TO_SERVICES_DECILE,
	HOUSING_RANK,
	HOUSING_DECILE,
	PHYSICAL_ENVIRONMENT_RANK,
	PHYSICAL_ENVIRONMENT_DECILE,
	COMMUNITY_SAFETY_RANK,
	COMMUNITY_SAFETY_DECILE 
)
FROM (
    SELECT 
        $1,                        
        $2,                        
        $3,
        $4,
        $5,                        
        $6,                        
        $7,
        $8,
        $9,                        
        $10,                        
        $11,
        $12,
        $13,                        
        $14,                        
        $15,
        $16,
        $17,                        
        $18,                        
        $19,
        $20
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/deprivation_wales_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;

-- Creating the table for the cleaned English deprivation data
create or replace TABLE CRIME_ETL_DB.CLEAN.DEPRIVATION_ENGLAND_CLEAN (
	LSOA_CODE VARCHAR,
	LSOA_NAME VARCHAR,
	LOCAL_AUTHORITY_CODE VARCHAR,
	LOCAL_AUTHORITY_NAME VARCHAR,
	IMD_SCORE NUMBER,
	IMD_RANK NUMBER,
	IMD_DECILE NUMBER,
	INCOME_SCORE NUMBER,
	INCOME_RANK NUMBER,
	INCOME_DECILE NUMBER,
	EMPLOYMENT_SCORE NUMBER,
	EMPLOYMENT_RANK NUMBER,
	EMPLOYMENT_DECILE NUMBER,
	EDUCATION_SCORE NUMBER,
	EDUCATION_RANK NUMBER,
	EDUCATION_DECILE NUMBER,
	HEALTH_SCORE NUMBER,
	HEALTH_RANK NUMBER,
	HEALTH_DECILE NUMBER,
	CRIME_SCORE NUMBER,
	CRIME_RANK NUMBER,
	CRIME_DECILE NUMBER,
	EXCLUDE_CRIME_DOMAIN_FROM_CRIME_ANALYSIS BOOLEAN,
	HOUSING_BARRIERS_SCORE NUMBER,
	HOUSING_BARRIERS_RANK NUMBER,
	HOUSING_BARRIERS_DECILE NUMBER,
	LIVING_ENVIRONMENT_SCORE NUMBER,
	LIVING_ENVIRONMENT_RANK NUMBER,
	LIVING_ENVIRONMENT_DECILE NUMBER,
	TOTAL_POPULATION_MID_2022 NUMBER,
	DEPENDENT_CHILDREN_0_15_MID_2022 NUMBER,
	OLDER_POPULATION_60_PLUS_MID_2022 NUMBER,
	WORKING_AGE_POPULATION_MID_2022 NUMBER
);

-- Copying the cleaned English deprivation data from the Amazon s3 bucket to the table
COPY INTO DEPRIVATION_ENGLAND_CLEAN (
	LSOA_CODE,
	LSOA_NAME,
	LOCAL_AUTHORITY_CODE,
	LOCAL_AUTHORITY_NAME,
	IMD_SCORE,
	IMD_RANK,
	IMD_DECILE,
	INCOME_SCORE,
	INCOME_RANK,
	INCOME_DECILE,
	EMPLOYMENT_SCORE,
	EMPLOYMENT_RANK,
	EMPLOYMENT_DECILE,
	EDUCATION_SCORE,
	EDUCATION_RANK,
	EDUCATION_DECILE,
	HEALTH_SCORE,
	HEALTH_RANK,
	HEALTH_DECILE,
	CRIME_SCORE,
	CRIME_RANK,
	CRIME_DECILE,
	EXCLUDE_CRIME_DOMAIN_FROM_CRIME_ANALYSIS,
	HOUSING_BARRIERS_SCORE,
	HOUSING_BARRIERS_RANK,
	HOUSING_BARRIERS_DECILE,
	LIVING_ENVIRONMENT_SCORE,
	LIVING_ENVIRONMENT_RANK,
	LIVING_ENVIRONMENT_DECILE,
	TOTAL_POPULATION_MID_2022,
	DEPENDENT_CHILDREN_0_15_MID_2022,
	OLDER_POPULATION_60_PLUS_MID_2022,
	WORKING_AGE_POPULATION_MID_2022
)
FROM (
    SELECT 
        $1,                        
        $2,                        
        $3,
        $4,
        $5,                        
        $6,                        
        $7,
        $8,
        $9,                        
        $10,                        
        $11,
        $12,
        $13,                        
        $14,                        
        $15,
        $16,
        $17,                        
        $18,                        
        $19,
        $20,
        $21,                        
        $22,                        
        $23,
        $24,
        $25,                        
        $26,                        
        $27,
        $28,
        $29,                        
        $30,
        $31,
        $32,
        $33
    FROM @CRIME_ETL_DB.CLEAN.CRIME_CLEAN_STAGE/deprivation_england_clean.csv
)
FILE_FORMAT = (FORMAT_NAME = 'CLEAN_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT'
FORCE = TRUE;