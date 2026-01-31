-- =======================================================================================
--  Olist (Kaggle) – Schema Setup Script (SAFE)
--
--  Purpose:
--      Creates the `olist` database if it does not already exist
--      Creates the base tables used for importing the raw CSVs
--
--  When to run:
--      First-time setup
--      Safe re-runs (will error if tables already exist unless you drop them)
--
--  Notes:
--      This script does NOT drop the database.
--      If you need a full reset, run the DEV reset script instead.
-- =======================================================================================

CREATE DATABASE IF NOT EXISTS olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

-- ---------------------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
  customer_id                   VARCHAR(50)             PRIMARY KEY,
  customer_unique_id            VARCHAR(50),
  customer_zip_code_prefix      INT,
  customer_city                 VARCHAR(100),
  customer_state                CHAR(2)
);

-- ---------------------------------------------------------------------------------------
-- Geolocation (large table)
-- ---------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS geolocation (
  geolocation_zip_code_prefix   INT,
  geolocation_lat               DECIMAL(10, 7),
  geolocation_lng               DECIMAL(10, 7),
  geolocation_city              VARCHAR(100),
  geolocation_state             CHAR(2)
);

-- ---------------------------------------------------------------------------------------
-- Sellers
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sellers (
  seller_id                     VARCHAR(50)             PRIMARY KEY,
  seller_zip_code_prefix        INT,
  seller_city                   VARCHAR(100),
  seller_state                  CHAR(2)
);

-- ---------------------------------------------------------------------------------------
-- Product category translation
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS product_category_name_translation (
  product_category_name         VARCHAR(100)            PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);

-- ---------------------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS products (
  product_id                    VARCHAR(50)             PRIMARY KEY,
  product_category_name         VARCHAR(100),
  product_name_lenght           INT,
  product_description_lenght    INT,
  product_photos_qty            INT,
  product_weight_g              INT,
  product_length_cm             INT,
  product_height_cm             INT,
  product_width_cm              INT
);

-- ---------------------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS orders (
  order_id                      VARCHAR(50)             PRIMARY KEY,
  customer_id                   VARCHAR(50),
  order_status                  VARCHAR(30),
  order_purchase_timestamp      DATETIME,
  order_approved_at             DATETIME,
  order_delivered_carrier_date  DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME
);

-- ---------------------------------------------------------------------------------------
-- Order items
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_items (
  order_id                      VARCHAR(50),
  order_item_id                 INT,
  product_id                    VARCHAR(50),
  seller_id                     VARCHAR(50),
  shipping_limit_date           DATETIME,
  price                         DECIMAL(10, 2),
  freight_value                 DECIMAL(10, 2),
  PRIMARY KEY (order_id, order_item_id)
);

-- ---------------------------------------------------------------------------------------
-- Payments
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_payments (
  order_id                      VARCHAR(50),
  payment_sequential            INT,
  payment_type                  VARCHAR(30),
  payment_installments          INT,
  payment_value                 DECIMAL(10, 2),
  PRIMARY KEY (order_id, payment_sequential)
);

-- ---------------------------------------------------------------------------------------
-- Reviews
-- ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS order_reviews (
  review_id                     VARCHAR(50),
  order_id                      VARCHAR(50),
  review_score                  INT,
  review_comment_title          VARCHAR(200),
  review_comment_message        TEXT,
  review_creation_date          DATETIME,
  review_answer_timestamp       DATETIME,
  PRIMARY KEY (review_id)
);