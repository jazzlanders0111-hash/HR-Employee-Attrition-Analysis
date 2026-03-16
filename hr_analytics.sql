-- =====================================================
-- HR Employee Attrition Analysis
-- =====================================================
-- Dataset : HR Employee Attrition (Kaggle, via MLJAR)
-- Table   : employee_attrition (1,470 rows)
-- Tool    : PostgreSQL 18 + pgAdmin 4
-- =====================================================


-- =====================================================
-- SECTION 0: SCHEMA AND TABLE SETUP
-- Safe to run repeatedly, creates only if not exists
-- =====================================================

CREATE SCHEMA IF NOT EXISTS hr_analytics;
SET search_path = hr_analytics;

CREATE TABLE IF NOT EXISTS employee_attrition (
    age                        INTEGER,
    attrition                  TEXT,
    business_travel            TEXT,
    daily_rate                 INTEGER,
    department                 TEXT,
    distance_from_home         INTEGER,
    education                  INTEGER,
    education_field            TEXT,
    employee_count             INTEGER,
    employee_number            INTEGER,
    environment_satisfaction   INTEGER,
    gender                     TEXT,
    hourly_rate                INTEGER,
    job_involvement            INTEGER,
    job_level                  INTEGER,
    job_role                   TEXT,
    job_satisfaction           INTEGER,
    marital_status             TEXT,
    monthly_income             INTEGER,
    monthly_rate               INTEGER,
    num_companies_worked       INTEGER,
    over18                     TEXT,
    overtime                   TEXT,
    percent_salary_hike        INTEGER,
    performance_rating         INTEGER,
    relationship_satisfaction  INTEGER,
    standard_hours             INTEGER,
    stock_option_level         INTEGER,
    total_working_years        INTEGER,
    training_times_last_year   INTEGER,
    work_life_balance          INTEGER,
    years_at_company           INTEGER,
    years_in_current_role      INTEGER,
    years_since_last_promotion INTEGER,
    years_with_curr_manager    INTEGER
);


-- =====================================================
-- DATA LOADING
-- TRUNCATE empties the table first so no duplicates
-- so that when we COPY it reloads fresh data every run
-- place the dataset in C:/pgdata/ and update path if needed
-- original CSV uses camelCase column names, mapped to snake_case below
-- =====================================================

TRUNCATE TABLE hr_analytics.employee_attrition;

COPY hr_analytics.employee_attrition(
    age, attrition, business_travel, daily_rate, department,
    distance_from_home, education, education_field, employee_count,
    employee_number, environment_satisfaction, gender, hourly_rate,
    job_involvement, job_level, job_role, job_satisfaction,
    marital_status, monthly_income, monthly_rate, num_companies_worked,
    over18, overtime, percent_salary_hike, performance_rating,
    relationship_satisfaction, standard_hours, stock_option_level,
    total_working_years, training_times_last_year, work_life_balance,
    years_at_company, years_in_current_role, years_since_last_promotion,
    years_with_curr_manager)
FROM 'C:/pgdata/HR-Employee-Attrition-All.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');


-- =====================================================
-- SECTION A: DATA EXPLORATION
-- =====================================================

-- Row count, verify data loaded correctly
SELECT COUNT(*) FROM hr_analytics.employee_attrition;

-- Quick look at the table
SELECT * FROM hr_analytics.employee_attrition LIMIT 5;

-- Overall attrition distribution
SELECT attrition, COUNT(*) AS total
FROM hr_analytics.employee_attrition
GROUP BY attrition;

-- Check useless columns (same value for every row, no analytical value)
-- over18 = 'Y' for all, employee_count = 1 for all, standard_hours = 80 for all
SELECT DISTINCT over18, employee_count, standard_hours
FROM hr_analytics.employee_attrition;

-- Check categorical values for any dirty entries
SELECT DISTINCT business_travel FROM hr_analytics.employee_attrition;
SELECT DISTINCT department      FROM hr_analytics.employee_attrition;
SELECT DISTINCT job_role        FROM hr_analytics.employee_attrition;
SELECT DISTINCT marital_status  FROM hr_analytics.employee_attrition;
SELECT DISTINCT overtime        FROM hr_analytics.employee_attrition;
SELECT DISTINCT education_field FROM hr_analytics.employee_attrition;

