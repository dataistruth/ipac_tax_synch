-- =============================================================================
-- Lakebase / Postgres — grants for client_a_app on schema client_a
--
-- Run as admin in Lakebase SQL editor (or psql connected as owner/superuser).
-- User client_a_app is used by notebooks via secret scope client-a-secrets.
--
-- Required for:
--   get_active_tables.py          → SELECT table_config
--   ingest_tables_from_sql_server → INSERT process_log, UPDATE table_config
--   update_lakebase.py            → UPDATE table_config, INSERT process_log
-- =============================================================================

-- 1) Schema access
GRANT USAGE ON SCHEMA client_a TO client_a_app;

-- 2) table_config — read active tables + update CT watermark
GRANT SELECT, UPDATE ON client_a.table_config TO client_a_app;

-- 3) process_log — write run status per table/job
GRANT SELECT, INSERT ON client_a.process_log TO client_a_app;

-- 4) Identity column on process_log (Postgres 10+)
GRANT USAGE, SELECT ON SEQUENCE client_a.process_log_log_id_seq TO client_a_app;

-- 5) Monitoring view (optional read)
GRANT SELECT ON client_a.v_latest_status TO client_a_app;

-- 6) Default privileges for future tables in this schema (optional)
ALTER DEFAULT PRIVILEGES IN SCHEMA client_a
    GRANT SELECT, INSERT, UPDATE ON TABLES TO client_a_app;

-- -----------------------------------------------------------------------------
-- Verify (run as admin — shows grants for client_a_app)
-- -----------------------------------------------------------------------------
SELECT
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'client_a_app'
  AND table_schema = 'client_a'
ORDER BY table_name, privilege_type;

-- -----------------------------------------------------------------------------
-- Test as client_a_app (connect as client_a_app, then run):
-- -----------------------------------------------------------------------------
-- SET search_path TO client_a, public;
-- SELECT COUNT(*) FROM table_config WHERE is_active = 'Y';
-- INSERT INTO process_log (job_id, task_id, task_type, object_nm, status)
-- VALUES ('test', 'test', 'ingress', 'partners', 'RUNNING');
