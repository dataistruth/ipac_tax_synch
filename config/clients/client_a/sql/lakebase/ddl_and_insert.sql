-- =============================================================================
-- ipac_control_db — per-client control schema (run once per client)
-- This file: client_a. For a new client, replace the schema name only.
--
-- Two tables:
--   client_a.table_config  -> what/how to load + last CT version (updated post-load)
--   client_a.process_log   -> one row per task execution (ingress/transform/egress)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS client_a;

-- -----------------------------------------------------------------------------
-- 1. table_config
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS client_a.table_config (
    src_schema_nm     varchar(128) NOT NULL DEFAULT 'dbo',
    src_tbl_nm        varchar(128) NOT NULL,
    primary_key       varchar(512) NOT NULL,              -- csv: 'entity_id,partner_id'
    is_active         char(1)      NOT NULL DEFAULT 'Y'
                      CHECK (is_active IN ('Y','N')),
    target_schema     varchar(128) NOT NULL,              -- UC schema e.g. 'client_a_raw'
    target_tbl_nm     varchar(128) NOT NULL,
    tbl_size          varchar(10)  NOT NULL DEFAULT 'small'
                      CHECK (tbl_size IN ('small','medium','large')),
    load_mode         varchar(10)  NOT NULL DEFAULT 'incr'
                      CHECK (load_mode IN ('full','incr')),
    scd_type          smallint     NOT NULL DEFAULT 1
                      CHECK (scd_type IN (1,2)),
    cluster_keys      varchar(512),                       -- csv, Delta CLUSTER BY
    select_cols       text          DEFAULT '*',          -- '*' = all columns;
                                                          -- csv = only these cols (PK cols
                                                          -- auto-included even if omitted)
    sequence_key      varchar(128),                       -- ordering col for SCD2 / dedup
                                                          -- (default: SYS_CHANGE_VERSION)
    last_ct_version   bigint       NOT NULL DEFAULT 0,    -- 0 = never loaded -> snapshot
    -- ── additions ─────────────────────────────────────────────────────────────
    track_deletes     char(1)      NOT NULL DEFAULT 'Y'  -- apply CT 'D' rows to target
                      CHECK (track_deletes IN ('Y','N')),
    load_priority     int          NOT NULL DEFAULT 100,  -- lower loads first (dims->facts)
    last_full_load_dttm timestamptz,                      -- when snapshot last ran
                                                          -- (CT retention-expiry recovery)
    last_status       varchar(20),                        -- denormalized from process_log
                                                          -- for quick "what's red" queries
    insert_dttm       timestamptz  NOT NULL DEFAULT now(),
    update_dttm       timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (src_schema_nm, src_tbl_nm)
);

-- -----------------------------------------------------------------------------
-- 2. process_log
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS client_a.process_log (
    log_id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id            varchar(64)  NOT NULL,              -- {{job.run_id}}
    task_id           varchar(64)  NOT NULL,              -- {{task.run_id}}
    task_type         varchar(20)  NOT NULL
                      CHECK (task_type IN ('ingress','transform','egress')),
    -- ── additions ─────────────────────────────────────────────────────────────
    object_nm         varchar(256),                       -- which table/dataset this row is
                                                          -- about (one log row per table,
                                                          -- not per task, for pinpointing)
    load_mode         varchar(10),                        -- what actually ran: 'full'|'incr'
                                                          -- (incr can fall back to full)
    ct_version_from   bigint,                             -- delta window read
    ct_version_to     bigint,
    rows_read         bigint,
    rows_written      bigint,
    rows_deleted      bigint,                             -- CT 'D' rows applied
    error_message     text,
    -- ──────────────────────────────────────────────────────────────────────────
    start_time        timestamptz  NOT NULL DEFAULT now(),
    end_time          timestamptz,
    duration_sec      numeric(10,2) GENERATED ALWAYS AS
                      (EXTRACT(EPOCH FROM (end_time - start_time))) STORED,
    status            varchar(20)  NOT NULL DEFAULT 'RUNNING'
                      CHECK (status IN ('RUNNING','SUCCESS','FAILED','SKIPPED'))
);

