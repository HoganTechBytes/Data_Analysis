# Data Analysis Practice Repository

## Overview
This repository contains my **hands-on data analysis practice work**, primarily focused on **SQL** and **relational database concepts**, with supporting analysis and documentation.

The projects here are part of a **deliberate skill-polishing effort**, following along with a public YouTube tutorial series while:
- Writing queries myself
- Adjusting schemas where appropriate
- Applying real-world reasoning from prior analyst experience
- Version-controlling all work for clarity and reproducibility

This repository is intended to demonstrate **how I think with data**, not just final outputs.

---

## Purpose of This Repository
- Refresh and strengthen SQL fundamentals (joins, aggregations, filtering)
- Rebuild analyst fluency after time away from academic SQL work
- Practice professional workflows (scripts, Git, documentation)
- Create transparent, reviewable artifacts suitable for discussion with potential employers

While the structure and datasets are guided by a tutorial, **all SQL is typed, run, and reasoned through manually**, with notes and adjustments based on best practices.

---

## Current Focus Areas
- Relational database design
- INNER, LEFT, and OUTER join behavior
- Translating business questions into SQL queries
- Writing readable, maintainable SQL scripts
- Using Git for versioned analytical work

---

## Repository Structure
```
DData_Analysis/
├── Parks_Rec/
│   ├── scripts/
│   │   └── pnr.sql                    # Database creation + seed data
│   ├── queries/                       # Practice + analysis queries
│   │   ├── where.sql                  # Filtering patterns using WHERE clauses
│   │   ├── group.sql                  # Aggregations using GROUP BY + ORDER BY
│   │   ├── joins.sql                  # Join practice across related tables
│   │   ├── case.sql                   # CASE statements + conditional logic
│   │   ├── subs.sql                   # Subquery practice
│   │   └── questions.sql              # Business-question style queries
│   ├── notes.md                       # Observations + learning notes
│   └── README.md                      # Project overview
│
├── olist/
│   ├── raw_data/                      # Original Kaggle CSVs (ignored by git)
│   ├── scripts/                       # Schema + import + view setup scripts
│   │   ├── 00_dev_reset_schema.sql    # DEV reset (drop/recreate schema)
│   │   ├── 01_create_schema.sql       # Table creation
│   │   ├── 02_create_indexes.sql      # Indexes for analytics joins
│   │   ├── 03_import_data.sql         # CSV import into MySQL
│   │   └── 04_clean_views.sql         # Clean semantic views (v_*_clean)
│   ├── queries/                       # Business-question queries (portfolio-ready)
│   │   ├── 01_orders_per_month.sql    # Orders trend + delivered rate
│   │   └── 02_revenue_per_month.sql   # Revenue trend (payments-based)
│   └── README.md                      # Dataset overview + goals
│
└── README.md                          # Main repo overview