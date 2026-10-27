# Hospital Patient Analytics — PostgreSQL

Analysis of hospital encounters, procedure costs, insurance coverage,
and patient return visits using PostgreSQL.

## Dataset

The project uses five related tables:

| Table | Records |
|-------|--------:|
| Patients | 974 |
| Encounters | 27,891 |
| Procedures | 47,701 |
| Payers | 10 |
| Organizations | 1 |

## Business Questions

### Encounters Overview
- How many encounters occurred each year?
- What percentage belonged to each encounter class each year?
- What percentage lasted under, exactly, or over 24 hours?

### Cost and Coverage
- How many encounters had zero payer coverage?
- Which procedures were performed most frequently?
- Which procedures had the highest average base cost?
- How did average claim costs vary by payer?

### Patient Behavior
- How many unique patients had encounters each quarter?
- How many patients returned within 30 days?
- Which patients had the most qualifying return visits?

## SQL Techniques

- Aggregations and GROUP BY
- CASE expressions
- Common Table Expressions (CTEs)
- LEFT JOIN
- Window functions: LAG and SUM OVER
- Date extraction and timestamp arithmetic
- Conditional counting and percentage calculations

## Definitions and Assumptions

- Quarterly patient counts include all encounter classes.
- A qualifying return visit starts between 0 and 30 days after
  the same patient's immediately preceding encounter ended.
- This return-visit definition includes all encounter classes;
  it is not a clinical measure of unplanned inpatient readmissions.
- Patients are counted once per quarter, but may appear in
  multiple quarters.

## Tools

PostgreSQL 18, pgAdmin 4, and Visual Studio Code.

## Project File

[View the analysis queries](healthcare_analysis.sql)

## Running the Analysis

1. Create a PostgreSQL database.
2. Import the five CSV datasets into their corresponding tables.
3. Ensure date-time columns use timestamp types and costs use
   numeric types.
4. Open healthcare_analysis.sql and execute each query separately.

## Author

Sumir Tyagi
