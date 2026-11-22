-- ============================================================================
-- DBMS EXPERIMENT 8: Transactions (COMMIT, ROLLBACK, SAVEPOINT) &
-- Isolation Levels / Concurrency Anomalies

-- 1. Create Banking Table and Insert Initial Records
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(50) NOT NULL,
    Balance DECIMAL(12, 2) NOT NULL CHECK (Balance >= 0)
) ENGINE = InnoDB;

INSERT INTO Accounts (AccountID, AccountHolder, Balance) VALUES
(101, 'Aarav', 5000.00),
(102, 'Diya',  3000.00);

SELECT * FROM Accounts ORDER BY AccountID;

-- 2. Banking Transaction using BEGIN / START TRANSACTION and COMMIT
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 500 WHERE AccountID = 101 AND Balance >= 500;
UPDATE Accounts SET Balance = Balance + 500 WHERE AccountID = 102;
COMMIT;

SELECT AccountID, Balance FROM Accounts ORDER BY AccountID;

-- 3. Partial Rollback using SAVEPOINT
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 300 WHERE AccountID = 101;
SAVEPOINT after_debit;
UPDATE Accounts SET Balance = Balance - 50 WHERE AccountID = 101;
ROLLBACK TO SAVEPOINT after_debit;
UPDATE Accounts SET Balance = Balance + 300 WHERE AccountID = 102;
COMMIT;

SELECT AccountID, Balance FROM Accounts ORDER BY AccountID;

-- 4. Simulate Failure using ROLLBACK (Invalid Recipient Account 999)
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 200 WHERE AccountID = 101 AND Balance >= 200;
UPDATE Accounts SET Balance = Balance + 200 WHERE AccountID = 999;
SELECT ROW_COUNT();
-- Since recipient update affects 0 rows:
ROLLBACK;

SELECT AccountID, Balance FROM Accounts WHERE AccountID = 101;

-- 5. Isolation Level Syntax Reference
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- ============================================================================
-- 6. Dirty Read Demonstration (Run across two concurrent sessions)
-- ============================================================================
-- Reset test balance first:
UPDATE Accounts SET Balance = 1000 WHERE AccountID = 101;

-- [SESSION A]
START TRANSACTION;
UPDATE Accounts SET Balance = 700 WHERE AccountID = 101;
-- Keep transaction open; do not commit yet

-- [SESSION B]
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT Balance FROM Accounts WHERE AccountID = 101; -- Reads uncommitted 700

-- [SESSION A]
ROLLBACK;

-- ============================================================================
-- 7. Non-Repeatable Read Demonstration (READ COMMITTED)
-- ============================================================================
-- [SESSION A]
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT Balance FROM Accounts WHERE AccountID = 101; -- First read: 1000

-- [SESSION B]
UPDATE Accounts SET Balance = 900 WHERE AccountID = 101;
COMMIT;

-- [SESSION A]
SELECT Balance FROM Accounts WHERE AccountID = 101; -- Second read: 900
COMMIT;

-- ============================================================================
-- 8. REPEATABLE READ Demonstration (Consistent Snapshot)
-- ============================================================================
-- [SESSION A]
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT Balance FROM Accounts WHERE AccountID = 101; -- First read: 900

-- [SESSION B]
UPDATE Accounts SET Balance = 800 WHERE AccountID = 101;
COMMIT;

-- [SESSION A]
SELECT Balance FROM Accounts WHERE AccountID = 101; -- Second read: 900
COMMIT;
