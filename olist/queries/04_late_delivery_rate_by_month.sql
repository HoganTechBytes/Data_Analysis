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

    Notes / QA:
    - Joining to reviews can inflate counts if there are multiple review rows per order_id.
    - Use DISTINCT order_id for delivered_orders and late_delivered_orders to avoid
      double-counting due to joins.
===========================================================================================*/

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,

    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_delivered_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS late_delivery_rate_pct,

    COUNT(DISTINCT r.order_id) AS delivered_orders_with_reviews,
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
  AND is_late IS NOT NULL
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

    QA:
    - Join to order_items is item-level; use DISTINCT order_id for order counts.
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

/*===========================================================================================
    #5 Business question:
    Are late-delivery spikes driven by specific product categories?

    Scope:
    - Spike months: 2017-11, 2018-02, 2018-03, 2018-08
    - Top 5 categories per month by late_delivery_rate_pct (minimum 50 delivered orders)
===========================================================================================*/

WITH spike_months AS (
    SELECT '2017-11' AS purchase_month UNION ALL
    SELECT '2018-02' UNION ALL
    SELECT '2018-03' UNION ALL
    SELECT '2018-08'
),
category_month AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        p.product_category_name,

        COUNT(DISTINCT o.order_id) AS delivered_orders,
        COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_delivered_orders,

        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END)
            / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
        ) AS late_delivery_rate_pct
    FROM v_orders_clean o
    INNER JOIN v_order_items_clean oi
        ON oi.order_id = o.order_id
    INNER JOIN v_products_clean p
        ON p.product_id = oi.product_id
    INNER JOIN spike_months sm
        ON sm.purchase_month = DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.is_late IS NOT NULL
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
    GROUP BY
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        p.product_category_name
    HAVING delivered_orders >= 50
),
ranked AS (
    SELECT
        cm.*,
        ROW_NUMBER() OVER (
            PARTITION BY cm.purchase_month
            ORDER BY cm.late_delivery_rate_pct DESC
        ) AS rn
    FROM category_month cm
)
SELECT
    purchase_month,
    product_category_name,
    delivered_orders,
    late_delivered_orders,
    late_delivery_rate_pct
FROM ranked
WHERE rn <= 5
ORDER BY purchase_month, late_delivery_rate_pct DESC;

/*===========================================================================================
    #5 So what?
    - Spike months show specific categories with unusually high late-delivery rates rather
      than a uniform increase across all products.
    - Several categories repeat across spike months (e.g., cama_mesa_banho, bebes,
      relogios_presentes, construcao_ferramentas_construcao), suggesting category or
      fulfillment-specific drivers.
    - Some high-late categories also have meaningful volume (hundreds of orders), making them
      likely contributors to overall monthly lateness.
    - Next step: quantify category contribution (share of late orders) to identify which
      categories drive the most late deliveries in spike months.
===========================================================================================*/

/*===========================================================================================
    #6 Business question:
    Which product categories contribute the most late deliveries during spike months?

    Scope:
    - Spike months: 2017-11, 2018-02, 2018-03, 2018-08
===========================================================================================*/

WITH spike_months AS (
    SELECT '2017-11' AS purchase_month UNION ALL
    SELECT '2018-02' UNION ALL
    SELECT '2018-03' UNION ALL
    SELECT '2018-08'
),
category_month AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        p.product_category_name,

        COUNT(DISTINCT o.order_id) AS delivered_orders,
        COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_delivered_orders,

        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END)
            / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
        ) AS late_delivery_rate_pct
    FROM v_orders_clean o
    INNER JOIN v_order_items_clean oi
        ON oi.order_id = o.order_id
    INNER JOIN v_products_clean p
        ON p.product_id = oi.product_id
    INNER JOIN spike_months sm
        ON sm.purchase_month = DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.is_late IS NOT NULL
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
    GROUP BY
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        p.product_category_name
),
totals AS (
    SELECT
        purchase_month,
        SUM(late_delivered_orders) AS total_late_delivered_orders
    FROM category_month
    GROUP BY purchase_month
),
ranked AS (
    SELECT
        cm.*,
        t.total_late_delivered_orders,
        ROUND(
            100.0 * cm.late_delivered_orders / NULLIF(t.total_late_delivered_orders, 0),
            2
        ) AS pct_of_late_orders_in_month,
        ROW_NUMBER() OVER (
            PARTITION BY cm.purchase_month
            ORDER BY cm.late_delivered_orders DESC
        ) AS rn
    FROM category_month cm
    INNER JOIN totals t
        ON t.purchase_month = cm.purchase_month
)
SELECT
    purchase_month,
    product_category_name,
    delivered_orders,
    late_delivered_orders,
    late_delivery_rate_pct,
    pct_of_late_orders_in_month
