/*
    Business Question:
    - How many orders are placed per month?

    Notes:
    - Uses order_purchase_timestamp (when the order was made)
    - Includes all orders regardless of status (filter if needed)
*/

USE olist;

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS order_count
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL AND order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;