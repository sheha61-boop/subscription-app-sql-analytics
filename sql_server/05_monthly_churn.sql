-- Question 5: How did monthly-plan churn change around the June 2026 price increase?
-- Dialect: SQL Server (T-SQL), written for SSMS.
--
-- Definition: a monthly-plan user is "active" in a month if they have a
-- successful charge that month. They "churned" if they were active in a
-- month and have NO successful charge in the following month.
--
-- Method: one row per user per active month (DISTINCT), a self-referencing
-- NOT EXISTS check against the next month, then SUM of the 0/1 flag.
-- The flag is built in its own CTE because SQL Server does not allow a
-- subquery inside an aggregate (Msg 130).
--
-- Result:
-- | active_month | active_users | churned_next_month | churn_rate_pct |
-- |--------------|--------------|--------------------|----------------|
-- | 2026-03      | 1391         | 163                | 11.7           |
-- | 2026-04      | 2840         | 397                | 14.0           |
-- | 2026-05      | 4279         | 535                | 12.5           |
-- | 2026-06      | 5669         | 1597               | 28.2           |
-- | 2026-07      | 6267         | 1699               | 27.1           |
--
-- Churn roughly doubled (12-14% -> 27-28%) for users who paid the new
-- $15.99 price in June. August is excluded: the data ends in August, so
-- "no charge next month" cannot be observed yet.

;WITH active AS (
    SELECT DISTINCT
        C.user_id,
        FORMAT(C.charge_ts, 'yyyy-MM') AS active_month,
        FORMAT(DATEADD(month, 1, C.charge_ts), 'yyyy-MM') AS next_month
    FROM charges AS C
    JOIN users AS U ON U.user_id = C.user_id
    WHERE C.status = 'succeeded'
      AND U.plan_type = 'monthly'
),
churn_flags AS (
    SELECT
        A.user_id,
        A.active_month,
        CASE WHEN NOT EXISTS (
                 SELECT 1
                 FROM active AS N
                 WHERE N.user_id = A.user_id
                   AND N.active_month = A.next_month
             ) THEN 1 ELSE 0 END AS churned
    FROM active AS A
)
SELECT
    active_month,
    COUNT(*) AS active_users,
    SUM(churned) AS churned_next_month,
    CAST(SUM(churned) * 100.0 / COUNT(*) AS decimal(5, 1)) AS churn_rate_pct
FROM churn_flags
WHERE active_month < '2026-08'
GROUP BY active_month
ORDER BY active_month;
