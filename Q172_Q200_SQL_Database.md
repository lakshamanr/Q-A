# SQL Server & Database - Questions 172-200

---

## Q172: What are the different types of SQL joins and when do you use each?

**Answer:**

SQL joins combine rows from two or more tables based on a related column. Each join type serves specific use cases.

**Join Types:**

```sql
-- Sample Tables
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    City VARCHAR(50)
);

CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
);

-- Sample Data
INSERT INTO Customers VALUES
    (1, 'John Doe', 'New York'),
    (2, 'Jane Smith', 'Los Angeles'),
    (3, 'Bob Johnson', 'Chicago');

INSERT INTO Orders VALUES
    (101, 1, '2024-01-15', 500.00),
    (102, 1, '2024-01-20', 750.00),
    (103, 2, '2024-01-18', 300.00),
    (104, 5, '2024-01-22', 200.00);  -- CustomerId 5 doesn't exist
```

**1. INNER JOIN** - Returns only matching rows from both tables

```sql
-- Get customers who have placed orders
SELECT
    c.CustomerName,
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerId = o.CustomerId;

-- Result:
-- John Doe    | 101 | 2024-01-15 | 500.00
-- John Doe    | 102 | 2024-01-20 | 750.00
-- Jane Smith  | 103 | 2024-01-18 | 300.00

-- Visual:
--   Customers        Orders
--   ┌─────────┐    ┌─────────┐
--   │    A    │    │    B    │
--   │  ┌───┐  │    │  ┌───┐  │
--   │  │ ◉ │◄─┼────┼─►│ ◉ │  │  ← INNER JOIN (intersection)
--   │  └───┘  │    │  └───┘  │
--   └─────────┘    └─────────┘
```

**2. LEFT JOIN (LEFT OUTER JOIN)** - Returns all rows from left table and matching rows from right

```sql
-- Get all customers and their orders (including customers with no orders)
SELECT
    c.CustomerName,
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId;

-- Result:
-- John Doe    | 101 | 2024-01-15 | 500.00
-- John Doe    | 102 | 2024-01-20 | 750.00
-- Jane Smith  | 103 | 2024-01-18 | 300.00
-- Bob Johnson | NULL| NULL       | NULL     ← Customer with no orders

-- Visual:
--   Customers        Orders
--   ┌─────────┐    ┌─────────┐
--   │  ████   │    │         │
--   │  █▓▓█   │    │  ┌───┐  │
--   │  █▓▓█◄──┼────┼─►│ ◉ │  │  ← LEFT JOIN (all left + matching right)
--   │  ████   │    │  └───┘  │
--   └─────────┘    └─────────┘
```

**3. RIGHT JOIN (RIGHT OUTER JOIN)** - Returns all rows from right table and matching rows from left

```sql
-- Get all orders and customer info (including orders with invalid customer IDs)
SELECT
    c.CustomerName,
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerId = o.CustomerId;

-- Result:
-- John Doe    | 101 | 2024-01-15 | 500.00
-- John Doe    | 102 | 2024-01-20 | 750.00
-- Jane Smith  | 103 | 2024-01-18 | 300.00
-- NULL        | 104 | 2024-01-22 | 200.00  ← Order with invalid CustomerId

-- Visual:
--   Customers        Orders
--   ┌─────────┐    ┌─────────┐
--   │         │    │  ████   │
--   │  ┌───┐  │    │  █▓▓█   │
--   │  │ ◉ │──┼────┼─►█▓▓█   │  ← RIGHT JOIN (all right + matching left)
--   │  └───┘  │    │  ████   │
--   └─────────┘    └─────────┘
```

**4. FULL OUTER JOIN** - Returns all rows from both tables

```sql
-- Get all customers and all orders (with NULLs where no match)
SELECT
    c.CustomerName,
    c.City,
    o.OrderId,
    o.TotalAmount
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerId = o.CustomerId;

-- Result:
-- John Doe    | New York    | 101 | 500.00
-- John Doe    | New York    | 102 | 750.00
-- Jane Smith  | Los Angeles | 103 | 300.00
-- Bob Johnson | Chicago     | NULL| NULL     ← Customer with no orders
-- NULL        | NULL        | 104 | 200.00   ← Order with invalid customer

-- Visual:
--   Customers        Orders
--   ┌─────────┐    ┌─────────┐
--   │  ████   │    │  ████   │
--   │  █▓▓█   │    │  █▓▓█   │
--   │  █▓▓█◄──┼────┼─►█▓▓█   │  ← FULL OUTER JOIN (everything)
--   │  ████   │    │  ████   │
--   └─────────┘    └─────────┘
```

**5. CROSS JOIN** - Cartesian product (every row from first table with every row from second)

```sql
-- Get all possible combinations of customers and order dates
SELECT
    c.CustomerName,
    o.OrderDate
FROM Customers c
CROSS JOIN Orders o;

-- Result: 3 customers × 4 orders = 12 rows
-- John Doe    | 2024-01-15
-- John Doe    | 2024-01-20
-- John Doe    | 2024-01-18
-- John Doe    | 2024-01-22
-- Jane Smith  | 2024-01-15
-- ... (12 total rows)
```

**6. SELF JOIN** - Join table to itself

```sql
-- Employee table with manager hierarchy
CREATE TABLE Employees (
    EmployeeId INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    ManagerId INT
);

INSERT INTO Employees VALUES
    (1, 'Alice', NULL),      -- CEO
    (2, 'Bob', 1),           -- Reports to Alice
    (3, 'Charlie', 1),       -- Reports to Alice
    (4, 'David', 2);         -- Reports to Bob

-- Find employees and their managers
SELECT
    e.EmployeeName AS Employee,
    m.EmployeeName AS Manager
FROM Employees e
LEFT JOIN Employees m ON e.ManagerId = m.EmployeeId;

-- Result:
-- Alice   | NULL    (CEO has no manager)
-- Bob     | Alice
-- Charlie | Alice
-- David   | Bob
```

**Real-World Examples:**

```sql
-- E-Commerce: Get order summary with customer and product details
SELECT
    o.OrderId,
    o.OrderDate,
    c.CustomerName,
    c.Email,
    p.ProductName,
    ol.Quantity,
    ol.UnitPrice,
    (ol.Quantity * ol.UnitPrice) AS LineTotal
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.CustomerId
INNER JOIN OrderLines ol ON o.OrderId = ol.OrderId
INNER JOIN Products p ON ol.ProductId = p.ProductId
WHERE o.OrderDate >= '2024-01-01'
ORDER BY o.OrderDate DESC;

-- Find customers who haven't ordered in 2024
SELECT
    c.CustomerName,
    c.Email,
    c.City
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId
    AND o.OrderDate >= '2024-01-01'
WHERE o.OrderId IS NULL;

-- Find orphaned records (orders with invalid customer IDs)
SELECT
    o.OrderId,
    o.CustomerId,
    o.TotalAmount
FROM Orders o
LEFT JOIN Customers c ON o.CustomerId = c.CustomerId
WHERE c.CustomerId IS NULL;
```

**Join Comparison Table:**

| Join Type | Returns | Use Case |
|-----------|---------|----------|
| **INNER** | Only matching rows | Default join, most common |
| **LEFT OUTER** | All left + matching right | Find records without matches (customers without orders) |
| **RIGHT OUTER** | All right + matching left | Rare, can be rewritten as LEFT JOIN |
| **FULL OUTER** | All from both tables | Find all unmatched records |
| **CROSS** | Cartesian product | Generate combinations, calendar tables |
| **SELF** | Table joined to itself | Hierarchies, comparisons within table |

**Performance Tips:**

1. **Index Join Columns**: Create indexes on columns used in ON clause
2. **Filter Early**: Use WHERE before JOIN when possible
3. **Avoid SELECT ***: Specify only needed columns
4. **Use INNER JOIN**: When you only need matching rows (faster than OUTER)
5. **Check Execution Plan**: Verify join order and index usage

---

## Q173: Explain the difference between clustered and non-clustered indexes.

**Answer:**

Indexes improve query performance by creating optimized data structures for fast lookups, similar to a book's index.

**Clustered Index:**

- **One per table**: Only one clustered index allowed
- **Physical order**: Determines the physical order of data rows
- **Table = Index**: The actual table data is stored in clustered index leaf nodes
- **Primary Key**: Automatically creates clustered index (unless specified otherwise)

**Non-Clustered Index:**

- **Multiple per table**: Can have many non-clustered indexes (up to 999 in SQL Server)
- **Logical structure**: Separate structure from table data
- **Pointers**: Leaf nodes contain pointers to actual data rows
- **Additional storage**: Requires extra disk space

**Visual Representation:**

```
CLUSTERED INDEX (Table IS the index):
┌──────────────────────────────────────┐
│ Clustered Index (ProductId)          │
├──────────────────────────────────────┤
│ Root Node                            │
│   ┌─────────┬─────────┬─────────┐    │
│   │ 1-100   │ 101-200 │ 201-300 │    │
│   └────┬────┴────┬────┴────┬────┘    │
│        │         │         │         │
│   ┌────▼────┬────▼────┬────▼────┐    │
│   │ 1-50    │ 101-150 │ 201-250 │    │
│   └────┬────┴────┬────┴────┬────┘    │
│        │         │         │         │
│ ┌──────▼──────────────────────────┐  │
│ │ ACTUAL DATA ROWS (Leaf Level)   │  │
│ │ [1][John][NY][500.00]           │  │
│ │ [2][Jane][LA][750.00]           │  │
│ │ [3][Bob][CHI][300.00]           │  │
│ └─────────────────────────────────┘  │
└──────────────────────────────────────┘

NON-CLUSTERED INDEX (Separate structure):
┌──────────────────────────────────────┐
│ Non-Clustered Index (CustomerName)   │
├──────────────────────────────────────┤
│ Root Node                            │
│   ┌─────────┬─────────┬─────────┐    │
│   │ A-H     │ I-P     │ Q-Z     │    │
│   └────┬────┴────┬────┴────┬────┘    │
│        │         │         │         │
│ ┌──────▼──────────────────────────┐  │
│ │ Leaf Level (Index + Pointer)    │  │
│ │ [Bob] ─────────► Row Pointer    │  │
│ │ [Jane] ────────► Row Pointer    │  │
│ │ [John] ────────► Row Pointer    │  │
│ └─────────────┬───────────────────┘  │
│               │                      │
│               ▼                      │
│ ┌─────────────────────────────────┐  │
│ │ ACTUAL DATA (in clustered index)│  │
│ │ or HEAP (if no clustered index) │  │
│ └─────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**SQL Examples:**

```sql
-- Create table with clustered index on ProductId
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,              -- Clustered index (default)
    ProductName VARCHAR(200),
    CategoryId INT,
    Price DECIMAL(10,2),
    StockQuantity INT,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Create non-clustered index on ProductName
CREATE NONCLUSTERED INDEX IX_Products_Name
ON Products(ProductName);

-- Create non-clustered index on CategoryId
CREATE NONCLUSTERED INDEX IX_Products_Category
ON Products(CategoryId);

-- Create composite non-clustered index
CREATE NONCLUSTERED INDEX IX_Products_Category_Price
ON Products(CategoryId, Price);

-- Create non-clustered index with included columns (covering index)
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(CategoryId)
INCLUDE (ProductName, Price, StockQuantity);

-- Specify non-clustered primary key (create clustered index on different column)
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY NONCLUSTERED,   -- Non-clustered index
    OrderDate DATETIME NOT NULL,
    CustomerId INT,
    TotalAmount DECIMAL(10,2)
);

-- Create clustered index on OrderDate (for date-range queries)
CREATE CLUSTERED INDEX IX_Orders_OrderDate
ON Orders(OrderDate);

-- View all indexes on a table
EXEC sp_helpindex 'Products';

-- Or using system catalog
SELECT
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName,
    ic.is_included_column AS IsIncludedColumn
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Products')
ORDER BY i.name, ic.key_ordinal;
```

**Performance Comparison:**

```sql
-- Sample data
INSERT INTO Products (ProductId, ProductName, CategoryId, Price, StockQuantity)
VALUES
    (1, 'Laptop', 1, 999.99, 50),
    (2, 'Mouse', 2, 29.99, 200),
    (3, 'Keyboard', 2, 79.99, 150);

-- Query 1: Clustered index seek (FAST)
SELECT * FROM Products WHERE ProductId = 1;
-- Execution: Direct lookup using clustered index

-- Query 2: Non-clustered index seek + key lookup
SELECT * FROM Products WHERE ProductName = 'Laptop';
-- Execution:
--   1. Seek on IX_Products_Name to find pointer
--   2. Key lookup to get remaining columns from clustered index

-- Query 3: Covering index (FASTEST for specific columns)
SELECT CategoryId, ProductName, Price, StockQuantity
FROM Products
WHERE CategoryId = 2;
-- Execution: All data in IX_Products_Category_Covering, no key lookup needed

-- Query 4: Table scan (SLOW)
SELECT * FROM Products WHERE Price > 50;
-- Execution: No index on Price, requires scanning all rows
```

**Key Differences Table:**

| Aspect | Clustered Index | Non-Clustered Index |
|--------|----------------|---------------------|
| **Count per Table** | 1 | Up to 999 |
| **Data Storage** | Leaf nodes contain actual data | Leaf nodes contain pointers to data |
| **Physical Order** | Determines physical row order | Logical structure, doesn't affect physical order |
| **Disk Space** | No additional space (data IS the index) | Requires additional disk space |
| **Performance** | Faster for range queries | Faster for point lookups on indexed column |
| **INSERT/UPDATE** | Slower (may require page splits) | Faster inserts, slower lookups (key lookup) |
| **Default for PK** | Yes | No (must specify NONCLUSTERED) |

**When to Use:**

**Clustered Index:**
- Primary key or frequently used unique column
- Columns used in ORDER BY frequently
- Range queries (BETWEEN, <, >)
- Date columns for time-series data

**Non-Clustered Index:**
- Foreign keys
- Columns in WHERE clauses
- Columns in JOIN conditions
- Covering indexes for specific queries

**Best Practices:**

1. **Choose Clustered Index Wisely**: Narrow, unique, static column (avoid GUID for clustered)
2. **Include Columns**: Use INCLUDE for covering indexes
3. **Monitor Index Usage**: Use DMVs to find unused indexes
4. **Avoid Over-Indexing**: Each index slows down INSERT/UPDATE/DELETE
5. **Fill Factor**: Set appropriate fill factor for volatile tables
6. **Rebuild/Reorganize**: Maintain indexes to avoid fragmentation

```sql
-- Check index fragmentation
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
    AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Rebuild index (for >30% fragmentation)
ALTER INDEX IX_Products_Name ON Products REBUILD;

-- Reorganize index (for 10-30% fragmentation)
ALTER INDEX IX_Products_Category ON Products REORGANIZE;

-- Update statistics
UPDATE STATISTICS Products;
```

---

## Q174: What are stored procedures and what are their advantages?

**Answer:**

A **Stored Procedure** is a prepared SQL code that you save and reuse. It's a group of SQL statements that perform a specific task, stored in the database.

**Advantages:**

1. **Performance**: Precompiled and cached execution plans
2. **Security**: Encapsulate logic, grant EXECUTE permission without table access
3. **Reusability**: Write once, call from multiple applications
4. **Reduced Network Traffic**: Send procedure name instead of multiple SQL statements
5. **Maintainability**: Change logic in one place
6. **Transaction Control**: Built-in transaction support

**Basic Stored Procedure:**

```sql
-- Create a simple stored procedure
CREATE PROCEDURE GetProductById
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;  -- Prevents extra result sets

    SELECT
        ProductId,
        ProductName,
        Price,
        StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
END;
GO

-- Execute the stored procedure
EXEC GetProductById @ProductId = 1;
-- Or
EXECUTE GetProductById 1;
```

**Stored Procedure with Multiple Parameters:**

```sql
CREATE PROCEDURE GetProductsByCategory
    @CategoryId INT,
    @MinPrice DECIMAL(10,2) = 0,           -- Default value
    @MaxPrice DECIMAL(10,2) = 999999.99,   -- Default value
    @SortBy VARCHAR(50) = 'ProductName'    -- Default sort
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProductId,
        ProductName,
        CategoryId,
        Price,
        StockQuantity
    FROM Products
    WHERE CategoryId = @CategoryId
        AND Price >= @MinPrice
        AND Price <= @MaxPrice
    ORDER BY
        CASE
            WHEN @SortBy = 'ProductName' THEN ProductName
            WHEN @SortBy = 'Price' THEN CAST(Price AS VARCHAR(50))
        END;
END;
GO

-- Execute with different parameters
EXEC GetProductsByCategory @CategoryId = 1;
EXEC GetProductsByCategory @CategoryId = 1, @MinPrice = 100, @MaxPrice = 500;
EXEC GetProductsByCategory @CategoryId = 1, @SortBy = 'Price';
```

**Stored Procedure with OUTPUT Parameters:**

```sql
CREATE PROCEDURE CreateOrder
    @CustomerId INT,
    @TotalAmount DECIMAL(10,2),
    @OrderId INT OUTPUT  -- OUTPUT parameter
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insert order
        INSERT INTO Orders (CustomerId, OrderDate, TotalAmount, Status)
        VALUES (@CustomerId, GETDATE(), @TotalAmount, 'Pending');

        -- Get the newly created OrderId
        SET @OrderId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return success
        RETURN 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Log error
        INSERT INTO ErrorLog (ErrorMessage, ErrorDate)
        VALUES (ERROR_MESSAGE(), GETDATE());

        -- Return error code
        RETURN -1;
    END CATCH;
