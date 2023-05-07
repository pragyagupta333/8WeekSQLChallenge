SET SEARCH_PATH =PIZZA_RUNNER;

--------------------------------- DATA CLEANING -------------------------------------
/*  
CREATING TEMP TABLES FOR ALL THE CHANGES

A] REPLACING 'NULL' FROM EXCLUSIONS AND EXTRAS TO NULL

B] REMOVING KM,  MINS, MINUTE, MINUTES AND REPLACING 'NULL' TO NULL IN  DISTANCE ,DURATION,CANCELLATION IN RUNNER_ORDERS

C] CHANGING COLUMN DATA TYPES IN RUNNER_ORDERS_T
	1) PICKUP_TIME : VARCHAR TO TIMESTAMP   
	2) DURATION    : VARCHAR TO INT
	3) DISTANCE    : VARCHAR TO NUMERIC
*/
 
-- [A]
CREATE TEMP TABLE CUSTOMER_ORDERS_T AS 
	SELECT ORDER_ID, CUSTOMER_ID,PIZZA_ID,
		CASE 
			WHEN EXCLUSIONS ILIKE 'NULL' OR EXCLUSIONS ILIKE '' OR EXCLUSIONS IS NULL  THEN NULL
			ELSE EXCLUSIONS
		END AS EXCLUSIONS,
		
		CASE 
			WHEN EXTRAS ILIKE 'NULL' OR EXTRAS ILIKE '' OR EXTRAS IS NULL THEN NULL
			ELSE EXTRAS 
		END AS EXTRAS,
	ORDER_TIME
	FROM PIZZA_RUNNER.CUSTOMER_ORDERS;
	
-- [B]
CREATE TEMP TABLE RUNNER_ORDERS_T AS 
	SELECT ORDER_ID,RUNNER_ID,	
		CASE 
			WHEN PICKUP_TIME ILIKE 'NULL' THEN NULL
			ELSE PICKUP_TIME
		END AS PICKUP_TIME,
	
		CASE 
			WHEN DISTANCE ILIKE '%KM' THEN rtrim(distance,'km')
			WHEN DISTANCE ILIKE 'NULL' THEN NULL
			ELSE DISTANCE
		END AS DISTANCE,
		
		CASE 
			WHEN DURATION ILIKE '%MIN%' THEN rtrim(DURATION,'minutes')
			WHEN DURATION ILIKE 'NULL' THEN NULL
			ELSE DURATION
		END AS DURATION,
		
		CASE 
			WHEN CANCELLATION ILIKE 'NULL' OR CANCELLATION IS NULL OR CANCELLATION ILIKE '' THEN NULL
			ELSE CANCELLATION
			END AS CANCELLATION
	FROM RUNNER_ORDERS;
	
-- [C]			
ALTER TABLE RUNNER_ORDERS_T 
	ALTER COLUMN DISTANCE TYPE NUMERIC USING DISTANCE::NUMERIC,
	ALTER COLUMN DURATION TYPE INT USING DURATION::INT,
	ALTER COLUMN PICKUP_TIME TYPE timestamp WITHOUT TIME ZONE USING PICKUP_TIME::timestamp

------------------------------------ [B] Runner and Customer Experience ------------------------------


--QUE 1 : How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- ANS :
SELECT TO_CHAR(REGISTRATION_DATE,'W') AS REGISTRATION_WEEK ,COUNT(RUNNER_ID) AS RUNNERS_COUNT
FROM RUNNERS
GROUP BY 1 
ORDER BY 1

--QUE 2 : What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- ANS :

SELECT RO.RUNNER_ID,AVG (AGE(PICKUP_TIME,ORDER_TIME)) AS AVG_TIME
FROM CUSTOMER_ORDERS_T CO
JOIN RUNNER_ORDERS_T RO ON RO.ORDER_ID = CO.ORDER_ID
WHERE RO.CANCELLATION IS NULL
GROUP BY 1
----------------------------- OR ----------------------------------
SELECT RUNNER_ID,  (AVG(EXTRACT(MINUTES FROM PICKUP_TIME - ORDER_TIME))::INT||' Mins') AS AVG_TIME
FROM CUSTOMER_ORDERS_T CO
JOIN RUNNER_ORDERS_T RO ON RO.ORDER_ID = CO.ORDER_ID
WHERE RO.CANCELLATION IS NULL
GROUP BY 1

