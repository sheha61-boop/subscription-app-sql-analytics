-- Question 1: Which acquisition channel retains users best?
--
-- Approach: build a cohort-retention curve per channel. For every user,
-- find every month they were active, express that month as "months since
-- signup" (0, 1, 2, ...), then count distinct active users per channel per
-- months-since-signup value.
--
-- Result (March 2026 signup cohort, normalized to each channel's own
-- month-0 count = 100%): referral retains 76% of its cohort by month 5,
-- organic 67%, paid_search 57%, influencer only 53%.

WITH activity_by_month AS (
    SELECT DISTINCT
        A.user_id,
        SUBSTR(signup_ts, 1, 7) AS signup_month,
        SUBSTR(event_ts, 1, 7) AS event_month,
        channel
    FROM users AS A
    LEFT JOIN usage_events AS B ON A.user_id = B.user_id
),
activity_since_signup AS (
    SELECT
        user_id,
        channel,
        signup_month,
        (CAST(SUBSTR(event_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(event_month, 6, 2) AS INTEGER))
      - (CAST(SUBSTR(signup_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(signup_month, 6, 2) AS INTEGER))
        AS months_since_signup
    FROM activity_by_month
)
SELECT
    COUNT(DISTINCT user_id) AS active_users,
    months_since_signup,
    channel
FROM activity_since_signup
WHERE signup_month = '2026-03'
  AND months_since_signup IS NOT NULL
GROUP BY months_since_signup, channel
ORDER BY channel, months_since_signup;

-- Drop the "WHERE signup_month = '2026-03'" filter (and add signup_month
-- back into the SELECT/GROUP BY) to see every signup cohort at once.
