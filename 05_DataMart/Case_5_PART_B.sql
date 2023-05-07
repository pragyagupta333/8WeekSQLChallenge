SET search_path = data_mart;

DROP TABLE IF EXISTS weekly_sales_T;
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
	
SELECT * FROM weekly_sales_t
----------------------------------------------------------- B] Data Exploration ------------------------------------------------------------
-- QUE 1 : What day of the week is used for each week_date value?


SELECT week_date, TO_CHAR(week_date,'Day') as day_of_week
FROM weekly_sales_t

-- DOW : The day of week Sunday (0) to Saturday (6) (Extract function in postgres)

SELECT week_date, extract(DOW FROM week_date) as day_of_week
FROM weekly_sales_t


-- QUE 2 : What range of week numbers are missing from the dataset?

-- GOOGLE : There are 53 weeks in 2020. All weeks are starting on Monday and ending on Sunday.
-- SELECT DISTINCT WEEK_NUMBER::INT FROM weekly_sales_T ORDER BY 1  --> 12 TO 36 PRESENT IN DATA

SELECT generate_series(1, 53) AS week_numbers
EXCEPT 
(SELECT DISTINCT week_number::int FROM weekly_sales_T)
ORDER BY 1;

-- QUE 3 : How many total transactions were there for each year in the dataset?

SELECT DISTINCT calendar_year,SUM(transactions) as total_transactions
FROM weekly_sales_T
GROUP BY 1
ORDER BY 1

-- QUE 4 : What is the total sales for each region for each month?

SELECT region,month_number, SUM(sales) AS 'Total_Sales'
FROM weekly_sales_t
GROUP BY 1,2
ORDER BY 1,2


-- QUE 5 : What is the total count of transactions for each platform

SELECT  platform, COUNT(transactions) as Transactions_Counts
FROM weekly_sales_t
GROUP BY  1

-- QUE 6 : What is the percentage of sales for Retail vs Shopify for each month?

SELECT *
FROM weekly_sales_t
order by 4,3,8

WITH SALES_CTE AS (
	
	SELECT calendar_year,month_number,platform,SUM(sales) AS MONTHLY_SALES
	FROM weekly_sales_t
	GROUP BY 1,2,3
	ORDER BY 1,2,3
)
SELECT calendar_year, month_number, 
	ROUND(100*MAX(CASE WHEN platform ILIKE 'SHOPIFY' THEN MONTHLY_SALES ELSE NULL END) /SUM(MONTHLY_SALES),2) AS SHOPIFY_SALES_PERCENT, -->  monthly sales using shopify in that month / total_sales using shopify and retail in that month
	ROUND(100*MAX(CASE WHEN platform ILIKE 'RETAIL' THEN  MONTHLY_SALES ELSE NULL END) /SUM(MONTHLY_SALES ),2)  AS RETAIL_SALES_PERCENT
FROM SALES_CTE 
GROUP BY 1,2

-- NOTE: MAX AGGREGATE IS USED TO JUST AVOID ERROR - "USE PLATFORM IN GROUP OR IN AGGREGATE FUNCTIONS" AS PLATFORM CAN'T BE USED IN GROUP BY FOR THIS ANS
-- MAX(MONTHLY_SALES) = MIN(MONTHLY_SALES) = MONTHLY_SALES  => MAX(5000) =MIN(5000) = 5000. SINCE ONLY VALUE IS USED i.e 5000
-- CHECK THE SAME USING MIN() OR SUM() INSTEAD OF MAX() => OUTPUT WILL BE SAME IN ALL


-- QUE 7 : What is the percentage of sales by demographic for each year in the dataset?

WITH sales_cte AS(
	SELECT calendar_year,demographic,SUM(sales) YEARLY_SALES
	FROM weekly_sales_t
	GROUP BY 1,2
	ORDER BY 1,2
)
SELECT calendar_year,
	ROUND(100*MAX(CASE WHEN demographic ILIKE 'COUPLES' THEN YEARLY_SALES ELSE NULL END) /SUM(YEARLY_SALES) ,2)AS COUPLES_PERCENT,
	ROUND(100*MAX(CASE WHEN demographic ILIKE 'FAMILIES' THEN YEARLY_SALES ELSE NULL END) /SUM(YEARLY_SALES),2) AS FAMILIES_PERCENT,
	ROUND(100*MAX(CASE WHEN demographic ILIKE 'UNKNOWN' THEN YEARLY_SALES ELSE NULL END) /SUM(YEARLY_SALES) ,2)AS UNKNOWN_PERCENT
FROM sales_cte
GROUP BY 1


-- QUE 8 : Which age_band and demographic values contribute the most to Retail sales?

WITH sales_cte AS (
	SELECT age_band,demographic,SUM(sales) AS category_sales
	FROM weekly_sales_t
	WHERE PLATFORM = 'Retail'
	GROUP BY 1,2
	ORDER BY 1,2
),
total_cte AS (
SELECT SUM(category_sales) AS total_sales
FROM sales_cte
)
SELECT age_band, demographic, category_sales, total_sales,
ROUND((100*(category_sales)/total_sales),2) AS contribution_percentage
FROM sales_cte, total_cte
ORDER BY contribution_percentage DESC
-- LIMIT 1

-- QUE 9 : Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT calendar_year, platform ,SUM(sales)/SUM(transactions) AS Avg_transactions_per_year
FROM weekly_sales_t
GROUP BY 1,2
ORDER BY 1,2

USING AVG_TRANSACTION COLUMN ISN''T POSSIBLE
AVG OF AVG IS INACCURATE.