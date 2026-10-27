/*
HEALTHCARE ENCOUNTER ANALYSIS
SQL dialect: PostgreSQL

Tables used:
    encounters
    procedures
    payers

Readmission definition:
    An encounter starting between 0 and 30 days after
    the same patient's immediately previous encounter ended.
*/


-- ============================================================
-- OBJECTIVE 1: ENCOUNTERS OVERVIEW
-- ============================================================


-- 1(a): How many total encounters occurred each year?

SELECT
    EXTRACT(YEAR FROM START) AS encounter_year,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY encounter_year
ORDER BY encounter_year;


-- 1(b): For each year, what percentage of encounters
-- belonged to each encounter class?

WITH yearly_class_counts AS (
    SELECT
        EXTRACT(YEAR FROM START) AS encounter_year,
        ENCOUNTERCLASS,
        COUNT(*) AS encounter_count
    FROM encounters
    GROUP BY encounter_year, ENCOUNTERCLASS
)
SELECT
    encounter_year,
    ENCOUNTERCLASS,
    encounter_count,
    ROUND(
        encounter_count * 100.0
        / SUM(encounter_count) OVER (
            PARTITION BY encounter_year
        ),
        2
    ) AS percentage_of_yearly_encounters
FROM yearly_class_counts
ORDER BY encounter_year, ENCOUNTERCLASS;


-- 1(c): What percentage of encounters were over 24 hours
-- versus under 24 hours?
-- Exactly 24 hours is shown separately to avoid excluding it.
-- Encounters with missing or invalid durations are excluded.

WITH encounter_durations AS (
    SELECT
        EXTRACT(EPOCH FROM (STOP - START)) / 3600.0
            AS duration_hours
    FROM encounters
    WHERE START IS NOT NULL
      AND STOP IS NOT NULL
      AND STOP >= START
),
duration_categories AS (
    SELECT
        CASE
            WHEN duration_hours < 24 THEN 'Under 24 hours'
            WHEN duration_hours = 24 THEN 'Exactly 24 hours'
            ELSE 'Over 24 hours'
        END AS duration_category
    FROM encounter_durations
)
SELECT
    duration_category,
    COUNT(*) AS encounter_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_encounters
FROM duration_categories
GROUP BY duration_category
ORDER BY duration_category;


-- ============================================================
-- OBJECTIVE 2: COST & COVERAGE INSIGHTS
-- ============================================================


-- 2(a): How many encounters had zero payer coverage,
-- and what percentage of total encounters does this represent?

SELECT
    COUNT(*) AS total_encounters,
    COUNT(*) FILTER (
        WHERE PAYER_COVERAGE = 0
    ) AS encounters_with_zero_coverage,
    ROUND(
        COUNT(*) FILTER (
            WHERE PAYER_COVERAGE = 0
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS percentage_with_zero_coverage
FROM encounters;


-- 2(b): What are the top 10 most frequent procedures performed
-- and the average base cost for each?

SELECT
    DESCRIPTION,
    COUNT(*) AS count_of_procedures,
    AVG(BASE_COST) AS average_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY count_of_procedures DESC, DESCRIPTION
LIMIT 10;


-- 2(c): What are the top 10 procedures with the highest
-- average base cost and the number of times they were performed?

SELECT
    DESCRIPTION,
    AVG(BASE_COST) AS average_base_cost,
    COUNT(*) AS count_of_procedures
FROM procedures
GROUP BY DESCRIPTION
ORDER BY average_base_cost DESC NULLS LAST, DESCRIPTION
LIMIT 10;


-- 2(d): What is the average total claim cost for encounters,
-- broken down by payer?
-- Include payer names for easier interpretation.

SELECT
    e.PAYER AS payer_id,
    p.NAME AS payer_name,
    AVG(e.TOTAL_CLAIM_COST) AS avg_total_claim_cost
FROM encounters AS e
LEFT JOIN payers AS p
    ON e.PAYER = p.Id
GROUP BY e.PAYER, p.NAME
ORDER BY avg_total_claim_cost DESC NULLS LAST, payer_id;


-- ============================================================
-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
-- ============================================================


-- 3(a): How many unique patients were admitted each quarter
-- over time?
-- Includes all encounter classes.

SELECT
    EXTRACT(YEAR FROM START) AS encounter_year,
    CASE
        WHEN EXTRACT(MONTH FROM START) IN (1, 2, 3) THEN 'Q1'
        WHEN EXTRACT(MONTH FROM START) IN (4, 5, 6) THEN 'Q2'
        WHEN EXTRACT(MONTH FROM START) IN (7, 8, 9) THEN 'Q3'
        ELSE 'Q4'
    END AS encounter_quarter,
    COUNT(DISTINCT PATIENT) AS count_of_patients
FROM encounters
GROUP BY encounter_year, encounter_quarter
ORDER BY encounter_year, encounter_quarter;


-- 3(b): How many patients were readmitted within 30 days
-- of a previous encounter?
-- Id breaks ties when encounters have the same START time.

WITH previous_encounters AS (
    SELECT
        PATIENT,
        START,
        STOP,
        LAG(STOP) OVER (
            PARTITION BY PATIENT
            ORDER BY START, Id
        ) AS previous_stop
    FROM encounters
),
days_between AS (
    SELECT
        PATIENT,
        EXTRACT(EPOCH FROM (START - previous_stop)) / 86400.0
            AS days_since_previous_encounter
    FROM previous_encounters
)
SELECT
    COUNT(DISTINCT PATIENT) AS patients_readmitted
FROM days_between
WHERE days_since_previous_encounter BETWEEN 0 AND 30;


-- 3(c): Which patients had the most readmissions?
-- Uses the same 30-day definition as 3(b).

WITH previous_encounters AS (
    SELECT
        PATIENT,
        START,
        STOP,
        LAG(STOP) OVER (
            PARTITION BY PATIENT
            ORDER BY START, Id
        ) AS previous_stop
    FROM encounters
),
days_between AS (
    SELECT
        PATIENT,
        EXTRACT(EPOCH FROM (START - previous_stop)) / 86400.0
            AS days_since_previous_encounter
    FROM previous_encounters
)
SELECT
    PATIENT,
    COUNT(*) AS readmission_count
FROM days_between
WHERE days_since_previous_encounter BETWEEN 0 AND 30
GROUP BY PATIENT
ORDER BY readmission_count DESC, PATIENT;