# HR Employee Attrition Analysis

## Table of Contents
- [Business Context](#business-context)
- [Dataset Overview](#dataset-overview)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Data Preparation](#data-preparation)
- [C. Attrition Overview](#c-attrition-overview)
- [D. Work Factors Analysis](#d-work-factors-analysis)
- [E. Career and Satisfaction Analysis](#e-career-and-satisfaction-analysis)
- [F. Combined Risk Profile](#f-combined-risk-profile)
- [Key Findings](#key-findings)

> Dataset sourced from: [HR Employee Attrition on Kaggle via Pplonski github project](https://github.com/pplonski/datasets-for-start/blob/master/employee_attrition/HR-Employee-Attrition-All.csv)

---

## Business Context

Employee attrition is one of the most expensive problems a company can have. Replacing a single employee can cost anywhere from 50% to 200% of their annual salary when you factor in recruiting, onboarding, and lost productivity. The earlier a company can identify who is likely to leave, the better chance they have of doing something about it.

This project analyzes 1,470 employee records to answer: which departments and roles have the highest attrition, which work conditions drive people out, and whether we can build a simple risk model that flags employees before they resign.

---

## Dataset Overview

| Table | Rows | Columns | Description |
|---|---|---|---|
| `employee_attrition` | 1,470 | 35 | Employee demographics, job details, satisfaction scores, and attrition status |

The dataset came pre-cleaned with no nulls or dirty values. Three columns were excluded from analysis because they contain the same value for every row: `over18` (always Y), `employee_count` (always 1), and `standard_hours` (always 80).

---

## Entity Relationship Diagram

![ERD](https://github.com/user-attachments/assets/your-erd-image-here)

---

## Data Preparation

> The dataset was already clean so no heavy cleaning was needed. The main preparation step was adding an `attrition_flag` column as a binary integer so we can use `SUM` for headcount and `AVG` for rates consistently across every query without repeating `COUNT(CASE WHEN...)` logic everywhere.

```sql
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
```

**Key decision:**
- `attrition_flag` as `INTEGER` means `SUM(attrition_flag)` = employees who left, `AVG(attrition_flag) * 100` = attrition rate percentage. Cleaner than repeating `COUNT(CASE WHEN attrition = 'Yes' THEN 1 END)` in every query.

---

## C. Attrition Overview

> This section establishes the baseline numbers before drilling into specific factors. Overall rate, then broken down by department, job role, gender, and marital status.

---

### BQ1. What is the overall attrition rate?

```sql
SELECT
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition;
```

**Result:**
| total_employees | total_left | attrition_rate_pct |
|---|---|---|
| 1470 | 237 | 16.12% |

- About 1 in 6 employees left. That's the headline number for the whole project.

---

### BQ2. Attrition by department

```sql
SELECT
    department,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| department | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Sales | 446 | 92 | 20.63% |
| Human Resources | 63 | 12 | 19.05% |
| Research & Development | 961 | 133 | 13.84% |

- Sales and HR both lose roughly 1 in 5 employees
- R&D is the most stable despite being the largest department

---

### BQ3. Attrition by job role

```sql
SELECT
    job_role,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY job_role
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| job_role | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Sales Representative | 83 | 33 | 39.76% |
| Human Resources | 52 | 12 | 23.08% |
| Laboratory Technician | 259 | 62 | 23.94% |
| Research Scientist | 292 | 47 | 16.10% |
| Sales Executive | 326 | 57 | 17.48% |
| Manufacturing Director | 145 | 10 | 6.90% |
| Healthcare Representative | 131 | 9 | 6.87% |
| Manager | 102 | 5 | 4.90% |
| Research Director | 80 | 2 | 2.50% |

- Sales Representative stands out at 39.76%, nearly 4 in 10 left
- Research Director and Manager are the most stable at under 5%

---

### BQ4. Attrition by gender

```sql
SELECT
    gender,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY gender
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| gender | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Male | 882 | 150 | 17.01% |
| Female | 588 | 87 | 14.80% |

- Males leave slightly more but the gap is not dramatic at ~2 percentage points

---

### BQ5. Attrition by marital status

```sql
SELECT
    marital_status,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| marital_status | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Single | 470 | 120 | 25.53% |
| Married | 673 | 84 | 12.48% |
| Divorced | 327 | 33 | 10.09% |

- Single employees leave at more than double the rate of divorced employees
- Likely connected to career stage, younger employees are more willing to job hop

---

## D. Work Factors Analysis

> This section looks at job conditions that are within the company's control: overtime, travel requirements, and commuting distance. These are factors a company could actually change to improve retention.

---

### CQ1. Attrition by overtime

```sql
SELECT
    overtime,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY overtime
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| overtime | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Yes | 416 | 127 | 30.53% |
| No | 1054 | 110 | 10.44% |

- Overtime employees leave at nearly 3x the rate of those who don't work overtime
- This is the single strongest predictor of attrition in the entire dataset

---

### CQ2. Attrition by business travel

```sql
SELECT
    business_travel,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY business_travel
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| business_travel | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Travel_Frequently | 277 | 69 | 24.91% |
| Travel_Rarely | 1043 | 156 | 14.96% |
| Non-Travel | 150 | 12 | 8.00% |

- Frequent travelers leave at 3x the rate of non-travelers
- Even occasional travel doubles attrition compared to no travel

---

### CQ3. Attrition by distance from home

```sql
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
```

**Approach:**
- `MIN(distance_from_home)` in `ORDER BY` sorts the bands correctly without numbering the labels
- Max distance in this dataset is 29 so the Very Far band never appears

**Result:**
| distance_group | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Near (0-5km) | 632 | 87 | 13.77% |
| Medium (6-15km) | 509 | 82 | 16.11% |
| Far (16-29km) | 329 | 68 | 20.67% |

- Clear pattern: the further from home, the higher the attrition
- Nearly 7 percentage point difference between nearest and farthest group

---

## E. Career and Satisfaction Analysis

> This section looks at career history and job experience factors. Most of these are harder for a company to control directly but help identify which employee profiles are at highest risk.

---

### DQ1. Attrition by total working years

```sql
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
```

**Result:**
| working_years_band | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| 0-5 | 316 | 91 | 28.80% |
| 6-10 | 607 | 91 | 14.99% |
| 11-20 | 340 | 39 | 11.47% |
| 21+ | 207 | 16 | 7.73% |

- Early career employees (0-5 years) leave at nearly 4x the rate of veterans (21+)
- Clear inverse relationship between experience and attrition

---

### DQ2. Attrition by number of companies worked

```sql
SELECT
    CASE
        WHEN num_companies_worked <= 1            THEN '1'
        WHEN num_companies_worked BETWEEN 2 AND 3 THEN '2-3'
        WHEN num_companies_worked BETWEEN 4 AND 6 THEN '4-6'
        ELSE '7+'
    END AS companies_worked_band,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY companies_worked_band
ORDER BY MIN(num_companies_worked);
```

**Result:**
| companies_worked_band | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| 1 | 718 | 121 | 16.85% |
| 2-3 | 305 | 32 | 10.49% |
| 4-6 | 272 | 49 | 18.01% |
| 7+ | 175 | 35 | 20.00% |

- Employees who have only worked at 1 company and those who have worked at 7+ are both higher risk
- The 2-3 companies group is the most stable at 10.49%

---

### DQ3. Attrition by years with current manager

```sql
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
```

**Result:**
| manager_years_band | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| 0-2 | 683 | 146 | 21.38% |
| 3-5 | 271 | 34 | 12.55% |
| 6-10 | 443 | 54 | 12.19% |
| 11+ | 73 | 3 | 4.11% |

- Employees with 0-2 years under their current manager are at highest risk at 21.38%
- Once manager tenure reaches 6+ years attrition drops below 13%
- Manager stability is clearly a retention factor worth investing in

---

### DQ4. Attrition by education field

```sql
SELECT
    education_field,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY education_field
ORDER BY attrition_rate_pct DESC;
```

**Result:**
| education_field | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| Human Resources | 27 | 7 | 25.93% |
| Technical Degree | 132 | 32 | 24.24% |
| Marketing | 159 | 35 | 22.01% |
| Life Sciences | 606 | 89 | 14.69% |
| Medical | 464 | 63 | 13.58% |
| Other | 82 | 11 | 13.41% |

- HR and Technical Degree backgrounds leave most frequently
- Life Sciences and Medical backgrounds are the most stable

---

### DQ5. Attrition by job satisfaction score

```sql
SELECT
    job_satisfaction,
    COUNT(*)                              AS total_employees,
    SUM(attrition_flag)                   AS total_left,
    ROUND(AVG(attrition_flag) * 100.0, 2) AS attrition_rate_pct
FROM clean_attrition
GROUP BY job_satisfaction
ORDER BY job_satisfaction;
```

**Result:**
| job_satisfaction | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| 1 (lowest) | 289 | 66 | 22.84% |
| 2 | 280 | 46 | 16.43% |
| 3 | 442 | 73 | 16.52% |
| 4 (highest) | 459 | 52 | 11.33% |

- Lowest satisfaction group leaves at double the rate of the highest satisfaction group
- Scores 2 and 3 are surprisingly similar at around 16%

---

## F. Combined Risk Profile

> The individual factors paint a clear picture. This section puts them together into a scoring model to identify which employees carry the most risk all at once.

---

### EQ1. Employee risk scoring

Each risk factor identified in sections D and E contributes 1 point. Higher score means higher attrition risk.

```sql
SELECT
    employee_number,
    department,
    job_role,
    monthly_income,
    attrition,
    (
        CASE WHEN overtime = 'Yes'                        THEN 1 ELSE 0 END +
        CASE WHEN business_travel = 'Travel_Frequently'   THEN 1 ELSE 0 END +
        CASE WHEN job_satisfaction IN (1, 2)              THEN 1 ELSE 0 END +
        CASE WHEN total_working_years BETWEEN 0 AND 5     THEN 1 ELSE 0 END +
        CASE WHEN distance_from_home BETWEEN 16 AND 29    THEN 1 ELSE 0 END +
        CASE WHEN years_with_curr_manager BETWEEN 0 AND 2 THEN 1 ELSE 0 END
    ) AS risk_score
FROM clean_attrition
ORDER BY risk_score DESC
LIMIT 20;
```

**Approach:**
- Risk factors chosen based on findings from sections D and E
- Filter approach was tried first but stacking too many conditions left too few rows to be useful
- Scoring approach keeps all employees in the output and ranks them instead

---

### EQ2. Risk score validation

```sql
WITH scored AS (
    SELECT
        attrition_flag,
        (
            CASE WHEN overtime = 'Yes'                        THEN 1 ELSE 0 END +
            CASE WHEN business_travel = 'Travel_Frequently'   THEN 1 ELSE 0 END +
            CASE WHEN job_satisfaction IN (1, 2)              THEN 1 ELSE 0 END +
            CASE WHEN total_working_years BETWEEN 0 AND 5     THEN 1 ELSE 0 END +
            CASE WHEN distance_from_home BETWEEN 16 AND 29    THEN 1 ELSE 0 END +
            CASE WHEN years_with_curr_manager BETWEEN 0 AND 2 THEN 1 ELSE 0 END
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
```

**Result:**
| risk_score | total_employees | total_left | attrition_rate_pct |
|---|---|---|---|
| 5 | 22 | 18 | 81.82% |
| 4 | 92 | 44 | 47.83% |
| 3 | 253 | 60 | 23.72% |
| 2 | 462 | 66 | 14.29% |
| 1 | 429 | 35 | 8.16% |
| 0 | 212 | 14 | 6.60% |

- Every single level increases consistently with no noise in the pattern
- Score 5 employees leave at 81.82%, more than 8 in 10
- Score 0 employees leave at only 6.60%
- Employees with all 5 risk factors leave at 12x the rate of those with none

---

## Key Findings

The overall attrition rate is 16.12%, about 1 in 6 employees. Sales has the worst attrition by department at 20.63%, and Sales Representatives specifically are in a critical state at 39.76%.

The most important work condition by far is overtime. Employees working overtime leave at 30.53% compared to 10.44% for those who don't. That's nearly a 3x difference from a single factor. Frequent travel compounds this further at 24.91%, and even just living far from the office pushes attrition up to 20.67%.

On the career side, early career employees (0-5 total working years) are the most likely to leave at 28.80%, and employees who are newer to their current manager (0-2 years) are at 21.38%. Manager stability and career experience both play a significant role.

The risk scoring model in Section F brings this all together. Using just 6 binary flags built from the analysis above, the model cleanly separates low risk from high risk employees across every score level. An employee with a score of 5 has an 81.82% chance of leaving. An employee with a score of 0 has a 6.60% chance. A real HR team could run this model monthly, flag anyone scoring 4 or 5, and prioritize them for a retention conversation before they hand in their notice.

---

*Built with PostgreSQL 18 + pgAdmin 4*