CREATE INDEX IF NOT EXISTS ix_process_log_job    ON client_a.process_log (job_id);
CREATE INDEX IF NOT EXISTS ix_process_log_object ON client_a.process_log (object_nm, start_time DESC);

-- -----------------------------------------------------------------------------
-- Monitoring view: latest run per object
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW client_a.v_latest_status AS
SELECT DISTINCT ON (task_type, object_nm)
       task_type, object_nm, load_mode, status,
       rows_read, rows_written, rows_deleted,
       ct_version_from, ct_version_to,
       start_time, end_time, duration_sec, error_message
FROM client_a.process_log
ORDER BY task_type, object_nm, start_time DESC;

-- -----------------------------------------------------------------------------
-- Seed: all 12 client_a tables (verify PK names vs create_tables.sql)
-- -----------------------------------------------------------------------------
INSERT INTO client_a.table_config
    (src_tbl_nm, primary_key, target_schema, target_tbl_nm,
     tbl_size, load_mode, load_priority, is_active, select_cols)
VALUES
    -- ── dims (full reload, high priority) ────────────────────────────────────
    ('partners',                 'partner_id',                    'client_a_raw', 'partners',                 'small',  'full', 10,  'Y',  '*'),
    ('business_entities',        'entity_id',                     'client_a_raw', 'business_entities',        'small',  'full', 10,  'Y',  '*'),
    ('partner_entity_ownership', 'entity_id,partner_id',          'client_a_raw', 'partner_entity_ownership', 'small',  'full', 20,  'Y',  '*'),
    ('tax_filing_periods',       'filing_id',                     'client_a_raw', 'tax_filing_periods',       'small',  'full', 20,  'Y',  '*'),

    -- ── transactional (CT incremental) ───────────────────────────────────────
    ('gl_transactions',          'transaction_id',                'client_a_raw', 'gl_transactions',          'medium', 'incr', 100, 'Y',  '*'),
    ('k1_distributions',         'entity_id,partner_id,tax_year', 'client_a_raw', 'k1_distributions',         'small',  'incr', 100, 'Y',  '*'),
    ('tax_adjustments',          'adjustment_id',                 'client_a_raw', 'tax_adjustments',          'small',  'incr', 100, 'Y',  '*'),
    ('estimated_tax_payments',   'payment_id',                    'client_a_raw', 'estimated_tax_payments',   'small',  'incr', 100, 'Y',  '*'),
    ('document_tracker',         'document_id',                   'client_a_raw', 'document_tracker',         'small',  'incr', 100, 'Y',  '*'),
    ('billing_engagements',      'engagement_id',                 'client_a_raw', 'billing_engagements',      'small',  'incr', 100, 'Y',  '*'),

    -- ── wide fact tables (inactive; select_cols keeps PK within 32-col window)
    ('fact_gl_line_detail',        'gl_line_id',  'client_a_raw', 'fact_gl_line_detail',        'large', 'incr', 200, 'N',
     'gl_line_id,transaction_id,entity_id,partner_id,account_code,amount,line_description,posting_date'),
    ('fact_k1_allocation_detail',  'k1_alloc_id', 'client_a_raw', 'fact_k1_allocation_detail',  'large', 'incr', 200, 'N',
     'k1_alloc_id,entity_id,partner_id,tax_year,allocation_type,allocated_amount,effective_date')
ON CONFLICT (src_schema_nm, src_tbl_nm) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Post-load version commit (what the job runs after a successful MERGE)
-- -----------------------------------------------------------------------------
-- UPDATE client_a.table_config
--    SET last_ct_version = %(new_version)s,
--        last_status     = 'SUCCESS',
--        update_dttm     = now()
--  WHERE src_schema_nm = %(schema)s AND src_tbl_nm = %(table)s;
