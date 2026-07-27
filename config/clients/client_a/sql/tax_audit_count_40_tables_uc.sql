-- =============================================================================
-- tax_audit_count_40_tables_uc.sql
--
-- Row counts for all 40 tax_audit pipeline tables in Unity Catalog.
-- Run in Databricks SQL editor or SQL warehouse.
--
-- Destination: ipac_tax_synch.client_a_raw_auto
-- (dev target uses ipac_tax_synch.client_a_raw_dev)
-- =============================================================================

-- Per-table counts
SELECT 'audit_engagement' AS table_name, COUNT(*) AS row_count FROM ipac_tax_synch.client_a_raw_auto.audit_engagement
UNION ALL SELECT 'audit_entity_profile', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_entity_profile
UNION ALL SELECT 'audit_partner_allocation', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_partner_allocation
UNION ALL SELECT 'audit_tax_period_lock', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_tax_period_lock
UNION ALL SELECT 'audit_gl_balance', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_gl_balance
UNION ALL SELECT 'audit_adjustment_entry', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_adjustment_entry
UNION ALL SELECT 'audit_schedule_m1', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_schedule_m1
UNION ALL SELECT 'audit_schedule_k1_line', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_schedule_k1_line
UNION ALL SELECT 'audit_state_apportion', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_state_apportion
UNION ALL SELECT 'audit_transfer_price', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_transfer_price
UNION ALL SELECT 'audit_fixed_asset', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_fixed_asset
UNION ALL SELECT 'audit_depreciation', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_depreciation
UNION ALL SELECT 'audit_inventory_val', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_inventory_val
UNION ALL SELECT 'audit_ar_aging', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_ar_aging
UNION ALL SELECT 'audit_ap_aging', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_ap_aging
UNION ALL SELECT 'audit_payroll_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_payroll_tax
UNION ALL SELECT 'audit_sales_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_sales_tax
UNION ALL SELECT 'audit_nexus_study', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_nexus_study
UNION ALL SELECT 'audit_penalty_claim', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_penalty_claim
UNION ALL SELECT 'audit_document_log', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_document_log
UNION ALL SELECT 'audit_revenue_recognition', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_revenue_recognition
UNION ALL SELECT 'audit_cost_of_sales', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_cost_of_sales
UNION ALL SELECT 'audit_intercompany_elim', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_intercompany_elim
UNION ALL SELECT 'audit_consolidation_entry', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_consolidation_entry
UNION ALL SELECT 'audit_foreign_exchange', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_foreign_exchange
UNION ALL SELECT 'audit_deferred_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_deferred_tax
UNION ALL SELECT 'audit_uncertain_tax_pos', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_uncertain_tax_pos
UNION ALL SELECT 'audit_rd_tax_credit', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_rd_tax_credit
UNION ALL SELECT 'audit_estimated_payments', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_estimated_payments
UNION ALL SELECT 'audit_extension_filing', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_extension_filing
UNION ALL SELECT 'audit_amended_return', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_amended_return
UNION ALL SELECT 'audit_tax_provision', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_tax_provision
UNION ALL SELECT 'audit_effective_rate', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_effective_rate
UNION ALL SELECT 'audit_book_tax_diff', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_book_tax_diff
UNION ALL SELECT 'audit_wholly_owned_sub', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_wholly_owned_sub
UNION ALL SELECT 'audit_cash_flow_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_cash_flow_tax
UNION ALL SELECT 'audit_capital_account', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_capital_account
UNION ALL SELECT 'audit_partner_distribution', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_partner_distribution
UNION ALL SELECT 'audit_section_199a', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_section_199a
UNION ALL SELECT 'audit_form_mapping', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_form_mapping
ORDER BY table_name;

-- Summary (tables that exist in UC schema)
SELECT
    COUNT(*) AS tables_in_schema,
    SUM(row_count) AS total_rows
