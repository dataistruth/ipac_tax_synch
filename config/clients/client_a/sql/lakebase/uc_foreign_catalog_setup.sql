-- =============================================================================
-- Lakebase → Unity Catalog (Lakehouse Federation)
--
-- Exposes client_a control tables (process_log, table_config, v_latest_status)
-- for SQL dashboards with date filters.
--
-- IMPORTANT:
--   - Native Lakebase "Add catalog" (UI) cannot be created via SQL.
--   - This script uses CREATE CONNECTION + CREATE FOREIGN CATALOG instead.
--
-- Where to run:
--   Section A  → Lakebase SQL editor (Postgres)
--   Section B+ → Databricks UC SQL editor (Serverless SQL warehouse)
--
-- Prerequisites:
--   - Secret scope: client-a-secrets (lakebase-username, lakebase-password)
--   - UC privileges: CREATE CONNECTION, CREATE CATALOG (metastore admin)
--   - Postgres user must have SELECT on client_a objects
-- =============================================================================


-- =============================================================================
-- SECTION A — Postgres grants (Lakebase SQL editor)
-- =============================================================================
-- Run as Lakebase admin. client_a_app already has these in grant_client_a_app.sql;
-- re-run only if dashboard uses a different Postgres role.

-- GRANT USAGE ON SCHEMA client_a TO client_a_app;
-- GRANT SELECT ON client_a.process_log TO client_a_app;
-- GRANT SELECT ON client_a.table_config TO client_a_app;
-- GRANT SELECT ON client_a.v_latest_status TO client_a_app;


-- =============================================================================
-- SECTION B — UC connection to Lakebase (UC SQL editor)
-- =============================================================================

CREATE CONNECTION IF NOT EXISTS lakebase_client_a_conn
TYPE POSTGRESQL
OPTIONS (
  host     'ep-divine-flower-d2b43f3x.database.us-east-1.cloud.databricks.com',
  port     '5432',
  user     secret('client-a-secrets', 'lakebase-username'),
  password secret('client-a-secrets', 'lakebase-password')
)
COMMENT 'Lakebase control DB for client_a';

-- Verify:
-- DESCRIBE CONNECTION EXTENDED lakebase_client_a_conn;


-- =============================================================================
-- SECTION C — Foreign catalog (UC SQL editor)
-- =============================================================================

CREATE FOREIGN CATALOG IF NOT EXISTS ipac_lakebase
USING CONNECTION lakebase_client_a_conn
OPTIONS (database 'databricks_postgres');

REFRESH FOREIGN CATALOG ipac_lakebase;

-- Verify:
-- SHOW SCHEMAS IN ipac_lakebase;
-- SHOW TABLES IN ipac_lakebase.client_a;


-- =============================================================================
-- SECTION D — UC tags (UC SQL editor)
-- =============================================================================

ALTER CATALOG ipac_lakebase
SET TAGS ('client_name' = 'client_a');

-- Runtime 16.1+ alternative:
-- SET TAG ON CATALOG ipac_lakebase `client_name` = `client_a`;


-- =============================================================================
-- SECTION E — UC grants for dashboard users (UC SQL editor)
-- =============================================================================
-- Replace principal with your user or group.

-- GRANT USE CATALOG ON CATALOG ipac_lakebase TO `mukesh.singh@databricks.com`;
-- GRANT USE SCHEMA ON SCHEMA ipac_lakebase.client_a TO `mukesh.singh@databricks.com`;
-- GRANT SELECT ON SCHEMA ipac_lakebase.client_a TO `mukesh.singh@databricks.com`;

-- Group example:
-- GRANT USE CATALOG ON CATALOG ipac_lakebase TO `data-engineers`;
-- GRANT USE SCHEMA ON SCHEMA ipac_lakebase.client_a TO `data-engineers`;
-- GRANT SELECT ON SCHEMA ipac_lakebase.client_a TO `data-engineers`;


-- =============================================================================
-- SECTION F — Smoke tests (UC SQL editor)
-- =============================================================================

SELECT COUNT(*) AS log_rows
FROM ipac_lakebase.client_a.process_log;

SELECT
  object_nm,
  status,
  load_mode,
  rows_written,
  error_message,
  start_time,
  end_time,
  duration_sec
FROM ipac_lakebase.client_a.process_log
ORDER BY start_time DESC
LIMIT 20;

SELECT *
FROM ipac_lakebase.client_a.v_latest_status;


-- =============================================================================
-- SECTION G — Dashboard queries (UC SQL editor)
-- =============================================================================
-- Add SQL parameters in the editor:
--   start_date  (Date)
--   end_date    (Date)

-- Runs in date range
SELECT
  log_id,
  job_id,
  object_nm,
  status,
  load_mode,
  rows_written,
  error_message,
  start_time,
  end_time,
  duration_sec
FROM ipac_lakebase.client_a.process_log
WHERE start_time >= CAST(:start_date AS TIMESTAMP)
  AND start_time <  CAST(:end_date AS TIMESTAMP) + INTERVAL 1 DAY
ORDER BY start_time DESC;

-- Failures by table
SELECT
  object_nm,
  COUNT(*) AS failure_count
FROM ipac_lakebase.client_a.process_log
WHERE status = 'FAILED'
  AND start_time >= CAST(:start_date AS TIMESTAMP)
  AND start_time <  CAST(:end_date AS TIMESTAMP) + INTERVAL 1 DAY
GROUP BY object_nm
ORDER BY failure_count DESC;

-- Status summary (KPI)
SELECT
  status,
  COUNT(*) AS run_count
FROM ipac_lakebase.client_a.process_log
WHERE start_time >= CAST(:start_date AS TIMESTAMP)
  AND start_time <  CAST(:end_date AS TIMESTAMP) + INTERVAL 1 DAY
GROUP BY status;


-- =============================================================================
-- SECTION H — Optional convenience view in Delta catalog (UC SQL editor)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS ipac_tax_synch.monitoring;

CREATE OR REPLACE VIEW ipac_tax_synch.monitoring.client_a_process_log AS
SELECT *
FROM ipac_lakebase.client_a.process_log;

ALTER VIEW ipac_tax_synch.monitoring.client_a_process_log
SET TAGS ('client_name' = 'client_a');

-- GRANT USE SCHEMA ON SCHEMA ipac_tax_synch.monitoring TO `mukesh.singh@databricks.com`;
-- GRANT SELECT ON VIEW ipac_tax_synch.monitoring.client_a_process_log
--   TO `mukesh.singh@databricks.com`;


-- =============================================================================
-- SECTION I — Cleanup (UC SQL editor, only if redoing setup)
-- =============================================================================

-- DROP FOREIGN CATALOG IF EXISTS ipac_lakebase;
-- DROP CONNECTION IF EXISTS lakebase_client_a_conn;
