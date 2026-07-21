-- =============================================================================
-- create_wide_fact_tables.sql
-- Two wide fact tables to test the Lakeflow Connect clustering-key limitation:
-- PK column sits at ORDINAL POSITION 40 (beyond the first 32 columns).
-- Run against: free-sql-db-0862313
-- =============================================================================

-- -----------------------------------------------------------------------------
-- FACT 1: dbo.fact_gl_line_detail  (42 columns, PK = gl_line_id at position 40)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.fact_gl_line_detail (
    entity_id           INT             NOT NULL,       -- 1
    period_id           INT             NOT NULL,       -- 2
    partner_id          INT             NULL,           -- 3
    account_code        VARCHAR(20)     NOT NULL,       -- 4
    account_name        VARCHAR(100)    NULL,           -- 5
    account_type        VARCHAR(20)     NULL,           -- 6
    transaction_date    DATE            NOT NULL,       -- 7
    posting_date        DATE            NULL,           -- 8
    fiscal_year         INT             NOT NULL,       -- 9
    fiscal_quarter      TINYINT         NULL,           -- 10
    fiscal_month        TINYINT         NULL,           -- 11
    journal_source      VARCHAR(30)     NULL,           -- 12
    journal_batch       VARCHAR(30)     NULL,           -- 13
    reference_no        VARCHAR(40)     NULL,           -- 14
    description         VARCHAR(200)    NULL,           -- 15
    debit_amount        DECIMAL(18,2)   NULL,           -- 16
    credit_amount       DECIMAL(18,2)   NULL,           -- 17
    net_amount          DECIMAL(18,2)   NULL,           -- 18
    base_currency       CHAR(3)         NULL,           -- 19
    txn_currency        CHAR(3)         NULL,           -- 20
    exchange_rate       DECIMAL(18,6)   NULL,           -- 21
    base_amount         DECIMAL(18,2)   NULL,           -- 22
    book_amount         DECIMAL(18,2)   NULL,           -- 23
    tax_amount          DECIMAL(18,2)   NULL,           -- 24
    m1_adjustment       DECIMAL(18,2)   NULL,           -- 25
    state_amount        DECIMAL(18,2)   NULL,           -- 26
    federal_amount      DECIMAL(18,2)   NULL,           -- 27
    department_code     VARCHAR(20)     NULL,           -- 28
    cost_center         VARCHAR(20)     NULL,           -- 29
    project_code        VARCHAR(20)     NULL,           -- 30
    location_code       VARCHAR(20)     NULL,           -- 31
    intercompany_flag   BIT             NULL,           -- 32
    elimination_flag    BIT             NULL,           -- 33  <-- beyond col 32
    recurring_flag      BIT             NULL,           -- 34
    reversal_flag       BIT             NULL,           -- 35
    source_system       VARCHAR(30)     NULL,           -- 36
    created_by          VARCHAR(50)     NULL,           -- 37
    created_at          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),  -- 38
    updated_at          DATETIME2       NULL,           -- 39
    gl_line_id          BIGINT          IDENTITY(1,1) NOT NULL,             -- 40 = PK
    batch_uuid          UNIQUEIDENTIFIER NULL DEFAULT NEWID(),              -- 41
    is_active           BIT             NOT NULL DEFAULT 1,                 -- 42
    CONSTRAINT PK_fact_gl_line_detail PRIMARY KEY CLUSTERED (gl_line_id)
);
GO

-- -----------------------------------------------------------------------------
-- FACT 2: dbo.fact_k1_allocation_detail (41 columns, PK = k1_line_id at pos 40)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.fact_k1_allocation_detail (
    entity_id               INT             NOT NULL,   -- 1
    partner_id              INT             NOT NULL,   -- 2
    period_id               INT             NOT NULL,   -- 3
    tax_year                INT             NOT NULL,   -- 4
    allocation_method       VARCHAR(30)     NULL,       -- 5
    ownership_pct           DECIMAL(9,6)    NULL,       -- 6
    profit_pct              DECIMAL(9,6)    NULL,       -- 7
    loss_pct                DECIMAL(9,6)    NULL,       -- 8
    capital_pct             DECIMAL(9,6)    NULL,       -- 9
    ordinary_income         DECIMAL(18,2)   NULL,       -- 10
    rental_income           DECIMAL(18,2)   NULL,       -- 11
    interest_income         DECIMAL(18,2)   NULL,       -- 12
    dividend_income         DECIMAL(18,2)   NULL,       -- 13
    royalty_income          DECIMAL(18,2)   NULL,       -- 14
    st_capital_gain         DECIMAL(18,2)   NULL,       -- 15
    lt_capital_gain         DECIMAL(18,2)   NULL,       -- 16
    sec1231_gain            DECIMAL(18,2)   NULL,       -- 17
    other_income            DECIMAL(18,2)   NULL,       -- 18
    sec179_deduction        DECIMAL(18,2)   NULL,       -- 19
    charitable_contrib      DECIMAL(18,2)   NULL,       -- 20
    investment_interest     DECIMAL(18,2)   NULL,       -- 21
    sec59e_expenditure      DECIMAL(18,2)   NULL,       -- 22
    other_deductions        DECIMAL(18,2)   NULL,       -- 23
    se_earnings             DECIMAL(18,2)   NULL,       -- 24
    credits_amount          DECIMAL(18,2)   NULL,       -- 25
    foreign_tax_paid        DECIMAL(18,2)   NULL,       -- 26
    amt_adjustment          DECIMAL(18,2)   NULL,       -- 27
    tax_exempt_interest     DECIMAL(18,2)   NULL,       -- 28
    nondeductible_exp       DECIMAL(18,2)   NULL,       -- 29
    distributions_cash      DECIMAL(18,2)   NULL,       -- 30
    distributions_property  DECIMAL(18,2)   NULL,       -- 31
    capital_beginning       DECIMAL(18,2)   NULL,       -- 32
    capital_contributed     DECIMAL(18,2)   NULL,       -- 33  <-- beyond col 32
    capital_income          DECIMAL(18,2)   NULL,       -- 34
    capital_withdrawn       DECIMAL(18,2)   NULL,       -- 35
    capital_ending          DECIMAL(18,2)   NULL,       -- 36
    state_source_code       VARCHAR(10)     NULL,       -- 37
    created_by              VARCHAR(50)     NULL,       -- 38
    created_at              DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(), -- 39
    k1_line_id              BIGINT          IDENTITY(1,1) NOT NULL,            -- 40 = PK
    is_final                BIT             NOT NULL DEFAULT 0,                -- 41
    CONSTRAINT PK_fact_k1_allocation_detail PRIMARY KEY CLUSTERED (k1_line_id)
);
GO

-- -----------------------------------------------------------------------------
-- Enable Change Tracking (required by Lakeflow Connect CDC)
-- Database-level CT is already on for free-sql-db-0862313; per-table below.
-- -----------------------------------------------------------------------------
ALTER TABLE dbo.fact_gl_line_detail
    ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO

ALTER TABLE dbo.fact_k1_allocation_detail
    ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
GO

-- Sanity check: PK ordinal positions (expect 40 for both)
SELECT t.name AS table_name, c.name AS pk_column, c.column_id AS ordinal_position
FROM sys.tables t
JOIN sys.indexes i        ON i.object_id = t.object_id AND i.is_primary_key = 1
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.name IN ('fact_gl_line_detail', 'fact_k1_allocation_detail');
GO