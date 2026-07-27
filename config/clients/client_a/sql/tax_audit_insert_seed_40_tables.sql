-- =============================================================================
-- tax_audit_insert_seed_40_tables.sql
--
-- Parameterized seed insert for all 40 tax_audit pipeline tables.
-- Set @RowsToInsert before running.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Prerequisite:
--   tax_audit_create_20_tables.sql
--   tax_audit_create_another_20_tables.sql
--   tax_audit_enable_change_tracking_40_tables.sql
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

PRINT CONCAT('Inserting ', @RowsToInsert, ' row(s) into each of 40 tax_audit tables...');

IF OBJECT_ID('tempdb..#tax_audit_40_seed') IS NOT NULL DROP TABLE #tax_audit_40_seed;

CREATE TABLE #tax_audit_40_seed (
    table_name   SYSNAME NOT NULL PRIMARY KEY,
    table_prefix VARCHAR(10) NOT NULL,
    base_entity  INT NOT NULL,
    base_period  INT NOT NULL,
    tax_year     INT NOT NULL
);

INSERT INTO #tax_audit_40_seed (table_name, table_prefix, base_entity, base_period, tax_year) VALUES
    (N'audit_engagement',         N'ENG', 100, 202601, 2025),
    (N'audit_entity_profile',     N'ENT', 100, 202601, 2025),
    (N'audit_partner_allocation', N'PAL', 100, 202601, 2025),
    (N'audit_tax_period_lock',    N'TPL', 100, 202601, 2025),
    (N'audit_gl_balance',         N'GLB', 100, 202601, 2025),
    (N'audit_adjustment_entry',   N'ADJ', 100, 202601, 2025),
    (N'audit_schedule_m1',        N'M1',  100, 202601, 2025),
    (N'audit_schedule_k1_line',   N'K1',  100, 202601, 2025),
    (N'audit_state_apportion',    N'APR', 100, 202601, 2025),
    (N'audit_transfer_price',     N'TP',  100, 202601, 2025),
    (N'audit_fixed_asset',        N'FA',  100, 202601, 2025),
    (N'audit_depreciation',       N'DEP', 100, 202601, 2025),
    (N'audit_inventory_val',      N'INV', 100, 202601, 2025),
    (N'audit_ar_aging',           N'AR',  100, 202601, 2025),
    (N'audit_ap_aging',           N'AP',  100, 202601, 2025),
    (N'audit_payroll_tax',        N'PR',  100, 202601, 2025),
    (N'audit_sales_tax',          N'ST',  100, 202601, 2025),
    (N'audit_nexus_study',        N'NX',  100, 202601, 2025),
    (N'audit_penalty_claim',      N'PN',  100, 202601, 2025),
    (N'audit_document_log',       N'DOC', 100, 202601, 2025),
    (N'audit_revenue_recognition',N'REV', 200, 202701, 2026),
    (N'audit_cost_of_sales',      N'COS', 200, 202701, 2026),
    (N'audit_intercompany_elim',  N'ICE', 200, 202701, 2026),
    (N'audit_consolidation_entry',N'CON', 200, 202701, 2026),
    (N'audit_foreign_exchange',   N'FX',  200, 202701, 2026),
    (N'audit_deferred_tax',       N'DFT', 200, 202701, 2026),
    (N'audit_uncertain_tax_pos',  N'UTP', 200, 202701, 2026),
    (N'audit_rd_tax_credit',      N'RDC', 200, 202701, 2026),
    (N'audit_estimated_payments', N'EST', 200, 202701, 2026),
    (N'audit_extension_filing',   N'EXT', 200, 202701, 2026),
    (N'audit_amended_return',     N'AMD', 200, 202701, 2026),
    (N'audit_tax_provision',      N'PRO', 200, 202701, 2026),
    (N'audit_effective_rate',     N'EFF', 200, 202701, 2026),
    (N'audit_book_tax_diff',      N'BTD', 200, 202701, 2026),
    (N'audit_wholly_owned_sub',   N'WOS', 200, 202701, 2026),
    (N'audit_cash_flow_tax',      N'CFT', 200, 202701, 2026),
    (N'audit_capital_account',    N'CAP', 200, 202701, 2026),
    (N'audit_partner_distribution',N'DIS', 200, 202701, 2026),
    (N'audit_section_199a',       N'199', 200, 202701, 2026),
    (N'audit_form_mapping',       N'FRM', 200, 202701, 2026);

