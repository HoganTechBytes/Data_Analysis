/*
Business Question:
- How many orders are placed each month?

Why it matters:
- Helps identify growth, seasonality, and unusual dips/spikes in demand

Notes:
- Uses order_purchase_timestamp (when the order was placed)
- Includes all orders, and separately counts delivered orders
- Dataset tail may be incomplete (final months show very low volume / undelivered orders)
*/

USE olist;

-- Question: How many orders were purchased each month (based on purchase timestamp)? --

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- Question: Of the orders purchased each month, how many were ultimately delivered? --

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;

-- Question: For each purchase month, what were total orders, delivered orders, and the delivered rate (% delivered)? --

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS total_order_count,
    SUM(
        CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END
       ) AS delivered_orders,
    ROUND(
        100 * SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) / COUNT(*), 2
        ) AS delivered_rate_pct
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;