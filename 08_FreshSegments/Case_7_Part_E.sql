SET Search_path = balanced_tree
SELECT * FROM product_hierarchy
SELECT * FROM product_prices

SELECT * FROM product_details
SELECT * FROM sales 
-------------------------------------- [E] Bonus Challenge --------------------------------



SELECT pp.product_id, pp.price,
PH3.level_text || ' ' ||PH2.level_text || ' - ' ||PH1.level_text AS product_name,
PH1.id AS category_id,
PH2.id AS segment_id,
PH3.id AS style_id,
PH1.level_text AS category_name,
PH2.level_text AS segment_name,
PH3.level_text AS style_name
FROM product_hierarchy PH1
JOIN product_hierarchy PH2 ON PH1.id = PH2.parent_id
JOIN product_hierarchy PH3 ON PH2.id = PH3.parent_id
JOIN product_prices PP ON PH3.id = PP.id

---------------------------------------------- practice --------------------------------------

WITH product_name_cte AS (
SELECT ID,CASE WHEN parent_id = 5 OR parent_id = 6 THEN level_text || ' - Mens'
WHEN parent_id = 3 OR parent_id = 4 THEN level_text || ' - Womens' END AS product_name
FROM product_hierarchy ph
),
segment_id_cte AS (
SELECT ID, CASE WHEN parent_id is not null THEN parent_id END AS segment_id -- is not null is used to make case when expression a boolean value(so that case works)
FROM product_hierarchy
)
SELECT
pp.product_id,
pp.price,
product_name ,
CASE WHEN product_name like '%Womens' THEN 1 ELSE 2 END AS category_id,
segment_id,
CASE WHEN level_name = 'Style' THEN PH.id END AS Style_id,
CASE WHEN product_name like '%Womens' THEN 'Womens' ELSE 'Mens' END AS category_name,
CASE WHEN segment_id = 3 THEN 'Jeans' --(segment_id = parent_id)
WHEN segment_id = 4 THEN 'Jacket'
WHEN segment_id = 5 THEN 'Shirt'
WHEN segment_id = 6 THEN 'Socks'
END AS segment_name
FROM segment_id_cte SI
JOIN product_name_cte PN ON SI.id = pn.id
JOIN product_prices pp ON pn.id = pp.id
RIGHT JOIN product_hierarchy ph ON pp.id = ph.id
WHERE product_id IS NOT NULL