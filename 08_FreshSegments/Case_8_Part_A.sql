SET search_path = fresh_segments
SELECT * FROM interest_map
SELECT * FROM Interest_Metrics

---------------------------------------- [A] Data Exploration and Cleansing---------------------------------------
-- QUE 1 : Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

-- altering column month_year from varchar(7) to varchar(10) => so to be able to  store concataneted date value ('01-') to month_year
ALTER TABLE Interest_Metrics 
	ALTER COLUMN month_year type varchar(10) 

-- concat date value => so to  be able to achieve a date format after which datatype date can be casted
UPDATE Interest_Metrics
	SET month_year = '01-'||month_year


ALTER TABLE Interest_Metrics 
	ALTER COLUMN month_year type date USING month_year::date;

-- QUE 2 : What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT month_year, COUNT(*)
FROM Interest_Metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST

-- QUE 3 : What do you think we should do with these null values in the fresh_segments.interest_metrics

-- QUE 4 : How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

ALTER TABLE Interest_Metrics
	ALTER COLUMN interest_id type INT USING interest_id::integer

SELECT COUNT(interest_id) 
FROM
	(SELECT interest_id FROM Interest_Metrics 
	EXCEPT
	SELECT id FROM interest_map) Metrics_not_map

SELECT COUNT(id) 
FROM
(	SELECT id FROM interest_map
	EXCEPT
	SELECT interest_id FROM Interest_Metrics ) map_not_metric


-- QUE 5 : Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT COUNT(ID),COUNT(*)
FROM interest_map

SELECT COUNT( DISTINCT ID),COUNT(*)
FROM interest_map -- So, ids are unique

-- QUE 6 : What sort of table join should we perform for our analysis and why? 
-- Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

SELECT _month, _year, month_year, interest_id, composition, index_value, ranking, percentile_ranking, interest_name, interest_summary, created_at, last_modified
FROM interest_metrics MT
LEFT JOIN interest_map MP ON MT.interest_id = MP.id
WHERE interest_id = 21246

-- QUE 7 : Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?









