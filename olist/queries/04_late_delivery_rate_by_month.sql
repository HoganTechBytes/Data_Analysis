/*===========================================================================================
    Business question:
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
   - There are clear spikes (Nov 2017, Feb–Mar 2018, Aug 2018), indicating periods of
     operational strain or seasonality.
   - Very small early months (2016-09, 2016-12) are noise due to low volume and shouldn’t
     drive conclusions.
===========================================================================================*/