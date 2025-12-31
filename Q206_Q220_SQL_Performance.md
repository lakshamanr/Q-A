# INTERVIEW QUESTIONS 206-220: SQL Performance & Entity Framework

## SECTION 5: SQL SERVER & DATABASE (Continued)

---

## Q206: What is blocking in SQL Server?

**Answer:**

**Blocking** occurs when one transaction holds a lock on a resource and another transaction wants an incompatible lock on the same resource. Unlike deadlocks, blocking is temporary and resolves when the first transaction releases its lock.

### Understanding Blocking

```sql
-- ============================================
-- BLOCKING EXAMPLE
-- ============================================

-- Session 1 (Blocker)
BEGIN TRANSACTION;
    -- Acquires exclusive lock on this row
    UPDATE Employees
    SET Salary = Salary * 1.10
    WHERE EmployeeID = 100;

    -- Long running operation
    WAITFOR DELAY '00:02:00';  -- Holds lock for 2 minutes

COMMIT TRANSACTION;

-- Session 2 (Blocked)
-- This query waits until Session 1 commits/rollbacks
SELECT * FROM Employees WHERE EmployeeID = 100;
-- Waiting... waiting... waiting...

-- Session 3 (Also Blocked)
UPDATE Employees
SET Department = 'Sales'
WHERE EmployeeID = 100;
-- Also waiting for Session 1
```

### Types of Locks That Cause Blocking

```sql
-- ============================================
-- LOCK TYPES
-- ============================================

-- 1. Shared Lock (S) - For reads
SELECT * FROM Employees WHERE EmployeeID = 100;
-- Blocks: Exclusive locks
-- Allows: Other shared locks

-- 2. Exclusive Lock (X) - For writes
UPDATE Employees SET Salary = 50000 WHERE EmployeeID = 100;
-- Blocks: All other locks (shared and exclusive)

-- 3. Update Lock (U) - Intent to update
SELECT * FROM Employees WITH (UPDLOCK) WHERE EmployeeID = 100;
-- Prevents deadlocks in read-then-update scenarios

-- 4. Intent Locks (IS, IX, IU)
-- Acquired on higher-level resources (table level)
-- to indicate locks at lower levels (row level)
```

### Detecting Blocking

#### 1. Using sys.dm_exec_requests

```sql
-- Find blocked sessions
SELECT
    blocking.session_id AS BlockingSessionID,
    blocked.session_id AS BlockedSessionID,
    blocking.login_name AS BlockingUser,
    blocked.login_name AS BlockedUser,
    blocking.host_name AS BlockingHost,
    blocked.wait_time AS WaitTimeMs,
    blocked.wait_type,
    blocking_sql.text AS BlockingQuery,
    blocked_sql.text AS BlockedQuery
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_sessions blocking
    ON blocked.blocking_session_id = blocking.session_id
LEFT JOIN sys.dm_exec_sql_text(blocking.sql_handle) AS blocking_sql
LEFT JOIN sys.dm_exec_sql_text(blocked.sql_handle) AS blocked_sql
WHERE blocked.blocking_session_id <> 0;
```

#### 2. Using sp_who2

```sql
-- Quick view of all sessions
EXEC sp_who2;

-- Look for:
-- - High CPU time
-- - Status = 'SUSPENDED' (blocked)
-- - BlkBy column showing blocking session
```

#### 3. Using Activity Monitor

```
Right-click SQL Server instance in SSMS
→ Activity Monitor
→ View "Processes" section
→ Look for blocked/blocking sessions
```

### Resolving Blocking

#### 1. Kill the Blocking Session (Last Resort)

```sql
-- Find the blocking session
SELECT session_id, blocking_session_id
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Kill the blocker (use carefully!)
KILL 52;  -- 52 is the blocking session_id

-- Better: Investigate what the query is doing first!
```

#### 2. Optimize the Blocking Query

```sql
-- ❌ BAD - Holds locks for long time
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processing'
    WHERE CustomerID = 100;

    -- Complex processing
    EXEC sp_ComplexBusinessLogic;

    -- External API call
    EXEC sp_CallExternalAPI;

COMMIT TRANSACTION;

-- ✅ GOOD - Minimize lock duration
-- Do external work outside transaction
EXEC sp_ComplexBusinessLogic;
EXEC sp_CallExternalAPI;

BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processing'
    WHERE CustomerID = 100;
COMMIT TRANSACTION;
```

#### 3. Use Row Versioning (SNAPSHOT Isolation)

```sql
-- Enable snapshot isolation
ALTER DATABASE YourDB SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE YourDB SET READ_COMMITTED_SNAPSHOT ON;

-- Readers don't block writers, writers don't block readers!
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SELECT * FROM Employees WHERE EmployeeID = 100;
-- No blocking - uses row versioning
```

#### 4. Use NOLOCK Hint (For Reads Only)

```sql
-- Allow dirty reads to avoid blocking
SELECT * FROM Orders WITH (NOLOCK)
WHERE CustomerID = 100;

-- Warning: May read uncommitted/inconsistent data
-- Use only for reports where accuracy isn't critical
```

### Monitoring Blocking in Production

#### 1. Create Blocking Alert

```sql
-- Create alert for blocking > 30 seconds
USE msdb;
GO

EXEC sp_add_alert
    @name = N'Blocking Alert',
    @message_id = 0,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 300,  -- 5 minutes
    @include_event_description_in = 1,
    @performance_condition = N'SQLServer:General Statistics|User Connections||>|100';
GO
```

#### 2. Create Blocking Report Job

```sql
CREATE PROCEDURE usp_ReportBlocking
AS
BEGIN
    -- Log blocking chains
    INSERT INTO BlockingLog (LogTime, BlockingSessionID, BlockedSessionID, WaitTimeMs)
    SELECT
        GETDATE(),
        blocking_session_id,
        session_id,
        wait_time
    FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
      AND wait_time > 30000;  -- More than 30 seconds

    -- Send alert email if serious blocking
    IF EXISTS (SELECT 1 FROM sys.dm_exec_requests
               WHERE blocking_session_id <> 0 AND wait_time > 60000)
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'DBA',
            @recipients = 'dba@company.com',
            @subject = 'Critical Blocking Detected',
            @body = 'Blocking exceeds 60 seconds';
    END
END
GO

-- Schedule to run every minute
```

### Preventing Blocking

#### 1. Use Indexes

```sql
-- ❌ BAD - Table scan holds many locks
SELECT * FROM Orders WHERE OrderDate = '2025-01-01';
-- Locks entire table during scan

-- ✅ GOOD - Index seek locks fewer rows
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
SELECT * FROM Orders WHERE OrderDate = '2025-01-01';
-- Locks only matching rows
```

#### 2. Keep Transactions Short

```sql
-- ❌ BAD
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;

    -- User input wait
    WAITFOR DELAY '00:05:00';

    UPDATE Orders SET Status = 'Processed' WHERE ProductID = 1;
COMMIT TRANSACTION;

-- ✅ GOOD
UPDATE Products SET Price = 100 WHERE ProductID = 1;

-- Get user input outside transaction
DECLARE @UserInput VARCHAR(100);
-- ... get input ...

BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processed' WHERE ProductID = 1;
COMMIT TRANSACTION;
```

#### 3. Use Read Uncommitted for Reports

```sql
-- Reports don't need transactional consistency
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE OrderDate = CAST(GETDATE() AS DATE);
```

---

## Q207: Explain optimistic vs pessimistic locking.

**Answer:**

**Locking strategies** determine how concurrent data access is managed.

### Pessimistic Locking

Assumes conflicts **will** happen. Locks data when read, preventing others from modifying it.

```sql
-- ============================================
-- PESSIMISTIC LOCKING EXAMPLE
-- ============================================

BEGIN TRANSACTION;

    -- Lock the row immediately
    SELECT @CurrentQuantity = Quantity
    FROM Inventory WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductID = @ProductID;

    -- Business logic
    IF @CurrentQuantity >= @RequestedQuantity
    BEGIN
        -- Update (we hold the lock)
        UPDATE Inventory
        SET Quantity = Quantity - @RequestedQuantity
        WHERE ProductID = @ProductID;

        -- Success
        SELECT 'Inventory allocated' AS Result;
    END
    ELSE
    BEGIN
        -- Insufficient inventory
        SELECT 'Insufficient inventory' AS Result;
    END

COMMIT TRANSACTION;

-- Other sessions CANNOT update this row until we commit
```

**Advantages:**
- ✅ Guarantees no conflicts
- ✅ Simple to implement
- ✅ Works well with low concurrency

**Disadvantages:**
- ❌ Reduces concurrency
- ❌ Can cause blocking
- ❌ Potential for deadlocks

---

### Optimistic Locking

Assumes conflicts **rarely** happen. Only checks for conflicts when updating.

```sql
-- ============================================
-- OPTIMISTIC LOCKING WITH ROWVERSION
-- ============================================

-- 1. Add RowVersion column to table
ALTER TABLE Products
ADD RowVersion ROWVERSION;

-- 2. Read data (no lock)
DECLARE @RowVersion BINARY(8);

SELECT
    @Price = Price,
    @RowVersion = RowVersion  -- Save version
FROM Products
WHERE ProductID = @ProductID;

-- 3. User makes changes (no lock held during this time)
-- ... user input, business logic, etc. ...

-- 4. Update with version check
UPDATE Products
SET
    Price = @NewPrice,
    LastModified = GETDATE()
WHERE ProductID = @ProductID
  AND RowVersion = @RowVersion;  -- Check if version matches

-- 5. Check if update succeeded
IF @@ROWCOUNT = 0
BEGIN
    -- Conflict! Data changed by another user
    RAISERROR('Data was modified by another user. Please refresh and try again.', 16, 1);
END
ELSE
BEGIN
    -- Success
    SELECT 'Update successful' AS Result;
END
```

**Advantages:**
- ✅ Higher concurrency
- ✅ No blocking
- ✅ Better performance for read-heavy workloads

**Disadvantages:**
- ❌ Must handle conflicts in application
- ❌ Updates may fail
- ❌ Requires retry logic

---

### Comparison: Pessimistic vs Optimistic

```sql
-- ============================================
-- SIDE-BY-SIDE COMPARISON
-- ============================================

-- PESSIMISTIC: Lock immediately
BEGIN TRANSACTION;
    -- Locks row NOW
    SELECT Price FROM Products WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductID = 1;

    -- 30 seconds of processing (row is locked entire time)
    WAITFOR DELAY '00:00:30';

    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT TRANSACTION;
-- Total lock time: 30+ seconds

-- OPTIMISTIC: Lock only during update
-- Read (no lock)
SELECT @Price = Price, @RowVersion = RowVersion
FROM Products
WHERE ProductID = 1;

-- 30 seconds of processing (no lock held)
WAITFOR DELAY '00:00:30';

-- Lock only for update (milliseconds)
BEGIN TRANSACTION;
    UPDATE Products
    SET Price = 100
    WHERE ProductID = 1 AND RowVersion = @RowVersion;
COMMIT TRANSACTION;
-- Total lock time: milliseconds
```

### Implementation Patterns

#### 1. Optimistic Locking with Timestamp

```sql
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    TotalAmount DECIMAL(18,2),
    RowVersion ROWVERSION,  -- Automatically updated by SQL Server
    LastModified DATETIME2
);

-- Application Code (C#)
```

```csharp
// Read order
var order = dbContext.Orders.Find(orderId);
byte[] originalVersion = order.RowVersion;  // Save version

// User modifies order
order.TotalAmount = 500;

// Try to save
try
{
    // EF Core automatically includes RowVersion in WHERE clause
    dbContext.SaveChanges();
}
catch (DbUpdateConcurrencyException ex)
{
    // Conflict detected!
    var entry = ex.Entries.Single();
    var databaseValues = entry.GetDatabaseValues();

    if (databaseValues == null)
    {
        // Row was deleted
        ModelState.AddModelError("", "The record was deleted by another user.");
    }
    else
    {
        // Row was modified
        ModelState.AddModelError("", "The record was modified by another user. Refresh and try again.");
    }
}
```

#### 2. Optimistic Locking with Timestamp Column

```sql
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    LastModified DATETIME2 DEFAULT GETDATE()
);

-- Update with timestamp check
DECLARE @LastModified DATETIME2;

SELECT @LastModified = LastModified
FROM Products
WHERE ProductID = @ProductID;

-- Process...

UPDATE Products
SET
    Price = @NewPrice,
    LastModified = GETDATE()
WHERE ProductID = @ProductID
  AND LastModified = @LastModified;  -- Conflict detection

IF @@ROWCOUNT = 0
    RAISERROR('Concurrency conflict detected', 16, 1);
```

#### 3. Pessimistic Locking with Application Lock

```sql
CREATE PROCEDURE sp_UpdateInventoryPessimistic
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    BEGIN TRANSACTION;

        -- Acquire application lock
        DECLARE @Result INT;
        EXEC @Result = sp_getapplock
            @Resource = @ProductID,
            @LockMode = 'Exclusive',
            @LockOwner = 'Transaction',
            @LockTimeout = 5000;  -- 5 second timeout

        IF @Result < 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Could not acquire lock', 16, 1);
            RETURN;
        END

        -- Update inventory
        UPDATE Inventory
        SET Quantity = Quantity - @Quantity
        WHERE ProductID = @ProductID;

        -- Release lock (automatic on commit)
    COMMIT TRANSACTION;
END
GO
```

### When to Use Each

| Scenario | Recommended Strategy |
|----------|---------------------|
| **High read, low write** | Optimistic |
| **High write, high contention** | Pessimistic |
| **Short transactions** | Optimistic |
| **Long-running transactions** | Pessimistic |
| **User interactive (edit forms)** | Optimistic |
| **Batch processing** | Pessimistic |
| **Financial transactions** | Pessimistic |
| **Inventory management (critical)** | Pessimistic |
| **Product catalog** | Optimistic |
| **Reporting/analytics** | Optimistic (or no locking) |

---

## Q208: What is query execution plan? How do you analyze it?

**Answer:**

A **query execution plan** is SQL Server's roadmap for executing a query. It shows operations, order, cost, and methods used.

### Types of Execution Plans

#### 1. Estimated Execution Plan
```sql
-- Show estimated plan (doesn't execute query)
SET SHOWPLAN_XML ON;
SELECT * FROM Orders WHERE CustomerID = 100;
SET SHOWPLAN_XML OFF;

-- Or use SSMS: Ctrl+L
```

#### 2. Actual Execution Plan
```sql
-- Show actual plan (executes query)
SET STATISTICS XML ON;
SELECT * FROM Orders WHERE CustomerID = 100;
SET STATISTICS XML OFF;

-- Or use SSMS: Ctrl+M, then run query
```

### Reading Execution Plans

Execution plans are read **right-to-left** and **top-to-bottom**.

```sql
-- ============================================
-- EXAMPLE QUERY
-- ============================================
SELECT
    c.CustomerName,
    o.OrderDate,
    od.Quantity,
    p.ProductName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 100;

/*
Execution Plan (simplified):
1. Clustered Index Seek on Customers (Cost: 0.003%)
2. Nested Loop (Cost: 5%)
   ├─ Index Seek on Orders (Cost: 15%)
   └─ Nested Loop (Cost: 30%)
      ├─ Index Seek on OrderDetails (Cost: 25%)
      └─ Key Lookup on Products (Cost: 25%)
*/
```

### Key Plan Operations

#### 1. Index Seek (Good!)
```sql
-- Efficiently uses index
SELECT * FROM Orders WHERE OrderID = 1000;

-- Plan shows: Index Seek (NonClustered)
-- Cost: ~0.003%
-- Rows Read: 1
```

#### 2. Index Scan (Could be better)
```sql
-- Scans entire index
SELECT * FROM Orders WHERE OrderDate > '2025-01-01';

-- Plan shows: Index Scan (NonClustered)
-- Cost: ~5%
-- Rows Read: 10,000 (entire index)

-- Fix: Add filtered index or covering index
CREATE INDEX IX_Orders_OrderDate
ON Orders(OrderDate) INCLUDE (CustomerID, TotalAmount);
```

#### 3. Table Scan (Bad!)
```sql
-- No index available
SELECT * FROM Orders WHERE YEAR(OrderDate) = 2025;

-- Plan shows: Table Scan
-- Cost: ~80%
-- Rows Read: 1,000,000 (entire table!)

-- Fix 1: Don't use functions on columns
SELECT * FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2026-01-01';

-- Fix 2: Add computed column and index
ALTER TABLE Orders ADD OrderYear AS YEAR(OrderDate);
CREATE INDEX IX_Orders_OrderYear ON Orders(OrderYear);
```

