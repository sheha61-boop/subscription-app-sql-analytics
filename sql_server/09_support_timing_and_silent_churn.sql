-- Question 9: When do billing complaints and cancellations happen, and do
-- users complain before they leave?
-- Dialect: SQL Server (T-SQL), written for SSMS.

-- Part 1: billing complaints by day of the month.
--
-- Result (top rows):
-- | day_of_month | billing_complaints |
-- |--------------|--------------------|
-- | 2            | 421                |
-- | 1            | 340                |
-- | 3            | 305                |
-- | 4            | 127                |
-- | 20           | 31                 |
--
-- Renewals are charged on the 1st, and 69% of all billing complaints
-- (1193 of 1734) arrive on days 1-4. Support needs extra billing staff
-- at the start of each month.

SELECT
    DAY(created_ts) AS day_of_month,
    COUNT(*) AS billing_complaints
FROM support_tickets
WHERE category = 'billing_complaint'
GROUP BY DAY(created_ts)
ORDER BY billing_complaints DESC, day_of_month;

-- Part 2: the month-end date-filter trap.
-- created_ts includes a time, so BETWEEN '2026-07-01' AND '2026-07-31'
-- stops at 2026-07-31 00:00:00 and silently drops almost all of July 31.
-- Cancellation requests only arrive in the last ~5 days of each month
-- (just before the next charge), so they are hit hardest.
--
-- Result:
-- | category             | correct_filter | between_filter |
-- |----------------------|----------------|----------------|
-- | billing_complaint    | 785            | 775            |
-- | cancellation_request | 406            | 319            |
-- | bug_report           | 79             | 77             |
-- | feature_request      | 45             | 43             |
--
-- The BETWEEN version under-reports July cancellations by 21%.

SELECT
    category,
    SUM(CASE WHEN created_ts >= '2026-07-01' AND created_ts < '2026-08-01' THEN 1 ELSE 0 END) AS correct_filter,
    SUM(CASE WHEN created_ts BETWEEN '2026-07-01' AND '2026-07-31' THEN 1 ELSE 0 END) AS between_filter
FROM support_tickets
GROUP BY category
ORDER BY correct_filter DESC;

-- Part 3: silent churn. How many users asked to cancel without ever
-- filing a billing complaint?
--
-- Result:
-- | cancel_requesters | also_complained | silent_cancellers |
-- |-------------------|-----------------|-------------------|
-- | 917               | 105             | 812               |
--
-- 89% of users who asked to cancel never complained first. Complaints are
-- not an early-warning signal for most churn, so retention monitoring
-- should also watch behaviour (e.g. falling usage), not only tickets.

;WITH cancel_requesters AS (
    SELECT DISTINCT user_id
    FROM support_tickets
    WHERE category = 'cancellation_request'
),
also_complained AS (
    SELECT user_id FROM support_tickets WHERE category = 'cancellation_request'
    INTERSECT
    SELECT user_id FROM support_tickets WHERE category = 'billing_complaint'
),
silent_cancellers AS (
    SELECT user_id FROM support_tickets WHERE category = 'cancellation_request'
    EXCEPT
    SELECT user_id FROM support_tickets WHERE category = 'billing_complaint'
)
SELECT
    (SELECT COUNT(*) FROM cancel_requesters) AS cancel_requesters,
    (SELECT COUNT(*) FROM also_complained)   AS also_complained,
    (SELECT COUNT(*) FROM silent_cancellers) AS silent_cancellers;
