
USE portfolio_covid
--CREATING CALCULATION FOR NEW cases AND deaths BY USING LAG() FUNCTION
DROP TABLE IF EXISTS #temp_new;

WITH cte_lag AS
(
    SELECT
        date,
        state,
        cases,
        deaths,
        LAG(deaths, 1, NULL) OVER (PARTITION BY fips ORDER BY date) AS deaths_lag,
        LAG(cases, 1, NULL) OVER (PARTITION BY fips ORDER BY date) AS cases_lag
    FROM
        us_states
)

-- CREATING COLUMN FOR CHANGE OF cases AND deaths IN NEW TEMP TABLE
SELECT *,
       deaths - deaths_lag AS new_deaths,
       cases - cases_lag AS new_cases,

	   CASE 
	   WHEN deaths>deaths_lag THEN 'incline'
	   WHEN deaths<deaths_lag THEN 'decline'
	   WHEN deaths_lag IS NULL THEN NULL
	   ELSE 'constant' END AS daily_deaths_status,

	   CASE 
	   WHEN cases>cases_lag THEN 'incline'
	   WHEN cases<cases_lag THEN 'decline'
	   WHEN cases_lag IS NULL THEN NULL
	   ELSE 'constant' END AS daily_cases_status


INTO #temp_new
FROM cte_lag;

SELECT * FROM #temp_new;
--CHECKS IF QUERIES WORK PROPERLY
SELECT * FROM #temp_new
WHERE state like '%' -- JUST TO BE ABLE TO SELECT WHATEVER state
ORDER BY date;

SELECT * FROM #temp_new
WHERE state like '%' AND daily_cases_status != daily_deaths_status
ORDER BY date;

--MAX new_cases state
SELECT t1.state, t1.date, t1.new_cases
FROM #temp_new t1
WHERE t1.new_cases = (SELECT MAX(t2.new_cases) FROM #temp_new t2 WHERE t2.state = t1.state)
ORDER BY new_cases DESC;

--MAX new_deaths state
SELECT t1.state, t1.date, t1.new_deaths
FROM #temp_new t1
WHERE t1.new_deaths = (SELECT MAX(t2.new_deaths) FROM #temp_new t2 WHERE t2.state = t1.state)
ORDER BY new_deaths DESC;

--COUNTING STATUSES PER state AND year
DROP TABLE IF EXISTS #count_status
SELECT
    state,
    YEAR(date) AS year,
    COUNT(CASE WHEN daily_deaths_status LIKE 'incline' THEN 1 END) AS deaths_incline_ct,
    COUNT(CASE WHEN daily_deaths_status LIKE 'decline' THEN 1 END) AS deaths_decline_ct,
    COUNT(CASE WHEN daily_deaths_status LIKE 'constant' THEN 1 END) AS deaths_constant_ct

INTO #count_status
FROM #temp_new

GROUP BY
    state, YEAR(date)

--CHECKING IF statuses counts ARE EQUAL TO DAYS IN CALENDAR YEAR
SELECT state, year, deaths_incline_ct+deaths_decline_ct+deaths_constant_ct
FROM #count_status

--IT IS NOT us_states TABLE LACKS DATA MOSTLY FROM 2020 WHEN COVID EPIDEMIC JUST STARTED AND 2023 BECAUSE THE YEAR IS NOT OVER DURING THE ANALYSIS
SELECT state, 
AVG(deaths_incline_ct+deaths_decline_ct+deaths_constant_ct) AS state_avg
FROM #count_status
WHERE year !=2023
GROUP BY state;

--NATION WIDE AVERAGE NUMBER OF REPORTING DAYS EXCEPT 2020
SELECT
AVG(deaths_incline_ct+deaths_decline_ct+deaths_constant_ct) AS nation_avg
FROM #count_status
WHERE year !=2023 

--CREATING TEMP TABLE FOR deaths AND cases RANKING
DROP TABLE IF EXISTS #temp_max 

SELECT 
    date,
    state,
    cases,
    deaths,
    RANK() OVER(PARTITION BY state ORDER BY deaths DESC) AS death_rank,
    RANK() OVER(PARTITION BY state ORDER BY cases DESC) AS cases_rank
INTO 
    #temp_max 
FROM 
    us_states
--CALCULATING MAX DEATHS&CASES GROUPPED BY STATE !WITH DATE!
SELECT * FROM #temp_max 
WHERE death_rank=1 OR cases_rank=1
ORDER BY state

--HOW OFTEN IF death_rank MATCHES cases_rank?
SELECT COUNT(*) FROM #temp_max WHERE death_rank = cases_rank

--IN WHICH CASES DOES IT MATCH?
SELECT * FROM #temp_max WHERE death_rank = cases_rank

--CREATING TEMP TABLE FOR ROLLING CASES AND ROLLING DEATHS
SELECT
date,state,cases,deaths,
SUM(deaths) OVER(PARTITION BY fips ORDER BY date) AS rolling_deaths,
SUM(cases) OVER(PARTITION BY fips ORDER BY date) AS rolling_cases
INTO 
    #temp_rolling 
FROM us_states

SELECT * FROM #temp_rolling ;
--CREATING cte FOR DIFFERENCES AND PRECENTAGES BETWEEN DAYS
WITH rolling_cte AS
(
    SELECT 
        date,
        state,
        cases,
        deaths,
        cases - deaths AS diff,
        rolling_cases - rolling_deaths AS rolling_diff
    FROM 
        #temp_rolling 
)

SELECT r.*
FROM rolling_cte r
WHERE EXISTS (
    SELECT 1
    FROM rolling_cte sub
    WHERE sub.state = r.state 
    GROUP BY YEAR(date), sub.state
    HAVING MIN(sub.rolling_diff) = r.rolling_diff
)
ORDER BY state,date;
--CREATING ROLLING SUMS OF cases AND deaths IS NOT APROPIERATE IN THIS CASE BEACUSE cases AND deaths REPRESNT TOTAL NUMBER OF cases AND deaths FOR PEROID FROM START UNTIL THE LAST ANALISED DAY
DROP TABLE IF EXISTS #temp_rolling;



