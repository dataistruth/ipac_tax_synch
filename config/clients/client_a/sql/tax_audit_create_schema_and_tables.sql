-- =============================================================================
-- tax_audit_create_schema_and_tables.sql
--
-- Creates schema tax_audit and two wide tables (50+ columns each) for CDC /
-- Lakeflow Connect testing against Azure SQL.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
--
-- Run order:
--   1. this file
--   2. tax_audit_enable_change_tracking.sql
--   3. tax_audit_insert_seed.sql
-- =============================================================================

USE [free-sql-db-0862313];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'tax_audit')
    EXEC(N'CREATE SCHEMA tax_audit AUTHORIZATION dbo;');
GO

-- -----------------------------------------------------------------------------
-- TABLE 1: tax_audit.audit_finding_detail  (54 columns, PK at position 52)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'tax_audit.audit_finding_detail', N'U') IS NOT NULL
    DROP TABLE tax_audit.audit_finding_detail;
GO

CREATE TABLE tax_audit.audit_finding_detail (
    entity_id               INT             NOT NULL,       --  1
    period_id               INT             NOT NULL,       --  2
    partner_id              INT             NULL,           --  3
    finding_code            VARCHAR(20)     NOT NULL,       --  4
    finding_title           VARCHAR(200)    NOT NULL,       --  5
    finding_category        VARCHAR(50)     NOT NULL,       --  6
    risk_level              VARCHAR(20)     NOT NULL,       --  7
    audit_area              VARCHAR(50)     NOT NULL,       --  8
    tax_year                INT             NOT NULL,       --  9
    fiscal_quarter          TINYINT         NULL,           -- 10
    fiscal_month            TINYINT         NULL,           -- 11
    jurisdiction_code       VARCHAR(10)     NULL,           -- 12
    form_type               VARCHAR(20)     NULL,           -- 13
    line_reference          VARCHAR(30)     NULL,           -- 14
    finding_status          VARCHAR(30)     NOT NULL,       -- 15
    severity_score          DECIMAL(9,2)    NULL,           -- 16
    materiality_threshold   DECIMAL(18,2)   NULL,           -- 17
    exposure_amount         DECIMAL(18,2)   NULL,           -- 18
    adjusted_amount         DECIMAL(18,2)   NULL,           -- 19
    penalty_estimate        DECIMAL(18,2)   NULL,           -- 20
    interest_estimate       DECIMAL(18,2)   NULL,           -- 21
    currency_code           CHAR(3)         NOT NULL,       -- 22
    exchange_rate           DECIMAL(18,6)   NULL,           -- 23
    base_amount             DECIMAL(18,2)   NULL,           -- 24
    state_amount            DECIMAL(18,2)   NULL,           -- 25
    federal_amount          DECIMAL(18,2)   NULL,           -- 26
    local_amount            DECIMAL(18,2)   NULL,           -- 27
    m1_adjustment           DECIMAL(18,2)   NULL,           -- 28
    m2_adjustment           DECIMAL(18,2)   NULL,           -- 29
    m3_adjustment           DECIMAL(18,2)   NULL,           -- 30
    book_difference         DECIMAL(18,2)   NULL,           -- 31
    tax_difference          DECIMAL(18,2)   NULL,           -- 32
    reviewer_id             INT             NULL,           -- 33
    preparer_id             INT             NULL,           -- 34
    manager_id              INT             NULL,           -- 35
    engagement_code         VARCHAR(30)     NULL,           -- 36
    workpaper_ref           VARCHAR(40)     NULL,           -- 37
    source_document         VARCHAR(100)    NULL,           -- 38
    sampling_method         VARCHAR(30)     NULL,           -- 39
    sample_size             INT             NULL,           -- 40
    population_size         INT             NULL,           -- 41
    exception_rate          DECIMAL(9,4)    NULL,           -- 42
    root_cause              VARCHAR(200)    NULL,           -- 43
    remediation_plan        VARCHAR(500)    NULL,           -- 44
    remediation_due_date    DATE            NULL,           -- 45
    remediation_owner       VARCHAR(100)    NULL,           -- 46
    is_repeat_finding       BIT             NOT NULL DEFAULT 0, -- 47
    is_significant          BIT             NOT NULL DEFAULT 0, -- 48
    is_reportable           BIT             NOT NULL DEFAULT 0, -- 49
    requires_disclosure     BIT             NOT NULL DEFAULT 0, -- 50
    notes                   VARCHAR(500)    NULL,           -- 51
    finding_id              BIGINT          IDENTITY(1,1) NOT NULL, -- 52 = PK
    batch_uuid              UNIQUEIDENTIFIER NULL DEFAULT NEWID(),  -- 53
    is_active               BIT             NOT NULL DEFAULT 1,     -- 54
    CONSTRAINT PK_audit_finding_detail PRIMARY KEY CLUSTERED (finding_id)
);
GO