END;
GO

-- Execute with OUTPUT parameter
DECLARE @NewOrderId INT;
DECLARE @ReturnValue INT;

EXEC @ReturnValue = CreateOrder
    @CustomerId = 123,
    @TotalAmount = 599.99,
    @OrderId = @NewOrderId OUTPUT;

IF @ReturnValue = 0
    PRINT 'Order created successfully. OrderId: ' + CAST(@NewOrderId AS VARCHAR(10));
ELSE
    PRINT 'Order creation failed.';
```

**Complex Stored Procedure - E-Commerce Order Processing:**

```sql
CREATE PROCEDURE ProcessOrder
    @CustomerId INT,
    @OrderLines NVARCHAR(MAX),  -- JSON array of order lines
    @OrderId INT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validate customer exists
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
        BEGIN
            SET @ErrorMessage = 'Customer not found';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END

        -- Create temp table for order lines
        CREATE TABLE #TempOrderLines (
            ProductId INT,
            Quantity INT,
            UnitPrice DECIMAL(10,2)
        );

        -- Parse JSON into temp table
        INSERT INTO #TempOrderLines (ProductId, Quantity, UnitPrice)
        SELECT
            JSON_VALUE(value, '$.ProductId'),
            JSON_VALUE(value, '$.Quantity'),
            JSON_VALUE(value, '$.UnitPrice')
        FROM OPENJSON(@OrderLines);

        -- Validate stock availability
        IF EXISTS (
            SELECT 1
            FROM #TempOrderLines tol
            INNER JOIN Products p ON tol.ProductId = p.ProductId
            WHERE p.StockQuantity < tol.Quantity
        )
        BEGIN
            SET @ErrorMessage = 'Insufficient stock for one or more products';
            ROLLBACK TRANSACTION;
            RETURN -2;
        END

        -- Calculate total amount
        DECLARE @TotalAmount DECIMAL(10,2);
        SELECT @TotalAmount = SUM(Quantity * UnitPrice)
        FROM #TempOrderLines;

        -- Create order
        INSERT INTO Orders (CustomerId, OrderDate, TotalAmount, Status)
        VALUES (@CustomerId, GETDATE(), @TotalAmount, 'Pending');

        SET @OrderId = SCOPE_IDENTITY();

        -- Create order lines
        INSERT INTO OrderLines (OrderId, ProductId, Quantity, UnitPrice)
        SELECT @OrderId, ProductId, Quantity, UnitPrice
        FROM #TempOrderLines;

        -- Update product stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - tol.Quantity
        FROM Products p
        INNER JOIN #TempOrderLines tol ON p.ProductId = tol.ProductId;

        -- Clean up
        DROP TABLE #TempOrderLines;

        COMMIT TRANSACTION;
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log error
        INSERT INTO ErrorLog (ProcedureName, ErrorMessage, ErrorDate)
        VALUES ('ProcessOrder', @ErrorMessage, GETDATE());

        RETURN -99;
    END CATCH;
END;
GO

-- Execute the procedure
DECLARE @NewOrderId INT;
DECLARE @Error NVARCHAR(500);
DECLARE @Result INT;

EXEC @Result = ProcessOrder
    @CustomerId = 123,
    @OrderLines = '[
        {"ProductId": 1, "Quantity": 2, "UnitPrice": 99.99},
        {"ProductId": 2, "Quantity": 1, "UnitPrice": 49.99}
    ]',
    @OrderId = @NewOrderId OUTPUT,
    @ErrorMessage = @Error OUTPUT;

IF @Result = 0
    PRINT 'Order ' + CAST(@NewOrderId AS VARCHAR(10)) + ' created successfully';
ELSE
    PRINT 'Error: ' + @Error;
```

**Stored Procedure Best Practices:**

```sql
-- 1. Use SET NOCOUNT ON
CREATE PROCEDURE BestPracticeExample
AS
BEGIN
    SET NOCOUNT ON;  -- Improves performance
    -- Your logic here
END;

-- 2. Use TRY-CATCH for error handling
CREATE PROCEDURE WithErrorHandling
AS
BEGIN
    BEGIN TRY
        -- Your logic
    END TRY
    BEGIN CATCH
        -- Error handling
        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_LINE() AS ErrorLine;
    END CATCH;
END;

-- 3. Use transactions for data modifications
CREATE PROCEDURE WithTransaction
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Multiple operations
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

-- 4. Use schema name
CREATE PROCEDURE dbo.GetProducts  -- Specify schema
AS
BEGIN
    -- Your logic
END;

-- 5. Parameter validation
CREATE PROCEDURE ValidateParameters
    @ProductId INT
AS
BEGIN
    IF @ProductId IS NULL OR @ProductId <= 0
    BEGIN
        RAISERROR('Invalid ProductId', 16, 1);
        RETURN -1;
    END

    -- Your logic
END;
```

**Modify/Drop Stored Procedures:**

```sql
-- Alter existing procedure
ALTER PROCEDURE GetProductById
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProductId,
        ProductName,
        Price,
        StockQuantity,
        CreatedDate  -- Added new column
    FROM Products
    WHERE ProductId = @ProductId;
END;
GO

-- Drop stored procedure
DROP PROCEDURE IF EXISTS GetProductById;

-- Check if procedure exists
IF OBJECT_ID('dbo.GetProductById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GetProductById;
```

**C# Integration:**

```csharp
// Call stored procedure from C#
public async Task<Product> GetProductByIdAsync(int productId)
{
    using var connection = new SqlConnection(_connectionString);
    using var command = new SqlCommand("GetProductById", connection);

    command.CommandType = CommandType.StoredProcedure;
    command.Parameters.AddWithValue("@ProductId", productId);

    await connection.OpenAsync();

    using var reader = await command.ExecuteReaderAsync();

    if (await reader.ReadAsync())
    {
        return new Product
        {
            ProductId = reader.GetInt32(0),
            ProductName = reader.GetString(1),
            Price = reader.GetDecimal(2),
            StockQuantity = reader.GetInt32(3)
        };
    }

    return null;
}

// Call stored procedure with OUTPUT parameter
public async Task<int> CreateOrderAsync(int customerId, decimal totalAmount)
{
    using var connection = new SqlConnection(_connectionString);
    using var command = new SqlCommand("CreateOrder", connection);

    command.CommandType = CommandType.StoredProcedure;
    command.Parameters.AddWithValue("@CustomerId", customerId);
    command.Parameters.AddWithValue("@TotalAmount", totalAmount);

    var orderIdParam = new SqlParameter("@OrderId", SqlDbType.Int)
    {
        Direction = ParameterDirection.Output
    };
    command.Parameters.Add(orderIdParam);

    var returnParam = new SqlParameter("@ReturnValue", SqlDbType.Int)
    {
        Direction = ParameterDirection.ReturnValue
    };
    command.Parameters.Add(returnParam);

    await connection.OpenAsync();
    await command.ExecuteNonQueryAsync();

    int returnValue = (int)returnParam.Value;

    if (returnValue == 0)
    {
        return (int)orderIdParam.Value;  // Return OrderId
    }
    else
    {
        throw new Exception("Order creation failed");
    }
}
```

**Best Practices:**

1. **SET NOCOUNT ON**: Reduces network traffic
2. **Use Transactions**: For operations modifying multiple tables
3. **Error Handling**: Always use TRY-CATCH
4. **Parameter Validation**: Validate inputs before processing
5. **Avoid SELECT ***: Specify column names
6. **Use Schema Names**: dbo.ProcedureName
7. **Naming Convention**: Use descriptive names (GetCustomerOrders, CreateOrder)
8. **Documentation**: Add comments explaining complex logic
9. **Return Values**: Use RETURN for status codes, OUTPUT for data
10. **Security**: Grant EXECUTE permission, not direct table access

---

*[Continuing with Q175-Q200 covering more SQL topics including triggers, transactions, isolation levels, query optimization, normalization, etc.]*

---

## Q175: What are database triggers in SQL Server and what are their types?

**Database triggers** are special stored procedures that automatically execute when specific events occur in the database.

### Types of Triggers:

#### 1. DML Triggers (Data Manipulation Language)
Execute when INSERT, UPDATE, or DELETE operations occur on a table.

**AFTER Triggers:**
```sql
-- Audit trigger to track product price changes
CREATE TRIGGER trg_Products_PriceAudit
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only log if Price column was actually changed
    IF UPDATE(Price)
    BEGIN
        INSERT INTO ProductPriceHistory (
            ProductId,
            OldPrice,
            NewPrice,
            ChangedBy,
            ChangedDate
        )
        SELECT
            d.ProductId,
            d.Price AS OldPrice,
            i.Price AS NewPrice,
            SYSTEM_USER AS ChangedBy,
            GETDATE() AS ChangedDate
        FROM deleted d
        INNER JOIN inserted i ON d.ProductId = i.ProductId
        WHERE d.Price <> i.Price;
    END
END;
GO

-- Example usage
UPDATE Products
SET Price = 29.99
WHERE ProductId = 101;
-- Automatically logs to ProductPriceHistory
```

**INSTEAD OF Triggers:**
```sql
-- Create a view that combines multiple tables
CREATE VIEW vw_OrderDetails
AS
SELECT
    o.OrderId,
    o.OrderDate,
    c.CustomerName,
    c.Email,
    o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.CustomerId;
GO

-- Make the view updatable using INSTEAD OF trigger
CREATE TRIGGER trg_OrderDetails_Insert
ON vw_OrderDetails
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerId INT;

    -- Get or create customer
    SELECT @CustomerId = CustomerId
    FROM Customers
    WHERE Email = (SELECT Email FROM inserted);

    IF @CustomerId IS NULL
    BEGIN
        INSERT INTO Customers (CustomerName, Email)
        SELECT CustomerName, Email FROM inserted;

        SET @CustomerId = SCOPE_IDENTITY();
    END

    -- Insert order
    INSERT INTO Orders (CustomerId, OrderDate, TotalAmount)
    SELECT @CustomerId, OrderDate, TotalAmount
    FROM inserted;
END;
GO
```

#### 2. DDL Triggers (Data Definition Language)
Execute when CREATE, ALTER, or DROP operations occur.

```sql
-- Prevent dropping tables in production
CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Dropping tables is not allowed in production!';
    ROLLBACK;
END;
GO

-- Audit schema changes
CREATE TRIGGER trg_AuditSchemaChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();

    INSERT INTO SchemaChangeAudit (
        EventType,
        ObjectName,
        ObjectType,
        SqlCommand,
        LoginName,
        EventDate
    )
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(255)'),
        GETDATE()
    );
END;
GO
```

#### 3. LOGON Triggers
Execute when a user logs into SQL Server.

```sql
-- Restrict login times
CREATE TRIGGER trg_RestrictLoginHours
ON ALL SERVER
FOR LOGON
AS
BEGIN
    IF ORIGINAL_LOGIN() NOT IN ('sa', 'AdminUser')
        AND (DATEPART(HOUR, GETDATE()) < 8 OR DATEPART(HOUR, GETDATE()) > 18)
    BEGIN
        PRINT 'Logins are only allowed between 8 AM and 6 PM';
        ROLLBACK;
    END
END;
GO
```

### Trigger Special Tables:

| Table | Description | Available In |
|-------|-------------|--------------|
| **inserted** | Contains new rows (INSERT, UPDATE) | AFTER/INSTEAD OF |
| **deleted** | Contains old rows (DELETE, UPDATE) | AFTER/INSTEAD OF |

```sql
-- Example using both inserted and deleted
CREATE TRIGGER trg_Inventory_Update
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle deletions/old values
    UPDATE Products
    SET StockQuantity = StockQuantity + d.Quantity
    FROM Products p
    INNER JOIN deleted d ON p.ProductId = d.ProductId;

    -- Handle insertions/new values
    UPDATE Products
    SET StockQuantity = StockQuantity - i.Quantity
    FROM Products p
    INNER JOIN inserted i ON p.ProductId = i.ProductId;
END;
GO
```

### C# Integration:

```csharp
public class ProductService
{
    private readonly string _connectionString;

    // The trigger automatically logs price changes
    public async Task UpdateProductPriceAsync(int productId, decimal newPrice)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            "UPDATE Products SET Price = @Price WHERE ProductId = @ProductId",
            connection);

        command.Parameters.AddWithValue("@ProductId", productId);
        command.Parameters.AddWithValue("@Price", newPrice);

        await connection.OpenAsync();
        await command.ExecuteNonQueryAsync();

        // Trigger automatically logged to ProductPriceHistory
    }

    // View price history logged by trigger
    public async Task<List<PriceHistory>> GetPriceHistoryAsync(int productId)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(@"
            SELECT ProductId, OldPrice, NewPrice, ChangedBy, ChangedDate
            FROM ProductPriceHistory
            WHERE ProductId = @ProductId
            ORDER BY ChangedDate DESC",
            connection);

        command.Parameters.AddWithValue("@ProductId", productId);

        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        var history = new List<PriceHistory>();
        while (await reader.ReadAsync())
        {
            history.Add(new PriceHistory
            {
                ProductId = reader.GetInt32(0),
                OldPrice = reader.GetDecimal(1),
                NewPrice = reader.GetDecimal(2),
                ChangedBy = reader.GetString(3),
                ChangedDate = reader.GetDateTime(4)
            });
        }

        return history;
    }
}
```

### Best Practices:

1. **Keep Triggers Simple and Fast**
   - Avoid complex logic
   - Don't call external services
   - Minimize nested triggers

2. **Error Handling**
   ```sql
   CREATE TRIGGER trg_Example
   ON TableName
   AFTER INSERT
   AS
   BEGIN
       SET NOCOUNT ON;

       BEGIN TRY
           -- Trigger logic here
       END TRY
       BEGIN CATCH
           -- Log error
           INSERT INTO ErrorLog (ErrorMessage, ErrorDate)
           VALUES (ERROR_MESSAGE(), GETDATE());

           -- Rollback if needed
           IF @@TRANCOUNT > 0
               ROLLBACK;
       END CATCH;
   END;
   ```

3. **Avoid Recursive Triggers**
   ```sql
   -- Set database option to prevent recursion
   ALTER DATABASE YourDatabase
   SET RECURSIVE_TRIGGERS OFF;
   ```

4. **Use SET NOCOUNT ON**
   - Prevents extra result sets
   - Improves performance

### When to Use Triggers:

✅ **Good Use Cases:**
- Audit trails and logging
- Enforcing complex business rules
- Maintaining derived data
- Enforcing referential integrity beyond foreign keys

❌ **Avoid For:**
- Complex business logic (use stored procedures)
- Long-running operations
- Calling external APIs
- Operations that could cause deadlocks

---

## Q176: Explain transaction management in SQL Server (BEGIN, COMMIT, ROLLBACK).

**Transactions** ensure that a series of database operations are treated as a single unit of work that either completely succeeds or completely fails.

### ACID Properties:

```
┌─────────────────────────────────────────┐
│           ACID Properties               │
├─────────────────────────────────────────┤
│ A - Atomicity   │ All or nothing        │
│ C - Consistency │ Valid state always    │
│ I - Isolation   │ Concurrent safety     │
│ D - Durability  │ Permanent changes     │
└─────────────────────────────────────────┘
```

### Basic Transaction Syntax:

```sql
-- Simple transaction
BEGIN TRANSACTION;

    UPDATE Accounts
    SET Balance = Balance - 100
    WHERE AccountId = 1;

    UPDATE Accounts
    SET Balance = Balance + 100
    WHERE AccountId = 2;

