# INTERVIEW QUESTIONS 200-220: SQL Server Views & Entity Framework

## SECTION 5: SQL SERVER & DATABASE MANAGEMENT (Continued)

---

## Q200: Explain views in SQL Server. What are indexed views?

**Answer:**

A **view** is a virtual table based on the result-set of an SQL statement. It contains rows and columns from one or more tables. Indexed views (also called materialized views) physically store data and can significantly improve query performance.

### Types of Views:

#### 1. Simple View (Single Table)
```sql
-- Create a simple view showing active employees
CREATE VIEW vw_ActiveEmployees
AS
SELECT
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Department
FROM Employees
WHERE IsActive = 1;

-- Usage
SELECT * FROM vw_ActiveEmployees;
```

#### 2. Complex View (Multiple Tables with Joins)
```sql
-- Create a complex view with joins
CREATE VIEW vw_EmployeeSalesReport
AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    d.DepartmentName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSales,
    AVG(o.TotalAmount) AS AverageSale
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
WHERE e.IsActive = 1
GROUP BY
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    d.DepartmentName;
```

### Indexed Views (Materialized Views)

Indexed views physically store the result set and automatically update when underlying tables change.

#### Requirements for Indexed Views:
```sql
-- Step 1: Create view WITH SCHEMABINDING
CREATE VIEW vw_ProductSalesSummary
WITH SCHEMABINDING
AS
SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    COUNT_BIG(*) AS OrderCount,  -- COUNT_BIG required for indexed views
    SUM(od.Quantity) AS TotalQuantity,
    SUM(od.UnitPrice * od.Quantity) AS TotalRevenue
FROM dbo.Products p  -- Must use schema prefix with SCHEMABINDING
INNER JOIN dbo.OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.CategoryID;

-- Step 2: Create unique clustered index
CREATE UNIQUE CLUSTERED INDEX IX_ProductSalesSummary_ProductID
ON vw_ProductSalesSummary(ProductID);

-- Step 3: Optionally add non-clustered indexes
CREATE NONCLUSTERED INDEX IX_ProductSalesSummary_CategoryID
ON vw_ProductSalesSummary(CategoryID)
INCLUDE (TotalRevenue);
```

### Key Differences: Regular View vs Indexed View

| Feature | Regular View | Indexed View |
|---------|--------------|--------------|
| **Storage** | No physical storage | Physically stored |
| **Performance** | Executes query each time | Pre-calculated results |
| **Maintenance** | No maintenance overhead | Automatically maintained |
| **Schema Binding** | Optional | Required (WITH SCHEMABINDING) |
| **Updates** | Dynamic, always current | Updated when base tables change |
| **Restrictions** | Few restrictions | Many restrictions (no OUTER JOIN, etc.) |

### View Updatability

```sql
-- Create an updatable view
CREATE VIEW vw_CustomerContacts
AS
SELECT
    CustomerID,
    CustomerName,
    Email,
    Phone
FROM Customers
WHERE IsActive = 1;

-- These operations work on updatable views:
UPDATE vw_CustomerContacts
SET Email = 'newemail@example.com'
WHERE CustomerID = 100;

INSERT INTO vw_CustomerContacts (CustomerID, CustomerName, Email, Phone)
VALUES (200, 'John Doe', 'john@example.com', '555-1234');

DELETE FROM vw_CustomerContacts WHERE CustomerID = 200;
```

### WITH CHECK OPTION

Ensures that data modifications through the view comply with the view's WHERE clause:

```sql
CREATE VIEW vw_HighValueOrders
AS
SELECT
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM Orders
WHERE TotalAmount >= 1000
WITH CHECK OPTION;

-- This will fail because TotalAmount < 1000
INSERT INTO vw_HighValueOrders (OrderID, CustomerID, OrderDate, TotalAmount)
VALUES (999, 1, GETDATE(), 500);  -- Error!
```

### Benefits of Views:
1. **Security** - Hide sensitive columns
2. **Simplification** - Encapsulate complex queries
3. **Abstraction** - Decouple applications from table structure
4. **Performance** (indexed views) - Pre-calculated aggregations

### Best Practices:
```sql
-- 1. Use meaningful naming conventions
CREATE VIEW vw_CustomerOrderSummary  -- prefix with 'vw_'

-- 2. Include column names explicitly
CREATE VIEW vw_Orders
AS
SELECT
    OrderID,
    CustomerID,
    OrderDate
    -- Don't use SELECT *
FROM Orders;

-- 3. Document complex views
CREATE VIEW vw_MonthlyRevenue
AS
/*
 * Monthly Revenue Report
 * Shows total revenue grouped by month and year
 * Updated: 2025-01-15
 */
SELECT
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
```

