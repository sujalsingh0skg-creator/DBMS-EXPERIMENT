-- ============================================================================
-- DBMS EXPERIMENT 10: Query Optimization & Performance Benchmarking

-- 1. Create SalesAnalytics Dataset Table
CREATE TABLE SalesAnalytics (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerName VARCHAR(60),
    Region VARCHAR(20),
    OrderDate DATE NOT NULL,
    Status VARCHAR(20),
    ProductCategory VARCHAR(30),
    Quantity INT,
    Amount DECIMAL(10, 2)
) ENGINE = InnoDB;

-- 2. Generate 10,000 Sample Records using Recursive CTE (MySQL 8.0+)
SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO SalesAnalytics
(OrderID, CustomerID, CustomerName, Region, OrderDate, Status, ProductCategory, Quantity, Amount)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    n,
    1000 + MOD(n, 2500),
    CONCAT('Customer_', MOD(n, 1800) + 1),
    ELT(MOD(n, 4) + 1, 'North', 'South', 'East', 'West'),
    DATE_ADD('2026-01-01', INTERVAL MOD(n, 365) DAY),
    ELT(MOD(n, 4) + 1, 'Delivered', 'Pending', 'Cancelled', 'Returned'),
    ELT(MOD(n, 5) + 1, 'Electronics', 'Clothing', 'Books', 'Home', 'Sports'),
    MOD(n, 8) + 1,
    500 + MOD(n * 37, 12000)
FROM seq;

SELECT COUNT(*) AS TotalRows FROM SalesAnalytics;

-- ============================================================================
-- 3. Five Slow Queries & Their Optimized Versions
-- ============================================================================

-- Query 1: Filter by Region
-- Before Optimization:
EXPLAIN SELECT * FROM SalesAnalytics WHERE Region = 'North';

-- After Optimization (Single-column index + specific column projection):
CREATE INDEX idx_region ON SalesAnalytics (Region);
EXPLAIN SELECT OrderID, CustomerName, OrderDate, Amount
FROM SalesAnalytics
WHERE Region = 'North';


-- Query 2: Filter by Status and Date
-- Before Optimization:
EXPLAIN SELECT OrderID, OrderDate, Amount
FROM SalesAnalytics
WHERE OrderDate BETWEEN '2026-01-01' AND '2026-03-31'
  AND Status = 'Delivered';

-- After Optimization (Composite index with equality column first):
CREATE INDEX idx_status_date ON SalesAnalytics (Status, OrderDate);
EXPLAIN SELECT OrderID, OrderDate, Amount
FROM SalesAnalytics
WHERE Status = 'Delivered'
  AND OrderDate BETWEEN '2026-01-01' AND '2026-03-31';


-- Query 3: Filter by Region and Amount
-- Before Optimization:
EXPLAIN SELECT Region, SUM(Amount)
FROM SalesAnalytics
WHERE Region = 'West' AND Amount >= 5000
GROUP BY Region;

-- After Optimization (Composite index on Region & Amount):
CREATE INDEX idx_region_amount ON SalesAnalytics (Region, Amount);
EXPLAIN SELECT Region, SUM(Amount)
FROM SalesAnalytics
WHERE Region = 'West' AND Amount >= 5000
GROUP BY Region;


-- Query 4: Function on Date Column
-- Before Optimization (Non-sargable YEAR() function):
EXPLAIN SELECT COUNT(*)
FROM SalesAnalytics
WHERE YEAR(OrderDate) = 2026;

-- After Optimization (Sargable date range + index):
CREATE INDEX idx_order_date ON SalesAnalytics (OrderDate);
EXPLAIN SELECT COUNT(*)
FROM SalesAnalytics
WHERE OrderDate >= '2026-01-01'
  AND OrderDate < '2027-01-01';


-- Query 5: IN Subquery Rewritten as JOIN
-- Before Optimization:
EXPLAIN SELECT CustomerID, CustomerName
FROM SalesAnalytics
WHERE CustomerID IN (
    SELECT CustomerID FROM SalesAnalytics WHERE Status = 'Delivered'
);

-- After Optimization (DISTINCT + Self-JOIN + composite index):
CREATE INDEX idx_status_customer ON SalesAnalytics (Status, CustomerID);
EXPLAIN SELECT DISTINCT a.CustomerID, a.CustomerName
FROM SalesAnalytics a
JOIN SalesAnalytics d ON d.CustomerID = a.CustomerID
WHERE d.Status = 'Delivered';

-- ============================================================================
-- 4. Actual Execution Timing Benchmark (MySQL 8.0.18+)
-- ============================================================================
EXPLAIN ANALYZE
SELECT OrderID, OrderDate, Amount
FROM SalesAnalytics
WHERE Status = 'Delivered'
  AND OrderDate BETWEEN '2026-01-01' AND '2026-03-31';
