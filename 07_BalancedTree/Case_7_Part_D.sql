SET Search_path = balanced_tree
SELECT * FROM product_hierarchy
SELECT * FROM product_prices

SELECT * FROM product_details
SELECT * FROM sales 
-------------------------------------- [D] Reporting Challenge --------------------------------
		to_char(start_txn_time,'month') AS Months, 


SELECT Top_Product,Months,Revenue,
	ROW_NUMBER() WITHIN GROUP (ORDER BY Revenue ) 
FROM 
		(SELECT  product_name as Top_Product, 
				extract(month from start_txn_time)AS Months, 
				SUM(qty*s.price) AS Revenue
		FROM sales  S
		JOIN product_details P ON S.prod_id = P.product_id
		GROUP BY 1,2
		ORDER BY 2,3 DESC)X
GROUP BY 1,2,3












