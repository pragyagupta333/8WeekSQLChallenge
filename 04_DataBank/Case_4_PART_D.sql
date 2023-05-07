SET search_path = data_bank;

SELECT * FROM REGIONS
SELECT * FROM CUSTOMER_NODES
SELECT * FROM CUSTOMER_TRANSACTIONS

------------------------------------------------------ D. Extra Challenge ----------------------------------------------------------------------------


Data Bank wants to try another option which is a bit more difficult to implement 
they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, 
how much data would be required for this option on a monthly basis?

Special notes:

Data Bank wants an initial calculation which does not allow for compounding interest, 
however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

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
),
RUNNING_BALANCE_CTE AS (
	SELECT CUSTOMER_ID, MONTH, TXN_DATE,  TXN_TYPE, 
	SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RUNNING_BALANCE
	FROM MONTHLY_TRANSACTIONS_CTE
)
SELECT *,(RUNNING_BALANCE*365*6)/100 AS SIMPLE_INTEREST
FROM RUNNING_BALANCE_CTE
