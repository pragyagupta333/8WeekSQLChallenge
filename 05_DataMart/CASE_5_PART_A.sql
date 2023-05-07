SET search_path = data_mart;
SELECT * FROM weekly_sales_T
-------------------------------------------- 1. Data Cleansing Steps ----------------------------------------------------------
-- QUE 1 : Convert the week_date to a DATE format
-- ANS :

ALTER TABLE WEEKLY_SALES
	ALTER COLUMN WEEK_DATE TYPE DATE USING(WEEK_DATE::DATE);
	
-- QUE 2 : Add a week_number as the second column for each week_date value, 
--         for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- ANS : 

DROP TABLE IF EXISTS weekly_sales_T;
CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	REGION,PLATFORM,SEGMENT,CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES

-- QUE 3 : Add a month_number with the calendar month for each week_date value as the 3rd column
-- ANS : 

DROP TABLE IF EXISTS weekly_sales_T;
CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	REGION,PLATFORM,SEGMENT,CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES
	
-- QUE 4 : Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- ANS :

DROP TABLE IF EXISTS weekly_sales_T;
CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	EXTRACT('YEAR' FROM WEEK_DATE) AS CALENAR_YEAR,
	REGION,PLATFORM,SEGMENT,CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES

-- QUE 5 : Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--													segment		age_band
--													1			Young Adults
--													2			Middle Aged
--													3 or 4		Retirees
-- ANS :

DROP TABLE IF EXISTS weekly_sales_T;
CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	EXTRACT('YEAR' FROM WEEK_DATE) AS CALENAR_YEAR,
	CASE 
		 WHEN SEGMENT ILIKE '%1' THEN 'Young Adults' 
		 WHEN SEGMENT ILIKE '%2' THEN 'Middle Aged' 
		 ELSE 'Retirees'
		 END AS AGE_BAND,
	REGION,PLATFORM,SEGMENT,CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES
	

-- QUE 6 : Add a new demographic column using the following mapping for the first letter in the segment values:
--														segment		demographic
--														C			Couples
--														F			Families
-- ANS :

DROP TABLE IF EXISTS weekly_sales_T;
CREATE TEMP TABLE WEEKLY_SALES_T AS
	SELECT 
	WEEK_DATE,
	TO_CHAR(WEEK_DATE,'WW') AS WEEK_NUMBER,
	EXTRACT('MONTH' FROM WEEK_DATE) AS MONTH_NUMBER,
	EXTRACT('YEAR' FROM WEEK_DATE) AS CALENAR_YEAR,
	CASE 
		 WHEN SEGMENT ILIKE '%1' THEN 'Young Adults' 
		 WHEN SEGMENT ILIKE '%2' THEN 'Middle Aged' 
		 ELSE 'Retirees'
		 END AS AGE_BAND,
	CASE 
		 WHEN SEGMENT ILIKE 'C%' THEN 'Couples' 
		 WHEN SEGMENT ILIKE 'F%' THEN 'Families' 
		 END AS demographic,
	REGION,PLATFORM,SEGMENT,CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES
	
-- QUE 7 : Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns	
-- ANS :

DROP TABLE IF EXISTS weekly_sales_T;
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
	CUSTOMER_TYPE,TRANSACTIONS,SALES
	FROM WEEKLY_SALES

-- QUE 8 : Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
-- ANS : 
DROP TABLE IF EXISTS weekly_sales_T;
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


SELECT * FROM WEEKLY_SALES_T







