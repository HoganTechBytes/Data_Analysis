/*===========================================================================================
    Business question:
    Do late deliveries correlate with lower review scores (association, not causation)?

    Why it matters:
    Late delivery is a service-quality signal. If late orders tend to have worse reviews,
    it indicates customer sentiment risk.
===========================================================================================*/

USE olist;

-- Note: pct_of_reviewed_deliveries is within delivered orders that have reviews (join to reviews). --

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
GROUP BY o.is_late, delivery_status
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

-- Question: What is the comment rate (% of reviews with non-empty text) for late vs on-time deliveries? --

SELECT
    CASE
        WHEN o.is_late = 0 THEN 'On Time'
        WHEN o.is_late = 1 THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS reviews_total,

    SUM(CASE WHEN r.review_comment_message IS NOT NULL 
             AND TRIM(r.review_comment_message) <> '' 
        THEN 1 ELSE 0 END) AS reviews_with_comments,

    ROUND(
        100.0 * SUM(CASE WHEN r.review_comment_message IS NOT NULL 
                          AND TRIM(r.review_comment_message) <> '' 
                    THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS pct_with_comments
FROM v_orders_clean AS o
INNER JOIN v_reviews_clean AS r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
    AND o.is_late IS NOT NULL
    AND r.review_score IS NOT NULL
GROUP BY o.is_late, delivery_status
ORDER BY o.is_late;

/*===========================================================================================
    So what?
    - Late orders are only 7.98% of reviewed deliveries, but they’re associated with far
      higher low-rating rates.
    - This suggests late delivery creates stronger customer frustration (people are more
      motivated to explain why they rated poorly).
    - Written comments are a rich source of root-cause insight, especially for late
      deliveries.
    - Next step: review/comment themes (late delivery, missing items, damage, product
      quality) to identify what drives low ratings beyond timing.
===========================================================================================*/

-- Question: What is the full rating distribution (1–5) by late vs on-time --

SELECT
    CASE
        WHEN o.is_late = 0 THEN 'On Time'
        WHEN o.is_late = 1 THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    r.review_score,

    COUNT(*) AS review_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.is_late), 2
    ) AS pct_within_status
FROM v_orders_clean AS o
INNER JOIN v_reviews_clean AS r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
    AND o.is_late IS NOT NULL
    AND r.review_score IS NOT NULL
GROUP BY o.is_late, delivery_status, r.review_score
ORDER BY o.is_late, r.review_score;

/*===========================================================================================
    So what?
   - On-time deliveries are overwhelmingly positive: 62.48% are 5-star, and only 9.18% are
     1–2 stars.
   - Late deliveries shift dramatically toward the lowest ratings: 46.23% are 1-star (vs 
     6.55% on-time).
   - Late deliveries also reduce 5-star outcomes sharply: 22.24% 5-star vs 62.48% on-time.
   - This shows lateness doesn’t just “slightly lower” satisfaction—it strongly polarizes
     reviews toward negative outcomes.
===========================================================================================*/

-- Question: What share of low reviews (1–2 stars) come from late vs on-time deliveries? --

SELECT
    CASE
        WHEN o.is_late = 0 THEN 'On Time'
        WHEN o.is_late = 1 THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS low_review_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2
    ) AS pct_of_all_low_reviews
FROM v_orders_clean AS o
INNER JOIN v_reviews_clean AS r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
    AND o.is_late IS NOT NULL
    AND r.review_score IS NOT NULL
    AND r.review_score <= 2
GROUP BY o.is_late, delivery_status
ORDER BY o.is_late;

/*===========================================================================================
    Combined insight:
    Delivery timeliness is strongly associated with customer satisfaction. Late deliveries
    are rare (7.98% of reviewed orders) but have much worse outcomes:
      - Avg rating: 2.57 late vs 4.30 on-time
      - Low-rating rate (1–2 stars): 54.06% late vs 9.18% on-time
      - Comment rate: 55.52% late vs 39.30% on-time
    Late orders account for 33.82% of all 1–2 star reviews despite being a small share of
    reviewed deliveries, making late delivery reduction a high-leverage quality improvement.

    Analyst workflow note:
    This analysis was iterative: each query answered one question, then used the results to
    refine the next question and strengthen the final conclusions with supporting evidence.
===========================================================================================*/
