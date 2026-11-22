-- ============================================================================
-- DBMS EXPERIMENT 7: Normalization (UNF -> 1NF -> 2NF -> 3NF -> BCNF),
-- Lossless Join & Dependency Preservation Verification

-- 1. Create and Populate Denormalized Sales Relation
CREATE TABLE Sales (
    OrderID INT,
    OrderDate DATE,
    CustomerID VARCHAR(10),
    CustomerName VARCHAR(60),
    CustomerCity VARCHAR(40),
    ProductID VARCHAR(10),
    ProductName VARCHAR(60),
    UnitPrice DECIMAL(10, 2),
    Quantity INT,
    SalespersonID VARCHAR(10),
    SalespersonName VARCHAR(60)
);

INSERT INTO Sales VALUES
(1001, '2026-11-01', 'C01', 'Aarav Sharma', 'Delhi', 'P01', 'Keyboard', 1200.00, 2, 'S01', 'Neha'),
(1001, '2026-11-01', 'C01', 'Aarav Sharma', 'Delhi', 'P02', 'Mouse',    500.00,  1, 'S01', 'Neha'),
(1002, '2026-11-02', 'C02', 'Diya Verma',   'Noida', 'P01', 'Keyboard', 1200.00, 1, 'S02', 'Rahul'),
(1003, '2026-11-03', 'C01', 'Aarav Sharma', 'Delhi', 'P03', 'Monitor',  8500.00, 1, 'S01', 'Neha');

-- View 1NF Initial Data
SELECT OrderID, CustomerID, ProductID, ProductName, Quantity
FROM Sales
ORDER BY OrderID, ProductID;

-- 2. Create Normalized 3NF / BCNF Tables
CREATE TABLE Customers (
    CustomerID VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(60),
    CustomerCity VARCHAR(40)
);

CREATE TABLE Salespersons (
    SalespersonID VARCHAR(10) PRIMARY KEY,
    SalespersonName VARCHAR(60)
);

CREATE TABLE Products (
    ProductID VARCHAR(10) PRIMARY KEY,
    ProductName VARCHAR(60),
    UnitPrice DECIMAL(10, 2)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATE,
    CustomerID VARCHAR(10),
    SalespersonID VARCHAR(10),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (SalespersonID) REFERENCES Salespersons(SalespersonID)
);

CREATE TABLE OrderItems (
    OrderID INT,
    ProductID VARCHAR(10),
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 3. Populate Normalized Relations from Sales
INSERT INTO Customers    SELECT DISTINCT CustomerID, CustomerName, CustomerCity FROM Sales;
INSERT INTO Salespersons SELECT DISTINCT SalespersonID, SalespersonName FROM Sales;
INSERT INTO Products     SELECT DISTINCT ProductID, ProductName, UnitPrice FROM Sales;
INSERT INTO Orders       SELECT DISTINCT OrderID, OrderDate, CustomerID, SalespersonID FROM Sales;
INSERT INTO OrderItems   SELECT OrderID, ProductID, Quantity FROM Sales;

-- Verify Relation Sizes
SELECT 'Customers' AS Relation, COUNT(*) AS `Rows` FROM Customers
UNION ALL SELECT 'Products',     COUNT(*) FROM Products
UNION ALL SELECT 'Orders',       COUNT(*) FROM Orders
UNION ALL SELECT 'OrderItems',   COUNT(*) FROM OrderItems
UNION ALL SELECT 'Salespersons', COUNT(*) FROM Salespersons;

-- 4. Lossless Join Verification
SELECT o.OrderID, o.OrderDate, o.CustomerID, c.CustomerName,
       oi.ProductID, p.ProductName, p.UnitPrice, oi.Quantity,
       o.SalespersonID, s.SalespersonName
FROM Orders o
JOIN Customers c    ON c.CustomerID = o.CustomerID
JOIN Salespersons s ON s.SalespersonID = o.SalespersonID
JOIN OrderItems oi  ON oi.OrderID = o.OrderID
JOIN Products p     ON p.ProductID = oi.ProductID
ORDER BY o.OrderID, oi.ProductID;

-- Lossless Row-Count Check
SELECT
    (SELECT COUNT(*) FROM Sales) AS OriginalRows,
    (SELECT COUNT(*)
     FROM Orders o
     JOIN Customers c    ON c.CustomerID = o.CustomerID
     JOIN Salespersons s ON s.SalespersonID = o.SalespersonID
     JOIN OrderItems oi  ON oi.OrderID = o.OrderID
     JOIN Products p     ON p.ProductID = oi.ProductID) AS RejoinedRows;

-- 5. Dependency Preservation Verification (Duplicate Determinant Key Check)
SELECT
    (SELECT COUNT(*) - COUNT(DISTINCT CustomerID) FROM Customers) AS DuplicateCustomerKeys,
    (SELECT COUNT(*) - COUNT(DISTINCT ProductID) FROM Products) AS DuplicateProductKeys,
    (SELECT COUNT(*) - COUNT(DISTINCT SalespersonID) FROM Salespersons) AS DuplicateSalespersonKeys,
    (SELECT COUNT(*) - COUNT(DISTINCT OrderID) FROM Orders) AS DuplicateOrderKeys,
    (SELECT COUNT(*) - COUNT(DISTINCT CONCAT(OrderID, '-', ProductID)) FROM OrderItems) AS DuplicateOrderProductKeys;