#### 4. Key Lookup (Performance Killer!)
```sql
-- Index seek followed by lookup for additional columns
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);

SELECT CustomerID, OrderDate, TotalAmount
FROM Orders
WHERE CustomerID = 100;

-- Plan shows:
-- 1. Index Seek on IX_Orders_CustomerID (finds rows)
-- 2. Key Lookup (retrieves OrderDate, TotalAmount from clustered index)
-- Cost: High for many rows!

-- Fix: Covering index
CREATE INDEX IX_Orders_CustomerID_Covering
ON Orders(CustomerID) INCLUDE (OrderDate, TotalAmount);

-- Now: Single Index Seek (no lookup needed)
```

#### 5. Nested Loop Join (Good for small datasets)
```sql
SELECT *
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID = 100;

-- Plan shows: Nested Loop Join
-- Good when outer table is small (1 customer)
-- For each row in outer table, seek in inner table
```

#### 6. Hash Match Join (Good for large datasets)
```sql
SELECT *
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Plan shows: Hash Match (Inner Join)
-- Builds hash table from one input
-- Probes with other input
-- Good for large datasets without indexes
```

#### 7. Merge Join (Best with sorted inputs)
```sql
SELECT *
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;

-- Plan shows: Merge Join
-- Both inputs sorted on join key
-- Most efficient join for sorted data
```

### Analyzing Query Performance

```sql
-- ============================================
-- PERFORMANCE ANALYSIS EXAMPLE
-- ============================================

-- Enable statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Run query
SELECT
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City = 'New York'
GROUP BY c.CustomerID, c.CustomerName;

/*
Output:
SQL Server parse and compile time:
   CPU time = 15 ms, elapsed time = 20 ms.

SQL Server Execution Times:
   CPU time = 250 ms, elapsed time = 300 ms.

Table 'Orders'. Scan count 1, logical reads 50000
Table 'Customers'. Scan count 1, logical reads 10000
*/

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

### Key Metrics to Analyze

#### 1. Query Cost
```sql
-- Relative cost compared to batch
-- Look for high-cost operations (>20% of total)
```

#### 2. Number of Rows
```sql
-- Estimated Rows vs Actual Rows
-- Large discrepancy = outdated statistics

-- Update statistics
UPDATE STATISTICS Orders WITH FULLSCAN;

-- Or enable auto-update
ALTER DATABASE YourDB SET AUTO_UPDATE_STATISTICS ON;
```

#### 3. I/O Statistics
```sql
-- Logical reads = pages read from buffer cache
-- Physical reads = pages read from disk (should be low)

-- Bad: High logical reads
Table 'Orders'. Scan count 1, logical reads 500000

-- Good: Low logical reads
Table 'Orders'. Scan count 1, logical reads 15
```

#### 4. Warnings (Red exclamation marks)
```sql
-- Common warnings:
-- 1. Missing Index
-- 2. Implicit Conversion
-- 3. Cardinality Estimate Warning
-- 4. Excessive Grant (memory)

-- Example: Implicit conversion
SELECT * FROM Orders
WHERE OrderID = '1000';  -- OrderID is INT, comparing to VARCHAR

-- Fix:
SELECT * FROM Orders
WHERE OrderID = 1000;
```

### Using Missing Index Suggestions

```sql
-- Query returns missing index recommendations
SELECT
    mid.statement AS TableName,
    migs.avg_user_impact AS AvgImpactPercent,
    migs.user_seeks + migs.user_scans AS TotalSeeksAndScans,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
WHERE migs.avg_user_impact > 20  -- More than 20% improvement
ORDER BY migs.avg_user_impact DESC;

-- Generate CREATE INDEX statement
-- But REVIEW FIRST - don't blindly create all suggested indexes!
```

### Plan Cache Analysis

```sql
-- Find expensive queries in plan cache
SELECT TOP 20
    qs.execution_count,
    qs.total_worker_time / 1000 AS TotalCPUms,
    qs.total_elapsed_time / 1000 AS TotalElapsedms,
    qs.total_logical_reads,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_worker_time DESC;  -- Order by CPU time
```

### Best Practices

1. ✅ Always review execution plan for slow queries
2. ✅ Look for Table Scans - replace with Index Seeks
3. ✅ Eliminate Key Lookups with covering indexes
4. ✅ Check for warnings (red exclamation marks)
5. ✅ Compare Estimated vs Actual rows
6. ✅ Update statistics regularly
7. ✅ Use appropriate join types
8. ✅ Avoid implicit conversions
9. ✅ Monitor I/O statistics
10. ✅ Clear plan cache during testing

---

## Q209: What is the difference between table scan and index seek?

**Answer:**

The difference between **table scan** and **index seek** is critical for query performance.

### Table Scan

Reads **every row** in the table sequentially.

```sql
-- ============================================
-- TABLE SCAN EXAMPLE
-- ============================================

-- No indexes on OrderDate
SELECT * FROM Orders
WHERE OrderDate = '2025-01-15';

/*
Execution Plan:
├─ Table Scan (Clustered Index Scan)
   ├─ Cost: 85%
   ├─ Rows Read: 1,000,000 (entire table)
   ├─ Rows Returned: 100 (matching rows)
   └─ I/O: 50,000 logical reads
*/

-- Analysis:
-- Reads: 1,000,000 rows
-- Returns: 100 rows
-- Efficiency: 0.01% (99.99% waste!)
```

**When Table Scans Occur:**
1. No suitable index exists
2. Table is very small (faster than index overhead)
3. Query returns most rows (>20-25% of table)
4. Statistics are outdated
5. Function used on indexed column

**When Table Scans Are OK:**
- ✅ Very small tables (<100 rows)
- ✅ Returning most/all rows
- ✅ Read-once batch operations

---

### Index Seek

Navigates the B-tree structure to find specific rows.

```sql
-- ============================================
-- INDEX SEEK EXAMPLE
-- ============================================

-- Create index
CREATE INDEX IX_Orders_OrderDate
ON Orders(OrderDate);

-- Same query now
SELECT * FROM Orders
WHERE OrderDate = '2025-01-15';

/*
Execution Plan:
├─ Index Seek (NonClustered)
   ├─ Cost: 5%
   ├─ Rows Read: 100 (only matching rows)
   ├─ Rows Returned: 100
   └─ I/O: 25 logical reads

└─ OR Key Lookup (if index not covering)
   ├─ Cost: 10%
   └─ I/O: 100 logical reads
*/

-- Analysis:
-- Reads: 100 rows (0.01% of table)
-- Returns: 100 rows
-- Efficiency: 100%!
```

**How Index Seek Works:**
```
B-Tree Structure:
                [Root Node]
                /    |    \
         [Branch]  [Branch]  [Branch]
          /   \      /   \      /   \
      [Leaf] [Leaf][Leaf][Leaf][Leaf][Leaf]

Seek process:
1. Start at root
2. Navigate to correct branch (binary search)
3. Navigate to correct leaf
4. Read only matching rows
Total reads: ~3-4 levels (logarithmic)
```

---

### Index Scan vs Index Seek

```sql
-- ============================================
-- INDEX SCAN (Different from Index Seek!)
-- ============================================

CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);

-- Index Seek (Good)
SELECT * FROM Orders
WHERE OrderDate = '2025-01-15';
-- Navigates B-tree to specific location

-- Index Scan (Not as good)
SELECT * FROM Orders
WHERE YEAR(OrderDate) = 2025;
-- Scans entire index (can't use B-tree navigation)
-- Still better than table scan if index is smaller

/*
Index Scan vs Table Scan:
- Index Scan: Reads all rows in index (smaller than table)
- Table Scan: Reads all rows in table (larger)
- Both read all rows, but index scan is faster
*/
```

### Comparison Table

| Feature | Table Scan | Index Scan | Index Seek |
|---------|-----------|------------|------------|
| **Reads** | All rows in table | All rows in index | Only matching rows |
| **Structure** | Heap or clustered index | Non-clustered index | Non-clustered index |
| **Performance** | Slowest | Medium | Fastest |
| **I/O** | Highest | Medium | Lowest |
| **Cost** | 80-95% | 20-50% | 0.01-10% |
| **When Used** | No index / returns most rows | Covered query but no seek predicate | Equality/range predicate on index |

### Examples: Converting Scans to Seeks

#### Example 1: Function on Column
```sql
-- ❌ BAD: Index Scan (can't seek on function)
SELECT * FROM Orders
WHERE YEAR(OrderDate) = 2025;

-- ✅ GOOD: Index Seek
SELECT * FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2026-01-01';

-- OR: Computed column + index
ALTER TABLE Orders ADD OrderYear AS YEAR(OrderDate) PERSISTED;
CREATE INDEX IX_Orders_OrderYear ON Orders(OrderYear);

SELECT * FROM Orders WHERE OrderYear = 2025;
-- Now index seek!
```

#### Example 2: Wildcard Search
```sql
-- ❌ BAD: Index Scan
SELECT * FROM Customers
WHERE CustomerName LIKE '%Smith%';
-- Can't use index for leading wildcard

-- ✅ GOOD: Index Seek (if possible)
SELECT * FROM Customers
WHERE CustomerName LIKE 'Smith%';
-- Can use index for trailing wildcard

-- BEST: Full-text search for contains queries
CREATE FULLTEXT INDEX ON Customers(CustomerName);
SELECT * FROM Customers
WHERE CONTAINS(CustomerName, 'Smith');
```

#### Example 3: OR Conditions
```sql
-- ❌ BAD: May cause scan
SELECT * FROM Orders
WHERE CustomerID = 100 OR OrderDate = '2025-01-01';

-- ✅ GOOD: Index union
SELECT * FROM Orders WHERE CustomerID = 100
UNION ALL
SELECT * FROM Orders WHERE OrderDate = '2025-01-01' AND CustomerID <> 100;

-- OR: Multi-column index
CREATE INDEX IX_Orders_Combined
ON Orders(CustomerID, OrderDate);
```

---

## Q210: How do you optimize slow queries?

**Answer:**

Query optimization is a systematic process involving analysis, indexing, and query rewriting.

### Step-by-Step Optimization Process

#### 1. Identify Slow Queries

```sql
-- ============================================
-- FIND SLOW QUERIES IN PLAN CACHE
-- ============================================

SELECT TOP 20
    DB_NAME(qt.dbid) AS DatabaseName,
    qs.execution_count AS ExecutionCount,
    qs.total_elapsed_time / 1000 / 1000 AS TotalElapsedTimeSec,
    qs.total_elapsed_time / qs.execution_count / 1000 AS AvgElapsedTimeMs,
    qs.total_worker_time / qs.execution_count / 1000 AS AvgCPUTimeMs,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    qs.total_physical_reads / qs.execution_count AS AvgPhysicalReads,
    qs.creation_time AS PlanCreationTime,
    qs.last_execution_time AS LastExecutionTime,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText,
    qp.query_plan AS ExecutionPlan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.dbid = DB_ID()  -- Current database only
ORDER BY qs.total_elapsed_time DESC;  -- Slowest total time
```

#### 2. Analyze Execution Plan

```sql
-- ============================================
-- ORIGINAL SLOW QUERY
-- ============================================

-- Example: Slow order report
SELECT
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalRevenue,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City = 'New York'
  AND YEAR(o.OrderDate) = 2025
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalRevenue DESC;

/*
Execution Plan Analysis:
├─ Table Scan on Customers (Cost: 35%)  ❌ BAD
├─ Index Scan on Orders (Cost: 40%)     ❌ BAD (function on column)
├─ Hash Match (Aggregate) (Cost: 15%)
└─ Sort (Cost: 10%)
Total Cost: 100%
Execution Time: 5000ms
Logical Reads: 250,000
*/
```

#### 3. Optimize with Indexes

```sql
-- ============================================
-- ADD MISSING INDEXES
-- ============================================

-- Index for Customers.City
CREATE INDEX IX_Customers_City
ON Customers(City)
INCLUDE (CustomerID, CustomerName);

-- Index for Orders - avoid function on column
CREATE INDEX IX_Orders_CustomerID_OrderDate
ON Orders(CustomerID, OrderDate)
INCLUDE (OrderID, TotalAmount);

-- OR: Computed column for year
ALTER TABLE Orders
ADD OrderYear AS YEAR(OrderDate) PERSISTED;

CREATE INDEX IX_Orders_CustomerID_Year
ON Orders(CustomerID, OrderYear)
INCLUDE (OrderID, TotalAmount, OrderDate);
```

#### 4. Rewrite Query

```sql
-- ============================================
-- OPTIMIZED QUERY
-- ============================================

SELECT
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalRevenue,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2025-01-01'  -- No function!
    AND o.OrderDate < '2026-01-01'
WHERE c.City = 'New York'
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalRevenue DESC;

/*
Optimized Execution Plan:
├─ Index Seek on IX_Customers_City (Cost: 5%)     ✅ GOOD
├─ Index Seek on IX_Orders_CustomerID_OrderDate (Cost: 10%)  ✅ GOOD
├─ Hash Match (Aggregate) (Cost: 3%)
└─ Sort (Cost: 2%)
Total Cost: 20%
Execution Time: 150ms  (33x faster!)
Logical Reads: 1,500  (167x fewer!)
*/
```

### Common Optimization Techniques

#### 1. Eliminate Functions on Columns

```sql
-- ❌ BAD
SELECT * FROM Orders
WHERE YEAR(OrderDate) = 2025;
-- Can't use index on OrderDate

-- ✅ GOOD
SELECT * FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2026-01-01';
-- Can use index seek

-- ❌ BAD
SELECT * FROM Customers
WHERE UPPER(Email) = 'JOHN@EXAMPLE.COM';

-- ✅ GOOD
-- Create case-insensitive index
CREATE INDEX IX_Customers_Email
ON Customers(Email)
WHERE Email COLLATE Latin1_General_CI_AS;

SELECT * FROM Customers
WHERE Email = 'john@example.com' COLLATE Latin1_General_CI_AS;
```

#### 2. Use Covering Indexes

```sql
-- Query needs CustomerID, OrderDate, TotalAmount
SELECT CustomerID, OrderDate, TotalAmount
FROM Orders
WHERE CustomerID = 100;

-- ❌ BAD: Index + Key Lookup
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
-- Plan: Index Seek + Key Lookup (expensive!)

-- ✅ GOOD: Covering Index
CREATE INDEX IX_Orders_CustomerID_Covering
ON Orders(CustomerID)
INCLUDE (OrderDate, TotalAmount);
-- Plan: Single Index Seek (fast!)
```

#### 3. Avoid SELECT *

```sql
-- ❌ BAD
SELECT * FROM Orders WHERE OrderID = 1000;
-- Returns all columns (may force key lookup)

-- ✅ GOOD
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Orders WHERE OrderID = 1000;
-- Returns only needed columns (may use covering index)
```

#### 4. Use EXISTS Instead of IN for Subqueries

```sql
-- ❌ SLOW
SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID FROM Orders WHERE OrderDate > '2025-01-01'
);

-- ✅ FAST
SELECT CustomerID, CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o
    WHERE o.CustomerID = c.CustomerID
      AND o.OrderDate > '2025-01-01'
);
```

#### 5. Optimize JOIN Order

```sql
-- ❌ BAD: Large table first
SELECT *
FROM LargeTable lt  -- 10M rows
INNER JOIN SmallTable st ON lt.ID = st.ID  -- 100 rows
WHERE st.Category = 'A';

-- ✅ GOOD: Small table first
SELECT *
FROM SmallTable st  -- 100 rows
INNER JOIN LargeTable lt ON st.ID = lt.ID  -- 10M rows
WHERE st.Category = 'A';
-- Filters early, fewer joins
```

#### 6. Partition Large Queries

```sql
-- ❌ BAD: Process all at once
UPDATE Orders
SET Status = 'Archived'
WHERE OrderDate < '2020-01-01';  -- 5M rows, long transaction

-- ✅ GOOD: Batch processing
DECLARE @BatchSize INT = 10000;
DECLARE @RowsAffected INT = @BatchSize;

WHILE @RowsAffected = @BatchSize
BEGIN
    UPDATE TOP (@BatchSize) Orders
    SET Status = 'Archived'
    WHERE OrderDate < '2020-01-01'
      AND Status <> 'Archived';

    SET @RowsAffected = @@ROWCOUNT;

    -- Reduce log file pressure
    CHECKPOINT;

    -- Small delay
    WAITFOR DELAY '00:00:01';
END
```

#### 7. Update Statistics

```sql
-- Check statistics
DBCC SHOW_STATISTICS ('Orders', 'IX_Orders_CustomerID');

