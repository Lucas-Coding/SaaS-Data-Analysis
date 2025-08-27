-- View first 10 rows
SELECT * FROM saas_cleaned_sql LIMIT 10;

-- Count total number of orders
SELECT COUNT(*) AS total_orders FROM saas_cleaned_sql;

-- Calculate the total sales
SELECT ROUND(SUM(sales), 2) AS total_sales FROM saas_cleaned_sql;

-- Average profit across all orders
SELECT ROUND(AVG(profit), 2) AS average_profit FROM saas_cleaned_sql;

-- Total sales by country
SELECT country, ROUND(SUM(sales), 2) AS total_sales_by_country FROM saas_cleaned_sql GROUP BY country;

-- average profit margin by productdescending
SELECT product, ROUND(AVG(profit_margin), 2) AS avg_profit_margin FROM saas_cleaned_sql GROUP BY product ORDER BY avg_profit_margin DESC;

-- Customers with more than 5 orders
SELECT customer, COUNT(*) AS order_count FROM saas_cleaned_sql GROUP BY customer HAVING order_count > 5 order by order_count DESC;

-- Monthly sales trend
SELECT purchase_month, ROUND(SUM(sales), 2) AS monthly_sales FROM saas_cleaned_sql GROUP BY purchase_month ORDER BY purchase_month;

-- Top 5 industries by average discount
SELECT industry, ROUND(AVG(discount), 2) AS avg_discount FROM saas_cleaned_sql GROUP BY industry ORDER BY avg_discount DESC LIMIT 10;

-- Total quantity sold by country and product
SELECT country, product, ROUND(SUM(quantity), 2) AS total_quantity FROM saas_cleaned_sql GROUP BY country, product ORDER BY total_quantity DESC;

-- Average revenue per unit by discount category where > 100
SELECT discount_category, ROUND(AVG(rev_per_unit), 2) AS avg_rev_per_unit FROM saas_cleaned_sql GROUP BY discount_category HAVING ROUND(AVG(rev_per_unit), 2) > 100;


-- More Indepth Queries


-- Rank products by total sales using rank
SELECT 
    product, 
    ROUND(SUM(sales), 2) AS total_sales, 
    RANK() OVER (ORDER BY ROUND(SUM(sales), 2) DESC) AS sales_rank 
FROM saas_cleaned_sql 
GROUP BY product;


-- Compare the monthly profits 
-- and the previous month's profits with the percentage change
WITH MonthlyProfit AS (
    SELECT 
        purchase_month, 
        ROUND(SUM(profit), 2) AS total_profit, 
        LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month) AS previous_month_profit,
        ROUND(
            ((ROUND(SUM(profit), 2) - LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month)) 
             / NULLIF(LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month), 0) * 100), 2
        ) AS profit_percentage_change
    FROM saas_cleaned_sql 
    GROUP BY purchase_month 
    ORDER BY purchase_month
)

-- query results
SELECT * FROM MonthlyProfit;

WITH MonthlyProfit1 AS (
    SELECT 
        purchase_month, 
        ROUND(SUM(profit), 2) AS total_profit, 
        LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month) AS previous_month_profit,
        ROUND(
            ((ROUND(SUM(profit), 2) - LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month)) 
             / NULLIF(LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY purchase_month), 0) * 100), 2
        ) AS profit_percentage_change
    FROM saas_cleaned_sql 
    GROUP BY purchase_month
)

-- Get the average profit per month(doesn't take into account years)
SELECT 
    CAST(SUBSTRING_INDEX(m.purchase_month, '-', -1) AS UNSIGNED) AS month_number, -- Extract last part (month) and convert to integer
    ROUND(AVG(m.total_profit), 2) AS avg_profit_by_month
FROM MonthlyProfit1 m
GROUP BY CAST(SUBSTRING_INDEX(m.purchase_month, '-', -1) AS UNSIGNED)
ORDER BY month_number;


-- Average of sales by segment
SELECT 
    segment, 
    ROUND(AVG(sales), 2) AS avg_sales
FROM saas_cleaned_sql 
GROUP BY segment 
ORDER BY avg_sales DESC;

-- Positive vs negative profit by country
SELECT 
    country, 
    ROUND(SUM(CASE WHEN profit > 0 THEN profit ELSE 0 END), 2) AS positive_profit, 
    ROUND(SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END), 2) AS negative_profit 