-->VERIFY
SELECT RO.RUNNER_ID, RO.PICKUP_TIME, CO.ORDER_TIME
FROM CUSTOMER_ORDERS_T CO
JOIN RUNNER_ORDERS_T RO ON RO.ORDER_ID = CO.ORDER_ID
WHERE RO.CANCELLATION IS NULL

--QUE 3 : Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- ANS :

WITH PREP_TIME_TAKEN AS(
	SELECT 
	CO.ORDER_ID,COUNT(CO.ORDER_ID) AS NO_OF_PIZZA,
	CO.ORDER_TIME,RO.PICKUP_TIME,
	(EXTRACT(MINUTES FROM PICKUP_TIME - ORDER_TIME)) AS prep_time
	FROM CUSTOMER_ORDERS_T CO
	JOIN RUNNER_ORDERS_T RO ON RO.ORDER_ID = CO.ORDER_ID
	WHERE RO.CANCELLATION IS NULL
	GROUP BY 1,3,4
)

SELECT NO_OF_PIZZA,AVG(prep_time)::INT AS AVG_PREP_TIME
FROM PREP_TIME_TAKEN
GROUP BY 1

--QUE 4 : What was the average distance travelled for each customer?
-- ANS :

SELECT CO.CUSTOMER_ID,AVG(RO.DISTANCE)::NUMERIC(4,2) AS AVG_DISTANCE_TRAVELLED
FROM CUSTOMER_ORDERS_T CO
JOIN RUNNER_ORDERS_T RO ON RO.ORDER_ID = CO.ORDER_ID
WHERE RO.CANCELLATION IS NULL
GROUP BY 1
ORDER BY 1

--QUE 5 : What was the difference between the longest and shortest delivery times for all orders?
-- ANS :

SELECT MAX(RO.DURATION)-MIN(RO.DURATION) AS DELIVERY_DURATION_DIFF
FROM RUNNER_ORDERS_T RO
WHERE DURATION IS NOT NULL

--QUE 6 : What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- ANS :

SELECT RO.ORDER_ID, RO.RUNNER_ID, 
ROUND(AVG((RO.DISTANCE/RO.DURATION)*60),2) AS AVG_SPEED
FROM RUNNER_ORDERS_T RO
WHERE RO.CANCELLATION IS NULL
GROUP BY 1,2
------------------ OR -----------------------
WITH AVG_SPEED AS(
	SELECT RO.ORDER_ID, RO.RUNNER_ID, RO.DISTANCE AS DISTANCE_km ,RO.DURATION/60::NUMERIC(4,2) as TIME_HOUR ,(RO.DISTANCE/RO.DURATION)*60 AS SPEED
	FROM RUNNER_ORDERS_T RO
	WHERE RO.CANCELLATION IS NULL 
)

SELECT RUNNER_ID, ORDER_ID, DISTANCE_km,TIME_HOUR,
ROUND(SPEED,2) AS AVG_SPEED
FROM AVG_SPEED 
GROUP BY 1,2,3,4,5

--QUE 7 :What is the successful delivery percentage for each runner?
-- ANS :

WITH ORDERS AS (
	SELECT RUNNER_ID, 
	SUM( CASE  
			WHEN CANCELLATION IS NULL THEN 1 ELSE 0 END ) AS SUCCESSFUL_ORDERS,
	COUNT(ORDER_ID) AS TOTAL_ORDERS
	FROM RUNNER_ORDERS_T
	GROUP BY 1
	ORDER BY 1
)
SELECT RUNNER_ID,(SUCCESSFUL_ORDERS*100/TOTAL_ORDERS) AS successful_delivery_percentage
FROM ORDERS