-- Update statistics
UPDATE STATISTICS Orders WITH FULLSCAN;

-- Enable auto-update
ALTER DATABASE YourDB SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE YourDB SET AUTO_UPDATE_STATISTICS_ASYNC ON;
```

#### 8. Rebuild Fragmented Indexes

```sql
-- Check fragmentation
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
  AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Rebuild index
ALTER INDEX IX_Orders_CustomerID ON Orders REBUILD;

-- Or reorganize (online operation)
ALTER INDEX IX_Orders_CustomerID ON Orders REORGANIZE;
```

### Advanced Techniques

#### 1. Use Query Hints (Carefully!)

```sql
-- Force index usage
SELECT *
FROM Orders WITH (INDEX(IX_Orders_OrderDate))
WHERE OrderDate > '2025-01-01';

-- Force join type
SELECT *
FROM Customers c
INNER HASH JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Parallelize query
SELECT * FROM Orders
WHERE OrderDate > '2025-01-01'
OPTION (MAXDOP 4);  -- Use 4 cores
```

#### 2. Materialized Views (Indexed Views)

```sql
-- Create indexed view for expensive aggregation
CREATE VIEW vw_CustomerOrderStats
WITH SCHEMABINDING
AS
SELECT
    c.CustomerID,
    COUNT_BIG(*) AS OrderCount,
    SUM(o.TotalAmount) AS TotalRevenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID;
GO

-- Create clustered index on view
CREATE UNIQUE CLUSTERED INDEX IX_CustomerOrderStats
ON vw_CustomerOrderStats(CustomerID);

-- Query uses pre-calculated view
SELECT * FROM vw_CustomerOrderStats WHERE CustomerID = 100;
-- Instant results!
```

#### 3. Table Partitioning

```sql
-- Partition large tables by date range
CREATE PARTITION FUNCTION pf_OrderDate (DATE)
AS RANGE RIGHT FOR VALUES
    ('2023-01-01', '2024-01-01', '2025-01-01');

CREATE PARTITION SCHEME ps_OrderDate
AS PARTITION pf_OrderDate
ALL TO ([PRIMARY]);

CREATE TABLE Orders (
    OrderID INT,
    OrderDate DATE,
    ...
) ON ps_OrderDate(OrderDate);

-- Queries on recent data are faster
SELECT * FROM Orders
WHERE OrderDate >= '2025-01-01';
-- Only scans 2025 partition!
```

---

## Q211: What are SQL Server Profiler and DMVs?

**Answer:**

**SQL Server Profiler** and **Dynamic Management Views (DMVs)** are tools for monitoring and troubleshooting SQL Server performance.

### SQL Server Profiler

A GUI tool for capturing SQL Server events in real-time.

#### Common Use Cases:

```sql
-- ============================================
-- EVENTS TO CAPTURE
-- ============================================

1. RPC:Completed - Stored procedure executions
2. SQL:BatchCompleted - Ad-hoc query executions
3. SQL:BatchStarting - Query starts
4. Deadlock graph - Deadlock visualization
5. Errors and Warnings - Exceptions
6. Showplan XML - Execution plans
```

#### Creating a Trace:

```sql
-- Server-side trace (better than Profiler GUI)
DECLARE @TraceID INT;
DECLARE @MaxFileSize BIGINT = 100;  -- 100 MB

EXEC sp_trace_create
    @TraceID OUTPUT,
    @options = 2,  -- TRACE_FILE_ROLLOVER
    @tracefile = N'C:\Temp\MyTrace',
    @maxfilesize = @MaxFileSize;

-- Add events: SQL:BatchCompleted
EXEC sp_trace_setevent @TraceID, 12, 1, 1;  -- TextData
EXEC sp_trace_setevent @TraceID, 12, 13, 1; -- Duration
EXEC sp_trace_setevent @TraceID, 12, 16, 1; -- Reads

-- Set filter: Duration > 1000ms
EXEC sp_trace_setfilter @TraceID, 13, 0, 4, 1000000;  -- microseconds

-- Start trace
EXEC sp_trace_setstatus @TraceID, 1;

-- Stop trace
EXEC sp_trace_setstatus @TraceID, 0;

-- Close trace
EXEC sp_trace_setstatus @TraceID, 2;
```

### Dynamic Management Views (DMVs)

System views providing real-time server state and performance data.

#### 1. Query Performance DMVs

```sql
-- ============================================
-- TOP CPU CONSUMING QUERIES
-- ============================================

SELECT TOP 20
    qs.execution_count,
    qs.total_worker_time / 1000 AS TotalCPUms,
    qs.total_worker_time / qs.execution_count / 1000 AS AvgCPUms,
    qs.total_elapsed_time / qs.execution_count / 1000 AS AvgElapsedms,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    qs.creation_time,
    qs.last_execution_time,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_worker_time DESC;
```

```sql
-- ============================================
-- TOP I/O CONSUMING QUERIES
-- ============================================

SELECT TOP 20
    qs.execution_count,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    qs.total_physical_reads,
    qs.total_logical_writes,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_logical_reads DESC;
```

#### 2. Index DMVs

```sql
-- ============================================
-- MISSING INDEXES
-- ============================================

SELECT
    CONVERT(DECIMAL(18,2), migs.avg_user_impact) AS AvgImprovementPercent,
    migs.user_seeks + migs.user_scans AS TotalSeeksAndScans,
    migs.last_user_seek,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    'CREATE INDEX IX_' + REPLACE(REPLACE(REPLACE(mid.statement, '[', ''), ']', ''), '.', '_') +
    ' ON ' + mid.statement +
    ' (' + ISNULL(mid.equality_columns, '') +
    CASE WHEN mid.inequality_columns IS NOT NULL
        THEN CASE WHEN mid.equality_columns IS NOT NULL THEN ',' ELSE '' END + mid.inequality_columns
        ELSE '' END + ')' +
    CASE WHEN mid.included_columns IS NOT NULL
        THEN ' INCLUDE (' + mid.included_columns + ')'
        ELSE '' END AS CreateIndexStatement
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
WHERE migs.avg_user_impact > 20
  AND (migs.user_seeks + migs.user_scans) > 100
ORDER BY migs.avg_user_impact DESC;
```

```sql
-- ============================================
-- UNUSED INDEXES
-- ============================================

SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    'DROP INDEX ' + i.name + ' ON ' + OBJECT_NAME(i.object_id) AS DropStatement
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
   AND i.index_id = ius.index_id
   AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND i.index_id > 0  -- Not heap
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0
  AND (ius.user_seeks + ius.user_scans + ius.user_lookups = 0
       OR ius.user_seeks + ius.user_scans + ius.user_lookups IS NULL)
  AND ius.user_updates > 0  -- Costing updates but not used
ORDER BY ius.user_updates DESC;
```

#### 3. Blocking and Wait Statistics

```sql
-- ============================================
-- CURRENT BLOCKING
-- ============================================

SELECT
    blocking.session_id AS BlockingSessionID,
    blocked.session_id AS BlockedSessionID,
    blocking_user.login_name AS BlockingUser,
    blocked_user.login_name AS BlockedUser,
    blocked.wait_time / 1000 AS WaitTimeSeconds,
    blocked.wait_type,
    blocked.wait_resource,
    blocking_sql.text AS BlockingQuery,
    blocked_sql.text AS BlockedQuery,
    blocking.status AS BlockingStatus,
    blocked.status AS BlockedStatus
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_sessions blocked_user
    ON blocked.session_id = blocked_user.session_id
LEFT JOIN sys.dm_exec_requests blocking
    ON blocked.blocking_session_id = blocking.session_id
LEFT JOIN sys.dm_exec_sessions blocking_user
    ON blocking.session_id = blocking_user.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) AS blocked_sql
OUTER APPLY sys.dm_exec_sql_text(blocking.sql_handle) AS blocking_sql
WHERE blocked.blocking_session_id <> 0;
```

```sql
-- ============================================
-- WAIT STATISTICS
-- ============================================

SELECT TOP 20
    wait_type,
    wait_time_ms / 1000.0 AS WaitTimeSec,
    waiting_tasks_count AS WaitCount,
    wait_time_ms / waiting_tasks_count AS AvgWaitMs,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5,2)) AS PercentOfTotal
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
    'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
    'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
ORDER BY wait_time_ms DESC;

/*
Common Wait Types:
- PAGEIOLATCH_*: Disk I/O waits (add memory or faster disks)
- LCK_M_*: Lock waits (blocking)
- CXPACKET: Parallelism waits
- ASYNC_NETWORK_IO: Client not consuming results fast enough
- WRITELOG: Transaction log writes (faster log disk)
*/
```

#### 4. Database and Table Information

```sql
-- ============================================
-- DATABASE SIZE AND SPACE USAGE
-- ============================================

SELECT
    DB_NAME(database_id) AS DatabaseName,
    SUM(size * 8 / 1024) AS SizeMB,
    SUM(CASE WHEN type = 0 THEN size * 8 / 1024 ELSE 0 END) AS DataSizeMB,
    SUM(CASE WHEN type = 1 THEN size * 8 / 1024 ELSE 0 END) AS LogSizeMB
FROM sys.master_files
GROUP BY database_id
ORDER BY SizeMB DESC;
```

```sql
-- ============================================
-- TABLE SIZES
-- ============================================

SELECT
    t.name AS TableName,
    p.rows AS RowCount,
    SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB,
    SUM(a.used_pages) * 8 / 1024 AS UsedSpaceMB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
  AND i.index_id <= 1  -- Heap or clustered index only
GROUP BY t.name, p.rows
ORDER BY TotalSpaceMB DESC;
```

### Extended Events (Modern Alternative to Profiler)

```sql
-- ============================================
-- CREATE EXTENDED EVENT SESSION
-- ============================================

CREATE EVENT SESSION SlowQueries ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.username)
    WHERE duration >= 1000000  -- 1 second in microseconds
),
ADD EVENT sqlserver.rpc_completed (
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.username)
    WHERE duration >= 1000000
)
ADD TARGET package0.event_file (
    SET filename = N'C:\Temp\SlowQueries.xel',
    max_file_size = 100,  -- MB
    max_rollover_files = 5
);

-- Start session
ALTER EVENT SESSION SlowQueries ON SERVER STATE = START;

-- Query results
SELECT
    event_data.value('(event/@name)[1]', 'varchar(50)') AS EventName,
    event_data.value('(event/@timestamp)[1]', 'datetime2') AS EventTime,
    event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') / 1000 AS DurationMs,
    event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS QueryText,
    event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(128)') AS DatabaseName
FROM (
    SELECT CAST(event_data AS XML) AS event_data
    FROM sys.fn_xe_file_target_read_file('C:\Temp\SlowQueries*.xel', NULL, NULL, NULL)
) AS xedata
ORDER BY EventTime DESC;

-- Stop session
ALTER EVENT SESSION SlowQueries ON SERVER STATE = STOP;
```

### Comparison: Profiler vs Extended Events vs DMVs

| Feature | SQL Profiler | Extended Events | DMVs |
|---------|-------------|-----------------|------|
| **Performance Impact** | High | Low | Very Low |
| **Real-time Monitoring** | Yes | Yes | Yes (snapshot) |
| **Historical Data** | File trace | File/ring buffer | Limited |
| **Filtering** | Limited | Excellent | Query-based |
| **Modern Recommended** | ❌ Deprecated | ✅ Yes | ✅ Yes |
| **GUI** | Yes | SSMS | Query-based |

---

## SECTION 6: ENTITY FRAMEWORK & LINQ

---

## Q212: What is Entity Framework? What are its advantages?

**Answer:**

**Entity Framework (EF)** is an Object-Relational Mapper (ORM) that enables .NET developers to work with databases using .NET objects, eliminating most data-access code.

### Key Concepts

```csharp
// ============================================
// TRADITIONAL ADO.NET (Without EF)
// ============================================

public List<Customer> GetCustomers()
{
    var customers = new List<Customer>();

    using (var connection = new SqlConnection(connectionString))
    {
        connection.Open();
        var command = new SqlCommand("SELECT * FROM Customers", connection);

        using (var reader = command.ExecuteReader())
        {
            while (reader.Read())
            {
                var customer = new Customer
                {
                    CustomerID = reader.GetInt32(0),
                    CustomerName = reader.GetString(1),
                    Email = reader.GetString(2),
                    // ... map all columns manually
                };
                customers.Add(customer);
            }
        }
    }

    return customers;
}

// ============================================
// WITH ENTITY FRAMEWORK
// ============================================

public List<Customer> GetCustomers()
{
    using (var context = new AppDbContext())
    {
        return context.Customers.ToList();
    }
    // That's it! EF handles everything
}
```

### Core Components

```csharp
// ============================================
// 1. ENTITY CLASSES (POCOs)
// ============================================

public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public DateTime CreatedDate { get; set; }

    // Navigation property
    public ICollection<Order> Orders { get; set; }
}

public class Order
{
    public int OrderID { get; set; }
    public int CustomerID { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }

    // Navigation property
    public Customer Customer { get; set; }
    public ICollection<OrderDetail> OrderDetails { get; set; }
}

// ============================================
// 2. DbCONTEXT
// ============================================

public class AppDbContext : DbContext
{
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderDetail> OrderDetails { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlServer(
            "Server=.;Database=MyApp;Trusted_Connection=True;");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Fluent API configuration
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerID);
    }
}
```

### Advantages of Entity Framework

#### 1. Productivity

```csharp
// CRUD operations are simple
using (var context = new AppDbContext())
{
    // CREATE
    var customer = new Customer
    {
        CustomerName = "John Doe",
        Email = "john@example.com",
        CreatedDate = DateTime.Now
    };
    context.Customers.Add(customer);
    context.SaveChanges();

    // READ
    var customers = context.Customers
        .Where(c => c.Email.Contains("@example.com"))
        .ToList();

    // UPDATE
    var existingCustomer = context.Customers.Find(1);
    existingCustomer.Email = "newemail@example.com";
    context.SaveChanges();

    // DELETE
    context.Customers.Remove(existingCustomer);
    context.SaveChanges();
}
```

#### 2. LINQ Support

```csharp
// ============================================
// COMPLEX QUERIES WITH LINQ
// ============================================

using (var context = new AppDbContext())
{
    // Strongly-typed, IntelliSense, compile-time checking
    var highValueCustomers = context.Customers
        .Where(c => c.Orders.Any(o => o.TotalAmount > 1000))
        .Select(c => new
        {
            c.CustomerName,
            c.Email,
            TotalOrders = c.Orders.Count(),
            TotalSpent = c.Orders.Sum(o => o.TotalAmount),
            LastOrderDate = c.Orders.Max(o => o.OrderDate)
        })
        .OrderByDescending(c => c.TotalSpent)
        .Take(10)
        .ToList();

    // EF translates to efficient SQL!
}

/*
Generated SQL:
SELECT TOP 10
    c.CustomerName,
    c.Email,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 1000
GROUP BY c.CustomerID, c.CustomerName, c.Email
ORDER BY SUM(o.TotalAmount) DESC
*/
```

#### 3. Change Tracking

```csharp
using (var context = new AppDbContext())
{
    var customer = context.Customers.Find(1);

    // Modify entity
    customer.Email = "updated@example.com";
    customer.CustomerName = "Updated Name";

    // EF tracks changes automatically
    context.SaveChanges();

    // Generates optimized UPDATE:
    // UPDATE Customers
    // SET Email = 'updated@example.com',
    //     CustomerName = 'Updated Name'
    // WHERE CustomerID = 1
    // Only modified columns updated!
}
```

#### 4. Database Migrations

```csharp
// ============================================
// CODE-FIRST MIGRATIONS
// ============================================

// 1. Make model changes
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public string PhoneNumber { get; set; }  // NEW COLUMN
}

// 2. Create migration
// PM> Add-Migration AddPhoneNumber

// 3. Migration code auto-generated
public partial class AddPhoneNumber : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "PhoneNumber",
            table: "Customers",
            nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "PhoneNumber",
            table: "Customers");
    }
}

// 4. Apply to database
// PM> Update-Database
```

#### 5. Lazy Loading, Eager Loading, Explicit Loading

```csharp
// Lazy Loading (loads related data on-demand)
var customer = context.Customers.Find(1);
var orders = customer.Orders;  // Loads orders now (separate query)

// Eager Loading (loads related data immediately)
var customers = context.Customers
    .Include(c => c.Orders)
        .ThenInclude(o => o.OrderDetails)
    .ToList();  // Single query with JOINs

// Explicit Loading
var customer = context.Customers.Find(1);
context.Entry(customer)
    .Collection(c => c.Orders)
    .Load();  // Explicitly load orders
