SET search_path = data_mart;

CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	EXTRACT('YEAR' FROM WEEK_DATE) AS CALENDAR_YEAR,
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
	
SELECT * FROM  weekly_sales_T

DROP TABLE weekly_sales_T
-------------------------------------------- 3. Before & After Analysis ----------------------------------------------------------
/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:
*/

-- QUE 1 : What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

WITH after_cte AS (
SELECT SUM(SALES) AS after_sales
FROM weekly_sales_T
WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+3 )::TEXT
AND EXTRACT(year from WEEK_DATE )= '2020'
),
before_cte as (
SELECT SUM(SALES) AS before_sales
FROM weekly_sales_T
WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-4)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
AND EXTRACT(year FROM WEEK_DATE )= '2020'
)
SELECT before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
(after_sales - before_sales)*100/(before_sales)::decimal as percent_sales
FROM after_cte,before_cte

------------------------------------------------- OR -----------------------------------------------------
DO $$
DECLARE
week_num INT :=
	( 
		SELECT distinct week_number 
		FROM weekly_sales_t
		WHERE week_date = '2020-06-15'
	);
before_sales BIGINT :=
	(
		SELECT SUM(SALES) AS before_sales 
		FROM weekly_sales_T
		WHERE week_number BETWEEN (WEEK_NUM - 4)::TEXT AND (WEEK_NUM - 1 )::TEXT
		AND EXTRACT(year from WEEK_DATE )='2020'
	);
after_sales BIGINT:=
	(
		SELECT SUM(SALES) AS after_sales 
		FROM weekly_sales_T
		WHERE week_NUMBER BETWEEN WEEK_NUM::TEXT AND (WEEK_NUM + 3 )::TEXT
		AND EXTRACT(year from WEEK_DATE )='2020'
	);

BEGIN
RAISE NOTICE 'BEFORE_SALES : %',BEFORE_SALES;
RAISE NOTICE 'AFTER_SALES : %',AFTER_SALES;
RAISE NOTICE 'GROWTH_OR_REDUCTION_RATE : %',(AFTER_SALES - BEFORE_SALES);
RAISE NOTICE 'PERCENT_SALES : %',(AFTER_SALES - BEFORE_SALES)*100/(BEFORE_SALES)::decimal;
END $$;

-- QUE 2 : What about the entire 12 weeks before and after?

WITH after_cte AS (
SELECT SUM(SALES) AS after_sales
FROM weekly_sales_T
WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
AND EXTRACT(year from WEEK_DATE )= '2020'
),
before_cte as (
SELECT SUM(SALES) AS before_sales
FROM weekly_sales_T
WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
AND EXTRACT(year FROM WEEK_DATE )= '2020'
)
SELECT before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
(after_sales - before_sales)*100/(before_sales)::decimal as percent_sales
FROM after_cte,before_cte

------------------------------------------------------------- OR ------------------------------------------------
DO $$
DECLARE
week_num INT :=
	( 
		SELECT distinct week_number 
		FROM weekly_sales_t
		WHERE week_date = '2020-06-15'
	);
before_sales BIGINT :=
	(
		SELECT SUM(SALES) AS before_sales 
		FROM weekly_sales_T
		WHERE week_number BETWEEN (WEEK_NUM - 12)::TEXT AND (WEEK_NUM - 1 )::TEXT
		AND EXTRACT(year from WEEK_DATE )='2020'
	);
after_sales BIGINT:=
	(
		SELECT SUM(SALES) AS after_sales 
		FROM weekly_sales_T
		WHERE week_NUMBER BETWEEN WEEK_NUM::TEXT AND (WEEK_NUM + 11 )::TEXT
		AND EXTRACT(year from WEEK_DATE )='2020'
	);

BEGIN
RAISE NOTICE 'BEFORE_SALES : %',BEFORE_SALES;
RAISE NOTICE 'AFTER_SALES : %',AFTER_SALES;
RAISE NOTICE 'GROWTH_OR_REDUCTION_RATE : %',(AFTER_SALES - BEFORE_SALES);
RAISE NOTICE 'PERCENT_SALES : %',(AFTER_SALES - BEFORE_SALES)*100/(BEFORE_SALES)::decimal;
END $$;

-- RETURN FORMAT('Before_sales %s After_sales %s',before_sales_value, after_sales_value );


-- QUE 3 : How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

SELECT * FROM weekly_sales_T

-- [a] 4 weeks before and after

WITH after_cte AS (
	SELECT calendar_year, SUM(SALES) AS after_sales
	FROM weekly_sales_T
	WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+3 )::TEXT
	GROUP BY 1
),
before_cte as (
	SELECT calendar_year, SUM(SALES) AS before_sales
	FROM weekly_sales_T
	WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-4)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
	GROUP BY 1
)
SELECT a.calendar_year,before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.calendar_year = b.calendar_year
GROUP BY 1,2,3


-- [b] 12 weeks before and after 

WITH after_cte AS (
SELECT calendar_year,SUM(SALES) AS after_sales
FROM weekly_sales_T
WHERE week_NUMBER BETWEEN TO_CHAR('2020-06-15'::DATE,'WW') AND (TO_CHAR('2020-06-15'::DATE,'WW')::INT+11 )::TEXT
GROUP BY 1	
),
before_cte as (
SELECT calendar_year,SUM(SALES) AS before_sales
FROM weekly_sales_T
WHERE week_number BETWEEN (TO_CHAR('2020-06-14'::DATE, 'WW')::INT-12)::text AND (TO_CHAR('2020-06-14'::DATE,'WW')::INT-1)::text
GROUP BY 1	
)
SELECT a.calendar_year,before_sales, after_sales,
(after_sales - before_sales) as growth_or_reduction_rate,
ROUND((after_sales - before_sales)*100/(before_sales)::decimal,2) AS percent_sales
FROM after_cte a 
JOIN before_cte b
ON a.calendar_year = b.calendar_year
GROUP BY 1,2,3
