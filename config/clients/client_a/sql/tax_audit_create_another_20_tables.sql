-- =============================================================================
-- tax_audit_create_another_20_tables.sql
--
-- Adds another 20 tables to schema tax_audit (CDC / scale testing).
-- Does not modify existing tax_audit tables.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Run order:
--   1. this file
--   2. tax_audit_enable_change_tracking_40_tables.sql
--   3. tax_audit_insert_seed_40_tables.sql
-- =============================================================================

USE [free-sql-db-0862313];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'tax_audit')
    EXEC(N'CREATE SCHEMA tax_audit AUTHORIZATION dbo;');
GO

/*
    Shared column template (same as tax_audit_create_20_tables.sql):
      entity_id, period_id, partner_id, record_code, record_name, record_category,
      tax_year, fiscal_quarter, jurisdiction_code, status_code,
      amount_01..amount_10, flag_01, flag_02, notes, source_ref,
      created_by, created_at, updated_at, is_active
*/

--  1. audit_revenue_recognition
IF OBJECT_ID(N'tax_audit.audit_revenue_recognition', N'U') IS NOT NULL DROP TABLE tax_audit.audit_revenue_recognition;
GO
CREATE TABLE tax_audit.audit_revenue_recognition (
    revenue_recognition_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_revenue_recognition PRIMARY KEY CLUSTERED (revenue_recognition_id)
);
GO

--  2. audit_cost_of_sales
IF OBJECT_ID(N'tax_audit.audit_cost_of_sales', N'U') IS NOT NULL DROP TABLE tax_audit.audit_cost_of_sales;
GO
CREATE TABLE tax_audit.audit_cost_of_sales (
    cost_of_sales_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_cost_of_sales PRIMARY KEY CLUSTERED (cost_of_sales_id)
);
GO

--  3. audit_intercompany_elim
IF OBJECT_ID(N'tax_audit.audit_intercompany_elim', N'U') IS NOT NULL DROP TABLE tax_audit.audit_intercompany_elim;
GO
CREATE TABLE tax_audit.audit_intercompany_elim (
    intercompany_elim_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_intercompany_elim PRIMARY KEY CLUSTERED (intercompany_elim_id)
);
GO

--  4. audit_consolidation_entry
IF OBJECT_ID(N'tax_audit.audit_consolidation_entry', N'U') IS NOT NULL DROP TABLE tax_audit.audit_consolidation_entry;
GO
CREATE TABLE tax_audit.audit_consolidation_entry (
    consolidation_entry_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_consolidation_entry PRIMARY KEY CLUSTERED (consolidation_entry_id)
);
GO

--  5. audit_foreign_exchange
IF OBJECT_ID(N'tax_audit.audit_foreign_exchange', N'U') IS NOT NULL DROP TABLE tax_audit.audit_foreign_exchange;
GO
CREATE TABLE tax_audit.audit_foreign_exchange (
    foreign_exchange_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_foreign_exchange PRIMARY KEY CLUSTERED (foreign_exchange_id)
);
GO

--  6. audit_deferred_tax
IF OBJECT_ID(N'tax_audit.audit_deferred_tax', N'U') IS NOT NULL DROP TABLE tax_audit.audit_deferred_tax;
GO
CREATE TABLE tax_audit.audit_deferred_tax (
    deferred_tax_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_deferred_tax PRIMARY KEY CLUSTERED (deferred_tax_id)
);
GO

--  7. audit_uncertain_tax_pos
IF OBJECT_ID(N'tax_audit.audit_uncertain_tax_pos', N'U') IS NOT NULL DROP TABLE tax_audit.audit_uncertain_tax_pos;
GO
CREATE TABLE tax_audit.audit_uncertain_tax_pos (
    uncertain_tax_pos_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_uncertain_tax_pos PRIMARY KEY CLUSTERED (uncertain_tax_pos_id)
);
GO

--  8. audit_rd_tax_credit
IF OBJECT_ID(N'tax_audit.audit_rd_tax_credit', N'U') IS NOT NULL DROP TABLE tax_audit.audit_rd_tax_credit;
GO
CREATE TABLE tax_audit.audit_rd_tax_credit (
    rd_tax_credit_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_rd_tax_credit PRIMARY KEY CLUSTERED (rd_tax_credit_id)
);
GO

--  9. audit_estimated_payments
IF OBJECT_ID(N'tax_audit.audit_estimated_payments', N'U') IS NOT NULL DROP TABLE tax_audit.audit_estimated_payments;
GO
CREATE TABLE tax_audit.audit_estimated_payments (
    estimated_payments_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_estimated_payments PRIMARY KEY CLUSTERED (estimated_payments_id)
);
GO

-- 10. audit_extension_filing
IF OBJECT_ID(N'tax_audit.audit_extension_filing', N'U') IS NOT NULL DROP TABLE tax_audit.audit_extension_filing;
GO
CREATE TABLE tax_audit.audit_extension_filing (
    extension_filing_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_extension_filing PRIMARY KEY CLUSTERED (extension_filing_id)
);
GO