```

### Advantages Summary

| Advantage | Description | Example |
|-----------|-------------|---------|
| **Productivity** | Less code, faster development | CRUD in few lines |
| **LINQ Support** | Strongly-typed queries | Compile-time checking |
| **Change Tracking** | Automatic change detection | SaveChanges() |
| **Migrations** | Version control for database | Add-Migration |
| **Database Independent** | Switch providers easily | SQL Server ↔ PostgreSQL |
| **Lazy/Eager Loading** | Control data loading | Performance optimization |
| **Transaction Support** | Built-in transaction management | context.Database.BeginTransaction() |
| **Caching** | First-level cache (context) | Better performance |

---

---

## Q213: Explain Code-First vs Database-First approaches in Entity Framework.

**Answer:**

Entity Framework supports three development approaches for working with databases.

### 1. Code-First Approach

Define C# classes first, then generate database from code.

```csharp
// ============================================
// CODE-FIRST EXAMPLE
// ============================================

// 1. Define entity classes
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public DateTime CreatedDate { get; set; }

    // Navigation property
    public ICollection<Order> Orders { get; set; }
}

public class Order
{
    public int OrderID { get; set; }
    public int CustomerID { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }

    // Navigation properties
    public Customer Customer { get; set; }
    public ICollection<OrderDetail> OrderDetails { get; set; }
}

public class OrderDetail
{
    public int OrderDetailID { get; set; }
    public int OrderID { get; set; }
    public int ProductID { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    public Order Order { get; set; }
    public Product Product { get; set; }
}

// 2. Define DbContext
public class AppDbContext : DbContext
{
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderDetail> OrderDetails { get; set; }
    public DbSet<Product> Products { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlServer(
            @"Server=.;Database=ECommerceDB;Trusted_Connection=True;");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure relationships using Fluent API
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerID)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<OrderDetail>()
            .HasOne(od => od.Order)
            .WithMany(o => o.OrderDetails)
            .HasForeignKey(od => od.OrderID);

        // Configure table names
        modelBuilder.Entity<Customer>().ToTable("Customers");
        modelBuilder.Entity<Order>().ToTable("Orders");

        // Configure column properties
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.Property(e => e.CustomerName)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Email)
                .HasMaxLength(255);

            entity.HasIndex(e => e.Email)
                .IsUnique();
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.Property(e => e.TotalAmount)
                .HasColumnType("decimal(18,2)");

            entity.Property(e => e.OrderDate)
                .HasDefaultValueSql("GETDATE()");
        });
    }
}

// 3. Create migration
// PM> Add-Migration InitialCreate

// 4. Apply to database
// PM> Update-Database
```

**Generated Migration:**
```csharp
public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Customers",
            columns: table => new
            {
                CustomerID = table.Column<int>(nullable: false)
                    .Annotation("SqlServer:Identity", "1, 1"),
                CustomerName = table.Column<string>(maxLength: 100, nullable: false),
                Email = table.Column<string>(maxLength: 255, nullable: true),
                CreatedDate = table.Column<DateTime>(nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Customers", x => x.CustomerID);
            });

        migrationBuilder.CreateIndex(
            name: "IX_Customers_Email",
            table: "Customers",
            column: "Email",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Customers");
    }
}
```

**Advantages of Code-First:**
- ✅ Full control over domain model
- ✅ Version control friendly (code, not database)
- ✅ Great for new projects
- ✅ Database can be recreated from code
- ✅ Works well with DDD (Domain-Driven Design)
- ✅ Easy to unit test (in-memory database)

**Disadvantages:**
- ❌ Not ideal for existing databases
- ❌ Complex database features harder to implement
- ❌ Learning curve for Fluent API

---

### 2. Database-First Approach

Start with existing database, generate C# classes from database schema.

```bash
# Scaffold database to code
# Package Manager Console:
PM> Scaffold-DbContext "Server=.;Database=AdventureWorks;Trusted_Connection=True;" Microsoft.EntityFrameworkCore.SqlServer -OutputDir Models

# CLI:
dotnet ef dbcontext scaffold "Server=.;Database=AdventureWorks;Trusted_Connection=True;" Microsoft.EntityFrameworkCore.SqlServer -o Models
```

**Generated Code:**
```csharp
// ============================================
// AUTO-GENERATED FROM DATABASE
// ============================================

public partial class AdventureWorksContext : DbContext
{
    public AdventureWorksContext()
    {
    }

    public AdventureWorksContext(DbContextOptions<AdventureWorksContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Customer> Customers { get; set; }
    public virtual DbSet<Order> Orders { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer("Server=.;Database=AdventureWorks;Trusted_Connection=True;");
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.ToTable("Customers");

            entity.Property(e => e.CustomerId).HasColumnName("CustomerID");

            entity.Property(e => e.CustomerName)
                .IsRequired()
                .HasMaxLength(100)
                .IsUnicode(false);

            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .IsUnicode(false);
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.ToTable("Orders");

            entity.Property(e => e.OrderId).HasColumnName("OrderID");
            entity.Property(e => e.CustomerId).HasColumnName("CustomerID");

            entity.Property(e => e.OrderDate)
                .HasColumnType("datetime")
                .HasDefaultValueSql("(getdate())");

            entity.Property(e => e.TotalAmount)
                .HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Customer)
                .WithMany(p => p.Orders)
                .HasForeignKey(d => d.CustomerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Orders_Customers");
        });
    }
}

// Auto-generated entity classes
public partial class Customer
{
    public Customer()
    {
        Orders = new HashSet<Order>();
    }

    public int CustomerId { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public DateTime CreatedDate { get; set; }

    public virtual ICollection<Order> Orders { get; set; }
}
```

**Advantages of Database-First:**
- ✅ Perfect for existing databases
- ✅ DBA controls database design
- ✅ Complex database features preserved
- ✅ Quick to get started
- ✅ Works with legacy databases

**Disadvantages:**
- ❌ Generated code can be overwritten
- ❌ Database changes require regeneration
- ❌ Less control over class design
- ❌ Harder to version control database changes

---

### 3. Model-First Approach (Legacy - Not Recommended)

Visual designer to create entity models, then generate database and classes.

**Note:** Model-First is deprecated in EF Core. Use Code-First instead.

---

### Comparison Table

| Feature | Code-First | Database-First |
|---------|-----------|----------------|
| **Starting Point** | C# classes | Database tables |
| **Database Creation** | Migrations generate DB | DB already exists |
| **Version Control** | Easy (code) | Difficult (database) |
| **Team Workflow** | Developer-centric | DBA-centric |
| **Database Changes** | Migrations | Manual SQL or regenerate |
| **Learning Curve** | Steeper (Fluent API) | Easier to start |
| **Best For** | New projects, Greenfield | Existing databases, Legacy systems |
| **Domain Model Control** | Full control | Limited by database |
| **Database Features** | Limited to EF support | All database features |

---

### Hybrid Approach (Recommended for Many Scenarios)

```csharp
// ============================================
// SCAFFOLD ONCE, THEN USE CODE-FIRST
// ============================================

// 1. Scaffold existing database once
// PM> Scaffold-DbContext "..." -OutputDir Models -Force

// 2. Move context to separate file (won't be overwritten)
public class AppDbContext : AdventureWorksContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    // Add custom configurations
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Add your customizations here
        modelBuilder.Entity<Customer>()
            .HasQueryFilter(c => c.IsActive);  // Global filter
    }
}

// 3. From now on, use Code-First migrations
// PM> Add-Migration AddIsActiveColumn
// PM> Update-Database
```

---

### Real-World Example: Choosing the Right Approach

```csharp
// ============================================
// SCENARIO 1: NEW STARTUP PROJECT
// ============================================
// Choice: CODE-FIRST
// Reason: Clean domain model, no legacy constraints

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));
    }
}

// ============================================
// SCENARIO 2: LEGACY ENTERPRISE SYSTEM
// ============================================
// Choice: DATABASE-FIRST
// Reason: Existing database with stored procs, complex schema

// Scaffold with specific tables only
// PM> Scaffold-DbContext "..." -Tables Customers,Orders,Products

// ============================================
// SCENARIO 3: MICROSERVICES MIGRATION
// ============================================
// Choice: HYBRID
// Reason: Start with database-first, migrate to code-first gradually

// 1. Scaffold monolith database
// PM> Scaffold-DbContext "..." -OutputDir ModelsLegacy

// 2. Create new code-first context for new features
public class ModernDbContext : DbContext
{
    public DbSet<NewFeature> NewFeatures { get; set; }
}

// 3. Use both contexts in application
public class CustomerService
{
    private readonly LegacyDbContext _legacyDb;
    private readonly ModernDbContext _modernDb;

    public CustomerService(LegacyDbContext legacyDb, ModernDbContext modernDb)
    {
        _legacyDb = legacyDb;
        _modernDb = modernDb;
    }
}
```

---

## Q214: What is DbContext and DbSet in Entity Framework?

**Answer:**

**DbContext** is the primary class for interacting with the database. **DbSet** represents a collection of entities that can be queried and saved.

### DbContext

The gateway to the database - manages entity objects, change tracking, and database operations.

```csharp
// ============================================
// DbCONTEXT BASICS
// ============================================

public class AppDbContext : DbContext
{
    // DbSets - collections of entities
    public DbSet<Customer> Customers { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<Product> Products { get; set; }

    // Constructor for dependency injection
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    // Configure connection string
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer(
                @"Server=.;Database=MyApp;Trusted_Connection=True;");
        }
    }

    // Configure model (relationships, constraints, etc.)
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Fluent API configuration
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerID);

        // Seed data
        modelBuilder.Entity<Product>().HasData(
            new Product { ProductID = 1, ProductName = "Laptop", Price = 999.99m },
            new Product { ProductID = 2, ProductName = "Mouse", Price = 29.99m }
        );
    }
}
```

### DbContext Responsibilities

#### 1. Querying

```csharp
using (var context = new AppDbContext())
{
    // Query customers
    var customers = context.Customers
        .Where(c => c.City == "New York")
        .ToList();

    // Query with navigation properties
    var ordersWithCustomers = context.Orders
        .Include(o => o.Customer)
        .Where(o => o.OrderDate > DateTime.Now.AddDays(-30))
        .ToList();

    // Complex query
    var result = context.Orders
        .Where(o => o.TotalAmount > 1000)
        .GroupBy(o => o.CustomerID)
        .Select(g => new
        {
            CustomerID = g.Key,
            OrderCount = g.Count(),
            TotalSpent = g.Sum(o => o.TotalAmount)
        })
        .ToList();
}
```

#### 2. Change Tracking

```csharp
using (var context = new AppDbContext())
{
    // Load entity
    var customer = context.Customers.Find(1);

    // Change tracking automatically detects changes
    customer.Email = "newemail@example.com";
    customer.PhoneNumber = "555-1234";

    // Check tracked changes
    var entries = context.ChangeTracker.Entries()
        .Where(e => e.State == EntityState.Modified);

    foreach (var entry in entries)
    {
        Console.WriteLine($"Entity: {entry.Entity.GetType().Name}");

        foreach (var prop in entry.Properties)
        {
            if (prop.IsModified)
            {
                Console.WriteLine($"  {prop.Metadata.Name}: {prop.OriginalValue} → {prop.CurrentValue}");
            }
        }
    }

    // Save changes
    context.SaveChanges();  // Only modified columns updated!
}
```

#### 3. Saving Data

```csharp
using (var context = new AppDbContext())
{
    // INSERT
    var newCustomer = new Customer
    {
        CustomerName = "John Doe",
        Email = "john@example.com",
        CreatedDate = DateTime.Now
    };
    context.Customers.Add(newCustomer);

    // UPDATE
    var existingCustomer = context.Customers.Find(1);
    existingCustomer.Email = "updated@example.com";

    // DELETE
    var customerToDelete = context.Customers.Find(999);
    context.Customers.Remove(customerToDelete);

    // Execute all operations
    int affected = context.SaveChanges();
    Console.WriteLine($"{affected} rows affected");
}
```

#### 4. Transaction Management

```csharp
using (var context = new AppDbContext())
{
    // Implicit transaction (default behavior of SaveChanges)
    var customer = new Customer { CustomerName = "Jane" };
    var order = new Order { CustomerID = customer.CustomerID, TotalAmount = 500 };

    context.Customers.Add(customer);
    context.Orders.Add(order);

    context.SaveChanges();  // Both succeed or both fail

    // Explicit transaction
    using (var transaction = context.Database.BeginTransaction())
    {
        try
        {
            // Operation 1
            context.Customers.Add(new Customer { CustomerName = "Alice" });
            context.SaveChanges();

            // Operation 2
            context.Orders.Add(new Order { CustomerID = 1, TotalAmount = 1000 });
            context.SaveChanges();

            // Commit if all succeeded
            transaction.Commit();
        }
        catch (Exception ex)
        {
            // Rollback on error
            transaction.Rollback();
            Console.WriteLine($"Transaction failed: {ex.Message}");
        }
    }
}
```

---

### DbSet<TEntity>

Represents a table in the database.

```csharp
// ============================================
// DbSET OPERATIONS
// ============================================

using (var context = new AppDbContext())
{
    // DbSet reference
    DbSet<Customer> customers = context.Customers;

    // QUERY (LINQ)
    var activeCustomers = customers
        .Where(c => c.IsActive)
        .OrderBy(c => c.CustomerName)
        .ToList();

    // FIND by primary key (uses cache if available)
    var customer = customers.Find(1);  // Fast!

    // SINGLE (throws if not exactly one)
    var singleCustomer = customers.Single(c => c.Email == "unique@example.com");

    // FIRST (throws if none)
    var firstCustomer = customers.First(c => c.City == "New York");

    // FIRST OR DEFAULT (returns null if none)
    var maybeCustomer = customers.FirstOrDefault(c => c.CustomerID == 999);

    // ANY (exists check)
    bool hasOrders = context.Orders.Any(o => o.CustomerID == 1);

    // COUNT
    int totalCustomers = customers.Count();
    int nyCustomers = customers.Count(c => c.City == "New York");

    // ADD (insert)
    customers.Add(new Customer { CustomerName = "New Customer" });

    // ADD RANGE (bulk insert)
    customers.AddRange(new[]
    {
        new Customer { CustomerName = "Customer 1" },
        new Customer { CustomerName = "Customer 2" },
        new Customer { CustomerName = "Customer 3" }
    });

    // UPDATE (via change tracking)
    var customerToUpdate = customers.Find(1);
    customerToUpdate.Email = "newemail@example.com";

    // REMOVE (delete)
    var customerToDelete = customers.Find(999);
    customers.Remove(customerToDelete);

    // REMOVE RANGE (bulk delete)
    var inactiveCustomers = customers.Where(c => !c.IsActive).ToList();
    customers.RemoveRange(inactiveCustomers);

    // ATTACH (attach disconnected entity)
    var disconnectedCustomer = new Customer { CustomerID = 1, Email = "new@example.com" };
    customers.Attach(disconnectedCustomer);
    context.Entry(disconnectedCustomer).State = EntityState.Modified;

    // Save all changes
    context.SaveChanges();
}
```

### DbContext Lifetime and Patterns

#### 1. Unit of Work Pattern (Recommended)

```csharp
// ============================================
// UNIT OF WORK WITH DEPENDENCY INJECTION
// ============================================

// Startup.cs
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Register DbContext with scoped lifetime
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<ICustomerRepository, CustomerRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
    }
}

// Repository pattern
public interface ICustomerRepository
{
    Customer GetById(int id);
    IEnumerable<Customer> GetAll();
    void Add(Customer customer);
    void Update(Customer customer);
    void Delete(int id);
}

public class CustomerRepository : ICustomerRepository
{
    private readonly AppDbContext _context;

    public CustomerRepository(AppDbContext context)
    {
        _context = context;  // Injected, managed by DI container
    }

    public Customer GetById(int id)
    {
        return _context.Customers.Find(id);
    }

    public IEnumerable<Customer> GetAll()
    {
        return _context.Customers.ToList();
    }

    public void Add(Customer customer)
    {
        _context.Customers.Add(customer);
    }

    public void Update(Customer customer)
    {
        _context.Entry(customer).State = EntityState.Modified;
    }

    public void Delete(int id)
    {
        var customer = _context.Customers.Find(id);
        if (customer != null)
        {
            _context.Customers.Remove(customer);
        }
    }
}

// Service layer
public class OrderService
{
    private readonly AppDbContext _context;
    private readonly ICustomerRepository _customerRepo;
    private readonly IOrderRepository _orderRepo;