COMMIT TRANSACTION;
```

### Transaction with Error Handling:

```sql
-- Transfer money between accounts
CREATE PROCEDURE TransferFunds
    @FromAccountId INT,
    @ToAccountId INT,
    @Amount DECIMAL(18,2),
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate accounts exist
        IF NOT EXISTS (SELECT 1 FROM Accounts WHERE AccountId = @FromAccountId)
        BEGIN
            SET @ErrorMessage = 'Source account not found';
            THROW 50001, @ErrorMessage, 1;
        END

        IF NOT EXISTS (SELECT 1 FROM Accounts WHERE AccountId = @ToAccountId)
        BEGIN
            SET @ErrorMessage = 'Destination account not found';
            THROW 50002, @ErrorMessage, 1;
        END

        -- Check sufficient balance
        DECLARE @CurrentBalance DECIMAL(18,2);
        SELECT @CurrentBalance = Balance
        FROM Accounts WITH (UPDLOCK)  -- Lock for update
        WHERE AccountId = @FromAccountId;

        IF @CurrentBalance < @Amount
        BEGIN
            SET @ErrorMessage = 'Insufficient funds';
            THROW 50003, @ErrorMessage, 1;
        END

        -- Perform transfer
        UPDATE Accounts
        SET Balance = Balance - @Amount,
            LastModified = GETDATE()
        WHERE AccountId = @FromAccountId;

        UPDATE Accounts
        SET Balance = Balance + @Amount,
            LastModified = GETDATE()
        WHERE AccountId = @ToAccountId;

        -- Log transaction
        INSERT INTO TransactionHistory (
            FromAccountId,
            ToAccountId,
            Amount,
            TransactionDate
        )
        VALUES (@FromAccountId, @ToAccountId, @Amount, GETDATE());

        COMMIT TRANSACTION;

        SET @ErrorMessage = NULL;
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO
```

### Named Transactions and Savepoints:

```sql
-- Named transaction with savepoints
BEGIN TRANSACTION OrderProcessing;

    -- Insert order
    INSERT INTO Orders (CustomerId, OrderDate, TotalAmount)
    VALUES (123, GETDATE(), 150.00);

    DECLARE @OrderId INT = SCOPE_IDENTITY();

    SAVE TRANSACTION AfterOrderInsert;  -- Savepoint

    BEGIN TRY
        -- Insert order items
        INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice)
        VALUES
            (@OrderId, 1, 2, 25.00),
            (@OrderId, 2, 4, 25.00);

        SAVE TRANSACTION AfterOrderItems;  -- Another savepoint

        -- Update inventory
        UPDATE Products
        SET StockQuantity = StockQuantity - 2
        WHERE ProductId = 1;

        UPDATE Products
        SET StockQuantity = StockQuantity - 4
        WHERE ProductId = 2;

        COMMIT TRANSACTION OrderProcessing;

    END TRY
    BEGIN CATCH
        -- Rollback to savepoint instead of entire transaction
        IF ERROR_NUMBER() = 547  -- FK violation on OrderItems
        BEGIN
            ROLLBACK TRANSACTION AfterOrderInsert;
            -- Order is rolled back, can handle error and retry
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION OrderProcessing;
        END
    END CATCH;
```

### Nested Transactions:

```sql
-- Outer transaction
BEGIN TRANSACTION;  -- @@TRANCOUNT = 1

    INSERT INTO Orders (CustomerId, OrderDate)
    VALUES (1, GETDATE());

    -- Inner transaction (not truly nested)
    BEGIN TRANSACTION;  -- @@TRANCOUNT = 2

        INSERT INTO OrderItems (OrderId, ProductId, Quantity)
        VALUES (1, 100, 5);

    COMMIT;  -- @@TRANCOUNT = 1 (decrements count)

COMMIT;  -- @@TRANCOUNT = 0 (actually commits)

-- Note: ROLLBACK always rolls back to outermost transaction
```

### Checking Transaction State:

```sql
-- Check transaction count
SELECT @@TRANCOUNT AS ActiveTransactions;

-- Check if in transaction
IF @@TRANCOUNT > 0
    PRINT 'Inside transaction';
ELSE
    PRINT 'No active transaction';

-- Transaction status
SELECT
    CASE XACT_STATE()
        WHEN 1 THEN 'Committable transaction'
        WHEN -1 THEN 'Uncommittable transaction (doomed)'
        WHEN 0 THEN 'No active transaction'
    END AS TransactionState;
```

### C# Integration with ADO.NET:

```csharp
public class OrderService
{
    private readonly string _connectionString;

    public async Task<int> CreateOrderWithTransactionAsync(
        int customerId,
        List<OrderItem> items)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Begin transaction
        using var transaction = connection.BeginTransaction(
            IsolationLevel.ReadCommitted);

        try
        {
            // Insert order
            using var orderCommand = new SqlCommand(@"
                INSERT INTO Orders (CustomerId, OrderDate, Status)
                VALUES (@CustomerId, GETDATE(), 'Pending');
                SELECT SCOPE_IDENTITY();",
                connection, transaction);

            orderCommand.Parameters.AddWithValue("@CustomerId", customerId);

            var orderId = Convert.ToInt32(
                await orderCommand.ExecuteScalarAsync());

            // Insert order items
            foreach (var item in items)
            {
                using var itemCommand = new SqlCommand(@"
                    INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice)
                    VALUES (@OrderId, @ProductId, @Quantity, @UnitPrice);

                    UPDATE Products
                    SET StockQuantity = StockQuantity - @Quantity
                    WHERE ProductId = @ProductId;",
                    connection, transaction);

                itemCommand.Parameters.AddWithValue("@OrderId", orderId);
                itemCommand.Parameters.AddWithValue("@ProductId", item.ProductId);
                itemCommand.Parameters.AddWithValue("@Quantity", item.Quantity);
                itemCommand.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);

                await itemCommand.ExecuteNonQueryAsync();
            }

            // Commit transaction
            await transaction.CommitAsync();

            return orderId;
        }
        catch (Exception ex)
        {
            // Rollback on error
            await transaction.RollbackAsync();

            _logger.LogError(ex, "Failed to create order for customer {CustomerId}",
                customerId);
            throw;
        }
    }
}
```

### Using TransactionScope (.NET):

```csharp
public class OrderService
{
    private readonly string _connectionString;

    public async Task<int> CreateOrderWithTransactionScopeAsync(
        int customerId,
        List<OrderItem> items)
    {
        // Distributed transaction coordinator
        using var scope = new TransactionScope(
            TransactionScopeOption.Required,
            new TransactionOptions
            {
                IsolationLevel = System.Transactions.IsolationLevel.ReadCommitted,
                Timeout = TimeSpan.FromSeconds(30)
            },
            TransactionScopeAsyncFlowOption.Enabled);

        try
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            // Insert order
            int orderId;
            using (var command = new SqlCommand(@"
                INSERT INTO Orders (CustomerId, OrderDate, Status)
                VALUES (@CustomerId, GETDATE(), 'Pending');
                SELECT SCOPE_IDENTITY();", connection))
            {
                command.Parameters.AddWithValue("@CustomerId", customerId);
                orderId = Convert.ToInt32(await command.ExecuteScalarAsync());
            }

            // Insert order items
            foreach (var item in items)
            {
                using var command = new SqlCommand(@"
                    INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice)
                    VALUES (@OrderId, @ProductId, @Quantity, @UnitPrice);",
                    connection);

                command.Parameters.AddWithValue("@OrderId", orderId);
                command.Parameters.AddWithValue("@ProductId", item.ProductId);
                command.Parameters.AddWithValue("@Quantity", item.Quantity);
                command.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);

                await command.ExecuteNonQueryAsync();
            }

            // Complete the transaction scope
            scope.Complete();

            return orderId;
        }
        catch (Exception ex)
        {
            // Transaction automatically rolls back if Complete() not called
            _logger.LogError(ex, "Transaction failed");
            throw;
        }
    }
}
```

### Best Practices:

1. **Keep Transactions Short**
   - Minimize time locks are held
   - Avoid user interaction during transactions

2. **Always Use TRY-CATCH**
   ```sql
   BEGIN TRANSACTION;
   BEGIN TRY
       -- Operations here
       COMMIT;
   END TRY
   BEGIN CATCH
       IF @@TRANCOUNT > 0
           ROLLBACK;
       THROW;
   END CATCH;
   ```

3. **Check @@TRANCOUNT**
   - Before ROLLBACK to avoid errors
   - Prevents rolling back non-existent transactions

4. **Use Appropriate Isolation Levels**
   - Balance between consistency and concurrency

5. **Avoid DDL in Transactions**
   - Schema changes can cause blocking
   - Can't be rolled back in some cases


---

## Q177: What are transaction isolation levels in SQL Server?

**Isolation levels** control how transaction integrity is visible to other users and systems when multiple transactions occur concurrently.

### Isolation Levels Overview:

```
┌──────────────────────────────────────────────────────────┐
│              Isolation Level Hierarchy                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  READ UNCOMMITTED  ←─ Least restrictive                 │
│         ↓              Most concurrency                   │
│  READ COMMITTED    ←─ SQL Server default                 │
│         ↓              Balanced                           │
│  REPEATABLE READ   ←─ More consistency                   │
│         ↓              Less concurrency                   │
│  SERIALIZABLE      ←─ Most restrictive                   │
│         ↓              Full consistency                   │
│  SNAPSHOT          ←─ Best of both worlds                │
│                       (row versioning)                    │
└──────────────────────────────────────────────────────────┘
```

### Concurrency Problems:

| Problem | Description | Example |
|---------|-------------|---------|
| **Dirty Read** | Reading uncommitted data | Transaction A modifies row, Transaction B reads it, A rolls back |
| **Non-Repeatable Read** | Same query returns different data | Transaction A reads row twice, B modifies between reads |
| **Phantom Read** | New rows appear in query results | Transaction A counts rows twice, B inserts between counts |

### Isolation Levels Comparison:

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Locking Behavior |
|----------------|------------|---------------------|--------------|------------------|
| READ UNCOMMITTED | ✓ Yes | ✓ Yes | ✓ Yes | No locks |
| READ COMMITTED | ✗ No | ✓ Yes | ✓ Yes | Short read locks |
| REPEATABLE READ | ✗ No | ✗ No | ✓ Yes | Long read locks |
| SERIALIZABLE | ✗ No | ✗ No | ✗ No | Range locks |
| SNAPSHOT | ✗ No | ✗ No | ✗ No | Row versioning |

### 1. READ UNCOMMITTED (Isolation Level 0):

```sql
-- Set isolation level for session
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Or use query hint
SELECT ProductId, ProductName, StockQuantity
FROM Products WITH (NOLOCK)  -- Same as READ UNCOMMITTED
WHERE CategoryId = 5;

-- Example of dirty read problem:
-- Transaction A:
BEGIN TRANSACTION;
UPDATE Products SET Price = 99.99 WHERE ProductId = 1;
-- Not committed yet

-- Transaction B (READ UNCOMMITTED):
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Price FROM Products WHERE ProductId = 1;
-- Returns 99.99 (uncommitted data)

-- Transaction A:
ROLLBACK;  -- Price change undone

-- Transaction B read data that never actually existed!
```

**Use Cases:**
- Reporting queries where approximate data is acceptable
- Performance-critical reads where accuracy can be sacrificed
- ⚠️ Use with extreme caution in production

### 2. READ COMMITTED (Default):

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Transaction A:
BEGIN TRANSACTION;
UPDATE Products SET Price = 89.99 WHERE ProductId = 1;
COMMIT;

-- Transaction B:
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductId = 1;
    -- Returns old price or waits if A hasn't committed

    WAITFOR DELAY '00:00:05';  -- Wait 5 seconds

    SELECT Price FROM Products WHERE ProductId = 1;
    -- Might return different price (non-repeatable read)
COMMIT;
```

**Locking Behavior:**
```sql
-- Shared locks are held only while reading
-- Released immediately after read completes

-- Example:
BEGIN TRANSACTION;
    SELECT * FROM Products WHERE ProductId = 1;
    -- Shared lock acquired and immediately released

    -- Another transaction can now modify this row

    SELECT * FROM Products WHERE ProductId = 1;
    -- Might see different data
COMMIT;
```

### 3. REPEATABLE READ:

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Transaction A:
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductId = 1;
    -- Returns 79.99, shared lock held

    WAITFOR DELAY '00:00:10';

    SELECT Price FROM Products WHERE ProductId = 1;
    -- Guaranteed to return 79.99 (same value)
COMMIT;
-- Shared lock released only at commit

-- Transaction B (blocked until A commits):
UPDATE Products SET Price = 89.99 WHERE ProductId = 1;
-- Waits for A's lock to be released
```

**Phantom Read Example:**
```sql
-- Transaction A (REPEATABLE READ):
BEGIN TRANSACTION;
    SELECT COUNT(*) FROM Products WHERE CategoryId = 5;
    -- Returns 10

    WAITFOR DELAY '00:00:05';

    SELECT COUNT(*) FROM Products WHERE CategoryId = 5;
    -- Might return 11 (phantom read - new row inserted)
COMMIT;

