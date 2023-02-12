-- Codebasics SQL Challenge
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- Request 1: Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
-- 

SELECT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' and region = 'APAC';

-- 
-- Request 2: What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields:
-- unique_products_2020 unique_products_2021 percentage_chg
-- 
with ct1 as (
			select count(distinct product_code) as unique_products_2020
			from fact_sales_monthly
			where fiscal_year = 2020),
	 ct2 as (
			select count(distinct product_code) as unique_products_2021
			from fact_sales_monthly
			where fiscal_year = 2021)
select unique_products_2020, unique_products_2021, (unique_products_2021-unique_products_2020)/unique_products_2020*100 as percentage_chg
from ct1 cross join ct2;

-- 
-- Request 3: Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields: segment, product_count


SELECT SEGMENT, COUNT(DISTINCT product_code) AS PRODUCT_COUNT
FROM dim_product
GROUP BY segment
ORDER BY PRODUCT_COUNT DESC;

-- 
-- Request 4: Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, segment product_count_2020 product_count_2021 difference

with ct1 as (
			select p.segment, count(distinct(p.product_code)) as product_count_2020
			from dim_product p 
			join fact_sales_monthly s on p.product_code = s.product_code
			where s.fiscal_year = 2020
			group by p.segment
            ),
	ct2 as (
			select p.segment, count(distinct(p.product_code)) as product_count_2021
			from dim_product p 
			join fact_sales_monthly s on p.product_code = s.product_code
			where s.fiscal_year = 2021
			group by p.segment
            )
select ct1.segment, product_count_2020, product_count_2021,  product_count_2021-product_count_2020 as difference
from ct1 inner join ct2 on ct1.segment = ct2.segment
order by difference desc;

-- 
-- Request 5: Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, product_code product manufacturing_cost

select product_code, product, manufacturing_cost
from (
	select fm.product_code, dp.product, fm.manufacturing_cost
	from fact_manufacturing_cost fm
	join dim_product dp
	on fm.product_code = dp.product_code
    ) tb1
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
union all
select product_code, product, manufacturing_cost
from (
	select fm.product_code, dp.product, fm.manufacturing_cost
	from fact_manufacturing_cost fm
	join dim_product dp
	on fm.product_code = dp.product_code
    ) tb2
where manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);

-- Request 6: Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
-- for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields, customer_code customer average_discount_percentage

select c.customer_code, c.customer, d.pre_invoice_discount_pct as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions d on c.customer_code = d.customer_code
where c.market = 'India' and d.fiscal_year = 2021 and d.pre_invoice_discount_pct > (select round(avg(pre_invoice_discount_pct), 4) as avg_dis_pct
									from fact_pre_invoice_deductions)
order by average_discount_percentage desc limit 5;

-- Request 7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: Month Year Gross sales Amount

select month(s.date) as month_, year(s.date) as year_, s.sold_quantity * p.gross_price as gross_sales_amount
from dim_customer c
join fact_sales_monthly s on c.customer_code = s.customer_code
join fact_gross_price p on s.product_code = p.product_code
where c.customer = 'Atliq Exclusive'
group by month_, year_;

-- Request 8: In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, 
-- Quarter, total_sold_quantity

select quarter(date) as Quarter_, sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter_
order by total_sold_quantity desc;
 
-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, channel gross_sales_mln percentage

with ct1 as(
			select c.channel, p.gross_price * s.sold_quantity as gross_sales_ml
			from fact_gross_price p
			join fact_sales_monthly s on p.product_code = s.product_code
			join dim_customer c on c.customer_code = s.customer_code
			where s.fiscal_year = 2021
			group by c.channel
			),
	 ct2 as(
			select sum(gross_sales_ml) as sum_gross_sales_ml from ct1
			)
select ct1.channel, ct1.gross_sales_ml, round(ct1.gross_sales_ml/ct2.sum_gross_sales_ml * 100, 2) as percentage
from ct1 cross join ct2;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields:
-- division, product_code, product, total_sold_quantity, rank_order

with ct1 as (
			select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
			from fact_sales_monthly s
			join dim_product p on s.product_code = p.product_code
			group by p.division, p.product_code, p.product
            ),
	 ct2 as (
			select division, product_code, product, total_sold_quantity, 
				   rank() over (partition by division order by total_sold_quantity desc) as rank_order
			from ct1
            )
select division, product_code, product, total_sold_quantity, rank_order
from ct2
where rank_order <= 3;