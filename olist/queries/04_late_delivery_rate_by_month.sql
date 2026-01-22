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
    So what?

    - Baseline: Late deliveries are usually under ~10% of delivered orders (most months).
      Spikes / anomalies: There are clear late-rate surges:
        - Nov 2017: 14.31%
        - Feb 2018: 15.99%
        - Mar 2018: 21.36% (highest)
        - Aug 2018: 10.39%

    - Interpretation: Those spikes suggest periods of operational strain (seasonality,
      backlog, logistics bottlenecks), not a constant problem.
===========================================================================================*/