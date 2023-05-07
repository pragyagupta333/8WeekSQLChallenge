SET search_path = data_mart;

CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	EXTRACT('YEAR' FROM WEEK_DATE) AS CALENAR_YEAR,
	CASE 
		 WHEN SEGMENT ILIKE '%1' THEN 'Young Adults' 
		 WHEN SEGMENT ILIKE '%2' THEN 'Middle Aged' 
		 WHEN SEGMENT ILIKE '%3' OR SEGMENT ILIKE '%4' THEN 'Retirees' 
		 WHEN SEGMENT ILIKE 'NULL' THEN 'Unknown'
		 END AS AGE_BAND,
	CASE 
		 WHEN SEGMENT ILIKE 'C%' THEN 'Couples' 
		 WHEN SEGMENT ILIKE 'F%' THEN 'Families'
		 WHEN SEGMENT ILIKE 'NULL' THEN 'Unknown'
		 END AS demographic,
	REGION,PLATFORM,
	CASE 
		WHEN SEGMENT ILIKE 'NULL' THEN 'Unknown'
		ELSE SEGMENT
		END SEGMENT,
	CUSTOMER_TYPE,TRANSACTIONS,SALES,
	ROUND((SALES/TRANSACTIONS),2) AS avg_transaction
	FROM WEEKLY_SALES
	
SELECT * FROM weekly_sales_T
--------------------------------------------4. Bonus Question----------------------------------------------------------

Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

1. region
2. platform
3. age_band
4. demographic
5. customer_type

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?


-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- [a] Region : 
WITH after_cte AS (
	
	SELECT region, SUM(sales) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
	AND EXTRACT(year from WEEK_DATE )= '2020'
	GROUP BY region
),
before_cte as (
	
	SELECT region, SUM(sales) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	AND EXTRACT(year FROM WEEK_DATE )= '2020'
	GROUP BY region
)

SELECT a.region, before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.region = b.region
GROUP BY 1,2,3
ORDER BY 5

-- [b] platform
WITH after_cte AS (
	
	SELECT platform, SUM(sales) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
	AND EXTRACT(year from WEEK_DATE )= '2020'
	GROUP BY platform
),
before_cte as (
	
	SELECT platform, SUM(sales) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	AND EXTRACT(year FROM WEEK_DATE )= '2020'
	GROUP BY platform
)
SELECT a.platform, before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.platform = b.platform
GROUP BY 1,2,3
ORDER BY 5

-- [c] age_band
WITH after_cte AS (
	
	SELECT age_band, SUM(sales) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
	AND EXTRACT(year from WEEK_DATE )= '2020'
	GROUP BY age_band
),
before_cte as (
	
	SELECT age_band, SUM(sales) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	AND EXTRACT(year FROM WEEK_DATE )= '2020'
	GROUP BY age_band
)
SELECT a.age_band, before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.age_band = b.age_band
GROUP BY 1,2,3
ORDER BY 5


-- [d] demographic

WITH after_cte AS (
	
	SELECT demographic, SUM(sales) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
	AND EXTRACT(year from WEEK_DATE )= '2020'
	GROUP BY demographic
),
before_cte as (
	
	SELECT demographic, SUM(sales) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	AND EXTRACT(year FROM WEEK_DATE )= '2020'
	GROUP BY demographic
)
SELECT a.demographic, before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.demographic = b.demographic
GROUP BY 1,2,3
ORDER BY 5


-- [e] customer_type


WITH after_cte AS (
	
	SELECT customer_type, SUM(sales) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
	AND EXTRACT(year from WEEK_DATE )= '2020'
	GROUP BY customer_type
),
before_cte as (
	
	SELECT customer_type, SUM(sales) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	AND EXTRACT(year FROM WEEK_DATE )= '2020'
	GROUP BY customer_type
)
SELECT a.customer_type, before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.customer_type = b.customer_type
GROUP BY 1,2,3
ORDER BY 5
