/*
Olist (Kaggle) – Schema Reset Script (DEV)

Purpose:
- Drops and recreates the `olist` database
- Creates the base tables used for importing the raw CSVs

When to run:
- Initial setup
- Rebuilding during import/debugging

Warning:
- This script permanently deletes the `olist` database and all objects inside it.
- Do not run if you need to preserve existing data.
*/

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

-- Customers
CREATE TABLE customers (
  customer_id VARCHAR(50) PRIMARY KEY,
  customer_unique_id VARCHAR(50),
  customer_zip_code_prefix INT,
  customer_city VARCHAR(100),
  customer_state CHAR(2)
);

-- Geolocation (large table)
CREATE TABLE geolocation (
  geolocation_zip_code_prefix INT,
  geolocation_lat DECIMAL(10, 7),
  geolocation_lng DECIMAL(10, 7),
  geolocation_city VARCHAR(100),
  geolocation_state CHAR(2)
);

-- Sellers
CREATE TABLE sellers (
  seller_id VARCHAR(50) PRIMARY KEY,
  seller_zip_code_prefix INT,
  seller_city VARCHAR(100),
  seller_state CHAR(2)
);

-- Product category translation
CREATE TABLE product_category_name_translation (
  product_category_name VARCHAR(100) PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);

-- Products
CREATE TABLE products (
  product_id VARCHAR(50) PRIMARY KEY,
  product_category_name VARCHAR(100),
  product_name_lenght INT,
  product_description_lenght INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
);

-- Orders
CREATE TABLE orders (
  order_id VARCHAR(50) PRIMARY KEY,
  customer_id VARCHAR(50),
  order_status VARCHAR(30),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME
);

-- Order items
CREATE TABLE order_items (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date DATETIME,
  price DECIMAL(10, 2),
  freight_value DECIMAL(10, 2),
  PRIMARY KEY (order_id, order_item_id)
);

-- Payments
CREATE TABLE order_payments (
  order_id VARCHAR(50),
  payment_sequential INT,
  payment_type VARCHAR(30),
  payment_installments INT,
  payment_value DECIMAL(10, 2),
  PRIMARY KEY (order_id, payment_sequential)
);

-- Reviews
CREATE TABLE order_reviews (
  review_id VARCHAR(50),
  order_id VARCHAR(50),
  review_score INT,
  review_comment_title VARCHAR(200),
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME,
  PRIMARY KEY (review_id)
);
