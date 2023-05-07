SET Search_path = balanced_tree
SELECT * FROM product_hierarchy
SELECT * FROM product_prices

SELECT * FROM product_details
SELECT * FROM sales
-------------------------------------- [B]Transaction Analysis --------------------------------
-- QUE 1 : How many unique transactions were there?

SELECT count(distinct txn_id) AS uniqur_txn_count
FROM sales

-- QUE 2 : What is the average unique products purchased in each transaction?

WITH products_count AS (
SELECT txn_id,count(distinct prod_id) AS product_purchase_count
FROM sales
GROUP BY txn_id
)			 
SELECT avg(product_purchase_count)::int AS avg_number_of_items
FROM products_count
			 
			 
-- QUE 3 : What are the 25th, 50th and 75th percentile values for the revenue per transaction?

WITH revenue_cte AS (
SELECT txn_id, sum(price*qty) AS Revenue
FROM sales
GROUP BY 1
)						 
SELECT  
	percentile_cont(0.25) within group (order by Revenue) AS "25th percentile",
	percentile_cont(0.50) within group (order by Revenue) AS "50th percentile",
	percentile_cont(0.75) within group (order by Revenue) AS "75th percentile"
FROM revenue_cte
			 		 
-- QUE 4 : What is the average discount value per transaction?
			 
WITH discount_cte AS (
SELECT txn_id,
ROUND(sum(price*qty*(discount/100.0)),2) AS discount_per_txn
FROM sales
GROUP BY 1
)
SELECT round(avg(discount_per_txn),2)
FROM discount_cte
			 
-- QUE 5 : What is the percentage split of all transactions for members vs non-members?


WITH member_cte AS (
SELECT count(distinct txn_id) AS MEMBER_TXN_COUNT
FROM sales
WHERE member = 'true'
),
non_member_cte AS (
SELECT count(distinct txn_id) AS NON_MEMBER_TXN_COUNT
FROM sales
WHERE member = 'false'
),			 
total_members_cte AS(
SELECT 
count(distinct txn_id) AS total_txn_count
FROM sales 
)
SELECT ROUND(100.0*MEMBER_TXN_COUNT / total_txn_count,2) AS MEMBER_PERCENT,
		 ROUND(100.0*NON_MEMBER_TXN_COUNT / total_txn_count,2) AS NON_MEMBER_PERCENT
FROM member_cte,non_member_cte,total_members_cte
---------------------------- OR ----------------------------------------			 
SELECT 
  CAST(100.0*COUNT(DISTINCT CASE WHEN member = 'true' THEN txn_id END) 
		/ COUNT(DISTINCT txn_id) AS FLOAT) AS members_pct,
  CAST(100.0*COUNT(DISTINCT CASE WHEN member = 'false' THEN txn_id END)
		/ COUNT(DISTINCT txn_id) AS FLOAT) AS non_members_pct
FROM sales;
---------------------- OR -----------------------------
SELECT member,
	-- The OVER clause allows us to nest aggregate functions
	round(100 * (count(DISTINCT txn_id) / sum(count(DISTINCT txn_id)) OVER()),2) AS percentage_distribution
FROM balanced_tree.sales
GROUP BY MEMBER;
			 
			 			 
-- QUE 6 : What is the average revenue for member transactions and non-member transactions?

WITH Revenuye_cte AS(
SELECT 
	txn_id,
	member,
	SUM(PRICE*QTY)*(1-discount/100.0) as  Revenue
FROM sales
GROUP BY txn_id,member,discount
)
SELECT 
	CASE member WHEN 'false' THEN 'Non-Member'
				ELSE 'Member'
	END AS Customers,
	AVG(Revenue)::numeric(5,2) As Revenue
FROM Revenuye_cte
GROUP BY member


			 
			 