    public OrderService(
        AppDbContext context,
        ICustomerRepository customerRepo,
        IOrderRepository orderRepo)
    {
        _context = context;
        _customerRepo = customerRepo;
        _orderRepo = orderRepo;
    }

    public void ProcessOrder(int customerId, List<OrderItem> items)
    {
        // All operations use same DbContext instance (Unit of Work)
        var customer = _customerRepo.GetById(customerId);

        var order = new Order
        {
            CustomerID = customerId,
            OrderDate = DateTime.Now,
            TotalAmount = items.Sum(i => i.Price * i.Quantity)
        };

        _orderRepo.Add(order);

        // Single SaveChanges for all operations (transaction)
        _context.SaveChanges();
    }
}
```

#### 2. Per-Request Lifetime (Web Applications)

```csharp
// ASP.NET Core automatically creates one DbContext per HTTP request
public class CustomersController : ControllerBase
{
    private readonly AppDbContext _context;

    public CustomersController(AppDbContext context)
    {
        _context = context;  // One instance for this request
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCustomer(int id)
    {
        var customer = await _context.Customers
            .Include(c => c.Orders)
            .FirstOrDefaultAsync(c => c.CustomerID == id);

        return customer == null ? NotFound() : Ok(customer);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCustomer([FromBody] Customer customer)
    {
        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCustomer),
            new { id = customer.CustomerID }, customer);
    }
}  // DbContext automatically disposed here
```

### DbContext Configuration Options

```csharp
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        // Logging
        optionsBuilder.LogTo(Console.WriteLine, LogLevel.Information);

        // Enable sensitive data logging (dev only!)
        optionsBuilder.EnableSensitiveDataLogging();

        // Detailed errors
        optionsBuilder.EnableDetailedErrors();

        // Lazy loading
        optionsBuilder.UseLazyLoadingProxies();

        // Query splitting
        optionsBuilder.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);

        // Command timeout
        optionsBuilder.CommandTimeout(30);  // 30 seconds

        // Connection pooling
        optionsBuilder.UseSqlServer(connectionString, sqlOptions =>
        {
            sqlOptions.MaxBatchSize(100);
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        });
    }
}
```

### Key DbContext Methods

```csharp
using (var context = new AppDbContext())
{
    // SaveChanges - persist all changes
    int rowsAffected = context.SaveChanges();

    // SaveChangesAsync - async version
    await context.SaveChangesAsync();

    // Entry - get entity state and metadata
    var entry = context.Entry(customer);
    Console.WriteLine($"State: {entry.State}");  // Added, Modified, Deleted, Unchanged

    // ChangeTracker - access change tracking
    context.ChangeTracker.DetectChanges();  // Manual detection
    context.ChangeTracker.Clear();  // Clear tracked entities

    // Database - database operations
    context.Database.EnsureCreated();  // Create database if not exists
    context.Database.Migrate();  // Apply pending migrations
    context.Database.ExecuteSqlRaw("DELETE FROM Orders WHERE OrderDate < '2020-01-01'");

    // Set - get DbSet dynamically
    var set = context.Set<Customer>();
}
```

---

## Q215: Explain Lazy Loading vs Eager Loading vs Explicit Loading in EF.

**Answer:**

These are three strategies for loading related data in Entity Framework.

### 1. Lazy Loading

Related data is **automatically loaded** when navigation property is accessed.

```csharp
// ============================================
// LAZY LOADING
// ============================================

// 1. Enable lazy loading
// Install: Microsoft.EntityFrameworkCore.Proxies
services.AddDbContext<AppDbContext>(options =>
    options.UseLazyLoadingProxies()
           .UseSqlServer(connectionString));

// 2. Make navigation properties virtual
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }

    // MUST be virtual for lazy loading
    public virtual ICollection<Order> Orders { get; set; }
}

public class Order
{
    public int OrderID { get; set; }
    public int CustomerID { get; set; }
    public decimal TotalAmount { get; set; }

    // MUST be virtual for lazy loading
    public virtual Customer Customer { get; set; }
    public virtual ICollection<OrderDetail> OrderDetails { get; set; }
}

// 3. Use lazy loading
using (var context = new AppDbContext())
{
    // First query - loads only Customer
    var customer = context.Customers.First();
    // SQL: SELECT * FROM Customers

    // Accessing Orders triggers lazy loading
    var orderCount = customer.Orders.Count;  // Separate query fired here!
    // SQL: SELECT * FROM Orders WHERE CustomerID = @p0

    // Each order's details loaded on access
    foreach (var order in customer.Orders)
    {
        Console.WriteLine($"Order has {order.OrderDetails.Count} items");
        // SQL: SELECT * FROM OrderDetails WHERE OrderID = @p0
        // This query fires for EACH order! (N+1 problem)
    }
}

/*
Queries Generated:
1. SELECT * FROM Customers (1 query)
2. SELECT * FROM Orders WHERE CustomerID = 1 (1 query)
3. SELECT * FROM OrderDetails WHERE OrderID = 1 (N queries, one per order)

Total: 1 + 1 + N queries
*/
```

**Advantages:**
- ✅ Simple to use - no explicit loading code
- ✅ Only loads data when needed
- ✅ Good for small object graphs

**Disadvantages:**
- ❌ N+1 query problem
- ❌ Can cause performance issues
- ❌ Doesn't work with disconnected scenarios
- ❌ Requires virtual navigation properties

**The N+1 Problem:**
```csharp
// ============================================
// N+1 PROBLEM EXAMPLE
// ============================================

using (var context = new AppDbContext())
{
    // 1 query to get customers
    var customers = context.Customers.ToList();
    // SQL: SELECT * FROM Customers

    // Loop through customers
    foreach (var customer in customers)  // Assume 100 customers
    {
        // Each customer access triggers a query (100 queries!)
        Console.WriteLine($"{customer.CustomerName}: {customer.Orders.Count} orders");
        // SQL: SELECT * FROM Orders WHERE CustomerID = @p0
    }
}

// Result: 1 + 100 = 101 queries! (VERY SLOW!)
```

---

### 2. Eager Loading

Related data is **loaded immediately** with the main query using `Include()`.

```csharp
// ============================================
// EAGER LOADING
// ============================================

using (var context = new AppDbContext())
{
    // Load customer with orders in single query
    var customers = context.Customers
        .Include(c => c.Orders)  // Eager load orders
        .ToList();

    /*
    Generated SQL (single query with JOIN):
    SELECT c.*, o.*
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    */

    // No additional queries when accessing Orders
    foreach (var customer in customers)
    {
        Console.WriteLine($"{customer.CustomerName}: {customer.Orders.Count} orders");
        // No additional database query!
    }
}

// Multiple levels of eager loading
using (var context = new AppDbContext())
{
    var customers = context.Customers
        .Include(c => c.Orders)           // Load orders
            .ThenInclude(o => o.OrderDetails)  // Load order details
                .ThenInclude(od => od.Product)  // Load products
        .Include(c => c.Address)          // Load customer address
        .ToList();

    /*
    Single query with multiple JOINs:
    SELECT c.*, o.*, od.*, p.*, a.*
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    LEFT JOIN Addresses a ON c.CustomerID = a.CustomerID
    */
}

// Filtered includes (EF Core 5+)
using (var context = new AppDbContext())
{
    var customers = context.Customers
        .Include(c => c.Orders.Where(o => o.OrderDate > DateTime.Now.AddMonths(-1)))
        .ToList();

    // Only includes orders from last month
}

// Split queries (EF Core 5+)
using (var context = new AppDbContext())
{
    var customers = context.Customers
        .Include(c => c.Orders)
        .ThenInclude(o => o.OrderDetails)
        .AsSplitQuery()  // Use separate queries instead of single JOIN
        .ToList();

    /*
    Three separate queries:
    1. SELECT * FROM Customers
    2. SELECT * FROM Orders WHERE CustomerID IN (...)
    3. SELECT * FROM OrderDetails WHERE OrderID IN (...)

    Better performance for large datasets with cartesian explosion
    */
}
```

**Advantages:**
- ✅ Best performance (fewer queries)
- ✅ No N+1 problem
- ✅ Works with disconnected scenarios
- ✅ No virtual properties needed
- ✅ Explicit and clear

**Disadvantages:**
- ❌ May load more data than needed
- ❌ Large JOINs can be slower than split queries
- ❌ Cartesian explosion with multiple collections

**Cartesian Explosion Example:**
```csharp
// ============================================
// CARTESIAN EXPLOSION PROBLEM
// ============================================

// Customer has 10 orders, each order has 10 items = 100 rows returned!
var customer = context.Customers
    .Include(c => c.Orders)
    .ThenInclude(o => o.OrderDetails)
    .First(c => c.CustomerID == 1);

/*
Result set (cartesian product):
- 1 customer × 10 orders × 10 items = 100 rows
- Lots of duplicate customer and order data!

Customer | Order | OrderDetail
---------|-------|------------
Customer1| Order1| Detail1
Customer1| Order1| Detail2
...
Customer1| Order2| Detail1
Customer1| Order2| Detail2
...

Solution: Use AsSplitQuery()
*/

var customer = context.Customers
    .Include(c => c.Orders)
    .ThenInclude(o => o.OrderDetails)
    .AsSplitQuery()  // Separate queries, no cartesian product
    .First(c => c.CustomerID == 1);
```

---

### 3. Explicit Loading

Related data is **manually loaded** when needed using `Load()`.

```csharp
// ============================================
// EXPLICIT LOADING
// ============================================

using (var context = new AppDbContext())
{
    // Load customer only
    var customer = context.Customers.Find(1);

    // Explicitly load orders when needed
    context.Entry(customer)
        .Collection(c => c.Orders)  // For collections
        .Load();

    // SQL: SELECT * FROM Orders WHERE CustomerID = 1

    // Now orders are available
    Console.WriteLine($"Order count: {customer.Orders.Count}");

    // Load specific order's details
    var firstOrder = customer.Orders.First();
    context.Entry(firstOrder)
        .Collection(o => o.OrderDetails)  // Load details for this order
        .Load();

    // Load reference navigation (single entity)
    context.Entry(firstOrder)
        .Reference(o => o.Customer)  // For single reference
        .Load();
}

// Query before loading
using (var context = new AppDbContext())
{
    var customer = context.Customers.Find(1);

    // Check if already loaded
    var ordersEntry = context.Entry(customer).Collection(c => c.Orders);

    if (!ordersEntry.IsLoaded)
    {
        // Load with filter
        ordersEntry.Query()
            .Where(o => o.TotalAmount > 1000)
            .OrderByDescending(o => o.OrderDate)
            .Load();
    }

    // Or get count without loading
    var orderCount = ordersEntry.Query().Count();
}

// Conditional explicit loading
using (var context = new AppDbContext())
{
    var customers = context.Customers.Take(10).ToList();

    foreach (var customer in customers)
    {
        // Load orders only for VIP customers
        if (customer.IsVIP)
        {
            context.Entry(customer)
                .Collection(c => c.Orders)
                .Query()
                .Where(o => o.OrderDate > DateTime.Now.AddYears(-1))
                .Load();
        }
    }
}
```

**Advantages:**
- ✅ Full control over loading
- ✅ Can filter related data
- ✅ Efficient for conditional loading
- ✅ Works with disconnected scenarios

**Disadvantages:**
- ❌ More verbose code
- ❌ Can still cause N+1 if not careful
- ❌ Easy to forget to load data

---

### Comparison Table

| Feature | Lazy Loading | Eager Loading | Explicit Loading |
|---------|-------------|---------------|------------------|
| **Loading Time** | On access | Immediately | On demand (manual) |
| **Syntax** | Automatic | `.Include()` | `.Load()` |
| **Number of Queries** | Many (N+1 risk) | Few (1 or split) | Controlled |
| **Virtual Properties** | Required | Not required | Not required |
| **Performance** | Poor (many queries) | Good (optimized) | Good (controlled) |
| **Control** | None | Medium | Full |
| **Disconnected Scenarios** | ❌ No | ✅ Yes | ✅ Yes |
| **Code Complexity** | Simple | Medium | Verbose |
| **Best For** | Simple scenarios | Known data needs | Conditional loading |

---

### Real-World Recommendations

```csharp
// ============================================
// WHEN TO USE EACH STRATEGY
// ============================================

// 1. LAZY LOADING - Small applications, simple object graphs
public class SimpleBlogService
{
    public Blog GetBlog(int id)
    {
        using var context = new BlogContext();
        var blog = context.Blogs.Find(id);

        // Lazy loading is fine here - simple scenario
        return blog;
    }
}

// 2. EAGER LOADING - Known data requirements, avoid N+1
public class OrderReportService
{
    public List<OrderDTO> GetOrdersWithDetails()
    {
        using var context = new AppDbContext();

        // We KNOW we need this data - eager load it
        return context.Orders
            .Include(o => o.Customer)
            .Include(o => o.OrderDetails)
                .ThenInclude(od => od.Product)
            .Where(o => o.OrderDate > DateTime.Now.AddMonths(-1))
            .Select(o => new OrderDTO
            {
                OrderID = o.OrderID,
                CustomerName = o.Customer.CustomerName,
                Items = o.OrderDetails.Select(od => new OrderItemDTO
                {
                    ProductName = od.Product.ProductName,
                    Quantity = od.Quantity
                }).ToList()
            })
            .ToList();
    }
}

// 3. EXPLICIT LOADING - Conditional requirements
public class CustomerService
{
    public CustomerViewModel GetCustomer(int id, bool includeOrders)
    {
        using var context = new AppDbContext();

        var customer = context.Customers.Find(id);

        // Load orders only if requested
        if (includeOrders)
        {
            context.Entry(customer)
                .Collection(c => c.Orders)
                .Query()
                .Where(o => o.Status != "Cancelled")
                .Load();
        }

        return MapToViewModel(customer);
    }
}

// BEST PRACTICE: Use projections (no loading needed!)
public class OptimizedOrderService
{
    public List<OrderSummaryDTO> GetOrderSummaries()
    {
        using var context = new AppDbContext();

        // Select only needed data - no loading strategy needed!
        return context.Orders
            .Where(o => o.OrderDate > DateTime.Now.AddMonths(-1))
            .Select(o => new OrderSummaryDTO
            {
                OrderID = o.OrderID,
                CustomerName = o.Customer.CustomerName,  // No Include needed!
                TotalAmount = o.TotalAmount,
                ItemCount = o.OrderDetails.Count  // No Include needed!
            })
            .ToList();

        // Single efficient query, no extra data loaded
    }
}
```

---

## Q216: What is the N+1 query problem and how do you solve it?

**Answer:**

The **N+1 query problem** is one of the most common performance issues in ORM applications. It occurs when the application executes 1 query to fetch N parent records, then executes N additional queries to fetch related child records for each parent.

### The Problem

```csharp
// ============================================
// N+1 QUERY PROBLEM DEMONSTRATION
// ============================================

using (var context = new AppDbContext())
{
    // 1st query: Get all customers
    var customers = context.Customers
        .Where(c => c.City == "New York")
        .ToList();  // 1 query → SELECT * FROM Customers WHERE City = 'New York'

    // For each customer, access orders (causes additional queries)
    foreach (var customer in customers)  // Assume 100 customers
    {
        Console.WriteLine($"Customer: {customer.CustomerName}");

        // N queries (one for each customer!)
        foreach (var order in customer.Orders)  // Lazy loading kicks in
        {
            // SQL: SELECT * FROM Orders WHERE CustomerID = @p0
            Console.WriteLine($"  Order #{order.OrderID}: ${order.TotalAmount}");
        }
    }
}

/*
Total Queries = 1 + N
If N = 100 customers, that's 101 database round trips!
Each round trip has network latency and processing overhead.

Execution Timeline:
Query 1: SELECT * FROM Customers WHERE City = 'New York'
Query 2: SELECT * FROM Orders WHERE CustomerID = 1
Query 3: SELECT * FROM Orders WHERE CustomerID = 2
Query 4: SELECT * FROM Orders WHERE CustomerID = 3
...
Query 101: SELECT * FROM Orders WHERE CustomerID = 100
*/
```

### Why Is This a Problem?

```csharp
// Performance impact example
Stopwatch sw = Stopwatch.StartNew();

using (var context = new AppDbContext())
{
    var customers = context.Customers.Take(100).ToList();  // 1 query

    foreach (var customer in customers)
    {
        var orderCount = customer.Orders.Count;  // 100 queries!
    }
}

sw.Stop();
// Elapsed time: 5000ms (5 seconds!)

