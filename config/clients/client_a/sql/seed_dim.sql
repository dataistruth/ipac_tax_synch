-- =============================================================================
-- seed_dim.sql — Dimension table seed data (run ONCE)
-- Static reference data: partners, entities, ownership, filing periods, docs
-- Safe to re-run — uses MERGE so no duplicates
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Partners
-- -----------------------------------------------------------------------------
MERGE dbo.partners AS target
USING (VALUES
    ('P001', 'James',   'Whitfield',  'j.whitfield@alphacorp.com',  '123-45-6789', 30.00, '2015-01-01'),
    ('P002', 'Sarah',   'Nguyen',     's.nguyen@alphacorp.com',     '234-56-7890', 25.00, '2015-01-01'),
    ('P003', 'Michael', 'Okafor',     'm.okafor@alphacorp.com',     '345-67-8901', 20.00, '2016-06-01'),
    ('P004', 'Linda',   'Carmichael', 'l.carmichael@alphacorp.com', '456-78-9012', 15.00, '2018-03-01'),
    ('P005', 'David',   'Torres',     'd.torres@alphacorp.com',     '567-89-0123', 10.00, '2020-09-01')
) AS source (partner_code, first_name, last_name, email, tax_id_ssn, ownership_pct, partner_since)
ON target.partner_code = source.partner_code
WHEN NOT MATCHED THEN
    INSERT (partner_code, first_name, last_name, email, tax_id_ssn, ownership_pct, partner_since)
    VALUES (source.partner_code, source.first_name, source.last_name, source.email,
            source.tax_id_ssn, source.ownership_pct, source.partner_since);

PRINT 'partners: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 2. Business Entities
-- -----------------------------------------------------------------------------
MERGE dbo.business_entities AS target
USING (VALUES
    ('ALPHA-LLC',   'Alpha Holdings LLC',          'LLC',         '81-1234567', 'DE', '12/31', '2015-01-01'),
    ('BETA-SCORP',  'Beta Services S-Corp',         'S-Corp',      '82-2345678', 'TX', '12/31', '2016-06-01'),
    ('GAMMA-PTNR',  'Gamma Real Estate Partners',   'Partnership', '83-3456789', 'FL', '12/31', '2018-03-01'),
    ('DELTA-CCORP', 'Delta Tech Solutions C-Corp',   'C-Corp',      '84-4567890', 'CA', '12/31', '2020-09-01')
) AS source (entity_code, entity_name, entity_type, ein, state_of_formation, fiscal_year_end, formed_date)
ON target.entity_code = source.entity_code
WHEN NOT MATCHED THEN
    INSERT (entity_code, entity_name, entity_type, ein, state_of_formation, fiscal_year_end, formed_date)
    VALUES (source.entity_code, source.entity_name, source.entity_type, source.ein,
            source.state_of_formation, source.fiscal_year_end, source.formed_date);

PRINT 'business_entities: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 3. Partner Entity Ownership
-- -----------------------------------------------------------------------------
MERGE dbo.partner_entity_ownership AS target
USING (
    SELECT p.partner_id, e.entity_id, v.ownership_pct, v.effective_from
    FROM (VALUES
        ('P001', 'ALPHA-LLC',   30.00, '2015-01-01'),
        ('P002', 'ALPHA-LLC',   25.00, '2015-01-01'),
        ('P003', 'ALPHA-LLC',   20.00, '2016-06-01'),
        ('P004', 'ALPHA-LLC',   15.00, '2018-03-01'),
        ('P005', 'ALPHA-LLC',   10.00, '2020-09-01'),
        ('P001', 'BETA-SCORP',  40.00, '2016-06-01'),
        ('P002', 'BETA-SCORP',  35.00, '2016-06-01'),
        ('P003', 'BETA-SCORP',  25.00, '2016-06-01'),
        ('P001', 'GAMMA-PTNR',  50.00, '2018-03-01'),
        ('P004', 'GAMMA-PTNR',  30.00, '2018-03-01'),
        ('P005', 'GAMMA-PTNR',  20.00, '2018-03-01'),
        ('P002', 'DELTA-CCORP', 45.00, '2020-09-01'),
        ('P003', 'DELTA-CCORP', 35.00, '2020-09-01'),
        ('P005', 'DELTA-CCORP', 20.00, '2020-09-01')
    ) v (partner_code, entity_code, ownership_pct, effective_from)
    JOIN dbo.partners p           ON p.partner_code = v.partner_code
    JOIN dbo.business_entities e  ON e.entity_code  = v.entity_code
) AS source ON target.partner_id     = source.partner_id
           AND target.entity_id      = source.entity_id
           AND target.effective_from = source.effective_from
