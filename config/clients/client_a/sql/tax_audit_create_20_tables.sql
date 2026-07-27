-- =============================================================================
-- tax_audit_create_20_tables.sql
--
-- Adds 20 tables to schema tax_audit (CDC / Lakeflow Connect scale testing).
-- Does not drop the existing audit_finding_detail / audit_workpaper_line tables.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Run order:
--   1. tax_audit_create_schema_and_tables.sql  (optional — schema + 2 wide tables)
--   2. this file
--   3. tax_audit_enable_change_tracking_40_tables.sql
--   4. tax_audit_insert_seed_40_tables.sql
-- =============================================================================

USE [free-sql-db-0862313];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'tax_audit')
    EXEC(N'CREATE SCHEMA tax_audit AUTHORIZATION dbo;');
GO

/*
    Shared column template (non-PK columns identical across all 20 tables):
      entity_id, period_id, partner_id, record_code, record_name, record_category,
      tax_year, fiscal_quarter, jurisdiction_code, status_code,
      amount_01..amount_10, flag_01, flag_02, notes, source_ref,
      created_by, created_at, updated_at, is_active
*/

--  1. audit_engagement
IF OBJECT_ID(N'tax_audit.audit_engagement', N'U') IS NOT NULL DROP TABLE tax_audit.audit_engagement;
GO
CREATE TABLE tax_audit.audit_engagement (
    engagement_id       BIGINT IDENTITY(1,1) NOT NULL,
    entity_id           INT NOT NULL, period_id INT NOT NULL, partner_id INT NULL,
    record_code         VARCHAR(30) NOT NULL, record_name VARCHAR(200) NOT NULL,
    record_category     VARCHAR(50) NOT NULL, tax_year INT NOT NULL, fiscal_quarter TINYINT NULL,
    jurisdiction_code   VARCHAR(10) NULL, status_code VARCHAR(30) NOT NULL,
    amount_01 DECIMAL(18,2) NULL, amount_02 DECIMAL(18,2) NULL, amount_03 DECIMAL(18,2) NULL,
    amount_04 DECIMAL(18,2) NULL, amount_05 DECIMAL(18,2) NULL, amount_06 DECIMAL(18,2) NULL,
    amount_07 DECIMAL(18,2) NULL, amount_08 DECIMAL(18,2) NULL, amount_09 DECIMAL(18,2) NULL,
    amount_10 DECIMAL(18,2) NULL, flag_01 BIT NOT NULL DEFAULT 0, flag_02 BIT NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL, source_ref VARCHAR(100) NULL, created_by VARCHAR(50) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), updated_at DATETIME2 NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_audit_engagement PRIMARY KEY CLUSTERED (engagement_id)
);
GO

--  2. audit_entity_profile
IF OBJECT_ID(N'tax_audit.audit_entity_profile', N'U') IS NOT NULL DROP TABLE tax_audit.audit_entity_profile;
GO
CREATE TABLE tax_audit.audit_entity_profile (
    entity_profile_id   BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_entity_profile PRIMARY KEY CLUSTERED (entity_profile_id)
);
GO

--  3. audit_partner_allocation
IF OBJECT_ID(N'tax_audit.audit_partner_allocation', N'U') IS NOT NULL DROP TABLE tax_audit.audit_partner_allocation;
GO
CREATE TABLE tax_audit.audit_partner_allocation (
    partner_allocation_id BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_partner_allocation PRIMARY KEY CLUSTERED (partner_allocation_id)
);
GO

--  4. audit_tax_period_lock
IF OBJECT_ID(N'tax_audit.audit_tax_period_lock', N'U') IS NOT NULL DROP TABLE tax_audit.audit_tax_period_lock;
GO
CREATE TABLE tax_audit.audit_tax_period_lock (
    tax_period_lock_id  BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_tax_period_lock PRIMARY KEY CLUSTERED (tax_period_lock_id)
);
GO

--  5. audit_gl_balance
IF OBJECT_ID(N'tax_audit.audit_gl_balance', N'U') IS NOT NULL DROP TABLE tax_audit.audit_gl_balance;
GO
CREATE TABLE tax_audit.audit_gl_balance (
    gl_balance_id       BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_gl_balance PRIMARY KEY CLUSTERED (gl_balance_id)
);
GO

--  6. audit_adjustment_entry
IF OBJECT_ID(N'tax_audit.audit_adjustment_entry', N'U') IS NOT NULL DROP TABLE tax_audit.audit_adjustment_entry;
GO
CREATE TABLE tax_audit.audit_adjustment_entry (
    adjustment_entry_id BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_adjustment_entry PRIMARY KEY CLUSTERED (adjustment_entry_id)
);
GO

--  7. audit_schedule_m1
IF OBJECT_ID(N'tax_audit.audit_schedule_m1', N'U') IS NOT NULL DROP TABLE tax_audit.audit_schedule_m1;
GO
CREATE TABLE tax_audit.audit_schedule_m1 (
    schedule_m1_id      BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_schedule_m1 PRIMARY KEY CLUSTERED (schedule_m1_id)
);
GO

--  8. audit_schedule_k1_line
IF OBJECT_ID(N'tax_audit.audit_schedule_k1_line', N'U') IS NOT NULL DROP TABLE tax_audit.audit_schedule_k1_line;
GO
CREATE TABLE tax_audit.audit_schedule_k1_line (
    schedule_k1_line_id BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_schedule_k1_line PRIMARY KEY CLUSTERED (schedule_k1_line_id)
);
GO

