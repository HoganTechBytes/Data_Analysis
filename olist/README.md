# Olist E-Commerce Analytics Project

## Overview
This project is based on the **Olist Brazilian E-Commerce Public Dataset** (Kaggle) and is used to practice **real-world analytics workflows** on a multi-table relational dataset.

The focus is not only on writing SQL queries, but on building a complete analytics workflow:
- designing analytics-friendly schemas
- creating clean semantic views
- validating results with lightweight QA checks
- handing results off to Python for downstream analysis and visualization

The dataset supports realistic business questions around:
- order and revenue trends
- delivery performance and delays
- customer experience and review scores
- payment behavior

---

## Primary Deliverables

This project produces a **monthly trend pack** intended for direct review.

Key outputs:
- `python/outputs/trend_pack.md` — consolidated monthly findings, QA notes, and insights
- `python/outputs/charts/` — versioned PNG charts referenced by the trend pack

These outputs are committed intentionally as portfolio artifacts and can be reviewed
without running the code.

## Dataset Context
The Olist dataset includes multiple related tables covering the full e-commerce lifecycle, including:
- customers
- orders
- order items
- payments
- reviews
- products
- sellers
- shipping and delivery timestamps

Rather than querying raw tables directly, this project emphasizes **clean, analytics-oriented views** that simplify joins and reduce downstream complexity.

---

## Relational Schema
The dataset is fully relational and designed to be analyzed through joins across multiple tables.

![Olist schema](https://github.com/user-attachments/assets/6f3297ad-958a-4d1a-b2fe-fc7ed7927e96)

---

## Schema & View Design

### Clean Semantic Views (`v_*_clean`)
To support consistent analysis, the project defines a set of **clean views** that:
- standardize column naming
- normalize date handling
- expose commonly used derived fields (e.g., delivery status, lateness flags)
- reduce repetitive join logic in analytical queries

These views act as the **semantic layer** for all downstream SQL and Python analysis.

---

## SQL Style & Join Conventions

### Join Syntax & Formatting
Throughout the project, SQL is written with an emphasis on **readability and consistency**:

- Use explicit joins (`INNER JOIN`, `LEFT JOIN`) rather than implicit joins.
- Indent joins and conditions to keep multi-table queries readable.
- Capitalize SQL keywords to visually separate logic from identifiers.

Example:
```sql
SELECT
    o.order_id,
    p.payment_value
FROM v_orders_clean AS o
INNER JOIN v_payments_clean AS p
    ON p.order_id = o.order_id;
```

### Table Alias Conventions
Aliases are used consistently to keep queries concise:

- `o`  = orders  
- `oi` = order_items  
- `p`  = payments  
- `c`  = customers  
- `pr` = products  
- `r`  = reviews  

Aliases are optional for simple single-table queries but are standard for joins.

### Join Column Conventions
- Foreign keys use consistent naming (`order_id`, `customer_id`, `product_id`).
- When column names overlap, output columns are explicitly aliased:

```sql
SELECT
    c.customer_id AS customer_id,
    o.order_id AS order_id
FROM v_customers_clean AS c
INNER JOIN v_orders_clean AS o
    ON o.customer_id = c.customer_id;
```

---

## Analytics Workflow

### SQL Analysis
Business-question-driven SQL queries live in `queries/` and focus on:
- monthly order and revenue trends
- delivery performance metrics
- review score relationships

These queries are written against clean views and are designed to be **portfolio-ready**.

### Python Pipeline
Results are exported and validated using Python scripts that:
- connect to MySQL via SQLAlchemy
- export query results to CSV
- run lightweight QA checks (schema, nulls, grain, continuity)
- prepare data for visualization and dashboards

Script numbering reflects pipeline order and execution flow.

### Charts & Insights

The Python charting layer generates **versioned, reproducible PNG charts** that are
committed directly to the repository as portfolio artifacts.

Current charts include:
- Revenue per month (delivered orders only)
- Orders vs delivered rate trends
- Late delivery rate over time
- Average review score: late vs on-time deliveries

Each chart:
- Applies minimum-volume thresholds to avoid misleading sparsity
- Logs QA notes when data is filtered
- Emits concise, text-based insights alongside visual output

Example insight:
> Late deliveries score on average ~1.6 points lower than on-time deliveries across stable months.

Metric coverage varies slightly by chart due to delivered-only filters and review
availability, which is documented in QA notes within the trend pack.


---

## Project Status
- ✔ Dataset imported into MySQL  
- ✔ Schema and clean views defined  
- ✔ Core business queries implemented  
- ✔ SQL → Python export pipeline complete  
- ✔ Charting pipeline implemented (Python / Matplotlib)  
- ✔ QA-gated trend visualizations generated and committed
- ⏳ Dashboard layer (Power BI / Excel / notebook) optional / future  

---

## How to Run (Optional)

This project uses a local Python virtual environment.

High-level flow:
1. Create and activate a `.venv`
2. Install dependencies from `requirements.txt`
3. Run SQL extracts against the MySQL Olist database
4. Execute the Python trend pack scripts

The primary review artifacts are already committed and do not require local execution.

## Source
Dataset: **Olist Brazilian E-Commerce Public Dataset (Kaggle)**

> This project is for learning and portfolio development. All data used is public and non-proprietary.
