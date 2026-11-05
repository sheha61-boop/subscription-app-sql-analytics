-- Question 7: What is monthly recurring revenue (MRR), with annual plans
-- spread correctly across the year?
-- Dialect: SQL Server (T-SQL), written for SSMS.
--
-- Problem: an annual subscriber pays $119.99 once. Counting it as revenue
-- in that one month makes MRR spike and then vanish. MRR should count it
-- as $119.99 / 12 in each of the 12 months the plan covers.
--
-- Method: successful revenue per calendar month, split by plan. Annual cash
-- from the current month and the 11 before it (a 12-month window, written
-- as ROWS explicitly) is divided by 12 and added to monthly-plan revenue.
--
-- Result:
-- | revenue_month | monthly_plan_revenue | annual_mrr | total_mrr |
-- |---------------|----------------------|------------|-----------|
-- | 2026-03       | 18069.09             | 5639.53    | 23708.62  |
-- | 2026-04       | 37138.41             | 11589.03   | 48727.44  |
-- | 2026-05       | 55895.97             | 18148.49   | 74044.46  |
-- | 2026-06       | 90846.15             | 24657.95   | 115504.10 |
-- | 2026-07       | 100545.12            | 32077.33   | 132622.45 |
-- | 2026-08       | 108779.97            | 39616.70   | 148396.67 |
--
-- MRR keeps growing because new signups outpace churn, which is why
-- company-level revenue hides the churn shown in files 05 and 06.

;WITH monthly_revenue AS (
    SELECT
        FORMAT(C.charge_ts, 'yyyy-MM') AS revenue_month,
        SUM(CASE WHEN U.plan_type = 'monthly' THEN C.amount ELSE 0 END) AS monthly_plan_revenue,
        SUM(CASE WHEN U.plan_type = 'annual'  THEN C.amount ELSE 0 END) AS annual_cash
    FROM charges AS C
    JOIN users AS U ON U.user_id = C.user_id
    WHERE C.status = 'succeeded'
    GROUP BY FORMAT(C.charge_ts, 'yyyy-MM')
)
SELECT
    revenue_month,
    monthly_plan_revenue,
    CAST(SUM(annual_cash) OVER (ORDER BY revenue_month
                                ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) / 12
         AS decimal(12, 2)) AS annual_mrr,
    CAST(monthly_plan_revenue
         + SUM(annual_cash) OVER (ORDER BY revenue_month
                                  ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) / 12
         AS decimal(12, 2)) AS total_mrr
FROM monthly_revenue
ORDER BY revenue_month;
