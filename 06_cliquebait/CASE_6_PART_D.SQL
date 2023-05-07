SET search_path = clique_bait;

SELECT * FROM event_identifier;
SELECT * FROM campaign_identifier;
SELECT * FROM page_hierarchy
SELECT * FROM users
SELECT * FROM events

SELECT * FROM PRODUCT_COUNTS
SELECT * FROM category_COUNTS
-------------------------------------------------------------------------------------------------------------------
/*Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number) */

CREATE TABLE purchase_details AS (
SELECT 
	user_id,
	visit_id,
	MIN(event_time) AS visit_start_time,
	SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
	SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
	(CASE WHEN visit_id IN (SELECT visit_id FROM events WHERE event_type = 3) THEN 1 ELSE 0 END ) AS purchase,
	C.campaign_name,
	SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
	SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
	STRING_AGG ( CASE WHEN  EVENT_NAME = 'Add to Cart' THEN  page_name END, ',' ORDER BY sequence_number ) AS cart_products
FROM events e
JOIN users u on u.cookie_id = e.cookie_id
JOIN event_identifier ei ON e.event_type = ei.event_type
JOIN page_hierarchy ph ON e.page_id = ph.page_id
LEFT JOIN campaign_identifier c ON event_time BETWEEN c.start_date AND c.end_date
WHERE PRODUCT_CATEGORY IS NOT NULL
GROUP BY 1,2,7
ORDER BY 1
)
SELECT * FROM Purchase_details

