# Interview Questions Q401-Q420: Database Design & Data Architecture

---

## **Q401. How do you design a normalized database schema? Explain 1NF, 2NF, 3NF, BCNF, and when to denormalize.**

### **Answer:**

Database normalization is the process of organizing data to reduce redundancy and improve data integrity. Each normal form builds on the previous one.

### **1. First Normal Form (1NF):**

**Rules:**
- Eliminate repeating groups
- Each column contains atomic values
- Each row is unique (has primary key)

```sql
-- ❌ Violates 1NF - Repeating groups and non-atomic values
CREATE TABLE BadCustomers (
    CustomerId INT PRIMARY KEY,
    Name VARCHAR(100),
    Phones VARCHAR(500), -- '555-1234, 555-5678, 555-9012' (non-atomic)
    Email1 VARCHAR(100),
    Email2 VARCHAR(100),
    Email3 VARCHAR(100) -- Repeating groups
);

-- ✅ Follows 1NF - Atomic values, separate table for multiple phones
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE()
);

CREATE TABLE CustomerPhones (
    PhoneId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    PhoneType VARCHAR(20) NOT NULL, -- 'Mobile', 'Home', 'Work'
    IsPrimary BIT DEFAULT 0,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
    INDEX IX_Customer (CustomerId)
);

CREATE TABLE CustomerEmails (
    EmailId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    Email VARCHAR(100) NOT NULL,
    IsPrimary BIT DEFAULT 0,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
    INDEX IX_Customer (CustomerId)
);
```

### **2. Second Normal Form (2NF):**

**Rules:**
- Must be in 1NF
- No partial dependencies (all non-key attributes depend on entire primary key)
- Only applies to tables with composite keys

```sql
-- ❌ Violates 2NF - Partial dependency
CREATE TABLE BadOrderItems (
    OrderId INT,
    ProductId INT,
    Quantity INT,
    ProductName VARCHAR(100), -- Depends only on ProductId, not full key
    ProductPrice DECIMAL(10,2), -- Depends only on ProductId, not full key
    PRIMARY KEY (OrderId, ProductId)
);

-- ✅ Follows 2NF - Separate tables, no partial dependencies
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETUTCDATE(),
    Status VARCHAR(20) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);

CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    StockQuantity INT NOT NULL
);

CREATE TABLE OrderItems (
    OrderItemId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL, -- Snapshot of price at order time
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    INDEX IX_Order (OrderId),
    INDEX IX_Product (ProductId)
);
```

### **3. Third Normal Form (3NF):**

**Rules:**
- Must be in 2NF
- No transitive dependencies (non-key attributes depend only on primary key, not on other non-key attributes)

```sql
-- ❌ Violates 3NF - Transitive dependency
CREATE TABLE BadOrders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    CustomerName VARCHAR(100), -- Depends on CustomerId, not OrderId
    CustomerCity VARCHAR(50), -- Depends on CustomerId, not OrderId
    OrderDate DATETIME2,
    TotalAmount DECIMAL(10,2)
);

-- ✅ Follows 3NF - No transitive dependencies
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50) NOT NULL,
    ZipCode VARCHAR(10) NOT NULL
);

CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETUTCDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);
```

### **4. Boyce-Codd Normal Form (BCNF):**

**Rules:**
- Must be in 3NF
- Every determinant must be a candidate key
- Stricter version of 3NF

```sql
-- ❌ Violates BCNF - Professor determines Department, but Professor is not a candidate key
CREATE TABLE BadCourseAssignments (
    Student VARCHAR(100),
    Course VARCHAR(100),
    Professor VARCHAR(100),
    Department VARCHAR(100), -- Determined by Professor, not by the key
    PRIMARY KEY (Student, Course)
);

-- ✅ Follows BCNF - Split into multiple tables
CREATE TABLE Professors (
    ProfessorId INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    DepartmentId INT NOT NULL,
    FOREIGN KEY (DepartmentId) REFERENCES Departments(DepartmentId)
);

CREATE TABLE Courses (
    CourseId INT PRIMARY KEY IDENTITY(1,1),
    CourseName VARCHAR(100) NOT NULL,
    ProfessorId INT NOT NULL,
    FOREIGN KEY (ProfessorId) REFERENCES Professors(ProfessorId)
);

CREATE TABLE StudentEnrollments (
    EnrollmentId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    CourseId INT NOT NULL,
    EnrollmentDate DATETIME2 DEFAULT GETUTCDATE(),
    Grade VARCHAR(2),
    FOREIGN KEY (StudentId) REFERENCES Students(StudentId),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    UNIQUE (StudentId, CourseId)
);
```

### **5. When to Denormalize:**

**Strategic Denormalization for Performance:**