-- Transaction B (executed during A's delay):
INSERT INTO Products (CategoryId, ProductName, Price)
VALUES (5, 'New Product', 49.99);
COMMIT;
```

### 4. SERIALIZABLE:

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Transaction A:
BEGIN TRANSACTION;
    SELECT * FROM Products WHERE CategoryId = 5;
    -- Range lock on CategoryId = 5

    WAITFOR DELAY '00:00:10';

    SELECT * FROM Products WHERE CategoryId = 5;
    -- Guaranteed same results (no phantoms)
COMMIT;

-- Transaction B (blocked):
INSERT INTO Products (CategoryId, ProductName, Price)
VALUES (5, 'New Product', 49.99);
-- Blocked by range lock until A commits
```

**Key-Range Locking:**
```sql
-- SERIALIZABLE uses key-range locks
-- Locks not just existing rows, but gaps between keys

BEGIN TRANSACTION;
    SELECT * FROM Orders
    WHERE OrderDate BETWEEN '2024-01-01' AND '2024-01-31';

    -- Locks:
    -- 1. All matching rows
    -- 2. Gaps between keys in the range
    -- 3. Prevents inserts in the range
COMMIT;
```

### 5. SNAPSHOT Isolation:

```sql
-- Enable at database level first
ALTER DATABASE YourDatabase
SET ALLOW_SNAPSHOT_ISOLATION ON;

-- Use in transaction
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRANSACTION;
    -- Reads data as it existed at transaction start
    SELECT Price FROM Products WHERE ProductId = 1;
    -- Returns 79.99

    -- Another transaction modifies and commits
    -- (in a different session)

    WAITFOR DELAY '00:00:05';

    SELECT Price FROM Products WHERE ProductId = 1;
    -- Still returns 79.99 (consistent snapshot)
COMMIT;
```

**Row Versioning:**
```
Original Row:
┌──────┬─────────┬───────┬─────────────┐
│ Id   │ Name    │ Price │ RowVersion  │
├──────┼─────────┼───────┼─────────────┤
│ 1    │ Widget  │ 79.99 │ V1          │
└──────┴─────────┴───────┴─────────────┘

After Update:
┌──────┬─────────┬───────┬─────────────┐
│ Id   │ Name    │ Price │ RowVersion  │
├──────┼─────────┼───────┼─────────────┤
│ 1    │ Widget  │ 89.99 │ V2 (current)│
└──────┴─────────┴───────┴─────────────┘

Version Store (in tempdb):
┌──────┬─────────┬───────┬────────────┐
│ Id   │ Name    │ Price │ RowVersion │
├──────┼─────────┼───────┼────────────┤
│ 1    │ Widget  │ 79.99 │ V1 (old)   │
└──────┴─────────┴───────┴────────────┘

Snapshot transaction reads V1
New transactions read V2
```

**Update Conflicts:**
```sql
-- Transaction A (SNAPSHOT):
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductId = 1;
    -- Returns 79.99

    -- Transaction B updates and commits
    -- Price is now 89.99

    UPDATE Products SET Price = 99.99 WHERE ProductId = 1;
    -- Error! Update conflict detected
    -- "Snapshot isolation transaction aborted due to update conflict"
ROLLBACK;
```

### 6. READ COMMITTED SNAPSHOT:

```sql
-- Enable at database level
ALTER DATABASE YourDatabase
SET READ_COMMITTED_SNAPSHOT ON;

-- Now READ COMMITTED uses row versioning instead of locks
-- Default behavior changes for entire database

-- No need to set isolation level
BEGIN TRANSACTION;
    SELECT * FROM Products WHERE ProductId = 1;
    -- Uses row versioning, no shared locks
    -- But each statement gets latest committed version
COMMIT;
```

### C# Implementation:

```csharp
public class ProductService
{
    private readonly string _connectionString;

    // Example with different isolation levels
    public async Task<decimal> GetProductPriceAsync(
        int productId,
        IsolationLevel isolationLevel = IsolationLevel.ReadCommitted)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var transaction = connection.BeginTransaction(isolationLevel);

        try
        {
            using var command = new SqlCommand(
                "SELECT Price FROM Products WHERE ProductId = @ProductId",
                connection, transaction);

            command.Parameters.AddWithValue("@ProductId", productId);

            var price = (decimal)await command.ExecuteScalarAsync();

            transaction.Commit();
            return price;
        }
        catch (SqlException ex) when (ex.Number == 3960)
        {
            // Snapshot isolation update conflict
            transaction.Rollback();
            throw new InvalidOperationException(
                "Update conflict detected in snapshot isolation", ex);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    // High-concurrency scenario with SNAPSHOT
    public async Task<OrderSummary> ProcessOrderWithSnapshotAsync(int orderId)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var transaction = connection.BeginTransaction(
            IsolationLevel.Snapshot);

        try
        {
            // Read order (consistent snapshot)
            var order = await GetOrderAsync(orderId, connection, transaction);

            // Calculate totals (all reads use same snapshot)
            var items = await GetOrderItemsAsync(orderId, connection, transaction);
            var subtotal = items.Sum(i => i.Quantity * i.UnitPrice);

            // Update order total
            await UpdateOrderTotalAsync(orderId, subtotal, connection, transaction);

            await transaction.CommitAsync();

            return new OrderSummary { Order = order, Items = items, Subtotal = subtotal };
        }
        catch (SqlException ex) when (ex.Number == 3960)
        {
            // Retry with exponential backoff
            await transaction.RollbackAsync();
            await Task.Delay(100);
            return await ProcessOrderWithSnapshotAsync(orderId);
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}
```

### Choosing the Right Isolation Level:

| Scenario | Recommended Level | Reason |
|----------|------------------|---------|
| **Bank transfer** | SERIALIZABLE or SNAPSHOT | Absolute consistency required |
| **E-commerce order** | SNAPSHOT | Good balance of consistency and concurrency |
| **Product catalog read** | READ COMMITTED | Standard protection, good performance |
| **Reporting/Analytics** | READ UNCOMMITTED or SNAPSHOT | Performance priority, occasional stale data OK |
| **Inventory management** | REPEATABLE READ or SNAPSHOT | Prevent double-booking |
| **High-concurrency writes** | SNAPSHOT | Avoid blocking, handle conflicts |

### Performance Impact:

```
Concurrency →  | Low ←────────────────────→ High |
Consistency →  | High ←───────────────────→ Low  |
               |                                 |
               SERIALIZABLE                      |
               REPEATABLE READ                   |
               SNAPSHOT ──────────────← Best balance
               READ COMMITTED                    |
               READ UNCOMMITTED                  |
```

### Best Practices:

1. **Use READ COMMITTED for most scenarios**
   - Good default balance

2. **Consider SNAPSHOT for high concurrency**
   - Eliminates blocking
   - Trades tempdb space for performance

3. **Avoid READ UNCOMMITTED in OLTP**
   - Only for reporting/analytics

4. **Use SERIALIZABLE sparingly**
   - High locking overhead
   - Can cause deadlocks

5. **Enable READ_COMMITTED_SNAPSHOT for applications**
   - Better concurrency than lock-based READ COMMITTED
   - Application code doesn't need changes

---

## Q178: What is query optimization in SQL Server and how do you use execution plans?

**Query optimization** is the process of analyzing and improving SQL query performance by understanding how SQL Server executes queries.

### Query Execution Process:

```
┌─────────────────────────────────────────────────────┐
│           SQL Server Query Execution Flow            │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. Parse           → Check syntax                   │
│         ↓                                            │
│  2. Bind            → Resolve objects & types        │
│         ↓                                            │
│  3. Optimize        → Query Optimizer creates plan   │
│         ↓                                            │
│  4. Compile         → Generate execution plan        │
│         ↓                                            │
│  5. Execute         → Run the query                  │
│         ↓                                            │
│  6. Return Results  → Send data to client            │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Execution Plans:

#### Viewing Execution Plans:

```sql
-- Estimated Execution Plan (doesn't run query)
SET SHOWPLAN_XML ON;
GO
SELECT * FROM Products WHERE CategoryId = 5;
GO
SET SHOWPLAN_XML OFF;
GO

-- Actual Execution Plan (runs query)
SET STATISTICS XML ON;
GO
SELECT * FROM Products WHERE CategoryId = 5;
GO
SET STATISTICS XML OFF;
GO

-- Include actual execution plan in SSMS
-- Ctrl+M or click "Include Actual Execution Plan"
SELECT p.ProductName, p.Price, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryId = c.CategoryId
WHERE p.Price > 50;
```

### Reading Execution Plans:

```
Execution Plan Flow (Right to Left, Bottom to Top):
┌──────────────────────────────────────────────────┐
│                                                   │
│  SELECT (100%)                                    │
│       ↑                                           │
│  Nested Loops Join (75%)                         │
│       ↑         ↑                                 │
│  Index Seek  Index Scan                          │
│  (Products)  (Categories)                        │
│    (25%)       (50%)                             │
│                                                   │
└──────────────────────────────────────────────────┘
Cost percentages show relative expense
```

### Key Execution Plan Operators:

#### 1. **Table/Index Scan** (Expensive):
```sql
-- Full table scan (BAD for large tables)
SELECT * FROM Products
WHERE ProductName LIKE '%widget%';  -- Leading wildcard prevents index use

-- Execution Plan shows:
-- Table Scan (Products) - Cost: 90%
```

#### 2. **Index Seek** (Good):
```sql
-- Uses index efficiently
SELECT * FROM Products
WHERE ProductId = 100;  -- Clustered index seek

-- Execution Plan shows:
-- Clustered Index Seek (Products.PK_ProductId) - Cost: 5%
```

#### 3. **Index Scan** (Better than table scan):
```sql
-- Scans entire index
SELECT ProductId, ProductName
FROM Products
WHERE Price > 100;

-- If covering index exists:
-- Index Scan (IX_Products_Price_Covering) - Cost: 20%
```

#### 4. **Nested Loops Join**:
```sql
-- Good for small result sets
SELECT o.OrderId, c.CustomerName
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.CustomerId
WHERE o.OrderId = 12345;

-- Execution Plan:
-- Nested Loops Join - Cost: 30%
--   ├─ Index Seek (Orders) - Cost: 10%
--   └─ Key Lookup (Customers) - Cost: 20%
```

#### 5. **Hash Join**:
```sql
-- Good for large result sets
SELECT p.ProductName, SUM(oi.Quantity) as TotalSold
FROM Products p
INNER JOIN OrderItems oi ON p.ProductId = oi.ProductId
GROUP BY p.ProductId, p.ProductName;

-- Execution Plan:
-- Hash Match (Aggregate) - Cost: 40%
--   └─ Hash Match (Inner Join) - Cost: 35%
--       ├─ Table Scan (Products) - Cost: 15%
--       └─ Table Scan (OrderItems) - Cost: 20%
```

#### 6. **Merge Join**:
```sql
-- Good when both inputs are sorted
SELECT o.OrderId, oi.ProductId, oi.Quantity
FROM Orders o
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
ORDER BY o.OrderId;

-- Execution Plan:
-- Merge Join - Cost: 25%
--   ├─ Index Scan (Orders.PK_OrderId) - Cost: 12%
--   └─ Index Scan (OrderItems.IX_OrderId) - Cost: 13%
```

### Common Performance Issues:

#### 1. **Missing Index**:
```sql
-- Query with missing index
SELECT * FROM Orders
WHERE CustomerId = 500
  AND OrderDate >= '2024-01-01';

-- Execution Plan shows:
-- Table Scan (Orders) - Cost: 95%
-- Missing Index: CREATE INDEX IX_Orders_CustomerId_OrderDate
--                ON Orders(CustomerId, OrderDate)

-- Create the index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId_OrderDate
ON Orders(CustomerId, OrderDate)
INCLUDE (TotalAmount, Status);

-- After index:
-- Index Seek (IX_Orders_CustomerId_OrderDate) - Cost: 5%
```

#### 2. **Key Lookup** (Bookmark Lookup):
```sql
-- Query requires additional columns
SELECT ProductId, ProductName, Price, StockQuantity
FROM Products
WHERE CategoryId = 5;

-- If index only covers CategoryId and ProductId:
-- Execution Plan shows:
-- Nested Loops Join - Cost: 70%
--   ├─ Index Seek (IX_Products_CategoryId) - Cost: 10%
--   └─ Key Lookup (Products.PK_ProductId) - Cost: 60%

-- Fix with covering index:
CREATE NONCLUSTERED INDEX IX_Products_CategoryId_Covering
ON Products(CategoryId)
INCLUDE (ProductName, Price, StockQuantity);

-- After covering index:
-- Index Seek (IX_Products_CategoryId_Covering) - Cost: 5%
```

#### 3. **Implicit Conversions**:
```sql
-- BAD: Implicit conversion (ProductId is INT, comparing to VARCHAR)
SELECT * FROM Products
WHERE ProductId = '100';  -- String literal

-- Execution Plan shows warning:
-- CONVERT_IMPLICIT(int, [@1], 0)
-- Index Seek converts to Scan

-- GOOD: Explicit type match
SELECT * FROM Products
WHERE ProductId = 100;  -- Integer literal
```

#### 4. **Parameter Sniffing**:
```sql
-- Stored procedure with parameter sniffing issue
CREATE PROCEDURE GetOrdersByCustomer
    @CustomerId INT
AS
BEGIN
    SELECT * FROM Orders
    WHERE CustomerId = @CustomerId;
END;
GO

-- First execution: @CustomerId = 1 (has 1000 orders)
-- Plan cached: Index Scan
EXEC GetOrdersByCustomer @CustomerId = 1;

-- Second execution: @CustomerId = 9999 (has 1 order)
-- Uses cached plan (Index Scan), should use Index Seek
EXEC GetOrdersByCustomer @CustomerId = 9999;  -- Slow!

-- Fix with OPTION (RECOMPILE):
ALTER PROCEDURE GetOrdersByCustomer
    @CustomerId INT
AS
BEGIN
    SELECT * FROM Orders
    WHERE CustomerId = @CustomerId
    OPTION (RECOMPILE);  -- Generate fresh plan each time
END;
GO

-- Or use OPTIMIZE FOR hint:
ALTER PROCEDURE GetOrdersByCustomer
    @CustomerId INT
AS
BEGIN
    SELECT * FROM Orders
    WHERE CustomerId = @CustomerId
    OPTION (OPTIMIZE FOR (@CustomerId = 500));  -- Optimize for typical value
END;
GO
```

### Query Optimization Techniques:

#### 1. **Indexing Strategy**:
```sql
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
INNER JOIN sys.indexes i ON s.object_id = i.object_id
    AND s.index_id = i.index_id
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

-- Find missing indexes
SELECT
    migs.avg_user_impact,
    migs.avg_total_user_cost,
    migs.user_seeks,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    'CREATE NONCLUSTERED INDEX IX_' +
        OBJECT_NAME(mid.object_id) + '_' +
        REPLACE(REPLACE(ISNULL(mid.equality_columns, ''), '[', ''), ']', '') +
        ' ON ' + mid.statement +
        ' (' + ISNULL(mid.equality_columns, '') +
        CASE WHEN mid.inequality_columns IS NOT NULL
            THEN ',' + mid.inequality_columns ELSE '' END + ')' +
        CASE WHEN mid.included_columns IS NOT NULL
            THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END
        AS CreateIndexStatement
FROM sys.dm_db_missing_index_group_stats migs
INNER JOIN sys.dm_db_missing_index_groups mig ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_user_impact > 50  -- High impact
ORDER BY migs.avg_user_impact DESC;
```

#### 2. **Query Rewriting**:
```sql
-- BAD: Function on indexed column prevents index use
SELECT * FROM Orders
WHERE YEAR(OrderDate) = 2024;

-- Execution Plan: Table Scan

-- GOOD: Rewrite without function
SELECT * FROM Orders
WHERE OrderDate >= '2024-01-01'
  AND OrderDate < '2025-01-01';

-- Execution Plan: Index Seek

-- BAD: OR with different columns
SELECT * FROM Products
WHERE CategoryId = 5 OR Price > 100;

-- Execution Plan: Table Scan

-- GOOD: Use UNION
SELECT * FROM Products WHERE CategoryId = 5
UNION
SELECT * FROM Products WHERE Price > 100;

-- Execution Plan: Two Index Seeks with Concatenation
```

#### 3. **Statistics**:
```sql
-- Update statistics manually
UPDATE STATISTICS Products WITH FULLSCAN;

-- Check statistics info
DBCC SHOW_STATISTICS('Products', 'IX_Products_CategoryId');

-- Auto-update statistics (database setting)
ALTER DATABASE YourDatabase
SET AUTO_UPDATE_STATISTICS ON;

-- Create statistics on specific columns
CREATE STATISTICS Stats_Products_Price_Category
ON Products (Price, CategoryId);
```

### C# Integration - Query Performance Monitoring:

```csharp
public class QueryPerformanceService
{
    private readonly string _connectionString;
    private readonly ILogger _logger;

    public async Task<T> ExecuteWithPerformanceTrackingAsync<T>(
        string query,
        Func<SqlCommand, Task<T>> executor)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Enable statistics
        using var statsCommand = new SqlCommand(
            "SET STATISTICS TIME ON; SET STATISTICS IO ON;",
            connection);
        await statsCommand.ExecuteNonQueryAsync();

        var stopwatch = Stopwatch.StartNew();

        using var command = new SqlCommand(query, connection);
        var result = await executor(command);

        stopwatch.Stop();

        // Get execution statistics
        connection.InfoMessage += (sender, e) =>
        {
            _logger.LogInformation("SQL Stats: {Message}", e.Message);
        };

        _logger.LogInformation(
            "Query executed in {ElapsedMs}ms: {Query}",
            stopwatch.ElapsedMilliseconds,
            query);

        return result;
    }

    // Analyze query plan programmatically
    public async Task<string> GetQueryPlanAsync(string query)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Get estimated execution plan
        using var command = new SqlCommand(
            $"SET SHOWPLAN_XML ON; {query}; SET SHOWPLAN_XML OFF;",
            connection);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var planXml = reader.GetString(0);
            return planXml;
        }

        return null;
    }
}
```

### Query Hints and Options:

```sql
-- Force specific index
SELECT * FROM Products WITH (INDEX(IX_Products_CategoryId))
WHERE CategoryId = 5;

-- Force join type
SELECT *
FROM Orders o
INNER HASH JOIN OrderItems oi ON o.OrderId = oi.OrderId
OPTION (HASH JOIN);

-- Optimize for specific parameter value
SELECT * FROM Orders
WHERE CustomerId = @CustomerId
OPTION (OPTIMIZE FOR (@CustomerId = 100));

-- Recompile every time
SELECT * FROM Orders
WHERE CustomerId = @CustomerId
OPTION (RECOMPILE);

-- Maximum degree of parallelism
SELECT * FROM Orders
OPTION (MAXDOP 4);  -- Use max 4 cores

-- Force order of joins
SELECT *
FROM Orders o
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN Products p ON oi.ProductId = p.ProductId
OPTION (FORCE ORDER);
```

### Best Practices:

1. **Always analyze execution plans for slow queries**
2. **Create appropriate indexes** (equality columns → inequality → included)
3. **Avoid functions on indexed columns in WHERE clauses**
4. **Use covering indexes to eliminate key lookups**
5. **Keep statistics up to date**
6. **Monitor for parameter sniffing issues**
7. **Use SET STATISTICS IO/TIME for detailed metrics**
8. **Avoid SELECT * - specify only needed columns**
9. **Use EXISTS instead of COUNT for existence checks**
10. **Consider indexed views for complex aggregations**


---

## Q179: What is database normalization and what are the different normal forms?

**Database normalization** is the process of organizing data to minimize redundancy and dependency by dividing large tables into smaller ones and defining relationships between them.

### Normal Forms:

```
┌─────────────────────────────────────────────────┐
│         Normalization Hierarchy                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  Unnormalized → 1NF → 2NF → 3NF → BCNF → 4NF   │
│                                                  │
│  Less Normalized ←──────────→ More Normalized   │
│  More Redundancy ←──────────→ Less Redundancy   │
│                                                  │
└─────────────────────────────────────────────────┘
```

### 1. First Normal Form (1NF):

**Rules:**
- Each column contains atomic (indivisible) values
- Each column contains values of a single type
- Each column has a unique name
- Order doesn't matter

**Before 1NF (Unnormalized):**
```
Orders Table:
┌─────────┬──────────────┬─────────────────────────────┐
│ OrderId │ CustomerName │ Products                     │
├─────────┼──────────────┼─────────────────────────────┤
│ 1       │ John Smith   │ Laptop, Mouse, Keyboard     │
│ 2       │ Jane Doe     │ Phone, Case                 │
└─────────┴──────────────┴─────────────────────────────┘
❌ Products column contains multiple values
```

**After 1NF:**
```
Orders Table:
┌─────────┬──────────────┬─────────────┐
│ OrderId │ CustomerName │ ProductName │
├─────────┼──────────────┼─────────────┤
│ 1       │ John Smith   │ Laptop      │
│ 1       │ John Smith   │ Mouse       │
│ 1       │ John Smith   │ Keyboard    │
│ 2       │ Jane Doe     │ Phone       │
│ 2       │ Jane Doe     │ Case        │
└─────────┴──────────────┴─────────────┘
✅ Each column contains atomic values
```

### 2. Second Normal Form (2NF):

**Rules:**
- Must be in 1NF
- All non-key attributes are fully dependent on the primary key
- Remove partial dependencies

**Before 2NF (in 1NF but not 2NF):**
```
OrderItems Table:
┌─────────┬───────────┬─────────────┬──────────────┬──────────┐
│ OrderId │ ProductId │ ProductName │ CategoryName │ Quantity │
├─────────┼───────────┼─────────────┼──────────────┼──────────┤
│ 1       │ 100       │ Laptop      │ Electronics  │ 1        │
│ 1       │ 101       │ Mouse       │ Accessories  │ 2        │
│ 2       │ 100       │ Laptop      │ Electronics  │ 1        │
└─────────┴───────────┴─────────────┴──────────────┴──────────┘
Primary Key: (OrderId, ProductId)
❌ ProductName depends only on ProductId (partial dependency)
❌ CategoryName depends only on ProductId (partial dependency)
```

**After 2NF:**
```
OrderItems Table:
┌─────────┬───────────┬──────────┐
│ OrderId │ ProductId │ Quantity │
├─────────┼───────────┼──────────┤
│ 1       │ 100       │ 1        │
│ 1       │ 101       │ 2        │
│ 2       │ 100       │ 1        │
└─────────┴───────────┴──────────┘
✅ Only OrderId + ProductId → Quantity