FROM saas_cleaned_sql 
GROUP BY country 
ORDER BY positive_profit DESC;


-- Get country has never had a sale where the company has lost profit.
with Profit_Index as (
SELECT 
    country, 
    ROUND(SUM(CASE WHEN profit > 0 THEN profit ELSE 0 END), 2) AS positive_profit, 
    ROUND(SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END), 2) AS negative_profit 
FROM saas_cleaned_sql 
GROUP BY country 
ORDER BY positive_profit DESC)

SELECT country, positive_profit
FROM Profit_Index
WHERE negative_profit  = 0
order by positive_profit DESC;


-- The count of different discount categories and 
-- the number of times they have been given to different countries
SELECT country,
    SUM(CASE WHEN discount BETWEEN 0.0 AND 0.0 THEN 1 ELSE 0 END) AS no_discount_count,
    SUM(CASE WHEN discount BETWEEN 0.00001 AND 0.2 THEN 1 ELSE 0 END) AS low_discount_count,
    SUM(CASE WHEN discount BETWEEN 0.2 AND 0.3 THEN 1 ELSE 0 END) AS moderately_low_discount_count,
    SUM(CASE WHEN discount BETWEEN 0.4 AND 0.5 THEN 1 ELSE 0 END) AS moderately_high_discount_count,
    SUM(CASE WHEN discount BETWEEN 0.6 AND 0.7 THEN 1 ELSE 0 END) AS very_high_discount_count
FROM saas_cleaned_sql
group by country
order by country ASC;



-- The average sales, profit, discount and profit margin per product
SELECT product, ROUND(AVG(sales), 2) AS average_sales , ROUND(AVG(profit), 2) AS average_profit, ROUND(AVG(discount), 2) AS average_discount, ROUND(AVG(profit_margin), 2) AS average_profit_margin
FROM saas_cleaned_sql
GROUP BY product;


-- The difference in sales between each year from 2020 to 2023
SELECT 
    EXTRACT(YEAR FROM order_date) AS year, 
    COUNT(*),
    ROUND(SUM(sales), 2) AS total_sales, 
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(((ROUND(SUM(sales), 2) - LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date))) * 100.0 / NULLIF(LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date)), 0)), 2) AS sales_pct_diff,
    ROUND(((ROUND(SUM(profit), 2) - LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date))) * 100.0 / NULLIF(LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date)), 0)), 2) AS profit_pct_diff
FROM saas_cleaned_sql
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;


-- The difference in sales and profit between the first year and
-- the last year, as well as the percentage difference.
SELECT 
    EXTRACT(YEAR FROM order_date) AS year, 
    COUNT(*),
    ROUND(SUM(sales), 2) AS total_sales, 
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(((ROUND(SUM(sales), 2) - LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date))) * 100.0 / NULLIF(LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date)), 0)), 2) AS sales_pct_diff,
    ROUND(((ROUND(SUM(profit), 2) - LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date))) * 100.0 / NULLIF(LAG(ROUND(SUM(profit), 2)) OVER (ORDER BY EXTRACT(YEAR FROM order_date)), 0)), 2) AS profit_pct_diff
FROM saas_cleaned_sql
GROUP BY EXTRACT(YEAR FROM order_date)
having year = 2020 or year = 2023
ORDER BY year;

--  The total number of orders from each industry
SELECT industry, COUNT(*)
from saas_cleaned_sql
GROUP BY industry;

