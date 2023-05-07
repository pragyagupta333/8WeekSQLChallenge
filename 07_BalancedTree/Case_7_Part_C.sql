SET Search_path = balanced_tree
SELECT * FROM product_hierarchy
SELECT * FROM product_prices

SELECT * FROM product_details
SELECT * FROM sales
-------------------------------------- [C] Product Analysis--------------------------------

-- QUE 1 : What are the top 3 products by total revenue before discount?

SELECT product_id, product_name,SUM(qty*s.price) AS Revenue_Before_Discount
FROM sales  S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3

-- QUE 2 : What is the total quantity, revenue and discount for each segment?
-- Note : discount in dataset is as percentage_discount. So, dividing discount by 100

SELECT segment_id,segment_name,SUM(qty) AS quantity,SUM(qty*s.price) AS Revenue_Before_Discount, ROUND(SUM(qty*S.price*discount/100.0),2) AS discount  
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
ORDER BY 1

-- QUE 3 : What is the top selling product for each segment?

SELECT product_name as Top_selling_product,segment_name,SUM(qty) AS quantity
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
ORDER BY 3 DESC

-- QUE 4 : What is the total quantity, revenue and discount for each category?

SELECT category_id,category_name,SUM(qty) AS quantity,SUM(qty*s.price) AS Revenue_Before_Discount, ROUND(SUM(qty*S.price*discount/100.0),2) AS discount  
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
ORDER BY 1

-- QUE 5 : What is the top selling product for each category?

WITH top_selling_cte AS (
SELECT category_name,product_name as Top_selling_product,SUM(qty) AS quantity,
DENSE_RANK() OVER(PARTITION BY category_name ORDER BY SUM(qty) desc) AS rank
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
)
SELECT category_name, Top_selling_product, quantity
FROM top_selling_cte
WHERE rank = 1

ROUND(SUM(qty*s.price)*(1-discount/100.0),2) AS Revenue_After_Discount

-- QUE 6 : What is the percentage split of revenue by product for each segment?

WITH total_revenue_cte AS (
SELECT segment_name,product_name,SUM(qty*s.price) AS Revenue_Before_Discount
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
)
SELECT 
  segment_name,
  product_name,
  CAST(100.0 * Revenue_Before_Discount 
	/ SUM(Revenue_Before_Discount) OVER (PARTITION BY segment_name) 
    AS decimal (10, 2)) AS percent_distribution
FROM total_revenue_cte;

-- 	QUE 7 : What is the percentage split of revenue by segment for each category?

WITH total_revenue_cte AS (
SELECT category_name,segment_name,SUM(qty*s.price) AS Revenue_Before_Discount
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1,2
)
SELECT 
  category_name,
  segment_name,
  CAST(100.0 * Revenue_Before_Discount 
	/ SUM(Revenue_Before_Discount) OVER (PARTITION BY category_name) 
    AS decimal (10, 2)) AS percent_distribution
FROM total_revenue_cte;


-- QUE 8 : What is the percentage split of total revenue by category?

WITH total_revenue_cte AS (
SELECT category_name, SUM(qty*s.price) AS Revenue_Before_Discount
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
GROUP BY 1
)

SELECT 
  category_name,
  CAST(100.0 * Revenue_Before_Discount 
	/ SUM(Revenue_Before_Discount) OVER () 
    AS decimal (10, 2)) AS percent_distribution
FROM total_revenue_cte;

-- QUE 9 : What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

WITH txn_count_cte AS (
SELECT product_name, COUNT( distinct  txn_id) product_txn_count, (SELECT count(distinct txn_id) FROM sales) as Total_no_of_txn
FROM sales S
JOIN product_details P ON S.prod_id = P.product_id
WHERE qty > 0
GROUP BY 1
)
SELECT 
product_name,
CAST( 100.0*product_txn_count 
	/ Total_no_of_txn
    AS decimal (10, 2)) AS txn_penetration
FROM txn_count_cte

-- QUE 10 : What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH CTE AS (   SELECT  txn_id, 
                        p1.product_name
                FROM sales s 
                LEFT JOIN product_details  p1 ON s.prod_id = p1.product_id)

SELECT 
        C1.product_name AS PRODUCT_1,
        C2.product_name AS PRODUCT_2,
        C3.product_name AS PRODUCT_3,
        COUNT (*) AS time_trans
FROM CTE c1 
LEFT JOIN CTE C2 ON C1.txn_id =C2.txn_id  AND C1.product_name < c2.product_name
LEFT JOIN CTE C3 ON C1.txn_id = C3.txn_id AND C1.product_name < c3.product_name AND C2.product_name < c3.product_name
WHERE C1.product_name IS NOT NULL and C2.product_name IS NOT NULL AND C3.product_name IS NOT NULL
GROUP BY C1.product_name, C2.product_name,C3.product_name
ORDER BY time_trans DESC 
LIMIT 1;
