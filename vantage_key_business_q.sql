-- =============================================================
-- Author: Sam Zivin
-- Vantage Client Analysis
-- Key Business Questions
-- =============================================================


-- =============================================================
-- CLIENT & AGENT OVERVIEW
-- =============================================================

-- 1. How many active clients does each agent manage, and what is their total combined premium volume?
SELECT
    DISTINCT c.agent_id,
    a.first_name,
    a.last_name,
    COUNT(DISTINCT c.client_id) AS active_clients,
    SUM(p.premium)              AS premium_vol
FROM clients c
INNER JOIN policies p ON c.client_id = p.client_id
JOIN agents a         ON a.agent_id  = c.agent_id
WHERE p.status = 'Active'
GROUP BY c.agent_id, a.first_name, a.last_name
ORDER BY active_clients DESC, premium_vol DESC;


-- 2. Which clients have been with Vantage the longest, and what region is their agent in?
SELECT
    c.client_id,
    c.company_name,
    c.since_date,
    a.region
FROM clients c
LEFT JOIN agents a ON c.agent_id = a.agent_id
GROUP BY c.client_id, a.region
ORDER BY c.since_date;


-- 2b. Follow up: What is the premium volume for these clients?
SELECT
    c.client_id,
    c.company_name,
    c.since_date,
    a.region,
    SUM(p.premium) AS premium_volume
FROM clients c
LEFT JOIN agents a  ON c.agent_id  = a.agent_id
JOIN policies p     ON c.client_id = p.client_id
GROUP BY c.client_id, a.region
ORDER BY c.since_date
LIMIT 3;


-- 3. How many policies does each client carry, and what is their total premium spend?
SELECT
    c.company_name,
    p.client_id,
    COUNT(DISTINCT p.policy_id) AS policy_count,
    SUM(p.premium)              AS total_premium_spend
FROM policies p
LEFT JOIN clients c ON p.client_id = c.client_id
GROUP BY p.client_id, c.company_name
ORDER BY total_premium_spend DESC;


-- 3b. What type of policies does Coastal Pharma carry, and who is their agent?
SELECT
    c.company_name,
    c.agent_id,
    p.policy_type,
    p.coverage_limit,
    p.premium
FROM clients c
LEFT JOIN policies p ON p.client_id = c.client_id
WHERE c.company_name = 'Coastal Pharma';


-- 4. Which region generates the most total premium volume?
SELECT
    a.region,
    SUM(p.premium) AS total_premium_volume
FROM agents a
INNER JOIN clients c ON a.agent_id  = c.agent_id
LEFT JOIN policies p ON p.client_id = c.client_id
GROUP BY a.region
ORDER BY total_premium_volume DESC;


-- 5. How many clients does each agent have per industry?
SELECT
    a.first_name,
    a.last_name,
    c.agent_id,
    COUNT(DISTINCT c.client_id) AS client_count,
    c.industry
FROM clients c
LEFT JOIN agents a ON c.agent_id = a.agent_id
GROUP BY a.first_name, a.last_name, c.agent_id, c.industry
ORDER BY client_count DESC;


-- 6. Calculate the loss ratio grouped by agent while flagging agents by loss ratio
WITH agent_loss AS (
    SELECT
        a.first_name,
        a.last_name,
        a.agent_id,
        COALESCE(SUM(cl.amount_paid), 0) / NULLIF(SUM(p.premium), 0) * 100 AS loss_ratio
    FROM agents a
    JOIN clients c ON a.agent_id = c.agent_id
    JOIN policies p ON c.client_id = p.client_id
    LEFT JOIN claims cl ON p.policy_id = cl.policy_id
    GROUP BY a.first_name, a.last_name, a.agent_id
)
SELECT
    first_name,
    last_name,
    agent_id,
    ROUND(loss_ratio::NUMERIC, 2) AS loss_ratio,
    CASE
        WHEN loss_ratio <= 60 THEN 'Acceptable'
        WHEN loss_ratio <= 75 THEN 'Manager Review'
        ELSE                       'Unacceptable'
    END AS loss_ratio_flag
FROM agent_loss
ORDER BY loss_ratio DESC;
-- =============================================================
-- CLAIMS
-- =============================================================

-- 7. What is the total amount paid out in claims by policy type?
SELECT
    p.policy_type,
    COALESCE(SUM(cl.amount_paid), 0) AS total_paid
FROM policies p
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.policy_type;


-- 8. Which clients have had at least one denied claim?
SELECT DISTINCT
    c.company_name AS at_least_one_denied_claim,
    cl.claim_type
FROM claims cl
LEFT JOIN clients c ON cl.client_id = c.client_id
WHERE cl.status = 'Denied';


-- 9. What is the average time in days between date of loss and date reported, by claim type?
SELECT
    ROUND(ABS(AVG(date_reported - date_of_loss)), 1) AS days_loss_to_claim,
    claim_type
FROM claims
GROUP BY claim_type;


-- 10. Which policy type has the highest average claim payout?
SELECT
    p.policy_type,
    ROUND(AVG(cl.amount_paid), 2) AS avg_claim_payout
FROM claims cl
JOIN policies p ON cl.policy_id = p.policy_id
WHERE cl.amount_paid IS NOT NULL
GROUP BY p.policy_type
ORDER BY avg_claim_payout DESC;


-- 11. What percentage of total claims by volume are construction industry clients responsible for?
SELECT
    c.industry,
    COUNT(cl.claim_id)                                                      AS total_claims,
    ROUND(COUNT(cl.claim_id) * 100.0 / SUM(COUNT(cl.claim_id)) OVER(), 2) AS percentage_of_claims
FROM claims cl
LEFT JOIN clients c ON cl.client_id = c.client_id
GROUP BY c.industry
ORDER BY percentage_of_claims DESC;


-- =============================================================
-- PAYMENTS & PREMIUMS
-- =============================================================

-- 12. Which clients have an unpaid or partial premium balance?
SELECT
    client_id,
    (SUM(amount_due) - SUM(amount_paid)) AS balance
FROM premiums_payments
WHERE status = 'Unpaid'
   OR status = 'Partial'
GROUP BY client_id;


-- 13. What is the total outstanding balance across all unpaid policies?
SELECT
    (SUM(amount_due) - SUM(amount_paid)) AS total_outstanding
FROM premiums_payments
WHERE status = 'Unpaid'
   OR status = 'Partial';


-- 14. Which payment method is most commonly used, and what is the total volume processed by each?
SELECT
    payment_method,
    COUNT(payment_method) AS payment_counter,
    SUM(amount_paid)      AS total_volume
FROM premiums_payments
GROUP BY payment_method
ORDER BY total_volume;


-- =============================================================
-- DATA QUALITY
-- =============================================================

-- 15. Which clients have no assigned agent?
SELECT client_id
FROM clients
WHERE agent_id IS NULL;


-- 16. Flag missing contact details across all clients
SELECT
    company_name,
    COALESCE(contact_name,  'No contact provided')      AS contact_name,
    COALESCE(contact_email, 'No email provided')        AS email,
    COALESCE(phone,         'No phone number provided') AS phone,
    COALESCE(agent_id,      'No agent ID found')        AS agent_id
FROM clients;


-- 17. Are there any duplicate claims based on matching policy_id, date_of_loss, and amount_claimed?
WITH duplicates AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY policy_id, date_of_loss, amount_claimed
        ) AS row_num
    FROM claims
)
SELECT *
FROM duplicates
WHERE row_num > 1;