// Each query might only take 50ms, but:
// 101 queries × 50ms = 5050ms total
```

---

### Solution 1: Eager Loading with Include

**Best solution** for most scenarios - load all data in fewer queries.

```csharp
// ============================================
// SOLUTION 1: EAGER LOADING
// ============================================

using (var context = new AppDbContext())
{
    // Load customers AND orders in single query
    var customers = context.Customers
        .Where(c => c.City == "New York")
        .Include(c => c.Orders)  // Eager load orders
        .ToList();

    // SQL Generated:
    /*
    SELECT c.*, o.*
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE c.City = 'New York'
    */

    // Now iterate without additional queries
    foreach (var customer in customers)
    {
        Console.WriteLine($"Customer: {customer.CustomerName}");

        foreach (var order in customer.Orders)  // No additional query!
        {
            Console.WriteLine($"  Order #{order.OrderID}: ${order.TotalAmount}");
        }
    }
}

// Total queries: 1 (vs 101!)
// Performance: ~100ms (vs 5000ms!)
```

**Multiple Levels:**
```csharp
// Load customers → orders → order details → products
var customers = context.Customers
    .Include(c => c.Orders)
        .ThenInclude(o => o.OrderDetails)
            .ThenInclude(od => od.Product)
    .Where(c => c.City == "New York")
    .ToList();

// Single query with multiple JOINs
```

**Caution - Cartesian Explosion:**
```csharp
// Including multiple collections can cause cartesian explosion
var customers = context.Customers
    .Include(c => c.Orders)  // 10 orders per customer
    .Include(c => c.Addresses)  // 5 addresses per customer
    .ToList();

// Returns: Customer rows × Orders × Addresses = Huge result set!
// Solution: Use split queries
```

---

### Solution 2: Split Queries (EF Core 5+)

Separate query for each Include, avoiding cartesian explosion.

```csharp
// ============================================
// SOLUTION 2: SPLIT QUERIES
// ============================================

using (var context = new AppDbContext())
{
    var customers = context.Customers
        .Include(c => c.Orders)
        .Include(c => c.Addresses)
        .AsSplitQuery()  // Use multiple queries
        .ToList();

    /*
    Query 1: SELECT * FROM Customers
    Query 2: SELECT * FROM Orders WHERE CustomerID IN (...)
    Query 3: SELECT * FROM Addresses WHERE CustomerID IN (...)

    Total: 3 queries (not 101!)
    No cartesian explosion
    */
}

// Configure globally
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder
        .UseSqlServer(connectionString)
        .UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
}
```

---

### Solution 3: Projection (Select)

**Best performance** - only fetch needed data.

```csharp
// ============================================
// SOLUTION 3: PROJECTION
// ============================================

using (var context = new AppDbContext())
{
    var result = context.Customers
        .Where(c => c.City == "New York")
        .Select(c => new CustomerDTO
        {
            CustomerName = c.CustomerName,
            Email = c.Email,
            OrderCount = c.Orders.Count,  // No Include needed!
            TotalSpent = c.Orders.Sum(o => o.TotalAmount),  // Translated to SQL
            RecentOrders = c.Orders
                .OrderByDescending(o => o.OrderDate)
                .Take(5)
                .Select(o => new OrderDTO
                {
                    OrderID = o.OrderID,
                    OrderDate = o.OrderDate,
                    TotalAmount = o.TotalAmount
                })
                .ToList()
        })
        .ToList();

    /*
    Single efficient SQL query:
    SELECT
        c.CustomerName,
        c.Email,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        (SELECT TOP 5 ... FROM Orders WHERE CustomerID = c.CustomerID ORDER BY OrderDate DESC) AS RecentOrders
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE c.City = 'New York'
    GROUP BY c.CustomerID, c.CustomerName, c.Email
    */
}

// No additional queries!
// Only fetches needed columns
// Fastest solution
```

---

### Solution 4: Batching with IN Queries

For scenarios where eager loading isn't practical.

```csharp
// ============================================
// SOLUTION 4: MANUAL BATCHING
// ============================================

using (var context = new AppDbContext())
{
    // Get customers
    var customers = context.Customers
        .Where(c => c.City == "New York")
        .ToList();  // Query 1

    var customerIds = customers.Select(c => c.CustomerID).ToList();

    // Get all orders in single query
    var orders = context.Orders
        .Where(o => customerIds.Contains(o.CustomerID))
        .ToList();  // Query 2 - gets all orders at once

    // Manually associate orders with customers
    foreach (var customer in customers)
    {
        customer.Orders = orders
            .Where(o => o.CustomerID == customer.CustomerID)
            .ToList();
    }

    // Total queries: 2 (vs 101!)
}
```

---

### Solution 5: Disable Lazy Loading

Prevent lazy loading to catch N+1 problems during development.

```csharp
// ============================================
// SOLUTION 5: DISABLE LAZY LOADING
// ============================================

// Don't use virtual properties
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }

    // NOT virtual - can't lazy load
    public ICollection<Order> Orders { get; set; }
}

// Or configure context
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder
        .UseSqlServer(connectionString);
        // Don't call UseLazyLoadingProxies()
}

// Now accessing Orders without Include throws NullReferenceException
// Forces you to use Include or Load explicitly
```

---

### Real-World Examples

#### Example 1: Order History Page

```csharp
// ❌ BAD - N+1 Problem
public class OrderController : Controller
{
    public IActionResult Index()
    {
        var orders = _context.Orders.ToList();  // 1 query

        // View accesses Customer and Product for each order
        // Results in N queries!
        return View(orders);
    }
}

// View (Razor)
@foreach (var order in Model)
{
    <tr>
        <td>@order.Customer.CustomerName</td>  // Query!
        <td>@order.Product.ProductName</td>    // Query!
    </tr>
}

// ✅ GOOD - Eager Loading
public IActionResult Index()
{
    var orders = _context.Orders
        .Include(o => o.Customer)
        .Include(o => o.Product)
        .ToList();  // Single query with JOINs

    return View(orders);
}

// ✅ BETTER - Projection
public IActionResult Index()
{
    var orders = _context.Orders
        .Select(o => new OrderViewModel
        {
            OrderID = o.OrderID,
            CustomerName = o.Customer.CustomerName,
            ProductName = o.Product.ProductName,
            TotalAmount = o.TotalAmount
        })
        .ToList();  // Single optimized query

    return View(orders);
}
```

#### Example 2: API Endpoint

```csharp
// ❌ BAD
[HttpGet]
public IActionResult GetCustomers()
{
    var customers = _context.Customers.ToList();  // 1 query

    var result = customers.Select(c => new
    {
        Name = c.CustomerName,
        OrderCount = c.Orders.Count,  // N queries!
        TotalSpent = c.Orders.Sum(o => o.TotalAmount)  // N more queries!
    });

    return Ok(result);
}

// ✅ GOOD
[HttpGet]
public IActionResult GetCustomers()
{
    var result = _context.Customers
        .Select(c => new
        {
            Name = c.CustomerName,
            OrderCount = c.Orders.Count,  // Translated to SQL!
            TotalSpent = c.Orders.Sum(o => o.TotalAmount)
        })
        .ToList();  // Single query

    return Ok(result);
}
```

---

### Detecting N+1 Problems

#### 1. Enable Query Logging

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder
        .UseSqlServer(connectionString)
        .LogTo(Console.WriteLine, LogLevel.Information)
        .EnableSensitiveDataLogging();
}

// Output shows every SQL query executed
// Look for repeated queries with different parameters
```

#### 2. Use Profiling Tools

```csharp
// SQL Server Profiler
// Entity Framework Profiler (commercial)
// MiniProfiler (open source)

// MiniProfiler example
services.AddMiniProfiler(options =>
{
    options.RouteBasePath = "/profiler";
});

// Shows query count and duplicate queries
```

#### 3. Unit Test for Query Count

```csharp
[Fact]
public void GetCustomers_ShouldNotCauseNPlusOne()
{
    using var context = CreateTestContext();

    int queryCount = 0;
    context.Database.Log = sql =>
    {
        if (sql.Contains("SELECT"))
            queryCount++;
    };

    // Act
    var service = new CustomerService(context);
    var result = service.GetCustomersWithOrders();

    // Assert
    Assert.True(queryCount <= 3, $"Expected <= 3 queries, got {queryCount}");
}
```

---

### Best Practices

```csharp
// 1. ✅ Use Include for known relationships
var customers = context.Customers
    .Include(c => c.Orders)
    .ToList();

// 2. ✅ Use projection when you don't need full entities
var customers = context.Customers
    .Select(c => new { c.Name, OrderCount = c.Orders.Count })
    .ToList();

// 3. ✅ Use AsSplitQuery to avoid cartesian explosion
var customers = context.Customers
    .Include(c => c.Orders)
    .Include(c => c.Addresses)
    .AsSplitQuery()
    .ToList();

// 4. ✅ Disable lazy loading in production
optionsBuilder.UseSqlServer(connectionString);
// Don't use .UseLazyLoadingProxies()

// 5. ✅ Monitor query counts in development
optionsBuilder.LogTo(Console.WriteLine);

// 6. ❌ Avoid lazy loading in loops
// 7. ❌ Don't access navigation properties without Include
// 8. ❌ Don't iterate over large collections without pagination
```

---

## Q217: What are Tracking vs No-Tracking queries in Entity Framework?

**Answer:**

**Tracking** means EF keeps track of entity changes for automatic updates. **No-Tracking** queries return read-only data without change tracking overhead.

### Tracking Queries (Default)

EF monitors entities for changes and updates them on `SaveChanges()`.

```csharp
// ============================================
// TRACKING QUERY (DEFAULT)
// ============================================

using (var context = new AppDbContext())
{
    // This is a tracking query by default
    var customer = context.Customers.First(c => c.CustomerID == 1);

    // Entity is tracked
    var entry = context.Entry(customer);
    Console.WriteLine($"State: {entry.State}");  // Unchanged

    // Modify entity
    customer.Email = "newemail@example.com";

    // State automatically changes
    Console.WriteLine($"State: {entry.State}");  // Modified

    // EF knows what changed
    foreach (var prop in entry.Properties.Where(p => p.IsModified))
    {
        Console.WriteLine($"{prop.Metadata.Name}: {prop.OriginalValue} → {prop.CurrentValue}");
    }

    // Save changes - EF generates UPDATE for modified columns only
    context.SaveChanges();
    /*
    UPDATE Customers
    SET Email = 'newemail@example.com'
    WHERE CustomerID = 1
    */
}
```

**How Tracking Works:**

```csharp
using (var context = new AppDbContext())
{
    // Load entity
    var customer1 = context.Customers.Find(1);

    // Load same entity again
    var customer2 = context.Customers.Find(1);

    // Same instance! (identity map pattern)
    Console.WriteLine(Object.ReferenceEquals(customer1, customer2));  // True

    // Change tracking context (1st level cache)
    var tracked = context.ChangeTracker.Entries<Customer>();
    Console.WriteLine($"Tracked entities: {tracked.Count()}");  // 1
}
```

**Advantages of Tracking:**
- ✅ Automatic change detection
- ✅ Easy updates (just modify and save)
- ✅ Identity map (same entity = same instance)
- ✅ Relationship fixup (navigation properties auto-populated)

**Disadvantages:**
- ❌ Memory overhead (maintains snapshots)
- ❌ Slower for read-only queries
- ❌ Not suitable for large result sets

---

### No-Tracking Queries

Read-only queries without change tracking overhead.

```csharp
// ============================================
// NO-TRACKING QUERY
// ============================================

using (var context = new AppDbContext())
{
    // Use AsNoTracking()
    var customers = context.Customers
        .AsNoTracking()  // Disable change tracking
        .Where(c => c.City == "New York")
        .ToList();

    // Entities are not tracked
    var entry = context.Entry(customers[0]);
    Console.WriteLine($"State: {entry.State}");  // Detached

    // Modifications won't be saved
    customers[0].Email = "newemail@example.com";
    context.SaveChanges();  // No UPDATE generated

    // Lower memory usage
    // Faster query execution
}
```

**AsNoTracking() for entire context:**

```csharp
public class AppDbContext : DbContext
{
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder
            .UseSqlServer(connectionString)
            .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
            // All queries are no-tracking by default
    }
}

// Override for specific query
var customer = context.Customers
    .AsTracking()  // Enable tracking for this query
    .First(c => c.CustomerID == 1);
```

**Advantages of No-Tracking:**
- ✅ Better performance (20-30% faster)
- ✅ Lower memory usage
- ✅ Suitable for read-only scenarios
- ✅ Better for large result sets

**Disadvantages:**
- ❌ Can't save changes automatically
- ❌ No identity map
- ❌ Manual attach needed for updates

---

### Performance Comparison

```csharp
// ============================================
// PERFORMANCE BENCHMARK
// ============================================

// Tracking query
var sw1 = Stopwatch.StartNew();
using (var context = new AppDbContext())
{
    var customers = context.Customers
        .Take(10000)
        .ToList();  // Tracking enabled
}
sw1.Stop();
Console.WriteLine($"Tracking: {sw1.ElapsedMilliseconds}ms");  // 500ms

// No-tracking query
var sw2 = Stopwatch.StartNew();
using (var context = new AppDbContext())
{
    var customers = context.Customers
        .AsNoTracking()
        .Take(10000)
        .ToList();  // No tracking
}
sw2.Stop();
Console.WriteLine($"No-Tracking: {sw2.ElapsedMilliseconds}ms");  // 350ms

// No-Tracking is ~30% faster!
```

---

### When to Use Each

```csharp
// ============================================
// USE TRACKING WHEN:
// ============================================

// 1. Updating entities
using (var context = new AppDbContext())
{
    var customer = context.Customers.First(c => c.CustomerID == 1);
    customer.Email = "updated@example.com";
    context.SaveChanges();  // Needs tracking
}

// 2. Working with relationships
using (var context = new AppDbContext())
{
    var order = context.Orders
        .Include(o => o.Customer)
        .First(o => o.OrderID == 1);

    // Relationship fixup requires tracking
    Console.WriteLine(order.Customer.CustomerName);
}

// 3. Small result sets where tracking overhead is negligible

// ============================================
// USE NO-TRACKING WHEN:
// ============================================

// 1. Read-only queries (reports, views)
public IActionResult GetCustomers()
{
    var customers = _context.Customers
        .AsNoTracking()
        .Select(c => new CustomerDTO
        {
            Name = c.CustomerName,
            Email = c.Email
        })
        .ToList();

    return Ok(customers);
}

// 2. Large result sets
public List<OrderDTO> GetAllOrders()
{
    return _context.Orders
        .AsNoTracking()  // 10,000+ orders
        .Select(o => new OrderDTO { ... })
        .ToList();
}

// 3. Projections (Select) - automatically no-tracking
public List<CustomerSummary> GetCustomerSummaries()
{
    return _context.Customers
        .Select(c => new CustomerSummary  // Automatically no-tracking
        {
            Name = c.CustomerName,
            OrderCount = c.Orders.Count()
        })
        .ToList();
}

// 4. Export/reporting scenarios
public byte[] ExportCustomers()
{
    var customers = _context.Customers
        .AsNoTracking()  // Large export
        .ToList();

    return GenerateExcel(customers);
}
```

---

### Updating No-Tracking Entities

```csharp
// ============================================
// UPDATING NO-TRACKING ENTITIES
// ============================================

// Method 1: Attach and mark as modified
using (var context = new AppDbContext())
{
    var customer = new Customer
    {
        CustomerID = 1,
        Email = "updated@example.com",
        CustomerName = "John Doe"
    };

    // Attach entity
    context.Customers.Attach(customer);

    // Mark as modified
    context.Entry(customer).State = EntityState.Modified;

    // Or mark specific properties as modified
    context.Entry(customer).Property(c => c.Email).IsModified = true;

    context.SaveChanges();
    /*
    UPDATE Customers
    SET Email = 'updated@example.com'
    WHERE CustomerID = 1
    */
}

// Method 2: Update method (EF Core 7+)
using (var context = new AppDbContext())
{
    var customer = new Customer
    {
        CustomerID = 1,
        Email = "updated@example.com"
    };

    context.Customers.Update(customer);  // Attaches and marks all properties as modified

    context.SaveChanges();
}

// Method 3: Load then update
using (var context = new AppDbContext())
{
    // Load with no-tracking
    var customer = context.Customers
        .AsNoTracking()
        .First(c => c.CustomerID == 1);

    // Modify
    customer.Email = "updated@example.com";

    // Attach with modified state
    context.Entry(customer).State = EntityState.Modified;

    context.SaveChanges();
}
```

---

### Real-World Examples

#### Example 1: API Controller