-- Check numeric ranges
SELECT
    MIN(age)                AS min_age,
    MAX(age)                AS max_age,
    MIN(monthly_income)     AS min_income,
    MAX(monthly_income)     AS max_income,
    MIN(distance_from_home) AS min_distance,
    MAX(distance_from_home) AS max_distance,
    MIN(years_at_company)   AS min_years,
    MAX(years_at_company)   AS max_years
FROM hr_analytics.employee_attrition;

-- Null check
SELECT
    COUNT(*)                              AS total,
    COUNT(*) - COUNT(attrition)           AS null_attrition,
    COUNT(*) - COUNT(department)          AS null_dept,
    COUNT(*) - COUNT(monthly_income)      AS null_income,
    COUNT(*) - COUNT(job_role)            AS null_job_role
FROM hr_analytics.employee_attrition;

-- DATA QUALITY NOTE
-- Dataset came pre-cleaned, no nulls, no dirty string values found
-- over18, employee_count, standard_hours have identical values across all rows
-- These three columns are excluded from the clean table as they add no analytical value


-- =====================================================
-- SECTION B: DATA PREPARATION
-- =====================================================

-- attrition_flag added as INTEGER (1 = left, 0 = stayed)
-- allows SUM for headcount and AVG for rate across all queries
-- over18, employee_count, standard_hours dropped since all rows are identical

DROP TABLE IF EXISTS clean_attrition;
CREATE TEMP TABLE clean_attrition AS
SELECT
    age,
    CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END AS attrition_flag,
    attrition,
    business_travel,
    daily_rate,
    department,
    distance_from_home,
    education,
    education_field,
    employee_number,
    environment_satisfaction,
    gender,
    hourly_rate,
    job_involvement,
    job_level,
    job_role,
    job_satisfaction,
    marital_status,
    monthly_income,
    monthly_rate,
    num_companies_worked,
    overtime,
    percent_salary_hike,
    performance_rating,
    relationship_satisfaction,
    stock_option_level,
    total_working_years,
    training_times_last_year,
    work_life_balance,
    years_at_company,
    years_in_current_role,
    years_since_last_promotion,
    years_with_curr_manager
FROM hr_analytics.employee_attrition;

-- Verify row count matches original
SELECT COUNT(*) FROM clean_attrition;


-- =====================================================
-- SECTION C: ATTRITION OVERVIEW
-- =====================================================

-- BQ1: What is the overall attrition rate?
-- AVG(attrition_flag) works because flag is 1 or 0, average gives the proportion directly
SELECT
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition;

-- BQ2: Attrition by department
SELECT
    department,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- BQ3: Attrition by job role
SELECT
    job_role,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY job_role
ORDER BY attrition_rate_pct DESC;

-- BQ4: Attrition by gender
SELECT
    gender,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY gender
ORDER BY attrition_rate_pct DESC;

-- BQ5: Attrition by marital status
SELECT
    marital_status,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;


-- =====================================================
-- SECTION D: WORK FACTORS ANALYSIS
-- =====================================================

-- CQ1: Attrition by overtime
-- Overtime is the single strongest predictor in the dataset
SELECT
    overtime,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY overtime
ORDER BY attrition_rate_pct DESC;

-- CQ2: Attrition by business travel category
SELECT
    business_travel,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY business_travel
ORDER BY attrition_rate_pct DESC;

-- CQ3: Attrition by distance from home (banded)
-- max distance in this dataset is 29 so Very Far band never triggers
-- MIN(distance_from_home) used in ORDER BY to sort bands correctly without numbering labels
SELECT
    CASE
        WHEN distance_from_home BETWEEN 0  AND 5  THEN 'Near'
        WHEN distance_from_home BETWEEN 6  AND 15 THEN 'Medium'
        WHEN distance_from_home BETWEEN 16 AND 29 THEN 'Far'
        ELSE 'Very Far'
    END AS distance_group,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY distance_group
ORDER BY MIN(distance_from_home);


-- =====================================================
-- SECTION E: CAREER AND SATISFACTION ANALYSIS
-- =====================================================

-- DQ1: Attrition by total working years (banded)
-- Early career employees (0-5 years) leave at nearly 4x the rate of veterans (21+)
SELECT
    CASE
        WHEN total_working_years BETWEEN 0  AND 5  THEN '0-5'
        WHEN total_working_years BETWEEN 6  AND 10 THEN '6-10'
        WHEN total_working_years BETWEEN 11 AND 20 THEN '11-20'
        ELSE '21+'
    END AS working_years_band,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY working_years_band
ORDER BY MIN(total_working_years);

