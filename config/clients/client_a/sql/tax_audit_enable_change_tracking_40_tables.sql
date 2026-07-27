-- =============================================================================
-- tax_audit_enable_change_tracking_40_tables.sql
--
-- Enables SQL Server Change Tracking for all 40 tax_audit pipeline tables.
-- Uses explicit ALTER TABLE syntax (no seed/temp-table insert pattern).
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Prerequisite:
--   tax_audit_create_20_tables.sql
--   tax_audit_create_another_20_tables.sql
-- =============================================================================

USE [free-sql-db-0862313];
GO

------------------------------------------------------------
-- Database-level change tracking
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()
)
BEGIN
    ALTER DATABASE CURRENT
    SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON);
    PRINT 'Database change tracking enabled.';
END
ELSE
    PRINT 'Database change tracking already enabled.';
GO

------------------------------------------------------------
-- Table-level change tracking — batch 1 (20 tables)
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_engagement'))
    ALTER TABLE tax_audit.audit_engagement ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_entity_profile'))
    ALTER TABLE tax_audit.audit_entity_profile ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_partner_allocation'))
    ALTER TABLE tax_audit.audit_partner_allocation ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_tax_period_lock'))
    ALTER TABLE tax_audit.audit_tax_period_lock ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_gl_balance'))
    ALTER TABLE tax_audit.audit_gl_balance ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_adjustment_entry'))
    ALTER TABLE tax_audit.audit_adjustment_entry ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_schedule_m1'))
    ALTER TABLE tax_audit.audit_schedule_m1 ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_schedule_k1_line'))
    ALTER TABLE tax_audit.audit_schedule_k1_line ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_state_apportion'))
    ALTER TABLE tax_audit.audit_state_apportion ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_transfer_price'))
    ALTER TABLE tax_audit.audit_transfer_price ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_fixed_asset'))
    ALTER TABLE tax_audit.audit_fixed_asset ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_depreciation'))
    ALTER TABLE tax_audit.audit_depreciation ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_inventory_val'))
    ALTER TABLE tax_audit.audit_inventory_val ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_ar_aging'))
    ALTER TABLE tax_audit.audit_ar_aging ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_ap_aging'))
    ALTER TABLE tax_audit.audit_ap_aging ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_payroll_tax'))
    ALTER TABLE tax_audit.audit_payroll_tax ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_sales_tax'))
    ALTER TABLE tax_audit.audit_sales_tax ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_nexus_study'))
    ALTER TABLE tax_audit.audit_nexus_study ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_penalty_claim'))
    ALTER TABLE tax_audit.audit_penalty_claim ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_document_log'))
    ALTER TABLE tax_audit.audit_document_log ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO

------------------------------------------------------------
-- Table-level change tracking — batch 2 (another 20 tables)
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_revenue_recognition'))
    ALTER TABLE tax_audit.audit_revenue_recognition ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_cost_of_sales'))
    ALTER TABLE tax_audit.audit_cost_of_sales ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_intercompany_elim'))
    ALTER TABLE tax_audit.audit_intercompany_elim ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_consolidation_entry'))
    ALTER TABLE tax_audit.audit_consolidation_entry ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_foreign_exchange'))
    ALTER TABLE tax_audit.audit_foreign_exchange ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_deferred_tax'))
    ALTER TABLE tax_audit.audit_deferred_tax ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_uncertain_tax_pos'))
    ALTER TABLE tax_audit.audit_uncertain_tax_pos ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_rd_tax_credit'))
    ALTER TABLE tax_audit.audit_rd_tax_credit ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_estimated_payments'))
    ALTER TABLE tax_audit.audit_estimated_payments ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_extension_filing'))
    ALTER TABLE tax_audit.audit_extension_filing ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_amended_return'))
    ALTER TABLE tax_audit.audit_amended_return ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_tax_provision'))
    ALTER TABLE tax_audit.audit_tax_provision ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_effective_rate'))
    ALTER TABLE tax_audit.audit_effective_rate ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_book_tax_diff'))
    ALTER TABLE tax_audit.audit_book_tax_diff ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_wholly_owned_sub'))
    ALTER TABLE tax_audit.audit_wholly_owned_sub ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_cash_flow_tax'))
    ALTER TABLE tax_audit.audit_cash_flow_tax ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_capital_account'))
    ALTER TABLE tax_audit.audit_capital_account ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_partner_distribution'))
    ALTER TABLE tax_audit.audit_partner_distribution ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_section_199a'))
    ALTER TABLE tax_audit.audit_section_199a ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'tax_audit.audit_form_mapping'))
    ALTER TABLE tax_audit.audit_form_mapping ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO

