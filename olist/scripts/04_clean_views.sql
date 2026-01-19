/*
Olist (Kaggle) – Clean Views

Purpose:
- Provide analysis-friendly column names and light standardization
- Keep raw imported tables unchanged

Usage:
- Write portfolio queries against these views (prefixed with v_)

Kaggle has known data quality issues, such as typos in column names.
*/

USE olist;

DROP VIEW IF EXISTS v_products_clean;

CREATE VIEW v_products_clean AS
SELECT
    product_id,
    product_category_name,
    product_name_lenght AS product_name_length,
    product_description_lenght AS product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;

DROP VIEW IF EXISTS v_orders_clean;

CREATE VIEW v_orders_clean AS
SELECT
    order_id,
    customer_id,
    order_status,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    -- Derived columns --
    CASE
      WHEN order_delivered_customer_date IS NULL THEN NULL
      ELSE TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)
    END AS delivery_days,

    CASE
        WHEN order_delivered_customer_date IS NULL THEN NULL
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_late
FROM orders;

DROP VIEW IF EXISTS v_order_items_clean;

CREATE VIEW v_order_items_clean AS
    SELECT 
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value,

        -- Derived column --
        (price + freight_value) AS item_total
FROM order_items;