USE portfolio_walmart;

SELECT * FROM walmart;

--let's create a summary table for profits per category group
--with average median, worst and best prdouct and their balues and total profit per category
DROP TABLE IF EXISTS profits_table;

WITH 
sorted_data AS 
(
  SELECT
    category, profit,
    ROW_NUMBER() OVER (partition by category ORDER BY profit) AS RowAsc,
    ROW_NUMBER() OVER (partition by  category ORDER BY profit DESC) AS RowDesc
  FROM walmart
),
median_data AS
(
SELECT category, AVG(profit) AS median_profit
FROM sorted_data
WHERE RowAsc = RowDesc OR RowAsc + 1 = RowDesc OR RowAsc - 1 = RowDesc
group by category
),
agg_data AS
(
SELECT TOP 10 
	category,
	SUM(profit) AS total_profit,
	MIN(profit) AS min_profit,
	MAX(profit) AS max_profit,
	AVG(profit) AS avg_profit,
	SUM(quantity) AS category_quan 
FROM walmart
GROUP BY category
),

w_products AS 
(
SELECT 
	w.category,
	product_name AS worst_product
FROM walmart AS w 
INNER JOIN agg_data AS a ON profit = min_profit
),
b_products AS 
(
SELECT 
	w.category,
	product_name AS best_product
FROM walmart AS w 
INNER JOIN agg_data AS a ON profit = max_profit
),
profit_summary AS 
(
SELECT 
	
	DISTINCT m.category,
	worst_product,
	min_profit AS worst_profit,
	best_product,
	max_profit AS best_profit,
	ROUND(avg_profit,4) AS average,
	median_profit AS median,
	ROUND(total_profit,4) AS total


FROM median_data AS m
INNER JOIN agg_data AS a on a.category = m.category
INNER JOIN w_products AS w on w.category = m.category
INNER JOIN b_products AS b on b.category = m.category
)
SELECT 
RANK() OVER(ORDER BY total DESC, average DESC, median DESC) AS ranking,
*
INTO profits_table
FROM profit_summary
SELECT * FROM profits_table;

--let's create summary table for cities
DROP TABLE IF EXISTS #temp_city_agg
SELECT
	city,
	COUNT(*) * SUM(quantity) AS total_products_ordered,
	COUNT(*) AS total_orders,
	SUM(profit) AS total_profit,
	SUM(sales) AS total_sales
INTO #temp_city_agg
FROM walmart
GROUP BY city
ORDER BY SUM(profit) DESC

DROP TABLE IF EXISTS #temp_category_city_rank
SELECT 
	city,category,
	RANK() OVER(PARTITION BY city ORDER BY SUM(profit) DESC) AS ranking,
	SUM(profit) AS category_profit
INTO #temp_category_city_rank
FROM walmart
GROUP BY city, category ;

DROP TABLE IF EXISTS #temp_category_city_rank_1;
SELECT 
	* 
INTO #temp_category_city_rank_1
FROM #temp_category_city_rank
WHERE ranking = 1

DROP TABLE IF EXISTS city_summary;
SELECT 
	tca.city,
	total_products_ordered,
	total_orders,
	total_profit,
	total_sales,
tccr1.category AS top_category,
	category_profit
INTO city_summary
FROM #temp_city_agg AS tca
INNER JOIN #temp_category_city_rank_1 AS tccr1 ON tca.city = tccr1.city
SELECT * FROM city_summary;


--let's create summary table for cities
DROP TABLE IF EXISTS #temp_region_agg
SELECT
	region_state AS region,
	COUNT(*) * SUM(quantity) AS total_products_ordered,
	COUNT(*) AS total_orders,
	SUM(profit) AS total_profit,
	SUM(sales) AS total_sales
INTO #temp_region_agg
FROM walmart
GROUP BY region_state
ORDER BY SUM(profit) DESC

DROP TABLE IF EXISTS #temp_category_region_rank
SELECT 
	region_state AS region,
	category,
	RANK() OVER(PARTITION BY region_state ORDER BY SUM(profit) DESC) AS ranking,
	SUM(profit) AS category_profit
INTO #temp_category_region_rank
FROM walmart
GROUP BY region_state, category ;

DROP TABLE IF EXISTS #temp_category_region_rank_1;
SELECT 
	* 
INTO #temp_category_region_rank_1
FROM #temp_category_region_rank
WHERE ranking = 1

DROP TABLE IF EXISTS region_summary;
SELECT 
	tra.region,
	total_products_ordered,
	total_orders,
	total_profit,
	total_sales,
tcrr1.category AS top_category,
	category_profit
INTO region_summary
FROM #temp_region_agg AS tra
INNER JOIN #temp_category_region_rank_1 AS tcrr1 ON tra.region = tcrr1.region
SELECT * FROM region_summary;










