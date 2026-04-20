-- =============================================================
-- DATA IMPORT & CLEANING
-- All numeric columns use NUMERIC to avoid rounding issues with FLOAT
-- =============================================================


-- =============================================================
-- 1. AGENTS
-- =============================================================

CREATE TABLE agents (
    agent_id    VARCHAR(10) PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    email       VARCHAR(100),
    phone       VARCHAR(30),
    region      VARCHAR(50),
    hire_date   VARCHAR(20),
    status      VARCHAR(20)
);

SELECT * FROM agents;


-- Remove duplicate agents
SELECT *
FROM agents
WHERE agent_id = 'A005'
   OR agent_id = 'A010';

DELETE FROM agents
WHERE agent_id = 'A005'
   OR agent_id = 'A010';


-- Preview reformatted phone numbers
SELECT
    regexp_replace(
        regexp_replace(
            regexp_replace(phone, '^\+?1', ''),  -- Step 1: strip leading +1 or 1
        '\D', '', 'g'),                           -- Step 2: strip remaining non-digits
    '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3')       -- Step 3: reformat
AS phone
FROM agents;

-- Apply phone number reformatting
UPDATE agents
SET phone =
    regexp_replace(
        regexp_replace(
            regexp_replace(phone, '^\+?1', ''),
        '\D', '', 'g'),
    '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3');


-- Fix malformed hire_date for A007, then standardise status casing and correct typo
UPDATE agents
SET hire_date = TO_DATE('03/14/2026', 'MM/DD/YYYY')
WHERE agent_id = 'A007';

UPDATE agents
SET status = INITCAP(status);

UPDATE agents
SET status = CASE WHEN status = 'Actve' THEN 'Active' ELSE status END;


-- Convert hire_date from VARCHAR to DATE
ALTER TABLE agents
ALTER COLUMN hire_date TYPE DATE USING hire_date::date;

SELECT * FROM agents;


-- =============================================================
-- 2. CLIENTS
-- =============================================================

CREATE TABLE IF NOT EXISTS clients (
    client_id       VARCHAR(10) PRIMARY KEY,
    company_name    VARCHAR(100),
    industry        VARCHAR(50),
    contact_name    VARCHAR(100),
    contact_email   VARCHAR(100),
    phone           VARCHAR(30),
    state           VARCHAR(20),
    agent_id        VARCHAR(10),
    since_date      VARCHAR(20),
    annual_revenue  NUMERIC
);

SELECT * FROM clients;


-- Remove duplicate clients
SELECT *
FROM clients
WHERE client_id = 'C002'
   OR client_id = 'C012';

DELETE FROM clients
WHERE client_id = 'C002'
   OR client_id = 'C012';


-- Fix misspelled industry value and standardise casing
UPDATE clients
SET industry = 'Manufacturing'
WHERE industry = 'Manufactoring';

UPDATE clients
SET industry = INITCAP(industry);


-- Preview reformatted phone numbers
SELECT
    regexp_replace(
        regexp_replace(
            regexp_replace(phone, '^\+?1', ''),  -- Step 1: strip leading +1 or 1
        '\D', '', 'g'),                           -- Step 2: strip remaining non-digits
    '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3')       -- Step 3: reformat
AS phone
FROM clients;

-- Apply phone number reformatting
UPDATE clients
SET phone =
    regexp_replace(
        regexp_replace(
            regexp_replace(phone, '^\+?1', ''),
        '\D', '', 'g'),
    '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3');


-- Preview and remove stray parentheses from state column
SELECT BTRIM(state, '()')
FROM clients;

UPDATE clients
SET state = BTRIM(state, '()');


-- Convert since_date from VARCHAR to DATE
ALTER TABLE clients
ALTER COLUMN since_date TYPE DATE USING since_date::date;

SELECT * FROM clients;

-- Backfill NULL contact fields with placeholder text
UPDATE clients
SET contact_name = 'No contact provided'
WHERE contact_name IS NULL;

UPDATE clients
SET contact_email = 'No email provided'
WHERE contact_email IS NULL;

UPDATE clients
SET phone = 'No phone provided'
WHERE phone IS NULL;

-- Reassign Coastal Pharma (C011) to Linda Okafor (A007)
UPDATE clients
SET agent_id = 'A007'
WHERE client_id = 'C011';

-- =============================================================
-- 3. POLICIES
-- =============================================================

