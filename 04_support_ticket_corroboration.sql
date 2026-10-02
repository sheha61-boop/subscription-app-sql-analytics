-- Question 4: Do support tickets corroborate the pattern found in
-- question 2?
--
-- 676 of 678 billing complaints in June, and 780 of 785 in July, came
-- from monthly-plan users specifically. Annual-plan users, whose price
-- never changed, generated only single-digit billing complaints across
-- the same months -- confirming the complaint spike (and the churn it
-- corresponds to) is concentrated on exactly the group the price hike
-- affected, not a broader, plan-agnostic issue.

-- Monthly-plan billing complaints by month
SELECT
    COUNT(ticket_id) AS total_tickets,
    SUBSTR(created_ts, 1, 7) AS ticket_month
FROM support_tickets AS A
LEFT JOIN users AS B ON A.user_id = B.user_id
WHERE ticket_month >= '2026-06'
  AND plan_type = 'monthly'
  AND category = 'billing_complaint'
GROUP BY ticket_month;

-- Annual-plan billing complaints by month, for comparison
SELECT
    COUNT(ticket_id) AS total_tickets,
    SUBSTR(created_ts, 1, 7) AS ticket_month
FROM support_tickets AS A
LEFT JOIN users AS B ON A.user_id = B.user_id
WHERE ticket_month >= '2026-06'
  AND plan_type = 'annual'
  AND category = 'billing_complaint'
GROUP BY ticket_month;