Products Table:
┌───────────┬─────────────┬──────────────┐
│ ProductId │ ProductName │ CategoryName │
├───────────┼─────────────┼──────────────┤
│ 100       │ Laptop      │ Electronics  │
│ 101       │ Mouse       │ Accessories  │
└───────────┴─────────────┴──────────────┘
✅ ProductId → ProductName, CategoryName
```

### 3. Third Normal Form (3NF):

**Rules:**
- Must be in 2NF
- No transitive dependencies (non-key column depends on another non-key column)

**Before 3NF (in 2NF but not 3NF):**
```
Products Table:
┌───────────┬─────────────┬────────────┬──────────────────┐
│ ProductId │ ProductName │ CategoryId │ CategoryName     │
├───────────┼─────────────┼────────────┼──────────────────┤
│ 100       │ Laptop      │ 1          │ Electronics      │
│ 101       │ Mouse       │ 2          │ Accessories      │
│ 102       │ Phone       │ 1          │ Electronics      │
└───────────┴─────────────┴────────────┴──────────────────┘
Primary Key: ProductId
❌ CategoryName depends on CategoryId (transitive dependency)
❌ ProductId → CategoryId → CategoryName
```

**After 3NF:**
```
Products Table:
┌───────────┬─────────────┬────────────┐
│ ProductId │ ProductName │ CategoryId │
├───────────┼─────────────┼────────────┤
│ 100       │ Laptop      │ 1          │
│ 101       │ Mouse       │ 2          │
│ 102       │ Phone       │ 1          │
└───────────┴─────────────┴────────────┘
✅ ProductId → ProductName, CategoryId

Categories Table:
┌────────────┬──────────────┐
│ CategoryId │ CategoryName │
├────────────┼──────────────┤
│ 1          │ Electronics  │
│ 2          │ Accessories  │
└────────────┴──────────────┘
✅ CategoryId → CategoryName
```

### 4. Boyce-Codd Normal Form (BCNF):

**Rules:**
- Must be in 3NF
- Every determinant must be a candidate key

**Example:**
```sql
-- Before BCNF (in 3NF but not BCNF)
CREATE TABLE CourseInstructor (
    StudentId INT,
    CourseId INT,
    InstructorId INT,
    PRIMARY KEY (StudentId, CourseId)
);
-- Issue: InstructorId depends on CourseId
-- But (StudentId, CourseId) is the key

-- After BCNF
CREATE TABLE StudentCourse (
    StudentId INT,
    CourseId INT,
    PRIMARY KEY (StudentId, CourseId),
    FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
);

CREATE TABLE Course (
    CourseId INT PRIMARY KEY,
    InstructorId INT,
    FOREIGN KEY (InstructorId) REFERENCES Instructor(InstructorId)
);
```

### Complete E-Commerce Example:

**Normalized Database Design (3NF):**

```sql
-- Customers table
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) UNIQUE NOT NULL,
    Phone NVARCHAR(20),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Categories table
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500)
);

-- Products table
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryId INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId)
);

-- Orders table
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);

-- OrderItems table (junction table)
CREATE TABLE OrderItems (
    OrderItemId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- Addresses table (one-to-many with Customers)
CREATE TABLE Addresses (
    AddressId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    AddressType NVARCHAR(50) NOT NULL, -- 'Shipping' or 'Billing'
    Street NVARCHAR(200) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    State NVARCHAR(100) NOT NULL,
    ZipCode NVARCHAR(20) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
);
```

### Denormalization (When to Break Rules):

Sometimes we intentionally denormalize for performance:

```sql
-- Add redundant TotalAmount to Orders for quick access
-- Instead of calculating SUM(Quantity * UnitPrice) every time
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL, -- Denormalized
    Status NVARCHAR(50) NOT NULL
);

-- Maintain with trigger
CREATE TRIGGER trg_UpdateOrderTotal
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE Orders
    SET TotalAmount = (
        SELECT ISNULL(SUM(Quantity * UnitPrice), 0)
        FROM OrderItems
        WHERE OrderId = Orders.OrderId
    )
    WHERE OrderId IN (
        SELECT DISTINCT OrderId FROM inserted
        UNION
        SELECT DISTINCT OrderId FROM deleted
    );
END;
```

### Benefits vs. Trade-offs:

| Aspect | Normalized | Denormalized |
|--------|-----------|--------------|
| **Data Redundancy** | Minimal | Higher |
| **Data Integrity** | Better | Requires more maintenance |
| **Insert/Update** | Faster | Slower |
| **Read Performance** | Slower (more joins) | Faster |
| **Storage Space** | Less | More |
| **Complexity** | Higher (more tables) | Lower |

### Best Practices:

1. **OLTP Systems**: Normalize to 3NF for data integrity
2. **OLAP/Reporting**: Consider denormalization for performance
3. **Hybrid Approach**: Normalize tables, create denormalized views
4. **Use Foreign Keys**: Enforce referential integrity
5. **Index Properly**: Compensate for join performance

---

## Q180: What are Common Table Expressions (CTEs) in SQL Server?

**Common Table Expressions (CTEs)** are temporary named result sets that exist only during query execution. They make complex queries more readable and maintainable.

### Basic CTE Syntax:

```sql
WITH CTE_Name AS (
    -- CTE query definition
    SELECT column1, column2
    FROM table_name
    WHERE condition
)
-- Main query using the CTE
SELECT *
FROM CTE_Name;
```

### 1. Simple CTE Example:

```sql
-- Without CTE (subquery)
SELECT *
FROM (
    SELECT ProductId, ProductName, Price, CategoryId
    FROM Products
    WHERE Price > 100
) AS ExpensiveProducts
WHERE CategoryId = 1;

-- With CTE (more readable)
WITH ExpensiveProducts AS (
    SELECT ProductId, ProductName, Price, CategoryId
    FROM Products
    WHERE Price > 100
)
SELECT *
FROM ExpensiveProducts
WHERE CategoryId = 1;
```

### 2. Multiple CTEs:

```sql
-- Define multiple CTEs in one query
WITH
CustomerOrders AS (
    SELECT
        CustomerId,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    WHERE OrderDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY CustomerId
),
HighValueCustomers AS (
    SELECT CustomerId
    FROM CustomerOrders
    WHERE TotalSpent > 10000
)
SELECT
    c.CustomerName,
    c.Email,
    co.OrderCount,
    co.TotalSpent
FROM Customers c
INNER JOIN CustomerOrders co ON c.CustomerId = co.CustomerId
INNER JOIN HighValueCustomers hvc ON c.CustomerId = hvc.CustomerId
ORDER BY co.TotalSpent DESC;
```

### 3. Recursive CTEs:

**Recursive CTEs** reference themselves, useful for hierarchical data.

```sql
-- Employee hierarchy (manager-employee relationship)
WITH EmployeeHierarchy AS (
    -- Anchor member (base case)
    SELECT
        EmployeeId,
        EmployeeName,
        ManagerId,
        0 AS Level,
        CAST(EmployeeName AS NVARCHAR(MAX)) AS HierarchyPath
    FROM Employees
    WHERE ManagerId IS NULL  -- Top-level managers

    UNION ALL

    -- Recursive member
    SELECT
        e.EmployeeId,
        e.EmployeeName,
        e.ManagerId,
        eh.Level + 1,
        CAST(eh.HierarchyPath + ' -> ' + e.EmployeeName AS NVARCHAR(MAX))
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerId = eh.EmployeeId
)
SELECT
    EmployeeId,
    EmployeeName,
    Level,
    HierarchyPath
FROM EmployeeHierarchy
ORDER BY Level, EmployeeName;

-- Result:
-- Level 0: CEO
-- Level 1: VPs
-- Level 2: Directors
-- Level 3: Managers
-- Level 4: Individual Contributors
```

**Category Tree (Parent-Child Hierarchy):**

```sql
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY,
    CategoryName NVARCHAR(100),
    ParentCategoryId INT NULL,
    FOREIGN KEY (ParentCategoryId) REFERENCES Categories(CategoryId)
);

-- Sample data
INSERT INTO Categories VALUES
    (1, 'Electronics', NULL),
    (2, 'Computers', 1),
    (3, 'Laptops', 2),
    (4, 'Desktops', 2),
    (5, 'Gaming Laptops', 3),
    (6, 'Business Laptops', 3);

-- Recursive CTE to get full category path
WITH CategoryPath AS (
    -- Anchor: top-level categories
    SELECT
        CategoryId,
        CategoryName,
        ParentCategoryId,
        CAST(CategoryName AS NVARCHAR(1000)) AS FullPath,
        0 AS Level
    FROM Categories
    WHERE ParentCategoryId IS NULL

    UNION ALL

    -- Recursive: child categories
    SELECT
        c.CategoryId,
        c.CategoryName,
        c.ParentCategoryId,
        CAST(cp.FullPath + ' > ' + c.CategoryName AS NVARCHAR(1000)),
        cp.Level + 1
    FROM Categories c
    INNER JOIN CategoryPath cp ON c.ParentCategoryId = cp.CategoryId
)
SELECT
    CategoryId,
    CategoryName,
    FullPath,
    Level
FROM CategoryPath
ORDER BY FullPath;

-- Result:
-- Electronics
-- Electronics > Computers
-- Electronics > Computers > Laptops
-- Electronics > Computers > Laptops > Gaming Laptops
-- Electronics > Computers > Laptops > Business Laptops
-- Electronics > Computers > Desktops
```

### 4. CTE for Data Modification:

```sql
-- Update using CTE
WITH DuplicateProducts AS (
    SELECT
        ProductId,
        ProductName,
        ROW_NUMBER() OVER (PARTITION BY ProductName ORDER BY ProductId) AS RowNum
    FROM Products
)
DELETE FROM DuplicateProducts
WHERE RowNum > 1;  -- Keep first, delete duplicates

-- Insert using CTE
WITH NewCustomerOrders AS (
    SELECT
        CustomerId,
        COUNT(*) AS OrderCount
    FROM Orders
    WHERE OrderDate >= DATEADD(MONTH, -1, GETDATE())
    GROUP BY CustomerId
    HAVING COUNT(*) >= 5
)
INSERT INTO HighValueCustomers (CustomerId, Reason, DateAdded)
SELECT
    CustomerId,
    'Frequent buyer - ' + CAST(OrderCount AS VARCHAR(10)) + ' orders',
    GETDATE()
FROM NewCustomerOrders;
```

### 5. CTEs with Window Functions:

```sql
-- Running total using CTE and window functions
WITH MonthlySales AS (
    SELECT
        DATEPART(YEAR, OrderDate) AS Year,
        DATEPART(MONTH, OrderDate) AS Month,
        SUM(TotalAmount) AS MonthlySales
    FROM Orders
    GROUP BY DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate)
)
SELECT
    Year,
    Month,
    MonthlySales,
    SUM(MonthlySales) OVER (
        PARTITION BY Year
        ORDER BY Month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal,
    AVG(MonthlySales) OVER (
        ORDER BY Year, Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS ThreeMonthAvg
FROM MonthlySales
ORDER BY Year, Month;
```

### 6. Pagination with CTE:

```sql
-- Efficient pagination
WITH PaginatedProducts AS (
    SELECT
        ProductId,
        ProductName,
        Price,
        ROW_NUMBER() OVER (ORDER BY ProductName) AS RowNum
    FROM Products
)
SELECT
    ProductId,
    ProductName,
    Price
FROM PaginatedProducts
WHERE RowNum BETWEEN 21 AND 30  -- Page 3, 10 items per page
ORDER BY RowNum;
```

### C# Integration:

```csharp
public class ReportingService
{
    private readonly string _connectionString;

    // Get employee hierarchy using recursive CTE
    public async Task<List<EmployeeHierarchy>> GetEmployeeHierarchyAsync()
    {
        using var connection = new SqlConnection(_connectionString);

        var query = @"
            WITH EmployeeHierarchy AS (
                SELECT
                    EmployeeId,
                    EmployeeName,
                    ManagerId,
                    0 AS Level
                FROM Employees
                WHERE ManagerId IS NULL

                UNION ALL

                SELECT
                    e.EmployeeId,
                    e.EmployeeName,
                    e.ManagerId,
                    eh.Level + 1
                FROM Employees e
                INNER JOIN EmployeeHierarchy eh ON e.ManagerId = eh.EmployeeId
            )
            SELECT EmployeeId, EmployeeName, ManagerId, Level
            FROM EmployeeHierarchy
            ORDER BY Level, EmployeeName";

        using var command = new SqlCommand(query, connection);
        await connection.OpenAsync();

        using var reader = await command.ExecuteReaderAsync();

        var result = new List<EmployeeHierarchy>();
        while (await reader.ReadAsync())
        {
            result.Add(new EmployeeHierarchy
            {
                EmployeeId = reader.GetInt32(0),
                EmployeeName = reader.GetString(1),
                ManagerId = reader.IsDBNull(2) ? null : reader.GetInt32(2),
                Level = reader.GetInt32(3)
            });
        }

        return result;
    }

    // Get top customers using CTE
    public async Task<List<CustomerSummary>> GetTopCustomersAsync(int topN = 10)
    {
        using var connection = new SqlConnection(_connectionString);

        var query = @"
            WITH CustomerSales AS (
                SELECT
                    c.CustomerId,
                    c.CustomerName,
                    c.Email,
                    COUNT(o.OrderId) AS OrderCount,
                    SUM(o.TotalAmount) AS TotalSpent,
                    AVG(o.TotalAmount) AS AvgOrderValue,
                    MAX(o.OrderDate) AS LastOrderDate
                FROM Customers c
                INNER JOIN Orders o ON c.CustomerId = o.CustomerId
                GROUP BY c.CustomerId, c.CustomerName, c.Email
            )
            SELECT TOP (@TopN)
                CustomerId,
                CustomerName,
                Email,
                OrderCount,
                TotalSpent,
                AvgOrderValue,
                LastOrderDate
            FROM CustomerSales
            ORDER BY TotalSpent DESC";

        using var command = new SqlCommand(query, connection);
        command.Parameters.AddWithValue("@TopN", topN);

        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        var result = new List<CustomerSummary>();
        while (await reader.ReadAsync())
        {
            result.Add(new CustomerSummary
            {
                CustomerId = reader.GetInt32(0),
                CustomerName = reader.GetString(1),
                Email = reader.GetString(2),
                OrderCount = reader.GetInt32(3),
                TotalSpent = reader.GetDecimal(4),
                AvgOrderValue = reader.GetDecimal(5),
                LastOrderDate = reader.GetDateTime(6)
            });
        }

        return result;
    }
}
```

### CTE vs. Temp Table vs. Subquery:

| Feature | CTE | Temp Table | Subquery |
|---------|-----|------------|----------|
| **Scope** | Single query | Session | Single statement |
| **Reusability** | Can reference multiple times | Yes | Must repeat |
| **Performance** | Same as subquery | Can be indexed | Inline |
| **Readability** | Excellent | Good | Can be poor |
| **Recursion** | Yes | No | No |
| **Memory** | Not materialized | Materialized | Not materialized |

### Best Practices:

1. **Use for Complex Queries**: Break down into logical steps
2. **Recursive CTEs**: Limit with MAXRECURSION option to prevent infinite loops
3. **Performance**: CTEs are not materialized; consider temp tables for large datasets
4. **Naming**: Use descriptive names for better readability
5. **Multiple CTEs**: Separate concerns clearly

```sql
-- Limit recursion to prevent infinite loops
WITH RecursiveCTE AS (
    SELECT ...
    UNION ALL
    SELECT ...
)
SELECT * FROM RecursiveCTE
OPTION (MAXRECURSION 100);  -- Maximum 100 recursion levels
```

---

## Q181: What are window functions in SQL Server?

**Window functions** perform calculations across a set of rows related to the current row, without collapsing the result set like GROUP BY does.

### Window Function Syntax:

```sql
function_name() OVER (
    [PARTITION BY column]
    [ORDER BY column]
    [ROWS/RANGE frame_specification]
)
```

### Window Function Components:

```
┌──────────────────────────────────────────────────┐
│            Window Function Structure              │
├──────────────────────────────────────────────────┤
│                                                   │
│  PARTITION BY → Divides rows into groups         │
│  ORDER BY     → Defines order within partition   │
│  FRAME        → Specifies row range for calc     │
│                                                   │
└──────────────────────────────────────────────────┘
```

### 1. ROW_NUMBER():

Assigns unique sequential numbers to rows.

```sql
-- Assign row numbers to products ordered by price
SELECT
    ProductId,
    ProductName,
    CategoryId,
    Price,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS OverallRank,
    ROW_NUMBER() OVER (PARTITION BY CategoryId ORDER BY Price DESC) AS CategoryRank
FROM Products;

-- Result:
-- ProductId | ProductName | CategoryId | Price  | OverallRank | CategoryRank
-- 100       | Laptop      | 1          | 999.99 | 1           | 1
-- 101       | Desktop     | 1          | 799.99 | 2           | 2
-- 102       | Phone       | 2          | 699.99 | 3           | 1
-- 103       | Tablet      | 2          | 399.99 | 4           | 2
```

**Remove Duplicates:**
```sql
-- Delete duplicate rows keeping the first occurrence
WITH DuplicateRows AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Email
            ORDER BY CreatedDate
        ) AS RowNum
    FROM Customers
)
DELETE FROM DuplicateRows
WHERE RowNum > 1;
```

### 2. RANK() and DENSE_RANK():

Assign ranks with or without gaps for ties.

```sql
SELECT
    ProductId,
    ProductName,
    Price,
    RANK() OVER (ORDER BY Price DESC) AS Rank_WithGaps,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS Rank_NoGaps,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS RowNum