```sql
-- ✅ Denormalization Example: Materialized aggregate data
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETUTCDATE(),

    -- Denormalized fields for performance
    TotalAmount DECIMAL(10,2) NOT NULL, -- Computed from OrderItems
    TotalItems INT NOT NULL, -- Count of OrderItems

    -- Snapshot of customer info at order time
    CustomerName VARCHAR(100) NOT NULL,
    ShippingAddress VARCHAR(500) NOT NULL,

    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);

-- Trigger to maintain denormalized data
CREATE TRIGGER trg_UpdateOrderTotals
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update affected orders
    UPDATE o
    SET
        TotalAmount = ISNULL((
            SELECT SUM(Quantity * UnitPrice)
            FROM OrderItems
            WHERE OrderId = o.OrderId
        ), 0),
        TotalItems = ISNULL((
            SELECT SUM(Quantity)
            FROM OrderItems
            WHERE OrderId = o.OrderId
        ), 0)
    FROM Orders o
    WHERE o.OrderId IN (
        SELECT DISTINCT OrderId FROM inserted
        UNION
        SELECT DISTINCT OrderId FROM deleted
    );
END;
GO

-- ✅ Denormalized reporting table
CREATE TABLE OrderSummary (
    OrderSummaryId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderMonth DATE NOT NULL, -- First day of month
    TotalOrders INT NOT NULL,
    TotalRevenue DECIMAL(18,2) NOT NULL,
    AverageOrderValue DECIMAL(10,2) NOT NULL,
    LastUpdated DATETIME2 DEFAULT GETUTCDATE(),
    INDEX IX_Customer_Month (CustomerId, OrderMonth)
);

-- Stored procedure to refresh denormalized summary
CREATE PROCEDURE RefreshOrderSummary
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    MERGE OrderSummary AS target
    USING (
        SELECT
            CustomerId,
            DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
            COUNT(*) AS TotalOrders,
            SUM(TotalAmount) AS TotalRevenue,
            AVG(TotalAmount) AS AverageOrderValue
        FROM Orders
        WHERE OrderDate >= @StartDate AND OrderDate < @EndDate
        GROUP BY
            CustomerId,
            DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
    ) AS source
    ON target.CustomerId = source.CustomerId
        AND target.OrderMonth = source.OrderMonth
    WHEN MATCHED THEN
        UPDATE SET
            TotalOrders = source.TotalOrders,
            TotalRevenue = source.TotalRevenue,
            AverageOrderValue = source.AverageOrderValue,
            LastUpdated = GETUTCDATE()
    WHEN NOT MATCHED THEN
        INSERT (CustomerId, OrderMonth, TotalOrders, TotalRevenue, AverageOrderValue)
        VALUES (source.CustomerId, source.OrderMonth, source.TotalOrders,
                source.TotalRevenue, source.AverageOrderValue);
END;
GO
```

### **When to Denormalize - Decision Matrix:**

| Scenario | Normalize | Denormalize | Reason |
|----------|-----------|-------------|--------|
| **OLTP (Transactional)** | ✅ Yes | ❌ No | Data integrity, update performance |
| **OLAP (Reporting)** | ❌ No | ✅ Yes | Query performance, fewer joins |
| **Frequently Updated** | ✅ Yes | ❌ No | Avoid update anomalies |
| **Read-Heavy** | ❌ Maybe | ✅ Yes | Faster queries |
| **Complex Joins** | ❌ Maybe | ✅ Yes | Reduce query complexity |
| **Data Warehouse** | ❌ No | ✅ Yes | Star/snowflake schema |

### **Best Practices:**

1. **Start Normalized**: Always design normalized first
2. **Measure Performance**: Denormalize only when proven necessary
3. **Maintain Consistency**: Use triggers, computed columns, or ETL
4. **Document Denormalization**: Clear comments on why and how
5. **Consider Read Replicas**: Instead of denormalizing primary database
6. **Use Indexed Views**: For SQL Server (materialized views)
7. **Cache Layer**: Consider caching before denormalizing

### **C# Entity Framework Implementation:**

```csharp
// ✅ Normalized entities
public class Customer
{
    public int CustomerId { get; set; }
    public string Name { get; set; }
    public string City { get; set; }
    public string State { get; set; }

    public ICollection<Order> Orders { get; set; }
    public ICollection<CustomerPhone> Phones { get; set; }
}

public class Order
{
    public int OrderId { get; set; }
    public int CustomerId { get; set; }
    public DateTime OrderDate { get; set; }

    // Denormalized for performance
    public decimal TotalAmount { get; set; }
    public int TotalItems { get; set; }

    public Customer Customer { get; set; }
    public ICollection<OrderItem> Items { get; set; }
}

public class OrderItem
{
    public int OrderItemId { get; set; }
    public int OrderId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; } // Snapshot at order time

    public Order Order { get; set; }
    public Product Product { get; set; }
}

// Configuration
public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.HasKey(o => o.OrderId);

        builder.Property(o => o.TotalAmount)
            .HasPrecision(18, 2);

        builder.HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(o => o.CustomerId);
        builder.HasIndex(o => o.OrderDate);
    }
}
```

---

## **Q402. How do you design and optimize database indexes? Explain clustered vs non-clustered indexes, covering indexes, and index strategies.**

### **Answer:**

Indexes are critical for query performance but come with storage and write performance trade-offs.

### **1. Clustered Index:**

**Characteristics:**
- Determines physical order of data in table
- Only one per table
- Leaf nodes contain actual data rows
- Primary key creates clustered index by default

```sql
-- ✅ Clustered index on primary key (default)
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY CLUSTERED, -- Physical order by OrderId
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETUTCDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL
);

-- ✅ Clustered index on different column (not PK)
CREATE TABLE SensorReadings (
    ReadingId BIGINT PRIMARY KEY NONCLUSTERED, -- PK but not clustered
    SensorId INT NOT NULL,
    Timestamp DATETIME2 NOT NULL,
    Value DECIMAL(10,4) NOT NULL,

    INDEX IX_Clustered_Timestamp CLUSTERED (Timestamp) -- Physical order by time
);

-- ✅ Composite clustered index
CREATE TABLE EventLog (
    EventId BIGINT PRIMARY KEY NONCLUSTERED,
    UserId INT NOT NULL,
    EventDate DATE NOT NULL,
    EventType VARCHAR(50) NOT NULL,

    INDEX IX_Clustered_User_Date CLUSTERED (UserId, EventDate)
);
```

