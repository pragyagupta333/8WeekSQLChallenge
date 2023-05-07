SET search_path = dannys_diner;

-- QUE 1: What is the total amount each customer spent at the restaurant?
-- ANS : 
SELECT S.CUSTOMER_ID, SUM(M.PRICE) AS Amount_Spent
FROM SALES S 
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY(CUSTOMER_ID)
ORDER BY AMOUNT_SPENT DESC;

-- QUE 2 : How many days has each customer visited the restaurant?
-- ANS :
SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS NO_OF_VISITS
FROM SALES
GROUP BY (CUSTOMER_ID);
		
-- QUE 3 : What was the first item from the menu purchased by each customer?
-- ANS : 		
WITH FIRST_ORDER AS(

	SELECT CUSTOMER_ID, PRODUCT_NAME, ORDER_DATE,
	DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) AS DATE_RANK
	FROM SALES S
	JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
 )

SELECT DISTINCT CUSTOMER_ID, PRODUCT_NAME AS FIRST_ITEM, ORDER_DATE
FROM FIRST_ORDER F 
WHERE F.DATE_RANK =1
	
-- QUE 4 : What is the most purchased item on the menu and how many times was it purchased by all customers?
-- ANS :
	
--  If There Is Only One Item As Most Purshased  (Like Ramen -> 8 orders)
SELECT M.PRODUCT_NAME AS MOST_PURCHASED_ITEM,
COUNT(S.PRODUCT_ID) PURCHASE_COUNT
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY PURCHASE_COUNT DESC
LIMIT 1 
				
-- If There Could Be More Than 1 Item As Most Purshased (like ramen -> total 8 orders and curry -> total 8 orders)

WITH PURCHASE_COUNT AS (

	SELECT M.PRODUCT_NAME, COUNT(S.PRODUCT_ID) NO_OF_ORDERS
	FROM SALES S
	JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
	GROUP BY M.PRODUCT_NAME
)

SELECT PRODUCT_NAME, NO_OF_ORDERS
FROM PURCHASE_COUNT C 
WHERE C.NO_OF_ORDERS = (SELECT MAX(C.NO_OF_ORDERS) 
						  FROM PURCHASE_COUNT C )

-- QUE 5 : Which item was the most popular for each customer?
-- ANS : 

WITH POPULAR_ITEM AS (

	SELECT S.CUSTOMER_ID, M.PRODUCT_NAME,COUNT(S.PRODUCT_ID) AS ORDER_COUNT,
	DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY COUNT(S.PRODUCT_ID)DESC ) AS RANK
	FROM SALES S
	JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
	GROUP BY S.CUSTOMER_ID,M.PRODUCT_NAME
)

SELECT CUSTOMER_ID, PRODUCT_NAME AS  MOST_POPULAR_ITEM, ORDER_COUNT
FROM POPULAR_ITEM
WHERE RANK =1


-- QUE 6 : Which item was purchased first by the customer after they became a member?
-- ANS : 

-- Assuming Orders Placed On Joining Date Are Placed As Customers Being A Member i.e.
-- (Customer 'A' Became A Member On Joining Date(7th Jan) first And Then Only After Becaming A Member He Placed The Order On 7th Jan ) 

WITH MEMBER_ORDER AS(

	SELECT S.CUSTOMER_ID,MU.PRODUCT_NAME,S.ORDER_DATE,ME.JOIN_DATE,
	DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS RANK
	FROM SALES S 
	JOIN MEMBERS ME ON S.CUSTOMER_ID = ME.CUSTOMER_ID
	JOIN MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
	WHERE S.ORDER_DATE >= ME.JOIN_DATE
)

SELECT CUSTOMER_ID AS CUSTOMER_AS_MEMBER, PRODUCT_NAME AS FIRST_ORDER 
FROM MEMBER_ORDER
WHERE RANK =1

				
-- QUE 7 : Which item was purchased just before the customer became a member?
-- ANS : 