FROM (
    SELECT 'audit_engagement' AS table_name, COUNT(*) AS row_count FROM ipac_tax_synch.client_a_raw_auto.audit_engagement
    UNION ALL SELECT 'audit_entity_profile', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_entity_profile
    UNION ALL SELECT 'audit_partner_allocation', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_partner_allocation
    UNION ALL SELECT 'audit_tax_period_lock', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_tax_period_lock
    UNION ALL SELECT 'audit_gl_balance', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_gl_balance
    UNION ALL SELECT 'audit_adjustment_entry', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_adjustment_entry
    UNION ALL SELECT 'audit_schedule_m1', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_schedule_m1
    UNION ALL SELECT 'audit_schedule_k1_line', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_schedule_k1_line
    UNION ALL SELECT 'audit_state_apportion', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_state_apportion
    UNION ALL SELECT 'audit_transfer_price', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_transfer_price
    UNION ALL SELECT 'audit_fixed_asset', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_fixed_asset
    UNION ALL SELECT 'audit_depreciation', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_depreciation
    UNION ALL SELECT 'audit_inventory_val', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_inventory_val
    UNION ALL SELECT 'audit_ar_aging', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_ar_aging
    UNION ALL SELECT 'audit_ap_aging', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_ap_aging
    UNION ALL SELECT 'audit_payroll_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_payroll_tax
    UNION ALL SELECT 'audit_sales_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_sales_tax
    UNION ALL SELECT 'audit_nexus_study', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_nexus_study
    UNION ALL SELECT 'audit_penalty_claim', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_penalty_claim
    UNION ALL SELECT 'audit_document_log', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_document_log
    UNION ALL SELECT 'audit_revenue_recognition', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_revenue_recognition
    UNION ALL SELECT 'audit_cost_of_sales', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_cost_of_sales
    UNION ALL SELECT 'audit_intercompany_elim', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_intercompany_elim
    UNION ALL SELECT 'audit_consolidation_entry', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_consolidation_entry
    UNION ALL SELECT 'audit_foreign_exchange', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_foreign_exchange
    UNION ALL SELECT 'audit_deferred_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_deferred_tax
    UNION ALL SELECT 'audit_uncertain_tax_pos', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_uncertain_tax_pos
    UNION ALL SELECT 'audit_rd_tax_credit', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_rd_tax_credit
    UNION ALL SELECT 'audit_estimated_payments', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_estimated_payments
    UNION ALL SELECT 'audit_extension_filing', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_extension_filing
    UNION ALL SELECT 'audit_amended_return', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_amended_return
    UNION ALL SELECT 'audit_tax_provision', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_tax_provision
    UNION ALL SELECT 'audit_effective_rate', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_effective_rate
    UNION ALL SELECT 'audit_book_tax_diff', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_book_tax_diff
    UNION ALL SELECT 'audit_wholly_owned_sub', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_wholly_owned_sub
    UNION ALL SELECT 'audit_cash_flow_tax', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_cash_flow_tax
    UNION ALL SELECT 'audit_capital_account', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_capital_account
    UNION ALL SELECT 'audit_partner_distribution', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_partner_distribution
    UNION ALL SELECT 'audit_section_199a', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_section_199a
    UNION ALL SELECT 'audit_form_mapping', COUNT(*) FROM ipac_tax_synch.client_a_raw_auto.audit_form_mapping
) c;

-- Which UC tables exist (no row count — fast inventory check)
SELECT table_name
FROM ipac_tax_synch.information_schema.tables
WHERE table_schema = 'client_a_raw_auto'
  AND table_name IN (
    'audit_engagement', 'audit_entity_profile', 'audit_partner_allocation',
    'audit_tax_period_lock', 'audit_gl_balance', 'audit_adjustment_entry',
    'audit_schedule_m1', 'audit_schedule_k1_line', 'audit_state_apportion',
    'audit_transfer_price', 'audit_fixed_asset', 'audit_depreciation',
    'audit_inventory_val', 'audit_ar_aging', 'audit_ap_aging',
    'audit_payroll_tax', 'audit_sales_tax', 'audit_nexus_study',
    'audit_penalty_claim', 'audit_document_log',
    'audit_revenue_recognition', 'audit_cost_of_sales', 'audit_intercompany_elim',
    'audit_consolidation_entry', 'audit_foreign_exchange', 'audit_deferred_tax',
    'audit_uncertain_tax_pos', 'audit_rd_tax_credit', 'audit_estimated_payments',
    'audit_extension_filing', 'audit_amended_return', 'audit_tax_provision',
    'audit_effective_rate', 'audit_book_tax_diff', 'audit_wholly_owned_sub',
    'audit_cash_flow_tax', 'audit_capital_account', 'audit_partner_distribution',
    'audit_section_199a', 'audit_form_mapping'
  )
ORDER BY table_name;
