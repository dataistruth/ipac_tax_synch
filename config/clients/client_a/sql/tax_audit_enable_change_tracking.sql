-- =============================================================================
-- tax_audit_enable_change_tracking.sql
--
-- Enables SQL Server Change Tracking for tax_audit wide tables.
-- Required before Lakeflow Connect CDC can ingest these tables.
--
-- Database : free-sql-db-0862313
-- Schema   : tax_audit
-- Tables   : audit_finding_detail, audit_workpaper_line
--
-- Prerequisite: run tax_audit_create_schema_and_tables.sql first.
-- =============================================================================

USE [free-sql-db-0862313];
GO

------------------------------------------------------------
-- Database-level change tracking
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.change_tracking_databases
    WHERE database_id = DB_ID()
)
BEGIN
    ALTER DATABASE CURRENT
    SET CHANGE_TRACKING = ON (
        CHANGE_RETENTION = 7 DAYS,
        AUTO_CLEANUP = ON
    );
    PRINT 'Database change tracking enabled.';
END
ELSE
    PRINT 'Database change tracking already enabled.';
GO

------------------------------------------------------------
-- Table-level change tracking
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID(N'tax_audit.audit_finding_detail')
)
BEGIN
    ALTER TABLE tax_audit.audit_finding_detail
    ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
    PRINT 'Change tracking enabled: tax_audit.audit_finding_detail';
END
ELSE
    PRINT 'Change tracking already enabled: tax_audit.audit_finding_detail';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID(N'tax_audit.audit_workpaper_line')
)
BEGIN
    ALTER TABLE tax_audit.audit_workpaper_line
    ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);
    PRINT 'Change tracking enabled: tax_audit.audit_workpaper_line';
END
ELSE
    PRINT 'Change tracking already enabled: tax_audit.audit_workpaper_line';
GO

------------------------------------------------------------
-- Verification
------------------------------------------------------------
PRINT '--- tax_audit change tracking status ---';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    CASE WHEN ct.object_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS change_tracking_enabled
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
WHERE s.name = N'tax_audit'
  AND t.name IN (N'audit_finding_detail', N'audit_workpaper_line')
ORDER BY t.name;
GO

SELECT
    DB_NAME() AS database_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()
    ) THEN 'YES' ELSE 'NO' END AS database_change_tracking_enabled;
GO
