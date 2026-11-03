-- 02_create_tables.sql
-- Creates the retail schema and its two tables. Run connected to retail_analytics.
--
-- psql -U postgres -d retail_analytics -f 02_create_tables.sql
--
-- Safe to re-run: existing tables and data are left in place.
-- To start again from scratch, uncomment the DROP statements below.

-- DROP TABLE IF EXISTS retail.orders;
-- DROP TABLE IF EXISTS retail.customers;

CREATE SCHEMA IF NOT EXISTS retail;

CREATE TABLE IF NOT EXISTS retail.customers (
    customer_id        INTEGER      PRIMARY KEY,
    customer_name      VARCHAR(100) NOT NULL,
    gender             VARCHAR(10)  CHECK (gender IN ('Male', 'Female')),
    city               VARCHAR(50),
    registration_date  DATE,
    customer_segment   VARCHAR(20)  CHECK (customer_segment IN ('Retail', 'Corporate', 'VIP'))
);

CREATE TABLE IF NOT EXISTS retail.orders (
    order_id          INTEGER       PRIMARY KEY,
    customer_id       INTEGER       NOT NULL REFERENCES retail.customers (customer_id),
    order_date        DATE          NOT NULL,
    product_name      VARCHAR(100),
    product_category  VARCHAR(50),
    quantity          INTEGER       CHECK (quantity > 0),
    unit_price        NUMERIC(12,2) CHECK (unit_price >= 0),
    cost_price        NUMERIC(12,2) CHECK (cost_price >= 0),
    discount          NUMERIC(5,2)  DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),
    payment_method    VARCHAR(30)   CHECK (payment_method IN ('M-Pesa', 'Cash', 'Card', 'Bank Transfer')),
    order_status      VARCHAR(20)   CHECK (order_status IN ('Completed', 'Pending', 'Cancelled'))
);

-- Indexes support common customer joins and date filters.
CREATE INDEX IF NOT EXISTS idx_orders_customer ON retail.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON retail.orders (order_date);
