-- =============================================================================
-- tax_audit_insert_seed.sql
--
-- Parameterized seed insert for tax_audit wide tables.
-- Set @RowsToInsert to the number of rows you want per table, then execute.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Safe to re-run: each execution appends rows (IDENTITY PKs stay unique),
-- which is useful for incremental CDC / change-tracking tests.
--
-- Prerequisite:
--   1. tax_audit_create_schema_and_tables.sql
--   2. tax_audit_enable_change_tracking.sql
-- =============================================================================

USE [free-sql-db-0862313];
GO

------------------------------------------------------------
-- >>> SET ROW COUNT HERE <<<
------------------------------------------------------------
DECLARE @RowsToInsert INT = 25;   -- change this number before running

IF @RowsToInsert IS NULL OR @RowsToInsert < 1
BEGIN
    RAISERROR('@RowsToInsert must be >= 1', 16, 1);
    RETURN;
END;

PRINT CONCAT('Inserting ', @RowsToInsert, ' row(s) into each tax_audit table...');

------------------------------------------------------------
-- Seed tax_audit.audit_finding_detail
------------------------------------------------------------
;WITH n AS (
    SELECT TOP (@RowsToInsert)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
)
INSERT INTO tax_audit.audit_finding_detail (
    entity_id, period_id, partner_id, finding_code, finding_title,
    finding_category, risk_level, audit_area, tax_year, fiscal_quarter, fiscal_month,
    jurisdiction_code, form_type, line_reference, finding_status,
    severity_score, materiality_threshold, exposure_amount, adjusted_amount,
    penalty_estimate, interest_estimate, currency_code, exchange_rate,
    base_amount, state_amount, federal_amount, local_amount,
    m1_adjustment, m2_adjustment, m3_adjustment, book_difference, tax_difference,
    reviewer_id, preparer_id, manager_id, engagement_code, workpaper_ref,
    source_document, sampling_method, sample_size, population_size, exception_rate,
    root_cause, remediation_plan, remediation_due_date, remediation_owner,
    is_repeat_finding, is_significant, is_reportable, requires_disclosure, notes
)
SELECT
    100 + (rn % 5),                                         -- entity_id
    202601 + (rn % 8),                                      -- period_id
    CASE WHEN rn % 4 = 0 THEN NULL ELSE 1 + (rn % 6) END,   -- partner_id
    CONCAT('FND-', RIGHT('00000' + CAST(rn AS VARCHAR(10)), 5)),
    CONCAT('Tax audit finding ', rn),
    CASE rn % 4 WHEN 0 THEN 'COMPLIANCE' WHEN 1 THEN 'CALCULATION' WHEN 2 THEN 'DOCUMENTATION' ELSE 'CLASSIFICATION' END,
    CASE rn % 3 WHEN 0 THEN 'HIGH' WHEN 1 THEN 'MEDIUM' ELSE 'LOW' END,
    CASE rn % 3 WHEN 0 THEN 'INCOME_TAX' WHEN 1 THEN 'SALES_TAX' ELSE 'PAYROLL_TAX' END,
    2025,
    1 + (rn % 4),
    1 + (rn % 12),
    CASE rn % 4 WHEN 0 THEN 'US-FED' WHEN 1 THEN 'US-NY' WHEN 2 THEN 'US-CA' ELSE 'US-IL' END,
    CASE rn % 3 WHEN 0 THEN '1120S' WHEN 1 THEN '1065' ELSE '1120' END,
    CONCAT('L', 100 + rn),
    CASE rn % 4 WHEN 0 THEN 'OPEN' WHEN 1 THEN 'IN_REVIEW' WHEN 2 THEN 'CLOSED' ELSE 'DEFERRED' END,
    rn * 1.25,                                              -- severity_score
    50000.00,                                               -- materiality_threshold
    rn * 2500.00,                                           -- exposure_amount
    rn * 1800.00,                                           -- adjusted_amount
    rn * 120.00,                                            -- penalty_estimate
    rn * 45.00,                                             -- interest_estimate
    'USD',
    1.000000,
    rn * 1800.00,
    rn * 250.00,
    rn * 1550.00,
    rn * 75.00,
    rn * 12.50,
    rn * 8.25,
    rn * 4.10,
    rn * 22.00,
    rn * 18.00,
    200 + (rn % 3),                                         -- reviewer_id
    100 + (rn % 4),                                         -- preparer_id
    300 + (rn % 2),                                         -- manager_id
    CONCAT('ENG-2025-', 100 + rn),
    CONCAT('WP-FND-', rn),
    CONCAT('support_doc_', rn, '.pdf'),
    CASE rn % 2 WHEN 0 THEN 'RANDOM' ELSE 'JUDGMENTAL' END,
    25 + (rn % 10),
    1000 + (rn * 10),
    CAST((rn % 10) AS DECIMAL(9,4)) / 100.0,
    CONCAT('Root cause narrative for finding ', rn),
    CONCAT('Remediation steps for finding ', rn),
    DATEADD(DAY, 30 + rn, CAST(GETDATE() AS DATE)),
    CONCAT('owner_', 1 + (rn % 5), '@example.com'),
    rn % 7 % 2,
    rn % 5 % 2,
    rn % 3 % 2,
    rn % 4 % 2,
    CONCAT('Seed notes for finding ', rn)