DECLARE @table_name SYSNAME;
DECLARE @prefix VARCHAR(10);
DECLARE @base_entity INT;
DECLARE @base_period INT;
DECLARE @tax_year INT;
DECLARE @sql NVARCHAR(MAX);

DECLARE seed_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT table_name, table_prefix, base_entity, base_period, tax_year
    FROM #tax_audit_40_seed
    ORDER BY table_name;

OPEN seed_cursor;
FETCH NEXT FROM seed_cursor INTO @table_name, @prefix, @base_entity, @base_period, @tax_year;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
;WITH n AS (
    SELECT TOP (@Rows) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
)
INSERT INTO tax_audit.' + QUOTENAME(@table_name) + N' (
    entity_id, period_id, partner_id, record_code, record_name, record_category,
    tax_year, fiscal_quarter, jurisdiction_code, status_code,
    amount_01, amount_02, amount_03, amount_04, amount_05,
    amount_06, amount_07, amount_08, amount_09, amount_10,
    flag_01, flag_02, notes, source_ref, created_by, updated_at
)
SELECT
    @BaseEntity + (rn % 5),
    @BasePeriod + (rn % 8),
    CASE WHEN rn % 4 = 0 THEN NULL ELSE 1 + (rn % 6) END,
    CONCAT(@Prefix, ''-'', RIGHT(''00000'' + CAST(rn AS VARCHAR(10)), 5)),
    CONCAT(@Tbl, '' record '', rn),
    CASE rn % 4 WHEN 0 THEN ''COMPLIANCE'' WHEN 1 THEN ''CALCULATION'' WHEN 2 THEN ''DOCUMENTATION'' ELSE ''REVIEW'' END,
    @TaxYear,
    1 + (rn % 4),
    CASE rn % 4 WHEN 0 THEN ''US-FED'' WHEN 1 THEN ''US-NY'' WHEN 2 THEN ''US-CA'' ELSE ''US-IL'' END,
    CASE rn % 3 WHEN 0 THEN ''OPEN'' WHEN 1 THEN ''IN_REVIEW'' ELSE ''CLOSED'' END,
    rn * 10.00, rn * 20.00, rn * 30.00, rn * 40.00, rn * 50.00,
    rn * 60.00, rn * 70.00, rn * 80.00, rn * 90.00, rn * 100.00,
    rn % 3 % 2, rn % 5 % 2,
    CONCAT(''Seed notes for '', @Tbl, '' row '', rn),
    CONCAT(''SRC-'', @Prefix, ''-'', rn),
    ''tax_audit_seed_40'',
    SYSUTCDATETIME()
FROM n;';

    EXEC sp_executesql
        @sql,
        N'@Rows INT, @Prefix VARCHAR(10), @Tbl SYSNAME, @BaseEntity INT, @BasePeriod INT, @TaxYear INT',
        @Rows = @RowsToInsert,
        @Prefix = @prefix,
        @Tbl = @table_name,
        @BaseEntity = @base_entity,
        @BasePeriod = @base_period,
        @TaxYear = @tax_year;

    FETCH NEXT FROM seed_cursor INTO @table_name, @prefix, @base_entity, @base_period, @tax_year;
END;

CLOSE seed_cursor;
DEALLOCATE seed_cursor;
GO

------------------------------------------------------------
-- Verify row counts (accurate COUNT_BIG — run tax_audit_count_40_tables_sqlserver.sql)
------------------------------------------------------------
PRINT CONCAT('Expected rows per table after this run: ', @RowsToInsert);
PRINT 'Run tax_audit_count_40_tables_sqlserver.sql for full per-table counts.';
GO

DROP TABLE IF EXISTS #tax_audit_40_seed;
GO
