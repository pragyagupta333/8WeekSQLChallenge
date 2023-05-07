SET search_path = data_bank;

SELECT * FROM REGIONS
SELECT * FROM CUSTOMER_NODES
SELECT * FROM CUSTOMER_TRANSACTIONS
ORDER BY 1
------------------------------------------------------ C. Data Allocation Challenge ----------------------------------------------------------------------------


To test out a few different hypotheses - the Data Bank team wants to run an experiment where different
groups of customers would be allocated data using 3 different options:

	Option 1: data is allocated based off the amount of money at the end of the previous month
	Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
	Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data 
elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

	[A] running customer balance column that includes the impact each transaction
	[B] customer balance at the end of each month
	[C] minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?
	
	
[A] running customer balance column that includes the impact each transaction

WITH MONTHLY_TRANSACTIONS_CTE AS (
	SELECT CUSTOMER_ID,
	EXTRACT('MONTH' FROM TXN_DATE) AS MONTH,TXN_DATE,TXN_TYPE,
		CASE WHEN TXN_TYPE ILIKE 'DEPOSIT' THEN TXN_AMOUNT 
			 ELSE -TXN_AMOUNT 
		END AS TXN_AMOUNT
	FROM CUSTOMER_TRANSACTIONS
	ORDER BY 1
)
SELECT *,
SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RUNNING_BALANCE
FROM MONTHLY_TRANSACTIONS_CTE


[B] customer balance at the end of each month

WITH MONTHLY_TRANSACTIONS_CTE AS (
	SELECT CUSTOMER_ID,
	EXTRACT('MONTH' FROM TXN_DATE) AS MONTH,
	TXN_DATE,TXN_TYPE,
		CASE WHEN TXN_TYPE ILIKE 'DEPOSIT' THEN TXN_AMOUNT 
			 ELSE -TXN_AMOUNT 
		END AS TXN_AMOUNT
	FROM CUSTOMER_TRANSACTIONS
	GROUP BY 1,2,3,4,5
	ORDER BY 1
)
,
MONTHLY_BALANCE_CTE AS (
	SELECT CUSTOMER_ID, MONTH, TXN_DATE,  TXN_TYPE, TXN_AMOUNT,
	SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS BALANCE,
	--SUMS ALL ABOVE ROWS IN THAT PARTITION TILL CURRENT ROW
	ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID,MONTH ORDER BY TXN_DATE DESC ) AS RN
	FROM MONTHLY_TRANSACTIONS_CTE
)
SELECT CUSTOMER_ID,TXN_DATE,MONTH,BALANCE AS MONTH_END_BALANCE
FROM MONTHLY_BALANCE_CTE 
WHERE RN=1

[C] minimum, average and maximum values of the running balance for each customer

-- MIN,MAX,AVG VALUE FOR EACH RECORD OF RUNNING_BALANCE

WITH MONTHLY_TRANSACTIONS_CTE AS (
	SELECT CUSTOMER_ID,
	EXTRACT('MONTH' FROM TXN_DATE) AS MONTH,TXN_DATE,TXN_TYPE,
		CASE WHEN TXN_TYPE ILIKE 'DEPOSIT' THEN TXN_AMOUNT 
			 ELSE -TXN_AMOUNT 
		END AS TXN_AMOUNT
	FROM CUSTOMER_TRANSACTIONS
	ORDER BY 1
),
RUNNING_BALANCE_CTE AS (
SELECT *,
SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RUNNING_BALANCE
FROM MONTHLY_TRANSACTIONS_CTE
)
SELECT CUSTOMER_ID,RUNNING_BALANCE,
	MIN(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE),
	MAX(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE),
	ROUND(AVG(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE),2) AS AVG
FROM RUNNING_BALANCE_CTE
GROUP BY 1,RUNNING_BALANCE,TXN_DATE



