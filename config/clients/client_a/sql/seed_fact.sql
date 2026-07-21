-- =============================================================================
-- seed_fact.sql — Fact table inserts (run on a schedule / interval)
-- Simulates live transactional activity — safe to run repeatedly.
-- Recommended interval: every 5-15 minutes during demo
--
-- Tables updated each run:
--   gl_transactions        → new revenue + expense rows
--   k1_distributions       → updated allocations
--   tax_adjustments        → new/updated book-to-tax items
--   estimated_tax_payments → new quarterly payments
--   billing_engagements    → new engagements + hours logged
-- =============================================================================

PRINT '--- Fact insert run: ' + CONVERT(VARCHAR, GETDATE(), 120) + ' ---';

-- -----------------------------------------------------------------------------
-- 1. GL Transactions — new revenue + expense rows every run
-- -----------------------------------------------------------------------------
INSERT INTO dbo.gl_transactions
    (entity_id, transaction_date, fiscal_year, fiscal_quarter,
     account_code, account_name, account_type,
     debit_amount, credit_amount, description, reference_no)
SELECT
    e.entity_id,
    CAST(GETDATE() AS DATE),
    YEAR(GETDATE()),
    DATEPART(QUARTER, GETDATE()),
    v.account_code,
    v.account_name,
    v.account_type,
    v.debit_amount,
    v.credit_amount,
    v.description + ' [' + CONVERT(VARCHAR, GETDATE(), 120) + ']',
    'REF-' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + '-' + e.entity_code + '-' + v.account_code
FROM (VALUES
    -- Revenue
    ('ALPHA-LLC',   '4000', 'Consulting Revenue',      'REVENUE', 0.00,                            ROUND(RAND() * 50000 + 10000, 2), 'Monthly consulting revenue'),
    ('BETA-SCORP',  '4100', 'Service Revenue',         'REVENUE', 0.00,                            ROUND(RAND() * 30000 + 5000,  2), 'Service billing revenue'),
    ('GAMMA-PTNR',  '4200', 'Rental Income',           'REVENUE', 0.00,                            ROUND(RAND() * 20000 + 8000,  2), 'Property rental income'),
    ('DELTA-CCORP', '4300', 'Software License Rev',    'REVENUE', 0.00,                            ROUND(RAND() * 40000 + 15000, 2), 'SaaS license revenue'),
    -- Expenses
    ('ALPHA-LLC',   '6000', 'Salaries & Wages',        'EXPENSE', ROUND(RAND() * 25000 + 8000, 2), 0.00,                            'Payroll run'),
    ('BETA-SCORP',  '6100', 'Contractor Expense',      'EXPENSE', ROUND(RAND() * 10000 + 2000, 2), 0.00,                            'Contractor payments'),
    ('GAMMA-PTNR',  '6200', 'Property Maintenance',    'EXPENSE', ROUND(RAND() * 5000  + 1000, 2), 0.00,                            'Maintenance costs'),
    ('DELTA-CCORP', '6300', 'Cloud Infrastructure',    'EXPENSE', ROUND(RAND() * 8000  + 2000, 2), 0.00,                            'AWS/Azure costs'),
    ('ALPHA-LLC',   '6400', 'Professional Fees',       'EXPENSE', ROUND(RAND() * 3000  + 500,  2), 0.00,                            'Legal & accounting'),
    ('BETA-SCORP',  '6500', 'Travel & Entertainment',  'EXPENSE', ROUND(RAND() * 2000  + 200,  2), 0.00,                            'Business travel')
) v (entity_code, account_code, account_name, account_type, debit_amount, credit_amount, description)
JOIN dbo.business_entities e ON e.entity_code = v.entity_code;

PRINT 'gl_transactions: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows inserted';

-- -----------------------------------------------------------------------------
-- 2. K-1 Distributions — update draft allocations each run
-- -----------------------------------------------------------------------------
MERGE dbo.k1_distributions AS target
USING (
    SELECT p.partner_id, e.entity_id, peo.ownership_pct
    FROM dbo.partner_entity_ownership peo
    JOIN dbo.partners p             ON p.partner_id = peo.partner_id
    JOIN dbo.business_entities e    ON e.entity_id  = peo.entity_id
    WHERE peo.effective_to IS NULL
) AS source ON target.partner_id = source.partner_id
           AND target.entity_id  = source.entity_id
           AND target.tax_year   = 2025
