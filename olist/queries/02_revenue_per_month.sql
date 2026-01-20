/*
Business Question:
- How much revenue do we generate per month (payments-based)?

Why it matters:
- Shows revenue trend over time and seasonality
- Lets us compare revenue trend vs order volume trend

Definition:
- Revenue = SUM(payment_value) from v_payments_clean
- Month = purchase month from v_orders_clean (order_purchase_timestamp)

Caveat:
- Dataset tail months may be incomplete
*/

USE olist;

-- Question: What is total payments-based revenue per purchase month? --

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM v_orders_clean AS o
INNER JOIN v_payments_clean AS p
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

/*===========================================================================================
    So what?
    - Revenue ramps through 2017 and peaks around Nov 2017 (holiday effect likely).
    - Early months in 2016 show very low revenue and missing months (data starts midstream / 
      tracking begins).
    - 2018-09 and 2018-10 are unusually low and likely reflect an incomplete dataset tail, not
      true demand collapse.
=============================================================================================*/