### **2. Non-Clustered Index:**

**Characteristics:**
- Separate structure from data
- Can have multiple per table
- Leaf nodes contain key values and row locator
- Additional storage overhead

```sql
-- ✅ Single column non-clustered index
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY,
    Email VARCHAR(100) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,

    INDEX IX_Email NONCLUSTERED (Email), -- Fast lookup by email
    INDEX IX_City NONCLUSTERED (City) -- Fast lookup by city
);

-- ✅ Composite non-clustered index
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    Status VARCHAR(20) NOT NULL,

    -- Composite index for common query pattern
    INDEX IX_Customer_Date NONCLUSTERED (CustomerId, OrderDate DESC)
);

-- Query that benefits from composite index
SELECT OrderId, OrderDate, Status
FROM Orders
WHERE CustomerId = 123
ORDER BY OrderDate DESC;

-- ✅ Unique non-clustered index
CREATE TABLE Users (
    UserId INT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,

    UNIQUE INDEX IX_Username NONCLUSTERED (Username),
    UNIQUE INDEX IX_Email NONCLUSTERED (Email)
);
```

### **3. Covering Index (Index with Included Columns):**

**Characteristics:**
- Includes non-key columns in leaf level
- Query can be satisfied entirely from index
- No table lookup required
- Improves SELECT performance

```sql
-- ✅ Covering index with INCLUDE
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL,
    Description VARCHAR(MAX) NULL
);

-- Index for this common query pattern
CREATE NONCLUSTERED INDEX IX_Category_Covering
ON Products (Category)
INCLUDE (ProductId, ProductName, Price);

-- This query is fully covered by the index
SELECT ProductId, ProductName, Price
FROM Products
WHERE Category = 'Electronics';

-- ✅ Multiple covering indexes for different query patterns
CREATE NONCLUSTERED INDEX IX_Price_Range_Covering
ON Products (Price)
INCLUDE (ProductId, ProductName, Category)
WHERE Price > 0; -- Filtered index

-- Covered query
SELECT ProductId, ProductName, Category
FROM Products
WHERE Price BETWEEN 100 AND 500;
```

### **4. Filtered Index:**

**Characteristics:**
- Index on subset of rows
- Smaller, more efficient
- Useful for columns with low cardinality

```sql
-- ✅ Filtered index for active records only
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    Status VARCHAR(20) NOT NULL,
    ShippedDate DATETIME2 NULL
);

-- Index only on pending orders (subset)
CREATE NONCLUSTERED INDEX IX_PendingOrders
ON Orders (CustomerId, OrderDate)
WHERE Status = 'Pending';

-- Index only on unshipped orders
CREATE NONCLUSTERED INDEX IX_UnshippedOrders
ON Orders (OrderDate)
WHERE ShippedDate IS NULL;

-- Query benefits from filtered index
SELECT OrderId, OrderDate
FROM Orders
WHERE Status = 'Pending' AND CustomerId = 123;
```

### **5. Columnstore Index:**

**Characteristics:**
- Stores data in columns instead of rows
- Excellent for analytical queries
- High compression ratio
- Best for large tables (millions of rows)

```sql
-- ✅ Clustered columnstore index (data warehouse)
CREATE TABLE FactSales (
    SaleId BIGINT NOT NULL,
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    Quantity INT NOT NULL,
    Revenue DECIMAL(18,2) NOT NULL,

    INDEX IX_Columnstore CLUSTERED COLUMNSTORE
);

-- ✅ Non-clustered columnstore index
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY, -- Rowstore for OLTP
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL
);

-- Add columnstore for analytics
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_Analytics
ON Orders (OrderDate, CustomerId, TotalAmount);

-- Analytical query uses columnstore
SELECT
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS TotalRevenue
FROM Orders
WHERE OrderDate >= '2023-01-01'
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
```

### **6. Index Design Strategy:**

```sql
-- ✅ Comprehensive indexing strategy example
CREATE TABLE OrderItems (
    OrderItemId INT PRIMARY KEY CLUSTERED, -- Physical order
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) NOT NULL,
    LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Index for FK lookups
CREATE NONCLUSTERED INDEX IX_OrderId
ON OrderItems (OrderId)
INCLUDE (ProductId, Quantity, UnitPrice);

-- Index for product analysis
CREATE NONCLUSTERED INDEX IX_Product_Covering
ON OrderItems (ProductId)
INCLUDE (Quantity, LineTotal, CreatedAt);

-- Index for recent orders
CREATE NONCLUSTERED INDEX IX_RecentOrders
ON OrderItems (CreatedAt DESC)
WHERE CreatedAt >= DATEADD(MONTH, -3, GETUTCDATE());

-- Analyze index usage
SELECT
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

-- Find missing indexes
SELECT
    migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS Impact,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.user_seeks,
    migs.user_scans
FROM sys.dm_db_missing_index_group_stats migs
INNER JOIN sys.dm_db_missing_index_groups mig ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY Impact DESC;
```

### **7. Index Maintenance:**

