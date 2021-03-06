which data set we want to see
SELECT *
FROM `bigquery-public-data.covid19_google_mobility.mobility_report`

SELECT distinct country_region
FROM `bigquery-public-data.covid19_google_mobility.mobility_report` 


SELECT * FROM `bigquery-public-data.covid19_open_data.covid19_open_data` LIMIT 1000

SELECT DISTINCT country_name FROM `bigquery-public-data.covid19_open_data.covid19_open_data` LIMIT 1000


https://storage.googleapis.com/gcp-public-data-symptom-search/COVID-19%20Search%20Trends%20symptoms%20dataset%20documentation%20.pdf


SELECT distinct country_region, max(date), min(date)  
FROM `bigquery-public-data.covid19_vaccination_search_insights.covid19_vaccination_search_insights` 

group by 1

-- SELECT countries_and_territories,
-- pop_data_2019,
-- confirmed_cases,	
-- deaths
-- FROM `bigquery-public-data.covid19_ecdc.covid_19_geographic_distribution_worldwide` 
-- where date = "2020-10-01"

SELECT distinct countries_and_territories

FROM `bigquery-public-data.covid19_ecdc.covid_19_geographic_distribution_worldwide` 
where date = "2020-10-01"
order by 1


query 1: Total Confirmed Cases

SELECT sum(cumulative_confirmed) AS total_cases_worldwide 
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE date='2020-04-15'

query 1b: Total Confirmed Cases

Select 
location_key,
sum(new_deceased),
sum(population) 
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE 
country_name="United States of America" 
AND date='2020-04-10'
-- AND subregion1_name is NOT NULL
-- GROUP BY subregion1_name
group by 1


Query 1c
Select 
country_name,
sum(new_deceased),
sum(population) 
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE 
country_name in ("Vietnam","Singapore","Malaysia")
AND date='2020-04-10'
-- AND subregion1_name is NOT NULL
-- GROUP BY subregion1_name
group by 1

Query 2: Worst Affected Areas - death count 

WITH deaths_by_states AS (
SELECT subregion1_name AS state, sum(cumulative_deceased) AS death_count
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE country_name="United States of America" AND date='2020-04-10' AND subregion1_name is NOT NULL
GROUP BY subregion1_name
)

SELECT count(*) as count_of_states
FROM deaths_by_states
WHERE death_count > 100


Query 2: Worst Affected Areas - by death count rate

WITH deaths_by_states AS (
SELECT subregion1_name AS state, sum(new_deceased)/ sum(population) AS death_count_rate
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE 
country_name="United States of America" 
AND date='2020-04-10'
AND subregion1_name is NOT NULL
GROUP BY subregion1_name
)

SELECT count(*) as count_of_states
FROM deaths_by_states
WHERE death_count_rate > 0.001



Query 3: Identifying Hotspots

SELECT subregion1_name as state, sum(cumulative_confirmed) as total_confirmed_cases 
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE country_name="United States of America" and date='2020-04-10' and subregion1_name is NOT NULL
GROUP BY subregion1_name
HAVING total_confirmed_cases > 1000
ORDER BY total_confirmed_cases desc



Query 4: Fatality Ratio

SELECT sum(cumulative_confirmed) as total_confirmed_cases, sum(cumulative_deceased) as total_deaths,
(sum(cumulative_deceased)/sum(cumulative_confirmed))*100 as case_fatality_ratio
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE country_name="Italy" and date BETWEEN "2020-04-01" AND "2020-04-30"



Query 5: Identifying specific day

SELECT date
FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
WHERE country_name="Italy" and cumulative_deceased>10000
ORDER BY date asc
LIMIT 1



Query 6: Finding days with zero net new cases

WITH india_cases_by_date AS (
SELECT
    date,
    SUM( cumulative_confirmed ) AS cases 
    FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name ="India"
    AND date between '2020-02-21' and '2020-03-15'
  GROUP BY
    date
  ORDER BY
    date ASC 
 )
, india_previous_day_comparison AS 
(SELECT
  date,
  cases,
  LAG(cases) OVER(ORDER BY date) AS previous_day,
  cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
FROM india_cases_by_date
)
SELECT count(*)
FROM india_previous_day_comparison
WHERE net_new_cases=0



Query 7: Doubling rate

WITH us_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="United States of America"
    AND date between '2020-03-22' and '2020-04-20'
  GROUP BY
    date
  ORDER BY
    date ASC 
 )
, us_previous_day_comparison AS 
(SELECT
  date,
  cases,
  LAG(cases) OVER(ORDER BY date) AS previous_day,
  cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
  (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
FROM us_cases_by_date
)
SELECT 
Date, 
cases as Confirmed_Cases_On_Day, 
previous_day as Confirmed_Cases_Previous_Day, 
percentage_increase as Percentage_Increase_In_Cases
FROM us_previous_day_comparison
WHERE percentage_increase > 10



Query 8: Recovery rate

WITH cases_by_country AS (
  SELECT
    country_name AS country,
    sum(cumulative_confirmed) AS cases,
    sum(cumulative_recovered) AS recovered_cases
  FROM
    bigquery-public-data.covid19_open_data.covid19_open_data
  WHERE
    date = '2020-05-10'
  GROUP BY
    country_name
 )
, recovered_rate AS 
(SELECT
  country, cases, recovered_cases,
  (recovered_cases * 100)/cases AS recovery_rate
FROM cases_by_country
)
SELECT 
country, 
cases AS confirmed_cases, 
recovered_cases, 
recovery_rate
FROM recovered_rate
WHERE cases > 50000
ORDER BY recovery_rate desc
LIMIT 10



Query 9: CDGR - Cumulative Daily Growth Rate

WITH
  france_cases AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS total_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="France"
    AND date IN ('2020-01-24',
      '2020-05-10')
  GROUP BY
    date
  ORDER BY
    date)
, common_table_expression as (
SELECT
  total_cases AS first_day_cases,
  LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
  DATE_DIFF(LEAD(date) OVER(ORDER BY date),date, day) AS days_diff
FROM
  france_cases
LIMIT 1
)
SELECT 
first_day_cases, 
last_day_cases, 
days_diff, 
POW((last_day_cases/first_day_cases),
(1/days_diff))-1 as cdgr
FROM common_table_expression



Query 10: Create a Datastudio report

SELECT
  date, SUM(cumulative_confirmed) AS country_cases,
  SUM(cumulative_deceased) AS country_deaths
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date BETWEEN '2020-03-15'
  AND '2020-04-30'
  AND country_name ="United States of America"
GROUP BY date
