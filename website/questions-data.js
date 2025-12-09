// ==================== Questions Database ====================
// This file contains all interview questions organized by section

const questionsDatabase = [
    // ==================== Advanced .NET & ASP.NET Core (Q91-Q99) ====================
    {
        number: 91,
        title: "What is Dependency Injection in ASP.NET Core and how do you use it?",
        section: "dotnet-advanced",
        difficulty: "intermediate",
        content: `
**Dependency Injection (DI)** is a design pattern where objects receive their dependencies from an external source rather than creating them internally.

### Service Lifetimes:

**1. Transient**: Created each time they're requested
**2. Scoped**: Created once per request
**3. Singleton**: Created once for the application lifetime

### Example:

\`\`\`csharp
// Register services
builder.Services.AddTransient<IProductService, ProductService>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddSingleton<ICacheService, CacheService>();

// Use in controller
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts()
    {
        var products = await _productService.GetAllProductsAsync();
        return Ok(products);
    }
}
\`\`\`

### Best Practices:
- Use Scoped for services that maintain state during a request
- Use Singleton for stateless services and caching
- Avoid Singleton services depending on Scoped services
`
    },
    {
        number: 92,
        title: "Explain Middleware in ASP.NET Core",
        section: "dotnet-advanced",
        difficulty: "intermediate",
        content: `
**Middleware** are components that handle HTTP requests and responses in a pipeline.

### Custom Middleware Example:

\`\`\`csharp
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = Guid.NewGuid().ToString();
        _logger.LogInformation("Request {RequestId}: {Method} {Path}",
            requestId, context.Request.Method, context.Request.Path);

        await _next(context);  // Call next middleware

        _logger.LogInformation("Response {RequestId}: {StatusCode}",
            requestId, context.Response.StatusCode);
    }
}

// Register in Program.cs
app.UseMiddleware<RequestLoggingMiddleware>();
\`\`\`

### Middleware Order:
1. Exception handling
2. HTTPS redirection
3. Static files
4. Authentication
5. Authorization
6. Custom middleware
7. Endpoints
`
    },
    {
        number: 93,
        title: "What is Authentication and Authorization in ASP.NET Core?",
        section: "dotnet-advanced",
        difficulty: "advanced",
        content: `
**Authentication** verifies who you are. **Authorization** determines what you can do.

### JWT Authentication:

\`\`\`csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"])
            )
        };
    });

// Authorization policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("MinimumAge", policy => policy.Requirements.Add(new MinimumAgeRequirement(18)));
});
\`\`\`

### Usage in Controllers:

\`\`\`csharp
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = "AdminOnly")]
    public IActionResult GetSensitiveData()
    {
        return Ok("Sensitive admin data");
    }
}
\`\`\`
`
    },
    {
        number: 94,
        title: "Explain Async/Await programming in C#",
        section: "dotnet-advanced",
        difficulty: "advanced",
        content: `
**Async/Await** enables asynchronous programming for I/O-bound operations.

### Good Example:

\`\`\`csharp
public async Task<OrderSummary> GetOrderSummaryAsync(Guid orderId)
{
    // Execute operations in parallel
    var orderTask = GetOrderAsync(orderId);
    var customerTask = GetCustomerAsync(orderId);
    var paymentTask = GetPaymentAsync(orderId);

    await Task.WhenAll(orderTask, customerTask, paymentTask);

    return new OrderSummary
    {
        Order = orderTask.Result,
        Customer = customerTask.Result,
        Payment = paymentTask.Result
    };
}
\`\`\`

### Bad Example (Anti-pattern):

\`\`\`csharp
// ❌ Sequential execution - slow!
public async Task<OrderSummary> GetOrderSummarySlowAsync(Guid orderId)
{
    var order = await GetOrderAsync(orderId);      // Waits
    var customer = await GetCustomerAsync(orderId); // Then waits
    var payment = await GetPaymentAsync(orderId);   // Then waits
    return new OrderSummary { Order = order, Customer = customer, Payment = payment };
}
\`\`\`

### Best Practices:
- Use async/await for I/O operations
- Avoid async void (use async Task)
- Don't block on async code (.Result, .Wait())
- Use ConfigureAwait(false) in libraries
`
    },

    // ==================== Azure Cloud Services (Q100-Q120) ====================
    {
        number: 100,
        title: "What is the difference between Azure Service Bus and Azure Storage Queues?",
        section: "azure-cloud",
        difficulty: "intermediate",
        content: `
Both are message queuing solutions but serve different purposes.

### Key Differences:

| Feature | Azure Service Bus | Azure Storage Queues |
|---------|------------------|---------------------|
| **Message Size** | Up to 256 KB (standard), 100 MB (premium) | Up to 64 KB |
| **Ordering** | FIFO guarantee with sessions | Best-effort ordering |
| **Duplicate Detection** | Built-in | No built-in |
| **TTL** | Configurable, up to unlimited | Maximum 7 days |
| **Protocols** | AMQP, HTTP/HTTPS | HTTP/HTTPS only |
| **Topics/Subscriptions** | Yes (pub-sub pattern) | No (queues only) |

### When to Use:
- **Service Bus**: Enterprise messaging, FIFO ordering, pub-sub, large messages
- **Storage Queues**: Simple queuing, cost-effective, high volume

\`\`\`csharp
// Service Bus example
var client = new ServiceBusClient(connectionString);
var sender = client.CreateSender("myqueue");
await sender.SendMessageAsync(new ServiceBusMessage("Hello"));
\`\`\`
`
    },
    {
        number: 101,
        title: "Explain Azure Event Hub and Event Grid",
        section: "azure-cloud",
        difficulty: "intermediate",
        content: `
**Event Hub** is for high-throughput event streaming. **Event Grid** is for reactive programming with events.

### Event Hub:
- **Use Case**: Big data streaming, telemetry
- **Throughput**: Millions of events/second
- **Retention**: 1-7 days (up to 90 with capture)

### Event Grid:
- **Use Case**: Event-driven applications
- **Throughput**: Millions of events/second
- **Retention**: 24 hours with retry

\`\`\`csharp
// Event Hub Producer
var producer = new EventHubProducerClient(connectionString, eventHubName);
var eventBatch = await producer.CreateBatchAsync();
eventBatch.TryAdd(new EventData(Encoding.UTF8.GetBytes("Event data")));
await producer.SendAsync(eventBatch);
\`\`\`
`
    },

    // ==================== SQL Server & Database (Q172-Q200) ====================
    {
        number: 172,
        title: "Explain different types of SQL Joins",
        section: "sql-database",
        difficulty: "beginner",
        content: `
**SQL Joins** combine rows from two or more tables based on related columns.

### Types of Joins:

**1. INNER JOIN**: Returns matching rows from both tables

\`\`\`sql
SELECT c.CustomerName, o.OrderId, o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerId = o.CustomerId;
\`\`\`

**2. LEFT JOIN**: Returns all rows from left table + matching from right

\`\`\`sql
SELECT c.CustomerName, o.OrderId
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId;
-- Includes customers with no orders
\`\`\`

**3. RIGHT JOIN**: Returns all rows from right table + matching from left

**4. FULL OUTER JOIN**: Returns all rows from both tables

**5. CROSS JOIN**: Cartesian product of both tables

**6. SELF JOIN**: Table joined with itself

\`\`\`sql
-- Self join for employee hierarchy
SELECT e.EmployeeName AS Employee, m.EmployeeName AS Manager
FROM Employees e
LEFT JOIN Employees m ON e.ManagerId = m.EmployeeId;
\`\`\`
`
    },
    {
        number: 173,
        title: "What is the difference between Clustered and Non-Clustered Index?",
        section: "sql-database",
        difficulty: "intermediate",
        content: `
**Clustered Index** determines physical order of data. **Non-Clustered Index** is a separate structure.

### Clustered Index:
- One per table
- Determines physical storage order
- Faster for range queries
- Primary key creates clustered index by default

\`\`\`sql
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,  -- Clustered index
    ProductName VARCHAR(200),
    Price DECIMAL(10,2)
);
\`\`\`

### Non-Clustered Index:
- Multiple per table
- Separate structure with pointer to data
- Faster for specific lookups

\`\`\`sql
-- Non-clustered index
CREATE NONCLUSTERED INDEX IX_Products_Name
ON Products(ProductName);

-- Covering index (includes additional columns)
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(CategoryId)
INCLUDE (ProductName, Price, StockQuantity);
\`\`\`

### Performance Comparison:
- **Clustered**: Best for range queries, sorting
- **Non-Clustered**: Best for specific lookups
- **Covering Index**: Eliminates key lookups
`
    },
    {
        number: 174,
        title: "What are Stored Procedures and when should you use them?",
        section: "sql-database",
        difficulty: "intermediate",
        content: `
**Stored Procedures** are precompiled SQL code stored in the database.

### Benefits:
- Performance (compiled once)
- Security (grant execute permission only)
- Reusability
- Reduced network traffic

### Example:

\`\`\`sql
CREATE PROCEDURE GetCustomerOrders
    @CustomerId INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderId,
        o.OrderDate,
        o.TotalAmount,
        COUNT(oi.OrderItemId) AS ItemCount
    FROM Orders o
    INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
    WHERE o.CustomerId = @CustomerId
      AND o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY o.OrderId, o.OrderDate, o.TotalAmount
    ORDER BY o.OrderDate DESC;
END;
GO

-- Execute
EXEC GetCustomerOrders @CustomerId = 123, @StartDate = '2024-01-01', @EndDate = '2024-12-31';
\`\`\`

### C# Integration:

\`\`\`csharp
using var connection = new SqlConnection(connectionString);
using var command = new SqlCommand("GetCustomerOrders", connection);
command.CommandType = CommandType.StoredProcedure;
command.Parameters.AddWithValue("@CustomerId", customerId);
command.Parameters.AddWithValue("@StartDate", startDate);
command.Parameters.AddWithValue("@EndDate", endDate);

await connection.OpenAsync();
using var reader = await command.ExecuteReaderAsync();
\`\`\`
`
    },
    {
        number: 175,
        title: "What are database triggers and what are their types?",
        section: "sql-database",
        difficulty: "advanced",
        content: `
**Triggers** are special stored procedures that automatically execute when specific events occur.

### Types of Triggers:

**1. DML Triggers**: Execute on INSERT, UPDATE, DELETE

\`\`\`sql
-- AFTER trigger for audit logging
CREATE TRIGGER trg_Products_PriceAudit
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Price)
    BEGIN
        INSERT INTO ProductPriceHistory (ProductId, OldPrice, NewPrice, ChangedBy, ChangedDate)
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
\`\`\`

**2. DDL Triggers**: Execute on CREATE, ALTER, DROP

**3. LOGON Triggers**: Execute when user logs in

### Best Practices:
- Keep triggers simple and fast
- Avoid complex logic
- Use for audit trails, enforcing business rules
- Don't use for complex business logic (use stored procedures)
`
    }

    // NOTE: In production, you would load all 570 questions here
    // For demonstration, we're showing the structure with sample questions
];

// Export for use in script.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = questionsDatabase;
}
