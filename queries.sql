-- Duka Smart Electronics: answers to the 46 retail analytics questions.
-- Run this file while connected to retail_analytics, after loading data/02-04.
-- Business rules: order counts include every status; monetary measures use Completed
-- orders only; discount is a percentage; monthly periods use date_trunc('month', ...).

-- Section A — SQL fundamentals

-- Q1: Retrieve all customer records.
select * from retail.customers;

-- Q2: Display customer names, cities, and segments.
select customer_name, city, customer_segment from retail.customers order by customer_name;

-- Q3: Find customers living in Nairobi.
select * from retail.customers where city = 'Nairobi' order by customer_name;

-- Q4: Find customers registered after January 1, 2025.
select * from retail.customers where registration_date > date '2025-01-01' order by registration_date;

-- Q5: Display all unique customer cities.
select distinct city from retail.customers order by city;

-- Q6: Retrieve the 10 most recent orders (order_id breaks date ties deterministically).
select * from retail.orders order by order_date desc, order_id desc limit 10;

-- Q7: Find orders with unit prices above KSh 10,000.
select * from retail.orders where unit_price > 10000 order by unit_price desc;

-- Q8: Find customers whose names start with A.
select * from retail.customers where customer_name ILIKE 'A%' order by customer_name;

-- Q9: Retrieve orders with quantities between 2 and 5, inclusive.
select * from retail.orders where quantity between 2 and 5 order by quantity, order_id;

-- Q10: Find orders paid through M-Pesa.
select * from retail.orders where payment_method = 'M-Pesa' order by order_date, order_id;

-- Section B — Aggregation and grouping

-- Q11: count all customers.
select count(*) as customer_count from retail.customers;

-- Q12: count all orders, regardless of status.
select count(*) as order_count from retail.orders;

-- Q13: Calculate completed-order revenue.
select round(coalesce(sum(quantity * unit_price * (1 - discount / 100.0)), 0), 2) as completed_revenue_ksh
from retail.orders where order_status = 'Completed';

-- Q14: Calculate the average completed-order value (one row in orders = one order).
select round(avg(quantity * unit_price * (1 - discount / 100.0)), 2) as average_completed_order_value_ksh
from retail.orders where order_status = 'Completed';

-- Q15: Find the highest and lowest listed unit prices.
select max(unit_price) as highest_unit_price_ksh, min(unit_price) as lowest_unit_price_ksh from retail.orders;

-- Q16: Calculate completed-order revenue by product category.
select product_category,
       round(sum(quantity * unit_price * (1 - discount / 100.0)), 2) as revenue_ksh
from retail.orders where order_status = 'Completed'
group by product_category order by revenue_ksh desc;

-- Q17: count distinct customers by city.
select city, count(distinct customer_id) as customer_count
from retail.customers group by city order by customer_count desc, city;

-- Q18: Calculate completed quantity sold by product.
select product_name, sum(quantity) as units_sold
from retail.orders where order_status = 'Completed'
group by product_name order by units_sold desc, product_name;

-- Q19: Find categories generating more than KSh 100,000 in completed revenue.
select product_category,
       round(sum(quantity * unit_price * (1 - discount / 100.0)), 2) as revenue_ksh
from retail.orders where order_status = 'Completed'
group by product_category
having sum(quantity * unit_price * (1 - discount / 100.0)) > 100000
order by revenue_ksh desc;

-- Q20: Calculate the percentage of cancelled orders among all orders.
select round(100.0 * count(*) filter (where order_status = 'Cancelled') / nullif(count(*), 0), 2)
       as cancelled_order_percentage
from retail.orders;

-- Section C — Joins and customer analytics

-- Q21: Display orders with customer names and cities.
select o.*, c.customer_name, c.city
from retail.orders o join retail.customers c using (customer_id)
order by o.order_date, o.order_id;

-- Q22: Calculate completed-order spending by customer, including customers with zero spend.
select c.customer_id, c.customer_name,
       round(coalesce(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0))
           filter (where o.order_status = 'Completed'), 0), 2) as spending_ksh
from retail.customers c left join retail.orders o using (customer_id)
group by c.customer_id, c.customer_name order by spending_ksh desc, c.customer_id;

