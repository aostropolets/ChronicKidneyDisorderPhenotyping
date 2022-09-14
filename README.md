# Investigating portability of EHR-derinved pehnotypes 

## Overview
This script generates cohorts to identify patients with chronic kidney disorder.
To assemble whole script run concat.bat or concat.sh depending on your OS.

## Prerequisites
You need to have database converted to OMOP CDM v.5 (https://ohdsi.org), the database has to have measurement and its values, condition and procedure patient data.
The original script is written for SQL Server, use SQL Render to convert it to your target SQL dialect (https://data.ohdsi.org/SqlDeveloper/)
Replace the following variables with your database schemas:
@cdm_database_schema - schema where OMOP Vocabulary and patienttables are stored 
@target_database_schema - schema with writing access

# Description of separate files
1. CKD_codes
Creates the table with OMOP Vocabulary codes to subsequently be used in phenityping
2. creatinine
Identify creatinine measurements in patient records
3. height
Identify height measurements in patient records
4. height
Calculate eGRFR values for patients based on previous measurements.
5. transplant, dialysis, other acute conditions (for examplr shock), acute kidney failure, chronic kideny disorder, other kidney disorders
Identify records of interest to identify patients with CKD
6. Script for the phenotype itself
7. Comparator cohorts to compare them to the gold standard
