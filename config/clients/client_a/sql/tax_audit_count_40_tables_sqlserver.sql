-- =============================================================================
-- tax_audit_count_40_tables_sqlserver.sql
--
-- Returns 40 rows — one row per table (table_name, row_count).
-- Database : free-sql-db-0862313 | Schema : tax_audit
-- =============================================================================

USE [free-sql-db-0862313];
GO

SELECT 'audit_engagement'           AS table_name, COUNT(*) AS row_count FROM tax_audit.audit_engagement
UNION ALL SELECT 'audit_entity_profile',       COUNT(*) FROM tax_audit.audit_entity_profile
UNION ALL SELECT 'audit_partner_allocation',   COUNT(*) FROM tax_audit.audit_partner_allocation
UNION ALL SELECT 'audit_tax_period_lock',      COUNT(*) FROM tax_audit.audit_tax_period_lock
UNION ALL SELECT 'audit_gl_balance',           COUNT(*) FROM tax_audit.audit_gl_balance
UNION ALL SELECT 'audit_adjustment_entry',     COUNT(*) FROM tax_audit.audit_adjustment_entry
UNION ALL SELECT 'audit_schedule_m1',          COUNT(*) FROM tax_audit.audit_schedule_m1
UNION ALL SELECT 'audit_schedule_k1_line',     COUNT(*) FROM tax_audit.audit_schedule_k1_line
UNION ALL SELECT 'audit_state_apportion',      COUNT(*) FROM tax_audit.audit_state_apportion
UNION ALL SELECT 'audit_transfer_price',       COUNT(*) FROM tax_audit.audit_transfer_price
UNION ALL SELECT 'audit_fixed_asset',          COUNT(*) FROM tax_audit.audit_fixed_asset
UNION ALL SELECT 'audit_depreciation',         COUNT(*) FROM tax_audit.audit_depreciation
UNION ALL SELECT 'audit_inventory_val',        COUNT(*) FROM tax_audit.audit_inventory_val
UNION ALL SELECT 'audit_ar_aging',             COUNT(*) FROM tax_audit.audit_ar_aging
UNION ALL SELECT 'audit_ap_aging',             COUNT(*) FROM tax_audit.audit_ap_aging
UNION ALL SELECT 'audit_payroll_tax',          COUNT(*) FROM tax_audit.audit_payroll_tax
UNION ALL SELECT 'audit_sales_tax',            COUNT(*) FROM tax_audit.audit_sales_tax
UNION ALL SELECT 'audit_nexus_study',          COUNT(*) FROM tax_audit.audit_nexus_study
UNION ALL SELECT 'audit_penalty_claim',        COUNT(*) FROM tax_audit.audit_penalty_claim
UNION ALL SELECT 'audit_document_log',         COUNT(*) FROM tax_audit.audit_document_log
UNION ALL SELECT 'audit_revenue_recognition',  COUNT(*) FROM tax_audit.audit_revenue_recognition
UNION ALL SELECT 'audit_cost_of_sales',        COUNT(*) FROM tax_audit.audit_cost_of_sales
UNION ALL SELECT 'audit_intercompany_elim',    COUNT(*) FROM tax_audit.audit_intercompany_elim
UNION ALL SELECT 'audit_consolidation_entry',  COUNT(*) FROM tax_audit.audit_consolidation_entry
UNION ALL SELECT 'audit_foreign_exchange',     COUNT(*) FROM tax_audit.audit_foreign_exchange
UNION ALL SELECT 'audit_deferred_tax',         COUNT(*) FROM tax_audit.audit_deferred_tax
UNION ALL SELECT 'audit_uncertain_tax_pos',    COUNT(*) FROM tax_audit.audit_uncertain_tax_pos
UNION ALL SELECT 'audit_rd_tax_credit',        COUNT(*) FROM tax_audit.audit_rd_tax_credit
UNION ALL SELECT 'audit_estimated_payments',  COUNT(*) FROM tax_audit.audit_estimated_payments
UNION ALL SELECT 'audit_extension_filing',      COUNT(*) FROM tax_audit.audit_extension_filing
UNION ALL SELECT 'audit_amended_return',       COUNT(*) FROM tax_audit.audit_amended_return
UNION ALL SELECT 'audit_tax_provision',        COUNT(*) FROM tax_audit.audit_tax_provision
UNION ALL SELECT 'audit_effective_rate',       COUNT(*) FROM tax_audit.audit_effective_rate
UNION ALL SELECT 'audit_book_tax_diff',        COUNT(*) FROM tax_audit.audit_book_tax_diff
UNION ALL SELECT 'audit_wholly_owned_sub',     COUNT(*) FROM tax_audit.audit_wholly_owned_sub
UNION ALL SELECT 'audit_cash_flow_tax',        COUNT(*) FROM tax_audit.audit_cash_flow_tax
UNION ALL SELECT 'audit_capital_account',      COUNT(*) FROM tax_audit.audit_capital_account
UNION ALL SELECT 'audit_partner_distribution', COUNT(*) FROM tax_audit.audit_partner_distribution
UNION ALL SELECT 'audit_section_199a',         COUNT(*) FROM tax_audit.audit_section_199a
UNION ALL SELECT 'audit_form_mapping',         COUNT(*) FROM tax_audit.audit_form_mapping
ORDER BY table_name;
GO