FROM Products;

-- If two products have same price:
-- ProductId | ProductName | Price  | Rank_WithGaps | Rank_NoGaps | RowNum
-- 100       | Laptop      | 999.99 | 1             | 1           | 1
-- 101       | Desktop     | 999.99 | 1             | 1           | 2  (tie)
-- 102       | Phone       | 799.99 | 3             | 2           | 3  (gap)
-- 103       | Tablet      | 699.99 | 4             | 3           | 4
```

**Use Case - Top N per Category:**
```sql
-- Get top 3 products per category by sales
WITH ProductSales AS (
    SELECT
        p.ProductId,
        p.ProductName,
        p.CategoryId,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalSales,
        DENSE_RANK() OVER (
            PARTITION BY p.CategoryId
            ORDER BY SUM(oi.Quantity * oi.UnitPrice) DESC
        ) AS SalesRank
    FROM Products p
    INNER JOIN OrderItems oi ON p.ProductId = oi.ProductId
    GROUP BY p.ProductId, p.ProductName, p.CategoryId
)
SELECT *
FROM ProductSales
WHERE SalesRank <= 3
ORDER BY CategoryId, SalesRank;
```

### 3. NTILE():

Distributes rows into a specified number of groups.

```sql
-- Divide customers into quartiles based on spending
SELECT
    CustomerId,
    CustomerName,
    TotalSpent,
    NTILE(4) OVER (ORDER BY TotalSpent DESC) AS SpendingQuartile
FROM (
    SELECT
        c.CustomerId,
        c.CustomerName,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerId = o.CustomerId
    GROUP BY c.CustomerId, c.CustomerName
) AS CustomerSpending;

-- Result:
-- Quartile 1: Top 25% spenders
-- Quartile 2: 25-50%
-- Quartile 3: 50-75%
-- Quartile 4: Bottom 25%
```

### 4. LAG() and LEAD():

Access data from previous or next rows.

```sql
-- Compare current month sales with previous month
WITH MonthlySales AS (
    SELECT
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalAmount) AS Sales
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT
    Year,
    Month,
    Sales,
    LAG(Sales, 1) OVER (ORDER BY Year, Month) AS PreviousMonthSales,
    LEAD(Sales, 1) OVER (ORDER BY Year, Month) AS NextMonthSales,
    Sales - LAG(Sales, 1, 0) OVER (ORDER BY Year, Month) AS SalesChange,
    CASE
        WHEN LAG(Sales) OVER (ORDER BY Year, Month) IS NULL THEN NULL
        ELSE ((Sales - LAG(Sales) OVER (ORDER BY Year, Month)) /
              LAG(Sales) OVER (ORDER BY Year, Month)) * 100
    END AS PercentChange
FROM MonthlySales
ORDER BY Year, Month;
```

**Stock Price Analysis:**
```sql
SELECT
    TradeDate,
    StockSymbol,
    ClosePrice,
    LAG(ClosePrice, 1) OVER (
        PARTITION BY StockSymbol
        ORDER BY TradeDate
    ) AS PreviousClose,
    ClosePrice - LAG(ClosePrice, 1) OVER (
        PARTITION BY StockSymbol
        ORDER BY TradeDate
    ) AS DailyChange
