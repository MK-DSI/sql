--Homework 4: Advanced SQL
--    Due on Thursday, September 19 at 11:59pm
--    Weight: 8% of total grade
--    Upload one .sql file with your queries
--COALESCE
--Our favourite manager wants a detailed long list of products, 
--but is afraid of tables! We tell them, no problem! 
--We can produce a list with all of the appropriate details.
--Using the following syntax you create our super cool and
--not at all needy manager a list:
--SELECT 
--product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
--FROM product
/* But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first problem, 
and 'unit' for the second problem.
HINT: keep the syntax the same, but edited the correct components with the string. 
The || values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- 
and the NULL rows will be fixed. 
All the other rows will remain the same.*/

SELECT
COALESCE(product_name, '') || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product

--OR if all product names are persent:

SELECT
product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product

/*Windowed Functions
Write a query that selects from the customer_purchases table and numbers 
each customer’s visits to the farmer’s market 
(labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc.
You can either display all rows in the customer_purchases table,
with the counter changing on each new market date for each customer, 
or select only the unique market dates per customer (without purchase details) 
and number those visits. HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK().
Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1,
then write another query that uses this one as a subquery (or temp table)
and filters the results to only the customer’s most recent visit.
Using a COUNT() window function, include a value along with each 
row of the customer_purchases table that indicates how many 
different times that customer has purchased that product_id.*/

--Numbering the rows

--using ROW-NUMBER 
SELECT 
customer_id, market_date, 
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date;

--using DENSE_RANK
SELECT 
customer_id, market_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date;

--reverse order

--The program above does individual raw sorting, and raw numbers does correspond with the time of the purchase, 
--but the visit_N column is not sorted in DESC order, for example, customer 1, transactions 1-6, this needs to be re-ordered. 

SELECT
customer_id, market_date, transaction_time,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time;

--The program sorts every day as 1 row or one visit_N number and transactions at different times are still numbered as one instance/1 raw, interesting.  

SELECT
customer_id, market_date, transaction_time,
-DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time;

--using row_number, descending rows, reversed numbers
WITH visit_n2 AS(
SELECT
customer_id, market_date, transaction_time,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time)
SELECT * FROM visit_n2 ORDER BY customer_id, market_date, transaction_time DESC;

--comparing to using dense_rank, descending rows, reversed numbers
WITH visit_n2 AS(
SELECT
customer_id, market_date, transaction_time,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time)
SELECT * FROM visit_n2 ORDER BY customer_id, market_date, transaction_time DESC;

--filtering by 1st visit (comparing dense_rank) -multiple purchases at different transaction time are under the same row number
WITH visit_n2 AS(
SELECT
customer_id, market_date, transaction_time,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time)
SELECT * FROM visit_n2 WHERE visit_N = 1 ORDER BY customer_id, market_date, transaction_time DESC;

--filtering by 1st visit (comparing raw_number) - only first transaction by time is selected in one row
WITH visit_n2 AS(
SELECT
customer_id, market_date, transaction_time,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) 
AS visit_N
FROM customer_purchases 
ORDER BY customer_id, market_date, transaction_time)
SELECT * FROM visit_n2 WHERE visit_N = 1 ORDER BY customer_id, market_date, transaction_time DESC;

--counting purchases of products per customer 
SELECT
customer_id, market_date, product_id,
COUNT (product_id) OVER (PARTITION BY customer_id, market_date) as product_purchase_count
FROM customer_purchases ORDER BY customer_id


-- This quary is more organized by customer_id, and market_date, and product_purchase_count.
SELECT
customer_id, market_date, product_id,
COUNT (product_id) OVER (PARTITION BY customer_id, market_date) as product_purchase_count
FROM customer_purchases ORDER BY product_id, customer_id, product_purchase_count


/*String manipulations

    Some product names in the product table have descriptions like "Jar" or "Organic". 
	These are separated from the product name with a hyphen. 
	Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
	Remove any trailing or leading whitespaces. Don't just use a case statement for each product!

product_name 	description
Habanero Peppers - Organic 	Organic
HINT: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column.
*/

SELECT product_name,
CASE 
WHEN 
INSTR(product_name, '-') >0 THEN
LTRIM(SUBSTR(product_name, INSTR(product_name, '-')+1))
ELSE 
NULL
END AS description
FROM product;


/*
UNION
Using a UNION, write a query that displays the market dates with the highest and lowest total sales.
HINT: There are a possibly a few ways to do this query, but if you're struggling, 
try the following: 1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query
 to create "best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, with a UNION binding them.
*/

WITH total_sales /*Creating my temp table*/ AS
(SELECT market_date, SUM(quantity * cost_to_customer_per_qty) AS total_sales
FROM customer_purchases 
GROUP BY market_date),

-- Ascended and descended orders to find best and worst days	
ranked_sales AS (
SELECT  market_date, total_sales,
RANK() OVER (ORDER BY total_sales DESC) AS sales_rank_desc,
RANK() OVER (ORDER BY total_sales ASC) AS sales_rank_asc
FROM total_sales)

--Union combo
SELECT  market_date, total_sales
FROM  ranked_sales
WHERE  sales_rank_desc = 1  
UNION
SELECT  market_date, total_sales
FROM  ranked_sales
WHERE  sales_rank_asc = 1;  
 
 