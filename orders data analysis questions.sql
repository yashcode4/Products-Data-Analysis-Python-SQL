-- Pandas will load the data in postgresql server using highest memory available. Hence, creating table manually and append the data into table.
CREATE TABLE df_orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(50),
    quantity INT,
    discount DECIMAL(7,2),
    sale_price DECIMAL(7,2),
    profit DECIMAL(7,2)
);

-- Viewing the Data
select * from df_orders;

-- Exploratory Data Analysis
-- Q1. Find top 10 highest revenue generating products.
select 
	product_id, 
	sum(quantity*sale_price) as sales
from df_orders
group by 
	product_id
order by 
	sales desc
limit 10;

-- Q2. Find top 5 higest selling products in each region.
with cte as (
select 
	region, 
	product_id, 
	sum(quantity*sale_price) as sales
from df_orders
group by 
	region, 
	product_id)
select * 
from (select *
, row_number() over(partition by region order by sales desc) as rn
from cte) A
where rn<=5;

-- Q3. Find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023.
with cte as (
select 
	extract (year from order_date) as order_year,
	extract (month from order_date) as order_month, 
	sum(quantity*sale_price) as sales
FROM df_orders
group by 
	extract (year from order_date),
	extract (month from order_date)
)
select order_month,
sum(case when order_year = 2022 then sales else 0 end) as sales_2022,
sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from cte
group by 
	order_month
order by 
	order_month;

-- Q4. For each category which month had highest sales
with cte as (
select 
	category,
	to_char(order_date, 'YYYYMM') as order_year_month, 
	sum(quantity*sale_price) as sales
from df_orders
group by
	category,
	to_char(order_date, 'YYYYMM')
)
select * from (
select *,
	row_number() over (partition by category order by sales desc) as rn
from cte
) a
where rn = 1;

-- Q5. Which sub category had highest growth by profit in 2023 compare to 2022.
with cte as (
select 
	sub_category,
	extract (year from order_date) as order_year,
	sum(quantity*sale_price) as sales
FROM df_orders
group by 
	sub_category,
	extract (year from order_date)
),
cte2 as (
select sub_category,
sum(case when order_year = 2022 then sales else 0 end) as sales_2022,
sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from cte
group by sub_category
)
select *,
(sales_2023-sales_2022)*100/sales_2022 as growth_percentage
from cte2 
order by (sales_2023-sales_2022)*100/sales_2022 desc
limit 1;

	