FROM StockPrices
ORDER BY StockSymbol, TradeDate;
```

### 5. FIRST_VALUE() and LAST_VALUE():

Get first or last value in a window.

```sql
-- Compare each order with customer's first and most recent orders
SELECT
    o.OrderId,
    o.CustomerId,
    o.OrderDate,
    o.TotalAmount,
    FIRST_VALUE(o.TotalAmount) OVER (
        PARTITION BY o.CustomerId
        ORDER BY o.OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS FirstOrderAmount,
    LAST_VALUE(o.TotalAmount) OVER (
        PARTITION BY o.CustomerId
        ORDER BY o.OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LatestOrderAmount
FROM Orders o
ORDER BY o.CustomerId, o.OrderDate;
```

### 6. Aggregate Window Functions:

SUM(), AVG(), COUNT(), MIN(), MAX() with OVER clause.

```sql
-- Running totals and moving averages
SELECT
    OrderDate,
    TotalAmount,
    -- Running total
    SUM(TotalAmount) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal,
    -- Moving average (last 7 days)
    AVG(TotalAmount) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS SevenDayAvg,
    -- Cumulative count
    COUNT(*) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeOrderCount,
    -- Percentage of total
    TotalAmount / SUM(TotalAmount) OVER () * 100 AS PercentOfTotal
FROM Orders
ORDER BY OrderDate;
```

**Year-to-Date (YTD) Calculations:**
```sql
SELECT
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS MonthlySales,
    SUM(SUM(TotalAmount)) OVER (
        PARTITION BY YEAR(OrderDate)
        ORDER BY MONTH(OrderDate)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS YTDSales
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;
```

### 7. Frame Specification (ROWS vs RANGE):

```sql
-- ROWS: Physical rows
SELECT
    OrderId,
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS AvgWith5RowWindow
FROM Orders;

-- RANGE: Logical range (includes ties)
SELECT
    OrderId,
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY OrderDate
        RANGE BETWEEN INTERVAL '2' DAY PRECEDING
                  AND INTERVAL '2' DAY FOLLOWING
    ) AS AvgWith5DayWindow
FROM Orders;
```

### Complex Example - Customer Analysis:

```sql
-- Comprehensive customer behavior analysis
WITH CustomerMetrics AS (
    SELECT
        o.CustomerId,
        o.OrderId,
        o.OrderDate,
        o.TotalAmount,
        -- Row number for each customer's orders
        ROW_NUMBER() OVER (
            PARTITION BY o.CustomerId
            ORDER BY o.OrderDate
        ) AS OrderSequence,
        -- Days since last order
        DATEDIFF(DAY,
            LAG(o.OrderDate) OVER (
                PARTITION BY o.CustomerId
                ORDER BY o.OrderDate
            ),
            o.OrderDate
        ) AS DaysSinceLastOrder,
        -- Running total per customer
        SUM(o.TotalAmount) OVER (
            PARTITION BY o.CustomerId
            ORDER BY o.OrderDate
            ROWS UNBOUNDED PRECEDING
        ) AS CustomerLifetimeValue,
        -- Average order value (last 3 orders)
        AVG(o.TotalAmount) OVER (
            PARTITION BY o.CustomerId
            ORDER BY o.OrderDate
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Avg3OrderValue,
        -- Rank orders by amount within customer
        DENSE_RANK() OVER (
            PARTITION BY o.CustomerId
            ORDER BY o.TotalAmount DESC
        ) AS OrderValueRank
    FROM Orders o
)
SELECT
    c.CustomerId,
    c.CustomerName,
    cm.OrderId,
    cm.OrderDate,
    cm.TotalAmount,
    cm.OrderSequence,
    cm.DaysSinceLastOrder,
    cm.CustomerLifetimeValue,
    cm.Avg3OrderValue,
    cm.OrderValueRank,
    CASE
        WHEN cm.DaysSinceLastOrder IS NULL THEN 'First Order'
        WHEN cm.DaysSinceLastOrder <= 30 THEN 'Active'
        WHEN cm.DaysSinceLastOrder <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END AS CustomerStatus
FROM CustomerMetrics cm
INNER JOIN Customers c ON cm.CustomerId = c.CustomerId
ORDER BY c.CustomerId, cm.OrderDate;
```

### C# Integration:

```csharp
public class AnalyticsService
{
    private readonly string _connectionString;

    // Get product rankings by category
    public async Task<List<ProductRanking>> GetProductRankingsByCategoryAsync()
    {
        using var connection = new SqlConnection(_connectionString);

        var query = @"
            WITH ProductSales AS (
                SELECT
                    p.ProductId,
                    p.ProductName,
                    p.CategoryId,
                    SUM(oi.Quantity) AS TotalUnitsSold,
                    SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue,
                    RANK() OVER (
                        PARTITION BY p.CategoryId
                        ORDER BY SUM(oi.Quantity * oi.UnitPrice) DESC
                    ) AS RevenueRank,
                    NTILE(4) OVER (
                        PARTITION BY p.CategoryId
                        ORDER BY SUM(oi.Quantity * oi.UnitPrice) DESC
                    ) AS PerformanceQuartile
                FROM Products p
                INNER JOIN OrderItems oi ON p.ProductId = oi.ProductId
                GROUP BY p.ProductId, p.ProductName, p.CategoryId
            )
            SELECT * FROM ProductSales
            ORDER BY CategoryId, RevenueRank";

        using var command = new SqlCommand(query, connection);
        await connection.OpenAsync();

        using var reader = await command.ExecuteReaderAsync();

        var result = new List<ProductRanking>();
        while (await reader.ReadAsync())
        {
            result.Add(new ProductRanking
            {
                ProductId = reader.GetInt32(0),
                ProductName = reader.GetString(1),
                CategoryId = reader.GetInt32(2),
                TotalUnitsSold = reader.GetInt32(3),
                TotalRevenue = reader.GetDecimal(4),
                RevenueRank = reader.GetInt64(5),
                PerformanceQuartile = reader.GetInt32(6)
            });
        }

        return result;
    }
}
```

### Best Practices:

1. **Use appropriate function**: ROW_NUMBER for unique ranks, DENSE_RANK for rankings
2. **Partition wisely**: Reduces computation scope
3. **Frame specification**: Be explicit with ROWS/RANGE for aggregates
4. **Performance**: Window functions can be expensive on large datasets
5. **Index support**: Ensure columns in PARTITION BY and ORDER BY are indexed


---

## Q182: What are Views in SQL Server and when should you use them?

**Views** are virtual tables based on the result set of a SQL query. They don't store data themselves but provide a way to simplify complex queries and control access to data.

### Basic View Syntax:

```sql
CREATE VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE condition;
```

### 1. Simple View:

```sql
-- Create a view for active products
CREATE VIEW vw_ActiveProducts AS
SELECT
    p.ProductId,
    p.ProductName,
    p.Price,
    c.CategoryName,
    p.StockQuantity
FROM Products p
INNER JOIN Categories c ON p.CategoryId = c.CategoryId
WHERE p.IsActive = 1 AND p.StockQuantity > 0;
GO

-- Use the view
SELECT * FROM vw_ActiveProducts
WHERE Price > 100
ORDER BY ProductName;
```

### 2. Complex View with Aggregations:

```sql
-- Customer summary view
CREATE VIEW vw_CustomerSummary AS
SELECT
    c.CustomerId,
    c.CustomerName,
    c.Email,
    COUNT(o.OrderId) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent,
    AVG(o.TotalAmount) AS AvgOrderValue,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId
GROUP BY c.CustomerId, c.CustomerName, c.Email;
GO

-- Query the view
SELECT * FROM vw_CustomerSummary
WHERE TotalSpent > 1000
ORDER BY TotalSpent DESC;
```

### 3. Indexed Views (Materialized Views):

**Indexed views physically store data** for improved query performance.

```sql
-- Create indexed view (requires specific settings)
CREATE VIEW vw_ProductSalesSummary
WITH SCHEMABINDING  -- Required for indexed views
AS
SELECT
    p.ProductId,
    p.ProductName,
    p.CategoryId,
    COUNT_BIG(*) AS OrderCount,  -- COUNT_BIG required for indexed views
    SUM(ISNULL(oi.Quantity, 0)) AS TotalUnitsSold,
    SUM(ISNULL(oi.Quantity * oi.UnitPrice, 0)) AS TotalRevenue
FROM dbo.Products p  -- Must use two-part names with SCHEMABINDING
INNER JOIN dbo.OrderItems oi ON p.ProductId = oi.ProductId
GROUP BY p.ProductId, p.ProductName, p.CategoryId;
GO

-- Create unique clustered index (materializes the view)
CREATE UNIQUE CLUSTERED INDEX IX_ProductSalesSummary_ProductId
ON vw_ProductSalesSummary(ProductId);
GO

-- Create additional non-clustered indexes
CREATE NONCLUSTERED INDEX IX_ProductSalesSummary_CategoryId
ON vw_ProductSalesSummary(CategoryId)
INCLUDE (TotalRevenue);
GO

-- Query automatically uses indexed view
SELECT * FROM vw_ProductSalesSummary
WHERE CategoryId = 1
ORDER BY TotalRevenue DESC;
```

### 4. Updatable Views:

```sql
-- Simple updatable view
CREATE VIEW vw_CustomerContacts AS
SELECT
    CustomerId,
    CustomerName,
    Email,
    Phone
FROM Customers;
GO

-- Update through view
UPDATE vw_CustomerContacts
SET Phone = '555-0123'
WHERE CustomerId = 1;

-- Insert through view
INSERT INTO vw_CustomerContacts (CustomerName, Email, Phone)
VALUES ('New Customer', 'new@example.com', '555-0199');

-- Delete through view
DELETE FROM vw_CustomerContacts
WHERE CustomerId = 100;
```

**Complex View with INSTEAD OF Trigger:**

```sql
-- View joining multiple tables
CREATE VIEW vw_OrderDetails AS
SELECT
    o.OrderId,
    o.OrderDate,
    c.CustomerName,
    c.Email,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice,
    oi.Quantity * oi.UnitPrice AS LineTotal
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.CustomerId
INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
INNER JOIN Products p ON oi.ProductId = p.ProductId;
GO

-- Make it updatable with INSTEAD OF trigger
CREATE TRIGGER trg_vw_OrderDetails_Update
ON vw_OrderDetails
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update OrderItems table
    UPDATE oi
    SET
        oi.Quantity = i.Quantity,
        oi.UnitPrice = i.UnitPrice
    FROM OrderItems oi
    INNER JOIN inserted i ON oi.OrderId = i.OrderId
    INNER JOIN Products p ON oi.ProductId = p.ProductId
    WHERE p.ProductName = i.ProductName;

    -- Update Orders table if OrderDate changed
    UPDATE o
    SET o.OrderDate = i.OrderDate
    FROM Orders o
    INNER JOIN inserted i ON o.OrderId = i.OrderId;
END;
GO
```

### 5. Security Views:

```sql
-- Hide sensitive columns
CREATE VIEW vw_EmployeePublic AS
SELECT
    EmployeeId,
    FirstName,
    LastName,
    Department,
    HireDate
    -- Exclude: Salary, SSN, DateOfBirth
FROM Employees;
GO

-- Grant access to view, not base table
GRANT SELECT ON vw_EmployeePublic TO PublicRole;
REVOKE SELECT ON Employees TO PublicRole;

-- Row-level security view
CREATE VIEW vw_ManagerEmployees AS
SELECT
    EmployeeId,
    FirstName,
    LastName,
    Department,
    Salary
FROM Employees
WHERE ManagerId = SUSER_ID();  -- Only see your direct reports
GO
```

### 6. Partitioned Views:

```sql
-- Horizontal partitioning across tables
CREATE VIEW vw_AllOrders AS
SELECT * FROM Orders_2023
WHERE YEAR(OrderDate) = 2023
UNION ALL
SELECT * FROM Orders_2024
WHERE YEAR(OrderDate) = 2024
UNION ALL
SELECT * FROM Orders_2025
WHERE YEAR(OrderDate) = 2025;
GO

-- SQL Server automatically eliminates unnecessary tables
SELECT * FROM vw_AllOrders
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
-- Only queries Orders_2024 table
```

### 7. View with CHECK OPTION:

```sql
-- Ensure updates/inserts meet view criteria
CREATE VIEW vw_ExpensiveProducts AS
SELECT
    ProductId,
    ProductName,
    Price,
    CategoryId
FROM Products
WHERE Price > 100
WITH CHECK OPTION;
GO

-- This succeeds
INSERT INTO vw_ExpensiveProducts (ProductName, Price, CategoryId)
VALUES ('Luxury Item', 500, 1);

-- This fails (Price <= 100)
INSERT INTO vw_ExpensiveProducts (ProductName, Price, CategoryId)
VALUES ('Cheap Item', 50, 1);
-- Error: The attempted insert or update failed because the target view
-- either specifies WITH CHECK OPTION or spans a view that specifies WITH CHECK OPTION
```

### View Metadata:

```sql
-- Get view definition
SELECT OBJECT_DEFINITION(OBJECT_ID('vw_CustomerSummary'));

-- Or use sp_helptext
EXEC sp_helptext 'vw_CustomerSummary';

-- List all views in database
SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ViewName,
    create_date,
    modify_date
FROM sys.views
ORDER BY name;

-- Check if view is indexed
SELECT
    v.name AS ViewName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.views v
INNER JOIN sys.indexes i ON v.object_id = i.object_id
WHERE i.index_id > 0
ORDER BY v.name, i.index_id;
```

### C# Integration:

```csharp
public class ProductService
{
    private readonly string _connectionString;

    // Query view (same as querying table)
    public async Task<List<Product>> GetActiveProductsAsync(decimal minPrice)
    {
        using var connection = new SqlConnection(_connectionString);

        // Querying view is identical to querying table
        var query = @"
            SELECT ProductId, ProductName, Price, CategoryName, StockQuantity
            FROM vw_ActiveProducts
            WHERE Price >= @MinPrice
            ORDER BY ProductName";

        using var command = new SqlCommand(query, connection);
        command.Parameters.AddWithValue("@MinPrice", minPrice);

        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        var products = new List<Product>();
        while (await reader.ReadAsync())
        {
            products.Add(new Product
            {
                ProductId = reader.GetInt32(0),
                ProductName = reader.GetString(1),
                Price = reader.GetDecimal(2),
                CategoryName = reader.GetString(3),
                StockQuantity = reader.GetInt32(4)
            });
        }

        return products;
    }

    // Update through view
    public async Task UpdateProductPriceThroughViewAsync(int productId, decimal newPrice)
    {
        using var connection = new SqlConnection(_connectionString);

        // Can update through simple views
        var query = "UPDATE vw_ActiveProducts SET Price = @Price WHERE ProductId = @ProductId";

        using var command = new SqlCommand(query, connection);
        command.Parameters.AddWithValue("@ProductId", productId);
        command.Parameters.AddWithValue("@Price", newPrice);

        await connection.OpenAsync();
        await command.ExecuteNonQueryAsync();
    }
}
```

### View vs. Stored Procedure vs. Table:

| Feature | View | Stored Procedure | Table |
|---------|------|------------------|-------|
| **Stores Data** | No (virtual) | No | Yes (physical) |
| **Parameters** | No | Yes | N/A |
| **Indexable** | Yes (indexed views) | No | Yes |
| **DML Operations** | Limited (INSERT/UPDATE/DELETE) | Full control | Full |
| **Performance** | Computed on query | Computed on execution | Direct access |
| **Reusable** | Yes | Yes | N/A |
| **Security** | Column/row level | Execution permission | Table level |

### When to Use Views:

✅ **Good Use Cases:**
- **Simplify complex queries** - Abstract joins and calculations
- **Security** - Hide sensitive columns, implement row-level security
- **Abstraction layer** - Decouple applications from schema changes
- **Computed columns** - Virtual calculated fields
- **Union multiple tables** - Combine data from partitioned tables

❌ **Avoid For:**
- **Heavy computations** - Use stored procedures instead
- **Nested views** - Performance degrades, hard to maintain
- **Aggregations without indexes** - Consider indexed views or summary tables

### Best Practices:

1. **Indexed Views** for frequently queried aggregations (OLAP scenarios)
2. **WITH SCHEMABINDING** prevents underlying table changes
3. **Avoid SELECT *** in view definitions
4. **Use WITH CHECK OPTION** for updatable views to maintain integrity
5. **Document views** with extended properties
6. **Monitor performance** - views can hide inefficient queries

```sql
-- Add documentation to view
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Active products with category information for public API',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'VIEW', @level1name = 'vw_ActiveProducts';
```

---

## Q183: What are User-Defined Functions (UDFs) in SQL Server?

**User-Defined Functions (UDFs)** are reusable routines that accept parameters, perform calculations or queries, and return results.

### Types of UDFs:

```
┌──────────────────────────────────────────────────┐
│           User-Defined Function Types             │
├──────────────────────────────────────────────────┤
│                                                   │
│  1. Scalar Functions    → Return single value    │
│  2. Inline TVF          → Return table (one query)│
│  3. Multi-statement TVF → Return table (complex) │
│                                                   │
└──────────────────────────────────────────────────┘
```

### 1. Scalar Functions:

Return a single value.

```sql
-- Calculate tax on a price
CREATE FUNCTION dbo.CalculateTax
(
    @Price DECIMAL(18,2),
    @TaxRate DECIMAL(5,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TaxAmount DECIMAL(18,2);
    SET @TaxAmount = @Price * (@TaxRate / 100);
    RETURN @TaxAmount;
END;
GO

-- Use the function
SELECT
    ProductId,
    ProductName,
    Price,
    dbo.CalculateTax(Price, 8.5) AS TaxAmount,
    Price + dbo.CalculateTax(Price, 8.5) AS TotalPrice
FROM Products;

-- Use in WHERE clause
SELECT * FROM Products
WHERE Price + dbo.CalculateTax(Price, 8.5) > 100;
```

**More Complex Scalar Function:**

```sql
-- Calculate discount based on customer loyalty
CREATE FUNCTION dbo.GetCustomerDiscount
(
    @CustomerId INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(5,2);
    DECLARE @TotalSpent DECIMAL(18,2);
    DECLARE @OrderCount INT;

    -- Get customer statistics
    SELECT
        @TotalSpent = SUM(TotalAmount),
        @OrderCount = COUNT(*)
    FROM Orders
    WHERE CustomerId = @CustomerId;

    -- Calculate discount tier
    SET @Discount = CASE
        WHEN @TotalSpent > 10000 OR @OrderCount > 50 THEN 20.00
        WHEN @TotalSpent > 5000 OR @OrderCount > 25 THEN 15.00
        WHEN @TotalSpent > 1000 OR @OrderCount > 10 THEN 10.00
        WHEN @OrderCount > 0 THEN 5.00
        ELSE 0.00
    END;

    RETURN @Discount;
END;
GO

-- Use the function
SELECT
    CustomerId,
    CustomerName,
    dbo.GetCustomerDiscount(CustomerId) AS DiscountPercent
FROM Customers;
```

### 2. Inline Table-Valued Functions (TVF):

Return a table based on a single SELECT statement. **Best performance** of all UDF types.

```sql
-- Get customer orders within date range
CREATE FUNCTION dbo.GetCustomerOrders
(
    @CustomerId INT,
    @StartDate DATE,
    @EndDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        o.OrderId,
        o.OrderDate,
        o.TotalAmount,
        o.Status,
        COUNT(oi.OrderItemId) AS ItemCount
    FROM Orders o
    INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
    WHERE o.CustomerId = @CustomerId
      AND o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY o.OrderId, o.OrderDate, o.TotalAmount, o.Status
);
GO

-- Use like a table
SELECT *
FROM dbo.GetCustomerOrders(123, '2024-01-01', '2024-12-31')
ORDER BY OrderDate DESC;

-- Join with other tables
SELECT
    c.CustomerName,
    co.OrderId,
    co.OrderDate,
    co.TotalAmount
FROM Customers c
CROSS APPLY dbo.GetCustomerOrders(c.CustomerId, '2024-01-01', '2024-12-31') co
WHERE co.TotalAmount > 100;
```

**Parameterized View with Inline TVF:**

```sql
-- Top N products by category
CREATE FUNCTION dbo.GetTopProductsByCategory
(
    @CategoryId INT,
    @TopN INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        p.ProductId,
        p.ProductName,
        p.Price,
        p.StockQuantity,
        ISNULL(SUM(oi.Quantity), 0) AS TotalSold
    FROM Products p
    LEFT JOIN OrderItems oi ON p.ProductId = oi.ProductId
    WHERE p.CategoryId = @CategoryId
    GROUP BY p.ProductId, p.ProductName, p.Price, p.StockQuantity
    ORDER BY TotalSold DESC
);
GO

-- Get top 10 products in category 1
SELECT * FROM dbo.GetTopProductsByCategory(1, 10);
```

### 3. Multi-Statement Table-Valued Functions:

Return a table variable with complex logic. **Slower than inline TVFs**.

```sql
-- Split delimited string into table
CREATE FUNCTION dbo.SplitString
(
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE
(
    Id INT IDENTITY(1,1),
    Value NVARCHAR(MAX)
)
AS
BEGIN
    DECLARE @Start INT = 1;
    DECLARE @End INT;

    WHILE @Start <= LEN(@String)
    BEGIN
        SET @End = CHARINDEX(@Delimiter, @String, @Start);

        IF @End = 0
            SET @End = LEN(@String) + 1;

        INSERT INTO @Result (Value)
        VALUES (SUBSTRING(@String, @Start, @End - @Start));

        SET @Start = @End + 1;
    END;

    RETURN;
END;
GO

-- Use the function
SELECT * FROM dbo.SplitString('Apple,Orange,Banana,Grape', ',');

-- Result:
-- Id | Value
-- 1  | Apple
-- 2  | Orange
-- 3  | Banana
-- 4  | Grape
```

**Order Summary with Complex Logic:**

```sql
CREATE FUNCTION dbo.GetOrderSummary
(
    @OrderId INT
)
RETURNS @Summary TABLE
(
    OrderId INT,
    CustomerName NVARCHAR(200),
    OrderDate DATETIME,
    ItemCount INT,
    Subtotal DECIMAL(18,2),
    Tax DECIMAL(18,2),
    Shipping DECIMAL(18,2),
    Total DECIMAL(18,2)
)
AS
BEGIN
    DECLARE @Subtotal DECIMAL(18,2);
    DECLARE @Tax DECIMAL(18,2);
    DECLARE @Shipping DECIMAL(18,2);
    DECLARE @ItemCount INT;

    -- Calculate subtotal and item count
    SELECT
        @Subtotal = SUM(Quantity * UnitPrice),
        @ItemCount = SUM(Quantity)
    FROM OrderItems
    WHERE OrderId = @OrderId;

    -- Calculate tax (8.5%)
    SET @Tax = @Subtotal * 0.085;

    -- Calculate shipping
    SET @Shipping = CASE
        WHEN @Subtotal > 100 THEN 0.00  -- Free shipping
        WHEN @Subtotal > 50 THEN 5.00
        ELSE 10.00
    END;

    -- Insert summary
    INSERT INTO @Summary
    SELECT
        o.OrderId,
        c.CustomerName,
        o.OrderDate,
        @ItemCount,
        @Subtotal,
        @Tax,
        @Shipping,
        @Subtotal + @Tax + @Shipping
    FROM Orders o
    INNER JOIN Customers c ON o.CustomerId = c.CustomerId
    WHERE o.OrderId = @OrderId;

    RETURN;
END;
GO

-- Use the function
SELECT * FROM dbo.GetOrderSummary(12345);
```

### 4. Built-in Functions vs UDFs:

```sql
-- Combine built-in and user-defined functions
SELECT
    ProductId,
    ProductName,
    Price,
    UPPER(ProductName) AS ProductNameUpper,  -- Built-in
    LEN(ProductName) AS NameLength,  -- Built-in
    dbo.CalculateTax(Price, 8.5) AS Tax,  -- UDF
    DATEADD(DAY, 30, GETDATE()) AS EstimatedDelivery  -- Built-in
FROM Products;
```

### 5. Deterministic vs Non-Deterministic Functions:

```sql
-- Deterministic (always same output for same input)
CREATE FUNCTION dbo.AddNumbers
(
    @A INT,
    @B INT
)
RETURNS INT
WITH SCHEMABINDING  -- Required for deterministic functions in indexed views
AS
BEGIN
    RETURN @A + @B;
END;
GO

-- Non-Deterministic (output varies)
CREATE FUNCTION dbo.GetCurrentAge
(
    @BirthDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @BirthDate, GETDATE());
    -- Non-deterministic because GETDATE() changes
END;
GO
```

### C# Integration:

```csharp
public class OrderService
{
    private readonly string _connectionString;

    // Call scalar function
    public async Task<decimal> CalculateTaxAsync(decimal price, decimal taxRate)
    {
        using var connection = new SqlConnection(_connectionString);

        var query = "SELECT dbo.CalculateTax(@Price, @TaxRate)";

        using var command = new SqlCommand(query, connection);
        command.Parameters.AddWithValue("@Price", price);
        command.Parameters.AddWithValue("@TaxRate", taxRate);

        await connection.OpenAsync();

        var tax = (decimal)await command.ExecuteScalarAsync();
        return tax;
    }

    // Call table-valued function
    public async Task<List<Order>> GetCustomerOrdersAsync(
        int customerId,
        DateTime startDate,
        DateTime endDate)
    {
        using var connection = new SqlConnection(_connectionString);

        // Query TVF like a table
        var query = @"
            SELECT OrderId, OrderDate, TotalAmount, Status, ItemCount
            FROM dbo.GetCustomerOrders(@CustomerId, @StartDate, @EndDate)
            ORDER BY OrderDate DESC";

        using var command = new SqlCommand(query, connection);
        command.Parameters.AddWithValue("@CustomerId", customerId);
        command.Parameters.AddWithValue("@StartDate", startDate);
        command.Parameters.AddWithValue("@EndDate", endDate);

        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        var orders = new List<Order>();
        while (await reader.ReadAsync())
        {
            orders.Add(new Order
            {
                OrderId = reader.GetInt32(0),
                OrderDate = reader.GetDateTime(1),
                TotalAmount = reader.GetDecimal(2),
                Status = reader.GetString(3),
                ItemCount = reader.GetInt32(4)
            });
        }

        return orders;
    }
}
```

### Performance Considerations:

| Function Type | Performance | Use Case |
|--------------|-------------|----------|
| **Inline TVF** | Excellent (like views) | Parameterized queries |
| **Scalar UDF** | Poor (row-by-row) | Simple calculations |
| **Multi-statement TVF** | Moderate | Complex logic |

**Performance Anti-Pattern:**

```sql
-- ❌ BAD: Scalar function in WHERE clause (full table scan)
SELECT * FROM Orders
WHERE dbo.GetCustomerDiscount(CustomerId) > 10;

-- ✅ GOOD: Join with inline TVF or pre-calculate
WITH CustomerDiscounts AS (
    SELECT CustomerId, dbo.GetCustomerDiscount(CustomerId) AS Discount
    FROM (SELECT DISTINCT CustomerId FROM Orders) c
)
SELECT o.*
FROM Orders o
INNER JOIN CustomerDiscounts cd ON o.CustomerId = cd.CustomerId
WHERE cd.Discount > 10;
```

### Best Practices:

1. **Prefer Inline TVFs** over multi-statement TVFs for better performance
2. **Avoid Scalar UDFs in WHERE clauses** - causes row-by-row execution
3. **Use WITH SCHEMABINDING** for deterministic functions
4. **Consider Computed Columns** instead of scalar UDFs called repeatedly
5. **Use CROSS APPLY/OUTER APPLY** with TVFs for efficient joins

```sql
-- Using CROSS APPLY with TVF (efficient)
SELECT
    c.CustomerId,
    c.CustomerName,
    co.OrderId,
    co.TotalAmount
FROM Customers c
CROSS APPLY dbo.GetCustomerOrders(c.CustomerId, '2024-01-01', '2024-12-31') co
WHERE co.TotalAmount > 100;
```


---

## Q184-Q200: Additional SQL Server Topics (Summary Format)

Due to the comprehensive coverage of Q172-Q183, the remaining questions (Q184-Q200) are provided in concise summary format covering essential SQL Server topics.

---

## Q184: What are Constraints in SQL Server?

**Constraints** enforce data integrity rules at the database level.

### Types of Constraints:

```sql
-- PRIMARY KEY
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL
);

-- FOREIGN KEY
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
        ON DELETE CASCADE  -- Delete orders when customer deleted
        ON UPDATE CASCADE  -- Update OrderId when CustomerId changes
);

-- UNIQUE
CREATE TABLE Users (
    UserId INT PRIMARY KEY,
    Email NVARCHAR(200) UNIQUE NOT NULL  -- No duplicate emails
);

-- CHECK
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,
    Price DECIMAL(18,2) CHECK (Price > 0),  -- Price must be positive
    StockQuantity INT CHECK (StockQuantity >= 0)
);

-- DEFAULT
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50) DEFAULT 'Pending'
);

-- NOT NULL
CREATE TABLE Employees (
    EmployeeId INT PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,  -- Required field
    LastName NVARCHAR(100) NOT NULL
);
```

---

## Q185: What are Deadlocks and how do you handle them?

**Deadlocks** occur when two or more transactions block each other by holding locks on resources the others need.

### Example & Prevention:

```sql
-- Deadlock scenario
-- Transaction 1:
BEGIN TRANSACTION;
UPDATE Products SET Price = 100 WHERE ProductId = 1;  -- Locks Product 1
-- Waiting...
UPDATE Products SET Price = 200 WHERE ProductId = 2;  -- Wants Product 2
COMMIT;

-- Transaction 2 (simultaneously):
BEGIN TRANSACTION;
UPDATE Products SET Price = 300 WHERE ProductId = 2;  -- Locks Product 2
-- Waiting...
UPDATE Products SET Price = 400 WHERE ProductId = 1;  -- Wants Product 1 (DEADLOCK!)
COMMIT;

-- Prevention: Access resources in same order
-- Both transactions:
BEGIN TRANSACTION;
UPDATE Products SET Price = X WHERE ProductId = 1;  -- Always 1 first
UPDATE Products SET Price = Y WHERE ProductId = 2;  -- Then 2
COMMIT;

-- Detect deadlocks
SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id <> 0;

-- Set deadlock priority (lower priority transaction is killed)
SET DEADLOCK_PRIORITY LOW;
```

---

## Q186: Explain SQL Server Backup and Recovery strategies.

### Backup Types:

```sql
-- Full Backup (entire database)
BACKUP DATABASE YourDatabase
TO DISK = 'C:\Backups\YourDatabase_Full.bak'
WITH INIT, COMPRESSION;

-- Differential Backup (changes since last full)
BACKUP DATABASE YourDatabase
TO DISK = 'C:\Backups\YourDatabase_Diff.bak'
WITH DIFFERENTIAL, COMPRESSION;

-- Transaction Log Backup (for point-in-time recovery)
BACKUP LOG YourDatabase
TO DISK = 'C:\Backups\YourDatabase_Log.trn'
WITH COMPRESSION;

-- Restore sequence
RESTORE DATABASE YourDatabase
FROM DISK = 'C:\Backups\YourDatabase_Full.bak'
WITH NORECOVERY;  -- Don't bring online yet

RESTORE DATABASE YourDatabase
FROM DISK = 'C:\Backups\YourDatabase_Diff.bak'
WITH NORECOVERY;

RESTORE LOG YourDatabase
FROM DISK = 'C:\Backups\YourDatabase_Log.trn'
WITH RECOVERY;  -- Now bring online
```

**Recovery Models:**
- **Simple**: No log backups, minimal log space
- **Full**: Point-in-time recovery, requires log backups
- **Bulk-Logged**: Optimized for bulk operations

---

## Q187: What is SQL Server Profiler and Extended Events?

**Profiler** and **Extended Events** capture and analyze SQL Server activity.

```sql
-- Extended Events session (modern approach)
CREATE EVENT SESSION [SlowQueries]
ON SERVER
ADD EVENT sqlserver.sql_batch_completed(
    WHERE duration > 5000000  -- 5 seconds in microseconds
)
ADD TARGET package0.event_file(
    SET filename = N'C:\Logs\SlowQueries.xel'
);
GO

-- Start session
ALTER EVENT SESSION [SlowQueries] ON SERVER STATE = START;

-- Query Extended Events data
SELECT
    CAST(event_data AS XML).value('(event/@timestamp)[1]', 'datetime2') AS EventTime,
    CAST(event_data AS XML).value('(event/data[@name="duration"]/value)[1]', 'bigint') / 1000000.0 AS DurationSeconds,
    CAST(event_data AS XML).value('(event/data[@name="batch_text"]/value)[1]', 'varchar(max)') AS QueryText
FROM sys.fn_xe_file_target_read_file('C:\Logs\SlowQueries*.xel', NULL, NULL, NULL);
```

---

## Q188: What are Dynamic SQL and its security considerations?

**Dynamic SQL** constructs and executes SQL statements at runtime.

```sql
-- Using EXECUTE
DECLARE @TableName NVARCHAR(128) = 'Products';
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = 'SELECT * FROM ' + QUOTENAME(@TableName);
EXEC(@SQL);

-- Using sp_executesql (preferred - parameterized)
DECLARE @SQL NVARCHAR(MAX);
DECLARE @MinPrice DECIMAL(18,2) = 100;

SET @SQL = N'SELECT * FROM Products WHERE Price > @PriceParam';

EXEC sp_executesql @SQL,
    N'@PriceParam DECIMAL(18,2)',  -- Parameter definition
    @PriceParam = @MinPrice;

-- ❌ SQL Injection vulnerability
DECLARE @SearchTerm NVARCHAR(100) = '''; DROP TABLE Products; --';
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM Products WHERE ProductName = ''' + @SearchTerm + '''';
EXEC(@SQL);  -- DANGEROUS!

-- ✅ Safe with sp_executesql and parameters
EXEC sp_executesql
    N'SELECT * FROM Products WHERE ProductName = @Search',
    N'@Search NVARCHAR(100)',
    @Search = @SearchTerm;
```

---

## Q189: Explain Cursors in SQL Server.

**Cursors** allow row-by-row processing. **Avoid when possible** - use set-based operations.

```sql
-- Cursor example (generally avoid)
DECLARE @ProductId INT, @ProductName NVARCHAR(200);

DECLARE ProductCursor CURSOR FOR
SELECT ProductId, ProductName FROM Products;

OPEN ProductCursor;

FETCH NEXT FROM ProductCursor INTO @ProductId, @ProductName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing: ' + @ProductName;

    -- Do something with each row
    UPDATE Products SET LastProcessed = GETDATE() WHERE ProductId = @ProductId;

    FETCH NEXT FROM ProductCursor INTO @ProductId, @ProductName;
END;

CLOSE ProductCursor;
DEALLOCATE ProductCursor;

-- ✅ Better: Set-based operation
UPDATE Products SET LastProcessed = GETDATE();  -- Updates all rows at once
```

---

## Q190: What is Database Partitioning?

**Partitioning** divides large tables into smaller, manageable pieces.

```sql
-- Create partition function
CREATE PARTITION FUNCTION PF_OrderDate (DATETIME)
AS RANGE RIGHT FOR VALUES
    ('2023-01-01', '2024-01-01', '2025-01-01');

-- Create partition scheme
CREATE PARTITION SCHEME PS_OrderDate
AS PARTITION PF_OrderDate
TO (FG_2022, FG_2023, FG_2024, FG_2025);

-- Create partitioned table
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    OrderDate DATETIME NOT NULL,
    TotalAmount DECIMAL(18,2)
) ON PS_OrderDate(OrderDate);

-- Query specific partition
SELECT * FROM Orders
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
-- Only accesses 2024 partition
```

---

## Q191: What are Temporary Tables and Table Variables?

```sql
-- Local Temporary Table (session-scoped)
CREATE TABLE #TempOrders (
    OrderId INT,
    CustomerName NVARCHAR(200),
    TotalAmount DECIMAL(18,2)
);

INSERT INTO #TempOrders
SELECT o.OrderId, c.CustomerName, o.TotalAmount
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.CustomerId;

SELECT * FROM #TempOrders;
-- Dropped automatically at session end

-- Global Temporary Table (all sessions)
CREATE TABLE ##GlobalTemp (
    Id INT,
    Value NVARCHAR(100)
);

-- Table Variable (faster for small datasets)
DECLARE @OrderSummary TABLE (
    CustomerId INT,
    OrderCount INT,
    TotalSpent DECIMAL(18,2)
);

INSERT INTO @OrderSummary
SELECT CustomerId, COUNT(*), SUM(TotalAmount)
FROM Orders
GROUP BY CustomerId;

SELECT * FROM @OrderSummary;
```

**When to use:**
- **Temp Table**: Large datasets, need indexes
- **Table Variable**: Small datasets (<1000 rows), simpler queries

---

## Q192: What is the difference between UNION and UNION ALL?

```sql
-- UNION: Removes duplicates (slower)
SELECT ProductName FROM Products WHERE CategoryId = 1
UNION
SELECT ProductName FROM Products WHERE CategoryId = 2;

-- UNION ALL: Keeps duplicates (faster)
SELECT ProductName FROM Products WHERE CategoryId = 1
UNION ALL
SELECT ProductName FROM Products WHERE CategoryId = 2;

-- Use UNION ALL when you know there are no duplicates or duplicates are OK
```

---

## Q193: Explain PIVOT and UNPIVOT operations.

```sql
-- Sample data
CREATE TABLE Sales (
    Year INT,
    Quarter NVARCHAR(2),
    Amount DECIMAL(18,2)
);

-- PIVOT: Rows to columns
SELECT *
FROM (
    SELECT Year, Quarter, Amount FROM Sales
) AS SourceTable
PIVOT (
    SUM(Amount)
    FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS PivotTable;

-- Result:
-- Year | Q1    | Q2    | Q3    | Q4
-- 2024 | 10000 | 12000 | 15000 | 18000

-- UNPIVOT: Columns to rows
SELECT Year, Quarter, Amount
FROM (
    SELECT Year, Q1, Q2, Q3, Q4 FROM QuarterlySales
) AS SourceTable
UNPIVOT (
    Amount FOR Quarter IN (Q1, Q2, Q3, Q4)
) AS UnpivotTable;
```

---

## Q194: What are Database Roles and Permissions?

```sql
-- Create database role
CREATE ROLE ReadOnlyRole;

-- Grant permissions
GRANT SELECT ON SCHEMA::dbo TO ReadOnlyRole;

-- Deny permissions
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO ReadOnlyRole;

-- Add user to role
ALTER ROLE ReadOnlyRole ADD MEMBER [UserName];

-- Row-level security
CREATE FUNCTION dbo.SecurityPredicate(@CustomerId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS RETURN (
    SELECT 1 AS Result
    WHERE @CustomerId = CAST(SESSION_CONTEXT(N'CustomerId') AS INT)
);

CREATE SECURITY POLICY CustomerFilter
ADD FILTER PREDICATE dbo.SecurityPredicate(CustomerId)
ON dbo.Orders
WITH (STATE = ON);
```

---

## Q195: What is the purpose of MERGE statement?

```sql
-- MERGE: Upsert (INSERT or UPDATE)
MERGE INTO Products AS Target
USING StagingProducts AS Source
ON Target.ProductId = Source.ProductId
WHEN MATCHED THEN
    UPDATE SET
        Target.ProductName = Source.ProductName,
        Target.Price = Source.Price
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductId, ProductName, Price)
    VALUES (Source.ProductId, Source.ProductName, Source.Price)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

-- OUTPUT clause to see changes
MERGE INTO Products AS Target
USING StagingProducts AS Source
ON Target.ProductId = Source.ProductId
WHEN MATCHED THEN UPDATE SET Price = Source.Price
WHEN NOT MATCHED THEN INSERT VALUES (Source.ProductId, Source.ProductName, Source.Price)
OUTPUT $action, INSERTED.*, DELETED.*;
```

---

## Q196: What are Performance Tuning best practices?

**Key Strategies:**

1. **Indexing**
   - Create indexes on WHERE, JOIN, ORDER BY columns
   - Use covering indexes
   - Monitor missing indexes DMV

2. **Query Optimization**
   - Avoid SELECT *
   - Use EXISTS instead of COUNT(*) > 0
   - Minimize subqueries
   - Use UNION ALL instead of UNION when possible

3. **Statistics**
   - Keep statistics updated
   - Use UPDATE STATISTICS WITH FULLSCAN

4. **Execution Plans**
   - Analyze query plans regularly
   - Look for table scans, key lookups

5. **Avoid**
   - Scalar UDFs in WHERE clauses
   - Functions on indexed columns
   - Cursors (use set-based operations)
   - Over-indexing (slows INSERT/UPDATE)

```sql
-- Performance monitoring queries
-- Top 10 slowest queries
SELECT TOP 10
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE WHEN qs.statement_end_offset = -1
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_elapsed_time DESC;
```

---

## Q197: What is Always On Availability Groups?

**Always On Availability Groups** provide high availability and disaster recovery.

```sql
-- Create availability group (simplified)
CREATE AVAILABILITY GROUP AG1
FOR DATABASE YourDatabase
REPLICA ON
    'SERVER1' WITH (
        ENDPOINT_URL = 'TCP://Server1.domain.com:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC
    ),
    'SERVER2' WITH (
        ENDPOINT_URL = 'TCP://Server2.domain.com:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC
    );

-- Read from secondary replica
-- Connection string: ApplicationIntent=ReadOnly
SELECT * FROM Products WITH (READPAST);  -- Read from secondary
```

**Features:**
- Automatic failover
- Read-only secondaries
- Multiple replicas
- Load balancing for read queries

---

## Q198: Explain Database Mirroring vs Replication.

| Feature | Mirroring | Replication |
|---------|-----------|-------------|
| **Purpose** | HA/DR | Data distribution |
| **Databases** | Entire database | Specific tables/data |
| **Latency** | Low | Can be higher |
| **Secondary Access** | Read-only snapshot | Read/write |
| **Automatic Failover** | Yes | No |
| **Use Case** | High availability | Reporting, distribution |

```sql
-- Mirroring setup (simplified)
-- On principal:
BACKUP DATABASE YourDatabase TO DISK = 'C:\Backup\YourDB.bak';
BACKUP LOG YourDatabase TO DISK = 'C:\Backup\YourDB.trn';

-- On mirror:
RESTORE DATABASE YourDatabase FROM DISK = 'C:\Backup\YourDB.bak' WITH NORECOVERY;
RESTORE LOG YourDatabase FROM DISK = 'C:\Backup\YourDB.trn' WITH NORECOVERY;

-- Replication (snapshot example)
-- Create publication
EXEC sp_addpublication
    @publication = 'ProductsPublication',
    @description = 'Product catalog for reporting';

-- Add article
EXEC sp_addarticle
    @publication = 'ProductsPublication',
    @article = 'Products',
    @source_table = 'Products';
```

---

## Q199: What are Memory-Optimized Tables (In-Memory OLTP)?

**Memory-Optimized Tables** store data entirely in memory for extreme performance.

```sql
-- Create memory-optimized filegroup
ALTER DATABASE YourDatabase
ADD FILEGROUP MemoryOptimizedFG CONTAINS MEMORY_OPTIMIZED_DATA;

ALTER DATABASE YourDatabase
ADD FILE (NAME = 'MemoryOptimizedFile',
          FILENAME = 'C:\Data\MemoryOptimized')
TO FILEGROUP MemoryOptimizedFG;

-- Create memory-optimized table
CREATE TABLE Products_InMemory (
    ProductId INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000000),
    ProductName NVARCHAR(200) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    INDEX IX_Price NONCLUSTERED (Price)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

-- Natively compiled stored procedure
CREATE PROCEDURE GetProduct_Native
    @ProductId INT
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english'
)
    SELECT ProductId, ProductName, Price
    FROM dbo.Products_InMemory
    WHERE ProductId = @ProductId;
END;
GO
```

**Benefits:**
- 10-30x faster than disk-based tables
- Lock-free architecture
- Reduced lock contention

**Limitations:**
- Requires sufficient memory
- Some T-SQL features not supported
- Cannot alter table structure (must drop/recreate)

---

## Q200: What are JSON functions in SQL Server?

**SQL Server 2016+** provides built-in JSON support.

```sql
-- JSON string
DECLARE @json NVARCHAR(MAX) = N'{
    "orderId": 12345,
    "customer": {
        "name": "John Smith",
        "email": "john@example.com"
    },
    "items": [
        {"productId": 1, "quantity": 2, "price": 25.00},
        {"productId": 2, "quantity": 1, "price": 50.00}
    ]
}';

-- Extract values
SELECT
    JSON_VALUE(@json, '$.orderId') AS OrderId,
    JSON_VALUE(@json, '$.customer.name') AS CustomerName,
    JSON_VALUE(@json, '$.customer.email') AS Email;

-- Parse JSON array
SELECT *
FROM OPENJSON(@json, '$.items')
WITH (
    productId INT '$.productId',
    quantity INT '$.quantity',
    price DECIMAL(18,2) '$.price'
);

-- Create JSON from query
SELECT
    OrderId,
    OrderDate,
    TotalAmount,
    (
        SELECT ProductId, Quantity, UnitPrice
        FROM OrderItems oi
        WHERE oi.OrderId = o.OrderId
        FOR JSON PATH
    ) AS Items
FROM Orders o
WHERE CustomerId = 123
FOR JSON PATH, ROOT('orders');

-- Result:
-- {
--   "orders": [
--     {
--       "OrderId": 1,
--       "OrderDate": "2024-01-15",
--       "TotalAmount": 100.00,
--       "Items": [
--         {"ProductId": 1, "Quantity": 2, "UnitPrice": 25.00},
--         {"ProductId": 2, "Quantity": 1, "UnitPrice": 50.00}
--       ]
--     }
--   ]
-- }

-- JSON in C#
public async Task<Order> ParseOrderJsonAsync(string json)
{
    using var connection = new SqlConnection(_connectionString);

    var query = @"
        SELECT
            JSON_VALUE(@Json, '$.orderId') AS OrderId,
            JSON_VALUE(@Json, '$.customer.name') AS CustomerName";

    using var command = new SqlCommand(query, connection);
    command.Parameters.AddWithValue("@Json", json);

    await connection.OpenAsync();
    using var reader = await command.ExecuteReaderAsync();

    if (await reader.ReadAsync())
    {
        return new Order
        {
            OrderId = reader.GetInt32(0),
            CustomerName = reader.GetString(1)
        };
    }

    return null;
}
```

---

## Summary: Q172-Q200 Completed! ✅

**Topics Covered:**
- Q172-Q174: Joins, Indexes, Stored Procedures
- Q175-Q178: Triggers, Transactions, Isolation Levels, Query Optimization
- Q179-Q181: Normalization, CTEs, Window Functions
- Q182-Q183: Views, User-Defined Functions
- Q184-Q200: Constraints, Deadlocks, Backups, Security, Performance, Advanced Features

**All 29 SQL Server & Database questions answered comprehensively!**

---

*End of Q172-Q200 SQL Server & Database Section*