WHEN MATCHED AND target.status = 'DRAFT' THEN
    UPDATE SET
        ordinary_income  = ROUND(source.ownership_pct / 100 * (RAND() * 500000 + 100000), 2),
        guaranteed_pymts = ROUND(source.ownership_pct / 100 * (RAND() * 50000  + 10000),  2),
        capital_gains    = ROUND(source.ownership_pct / 100 * (RAND() * 80000  + 5000),   2),
        distributions    = ROUND(source.ownership_pct / 100 * (RAND() * 200000 + 50000),  2),
        ending_capital   = ROUND(source.ownership_pct / 100 * (RAND() * 300000 + 80000),  2),
        updated_at       = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (entity_id, partner_id, tax_year, ordinary_income, guaranteed_pymts,
            capital_gains, distributions, ending_capital, status)
    VALUES (source.entity_id, source.partner_id, 2025,
            ROUND(source.ownership_pct / 100 * (RAND() * 500000 + 100000), 2),
            ROUND(source.ownership_pct / 100 * (RAND() * 50000  + 10000),  2),
            ROUND(source.ownership_pct / 100 * (RAND() * 80000  + 5000),   2),
            ROUND(source.ownership_pct / 100 * (RAND() * 200000 + 50000),  2),
            ROUND(source.ownership_pct / 100 * (RAND() * 300000 + 80000),  2),
            'DRAFT');

PRINT 'k1_distributions: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 3. Tax Adjustments — add new book-to-tax items each run
-- -----------------------------------------------------------------------------
INSERT INTO dbo.tax_adjustments
    (entity_id, period_id, adjustment_type, book_amount, tax_amount, notes)
SELECT
    e.entity_id,
    fp.period_id,
    v.adjustment_type,
    ROUND(RAND() * 20000 + 1000, 2),
    ROUND(RAND() * 18000 + 800,  2),
    v.notes + ' — calculated ' + CONVERT(VARCHAR, GETDATE(), 120)
FROM (VALUES
    ('ALPHA-LLC',   2025, 'Federal', 'DEPRECIATION',   'Section 168 bonus depreciation'),
    ('BETA-SCORP',  2025, 'Federal', 'MEALS',          '50% meals disallowance'),
    ('GAMMA-PTNR',  2025, 'Federal', 'HOME_OFFICE',    'Partner home office deduction'),
    ('DELTA-CCORP', 2025, 'Federal', '179_DEDUCTION',  'Section 179 equipment deduction'),
    ('ALPHA-LLC',   2025, 'Federal', 'STOCK_COMP',     'Stock compensation adjustment')
) v (entity_code, tax_year, filing_type, adjustment_type, notes)
JOIN dbo.business_entities e  ON e.entity_code  = v.entity_code
JOIN dbo.tax_filing_periods fp ON fp.entity_id  = e.entity_id
                               AND fp.tax_year   = v.tax_year
                               AND fp.filing_type = v.filing_type
WHERE RAND() > 0.4;     -- insert ~60% of adjustment types each run

PRINT 'tax_adjustments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows inserted';

-- -----------------------------------------------------------------------------
-- 4. Estimated Tax Payments — add/update quarterly payments
-- -----------------------------------------------------------------------------
MERGE dbo.estimated_tax_payments AS target
USING (
    SELECT p.partner_id, e.entity_id, v.tax_year, v.quarter, v.due_date
    FROM (VALUES
        ('P001', 'ALPHA-LLC',   2025, 1, '2025-04-15'),
        ('P001', 'ALPHA-LLC',   2025, 2, '2025-06-16'),
        ('P001', 'ALPHA-LLC',   2025, 3, '2025-09-15'),
        ('P002', 'BETA-SCORP',  2025, 1, '2025-04-15'),
        ('P002', 'BETA-SCORP',  2025, 2, '2025-06-16'),
        ('P002', 'BETA-SCORP',  2025, 3, '2025-09-15'),
        ('P003', 'GAMMA-PTNR',  2025, 1, '2025-04-15'),
        ('P003', 'GAMMA-PTNR',  2025, 2, '2025-06-16'),
        ('P004', 'ALPHA-LLC',   2025, 1, '2025-04-15'),
        ('P005', 'DELTA-CCORP', 2025, 1, '2025-04-15'),
        ('P005', 'DELTA-CCORP', 2025, 2, '2025-06-16')
    ) v (partner_code, entity_code, tax_year, quarter, due_date)
    JOIN dbo.partners p           ON p.partner_code = v.partner_code
    JOIN dbo.business_entities e  ON e.entity_code  = v.entity_code
) AS source ON target.partner_id = source.partner_id
           AND target.entity_id  = source.entity_id
           AND target.tax_year   = source.tax_year
           AND target.quarter    = source.quarter