------------------------------------------------------------
-- Verification (shows all 40 expected tables — including missing)
------------------------------------------------------------
PRINT '--- tax_audit (40 tables) change tracking status ---';

;WITH expected AS (
    SELECT v.table_name
    FROM (VALUES
        (N'audit_engagement'), (N'audit_entity_profile'), (N'audit_partner_allocation'),
        (N'audit_tax_period_lock'), (N'audit_gl_balance'), (N'audit_adjustment_entry'),
        (N'audit_schedule_m1'), (N'audit_schedule_k1_line'), (N'audit_state_apportion'),
        (N'audit_transfer_price'), (N'audit_fixed_asset'), (N'audit_depreciation'),
        (N'audit_inventory_val'), (N'audit_ar_aging'), (N'audit_ap_aging'),
        (N'audit_payroll_tax'), (N'audit_sales_tax'), (N'audit_nexus_study'),
        (N'audit_penalty_claim'), (N'audit_document_log'),
        (N'audit_revenue_recognition'), (N'audit_cost_of_sales'), (N'audit_intercompany_elim'),
        (N'audit_consolidation_entry'), (N'audit_foreign_exchange'), (N'audit_deferred_tax'),
        (N'audit_uncertain_tax_pos'), (N'audit_rd_tax_credit'), (N'audit_estimated_payments'),
        (N'audit_extension_filing'), (N'audit_amended_return'), (N'audit_tax_provision'),
        (N'audit_effective_rate'), (N'audit_book_tax_diff'), (N'audit_wholly_owned_sub'),
        (N'audit_cash_flow_tax'), (N'audit_capital_account'), (N'audit_partner_distribution'),
        (N'audit_section_199a'), (N'audit_form_mapping')
    ) AS v(table_name)
)
SELECT
    e.table_name,
    CASE WHEN t.object_id IS NOT NULL THEN 'YES' ELSE 'NO — RUN tax_audit_create_another_20_tables.sql' END AS table_exists,
    CASE WHEN ct.object_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS change_tracking_enabled
FROM expected e
LEFT JOIN sys.tables t
    ON t.name = e.table_name AND t.schema_id = SCHEMA_ID(N'tax_audit')
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
ORDER BY e.table_name;
GO

PRINT '--- summary ---';
;WITH expected AS (
    SELECT v.table_name
    FROM (VALUES
        (N'audit_engagement'), (N'audit_entity_profile'), (N'audit_partner_allocation'),
        (N'audit_tax_period_lock'), (N'audit_gl_balance'), (N'audit_adjustment_entry'),
        (N'audit_schedule_m1'), (N'audit_schedule_k1_line'), (N'audit_state_apportion'),
        (N'audit_transfer_price'), (N'audit_fixed_asset'), (N'audit_depreciation'),
        (N'audit_inventory_val'), (N'audit_ar_aging'), (N'audit_ap_aging'),
        (N'audit_payroll_tax'), (N'audit_sales_tax'), (N'audit_nexus_study'),
        (N'audit_penalty_claim'), (N'audit_document_log'),
        (N'audit_revenue_recognition'), (N'audit_cost_of_sales'), (N'audit_intercompany_elim'),
        (N'audit_consolidation_entry'), (N'audit_foreign_exchange'), (N'audit_deferred_tax'),
        (N'audit_uncertain_tax_pos'), (N'audit_rd_tax_credit'), (N'audit_estimated_payments'),
        (N'audit_extension_filing'), (N'audit_amended_return'), (N'audit_tax_provision'),
        (N'audit_effective_rate'), (N'audit_book_tax_diff'), (N'audit_wholly_owned_sub'),
        (N'audit_cash_flow_tax'), (N'audit_capital_account'), (N'audit_partner_distribution'),
        (N'audit_section_199a'), (N'audit_form_mapping')
    ) AS v(table_name)
)
SELECT
    COUNT(*) AS expected_tables,
    SUM(CASE WHEN t.object_id IS NOT NULL THEN 1 ELSE 0 END) AS tables_found,
    SUM(CASE WHEN t.object_id IS NULL THEN 1 ELSE 0 END) AS tables_missing,
    SUM(CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END) AS change_tracking_on
FROM expected e
LEFT JOIN sys.tables t
    ON t.name = e.table_name AND t.schema_id = SCHEMA_ID(N'tax_audit')
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id;
GO
