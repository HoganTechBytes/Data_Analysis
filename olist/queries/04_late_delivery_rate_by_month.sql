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