-- Q23: Identify customers who have never ordered.
select c.customer_id, c.customer_name, c.city
from retail.customers c left join retail.orders o using (customer_id)
where o.order_id is null order by c.customer_id;

-- Q24: Find the 10 highest-spending customers (Completed orders only).
select c.customer_id, c.customer_name,
       round(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) as spending_ksh
from retail.customers c join retail.orders o using (customer_id)
where o.order_status = 'Completed'
group by c.customer_id, c.customer_name
order by spending_ksh desc, c.customer_id limit 10;

-- Q25: Calculate completed-order revenue by customer city.
select c.city, round(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) as revenue_ksh
from retail.customers c join retail.orders o using (customer_id)
where o.order_status = 'Completed'
group by c.city order by revenue_ksh desc;

-- Q26: Identify customers with more than five orders (all statuses count).
select c.customer_id, c.customer_name, count(o.order_id) as order_count
from retail.customers c join retail.orders o using (customer_id)
group by c.customer_id, c.customer_name
having count(o.order_id) > 5 order by order_count desc, c.customer_id;

-- Q27: Average customer spending by segment. Each customer's completed revenue is
-- calculated first; then the mean includes all customers in the segment (zero spend included).
with customer_spending as (
    select c.customer_id, c.customer_segment,
           coalesce(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0))
             filter (where o.order_status = 'Completed'), 0) as spending
    from retail.customers c left join retail.orders o using (customer_id)
    group by c.customer_id, c.customer_segment
)
select customer_segment, round(avg(spending), 2) as average_customer_spending_ksh
from customer_spending group by customer_segment order by average_customer_spending_ksh desc;

-- Q28: Most popular category among VIP customers, measured by completed units sold.
with category_units as (
    select o.product_category, sum(o.quantity) as units_sold
    from retail.customers c join retail.orders o using (customer_id)
    where c.customer_segment = 'VIP' and o.order_status = 'Completed'
    group by o.product_category
), ranked as (
    select *, rank() over (order by units_sold desc) as popularity_rank from category_units
)
select product_category, units_sold, popularity_rank
from ranked where popularity_rank = 1 order by product_category;

-- Section D — Subqueries and CTEs

-- Q29: Customers spending above the average total spending per purchasing customer.
with customer_spending as (
    select customer_id, sum(quantity * unit_price * (1 - discount / 100.0)) as spending
    from retail.orders where order_status = 'Completed' group by customer_id
)
select c.customer_id, c.customer_name, round(cs.spending, 2) as spending_ksh
from customer_spending cs join retail.customers c using (customer_id)
where cs.spending > (select avg(spending) from customer_spending)
order by cs.spending desc;

-- Q30: Products whose average listed unit price is above the overall average unit price.
select product_name, round(avg(unit_price), 2) as average_unit_price_ksh
from retail.orders group by product_name
having avg(unit_price) > (select avg(unit_price) from retail.orders)
order by average_unit_price_ksh desc, product_name;

-- Q31: Three highest-revenue months (completed orders only).
with monthly_revenue as (
    select date_trunc('month', order_date)::date as sales_month,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed'
    group by date_trunc('month', order_date)
)
select sales_month, round(revenue, 2) as revenue_ksh
from monthly_revenue order by revenue desc, sales_month limit 3;

-- Q32: Customers purchasing from at least three distinct categories (Completed orders).
select c.customer_id, c.customer_name, count(distinct o.product_category) as category_count
from retail.customers c join retail.orders o using (customer_id)
where o.order_status = 'Completed'
group by c.customer_id, c.customer_name
having count(distinct o.product_category) >= 3
order by category_count desc, c.customer_id;

-- Q33: Category revenue, cost, profit and profit margin (Completed orders only).
with category_totals as (
    select product_category,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue,
           sum(quantity * cost_price) as cost
    from retail.orders where order_status = 'Completed' group by product_category
)
select product_category, round(revenue, 2) as revenue_ksh, round(cost, 2) as cost_ksh,
       round(revenue - cost, 2) as profit_ksh,
       round(100.0 * (revenue - cost) / nullif(revenue, 0), 2) as profit_margin_pct
from category_totals order by profit_ksh desc;

