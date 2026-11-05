-- Question 8: Which acquisition channel complains most about billing,
-- after removing duplicate tickets?
-- Dialect: SQL Server (T-SQL), written for SSMS.
--
-- Part 1: find duplicates. Some users opened the same kind of ticket twice
-- on the same day (e.g. user 3187: two billing complaints on 2026-06-01).
-- These count as one issue.
--
-- Result: 8 duplicate groups, all billing complaints.
-- 3068 tickets -> 3060 after de-duplication (billing: 1734 -> 1726).

SELECT
    user_id,
    category,
    CAST(created_ts AS date) AS ticket_date,
    COUNT(*) AS tickets
FROM support_tickets
GROUP BY user_id, category, CAST(created_ts AS date)
HAVING COUNT(*) > 1
ORDER BY user_id;

-- Part 2: keep the first ticket of each duplicate group (ROW_NUMBER), then
-- compare channels on two different measures:
--   complaint_rate_pct  = % of the channel's users who filed a billing complaint
--   complaint_share_pct = the channel's share of all complaining users
--
-- Result:
-- | channel     | users | complaining_users | complaint_rate_pct | complaint_share_pct |
-- |-------------|-------|-------------------|--------------------|---------------------|
-- | referral    | 3386  | 394               | 11.6               | 24.6                |
-- | organic     | 4466  | 506               | 11.3               | 31.5                |
-- | paid_search | 4894  | 485               | 9.9                | 30.2                |
-- | influencer  | 2254  | 219               | 9.7                | 13.7                |
--
-- Organic produces the most complaints (largest share) only because it is
-- a big channel. The rate is similar everywhere (9.7-11.6%), so the billing
-- problem is product-wide, not caused by one acquisition channel.

;WITH ranked_tickets AS (
    SELECT
        ticket_id,
        user_id,
        category,
        ROW_NUMBER() OVER (PARTITION BY user_id, category, CAST(created_ts AS date)
                           ORDER BY created_ts) AS rn
    FROM support_tickets
),
clean_tickets AS (
    SELECT ticket_id, user_id, category
    FROM ranked_tickets
    WHERE rn = 1
),
channel_counts AS (
    SELECT
        U.channel,
        COUNT(DISTINCT U.user_id) AS users,
        COUNT(DISTINCT T.user_id) AS complaining_users
    FROM users AS U
    LEFT JOIN clean_tickets AS T
        ON T.user_id = U.user_id
       AND T.category = 'billing_complaint'
    GROUP BY U.channel
)
SELECT
    channel,
    users,
    complaining_users,
    CAST(complaining_users * 100.0 / users AS decimal(5, 1)) AS complaint_rate_pct,
    CAST(complaining_users * 100.0 / SUM(complaining_users) OVER () AS decimal(5, 1)) AS complaint_share_pct
FROM channel_counts
ORDER BY complaint_rate_pct DESC;
