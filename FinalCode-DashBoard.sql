Table Source Name: Covid-19_fourCountries


SELECT 
country_name, 
-- count(*), 
date,
-- location_key,
population,
sum(new_confirmed) new_confirmed,
sum(new_deceased) new_deceased,
sum(new_recovered) new_recovered,
sum(cumulative_confirmed) cumulative_confirmed,
sum(cumulative_deceased) cumulative_deceased,
sum(cumulative_recovered) cumulative_recovered ,
sum(cumulative_tested) cumulative_tested,
sum(new_persons_vaccinated) new_persons_vaccinated,
sum(new_vaccine_doses_administered)new_vaccine_doses_administered,
sum(new_persons_fully_vaccinated) new_persons_fully_vaccinated,
sum(cumulative_persons_vaccinated)cumulative_persons_vaccinated,
sum(cumulative_persons_fully_vaccinated) cumulative_persons_fully_vaccinated,
sum(investment_in_vaccines)investment_in_vaccines, 
sum(cumulative_hospitalized_patients)cumulative_hospitalized_patients,
sum(current_intensive_care_patients)current_intensive_care_patients, 
sum(current_hospitalized_patients)current_hospitalized_patients,
sum(contact_tracing) 
contact_tracing


FROM `bigquery-public-data.covid19_open_data.covid19_open_data` 
where country_name in ("Vietnam", "Singapore", "Canada", "United States of America")
group by 1,2,3


Table Source Name:

WITH cases_by_date AS (
  SELECT
  country_name,
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE country_name in
    ("Vietnam", "Singapore", "Canada", "United States of America") 
    AND date between DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH) and CURRENT_DATE()
  GROUP BY
    1,2
  ORDER BY
    1,2 ASC 
 )
, previous_day_comparison AS 
(SELECT
country_name,
  date,
  cases,
  LAG(cases) OVER(ORDER BY date) AS previous_day,
  cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
  (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
FROM cases_by_date
)
SELECT 
country_name,
Date, 
cases as Confirmed_Cases_On_Day, 
previous_day as Confirmed_Cases_Previous_Day, 
percentage_increase as Percentage_Increase_In_Cases
FROM previous_day_comparison
WHERE percentage_increase > 10
