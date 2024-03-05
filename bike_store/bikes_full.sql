--Database name created for this project is 'portfolio_bikes' import datasets there!
--Asking questions about customers
USE portfolio_bikes
--How many customers gave their phone numbers to our company

--Table was not created properly NULLs are written as varchar not NA in the table
--correcting:
--UPDATE customers
--SET phone = NULL
--WHERE phone LIKE 'NULL';
--table doesnt allow nulls altering the table:
ALTER TABLE customers
ALTER COLUMN phone VARCHAR(255) NULL
UPDATE customers
SET phone = NULL
WHERE phone LIKE 'NULL'


--employees ct expressions
DROP TABLE IF EXISTS employees_full;
WITH ord AS
(
    SELECT 
        o.staff_id,s.manager_id,
        COUNT(order_id) AS orders_count
    FROM orders AS o
	LEFT JOIN staffs AS s ON o.staff_id = s.staff_id
    GROUP BY o.staff_id,manager_id
),
employees AS
(
select distinct s1.staff_id, s2.manager_id
	FROM staffs AS s1
	LEFT JOIN staffs AS s2 ON s1.staff_id = s2.manager_id
),
managers AS
(
SELECT
	manager_id,
	COUNT(manager_id) AS subordinates
FROM staffs
GROUP BY manager_id
)

--ASKING QUESTIONS ABOUT EMPLOYEES:
SELECT
    s.staff_id,
	s.manager_id,
	s.store_id,
    CONCAT(s.first_name, ' ', s.last_name) AS emp_full_name,
	CONCAT(staffs.first_name, ' ', staffs.last_name) AS manag_full_name,
	subordinates,
    CASE 
        WHEN s.manager_id IS NULL THEN 'head_manager'
        WHEN s.staff_id IN (SELECT manager_id FROM staffs)
		AND s.staff_id IN (SELECT staff_id FROM ord) THEN 'manager'
		WHEN s.staff_id IN (SELECT manager_id FROM staffs) 
		AND s.staff_id NOT IN (SELECT staff_id FROM ord) THEN 'higher_manager'
		WHEN s.staff_id IN (SELECT staff_id FROM ord) THEN 'customer_service'
		ELSE 'other'  END AS position,
	orders_count,
	st.state,
	st.store_name
INTO employees_full
FROM staffs AS s
LEFT JOIN ord ON s.staff_id = ord.staff_id
LEFT JOIN managers ON s.staff_id = managers.manager_id
LEFT JOIN staffs ON s.manager_id = staffs.staff_id
INNER JOIN stores AS st ON s.store_id = st.store_id
WHERE s.active = 1


SELECT * FROM employees_full
ORDER BY subordinates DESC, position
--We can observe that Fabiola Jackson is the only person who does not answer to anyone,
--she is the head manager.
--I created a column that tells us who answers to who called manag_full_name
--I created a column with number of subordinates per working manager.
--I created a position column that defines employee's job
--on basis of orders handled by employee and number of subordinates under his command
--I created a column that calculates total number of orders per employee


--ASKING QUESTIONS ABOUT PRODUCTS
--starting by updating list_price column in products table by rounding list_price to 2 places after comma
UPDATE products
SET list_price = ROUND(list_price, 2)
--Let's see how many products each category has:

DROP TABLE IF EXISTS #temp_cat
SELECT
	c.category_id,
	COUNT(*) AS unique_models_count
INTO #temp_cat
FROM products AS p 
INNER JOIN categories AS c ON p.category_id = c.category_id
GROUP BY c.category_id

DROP TABLE IF EXISTS #temp_models
SELECT
	p.product_id,
	category_id,
	SUM(quantity) AS quantity,
	RANK() OVER(PARTITION BY category_id ORDER BY SUM(quantity) DESC) AS ranking
INTO #temp_models
FROM products AS p
INNER JOIN stocks AS s ON s.product_id = p.product_id
GROUP BY 	p.product_id, category_id

DROP TABLE IF EXISTS #temp_top_models
SELECT 
	p.category_id,
	quantity,
	p.product_name
INTO #temp_top_models
FROM #temp_models AS t
INNER JOIN products AS p ON t.product_id = p.product_id
WHERE ranking = 1

DROP TABLE IF EXISTS #temp_brands
SELECT
	category_id,
	b.brand_id,
	SUM(quantity) AS quantity,
	RANK() OVER(PARTITION BY category_id ORDER BY SUM(quantity) DESC) AS ranking
INTO #temp_brands
FROM products AS p
INNER JOIN stocks AS s ON p.product_id = s.product_id
INNER JOIN brands AS b on b.brand_id=p.brand_id
GROUP BY 
	category_id,
	b.brand_id
ORDER BY category_id, brand_id


DROP TABLE IF EXISTS #temp_top_brands
SELECT 
	category_id,
	brand_id,
	quantity
INTO #temp_top_brands
FROM #temp_brands
WHERE ranking = 1

DROP TABLE IF EXISTS #temp_pro
SELECT
	c.category_id,
	category_name,
	SUM(s.quantity) AS category_quantity,
	unique_models_count,
	topm.product_name AS top_model
	--,
	--b.brand_name AS top_brand