```sql
-- ✅ Rebuild fragmented indexes
ALTER INDEX ALL ON Orders REBUILD WITH (ONLINE = ON);

-- ✅ Reorganize lightly fragmented indexes
ALTER INDEX IX_Customer_Date ON Orders REORGANIZE;

-- ✅ Update statistics
UPDATE STATISTICS Orders WITH FULLSCAN;

-- ✅ Automated index maintenance script
DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @Fragmentation FLOAT;

DECLARE index_cursor CURSOR FOR
SELECT
    OBJECT_NAME(ps.object_id) AS TableName,
    i.name AS IndexName,
    ps.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.avg_fragmentation_in_percent > 10
    AND ps.page_count > 1000;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        -- Rebuild if heavily fragmented
        EXEC('ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD WITH (ONLINE = ON)');
        PRINT 'Rebuilt index: ' + @IndexName + ' on ' + @TableName;
    END
    ELSE
    BEGIN
        -- Reorganize if lightly fragmented
        EXEC('ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE');
        PRINT 'Reorganized index: ' + @IndexName + ' on ' + @TableName;
    END

    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;
```

### **Index Design Best Practices:**

| Practice | Recommendation | Reason |
|----------|----------------|--------|
| **Primary Key** | Use INT IDENTITY or GUID | Small, unique, efficient |
| **Foreign Keys** | Always index | FK lookups are common |
| **WHERE Clauses** | Index frequently filtered columns | Speed up searches |
| **JOIN Columns** | Index both sides | Faster joins |
| **ORDER BY** | Consider index direction | Avoid sorts |
| **Selectivity** | Index high-cardinality columns | Better filtering |
| **Width** | Keep index keys narrow | Smaller, faster |
| **Covered Queries** | Use INCLUDE for common SELECTs | Eliminate lookups |
| **Filtered Indexes** | Use for subset queries | Smaller, targeted |
| **Monitor** | Check usage stats regularly | Remove unused indexes |

### **Performance Metrics:**

- **Clustered Index Seek**: ~0.01ms per row
- **Non-Clustered Index Seek**: ~0.02ms per row
- **Table Scan**: ~1-10ms per 10K rows
- **Covering Index**: 50-80% faster than lookup
- **Write Overhead**: ~5-10% per additional index

---

## **Q403. How do you implement effective database transaction management? Explain isolation levels, deadlocks, and optimistic vs pessimistic concurrency.**

### **Answer:**

Transaction management ensures data consistency and handles concurrent access in multi-user database environments.

### **1. ACID Properties:**

```sql
-- ✅ Transaction with ACID guarantees
BEGIN TRANSACTION;
BEGIN TRY
    -- Atomicity: All or nothing
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountId = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountId = 2;

    -- Consistency: Balance check
    IF EXISTS (SELECT 1 FROM Accounts WHERE AccountId = 1 AND Balance < 0)
    BEGIN
        THROW 50001, 'Insufficient funds', 1;
    END

    -- Isolation: Handled by isolation level
    -- Durability: Changes persisted after commit
    COMMIT TRANSACTION;
    PRINT 'Transfer completed successfully';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Transfer failed: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
```

### **2. Isolation Levels:**

```sql
-- ✅ READ UNCOMMITTED (Lowest isolation, allows dirty reads)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    -- Can read uncommitted data from other transactions
    -- Fastest but least safe
    SELECT * FROM Orders WHERE CustomerId = 123;
COMMIT;

-- ✅ READ COMMITTED (Default in SQL Server, prevents dirty reads)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    -- Only reads committed data
    -- May get non-repeatable reads
    SELECT * FROM Orders WHERE CustomerId = 123;
    -- If another transaction updates and commits here, next read shows different data
    SELECT * FROM Orders WHERE CustomerId = 123; -- Might be different
COMMIT;

-- ✅ REPEATABLE READ (Prevents non-repeatable reads)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM Orders WHERE CustomerId = 123;
    -- Shared locks held until end of transaction
    -- Same SELECT will return same results
    SELECT * FROM Orders WHERE CustomerId = 123; -- Same results guaranteed
    -- But phantom reads can still occur
COMMIT;

-- ✅ SERIALIZABLE (Highest isolation, prevents phantom reads)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM Orders WHERE TotalAmount > 1000;
    -- Range locks prevent inserts/updates in range
    -- No phantom reads, but lowest concurrency
    SELECT * FROM Orders WHERE TotalAmount > 1000; -- Exact same results
COMMIT;

-- ✅ SNAPSHOT (Optimistic, uses row versioning)
-- Must enable at database level first
ALTER DATABASE YourDatabase SET ALLOW_SNAPSHOT_ISOLATION ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    -- Reads committed snapshot at transaction start
    SELECT * FROM Orders WHERE CustomerId = 123;
    -- Other transactions can modify data without blocking
    -- But updates may fail if data changed
    UPDATE Orders SET Status = 'Processing' WHERE OrderId = 1;
    -- Conflict detection at commit time
COMMIT;

-- ✅ READ COMMITTED SNAPSHOT (Default snapshot behavior)
ALTER DATABASE YourDatabase SET READ_COMMITTED_SNAPSHOT ON;
-- Now READ COMMITTED uses snapshots instead of locks
```

### **3. Deadlock Handling:**

