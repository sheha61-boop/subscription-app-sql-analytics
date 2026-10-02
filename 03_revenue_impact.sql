-- Question 3: How is monthly recurring revenue trending over time?
--
-- Company-wide monthly-plan revenue (all users, new signups included)
-- climbed every month through August -- looks like a clean win for the
-- price hike. But isolating just the pre-June signup cohort (the people
-- who actually experienced both the old and new price) shows revenue
-- peaking in June, then falling back to pre-hike (April) levels by
-- August: the price increase was a net wash for existing customers,
-- masked at the company level by continued new-customer acquisition.

-- All monthly-plan users (company-wide view)
SELECT
    SUM(amount) AS total_revenue,
    billing_period
FROM charges AS A
LEFT JOIN users AS B ON A.user_id = B.user_id
WHERE plan_type = 'monthly'
  AND status = 'succeeded'
GROUP BY billing_period
ORDER BY billing_period;

-- Same metric, isolated to the pre-June signup cohort only
SELECT
    SUM(amount) AS total_revenue,
    billing_period
FROM charges AS A
LEFT JOIN users AS B ON A.user_id = B.user_id
WHERE plan_type = 'monthly'
  AND status = 'succeeded'
  AND signup_ts < '2026-06-01'
GROUP BY billing_period
ORDER BY billing_period;
