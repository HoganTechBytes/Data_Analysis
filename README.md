# Data Analysis Portfolio & Practice Repository

## Overview
This repository contains my **hands-on data analysis work**, focused on **SQL, relational databases, and analytical pipelines**, with supporting Python scripts, QA checks, and documentation.

The projects here reflect a **deliberate skill-refresh and portfolio-building effort**, emphasizing:
- clean, readable SQL
- realistic business questions
- reproducible workflows
- transparent reasoning and validation

Rather than showcasing only final results, this repository is designed to demonstrate **how I think through data problems**, structure analysis, and validate outputs.

---

## What This Repository Demonstrates
- Strong SQL fundamentals (joins, aggregations, filtering, window-style logic)
- Translating business questions into structured queries
- Building **clean semantic views** for downstream analytics
- Lightweight but meaningful **data quality checks**
- Professional workflow habits (Git, documentation, reproducibility)
- SQL → Python handoff for analysis and visualization

Some datasets and structures are inspired by public tutorials or sample datasets; however, **all queries, scripts, and analytical decisions are written and reasoned through manually**, with adjustments based on real-world analyst experience.

---

## Project Highlights

### 🟦 Parks & Recreation (SQL Fundamentals)
A lightweight, fictional dataset used to:
- practice core SQL concepts
- reinforce join behavior and aggregations
- translate informal questions into structured queries

This project emphasizes **query clarity and correctness** rather than scale.

### 🟩 Olist (E-commerce Analytics Pipeline)
A larger, real-world e-commerce dataset used to build:
- clean relational schemas
- analytics-focused indexes
- semantic “clean” views (`v_*_clean`)
- monthly trend analysis
- Python-based export, QA, and charting workflows

This project more closely reflects **production-style analytics work**, including:
- schema setup
- data validation
- time-series trend analysis
- SQL → Python handoff

---

## Repository Structure
```
Data_Analysis/
├── Parks_Rec/
│   ├── scripts/
│   │   └── pnr.sql
│   ├── queries/
│   │   ├── where.sql
│   │   ├── group.sql
│   │   ├── joins.sql
│   │   ├── case.sql
│   │   ├── subs.sql
│   │   └── questions.sql
│   ├── notes.md
│   └── README.md
│
├── olist/
│   ├── raw_data/
│   ├── scripts/
│   │   ├── 00_dev_reset_schema.sql
│   │   ├── 01_create_schema.sql
│   │   ├── 02_create_indexes.sql
│   │   ├── 03_import_data.sql
│   │   └── 04_clean_views.sql
│   ├── queries/
│   │   ├── 01_orders_per_month.sql
│   │   └── 02_revenue_per_month.sql
│   ├── python/
│   │   ├── scripts/
│   │   └── outputs/
│   └── README.md
│
└── README.md
```

---

## How to Use This Repository
- SQL scripts are written for **MySQL 8.0.44**
- Python scripts assume a local virtual environment and `.env`-based DB credentials
- Projects are designed to be read **top-down**, following script numbering where present

Each project README provides dataset-specific context and goals.

---

## Notes on Style & Intent
- Script numbering is intentional and reflects pipeline order
- Documentation favors clarity over verbosity
- QA checks are included to surface issues early, not to block execution
- This repository prioritizes **thinking, structure, and validation** over flashy visuals
