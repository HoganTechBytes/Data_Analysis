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


---

## SQL Join Notes (Conventions I’m Using)

These notes summarize the join conventions used throughout this project. The goal is **readability**, **consistency**, and **clarity**.

### Join Syntax & Formatting

- Use explicit joins (`JOIN ... ON ...`) instead of implicit joins in the `WHERE` clause.
- Prefer explicit join types for clarity (ex: `INNER JOIN`, `LEFT JOIN`).
- Indent joins and join conditions so multi-table queries stay readable.
- Capitalize SQL keywords (`SELECT`, `FROM`, `JOIN`, `WHERE`) to visually separate them from identifiers.

Example style:

```sql
SELECT
    o.order_id,
    p.payment_value
FROM v_orders_clean AS o
INNER JOIN v_payments_clean AS p
    ON p.order_id = o.order_id;
```

### Table Alias Conventions

Aliases keep join-heavy queries short and readable.

- Use short, meaningful aliases:
  - `o` = orders
  - `p` = payments
  - `oi` = order_items
  - `c` = customers
  - `pr` = products
  - `r` = reviews
- Stay consistent across queries (don’t switch alias names randomly).
- In simple single-table queries, aliases are optional.

### Join Column Conventions

- Use consistent foreign key naming whenever possible (`customer_id`, `order_id`, `product_id`).
- If columns overlap (ex: multiple tables have `id`), alias columns in the output:

```sql
SELECT
    c.customer_id AS customer_id,
    o.order_id AS order_id
FROM v_customers_clean AS c
INNER JOIN v_orders_clean AS o
    ON o.customer_id = c.customer_id;
```

### Many-to-Many Join Tables (General Pattern)

When a schema uses a bridge table for many-to-many relationships, common naming patterns include:

- `table1_table2` (often alphabetical), ex: `user_role`
- A relationship-based name, ex: `subscriptions`, `memberships`

---

## Project Status
✅ Dataset downloaded  
🔄 Importing into MySQL  
⏳ Business question queries in progress  
⏳ Dashboard build (Power BI / Tableau) planned



## Source
Dataset: Olist Brazilian E-Commerce Public Dataset (Kaggle)

> Note: This project is for learning and portfolio development. All data is public and non-proprietary.