---

## Q201: What are transactions? Explain ACID properties.

**Answer:**

A **transaction** is a logical unit of work that contains one or more SQL statements. All statements must succeed or all must fail together.

### ACID Properties

**ACID** ensures database reliability:

#### 1. **A**tomicity - All or Nothing

```sql
-- Example: Bank transfer (Atomicity ensures both operations succeed or both fail)
BEGIN TRANSACTION;

DECLARE @TransferAmount DECIMAL(18,2) = 1000;

-- Debit from Account A
UPDATE Accounts
SET Balance = Balance - @TransferAmount
WHERE AccountID = 'A001';

-- Credit to Account B
UPDATE Accounts
SET Balance = Balance + @TransferAmount
WHERE AccountID = 'B001';

-- If both succeed, commit; otherwise rollback
IF @@ERROR = 0
    COMMIT TRANSACTION;
ELSE
    ROLLBACK TRANSACTION;
```

#### 2. **C**onsistency - Valid State to Valid State

```sql
-- Constraint ensures consistency
CREATE TABLE Accounts (
    AccountID VARCHAR(10) PRIMARY KEY,
    Balance DECIMAL(18,2) NOT NULL,
    -- Check constraint ensures balance never goes negative
    CONSTRAINT CK_Balance_NonNegative CHECK (Balance >= 0)
);

BEGIN TRANSACTION;
    -- This will fail and rollback due to check constraint
    UPDATE Accounts
    SET Balance = Balance - 5000  -- Would make balance negative
    WHERE AccountID = 'A001' AND Balance = 1000;
COMMIT TRANSACTION;
```

#### 3. **I**solation - Concurrent Transactions Don't Interfere

```sql
-- Transaction 1
BEGIN TRANSACTION;
    UPDATE Inventory
    SET Quantity = Quantity - 10
    WHERE ProductID = 'P001';

    -- Other transactions don't see this change until commit
    WAITFOR DELAY '00:00:10';  -- Simulate long operation
COMMIT TRANSACTION;

-- Transaction 2 (runs concurrently)
BEGIN TRANSACTION;
    SELECT Quantity FROM Inventory WHERE ProductID = 'P001';
    -- Sees the old value depending on isolation level
COMMIT TRANSACTION;
```

#### 4. **D**urability - Changes Persist

```sql
BEGIN TRANSACTION;
    INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount)
    VALUES (1001, 'C001', GETDATE(), 500.00);
COMMIT TRANSACTION;

-- Even if server crashes after COMMIT,
-- the data is permanently saved to disk
```

### Complete Transaction Example with Error Handling

```sql
CREATE PROCEDURE sp_ProcessOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Start transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check inventory
        DECLARE @AvailableQty INT;
        SELECT @AvailableQty = Quantity
        FROM Inventory
        WHERE ProductID = @ProductID;

        IF @AvailableQty < @Quantity
        BEGIN
            RAISERROR('Insufficient inventory', 16, 1);
        END

        -- Create order
        INSERT INTO Orders (CustomerID, OrderDate, Status)
        VALUES (@CustomerID, GETDATE(), 'Pending');

        SET @OrderID = SCOPE_IDENTITY();

        -- Add order details
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
        SELECT @OrderID, @ProductID, @Quantity, UnitPrice
        FROM Products
        WHERE ProductID = @ProductID;

        -- Update inventory
        UPDATE Inventory
        SET Quantity = Quantity - @Quantity,
            LastModified = GETDATE()
        WHERE ProductID = @ProductID;

        -- Create audit log
        INSERT INTO AuditLog (Action, TableName, RecordID, Timestamp)
        VALUES ('ORDER_CREATED', 'Orders', @OrderID, GETDATE());

        -- All successful - commit
        COMMIT TRANSACTION;

        RETURN 0;  -- Success

    END TRY
    BEGIN CATCH
        -- Rollback on error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Log error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();

        INSERT INTO ErrorLog (ErrorMessage, Severity, Timestamp)
        VALUES (@ErrorMessage, @ErrorSeverity, GETDATE());

        -- Re-throw error
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);

        RETURN -1;  -- Failure
    END CATCH
END
GO
```

### Nested Transactions