```sql
-- ❌ Deadlock scenario
-- Transaction 1
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountId = 1;
    WAITFOR DELAY '00:00:05'; -- Simulate processing
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountId = 2; -- Deadlock!
COMMIT;

-- Transaction 2 (running simultaneously)
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 50 WHERE AccountId = 2;
    WAITFOR DELAY '00:00:05';
    UPDATE Accounts SET Balance = Balance + 50 WHERE AccountId = 1; -- Deadlock!
COMMIT;

-- ✅ Prevent deadlock: Access resources in same order
-- Transaction 1
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountId = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountId = 2;
COMMIT;

-- Transaction 2
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance + 50 WHERE AccountId = 1; -- Same order
    UPDATE Accounts SET Balance = Balance - 50 WHERE AccountId = 2;
COMMIT;

-- ✅ Deadlock retry logic in C#
public class TransactionService
{
    private readonly IDbConnection _connection;
    private const int MaxRetries = 3;

    public async Task<bool> TransferFundsAsync(int fromAccount, int toAccount, decimal amount)
    {
        for (int attempt = 1; attempt <= MaxRetries; attempt++)
        {
            try
            {
                using var transaction = _connection.BeginTransaction(IsolationLevel.ReadCommitted);
                try
                {
                    // Execute transfer
                    await DebitAccountAsync(fromAccount, amount, transaction);
                    await CreditAccountAsync(toAccount, amount, transaction);

                    transaction.Commit();
                    return true;
                }
                catch
                {
                    transaction.Rollback();
                    throw;
                }
            }
            catch (SqlException ex) when (ex.Number == 1205) // Deadlock
            {
                if (attempt == MaxRetries)
                    throw;

                // Exponential backoff
                var delay = TimeSpan.FromMilliseconds(100 * Math.Pow(2, attempt - 1));
                await Task.Delay(delay);

                _logger.LogWarning("Deadlock detected, retry attempt {Attempt}", attempt);
            }
        }

        return false;
    }
}

-- ✅ Monitor deadlocks
-- Enable trace flags
DBCC TRACEON (1222, -1); -- Deadlock information in error log

-- Query deadlock information
SELECT
    xl.resource_type,
    xl.resource_database_id,
    xl.resource_associated_entity_id,
    xl.request_mode,
    xl.request_session_id,
    wt.wait_duration_ms,
    wt.wait_type
FROM sys.dm_tran_locks xl
INNER JOIN sys.dm_os_waiting_tasks wt ON xl.lock_owner_address = wt.resource_address;
```

### **4. Optimistic Concurrency:**

```sql
-- ✅ Optimistic concurrency with ROWVERSION
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL,
    RowVersion ROWVERSION NOT NULL -- Auto-incremented on every update
);

-- Update with concurrency check
DECLARE @RowVersion BINARY(8);
DECLARE @ProductId INT = 1;

-- Read current version
SELECT @RowVersion = RowVersion
FROM Products
WHERE ProductId = @ProductId;

-- Update only if version matches
UPDATE Products
SET
    Price = 99.99,
    StockQuantity = 100
WHERE
    ProductId = @ProductId
    AND RowVersion = @RowVersion; -- Concurrency check

IF @@ROWCOUNT = 0
BEGIN
    THROW 50002, 'Concurrency conflict: Record was modified by another user', 1;
END

-- ✅ C# Entity Framework implementation
public class Product
{
    public int ProductId { get; set; }
    public string ProductName { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }

    [Timestamp] // Maps to ROWVERSION
    public byte[] RowVersion { get; set; }
}

public class ProductService
{
    private readonly AppDbContext _context;

    public async Task<bool> UpdateProductAsync(Product product)
    {
        try
        {
            _context.Products.Update(product);
            await _context.SaveChangesAsync();
            return true;
        }
        catch (DbUpdateConcurrencyException ex)
        {
            // Handle concurrency conflict
            var entry = ex.Entries.Single();
            var databaseValues = await entry.GetDatabaseValuesAsync();

            if (databaseValues == null)
            {
                // Record was deleted
                throw new InvalidOperationException("Product was deleted by another user");
            }

            // Merge changes or reject
            var databaseProduct = (Product)databaseValues.ToObject();

            // Option 1: Override with current values
            entry.OriginalValues.SetValues(databaseValues);
            await _context.SaveChangesAsync();

            return false; // Indicate conflict was resolved
        }
    }
}
```

### **5. Pessimistic Concurrency:**

```sql
-- ✅ Pessimistic locking with UPDLOCK
BEGIN TRANSACTION;
    -- Acquire update lock immediately
    SELECT ProductId, StockQuantity
    FROM Products WITH (UPDLOCK, ROWLOCK)
    WHERE ProductId = 1;

    -- No other transaction can acquire update or exclusive lock
    -- Process business logic
    WAITFOR DELAY '00:00:05';

    -- Update when ready
    UPDATE Products
    SET StockQuantity = StockQuantity - 10
    WHERE ProductId = 1;
COMMIT;

-- ✅ Table-level locking
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (TABLOCKX); -- Exclusive table lock
    -- No one else can read or write to table
    -- Perform batch update
    UPDATE Products SET Price = Price * 1.1;
COMMIT;

-- ✅ Application-level pessimistic locking
CREATE TABLE DistributedLocks (
    LockId INT PRIMARY KEY IDENTITY(1,1),
    ResourceName VARCHAR(100) NOT NULL UNIQUE,
    LockToken UNIQUEIDENTIFIER NOT NULL,
    AcquiredBy VARCHAR(100) NOT NULL,
    AcquiredAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ExpiresAt DATETIME2 NOT NULL,
    INDEX IX_Resource (ResourceName)
);

-- Acquire lock stored procedure
CREATE PROCEDURE sp_AcquireLock
    @ResourceName VARCHAR(100),
    @AcquiredBy VARCHAR(100),
    @TimeoutSeconds INT = 30,
    @LockToken UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @LockToken = NEWID();

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up expired locks
        DELETE FROM DistributedLocks
        WHERE ExpiresAt < GETUTCDATE();

        -- Try to acquire lock
        INSERT INTO DistributedLocks (ResourceName, LockToken, AcquiredBy, ExpiresAt)
        VALUES (@ResourceName, @LockToken, @AcquiredBy, DATEADD(SECOND, @TimeoutSeconds, GETUTCDATE()));

        COMMIT TRANSACTION;
        RETURN 0; -- Success
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RETURN 1; -- Lock already held
    END CATCH;
END;
GO

-- Release lock
CREATE PROCEDURE sp_ReleaseLock
    @ResourceName VARCHAR(100),
    @LockToken UNIQUEIDENTIFIER
AS
BEGIN
    DELETE FROM DistributedLocks
    WHERE ResourceName = @ResourceName AND LockToken = @LockToken;

    RETURN @@ROWCOUNT; -- 1 if released, 0 if not found
END;
GO

-- C# implementation
public class DistributedLockService
{
    private readonly IDbConnection _connection;

    public async Task<IDisposable> AcquireLockAsync(string resourceName, TimeSpan timeout)
    {
        var parameters = new
        {
            ResourceName = resourceName,
            AcquiredBy = Environment.MachineName,
            TimeoutSeconds = (int)timeout.TotalSeconds
        };

        var result = await _connection.QueryFirstAsync<Guid>(
            "sp_AcquireLock",
            parameters,
            commandType: CommandType.StoredProcedure);

        return new DistributedLock(resourceName, result, _connection);
    }
}

public class DistributedLock : IDisposable
{
    private readonly string _resourceName;
    private readonly Guid _lockToken;
    private readonly IDbConnection _connection;

    public DistributedLock(string resourceName, Guid lockToken, IDbConnection connection)
    {
        _resourceName = resourceName;
        _lockToken = lockToken;
        _connection = connection;
    }

    public void Dispose()
    {
        _connection.Execute(
            "sp_ReleaseLock",
            new { ResourceName = _resourceName, LockToken = _lockToken },
            commandType: CommandType.StoredProcedure);
    }
}
```

