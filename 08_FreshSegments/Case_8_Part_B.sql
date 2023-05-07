SET search_path = fresh_segments
SELECT * FROM interest_map
SELECT * FROM Interest_Metrics 

---------------------------------------- [B] Interest Analysis ---------------------------------------
-- Que 1 : Which interests have been present in all month_year dates in our dataset?

SELECT interest_id
FROM Interest_Metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) = ( SELECT COUNT(distinct month_year)
									  FROM Interest_Metrics)

-- Que 2 : Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months
--        which total_months value passes the 90% cumulative percentage value?
1]
WITH MONTHS_CTE AS 
(
SELECT INTEREST_ID AS IDS ,COUNT(DISTINCT month_year) AS TOTAL_MONTHS
FROM Interest_Metrics 
GROUP BY 1
ORDER BY 1 
)
SELECT TOTAL_MONTHS, 
	   ROUND(100*SUM(COUNT(IDS)) OVER(ORDER BY total_months DESC)/ SUM(COUNT(IDS)) OVER(),2) AS CUM_PERCENT
FROM MONTHS_CTE
GROUP BY 1

2]
WITH MONTHS_CTE AS 
(
SELECT INTEREST_ID AS IDS ,COUNT(DISTINCT month_year) AS TOTAL_MONTHS
FROM Interest_Metrics 
GROUP BY 1
ORDER BY 1 
),
PERCENT_CTE AS (
SELECT TOTAL_MONTHS, 
	   ROUND(100*SUM(COUNT(IDS)) OVER(ORDER BY total_months DESC)/ SUM(COUNT(IDS)) OVER(),2) AS CUM_PERCENT
FROM MONTHS_CTE
GROUP BY 1
)
SELECT TOTAL_MONTHS,CUM_PERCENT
FROM PERCENT_CTE
WHERE CUM_PERCENT >= 90

-- Que 3 : If we were to remove all interest_id values which are lower than the total_months value we found in the previous question
-- how many total data points would we be removing?

WITH cte_total_months AS (
	SELECT interest_id,
		count(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
	HAVING count(DISTINCT month_year) < 6
) 
SELECT count(*) rows_removed
FROM interest_metrics
WHERE exists(
		SELECT interest_id
		FROM cte_total_months
		WHERE cte_total_months.interest_id = interest_metrics.interest_id
);

-- Que 4 : Does this decision make sense to remove these data points from a business perspective? 
-- Use an example where there are all 14 months present to a removed interest example for your arguments 
-- think about what it means to have less months present from a segment perspective.


-- Que 5 : After removing these interests - how many unique interests are there for each month?

WITH cte_total_months AS (
	SELECT interest_id,
		count(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
	HAVING count(DISTINCT month_year) >= 6
)
SELECT month_year,
	count(interest_id) AS n_interests
FROM interest_metrics
WHERE interest_id IN (
		SELECT interest_id
		FROM cte_total_months
	)
GROUP BY month_year
ORDER BY month_year;







