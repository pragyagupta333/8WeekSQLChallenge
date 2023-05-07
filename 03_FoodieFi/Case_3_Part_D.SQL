SET search_path = foodie_fi;
SELECT * FROM PLANS
SELECT * FROM SUBSCRIPTIONS
ORDER BY 3 DESC
-------- TEMP TABLE PAYMENTS FROM SECTION C ----------------
SELECT CUSTOMER_ID, PLAN_ID, PLAN_NAME, 
 PAYMENT_DATE::DATE::VARCHAR,

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
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NOT NULL
													 THEN LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE
						WHEN PLAN_NAME ILIKE '%MONTHLY' AND ( LEAD(START_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE)::TIMESTAMP WITHOUT TIME ZONE) IS NULL
													 THEN '2021-12-31'::DATE
						WHEN PLAN_NAME ILIKE 'PRO ANNUAL' THEN START_DATE
					END
					,'1 MONTH'+'1 SECOND'::INTERVAL
				   ) AS PAYMENT_DATE,
PRICE AS AMOUNT
FROM SUBSCRIPTIONS S 
JOIN PLANS P ON P.PLAN_ID = S.PLAN_ID
WHERE START_DATE <= '2021-12-31'-- ::DATE
    GROUP BY
       CUSTOMER_ID, S.PLAN_ID, PLAN_NAME,START_DATE,PRICE
  ) AS t
ORDER BY
  CUSTOMER_ID

SELECT * FROM PAYMENTS
DROP TABLE PAYMENTS
------------------------------------ D. Outside The Box Questions  --------------------------------------------------

-- QUE 1 : How would you calculate the rate of growth for Foodie-Fi?
-- ANS :


-- CALCULATING GROWTH IN TERMS OF NO.OF CUSTOMERS FOODIE FI HAD MONTHLY (EXCEPT FOR TRIAL AND CHURN PLANS )

WITH EARNING_CTE AS (
	
	SELECT DISTINCT EXTRACT(YEAR FROM START_DATE::DATE)AS YEAR ,EXTRACT(MONTH FROM START_DATE::DATE)AS MONTH ,
	COUNT(DISTINCT CUSTOMER_ID) AS CUSTOMER_COUNT
	FROM SUBSCRIPTIONS
	WHERE PLAN_ID NOT IN (0,4)
	GROUP BY 1,2
	ORDER BY 1,2
)

SELECT YEAR,MONTH, CUSTOMER_COUNT AS CURRENT_MONTH_CUSTOMERS,  LAG(CUSTOMER_COUNT) OVER(PARTITION BY YEAR) AS PREVIOUS_MONTH_CUSTOMERS,
ROUND((CUSTOMER_COUNT -LAG(CUSTOMER_COUNT) OVER(PARTITION BY YEAR) )*100/LAG(CUSTOMER_COUNT) OVER(PARTITION BY YEAR),4) AS GROWTH_PERCENTAGE
FROM EARNING_CTE
ORDER BY 1,2

-- CALCULATING GROWTH IN TERMS OF REVENUE FOODIE FI EARNED MONTHLY (EXCEPT FOR TRIAL AND CHURN PLANS )

WITH EARNING_CTE AS (
	
	SELECT DISTINCT EXTRACT(YEAR FROM START_DATE::DATE)AS YEAR ,EXTRACT(MONTH FROM START_DATE::DATE)AS MONTH ,SUM(AMOUNT) AS EARNING
	FROM PAYMENTS P
	JOIN SUBSCRIPTIONS S
	ON P.CUSTOMER_ID = S.CUSTOMER_ID
	WHERE P.PLAN_ID NOT IN (0,4)
	GROUP BY 1,2
	ORDER BY 1,2
)

SELECT YEAR,MONTH, EARNING AS CURRENT_MONTH_EARNING,  LAG(EARNING) OVER(PARTITION BY YEAR) AS PREVIOUS_MONTH_EARNING,
ROUND((EARNING - LAG(EARNING) OVER(PARTITION BY YEAR) )*100/LAG(EARNING) OVER(PARTITION BY YEAR),4) AS GROWTH_PERCENTAGE
FROM EARNING_CTE
ORDER BY 1,2



-- QUE 2 : What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- ANS : 

	[A] Monthly revenue growth: How does Foodie-Fis revenue increase or decrease by monthly? Are there any months that the revenue growth wrt previous months increasing significantly?
	Shown Above In Que 1
	In March of 2020, revenue improved significantly wrt previous month revenue
	
	[B] Customers growth: How many customers increase monthly? 
	Shown Above In Que 1
	In March of 2020, no. of customers using foodie fi increased significantly wrt previous month revenue
	
	[C] Conversion rate: How many customers keep using Foodie-Fi after trial? 
	
	
	[D] Churn rate: How many customers cancel the subscription by monthly? What plan they has used?




-- QUE 3 : What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- ANS :
		Customers who downgraded their plan
		Customers who upgraded from basic monthly to pro monthly or pro annual
		Customers who cancelled the subscription
-- QUE 4 : If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- ANS :

		What is the primary reason for the cancellation?
			Price
			Techinical issues
			Customer support
			Found an alternative
			Others (please specify)

		Overall, how satisfied were you with the subscription? (scale: Very Satisfied - Very Unsatisfied)

		Would you consider using our services in the future? ( scale: Very Satisfied - Very Unsatisfied)

		Would you recommend our company to a colleague, friend or family member? ( scale: Very Satisfied - Very Unsatisfied)

-- QUE 5 :What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
-- ANS : 

		From the exit survey, look for the most common reasons why customers cancelled the subscription
			Price: increase the number of discounts in some seasons of a year, extend the trial time, or add more benefits to customers
			Service quality: work with the relevant department to fix the issue
			Found an alternative: do some competitor analysis to see their competitive advantages over us

		To validate the effectiveness of those ideas, check:
			Churn rate
			Conversion rate