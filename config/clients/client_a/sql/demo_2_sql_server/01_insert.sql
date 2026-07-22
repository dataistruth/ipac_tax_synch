/* =============================================================================
   03_inserts.sql  —  Sample data for all 20 tables
   Run third, as an admin, after 01_ddl.sql (and 02_grants.sql).

   Each block is guarded with IF NOT EXISTS so re-running is safe (no dupes).
   Parent tables load before children to satisfy FKs. Explicit IDs are used
   for FKs via IDENTITY seeds (customers/products/stores start at 1;
   orders start at 1000).
   ============================================================================= */

SET NOCOUNT ON;
GO

-- ========================= 1. customers ======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.customers)
INSERT INTO sales_demo.customers (first_name, last_name, email, city, state_code) VALUES
('Ava','Nguyen','ava.nguyen@example.com','Chicago','IL'),
('Liam','Patel','liam.patel@example.com','Naperville','IL'),
('Maya','Johnson','maya.johnson@example.com','Milwaukee','WI'),
('Noah','Garcia','noah.garcia@example.com','Indianapolis','IN'),
('Sofia','Kim','sofia.kim@example.com','Evanston','IL'),
('Ethan','Brown','ethan.brown@example.com','Detroit','MI'),
('Isla','Martinez','isla.martinez@example.com','Madison','WI'),
('Lucas','Wilson','lucas.wilson@example.com','Columbus','OH');
GO

-- ========================= 2. products =======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.products)
INSERT INTO sales_demo.products (sku, product_name, category, unit_price) VALUES
('SKU-1001','Wireless Mouse','Electronics',24.99),
('SKU-1002','Mechanical Keyboard','Electronics',89.00),
('SKU-1003','27in Monitor','Electronics',249.50),
('SKU-1004','Standing Desk','Furniture',399.00),
('SKU-1005','Ergonomic Chair','Furniture',289.99),
('SKU-1006','USB-C Hub','Electronics',45.00),
('SKU-1007','Desk Lamp','Furniture',34.25),
('SKU-1008','Noise-Cancel Headphones','Electronics',199.99),
('SKU-1009','Webcam 1080p','Electronics',59.00),
('SKU-1010','Laptop Stand','Furniture',42.75);
GO

-- ========================= 3. stores =========================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.stores)
INSERT INTO sales_demo.stores (store_name, city, state_code, opened_date) VALUES
('Loop Flagship','Chicago','IL','2018-03-15'),
('North Shore','Evanston','IL','2020-07-01'),
('Lakefront','Milwaukee','WI','2021-05-20');
GO

-- ========================= 4. employees ======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.employees)
INSERT INTO sales_demo.employees (store_id, full_name, title, hire_date) VALUES
(1,'Grace Hopper','Store Manager','2018-03-01'),
(1,'Alan Turing','Sales Associate','2019-06-15'),
(2,'Ada Lovelace','Store Manager','2020-06-20'),
(2,'Katherine Johnson','Inventory Lead','2021-01-10'),
(3,'Edsger Dijkstra','Store Manager','2021-05-01');
GO

-- ========================= 5. suppliers ======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.suppliers)
INSERT INTO sales_demo.suppliers (supplier_name, contact_email, country) VALUES
('TechSource Ltd','sales@techsource.example','Taiwan'),
('FurniCraft Inc','orders@furnicraft.example','USA'),
('GlobalParts Co','contact@globalparts.example','Germany');
GO

-- ========================= 6. orders =========================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.orders)
INSERT INTO sales_demo.orders (customer_id, store_id, order_date, status, total_amount) VALUES
(1,1,'2026-06-01T10:15:00','DELIVERED',114.99),
(2,1,'2026-06-03T14:22:00','DELIVERED',488.00),
(3,2,'2026-06-10T09:05:00','SHIPPED',249.50),
(4,3,'2026-06-15T16:40:00','DELIVERED',59.00),
(5,2,'2026-06-20T11:30:00','PENDING',366.99),
(1,1,'2026-07-02T13:00:00','SHIPPED',199.99),
(6,3,'2026-07-05T15:45:00','PENDING',688.99),
(7,2,'2026-07-10T10:10:00','DELIVERED',45.00);
GO

-- ========================= 7. order_items ====================================
-- order_id starts at 1000 (IDENTITY(1000,1))
IF NOT EXISTS (SELECT 1 FROM sales_demo.order_items)
INSERT INTO sales_demo.order_items (order_id, product_id, quantity, unit_price) VALUES
(1000,1,1,24.99),(1000,2,1,89.00),
(1001,4,1,399.00),(1001,2,1,89.00),
(1002,3,1,249.50),
(1003,9,1,59.00),
(1004,5,1,289.99),(1004,7,1,34.25),(1004,10,1,42.75),
(1005,8,1,199.99),
(1006,4,1,399.00),(1006,5,1,289.99),
(1007,6,1,45.00);
GO

-- ========================= 8. payments =======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.payments)
INSERT INTO sales_demo.payments (order_id, method, amount, paid_at) VALUES
(1000,'CARD',114.99,'2026-06-01T10:16:00'),
(1001,'CARD',488.00,'2026-06-03T14:25:00'),
(1002,'TRANSFER',249.50,'2026-06-10T09:10:00'),
(1003,'CARD',59.00,'2026-06-15T16:42:00'),
(1005,'CARD',199.99,'2026-07-02T13:02:00'),
(1007,'CASH',45.00,'2026-07-10T10:12:00');
GO

