-- =============================================================================
-- Client A — Source SQL Server DDL
-- Small business: 5 partners, multiple entities, tax filings (IPAC practice)
-- Run once to create tables, then enable Change Tracking on each.
--
-- After running this script, enable Change Tracking:
--   1. Enable on database:
--      ALTER DATABASE free-sql-db-0862313
--      SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON);
--
--   2. Enable on each table (run the block at the bottom of this file)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Partners — the 5 partners in the practice/business
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.partners (
    partner_id        INT           IDENTITY(1,1) PRIMARY KEY,
    partner_code      VARCHAR(10)   NOT NULL UNIQUE,        -- e.g. P001
    first_name        VARCHAR(100)  NOT NULL,
    last_name         VARCHAR(100)  NOT NULL,
    email             VARCHAR(255)  NOT NULL,
    tax_id_ssn        VARCHAR(20)   NOT NULL,               -- SSN (masked in prod)
    ownership_pct     DECIMAL(5,2)  NOT NULL,               -- % ownership across entities
    partner_since     DATE          NOT NULL,
    is_active         BIT           NOT NULL DEFAULT 1,
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 2. Business Entities — LLC, S-Corp, Partnership etc.
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.business_entities (
    entity_id         INT           IDENTITY(1,1) PRIMARY KEY,
    entity_code       VARCHAR(20)   NOT NULL UNIQUE,        -- e.g. ALPHA-LLC
    entity_name       VARCHAR(255)  NOT NULL,
    entity_type       VARCHAR(50)   NOT NULL,               -- LLC / S-Corp / Partnership / C-Corp
    ein               VARCHAR(20)   NOT NULL UNIQUE,        -- Employer Identification Number
    state_of_formation VARCHAR(2)   NOT NULL,               -- e.g. DE, TX
    fiscal_year_end   VARCHAR(5)    NOT NULL DEFAULT '12/31',
    is_active         BIT           NOT NULL DEFAULT 1,
    formed_date       DATE          NOT NULL,
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 3. Partner Entity Ownership — which partner owns what % in each entity
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.partner_entity_ownership (
    ownership_id      INT           IDENTITY(1,1) PRIMARY KEY,
    partner_id        INT           NOT NULL REFERENCES dbo.partners(partner_id),
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    ownership_pct     DECIMAL(5,2)  NOT NULL,               -- % in this specific entity
    effective_from    DATE          NOT NULL,
    effective_to      DATE          NULL,                   -- NULL = currently active
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT uq_partner_entity UNIQUE (partner_id, entity_id, effective_from)
);

-- -----------------------------------------------------------------------------
-- 4. Tax Filing Periods — fiscal/tax years per entity
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.tax_filing_periods (
    period_id         INT           IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    tax_year          INT           NOT NULL,               -- e.g. 2024
    period_start      DATE          NOT NULL,
    period_end        DATE          NOT NULL,
    filing_type       VARCHAR(50)   NOT NULL,               -- Federal / State / Local
    form_type         VARCHAR(20)   NOT NULL,               -- 1065 / 1120S / 1120 / 1040
    status            VARCHAR(30)   NOT NULL DEFAULT 'PENDING', -- PENDING/IN_PROGRESS/FILED/AMENDED
    due_date          DATE          NOT NULL,
    extended_due_date DATE          NULL,
    filed_date        DATE          NULL,
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT uq_entity_period UNIQUE (entity_id, tax_year, filing_type, form_type)
);

-- -----------------------------------------------------------------------------
-- 5. General Ledger Transactions — financial activity per entity
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.gl_transactions (
    transaction_id    BIGINT        IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    transaction_date  DATE          NOT NULL,
    fiscal_year       INT           NOT NULL,
    fiscal_quarter    TINYINT       NOT NULL,               -- 1-4
    account_code      VARCHAR(20)   NOT NULL,               -- chart of accounts code
    account_name      VARCHAR(255)  NOT NULL,
    account_type      VARCHAR(50)   NOT NULL,               -- REVENUE/EXPENSE/ASSET/LIABILITY/EQUITY
    debit_amount      DECIMAL(18,2) NOT NULL DEFAULT 0,
    credit_amount     DECIMAL(18,2) NOT NULL DEFAULT 0,
    description       VARCHAR(500)  NULL,
    reference_no      VARCHAR(100)  NULL,
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 6. K1 Distributions — partner K-1 allocations per entity per year
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.k1_distributions (
    k1_id             INT           IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    partner_id        INT           NOT NULL REFERENCES dbo.partners(partner_id),
    tax_year          INT           NOT NULL,
    ordinary_income   DECIMAL(18,2) NOT NULL DEFAULT 0,
    guaranteed_pymts  DECIMAL(18,2) NOT NULL DEFAULT 0,
    capital_gains     DECIMAL(18,2) NOT NULL DEFAULT 0,
    self_employ_inc   DECIMAL(18,2) NOT NULL DEFAULT 0,
    distributions     DECIMAL(18,2) NOT NULL DEFAULT 0,    -- cash distributions
    ending_capital    DECIMAL(18,2) NOT NULL DEFAULT 0,    -- partner capital account
    status            VARCHAR(20)   NOT NULL DEFAULT 'DRAFT', -- DRAFT/FINAL/AMENDED
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT uq_k1 UNIQUE (entity_id, partner_id, tax_year)
);

-- -----------------------------------------------------------------------------
-- 7. Tax Adjustments — book-to-tax differences and adjustments
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.tax_adjustments (
    adjustment_id     INT           IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    period_id         INT           NOT NULL REFERENCES dbo.tax_filing_periods(period_id),
    adjustment_type   VARCHAR(100)  NOT NULL,               -- DEPRECIATION/MEALS/HOME_OFFICE/179_DEDUCTION
    book_amount       DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_amount        DECIMAL(18,2) NOT NULL DEFAULT 0,
    difference        AS (tax_amount - book_amount),        -- computed column
    notes             VARCHAR(1000) NULL,
    approved_by       VARCHAR(100)  NULL,
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 8. Estimated Tax Payments — quarterly estimated payments per partner/entity
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.estimated_tax_payments (
    payment_id        INT           IDENTITY(1,1) PRIMARY KEY,
    partner_id        INT           NOT NULL REFERENCES dbo.partners(partner_id),
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    tax_year          INT           NOT NULL,
    quarter           TINYINT       NOT NULL,               -- 1=Apr / 2=Jun / 3=Sep / 4=Jan
    due_date          DATE          NOT NULL,
    federal_amount    DECIMAL(18,2) NOT NULL DEFAULT 0,
    state_amount      DECIMAL(18,2) NOT NULL DEFAULT 0,
    payment_date      DATE          NULL,
    payment_method    VARCHAR(50)   NULL,                   -- EFTPS / CHECK / WIRE
    confirmation_no   VARCHAR(100)  NULL,
    status            VARCHAR(20)   NOT NULL DEFAULT 'PENDING', -- PENDING/PAID/LATE
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 9. Document Tracker — tax documents, returns, workpapers
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.document_tracker (
    document_id       INT           IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    period_id         INT           NULL REFERENCES dbo.tax_filing_periods(period_id),
    document_type     VARCHAR(100)  NOT NULL,               -- TAX_RETURN/W2/1099/WORKPAPER/ENGAGEMENT_LETTER
    document_name     VARCHAR(255)  NOT NULL,
    tax_year          INT           NOT NULL,
    received_date     DATE          NULL,
    reviewed_by       VARCHAR(100)  NULL,
    review_status     VARCHAR(30)   NOT NULL DEFAULT 'PENDING', -- PENDING/REVIEWED/APPROVED
    storage_ref       VARCHAR(500)  NULL,                   -- file path / SharePoint ref
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- -----------------------------------------------------------------------------
-- 10. Billing & Engagements — billing per entity per engagement
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.billing_engagements (
    engagement_id     INT           IDENTITY(1,1) PRIMARY KEY,
    entity_id         INT           NOT NULL REFERENCES dbo.business_entities(entity_id),
    engagement_type   VARCHAR(100)  NOT NULL,               -- TAX_PREP / ADVISORY / AUDIT_SUPPORT
    tax_year          INT           NOT NULL,
    engagement_date   DATE          NOT NULL,
    partner_id        INT           NOT NULL REFERENCES dbo.partners(partner_id), -- responsible partner
    budgeted_hours    DECIMAL(8,2)  NOT NULL DEFAULT 0,
    actual_hours      DECIMAL(8,2)  NOT NULL DEFAULT 0,
    billing_rate      DECIMAL(10,2) NOT NULL DEFAULT 0,     -- $ per hour
    billed_amount     DECIMAL(18,2) NOT NULL DEFAULT 0,
    paid_amount       DECIMAL(18,2) NOT NULL DEFAULT 0,
    invoice_date      DATE          NULL,
    payment_date      DATE          NULL,
    status            VARCHAR(30)   NOT NULL DEFAULT 'IN_PROGRESS', -- IN_PROGRESS/BILLED/PAID/WRITTEN_OFF
    created_at        DATETIME2     NOT NULL DEFAULT GETDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETDATE()
);

-- =============================================================================
-- Enable Change Tracking on each table
-- Run AFTER enabling CT on the database (see instructions at top)
-- =============================================================================

ALTER TABLE dbo.partners                  ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.business_entities         ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.partner_entity_ownership  ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.tax_filing_periods        ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.gl_transactions           ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.k1_distributions          ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.tax_adjustments           ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.estimated_tax_payments    ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.document_tracker          ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
ALTER TABLE dbo.billing_engagements       ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);