```sql
BEGIN TRANSACTION OuterTran;
    INSERT INTO Orders (OrderID, CustomerID) VALUES (1, 100);

    BEGIN TRANSACTION InnerTran;  -- @@TRANCOUNT = 2
        INSERT INTO OrderDetails (OrderID, ProductID) VALUES (1, 500);
    COMMIT TRANSACTION InnerTran;  -- @@TRANCOUNT = 1

COMMIT TRANSACTION OuterTran;  -- @@TRANCOUNT = 0

-- Note: Only the outermost COMMIT writes to disk
```

### Savepoints

```sql
BEGIN TRANSACTION;

    INSERT INTO Orders (OrderID, CustomerID) VALUES (1, 100);

    SAVE TRANSACTION SavePoint1;

    INSERT INTO OrderDetails (OrderID, ProductID) VALUES (1, 500);

    -- Rollback to savepoint (keeps Order insert, removes OrderDetail)
    ROLLBACK TRANSACTION SavePoint1;

COMMIT TRANSACTION;
```

---

## Q202: What are transaction isolation levels?

**Answer:**

**Transaction isolation levels** determine how one transaction's changes are visible to other concurrent transactions. They balance between **consistency** and **concurrency**.

### The Four Standard Isolation Levels

#### 1. READ UNCOMMITTED (Lowest Isolation)

Allows dirty reads - can read uncommitted changes from other transactions.

```sql
-- Session 1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRANSACTION;
    -- Can read uncommitted data from other transactions
    SELECT * FROM Products WHERE ProductID = 1;
    -- Might see data that gets rolled back!
COMMIT TRANSACTION;

-- Session 2 (concurrent)
BEGIN TRANSACTION;
    UPDATE Products SET Price = 999 WHERE ProductID = 1;
    -- Session 1 can see this change even though not committed
    ROLLBACK TRANSACTION;  -- Session 1 saw data that no longer exists!
```

**Use Case:** Reporting where approximate data is acceptable
**Problems:** Dirty reads, non-repeatable reads, phantom reads

#### 2. READ COMMITTED (SQL Server Default)

Only reads committed data. Prevents dirty reads.

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Session 1
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Reads: $100

    WAITFOR DELAY '00:00:05';  -- Wait 5 seconds

    SELECT Price FROM Products WHERE ProductID = 1;  -- Might read: $150
    -- Different value in same transaction!
COMMIT TRANSACTION;

