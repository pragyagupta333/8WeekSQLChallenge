SET search_path = foodie_fi;
SELECT * FROM PLANS
SELECT * FROM SUBSCRIPTIONS
------------------------------------ C. Challenge Payment Question  --------------------------------------------------
/*
The Foodie-Fi team wants you to create a new payments table for the year 2020 
that includes amounts paid by each customer in the subscriptions table with the following requirements:

A] monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
B] upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
C] upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
D] once a customer churns they will no longer make payments */

-- SOLUTION : 
A] monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
  USING GENERATE SERIES FUNCTION TO GENERATE PAYMENT_DATES OF EACH MONTH wrt START_DATE UNTILL CHURN OR END OF YEAR 2020 (AS ASKED IN QUE)
 SELECT  generate_series( '2007-02-01'::timestamp , '2007-02-07'::timestamp, '1 day'::interval) 
   generate_series( START , END, INTERVAL) 
 
 
WITH PAYMENT_DATE_CTE AS (
SELECT GENERATE_SERIES(START_DATE,
				   CASE 
--				   WHEN CUSTOMER PLAN IS BASIC/PRO MONTHLY THEN 2 CASES POSSIBLE
--							1. CUSTOMER CHURNS(UNSUBSCRIBES) AND NEXT_PAYMENT CONTINOUS UNTIL CHURN_DATE (i.e WHEN LEAD_DATE IS NOT NULL.)
--							2. CUSTOMER IS STILL SUBSCRIBED AND CONTINUOUS TO PAY EVERY MONTH TILL NOW FROM START_DATE (i.e LEAD_DATE IS NULL) THEN WE WILL STOP OUR PAYMENT_DATE AT END OF 2020(ASKED IN QUE)
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NOT NULL
													 THEN LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NULL
													 THEN '2020-12-31'::DATE
						WHEN PLAN_NAME ILIKE 'PRO ANNUAL' THEN START_DATE
					END
					,'1 MONTH'
				   ) AS PAYMENT_DATE
FROM SUBSCRIPTIONS S 
JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID
WHERE START_DATE <= '2020-12-31'--::DATE
)   
   
SELECT CUSTOMER_ID, S.PLAN_ID, PLAN_NAME, 
 PAYMENT_DATE ,
-- when plan upgrades (plan changes from pro monthly to pro annual)CUSTOMER 19 upgraded plans from pro monthly to pro annual within the next payment period(datediff between lag payment and current payment <30)
--		due to which code can have two payments one of pro monthly and other of pro annual when in reality only pro annual exists
--		so, we need to count one payment only i.e (here pro annual(upgraded plan))	so subtract downgraded(pro monthly)	(lower plan id) payment

-- else when plan does'nt upgrades (no change in plan_id/plan_name) then count payment amount of same previous plan amount continuously every month till churned.
				   CASE
				   		WHEN LAG(PLAN_NAME) OVER(PARTITION BY CUSTOMER_ID ORDER BY S.PLAN_ID) != PLAN_NAME
						AND (START_DATE - LAG(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY S.PLAN_ID)) < 30
							THEN PRICE - LAG(PRICE) OVER(PARTITION BY CUSTOMER_ID ORDER BY S.PLAN_ID)
						ELSE PRICE
				END AS AMOUNT
FROM PAYMENT_DATE_CTE,
SUBSCRIPTIONS S 
JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID
WHERE START_DATE <= '2020-12-31'--::DATE
ORDER BY 1,4

16 PROANNUAL 189.10
19 PROMONTHLY,PROANNUAL PAYMENT
SELECT CUSTOMER_ID, S.PLAN_ID, PLAN_NAME, START_DATE AS PAYMENT_DATE, PRICE AS AMOUNT
FROM SUBSCRIPTIONS S 
JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID
ORDER BY 1,4

-------------------------------------------------------------------------------------

   
SELECT CUSTOMER_ID, PLAN_ID, PLAN_NAME, 
 PAYMENT_DATE::DATE::VARCHAR,
 -- when plan upgrades (plan changes from pro monthly to pro annual)CUSTOMER 19 upgraded plans from pro monthly to pro annual within the next payment period(datediff between lag payment and current payment <30)
--		due to which code can have two payments one of pro monthly and other of pro annual when in reality only pro annual exists
--		so, we need to count one payment only i.e (here pro annual(upgraded plan))	so subtract downgraded(pro monthly)	(lower plan id) payment

-- else when plan does'nt upgrades (no change in plan_id/plan_name) then count payment amount of same previous plan amount continuously every month till churned.
   CASE
		WHEN LAG(PLAN_NAME) OVER(PARTITION BY CUSTOMER_ID ORDER BY PLAN_ID) != PLAN_NAME
		AND DATE_PART('DAY',PAYMENT_DATE - LAG(PAYMENT_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY PLAN_ID)) < 30
			THEN AMOUNT - LAG(AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY PLAN_ID)
		ELSE AMOUNT
	END AS AMOUNT,
  RANK() OVER(
    PARTITION BY CUSTOMER_ID
    ORDER BY
      PAYMENT_DATE
  ) AS PAYMENT_ORDER 
  
INTO TEMP TABLE PAYMENTS
FROM
  (
    SELECT CUSTOMER_ID, S.PLAN_ID, PLAN_NAME, 
      GENERATE_SERIES(START_DATE,
				   CASE 
--				   WHEN CUSTOMER PLAN IS BASIC/PRO MONTHLY THEN 2 CASES POSSIBLE
--							1. CUSTOMER CHURNS(UNSUBSCRIBES) AND NEXT_PAYMENT CONTINOUS UNTIL CHURN_DATE (i.e WHEN LEAD_DATE IS NOT NULL.)
--							2. CUSTOMER IS STILL SUBSCRIBED AND CONTINUOUS TO PAY EVERY MONTH TILL NOW FROM START_DATE (i.e LEAD_DATE IS NULL) THEN WE WILL STOP OUR PAYMENT_DATE AT END OF 2020(ASKED IN QUE)
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NOT NULL
													 THEN LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NULL
													 THEN '2020-12-31'::DATE
						WHEN PLAN_NAME ILIKE 'PRO ANNUAL' THEN START_DATE
					END
					,'1 MONTH'+'1 SECOND'::INTERVAL
				   ) AS PAYMENT_DATE,
PRICE AS AMOUNT
FROM SUBSCRIPTIONS S 
JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID
WHERE START_DATE <= '2020-12-31'-- ::DATE
    GROUP BY
       CUSTOMER_ID, S.PLAN_ID, PLAN_NAME,START_DATE,PRICE
  ) AS t
ORDER BY
  CUSTOMER_ID

SELECT * FROM PAYMENTS

DROP TABLE PAYMENTS




















