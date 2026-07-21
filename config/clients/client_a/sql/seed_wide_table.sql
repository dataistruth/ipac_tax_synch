-- =============================================================================
-- insert_wide_fact_tables.sql
-- Set-based seed: 25 rows per fact table, values derived from a row number
-- so amounts vary without hand-writing 40 columns x 25 rows.
-- Safe to re-run: each run appends 25 more rows (IDENTITY PK keeps them unique),
-- which also makes it handy for testing incremental CDC pickup.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Seed dbo.fact_gl_line_detail (25 rows)
-- -----------------------------------------------------------------------------
;WITH n AS (
    SELECT TOP (25) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.objects
)
INSERT INTO dbo.fact_gl_line_detail (
    entity_id, period_id, partner_id, account_code, account_name, account_type,
    transaction_date, posting_date, fiscal_year, fiscal_quarter, fiscal_month,
    journal_source, journal_batch, reference_no, description,
    debit_amount, credit_amount, net_amount,
    base_currency, txn_currency, exchange_rate, base_amount, book_amount,
    tax_amount, m1_adjustment, state_amount, federal_amount,
    department_code, cost_center, project_code, location_code,
    intercompany_flag, elimination_flag, recurring_flag, reversal_flag,
    source_system, created_by, updated_at
)
SELECT
    100 + (rn % 3),                                        -- entity_id: 100..102
    202601 + (rn % 6),                                     -- period_id
    CASE WHEN rn % 4 = 0 THEN NULL ELSE 1 + (rn % 5) END,  -- partner_id: 1..5 / NULL
    CONCAT('4', RIGHT('000' + CAST(rn * 10 AS VARCHAR(4)), 4)), -- account_code
    CONCAT('Revenue Account ', rn),
    CASE rn % 3 WHEN 0 THEN 'REVENUE' WHEN 1 THEN 'EXPENSE' ELSE 'ASSET' END,
    DATEADD(DAY, -rn, '2026-07-15'),                       -- transaction_date
    DATEADD(DAY, -rn + 1, '2026-07-15'),                   -- posting_date
    2026, 3, 7,
    CASE rn % 2 WHEN 0 THEN 'GL' ELSE 'AP' END,
    CONCAT('BATCH-', 1000 + rn),
    CONCAT('REF-2026-', 5000 + rn),
    CONCAT('Wide-table CDC test line ', rn),
    CASE WHEN rn % 2 = 0 THEN rn * 125.50 ELSE 0 END,      -- debit
    CASE WHEN rn % 2 = 1 THEN rn * 125.50 ELSE 0 END,      -- credit
    CASE WHEN rn % 2 = 0 THEN rn * 125.50 ELSE -rn * 125.50 END, -- net
    'USD', 'USD', 1.000000,
    rn * 125.50, rn * 125.50,
    rn * 26.35,                                            -- tax_amount
    rn * 3.14,                                             -- m1_adjustment
    rn * 6.20, rn * 20.15,                                 -- state / federal
    CONCAT('DEPT-', rn % 4), CONCAT('CC-', 100 + rn % 4),
    CONCAT('PRJ-', rn % 3), CASE rn % 2 WHEN 0 THEN 'CHI' ELSE 'NYC' END,
    rn % 5 % 2, 0, rn % 3 % 2, 0,
    'NETSUITE', 'seed_script', SYSUTCDATETIME()
FROM n;
GO

-- -----------------------------------------------------------------------------
-- Seed dbo.fact_k1_allocation_detail (25 rows)
-- -----------------------------------------------------------------------------
;WITH n AS (
    SELECT TOP (25) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.objects
)
INSERT INTO dbo.fact_k1_allocation_detail (
    entity_id, partner_id, period_id, tax_year, allocation_method,
    ownership_pct, profit_pct, loss_pct, capital_pct,
    ordinary_income, rental_income, interest_income, dividend_income,
    royalty_income, st_capital_gain, lt_capital_gain, sec1231_gain, other_income,
    sec179_deduction, charitable_contrib, investment_interest,
    sec59e_expenditure, other_deductions, se_earnings, credits_amount,
    foreign_tax_paid, amt_adjustment, tax_exempt_interest, nondeductible_exp,
    distributions_cash, distributions_property,
    capital_beginning, capital_contributed, capital_income,
    capital_withdrawn, capital_ending,
    state_source_code, created_by, is_final
)
SELECT
    100 + (rn % 3),                                        -- entity_id
    1 + (rn % 5),                                          -- partner_id: 1..5
    202601 + (rn % 6),                                     -- period_id
    2025,
    CASE rn % 2 WHEN 0 THEN 'PRO_RATA' ELSE 'TARGETED' END,
    20.000000, 20.000000, 20.000000, 20.000000,
    rn * 10000.00,                                         -- ordinary_income
    rn * 1500.00, rn * 320.00, rn * 210.00, rn * 55.00,
    rn * 400.00, rn * 900.00, rn * 130.00, rn * 75.00,
    rn * 250.00, rn * 100.00, rn * 60.00,
    rn * 15.00, rn * 180.00, rn * 8200.00, rn * 45.00,
    rn * 12.00, rn * 33.00, rn * 27.00, rn * 19.00,
    rn * 2000.00, 0.00,
    rn * 50000.00, rn * 1000.00, rn * 10000.00,
    rn * 2000.00,
    rn * 50000.00 + rn * 1000.00 + rn * 10000.00 - rn * 2000.00, -- capital_ending
    CASE rn % 3 WHEN 0 THEN 'IL' WHEN 1 THEN 'NY' ELSE 'CA' END,
    'seed_script', 0
FROM n;
GO

-- Verify
SELECT 'fact_gl_line_detail' AS tbl, COUNT(*) AS row_count, MIN(gl_line_id) AS min_pk, MAX(gl_line_id) AS max_pk
FROM dbo.fact_gl_line_detail
UNION ALL
SELECT 'fact_k1_allocation_detail', COUNT(*), MIN(k1_line_id), MAX(k1_line_id)
FROM dbo.fact_k1_allocation_detail;
GO