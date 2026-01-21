/*===========================================================================================
    Business question:
    Do late deliveries correlate with lower review scores (association, not causation)?

    Why it matters:
    Late delivery is a service-quality signal. If late orders tend to have worse reviews,
    it indicates customer sentiment risk.
===========================================================================================*/

USE olist;

SELECT 
    CASE
        WHEN o.is_late = 0 THEN 'On Time'
        WHEN o.is_late = 1 THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS delivered_orders_with_reviews,

    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(
        100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS pct_low_reviews,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_reviewed_deliveries
FROM v_orders_clean AS o
INNER JOIN v_reviews_clean AS r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
    AND o.is_late IS NOT NULL
    AND r.review_score IS NOT NULL
GROUP BY o.is_late
ORDER BY o.is_late;

/*===========================================================================================
     So what?
   - On-time deliveries average 4.30 stars, while late deliveries drop to 2.57 stars (strong
     negative association).
   - Late deliveries have a much higher low-rating rate: 54.06% of late orders are 1–2 stars
     vs 9.18% for on-time.
   - Late orders are only 7.98% of reviewed deliveries, but they create a disproportionate
     share of negative customer sentiment.
   - Even on-time deliveries still generate low reviews (9.18%), suggesting other drivers
     beyond delivery speed (product/seller quality, damage, expectations).
===========================================================================================*/