-- Session 2 (during Session 1's wait)
BEGIN TRANSACTION;
    UPDATE Products SET Price = 150 WHERE ProductID = 1;
COMMIT TRANSACTION;
```

**Use Case:** Most general-purpose applications
**Problems:** Non-repeatable reads, phantom reads
**Prevents:** Dirty reads

#### 3. REPEATABLE READ

Ensures the same data is read throughout the transaction. Locks rows that are read.

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Session 1
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Reads: $100

    WAITFOR DELAY '00:00:10';

    SELECT Price FROM Products WHERE ProductID = 1;  -- Still reads: $100
    -- Same value guaranteed!
COMMIT TRANSACTION;

-- Session 2 (tries to update during Session 1)
BEGIN TRANSACTION;
    UPDATE Products SET Price = 150 WHERE ProductID = 1;
    -- This will BLOCK until Session 1 commits!
COMMIT TRANSACTION;
```

**Phantom Reads Still Possible:**
```sql
-- Session 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT COUNT(*) FROM Products WHERE CategoryID = 5;  -- Returns: 10

    WAITFOR DELAY '00:00:05';

    SELECT COUNT(*) FROM Products WHERE CategoryID = 5;  -- Returns: 11
    -- New row appeared! (Phantom read)
COMMIT TRANSACTION;

-- Session 2 (during wait)
BEGIN TRANSACTION;
    INSERT INTO Products (ProductID, CategoryID, ProductName)
    VALUES (999, 5, 'New Product');
COMMIT TRANSACTION;
```

**Use Case:** Financial transactions requiring consistency
**Problems:** Phantom reads
**Prevents:** Dirty reads, non-repeatable reads

#### 4. SERIALIZABLE (Highest Isolation)

Complete isolation - transactions appear to run serially. Prevents all anomalies.

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Session 1
BEGIN TRANSACTION;
    SELECT * FROM Products WHERE CategoryID = 5;
    -- Locks the entire range - no inserts/updates/deletes allowed

    WAITFOR DELAY '00:00:10';

    SELECT * FROM Products WHERE CategoryID = 5;
    -- Guaranteed identical results!
COMMIT TRANSACTION;

-- Session 2
BEGIN TRANSACTION;
    INSERT INTO Products (ProductID, CategoryID) VALUES (999, 5);
    -- This BLOCKS until Session 1 commits
COMMIT TRANSACTION;
```

**Use Case:** Critical financial/inventory operations
**Problems:** Lowest concurrency, potential deadlocks
**Prevents:** All anomalies (dirty reads, non-repeatable reads, phantom reads)

### SQL Server Specific: SNAPSHOT Isolation

Uses row versioning instead of locking:

```sql
-- Enable snapshot isolation (database level)
ALTER DATABASE YourDatabase
SET ALLOW_SNAPSHOT_ISOLATION ON;

-- Session 1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Reads: $100

    WAITFOR DELAY '00:00:10';

    SELECT Price FROM Products WHERE ProductID = 1;  -- Still reads: $100
    -- Reads from snapshot at transaction start time
COMMIT TRANSACTION;

-- Session 2 (concurrent)
BEGIN TRANSACTION;
    UPDATE Products SET Price = 150 WHERE ProductID = 1;
COMMIT TRANSACTION;  -- No blocking! Updates are allowed

-- Session 1 sees old version, Session 2 creates new version
```

### READ_COMMITTED_SNAPSHOT (RCSI)

```sql
ALTER DATABASE YourDatabase
SET READ_COMMITTED_SNAPSHOT ON;

-- Now READ COMMITTED uses row versioning instead of locks
-- No code changes needed - same isolation level behaves differently
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Products;  -- No shared locks, uses versioning
COMMIT TRANSACTION;
```

### Comparison Table

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Locking Behavior |
|----------------|------------|---------------------|--------------|------------------|
| **READ UNCOMMITTED** | ✗ Yes | ✗ Yes | ✗ Yes | No locks |
| **READ COMMITTED** | ✓ No | ✗ Yes | ✗ Yes | Short shared locks |
| **REPEATABLE READ** | ✓ No | ✓ No | ✗ Yes | Shared locks held |
| **SERIALIZABLE** | ✓ No | ✓ No | ✓ No | Range locks |
| **SNAPSHOT** | ✓ No | ✓ No | ✓ No | No locks (versioning) |

### Practical Example: E-commerce Order Processing

```sql
CREATE PROCEDURE sp_PlaceOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    -- Use SERIALIZABLE for critical inventory operations
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @AvailableStock INT;

        -- Lock the inventory row
        SELECT @AvailableStock = StockQuantity
        FROM Inventory WITH (HOLDLOCK)
        WHERE ProductID = @ProductID;

        IF @AvailableStock >= @Quantity
        BEGIN
            -- Reduce inventory
            UPDATE Inventory
            SET StockQuantity = StockQuantity - @Quantity
            WHERE ProductID = @ProductID;

            -- Create order
            INSERT INTO Orders (CustomerID, OrderDate, Status)
            VALUES (@CustomerID, GETDATE(), 'Confirmed');

            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Insufficient stock', 16, 1);
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
```

---

## Q203: Explain READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, and SERIALIZABLE.

**Answer:**

Covered in detail in Q202 above. Here's a focused comparison:

### Quick Reference with Real-World Examples

```sql
-- ============================================
-- READ UNCOMMITTED - "I don't care about accuracy"
-- ============================================
-- Use for: Dashboards, approximate counts, analytics

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT COUNT(*) FROM Orders;  -- Might include uncommitted/rolled-back orders
SELECT AVG(Price) FROM Products;  -- Approximate average is fine

-- ============================================
-- READ COMMITTED - "Show me only committed data"
-- ============================================
-- Use for: General web applications, most business logic

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM Customers WHERE CustomerID = 123;
-- Won't see uncommitted changes, but data might change between reads

-- ============================================
-- REPEATABLE READ - "Lock what I read"
-- ============================================
-- Use for: Reports that need consistency, batch processing

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT SUM(Balance) FROM Accounts WHERE CustomerID = 123;
    -- Balance values locked - won't change during transaction

    -- ... more processing ...

    SELECT SUM(Balance) FROM Accounts WHERE CustomerID = 123;
    -- Same result guaranteed!
COMMIT TRANSACTION;

-- ============================================
-- SERIALIZABLE - "Complete isolation"
-- ============================================
-- Use for: Financial transactions, inventory management

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM Inventory WHERE ProductID = 1 AND Qty >= 10)
    BEGIN
        -- Range is locked - no inserts/updates/deletes in this range
        UPDATE Inventory SET Qty = Qty - 10 WHERE ProductID = 1;
    END