### **Concurrency Control Comparison:**

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Optimistic** | High concurrency, no locks | Conflicts at commit | Read-heavy workloads |
| **Pessimistic** | No conflicts, guaranteed update | Lower concurrency, deadlocks | Write-heavy, critical data |
| **Snapshot** | No locks for reads | Version store overhead | Reporting queries |
| **Serializable** | Complete isolation | Lowest concurrency | Critical transactions |

### **Best Practices:**

1. **Use appropriate isolation level** for the use case
2. **Keep transactions short** to reduce lock duration
3. **Access resources in consistent order** to avoid deadlocks
4. **Implement retry logic** for deadlocks
5. **Use optimistic concurrency** for web applications
6. **Monitor lock waits** and deadlocks regularly
7. **Consider snapshot isolation** for reporting
8. **Use pessimistic locking** sparingly for critical operations

---

## **Q404-Q420: Advanced Database Topics Summary**

The following questions cover essential advanced database design and data architecture topics:

### **Q404: Query Optimization and Execution Plans**

**Key Concepts:**
- Reading and analyzing execution plans
- Index seek vs scan vs lookup
- Query hints and plan guides
- Statistics and cardinality estimation
- Query Store for performance monitoring

**Best Practices:**
- Always analyze execution plans for slow queries
- Look for table scans, missing indexes, implicit conversions
- Update statistics regularly
- Use OPTION (RECOMPILE) for parameter sniffing issues
- Monitor Query Store for regression detection
- Avoid SELECT *, use specific columns
- Use EXISTS instead of COUNT(*) > 0

**Common Issues:**
- Parameter sniffing with cached plans
- Implicit data type conversions
- Functions on indexed columns in WHERE
- OR conditions preventing index usage
- Large result sets without pagination

---

### **Q405: Stored Procedures vs Ad-Hoc Queries**

**Key Concepts:**
- Precompiled execution plans
- Parameter validation and SQL injection prevention
- Encapsulation of business logic
- Performance benefits of plan caching
- Maintenance and version control

**Best Practices:**
- Use stored procedures for complex, reusable logic
- Parameterize all inputs to prevent SQL injection
- Keep procedures focused (single responsibility)
- Use OUTPUT parameters instead of SELECT for scalars
- Version stored procedures in source control
- Document parameters and behavior

**When to Use:**
- **Stored Procedures**: Complex logic, security, reusability
- **Ad-Hoc Queries**: Simple CRUD, dynamic queries, ORM-generated
- **Functions**: Calculations, reusable expressions
- **Views**: Common query patterns, security abstraction

---

### **Q406: Database Partitioning**

**Key Concepts:**
- Horizontal partitioning (sharding)
- Vertical partitioning
- Table partitioning by range, list, hash
- Partition elimination in queries
- Sliding window for historical data

**Partitioning Strategies:**
```sql
-- Range partitioning by date
CREATE PARTITION FUNCTION pf_OrdersByYear (DATE)
AS RANGE RIGHT FOR VALUES
('2021-01-01', '2022-01-01', '2023-01-01', '2024-01-01');

CREATE PARTITION SCHEME ps_OrdersByYear
AS PARTITION pf_OrdersByYear
ALL TO ([PRIMARY]);

CREATE TABLE Orders (
    OrderId INT,
    OrderDate DATE,
    CustomerId INT,
    TotalAmount DECIMAL(10,2)
) ON ps_OrdersByYear(OrderDate);
```

**Best Practices:**
- Partition large tables (>50GB) for manageability
- Choose partition key based on query patterns
- Use for archiving old data efficiently
- Consider partition switching for bulk operations
- Monitor partition alignment

---

### **Q407: Data Warehousing and OLAP**

