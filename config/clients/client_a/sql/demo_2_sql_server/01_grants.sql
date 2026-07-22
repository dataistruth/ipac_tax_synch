/* =============================================================================
   02_grants.sql  —  etl_reader user + SELECT on 15 of 20 tables
   Run second, as an admin, in your target database.

   AZURE SQL DATABASE (your case): uses a CONTAINED user (no login, no
   CHECK_POLICY — that keyword is not supported on Azure SQL DB).

   SQL SERVER (on-prem / VM / Managed Instance): use the alternative block
   at the bottom instead.
   ============================================================================= */

-- ========================= 1. Contained user (Azure SQL DB) ==================
-- CHANGE THE PASSWORD before running. Store the real one in your
-- Databricks secret scope (sqlserver/password), not in this file.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'etl_reader')
    CREATE USER etl_reader WITH PASSWORD = 'Ch@ngeMe!2026#Etl';
GO

-- ========================= 2. Grants — exactly 15 tables =====================
-- Table-level on purpose (NOT schema-level) so the 5 sensitive tables
-- (employee_salaries, customer_payment_methods, audit_log, internal_costs,
--  vendor_contracts) remain inaccessible.
GRANT SELECT ON sales_demo.customers            TO etl_reader;
GRANT SELECT ON sales_demo.products             TO etl_reader;
GRANT SELECT ON sales_demo.stores               TO etl_reader;
GRANT SELECT ON sales_demo.employees            TO etl_reader;
GRANT SELECT ON sales_demo.orders               TO etl_reader;
GRANT SELECT ON sales_demo.order_items          TO etl_reader;
GRANT SELECT ON sales_demo.payments             TO etl_reader;
GRANT SELECT ON sales_demo.shipments            TO etl_reader;
GRANT SELECT ON sales_demo.inventory            TO etl_reader;
GRANT SELECT ON sales_demo.suppliers            TO etl_reader;
GRANT SELECT ON sales_demo.purchase_orders      TO etl_reader;
GRANT SELECT ON sales_demo.promotions           TO etl_reader;
GRANT SELECT ON sales_demo.customer_addresses   TO etl_reader;
GRANT SELECT ON sales_demo.product_reviews      TO etl_reader;
GRANT SELECT ON sales_demo.returns              TO etl_reader;
GO

-- Required for CHANGETABLE(CHANGES ...) in the CT-based ingestion pipeline:
GRANT VIEW CHANGE TRACKING ON SCHEMA::sales_demo TO etl_reader;
GO

-- ========================= 3. Verify =========================================
EXECUTE AS USER = 'etl_reader';
SELECT 'granted_tables_visible' AS check_name, COUNT(*) AS n
FROM   sys.tables t
WHERE  SCHEMA_NAME(t.schema_id) = 'sales_demo';   -- expect 15
REVERT;
GO

-- Manual spot checks:
--   EXECUTE AS USER = 'etl_reader';
--   SELECT TOP 5 * FROM sales_demo.customers;          -- works
--   SELECT TOP 5 * FROM sales_demo.employee_salaries;  -- permission denied
--   REVERT;

PRINT '02_grants complete: etl_reader with SELECT on 15 tables + VIEW CHANGE TRACKING.';
GO

/* =============================================================================
   ALTERNATIVE for SQL Server on-prem / VM / Managed Instance
   (run instead of section 1; login in master context first):

   CREATE LOGIN etl_reader WITH PASSWORD = 'Ch@ngeMe!2026#Etl',
       CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;
   GO
   CREATE USER etl_reader FOR LOGIN etl_reader;
   GO
   -- then run sections 2 and 3 above unchanged.
   ============================================================================= */