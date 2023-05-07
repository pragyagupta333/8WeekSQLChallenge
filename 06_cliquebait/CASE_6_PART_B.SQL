
SET search_path = clique_bait;

SELECT * FROM event_identifier;
SELECT * FROM campaign_identifier;
SELECT * FROM page_hierarchy
SELECT * FROM users
SELECT * FROM events


SELECT VISIT_ID,USER_ID,U.COOKIE_ID,PH.PAGE_ID,PH.PAGE_NAME,E.EVENT_TYPE,EVENT_NAME
FROM EVENTS E
JOIN USERS U ON E.COOKIE_ID = U.COOKIE_ID
JOIN PAGE_HIERARCHY PH ON E.PAGE_ID = PH.PAGE_ID
JOIN EVENT_IDENTIFIER EI ON E.EVENT_TYPE = EI.EVENT_TYPE
-- SINGLE USERS HAS SINGLE VISIT ID AND COOKIE ID
------------------------------------------ 2. Digital Analysis---------------------------------------------------------------------------------

-- QUE 1 : How many users are there?

SELECT COUNT(DISTINCT user_id) as users_count
FROM users

-- QUE 2 : How many cookies does each user have on average?

WITH cookie_cte AS (
	SELECT 
		user_id as users,
		COUNT(cookie_id) as cookie_count
	FROM users
	GROUP BY 1
)
SELECT 
	users, 
	AVG(cookie_count)::INT AVG_COOKIE
FROM cookie_cte
GROUP BY 1
ORDER BY 1

-- QUE 3 : What is the unique number of visits by all users per month?

SELECT 
	EXTRACT(MONTH FROM event_time) AS month_num,
	TO_CHAR(event_time,'Month') AS visit_month,
	COUNT(DISTINCT visit_id) AS visit_count
FROM events
GROUP BY 1,2
ORDER BY 1

-- QUE 4 : What is the number of events for each event type?

SELECT 
	EI.event_name,
	COUNT(EI.event_name) AS event_count
FROM events E
JOIN event_identifier EI
ON E.event_type = EI.event_type
GROUP BY 1
ORDER BY 2 DESC


-- QUE 5 : What is the percentage of visits which have a purchase event?
	-- no of PURCHASE_event_VISIT / TOTAL no of visits

WITH total_visit_cte AS (
	
	SELECT 
		COUNT(distinct visit_id) AS total_visit_count
	FROM events E
),

purchase_visit_cte AS (
	
	SELECT 
		event_name,
		COUNT( distinct visit_id) AS purchase_visit_count
	FROM events E
	JOIN event_identifier EI
	ON E.event_type = EI.event_type
	WHERE event_name ILIKE 'Purchase'
	GROUP BY 1
)
SELECT 
	ROUND(100*purchase_visit_count / total_visit_count, 2) AS percent_purchase_visits
FROM 
purchase_visit_cte,
total_visit_cte

-- QUE 6 : What is the percentage of visits which view the checkout page but do not have a purchase event?

-- NO OF VISIT ID WHO VIEW(EVENT) CHECKOUT(PAGE) BUT MADE NO PURCHASE(EVENT) / TOTAL VISITS MADE

WITH visits_count_cte AS (
SELECT 
	COUNT(DISTINCT visit_id) AS visits_count
FROM events E
JOIN event_identifier EI
ON E.event_type = EI.event_type
JOIN page_hierarchy PH 
ON PH.page_id = e.page_id
WHERE event_name ILIKE 'Page View' AND page_name ILIKE 'Checkout' AND visit_id NOT IN (SELECT 
																						 		visit_id
																						 FROM events E
																						 JOIN event_identifier EI
																						 ON E.event_type = EI.event_type 
																						 WHERE event_name ILIKE 'Purchase')),
total_visit_cte AS (
	
	SELECT 
		COUNT(distinct visit_id) AS total_visit_count
	FROM events E
	JOIN page_hierarchy PH 
	ON PH.page_id = e.page_id
	WHERE page_name ILIKE 'Checkout'
)
SELECT 
	ROUND(100*visits_count::numeric / total_visit_count, 2) AS percent_visits
FROM 
visits_count_cte,
total_visit_cte


-- QUE 7 : What are the top 3 pages by number of views?

SELECT 
	PAGE_NAME, 
	COUNT(EVENT_NAME) AS NO_OF_VIEWS
FROM EVENTS E
JOIN PAGE_HIERARCHY PH ON E.PAGE_ID = PH.PAGE_ID
JOIN EVENT_IDENTIFIER EI ON E.EVENT_TYPE = EI.EVENT_TYPE
WHERE EVENT_NAME ILIKE 'PAGE VIEW'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3

SELECT * FROM campaign_identifier;

-- QUE 8 : What is the number of views and cart adds for each product category?

SELECT * FROM users
SELECT * FROM events
SELECT * FROM event_identifier;
SELECT * FROM page_hierarchy

SELECT event_name,product_category,COUNT(event_name) AS EVENT_COUNT
FROM page_hierarchy ph
JOIN events e ON e.page_id = ph.page_id
JOIN event_identifier EI
ON E.event_type = EI.event_type
WHERE event_name = 'Page View' OR event_name = 'Add to Cart'
GROUP BY 1,2
ORDER BY 1,2

------------------- OR -------------------

SELECT product_category,
	SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS no_of_views,
	SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS no_of_add_to_cart
FROM page_hierarchy ph
JOIN events e ON e.page_id = ph.page_id
JOIN event_identifier EI
ON E.event_type = EI.event_type
WHERE product_category IS NOT NULL
GROUP BY 1

-- QUE 9 : What are the top 3 products by purchases?

-- A USER CAN PUT PRODUCTS TO CART AND NOT PURCHASE THEM ,HENCE WE NEED TO USE ONLY THOSE ADD TO CART WHICH ARE ALSO PURCHASED
SELECT PAGE_NAME AS PRODUCT_NAME , PRODUCT_CATEGORY ,COUNT(EVENT_NAME)
FROM page_hierarchy ph
JOIN events e ON e.page_id = ph.page_id
JOIN event_identifier EI
ON E.event_type = EI.event_type
WHERE EVENT_NAME = 'Add to Cart'
AND VISIT_ID IN (
				SELECT VISIT_ID 
				FROM EVENTS E
				JOIN event_identifier EI
                ON E.event_type = EI.event_type
				WHERE EVENT_NAME = 'Purchase'
				)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3
















