use portfolio_paintings; --this how i called my databse containg all needed data files
--I will analyze date on the go in sql file but also prepare and create new data files for visulaisation
--select * from product_size
--QUERIES ABOUT PRICES
--select * from product_size -- looking at the data

--creating median sales price for summary table
DROP TABLE IF EXISTS #ordered_sale_price
    SELECT 
        sale_price,
        ROW_NUMBER() OVER (ORDER BY sale_price) AS RowAsc,
        ROW_NUMBER() OVER (ORDER BY sale_price DESC) AS RowDesc
	INTO #ordered_sale_price
    FROM product_size
DROP TABLE IF EXISTS #median_sale_price
SELECT AVG(sale_price * 1.0) AS median_sale
INTO #median_sale_price
FROM #ordered_sale_price
WHERE RowAsc IN ((RowDesc + 1) / 2, (RowDesc + 2) / 2);
--sale price is considered as the price in sale transaction 
--in how many cases sale price differs from regular price, is it higher, lower? 
--what is the median max and min prices of sales?
DROP TABLE IF EXISTS #products_price
SELECT
COUNT(distinct work_id) as art_pieces,
round(100.00*COUNT(CASE WHEN sale_price > regular_price THEN 1 ELSE NULL END)/COUNT(*),0) AS sale_higher,
round(100.00*COUNT(CASE WHEN sale_price < regular_price THEN 1 ELSE NULL END)/COUNT(*),0) AS regular_higher,
round(100.00*COUNT(CASE WHEN sale_price = regular_price THEN 1 ELSE NULL END)/COUNT(*),0) AS same_price,
AVG(sale_price) AS avg_sale_price,
AVG(regular_price) AS avg_regular_price,
abs(AVG(sale_price) - AVG(regular_price)) AS avg_price_diff,
ROUND(100.0*AVG(sale_price)/AVG(regular_price),0) AS avg_price_percent,

MAX(sale_price) as max_sale_price, min(sale_price) as min_sale_price
INTO #products_price
FROM product_size

DROP TABLE IF EXISTS price_summary
SELECT 
*
INTO price_summary
FROM #products_price
CROSS JOIN #median_sale_price
--select * from price_summary
-- we have 14630 pieces of art
--art never sales above regular_price
--93 percent of transactions had lower price then regular, 7 percent had the same price
--avg sale price is about 55 percent of avg regular price
--the highest sold price is 1115 and lowest one is 10
--median sale price equals 305, so about 50% of other art pieces is at a lower sale price and 50% at higher

--creating temp table for later joining
DROP TABLE IF EXISTS #temp_price
SELECT 
	work_id,
	AVG(sale_price) AS avg_sale
INTO #temp_price
FROM product_size
GROUP BY work_id

--analysing tables
--subject analysis
--select * from subject
--what categories do we have and how many pieces of art are in each category
--what is the average price of art pieces per different category

--select count(*) from subject
--select count(*) from product_size
--number of records isn't equal



--creating median price per subject of art
drop table if exists #subject_median_data
select 
	case when subject is null then 'Other' else subject end as subject, --creating Other label if subject is null
	sale_price
INTO #subject_median_data
from product_size as ps
left join subject as s on s.work_id = ps.work_id
order by sale_price asc

--creating order for median calculating
DROP TABLE IF EXISTS #ordered_data;
    SELECT 
        subject,
        sale_price,
        ROW_NUMBER() OVER (PARTITION BY subject ORDER BY sale_price) AS RowAsc,
        COUNT(*) OVER (PARTITION BY subject) AS roww
	into #ordered_data
    FROM #subject_median_data;



--creating table for agg data per subject
DROP TABLE IF EXISTS #temp_subject
SELECT 
	case when s.subject is null then 'Other' else s.subject end as subject,
	COUNT(*) AS art_pieces, 
	AVG(sale_price) AS avg_sale,
	min(sale_price) as lowest_sale,
	max(sale_price) as highest_sale
INTO #temp_subject
FROM product_size AS ps
LEFT JOIN subject AS s ON s.work_id = ps.work_id
GROUP BY s.subject
--select * from #temp_subject

--median calculation
drop table if exists #median_sale_price_
SELECT 
    subject,
    AVG(sale_price * 1.0) AS median_sale
INTO #median_sale_price_
FROM #ordered_data
WHERE RowAsc IN ((roww + 1) / 2, (roww + 2) / 2)
GROUP BY subject

