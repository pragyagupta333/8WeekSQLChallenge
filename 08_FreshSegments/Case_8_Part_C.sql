SET search_path = fresh_segments
SELECT * FROM interest_map
SELECT * FROM Interest_Metrics 

------------------------------------------------------ [C] Segment Analysis ----------------------------------------------



-- Que 1 : Using our filtered dataset by removing the interests with less than 6 months worth of data, 
-- which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
-- Only use the maximum composition value for each interest but you must keep the corresponding month_year

DROP TABLE IF EXISTS interest_metrics_T;
CREATE TEMP TABLE interest_metrics_T AS (
	WITH cte_total_months AS (
		SELECT interest_id,
			count(DISTINCT month_year) AS total_months
		FROM interest_metrics
		GROUP BY interest_id
		HAVING count(DISTINCT month_year) >= 6
	)
	SELECT *
	FROM interest_metrics
	WHERE interest_id IN (
			SELECT interest_id
			FROM cte_total_months
		)
);


WITH get_top_ranking AS (
	SELECT month_year,
		interest_id,
		ip.interest_name,
		composition,
		rank() OVER (ORDER BY composition desc) AS rnk
	FROM interest_metrics_T
		JOIN interest_map AS ip ON interest_id::numeric = ip.id
)
SELECT *
FROM get_top_ranking
WHERE rnk <= 10;


--Que 2 : Which 5 interests had the lowest average ranking value?

SELECT interest_name,ROUND(avg(ranking),2) AS avg_rnk
FROM interest_metrics_T T
JOIN interest_map M ON T.interest_id = m.id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- Que 3 : Which 5 interests had the largest standard deviation in their percentile_ranking value?

SELECT interest_name,ROUND(stddev(percentile_ranking)::NUMERIC,2) AS percentile_ranking
FROM interest_metrics_T T
JOIN interest_map M ON T.interest_id = m.id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- Que 4 : For the 5 interests found in the previous question 
-- what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? 
-- Can you describe what is happening for these 5 interests?

WITH get_std_dev AS (
	SELECT interest_id,
		ip.interest_name,
		round(stddev(percentile_ranking)::numeric, 2) AS std_dev,
		rank() OVER (
			ORDER BY stddev(percentile_ranking) desc
		) AS rnk
	FROM filtered_data
		JOIN fresh_segments.interest_map AS ip ON interest_id::numeric = ip.id
	GROUP BY interest_id,
		ip.interest_name
),
-- Reduce the list down to the lowest 5
get_interest_id AS (
	SELECT *
	FROM get_std_dev
	WHERE rnk <= 5
),
-- Get the min and max values via rank or row_number for values in the previous CTE (the lowest 5)
get_min_max as (
	SELECT month_year,
		interest_id,
		percentile_ranking,
		rank() over(
			PARTITION BY interest_id
			ORDER BY percentile_ranking
		) AS min_rank,
		rank() over(
			PARTITION BY interest_id
			ORDER BY percentile_ranking desc
		) AS max_rank
	FROM filtered_data
	WHERE interest_id IN (
			SELECT interest_id
			FROM get_interest_id
		)
) -- Join the map table to get the interest_name and select all values with the rank of one.
SELECT gmm.month_year,
	ip.interest_name,
	percentile_ranking
FROM get_min_max AS gmm
	JOIN fresh_segments.interest_map AS ip ON ip.id = gmm.interest_id::numeric
WHERE min_rank = 1
	OR max_rank = 1
ORDER BY interest_id,
	percentile_ranking;
-- Que 5 : How would you describe our customers in this segment based off their composition and ranking values?
-- What sort of products or services should we show to these customers and what should we avoid?






