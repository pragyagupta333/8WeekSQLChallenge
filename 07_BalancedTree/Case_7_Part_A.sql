SET Search_path = balanced_tree
SELECT * FROM product_hierarchy
SELECT * FROM product_prices

SELECT * FROM product_details
SELECT * FROM sales

SELECT *
FROM product_details P
JOIN sales S ON P.product_id = S.prod_id
---------------------------- [A] High Level Sales Analysis ----------------------------------------
-- QUE 1 : What was the total quantity sold for all products?

SELECT SUM(qty) AS total_quatity
FROM sales

-- QUE 2 : What is the total generated revenue for all products before discounts?

SELECT SUM(price * qty ) AS revenue_before_discounts
FROM  sales 

-- QUE 3 : What was the total discount amount for all products?
--(discount in sales table is  percentage discount  
-- and discount is given on no of products(qty) purchase(price) and not on single product(price))

SELECT round(sum((price * qty) * (discount::NUMERIC / 100)),2 AS total_discount
FROM sales


