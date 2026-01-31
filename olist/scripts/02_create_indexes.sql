-- =======================================================================================
--  Olist (Kaggle) – Index Creation Script
--
--  Purpose:
--      Adds helpful indexes for joins and analytics queries
--
--  Note:
--      Re-running this script will error if indexes already exist.
--      If you need a clean rebuild, run 00_dev_reset_schema.sql.
-- =======================================================================================

USE olist;

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_reviews_order_id ON order_reviews(order_id);
CREATE INDEX idx_customers_unique ON customers(customer_unique_id);