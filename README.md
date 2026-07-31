# ReadMe - Snowflake Crime ETL Pipeline

This is a recreation of the 'Python Crime Data Engineering' project, now completed as a group in Snowflake. 

## Project Overview 

The objective of this project was to design and implement a scalable Python-based data ETL pipeline in Snowflake that transforms raw crime data into a clean, aggregated, and reporting-ready dataset suitable for use in BI analysis. Particular emphasis was placed on data quality and validation throughout the pipeline. 

## ETL Pipeline 

Using the 'Crime ETL Pipeline.ipynb' file, run all blocks of code in Snowflake, in order to recreate the ETL pipeline. 

**Note: Access to the s3 bucket is dependent on providing the Ingestion Engineer with the STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID property values, produced by the DESC INTEGRATION CRIME_S3_INTEGRATION; and account permissions being granted.

## Technologies Used 

- **Snowflake**
  - Crime Data ETL Pipeline
  - Collaboration (S3 Bucket, Stage)
- **Git Hub**
  - Version Control
  - Collaboration
  - Publish Project

 ## Project Files 

 *The first directory in the following paths is the project folder. Ignore if already in that folder. 

**Final Reporting Dataset:** Snowflake_Crime_Data_ETL_Pipeline/processedAndAggregatedCrimeData.csv     
**Crime ETL Pipeline:** Snowflake_Crime_Data_ETL_Pipeline/Crime ETL Pipeline.ipynb
