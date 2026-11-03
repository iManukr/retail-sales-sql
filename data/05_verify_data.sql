-- 05_verify_data.sql
-- Run while connected to retail_analytics after loading the dataset into the retail schema.
-- Expected: 150 customers, 800 orders, no orphan orders, five categories,
-- and the expected order statuses and date range.
--
-- In DBeaver, open this file in the retail_analytics connection and execute the script.

SELECT 'customers' AS check_name, COUNT(*)::TEXT AS result, '150' AS expected
FROM retail.customers
UNION ALL
SELECT 'orders', COUNT(*)::TEXT, '800'
FROM retail.orders
UNION ALL
SELECT 'orders with no customer', COUNT(*)::TEXT, '0'
FROM retail.orders o
LEFT JOIN retail.customers c USING (customer_id)
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'first order DATE', MIN(order_date)::TEXT, '2025-01-..'
FROM retail.orders
UNION ALL
SELECT 'last order DATE', MAX(order_date)::TEXT, '2026-09-..'
FROM retail.orders
UNION ALL
SELECT 'customers with no orders', COUNT(*)::TEXT, 'more than 0'
FROM retail.customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM retail.orders o
    WHERE o.customer_id = c.customer_id
)
UNION ALL
SELECT 'customers with 2+ orders', COUNT(*)::TEXT, 'more than 0'
FROM (
    SELECT customer_id
    FROM retail.orders
    GROUP BY customer_id
    HAVING COUNT(*) >= 2
) t
UNION ALL
SELECT 'customers with 6+ orders', COUNT(*)::TEXT, 'more than 0'
FROM (
    SELECT customer_id
    FROM retail.orders
    GROUP BY customer_id
    HAVING COUNT(*) > 5
) t
UNION ALL
SELECT 'categories', COUNT(DISTINCT product_category)::TEXT, '5'
FROM retail.orders
UNION ALL
SELECT 'statuses', string_agg(DISTINCT order_status, ', '), 'Cancelled, Completed, Pending'
FROM retail.orders
UNION ALL
SELECT 'orders before registration', COUNT(*)::TEXT, '0'
FROM retail.orders o
JOIN retail.customers c USING (customer_id)
WHERE o.order_date < c.registration_date;

-- Completed-order revenue, cost, AND profit (see the project README business rules).
SELECT
    ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100.0)), 0), 2) AS completed_revenue,
    ROUND(COALESCE(SUM(quantity * cost_price), 0), 2) AS completed_cost,
    ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100.0))
        - SUM(quantity * cost_price), 0), 2) AS completed_profit
FROM retail.orders
WHERE order_status = 'Completed';