WHEN NOT MATCHED THEN
    INSERT (partner_id, entity_id, ownership_pct, effective_from)
    VALUES (source.partner_id, source.entity_id, source.ownership_pct, source.effective_from);

PRINT 'partner_entity_ownership: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 4. Tax Filing Periods
-- -----------------------------------------------------------------------------
MERGE dbo.tax_filing_periods AS target
USING (
    SELECT e.entity_id, v.tax_year, v.period_start, v.period_end,
           v.filing_type, v.form_type, v.status, v.due_date
    FROM (VALUES
        ('ALPHA-LLC',   2024, '2024-01-01', '2024-12-31', 'Federal', '1065',  'FILED',       '2025-03-15'),
        ('ALPHA-LLC',   2024, '2024-01-01', '2024-12-31', 'State',   '1065',  'FILED',       '2025-04-15'),
        ('BETA-SCORP',  2024, '2024-01-01', '2024-12-31', 'Federal', '1120S', 'FILED',       '2025-03-15'),
        ('GAMMA-PTNR',  2024, '2024-01-01', '2024-12-31', 'Federal', '1065',  'FILED',       '2025-03-15'),
        ('DELTA-CCORP', 2024, '2024-01-01', '2024-12-31', 'Federal', '1120',  'FILED',       '2025-04-15'),
        ('ALPHA-LLC',   2025, '2025-01-01', '2025-12-31', 'Federal', '1065',  'IN_PROGRESS', '2026-03-15'),
        ('BETA-SCORP',  2025, '2025-01-01', '2025-12-31', 'Federal', '1120S', 'IN_PROGRESS', '2026-03-15'),
        ('GAMMA-PTNR',  2025, '2025-01-01', '2025-12-31', 'Federal', '1065',  'PENDING',     '2026-03-15'),
        ('DELTA-CCORP', 2025, '2025-01-01', '2025-12-31', 'Federal', '1120',  'PENDING',     '2026-04-15')
    ) v (entity_code, tax_year, period_start, period_end, filing_type, form_type, status, due_date)
    JOIN dbo.business_entities e ON e.entity_code = v.entity_code
) AS source ON target.entity_id   = source.entity_id
           AND target.tax_year    = source.tax_year
           AND target.filing_type = source.filing_type
           AND target.form_type   = source.form_type
WHEN NOT MATCHED THEN
    INSERT (entity_id, tax_year, period_start, period_end, filing_type, form_type, status, due_date)
    VALUES (source.entity_id, source.tax_year, source.period_start, source.period_end,
            source.filing_type, source.form_type, source.status, source.due_date);

PRINT 'tax_filing_periods: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

-- -----------------------------------------------------------------------------
-- 5. Document Tracker (initial documents)
-- -----------------------------------------------------------------------------
MERGE dbo.document_tracker AS target
USING (
    SELECT e.entity_id, v.document_type, v.document_name, v.tax_year, v.received_date, v.review_status
    FROM (VALUES
        ('ALPHA-LLC',   'ENGAGEMENT_LETTER', 'Engagement Letter 2025',        2025, '2025-01-15', 'APPROVED'),
        ('ALPHA-LLC',   'WORKPAPER',         'Prior Year Trial Balance 2024',  2024, '2025-02-01', 'APPROVED'),
        ('BETA-SCORP',  'ENGAGEMENT_LETTER', 'Engagement Letter 2025',         2025, '2025-01-20', 'APPROVED'),
        ('BETA-SCORP',  'W2',                'W-2 Summary 2024',               2024, '2025-02-10', 'REVIEWED'),
        ('GAMMA-PTNR',  'ENGAGEMENT_LETTER', 'Engagement Letter 2025',         2025, '2025-01-18', 'APPROVED'),
        ('GAMMA-PTNR',  'WORKPAPER',         'Depreciation Schedule 2024',     2024, '2025-03-01', 'REVIEWED'),
        ('DELTA-CCORP', 'ENGAGEMENT_LETTER', 'Engagement Letter 2025',         2025, '2025-01-22', 'APPROVED'),
        ('DELTA-CCORP', 'WORKPAPER',         'R&D Credit Study 2024',          2024, '2025-03-10', 'PENDING')
    ) v (entity_code, document_type, document_name, tax_year, received_date, review_status)
    JOIN dbo.business_entities e ON e.entity_code = v.entity_code
) AS source ON target.entity_id    = source.entity_id
           AND target.document_name = source.document_name
           AND target.tax_year      = source.tax_year
WHEN NOT MATCHED THEN
    INSERT (entity_id, document_type, document_name, tax_year, received_date, review_status)
    VALUES (source.entity_id, source.document_type, source.document_name,
            source.tax_year, source.received_date, source.review_status);

PRINT 'document_tracker: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows merged';

PRINT '--- Dimension seed complete ---';