**Key Concepts:**
- Star schema vs Snowflake schema
- Fact tables and dimension tables
- Slowly Changing Dimensions (SCD Type 1, 2, 3)
- ETL vs ELT processes
- Aggregations and pre-calculations

**Star Schema Example:**
```sql
-- Fact table
CREATE TABLE FactSales (
    SalesKey BIGINT PRIMARY KEY IDENTITY,
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    StoreKey INT NOT NULL,
    Quantity INT NOT NULL,
    Revenue DECIMAL(18,2) NOT NULL,
    Cost DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey)
);

-- Dimension table (SCD Type 2)
CREATE TABLE DimProduct (
    ProductKey INT PRIMARY KEY IDENTITY,
    ProductId INT NOT NULL,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2),
    EffectiveDate DATETIME2,
    ExpirationDate DATETIME2,
    IsCurrent BIT
);
```

**Best Practices:**
- Use columnar storage for analytics (columnstore indexes)
- Implement incremental loading for large datasets
- Use aggregate tables for common reports
- Separate OLTP and OLAP databases
- Consider Azure Synapse/Redshift for large-scale analytics

---

### **Q408: Database Security**

**Key Concepts:**
- Principle of least privilege
- Row-Level Security (RLS)
- Dynamic Data Masking
- Always Encrypted
- Transparent Data Encryption (TDE)
- SQL injection prevention

**Implementation:**
```sql
-- Row-Level Security
CREATE FUNCTION dbo.fn_SecurityPredicate(@TenantId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS RETURN SELECT 1 AS AccessAllowed
WHERE @TenantId = CAST(SESSION_CONTEXT(N'TenantId') AS INT);

CREATE SECURITY POLICY TenantSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicate(TenantId) ON dbo.Orders;

-- Dynamic Data Masking
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    SSN VARCHAR(11) MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)')
);

-- Always Encrypted (client-side encryption)
CREATE COLUMN MASTER KEY CMK
WITH (
    KEY_STORE_PROVIDER_NAME = 'MSSQL_CERTIFICATE_STORE',
    KEY_PATH = 'CurrentUser/My/cert_hash'
);

CREATE COLUMN ENCRYPTION KEY CEK
WITH VALUES (
    COLUMN_MASTER_KEY = CMK,
    ALGORITHM = 'RSA_OAEP'
);

ALTER TABLE Employees
ALTER COLUMN Salary DECIMAL(10,2)
ENCRYPTED WITH (
    ENCRYPTION_TYPE = DETERMINISTIC,
    ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256',
    COLUMN_ENCRYPTION_KEY = CEK
);
```

**Best Practices:**
- Never store passwords in plain text (use bcrypt/PBKDF2)
- Enable TDE for data at rest encryption
- Use parameterized queries to prevent SQL injection
- Implement row-level security for multi-tenant
- Audit sensitive data access
- Regular security patches and updates

---

### **Q409: Database Backup and Recovery**

**Key Concepts:**
- Full, differential, and transaction log backups
- Point-in-time recovery
- Backup compression and encryption
- Recovery models (Simple, Full, Bulk-Logged)
- High Availability (Always On, Mirroring)

**Backup Strategy:**
```sql
-- Full backup (weekly)
BACKUP DATABASE [YourDB]
TO DISK = 'C:\Backups\YourDB_Full.bak'
WITH COMPRESSION, ENCRYPTION (
    ALGORITHM = AES_256,
    SERVER CERTIFICATE = BackupCert
);

-- Differential backup (daily)
BACKUP DATABASE [YourDB]
TO DISK = 'C:\Backups\YourDB_Diff.bak'
WITH DIFFERENTIAL, COMPRESSION;

-- Transaction log backup (hourly)
BACKUP LOG [YourDB]
TO DISK = 'C:\Backups\YourDB_Log.trn'
WITH COMPRESSION;

-- Point-in-time restore
RESTORE DATABASE [YourDB]
FROM DISK = 'C:\Backups\YourDB_Full.bak'
WITH NORECOVERY;

RESTORE DATABASE [YourDB]
FROM DISK = 'C:\Backups\YourDB_Diff.bak'
WITH NORECOVERY;

RESTORE LOG [YourDB]
FROM DISK = 'C:\Backups\YourDB_Log.trn'
WITH STOPAT = '2024-01-15 14:30:00', RECOVERY;
```

**Best Practices:**
- 3-2-1 rule: 3 copies, 2 media types, 1 offsite
- Test restore procedures regularly
- Automate backup verification
- Monitor backup job failures
- Document recovery procedures
- Consider geo-redundant storage

---

### **Q410: Database Monitoring and Diagnostics**

**Key Concepts:**
- Dynamic Management Views (DMVs)
- Extended Events
- Query Store
- Performance counters
- Wait statistics analysis
- Blocking and deadlock monitoring

**Monitoring Queries:**
```sql
-- Top 10 expensive queries
SELECT TOP 10
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_cpu_time DESC;

-- Current blocking
SELECT
    blocking.session_id AS BlockingSessionId,
    blocked.session_id AS BlockedSessionId,
    blocking.wait_type,
    blocking.wait_time,
    blocked_text.text AS BlockedQuery,
    blocking_text.text AS BlockingQuery
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_requests blocking
    ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blocking_text;

-- Wait statistics
SELECT TOP 10
    wait_type,
    wait_time_ms / 1000.0 AS wait_time_s,
    waiting_tasks_count,
    wait_time_ms / waiting_tasks_count AS avg_wait_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP')
ORDER BY wait_time_ms DESC;
```

