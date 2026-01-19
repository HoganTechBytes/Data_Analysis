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

DROP VIEW IF EXISTS v_payments_clean;

CREATE VIEW v_payments_clean AS
    SELECT 
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
FROM order_payments;

DROP VIEW IF EXISTS v_customers_clean;

CREATE VIEW v_customers_clean AS
    Select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
FROM customers;

DROP VIEW IF EXISTS v_reviews_clean;

CREATE VIEW v_reviews_clean AS
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
FROM order_reviews;