# Olist Monthly Trend Pack

Monthly trend pack using the Olist dataset. The goal is simple: QA-checked metrics, clean charts, and clear, actionable takeaways.

## Executive Summary
- [INSIGHT][revenue] Revenue is the north-star trend line. Interpret month-to-month changes alongside order volume and delivered rate to separate demand shifts from fulfillment issues.
- [INSIGHT][orders] If order volume holds steady but delivered rate drops, the story is likely operational (fulfillment/logistics) rather than demand.

## Metric Definitions
- **Revenue (delivered only):** Sum of payment value for delivered orders
- **Delivered rate:** delivered_orders / total_orders
- **Late delivery rate:** late_delivered_orders / delivered_orders (is_late=1)
- **Review score (avg):** Average review score split into late vs on-time groups

## Generated Charts
- outputs/charts/01_revenue_per_month.png
- outputs/charts/02_orders_and_delivered_rate.png
- outputs/charts/03_late_delivery_rate.png
- outputs/charts/04_review_score_late_vs_on_time.png

## Thresholds / Filters
- Orders chart: total_orders >= 100
- Late delivery chart: delivered_orders >= 100
- Review chart: min_reviews = 30 for both late/on-time
- Revenue chart: no min-volume filter applied

## QA Notes
- [QA NOTE] orders chart: dropped 4 sparse month rows (total_orders < 100).
- [QA NOTE] late delivery chart: dropped 2 sparse month rows (delivered_orders < 100).
- [QA NOTE] review score chart: dropped 4 months where either group had review_count < 30.

# Chart Notes & Insights

## 01) Revenue per Month (Delivered Orders Only)
**Chart:** outputs/charts/01_revenue_per_month.png  
**QA gate:** none (baseline visibility)

**So what**
- [INSIGHT][revenue] Revenue is the north-star trend line. Interpret month-to-month changes alongside order volume and delivered rate to separate demand shifts from fulfillment issues.

**Follow-up question**
- If revenue changes, is it driven by order volume, average order value, or payment mix?

## 02) Orders per Month + Delivered Rate
**Chart:** outputs/charts/02_orders_and_delivered_rate.png  
**QA gate:** total_orders >= 100

**So what**
- [INSIGHT][orders] If order volume holds steady but delivered rate drops, the story is likely operational (fulfillment/logistics) rather than demand.

**Follow-up question**
- When delivered rate dips, are those months concentrated in certain seller states or categories?

## 03) Late Delivery Rate (Delivered Orders Only)
**Chart:** outputs/charts/03_late_delivery_rate.png  
**QA gate:** delivered_orders >= 100

**So what**
- [INSIGHT][late] Late delivery rate is a controllable experience metric. Sustained increases often precede weaker reviews and repeat-purchase risk, especially if concentrated in key sellers/categories.

**Follow-up question**
- Are late deliveries driven by specific sellers, shipping distance, or category handling time?

## 04) Avg Review Score - Late vs On-Time
**Chart:** outputs/charts/04_review_score_late_vs_on_time.png  
**QA gate:** min_reviews = 30 for both groups

**So what**
- [INSIGHT] Late deliveries score on average 1.64 points lower than on-time deliveries (range 0.85-2.06, across 19 stable months; min_reviews=30).

**Follow-up question**
- What's the review 'breakpoint' (e.g., after how many days late do reviews drop sharply)?

## Reproducibility
- Source extract script: scripts/01_monthly_trend_pack.py
- Chart + report generator: scripts/02_monthly_trend_charts.py
- Outputs: outputs/charts/ and outputs/trend_pack.md