WHEN NOT MATCHED THEN
    INSERT (partner_id, entity_id, tax_year, quarter, due_date,
            federal_amount, state_amount, status)
    VALUES (source.partner_id, source.entity_id, source.tax_year, source.quarter, source.due_date,
            ROUND(RAND() * 15000 + 2000, 2),
            ROUND(RAND() * 5000  + 500,  2),
            CASE WHEN source.due_date < CAST(GETDATE() AS DATE) THEN 'PAID' ELSE 'PENDING' END)
WHEN MATCHED AND target.status = 'PENDING'
          AND target.due_date  < CAST(GETDATE() AS DATE) THEN
    UPDATE SET
        status          = 'PAID',
        payment_date    = target.due_date,
        payment_method  = 'EFTPS',
        confirmation_no = 'EFTPS-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' +
                          CAST(target.payment_id AS VARCHAR),
        updated_at      = GETDATE();

PRINT 'estimated_tax_payments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 5. Billing Engagements — new engagements + log hours on existing ones
-- -----------------------------------------------------------------------------

-- Add new engagements if not already present
MERGE dbo.billing_engagements AS target
USING (
    SELECT e.entity_id, p.partner_id, v.engagement_type, v.tax_year,
           v.engagement_date, v.budgeted_hours, v.billing_rate
    FROM (VALUES
        ('ALPHA-LLC',   'P001', 'TAX_PREP',      2025, '2025-01-15', 40.0, 350.00),
        ('ALPHA-LLC',   'P001', 'ADVISORY',       2025, '2025-02-01', 20.0, 400.00),
        ('BETA-SCORP',  'P002', 'TAX_PREP',      2025, '2025-01-20', 35.0, 350.00),
        ('GAMMA-PTNR',  'P001', 'TAX_PREP',      2025, '2025-01-18', 45.0, 350.00),
        ('GAMMA-PTNR',  'P004', 'AUDIT_SUPPORT',  2025, '2025-03-01', 30.0, 375.00),
        ('DELTA-CCORP', 'P002', 'TAX_PREP',      2025, '2025-01-22', 50.0, 350.00),
        ('DELTA-CCORP', 'P003', 'ADVISORY',       2025, '2025-04-01', 25.0, 400.00)
    ) v (entity_code, partner_code, engagement_type, tax_year, engagement_date, budgeted_hours, billing_rate)
    JOIN dbo.business_entities e ON e.entity_code  = v.entity_code
    JOIN dbo.partners p          ON p.partner_code = v.partner_code
) AS source ON target.entity_id       = source.entity_id
           AND target.partner_id      = source.partner_id
           AND target.engagement_type = source.engagement_type
           AND target.tax_year        = source.tax_year
WHEN NOT MATCHED THEN
    INSERT (entity_id, partner_id, engagement_type, tax_year, engagement_date,
            budgeted_hours, billing_rate, actual_hours, billed_amount, status)
    VALUES (source.entity_id, source.partner_id, source.engagement_type, source.tax_year,
            source.engagement_date, source.budgeted_hours, source.billing_rate,
            0.0, 0.00, 'IN_PROGRESS');

-- Log hours on active engagements
UPDATE dbo.billing_engagements
SET    actual_hours  = actual_hours + ROUND(RAND() * 3 + 0.5, 1),
       billed_amount = (actual_hours + ROUND(RAND() * 3 + 0.5, 1)) * billing_rate,
       updated_at    = GETDATE()
WHERE  status        = 'IN_PROGRESS'
AND    tax_year      = 2025
AND    RAND()        > 0.3;   -- update ~70% of active engagements each run

-- Mark as BILLED when hours exceed budget
UPDATE dbo.billing_engagements
SET    status       = 'BILLED',
       invoice_date = CAST(GETDATE() AS DATE),
       updated_at   = GETDATE()
WHERE  status       = 'IN_PROGRESS'
AND    actual_hours >= budgeted_hours
AND    tax_year     = 2025;

PRINT 'billing_engagements: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows updated/inserted';

PRINT '--- Fact insert run complete: ' + CONVERT(VARCHAR, GETDATE(), 120) + ' ---';