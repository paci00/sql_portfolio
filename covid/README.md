##1.Data
The data analyzed comes from the coronavirus case and death data repository of the US nytimes website: https://github.com/nytimes/covid-19-data/tree/master

At the link you will find the terminology, definition and description of the statistics collected

##2. Analysis
The project is completely proprietary and made with SQL query language using relational database management system developed by Microsoft called MSSQL. In total, the code consists of 154 lines

The project consists of the following key words and functions of SQL:

USE - selects the database you want to use

DROP TABLE - removes a table from the database

WITH - defines a common expression to use in a query

SELECT - returns data from a database or table

LAG - returns the value from the previous row in the specified partition or queries

OVER - defines the analysis window in which the function is to be executed

PARTITION BY - divides the results of a query into partitions according to a specified column or expression

ORDER BY - sorts the query results by the specified column or expression

CASE - returns different results depending on logical conditions

WHEN - specifies the condition to be checked in the CASE statement

THEN - specifies the value to return when the condition is met in the CASE statement

END - ends the CASE instruction

INTO - copies data from one table to another or creates a new table with the results of the query

WHERE - filters the query results according to a specified condition

LIKE - compares values using wildcards

YEAR - returns the year from the date

COUNT - returns the number of rows that meet the specified criterion

AVG - returns the average value from a set of values

RANK - returns the ranking of values in a specified partition or query

SUM - returns the sum of the values from the value set

EXISTS - checks if the subquery returns any results

HAVING - filters the results of queries grouped by a specific condition

