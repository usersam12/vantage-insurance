## Vantage Insurance Brokers - Power BI Portfolio Project
A three-page dashboard built specifically for a non-technical audience without SQL experience to gain insights into complex commercial insurance data.

A download version of the report is available [Vantage Power BI Report](vantage_pbi.pbix) and as a viewable pdf [Vantage Power BI View](vantage_pbi_view.pdf).

### Key Questions
The dashboard addresses three questions a regional manager would ask on a weekly basis:

+ How is the overall book performing in terms of premium volume, loss ratio, and outstanding balances?
+ Which agents are driving the most premium, and where is claims exposure concentrated?
+ What does an individual client's policy and claims history look like?

### Report Pages

#### Page 1 - Overview

Executive summary of the full book of business intended to provide a high-level overview of brokerage health through overall premium values, loss ratio, and industry metrics.


#### Page 2 - Agent Performance

Book-of-business breakdown by agent which allows managers to conduct individual overviews of agent metrics.


#### Page 3 - Claims Overview
Drill-through destination from Page 2. Considering Vantage's weaknesses in underwriting, the claims overview is important for analytics directors to gain a broad understanding of individual accounts.

## Approach

### DAX Measures
Measures are organised in a dedicated _Measures table with display folders.

Premium

+ Total Active Premium Volume - sum of premium filtered to active policies
+ Total All Time Premium Volume - unfiltered premium sum
+ Sum of Premium YoY% - year-over-year growth using DATEADD time intelligence

Claims

+ Claims Volume - count and sum of claims
+ Claims Volume as a % of Premium - loss ratio per agent or client context
+ Claims % of Total Volume - industry share using ALL(clients[industry]) to remove filter context from the denominator
+ No Claims Message - returns a message string when no claims exist in the current filter context, used to populate a card visual over an empty bar chart

KPI

+ Loss Ratio - SUM(claims[amount_paid]) / SUM(policies[premium])
+ Outstanding Premium Balance - SUM(premiums_payments[amount_due]) floored at zero using IF(Balance > 0, Balance) to suppress negative values
+ Active Client Count - DISTINCTCOUNT(policies[client_id]) filtered to active policies
+ Policy Count Active - count of active policies

Navigation / UX

+ Claims Title Drill-down - uses SELECTEDVALUE(agents[agent_name]) to return a dynamic page title that updates when drilling through from the agent page, with a fallback for the unfiltered state

