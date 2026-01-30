# Olist Monthly Trend Pack

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

## Insights
- [INSIGHT] Late deliveries score on average 1.64 points lower than on-time deliveries (range 0.85–2.06, across 19 stable months; min_reviews=30).
