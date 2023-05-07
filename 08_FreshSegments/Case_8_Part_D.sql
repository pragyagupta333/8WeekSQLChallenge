SET search_path = fresh_segments
SELECT * FROM interest_map
SELECT * FROM Interest_Metrics 
------------------------------------------------------ [D] Index Analysis ----------------------------------------------

-- Que 1 : What is the top 10 interests by the average composition for each month?



WITH CTE AS (   

SELECT  month_year, 
interest_name,
CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
FROM interest_metrics i
LEFT JOIN interest_map i2 ON i.interest_id = i2.id
WHERE month_year IS NOT NULL
), 
RANK_CTE AS (
SELECT month_year, 
Interest_name,
average_composition,
rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
FROM CTE
)

SELECT *
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10;

-- Que 2 : For all of these top 10 interests - which interest appears the most often?
WITH CTE AS (   
SELECT  month_year, 
interest_name,
CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
FROM interest_metrics i
LEFT JOIN interest_map i2 ON i.interest_id = i2.id
WHERE month_year IS NOT NULL
), 
RANK_CTE AS (
SELECT     month_year, 
Interest_name,
average_composition,
rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
FROM CTE)

SELECT interest_name, COUNT(*) AS Count_Appearance
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY interest_name
ORDER BY Count_Appearance DESC ;


-- Que 3 : What is the average of the average composition for the top 10 interests for each month?
WITH CTE AS (  
SELECT  month_year, 
interest_name,
CAST( composition/index_value AS DECIMAL(10,2)) as average_composition
FROM interest_metrics i
LEFT JOIN interest_map i2 ON i.interest_id = i2.id
WHERE month_year IS NOT NULL
), 
RANK_CTE AS (
SELECT     month_year, 
Interest_name,
average_composition,
rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
FROM CTE)

SELECT month_year, AVG(average_composition) AS AVERAGE_AVG_COMP
FROM RANK_CTE
WHERE RANK_Avg_Comp <= 10
GROUP BY month_year
ORDER BY month_year;


-- Que 4 : What is the 3 month rolling average of the max average composition value from September 2018 to August 2019
--         and include the previous top ranking interests in the same output shown below.
WITH CTE AS (   
SELECT  month_year, 
interest_name,
CAST( composition/index_value AS FLOAT) as average_composition
FROM interest_metrics i
LEFT JOIN interest_map i2 ON i.interest_id = i2.id
WHERE month_year IS NOT NULL
                ), 
RANK_CTE AS (
SELECT month_year, 
Interest_name,
average_composition,
rank() over (partition by month_year order by average_composition DESC ) AS RANK_Avg_Comp
FROM CTE),

MAX_CTE AS  (   
SELECT  month_year,
interest_name,
ROUND(AVG(average_composition)::numeric,2) AS AVERAGE_AVG_COMP
FROM RANK_CTE
WHERE RANK_Avg_Comp = 1
GROUP BY month_year,interest_name
),

AVG_3month_CTE AS (
SELECT *,
ROUND(AVG(AVERAGE_AVG_COMP) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  ),2) AS THREE_month_moving_avg
FROM MAX_CTE),


LAG_CTE as (
SELECT *,
ROUND(LAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year),2) AS one_month,
ROUND(LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year),2) AS two_month,
CONCAT( LAG(interest_name,1) OVER(ORDER BY month_year)  , ':',lAG(AVERAGE_AVG_COMP,1) OVER(ORDER BY month_year)) AS one_month_ago,
CONCAT( LAG(interest_name,2) OVER(ORDER BY month_year)  , ':',LAG(AVERAGE_AVG_COMP,2) OVER(ORDER BY month_year)) AS two_month_ago
FROM AVG_3month_CTE )
                
SELECT month_year,
        interest_name,
        AVERAGE_AVG_COMP,
        one_month_ago,
        two_month_ago
FROM LAG_CTE
WHERE one_month IS NOT NULL AND two_month IS NOT NULL;


-- Que 5 : Provide a possible reason why the max average composition might change from month to month? 
--         Could it signal something is not quite right with the overall business model for Fresh Segments?

