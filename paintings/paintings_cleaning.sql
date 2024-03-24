USE portfolio_paintings;

--First i am going to clean and adjust data

--checking data types of columns and adjusting
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'subject'
--work_id should be integer
ALTER TABLE subject
ALTER COLUMN work_id int
select top 10 * from subject--just to check data
select work_id from subject where work_id is null or subject is null --no null values
select subject, count(*) from subject group by subject --subjects seem ok
--data is correct

--doing the same process for other tables
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'product_size'

--altering tables by chaning types and droping unwanted
ALTER TABLE product_size
ALTER COLUMN work_id INT
ALTER TABLE product_size
DROP COLUMN IF EXISTS size_id
ALTER TABLE product_size
ALTER COLUMN sale_price INT
ALTER TABLE product_size
ALTER COLUMN regular_price INT

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'product_size';


SELECT * FROM museum_hours --open and close are researved for mssql, changing names
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'museum_hours'
EXEC sp_rename 'museum_hours.[open]', 'open_time', 'COLUMN'
EXEC sp_rename 'museum_hours.[close]', 'close_time', 'COLUMN'



ALTER TABLE museum_hours
ALTER COLUMN museum_id INT --altering table to change data type to int
select distinct open_time from museum_hours -- strings look ok 
select distinct close_time from museum_hours --strings look ok no nulls no unexpected values

SELECT open_time
FROM museum_hours
WHERE TRY_CONVERT(TIME, open_time) IS NULL 
AND open_time IS NOT NULL
--data can not be converted propperly

--adding new column for open time and close time as backup
alter table museum_hours
add open_time_new time,
close_time_new time

update museum_hours --filling in new columns with substringed data ready to convert
set open_time_new = substring(open_time, 1,5),
	close_time_new = substring(close_time, 1,5)

update museum_hours --updating open and close time columnsto propper time values
set open_time = convert(time, open_time_new),
	close_time = convert(time, close_time_new)
select * from museum_hours
--chaning close_time to 24hours system, open_time doesnt require it
update museum_hours
set close_time = DATEADD(HOUR, 12, close_time)

--converting data type to time
alter table museum_hours
alter column open_time time
alter table museum_hours
alter column close_time time
--droping unwanted columns
alter table museum_hours
drop column if exists close_time_new
alter table museum_hours
drop column if exists open_time_new

--checking if everything is alright
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'museum_hours'
select * from museum_hours;


--cleaning transfering of museum table
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'museum'
select * from museum

alter table museum
drop column state,postal,phone,url --data in these column is of no use and full of errors

alter table museum
add address_new varchar(255), new_city varchar(255),country_new varchar(255) --data backup

update museum --correcting adress column with case when manually
set address_new = 
	CASE 
		WHEN address LIKE '%"Av. Paulista%' THEN address + ' 1578 - Bela Vista"'
		WHEN address LIKE '%Palace Square%' THEN address + ' ' + city
		WHEN address LIKE '%"C. de Ruiz de Alarcón%' THEN address + '' + city
		WHEN address LIKE '%Houston"%' THEN city
		WHEN address LIKE '%"P.º del Prado%' THEN address + '' + city
		WHEN address LIKE '%"Piazzale degli Uffizi%' THEN address + '' + city 
		ELSE address
		END
select * from museum --data seems ok

update museum --same for city column
set new_city = 
	CASE 
		WHEN city LIKE '% 6"%' THEN 'Florence'
		WHEN city LIKE '% 1578 - Bela Vista"%' THEN 'Brazil'
		WHEN city LIKE '%2%' THEN 'Petersburg'
		WHEN city LIKE '%45128%' THEN 'Essen'
		WHEN city LIKE '%38000%' THEN 'Grenoble'
		WHEN city LIKE '%29000%' THEN 'Quimper'
		WHEN city LIKE '%23"%' THEN 'Madrid'
		WHEN city LIKE '%1001 Bissonnet St%' THEN 'Houston'
		WHEN city LIKE '%6"%' THEN 'Italy'
		WHEN city LIKE '%6731 AW Otterlo%' THEN 'Otterlo'
		WHEN city LIKE '%75001%' THEN 'Paris'
		WHEN city LIKE '% 8"%' THEN 'Madrid'
		ELSE city
		END
select * from museum

update museum --same for country column
set country_new = 
	CASE 
		WHEN country LIKE '%01310-200%' THEN 'Brazil'
		WHEN country LIKE '77005' THEN 'USA'
		WHEN country LIKE '%28014%' THEN 'Spain'
		WHEN country LIKE '%50122%' THEN 'Italy'
		ELSE country
		END
select * from museum

--updating columns to contain proper data
update museum
set
	address = address_new,
	city = new_city,
	country = country_new

--deleting unnecessary columns
alter table museum
drop column if exists country_new
alter table museum
drop column if exists address_new
alter table museum
drop column if exists new_city;


--doing the same to canvas_size table
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'canvas_size'
select * from canvas_size
-- I will use label column to recreate width and height columns but with cm instead of inches
--there are some null values in height column i am assuming that in these scenrios width = height

--it's not null so it has to have spaces in it
update canvas_size
set 
	height = REPLACE(height, ' ','')

--case when to set height equal to width when height is not given
update canvas_size
set 
	height = case 
	when height like '' then width
	else height end
select * from canvas_size

--altering to propper data types
alter table canvas_size
alter column size_id int
alter table canvas_size
alter column width int
alter table canvas_size
alter column height int

--using cm values instead of inches
update canvas_size
set
	width = round(width * 2.54,0),
	height = round(height * 2.54,0)
	select * from canvas_size;

--doing the same for artist table
select * from artist
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'artist'
--artist_id,death and birth should be int
-- i will create additional column with full name of artists

--chaning data types
alter table artist
alter column artist_id int
alter table artist
alter column birth int
alter table artist
alter column death int
--adding new column for full names
alter table artist
add full_name varchar(128)
--filling in full name column
update artist
set
	full_name = case
	when middle_names not like ' %' then replace(first_name,' ','') + ' ' + middle_names + ' ' + replace(last_name, ' ','')
	else replace(first_name,' ','') + ' ' + replace(last_name, ' ','') end

select * from artist
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'artist';


select * from workww$
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'workww$'
--changing name of workww$ column to work
sp_rename 'workww$', 'work', 'OBJECT'

--i will change null values in style column so it says 'Other'
update work
	set style = case
	when style is null then 'Other'
	else style end

select * from work
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'work'
--data seems ok

--all tables have been properly handled cleaned and updated
--going to analysis part
