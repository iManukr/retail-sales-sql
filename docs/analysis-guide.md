# Analysis guide

This guide explains how to work with the SQL analysis in [`../queries.sql`](../queries.sql). The database and dataset setup instructions are in the [project README](../README.md), and the original assignment is in [`../data/README.md`](../data/README.md).

## Data model

The analysis uses two tables in the `retail` schema:

- `retail.customers`: one row per customer, including their city, registration date, and segment.
- `retail.orders`: one row per order, linked to a customer by `customer_id`.

Each order includes product, quantity, unit price, cost price, discount percentage, payment method, date, and status. The customer-to-orders relationship is one-to-many. A left join is used when customers without orders must remain in the result.

## Financial calculations

Apply these expressions consistently:

```sql
-- Net sales revenue after discount
quantity * unit_price * (1 - discount / 100.0)

-- Cost and profit
quantity * cost_price
quantity * unit_price * (1 - discount / 100.0) - quantity * cost_price
```

Financial totals and averages filter to `order_status = 'Completed'`. The discount is a percentage, so a value of `10` means ten percent. Use `100.0` in percentage calculations to avoid integer division, and use `nullif(denominator, 0)` for safe division.

Order counts generally include `Completed`, `Pending`, and `Cancelled` orders. The monthly view follows both rules: its `orders` column counts all orders, while money columns include completed orders only.

## Query design notes

- **Customer spending:** where a question asks for an average customer spend, first aggregate completed revenue to one row per customer, then aggregate those customer totals. This avoids treating each order as a separate customer observation.
- **Customers with no orders:** use a left join and test the order-side key for `null`.
- **Monthly analysis:** group by `date_trunc('month', order_date)` so months from different years are not combined. Window calculations are applied after monthly aggregation.
- **Inactive customers:** Q34 compares each customer's latest completed order date to the maximum order date in the dataset. Customers with no completed order have no latest completed order and are not included.
- **Category popularity:** Q28 measures popularity by completed units sold and preserves ties for the top category.
- **Value bands:** Q45 orders customers by completed revenue and assigns quartiles with `ntile(4)`. The top quartile is High, the middle half is Medium, and the bottom quartile is Low. The exact monetary cutoffs depend on the loaded dataset and are returned by the query.
- **Management summary:** Q46 produces four result sets. It ranks customers and products by completed revenue, categories by completed profit, and months by completed revenue.

## Views and function

Q43 creates or replaces `retail.monthly_sales_summary`, with one row per month and the columns `month`, `orders`, `revenue`, `cost`, and `profit`.

Q44 creates or replaces `retail.completed_revenue_for_customer(integer)`. It sums completed-order revenue for the requested customer and returns `0` if there are no matching completed orders, including when the customer ID does not exist.

Both statements can be run again safely because they use `create or replace`. Run the file with a role that has permission to create objects in the `retail` schema.

## Turning query results into insights

Use query output as evidence, then explain a business implication and a concrete action. For each finding, record:

1. The result and its query number (for example, category revenue from Q16 or margin from Q33).
2. Why the result may matter, such as sales concentration, weak profitability, customer churn risk, or city-level opportunity.
3. A recommendation linked to the evidence, such as reviewing discounts, protecting stock for a leading product, or contacting lapsed high-spend customers.

Do not infer causes from a descriptive query alone. For example, a lower-revenue month identifies when sales were lower; it does not explain why. Compare order volume, average order value, category mix, and order status before recommending a cause-specific change.

## Business questions and recommendations

Use these recommendations as next steps after reviewing the actual query results. They are decision guides, not claims about what the dataset shows.

| Business question | Evidence to review | Recommendation to consider |
|---|---|---|
| Which customers should receive retention outreach? | Q24 and Q34: high spenders and customers whose last completed purchase is over 90 days old. | Prioritize lapsed customers with high historical spending for personal follow-up. Offer a relevant product or service based on their purchase history; track whether they return and the margin after any incentive. |
| Which products deserve more inventory attention? | Q18 and Q46: completed units sold and top products by revenue. | Check stock availability and supplier lead times for products that rank highly on both units and revenue. Avoid expanding stock based on revenue alone; check profitability and returns before increasing orders. |
| Are promotions helping profitability? | Q33 and Q16: category profit, margin, and revenue. | Compare discounted sales and margin by category. Keep or expand promotions only where incremental volume offsets the discount; revise discounts that raise revenue while eroding profit. |
| Which locations need a sales plan? | Q25: completed revenue by customer city. | Compare city revenue with customer counts and order frequency. If a city has a substantial customer base but weak revenue, investigate availability, product mix, and local outreach before increasing broad advertising spend. |
| Is the business growing consistently? | Q38–Q40: cumulative revenue and month-over-month revenue changes. | Investigate sharp declines by checking order counts, average order value, category mix, and cancelled orders. Plan stock and campaigns around repeatable seasonal patterns rather than reacting to one unusually strong month. |
| Which customer segments are most valuable? | Q27 and Q45: average customer spend by segment and quartile-based value bands. | Tailor service and loyalty benefits to customer value while monitoring the cost of those benefits. Use the bands to prioritize outreach, and review thresholds periodically as sales grow. |

For the final submission, strengthen these recommendations with the actual values returned by the queries. State the query number, the observed number or comparison, why it matters, and the action management should take.

