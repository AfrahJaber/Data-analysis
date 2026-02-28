/*
================================================================================
PROJECT: Hospital Operational Efficiency & Patient Flow Analysis
AUTHOR: [Afrah Alanazi]
DESCRIPTION: 
    This project analyzes hospital performance data to identify operational 
    bottlenecks, evaluate staffing workloads, and optimize patient care for 
    elderly demographics.
    
KEY DELIVERABLES:
    - Data Cleaning & Normalization (TRIM, Data Integrity Checks).
    - Feature Engineering (Stay_Duration calculation).
    - Departmental Performance Metrics (Satisfaction vs. Rejection).
    - Resource Allocation Analysis (Staffing Efficiency).
    
METHODOLOGY: Follows the Google Data Analytics professional framework 
            (Ask, Prepare, Process, Analyze, Share, Act).
================================================================================
*/

-- 1. Data Normalization (Trimming hidden white spaces)
UPDATE patients SET service = TRIM(Service);
UPDATE services_weekly SET Service = TRIM(Service);
UPDATE staff SET Service = TRIM(Service);
UPDATE staff_schedule SET Service = TRIM(Service);

-- 2. Handling Missing Values (Filling Nulls in 'Event' column)
UPDATE services_weekly
SET Event = 'Normal'
WHERE Event IS NULL OR Event = '';

-- 3. Data Integrity Cleaning (Removing logical date errors in 'patients' table)
DELETE FROM patients 
WHERE Departure_Date < Arrival_Date;

-- 4. Feature Engineering: Creating 'Stay_Duration' (Key metric for bed turnover analysis)

-- Step 4.1: Adding the new column
ALTER TABLE patients ADD Stay_Duration INT;
GO

-- Step 4.2: Calculating duration (Difference in days)
UPDATE patients 
SET Stay_Duration = DATEDIFF(day, Arrival_Date, Departure_Date);

/* Unit: Day (Difference in days)
   Start: Arrival_Date
   End: Departure_Date  
*/

-- Step 4.3: Previewing the engineered data
SELECT TOP 10 Service, Arrival_Date, Departure_Date, Stay_Duration
FROM patients
ORDER BY Arrival_Date DESC;

-- 5. Strategic Analysis: Identifying bottlenecks and congestion by service
SELECT 
    p.Service, 
    ROUND(AVG(p.Stay_Duration), 1) AS Avg_Stay_Days, -- Average bed occupancy days
    SUM(s.patients_refused) AS Total_patients_refused, -- Total rejected patients from services table
    ROUND(AVG(s.Patient_Satisfaction), 1) AS Avg_Satisfaction
FROM patients p
JOIN services_weekly s ON p.Service = s.Service
GROUP BY p.Service
ORDER BY Total_patients_refused DESC;


-- 6. Resource Allocation Analysis: Do we need more staff or more beds?
SELECT 
    sw.service,
    -- Calculating workload: Admitted patients per present staff member
    SUM(sw.patients_admitted) / NULLIF(SUM(CAST(sch.present AS INT)), 0) AS patients_per_staff, 
    AVG(sw.staff_morale) AS avg_staff_morale,
    SUM(sw.patients_refused) AS total_refused
FROM services_weekly sw
JOIN staff_schedule sch ON sw.service = sch.service AND sw.week = sch.week
WHERE sch.present = 1 
GROUP BY sw.service
ORDER BY patients_per_staff DESC;


-- 7. Geriatric Care Analysis: Analyzing elderly patient (Age >= 60) behavior
SELECT 
    service, 
    AVG(satisfaction) AS elderly_satisfaction,
    AVG(Stay_Duration) AS avg_stay
FROM patients
WHERE age >= 60
GROUP BY service;