FROM n;

------------------------------------------------------------
-- Seed tax_audit.audit_workpaper_line
------------------------------------------------------------
;WITH n AS (
    SELECT TOP (@RowsToInsert)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
)
INSERT INTO tax_audit.audit_workpaper_line (
    entity_id, period_id, partner_id, workpaper_code, workpaper_title,
    section_code, subsection_code, line_no, account_code, account_name, account_type,
    tax_year, fiscal_quarter, fiscal_month, transaction_date, posting_date,
    journal_source, journal_batch, reference_no, description,
    debit_amount, credit_amount, net_amount, tax_basis_amount, gaap_amount,
    permanent_diff, temporary_diff, state_amount, federal_amount, foreign_amount,
    currency_code, exchange_rate, department_code, cost_center, project_code, location_code,
    preparer_id, reviewer_id, manager_id, engagement_code, source_system,
    source_table, source_key, tie_out_status, tie_out_variance, support_doc_ref,
    sampling_flag, tested_flag, exception_flag, signoff_status, signoff_date, created_by, updated_at
)
SELECT
    100 + (rn % 5),
    202601 + (rn % 8),
    CASE WHEN rn % 4 = 0 THEN NULL ELSE 1 + (rn % 6) END,
    CONCAT('WP-', RIGHT('00000' + CAST(rn AS VARCHAR(10)), 5)),
    CONCAT('Audit workpaper line ', rn),
    CONCAT('SEC-', 1 + (rn % 6)),
    CONCAT('SUB-', 1 + (rn % 4)),
    rn,
    CONCAT('6', RIGHT('000' + CAST(rn * 11 AS VARCHAR(4)), 4)),
    CONCAT('Expense Account ', rn),
    CASE rn % 3 WHEN 0 THEN 'EXPENSE' WHEN 1 THEN 'REVENUE' ELSE 'ASSET' END,
    2025,
    1 + (rn % 4),
    1 + (rn % 12),
    DATEADD(DAY, -rn, CAST(GETDATE() AS DATE)),
    DATEADD(DAY, -rn + 1, CAST(GETDATE() AS DATE)),
    CASE rn % 2 WHEN 0 THEN 'GL' ELSE 'AP' END,
    CONCAT('BATCH-', 2000 + rn),
    CONCAT('REF-AUD-', 7000 + rn),
    CONCAT('Workpaper CDC test line ', rn),
    CASE WHEN rn % 2 = 0 THEN rn * 88.75 ELSE 0 END,
    CASE WHEN rn % 2 = 1 THEN rn * 88.75 ELSE 0 END,
    CASE WHEN rn % 2 = 0 THEN rn * 88.75 ELSE -rn * 88.75 END,
    rn * 88.75,
    rn * 90.00,
    rn * 1.25,
    rn * 2.50,
    rn * 6.00,
    rn * 82.75,
    rn * 3.50,
    'USD',
    1.000000,
    CONCAT('DEPT-', rn % 5),
    CONCAT('CC-', 200 + rn % 5),
    CONCAT('PRJ-', rn % 4),
    CASE rn % 2 WHEN 0 THEN 'NYC' ELSE 'CHI' END,
    100 + (rn % 4),
    200 + (rn % 3),
    300 + (rn % 2),
    CONCAT('ENG-2025-', 100 + rn),
    'NETSUITE',
    'gl_transactions',
    CONCAT('GL-', 100000 + rn),
    CASE rn % 3 WHEN 0 THEN 'TIED' WHEN 1 THEN 'VARIANCE' ELSE 'PENDING' END,
    CASE WHEN rn % 3 = 1 THEN rn * 0.55 ELSE 0 END,
    CONCAT('support_wp_', rn, '.pdf'),
    rn % 4 % 2,
    rn % 3 % 2,
    rn % 5 % 2,
    CASE rn % 3 WHEN 0 THEN 'SIGNED' WHEN 1 THEN 'PENDING' ELSE 'REVIEW' END,
    DATEADD(DAY, -rn, CAST(GETDATE() AS DATE)),
    'tax_audit_seed_script',
    SYSUTCDATETIME()
FROM n;
GO

------------------------------------------------------------
-- Verify row counts
------------------------------------------------------------
SELECT 'audit_finding_detail' AS table_name, COUNT(*) AS row_count,
       MIN(finding_id) AS min_pk, MAX(finding_id) AS max_pk
FROM tax_audit.audit_finding_detail
UNION ALL
SELECT 'audit_workpaper_line', COUNT(*), MIN(workpaper_line_id), MAX(workpaper_line_id)
FROM tax_audit.audit_workpaper_line;
GO
