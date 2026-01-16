# Olist E-Commerce Dataset (Kaggle)

## Overview
This folder contains work based on the **Olist Brazilian E-Commerce Public Dataset**, sourced from Kaggle.  
The goal of this project is to practice **real-world SQL analysis** using a multi-table dataset (customers, orders, payments, reviews, products, sellers, and shipping).

This dataset is commonly used in analytics portfolios because it supports realistic business questions such as:
- customer retention / repurchase behavior
- delivery performance and delays
- review score impact factors
- revenue and payment trends

---

## Customers Dataset (`olist_customers_dataset.csv`)
The customers dataset contains customer and location-related information. It is used to:
- link customers to their orders
- identify delivery locations by customer location fields
- distinguish individual purchases vs repeat customers

### Key Notes
- Each order is assigned to a **customer_id**
- The same person may have multiple orders, and may receive **different customer_id values** per order
- The `customer_unique_id` field allows identification of customers who placed multiple orders (repurchases)

---

## Data Schema
The dataset is relational and intended to be used through joins across multiple tables.
<img width="2486" height="1496" alt="image" src="https://github.com/user-attachments/assets/6f3297ad-958a-4d1a-b2fe-fc7ed7927e96" />


## Project Status
✅ Dataset downloaded  
🔄 Importing into MySQL  
⏳ Business question queries in progress  
⏳ Dashboard build (Power BI / Tableau) planned



## Source
Dataset: Olist Brazilian E-Commerce Public Dataset (Kaggle)

> Note: This project is for learning and portfolio development. All data is public and non-proprietary.

