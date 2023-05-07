
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


------------------------------------------ 3. Product Funnel Analysis ---------------------------------------------------------------------------------
/*
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased? */

WITH VIEW_CART_CTE AS (
SELECT 
PRODUCT_ID,
PAGE_NAME AS PRODUCT_NAME,
PRODUCT_CATEGORY, 
SUM(CASE WHEN EVENT_NAME = 'Page View' THEN 1 ELSE 0 END )AS VIEW_COUNTS,
SUM(CASE WHEN EVENT_NAME = 'Add to Cart' THEN 1 ELSE 0 END )AS CART_COUNTS
FROM events e 
JOIN event_identifier EI ON E.event_type = EI.event_type
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE  PRODUCT_CATEGORY IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1
),
abandoned_CTE AS (
SELECT PRODUCT_ID, PAGE_NAME AS PRODUCT_NAME, PRODUCT_CATEGORY,
COUNT(EVENT_NAME) AS abandoned_COUNTS
FROM page_hierarchy ph
JOIN events e ON e.page_id = ph.page_id
JOIN event_identifier EI
ON E.event_type = EI.event_type
WHERE EVENT_NAME = 'Add to Cart'
AND VISIT_ID NOT IN (
				SELECT VISIT_ID 
				FROM EVENTS E
				JOIN event_identifier EI
                ON E.event_type = EI.event_type
				WHERE EVENT_NAME = 'Purchase'
				)
GROUP BY 1,2,3
ORDER BY 1
),
PURCHASE_CTE AS (
SELECT PRODUCT_ID, PAGE_NAME AS PRODUCT_NAME, PRODUCT_CATEGORY,
COUNT(EVENT_NAME) AS PURCHASE_COUNTS
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
GROUP BY 1,2,3
ORDER BY 1
)
SELECT 
	V.*,
	abandoned_COUNTS,
	PURCHASE_COUNTS
INTO PRODUCT_COUNTS
FROM 
	VIEW_CART_CTE V
JOIN abandoned_CTE A  ON V.PRODUCT_ID= A.PRODUCT_ID
JOIN PURCHASE_CTE P ON A.PRODUCT_ID = P.PRODUCT_ID


SELECT * FROM PRODUCT_COUNTS


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

*/

WITH VIEW_CART_CTE AS (
SELECT 
PRODUCT_CATEGORY, 
SUM(CASE WHEN EVENT_NAME = 'Page View' THEN 1 ELSE 0 END )AS VIEW_COUNTS,
SUM(CASE WHEN EVENT_NAME = 'Add to Cart' THEN 1 ELSE 0 END )AS CART_COUNTS
FROM events e 
JOIN event_identifier EI ON E.event_type = EI.event_type
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE  PRODUCT_CATEGORY IS NOT NULL
GROUP BY 1
ORDER BY 1
),
abandoned_CTE AS (
SELECT  PRODUCT_CATEGORY,
COUNT(EVENT_NAME) AS abandoned_COUNTS
FROM page_hierarchy ph
JOIN events e ON e.page_id = ph.page_id
JOIN event_identifier EI
ON E.event_type = EI.event_type
WHERE EVENT_NAME = 'Add to Cart'
AND VISIT_ID NOT IN (
				SELECT VISIT_ID 
				FROM EVENTS E
				JOIN event_identifier EI
                ON E.event_type = EI.event_type
				WHERE EVENT_NAME = 'Purchase'
				)
GROUP BY 1
ORDER BY 1
),
PURCHASE_CTE AS (
SELECT PRODUCT_CATEGORY,
COUNT(EVENT_NAME) AS PURCHASE_COUNTS
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
GROUP BY 1
ORDER BY 1
)
SELECT 
	V.*,
	abandoned_COUNTS,
	PURCHASE_COUNTS
INTO category_COUNTS
FROM 
	VIEW_CART_CTE V
JOIN abandoned_CTE A  ON V.PRODUCT_CATEGORY= A.PRODUCT_CATEGORY
JOIN PURCHASE_CTE P ON A.PRODUCT_CATEGORY = P.PRODUCT_CATEGORY


SELECT * FROM category_COUNTS

-------------------------------------------------------------------------------------------------------
Use your 2 new output tables - answer the following questions:

SELECT * FROM PRODUCT_COUNTS
SELECT * FROM category_COUNTS


-- QUE 1 :Which product had the most views, cart adds and purchases?

SELECT product_id,product_name,product_category,view_counts
FROM PRODUCT_COUNTS
ORDER BY view_counts DESC
LIMIT 1

SELECT product_id,product_name,product_category,cart_counts
FROM PRODUCT_COUNTS
ORDER BY cart_counts DESC
LIMIT 1

SELECT product_id,product_name,product_category,purchase_counts
FROM PRODUCT_COUNTS
ORDER BY purchase_counts DESC
LIMIT 1
---------------------------------------------------- OR -------------------------------------------
WITH product_rank_cte AS (
SELECT product_id,product_name,product_category,view_counts,cart_counts,purchase_counts,
RANK() OVER(ORDER BY VIEW_COUNTS DESC) AS view_rank,
RANK() OVER(ORDER BY cart_counts DESC) AS cart_rank,
RANK() OVER(ORDER BY purchase_counts DESC) AS purchase_rank
FROM PRODUCT_COUNTS
)
SELECT *
FROM product_rank_cte
WHERE view_rank =1 OR cart_rank = 1 OR purchase_rank =1 



-- QUE 2 : Which product was most likely to be abandoned?

SELECT  product_id,product_name,product_category,abandoned_counts
FROM PRODUCT_COUNTS
ORDER BY abandoned_counts DESC
LIMIT 1

-- QUE 3 : Which product had the highest view to purchase percentage?

SELECT  product_id,product_name,product_category,ROUND((100*purchase_counts::DECIMAL/view_counts),2)
FROM PRODUCT_COUNTS
ORDER BY 4 DESC
LIMIT 1

-- QUE 4 : What is the average conversion rate from view to cart add?

SELECT * FROM PRODUCT_COUNTS
SELECT * FROM category_COUNTS

SELECT 
 100*SUM(cart_counts)/SUM(view_counts)
FROM PRODUCT_COUNTS



-- QUE 5 : What is the average conversion rate from cart add to purchase? 

SELECT 
 100*SUM(purchase_counts)/SUM(cart_counts)
FROM PRODUCT_COUNTS


























