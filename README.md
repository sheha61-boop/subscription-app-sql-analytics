# Subscription App: Retention & Pricing SQL Analysis

## About

This project analyzes a **simulated** subscription-app dataset (no real company, customers, or transactions) to answer four business questions about user retention, a price change, and its impact on revenue. The analysis was conducted entirely in SQL (SQLite) and is written up as a full case study in **`Subscription_App_Case_Study.pdf`**, included in this repo.

The dataset spans 2026-03-01 to 2026-08-31: 15,000 users who signed up through four acquisition channels (organic, referral, paid_search, influencer), on either a monthly or annual plan, across ios/android/web.

## Files

| File | Description |
|---|---|
| `Subscription_App_Case_Study.pdf` | The full write-up: executive summary, all four findings with charts, and recommendations |
| `01_channel_retention.sql` | Question 1: which acquisition channel retains users best (cohort retention curve by channel) |
| `02_price_hike_churn.sql` | Question 2: did the June 2026 price increase cause churn (monthly vs. annual plan comparison, plus a check ruling out a technical billing bug) |
| `03_revenue_impact.sql` | Question 3: how monthly recurring revenue trended, both company-wide and isolated to the pre-hike customer cohort |
| `04_support_ticket_corroboration.sql` | Question 4: whether support tickets corroborate the churn pattern found in question 2 |
| `data/users.csv` | 15,000 users: signup date, acquisition channel, plan type, device OS |
| `data/usage_events.csv` | ~467,700 app usage events (app opens, content views, feature use) |
| `data/charges.csv` | ~32,900 billing charges: amount, billing period, success/failure status |
| `data/support_tickets.csv` | ~3,070 support tickets: category, resolution time |

## How to run

Load the CSVs into a SQLite database, then run any of the `.sql` files against it:

```bash
sqlite3 subscription.db <<EOF
.mode csv
.import data/users.csv users
.import data/usage_events.csv usage_events
.import data/charges.csv charges
.import data/support_tickets.csv support_tickets
EOF

sqlite3 subscription.db < 01_channel_retention.sql
```

(Each `.sql` file's first import run will include the CSV header row as a data row — delete that row from each table, or re-import with `--skip 1`, before trusting the counts.)

## Key Findings

- **Channel retention**: referral-acquired users retain 76% of their original cohort by month 5, versus 67% for organic, 57% for paid_search, and just 53% for influencer — a 23-point gap between best and worst channel.
- **Price-hike churn**: after the monthly plan's price rose from $12.99 to $15.99 in June 2026, monthly-plan active users (pre-hike signup cohort) fell 23.1% the following month and stayed down, while annual-plan users (unaffected by the price change) declined only 3.9%-5.7% over the same period.
- **Ruled out alternative explanations**: a general product-wide issue would have hit annual users equally (it didn't), and a technical billing bug would show up as a spike in failed charges (the failed-charge rate stayed flat around 5% throughout).
- **Revenue impact**: company-wide monthly-plan revenue grew every month through August, but that growth came entirely from new signups. Revenue from the pre-hike cohort specifically peaked the month of the hike, then fell back to its pre-hike (April) level by August — a net wash for existing customers, masked by new customer acquisition.
- **Support ticket corroboration**: 676 of 678 billing complaints in June, and 780 of 785 in July, came from monthly-plan users specifically — confirming the complaint spike (and the churn) is concentrated on exactly the group the price hike affected.

## Skills Demonstrated

CTEs (multi-step cohort construction), window functions (`LAG()` for month-over-month comparison within partitions), conditional aggregation (`SUM(CASE WHEN...)` for rate calculations), multi-table joins with deliberate `INNER JOIN` vs. `LEFT JOIN` choices, date arithmetic for cohort-relative time, and float-division handling to avoid integer-division truncation bugs.