CREATE TABLE policies (
    policy_id       VARCHAR(10) PRIMARY KEY,
    client_id       VARCHAR(10),
    policy_type     VARCHAR(50),
    carrier         VARCHAR(50),
    effective_date  VARCHAR(20),
    expiration_date VARCHAR(20),
    premium         NUMERIC,
    coverage_limit  NUMERIC,
    deductible      NUMERIC,
    status          VARCHAR(20)
);

SELECT * FROM policies;


-- Remove duplicate policy and fix status typo
DELETE FROM policies
WHERE policy_id = 'P003';

UPDATE policies
SET status = 'Expired'
WHERE status = 'Expirred';

UPDATE policies
SET status = INITCAP(status);

-- Backfill missing premium for P005
UPDATE policies
SET premium = '18750'
WHERE policy_id = 'P005';

-- Convert date columns from VARCHAR to DATE
ALTER TABLE policies
ALTER COLUMN effective_date  TYPE DATE USING effective_date::date,
ALTER COLUMN expiration_date TYPE DATE USING expiration_date::date;


-- =============================================================
-- 4. CLAIMS
-- =============================================================

CREATE TABLE IF NOT EXISTS claims (
    claim_id        VARCHAR(10) PRIMARY KEY,
    policy_id       VARCHAR(10),
    client_id       VARCHAR(10),
    date_of_loss    VARCHAR(20),
    date_reported   VARCHAR(20),
    claim_type      VARCHAR(50),
    amount_claimed  NUMERIC,
    amount_paid     NUMERIC,
    status          VARCHAR(20),
    adjuster_notes  TEXT
);

SELECT * FROM claims;


-- Fix malformed dates for CL003
UPDATE claims
SET date_of_loss  = TO_DATE('04/22/2023', 'MM/DD/YYYY'),
    date_reported = TO_DATE('04/22/2023', 'MM/DD/YYYY')
WHERE claim_id = 'CL003';


-- Convert date columns from VARCHAR to DATE
ALTER TABLE claims
ALTER COLUMN date_of_loss  TYPE DATE USING date_of_loss::date,
ALTER COLUMN date_reported TYPE DATE USING date_reported::date;


-- CL014: amount_claimed ($9,999,999) is a statistical outlier but retained as a legitimate CAT Loss
UPDATE claims
SET adjuster_notes = 'Hurricane Damage - CAT Loss'
WHERE claim_id = 'CL014';

-- Standardize claim_type values
UPDATE claims
SET claim_type = 'Cyber Breach'
WHERE claim_type = 'Cyber';

UPDATE claims
SET claim_type = 'General Liability'
WHERE claim_type = 'General Liabilty';

-- Remove duplicate claims, keeping the row with the lowest ctid
DELETE FROM claims
WHERE ctid IN (
    SELECT ctid
    FROM (
        SELECT
            ctid,
            ROW_NUMBER() OVER (
                PARTITION BY policy_id, date_of_loss, amount_claimed
                ORDER BY ctid
            ) AS rn
        FROM claims
    ) sub
    WHERE rn > 1
);


-- =============================================================
-- 5. PREMIUMS & PAYMENTS
-- =============================================================

CREATE TABLE IF NOT EXISTS premiums_payments (
    payment_id      VARCHAR(10) PRIMARY KEY,
    policy_id       VARCHAR(10),
    client_id       VARCHAR(10),
    due_date        VARCHAR(20),
    paid_date       VARCHAR(20),
    amount_due      NUMERIC,
    amount_paid     NUMERIC,
    payment_method  VARCHAR(30),
    status          VARCHAR(20)
);


-- Fix malformed due_date for PAY011
UPDATE premiums_payments
SET due_date = TO_DATE('August 19 2023', 'Month DD YYYY')
WHERE payment_id = 'PAY011';

UPDATE premiums_payments
SET status = INITCAP(status);

-- Backfill NULL amount_paid for C005 to 0
UPDATE premiums_payments
SET amount_paid = '0'
WHERE policy_id = 'P005';


-- Convert date columns from VARCHAR to DATE
ALTER TABLE premiums_payments
ALTER COLUMN due_date  TYPE DATE USING due_date::date,
ALTER COLUMN paid_date TYPE DATE USING paid_date::date;

SELECT * FROM premiums_payments;

SELECT * FROM claims;