```csharp
public class CustomersController : ControllerBase
{
    private readonly AppDbContext _context;

    // GET: api/customers (read-only - use no-tracking)
    [HttpGet]
    public async Task<IActionResult> GetCustomers()
    {
        var customers = await _context.Customers
            .AsNoTracking()  // Read-only
            .Select(c => new CustomerDTO
            {
                CustomerID = c.CustomerID,
                CustomerName = c.CustomerName,
                Email = c.Email
            })
            .ToListAsync();

        return Ok(customers);
    }

    // GET: api/customers/5 (for update - use tracking)
    [HttpGet("{id}")]
    public async Task<IActionResult> GetCustomer(int id)
    {
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.CustomerID == id);
            // Tracking enabled (default)

        return customer == null ? NotFound() : Ok(customer);
    }

    // PUT: api/customers/5 (update - needs tracking or attach)
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCustomer(int id, Customer customer)
    {
        if (id != customer.CustomerID)
            return BadRequest();

        // Option 1: Attach and mark modified
        _context.Entry(customer).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!CustomerExists(id))
                return NotFound();
            throw;
        }

        return NoContent();
    }
}
```

#### Example 2: Reporting Service

```csharp
public class ReportService
{
    private readonly AppDbContext _context;

    public async Task<SalesReport> GetSalesReport(DateTime startDate, DateTime endDate)
    {
        // All no-tracking for read-only report
        var totalSales = await _context.Orders
            .AsNoTracking()
            .Where(o => o.OrderDate >= startDate && o.OrderDate <= endDate)
            .SumAsync(o => o.TotalAmount);

        var topCustomers = await _context.Customers
            .AsNoTracking()
            .Select(c => new
            {
                c.CustomerName,
                TotalSpent = c.Orders
                    .Where(o => o.OrderDate >= startDate && o.OrderDate <= endDate)
                    .Sum(o => o.TotalAmount)
            })
            .OrderByDescending(x => x.TotalSpent)
            .Take(10)
            .ToListAsync();

        return new SalesReport
        {
            TotalSales = totalSales,
            TopCustomers = topCustomers
        };
    }
}
```

---

### Best Practices

1. ✅ Use **No-Tracking** for read-only queries
2. ✅ Use **No-Tracking** for large datasets
3. ✅ Use **No-Tracking** for reporting/analytics
4. ✅ Use **Tracking** for updates
5. ✅ Use **Tracking** for small result sets with updates
6. ✅ Projections (Select) are automatically no-tracking
7. ❌ Don't track entities you won't update
8. ❌ Don't forget to attach entities before updating no-tracking results

---

## Q218: Explain Entity Framework Migrations in detail.

**Answer:**

**Migrations** allow you to evolve the database schema over time while preserving existing data. They track changes to the model and generate SQL scripts to update the database.

### How Migrations Work

```csharp
// ============================================
// BASIC MIGRATION WORKFLOW
// ============================================

// 1. Create initial model
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
}

public class AppDbContext : DbContext
{
    public DbSet<Customer> Customers { get; set; }
}

// 2. Create initial migration
// PM> Add-Migration InitialCreate
// CLI> dotnet ef migrations add InitialCreate

// 3. Apply migration to database
// PM> Update-Database
// CLI> dotnet ef database update
```

### Migration Files

**What Gets Generated:**

```csharp
// ============================================
// 20250115123456_InitialCreate.cs
// ============================================

public partial class InitialCreate : Migration
{
    // Applied when updating database
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Customers",
            columns: table => new
            {
                CustomerID = table.Column<int>(nullable: false)
                    .Annotation("SqlServer:Identity", "1, 1"),
                CustomerName = table.Column<string>(nullable: true),
                Email = table.Column<string>(nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Customers", x => x.CustomerID);
            });
    }

    // Applied when rolling back
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "Customers");
    }
}

// ============================================
// 20250115123456_InitialCreate.Designer.cs
// ============================================
// Contains model snapshot - used to detect changes

// ============================================
// AppDbContextModelSnapshot.cs
// ============================================
// Current state of the model - updated with each migration
```

---

### Adding Columns

```csharp
// ============================================
// ADD COLUMN MIGRATION
// ============================================

// 1. Modify model
public class Customer
{
    public int CustomerID { get; set; }
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public string PhoneNumber { get; set; }  // NEW COLUMN
    public DateTime CreatedDate { get; set; }  // NEW COLUMN
}

// 2. Create migration
// PM> Add-Migration AddCustomerPhoneAndCreatedDate

// 3. Generated migration
public partial class AddCustomerPhoneAndCreatedDate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "PhoneNumber",
            table: "Customers",
            nullable: true);

        migrationBuilder.AddColumn<DateTime>(
            name: "CreatedDate",
            table: "Customers",
            nullable: false,
            defaultValue: new DateTime(1, 1, 1));  // Default for existing rows
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "PhoneNumber", table: "Customers");
        migrationBuilder.DropColumn(name: "CreatedDate", table: "Customers");
    }
}

// 4. Apply migration
// PM> Update-Database
```

**With Default Values:**

```csharp
// Provide better default for existing data
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.AddColumn<DateTime>(
        name: "CreatedDate",
        table: "Customers",
        nullable: false,
        defaultValueSql: "GETDATE()");  // SQL Server default

    migrationBuilder.AddColumn<bool>(
        name: "IsActive",
        table: "Customers",
        nullable: false,
        defaultValue: true);  // C# default
}
```

---

### Renaming Columns

```csharp
// ============================================
// RENAME COLUMN
// ============================================

// Change model property name
public class Customer
{
    public int CustomerID { get; set; }
    public string FullName { get; set; }  // Was: CustomerName
    public string Email { get; set; }
}

// Create migration
// PM> Add-Migration RenameCustomerNameToFullName

// EF generates DROP + ADD by default (loses data!)
protected override void Up(MigrationBuilder migrationBuilder)
{
    // ❌ BAD - Default behavior
    migrationBuilder.DropColumn(name: "CustomerName", table: "Customers");
    migrationBuilder.AddColumn<string>(name: "FullName", table: "Customers");
}

// ✅ GOOD - Manually edit to use RenameColumn
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.RenameColumn(
        name: "CustomerName",
        table: "Customers",
        newName: "FullName");
}

protected override void Down(MigrationBuilder migrationBuilder)
{
    migrationBuilder.RenameColumn(
        name: "FullName",
        table: "Customers",
        newName: "CustomerName");
}
```

---

### Data Migration

```csharp
// ============================================
// MIGRATE DATA
// ============================================

// Add new column that needs to be calculated from existing data
public partial class AddFullNameColumn : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // 1. Add column (nullable)
        migrationBuilder.AddColumn<string>(
            name: "FullName",
            table: "Customers",
            nullable: true);

        // 2. Populate column from existing data
        migrationBuilder.Sql(@"
            UPDATE Customers
            SET FullName = FirstName + ' ' + LastName
            WHERE FullName IS NULL
        ");

        // 3. Make column required (not nullable)
        migrationBuilder.AlterColumn<string>(
            name: "FullName",
            table: "Customers",
            nullable: false);

        // 4. Drop old columns
        migrationBuilder.DropColumn(name: "FirstName", table: "Customers");
        migrationBuilder.DropColumn(name: "LastName", table: "Customers");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(name: "FirstName", table: "Customers");
        migrationBuilder.AddColumn<string>(name: "LastName", table: "Customers");

        migrationBuilder.Sql(@"
            UPDATE Customers
            SET FirstName = SUBSTRING(FullName, 1, CHARINDEX(' ', FullName) - 1),
                LastName = SUBSTRING(FullName, CHARINDEX(' ', FullName) + 1, LEN(FullName))
        ");

        migrationBuilder.DropColumn(name: "FullName", table: "Customers");
    }
}
```

---

### Seed Data

```csharp
// ============================================
// SEED DATA IN MIGRATIONS
// ============================================

// Method 1: In OnModelCreating
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Customer>().HasData(
        new Customer { CustomerID = 1, CustomerName = "John Doe", Email = "john@example.com" },
        new Customer { CustomerID = 2, CustomerName = "Jane Smith", Email = "jane@example.com" }
    );
}

// Migration generated automatically
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.InsertData(
        table: "Customers",
        columns: new[] { "CustomerID", "CustomerName", "Email" },
        values: new object[] { 1, "John Doe", "john@example.com" });

    migrationBuilder.InsertData(
        table: "Customers",
        columns: new[] { "CustomerID", "CustomerName", "Email" },
        values: new object[] { 2, "Jane Smith", "jane@example.com" });
}

// Method 2: SQL in migration
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.Sql(@"
        INSERT INTO Customers (CustomerName, Email, IsActive)
        VALUES
            ('Admin User', 'admin@company.com', 1),
            ('Test User', 'test@company.com', 1)
    ");
}
```

---

### Managing Migrations

```bash
# ============================================
# MIGRATION COMMANDS
# ============================================

# Create migration
Add-Migration MigrationName
dotnet ef migrations add MigrationName

# Apply all pending migrations
Update-Database
dotnet ef database update

# Apply specific migration (rollback/forward)
Update-Database MigrationName
dotnet ef database update MigrationName

# Rollback to initial state
Update-Database 0
dotnet ef database update 0

# Remove last migration (if not applied)
Remove-Migration
dotnet ef migrations remove

# List all migrations
Get-Migration
dotnet ef migrations list

# Generate SQL script
Script-Migration
dotnet ef migrations script

# Generate SQL from StartMigration to EndMigration
Script-Migration StartMigration EndMigration
dotnet ef migrations script FromMigration ToMigration

# Generate idempotent script (can run multiple times)
Script-Migration -Idempotent
dotnet ef migrations script --idempotent
```

---

### Production Deployment

```csharp
// ============================================
// PRODUCTION MIGRATION STRATEGIES
// ============================================

// Strategy 1: Generate SQL scripts (Recommended)
// PM> Script-Migration -Idempotent -Output "migration.sql"
// Then: Review and execute SQL manually in production

// Strategy 2: Programmatic migration on startup
public class Program
{
    public static void Main(string[] args)
    {
        var host = CreateHostBuilder(args).Build();

        // Apply migrations on startup
        using (var scope = host.Services.CreateScope())
        {
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            try
            {
                // Apply pending migrations
                context.Database.Migrate();
                Console.WriteLine("Migrations applied successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Migration failed: {ex.Message}");
                throw;
            }
        }

        host.Run();
    }
}

// Strategy 3: Check if migration needed
public void ConfigureServices(IServiceCollection services)
{
    services.AddDbContext<AppDbContext>(options =>
        options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));
}

public void Configure(IApplicationBuilder app, AppDbContext context)
{
    // Check for pending migrations
    var pendingMigrations = context.Database.GetPendingMigrations();

    if (pendingMigrations.Any())
    {
        Console.WriteLine($"Pending migrations: {string.Join(", ", pendingMigrations)}");

        if (Environment.GetEnvironmentVariable("APPLY_MIGRATIONS") == "true")
        {
            context.Database.Migrate();
        }
        else
        {
            throw new Exception("Database is not up to date. Please run migrations.");
        }
    }
}
```

---

### Handling Migration Conflicts

```csharp
// ============================================
// MERGE CONFLICTS IN MIGRATIONS
// ============================================

// Scenario: Two developers create migrations from same baseline

// Developer A creates:
// 20250115100000_AddPhoneNumber.cs

// Developer B creates (from same baseline):
// 20250115110000_AddAddress.cs

// After merge, model snapshot may be inconsistent

// Solution 1: Remove both migrations, recreate as one
// PM> Remove-Migration
// PM> Add-Migration AddPhoneNumberAndAddress

// Solution 2: Keep both, fix snapshot manually
// 1. Apply migrations in order
// 2. Remove migration files
// 3. Create fresh migration to sync snapshot
// PM> Add-Migration FixSnapshot

// The new migration should be empty if everything's in sync
```

---

### Custom Migration Operations

```csharp
// ============================================
// CUSTOM SQL IN MIGRATIONS
// ============================================

public partial class CreateStoredProcedure : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(@"
            CREATE PROCEDURE sp_GetTopCustomers
                @Limit INT = 10
            AS
            BEGIN
                SELECT TOP (@Limit)
                    CustomerID,
                    CustomerName,
                    COUNT(o.OrderID) AS OrderCount,
                    SUM(o.TotalAmount) AS TotalSpent
                FROM Customers c
                LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
                GROUP BY c.CustomerID, c.CustomerName
                ORDER BY TotalSpent DESC
            END
        ");

        // Create index
        migrationBuilder.Sql(@"
            CREATE INDEX IX_Orders_CustomerID_OrderDate
            ON Orders (CustomerID, OrderDate)
            INCLUDE (TotalAmount)
        ");

        // Create view
        migrationBuilder.Sql(@"
            CREATE VIEW vw_CustomerOrderStats AS
            SELECT
                c.CustomerID,
                c.CustomerName,
                COUNT(o.OrderID) AS OrderCount,
                ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent
            FROM Customers c
            LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
            GROUP BY c.CustomerID, c.CustomerName
        ");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS sp_GetTopCustomers");
        migrationBuilder.Sql("DROP INDEX IF EXISTS IX_Orders_CustomerID_OrderDate ON Orders");
        migrationBuilder.Sql("DROP VIEW IF EXISTS vw_CustomerOrderStats");
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use meaningful migration names
Add-Migration AddCustomerLoyaltyProgram  // Good
Add-Migration Update1  // Bad

// 2. ✅ Review generated migrations before applying
// Always check the Up and Down methods

// 3. ✅ Test migrations on development database first
Update-Database

// 4. ✅ Use idempotent scripts for production
Script-Migration -Idempotent

// 5. ✅ Include rollback plan (Down method)
protected override void Down(MigrationBuilder migrationBuilder)
{
    // Always implement Down()
}

// 6. ✅ Handle data migrations carefully
protected override void Up(MigrationBuilder migrationBuilder)
{
    // Add nullable first
    // Migrate data
    // Make non-nullable
}

// 7. ✅ Use custom SQL for complex operations
migrationBuilder.Sql("...");

// 8. ❌ Don't modify applied migrations
// Create new migration instead

// 9. ❌ Don't delete migration files
// Use Remove-Migration only for unapplied migrations

// 10. ❌ Don't forget to commit migration files to source control
// Commit .cs, .Designer.cs, and ModelSnapshot.cs
```

---

## Q219: What are Entity Framework Core performance best practices?

**Answer:**

### 1. Use AsNoTracking for Read-Only Queries

```csharp
// ❌ BAD - Tracking overhead for read-only data
var customers = context.Customers.ToList();

// ✅ GOOD - No tracking for read-only
var customers = context.Customers
    .AsNoTracking()
    .ToList();

// 20-30% faster, less memory
```

---

### 2. Use Projections (Select) Instead of Entities

```csharp
// ❌ BAD - Loads all columns, tracking overhead
var customers = context.Customers
    .Include(c => c.Orders)
    .ToList();

// ✅ GOOD - Only needed columns, no tracking
var customers = context.Customers
    .Select(c => new CustomerDTO
    {
        Name = c.CustomerName,
        Email = c.Email,
        OrderCount = c.Orders.Count
    })
    .ToList();

// Much faster, less data transferred
```

---

### 3. Avoid N+1 Query Problem

```csharp
// ❌ BAD - N+1 queries
var customers = context.Customers.ToList();
foreach (var customer in customers)
{
    var orderCount = customer.Orders.Count;  // N queries!
}

// ✅ GOOD - Single query with Include
var customers = context.Customers
    .Include(c => c.Orders)
    .ToList();

// ✅ BETTER - Projection
var customers = context.Customers
    .Select(c => new { c.Name, OrderCount = c.Orders.Count })
    .ToList();
```

---

### 4. Use Compiled Queries for Frequently Executed Queries

```csharp
// Define compiled query (once)
private static readonly Func<AppDbContext, int, Customer> _getCustomerById =
    EF.CompileQuery((AppDbContext context, int id) =>
        context.Customers.FirstOrDefault(c => c.CustomerID == id));

// Use compiled query (multiple times)
using (var context = new AppDbContext())
{
    var customer = _getCustomerById(context, 1);
    // 20-30% faster on subsequent calls
}

// Complex compiled query
private static readonly Func<AppDbContext, DateTime, IEnumerable<OrderSummary>> _getOrdersByDate =
    EF.CompileQuery((AppDbContext context, DateTime date) =>
        context.Orders
            .Where(o => o.OrderDate >= date)
            .Select(o => new OrderSummary
            {
                OrderID = o.OrderID,
                CustomerName = o.Customer.CustomerName,
                TotalAmount = o.TotalAmount
            }));
```