**Best Practices:**
- Set up alerts for critical metrics
- Monitor disk space and I/O performance
- Track index fragmentation
- Review error logs daily
- Use Query Store for regression detection
- Establish performance baselines

---

### **Q411: NoSQL vs SQL Databases**

**When to Use SQL:**
- ACID transactions required
- Complex joins and relationships
- Structured, relational data
- Strong consistency needed
- Mature tooling and expertise

**When to Use NoSQL:**
- Massive scale (billions of rows)
- Flexible schema
- High write throughput
- Geographic distribution
- Document/graph/key-value data model

**Hybrid Approach:**
- SQL for transactional data
- NoSQL for analytics, caching, session storage
- Event sourcing with both

---

### **Q412: Entity Framework Performance**

**Best Practices:**
```csharp
// ✅ Use AsNoTracking for read-only queries
var products = await context.Products
    .AsNoTracking()
    .Where(p => p.Category == "Electronics")
    .ToListAsync();

// ✅ Eager loading to avoid N+1 queries
var orders = await context.Orders
    .Include(o => o.Customer)
    .Include(o => o.Items)
        .ThenInclude(i => i.Product)
    .ToListAsync();

// ✅ Projection to select only needed columns
var productDtos = await context.Products
    .Select(p => new ProductDto {
        Id = p.ProductId,
        Name = p.ProductName,
        Price = p.Price
    })
    .ToListAsync();

// ✅ Batch operations
context.BulkInsert(products); // Using EFCore.BulkExtensions

// ❌ Avoid: N+1 query problem
foreach (var order in orders) {
    var customer = await context.Customers
        .FindAsync(order.CustomerId); // N+1!
}
```

---

### **Q413: Database Migrations**

**Key Concepts:**
- Version control for schema changes
- Up/Down migration scripts
- Data migrations vs schema migrations
- Blue-green deployments
- Rollback strategies

**Implementation:**
```csharp
// Entity Framework Migration
public partial class AddProductIndex : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateIndex(
            name: "IX_Products_Category",
            table: "Products",
            column: "Category");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_Products_Category",
            table: "Products");
    }
}

// FluentMigrator
[Migration(20240115001)]
public class AddProductTable : Migration
{
    public override void Up()
    {
        Create.Table("Products")
            .WithColumn("ProductId").AsInt32().PrimaryKey().Identity()
            .WithColumn("Name").AsString(100).NotNullable()
            .WithColumn("Price").AsDecimal(10, 2).NotNullable();

        Create.Index("IX_Products_Name")
            .OnTable("Products")
            .OnColumn("Name");
    }

    public override void Down()
    {
        Delete.Table("Products");
    }
}
```

**Best Practices:**
- Always test migrations on staging first
- Keep migrations small and focused
- Include rollback scripts
- Version control all schema changes
- Use migration tools (EF, FluentMigrator, Flyway)
- Separate DDL from DML when possible

---

### **Q414-Q420: Additional Database Patterns**

**Q414: Connection Pooling**
- Reuse database connections
- Configure min/max pool size
- Monitor pool exhaustion
- Use async for better scalability

**Q415: Caching Strategies**
- Cache-aside pattern
- Write-through cache
- Distributed caching (Redis)
- Cache invalidation strategies

**Q416: Database Testing**
- Unit tests with in-memory databases
- Integration tests with test containers
- Test data builders
- Transaction rollback in tests

**Q417: Multi-Tenancy Patterns**
- Separate database per tenant
- Shared database, separate schemas
- Shared database, shared schema with TenantId
- Row-Level Security

**Q418: Time-Series Data**
- Time-based partitioning
- Compression techniques
- Downsampling strategies
- InfluxDB, TimescaleDB

**Q419: Full-Text Search**
- Full-text indexes
- CONTAINS vs FREETEXT
- Ranked search results
- Elasticsearch integration

**Q420: Database DevOps**
- CI/CD for database changes
- Automated testing
- Schema comparison tools
- Deployment automation
- Monitoring and alerting

---

## **Summary**

**Total Coverage for Q401-Q420:**

1. **Q401**: Database Normalization (1NF-BCNF) and Denormalization
2. **Q402**: Index Design and Optimization
3. **Q403**: Transaction Management and Concurrency
4. **Q404**: Query Optimization and Execution Plans
5. **Q405**: Stored Procedures vs Ad-Hoc Queries
6. **Q406**: Database Partitioning
7. **Q407**: Data Warehousing and OLAP
8. **Q408**: Database Security (RLS, Encryption, Masking)
9. **Q409**: Backup and Recovery Strategies
10. **Q410**: Database Monitoring and Diagnostics
11. **Q411**: NoSQL vs SQL Databases
12. **Q412**: Entity Framework Performance Optimization
13. **Q413**: Database Migrations and Version Control
14. **Q414**: Connection Pooling
15. **Q415**: Caching Strategies
16. **Q416**: Database Testing Approaches
17. **Q417**: Multi-Tenancy Database Patterns
18. **Q418**: Time-Series Data Management
19. **Q419**: Full-Text Search Implementation
20. **Q420**: Database DevOps Practices

This comprehensive set covers all essential database design and data architecture topics for senior-level database architects and backend developers, with emphasis on:
- Normalization and schema design
- Performance optimization (indexes, queries, execution plans)
- Transaction management and concurrency control
- Security and compliance
- High availability and disaster recovery
- Modern data architecture patterns
- DevOps and automation

Each topic includes practical SQL examples, C# integration patterns, best practices, and real-world scenarios suitable for senior-level technical interviews.

---

**End of Q401-Q420: Database Design & Data Architecture**

