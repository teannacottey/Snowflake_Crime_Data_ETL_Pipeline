-- create initial storage integration
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION CRIME_S3_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::559852958324:role/SnowflakeCrimeS3Role'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://rockborne-ch19-g1-crime/raw/uk-police/'
    );

DESC INTEGRATION CRIME_S3_INTEGRATION;


-- altering storage to include clean, population and deprivation datasets
USE ROLE ACCOUNTADMIN;

ALTER STORAGE INTEGRATION CRIME_S3_INTEGRATION
SET STORAGE_ALLOWED_LOCATIONS = (
    's3://rockborne-ch19-g1-crime/raw/uk-police/',
    's3://rockborne-ch19-g1-crime/clean/uk-police/',
    's3://rockborne-ch19-g1-crime/raw/enrichment/population/',
    's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/england/',
    's3://rockborne-ch19-g1-crime/raw/enrichment/deprivation/wales/'
);