-- -----------------------------------------------------------------------------
-- TABLE 2: tax_audit.audit_workpaper_line  (56 columns, PK at position 54)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'tax_audit.audit_workpaper_line', N'U') IS NOT NULL
    DROP TABLE tax_audit.audit_workpaper_line;
GO

CREATE TABLE tax_audit.audit_workpaper_line (
    entity_id               INT             NOT NULL,       --  1
    period_id               INT             NOT NULL,       --  2
    partner_id              INT             NULL,           --  3
    workpaper_code          VARCHAR(20)     NOT NULL,       --  4
    workpaper_title         VARCHAR(200)    NOT NULL,       --  5
    section_code            VARCHAR(30)     NOT NULL,       --  6
    subsection_code         VARCHAR(30)     NULL,           --  7
    line_no                 INT             NOT NULL,       --  8
    account_code            VARCHAR(20)     NULL,           --  9
    account_name            VARCHAR(100)    NULL,           -- 10
    account_type            VARCHAR(20)     NULL,           -- 11
    tax_year                INT             NOT NULL,       -- 12
    fiscal_quarter          TINYINT         NULL,           -- 13
    fiscal_month            TINYINT         NULL,           -- 14
    transaction_date        DATE            NULL,           -- 15
    posting_date            DATE            NULL,           -- 16
    journal_source          VARCHAR(30)     NULL,           -- 17
    journal_batch           VARCHAR(30)     NULL,           -- 18
    reference_no            VARCHAR(40)     NULL,           -- 19
    description             VARCHAR(200)    NULL,           -- 20
    debit_amount            DECIMAL(18,2)   NULL,           -- 21
    credit_amount           DECIMAL(18,2)   NULL,           -- 22
    net_amount              DECIMAL(18,2)   NULL,           -- 23
    tax_basis_amount        DECIMAL(18,2)   NULL,           -- 24
    gaap_amount             DECIMAL(18,2)   NULL,           -- 25
    permanent_diff          DECIMAL(18,2)   NULL,           -- 26
    temporary_diff          DECIMAL(18,2)   NULL,           -- 27
    state_amount            DECIMAL(18,2)   NULL,           -- 28
    federal_amount          DECIMAL(18,2)   NULL,           -- 29
    foreign_amount          DECIMAL(18,2)   NULL,           -- 30
    currency_code           CHAR(3)         NOT NULL,       -- 31
    exchange_rate           DECIMAL(18,6)   NULL,           -- 32
    department_code         VARCHAR(20)     NULL,           -- 33
    cost_center             VARCHAR(20)     NULL,           -- 34
    project_code            VARCHAR(20)     NULL,           -- 35
    location_code           VARCHAR(20)     NULL,           -- 36
    preparer_id             INT             NULL,           -- 37
    reviewer_id             INT             NULL,           -- 38
    manager_id              INT             NULL,           -- 39
    engagement_code         VARCHAR(30)     NULL,           -- 40
    source_system           VARCHAR(30)     NULL,           -- 41
    source_table            VARCHAR(50)     NULL,           -- 42
    source_key              VARCHAR(50)     NULL,           -- 43
    tie_out_status          VARCHAR(20)     NULL,           -- 44
    tie_out_variance        DECIMAL(18,2)   NULL,           -- 45
    support_doc_ref         VARCHAR(100)    NULL,           -- 46
    sampling_flag           BIT             NOT NULL DEFAULT 0, -- 47
    tested_flag             BIT             NOT NULL DEFAULT 0, -- 48
    exception_flag          BIT             NOT NULL DEFAULT 0, -- 49
    signoff_status          VARCHAR(20)     NULL,           -- 50
    signoff_date            DATE            NULL,           -- 51
    created_by              VARCHAR(50)     NULL,           -- 52
    created_at              DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(), -- 53
    workpaper_line_id       BIGINT          IDENTITY(1,1) NOT NULL, -- 54 = PK
    updated_at              DATETIME2       NULL,           -- 55
    is_active               BIT             NOT NULL DEFAULT 1,     -- 56
    CONSTRAINT PK_audit_workpaper_line PRIMARY KEY CLUSTERED (workpaper_line_id)
);
GO

-- Sanity check: column counts (expect >= 50)
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    COUNT(c.column_id) AS column_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name = N'tax_audit'
  AND t.name IN (N'audit_finding_detail', N'audit_workpaper_line')
GROUP BY s.name, t.name
ORDER BY t.name;
GO
