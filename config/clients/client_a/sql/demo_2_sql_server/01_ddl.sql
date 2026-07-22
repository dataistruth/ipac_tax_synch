/* =============================================================================
   01_ddl.sql  —  Schema + 20 tables + Change Tracking
   Run first, as an admin, in your target database.
   Idempotent: skips objects that already exist.
   ============================================================================= */

-- ========================= 1. Schema =========================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sales_demo')
    EXEC('CREATE SCHEMA sales_demo');
GO

-- ========================= 2. Tables — granted set (15) ======================
IF OBJECT_ID('sales_demo.customers') IS NULL
CREATE TABLE sales_demo.customers (
    customer_id     INT IDENTITY(1,1) PRIMARY KEY,
    first_name      NVARCHAR(50)  NOT NULL,
    last_name       NVARCHAR(50)  NOT NULL,
    email           NVARCHAR(120) NOT NULL UNIQUE,
    city            NVARCHAR(60),
    state_code      CHAR(2),
    created_at      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    modified_at     DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('sales_demo.products') IS NULL
CREATE TABLE sales_demo.products (
    product_id      INT IDENTITY(1,1) PRIMARY KEY,
    sku             NVARCHAR(30)  NOT NULL UNIQUE,
    product_name    NVARCHAR(100) NOT NULL,
    category        NVARCHAR(50)  NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    is_active       BIT           NOT NULL DEFAULT 1,
    modified_at     DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('sales_demo.stores') IS NULL
CREATE TABLE sales_demo.stores (
    store_id        INT IDENTITY(1,1) PRIMARY KEY,
    store_name      NVARCHAR(80) NOT NULL,
    city            NVARCHAR(60),
    state_code      CHAR(2),
    opened_date     DATE
);
GO

IF OBJECT_ID('sales_demo.employees') IS NULL
CREATE TABLE sales_demo.employees (
    employee_id     INT IDENTITY(1,1) PRIMARY KEY,
    store_id        INT REFERENCES sales_demo.stores(store_id),
    full_name       NVARCHAR(100) NOT NULL,
    title           NVARCHAR(60),
    hire_date       DATE,
    modified_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('sales_demo.orders') IS NULL
CREATE TABLE sales_demo.orders (
    order_id        BIGINT IDENTITY(1000,1) PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES sales_demo.customers(customer_id),
    store_id        INT REFERENCES sales_demo.stores(store_id),
    order_date      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    status          NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(12,2),
    modified_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('sales_demo.order_items') IS NULL
CREATE TABLE sales_demo.order_items (
    order_item_id   BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES sales_demo.orders(order_id),
    product_id      INT    NOT NULL REFERENCES sales_demo.products(product_id),
    quantity        INT    NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    line_total      AS (quantity * unit_price) PERSISTED
);
GO

IF OBJECT_ID('sales_demo.payments') IS NULL
CREATE TABLE sales_demo.payments (
    payment_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES sales_demo.orders(order_id),
    paid_at         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    method          NVARCHAR(20) NOT NULL,
    amount          DECIMAL(12,2) NOT NULL
);
GO

IF OBJECT_ID('sales_demo.shipments') IS NULL
CREATE TABLE sales_demo.shipments (
    shipment_id     BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES sales_demo.orders(order_id),
    carrier         NVARCHAR(40),
    shipped_at      DATETIME2,
    delivered_at    DATETIME2,
    tracking_no     NVARCHAR(50)
);
GO

IF OBJECT_ID('sales_demo.inventory') IS NULL
CREATE TABLE sales_demo.inventory (
    inventory_id    BIGINT IDENTITY(1,1) PRIMARY KEY,
    store_id        INT NOT NULL REFERENCES sales_demo.stores(store_id),
    product_id      INT NOT NULL REFERENCES sales_demo.products(product_id),
    on_hand_qty     INT NOT NULL DEFAULT 0,
    last_counted_at DATETIME2,
    CONSTRAINT uq_inventory UNIQUE (store_id, product_id)
);
GO

IF OBJECT_ID('sales_demo.suppliers') IS NULL
CREATE TABLE sales_demo.suppliers (
    supplier_id     INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name   NVARCHAR(100) NOT NULL,
    contact_email   NVARCHAR(120),
    country         NVARCHAR(60)
);
GO

IF OBJECT_ID('sales_demo.purchase_orders') IS NULL
CREATE TABLE sales_demo.purchase_orders (
    po_id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    supplier_id     INT NOT NULL REFERENCES sales_demo.suppliers(supplier_id),
    ordered_at      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    status          NVARCHAR(20) NOT NULL DEFAULT 'OPEN',
    total_amount    DECIMAL(12,2)
);
GO

IF OBJECT_ID('sales_demo.promotions') IS NULL
CREATE TABLE sales_demo.promotions (
    promo_id        INT IDENTITY(1,1) PRIMARY KEY,
    promo_code      NVARCHAR(30) NOT NULL UNIQUE,
    description     NVARCHAR(200),
    discount_pct    DECIMAL(5,2) NOT NULL,
    starts_on       DATE NOT NULL,
    ends_on         DATE NOT NULL
);
GO

IF OBJECT_ID('sales_demo.customer_addresses') IS NULL
CREATE TABLE sales_demo.customer_addresses (
    address_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES sales_demo.customers(customer_id),
    address_type    NVARCHAR(15) NOT NULL DEFAULT 'SHIPPING',
    street          NVARCHAR(120),
    city            NVARCHAR(60),
    state_code      CHAR(2),
    postal_code     NVARCHAR(12)
);
GO

IF OBJECT_ID('sales_demo.product_reviews') IS NULL
CREATE TABLE sales_demo.product_reviews (
    review_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id      INT NOT NULL REFERENCES sales_demo.products(product_id),
    customer_id     INT NOT NULL REFERENCES sales_demo.customers(customer_id),
    rating          TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text     NVARCHAR(500),
    reviewed_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('sales_demo.returns') IS NULL
CREATE TABLE sales_demo.returns (
    return_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_item_id   BIGINT NOT NULL REFERENCES sales_demo.order_items(order_item_id),
    returned_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    reason          NVARCHAR(200),
    refund_amount   DECIMAL(10,2)
);
GO

-- ========================= 3. Tables — restricted set (5) ====================
IF OBJECT_ID('sales_demo.employee_salaries') IS NULL
CREATE TABLE sales_demo.employee_salaries (
    salary_id       INT IDENTITY(1,1) PRIMARY KEY,
    employee_id     INT NOT NULL REFERENCES sales_demo.employees(employee_id),
    annual_salary   DECIMAL(12,2) NOT NULL,
    effective_from  DATE NOT NULL
);
GO

IF OBJECT_ID('sales_demo.customer_payment_methods') IS NULL
CREATE TABLE sales_demo.customer_payment_methods (
    pm_id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES sales_demo.customers(customer_id),
    card_last4      CHAR(4),
    card_brand      NVARCHAR(20),
    token_ref       NVARCHAR(64)
);
GO

IF OBJECT_ID('sales_demo.audit_log') IS NULL
CREATE TABLE sales_demo.audit_log (
    audit_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    table_name      NVARCHAR(120),
    action          NVARCHAR(10),
    actor           NVARCHAR(60),
    happened_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    details         NVARCHAR(1000)
);
GO

IF OBJECT_ID('sales_demo.internal_costs') IS NULL
CREATE TABLE sales_demo.internal_costs (
    cost_id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id      INT NOT NULL REFERENCES sales_demo.products(product_id),
    unit_cost       DECIMAL(10,2) NOT NULL,
    effective_from  DATE NOT NULL
);
GO

IF OBJECT_ID('sales_demo.vendor_contracts') IS NULL
CREATE TABLE sales_demo.vendor_contracts (
    contract_id     INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id     INT NOT NULL REFERENCES sales_demo.suppliers(supplier_id),
    signed_on       DATE,
    terms           NVARCHAR(1000),
    annual_value    DECIMAL(14,2)
);
GO

-- ========================= 4. Change Tracking ================================
-- DB level first (skip if already enabled). On Azure SQL DB run against the DB:
-- ALTER DATABASE CURRENT SET CHANGE_TRACKING = ON
--   (CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON);
-- GO

DECLARE @t NVARCHAR(200), @sql NVARCHAR(400);
DECLARE ct_cursor CURSOR FOR
    SELECT t.name FROM sys.tables t
    WHERE SCHEMA_NAME(t.schema_id) = 'sales_demo'
      AND t.name IN ('customers','products','stores','employees','orders',
                     'order_items','payments','shipments','inventory','suppliers',
                     'purchase_orders','promotions','customer_addresses',
                     'product_reviews','returns')
      AND NOT EXISTS (SELECT 1 FROM sys.change_tracking_tables ctt
                      WHERE ctt.object_id = t.object_id);
OPEN ct_cursor;
FETCH NEXT FROM ct_cursor INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER TABLE sales_demo.' + QUOTENAME(@t) + ' ENABLE CHANGE_TRACKING';
    EXEC(@sql);
    FETCH NEXT FROM ct_cursor INTO @t;
END
CLOSE ct_cursor; DEALLOCATE ct_cursor;
GO

PRINT '01_ddl complete: schema sales_demo + 20 tables + change tracking.';