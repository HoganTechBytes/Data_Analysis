/*===========================================================================================
    Business Question:
    - How much revenue do we generate per month (payments-based)?

    Why it matters:
    - Shows revenue trend over time and seasonality
    - Lets us compare revenue trend vs order volume trend

    Definition:
    - Revenue = SUM(payment_value) from v_payments_clean
    - Month = purchase month from v_orders_clean (order_purchase_timestamp)

    Caveat:
    - Dataset tail months may be incomplete
===========================================================================================*/

USE olist;

-- Question: What is total payments-based revenue per purchase month? --

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM v_orders_clean AS o
INNER JOIN v_payments_clean AS p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    So what?
    - Revenue ramps through 2017 and peaks around Nov 2017 (holiday effect likely).
    - Early months in 2016 show very low revenue and missing months (data starts midstream / 
      tracking begins).
    - 2018-09 and 2018-10 are unusually low and likely reflect an incomplete dataset tail, not
      true demand collapse.
=============================================================================================*/

-- Question: For each purchase month, what are total orders, delivered orders, total revenue,
-- and AOV (total vs delivered)?

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,

    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(
        DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END
    ) AS delivered_orders,

    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(
        SUM(p.payment_value) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS aov_total,
    ROUND(
        SUM(p.payment_value) / NULLIF(COUNT(DISTINCT CASE WHEN o.order_status = 'delivered'
        THEN o.order_id END), 0), 2
    ) AS aov_delivered,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0) * 100, 2
        ) AS pct_orders_delivered
FROM v_orders_clean AS o
INNER JOIN v_payments_clean AS p
    ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*==========================================================================================
    So what?
    - Revenue growth is mainly driven by higher order volume, since delivered AOV stays 
      relatively stable (~150–175).
    - Delivered rate stabilizes in the mid-to-high 90% range across 2017–2018, suggesting
      strong fulfillment completion.
    - October 2016 has a notably lower delivered rate (~82%), which may indicate early
      operational instability or data quality issues.
    - September/October 2018 appear to be incomplete months (very low volume, 0% delivered)
      and should be excluded from trend conclusions.
==========================================================================================*/
