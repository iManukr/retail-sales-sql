# Duka Smart Electronics Retail Analytics

PostgreSQL analysis of sales and customer activity for Duka Smart Electronics, a fictional Kenyan retailer. The project answers the 46 assignment questions with SQL, from basic filtering through customer analysis, CTEs, window functions, a view, and a PL/pgSQL function.

## Project files

- [`queries.sql`](queries.sql) — all 46 answers, numbered `Q1` through `Q46`.
- [`insights.md`](insights.md) — findings from the query results, why they matter, and recommendations for management.
- [`docs/analysis-guide.md`](docs/analysis-guide.md) — data model, calculation choices, and guidance for interpreting results.
- [`screenshots/`](screenshots/) — folder for query result screenshots embedded in `insights.md`.
- [`data/01_create_database.sql`](data/01_create_database.sql) — creates the `retail_analytics` database when run against another database, such as `postgres`.
- [`data/02_create_tables.sql`](data/02_create_tables.sql) — creates the `retail` schema, its tables, and useful indexes.
- [`data/03_insert_customers.sql`](data/03_insert_customers.sql) — loads 150 customer records.
- [`data/04_insert_orders.sql`](data/04_insert_orders.sql) — loads 800 order records.
- [`data/05_verify_data.sql`](data/05_verify_data.sql) — checks the loaded record counts and data rules.
- [`data/README.md`](data/README.md) — the original assignment guide and full dataset reference.

## Requirements

- PostgreSQL 14 or newer.
- DBeaver, pgAdmin, or `psql` to connect to PostgreSQL and run SQL scripts.
- The `retail_analytics` database with the supplied `customers` and `orders` tables.

The analysis script expects both tables to be in the PostgreSQL schema named `retail`. PostgreSQL schemas are namespaces inside a database; the database should still be named `retail_analytics`.

## Set up the database

### Create the database

In DBeaver, connect to the PostgreSQL server and open an SQL editor connected to the `postgres` database. Run this statement once:

```sql
CREATE DATABASE retail_analytics;
```

The supplied `data/01_create_database.sql` uses `\\gexec`, a `psql`-specific command. In DBeaver, use the SQL statement above instead.

### Load the dataset

Connect to `retail_analytics`. Run the files in this order:

1. `data/02_create_tables.sql`
2. `data/03_insert_customers.sql`
3. `data/04_insert_orders.sql`
4. `data/05_verify_data.sql`

In DBeaver, open each file in the SQL editor associated with `retail_analytics` and use **Execute SQL Script**. The table setup script creates a schema named `retail` and creates both tables in it. Verification should report 150 customers and 800 orders.

## Run the analysis

Open `queries.sql` in DBeaver, make sure its active connection is `retail_analytics`, and execute the script. The queries are written with lowercase SQL commands and fully qualified table names such as `retail.customers`.

The script contains regular `select` queries as well as `create or replace view` and `create or replace function` statements. The latter create `retail.monthly_sales_summary` and `retail.completed_revenue_for_customer(...)`. The function examples show revenue for an existing customer and return zero for a nonexistent ID.

Some questions return multiple result sets. In particular, Q43 selects from the monthly view, Q44 shows two function examples, and Q46 returns four report sections. Use DBeaver's result tabs to view each result.

## Add screenshots

Save result screenshots in `screenshots/` with these filenames to have them appear beside the matching findings in `insights.md`:

- `q33-category-profitability.png`
- `q25-revenue-by-city.png`
- `q27-spending-by-segment.png`
- `q34-inactive-customers.png`
- `q40-monthly-revenue-growth.png`
- `q46-management-report.png`


## Business rules used

- Revenue: `quantity * unit_price * (1 - discount / 100.0)`.
- Cost: `quantity * cost_price`.
- Profit: revenue minus cost.
- Profit margin: `profit / nullif(revenue, 0) * 100`.
- Monetary calculations use `Completed` orders only unless a question explicitly asks for order counts or another measure.
- Order counts include all statuses. Customer counts count distinct customers.
- Monthly grouping uses `date_trunc('month', order_date)`.
- “Latest date” means the maximum `order_date` in the data, rather than the computer's current date.
- Q28 defines popularity as completed units sold. Q27 averages per-customer completed spending within each segment and includes customers with no completed spending as zero.
- Q45 uses spending quartiles: the top quartile is High, the middle two quartiles are Medium, and the bottom quartile is Low. The query includes the data-derived boundary amounts in its output.

## Question map

| Questions | Topics |
|---|---|
| Q1–Q10 | Selection, filtering, sorting, distinct values, and limits |
| Q11–Q20 | Counts, revenue, averages, grouping, and percentages |
| Q21–Q28 | Customer joins, spending, segments, and category popularity |
| Q29–Q34 | Subqueries, CTEs, product pricing, profitability, and inactive customers |
| Q35–Q42 | Ranking, recency, cumulative totals, monthly comparisons, and shares |
| Q43–Q46 | Monthly view, revenue function, value bands, and management report |

## Notes and limitations

- The records are fictional and should be treated as assignment data, not actual company results.
- The script assumes `retail.customers` and `retail.orders` already exist and the supplied data is loaded.
- Q43's monthly order count includes every order status, while its revenue, cost, and profit include completed orders only.
- Q46's lowest-revenue month is selected from months present in `orders`; months with no orders do not appear in the source data.
- Run `data/05_verify_data.sql` before analysis if you need to confirm the dataset is loaded correctly. It expects the tables to be in the `retail` schema.