--adding median to agg data
drop table if exists #temp_subject_data
select 
	ts.*, median_sale
into #temp_subject_data
from #temp_subject as ts
inner join #median_sale_price_ as msp on ts.subject = msp.subject
--select * from #temp_subject_data

--creating ranking for filtering lowest and higest priced paintings
drop table if exists #paintings_prices
select 
	case when subject is null then 'Other' else subject end as subject,
	name,
	sale_price,
	row_number() over(partition by subject order by sale_price desc, regular_price desc) as ranking
into #paintings_prices
from product_size as ps
left join subject as s on ps.work_id = s.work_id
left join work as w on ps.work_id = w.work_id


--getting higest priced paintings
drop table if exists #paintings_prices_max
select 
	distinct subject, 
	name as most_expensive, 
	sale_price
into #paintings_prices_max
from #paintings_prices 
where ranking = 1
--getting lowest priced paintings
drop table if exists #paintings_prices_min	
SELECT 
    DISTINCT subject, 
    name as cheapest, 
    sale_price
INTO #paintings_prices_min
FROM #paintings_prices AS pp
WHERE EXISTS (
    SELECT 1
    FROM #paintings_prices AS ppi
    WHERE ppi.subject = pp.subject
    GROUP BY ppi.subject
    HAVING max(ppi.ranking) = pp.ranking
)
--creating summary table for subjects
drop table if exists subject_summary
select
	tsd.subject,
	art_pieces, 
	cheapest, lowest_sale,
	most_expensive, highest_sale,
	avg_sale,
	median_sale
into subject_summary
from #temp_subject_data as tsd
left join #paintings_prices_max as ppmax on ppmax.subject = tsd.subject
left join #paintings_prices_min as ppmin on ppmin.subject = tsd.subject

--artists count per subject plus best artists
--select * from subject_summary
--moving to work table
--i will create summary table with average sale_price per style, count of art piece, most profitable artists per style

--creating similar summary table for style

--select * from work where style is null or artist_id is null or work_id is null
--no nulls in currently important columns

--creating part of table with agg functions for styles in work table
drop table if exists #style_agg
select
style,
count(distinct artist_id) as artists,
count(distinct w.work_id) as art_pieces,
avg(sale_price) as avg_sale_price
into #style_agg
from work as w
left join product_size as ps on w.work_id = ps.work_id 
group by style

--creating median
DROP TABLE IF EXISTS #ordered_data_bis
    SELECT 
        case when style is null then 'Other' else style end as style,
        sale_price,
        ROW_NUMBER() OVER (PARTITION BY style ORDER BY sale_price) AS RowAsc,
        COUNT(*) OVER (PARTITION BY style) AS roww
	into #ordered_data_bis
    FROM product_size as ps
	left join work as w on ps.work_id = w.work_id;
--median calculation
drop table if exists #median_sale_price3
SELECT 
    style,
    AVG(sale_price * 1.0) AS median_sale
INTO #median_sale_price3
FROM #ordered_data_bis
WHERE RowAsc IN ((roww + 1) / 2, (roww + 2) / 2)
GROUP BY style;


drop table if exists #style_calc
select 
ag.*,
msp2.median_sale

from #median_sale_price3 as msp2
left join #style_agg as ag on ag.style = msp2.style

--most important artists per style

--APPROACH UNSUCCESSFUL
--drop table if exists #top_artists
--select
--	case when a.style is null then 'Other' else a.style end as style,
--	full_name,
--	ps.work_id,
--	ps.sale_price,
--	row_number() over(partition by ps.work_id order by sale_price desc) as ranking
--into #top_artists
--from product_size as ps
--left join work as w on ps.work_id = w.work_id
--left join artist as a on w.artist_id = a.artist_id

--drop table if exists #top_artists2
--select *
--into #top_artists2
--from #top_artists
--where ranking = 1 


--select * from #top_artists2
--drop table if exists #top_artists3
--select 
--*,
--sum(sale_price) over(partition by full_name) as rolling_sum
--into #top_artists3
--from #top_artists2

--drop table if exists #top_artists4
--select 
--	full_name,
--	style,
--	work_id,
--	sale_price,
--	rolling_sum,
--row_number() over(partition by style order by rolling_sum desc) as ranking
--into #top_artists4
--from #top_artists3
 

