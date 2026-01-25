/*===========================================================================================
    Business Question:
    - How many orders are placed each month, and how many of those are delivered?

    Why it matters:
    - Establishes baseline demand over time (growth + seasonality).
    - Highlights incomplete “tail months” where delivery outcomes may not have fully
      occurred.
    - Provides context for downstream operational metrics (late delivery rate, reviews,
      revenue).

    Notes / QA:
    - Month is based on order_purchase_timestamp (when the order was placed).
    - “Delivered” is based on order_status = 'delivered'.
    - Final months may show artificially low delivered rates due to dataset
      tail / incomplete lifecycle.
===========================================================================================*/

USE olist;

/*===========================================================================================
    Question 1:
    - How many orders were purchased each month?

    Definition:
    - purchase_month = DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
    - order_count = COUNT(*) across all orders with a purchase timestamp
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS order_count
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    So what?
    - This establishes the demand baseline and helps spot seasonality, growth, or unusual
      dips.
    - Use this chart as the “context layer” for delivery performance and customer sentiment
      metrics.
    - Watch for very early/late months with low volume, which can amplify noise in
      rate-based metrics.
===========================================================================================*/


/*===========================================================================================
    Question 2:
    - Of the orders purchased each month, how many were ultimately delivered?

    Definition:
    - delivered_orders = COUNT(*) where order_status = 'delivered'
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS delivered_orders
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
  AND order_status = 'delivered'
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    So what?
    - Delivered order counts show fulfilled demand and help validate whether demand spikes
      were actually completed or still “in progress” in tail months.
    - If delivered_orders sharply diverges from total orders in late months, it likely
      reflects dataset tail/incomplete outcomes rather than real operational collapse.
===========================================================================================*/


/*===========================================================================================
    Question 3:
    - For each purchase month, what were total orders, delivered orders, and delivery rate?

    Definition:
    - total_orders = COUNT(*) for the purchase month
    - delivered_orders = SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
    - delivered_rate_pct = delivered_orders / total_orders

    Notes / QA:
    - Delivery rate can be misleading in the dataset tail (final months), where many orders
      may not have reached a terminal status in the available data extract.
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS delivered_rate_pct
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    So what?
    - This combines demand (total_orders) with fulfillment (delivered_orders) to show how
      “complete” each month is in the dataset.
    - Months with low delivered_rate_pct near the end of the timeline should be treated as
      incomplete lifecycle months (dataset tail) and excluded from conclusions about
      performance.
    - Next step: use delivered orders as the denominator for operational metrics
      (late delivery rate, review impacts) to avoid mixing in orders that never delivered.
===========================================================================================*/
/*===========================================================================================
    Question 4:
    - What is the order status breakdown by purchase month?

    Why it matters:
    - Explains “non-delivered” orders by outcome (canceled/unavailable/etc.).
    - Helps validate dataset tail behavior where many recent orders may still be
      in-progress.
    - Supports dashboard filters (focus on delivered orders for operational performance
      metrics).
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    order_status,
    COUNT(*) AS orders_in_status
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
  AND order_status IS NOT NULL
GROUP BY purchase_month, order_status
ORDER BY purchase_month, orders_in_status DESC;

/*===========================================================================================
    So what?
    - This shows whether non-delivered orders are mostly canceled/unavailable vs simply
      still in-flight (processing/shipped) in tail months.
    - If tail months have large counts in non-terminal statuses, the low delivered rate is
      likely incomplete data capture rather than operational failure.
    - Next step: for delivery performance metrics, restrict denominators to delivered orders
      to avoid mixing incomplete lifecycle orders into KPIs.
===========================================================================================*/

/*===========================================================================================
    Question 5:
    - What is the cancellation rate by purchase month?

    Why it matters:
    - Identifies demand that was lost before fulfillment (business impact separate from
      delivery).
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_orders,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS cancellation_rate_pct
FROM v_orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;