-- ========================= 9. shipments ======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.shipments)
INSERT INTO sales_demo.shipments (order_id, carrier, shipped_at, delivered_at, tracking_no) VALUES
(1000,'UPS','2026-06-01T18:00:00','2026-06-03T12:00:00','1Z999AA10123456784'),
(1001,'FedEx','2026-06-04T09:00:00','2026-06-06T14:30:00','771234567890'),
(1002,'UPS','2026-06-11T10:00:00',NULL,'1Z999AA1012345699'),
(1003,'USPS','2026-06-16T08:00:00','2026-06-18T13:00:00','9400110200881234567890'),
(1005,'FedEx','2026-07-03T09:30:00',NULL,'771234500001');
GO

-- ========================= 10. inventory =====================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.inventory)
INSERT INTO sales_demo.inventory (store_id, product_id, on_hand_qty, last_counted_at)
SELECT s.store_id, p.product_id,
       ABS(CHECKSUM(NEWID())) % 50 + 5,
       '2026-07-15T06:00:00'
FROM sales_demo.stores s CROSS JOIN sales_demo.products p;
GO

-- ========================= 11. purchase_orders ===============================
IF NOT EXISTS (SELECT 1 FROM sales_demo.purchase_orders)
INSERT INTO sales_demo.purchase_orders (supplier_id, ordered_at, status, total_amount) VALUES
(1,'2026-05-15T09:00:00','RECEIVED',12500.00),
(2,'2026-06-01T11:00:00','RECEIVED',8900.00),
(3,'2026-07-01T10:00:00','OPEN',4300.00);
GO

-- ========================= 12. promotions ====================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.promotions)
INSERT INTO sales_demo.promotions (promo_code, description, discount_pct, starts_on, ends_on) VALUES
('SUMMER26','Summer sale - electronics',10.00,'2026-06-01','2026-08-31'),
('DESK15','15 percent off desks',15.00,'2026-07-01','2026-07-31'),
('WELCOME5','New customer 5 percent off',5.00,'2026-01-01','2026-12-31');
GO

-- ========================= 13. customer_addresses ============================
IF NOT EXISTS (SELECT 1 FROM sales_demo.customer_addresses)
INSERT INTO sales_demo.customer_addresses (customer_id, address_type, street, city, state_code, postal_code) VALUES
(1,'SHIPPING','123 W Madison St','Chicago','IL','60602'),
(1,'BILLING','123 W Madison St','Chicago','IL','60602'),
(2,'SHIPPING','45 Oakwood Ave','Naperville','IL','60540'),
(3,'SHIPPING','88 Lakeshore Dr','Milwaukee','WI','53202'),
(5,'SHIPPING','12 Sherman Ave','Evanston','IL','60201');
GO

-- ========================= 14. product_reviews ===============================
IF NOT EXISTS (SELECT 1 FROM sales_demo.product_reviews)
INSERT INTO sales_demo.product_reviews (product_id, customer_id, rating, review_text) VALUES
(1,1,5,'Great mouse, battery lasts forever.'),
(2,2,4,'Keys feel great, a bit loud.'),
(3,3,5,'Crisp display, easy setup.'),
(8,1,5,'Best headphones I have owned.'),
(5,5,3,'Comfortable but assembly was tricky.');
GO

-- ========================= 15. returns =======================================
IF NOT EXISTS (SELECT 1 FROM sales_demo.returns)
INSERT INTO sales_demo.returns (order_item_id, reason, refund_amount) VALUES
(2,'Keyboard key defect',89.00);
GO

-- ========================= 16-20. restricted tables ==========================
IF NOT EXISTS (SELECT 1 FROM sales_demo.employee_salaries)
INSERT INTO sales_demo.employee_salaries (employee_id, annual_salary, effective_from) VALUES
(1,92000,'2026-01-01'),
(2,54000,'2026-01-01'),
(3,90000,'2026-01-01'),
(4,61000,'2026-01-01'),
(5,88000,'2026-01-01');
GO

IF NOT EXISTS (SELECT 1 FROM sales_demo.customer_payment_methods)
INSERT INTO sales_demo.customer_payment_methods (customer_id, card_last4, card_brand, token_ref) VALUES
(1,'4242','VISA','tok_a1b2c3'),
(2,'1881','MASTERCARD','tok_d4e5f6'),
(5,'0005','AMEX','tok_g7h8i9');
GO

IF NOT EXISTS (SELECT 1 FROM sales_demo.internal_costs)
INSERT INTO sales_demo.internal_costs (product_id, unit_cost, effective_from) VALUES
(1,11.20,'2026-01-01'),(2,41.00,'2026-01-01'),(3,150.00,'2026-01-01'),
(4,210.00,'2026-01-01'),(5,140.00,'2026-01-01');
GO

IF NOT EXISTS (SELECT 1 FROM sales_demo.vendor_contracts)
INSERT INTO sales_demo.vendor_contracts (supplier_id, signed_on, terms, annual_value) VALUES
(1,'2025-12-01','Net 45, exclusivity on SKU-1001 to SKU-1003',150000),
(2,'2026-01-15','Net 30, quarterly rebate 2 percent',96000);
GO

IF NOT EXISTS (SELECT 1 FROM sales_demo.audit_log)
INSERT INTO sales_demo.audit_log (table_name, action, actor, details) VALUES
('sales_demo.orders','INSERT','system','Initial seed');
GO

-- ========================= Row-count check ===================================
SELECT SCHEMA_NAME(t.schema_id) + '.' + t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE SCHEMA_NAME(t.schema_id) = 'sales_demo'
GROUP BY SCHEMA_NAME(t.schema_id) + '.' + t.name
ORDER BY table_name;
GO

PRINT '03_inserts complete: all 20 tables populated.';