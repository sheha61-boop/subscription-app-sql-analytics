-- Question 2: Is there a specific point where users commonly churn, and
-- does it line up with a business event (a price change)?
--
-- The monthly plan's price rose from $12.99 to $15.99 starting June 2026;
-- the annual plan (one lump-sum payment) was unaffected. Restricting to
-- users who signed up before the hike (so the same people are compared
-- before and after), monthly-plan active users fell 23.1% the month right
-- after the hike and stayed down, while annual-plan users only drifted
-- 3.9%-5.7% over the same months -- a normal decline, not a cliff.

WITH monthly_active_users AS (
    SELECT
        COUNT(DISTINCT B.user_id) AS total_users,
        plan_type,
        SUBSTR(event_ts, 1, 7) AS event_month
    FROM users AS A
    INNER JOIN usage_events AS B ON A.user_id = B.user_id
    WHERE signup_ts < '2026-06-01'
    GROUP BY plan_type, event_month
),
activity_per_month AS (
    SELECT
        total_users,
        plan_type,
        event_month,
        LAG(total_users) OVER (PARTITION BY plan_type ORDER BY event_month) AS prev_month_users
    FROM monthly_active_users
)
SELECT
    total_users,
    plan_type,
    event_month,
    prev_month_users,
    ROUND((total_users - prev_month_users) * 1.0 / prev_month_users * 100, 1) AS pct_change
FROM activity_per_month
ORDER BY plan_type, event_month;


-- Ruling out an alternative explanation #1: a general product-wide issue
-- (would have hit both plan types, not just monthly).
-- -> already shown by the annual-plan comparison above.

-- Ruling out an alternative explanation #2: a technical payment bug
-- (would show up as a spike in failed charges). Failed-charge rate for
-- monthly-plan users stayed flat around 5% through June/July -- no spike.

WITH failed_charges AS (
    SELECT
        COUNT(charge_id) AS total_charges,
        billing_period,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS fail_count
    FROM charges AS A
    LEFT JOIN users AS B ON A.user_id = B.user_id
    WHERE plan_type = 'monthly'
    GROUP BY billing_period
)
SELECT
    total_charges,
    billing_period,
    fail_count,
    ROUND(fail_count * 1.0 / total_charges * 100, 1) AS fail_rate_pct
FROM failed_charges
ORDER BY billing_period;