---

### 5. Use Split Queries to Avoid Cartesian Explosion

```csharp
// ❌ BAD - Cartesian explosion
var customers = context.Customers
    .Include(c => c.Orders)  // 10 orders per customer
    .Include(c => c.Addresses)  // 5 addresses per customer
    .ToList();
// Returns: 1 customer × 10 orders × 5 addresses = 50 duplicate rows!

// ✅ GOOD - Split queries
var customers = context.Customers
    .Include(c => c.Orders)
    .Include(c => c.Addresses)
    .AsSplitQuery()  // 3 queries, no duplication
    .ToList();
```

---

### 6. Use Pagination

```csharp
// ❌ BAD - Load all data
var orders = context.Orders.ToList();  // 100,000 rows!

// ✅ GOOD - Pagination
var page = 1;
var pageSize = 20;

var orders = context.Orders
    .OrderByDescending(o => o.OrderDate)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToList();  // Only 20 rows

// With total count (for UI pagination)
var query = context.Orders.AsQueryable();

var totalCount = await query.CountAsync();
var orders = await query
    .OrderByDescending(o => o.OrderDate)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();
```

---

### 7. Batch Operations

```csharp
// ❌ BAD - Individual saves
foreach (var customer in customers)
{
    customer.IsActive = false;
    context.SaveChanges();  // 1000 round trips!
}

// ✅ GOOD - Single batch
foreach (var customer in customers)
{
    customer.IsActive = false;
}
context.SaveChanges();  // 1 transaction

// ✅ BETTER - Bulk update with raw SQL
context.Database.ExecuteSqlRaw(@"
    UPDATE Customers
    SET IsActive = 0
    WHERE City = 'New York'
");

// ✅ BEST - Use library like EFCore.BulkExtensions
context.BulkUpdate(customers);
context.BulkInsert(newCustomers);
context.BulkDelete(customersToDelete);
```

---

### 8. Use Appropriate Fetch Strategies

```csharp
// For known requirements - Eager Loading
var customers = context.Customers
    .Include(c => c.Orders)
        .ThenInclude(o => o.OrderDetails)
    .ToList();

// For conditional loading - Explicit Loading
var customer = context.Customers.Find(1);
if (includeOrders)
{
    context.Entry(customer).Collection(c => c.Orders).Load();
}

// For read-only - Projection (best performance)
var customers = context.Customers
    .Select(c => new { c.Name, OrderCount = c.Orders.Count })
    .ToList();
```

---

### 9. Avoid Lazy Loading in Loops

```csharp
// ❌ BAD - Lazy loading in loop (N+1)
var customers = context.Customers.ToList();
foreach (var customer in customers)
{
    Console.WriteLine(customer.Orders.Count);  // Lazy load!
}

// ✅ GOOD - Disable lazy loading
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder.UseSqlServer(connectionString);
    // Don't call .UseLazyLoadingProxies()
}
```

---

### 10. Use Connection Pooling

```csharp
// ✅ Connection pooling enabled by default
services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// Configure pool size
var connectionString = "Server=.;Database=MyDb;Max Pool Size=100;Min Pool Size=5;";

// Monitor connection pool
// Use performance counters or SQL Server DMVs
```

---

### 11. Use async/await

```csharp
// ❌ Synchronous (blocks thread)
var customers = context.Customers.ToList();

// ✅ Asynchronous (frees thread)
var customers = await context.Customers.ToListAsync();

// In controllers
public async Task<IActionResult> GetCustomers()
{
    var customers = await _context.Customers
        .AsNoTracking()
        .ToListAsync();

    return Ok(customers);
}
```

---

### 12. Optimize Query Patterns

```csharp
// ❌ BAD - Multiple queries
var customer = context.Customers.Find(id);
var orderCount = context.Orders.Count(o => o.CustomerID == id);
var totalSpent = context.Orders.Where(o => o.CustomerID == id).Sum(o => o.TotalAmount);

// ✅ GOOD - Single query
var result = context.Customers
    .Where(c => c.CustomerID == id)
    .Select(c => new
    {
        Customer = c,
        OrderCount = c.Orders.Count(),
        TotalSpent = c.Orders.Sum(o => o.TotalAmount)
    })
    .FirstOrDefault();
```

---

### 13. Index Optimization

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Create indexes for frequently queried columns
    modelBuilder.Entity<Order>()
        .HasIndex(o => o.OrderDate);

    modelBuilder.Entity<Order>()
        .HasIndex(o => new { o.CustomerID, o.OrderDate })
        .IsUnique(false);

    // Covering index (includes additional columns)
    modelBuilder.Entity<Order>()
        .HasIndex(o => o.CustomerID)
        .IncludeProperties(o => new { o.OrderDate, o.TotalAmount });

    // Filtered index
    modelBuilder.Entity<Order>()
        .HasIndex(o => o.OrderDate)
        .HasFilter("[Status] = 'Active'");
}
```

---

### 14. Monitor and Log Queries

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    // Log to console (development)
    optionsBuilder
        .LogTo(Console.WriteLine, LogLevel.Information)
        .EnableSensitiveDataLogging()
        .EnableDetailedErrors();

    // Log slow queries only
    optionsBuilder.LogTo(
        message => Console.WriteLine(message),
        (eventId, logLevel) => logLevel >= LogLevel.Warning);

    // Custom logger
    optionsBuilder.LogTo(
        sql =>
        {
            if (sql.Contains("SELECT") && IsSlow(sql))
            {
                Logger.LogWarning($"Slow query detected: {sql}");
            }
        });
}
```

---

### 15. Use Database-Generated Values

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Use database defaults instead of C# defaults
    modelBuilder.Entity<Order>()
        .Property(o => o.OrderDate)
        .HasDefaultValueSql("GETDATE()");

    modelBuilder.Entity<Customer>()
        .Property(c => c.CustomerGuid)
        .HasDefaultValueSql("NEWID()");

    // Use identity columns
    modelBuilder.Entity<Customer>()
        .Property(c => c.CustomerID)
        .ValueGeneratedOnAdd();
}
```

---

### Performance Checklist

```csharp
// ✅ Use AsNoTracking for read-only queries
// ✅ Use projections (Select) instead of loading full entities
// ✅ Avoid N+1 queries - use Include or projections
// ✅ Use compiled queries for frequently executed queries
// ✅ Use split queries to avoid cartesian explosion
// ✅ Implement pagination for large datasets
// ✅ Batch database operations
// ✅ Disable lazy loading
// ✅ Use async/await
// ✅ Create appropriate indexes
// ✅ Monitor query performance
// ✅ Use connection pooling
// ✅ Cache frequently accessed data
// ✅ Use database-generated values
// ✅ Optimize fetch strategies based on use case
```

---

## Q220: How do you use raw SQL and stored procedures in EF Core?

**Answer:**

Entity Framework Core allows executing raw SQL when LINQ isn't sufficient or for performance optimization.

### 1. FromSqlRaw / FromSqlInterpolated

Execute SQL queries that return entities.

```csharp
// ============================================
// FROMSQLRAW
// ============================================

// Basic query
var customers = context.Customers
    .FromSqlRaw("SELECT * FROM Customers WHERE City = 'New York'")
    .ToList();

// ⚠️ WARNING: SQL Injection risk with string concatenation
var city = "New York";
var customers = context.Customers
    .FromSqlRaw($"SELECT * FROM Customers WHERE City = '{city}'")  // DANGEROUS!
    .ToList();

// ✅ SAFE: Use parameters
var customers = context.Customers
    .FromSqlRaw("SELECT * FROM Customers WHERE City = {0}", city)
    .ToList();

// ✅ BETTER: Use FromSqlInterpolated
var city = "New York";
var customers = context.Customers
    .FromSqlInterpolated($"SELECT * FROM Customers WHERE City = {city}")
    .ToList();
// Parameters automatically created - SQL injection safe!

// Combine with LINQ
var customers = context.Customers
    .FromSqlRaw("SELECT * FROM Customers WHERE City = 'New York'")
    .Where(c => c.IsActive)  // Additional LINQ filter
    .OrderBy(c => c.CustomerName)
    .ToList();

/*
Generated SQL:
SELECT *
FROM (
    SELECT * FROM Customers WHERE City = 'New York'
) AS c
WHERE c.IsActive = 1
ORDER BY c.CustomerName
*/
```

---

### 2. ExecuteSqlRaw / ExecuteSqlInterpolated

Execute non-query SQL (INSERT, UPDATE, DELETE).

```csharp
// ============================================
// EXECUTESQLRAW
// ============================================

// Update
var rowsAffected = context.Database.ExecuteSqlRaw(@"
    UPDATE Customers
    SET IsActive = 0
    WHERE LastOrderDate < DATEADD(YEAR, -1, GETDATE())
");

Console.WriteLine($"{rowsAffected} rows updated");

// With parameters (safe)
var city = "New York";
var isActive = false;

var rowsAffected = context.Database.ExecuteSqlRaw(@"
    UPDATE Customers
    SET IsActive = {1}
    WHERE City = {0}",
    city, isActive);

// ✅ BETTER: Use ExecuteSqlInterpolated
var rowsAffected = context.Database.ExecuteSqlInterpolated($@"
    UPDATE Customers
    SET IsActive = {isActive}
    WHERE City = {city}
");

// Delete
var deletedCount = context.Database.ExecuteSqlRaw(@"
    DELETE FROM Orders
    WHERE OrderDate < {0}",
    DateTime.Now.AddYears(-5));

// Insert (less common - usually use Add)
context.Database.ExecuteSqlRaw(@"
    INSERT INTO AuditLog (Action, Timestamp, UserId)
    VALUES ({0}, GETDATE(), {1})",
    "BULK_UPDATE", currentUserId);
```

---

### 3. Stored Procedures

#### Stored Procedures Returning Entities

```sql
-- ============================================
-- CREATE STORED PROCEDURE
-- ============================================

CREATE PROCEDURE sp_GetCustomersByCity
    @City NVARCHAR(100)
AS
BEGIN
    SELECT
        CustomerID,
        CustomerName,
        Email,
        City,
        IsActive
    FROM Customers
    WHERE City = @City
    ORDER BY CustomerName
END
GO
```

```csharp
// Execute stored procedure
var city = "New York";
var customers = context.Customers
    .FromSqlInterpolated($"EXEC sp_GetCustomersByCity {city}")
    .ToList();

// Or with FromSqlRaw
var customers = context.Customers
    .FromSqlRaw("EXEC sp_GetCustomersByCity @City",
        new SqlParameter("@City", city))
    .ToList();

// Combine with LINQ
var activeCustomers = context.Customers
    .FromSqlInterpolated($"EXEC sp_GetCustomersByCity {city}")
    .Where(c => c.IsActive)
    .ToList();
```

#### Stored Procedures with Output Parameters

```sql
CREATE PROCEDURE sp_GetCustomerStats
    @CustomerID INT,
    @OrderCount INT OUTPUT,
    @TotalSpent DECIMAL(18,2) OUTPUT
AS
BEGIN
    SELECT
        @OrderCount = COUNT(*),
        @TotalSpent = ISNULL(SUM(TotalAmount), 0)
    FROM Orders
    WHERE CustomerID = @CustomerID
END
GO
```

```csharp
// Execute with output parameters
var customerIdParam = new SqlParameter("@CustomerID", 1);
var orderCountParam = new SqlParameter
{
    ParameterName = "@OrderCount",
    SqlDbType = SqlDbType.Int,
    Direction = ParameterDirection.Output
};
var totalSpentParam = new SqlParameter
{
    ParameterName = "@TotalSpent",
    SqlDbType = SqlDbType.Decimal,
    Direction = ParameterDirection.Output
};

context.Database.ExecuteSqlRaw(
    "EXEC sp_GetCustomerStats @CustomerID, @OrderCount OUTPUT, @TotalSpent OUTPUT",
    customerIdParam,
    orderCountParam,
    totalSpentParam);

// Read output values
int orderCount = (int)orderCountParam.Value;
decimal totalSpent = (decimal)totalSpentParam.Value;

Console.WriteLine($"Orders: {orderCount}, Total: ${totalSpent}");
```

---

### 4. SqlQuery for Non-Entity Types

Execute queries that return scalar values or non-entity types.

```csharp
// ============================================
// SQLQUERY (EF CORE 7+)
// ============================================

// Return scalar value
var totalRevenue = context.Database
    .SqlQuery<decimal>($"SELECT SUM(TotalAmount) FROM Orders")
    .FirstOrDefault();

// Return anonymous type / DTO
public class OrderSummary
{
    public int OrderID { get; set; }
    public string CustomerName { get; set; }
    public decimal TotalAmount { get; set; }
}

var orderSummaries = context.Database
    .SqlQuery<OrderSummary>($@"
        SELECT
            o.OrderID,
            c.CustomerName,
            o.TotalAmount
        FROM Orders o
        INNER JOIN Customers c ON o.CustomerID = c.CustomerID
        WHERE o.OrderDate > {DateTime.Now.AddMonths(-1)}
    ")
    .ToList();

// Stored procedure returning custom type
var salesReport = context.Database
    .SqlQuery<MonthlySalesDTO>($"EXEC sp_GetMonthlySales {year}, {month}")
    .ToList();
```

---

### 5. Transactions with Raw SQL

```csharp
// ============================================
// TRANSACTIONS
// ============================================

using (var transaction = context.Database.BeginTransaction())
{
    try
    {
        // EF operation
        var customer = new Customer { CustomerName = "John Doe" };
        context.Customers.Add(customer);
        context.SaveChanges();

        // Raw SQL operation
        context.Database.ExecuteSqlRaw(@"
            UPDATE Inventory
            SET Quantity = Quantity - 1
            WHERE ProductID = {0}",
            productId);

        // Another EF operation
        var order = new Order { CustomerID = customer.CustomerID };
        context.Orders.Add(order);
        context.SaveChanges();

        // Commit if all succeeded
        transaction.Commit();
    }
    catch (Exception ex)
    {
        // Rollback on error
        transaction.Rollback();
        Console.WriteLine($"Transaction failed: {ex.Message}");
    }
}
```

---

### 6. Best Practices

```csharp
// 1. ✅ Use parameterized queries
var customers = context.Customers
    .FromSqlInterpolated($"SELECT * FROM Customers WHERE City = {city}");

// 2. ❌ Never concatenate user input
var query = $"SELECT * FROM Customers WHERE City = '{userInput}'";  // SQL INJECTION!

// 3. ✅ Return full entity structure
// Stored procedure must return ALL columns that match the entity

// 4. ✅ Use ExecuteSqlRaw for non-query operations
context.Database.ExecuteSqlRaw("DELETE FROM Logs WHERE LogDate < {0}", date);

// 5. ✅ Combine raw SQL with LINQ when appropriate
var result = context.Customers
    .FromSqlRaw("EXEC sp_GetActiveCustomers")
    .Where(c => c.City == "New York")
    .OrderBy(c => c.CustomerName)
    .ToList();

// 6. ✅ Use stored procedures for complex business logic
// Good for: Multi-step operations, complex joins, performance-critical queries

// 7. ✅ Map stored procedures to functions
modelBuilder.Entity<Customer>()
    .HasDbFunction(typeof(MyDbContext).GetMethod(nameof(MyDbContext.GetTopCustomers)));

public IQueryable<CustomerSummary> GetTopCustomers(int limit)
    => FromExpression(() => GetTopCustomers(limit));

// 8. ❌ Don't overuse raw SQL
// Use LINQ when possible - better type safety, refactoring support
```

---

## Questions 206-220 Complete!

✅ **Comprehensive Coverage:**
- Q206: Blocking in SQL Server
- Q207: Optimistic vs Pessimistic Locking
- Q208: Query Execution Plans
- Q209: Table Scan vs Index Seek
- Q210: Query Optimization Techniques
- Q211: SQL Server Profiler & DMVs
- Q212: Entity Framework Introduction
- Q213: Code-First vs Database-First
- Q214: DbContext and DbSet
- Q215: Lazy Loading vs Eager Loading vs Explicit Loading
- Q216: N+1 Query Problem and Solutions
- Q217: Tracking vs No-Tracking Queries
- Q218: Entity Framework Migrations
- Q219: EF Core Performance Best Practices
- Q220: Raw SQL and Stored Procedures

**All answers include:**
- ✅ Detailed code examples
- ✅ Real-world scenarios
- ✅ Best practices
- ✅ Performance considerations
- ✅ Common pitfalls and solutions
- ✅ SQL Server specific optimizations
- ✅ Entity Framework Core best practices

**Ready for the next section: Q221-Q240 or different topic!**
