## Vantage Insurance Brokers - Power BI Portfolio Project
A three-page dashboard built specifically for a non-technical audience without SQL experience to gain insights into complex commercial insurance data.

A download version of the report is available as a raw file "vantage_pbi.pbix", and a visual of the report is available as a PDF "vantage_new.pdf".

### Business Context
Vantage Insurance Brokers is a fictional commercial lines brokerage. The dashboard addresses three questions a regional manager would ask on a weekly basis:

How is the overall book performing in terms of premium volume, loss ratio, and outstanding balances?
Which agents are driving the most premium, and where is claims exposure concentrated?
What does an individual client's policy and claims history look like?

### DAX Measures
Measures are organised in a dedicated _Measures table with display folders.
Premium

Total Active Premium Volume - sum of premium filtered to active policies
Total All Time Premium Volume - unfiltered premium sum
Sum of Premium YoY% - year-over-year growth using DATEADD time intelligence

Claims

Claims Volume - count and sum of claims
Claims Volume as a % of Premium - loss ratio per agent or client context
Claims % of Total Volume - industry share using ALL(clients[industry]) to remove filter context from the denominator
No Claims Message - returns a message string when no claims exist in the current filter context, used to populate a card visual over an empty bar chart

KPI

Loss Ratio - SUM(claims[amount_paid]) / SUM(policies[premium])
Outstanding Premium Balance - SUM(premiums_payments[amount_due]) floored at zero using IF(Balance > 0, Balance) to suppress negative values
Active Client Count - DISTINCTCOUNT(policies[client_id]) filtered to active policies
Policy Count Active - count of active policies

Navigation / UX

Claims Title Drill-down - uses SELECTEDVALUE(agents[agent_name]) to return a dynamic page title that updates when drilling through from the agent page, with a fallback for the unfiltered state

### Report Pages

Page 1 - Overview
Executive summary of the full book of business.

KPI cards - Total Active Premium Volume, Active Policy Count, Outstanding Premium Balance, Loss Ratio
Line chart - Premium volume trend over time using the date hierarchy
Donut chart - Premium distribution by client industry
Treemap — Claims volume as a percentage of total, segmented by industry

Page 2 - Agent Performance
Book-of-business breakdown by agent.

Table - Agent name, active client count, total active premium volume, claims volume, claims as % of premium
Bar chart - Premium volume ranked by agent
Drill-through button — passes agent context to Page 3

Page 3 - Client & Policy Details
Drill-through destination from Page 2. Page title updates dynamically to show the selected agent's name.

KPI cards - Agent region, outstanding premium balance, loss ratio scoped to the selected agent.
Table - Client list with company name, industry, policy type, premium, and status.
Bar chart - Claims breakdown by claim ID and type, showing claims volume as % of premium with amount paid as a tooltip.
Slicer - Filters by dates between 1/1/2021 and 12/31/2024, as these are the use-case dates for Vantage.

### What I Would Add In The Future

As an individual on a personal account, gaining access to Power BI Service is challenging, but if I had access I would add row-level security to restrict each agent to their own book of business. Additionally the portfolio reader would have view-only access.