-- Q34: Customers whose latest completed order was over 90 days before the dataset's latest date.
with latest_data_date as (select max(order_date) as as_of_date from retail.orders),
customer_last_order as (
    select customer_id, max(order_date) as last_completed_order
    from retail.orders where order_status = 'Completed' group by customer_id
)
select c.customer_id, c.customer_name, clo.last_completed_order, ld.as_of_date,
       (ld.as_of_date - clo.last_completed_order) as days_since_last_completed_order
from customer_last_order clo join retail.customers c using (customer_id)
cross join latest_data_date ld
where ld.as_of_date - clo.last_completed_order > 90
order by days_since_last_completed_order desc, c.customer_id;

-- Section E — Window functions

-- Q35: rank customers by completed-order spending.
with customer_spending as (
    select c.customer_id, c.customer_name,
           coalesce(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0))
             filter (where o.order_status = 'Completed'), 0) as spending
    from retail.customers c left join retail.orders o using (customer_id)
    group by c.customer_id, c.customer_name
)
select customer_id, customer_name, round(spending, 2) as spending_ksh,
       rank() over (order by spending desc) as spending_rank
from customer_spending order by spending_rank, customer_id;

-- Q36: Number each customer's orders by recency (all statuses).
select customer_id, order_id, order_date, order_status,
       row_number() over (partition by customer_id order by order_date desc, order_id desc) as recency_number
from retail.orders order by customer_id, recency_number;

-- Q37: rank products within categories by completed revenue using dense_rank.
with product_revenue as (
    select product_category, product_name,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed'
    group by product_category, product_name
)
select product_category, product_name, round(revenue, 2) as revenue_ksh,
       dense_rank() over (partition by product_category order by revenue desc) as category_rank
from product_revenue order by product_category, category_rank, product_name;

-- Q38: Calculate cumulative monthly completed-order revenue.
with monthly as (
    select date_trunc('month', order_date)::date as sales_month,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed'
    group by date_trunc('month', order_date)
)
select sales_month, round(revenue, 2) as monthly_revenue_ksh,
       round(sum(revenue) over (order by sales_month rows between unbounded preceding and current row), 2)
         as cumulative_revenue_ksh
from monthly order by sales_month;

-- Q39: Compare monthly completed-order revenue with the prior observed sales month.
with monthly as (
    select date_trunc('month', order_date)::date as sales_month,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed'
    group by date_trunc('month', order_date)
)
select sales_month, round(revenue, 2) as revenue_ksh,
       round(lag(revenue) over (order by sales_month), 2) as previous_month_revenue_ksh
from monthly order by sales_month;

-- Q40: Calculate month-over-month completed revenue growth (first month has no prior month).
with monthly as (
    select date_trunc('month', order_date)::date as sales_month,
           sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed'
    group by date_trunc('month', order_date)
), compared as (
    select sales_month, revenue, lag(revenue) over (order by sales_month) as previous_revenue
    from monthly
)
select sales_month, round(revenue, 2) as revenue_ksh,
       round(100.0 * (revenue - previous_revenue) / nullif(previous_revenue, 0), 2) as mom_growth_pct
from compared order by sales_month;

-- Q41: Divide customers into four spending groups using ntile(4); zero spend included.
with customer_spending as (
    select c.customer_id, c.customer_name,
           coalesce(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0))
             filter (where o.order_status = 'Completed'), 0) as spending
    from retail.customers c left join retail.orders o using (customer_id)
    group by c.customer_id, c.customer_name
)
select customer_id, customer_name, round(spending, 2) as spending_ksh,
       ntile(4) over (order by spending desc, customer_id) as spending_quartile
from customer_spending order by spending_quartile, spending desc, customer_id;

-- Q42: Calculate category share of total completed-order revenue using a window function.
with category_revenue as (
    select product_category, sum(quantity * unit_price * (1 - discount / 100.0)) as revenue
    from retail.orders where order_status = 'Completed' group by product_category
)
select product_category, round(revenue, 2) as revenue_ksh,
       round(100.0 * revenue / nullif(sum(revenue) over (), 0), 2) as share_of_revenue_pct
from category_revenue order by revenue desc;

-- Section F — Advanced business intelligence