-- 11. audit_amended_return
IF OBJECT_ID(N'tax_audit.audit_amended_return', N'U') IS NOT NULL DROP TABLE tax_audit.audit_amended_return;
GO
CREATE TABLE tax_audit.audit_amended_return (
    amended_return_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_amended_return PRIMARY KEY CLUSTERED (amended_return_id)
);
GO

-- 12. audit_tax_provision
IF OBJECT_ID(N'tax_audit.audit_tax_provision', N'U') IS NOT NULL DROP TABLE tax_audit.audit_tax_provision;
GO
CREATE TABLE tax_audit.audit_tax_provision (
    tax_provision_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_tax_provision PRIMARY KEY CLUSTERED (tax_provision_id)
);
GO

-- 13. audit_effective_rate
IF OBJECT_ID(N'tax_audit.audit_effective_rate', N'U') IS NOT NULL DROP TABLE tax_audit.audit_effective_rate;
GO
CREATE TABLE tax_audit.audit_effective_rate (
    effective_rate_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_effective_rate PRIMARY KEY CLUSTERED (effective_rate_id)
);
GO

-- 14. audit_book_tax_diff
IF OBJECT_ID(N'tax_audit.audit_book_tax_diff', N'U') IS NOT NULL DROP TABLE tax_audit.audit_book_tax_diff;
GO
CREATE TABLE tax_audit.audit_book_tax_diff (
    book_tax_diff_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_book_tax_diff PRIMARY KEY CLUSTERED (book_tax_diff_id)
);
GO

-- 15. audit_wholly_owned_sub
IF OBJECT_ID(N'tax_audit.audit_wholly_owned_sub', N'U') IS NOT NULL DROP TABLE tax_audit.audit_wholly_owned_sub;
GO
CREATE TABLE tax_audit.audit_wholly_owned_sub (
    wholly_owned_sub_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_wholly_owned_sub PRIMARY KEY CLUSTERED (wholly_owned_sub_id)
);
GO

-- 16. audit_cash_flow_tax
IF OBJECT_ID(N'tax_audit.audit_cash_flow_tax', N'U') IS NOT NULL DROP TABLE tax_audit.audit_cash_flow_tax;
GO
CREATE TABLE tax_audit.audit_cash_flow_tax (
    cash_flow_tax_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_cash_flow_tax PRIMARY KEY CLUSTERED (cash_flow_tax_id)
);
GO

-- 17. audit_capital_account
IF OBJECT_ID(N'tax_audit.audit_capital_account', N'U') IS NOT NULL DROP TABLE tax_audit.audit_capital_account;
GO
CREATE TABLE tax_audit.audit_capital_account (
    capital_account_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_capital_account PRIMARY KEY CLUSTERED (capital_account_id)
);
GO

-- 18. audit_partner_distribution
IF OBJECT_ID(N'tax_audit.audit_partner_distribution', N'U') IS NOT NULL DROP TABLE tax_audit.audit_partner_distribution;
GO
CREATE TABLE tax_audit.audit_partner_distribution (
    partner_distribution_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_partner_distribution PRIMARY KEY CLUSTERED (partner_distribution_id)
);
GO

-- 19. audit_section_199a
IF OBJECT_ID(N'tax_audit.audit_section_199a', N'U') IS NOT NULL DROP TABLE tax_audit.audit_section_199a;
GO
CREATE TABLE tax_audit.audit_section_199a (
    section_199a_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_section_199a PRIMARY KEY CLUSTERED (section_199a_id)
);
GO

-- 20. audit_form_mapping
IF OBJECT_ID(N'tax_audit.audit_form_mapping', N'U') IS NOT NULL DROP TABLE tax_audit.audit_form_mapping;
GO
CREATE TABLE tax_audit.audit_form_mapping (
    form_mapping_id BIGINT IDENTITY(1,1) NOT NULL,
    entity_id INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_form_mapping PRIMARY KEY CLUSTERED (form_mapping_id)
);
GO

SELECT t.name AS table_name, COUNT(c.column_id) AS column_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name = N'tax_audit'
  AND t.name IN (
    N'audit_revenue_recognition', N'audit_cost_of_sales', N'audit_intercompany_elim',
    N'audit_consolidation_entry', N'audit_foreign_exchange', N'audit_deferred_tax',
    N'audit_uncertain_tax_pos', N'audit_rd_tax_credit', N'audit_estimated_payments',
    N'audit_extension_filing', N'audit_amended_return', N'audit_tax_provision',
    N'audit_effective_rate', N'audit_book_tax_diff', N'audit_wholly_owned_sub',
    N'audit_cash_flow_tax', N'audit_capital_account', N'audit_partner_distribution',
    N'audit_section_199a', N'audit_form_mapping'
  )
GROUP BY t.name
ORDER BY t.name;
GO