COMMIT TRANSACTION;
```

### Decision Tree for Choosing Isolation Level

```
Is data accuracy critical?
│
├─ NO  → READ UNCOMMITTED (reports, analytics)
│
└─ YES → Are you reading same data multiple times in transaction?
          │
          ├─ NO  → READ COMMITTED (default, most apps)
          │
          └─ YES → Do you need to prevent phantom reads?
                   │
                   ├─ NO  → REPEATABLE READ
                   │
                   └─ YES → SERIALIZABLE or SNAPSHOT
```

---

## Q204: What is dirty read, non-repeatable read, and phantom read?

**Answer:**

These are **concurrency anomalies** that can occur when multiple transactions access the same data simultaneously.

### 1. Dirty Read

Reading **uncommitted** data that might be rolled back.

```sql
-- ============================================
-- DIRTY READ EXAMPLE
-- ============================================

-- Session 1 (Writer)
BEGIN TRANSACTION;
    UPDATE BankAccount
    SET Balance = Balance + 1000000  -- Add $1M
    WHERE AccountID = 'A001';

    -- Transaction not committed yet!
    WAITFOR DELAY '00:00:30';

    ROLLBACK TRANSACTION;  -- Oops, mistake! Rollback

-- Session 2 (Reader - using READ UNCOMMITTED)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Balance FROM BankAccount WHERE AccountID = 'A001';
-- Reads: $1,000,000 (THE DIRTY READ!)
-- This money doesn't actually exist!

-- Real-world problem: User sees $1M balance and makes a purchase,
-- but account actually has $0!
```

**Prevention:**
```sql
-- Use READ COMMITTED or higher
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Balance FROM BankAccount WHERE AccountID = 'A001';
-- Waits for Session 1 to commit/rollback, then reads committed value
```

---

### 2. Non-Repeatable Read

Same query returns **different results** within the same transaction.

```sql
-- ============================================
-- NON-REPEATABLE READ EXAMPLE
-- ============================================

-- Session 1 (Reader)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

    -- Read 1
    SELECT Price FROM Products WHERE ProductID = 100;
    -- Returns: $50.00

    -- Business logic here...
    WAITFOR DELAY '00:00:10';

    -- Read 2 (same query in same transaction)
    SELECT Price FROM Products WHERE ProductID = 100;
    -- Returns: $75.00  -- DIFFERENT VALUE! (Non-repeatable read)

    -- Problem: Calculations might be wrong if we used first value!

COMMIT TRANSACTION;

