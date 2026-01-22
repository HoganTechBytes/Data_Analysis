/*===========================================================================================
    #1 Business question:
    How does the late delivery rate change over time (by purchase month)?

    Why it matters:
    - Identifies operational performance trends and seasonality.
    - Highlights periods where customers may be at higher risk of poor experience.
    - Sets up a trend visual for a delivery performance dashboard.

    Definition:
    - Month = purchase month from v_orders_clean (order_purchase_timestamp)
    - Late delivered order = order_status = 'delivered' AND is_late = 1
===========================================================================================*/

USE olist;

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_delivered_orders,
    ROUND(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS late_delivery_rate_pct
FROM v_orders_clean
WHERE order_status = 'delivered'
    AND order_purchase_timestamp IS NOT NULL
    AND is_late IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    #1 So what?

   - Late deliveries are usually under ~10% of delivered orders, suggesting lateness is not
     constant across the dataset.
   - Late rates spike in a few months (Nov 2017, Feb–Mar 2018, Aug 2018), peaking around
     ~21% in Mar 2018, suggesting operational strain or seasonality.
   - Very small early months (2016-09, 2016-12) are noise due to low volume and shouldn’t
     drive conclusions.
===========================================================================================*/

/*===========================================================================================
    #2 Business question:
    Do months with higher late-delivery rates also show lower average review scores?

    Why it matters:
    - Connects operational performance (lateness) to customer outcomes (ratings).
    - Helps prioritize which late-rate spikes may be most harmful to sentiment.

    Notes:
    - late_delivery_rate_pct is based on delivered orders.
    - avg_review_score is based on delivered orders that have reviews.
===========================================================================================*/

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN o.is_late = 1 THEN 1 ELSE 0 END) AS late_delivered_orders,
    ROUND(
        100.0 * SUM(CASE WHEN o.is_late = 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS late_delivery_rate_pct,
    COUNT(r.order_id) AS delivered_orders_with_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM v_orders_clean AS o
LEFT JOIN v_reviews_clean AS r
    ON r.order_id = o.order_id
    AND r.review_score IS NOT NULL
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.is_late IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    #2 So what?
    - Average customer review scores are consistently strong (~4.1–4.3) across most months.
    - Months with higher late-delivery rates align with noticeable dips in average review
      score (e.g., Mar 2018: 21.37% late and 3.81 avg rating).
    - This supports the idea that late delivery rate is a meaningful operational metric tied
      to customer sentiment at the monthly level.
    - Very small early months (2016-09, 2016-12) are low-volume noise and shouldn’t drive
      trend conclusions.
===========================================================================================*/
/*===========================================================================================
    #3 Business question:
    Are late deliveries worse in high-volume months?

    Why it matters:
    - Tests whether late deliveries increase when order volume increases (capacity strain).
    - Helps distinguish seasonality effects from isolated operational issues.

    Definition:
    - Volume = delivered_orders per purchase_month
    - Late rate = late_delivered_orders / delivered_orders
===========================================================================================*/

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_delivered_orders,
    ROUND(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS late_delivery_rate_pct
FROM v_orders_clean
WHERE order_status = 'delivered'
    AND order_purchase_timestamp IS NOT NULL
    and is_late IS NOT NULL
GROUP BY purchase_month
ORDER BY delivered_orders DESC
LIMIT 10;

/*===========================================================================================
    #3 So what?
    - High order volume does not consistently produce high late-delivery rates (e.g., some
      high-volume months still have low late rates).
    - However, several peak-volume months also show elevated lateness (Nov 2017, Feb–Mar
      2018), suggesting volume may contribute but is not the only driver.
    - Late delivery spikes appear event-driven or operationally specific rather than a
      predictable “more orders = more late deliveries” relationship.
    - Next step: investigate what changed in spike months (seller mix, product categories,
      freight/distance, or regional delivery patterns).
===========================================================================================*/
/*===========================================================================================
    #4 Business question:
    Are spike months associated with higher freight costs?

    Why it matters:
    - Higher freight cost can signal longer routes, heavier orders, or logistics strain.
    - Helps explain why certain months see late-delivery spikes.

    Definition:
    - Month = purchase month from v_orders_clean (order_purchase_timestamp)
    - Freight = SUM(freight_value) from v_order_items_clean
    - Avg freight per delivered order = total_freight / delivered_orders
===========================================================================================*/

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_delivered_orders,

    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS late_delivery_rate_pct,

    ROUND(SUM(oi.freight_value), 2) AS total_freight_value,
    ROUND(
        SUM(oi.freight_value) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_freight_per_order
FROM v_orders_clean AS o
INNER JOIN v_order_items_clean AS oi
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp IS NOT NULL
    AND o.is_late IS NOT NULL
GROUP BY purchase_month
ORDER BY late_delivered_orders DESC
LIMIT 10;

/*===========================================================================================
    #4 So what?
    - Spike months with high late-delivery rates do not consistently show higher average
      freight costs per order.
    - Some months have higher freight costs but low late-delivery rates (e.g., 2018-07),
      suggesting freight cost alone does not explain delivery delays.
    - Late spikes occur even when freight cost is relatively low (e.g., 2018-02), indicating
      other operational factors are likely driving delays.
    - Next step: investigate other drivers such as seller mix, product categories, and
      geographic delivery patterns during spike months.
===========================================================================================*/
