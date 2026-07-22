/*
    sales_demo — etl_reader least privilege + change tracking (15 tables only)

    Database : free-sql-db-0862313
    Schema   : sales_demo
    Login    : etl_reader  (server login on master + user in this DB)

    Matches: resources/jobs/lakeflow_managed_ingestion_with_limited_id_perm.yml

    Run order:
      1. master  — ALTER LOGIN etl_reader WITH PASSWORD = '...';
      2. this DB — run entire script (select all, execute)

    Excluded (no access, no CT):
      employee_salaries, customer_payment_methods, audit_log,
      internal_costs, vendor_contracts
*/

USE [free-sql-db-0862313];
GO

------------------------------------------------------------
-- Allowed tables (#temp persists across GO in same session)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#allowed') IS NOT NULL
    DROP TABLE #allowed;

CREATE TABLE #allowed (table_name SYSNAME NOT NULL PRIMARY KEY);

INSERT INTO #allowed (table_name) VALUES
    ('customers'),
    ('products'),
    ('stores'),
    ('employees'),
    ('orders'),
    ('order_items'),
    ('payments'),
    ('shipments'),
    ('inventory'),
    ('suppliers'),
    ('purchase_orders'),
    ('promotions'),
    ('customer_addresses'),
    ('product_reviews'),
    ('returns');
GO

------------------------------------------------------------
-- User mapping
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'etl_reader')
    CREATE USER etl_reader FROM LOGIN etl_reader;
GO

------------------------------------------------------------
-- Remove broad access
------------------------------------------------------------
IF IS_ROLEMEMBER('db_datareader', 'etl_reader') = 1
    ALTER ROLE db_datareader DROP MEMBER etl_reader;
GO

REVOKE SELECT ON SCHEMA::sales_demo FROM etl_reader;
GO

------------------------------------------------------------
-- Change tracking: database
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()
)
BEGIN
    ALTER DATABASE CURRENT
    SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON);
END
GO

------------------------------------------------------------
-- Change tracking: 15 tables only
------------------------------------------------------------
DECLARE @ct_sql NVARCHAR(MAX) = N'';

SELECT @ct_sql = @ct_sql
    + N'IF NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N''sales_demo.'
    + a.table_name + N'''))'
    + N' ALTER TABLE sales_demo.' + QUOTENAME(a.table_name)
    + N' ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = ON);' + CHAR(10)
FROM #allowed a
INNER JOIN sys.tables t ON t.name = a.table_name
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id AND s.name = 'sales_demo';

IF LEN(@ct_sql) > 0
    EXEC sp_executesql @ct_sql;
GO

------------------------------------------------------------
-- Grants: SELECT + VIEW CHANGE TRACKING on 15 tables only
------------------------------------------------------------
DECLARE @grant_sql NVARCHAR(MAX) = N'';

SELECT @grant_sql = @grant_sql
    + N'GRANT SELECT ON sales_demo.' + QUOTENAME(a.table_name) + N' TO etl_reader;' + CHAR(10)
    + N'GRANT VIEW CHANGE TRACKING ON sales_demo.' + QUOTENAME(a.table_name) + N' TO etl_reader;' + CHAR(10)
FROM #allowed a
INNER JOIN sys.tables t ON t.name = a.table_name
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id AND s.name = 'sales_demo';

IF LEN(@grant_sql) > 0
    EXEC sp_executesql @grant_sql;
GO

GRANT VIEW DATABASE STATE TO etl_reader;
GO

------------------------------------------------------------
-- Deny sensitive tables (if they exist)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#denied') IS NOT NULL
    DROP TABLE #denied;

CREATE TABLE #denied (table_name SYSNAME NOT NULL PRIMARY KEY);

INSERT INTO #denied (table_name) VALUES
    ('employee_salaries'),
    ('customer_payment_methods'),
    ('audit_log'),
    ('internal_costs'),
    ('vendor_contracts');
GO

DECLARE @deny_sql NVARCHAR(MAX) = N'';

SELECT @deny_sql = @deny_sql
    + N'DENY SELECT ON sales_demo.' + QUOTENAME(d.table_name) + N' TO etl_reader;' + CHAR(10)
FROM #denied d
INNER JOIN sys.tables t ON t.name = d.table_name
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id AND s.name = 'sales_demo';

IF LEN(@deny_sql) > 0
    EXEC sp_executesql @deny_sql;
GO

------------------------------------------------------------
-- Verification
------------------------------------------------------------
PRINT '--- Change tracking (15 allowed tables) ---';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    CASE WHEN ct.object_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS change_tracking_enabled
FROM #allowed a
INNER JOIN sys.tables t ON t.name = a.table_name
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id AND s.name = 'sales_demo'
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
ORDER BY t.name;
GO

PRINT '--- etl_reader permissions ---';

SELECT
    OBJECT_SCHEMA_NAME(p.major_id) AS schema_name,
    OBJECT_NAME(p.major_id)         AS table_name,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'etl_reader'
  AND p.class = 1
ORDER BY schema_name, table_name, permission_name;
GO

DROP TABLE IF EXISTS #allowed;
DROP TABLE IF EXISTS #denied;
GO