--  9. audit_state_apportion
IF OBJECT_ID(N'tax_audit.audit_state_apportion', N'U') IS NOT NULL DROP TABLE tax_audit.audit_state_apportion;
GO
CREATE TABLE tax_audit.audit_state_apportion (
    state_apportion_id  BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_state_apportion PRIMARY KEY CLUSTERED (state_apportion_id)
);
GO

-- 10. audit_transfer_price
IF OBJECT_ID(N'tax_audit.audit_transfer_price', N'U') IS NOT NULL DROP TABLE tax_audit.audit_transfer_price;
GO
CREATE TABLE tax_audit.audit_transfer_price (
    transfer_price_id   BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_transfer_price PRIMARY KEY CLUSTERED (transfer_price_id)
);
GO

-- 11. audit_fixed_asset
IF OBJECT_ID(N'tax_audit.audit_fixed_asset', N'U') IS NOT NULL DROP TABLE tax_audit.audit_fixed_asset;
GO
CREATE TABLE tax_audit.audit_fixed_asset (
    fixed_asset_id      BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_fixed_asset PRIMARY KEY CLUSTERED (fixed_asset_id)
);
GO

-- 12. audit_depreciation
IF OBJECT_ID(N'tax_audit.audit_depreciation', N'U') IS NOT NULL DROP TABLE tax_audit.audit_depreciation;
GO
CREATE TABLE tax_audit.audit_depreciation (
    depreciation_id     BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_depreciation PRIMARY KEY CLUSTERED (depreciation_id)
);
GO

-- 13. audit_inventory_val
IF OBJECT_ID(N'tax_audit.audit_inventory_val', N'U') IS NOT NULL DROP TABLE tax_audit.audit_inventory_val;
GO
CREATE TABLE tax_audit.audit_inventory_val (
    inventory_val_id    BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_inventory_val PRIMARY KEY CLUSTERED (inventory_val_id)
);
GO

-- 14. audit_ar_aging
IF OBJECT_ID(N'tax_audit.audit_ar_aging', N'U') IS NOT NULL DROP TABLE tax_audit.audit_ar_aging;
GO
CREATE TABLE tax_audit.audit_ar_aging (
    ar_aging_id         BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_ar_aging PRIMARY KEY CLUSTERED (ar_aging_id)
);
GO

-- 15. audit_ap_aging
IF OBJECT_ID(N'tax_audit.audit_ap_aging', N'U') IS NOT NULL DROP TABLE tax_audit.audit_ap_aging;
GO
CREATE TABLE tax_audit.audit_ap_aging (
    ap_aging_id         BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_ap_aging PRIMARY KEY CLUSTERED (ap_aging_id)
);
GO

-- 16. audit_payroll_tax
IF OBJECT_ID(N'tax_audit.audit_payroll_tax', N'U') IS NOT NULL DROP TABLE tax_audit.audit_payroll_tax;
GO
CREATE TABLE tax_audit.audit_payroll_tax (
    payroll_tax_id      BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_payroll_tax PRIMARY KEY CLUSTERED (payroll_tax_id)
);
GO

-- 17. audit_sales_tax
IF OBJECT_ID(N'tax_audit.audit_sales_tax', N'U') IS NOT NULL DROP TABLE tax_audit.audit_sales_tax;
GO
CREATE TABLE tax_audit.audit_sales_tax (
    sales_tax_id        BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_sales_tax PRIMARY KEY CLUSTERED (sales_tax_id)
);
GO

-- 18. audit_nexus_study
IF OBJECT_ID(N'tax_audit.audit_nexus_study', N'U') IS NOT NULL DROP TABLE tax_audit.audit_nexus_study;
GO
CREATE TABLE tax_audit.audit_nexus_study (
    nexus_study_id      BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_nexus_study PRIMARY KEY CLUSTERED (nexus_study_id)
);
GO

-- 19. audit_penalty_claim
IF OBJECT_ID(N'tax_audit.audit_penalty_claim', N'U') IS NOT NULL DROP TABLE tax_audit.audit_penalty_claim;
GO
CREATE TABLE tax_audit.audit_penalty_claim (
    penalty_claim_id    BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_penalty_claim PRIMARY KEY CLUSTERED (penalty_claim_id)
);
GO

-- 20. audit_document_log
IF OBJECT_ID(N'tax_audit.audit_document_log', N'U') IS NOT NULL DROP TABLE tax_audit.audit_document_log;
GO
CREATE TABLE tax_audit.audit_document_log (
    document_log_id     BIGINT IDENTITY(1,1) NOT NULL,
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
    CONSTRAINT PK_audit_document_log PRIMARY KEY CLUSTERED (document_log_id)
);
GO

-- Verification
SELECT t.name AS table_name, COUNT(c.column_id) AS column_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name = N'tax_audit'
  AND t.name IN (
    N'audit_engagement', N'audit_entity_profile', N'audit_partner_allocation',
    N'audit_tax_period_lock', N'audit_gl_balance', N'audit_adjustment_entry',
    N'audit_schedule_m1', N'audit_schedule_k1_line', N'audit_state_apportion',
    N'audit_transfer_price', N'audit_fixed_asset', N'audit_depreciation',
    N'audit_inventory_val', N'audit_ar_aging', N'audit_ap_aging',
    N'audit_payroll_tax', N'audit_sales_tax', N'audit_nexus_study',
    N'audit_penalty_claim', N'audit_document_log'
  )
GROUP BY t.name
ORDER BY t.name;
GO