WITH CUSTOMER_ORDER AS (

	SELECT S.CUSTOMER_ID,MU.PRODUCT_NAME,S.ORDER_DATE,ME.JOIN_DATE,
	DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE DESC) AS RANK
	FROM SALES S 
	JOIN MEMBERS ME ON S.CUSTOMER_ID = ME.CUSTOMER_ID
	JOIN MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
	WHERE S.ORDER_DATE < ME.JOIN_DATE
)

SELECT CUSTOMER_ID AS CUSTOMER, PRODUCT_NAME AS FIRST_ORDER 
FROM CUSTOMER_ORDER
WHERE RANK =1
		
-- QUE 8 : What is the total items and amount spent for each member before they became a member?
-- ANS :

SELECT S.CUSTOMER_ID AS "CUSTOMER",COUNT(S.PRODUCT_ID) AS "QUANTITY" ,SUM(M.PRICE) AS "AMOUNT SPENT"
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
LEFT JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE S.ORDER_DATE < MEM.JOIN_DATE 
GROUP BY S.CUSTOMER_ID
ORDER BY S.CUSTOMER_ID
		

-- QUE 9 : If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- ANS :

SELECT S.CUSTOMER_ID AS "CUSTOMER",
SUM(CASE 
		WHEN MU.PRODUCT_NAME ='sushi' THEN 20*(MU.PRICE)
		ELSE 10*(MU.PRICE)
	END)AS "POINTS"
FROM SALES S
JOIN MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
GROUP BY S.CUSTOMER_ID
ORDER  BY CUSTOMER_ID
		
-- QUE 10 : In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--		   not just sushi - how many points do customer A and B have at the end of January?
-- ANS :	
SELECT S.CUSTOMER_ID AS "CUSTOMER",
SUM(
	CASE 
		WHEN S.ORDER_DATE BETWEEN MEM.JOIN_DATE AND (MEM.JOIN_DATE + 6) 
			THEN 20*(MU.PRICE)
		WHEN MU.PRODUCT_NAME ='sushi' 
			THEN 20*(MU.PRICE)
		ELSE 10*(MU.PRICE)
	END)AS "POINTS"
FROM SALES S
JOIN MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE DATE_PART('MONTH',S.ORDER_DATE) = 1
GROUP BY 1
ORDER BY 1

---------------------------------------------- BONUS QUESTIONS -----------------------------------------

-- QUE 1 : Join All The Things 
-- ANS :
SELECT S.CUSTOMER_ID, S.ORDER_DATE,MU.PRODUCT_NAME, MU.PRICE, 
CASE 
	WHEN S.ORDER_DATE < MEM.JOIN_DATE OR MEM.JOIN_DATE IS NULL THEN 'N'
	ELSE 'Y'
END AS MEMBER
FROM SALES S
JOIN  MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
LEFT JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
ORDER BY 1,2,3

-- QUE 2 : Rank All The Things
-- ANS : 	
WITH MEMBER_CTE AS(
	SELECT S.CUSTOMER_ID, S.ORDER_DATE,MU.PRODUCT_NAME, MU.PRICE, 
	CASE 
		WHEN S.ORDER_DATE < MEM.JOIN_DATE OR MEM.JOIN_DATE IS NULL THEN 'N'
		ELSE 'Y'
	END AS MEMBER
	FROM SALES S
	JOIN  MENU MU ON S.PRODUCT_ID = MU.PRODUCT_ID
	LEFT JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
	ORDER BY 1,2,3
)
SELECT *,
	CASE 
		WHEN MEMBER = 'Y' THEN DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ,(CASE WHEN MEMBER = 'Y' THEN 1 ELSE 0 END) ORDER BY ORDER_DATE)
		ELSE NULL
	END AS RANKING
FROM MEMBER_CTE 



----------------------------------------- DATABASE ---------------------------------------------------------------------
/*CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner; */

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