INTO #temp_pro
FROM categories AS c
INNER JOIN products AS p ON p.category_id = c.category_id
INNER JOIN stocks AS s ON s.product_id = p.product_id
INNER JOIN #temp_cat AS cat ON cat.category_id =	c.category_id
INNER JOIN #temp_top_models AS topm ON topm.category_id = c.category_id
--INNER JOIN #temp_top_brands AS topb ON topb.category_id = topm.category_id
--INNER JOIN brands AS b ON b.brand_id = topb.brand_id
GROUP BY 
	category_name,
	unique_models_count,
	topm.product_name,
	c.category_id

--median and avg price of bikes in each category
DROP TABLE IF EXISTS #temp_cat_price

SELECT 
list_price,
quantity,
category_id
INTO #temp_cat_price
FROM products AS p 
LEFT JOIN stocks AS s ON p.product_id = s.product_id;

DROP TABLE IF EXISTS #temp_agg_cat_price
SELECT 
category_id, 
ROUND(SUM(list_price*quantity)/SUM(quantity),2) AS avg_price,
MAX(list_price) AS most_expensive,
MIN(list_price) AS least_expensive
INTO #temp_agg_cat_price
FROM #temp_cat_price
GROUP BY category_id;

DROP TABLE IF EXISTS #temp_med_cat_price;

SELECT 
    category_id,
    list_price,
    dense_rank() OVER (PARTITION BY category_id ORDER BY list_price) AS RowAsc,
    dense_rank() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS RowDesc
INTO #temp_med_cat_price
FROM #temp_cat_price;

DROP TABLE IF EXISTS #temp_med_cat_price_full
SELECT  
    category_id,
    ROUND(AVG(list_price),2) AS median_model_price
INTO #temp_med_cat_price_full
FROM #temp_med_cat_price
WHERE RowAsc = RowDesc OR RowAsc + 1 = RowDesc OR RowAsc = RowDesc + 1
GROUP BY category_id;

DROP TABLE IF EXISTS #temp_cat_price_full
Select 
a.*,
median_model_price
into #temp_cat_price_full
from #temp_agg_cat_price as a
inner join #temp_med_cat_price_full as b on a.category_id = b.category_id

DROP TABLE IF EXISTS category_full
SELECT 
	pro.category_id,
	category_name,
	category_quantity,
	unique_models_count,
	avg_price,
	median_model_price,
	least_expensive,
	most_expensive,
	top_model,
	b.brand_name AS top_brand
INTO category_full
FROM #temp_pro AS pro
INNER JOIN #temp_top_brands AS topb ON topb.category_id = pro.category_id
INNER JOIN brands AS b ON b.brand_id = topb.brand_id
INNER JOIN #temp_cat_price_full AS price ON pro.category_id = price.category_id

SELECT * FROM category_full

--ASKING QUESTIONS ABOUT ORDERS
DROP TABLE IF EXISTS orders_full
SELECT
	FORMAT(order_date, 'yyyy-MM') AS date,
	COUNT(*) AS num_orders,
	COUNT(CASE WHEN required_date >= shipped_date THEN 1 ELSE NULL END ) AS ontime_orders,
	COUNT(CASE WHEN required_date < shipped_date THEN 1 ELSE NULL END) AS overdue_orders,
	LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')) AS prev_num_orders,
	COUNT(*)-LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')) AS change_nominal,
	ROUND(ABS(COUNT(*)-LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')))*100/COUNT(*),2) AS change_prec,
	CASE
		WHEN COUNT(*)-LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')) = 0 THEN 'stagnation'
		WHEN COUNT(*)-LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')) > 0 THEN 'increase'
		WHEN COUNT(*)-LAG(COUNT(*)) OVER(ORDER BY FORMAT(order_date, 'yyyy-MM')) < 0 THEN 'decrease'
		ELSE NULL END AS shift
	INTO orders_full
	FROM orders
	GROUP BY FORMAT(order_date, 'yyyy-MM');

DROP TABLE IF EXISTS #temp_day_orders
SELECT
	COUNT(*) AS num_orders_daily,
	DATENAME(dw, order_date) AS day_week,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
INTO #temp_day_orders
FROM orders
GROUP BY DATENAME(dw, order_date);

DROP TABLE IF EXISTS #temp_month_orders
SELECT
		COUNT(*) AS num_orders_monthly,
		FORMAT(order_date, 'MM') AS month,
		RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
INTO #temp_month_orders
FROM orders  
GROUP BY FORMAT(order_date, 'MM')
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS #temp_year_orders
SELECT
		COUNT(*) AS num_orders_yearly,
		FORMAT(order_date, 'yyyy') AS year,
		RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
INTO #temp_year_orders
FROM orders  
GROUP BY FORMAT(order_date, 'yyyy')
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS orders_top
SELECT TOP 3
	num_orders_daily,day_week,
	num_orders_monthly,FORMAT(CAST('1900-' + month + '-01' AS DATE), 'MMMM') AS month,
	num_orders_yearly,year
INTO orders_top
FROM #temp_month_orders AS d
LEFT JOIN #temp_day_orders AS m ON d.ranking=m.ranking
LEFT JOIN #temp_year_orders AS y ON d.ranking=y.ranking

SELECT * FROM orders_full
SELECT * FROM orders_top











