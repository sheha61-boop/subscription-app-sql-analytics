# Subscription App: Retention & Pricing SQL Analysis

## About

This project analyzes a **simulated** subscription-app dataset (no real company, customers, or transactions) to find out what happened after a price increase: who left, when, how revenue held up, and what support tickets reveal.

It has two parts:

- **Part 1 (SQLite):** the original four-question case study, written up in **`Subscription_App_Case_Study.pdf`**.
- **Part 2 (SQL Server / T-SQL):** a deeper follow-up in the `sql_server/` folder, covering monthly churn, a cohort retention grid, MRR with annual plans spread correctly, ticket de-duplication, support timing and "silent" churn.

The dataset spans 2026-03-01 to 2026-08-31: 15,000 users who signed up through four acquisition channels (organic, referral, paid_search, influencer), on either a monthly or annual plan, across ios/android/web.

**See also:** [Power BI dashboard](https://github.com/sheha61-boop/subscription-app-powerbi-dashboard), the visual companion to this analysis, built on the same dataset.

## The story in one paragraph

In June 2026 the monthly plan's price rose from $12.99 to $15.99. Monthly-plan churn **doubled**, from 12-14% a month to 27-28%. The drop appears in **every** signup cohort in the same calendar month (July), which points to an event rather than normal decay. Billing complaints made up **61%** of all support tickets in June and July, almost all of them from monthly-plan users. A technical billing bug is ruled out: the failed-charge rate stayed flat at about 5%. Revenue still grew, because new signups outpaced churn, and that growth masked the problem at company level. Finally, **89% of users who asked to cancel never complained first**, so support tickets alone are a poor early-warning signal.

## Key Findings

### Part 1: original case study (SQLite)

- **Channel retention**: referral-acquired users retain 76% of their original cohort by month 5, versus 67% for organic, 57% for paid_search, and just 53% for influencer, a 23-point gap between best and worst channel.
- **Price-hike churn**: after the price rise, monthly-plan active users (pre-hike signup cohort) fell 23.1% the following month and stayed down, while annual-plan users (unaffected by the price change) declined only 3.9%-5.7% over the same period.
- **Ruled out alternative explanations**: a general product-wide issue would have hit annual users equally (it didn't), and a technical billing bug would show up as a spike in failed charges (the failed-charge rate stayed flat around 5% throughout).
- **Revenue impact**: company-wide monthly-plan revenue grew every month through August, but that growth came entirely from new signups. Revenue from the pre-hike cohort peaked the month of the hike, then fell back to its April level by August.
- **Support ticket corroboration**: 676 of 678 billing complaints in June, and 780 of 785 in July, came from monthly-plan users, confirming the complaint spike is concentrated on exactly the group the price hike affected.

### Part 2: SQL Server deep-dive

- **Churn doubled** (`05`): of monthly-plan users who paid in a given month, the share who did not pay the next month was 11.7% (March), 14.0% (April) and 12.5% (May), then jumped to **28.2%** (June) and **27.1%** (July).
- **Every cohort drops in July** (`06`): in the cohort grid, July is month 4 for the March cohort, month 3 for April, month 2 for May and month 1 for June. Each loses 18-22 points that month, against 5-9 points in a normal month.
- **MRR** (`07`): with annual plans counted as 1/12 per month, MRR grew from $23,708.62 (March) to $148,396.67 (August). The growth comes from new signups, so company-level revenue hides the churn.
- **Complaints are product-wide, not channel-specific** (`08`): after removing 8 same-day duplicate tickets, 9.7-11.6% of each channel's users filed a billing complaint. Organic produces the most complaints only because it's the largest channel.
- **Timing** (`09`): 69% of billing complaints arrive on days 1-4 of the month, right after renewals are charged on the 1st. Cancellation requests arrive only in the last ~5 days of each month, just before the next charge.
- **A date-filter trap** (`09`): filtering July with `BETWEEN '2026-07-01' AND '2026-07-31'` misses most of July 31, because timestamps include a time, and under-reports July cancellations by 21% (319 instead of 406).
- **Silent churn** (`09`): only 105 of 917 users who asked to cancel had filed a billing complaint. The other 812 (89%) left without complaining.

### Recommendations

1. Re-examine the June price increase for existing monthly subscribers (e.g. grandfathering or an annual-plan offer), since churn doubled for exactly that group.
2. Staff billing support for the first days of each month, and route end-of-month cancellation requests to a retention offer.
3. Don't rely on complaints to predict churn. Monitor behaviour, such as falling usage, for the silent majority.

## Files

| File | Description |
|---|---|
| `Subscription_App_Case_Study.pdf` | Part 1 write-up: executive summary, findings with charts, and recommendations |
| `01_channel_retention.sql` | Q1: which acquisition channel retains users best (cohort retention curve by channel) |
| `02_price_hike_churn.sql` | Q2: did the June 2026 price increase cause churn (monthly vs. annual comparison, plus a billing-bug check) |
| `03_revenue_impact.sql` | Q3: monthly revenue trend, company-wide and for the pre-hike cohort |
| `04_support_ticket_corroboration.sql` | Q4: whether support tickets corroborate the churn pattern |
| `sql_server/05_monthly_churn.sql` | Q5: month-by-month churn rate for monthly-plan users (self-referencing `NOT EXISTS`) |
| `sql_server/06_cohort_retention_grid.sql` | Q6: signup cohort × months-since-signup retention grid (pivot with `MAX(CASE WHEN ...)`) |
| `sql_server/07_mrr_trend.sql` | Q7: MRR with annual plans spread over 12 months (window frame `ROWS BETWEEN 11 PRECEDING`) |
| `sql_server/08_ticket_dedup_and_channel_complaints.sql` | Q8: duplicate-ticket detection, `ROW_NUMBER` de-duplication, complaint rate vs. share by channel |
| `sql_server/09_support_timing_and_silent_churn.sql` | Q9: complaints by day of month, the `BETWEEN` month-end trap, silent churn with `INTERSECT` / `EXCEPT` |
| `users.csv` | 15,000 users: signup date, acquisition channel, plan type, device OS |
| `usage_events.csv` | ~467,700 app usage events (app opens, content views, feature use) |
| `charges.csv` | ~32,900 billing charges: amount, billing period, success/failure status |
| `support_tickets.csv` | ~3,070 support tickets: category, resolution time |

Every SQL file starts with a comment block giving the business question, the definitions used, and the expected result table.

## How to run

**Part 1 (SQLite):** load the CSVs into a SQLite database, then run any of the `01`-`04` files:

```bash
sqlite3 subscription.db <<EOF
.mode csv
.import users.csv users
.import usage_events.csv usage_events
.import charges.csv charges
.import support_tickets.csv support_tickets
EOF

sqlite3 subscription.db < 01_channel_retention.sql
```

(The first import includes the CSV header row as a data row: delete that row from each table, or re-import with `--skip 1`, before trusting the counts.)

**Part 2 (SQL Server):** import the four CSVs into a SQL Server database (e.g. with the SSMS *Import Flat File* wizard) using these column types, then open any file in `sql_server/` and run it:

| Table | Columns |
|---|---|
| `users` | `user_id int` (PK), `signup_ts datetime2`, `channel nvarchar(50)`, `plan_type nvarchar(50)`, `device_os nvarchar(50)` |
| `charges` | `charge_id int` (PK), `user_id int`, `charge_ts datetime2`, `billing_period nvarchar(50)`, `amount decimal(10,2)`, `status nvarchar(50)` |
| `support_tickets` | `ticket_id int` (PK), `user_id int`, `created_ts datetime2`, `category nvarchar(50)`, `resolution_hours decimal(6,1)` |
| `usage_events` | `event_id int` (PK), `user_id int`, `event_ts datetime2`, `event_type nvarchar(50)` |

`amount` must be `decimal`, not `float`, or the money totals pick up rounding errors.

## Skills Demonstrated

- **Querying & joins:** multi-step CTEs, deliberate `INNER JOIN` vs. `LEFT JOIN` choices (including filters in `ON` vs. `WHERE`), anti-joins with `NOT EXISTS`, correlated and self-referencing subqueries
- **Window functions:** `ROW_NUMBER` for de-duplication, `LAG()` for month-over-month comparison, `SUM() OVER ()` for share of total, explicit `ROWS BETWEEN` frames for rolling 12-month revenue
- **Analytics patterns:** churn, cohort retention grids, MRR, conditional aggregation (`SUM(CASE WHEN ...)`), rate vs. share of total
- **Data cleaning:** duplicate detection (`GROUP BY ... HAVING COUNT(*) > 1`), integer-division avoidance (`* 100.0`), correct date-range filtering (`>=` / `<` instead of `BETWEEN` on timestamps)
- **Set operations:** `UNION` vs. `UNION ALL`, `INTERSECT`, `EXCEPT`
- **Dialects:** SQLite (Part 1) and SQL Server / T-SQL (Part 2), including where they differ (date functions, integer division, window-frame defaults)