-- DQ2: Attrition by number of companies worked (banded)
SELECT
    CASE
        WHEN num_companies_worked <= 1                    THEN '1'
        WHEN num_companies_worked BETWEEN 2 AND 3         THEN '2-3'
        WHEN num_companies_worked BETWEEN 4 AND 6         THEN '4-6'
        ELSE '7+'
    END AS companies_worked_band,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY companies_worked_band
ORDER BY MIN(num_companies_worked);

-- DQ3: Attrition by years with current manager (banded)
-- Employees with 0-2 years with their manager leave at 21% vs 4% for those with 11+ years
SELECT
    CASE
        WHEN years_with_curr_manager BETWEEN 0  AND 2  THEN '0-2'
        WHEN years_with_curr_manager BETWEEN 3  AND 5  THEN '3-5'
        WHEN years_with_curr_manager BETWEEN 6  AND 10 THEN '6-10'
        ELSE '11+'
    END AS manager_years_band,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY manager_years_band
ORDER BY MIN(years_with_curr_manager);

-- DQ4: Attrition by education field
SELECT
    education_field,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY education_field
ORDER BY attrition_rate_pct DESC;

-- DQ5: Attrition by job satisfaction score (1-4)
-- 1 = lowest satisfaction, 4 = highest
SELECT
    job_satisfaction,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY job_satisfaction
ORDER BY job_satisfaction;


-- =====================================================
-- SECTION F: COMBINED RISK PROFILE
-- =====================================================

-- First attempt: filter approach
-- Stacking too many conditions results in very few rows, not useful for broad insights
-- Keeping this as documentation of what was tried before moving to the scoring approach
SELECT
    COUNT(*)        AS high_risk_count,
    overtime,
    business_travel AS travels_frequently,
    job_satisfaction AS low_job_satisfaction,
    total_working_years AS early_career
FROM clean_attrition
WHERE overtime = 'Yes'
AND business_travel = 'Travel_Frequently'
AND job_satisfaction IN (1, 2)
AND total_working_years IN (0, 1)
GROUP BY overtime, business_travel, job_satisfaction, total_working_years;

-- EQ1: Employee risk scoring
-- Each high risk factor contributes 1 point based on findings from sections C, D, E
-- Risk factors chosen: overtime, frequent travel, low job satisfaction,
-- early career, far distance, short manager tenure
-- Higher score = higher attrition risk
SELECT
    employee_number,
    department,
    job_role,
    monthly_income,
    attrition,
    (
        CASE WHEN overtime = 'Yes'                          THEN 1 ELSE 0 END +
        CASE WHEN business_travel = 'Travel_Frequently'     THEN 1 ELSE 0 END +
        CASE WHEN job_satisfaction IN (1, 2)                THEN 1 ELSE 0 END +
        CASE WHEN total_working_years BETWEEN 0 AND 5       THEN 1 ELSE 0 END +
        CASE WHEN distance_from_home BETWEEN 16 AND 29      THEN 1 ELSE 0 END +
        CASE WHEN years_with_curr_manager BETWEEN 0 AND 2   THEN 1 ELSE 0 END
    ) AS risk_score
FROM clean_attrition
ORDER BY risk_score DESC
LIMIT 20;

-- EQ2: Risk score validation against actual attrition
-- Checks whether higher scores actually correlate with higher attrition rates
WITH scored AS (
    SELECT
        attrition_flag,
        (
            CASE WHEN overtime = 'Yes'                          THEN 1 ELSE 0 END +
            CASE WHEN business_travel = 'Travel_Frequently'     THEN 1 ELSE 0 END +
            CASE WHEN job_satisfaction IN (1, 2)                THEN 1 ELSE 0 END +
            CASE WHEN total_working_years BETWEEN 0 AND 5       THEN 1 ELSE 0 END +
            CASE WHEN distance_from_home BETWEEN 16 AND 29      THEN 1 ELSE 0 END +
            CASE WHEN years_with_curr_manager BETWEEN 0 AND 2   THEN 1 ELSE 0 END
        ) AS risk_score
    FROM clean_attrition
)
SELECT
    risk_score,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM scored
GROUP BY risk_score
ORDER BY risk_score DESC;

-- KEY FINDING: Risk score validates cleanly across all levels
-- Score 0 = 6.60% attrition, Score 5 = 81.82% attrition
-- Every level increases consistently, no noise in the pattern
-- Employees with 5 risk factors leave at 12x the rate of those with none
-- A real HR team could use this scoring model to flag at-risk employees before they resign