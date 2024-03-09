USE portfolio_walmart
--this query clears and adjust main table and is meant to be used one time only before analysis part

--changing name of the table
EXEC sp_rename 'walmart$', 'walmart';

--chaning names of columns
EXEC sp_rename 'walmart.[Order ID]', 'order_id', 'COLUMN';
EXEC sp_rename 'walmart.[Order Date]', 'order_date', 'COLUMN';
EXEC sp_rename 'walmart.[Ship Date]', 'ship_date', 'COLUMN';
EXEC sp_rename 'walmart.[EmailID]', 'email_id', 'COLUMN';
EXEC sp_rename 'walmart.[Geography]', 'geography', 'COLUMN';
EXEC sp_rename 'walmart.[Category]', 'category', 'COLUMN';
EXEC sp_rename 'walmart.[Product Name]', 'product_name', 'COLUMN';
EXEC sp_rename 'walmart.[Sales]', 'sales', 'COLUMN';
EXEC sp_rename 'walmart.[Quantity]', 'quantity', 'COLUMN';
EXEC sp_rename 'walmart.[Profit]', 'profit', 'COLUMN';

--creating new columns based on values from geography column
ALTER TABLE walmart
ADD
	country VARCHAR(50),
	region_state VARCHAR(50),
	city VARCHAR(50);

UPDATE walmart
SET
region_state = PARSENAME(REPLACE(geography, ',', '.'), 1),
country = PARSENAME(REPLACE(geography, ',', '.'), 3),
city = PARSENAME(REPLACE(geography, ',', '.'), 2);

SELECT * FROM walmart