-- Q43: Monthly view. Order count includes all statuses; money fields use Completed orders only.
create or replace view retail.monthly_sales_summary as
select date_trunc('month', order_date)::date as month,
       count(*) as orders,
       round(coalesce(sum(quantity * unit_price * (1 - discount / 100.0))
           filter (where order_status = 'Completed'), 0), 2) as revenue,
       round(coalesce(sum(quantity * cost_price)
           filter (where order_status = 'Completed'), 0), 2) as cost,
       round(coalesce(sum(quantity * unit_price * (1 - discount / 100.0) - quantity * cost_price)
           filter (where order_status = 'Completed'), 0), 2) as profit
from retail.orders group by date_trunc('month', order_date);

select month, orders, revenue, cost, profit from retail.monthly_sales_summary order by month;

-- Q44: return completed-order revenue for a customer; unknown IDs return 0.
create or replace function retail.completed_revenue_for_customer(p_customer_id integer)
returns numeric(14,2)
language plpgsql
as $$
declare
    v_revenue numeric(14,2);
begin
    select coalesce(sum(quantity * unit_price * (1 - discount / 100.0)), 0)::numeric(14,2)
    into v_revenue
    from retail.orders
    where customer_id = p_customer_id and order_status = 'Completed';
    return coalesce(v_revenue, 0);
end;
$$;

-- Demonstrate with an existing customer and an ID absent from the customers table.
select customer_id, retail.completed_revenue_for_customer(customer_id) as completed_revenue_ksh
from retail.customers order by customer_id limit 1;
select 999999 as customer_id, retail.completed_revenue_for_customer(999999) as completed_revenue_ksh;

-- Q45: Value bands based on completed revenue. Thresholds are data-driven quartiles:
-- top quartile = High, middle two quartiles = Medium, bottom quartile = Low.
-- ntile assigns approximately equal-sized groups; boundary values are derived below.
with customer_spending as (
    select c.customer_id, c.customer_name,
           coalesce(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0))
             filter (where o.order_status = 'Completed'), 0) as spending
    from retail.customers c left join retail.orders o using (customer_id)
    group by c.customer_id, c.customer_name
), ranked as (
    select *, ntile(4) over (order by spending desc, customer_id) as spending_quartile
    from customer_spending
), thresholds as (
    select min(spending) filter (where spending_quartile = 1) as high_threshold,
           min(spending) filter (where spending_quartile = 3) as medium_threshold
    from ranked
)
select r.customer_id, r.customer_name, round(r.spending, 2) as completed_spending_ksh,
       case when r.spending_quartile = 1 then 'High'
            when r.spending_quartile in (2, 3) then 'Medium'
            else 'Low' end as value_segment,
       round(t.high_threshold, 2) as high_value_minimum_ksh,
       round(t.medium_threshold, 2) as medium_value_minimum_ksh
from ranked r cross join thresholds t
order by r.spending desc, r.customer_id;

-- Q46: Management report — four result sets: top five customers, top five products,
-- most profitable category, and lowest-revenue month. Financial figures use Completed orders.
-- Top five customers by completed revenue.
select c.customer_id, c.customer_name,
       round(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) as revenue_ksh
from retail.customers c join retail.orders o using (customer_id)
where o.order_status = 'Completed'
group by c.customer_id, c.customer_name
order by revenue_ksh desc, c.customer_id limit 5;

-- Top five products by completed revenue.
select product_name, round(sum(quantity * unit_price * (1 - discount / 100.0)), 2) as revenue_ksh
from retail.orders where order_status = 'Completed'
group by product_name order by revenue_ksh desc, product_name limit 5;

-- Most profitable category by completed-order profit.
select product_category,
       round(sum(quantity * unit_price * (1 - discount / 100.0) - quantity * cost_price), 2) as profit_ksh
from retail.orders where order_status = 'Completed'
group by product_category order by profit_ksh desc, product_category limit 1;

-- Lowest-revenue month among months that have orders; revenue is completed-order revenue.
with monthly as (
    select date_trunc('month', order_date)::date as sales_month,
           coalesce(sum(quantity * unit_price * (1 - discount / 100.0))
             filter (where order_status = 'Completed'), 0) as revenue
    from retail.orders group by date_trunc('month', order_date)
)
select sales_month, round(revenue, 2) as revenue_ksh
from monthly order by revenue, sales_month limit 1;