-- Session 2 (Writer - runs during Session 1's delay)
BEGIN TRANSACTION;
    UPDATE Products
    SET Price = 75.00
    WHERE ProductID = 100;
COMMIT TRANSACTION;
```

**Real-world scenario:**
```sql
-- Pricing calculation broken by non-repeatable read
BEGIN TRANSACTION;
    DECLARE @BasePrice DECIMAL(10,2);
    DECLARE @TaxRate DECIMAL(5,2);

    SELECT @BasePrice = Price FROM Products WHERE ProductID = 100;
    -- Reads: $50.00

    -- Another transaction updates price to $75.00 here!

    SELECT @TaxRate = TaxRate FROM TaxRates WHERE Region = 'NY';

    -- Calculate total (using old price!)
    DECLARE @Total DECIMAL(10,2) = @BasePrice * (1 + @TaxRate);

    INSERT INTO OrderDetails (ProductID, Price, Total)
    VALUES (100, @BasePrice, @Total);
    -- Wrong total! Price changed mid-transaction

COMMIT TRANSACTION;
```

**Prevention:**
```sql
-- Use REPEATABLE READ or higher
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 100;  -- $50.00

    WAITFOR DELAY '00:00:10';

    SELECT Price FROM Products WHERE ProductID = 100;  -- Still $50.00
    -- Other transactions CANNOT update this row until we commit
COMMIT TRANSACTION;
```

---

### 3. Phantom Read

New rows **appear or disappear** between reads in the same transaction.

```sql
-- ============================================
-- PHANTOM READ EXAMPLE
-- ============================================

-- Session 1 (Reader)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

    -- Read 1: Count high-value customers
    SELECT COUNT(*) AS HighValueCustomers
    FROM Customers
    WHERE TotalPurchases > 10000;
    -- Returns: 50

    WAITFOR DELAY '00:00:10';

    -- Read 2: Same query
    SELECT COUNT(*) AS HighValueCustomers
    FROM Customers
    WHERE TotalPurchases > 10000;
    -- Returns: 51  -- PHANTOM ROW APPEARED!

    -- Problem: Report shows inconsistent numbers

COMMIT TRANSACTION;

-- Session 2 (Writer - runs during Session 1's delay)
BEGIN TRANSACTION;
    -- Insert a new customer (PHANTOM!)
    INSERT INTO Customers (CustomerID, Name, TotalPurchases)
    VALUES (9999, 'New Customer', 15000);
COMMIT TRANSACTION;

-- Note: REPEATABLE READ prevents updates to existing rows,
-- but doesn't prevent inserts (phantoms)
```

**Detailed Example:**
```sql
-- Inventory allocation problem with phantom reads
CREATE PROCEDURE sp_AllocateInventory
    @WarehouseID INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    BEGIN TRANSACTION;

        -- Step 1: Get total available inventory
        SELECT @TotalAvailable = SUM(Quantity)
        FROM Inventory
        WHERE WarehouseID = @WarehouseID AND Status = 'Available';
        -- Returns: 1000 units

        -- Step 2: Business logic processing
        WAITFOR DELAY '00:00:05';

        -- Step 3: Allocate inventory to orders
        INSERT INTO Allocations (OrderID, Quantity)
        SELECT TOP 10 OrderID, RequiredQuantity
        FROM PendingOrders
        WHERE WarehouseID = @WarehouseID;

        -- Step 4: Re-check inventory (PHANTOM READ!)
        SELECT @TotalAvailable = SUM(Quantity)
        FROM Inventory
        WHERE WarehouseID = @WarehouseID AND Status = 'Available';
        -- Returns: 1500 units  -- NEW ROW APPEARED!

        -- Problem: Allocation logic might be wrong!

    COMMIT TRANSACTION;
END
GO

-- Another session inserted inventory during our transaction:
BEGIN TRANSACTION;
    INSERT INTO Inventory (WarehouseID, ProductID, Quantity, Status)
    VALUES (1, 500, 500, 'Available');  -- PHANTOM!
COMMIT TRANSACTION;
```

**Prevention:**
```sql
-- Use SERIALIZABLE or SNAPSHOT
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT COUNT(*) FROM Customers WHERE TotalPurchases > 10000;  -- 50

    -- Range is LOCKED - no inserts allowed

    WAITFOR DELAY '00:00:10';

    SELECT COUNT(*) FROM Customers WHERE TotalPurchases > 10000;  -- Still 50
    -- No phantoms!
COMMIT TRANSACTION;
```

### Summary Table

| Anomaly | What Happens | Example | Prevention |
|---------|--------------|---------|------------|
| **Dirty Read** | Read uncommitted data that might rollback | Bank shows $1M that doesn't exist | READ COMMITTED+ |
| **Non-Repeatable Read** | Same row changes between reads | Price changes from $50 to $75 mid-transaction | REPEATABLE READ+ |
| **Phantom Read** | New rows appear/disappear between reads | Customer count changes from 50 to 51 | SERIALIZABLE or SNAPSHOT |

### Visual Comparison

```
Time  →  Session 1                              Session 2
────────────────────────────────────────────────────────────────
T1       BEGIN TRAN
T2       SELECT Price = $50
T3                                              BEGIN TRAN
T4                                              UPDATE Price = $75
T5       SELECT Price = ?
T6                                              COMMIT
T7       COMMIT

READ UNCOMMITTED:  T5 reads $75 (dirty read - not committed)
READ COMMITTED:    T5 reads $75 (non-repeatable read - committed)
REPEATABLE READ:   T5 reads $50 (locks prevent update)
SERIALIZABLE:      T5 reads $50 (complete isolation)
```

---

## Q205: What is deadlock? How do you prevent and handle deadlocks?

**Answer:**

A **deadlock** occurs when two or more transactions are waiting for each other to release locks, creating a circular dependency. Neither can proceed.

### Classic Deadlock Scenario

```sql
-- ============================================
-- DEADLOCK EXAMPLE
-- ============================================

-- Session 1
BEGIN TRANSACTION;
    -- Lock Table A
    UPDATE Accounts SET Balance = Balance - 100
    WHERE AccountID = 'A001';

    WAITFOR DELAY '00:00:05';  -- Simulate processing

    -- Try to lock Table B (blocked by Session 2)
    UPDATE Orders SET Status = 'Processed'
    WHERE OrderID = 1001;

COMMIT TRANSACTION;

-- Session 2 (runs concurrently)
BEGIN TRANSACTION;
    -- Lock Table B
    UPDATE Orders SET Status = 'Pending'
    WHERE OrderID = 1001;

    WAITFOR DELAY '00:00:05';  -- Simulate processing

    -- Try to lock Table A (blocked by Session 1)
    UPDATE Accounts SET Balance = Balance + 100
    WHERE AccountID = 'A001';

COMMIT TRANSACTION;

-- Result: DEADLOCK!
-- Session 1 waits for Session 2
-- Session 2 waits for Session 1
-- SQL Server detects and kills one transaction (deadlock victim)
```

### Deadlock Error Message

```
Msg 1205, Level 13, State 51, Line 1
Transaction (Process ID 52) was deadlocked on lock resources
with another process and has been chosen as the deadlock victim.
Rerun the transaction.
```

---

### Prevention Strategies

#### 1. Access Resources in Same Order

```sql
-- ❌ BAD - Different order causes deadlocks
-- Session 1
UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 'A001';
UPDATE Orders SET Status = 'Processed' WHERE OrderID = 1001;

-- Session 2
UPDATE Orders SET Status = 'Pending' WHERE OrderID = 1001;
UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 'A001';

-- ✅ GOOD - Same order prevents deadlocks
-- Session 1
UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 'A001';
UPDATE Orders SET Status = 'Processed' WHERE OrderID = 1001;

-- Session 2
UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 'A001';
UPDATE Orders SET Status = 'Pending' WHERE OrderID = 1001;
```

#### 2. Keep Transactions Short

```sql
-- ❌ BAD - Long transaction holds locks
BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 10 WHERE ProductID = 1;

    -- Long operation
    WAITFOR DELAY '00:01:00';

    -- Complex calculation
    DECLARE @Result INT = dbo.ComplexCalculation(@ProductID);

    UPDATE Orders SET Status = 'Processed' WHERE OrderID = @OrderID;
COMMIT TRANSACTION;

-- ✅ GOOD - Short transaction
DECLARE @Result INT;

-- Do calculations outside transaction
SET @Result = dbo.ComplexCalculation(@ProductID);

BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 10 WHERE ProductID = 1;
    UPDATE Orders SET Status = 'Processed' WHERE OrderID = @OrderID;
COMMIT TRANSACTION;
```

#### 3. Use Appropriate Isolation Levels

```sql
-- ✅ Use SNAPSHOT isolation to avoid locking
ALTER DATABASE YourDB SET ALLOW_SNAPSHOT_ISOLATION ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    -- No locks acquired, uses row versioning
    SELECT * FROM Orders WHERE CustomerID = 123;
    UPDATE Orders SET Status = 'Processed' WHERE OrderID = 1001;
COMMIT TRANSACTION;
```

#### 4. Use NOLOCK Hint (Carefully!)

```sql
-- For read-only queries where dirty reads are acceptable
SELECT * FROM Orders WITH (NOLOCK) WHERE CustomerID = 123;
-- Equivalent to READ UNCOMMITTED - no locks acquired
```

#### 5. Set Deadlock Priority

```sql
-- Make this session less likely to be chosen as victim
SET DEADLOCK_PRIORITY HIGH;

BEGIN TRANSACTION;
    -- Transaction logic
COMMIT TRANSACTION;

-- Or make it more likely to be victim (for background jobs)
SET DEADLOCK_PRIORITY LOW;
```

---

### Handling Deadlocks

#### 1. Retry Logic

```sql
CREATE PROCEDURE sp_ProcessOrderWithRetry
    @OrderID INT,
    @MaxRetries INT = 3
AS
BEGIN
    DECLARE @RetryCount INT = 0;
    DECLARE @Success BIT = 0;

    WHILE @RetryCount < @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

                -- Order processing logic
                UPDATE Orders SET Status = 'Processing'
                WHERE OrderID = @OrderID;

                UPDATE Inventory SET Quantity = Quantity - 1
                WHERE ProductID = (SELECT ProductID FROM Orders WHERE OrderID = @OrderID);

            COMMIT TRANSACTION;

            SET @Success = 1;  -- Success!

        END TRY
        BEGIN CATCH
            -- Rollback if transaction active
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            -- Check if deadlock
            IF ERROR_NUMBER() = 1205  -- Deadlock error number
            BEGIN
                SET @RetryCount = @RetryCount + 1;

                -- Log deadlock
                INSERT INTO DeadlockLog (OrderID, AttemptNumber, ErrorTime)
                VALUES (@OrderID, @RetryCount, GETDATE());

                -- Exponential backoff
                WAITFOR DELAY '00:00:01';  -- Wait 1 second before retry

                IF @RetryCount >= @MaxRetries
                BEGIN
                    -- Max retries exceeded
                    RAISERROR('Order processing failed after %d attempts due to deadlocks',
                              16, 1, @MaxRetries);
                END
            END
            ELSE
            BEGIN
                -- Different error - don't retry
                THROW;
            END
        END CATCH
    END
END
GO
```

#### 2. Deadlock Detection and Monitoring

```sql
-- Enable deadlock graph in Extended Events
CREATE EVENT SESSION DeadlockMonitor ON SERVER
ADD EVENT sqlserver.xml_deadlock_report
ADD TARGET package0.event_file(SET filename=N'C:\Temp\Deadlocks.xel')
GO

ALTER EVENT SESSION DeadlockMonitor ON SERVER STATE = START;
GO

-- Query to find recent deadlocks
SELECT
    CAST(target_data AS XML) AS DeadlockGraph,
    CAST(target_data AS XML).value('(/event/@timestamp)[1]', 'datetime') AS DeadlockTime
FROM sys.fn_xe_file_target_read_file('C:\Temp\Deadlocks*.xel', NULL, NULL, NULL);
```

#### 3. Analyze Deadlock Graph

```sql
-- View deadlock information
-- Use SQL Server Profiler or Extended Events to capture deadlock graph
-- The graph shows:
-- - Which processes were involved
-- - Which resources they were waiting for
-- - Which process was chosen as victim
```

---

### Advanced Prevention Techniques

#### 1. Use Table Hints

```sql
-- Update with UPDLOCK to prevent deadlocks
BEGIN TRANSACTION;
    -- Acquire update lock immediately
    SELECT @Quantity = Quantity
    FROM Inventory WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductID = @ProductID;

    IF @Quantity >= @RequiredQty
    BEGIN
        UPDATE Inventory
        SET Quantity = Quantity - @RequiredQty
        WHERE ProductID = @ProductID;
    END
COMMIT TRANSACTION;
```

#### 2. Application-Level Locking

```sql
-- Use application locks for complex scenarios
BEGIN TRANSACTION;

    -- Acquire application lock
    EXEC sp_getapplock
        @Resource = 'OrderProcessing',
        @LockMode = 'Exclusive',
        @LockOwner = 'Transaction';

    -- Process order (protected by app lock)
    UPDATE Orders SET Status = 'Processing' WHERE OrderID = @OrderID;
    UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = @ProductID;

    -- Release lock
    EXEC sp_releaseapplock
        @Resource = 'OrderProcessing',
        @LockOwner = 'Transaction';

COMMIT TRANSACTION;
```

#### 3. Partition Data

```sql
-- Reduce contention by partitioning hot tables
-- Instead of single Inventory table:
CREATE TABLE Inventory_Partition1 (...);
CREATE TABLE Inventory_Partition2 (...);
CREATE TABLE Inventory_Partition3 (...);

-- Route updates based on ProductID hash
-- Different partitions = less lock contention
```

### Best Practices Summary

1. ✅ Access tables in consistent order
2. ✅ Keep transactions short
3. ✅ Use appropriate isolation levels
4. ✅ Implement retry logic with exponential backoff
5. ✅ Monitor and analyze deadlock graphs
6. ✅ Use covering indexes to reduce lock duration
7. ✅ Consider SNAPSHOT isolation for read-heavy workloads
8. ✅ Use application locks for complex scenarios
9. ✅ Partition hot tables to reduce contention
10. ✅ Test under concurrent load to identify potential deadlocks

---

## Questions 200-205 Complete!

✅ **Coverage:**
- Q200: Views and Indexed Views
- Q201: Transactions and ACID Properties
- Q202: Transaction Isolation Levels
- Q203: Isolation Levels Detailed
- Q204: Dirty Reads, Non-Repeatable Reads, Phantom Reads
- Q205: Deadlocks - Prevention and Handling

**Next batch (Q206-Q220) will cover:**
- Blocking and Locking
- Query Optimization
- SQL Server Performance Tuning
- Entity Framework Core

Ready to continue with the next set!