--drop table if exists #top_artists5
-- select 
--	*
--into #top_artists5
--from #top_artists4
--where ranking = 1

--select
--	sa.* ,
--	ta5.full_name,
--	ta5.rolling_sum as artist_paintings_sum
--from #style_agg as sa
--left join #top_artists5 as ta5 on ta5.style = sa.style

--proper approach
--creating needed data table
drop table if exists #top_artistsx1
select
full_name,
w.style, 
sp.work_id,
sale_price
into #top_artistsx1
from product_size as sp
left join work as w on w.work_id = sp.work_id
left join artist as a on w.artist_id = a.artist_id

--total sum by style and artist
drop table if exists #top_artistsx2
select
full_name,
style, 
work_id,
sale_price,
sum(sale_price) over(partition by style, full_name) as total_sum
into #top_artistsx2
from #top_artistsx1


drop table if exists #top_artistsx3
select *,
row_number() over(partition by style order by total_sum desc,sale_price desc) as ranking
into #top_artistsx3
from #top_artistsx2

drop table if exists #top_artistsx4
select full_name,style,total_sum,work_id
into #top_artistsx4
from #top_artistsx3
where ranking = 1

drop table if exists #style_agg2
select 
	sa.style, artists AS artists_count, art_pieces, avg_sale_price,
	full_name as top_artist, total_sum as top_artist_value
into #style_agg2
from #style_agg as sa
left join #top_artistsx4 as ta4 on sa.style = ta4.style
left join work as w on ta4.work_id = w.work_id

-- adding most expensive painting for every top_artist
DROP TABLE IF EXISTS #top_artists_paintings1
SELECT  
w.style, full_name, name, sale_price,
sum(sale_price) over(partition by w.style, full_name, name) 
/
count(name) over(partition by w.style, full_name, name) as painting_total_value

INTO #top_artists_paintings1
FROM product_size as ps 
left join work as w on ps.work_id = w.work_id
left join artist as a on w.artist_id = a.artist_id


--creating ranking by row number function
DROP TABLE IF EXISTS #top_artists_paintings2
SELECT 
	style,full_name,name, 
	row_number() over(partition by style,full_name order by painting_total_value desc) as ranking,
	painting_total_value
INTO #top_artists_paintings2
FROM #top_artists_paintings1


--filtering the results 
DROP TABLE IF EXISTS #top_artists_paintings3
SELECT
style,full_name,name, ranking,
painting_total_value
into #top_artists_paintings3
from #top_artists_paintings2
where ranking = 1

--complete summary table for style
DROP TABLE IF EXISTS style_summary
select 
sa2.* ,
name as most_expensive_example
into style_summary
from #style_agg2 as sa2
inner join #top_artists_paintings3 as tap3 on sa2.style = tap3.style and sa2.top_artist = tap3.full_name

--creating summary table for artists
--i will categorise them by nationality
-- i want to know average age, most popular style, number of artists, number of works, total worth of them artists with biggest value for total sales_price
drop table if exists #temp_artists
select
	a.nationality, a.full_name, a.style, a.birth, a.death,
	ps.work_id, ps.sale_price,
	w.artist_id, w.name,
	sum(ps.sale_price) over (partition by w.artist_id, name)
	/
	count(ps.sale_price) over(partition by w.artist_id, name) as avg_painting_value,
	death - birth as age
into #temp_artists
from product_size as ps 
left join work as w on w.work_id = ps.work_id
left join artist as a on a.artist_id = w.artist_id

--creating ranking by painting values per nationality
drop table if exists #temp_artists2
select
	distinct name,
	avg_painting_value,
	nationality,
	full_name,
	age,
	style,
	row_number() over(partition by nationality order by avg_painting_value desc) as ranking
into #temp_artists2
from #temp_artists

drop table if exists #temp_artists3
select 
nationality,
sum(avg_painting_value) as total_value,
avg(age) as avg_age,
count(name) as art_pieces

into #temp_artists3
from #temp_artists2
group by nationality

--creating final artists summary table
drop table if exists artists_summary
select
ta3.*, 
ta3.total_value/ta3.art_pieces as value_per_piece,
ta2.full_name as best_artists
into artists_summary
from #temp_artists3 as ta3
left join #temp_artists2 as ta2 on ta2.nationality = ta3.nationality
where ta2.ranking = 1
order by total_value desc, art_pieces desc





--final results
select * from style_summary
select * from subject_summary
select * from artists_summary