FROM ranked
WHERE rn <= 10
ORDER BY purchase_month, late_delivered_orders DESC;


/*===========================================================================================
    #6 So what?
    - We identified clear late-delivery spike months and the product categories most
      associated with those spikes.
    - This enables targeted mitigation such as setting more accurate delivery estimates or
      proactive customer messaging for high-risk categories at checkout.
    - Root cause is not proven here and may involve multiple factors (seller capacity, carrier
      performance, geography, or product handling complexity), so conclusions remain
      correlational.
    - Next step: isolate whether delays are driven by specific sellers or regions within the
      high-impact categories.
===========================================================================================*/

/*===========================================================================================
    #7 Business question:
    Within high-impact categories, are late deliveries concentrated among specific sellers
    during spike months?

    Scope:
    - Spike months: 2017-11, 2018-02, 2018-03, 2018-08
    - Categories: cama_mesa_banho, beleza_saude, informatica_acessorios, esporte_lazer
===========================================================================================*/

SET @top_n := 10;
SET @min_late_orders := 10;

WITH spike_months AS (
    SELECT '2017-11' AS purchase_month UNION ALL
    SELECT '2018-02' UNION ALL
    SELECT '2018-03' UNION ALL
    SELECT '2018-08'
),
high_impact_categories AS (
    SELECT 'cama_mesa_banho' AS product_category_name UNION ALL
    SELECT 'beleza_saude' UNION ALL
    SELECT 'informatica_acessorios' UNION ALL
    SELECT 'esporte_lazer'
),
seller_month_category AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        p.product_category_name,
        oi.seller_id,

        COUNT(DISTINCT o.order_id) AS delivered_orders,
        COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_delivered_orders,

        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END)
            / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
        ) AS late_delivery_rate_pct
    FROM v_orders_clean o
    INNER JOIN v_order_items_clean oi
        ON oi.order_id = o.order_id
    INNER JOIN v_products_clean p
        ON p.product_id = oi.product_id
    INNER JOIN spike_months sm
        ON sm.purchase_month = DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
    INNER JOIN high_impact_categories hic
        ON hic.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.is_late IS NOT NULL
      AND p.product_category_name IS NOT NULL
      AND TRIM(p.product_category_name) <> ''
    GROUP BY
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        p.product_category_name,
        oi.seller_id
),
ranked AS (
    SELECT
        smc.*,
        ROW_NUMBER() OVER (
            PARTITION BY smc.purchase_month, smc.product_category_name
            ORDER BY smc.late_delivered_orders DESC
        ) AS rn
    FROM seller_month_category smc
)
SELECT
    purchase_month,
    product_category_name,
    seller_id,
    delivered_orders,
    late_delivered_orders,
    late_delivery_rate_pct
FROM ranked
WHERE rn <= @top_n
  AND late_delivered_orders >= @min_late_orders
ORDER BY purchase_month, product_category_name, late_delivered_orders DESC;


/*===========================================================================================
    #7 So what?
    - During spike months (2017-11, 2018-02, 2018-03, 2018-08), late deliveries within the
      high-impact categories appear to be seller-concentrated rather than evenly distributed.
    - Multiple sellers recur across spike months (especially in cama_mesa_banho), suggesting
      the spike behavior is driven by a small subset of sellers with repeated fulfillment
      delays.
    - This supports targeted mitigation such as prioritizing seller performance reviews,
      tighter shipping SLAs, or updated delivery estimates for high-risk seller/category
      combinations.
    - Root cause is not proven here and may involve multiple factors (seller capacity,
      carrier performance, geography, or product handling complexity), so conclusions remain
      correlational.
    - Next step: quantify “repeat offenders” by ranking sellers across spike months by total
      late orders and contribution share, then optionally validate whether delays cluster by
      region.
===========================================================================================*/
