# Interview Questions: Q301-Q320 (Performance & Optimization)

## Q301: How do you optimize database queries and implement efficient data access in ASP.NET Core?

**Answer:**

Database query optimization is crucial for application performance and scalability.

```csharp
// ============================================
// Efficient Query Patterns with EF Core
// ============================================

public class OptimizedProductRepository
{
    private readonly ApplicationDbContext _context;

    public OptimizedProductRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    // ❌ BAD: N+1 Query Problem
    public async Task<List<ProductDto>> GetProductsWithCategoriesBad()
    {
        var products = await _context.Products.ToListAsync();

        // This generates N additional queries!
        return products.Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            CategoryName = p.Category.Name // N+1 problem!
        }).ToList();
    }

    // ✅ GOOD: Use Include to prevent N+1
    public async Task<List<ProductDto>> GetProductsWithCategoriesGood()
    {
        return await _context.Products
            .Include(p => p.Category)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                CategoryName = p.Category.Name
            })
            .ToListAsync();
    }

    // ✅ EXCELLENT: Use projection to select only needed fields
    public async Task<List<ProductDto>> GetProductsOptimized()
    {
        return await _context.Products
            .AsNoTracking() // Don't track entities (read-only)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                CategoryName = p.Category.Name,
                Price = p.Price
            })
            .ToListAsync();
    }

    // ✅ Pagination for large datasets
    public async Task<PagedResult<ProductDto>> GetProductsPaged(
        int pageNumber,
        int pageSize)
    {
        var query = _context.Products.AsNoTracking();

        var totalCount = await query.CountAsync();

        var products = await query
            .OrderBy(p => p.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            })
            .ToListAsync();

        return new PagedResult<ProductDto>
        {
            Items = products,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }

    // ✅ Filtering before loading
    public async Task<List<Product>> GetActiveProductsOptimized(decimal minPrice)
    {
        return await _context.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.Price >= minPrice)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    // ✅ Compiled Queries for frequently used queries
    private static readonly Func<ApplicationDbContext, int, Task<Product>>
        GetProductByIdCompiled = EF.CompileAsyncQuery(
            (ApplicationDbContext context, int id) =>
                context.Products
                    .Include(p => p.Category)
                    .FirstOrDefault(p => p.Id == id));

    public async Task<Product> GetProductByIdFast(int id)
    {
        return await GetProductByIdCompiled(_context, id);
    }
}

// ============================================
// Batch Operations
// ============================================

public class BatchOperationsService
{
    private readonly ApplicationDbContext _context;

    public BatchOperationsService(ApplicationDbContext context)
    {
        _context = context;
    }

    // ❌ BAD: Multiple individual queries
    public async Task UpdatePricesIndividually(List<int> productIds, decimal increase)
    {
        foreach (var id in productIds)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                product.Price += increase;
                await _context.SaveChangesAsync(); // Bad: SaveChanges in loop
            }
        }
    }

    // ✅ GOOD: Batch update
    public async Task UpdatePricesBatch(List<int> productIds, decimal increase)
    {
        var products = await _context.Products
            .Where(p => productIds.Contains(p.Id))
            .ToListAsync();

        foreach (var product in products)
        {
            product.Price += increase;
        }

        await _context.SaveChangesAsync(); // Single SaveChanges
    }

    // ✅ EXCELLENT: Bulk update using ExecuteUpdate (EF Core 7+)
    public async Task<int> UpdatePricesBulk(List<int> productIds, decimal increase)
    {
        return await _context.Products
            .Where(p => productIds.Contains(p.Id))
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(p => p.Price, p => p.Price + increase)
                .SetProperty(p => p.UpdatedAt, DateTime.UtcNow));
    }

    // ✅ Bulk delete (EF Core 7+)
    public async Task<int> DeleteProductsBulk(List<int> productIds)
    {
        return await _context.Products
            .Where(p => productIds.Contains(p.Id))
            .ExecuteDeleteAsync();
    }

    // ✅ Bulk insert
    public async Task BulkInsertProducts(List<Product> products)
    {
        _context.Products.AddRange(products);
        await _context.SaveChangesAsync();
    }
}

// ============================================
// Database Indexes
// ============================================

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string SKU { get; set; }
    public decimal Price { get; set; }
    public int CategoryId { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ApplicationDbContext : DbContext
{
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Single column index
        modelBuilder.Entity<Product>()
            .HasIndex(p => p.SKU)
            .IsUnique();

        // Composite index for common queries
        modelBuilder.Entity<Product>()
            .HasIndex(p => new { p.CategoryId, p.IsActive });

        // Filtered index (SQL Server specific)
        modelBuilder.Entity<Product>()
            .HasIndex(p => p.Price)
            .HasFilter("[IsActive] = 1");

        // Include columns in index (SQL Server)
        modelBuilder.Entity<Product>()
            .HasIndex(p => p.CategoryId)
            .IncludeProperties(p => new { p.Name, p.Price });
    }
}

// ============================================
// Connection Pooling and DbContext Lifetime
// ============================================

// ✅ GOOD: Scoped DbContext (default)
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlServer(
        connectionString,
        sqlOptions =>
        {
            sqlOptions.CommandTimeout(30);
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(5),
                errorNumbersToAdd: null);
        });

    // Enable query splitting for collections
    options.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);

    // Disable tracking by default
    // options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
});

// ============================================
// Raw SQL and Stored Procedures
// ============================================

public class RawSqlRepository
{
    private readonly ApplicationDbContext _context;

    public RawSqlRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    // ✅ Raw SQL query with parameters
    public async Task<List<Product>> SearchProductsRawSql(string searchTerm)
    {
        return await _context.Products
            .FromSqlInterpolated(
                $@"SELECT * FROM Products
                   WHERE Name LIKE {'%' + searchTerm + '%'}
                   AND IsActive = 1")
            .ToListAsync();
    }

    // ✅ Execute stored procedure
    public async Task<List<ProductSalesDto>> GetProductSalesReport(
        DateTime startDate,
        DateTime endDate)
    {
        return await _context.Database
            .SqlQueryRaw<ProductSalesDto>(
                @"EXEC sp_GetProductSalesReport @StartDate, @EndDate",
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate))
            .ToListAsync();
    }

    // ✅ Execute non-query command
    public async Task<int> UpdateProductPricesRawSql(decimal percentage)
    {
        return await _context.Database
            .ExecuteSqlInterpolatedAsync(
                $"UPDATE Products SET Price = Price * {1 + percentage / 100}");
    }
}

// ============================================
// Query Performance Monitoring
// ============================================

public class QueryPerformanceInterceptor : DbCommandInterceptor
{
    private readonly ILogger<QueryPerformanceInterceptor> _logger;
    private const int SlowQueryThresholdMs = 1000;

    public QueryPerformanceInterceptor(ILogger<QueryPerformanceInterceptor> logger)
    {
        _logger = logger;
    }

    public override async ValueTask<DbDataReader> ReaderExecutedAsync(
        DbCommand command,
        CommandExecutedEventData eventData,
        DbDataReader result,
        CancellationToken cancellationToken = default)
    {
        if (eventData.Duration.TotalMilliseconds > SlowQueryThresholdMs)
        {
            _logger.LogWarning(
                "Slow query detected ({Duration}ms): {CommandText}",
                eventData.Duration.TotalMilliseconds,
                command.CommandText);
        }

        return await base.ReaderExecutedAsync(
            command,
            eventData,
            result,
            cancellationToken);
    }
}

// Register interceptor
builder.Services.AddDbContext<ApplicationDbContext>((serviceProvider, options) =>
{
    options.UseSqlServer(connectionString)
        .AddInterceptors(
            serviceProvider.GetRequiredService<QueryPerformanceInterceptor>());
});

builder.Services.AddSingleton<QueryPerformanceInterceptor>();

/*
Database Query Optimization Best Practices:

1. ✅ Use AsNoTracking() for read-only queries
2. ✅ Use projection (Select) to retrieve only needed columns
3. ✅ Prevent N+1 queries with Include/ThenInclude
4. ✅ Implement pagination for large datasets
5. ✅ Use compiled queries for frequently executed queries
6. ✅ Batch operations instead of individual queries
7. ✅ Use ExecuteUpdate/ExecuteDelete for bulk operations
8. ✅ Create appropriate database indexes
9. ✅ Use query splitting for multiple collections
10. ✅ Monitor and log slow queries

Performance Tips:
- Avoid Select * - use projection
- Filter data in the database, not in memory
- Use async methods for I/O operations
- Consider denormalization for read-heavy scenarios
- Use caching for frequently accessed data
- Implement connection pooling
- Use batch operations for bulk updates
- Optimize indexes based on query patterns

Common Anti-Patterns to Avoid:
❌ Calling SaveChanges in a loop
❌ Loading entire table into memory
❌ Not using AsNoTracking for read-only queries
❌ Ignoring N+1 query problems
❌ Not implementing pagination
❌ Over-eager loading with too many Includes
*/
```

---

## Q302: How do you implement caching strategies in ASP.NET Core?

**Answer:**

Caching is essential for improving application performance by reducing database calls and expensive computations.

```csharp
// ============================================
// In-Memory Caching
// ============================================

using Microsoft.Extensions.Caching.Memory;

public class ProductService
{
    private readonly ApplicationDbContext _context;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        ApplicationDbContext context,
        IMemoryCache cache,
        ILogger<ProductService> logger)
    {
        _context = context;
        _cache = cache;
        _logger = logger;
    }

    // ✅ Basic caching
    public async Task<Product> GetProductByIdCached(int id)
    {
        var cacheKey = $"product_{id}";

        if (_cache.TryGetValue(cacheKey, out Product cachedProduct))
        {
            _logger.LogInformation("Cache hit for product {ProductId}", id);
            return cachedProduct;
        }

        _logger.LogInformation("Cache miss for product {ProductId}", id);

        var product = await _context.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product != null)
        {
            var cacheOptions = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30),
                SlidingExpiration = TimeSpan.FromMinutes(5)
            };

            _cache.Set(cacheKey, product, cacheOptions);
        }

        return product;
    }

    // ✅ Cache with GetOrCreateAsync
    public async Task<List<Product>> GetActiveProductsCached()
    {
        return await _cache.GetOrCreateAsync(
            "active_products",
            async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
                entry.SlidingExpiration = TimeSpan.FromMinutes(2);

                _logger.LogInformation("Loading active products from database");

                return await _context.Products
                    .AsNoTracking()
                    .Where(p => p.IsActive)
                    .ToListAsync();
            });
    }

    // ✅ Cache with dependencies
    public async Task<List<Category>> GetCategoriesCached()
    {
        return await _cache.GetOrCreateAsync(
            "categories",
            async entry =>
            {
                // Set cache priority
                entry.Priority = CacheItemPriority.High;

                // Register eviction callback
                entry.RegisterPostEvictionCallback(
                    (key, value, reason, state) =>
                    {
                        _logger.LogInformation(
                            "Cache entry {Key} evicted. Reason: {Reason}",
                            key, reason);
                    });

                return await _context.Categories
                    .AsNoTracking()
                    .ToListAsync();
            });
    }

    // ✅ Invalidate cache
    public async Task UpdateProductAndInvalidateCache(int id, Product updatedProduct)
    {
        var product = await _context.Products.FindAsync(id);
        if (product != null)
        {
            product.Name = updatedProduct.Name;
            product.Price = updatedProduct.Price;
            await _context.SaveChangesAsync();

            // Invalidate cache
            _cache.Remove($"product_{id}");
            _cache.Remove("active_products");
        }
    }
}

// ============================================
// Distributed Caching with Redis
// ============================================

using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

public class DistributedCacheService
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<DistributedCacheService> _logger;

    public DistributedCacheService(
        IDistributedCache cache,
        ILogger<DistributedCacheService> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    // ✅ Set cache with expiration
    public async Task SetAsync<T>(
        string key,
        T value,
        TimeSpan? absoluteExpiration = null,
        TimeSpan? slidingExpiration = null)
    {
        var options = new DistributedCacheEntryOptions();

        if (absoluteExpiration.HasValue)
        {
            options.AbsoluteExpirationRelativeToNow = absoluteExpiration.Value;
        }

        if (slidingExpiration.HasValue)
        {
            options.SlidingExpiration = slidingExpiration.Value;
        }

        var serialized = JsonSerializer.Serialize(value);
        await _cache.SetStringAsync(key, serialized, options);

        _logger.LogInformation("Cached item with key: {Key}", key);
    }

    // ✅ Get from cache
    public async Task<T> GetAsync<T>(string key)
    {
        var cached = await _cache.GetStringAsync(key);

        if (cached == null)
        {
            _logger.LogInformation("Cache miss for key: {Key}", key);
            return default;
        }

        _logger.LogInformation("Cache hit for key: {Key}", key);
        return JsonSerializer.Deserialize<T>(cached);
    }

    // ✅ Get or set pattern
    public async Task<T> GetOrSetAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan? absoluteExpiration = null)
    {
        var cached = await GetAsync<T>(key);
        if (cached != null)
        {
            return cached;
        }

        var value = await factory();
        await SetAsync(key, value, absoluteExpiration);
        return value;
    }

    // ✅ Remove from cache
    public async Task RemoveAsync(string key)
    {
        await _cache.RemoveAsync(key);
        _logger.LogInformation("Removed cache entry: {Key}", key);
    }

    // ✅ Refresh cache entry
    public async Task RefreshAsync(string key)
    {
        await _cache.RefreshAsync(key);
    }
}

// Register distributed cache in Program.cs
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
    options.InstanceName = "MyApp_";
});

builder.Services.AddSingleton<DistributedCacheService>();

// ============================================
// Response Caching
// ============================================

// Program.cs
builder.Services.AddResponseCaching();

var app = builder.Build();

app.UseResponseCaching();
app.UseHttpCacheHeaders(); // Optional: HTTP cache headers middleware

// Controller
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    // ✅ Response caching attribute
    [HttpGet]
    [ResponseCache(Duration = 60, Location = ResponseCacheLocation.Any)]
    public async Task<IActionResult> GetProducts()
    {
        var products = await _productService.GetAllProductsAsync();
        return Ok(products);
    }

    // ✅ Cache profile
    [HttpGet("{id}")]
    [ResponseCache(CacheProfileName = "Default30")]
    public async Task<IActionResult> GetProduct(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);
        return Ok(product);
    }

    // ✅ No caching
    [HttpPost]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public async Task<IActionResult> CreateProduct(Product product)
    {
        await _productService.CreateProductAsync(product);
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }
}

// Configure cache profiles in Program.cs
builder.Services.AddControllers(options =>
{
    options.CacheProfiles.Add("Default30", new CacheProfile
    {
        Duration = 30,
        Location = ResponseCacheLocation.Any
    });

    options.CacheProfiles.Add("Default60", new CacheProfile
    {
        Duration = 60,
        Location = ResponseCacheLocation.Any,
        VaryByHeader = "Accept"
    });
});

// ============================================
// Output Caching (ASP.NET Core 7+)
// ============================================

builder.Services.AddOutputCache(options =>
{
    // Default policy
    options.AddBasePolicy(builder => builder
        .Expire(TimeSpan.FromMinutes(10))
        .Tag("products"));

    // Named policy
    options.AddPolicy("ProductsCache", builder => builder
        .Expire(TimeSpan.FromMinutes(5))
        .SetVaryByQuery("category", "page")
        .Tag("products", "api"));

    // Custom policy with vary by header
    options.AddPolicy("VaryByUser", builder => builder
        .Expire(TimeSpan.FromMinutes(15))
        .SetVaryByHeader("Authorization")
        .Tag("user-specific"));
});

var app = builder.Build();

app.UseOutputCache();

// Usage in endpoints
app.MapGet("/api/products", async (ProductService service) =>
{
    return await service.GetAllProductsAsync();
})
.CacheOutput("ProductsCache");

// Invalidate cache by tag
app.MapPost("/api/products", async (
    Product product,
    ProductService service,
    IOutputCacheStore cache) =>
{
    await service.CreateProductAsync(product);
    await cache.EvictByTagAsync("products", default);
    return Results.Created($"/api/products/{product.Id}", product);
});

// ============================================
// Cache-Aside Pattern
// ============================================

public class CacheAsideProductService
{
    private readonly ApplicationDbContext _context;
    private readonly IDistributedCache _cache;

    public CacheAsideProductService(
        ApplicationDbContext context,
        IDistributedCache cache)
    {
        _context = context;
        _cache = cache;
    }

    public async Task<Product> GetProductAsync(int id)
    {
        var cacheKey = $"product_{id}";

        // Try to get from cache
        var cached = await _cache.GetStringAsync(cacheKey);
        if (cached != null)
        {
            return JsonSerializer.Deserialize<Product>(cached);
        }

        // Load from database
        var product = await _context.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product != null)
        {
            // Store in cache
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30),
                SlidingExpiration = TimeSpan.FromMinutes(5)
            };

            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(product),
                options);
        }

        return product;
    }

    public async Task UpdateProductAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();

        // Invalidate cache
        await _cache.RemoveAsync($"product_{product.Id}");
    }
}

// ============================================
// Hybrid Caching (ASP.NET Core 9+)
// ============================================

using Microsoft.Extensions.Caching.Hybrid;

public class HybridCacheProductService
{
    private readonly ApplicationDbContext _context;
    private readonly HybridCache _cache;

    public HybridCacheProductService(
        ApplicationDbContext context,
        HybridCache cache)
    {
        _context = context;
        _cache = cache;
    }

    public async Task<Product> GetProductAsync(int id, CancellationToken token = default)
    {
        return await _cache.GetOrCreateAsync(
            $"product_{id}",
            async cancel => await _context.Products
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id, cancel),
            new HybridCacheEntryOptions
            {
                Expiration = TimeSpan.FromMinutes(30),
                LocalCacheExpiration = TimeSpan.FromMinutes(5)
            },
            token: token);
    }
}

// Register hybrid cache
builder.Services.AddHybridCache();

/*
Caching Best Practices:

1. ✅ Use in-memory cache for single-server apps
2. ✅ Use distributed cache (Redis) for multi-server apps
3. ✅ Implement cache invalidation strategy
4. ✅ Set appropriate expiration times
5. ✅ Use cache-aside pattern for data caching
6. ✅ Implement cache warming for critical data
7. ✅ Monitor cache hit/miss ratios
8. ✅ Use response caching for static content
9. ✅ Implement cache tagging for bulk invalidation
10. ✅ Avoid caching user-specific data in response cache

Cache Strategies:
- Cache-Aside: Application manages cache (most common)
- Read-Through: Cache loads data automatically
- Write-Through: Cache writes to database automatically
- Write-Behind: Cache writes asynchronously
- Refresh-Ahead: Cache refreshes before expiration

When to Cache:
✅ Frequently accessed data
✅ Expensive computations
✅ External API responses
✅ Static or semi-static data
✅ Configuration data

When NOT to Cache:
❌ Frequently changing data
❌ User-specific sensitive data
❌ Large objects (>1MB)
❌ Data with complex invalidation logic
*/
```

---

## Q303: How do you implement asynchronous programming and parallel processing for better performance?

**Answer:**

Proper async/await usage and parallel processing significantly improve application throughput and responsiveness.

```csharp
// ============================================
// Async/Await Best Practices
// ============================================

public class AsyncBestPracticesService
{
    private readonly HttpClient _httpClient;
    private readonly ApplicationDbContext _context;

    public AsyncBestPracticesService(
        HttpClient httpClient,
        ApplicationDbContext context)
    {
        _httpClient = httpClient;
        _context = context;
    }

    // ❌ BAD: Blocking async call
    public Product GetProductBad(int id)
    {
        // Don't use .Result - it blocks the thread!
        return _context.Products.FindAsync(id).Result;
    }

    // ✅ GOOD: Proper async all the way
    public async Task<Product> GetProductGood(int id)
    {
        return await _context.Products.FindAsync(id);
    }

    // ❌ BAD: Async void (except event handlers)
    public async void ProcessOrderBad(int orderId)
    {
        await ProcessOrderAsync(orderId);
    }

    // ✅ GOOD: Return Task
    public async Task ProcessOrderGood(int orderId)
    {
        await ProcessOrderAsync(orderId);
    }

    // ✅ ConfigureAwait for library code
    public async Task<string> FetchDataLibrary(string url)
    {
        // Use ConfigureAwait(false) in library code
        var response = await _httpClient.GetAsync(url).ConfigureAwait(false);
        return await response.Content.ReadAsStringAsync().ConfigureAwait(false);
    }

    // ✅ ValueTask for hot path/frequently called methods
    public ValueTask<int> GetCachedCountAsync()
    {
        // Return synchronously if data is cached
        if (_cachedCount.HasValue)
        {
            return new ValueTask<int>(_cachedCount.Value);
        }

        return new ValueTask<int>(LoadCountAsync());
    }

    private int? _cachedCount;

    private async Task<int> LoadCountAsync()
    {
        _cachedCount = await _context.Products.CountAsync();
        return _cachedCount.Value;
    }
}

// ============================================
// Parallel Processing
// ============================================

public class ParallelProcessingService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ParallelProcessingService> _logger;

    public ParallelProcessingService(
        HttpClient httpClient,
        ILogger<ParallelProcessingService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    // ✅ Process multiple items in parallel
    public async Task<List<ProductData>> FetchProductDataParallel(List<int> productIds)
    {
        var tasks = productIds.Select(id => FetchProductDataAsync(id));

        var results = await Task.WhenAll(tasks);

        return results.ToList();
    }

    private async Task<ProductData> FetchProductDataAsync(int productId)
    {
        var response = await _httpClient.GetAsync($"api/products/{productId}");
        return await response.Content.ReadFromJsonAsync<ProductData>();
    }

    // ✅ Parallel processing with degree of parallelism
    public async Task<List<ProcessedOrder>> ProcessOrdersParallel(
        List<Order> orders,
        int maxDegreeOfParallelism = 4)
    {
        var results = new ConcurrentBag<ProcessedOrder>();

        var parallelOptions = new ParallelOptions
        {
            MaxDegreeOfParallelism = maxDegreeOfParallelism
        };

        await Parallel.ForEachAsync(
            orders,
            parallelOptions,
            async (order, cancellationToken) =>
            {
                var processed = await ProcessOrderAsync(order, cancellationToken);
                results.Add(processed);
            });

        return results.ToList();
    }

    // ✅ Batching with SemaphoreSlim for rate limiting
    public async Task<List<string>> FetchDataWithRateLimit(
        List<string> urls,
        int maxConcurrent = 10)
    {
        var semaphore = new SemaphoreSlim(maxConcurrent);
        var results = new List<string>();

        var tasks = urls.Select(async url =>
        {
            await semaphore.WaitAsync();
            try
            {
                return await _httpClient.GetStringAsync(url);
            }
            finally
            {
                semaphore.Release();
            }
        });

        return (await Task.WhenAll(tasks)).ToList();
    }

    // ✅ Timeout handling
    public async Task<string> FetchWithTimeout(string url, int timeoutSeconds = 30)
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds));

        try
        {
            var response = await _httpClient.GetAsync(url, cts.Token);
            return await response.Content.ReadAsStringAsync();
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Request to {Url} timed out after {Timeout}s",
                url, timeoutSeconds);
            throw new TimeoutException($"Request timed out after {timeoutSeconds} seconds");
        }
    }

    // ✅ Fire and forget with proper error handling
    public void ProcessInBackground(int orderId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await ProcessOrderAsync(orderId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Background processing failed for order {OrderId}",
                    orderId);
            }
        });
    }

    private async Task<ProcessedOrder> ProcessOrderAsync(
        Order order,
        CancellationToken cancellationToken = default)
    {
        await Task.Delay(100, cancellationToken); // Simulate processing
        return new ProcessedOrder { Id = order.Id };
    }

    private async Task ProcessOrderAsync(int orderId)
    {
        await Task.Delay(1000); // Simulate processing
    }
}

// ============================================
// Channels for Producer-Consumer Pattern
// ============================================

using System.Threading.Channels;

public class ChannelBasedProcessor
{
    private readonly Channel<WorkItem> _channel;
    private readonly ILogger<ChannelBasedProcessor> _logger;

    public ChannelBasedProcessor(ILogger<ChannelBasedProcessor> logger)
    {
        _logger = logger;
        _channel = Channel.CreateUnbounded<WorkItem>(new UnboundedChannelOptions
        {
            SingleReader = false,
            SingleWriter = false
        });
    }

    // Producer
    public async Task EnqueueWorkAsync(WorkItem item)
    {
        await _channel.Writer.WriteAsync(item);
        _logger.LogInformation("Enqueued work item {ItemId}", item.Id);
    }

    // Consumer
    public async Task ProcessWorkItemsAsync(CancellationToken cancellationToken)
    {
        await foreach (var item in _channel.Reader.ReadAllAsync(cancellationToken))
        {
            try
            {
                await ProcessItemAsync(item);
                _logger.LogInformation("Processed work item {ItemId}", item.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing item {ItemId}", item.Id);
            }
        }
    }

    // Multiple consumers
    public async Task StartProcessorsAsync(int consumerCount, CancellationToken cancellationToken)
    {
        var consumers = Enumerable.Range(0, consumerCount)
            .Select(i => Task.Run(async () =>
            {
                _logger.LogInformation("Consumer {ConsumerId} started", i);
                await ProcessWorkItemsAsync(cancellationToken);
                _logger.LogInformation("Consumer {ConsumerId} stopped", i);
            }, cancellationToken))
            .ToList();

        await Task.WhenAll(consumers);
    }

    private async Task ProcessItemAsync(WorkItem item)
    {
        await Task.Delay(100); // Simulate work
    }

    public void Complete()
    {
        _channel.Writer.Complete();
    }
}

public class WorkItem
{
    public int Id { get; set; }
    public string Data { get; set; }
}

// ============================================
// Background Service with Queue
// ============================================

public interface IBackgroundTaskQueue
{
    ValueTask QueueBackgroundWorkItemAsync(Func<CancellationToken, ValueTask> workItem);
    ValueTask<Func<CancellationToken, ValueTask>> DequeueAsync(CancellationToken cancellationToken);
}

public class BackgroundTaskQueue : IBackgroundTaskQueue
{
    private readonly Channel<Func<CancellationToken, ValueTask>> _queue;

    public BackgroundTaskQueue(int capacity)
    {
        var options = new BoundedChannelOptions(capacity)
        {
            FullMode = BoundedChannelFullMode.Wait
        };
        _queue = Channel.CreateBounded<Func<CancellationToken, ValueTask>>(options);
    }

    public async ValueTask QueueBackgroundWorkItemAsync(
        Func<CancellationToken, ValueTask> workItem)
    {
        if (workItem == null)
        {
            throw new ArgumentNullException(nameof(workItem));
        }

        await _queue.Writer.WriteAsync(workItem);
    }

    public async ValueTask<Func<CancellationToken, ValueTask>> DequeueAsync(
        CancellationToken cancellationToken)
    {
        return await _queue.Reader.ReadAsync(cancellationToken);
    }
}

public class QueuedHostedService : BackgroundService
{
    private readonly IBackgroundTaskQueue _taskQueue;
    private readonly ILogger<QueuedHostedService> _logger;

    public QueuedHostedService(
        IBackgroundTaskQueue taskQueue,
        ILogger<QueuedHostedService> logger)
    {
        _taskQueue = taskQueue;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Queued Hosted Service is running");

        while (!stoppingToken.IsCancellationRequested)
        {
            var workItem = await _taskQueue.DequeueAsync(stoppingToken);

            try
            {
                await workItem(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred executing work item");
            }
        }

        _logger.LogInformation("Queued Hosted Service is stopping");
    }
}

// Register in Program.cs
builder.Services.AddSingleton<IBackgroundTaskQueue>(new BackgroundTaskQueue(capacity: 100));
builder.Services.AddHostedService<QueuedHostedService>();

// Usage
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IBackgroundTaskQueue _taskQueue;

    public OrdersController(IBackgroundTaskQueue taskQueue)
    {
        _taskQueue = taskQueue;
    }

    [HttpPost("{id}/process")]
    public async Task<IActionResult> ProcessOrder(int id)
    {
        await _taskQueue.QueueBackgroundWorkItemAsync(async cancellationToken =>
        {
            // Background work
            await Task.Delay(5000, cancellationToken);
            // Process order...
        });

        return Accepted();
    }
}

// ============================================
// Task Parallel Library (TPL) Dataflow
// ============================================

using System.Threading.Tasks.Dataflow;

public class DataflowPipelineService
{
    private readonly ILogger<DataflowPipelineService> _logger;

    public DataflowPipelineService(ILogger<DataflowPipelineService> logger)
    {
        _logger = logger;
    }

    public async Task ProcessDataPipeline(List<int> orderIds)
    {
        // Define blocks
        var loadBlock = new TransformBlock<int, Order>(
            async orderId =>
            {
                _logger.LogInformation("Loading order {OrderId}", orderId);
                await Task.Delay(100); // Simulate load
                return new Order { Id = orderId };
            },
            new ExecutionDataflowBlockOptions
            {
                MaxDegreeOfParallelism = 4
            });

        var validateBlock = new TransformBlock<Order, Order>(
            async order =>
            {
                _logger.LogInformation("Validating order {OrderId}", order.Id);
                await Task.Delay(50); // Simulate validation
                return order;
            },
            new ExecutionDataflowBlockOptions
            {
                MaxDegreeOfParallelism = 8
            });

        var processBlock = new ActionBlock<Order>(
            async order =>
            {
                _logger.LogInformation("Processing order {OrderId}", order.Id);
                await Task.Delay(200); // Simulate processing
            },
            new ExecutionDataflowBlockOptions
            {
                MaxDegreeOfParallelism = 2
            });

        // Link blocks
        var linkOptions = new DataflowLinkOptions { PropagateCompletion = true };
        loadBlock.LinkTo(validateBlock, linkOptions);
        validateBlock.LinkTo(processBlock, linkOptions);

        // Post data
        foreach (var orderId in orderIds)
        {
            await loadBlock.SendAsync(orderId);
        }

        // Signal completion
        loadBlock.Complete();

        // Wait for pipeline to complete
        await processBlock.Completion;

        _logger.LogInformation("Pipeline completed");
    }
}

/*
Async/Await Best Practices:

1. ✅ Use async/await all the way down
2. ✅ Avoid async void (except event handlers)
3. ✅ Don't block on async code (.Result, .Wait())
4. ✅ Use ConfigureAwait(false) in libraries
5. ✅ Use ValueTask for hot paths
6. ✅ Handle cancellation tokens properly
7. ✅ Implement timeouts for external calls
8. ✅ Use SemaphoreSlim for throttling
9. ✅ Use Channels for producer-consumer
10. ✅ Monitor thread pool usage

Parallel Processing:
- Task.WhenAll: Wait for all tasks
- Task.WhenAny: Wait for first task
- Parallel.ForEachAsync: Parallel iteration
- TPL Dataflow: Complex pipelines
- Channels: Producer-consumer patterns

Common Mistakes:
❌ Using .Result or .Wait() (causes deadlocks)
❌ Not using cancellation tokens
❌ Async void methods
❌ Not handling exceptions in parallel tasks
❌ Over-parallelization (too many threads)
*/
```

---

## Q304: How do you optimize memory usage and prevent memory leaks in ASP.NET Core?

**Answer:**

Proper memory management is critical for application stability and performance.

```csharp
// ============================================
// Memory-Efficient Patterns
// ============================================

public class MemoryEfficientService
{
    private readonly ApplicationDbContext _context;

    public MemoryEfficientService(ApplicationDbContext context)
    {
        _context = context;
    }

    // ❌ BAD: Loading all data into memory
    public async Task<List<Product>> GetAllProductsBad()
    {
        // Don't load millions of records into memory!
        return await _context.Products.ToListAsync();
    }

    // ✅ GOOD: Streaming with AsAsyncEnumerable
    public async IAsyncEnumerable<Product> GetAllProductsStreaming(
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        await foreach (var product in _context.Products
            .AsNoTracking()
            .AsAsyncEnumerable()
            .WithCancellation(cancellationToken))
        {
            yield return product;
        }
    }

    // ✅ GOOD: Process in batches
    public async Task ProcessAllProductsInBatches(int batchSize = 1000)
    {
        var totalCount = await _context.Products.CountAsync();
        var batches = (int)Math.Ceiling(totalCount / (double)batchSize);

        for (int i = 0; i < batches; i++)
        {
            var products = await _context.Products
                .AsNoTracking()
                .OrderBy(p => p.Id)
                .Skip(i * batchSize)
                .Take(batchSize)
                .ToListAsync();

            await ProcessBatchAsync(products);

            // Allow GC to collect
            products = null;
            GC.Collect();
        }
    }

    private async Task ProcessBatchAsync(List<Product> products)
    {
        await Task.Delay(100); // Simulate processing
    }

    // ✅ Use ArrayPool for temporary arrays
    public async Task<byte[]> ProcessLargeDataWithArrayPool()
    {
        var pool = ArrayPool<byte>.Shared;
        byte[] buffer = pool.Rent(1024 * 1024); // 1MB buffer

        try
        {
            // Use buffer
            await ProcessBufferAsync(buffer);
            return buffer;
        }
        finally
        {
            pool.Return(buffer, clearArray: true);
        }
    }

    private async Task ProcessBufferAsync(byte[] buffer)
    {
        await Task.Delay(100);
    }
}

// ============================================
// Preventing Memory Leaks
// ============================================

// ❌ BAD: Static event handler causing memory leak
public class LeakyService
{
    public LeakyService()
    {
        // This creates a memory leak!
        SomeStaticClass.StaticEvent += OnStaticEvent;
    }

    private void OnStaticEvent(object sender, EventArgs e)
    {
        // Handle event
    }

    // No cleanup - this object will never be GC'd!
}

// ✅ GOOD: Proper event cleanup
public class NonLeakyService : IDisposable
{
    public NonLeakyService()
    {
        SomeStaticClass.StaticEvent += OnStaticEvent;
    }

    private void OnStaticEvent(object sender, EventArgs e)
    {
        // Handle event
    }

    public void Dispose()
    {
        SomeStaticClass.StaticEvent -= OnStaticEvent;
    }
}

// ✅ GOOD: Weak event pattern
public class WeakEventService
{
    private readonly WeakReference<EventHandler> _weakHandler;

    public WeakEventService()
    {
        EventHandler handler = OnEvent;
        _weakHandler = new WeakReference<EventHandler>(handler);

        if (_weakHandler.TryGetTarget(out var target))
        {
            SomeStaticClass.StaticEvent += target;
        }
    }

    private void OnEvent(object sender, EventArgs e)
    {
        // Handle event
    }
}

// ============================================
// Memory-Efficient File Processing
// ============================================

public class FileProcessingService
{
    // ❌ BAD: Loading entire file into memory
    public async Task<string> ReadLargeFileBad(string path)
    {
        // Don't do this for large files!
        return await File.ReadAllTextAsync(path);
    }

    // ✅ GOOD: Streaming file reading
    public async IAsyncEnumerable<string> ReadLargeFileStreaming(
        string path,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var reader = new StreamReader(path);

        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync();
            if (line != null)
            {
                yield return line;
            }

            if (cancellationToken.IsCancellationRequested)
            {
                yield break;
            }
        }
    }

    // ✅ GOOD: Process file in chunks with RecyclableMemoryStream
    public async Task ProcessLargeFileWithRecyclableStream(string path)
    {
        var memoryStreamManager = new RecyclableMemoryStreamManager();

        using var fileStream = File.OpenRead(path);
        using var recyclableStream = memoryStreamManager.GetStream();

        var buffer = new byte[81920]; // 80KB buffer
        int bytesRead;

        while ((bytesRead = await fileStream.ReadAsync(buffer, 0, buffer.Length)) > 0)
        {
            await recyclableStream.WriteAsync(buffer, 0, bytesRead);

            // Process chunk if needed
            if (recyclableStream.Length >= 1024 * 1024) // 1MB chunks
            {
                await ProcessChunkAsync(recyclableStream);
                recyclableStream.SetLength(0);
                recyclableStream.Position = 0;
            }
        }
    }

    private async Task ProcessChunkAsync(RecyclableMemoryStream stream)
    {
        await Task.Delay(100);
    }
}

// ============================================
// Span<T> and Memory<T> for Zero-Allocation
// ============================================

public class SpanOptimizedService
{
    // ✅ Use Span<T> for stack-allocated memory
    public int SumArraySpan(ReadOnlySpan<int> numbers)
    {
        int sum = 0;
        foreach (var number in numbers)
        {
            sum += number;
        }
        return sum;
    }

    // ✅ Use stackalloc for small arrays
    public string ProcessSmallArray()
    {
        Span<int> numbers = stackalloc int[10];
        for (int i = 0; i < numbers.Length; i++)
        {
            numbers[i] = i * 2;
        }

        return $"Sum: {SumArraySpan(numbers)}";
    }

    // ✅ Parse strings without allocation
    public int ParseIntFromSpan(ReadOnlySpan<char> input)
    {
        return int.Parse(input);
    }

    // ✅ String operations with Span
    public ReadOnlySpan<char> GetFileNameWithoutExtension(ReadOnlySpan<char> path)
    {
        var lastDot = path.LastIndexOf('.');
        var lastSlash = path.LastIndexOf('/');

        if (lastDot > lastSlash)
        {
            return path.Slice(lastSlash + 1, lastDot - lastSlash - 1);
        }

        return path.Slice(lastSlash + 1);
    }
}

// ============================================
// Object Pooling
// ============================================

using Microsoft.Extensions.ObjectPool;

public class PooledObject
{
    public int Value { get; set; }

    public void Reset()
    {
        Value = 0;
    }
}

public class PooledObjectPolicy : IPooledObjectPolicy<PooledObject>
{
    public PooledObject Create()
    {
        return new PooledObject();
    }

    public bool Return(PooledObject obj)
    {
        obj.Reset();
        return true;
    }
}

public class ObjectPoolService
{
    private readonly ObjectPool<PooledObject> _pool;

    public ObjectPoolService()
    {
        var policy = new PooledObjectPolicy();
        var provider = new DefaultObjectPoolProvider();
        _pool = provider.Create(policy);
    }

    public async Task ProcessWithPooledObject()
    {
        var obj = _pool.Get();
        try
        {
            obj.Value = 42;
            await ProcessObjectAsync(obj);
        }
        finally
        {
            _pool.Return(obj);
        }
    }

    private async Task ProcessObjectAsync(PooledObject obj)
    {
        await Task.Delay(100);
    }
}

// ============================================
// Memory Diagnostics and Monitoring
// ============================================

public class MemoryDiagnosticsService
{
    private readonly ILogger<MemoryDiagnosticsService> _logger;

    public MemoryDiagnosticsService(ILogger<MemoryDiagnosticsService> logger)
    {
        _logger = logger;
    }

    public void LogMemoryUsage()
    {
        var process = Process.GetCurrentProcess();

        _logger.LogInformation(
            "Memory Usage: Working Set: {WorkingSet:N0} bytes, " +
            "Private: {Private:N0} bytes, " +
            "GC Total: {GCTotal:N0} bytes, " +
            "Gen0: {Gen0}, Gen1: {Gen1}, Gen2: {Gen2}",
            process.WorkingSet64,
            process.PrivateMemorySize64,
            GC.GetTotalMemory(false),
            GC.CollectionCount(0),
            GC.CollectionCount(1),
            GC.CollectionCount(2));
    }

    public void TriggerGC()
    {
        _logger.LogInformation("Triggering garbage collection");
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();
    }

    // Monitor memory pressure
    public void RegisterMemoryPressure(long bytes)
    {
        GC.AddMemoryPressure(bytes);
    }

    public void UnregisterMemoryPressure(long bytes)
    {
        GC.RemoveMemoryPressure(bytes);
    }
}

// ============================================
// IDisposable Implementation
// ============================================

public class ProperDisposableService : IDisposable, IAsyncDisposable
{
    private readonly HttpClient _httpClient;
    private readonly Stream _stream;
    private bool _disposed;

    public ProperDisposableService(HttpClient httpClient, Stream stream)
    {
        _httpClient = httpClient;
        _stream = stream;
    }

    // Synchronous dispose
    public void Dispose()
    {
        Dispose(disposing: true);
        GC.SuppressFinalize(this);
    }

    // Asynchronous dispose
    public async ValueTask DisposeAsync()
    {
        await DisposeAsyncCore();

        Dispose(disposing: false);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (_disposed)
        {
            return;
        }

        if (disposing)
        {
            // Dispose managed resources
            _httpClient?.Dispose();
            _stream?.Dispose();
        }

        // Free unmanaged resources here if any

        _disposed = true;
    }

    protected virtual async ValueTask DisposeAsyncCore()
    {
        if (_stream != null)
        {
            await _stream.DisposeAsync();
        }

        _httpClient?.Dispose();
    }

    ~ProperDisposableService()
    {
        Dispose(disposing: false);
    }
}

/*
Memory Optimization Best Practices:

1. ✅ Use AsNoTracking() for read-only queries
2. ✅ Stream large datasets with IAsyncEnumerable
3. ✅ Process data in batches
4. ✅ Use ArrayPool for temporary arrays
5. ✅ Implement proper IDisposable pattern
6. ✅ Unsubscribe from events in Dispose
7. ✅ Use Span<T> and Memory<T> for zero-allocation
8. ✅ Implement object pooling for frequently created objects
9. ✅ Monitor GC collections and memory usage
10. ✅ Avoid string concatenation in loops (use StringBuilder)

Common Memory Leaks:
❌ Static event handlers not unsubscribed
❌ Timer not disposed
❌ IDisposable not implemented/called
❌ Captured variables in closures
❌ Unmanaged resources not released

Memory Profiling Tools:
- dotMemory (JetBrains)
- ANTS Memory Profiler
- Visual Studio Diagnostic Tools
- PerfView
- dotnet-counters
- dotnet-dump
*/
```

---

## Q305. How do you optimize HTTP client usage in ASP.NET Core?

```csharp
/*
HTTP Client Optimization - HttpClientFactory and Best Practices

❌ ANTI-PATTERN: Creating HttpClient instances directly
*/

// ❌ BAD: Socket exhaustion problem
public class BadHttpClientUsage
{
    public async Task<string> GetDataBad(string url)
    {
        using var client = new HttpClient(); // Creates new connection each time!
        return await client.GetStringAsync(url);
    }
}

// ❌ BAD: DNS issues with static HttpClient
public class AlsoBadHttpClientUsage
{
    private static readonly HttpClient _client = new HttpClient();

    public async Task<string> GetDataStatic(string url)
    {
        return await _client.GetStringAsync(url); // Doesn't respect DNS changes!
    }
}

// ✅ GOOD: Use IHttpClientFactory (ASP.NET Core 2.1+)
public class ProductService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IHttpClientFactory httpClientFactory,
        ILogger<ProductService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<Product> GetProductFromExternalApi(int id)
    {
        var client = _httpClientFactory.CreateClient("ProductApi");

        try
        {
            var response = await client.GetAsync($"/api/products/{id}");
            response.EnsureSuccessStatusCode();

            return await response.Content.ReadFromJsonAsync<Product>();
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to fetch product {ProductId}", id);
            throw;
        }
    }
}

// ✅ EXCELLENT: Named and Typed clients with configuration
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Named client with configuration
        services.AddHttpClient("ProductApi", client =>
        {
            client.BaseAddress = new Uri("https://api.example.com");
            client.Timeout = TimeSpan.FromSeconds(30);
            client.DefaultRequestHeaders.Add("Accept", "application/json");
            client.DefaultRequestHeaders.Add("User-Agent", "MyApp/1.0");
        })
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(2),
            PooledConnectionIdleTimeout = TimeSpan.FromMinutes(1),
            MaxConnectionsPerServer = 10
        })
        .AddPolicyHandler(GetRetryPolicy())
        .AddPolicyHandler(GetCircuitBreakerPolicy());

        // Typed client (preferred for strongly-typed services)
        services.AddHttpClient<IProductApiClient, ProductApiClient>((client) =>
        {
            client.BaseAddress = new Uri("https://api.example.com");
            client.Timeout = TimeSpan.FromSeconds(30);
        })
        .AddTransientHttpErrorPolicy(policyBuilder =>
            policyBuilder.WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt =>
                    TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryAttempt, context) =>
                {
                    Console.WriteLine($"Retry {retryAttempt} after {timespan.TotalSeconds}s");
                }
            ));
    }

    private static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryAttempt, context) =>
                {
                    Console.WriteLine($"Delaying for {timespan.TotalSeconds}s, then retry {retryAttempt}");
                });
    }

    private static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromSeconds(30),
                onBreak: (outcome, timespan) =>
                {
                    Console.WriteLine($"Circuit breaker opened for {timespan.TotalSeconds}s");
                },
                onReset: () => Console.WriteLine("Circuit breaker reset"));
    }
}

// ✅ Typed client implementation
public interface IProductApiClient
{
    Task<Product> GetProductAsync(int id);
    Task<List<Product>> GetProductsAsync(int page, int pageSize);
}

public class ProductApiClient : IProductApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ProductApiClient> _logger;

    public ProductApiClient(HttpClient httpClient, ILogger<ProductApiClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<Product> GetProductAsync(int id)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<Product>($"/api/products/{id}");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error fetching product {ProductId}", id);
            throw;
        }
    }

    public async Task<List<Product>> GetProductsAsync(int page, int pageSize)
    {
        var response = await _httpClient.GetAsync($"/api/products?page={page}&pageSize={pageSize}");
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<List<Product>>();
    }
}

// ✅ Advanced: Request/Response compression
public class CompressionDelegatingHandler : DelegatingHandler
{
    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        request.Headers.AcceptEncoding.Add(new StringWithQualityHeaderValue("gzip"));
        request.Headers.AcceptEncoding.Add(new StringWithQualityHeaderValue("deflate"));
        request.Headers.AcceptEncoding.Add(new StringWithQualityHeaderValue("br"));

        return await base.SendAsync(request, cancellationToken);
    }
}

// ✅ Advanced: Request timeout per operation
public class TimeoutDelegatingHandler : DelegatingHandler
{
    private readonly TimeSpan _timeout;

    public TimeoutDelegatingHandler(TimeSpan timeout)
    {
        _timeout = timeout;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(_timeout);

        try
        {
            return await base.SendAsync(request, cts.Token);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new TimeoutException($"Request timed out after {_timeout.TotalSeconds}s");
        }
    }
}

// Register custom handlers
services.AddHttpClient("ProductApi")
    .AddHttpMessageHandler(() => new CompressionDelegatingHandler())
    .AddHttpMessageHandler(() => new TimeoutDelegatingHandler(TimeSpan.FromSeconds(10)));

/*
Best Practices:
1. ✅ Always use IHttpClientFactory, never create HttpClient directly
2. ✅ Configure connection pooling lifetime (2-5 minutes)
3. ✅ Implement retry policies with exponential backoff
4. ✅ Use circuit breaker pattern for resilience
5. ✅ Set appropriate timeouts
6. ✅ Use typed clients for better testability
7. ✅ Enable compression for responses
8. ✅ Monitor and log HTTP requests
9. ✅ Use cancellation tokens
10. ✅ Limit concurrent connections per server

Performance Benefits:
- Prevents socket exhaustion
- Respects DNS TTL and changes
- Efficient connection pooling
- Automatic handler lifecycle management
- Built-in resilience patterns

Tools:
- Polly for resilience policies
- HttpClientFactory diagnostics
- Application Insights for monitoring
*/
```

---

## Q306. What are the best practices for response compression and minification in ASP.NET Core?

```csharp
/*
Response Compression and Minification Strategies
*/

// ✅ Response Compression Configuration
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddResponseCompression(options =>
        {
            options.EnableForHttps = true; // Enable for HTTPS (consider security implications)

            // Add compression providers
            options.Providers.Add<BrotliCompressionProvider>();
            options.Providers.Add<GzipCompressionProvider>();

            // MIME types to compress
            options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[]
            {
                "application/json",
                "application/javascript",
                "text/css",
                "text/html",
                "text/plain",
                "text/xml",
                "application/xml",
                "image/svg+xml",
                "application/font-woff",
                "application/font-woff2"
            });
        });

        // Configure compression levels
        services.Configure<BrotliCompressionProviderOptions>(options =>
        {
            options.Level = CompressionLevel.Fastest; // Balance between speed and size
        });

        services.Configure<GzipCompressionProviderOptions>(options =>
        {
            options.Level = CompressionLevel.Optimal;
        });

        // WebOptimizer for bundling and minification
        services.AddWebOptimizer(pipeline =>
        {
            // Minify CSS files
            pipeline.MinifyCssFiles("css/**/*.css");

            // Minify JavaScript files
            pipeline.MinifyJsFiles("js/**/*.js");

            // Bundle and minify
            pipeline.AddCssBundle("/css/bundle.css",
                "css/site.css",
                "css/theme.css",
                "css/components.css"
            ).MinifyCss();

            pipeline.AddJavaScriptBundle("/js/bundle.js",
                "js/jquery.js",
                "js/site.js",
                "js/app.js"
            ).MinifyJavaScript();

            // Add cache busting
            pipeline.AddFiles("text/css", "/css/site.css")
                .MinifyCss()
                .AddResponseHeader("Cache-Control", "max-age=31536000");
        });
    }

    public void Configure(IApplicationBuilder app)
    {
        // Order matters! Compression should be early in the pipeline
        app.UseResponseCompression();

        app.UseWebOptimizer();

        app.UseStaticFiles(new StaticFileOptions
        {
            OnPrepareResponse = ctx =>
            {
                // Cache static files for 1 year
                ctx.Context.Response.Headers.Append(
                    "Cache-Control", "public,max-age=31536000");
            }
        });

        app.UseRouting();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}

// ✅ Conditional compression for API responses
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "category", "page" })]
    public async Task<ActionResult<List<ProductDto>>> GetProducts(
        [FromQuery] string category,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var products = await _productService.GetProductsAsync(category, page, pageSize);

        // Response will be compressed automatically by middleware
        return Ok(products);
    }

    // Disable compression for small responses or already compressed content
    [HttpGet("image/{id}")]
    [DisableResponseCompression] // Custom attribute
    public async Task<IActionResult> GetProductImage(int id)
    {
        var image = await _productService.GetProductImageAsync(id);
        return File(image, "image/jpeg"); // Already compressed format
    }
}

// Custom attribute to disable compression
public class DisableResponseCompressionAttribute : Attribute, IResourceFilter
{
    public void OnResourceExecuting(ResourceExecutingContext context)
    {
        var compressionFeature = context.HttpContext.Features
            .Get<IHttpsCompressionFeature>();

        if (compressionFeature != null)
        {
            compressionFeature.Mode = HttpsCompressionMode.DoNotCompress;
        }
    }

    public void OnResourceExecuted(ResourceExecutedContext context) { }
}

// ✅ Custom compression middleware for specific scenarios
public class CustomCompressionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CustomCompressionMiddleware> _logger;

    public CustomCompressionMiddleware(
        RequestDelegate next,
        ILogger<CustomCompressionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var originalBody = context.Response.Body;

        // Only compress responses larger than 1KB
        const int compressionThreshold = 1024;

        using var memoryStream = new MemoryStream();
        context.Response.Body = memoryStream;

        await _next(context);

        memoryStream.Seek(0, SeekOrigin.Begin);

        if (memoryStream.Length > compressionThreshold &&
            context.Request.Headers.AcceptEncoding.Any(ae =>
                ae.Contains("br") || ae.Contains("gzip")))
        {
            var acceptEncoding = context.Request.Headers.AcceptEncoding.ToString();

            if (acceptEncoding.Contains("br"))
            {
                context.Response.Headers.Append("Content-Encoding", "br");
                using var brotliStream = new BrotliStream(
                    originalBody,
                    CompressionLevel.Fastest);
                await memoryStream.CopyToAsync(brotliStream);
            }
            else if (acceptEncoding.Contains("gzip"))
            {
                context.Response.Headers.Append("Content-Encoding", "gzip");
                using var gzipStream = new GZipStream(
                    originalBody,
                    CompressionLevel.Fastest);
                await memoryStream.CopyToAsync(gzipStream);
            }

            _logger.LogDebug(
                "Compressed response from {OriginalSize} to compressed size",
                memoryStream.Length);
        }
        else
        {
            await memoryStream.CopyToAsync(originalBody);
        }
    }
}

// ✅ Runtime bundling and minification service
public interface IAssetMinifier
{
    Task<string> MinifyJavaScriptAsync(string javascript);
    Task<string> MinifyCssAsync(string css);
}

public class AssetMinifier : IAssetMinifier
{
    private readonly IMemoryCache _cache;

    public AssetMinifier(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task<string> MinifyJavaScriptAsync(string javascript)
    {
        var hash = ComputeHash(javascript);

        return await _cache.GetOrCreateAsync($"js_minified_{hash}", async entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromHours(24);

            // Use NUglify or similar library
            var minified = NUglify.Uglify.Js(javascript);

            if (minified.HasErrors)
            {
                return javascript; // Return original if minification fails
            }

            return minified.Code;
        });
    }

    public async Task<string> MinifyCssAsync(string css)
    {
        var hash = ComputeHash(css);

        return await _cache.GetOrCreateAsync($"css_minified_{hash}", async entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromHours(24);

            var minified = NUglify.Uglify.Css(css);

            if (minified.HasErrors)
            {
                return css;
            }

            return minified.Code;
        });
    }

    private static string ComputeHash(string input)
    {
        using var sha256 = SHA256.Create();
        var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input));
        return Convert.ToBase64String(hashBytes);
    }
}

/*
Best Practices:
1. ✅ Use Brotli compression (better than gzip) for modern browsers
2. ✅ Only compress responses > 1KB (overhead not worth it for small responses)
3. ✅ Don't compress already compressed content (images, videos, PDFs)
4. ✅ Use fastest compression level for dynamic content
5. ✅ Use optimal compression for static assets
6. ✅ Enable compression for HTTPS (be aware of BREACH/CRIME attacks)
7. ✅ Bundle and minify CSS/JS files
8. ✅ Use cache busting for versioned assets
9. ✅ Compress API JSON responses
10. ✅ Set appropriate cache headers

Compression Comparison:
- Brotli: 15-25% better compression than gzip, slower
- Gzip: Fast, widely supported, good compression
- Deflate: Similar to gzip, less common

Security Considerations:
- BREACH attack: Compression + HTTPS + reflected user input = vulnerability
- Mitigation: Disable compression for sensitive pages with user input
- Use rate limiting and CSRF tokens

Performance Impact:
- Typical savings: 60-80% for text-based responses
- CPU overhead: Minimal with hardware acceleration
- Network savings: Significant for slow connections
*/
```

---

## Q307. How do you optimize static file serving in ASP.NET Core?

```csharp
/*
Static File Optimization Strategies
*/

// ✅ EXCELLENT: Comprehensive static file configuration
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddResponseCaching();
        services.AddResponseCompression();

        // Add memory cache for file metadata
        services.AddMemoryCache();
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.UseResponseCaching();
        app.UseResponseCompression();

        // Default static files with aggressive caching
        app.UseStaticFiles(new StaticFileOptions
        {
            OnPrepareResponse = ctx =>
            {
                // Cache for 1 year (immutable files with version/hash in name)
                const int durationInSeconds = 60 * 60 * 24 * 365;
                ctx.Context.Response.Headers[HeaderNames.CacheControl] =
                    $"public,max-age={durationInSeconds},immutable";

                // Add ETag for validation
                ctx.Context.Response.Headers[HeaderNames.ETag] =
                    $"\"{ComputeHash(ctx.File)}\"";
            },
            HttpsCompression = HttpsCompressionMode.Compress,
            ServeUnknownFileTypes = false,
            DefaultContentType = "application/octet-stream"
        });

        // Separate configuration for frequently changing files
        app.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(env.ContentRootPath, "wwwroot", "dynamic")),
            RequestPath = "/dynamic",
            OnPrepareResponse = ctx =>
            {
                // Short cache with validation
                ctx.Context.Response.Headers[HeaderNames.CacheControl] =
                    "public,max-age=300,must-revalidate";
                ctx.Context.Response.Headers[HeaderNames.ETag] =
                    $"\"{ComputeHash(ctx.File)}\"";
            }
        });

        // CDN/edge cache configuration
        app.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(env.ContentRootPath, "wwwroot", "cdn")),
            RequestPath = "/cdn",
            OnPrepareResponse = ctx =>
            {
                // Cache at CDN edge for 1 hour, browser for 5 minutes
                ctx.Context.Response.Headers[HeaderNames.CacheControl] =
                    "public,max-age=300,s-maxage=3600";

                // Enable CORS for CDN
                ctx.Context.Response.Headers[HeaderNames.AccessControlAllowOrigin] = "*";
            }
        });
    }

    private static string ComputeHash(IFileInfo file)
    {
        using var stream = file.CreateReadStream();
        using var sha256 = SHA256.Create();
        var hash = sha256.ComputeHash(stream);
        return Convert.ToBase64String(hash).Substring(0, 16);
    }
}

// ✅ Custom static file middleware with advanced features
public class OptimizedStaticFileMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly ILogger<OptimizedStaticFileMiddleware> _logger;
    private readonly string _rootPath;

    public OptimizedStaticFileMiddleware(
        RequestDelegate next,
        IMemoryCache cache,
        IWebHostEnvironment env,
        ILogger<OptimizedStaticFileMiddleware> logger)
    {
        _next = next;
        _cache = cache;
        _logger = logger;
        _rootPath = Path.Combine(env.WebRootPath);
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value;

        // Only handle static file requests
        if (!IsStaticFileRequest(path))
        {
            await _next(context);
            return;
        }

        var filePath = Path.Combine(_rootPath, path.TrimStart('/'));

        if (!File.Exists(filePath))
        {
            await _next(context);
            return;
        }

        var fileInfo = new FileInfo(filePath);

        // Check If-None-Match (ETag validation)
        var etag = $"\"{fileInfo.LastWriteTimeUtc.Ticks:x}-{fileInfo.Length:x}\"";
        if (context.Request.Headers.IfNoneMatch == etag)
        {
            context.Response.StatusCode = StatusCodes.Status304NotModified;
            return;
        }

        // Check If-Modified-Since
        if (context.Request.Headers.TryGetValue(HeaderNames.IfModifiedSince, out var ifModifiedSince))
        {
            if (DateTime.TryParse(ifModifiedSince, out var modifiedSince))
            {
                if (fileInfo.LastWriteTimeUtc <= modifiedSince.ToUniversalTime())
                {
                    context.Response.StatusCode = StatusCodes.Status304NotModified;
                    return;
                }
            }
        }

        // Set response headers
        context.Response.Headers[HeaderNames.ETag] = etag;
        context.Response.Headers[HeaderNames.LastModified] =
            fileInfo.LastWriteTimeUtc.ToString("R");
        context.Response.Headers[HeaderNames.CacheControl] =
            "public,max-age=31536000,immutable";
        context.Response.ContentType = GetContentType(path);

        // Serve file
        await context.Response.SendFileAsync(filePath);

        _logger.LogDebug("Served static file: {FilePath}", path);
    }

    private static bool IsStaticFileRequest(string path)
    {
        var extensions = new[] { ".css", ".js", ".jpg", ".png", ".gif", ".svg",
            ".woff", ".woff2", ".ttf", ".eot", ".ico" };
        return extensions.Any(ext => path.EndsWith(ext, StringComparison.OrdinalIgnoreCase));
    }

    private static string GetContentType(string path)
    {
        var provider = new FileExtensionContentTypeProvider();
        if (!provider.TryGetContentType(path, out var contentType))
        {
            contentType = "application/octet-stream";
        }
        return contentType;
    }
}

// ✅ Image optimization service
public interface IImageOptimizer
{
    Task<byte[]> OptimizeImageAsync(byte[] imageData, int maxWidth, int maxHeight, int quality = 85);
    Task<string> GenerateResponsiveImageAsync(string imagePath);
}

public class ImageOptimizer : IImageOptimizer
{
    private readonly IMemoryCache _cache;
    private readonly IWebHostEnvironment _env;

    public ImageOptimizer(IMemoryCache cache, IWebHostEnvironment env)
    {
        _cache = cache;
        _env = env;
    }

    public async Task<byte[]> OptimizeImageAsync(
        byte[] imageData,
        int maxWidth,
        int maxHeight,
        int quality = 85)
    {
        var cacheKey = $"img_{ComputeHash(imageData)}_{maxWidth}x{maxHeight}_{quality}";

        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromHours(24);
            entry.Size = imageData.Length;

            using var image = Image.Load(imageData);

            // Resize if necessary
            if (image.Width > maxWidth || image.Height > maxHeight)
            {
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Size = new Size(maxWidth, maxHeight),
                    Mode = ResizeMode.Max,
                    Sampler = KnownResamplers.Lanczos3
                }));
            }

            using var outputStream = new MemoryStream();

            // Save with optimization
            await image.SaveAsJpegAsync(outputStream, new JpegEncoder
            {
                Quality = quality
            });

            return outputStream.ToArray();
        });
    }

    public async Task<string> GenerateResponsiveImageAsync(string imagePath)
    {
        // Generate srcset for responsive images
        var sizes = new[] { 320, 640, 960, 1280, 1920 };
        var srcset = new List<string>();

        foreach (var size in sizes)
        {
            var resizedPath = $"{Path.GetFileNameWithoutExtension(imagePath)}-{size}w{Path.GetExtension(imagePath)}";
            var fullPath = Path.Combine(_env.WebRootPath, "images", resizedPath);

            if (!File.Exists(fullPath))
            {
                var originalData = await File.ReadAllBytesAsync(
                    Path.Combine(_env.WebRootPath, imagePath));
                var optimized = await OptimizeImageAsync(originalData, size, size);
                await File.WriteAllBytesAsync(fullPath, optimized);
            }

            srcset.Add($"/images/{resizedPath} {size}w");
        }

        return string.Join(", ", srcset);
    }

    private static string ComputeHash(byte[] data)
    {
        using var sha256 = SHA256.Create();
        var hash = sha256.ComputeHash(data);
        return Convert.ToBase64String(hash).Substring(0, 16);
    }
}

// ✅ File versioning and cache busting
public class AssetVersionHelper
{
    private static readonly Dictionary<string, string> _versionCache = new();
    private static readonly object _lock = new();

    public static string GetVersionedPath(string path, IWebHostEnvironment env)
    {
        if (_versionCache.TryGetValue(path, out var versionedPath))
        {
            return versionedPath;
        }

        lock (_lock)
        {
            if (_versionCache.TryGetValue(path, out versionedPath))
            {
                return versionedPath;
            }

            var fullPath = Path.Combine(env.WebRootPath, path.TrimStart('/'));

            if (!File.Exists(fullPath))
            {
                return path;
            }

            var fileInfo = new FileInfo(fullPath);
            var version = fileInfo.LastWriteTimeUtc.Ticks.ToString("x");

            versionedPath = $"{path}?v={version}";
            _versionCache[path] = versionedPath;

            return versionedPath;
        }
    }
}

// Usage in view
// <link rel="stylesheet" href="@AssetVersionHelper.GetVersionedPath("/css/site.css", env)" />

/*
Best Practices:
1. ✅ Use aggressive caching (1 year) for versioned assets
2. ✅ Implement ETags for cache validation
3. ✅ Use SendFileAsync for efficient file serving
4. ✅ Separate caching strategies for different file types
5. ✅ Optimize images (resize, compress, WebP format)
6. ✅ Use responsive images with srcset
7. ✅ Enable HTTP/2 server push for critical resources
8. ✅ Implement file version cache busting
9. ✅ Serve static files from CDN
10. ✅ Use proper MIME types

Performance Optimizations:
- SendFileAsync uses kernel-mode copying (zero-copy)
- ETags prevent unnecessary file transfers
- Immutable directive tells browser never revalidate
- Content hashing for perfect cache invalidation
- Range request support for large files

Cache Header Strategy:
- Immutable assets (hash in filename): max-age=31536000,immutable
- Infrequently changing: max-age=86400,must-revalidate
- Frequently changing: max-age=300,must-revalidate
- Private assets: private,no-cache,no-store

Tools:
- ImageSharp for image processing
- WebOptimizer for bundling
- BundlerMinifier for build-time optimization
- Cloudflare/Azure CDN for edge caching
*/
```

---

## Q308. How do you optimize database connection pooling in ASP.NET Core with Entity Framework Core?

```csharp
/*
Database Connection Pooling Optimization
*/

// ✅ EXCELLENT: Optimized connection string with pooling configuration
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // SQL Server with optimized connection pooling
        var connectionString = "Server=localhost;Database=MyDb;User Id=sa;Password=Pass;" +
            "Min Pool Size=10;" +          // Minimum connections to keep in pool
            "Max Pool Size=100;" +          // Maximum connections in pool
            "Connection Lifetime=300;" +    // Recycle connections after 5 minutes
            "Connection Timeout=30;" +      // Connection attempt timeout
            "Pooling=true;" +               // Enable connection pooling
            "MultipleActiveResultSets=true;"; // Enable MARS

        services.AddDbContext<ApplicationDbContext>(options =>
        {
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                // Enable connection resiliency
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorNumbersToAdd: null);

                // Command timeout
                sqlOptions.CommandTimeout(30);

                // Use compiled queries
                sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
            });

            // Disable tracking for read-only scenarios
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);

            // Enable sensitive data logging only in development
            if (env.IsDevelopment())
            {
                options.EnableSensitiveDataLogging();
                options.EnableDetailedErrors();
            }
        });

        // PostgreSQL connection pooling
        var postgresConnectionString = "Host=localhost;Database=mydb;Username=postgres;Password=pass;" +
            "Minimum Pool Size=10;" +
            "Maximum Pool Size=100;" +
            "Connection Idle Lifetime=300;" + // Close idle connections after 5 minutes
            "Connection Pruning Interval=10;"; // Check for idle connections every 10 seconds

        services.AddDbContext<PostgresDbContext>(options =>
            options.UseNpgsql(postgresConnectionString));
    }
}

// ✅ DbContext pooling (ASP.NET Core 2.1+)
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Use DbContext pooling instead of creating new instances
        // Significantly reduces overhead of DbContext instantiation
        services.AddDbContextPool<ApplicationDbContext>(options =>
        {
            options.UseSqlServer(connectionString);
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
        }, poolSize: 128); // Default is 128
    }
}

// ✅ GOOD: Proper DbContext lifetime management
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    // DbContext injected per request - automatically disposed
    public ProductsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<ProductDto>>> GetProducts()
    {
        // Connection automatically returned to pool after request
        var products = await _context.Products
            .AsNoTracking()
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            })
            .ToListAsync();

        return Ok(products);
    }
}

// ❌ BAD: Creating DbContext instances manually
public class BadProductService
{
    private readonly IConfiguration _configuration;

    public async Task<List<Product>> GetProductsBad()
    {
        // ❌ Creates new connection, bypasses pooling!
        using var context = new ApplicationDbContext();
        return await context.Products.ToListAsync();
    }
}

// ✅ GOOD: Using DbContext factory for background services
public class BackgroundProductProcessor : BackgroundService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    private readonly ILogger<BackgroundProductProcessor> _logger;

    public BackgroundProductProcessor(
        IDbContextFactory<ApplicationDbContext> contextFactory,
        ILogger<BackgroundProductProcessor> logger)
    {
        _contextFactory = contextFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // Create short-lived context for each operation
            await using var context = await _contextFactory.CreateDbContextAsync(stoppingToken);

            await ProcessProductsAsync(context, stoppingToken);

            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }

    private async Task ProcessProductsAsync(
        ApplicationDbContext context,
        CancellationToken cancellationToken)
    {
        var products = await context.Products
            .Where(p => p.Status == ProductStatus.Pending)
            .ToListAsync(cancellationToken);

        foreach (var product in products)
        {
            product.Status = ProductStatus.Processed;
        }

        await context.SaveChangesAsync(cancellationToken);
    }
}

// Register DbContext factory
services.AddDbContextFactory<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// ✅ Connection pool monitoring
public class ConnectionPoolMonitor : IHostedService
{
    private readonly ILogger<ConnectionPoolMonitor> _logger;
    private Timer _timer;

    public ConnectionPoolMonitor(ILogger<ConnectionPoolMonitor> logger)
    {
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _timer = new Timer(LogConnectionStats, null, TimeSpan.Zero, TimeSpan.FromMinutes(5));
        return Task.CompletedTask;
    }

    private void LogConnectionStats(object state)
    {
        try
        {
            // Get connection pool statistics (SQL Server specific)
            var stats = SqlConnection.RetrieveStatistics();

            _logger.LogInformation(
                "Connection Pool Stats - Active: {Active}, Available: {Available}",
                stats["NumberOfActiveConnections"],
                stats["NumberOfFreeConnections"]);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve connection pool stats");
        }
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _timer?.Dispose();
        return Task.CompletedTask;
    }
}

// ✅ Advanced: Custom connection interceptor
public class ConnectionLoggingInterceptor : DbConnectionInterceptor
{
    private readonly ILogger<ConnectionLoggingInterceptor> _logger;

    public ConnectionLoggingInterceptor(ILogger<ConnectionLoggingInterceptor> logger)
    {
        _logger = logger;
    }

    public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(
        DbConnection connection,
        ConnectionEventData eventData,
        InterceptionResult result,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Opening connection to {Database}", connection.Database);
        return await base.ConnectionOpeningAsync(connection, eventData, result, cancellationToken);
    }

    public override async ValueTask ConnectionOpenedAsync(
        DbConnection connection,
        ConnectionEndEventData eventData,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug(
            "Connection opened. State: {State}, Duration: {Duration}ms",
            connection.State,
            eventData.Duration.TotalMilliseconds);

        await base.ConnectionOpenedAsync(connection, eventData, cancellationToken);
    }
}

// Register interceptor
services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlServer(connectionString)
        .AddInterceptors(new ConnectionLoggingInterceptor(logger));
});

/*
Best Practices:
1. ✅ Use DbContextPool for better performance
2. ✅ Configure appropriate Min/Max pool sizes (10-100 typical)
3. ✅ Set connection lifetime to handle DNS changes (5 minutes)
4. ✅ Use DbContext per request (scoped lifetime)
5. ✅ Use IDbContextFactory for background services
6. ✅ Enable connection resiliency for transient failures
7. ✅ Monitor connection pool usage
8. ✅ Avoid holding connections open longer than needed
9. ✅ Use asynchronous operations
10. ✅ Don't create DbContext instances manually

Connection Pool Sizing Guidelines:
- Web applications: Max Pool Size = 100 * number of web servers
- CPU-bound: Max Pool Size = CPU cores + 1
- I/O-bound: Max Pool Size = CPU cores * 2-3
- Monitor and adjust based on metrics

Common Issues:
❌ Connection pool exhaustion (too many open connections)
❌ Connection leaks (not disposing DbContext)
❌ Too small pool size (performance bottleneck)
❌ Too large pool size (resource waste)
❌ Not using connection resiliency

Performance Benefits:
- Reusing connections (10-100ms saved per request)
- Reduced TCP/TLS handshake overhead
- Lower memory usage with pooling
- Better resource utilization

Tools:
- SQL Server Profiler for connection monitoring
- PerfView for connection pool analysis
- Application Insights for connection telemetry
- dotnet-counters for real-time metrics
*/
```

---

## Q309. What are the differences between Lazy Loading, Eager Loading, and Explicit Loading in Entity Framework Core, and which should you use?

```csharp
/*
EF Core Loading Strategies - Performance Comparison
*/

// ❌ BAD: Lazy Loading (N+1 Problem)
public class LazyLoadingExample
{
    public class ApplicationDbContext : DbContext
    {
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder
                .UseSqlServer(connectionString)
                .UseLazyLoadingProxies(); // Enable lazy loading
        }
    }

    // Entities with virtual navigation properties
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int CategoryId { get; set; }
        public virtual Category Category { get; set; } // Lazy loaded
        public virtual ICollection<Review> Reviews { get; set; } // Lazy loaded
    }

    // ❌ This causes N+1 queries!
    public async Task<List<ProductDto>> GetProductsWithLazyLoading()
    {
        var products = await _context.Products.ToListAsync(); // 1 query

        return products.Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            CategoryName = p.Category.Name, // N queries (one per product!)
            ReviewCount = p.Reviews.Count    // N more queries!
        }).ToList();

        // Total: 1 + 2N queries - VERY BAD!
    }
}

// ✅ GOOD: Eager Loading with Include
public class EagerLoadingExample
{
    public async Task<List<ProductDto>> GetProductsWithEagerLoading()
    {
        // Load all related data in a single query (or optimized queries)
        var products = await _context.Products
            .Include(p => p.Category)         // Join Category table
            .Include(p => p.Reviews)          // Join Reviews table
            .AsNoTracking()                   // No change tracking needed
            .ToListAsync();

        return products.Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            CategoryName = p.Category.Name,
            ReviewCount = p.Reviews.Count
        }).ToList();

        // Total: 1-2 queries depending on split query behavior
    }

    // ✅ EXCELLENT: Eager loading with projection (best performance)
    public async Task<List<ProductDto>> GetProductsWithProjection()
    {
        return await _context.Products
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                CategoryName = p.Category.Name,  // Automatically joined
                ReviewCount = p.Reviews.Count     // Optimized to SQL COUNT
            })
            .ToListAsync();

        // Single optimized query with only needed columns
    }

    // ✅ Multiple levels of eager loading
    public async Task<List<Product>> GetProductsWithNestedIncludes()
    {
        return await _context.Products
            .Include(p => p.Category)
                .ThenInclude(c => c.Department)
            .Include(p => p.Reviews)
                .ThenInclude(r => r.User)
            .AsNoTracking()
            .ToListAsync();
    }

    // ✅ Filtered include (EF Core 5.0+)
    public async Task<List<Product>> GetProductsWithFilteredIncludes()
    {
        return await _context.Products
            .Include(p => p.Reviews.Where(r => r.Rating >= 4).OrderByDescending(r => r.CreatedDate))
            .AsNoTracking()
            .ToListAsync();
    }
}

// ✅ GOOD: Explicit Loading (load related data on demand)
public class ExplicitLoadingExample
{
    public async Task<Product> GetProductWithExplicitLoading(int id)
    {
        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product == null)
            return null;

        // Load related data explicitly when needed
        await _context.Entry(product)
            .Reference(p => p.Category)  // Load single navigation property
            .LoadAsync();

        await _context.Entry(product)
            .Collection(p => p.Reviews)  // Load collection navigation property
            .LoadAsync();

        return product;
    }

    // ✅ Explicit loading with filtering
    public async Task<Product> GetProductWithFilteredExplicitLoading(int id)
    {
        var product = await _context.Products.FindAsync(id);

        if (product == null)
            return null;

        // Load only specific reviews
        await _context.Entry(product)
            .Collection(p => p.Reviews)
            .Query()
            .Where(r => r.Rating >= 4)
            .OrderByDescending(r => r.CreatedDate)
            .Take(10)
            .LoadAsync();

        return product;
    }

    // ✅ Check if already loaded
    public async Task<Product> GetProductWithConditionalLoading(int id)
    {
        var product = await _context.Products.FindAsync(id);

        if (product == null)
            return null;

        // Only load if not already loaded
        if (!_context.Entry(product).Reference(p => p.Category).IsLoaded)
        {
            await _context.Entry(product).Reference(p => p.Category).LoadAsync();
        }

        return product;
    }
}

// ✅ EXCELLENT: Split Query for large includes (EF Core 5.0+)
public class SplitQueryExample
{
    public async Task<List<Product>> GetProductsWithSplitQuery()
    {
        // Default: Single query with JOINs (cartesian explosion risk)
        var products = await _context.Products
            .Include(p => p.Reviews)
            .Include(p => p.Images)
            .AsSplitQuery()  // Use multiple queries instead of one big JOIN
            .ToListAsync();

        return products;

        // Query 1: SELECT * FROM Products
        // Query 2: SELECT * FROM Reviews WHERE ProductId IN (...)
        // Query 3: SELECT * FROM Images WHERE ProductId IN (...)
    }

    // Configure globally
    public class ApplicationDbContext : DbContext
    {
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder
                .UseSqlServer(connectionString,
                    o => o.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery));
        }
    }
}

// ✅ Performance comparison and decision matrix
public class LoadingStrategyComparison
{
    /*
    LAZY LOADING:
    Pros:
    - Simple to use, transparent
    - Load data only when needed

    Cons:
    - N+1 query problem
    - Unpredictable performance
    - Requires proxy creation overhead
    - Not recommended for web applications

    Use when:
    - Desktop applications with long-lived contexts
    - Rarely accessing related data
    - Not recommended for most scenarios

    EAGER LOADING:
    Pros:
    - Predictable query count
    - Can optimize with projection
    - No additional round trips

    Cons:
    - May load unnecessary data
    - Cartesian explosion with multiple collections
    - Large result sets

    Use when:
    - You know you'll need related data
    - Number of related entities is small
    - Web APIs and web applications (RECOMMENDED)

    EXPLICIT LOADING:
    Pros:
    - Full control over what's loaded
    - Can filter related data
    - Avoid loading unnecessary data

    Cons:
    - More verbose code
    - Additional round trips
    - Must manage loading manually

    Use when:
    - Conditional loading based on business logic
    - Loading large collections with filtering
    - Incremental data loading scenarios
    */

    // ✅ BEST PRACTICE: Use projection for optimal performance
    public async Task<List<ProductSummaryDto>> GetProductSummaries()
    {
        return await _context.Products
            .Where(p => p.IsActive)
            .Select(p => new ProductSummaryDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                CategoryName = p.Category.Name,
                AverageRating = p.Reviews.Average(r => (double?)r.Rating) ?? 0,
                ReviewCount = p.Reviews.Count,
                ImageUrl = p.Images.OrderBy(i => i.Order).Select(i => i.Url).FirstOrDefault()
            })
            .ToListAsync();

        // Single optimized query, no over-fetching, no N+1 problem
    }
}

/*
Performance Recommendations:

1. ✅ PREFER: Projection (Select) - Best performance
2. ✅ GOOD: Eager Loading (Include) - Predictable, good for web apps
3. ⚠️  CAUTION: Explicit Loading - Use for conditional scenarios
4. ❌ AVOID: Lazy Loading - N+1 problem, unpredictable performance

Query Count Examples (100 products):
- Lazy Loading: 1 + 100 + 100 = 201 queries ❌
- Eager Loading: 1-3 queries ✅
- Projection: 1 query ✅✅

Best Practices:
1. ✅ Use AsNoTracking() for read-only queries
2. ✅ Use projection when you only need specific fields
3. ✅ Use AsSplitQuery() for multiple collection includes
4. ✅ Filter data in the database, not in memory
5. ✅ Measure and profile your queries
6. ❌ Never use lazy loading in web applications
7. ❌ Avoid Include() if you don't need all fields
8. ❌ Don't include collections without limiting the data

Tools for Analysis:
- EF Core logging to see generated SQL
- MiniProfiler for query analysis
- SQL Server Profiler
- Application Insights
*/
```

---

## Q310. How do you optimize application startup time in ASP.NET Core?

```csharp
/*
Application Startup Optimization Strategies
*/

// ✅ EXCELLENT: Optimized Program.cs and Startup configuration
public class Program
{
    public static async Task Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ✅ Use minimal hosting model (ASP.NET Core 6.0+)
        // Faster startup than traditional Startup.cs approach

        // ✅ Reduce logging overhead during startup
        builder.Logging.ClearProviders();
        if (builder.Environment.IsDevelopment())
        {
            builder.Logging.AddConsole();
            builder.Logging.AddDebug();
        }
        else
        {
            builder.Logging.AddApplicationInsights();
        }

        // ✅ Configure services efficiently
        ConfigureServices(builder.Services, builder.Configuration, builder.Environment);

        var app = builder.Build();

        // ✅ Defer expensive initialization to first request or background
        _ = Task.Run(async () => await InitializeBackgroundServicesAsync(app.Services));

        // ✅ Configure minimal middleware pipeline
        ConfigureMiddleware(app, builder.Environment);

        await app.RunAsync();
    }

    private static void ConfigureServices(
        IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        // ✅ Register only essential services
        services.AddControllers()
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
                options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
            });

        // ✅ Use AddDbContextPool instead of AddDbContext
        services.AddDbContextPool<ApplicationDbContext>(options =>
        {
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection"));
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
        }, poolSize: 128);

        // ✅ Lazy initialization for expensive services
        services.AddSingleton<IExpensiveService>(provider =>
            new Lazy<ExpensiveService>(() => new ExpensiveService()).Value);

        // ✅ Register lightweight services as singletons when possible
        services.AddSingleton<IMemoryCache, MemoryCache>();
        services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();

        // ✅ Defer heavy initialization
        services.AddSingleton<ICacheWarmer, CacheWarmer>();

        // ✅ Conditional service registration
        if (environment.IsProduction())
        {
            services.AddResponseCaching();
            services.AddResponseCompression();
        }

        // ❌ AVOID: Expensive operations in ConfigureServices
        // Don't validate configurations here, defer to first use

        // ✅ Use source generators for JSON serialization (System.Text.Json)
        services.ConfigureHttpJsonOptions(options =>
        {
            options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
        });
    }

    private static void ConfigureMiddleware(WebApplication app, IHostEnvironment environment)
    {
        // ✅ Minimal middleware pipeline
        if (environment.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }
        else
        {
            app.UseExceptionHandler("/error");
            app.UseHsts();
        }

        // ✅ Order middleware by frequency of use
        app.UseRouting();
        app.UseAuthentication();
        app.UseAuthorization();
        app.MapControllers();
    }

    // ✅ Background initialization to not block startup
    private static async Task InitializeBackgroundServicesAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var cacheWarmer = scope.ServiceProvider.GetRequiredService<ICacheWarmer>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

        try
        {
            await Task.Delay(TimeSpan.FromSeconds(5)); // Wait for app to fully start
            await cacheWarmer.WarmCacheAsync();
            logger.LogInformation("Cache warming completed");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Cache warming failed");
        }
    }
}

// ✅ Lazy service initialization pattern
public interface IExpensiveService
{
    Task<string> DoWorkAsync();
}

public class ExpensiveService : IExpensiveService
{
    private readonly ILogger<ExpensiveService> _logger;

    public ExpensiveService(ILogger<ExpensiveService> logger)
    {
        _logger = logger;
        // ❌ Don't do expensive work in constructor
    }

    public async Task<string> DoWorkAsync()
    {
        // Work happens here, not during service registration
        return await Task.FromResult("Done");
    }
}

// ✅ Cache warming service (runs in background)
public interface ICacheWarmer
{
    Task WarmCacheAsync();
}

public class CacheWarmer : ICacheWarmer
{
    private readonly IMemoryCache _cache;
    private readonly IProductRepository _productRepository;
    private readonly ILogger<CacheWarmer> _logger;

    public CacheWarmer(
        IMemoryCache cache,
        IProductRepository productRepository,
        ILogger<CacheWarmer> logger)
    {
        _cache = cache;
        _productRepository = productRepository;
        _logger = logger;
    }

    public async Task WarmCacheAsync()
    {
        _logger.LogInformation("Starting cache warming...");

        // Load frequently accessed data into cache
        var popularProducts = await _productRepository.GetPopularProductsAsync();

        foreach (var product in popularProducts)
        {
            _cache.Set($"product_{product.Id}", product, TimeSpan.FromHours(1));
        }

        _logger.LogInformation("Cache warming completed for {Count} products", popularProducts.Count);
    }
}

// ✅ Source generator for JSON (AOT compilation support)
[JsonSerializable(typeof(ProductDto))]
[JsonSerializable(typeof(List<ProductDto>))]
[JsonSerializable(typeof(CategoryDto))]
public partial class AppJsonSerializerContext : JsonSerializerContext
{
}

// ✅ Feature flags for conditional service registration
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var features = configuration.GetSection("Features").Get<FeatureFlags>();

        services.AddSingleton(features);

        // Register services based on feature flags
        if (features.EnableCaching)
        {
            services.AddResponseCaching();
            services.AddMemoryCache();
        }

        if (features.EnableCompression)
        {
            services.AddResponseCompression();
        }

        if (features.EnableRateLimiting)
        {
            services.AddRateLimiter(options => { /* config */ });
        }

        return services;
    }
}

public class FeatureFlags
{
    public bool EnableCaching { get; set; }
    public bool EnableCompression { get; set; }
    public bool EnableRateLimiting { get; set; }
}

// ✅ Health checks with reduced startup impact
public static class HealthCheckExtensions
{
    public static IServiceCollection AddMinimalHealthChecks(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var healthChecks = services.AddHealthChecks();

        // ✅ Add only essential startup health checks
        healthChecks.AddCheck("self", () => HealthCheckResult.Healthy());

        // ✅ Defer expensive health checks
        if (configuration.GetValue<bool>("HealthChecks:EnableDatabase"))
        {
            healthChecks.AddDbContextCheck<ApplicationDbContext>(
                name: "database",
                tags: new[] { "ready" });  // Only check on /health/ready endpoint
        }

        return services;
    }
}

// ✅ Database migration strategy
public static class DatabaseMigrationExtensions
{
    public static async Task MigrateDatabaseAsync(this WebApplication app)
    {
        var environment = app.Services.GetRequiredService<IHostEnvironment>();
        var logger = app.Services.GetRequiredService<ILogger<Program>>();

        if (environment.IsDevelopment())
        {
            using var scope = app.Services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            try
            {
                // ✅ Run migrations in background, don't block startup
                _ = Task.Run(async () =>
                {
                    await Task.Delay(TimeSpan.FromSeconds(2));
                    await context.Database.MigrateAsync();
                    logger.LogInformation("Database migration completed");
                });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Database migration failed");
            }
        }
    }
}

/*
Best Practices:
1. ✅ Use minimal hosting model (ASP.NET Core 6+)
2. ✅ Register only essential services during startup
3. ✅ Use DbContextPool instead of DbContext
4. ✅ Defer expensive initialization to background tasks
5. ✅ Use lazy initialization for expensive services
6. ✅ Minimize middleware pipeline
7. ✅ Use feature flags for conditional registration
8. ✅ Avoid synchronous I/O during startup
9. ✅ Use source generators for AOT compilation
10. ✅ Run database migrations in background (dev only)

Startup Time Optimization Checklist:
✅ Reduce service registration overhead
✅ Minimize middleware count
✅ Defer cache warming
✅ Lazy load expensive services
✅ Use pooled DbContext
✅ Reduce logging verbosity
✅ Conditional service registration
✅ Background initialization
✅ Avoid reflection during startup
✅ Use compiled expressions

Measurements:
- Typical startup: 500ms - 2s
- Optimized startup: 100ms - 500ms
- Target: < 1 second for most applications

Tools:
- dotnet-trace for startup analysis
- PerfView for detailed profiling
- Application Insights for cold start monitoring
- Startup hooks for custom profiling

Common Bottlenecks:
❌ Database migrations blocking startup
❌ Expensive dependency injection registration
❌ Heavy middleware pipeline
❌ Synchronous I/O operations
❌ Assembly scanning and reflection
❌ Configuration validation
*/
```

---

## Q311. How do you implement performance monitoring and diagnostics in ASP.NET Core applications?

```csharp
/*
Performance Monitoring and Diagnostics Implementation
*/

// ✅ EXCELLENT: Comprehensive performance monitoring setup
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // ✅ Add Application Insights telemetry
        builder.Services.AddApplicationInsightsTelemetry(options =>
        {
            options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
            options.EnableAdaptiveSampling = true;
            options.EnableQuickPulseMetricStream = true;
        });

        // ✅ Add custom telemetry processor
        builder.Services.AddSingleton<ITelemetryProcessor, PerformanceTelemetryProcessor>();

        // ✅ Add EventCounters for custom metrics
        builder.Services.AddSingleton<PerformanceMetrics>();

        // ✅ Add diagnostic services
        builder.Services.AddSingleton<IPerformanceMonitor, PerformanceMonitor>();

        // ✅ Add MiniProfiler for development
        if (builder.Environment.IsDevelopment())
        {
            builder.Services.AddMiniProfiler(options =>
            {
                options.RouteBasePath = "/profiler";
                options.PopupRenderPosition = RenderPosition.BottomLeft;
                options.ColorScheme = ColorScheme.Auto;
            }).AddEntityFramework();
        }

        var app = builder.Build();

        // ✅ Use MiniProfiler middleware
        if (app.Environment.IsDevelopment())
        {
            app.UseMiniProfiler();
        }

        // ✅ Add response time middleware
        app.UseMiddleware<ResponseTimeMiddleware>();

        // ✅ Add request tracking middleware
        app.UseMiddleware<RequestTrackingMiddleware>();

        app.MapControllers();
        app.Run();
    }
}

// ✅ Response time tracking middleware
public class ResponseTimeMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ResponseTimeMiddleware> _logger;

    public ResponseTimeMiddleware(
        RequestDelegate next,
        ILogger<ResponseTimeMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();

            var elapsed = stopwatch.ElapsedMilliseconds;

            // Add response time header
            context.Response.Headers["X-Response-Time-ms"] = elapsed.ToString();

            // Log slow requests
            if (elapsed > 1000)
            {
                _logger.LogWarning(
                    "Slow request: {Method} {Path} took {ElapsedMs}ms",
                    context.Request.Method,
                    context.Request.Path,
                    elapsed);
            }
        }
    }
}

// ✅ Request tracking middleware
public class RequestTrackingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly PerformanceMetrics _metrics;

    public RequestTrackingMiddleware(
        RequestDelegate next,
        PerformanceMetrics metrics)
    {
        _next = next;
        _metrics = metrics;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        _metrics.IncrementRequestCount();

        try
        {
            await _next(context);

            _metrics.RecordRequestDuration(stopwatch.ElapsedMilliseconds);

            if (context.Response.StatusCode >= 200 && context.Response.StatusCode < 300)
            {
                _metrics.IncrementSuccessCount();
            }
            else
            {
                _metrics.IncrementErrorCount();
            }
        }
        catch
        {
            _metrics.IncrementErrorCount();
            throw;
        }
        finally
        {
            stopwatch.Stop();
        }
    }
}

// ✅ Custom performance metrics with EventCounters
public class PerformanceMetrics : IDisposable
{
    private readonly EventCounter _requestCounter;
    private readonly EventCounter _errorCounter;
    private readonly EventCounter _successCounter;
    private readonly EventCounter _requestDuration;
    private readonly EventSource _eventSource;

    public PerformanceMetrics()
    {
        _eventSource = new EventSource("MyApp-Performance");

        _requestCounter = new EventCounter("request-count", _eventSource)
        {
            DisplayName = "Request Count"
        };

        _errorCounter = new EventCounter("error-count", _eventSource)
        {
            DisplayName = "Error Count"
        };

        _successCounter = new EventCounter("success-count", _eventSource)
        {
            DisplayName = "Success Count"
        };

        _requestDuration = new EventCounter("request-duration", _eventSource)
        {
            DisplayName = "Request Duration (ms)",
            DisplayUnits = "ms"
        };
    }

    public void IncrementRequestCount() => _requestCounter.WriteMetric(1);
    public void IncrementErrorCount() => _errorCounter.WriteMetric(1);
    public void IncrementSuccessCount() => _successCounter.WriteMetric(1);
    public void RecordRequestDuration(long milliseconds) =>
        _requestDuration.WriteMetric(milliseconds);

    public void Dispose()
    {
        _requestCounter?.Dispose();
        _errorCounter?.Dispose();
        _successCounter?.Dispose();
        _requestDuration?.Dispose();
        _eventSource?.Dispose();
    }
}

// ✅ Custom Application Insights telemetry processor
public class PerformanceTelemetryProcessor : ITelemetryProcessor
{
    private readonly ITelemetryProcessor _next;

    public PerformanceTelemetryProcessor(ITelemetryProcessor next)
    {
        _next = next;
    }

    public void Process(ITelemetry item)
    {
        if (item is RequestTelemetry request)
        {
            // Add custom properties
            request.Properties["MachineName"] = Environment.MachineName;
            request.Properties["ThreadId"] = Thread.CurrentThread.ManagedThreadId.ToString();

            // Mark slow requests
            if (request.Duration > TimeSpan.FromSeconds(3))
            {
                request.Properties["IsSlowRequest"] = "true";
            }
        }

        if (item is DependencyTelemetry dependency)
        {
            // Track slow database queries
            if (dependency.Type == "SQL" && dependency.Duration > TimeSpan.FromSeconds(1))
            {
                dependency.Properties["IsSlowQuery"] = "true";
            }
        }

        _next.Process(item);
    }
}

// ✅ Performance monitoring service
public interface IPerformanceMonitor
{
    Task<PerformanceReport> GetPerformanceReportAsync();
    Task TrackOperationAsync(string operationName, Func<Task> operation);
    void TrackMetric(string metricName, double value, Dictionary<string, string> properties = null);
}

public class PerformanceMonitor : IPerformanceMonitor
{
    private readonly TelemetryClient _telemetryClient;
    private readonly ILogger<PerformanceMonitor> _logger;

    public PerformanceMonitor(
        TelemetryClient telemetryClient,
        ILogger<PerformanceMonitor> logger)
    {
        _telemetryClient = telemetryClient;
        _logger = logger;
    }

    public async Task<PerformanceReport> GetPerformanceReportAsync()
    {
        var report = new PerformanceReport
        {
            Timestamp = DateTime.UtcNow,
            CpuUsage = GetCpuUsage(),
            MemoryUsage = GetMemoryUsage(),
            GcStats = GetGcStats()
        };

        return await Task.FromResult(report);
    }

    public async Task TrackOperationAsync(string operationName, Func<Task> operation)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await operation();
            stopwatch.Stop();

            _telemetryClient.TrackMetric(
                $"{operationName}_Duration",
                stopwatch.ElapsedMilliseconds,
                new Dictionary<string, string>
                {
                    ["OperationName"] = operationName,
                    ["Status"] = "Success"
                });
        }
        catch (Exception ex)
        {
            stopwatch.Stop();

            _telemetryClient.TrackException(ex, new Dictionary<string, string>
            {
                ["OperationName"] = operationName,
                ["Duration"] = stopwatch.ElapsedMilliseconds.ToString()
            });

            _logger.LogError(ex, "Operation {OperationName} failed after {Duration}ms",
                operationName, stopwatch.ElapsedMilliseconds);

            throw;
        }
    }

    public void TrackMetric(string metricName, double value, Dictionary<string, string> properties = null)
    {
        _telemetryClient.TrackMetric(metricName, value, properties);
    }

    private double GetCpuUsage()
    {
        var process = Process.GetCurrentProcess();
        var startTime = DateTime.UtcNow;
        var startCpuUsage = process.TotalProcessorTime;

        Thread.Sleep(500);

        var endTime = DateTime.UtcNow;
        var endCpuUsage = process.TotalProcessorTime;

        var cpuUsedMs = (endCpuUsage - startCpuUsage).TotalMilliseconds;
        var totalMsPassed = (endTime - startTime).TotalMilliseconds;

        var cpuUsageTotal = cpuUsedMs / (Environment.ProcessorCount * totalMsPassed);

        return cpuUsageTotal * 100;
    }

    private long GetMemoryUsage()
    {
        var process = Process.GetCurrentProcess();
        return process.WorkingSet64 / (1024 * 1024); // MB
    }

    private GcStatistics GetGcStats()
    {
        return new GcStatistics
        {
            Gen0Collections = GC.CollectionCount(0),
            Gen1Collections = GC.CollectionCount(1),
            Gen2Collections = GC.CollectionCount(2),
            TotalMemory = GC.GetTotalMemory(false) / (1024 * 1024) // MB
        };
    }
}

public class PerformanceReport
{
    public DateTime Timestamp { get; set; }
    public double CpuUsage { get; set; }
    public long MemoryUsage { get; set; }
    public GcStatistics GcStats { get; set; }
}

public class GcStatistics
{
    public int Gen0Collections { get; set; }
    public int Gen1Collections { get; set; }
    public int Gen2Collections { get; set; }
    public long TotalMemory { get; set; }
}

// ✅ Usage in controllers
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly IPerformanceMonitor _performanceMonitor;
    private readonly TelemetryClient _telemetryClient;

    public ProductsController(
        IProductService productService,
        IPerformanceMonitor performanceMonitor,
        TelemetryClient telemetryClient)
    {
        _productService = productService;
        _performanceMonitor = performanceMonitor;
        _telemetryClient = telemetryClient;
    }

    [HttpGet]
    public async Task<ActionResult<List<ProductDto>>> GetProducts()
    {
        // Track custom operation
        List<ProductDto> products = null;

        await _performanceMonitor.TrackOperationAsync("GetProducts", async () =>
        {
            products = await _productService.GetProductsAsync();
        });

        // Track custom metric
        _performanceMonitor.TrackMetric("ProductCount", products.Count);

        return Ok(products);
    }

    [HttpGet("performance")]
    public async Task<ActionResult<PerformanceReport>> GetPerformanceReport()
    {
        var report = await _performanceMonitor.GetPerformanceReportAsync();
        return Ok(report);
    }
}

// ✅ EF Core query logging configuration
services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlServer(connectionString)
        .EnableSensitiveDataLogging(builder.Environment.IsDevelopment())
        .EnableDetailedErrors(builder.Environment.IsDevelopment())
        .LogTo(
            message => Console.WriteLine(message),
            new[] { DbLoggerCategory.Database.Command.Name },
            LogLevel.Information,
            DbContextLoggerOptions.SingleLine | DbContextLoggerOptions.UtcTime);
});

/*
Best Practices:
1. ✅ Use Application Insights for production monitoring
2. ✅ Use MiniProfiler for development profiling
3. ✅ Track custom metrics with EventCounters
4. ✅ Log slow requests and queries
5. ✅ Monitor memory and CPU usage
6. ✅ Track GC statistics
7. ✅ Use structured logging
8. ✅ Implement request correlation
9. ✅ Monitor dependency calls
10. ✅ Set up alerts for performance thresholds

Key Metrics to Monitor:
- Request rate and duration
- Error rate
- CPU and memory usage
- GC collections and pressure
- Database query performance
- External API call duration
- Cache hit/miss ratio
- Thread pool saturation

Tools:
- Application Insights (Azure)
- MiniProfiler (development)
- dotnet-counters (CLI monitoring)
- dotnet-trace (performance tracing)
- PerfView (advanced profiling)
- Visual Studio Profiler
- JetBrains dotTrace
- Seq/Elasticsearch for log aggregation

Alerting Thresholds:
- Response time > 3s (warning), > 5s (critical)
- Error rate > 1% (warning), > 5% (critical)
- CPU usage > 70% (warning), > 90% (critical)
- Memory usage > 80% (warning), > 95% (critical)
- Gen2 GC collections increasing rapidly
*/
```

---

## Q312. How do you use BenchmarkDotNet for performance testing in .NET applications?

```csharp
/*
BenchmarkDotNet - Performance Testing and Benchmarking
*/

// Install package: dotnet add package BenchmarkDotNet

using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;
using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Diagnosers;
using BenchmarkDotNet.Exporters;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Order;

// ✅ EXCELLENT: Comprehensive benchmark setup
[MemoryDiagnoser]  // Track memory allocations
[Orderer(SummaryOrderPolicy.FastestToSlowest)]  // Order results by performance
[RankColumn]  // Show relative performance
public class StringConcatenationBenchmarks
{
    private const int Iterations = 1000;

    [Benchmark(Baseline = true)]  // Set as baseline for comparison
    public string UsingStringConcatenation()
    {
        var result = "";
        for (int i = 0; i < Iterations; i++)
        {
            result += i.ToString();
        }
        return result;
    }

    [Benchmark]
    public string UsingStringBuilder()
    {
        var sb = new StringBuilder();
        for (int i = 0; i < Iterations; i++)
        {
            sb.Append(i.ToString());
        }
        return sb.ToString();
    }

    [Benchmark]
    public string UsingStringCreate()
    {
        return string.Create(Iterations * 4, Iterations, (span, iterations) =>
        {
            for (int i = 0; i < iterations; i++)
            {
                i.ToString().AsSpan().CopyTo(span.Slice(i * 4));
            }
        });
    }

    [Benchmark]
    public string UsingStringJoin()
    {
        return string.Join("", Enumerable.Range(0, Iterations));
    }
}

// ✅ Benchmark with parameters
[MemoryDiagnoser]
public class CollectionBenchmarks
{
    [Params(100, 1000, 10000)]  // Test with different sizes
    public int Size { get; set; }

    private List<int> _data;

    [GlobalSetup]  // Run once before all benchmarks
    public void Setup()
    {
        _data = Enumerable.Range(0, Size).ToList();
    }

    [Benchmark]
    public int ForLoop()
    {
        var sum = 0;
        for (int i = 0; i < _data.Count; i++)
        {
            sum += _data[i];
        }
        return sum;
    }

    [Benchmark]
    public int ForEachLoop()
    {
        var sum = 0;
        foreach (var item in _data)
        {
            sum += item;
        }
        return sum;
    }

    [Benchmark]
    public int LinqSum()
    {
        return _data.Sum();
    }

    [Benchmark]
    public int SpanSum()
    {
        var sum = 0;
        var span = CollectionsMarshal.AsSpan(_data);
        for (int i = 0; i < span.Length; i++)
        {
            sum += span[i];
        }
        return sum;
    }
}

// ✅ Database operation benchmarks
[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net70, baseline: true)]
[SimpleJob(RuntimeMoniker.Net80)]
public class DatabaseQueryBenchmarks
{
    private ApplicationDbContext _context;

    [GlobalSetup]
    public void Setup()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer("Server=localhost;Database=BenchmarkDb;Trusted_Connection=true;")
            .Options;

        _context = new ApplicationDbContext(options);
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _context?.Dispose();
    }

    [Benchmark(Baseline = true)]
    public async Task<List<Product>> WithoutAsNoTracking()
    {
        return await _context.Products.ToListAsync();
    }

    [Benchmark]
    public async Task<List<Product>> WithAsNoTracking()
    {
        return await _context.Products.AsNoTracking().ToListAsync();
    }

    [Benchmark]
    public async Task<List<ProductDto>> WithProjection()
    {
        return await _context.Products
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            })
            .ToListAsync();
    }

    [Benchmark]
    public async Task<List<Product>> WithCompiledQuery()
    {
        return await CompiledQueries.GetProducts(_context);
    }
}

// Compiled queries for comparison
public static class CompiledQueries
{
    private static readonly Func<ApplicationDbContext, Task<List<Product>>> _getProducts =
        EF.CompileAsyncQuery((ApplicationDbContext context) =>
            context.Products.AsNoTracking());

    public static Task<List<Product>> GetProducts(ApplicationDbContext context) =>
        _getProducts(context);
}

// ✅ Advanced benchmark with custom config
[Config(typeof(CustomBenchmarkConfig))]
[MemoryDiagnoser]
public class SerializationBenchmarks
{
    private Product _product;
    private string _json;

    [GlobalSetup]
    public void Setup()
    {
        _product = new Product
        {
            Id = 1,
            Name = "Test Product",
            Price = 99.99m,
            Category = new Category { Id = 1, Name = "Electronics" }
        };

        _json = JsonSerializer.Serialize(_product);
    }

    [Benchmark(Baseline = true)]
    public string NewtonsoftSerialize()
    {
        return JsonConvert.SerializeObject(_product);
    }

    [Benchmark]
    public string SystemTextJsonSerialize()
    {
        return JsonSerializer.Serialize(_product);
    }

    [Benchmark]
    public string SystemTextJsonSerializeSourceGen()
    {
        return JsonSerializer.Serialize(_product, ProductJsonContext.Default.Product);
    }

    [Benchmark]
    public Product NewtonsoftDeserialize()
    {
        return JsonConvert.DeserializeObject<Product>(_json);
    }

    [Benchmark]
    public Product SystemTextJsonDeserialize()
    {
        return JsonSerializer.Deserialize<Product>(_json);
    }

    [Benchmark]
    public Product SystemTextJsonDeserializeSourceGen()
    {
        return JsonSerializer.Deserialize(_json, ProductJsonContext.Default.Product);
    }
}

// Source generator for JSON
[JsonSerializable(typeof(Product))]
public partial class ProductJsonContext : JsonSerializerContext
{
}

// Custom benchmark configuration
public class CustomBenchmarkConfig : ManualConfig
{
    public CustomBenchmarkConfig()
    {
        AddDiagnoser(MemoryDiagnoser.Default);
        AddDiagnoser(new EventPipeProfiler(EventPipeProfile.CpuSampling));
        AddExporter(MarkdownExporter.GitHub);
        AddExporter(HtmlExporter.Default);
        AddColumn(StatisticColumn.Mean);
        AddColumn(StatisticColumn.StdDev);
        AddColumn(StatisticColumn.Median);
        AddColumn(RankColumn.Arabic);
        AddJob(Job.Default.WithWarmupCount(3).WithIterationCount(5));
    }
}

// ✅ Async benchmarks
[MemoryDiagnoser]
public class AsyncBenchmarks
{
    private readonly HttpClient _httpClient = new();

    [Benchmark]
    public async Task<string> AsyncMethod()
    {
        return await _httpClient.GetStringAsync("https://jsonplaceholder.typicode.com/posts/1");
    }

    [Benchmark]
    public async Task<string> AsyncMethodWithConfigureAwaitFalse()
    {
        return await _httpClient.GetStringAsync("https://jsonplaceholder.typicode.com/posts/1")
            .ConfigureAwait(false);
    }

    [Benchmark]
    public string SyncMethod()
    {
        return _httpClient.GetStringAsync("https://jsonplaceholder.typicode.com/posts/1").Result;
    }
}

// ✅ Running benchmarks
public class Program
{
    public static void Main(string[] args)
    {
        // Run a single benchmark class
        BenchmarkRunner.Run<StringConcatenationBenchmarks>();

        // Run multiple benchmark classes
        BenchmarkRunner.Run(new[]
        {
            typeof(StringConcatenationBenchmarks),
            typeof(CollectionBenchmarks),
            typeof(DatabaseQueryBenchmarks)
        });

        // Run all benchmarks in assembly
        BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);

        // Run with custom config
        BenchmarkRunner.Run<SerializationBenchmarks>(new CustomBenchmarkConfig());
    }
}

/*
Example output:

| Method                     | Size  | Mean      | Error    | StdDev   | Ratio | Rank | Gen0   | Allocated |
|--------------------------- |------ |----------:|---------:|---------:|------:|-----:|-------:|----------:|
| SpanSum                    | 100   |  43.21 ns | 0.234 ns | 0.219 ns |  0.49 |    1 |      - |         - |
| ForLoop                    | 100   |  87.34 ns | 0.421 ns | 0.394 ns |  1.00 |    2 |      - |         - |
| ForEachLoop                | 100   |  91.23 ns | 0.512 ns | 0.479 ns |  1.04 |    3 |      - |         - |
| LinqSum                    | 100   | 143.45 ns | 1.234 ns | 1.154 ns |  1.64 |    4 | 0.0153 |      96 B |

Best Practices:
1. ✅ Use [MemoryDiagnoser] to track allocations
2. ✅ Set a baseline for comparison
3. ✅ Use [Params] to test different scenarios
4. ✅ Use [GlobalSetup] for initialization
5. ✅ Use [GlobalCleanup] for resource cleanup
6. ✅ Run benchmarks in Release mode
7. ✅ Close other applications during benchmarking
8. ✅ Run multiple iterations for accuracy
9. ✅ Use meaningful benchmark names
10. ✅ Export results to markdown/HTML

Common Pitfalls:
❌ Running in Debug mode
❌ Comparing different runtime versions without configuration
❌ Not accounting for JIT compilation warmup
❌ Micro-optimizations that don't matter in practice
❌ Not considering memory allocations

Interpreting Results:
- Mean: Average execution time
- Error: Standard error of the mean
- StdDev: Standard deviation
- Ratio: Relative performance to baseline
- Gen0/1/2: Garbage collection counts
- Allocated: Total memory allocated

Commands:
- dotnet run -c Release  # Run benchmarks
- dotnet run -c Release --filter *String*  # Filter by name
- dotnet run -c Release --runtimes net7.0 net8.0  # Compare runtimes
*/
```

---

## Q313. What strategies do you use for load testing ASP.NET Core applications?

```csharp
/*
Load Testing Strategies for ASP.NET Core
*/

// ✅ Using k6 for load testing (JavaScript-based)
// install: choco install k6

// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
    stages: [
        { duration: '30s', target: 20 },   // Ramp-up to 20 users
        { duration: '1m30s', target: 100 }, // Ramp-up to 100 users
        { duration: '20s', target: 100 },   // Stay at 100 users
        { duration: '10s', target: 0 },     // Ramp-down to 0 users
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
        http_req_failed: ['rate<0.01'],   // Error rate must be less than 1%
        errors: ['rate<0.1'],              // Custom error rate
    },
};

// Base URL
const BASE_URL = 'https://localhost:5001';

export default function () {
    // Test GET endpoint
    let getResponse = http.get(`${BASE_URL}/api/products`);

    check(getResponse, {
        'GET status is 200': (r) => r.status === 200,
        'GET response time < 500ms': (r) => r.timings.duration < 500,
    }) || errorRate.add(1);

    // Test POST endpoint
    const payload = JSON.stringify({
        name: 'Load Test Product',
        price: 99.99,
        categoryId: 1
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    let postResponse = http.post(`${BASE_URL}/api/products`, payload, params);

    check(postResponse, {
        'POST status is 201': (r) => r.status === 201,
        'POST response time < 1000ms': (r) => r.timings.duration < 1000,
    }) || errorRate.add(1);

    sleep(1); // Think time between iterations
}

// Run: k6 run load-test.js

// ✅ Using NBomber (C# based load testing)
// Install: dotnet add package NBomber

public class LoadTestScenarios
{
    public static void RunProductApiLoadTest()
    {
        var httpClient = new HttpClient();

        // Define scenario
        var scenario = Scenario.Create("product_api_test", async context =>
        {
            // GET Products
            var getRequest = Http.CreateRequest("GET", "https://localhost:5001/api/products");

            var getResponse = await Http.Send(httpClient, getRequest);

            return getResponse;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(10))
        .WithLoadSimulations(
            Simulation.Inject(rate: 50, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(1)),
            Simulation.KeepConstant(copies: 100, during: TimeSpan.FromMinutes(2)),
            Simulation.RampConstant(copies: 200, during: TimeSpan.FromMinutes(1))
        );

        // Run scenario
        NBomberRunner
            .RegisterScenarios(scenario)
            .WithReportFormats(ReportFormat.Html, ReportFormat.Csv)
            .WithReportFolder("load-test-results")
            .Run();
    }

    // ✅ Complex scenario with data feed
    public static void RunComplexLoadTest()
    {
        var feed = Feed.CreateCircular("products",
            new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });

        var httpClient = new HttpClient();

        var getProductScenario = Scenario.Create("get_product_by_id", async context =>
        {
            var productId = feed.GetNextItem(context.ScenarioInfo);

            var request = Http.CreateRequest("GET",
                $"https://localhost:5001/api/products/{productId}");

            var response = await Http.Send(httpClient, request);

            return response;
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 50, during: TimeSpan.FromMinutes(3))
        );

        var createProductScenario = Scenario.Create("create_product", async context =>
        {
            var product = new
            {
                name = $"Product {Guid.NewGuid()}",
                price = Random.Shared.Next(10, 1000),
                categoryId = Random.Shared.Next(1, 10)
            };

            var request = Http.CreateRequest("POST", "https://localhost:5001/api/products")
                .WithJsonBody(product);

            var response = await Http.Send(httpClient, request);

            return response;
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 20, during: TimeSpan.FromMinutes(3))
        );

        NBomberRunner
            .RegisterScenarios(getProductScenario, createProductScenario)
            .Run();
    }
}

// ✅ Application preparation for load testing
public class LoadTestConfiguration
{
    public static void ConfigureForLoadTesting(IServiceCollection services)
    {
        // Enable response compression
        services.AddResponseCompression();

        // Configure connection pooling
        services.AddDbContextPool<ApplicationDbContext>(options =>
        {
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.MaxBatchSize(100);
                sqlOptions.CommandTimeout(30);
                sqlOptions.EnableRetryOnFailure(3);
            });
        }, poolSize: 256); // Increase pool size for load testing

        // Configure rate limiting
        services.AddRateLimiter(options =>
        {
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
            {
                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 100,
                        Window = TimeSpan.FromMinutes(1)
                    });
            });
        });

        // Configure HttpClient with connection pooling
        services.AddHttpClient("external-api")
            .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
            {
                PooledConnectionLifetime = TimeSpan.FromMinutes(2),
                MaxConnectionsPerServer = 50
            });
    }
}

// ✅ Monitoring during load tests
public class LoadTestMonitoring
{
    public static void LogPerformanceMetrics(ILogger logger)
    {
        var stopwatch = Stopwatch.StartNew();
        var initialMemory = GC.GetTotalMemory(false);

        // Your operation here

        stopwatch.Stop();
        var finalMemory = GC.GetTotalMemory(false);

        logger.LogInformation(
            "Performance Metrics - Duration: {Duration}ms, Memory Delta: {MemoryDelta}KB, Gen0: {Gen0}, Gen1: {Gen1}, Gen2: {Gen2}",
            stopwatch.ElapsedMilliseconds,
            (finalMemory - initialMemory) / 1024,
            GC.CollectionCount(0),
            GC.CollectionCount(1),
            GC.CollectionCount(2));
    }
}

/*
Load Testing Best Practices:
1. ✅ Start with realistic user scenarios
2. ✅ Gradually increase load (ramp-up)
3. ✅ Test peak load and sustained load
4. ✅ Monitor server resources (CPU, memory, network)
5. ✅ Test with production-like data volumes
6. ✅ Include think time between requests
7. ✅ Test error handling under load
8. ✅ Monitor database connection pool
9. ✅ Test caching effectiveness
10. ✅ Measure and log response times

Key Metrics to Track:
- Response time (p50, p95, p99)
- Throughput (requests/second)
- Error rate
- CPU and memory usage
- Database connection pool utilization
- Thread pool starvation
- GC collections

Load Testing Tools:
- k6 (open source, JavaScript)
- NBomber (C#-based)
- Apache JMeter
- Gatling
- Azure Load Testing
- Locust (Python-based)
- Artillery

Load Testing Scenarios:
1. Baseline Test: Low load to establish baseline
2. Stress Test: Increase load until system breaks
3. Spike Test: Sudden traffic increases
4. Soak Test: Sustained load over time (memory leaks)
5. Scalability Test: How system scales with resources

Typical Load Test Pattern:
1. Ramp-up: 0 → 100 users over 1 min
2. Sustain: 100 users for 5 minutes
3. Peak: 100 → 500 users over 2 minutes
4. Sustain Peak: 500 users for 10 minutes
5. Ramp-down: 500 → 0 users over 1 minute

Commands:
- k6 run script.js  # Run k6 test
- k6 run --vus 100 --duration 30s script.js  # Quick test
- dotnet run -c Release  # Run NBomber tests
*/
```

---

## Q314. How do you optimize API response payloads and reduce data transfer?

```csharp
/*
API Response Optimization Techniques
*/

// ❌ BAD: Returning full entities
[HttpGet]
public async Task<ActionResult<List<Product>>> GetProductsBad()
{
    // Returns all columns, navigation properties, and potentially huge payloads
    var products = await _context.Products
        .Include(p => p.Category)
        .Include(p => p.Reviews)
        .ToListAsync();

    return Ok(products); // Potentially megabytes of data!
}

// ✅ GOOD: Use DTOs with projection
[HttpGet]
public async Task<ActionResult<List<ProductDto>>> GetProductsOptimized()
{
    var products = await _context.Products
        .Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            Price = p.Price,
            CategoryName = p.Category.Name
            // Only essential fields
        })
        .ToListAsync();

    return Ok(products);
}

// ✅ EXCELLENT: Pagination with page size limits
[HttpGet]
public async Task<ActionResult<PagedResult<ProductDto>>> GetProductsPaginated(
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20)
{
    // Limit maximum page size
    pageSize = Math.Min(pageSize, 100);

    var query = _context.Products.AsQueryable();

    var totalCount = await query.CountAsync();

    var products = await query
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            Price = p.Price
        })
        .ToListAsync();

    var result = new PagedResult<ProductDto>
    {
        Items = products,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize,
        TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
    };

    return Ok(result);
}

// ✅ Field selection (sparse fieldsets)
[HttpGet("{id}")]
public async Task<ActionResult<object>> GetProductWithFields(
    int id,
    [FromQuery] string fields = null)
{
    var product = await _context.Products
        .Where(p => p.Id == id)
        .Select(p => new
        {
            p.Id,
            p.Name,
            p.Description,
            p.Price,
            p.Stock,
            CategoryName = p.Category.Name
        })
        .FirstOrDefaultAsync();

    if (product == null)
        return NotFound();

    // If fields specified, return only those fields
    if (!string.IsNullOrEmpty(fields))
    {
        var selectedFields = fields.Split(',').Select(f => f.Trim()).ToList();
        var result = new Dictionary<string, object>();

        var properties = product.GetType().GetProperties();
        foreach (var prop in properties)
        {
            if (selectedFields.Contains(prop.Name, StringComparer.OrdinalIgnoreCase))
            {
                result[prop.Name] = prop.GetValue(product);
            }
        }

        return Ok(result);
    }

    return Ok(product);
}

// Usage: GET /api/products/1?fields=id,name,price

// ✅ Response compression (configured globally)
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddResponseCompression(options =>
        {
            options.EnableForHttps = true;
            options.Providers.Add<BrotliCompressionProvider>();
            options.Providers.Add<GzipCompressionProvider>();
        });
    }

    public void Configure(IApplicationBuilder app)
    {
        app.UseResponseCompression();
        app.UseRouting();
        app.UseEndpoints(endpoints => endpoints.MapControllers());
    }
}

// ✅ Cursor-based pagination for large datasets
public class CursorPaginationController : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<CursorPagedResult<ProductDto>>> GetProductsCursor(
        [FromQuery] int? cursor = null,
        [FromQuery] int limit = 20)
    {
        limit = Math.Min(limit, 100);

        var query = _context.Products.AsQueryable();

        if (cursor.HasValue)
        {
            query = query.Where(p => p.Id > cursor.Value);
        }

        var products = await query
            .OrderBy(p => p.Id)
            .Take(limit + 1) // Take one extra to determine if there's a next page
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            })
            .ToListAsync();

        var hasNextPage = products.Count > limit;
        if (hasNextPage)
        {
            products = products.Take(limit).ToList();
        }

        var nextCursor = hasNextPage ? products.Last().Id : (int?)null;

        var result = new CursorPagedResult<ProductDto>
        {
            Items = products,
            NextCursor = nextCursor,
            HasNextPage = hasNextPage
        };

        return Ok(result);
    }
}

// ✅ GraphQL-like field selection with System.Text.Json
public class DynamicProjectionController : ControllerBase
{
    [HttpPost("query")]
    public async Task<ActionResult> QueryProducts([FromBody] QueryRequest request)
    {
        var query = _context.Products.AsQueryable();

        // Apply filters
        if (request.Filters != null)
        {
            if (request.Filters.ContainsKey("categoryId"))
            {
                var categoryId = int.Parse(request.Filters["categoryId"]);
                query = query.Where(p => p.CategoryId == categoryId);
            }
        }

        // Dynamic projection based on requested fields
        var results = await query
            .Take(request.Limit ?? 100)
            .ToListAsync();

        // Project to dictionary with only requested fields
        var projected = results.Select(p => ProjectFields(p, request.Fields)).ToList();

        return Ok(projected);
    }

    private Dictionary<string, object> ProjectFields(Product product, List<string> fields)
    {
        var result = new Dictionary<string, object>();

        foreach (var field in fields)
        {
            switch (field.ToLower())
            {
                case "id":
                    result["id"] = product.Id;
                    break;
                case "name":
                    result["name"] = product.Name;
                    break;
                case "price":
                    result["price"] = product.Price;
                    break;
                // Add more fields as needed
            }
        }

        return result;
    }
}

public class QueryRequest
{
    public List<string> Fields { get; set; }
    public Dictionary<string, string> Filters { get; set; }
    public int? Limit { get; set; }
}

// ✅ Incremental updates with ETag/If-Modified-Since
[HttpGet("{id}")]
public async Task<ActionResult<ProductDto>> GetProductWithCaching(int id)
{
    var product = await _context.Products
        .Where(p => p.Id == id)
        .Select(p => new
        {
            Product = new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            },
            p.ModifiedDate
        })
        .FirstOrDefaultAsync();

    if (product == null)
        return NotFound();

    // Generate ETag based on last modified date
    var etag = $"\"{product.ModifiedDate.Ticks}\"";
    Response.Headers.ETag = etag;
    Response.Headers.LastModified = product.ModifiedDate.ToString("R");

    // Check If-None-Match header
    if (Request.Headers.IfNoneMatch == etag)
    {
        return StatusCode(StatusCodes.Status304NotModified);
    }

    // Check If-Modified-Since header
    if (Request.Headers.TryGetValue("If-Modified-Since", out var ifModifiedSince))
    {
        if (DateTime.TryParse(ifModifiedSince, out var modifiedSince))
        {
            if (product.ModifiedDate <= modifiedSince.ToUniversalTime())
            {
                return StatusCode(StatusCodes.Status304NotModified);
            }
        }
    }

    return Ok(product.Product);
}

// ✅ Delta responses (only changed fields)
[HttpGet("{id}/delta")]
public async Task<ActionResult> GetProductDelta(
    int id,
    [FromQuery] long? sinceVersion = null)
{
    var product = await _context.Products.FindAsync(id);

    if (product == null)
        return NotFound();

    if (!sinceVersion.HasValue)
    {
        // Return full product
        return Ok(product);
    }

    // Get changes since version (implement change tracking)
    var changes = await _context.ProductChanges
        .Where(c => c.ProductId == id && c.Version > sinceVersion.Value)
        .Select(c => new
        {
            c.FieldName,
            c.NewValue,
            c.Version
        })
        .ToListAsync();

    return Ok(new
    {
        ProductId = id,
        Changes = changes,
        CurrentVersion = product.Version
    });
}

/*
API Response Optimization Best Practices:
1. ✅ Use DTOs with projection (Select only needed fields)
2. ✅ Implement pagination (offset or cursor-based)
3. ✅ Enable response compression (Brotli/Gzip)
4. ✅ Support field selection/sparse fieldsets
5. ✅ Use ETags for conditional requests
6. ✅ Implement cursor pagination for large datasets
7. ✅ Limit maximum page size
8. ✅ Use streaming for large responses
9. ✅ Cache responses when appropriate
10. ✅ Consider GraphQL for complex queries

Payload Size Reduction Techniques:
- Projection: Select only needed columns (70-90% reduction)
- Pagination: Limit result size (variable reduction)
- Compression: Brotli/Gzip (60-80% reduction for text)
- Field filtering: Client specifies fields (variable)
- Caching: ETags, 304 Not Modified (100% on cache hit)

Typical Payload Sizes:
❌ Full entity with navigation: 5-50KB per item
✅ DTO with projection: 0.5-5KB per item
✅ Compressed DTO: 0.1-1KB per item

Response Time Impact:
- 1MB uncompressed: ~200ms on 50Mbps connection
- 1MB compressed (Brotli): ~40ms on 50Mbps connection
- 10KB paginated: ~2ms on 50Mbps connection

Tools for Monitoring:
- Browser DevTools Network tab
- Fiddler/Postman for payload inspection
- Application Insights for response sizes
- Custom telemetry for tracking payload sizes
*/
```

---

## Q315. What are the best practices for background job processing in ASP.NET Core?

```csharp
/*
Background Job Processing Patterns and Best Practices
*/

// ✅ GOOD: Using IHostedService for simple background tasks
public class ProductSyncBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ProductSyncBackgroundService> _logger;

    public ProductSyncBackgroundService(
        IServiceProvider serviceProvider,
        ILogger<ProductSyncBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Product Sync Background Service is starting");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await DoWorkAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while syncing products");
            }

            // Wait for 5 minutes before next execution
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }

    private async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        // Create a scope to resolve scoped services
        using var scope = _serviceProvider.CreateScope();

        var productService = scope.ServiceProvider.GetRequiredService<IProductService>();

        await productService.SyncProductsAsync(cancellationToken);

        _logger.LogInformation("Product sync completed at {Time}", DateTimeOffset.UtcNow);
    }
}

// Register in Program.cs
services.AddHostedService<ProductSyncBackgroundService>();

// ✅ EXCELLENT: Using Hangfire for complex job scheduling
// Install: dotnet add package Hangfire.AspNetCore
// Install: dotnet add package Hangfire.SqlServer

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Add Hangfire services
        services.AddHangfire(configuration => configuration
            .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
            .UseSimpleAssemblyNameTypeSerializer()
            .UseRecommendedSerializerSettings()
            .UseSqlServerStorage(Configuration.GetConnectionString("HangfireConnection"), new SqlServerStorageOptions
            {
                CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
                SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
                QueuePollInterval = TimeSpan.Zero,
                UseRecommendedIsolationLevel = true,
                DisableGlobalLocks = true
            }));

        // Add the processing server as IHostedService
        services.AddHangfireServer(options =>
        {
            options.WorkerCount = Environment.ProcessorCount * 2;
            options.Queues = new[] { "critical", "default", "low" };
        });

        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<IReportGenerator, ReportGenerator>();
    }

    public void Configure(IApplicationBuilder app)
    {
        // Hangfire Dashboard
        app.UseHangfireDashboard("/hangfire", new DashboardOptions
        {
            Authorization = new[] { new HangfireAuthorizationFilter() }
        });

        app.UseRouting();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
            endpoints.MapHangfireDashboard();
        });
    }
}

// ✅ Hangfire job examples
public class BackgroundJobsController : ControllerBase
{
    private readonly IBackgroundJobClient _backgroundJobClient;
    private readonly IRecurringJobManager _recurringJobManager;

    public BackgroundJobsController(
        IBackgroundJobClient backgroundJobClient,
        IRecurringJobManager recurringJobManager)
    {
        _backgroundJobClient = backgroundJobClient;
        _recurringJobManager = recurringJobManager;
    }

    [HttpPost("send-email")]
    public IActionResult EnqueueEmail([FromBody] EmailRequest request)
    {
        // Fire-and-forget job
        var jobId = _backgroundJobClient.Enqueue<IEmailService>(
            service => service.SendEmailAsync(request.To, request.Subject, request.Body));

        return Ok(new { JobId = jobId });
    }

    [HttpPost("generate-report")]
    public IActionResult ScheduleReport([FromBody] ReportRequest request)
    {
        // Delayed job (execute after 5 minutes)
        var jobId = _backgroundJobClient.Schedule<IReportGenerator>(
            service => service.GenerateReportAsync(request.ReportType, request.Parameters),
            TimeSpan.FromMinutes(5));

        return Ok(new { JobId = jobId });
    }

    [HttpPost("setup-daily-sync")]
    public IActionResult SetupRecurringJob()
    {
        // Recurring job (daily at 2 AM)
        _recurringJobManager.AddOrUpdate<IProductService>(
            "product-daily-sync",
            service => service.SyncProductsAsync(CancellationToken.None),
            Cron.Daily(2));

        return Ok();
    }

    [HttpPost("process-order")]
    public IActionResult ProcessOrder([FromBody] Order order)
    {
        // Continuation job (execute after parent job completes)
        var parentJobId = _backgroundJobClient.Enqueue<IOrderService>(
            service => service.ValidateOrderAsync(order.Id));

        _backgroundJobClient.ContinueJobWith<IOrderService>(
            parentJobId,
            service => service.ProcessPaymentAsync(order.Id));

        return Ok(new { JobId = parentJobId });
    }
}

// ✅ Job priority with queues
public class QueuedJobsExample
{
    public void EnqueueCriticalJob(IBackgroundJobClient jobClient)
    {
        // High priority queue
        jobClient.Enqueue<ICriticalService>(
            x => x.ProcessCriticalData(),
            new BackgroundJobOptions { Queue = "critical" });
    }

    public void EnqueueLowPriorityJob(IBackgroundJobClient jobClient)
    {
        // Low priority queue
        jobClient.Enqueue<IReportService>(
            x => x.GenerateLargeReport(),
            new BackgroundJobOptions { Queue = "low" });
    }
}

// ✅ Job retry and error handling
public class ResilientBackgroundJob
{
    [AutomaticRetry(Attempts = 3, OnAttemptsExceeded = AttemptsExceededAction.Delete)]
    public async Task ProcessDataWithRetry()
    {
        // Job logic that will be retried up to 3 times on failure
        await ProcessExternalApiAsync();
    }

    [AutomaticRetry(Attempts = 5, DelaysInSeconds = new[] { 60, 300, 900 })]
    public async Task ProcessWithCustomRetryDelays()
    {
        // Custom retry delays: 1 min, 5 min, 15 min
        await ProcessDataAsync();
    }

    private async Task ProcessExternalApiAsync()
    {
        // Implementation
        await Task.CompletedTask;
    }

    private async Task ProcessDataAsync()
    {
        // Implementation
        await Task.CompletedTask;
    }
}

// ✅ Advanced: Using Channels for producer-consumer pattern
public class ChannelBackgroundProcessor : BackgroundService
{
    private readonly Channel<WorkItem> _channel;
    private readonly ILogger<ChannelBackgroundProcessor> _logger;
    private readonly IServiceProvider _serviceProvider;

    public ChannelBackgroundProcessor(
        ILogger<ChannelBackgroundProcessor> logger,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;

        // Create bounded channel with capacity limit
        _channel = Channel.CreateBounded<WorkItem>(new BoundedChannelOptions(100)
        {
            FullMode = BoundedChannelFullMode.Wait
        });
    }

    public async Task QueueWorkItemAsync(WorkItem item, CancellationToken cancellationToken = default)
    {
        await _channel.Writer.WriteAsync(item, cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var workItem in _channel.Reader.ReadAllAsync(stoppingToken))
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                await ProcessWorkItemAsync(workItem, scope.ServiceProvider, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing work item {ItemId}", workItem.Id);
            }
        }
    }

    private async Task ProcessWorkItemAsync(
        WorkItem item,
        IServiceProvider serviceProvider,
        CancellationToken cancellationToken)
    {
        var processor = serviceProvider.GetRequiredService<IWorkItemProcessor>();
        await processor.ProcessAsync(item, cancellationToken);

        _logger.LogInformation("Processed work item {ItemId}", item.Id);
    }
}

public class WorkItem
{
    public Guid Id { get; set; }
    public string Type { get; set; }
    public string Data { get; set; }
}

// ✅ Parallel processing with SemaphoreSlim
public class ParallelBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ParallelBackgroundService> _logger;
    private readonly SemaphoreSlim _semaphore;

    public ParallelBackgroundService(
        IServiceProvider serviceProvider,
        ILogger<ParallelBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _semaphore = new SemaphoreSlim(Environment.ProcessorCount); // Limit concurrency
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using var scope = _serviceProvider.CreateScope();
            var repository = scope.ServiceProvider.GetRequiredService<IProductRepository>();

            var pendingProducts = await repository.GetPendingProductsAsync();

            // Process products in parallel with concurrency limit
            var tasks = pendingProducts.Select(async product =>
            {
                await _semaphore.WaitAsync(stoppingToken);
                try
                {
                    await ProcessProductAsync(product, stoppingToken);
                }
                finally
                {
                    _semaphore.Release();
                }
            });

            await Task.WhenAll(tasks);

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    private async Task ProcessProductAsync(Product product, CancellationToken cancellationToken)
    {
        // Process product
        _logger.LogInformation("Processing product {ProductId}", product.Id);
        await Task.Delay(100, cancellationToken); // Simulate work
    }
}

/*
Background Job Processing Best Practices:
1. ✅ Use IHostedService for simple recurring tasks
2. ✅ Use Hangfire/Quartz for complex scheduling
3. ✅ Always create a scope for scoped services
4. ✅ Implement proper cancellation token support
5. ✅ Add retry logic with exponential backoff
6. ✅ Use queues for job prioritization
7. ✅ Monitor job execution and failures
8. ✅ Limit concurrency to avoid overwhelming resources
9. ✅ Use channels for producer-consumer patterns
10. ✅ Log job start, completion, and errors

Job Scheduling Libraries:
- Hangfire: Full-featured, dashboard, persistent storage
- Quartz.NET: Enterprise scheduler, complex triggers
- NCronTab: Simple cron-based scheduling
- System.Threading.Channels: In-process queuing
- Azure Functions/AWS Lambda: Serverless options

Hangfire vs IHostedService:
Hangfire:
  ✅ Persistent storage
  ✅ Dashboard UI
  ✅ Job continuations
  ✅ Distributed processing
  ❌ Additional dependency
  ❌ Requires database

IHostedService:
  ✅ Built-in, no dependencies
  ✅ Simple to implement
  ✅ Good for periodic tasks
  ❌ No persistence
  ❌ No built-in retry logic
  ❌ Single instance per app

Common Pitfalls:
❌ Not creating scope for scoped services
❌ Blocking the main thread
❌ No cancellation token support
❌ No error handling/retry logic
❌ Not limiting concurrency
❌ Memory leaks in long-running services
*/
```

---

## Q316. How do you implement efficient resource pooling in ASP.NET Core?

```csharp
/*
Resource Pooling Patterns for Performance Optimization
*/

// ✅ EXCELLENT: Object pooling with ObjectPool
using Microsoft.Extensions.ObjectPool;

// Register object pool
services.AddSingleton<ObjectPoolProvider, DefaultObjectPoolProvider>();
services.AddSingleton(serviceProvider =>
{
    var provider = serviceProvider.GetRequiredService<ObjectPoolProvider>();
    return provider.Create(new StringBuilderPooledObjectPolicy());
});

// Policy for StringBuilder pooling
public class StringBuilderPooledObjectPolicy : PooledObjectPolicy<StringBuilder>
{
    private const int MaximumBuilderSize = 1024;
    private const int InitialBuilderSize = 256;

    public override StringBuilder Create()
    {
        return new StringBuilder(InitialBuilderSize);
    }

    public override bool Return(StringBuilder obj)
    {
        if (obj.Capacity > MaximumBuilderSize)
        {
            // Don't return to pool if too large
            return false;
        }

        obj.Clear();
        return true;
    }
}

// Usage in service
public class ReportGenerator
{
    private readonly ObjectPool<StringBuilder> _stringBuilderPool;

    public ReportGenerator(ObjectPool<StringBuilder> stringBuilderPool)
    {
        _stringBuilderPool = stringBuilderPool;
    }

    public string GenerateReport(List<string> data)
    {
        var builder = _stringBuilderPool.Get();

        try
        {
            builder.AppendLine("Report Header");

            foreach (var item in data)
            {
                builder.AppendLine(item);
            }

            return builder.ToString();
        }
        finally
        {
            _stringBuilderPool.Return(builder);
        }
    }
}

// ✅ ArrayPool for temporary buffers
public class ImageProcessor
{
    public async Task<byte[]> ProcessImageAsync(Stream imageStream)
    {
        // Rent buffer from pool
        var buffer = ArrayPool<byte>.Shared.Rent(4096);

        try
        {
            int bytesRead;
            using var outputStream = new MemoryStream();

            while ((bytesRead = await imageStream.ReadAsync(buffer, 0, buffer.Length)) > 0)
            {
                // Process buffer
                ProcessBuffer(buffer, bytesRead);
                await outputStream.WriteAsync(buffer, 0, bytesRead);
            }

            return outputStream.ToArray();
        }
        finally
        {
            // Return buffer to pool
            ArrayPool<byte>.Shared.Return(buffer, clearArray: true);
        }
    }

    private void ProcessBuffer(byte[] buffer, int length)
    {
        // Process buffer logic
    }
}

// ✅ HttpClient pooling with IHttpClientFactory
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Named client
        services.AddHttpClient("github", client =>
        {
            client.BaseAddress = new Uri("https://api.github.com/");
            client.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");
            client.DefaultRequestHeaders.Add("User-Agent", "MyApp");
        })
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(2),
            PooledConnectionIdleTimeout = TimeSpan.FromMinutes(1),
            MaxConnectionsPerServer = 20
        });

        // Typed client
        services.AddHttpClient<GitHubService>()
            .SetHandlerLifetime(TimeSpan.FromMinutes(5));
    }
}

// ✅ DbContext pooling
services.AddDbContextPool<ApplicationDbContext>(options =>
{
    options.UseSqlServer(connectionString);
}, poolSize: 128);

// ✅ Custom object pool for complex objects
public class ExpensiveObjectPool : IDisposable
{
    private readonly ConcurrentBag<ExpensiveObject> _objects = new();
    private readonly SemaphoreSlim _semaphore;
    private readonly int _maxSize;

    public ExpensiveObjectPool(int maxSize = 10)
    {
        _maxSize = maxSize;
        _semaphore = new SemaphoreSlim(maxSize, maxSize);
    }

    public async Task<PooledObject<ExpensiveObject>> GetObjectAsync(CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);

        if (_objects.TryTake(out var obj))
        {
            return new PooledObject<ExpensiveObject>(obj, this);
        }

        // Create new object if pool is empty
        var newObj = new ExpensiveObject();
        await newObj.InitializeAsync();

        return new PooledObject<ExpensiveObject>(newObj, this);
    }

    public void ReturnObject(ExpensiveObject obj)
    {
        if (_objects.Count < _maxSize)
        {
            obj.Reset();
            _objects.Add(obj);
        }
        else
        {
            obj.Dispose();
        }

        _semaphore.Release();
    }

    public void Dispose()
    {
        while (_objects.TryTake(out var obj))
        {
            obj.Dispose();
        }
        _semaphore?.Dispose();
    }
}

public class PooledObject<T> : IDisposable where T : class
{
    private readonly ExpensiveObjectPool _pool;
    private T _object;
    private bool _disposed;

    public PooledObject(T obj, ExpensiveObjectPool pool)
    {
        _object = obj;
        _pool = pool;
    }

    public T Object => _object ?? throw new ObjectDisposedException(nameof(PooledObject<T>));

    public void Dispose()
    {
        if (_disposed) return;

        if (_object != null)
        {
            _pool.ReturnObject(_object as ExpensiveObject);
            _object = null;
        }

        _disposed = true;
    }
}

public class ExpensiveObject : IDisposable
{
    public async Task InitializeAsync()
    {
        // Expensive initialization
        await Task.Delay(100);
    }

    public void Reset()
    {
        // Reset state for reuse
    }

    public void Dispose()
    {
        // Cleanup resources
    }
}

// Usage
public class ExpensiveObjectConsumer
{
    private readonly ExpensiveObjectPool _pool;

    public ExpensiveObjectConsumer(ExpensiveObjectPool pool)
    {
        _pool = pool;
    }

    public async Task DoWorkAsync()
    {
        using var pooledObject = await _pool.GetObjectAsync();

        // Use the object
        var obj = pooledObject.Object;
        // ... work with obj ...

        // Automatically returned to pool when disposed
    }
}

// ✅ MemoryPool for advanced scenarios
public class AdvancedMemoryPooling
{
    public async Task ProcessLargeDataAsync(Stream dataStream)
    {
        using var memoryOwner = MemoryPool<byte>.Shared.Rent(4096);
        var memory = memoryOwner.Memory;

        int bytesRead = await dataStream.ReadAsync(memory);

        // Process memory
        ProcessData(memory.Slice(0, bytesRead));

        // Memory automatically returned to pool when memoryOwner is disposed
    }

    private void ProcessData(Memory<byte> data)
    {
        // Process data
    }
}

// ✅ RecyclableMemoryStream for large memory buffers
// Install: Microsoft.IO.RecyclableMemoryStream

public class RecyclableMemoryService
{
    private static readonly RecyclableMemoryStreamManager _manager = new RecyclableMemoryStreamManager(
        blockSize: 128 * 1024,        // 128 KB blocks
        largeBufferMultiple: 1024 * 1024,  // 1 MB large buffers
        maximumBufferSize: 16 * 1024 * 1024 // 16 MB max
    );

    public async Task<byte[]> CreateLargeBufferAsync()
    {
        using var stream = _manager.GetStream("operation-tag");

        // Use stream
        await WriteDataAsync(stream);

        return stream.ToArray();
    }

    private async Task WriteDataAsync(MemoryStream stream)
    {
        // Write data to stream
        await Task.CompletedTask;
    }
}

/*
Resource Pooling Best Practices:
1. ✅ Use ObjectPool for frequently created objects
2. ✅ Use ArrayPool for temporary byte buffers
3. ✅ Use IHttpClientFactory for HTTP clients
4. ✅ Use DbContextPool for Entity Framework
5. ✅ Use RecyclableMemoryStream for large buffers
6. ✅ Set appropriate pool sizes
7. ✅ Clear/reset objects before returning to pool
8. ✅ Handle thread safety in custom pools
9. ✅ Monitor pool utilization
10. ✅ Dispose pooled resources properly

Performance Benefits:
- Reduced GC pressure
- Faster object creation
- Lower memory allocation
- Better memory locality
- Reduced LOH allocations

Objects Good for Pooling:
✅ StringBuilder
✅ Byte arrays/buffers
✅ HttpClient instances
✅ DbContext instances
✅ Large objects (> 85KB)
✅ Frequently created objects

Objects NOT to Pool:
❌ Small, short-lived objects
❌ Objects with complex state
❌ Thread-specific objects
❌ Objects with unmanaged resources

Pool Sizing Guidelines:
- Start with: CPU cores * 2
- Monitor: Pool hit rate, allocation rate
- Adjust: Based on workload patterns
- Max size: Balance memory vs creation cost

Common Pitfalls:
❌ Pooling objects that are cheaper to create than pool
❌ Not clearing state before returning to pool
❌ Pool size too small (frequent allocation)
❌ Pool size too large (wasted memory)
❌ Not handling thread safety
*/
```

---

## Q317. How do you optimize middleware pipeline performance in ASP.NET Core?

```csharp
/*
Middleware Pipeline Optimization Strategies
*/

// ❌ BAD: Inefficient middleware order
public class BadMiddlewareConfiguration
{
    public void Configure(IApplicationBuilder app)
    {
        app.UseRouting(); // Should be earlier
        app.UseStaticFiles(); // Should be before routing for static files
        app.UseResponseCaching(); // Should be very early
        app.UseAuthorization();
        app.UseAuthentication(); // Wrong order! Auth must be before Authorization
        app.UseEndpoints(endpoints => endpoints.MapControllers());
    }
}

// ✅ GOOD: Optimized middleware order
public class OptimizedMiddlewareConfiguration
{
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        // 1. Response compression (very early)
        app.UseResponseCompression();

        // 2. Response caching (early, before most middleware)
        app.UseResponseCaching();

        // 3. Exception handling (catch all errors)
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }
        else
        {
            app.UseExceptionHandler("/error");
            app.UseHsts();
        }

        // 4. HTTPS redirection
        app.UseHttpsRedirection();

        // 5. Static files (short-circuit for static content)
        app.UseStaticFiles();

        // 6. Routing (determines endpoint)
        app.UseRouting();

        // 7. CORS (before auth)
        app.UseCors();

        // 8. Authentication (before authorization!)
        app.UseAuthentication();

        // 9. Authorization
        app.UseAuthorization();

        // 10. Custom middleware
        app.UseMiddleware<RequestTimingMiddleware>();

        // 11. Endpoints (last)
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
            endpoints.MapHealthChecks("/health");
        });
    }
}

// ✅ Conditional middleware registration
public class ConditionalMiddleware
{
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IConfiguration config)
    {
        // Only add in development
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
            app.UseMiniProfiler();
        }

        // Feature flag based middleware
        if (config.GetValue<bool>("Features:EnableRateLimiting"))
        {
            app.UseRateLimiter();
        }

        // Conditional middleware based on environment
        app.UseWhen(
            context => !context.Request.Path.StartsWithSegments("/health"),
            appBuilder => appBuilder.UseMiddleware<RequestLoggingMiddleware>()
        );
    }
}

// ✅ EXCELLENT: Short-circuiting middleware
public class FastPathMiddleware
{
    private readonly RequestDelegate _next;

    public FastPathMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Short-circuit for static files
        if (context.Request.Path.StartsWithSegments("/static"))
        {
            // Handle directly, don't invoke next middleware
            await HandleStaticFileAsync(context);
            return; // Short-circuit!
        }

        // Short-circuit for health checks
        if (context.Request.Path == "/ping")
        {
            context.Response.StatusCode = 200;
            await context.Response.WriteAsync("pong");
            return; // Short-circuit!
        }

        await _next(context);
    }

    private async Task HandleStaticFileAsync(HttpContext context)
    {
        // Handle static file
        await Task.CompletedTask;
    }
}

// ✅ Efficient custom middleware
public class OptimizedRequestMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<OptimizedRequestMiddleware> _logger;

    // Cache frequently accessed services in constructor
    public OptimizedRequestMiddleware(
        RequestDelegate next,
        ILogger<OptimizedRequestMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(
        HttpContext context,
        IMemoryCache cache) // Inject per-request services here
    {
        // Fast path check
        if (!ShouldProcess(context))
        {
            await _next(context);
            return;
        }

        // Avoid allocations
        var path = context.Request.Path.Value;
        var method = context.Request.Method;

        // Use ValueTask for potentially synchronous operations
        await ProcessRequestAsync(context, cache);

        await _next(context);
    }

    private bool ShouldProcess(HttpContext context)
    {
        // Quick checks to skip processing
        return !context.Request.Path.StartsWithSegments("/health");
    }

    private async ValueTask ProcessRequestAsync(HttpContext context, IMemoryCache cache)
    {
        // Implementation
        await Task.CompletedTask;
    }
}

// ✅ Middleware with request/response buffering
public class BufferingMiddleware
{
    private readonly RequestDelegate _next;

    public BufferingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Enable request buffering for multiple reads
        context.Request.EnableBuffering();

        // Replace response stream to buffer output
        var originalBody = context.Response.Body;

        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;

        try
        {
            await _next(context);

            // Process buffered response
            context.Response.Body.Seek(0, SeekOrigin.Begin);
            await context.Response.Body.CopyToAsync(originalBody);
        }
        finally
        {
            context.Response.Body = originalBody;
        }
    }
}

// ✅ Minimal endpoint filters (ASP.NET Core 7+)
public class MinimalApiOptimization
{
    public void ConfigureEndpoints(WebApplication app)
    {
        var productGroup = app.MapGroup("/api/products")
            .WithOpenApi()
            .AddEndpointFilter<ValidationFilter>();

        // Minimal API with filters
        productGroup.MapGet("/", async (ProductService service) =>
        {
            var products = await service.GetProductsAsync();
            return Results.Ok(products);
        })
        .CacheOutput(policy => policy.Expire(TimeSpan.FromMinutes(5)));

        productGroup.MapPost("/", async (Product product, ProductService service) =>
        {
            await service.AddProductAsync(product);
            return Results.Created($"/api/products/{product.Id}", product);
        })
        .AddEndpointFilter<ValidationFilter>();
    }
}

// ✅ Endpoint filter for validation
public class ValidationFilter : IEndpointFilter
{
    public async ValueTask<object> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        // Fast validation before hitting controller
        foreach (var argument in context.Arguments)
        {
            if (argument is IValidatable validatable)
            {
                if (!validatable.IsValid())
                {
                    return Results.BadRequest("Validation failed");
                }
            }
        }

        return await next(context);
    }
}

// ✅ Terminal middleware (doesn't call next)
public class TerminalMiddleware
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path == "/api/status")
        {
            await context.Response.WriteAsJsonAsync(new
            {
                Status = "OK",
                Timestamp = DateTime.UtcNow
            });
            // No call to _next - this is terminal
        }
    }
}

// Register as terminal middleware
app.Map("/api/status", appBuilder =>
{
    appBuilder.Run(new TerminalMiddleware().InvokeAsync);
});

/*
Middleware Pipeline Best Practices:
1. ✅ Order middleware by frequency (most common first)
2. ✅ Short-circuit when possible (return early)
3. ✅ Use Map/MapWhen for conditional middleware
4. ✅ Cache services in constructor
5. ✅ Use ValueTask for sync/async operations
6. ✅ Avoid allocations in hot paths
7. ✅ Use endpoint filters for minimal APIs
8. ✅ Register only necessary middleware
9. ✅ Use terminal middleware when appropriate
10. ✅ Profile and measure middleware performance

Optimal Middleware Order:
1. Response compression (early)
2. Response caching (early)
3. Exception handling
4. HTTPS redirection
5. Static files (short-circuit)
6. Routing
7. CORS
8. Authentication
9. Authorization
10. Custom middleware
11. Endpoints (last)

Performance Tips:
- Static files middleware short-circuits (no further processing)
- Health checks can be terminal endpoints
- Response caching saves entire pipeline execution
- Authentication/Authorization only when needed
- Use MapWhen to avoid running middleware for all requests

Middleware Performance Metrics:
- Response compression: ~60-80% size reduction
- Response caching: 100% pipeline skip on cache hit
- Static files: 50-100ms saved vs. MVC pipeline
- Short-circuiting: Saves all downstream middleware

Common Mistakes:
❌ Authorization before Authentication
❌ Static files after routing
❌ Response caching too late
❌ Not short-circuiting for simple requests
❌ Too many middleware in pipeline
❌ Allocating objects in InvokeAsync
*/
```

---

## Q318. What are CDN and static asset optimization strategies for ASP.NET Core?

```csharp
/*
CDN and Static Asset Optimization
*/

// ✅ EXCELLENT: CDN configuration with fallback
public class CdnConfiguration
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<CdnOptions>(configuration.GetSection("Cdn"));
    }
}

public class CdnOptions
{
    public string BaseUrl { get; set; }
    public bool Enabled { get; set; }
    public Dictionary<string, string> AssetVersions { get; set; }
}

// Tag helper for CDN assets with fallback
public class CdnScriptTagHelper : TagHelper
{
    private readonly CdnOptions _cdnOptions;

    public CdnScriptTagHelper(IOptions<CdnOptions> cdnOptions)
    {
        _cdnOptions = cdnOptions.Value;
    }

    public string Src { get; set; }
    public string FallbackSrc { get; set; }
    public string FallbackTest { get; set; }

    public override void Process(TagHelperContext context, TagHelperOutput output)
    {
        output.TagName = "script";

        if (_cdnOptions.Enabled && !string.IsNullOrEmpty(Src))
        {
            var cdnUrl = $"{_cdnOptions.BaseUrl}/{Src}";
            output.Attributes.SetAttribute("src", cdnUrl);

            // Add integrity check if available
            if (_cdnOptions.AssetVersions.TryGetValue(Src, out var integrity))
            {
                output.Attributes.SetAttribute("integrity", integrity);
                output.Attributes.SetAttribute("crossorigin", "anonymous");
            }

            // Add fallback for CDN failure
            if (!string.IsNullOrEmpty(FallbackSrc) && !string.IsNullOrEmpty(FallbackTest))
            {
                output.PostElement.AppendHtml($@"
                    <script>
                        {FallbackTest} || document.write('<script src=""{FallbackSrc}""><\/script>');
                    </script>
                ");
            }
        }
        else
        {
            output.Attributes.SetAttribute("src", FallbackSrc ?? Src);
        }
    }
}

// Usage in view:
// <cdn-script src="js/app.min.js"
//             fallback-src="/js/app.min.js"
//             fallback-test="window.MyApp"></cdn-script>

// ✅ Asset versioning and cache busting
public class AssetVersioningTagHelper : TagHelper
{
    private readonly IWebHostEnvironment _env;
    private readonly IMemoryCache _cache;

    public AssetVersioningTagHelper(
        IWebHostEnvironment env,
        IMemoryCache cache)
    {
        _env = env;
        _cache = cache;
    }

    public string Href { get; set; }
    public string Src { get; set; }

    public override void Process(TagHelperContext context, TagHelperOutput output)
    {
        var path = Href ?? Src;

        if (string.IsNullOrEmpty(path))
            return;

        var versionedPath = GetVersionedPath(path);

        if (!string.IsNullOrEmpty(Href))
        {
            output.Attributes.SetAttribute("href", versionedPath);
        }

        if (!string.IsNullOrEmpty(Src))
        {
            output.Attributes.SetAttribute("src", versionedPath);
        }
    }

    private string GetVersionedPath(string path)
    {
        var cacheKey = $"asset_version_{path}";

        return _cache.GetOrCreate(cacheKey, entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromHours(24);

            var fullPath = Path.Combine(_env.WebRootPath, path.TrimStart('/'));

            if (File.Exists(fullPath))
            {
                var fileInfo = new FileInfo(fullPath);
                var version = fileInfo.LastWriteTimeUtc.Ticks.ToString("x");
                return $"{path}?v={version}";
            }

            return path;
        });
    }
}

// ✅ Static file optimization
public class StaticFileOptimization
{
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        // Serve pre-compressed files
        app.UseStaticFiles(new StaticFileOptions
        {
            OnPrepareResponse = ctx =>
            {
                // Check if pre-compressed file exists
                var compressedPath = $"{ctx.File.PhysicalPath}.br";

                if (File.Exists(compressedPath) &&
                    ctx.Context.Request.Headers.AcceptEncoding.Any(e => e.Contains("br")))
                {
                    ctx.Context.Response.Headers.ContentEncoding = "br";
                    // Serve pre-compressed file
                }

                // Aggressive caching for versioned assets
                var path = ctx.Context.Request.Path.Value;

                if (path.Contains("?v=") || path.Contains(".min."))
                {
                    // Immutable caching for versioned assets
                    ctx.Context.Response.Headers[HeaderNames.CacheControl] =
                        "public,max-age=31536000,immutable";
                }
                else
                {
                    // Short cache for non-versioned assets
                    ctx.Context.Response.Headers[HeaderNames.CacheControl] =
                        "public,max-age=3600";
                }

                // Add ETag
                ctx.Context.Response.Headers[HeaderNames.ETag] =
                    $"\"{ctx.File.LastModified.ToFileTime():x}\"";
            }
        });

        // Serve WebP images with fallback
        app.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(env.WebRootPath, "images")),
            RequestPath = "/images",
            ContentTypeProvider = new FileExtensionContentTypeProvider
            {
                Mappings =
                {
                    [".webp"] = "image/webp",
                    [".avif"] = "image/avif"
                }
            }
        });
    }
}

// ✅ Build-time asset optimization
// Install: dotnet add package WebOptimizer.Core

public class AssetBundling
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddWebOptimizer(pipeline =>
        {
            // CSS bundling and minification
            pipeline.AddCssBundle("/css/bundle.css",
                "css/bootstrap.css",
                "css/site.css",
                "css/components.css"
            )
            .MinifyCss();

            // JavaScript bundling and minification
            pipeline.AddJavaScriptBundle("/js/bundle.js",
                "js/jquery.js",
                "js/bootstrap.js",
                "js/site.js"
            )
            .MinifyJavaScript();

            // SCSS compilation
            pipeline.CompileScssFiles();

            // Image optimization
            pipeline.AddFiles("image/jpeg", "/images/**/*.jpg")
                .CompressImages();

            pipeline.AddFiles("image/png", "/images/**/*.png")
                .CompressImages(quality: 85);
        });
    }
}

// ✅ Responsive images
public class ResponsiveImageTagHelper : TagHelper
{
    public string Src { get; set; }
    public int[] Sizes { get; set; } = new[] { 320, 640, 960, 1280, 1920 };

    public override void Process(TagHelperContext context, TagHelperOutput output)
    {
        output.TagName = "img";

        var srcset = new List<string>();
        var basePath = Path.GetDirectoryName(Src);
        var fileName = Path.GetFileNameWithoutExtension(Src);
        var extension = Path.GetExtension(Src);

        foreach (var size in Sizes)
        {
            var resizedPath = $"{basePath}/{fileName}-{size}w{extension}";
            srcset.Add($"{resizedPath} {size}w");
        }

        output.Attributes.SetAttribute("src", Src);
        output.Attributes.SetAttribute("srcset", string.Join(", ", srcset));
        output.Attributes.SetAttribute("sizes", "(max-width: 640px) 100vw, 50vw");
        output.Attributes.SetAttribute("loading", "lazy");
    }
}

// ✅ HTTP/2 Server Push
public class Http2ServerPushMiddleware
{
    private readonly RequestDelegate _next;

    public Http2ServerPushMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Only push on initial page load
        if (context.Request.Path == "/" && context.Request.Query["pushed"] != "1")
        {
            // Push critical resources
            context.Response.Headers.Append("Link",
                "</css/bundle.css>; rel=preload; as=style");
            context.Response.Headers.Append("Link",
                "</js/bundle.js>; rel=preload; as=script");
        }

        await _next(context);
    }
}

// ✅ Azure CDN integration
public class AzureCdnConfiguration
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IAzureCdnService>(sp => new AzureCdnService(
            configuration["Azure:Cdn:ProfileName"],
            configuration["Azure:Cdn:EndpointName"],
            configuration["Azure:Cdn:ResourceGroup"]
        ));
    }
}

public interface IAzureCdnService
{
    Task PurgeContentAsync(params string[] paths);
    Task PreloadContentAsync(params string[] paths);
}

public class AzureCdnService : IAzureCdnService
{
    private readonly string _profileName;
    private readonly string _endpointName;
    private readonly string _resourceGroup;

    public AzureCdnService(string profileName, string endpointName, string resourceGroup)
    {
        _profileName = profileName;
        _endpointName = endpointName;
        _resourceGroup = resourceGroup;
    }

    public async Task PurgeContentAsync(params string[] paths)
    {
        // Use Azure SDK to purge CDN cache
        // var credential = new DefaultAzureCredential();
        // var cdnClient = new CdnManagementClient(credential);
        // await cdnClient.Endpoints.PurgeContentAsync(_resourceGroup, _profileName, _endpointName, paths);

        await Task.CompletedTask;
    }

    public async Task PreloadContentAsync(params string[] paths)
    {
        // Preload content to CDN edge nodes
        await Task.CompletedTask;
    }
}

/*
CDN and Static Asset Optimization Best Practices:
1. ✅ Use CDN for static assets (CSS, JS, images)
2. ✅ Implement CDN fallback for reliability
3. ✅ Version assets for cache busting
4. ✅ Use Subresource Integrity (SRI) for security
5. ✅ Pre-compress static files (Brotli/Gzip)
6. ✅ Serve responsive images with srcset
7. ✅ Use modern image formats (WebP, AVIF)
8. ✅ Implement HTTP/2 server push
9. ✅ Bundle and minify CSS/JavaScript
10. ✅ Use aggressive caching for versioned assets

Performance Improvements:
- CDN edge caching: 80-95% latency reduction
- Brotli compression: 15-25% smaller than Gzip
- Image optimization: 40-70% size reduction
- WebP format: 25-35% smaller than JPEG
- Bundling: Reduce HTTP requests by 80-90%
- Cache headers: 100% bandwidth savings on cache hit

Cache Control Strategy:
Versioned assets:
  Cache-Control: public,max-age=31536000,immutable

Non-versioned assets:
  Cache-Control: public,max-age=3600,must-revalidate

Dynamic content:
  Cache-Control: private,no-cache

CDN Providers:
- Azure CDN
- Cloudflare
- Amazon CloudFront
- Fastly
- Akamai

Tools:
- WebOptimizer for bundling/minification
- ImageSharp for image processing
- Azure CDN for global distribution
- Cloudflare for DDoS protection + CDN
*/
```

---

## Q319. How do you profile and tune ASP.NET Core application performance?

```csharp
/*
Profiling and Performance Tuning Techniques
*/

// ✅ Built-in diagnostic tools configuration
public class DiagnosticConfiguration
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Add diagnostic services
        services.AddDiagnosticObserver();

        // Add event counters
        services.AddSingleton<DiagnosticListener>(sp =>
            new DiagnosticListener("MyApp"));

        // Add metrics
        services.AddSingleton<IMeterFactory, MeterFactory>();
    }

    public void Configure(IApplicationBuilder app)
    {
        // Enable diagnostic middleware
        app.Use(async (context, next) =>
        {
            var activity = Activity.Current;

            activity?.AddTag("http.url", context.Request.Path);
            activity?.AddTag("http.method", context.Request.Method);

            await next();

            activity?.AddTag("http.status_code", context.Response.StatusCode);
        });
    }
}

// ✅ Custom diagnostic events
public class CustomDiagnostics
{
    private static readonly DiagnosticListener _diagnosticListener =
        new DiagnosticListener("MyApp");

    public async Task<Product> GetProductWithDiagnostics(int id)
    {
        if (_diagnosticListener.IsEnabled("GetProduct"))
        {
            var stopwatch = Stopwatch.StartNew();

            try
            {
                var product = await GetProductAsync(id);
                stopwatch.Stop();

                _diagnosticListener.Write("GetProduct", new
                {
                    ProductId = id,
                    Duration = stopwatch.ElapsedMilliseconds,
                    Success = true
                });

                return product;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();

                _diagnosticListener.Write("GetProduct", new
                {
                    ProductId = id,
                    Duration = stopwatch.ElapsedMilliseconds,
                    Success = false,
                    Error = ex.Message
                });

                throw;
            }
        }

        return await GetProductAsync(id);
    }

    private async Task<Product> GetProductAsync(int id)
    {
        // Implementation
        await Task.Delay(10);
        return new Product { Id = id };
    }
}

// ✅ Memory profiling
public class MemoryProfiler
{
    public static void LogMemoryUsage(ILogger logger)
    {
        var process = Process.GetCurrentProcess();

        var memoryInfo = new
        {
            WorkingSet = process.WorkingSet64 / (1024 * 1024), // MB
            PrivateMemory = process.PrivateMemorySize64 / (1024 * 1024),
            VirtualMemory = process.VirtualMemorySize64 / (1024 * 1024),
            GcMemory = GC.GetTotalMemory(false) / (1024 * 1024),
            Gen0Collections = GC.CollectionCount(0),
            Gen1Collections = GC.CollectionCount(1),
            Gen2Collections = GC.CollectionCount(2),
            GcTotalMemory = GC.GetGCMemoryInfo().TotalAvailableMemoryBytes / (1024 * 1024),
            HeapSize = GC.GetGCMemoryInfo().HeapSizeBytes / (1024 * 1024)
        };

        logger.LogInformation(
            "Memory Usage - Working: {WorkingSet}MB, Private: {PrivateMemory}MB, " +
            "GC: {GcMemory}MB, Gen0: {Gen0}, Gen1: {Gen1}, Gen2: {Gen2}",
            memoryInfo.WorkingSet,
            memoryInfo.PrivateMemory,
            memoryInfo.GcMemory,
            memoryInfo.Gen0Collections,
            memoryInfo.Gen1Collections,
            memoryInfo.Gen2Collections);
    }
}

// ✅ Performance counters
public class PerformanceCounterService : BackgroundService
{
    private readonly ILogger<PerformanceCounterService> _logger;
    private readonly PerformanceCounter _cpuCounter;
    private readonly PerformanceCounter _ramCounter;

    public PerformanceCounterService(ILogger<PerformanceCounterService> logger)
    {
        _logger = logger;

        // Create performance counters
        _cpuCounter = new PerformanceCounter(
            "Processor", "% Processor Time", "_Total");
        _ramCounter = new PerformanceCounter(
            "Memory", "Available MBytes");
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var cpuUsage = _cpuCounter.NextValue();
            var availableRam = _ramCounter.NextValue();

            _logger.LogInformation(
                "Performance - CPU: {Cpu}%, Available RAM: {Ram}MB",
                cpuUsage, availableRam);

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}

// ✅ Query profiling with EF Core
public class QueryProfilingConfiguration
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            var logger = sp.GetRequiredService<ILoggerFactory>();

            options.UseSqlServer(connectionString)
                .EnableSensitiveDataLogging() // Dev only
                .EnableDetailedErrors()
                .LogTo(
                    message => Console.WriteLine(message),
                    new[] { DbLoggerCategory.Database.Command.Name },
                    LogLevel.Information,
                    DbContextLoggerOptions.SingleLine | DbContextLoggerOptions.UtcTime);

            // Add query interceptor
            options.AddInterceptors(new QueryPerformanceInterceptor());
        });
    }
}

public class QueryPerformanceInterceptor : DbCommandInterceptor
{
    private readonly ILogger<QueryPerformanceInterceptor> _logger;
    private const int SlowQueryThresholdMs = 1000;

    public override async ValueTask<DbDataReader> ReaderExecutedAsync(
        DbCommand command,
        CommandExecutedEventData eventData,
        DbDataReader result,
        CancellationToken cancellationToken = default)
    {
        var duration = eventData.Duration.TotalMilliseconds;

        if (duration > SlowQueryThresholdMs)
        {
            _logger?.LogWarning(
                "Slow query detected: {Query} took {Duration}ms",
                command.CommandText,
                duration);
        }

        return await base.ReaderExecutedAsync(command, eventData, result, cancellationToken);
    }
}

// ✅ OpenTelemetry integration
public class OpenTelemetryConfiguration
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddOpenTelemetry()
            .WithTracing(builder =>
            {
                builder
                    .AddAspNetCoreInstrumentation(options =>
                    {
                        options.RecordException = true;
                        options.EnrichWithHttpRequest = (activity, request) =>
                        {
                            activity.SetTag("http.client_ip", request.HttpContext.Connection.RemoteIpAddress);
                        };
                    })
                    .AddHttpClientInstrumentation()
                    .AddSqlClientInstrumentation(options =>
                    {
                        options.SetDbStatementForText = true;
                        options.RecordException = true;
                    })
                    .AddEntityFrameworkCoreInstrumentation()
                    .AddConsoleExporter()
                    .AddJaegerExporter(options =>
                    {
                        options.AgentHost = "localhost";
                        options.AgentPort = 6831;
                    });
            })
            .WithMetrics(builder =>
            {
                builder
                    .AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddRuntimeInstrumentation()
                    .AddPrometheusExporter();
            });
    }
}

/*
Profiling Tools and Techniques:

1. dotnet-counters (CLI tool):
   dotnet-counters monitor --process-id <PID>
   dotnet-counters collect --process-id <PID> --output counters.csv

2. dotnet-trace (Performance tracing):
   dotnet-trace collect --process-id <PID>
   dotnet-trace convert trace.nettrace --format speedscope

3. dotnet-dump (Memory dumps):
   dotnet-dump collect --process-id <PID>
   dotnet-dump analyze dump.dmp

4. PerfView (Windows):
   - CPU sampling
   - Memory allocations
   - GC collections
   - Thread time analysis

5. Visual Studio Profiler:
   - CPU usage
   - Memory usage
   - Database queries
   - Async/await analysis

6. JetBrains dotTrace:
   - Timeline profiling
   - Sampling profiling
   - Tracing profiling
   - Memory profiling

7. Application Insights:
   - Request telemetry
   - Dependency tracking
   - Exception tracking
   - Custom metrics

8. MiniProfiler:
   - SQL query profiling
   - Step timing
   - Client timing
   - Entity Framework profiling

Key Metrics to Monitor:
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate (%)
- CPU usage (%)
- Memory usage (MB)
- GC pause time (ms)
- Database query time (ms)
- External API call time (ms)
- Thread pool queue length
- Connection pool utilization

Performance Tuning Checklist:
✅ Profile before optimizing
✅ Identify bottlenecks with data
✅ Optimize database queries first
✅ Enable caching where appropriate
✅ Use async/await properly
✅ Minimize allocations
✅ Use object pooling
✅ Optimize hot paths
✅ Monitor GC pressure
✅ Load test after changes

Common Performance Issues:
❌ N+1 query problems
❌ Missing database indexes
❌ Synchronous I/O in async code
❌ Excessive allocations
❌ Large object heap fragmentation
❌ Thread pool starvation
❌ Connection pool exhaustion
❌ Inefficient serialization
❌ Missing output caching
❌ Unoptimized images

Profiling Workflow:
1. Establish baseline metrics
2. Identify bottlenecks with profiler
3. Formulate hypothesis
4. Implement optimization
5. Measure improvement
6. Repeat for next bottleneck
*/
```

---

## Q320. What is a comprehensive real-world performance optimization case study?

```csharp
/*
Real-World Performance Optimization Case Study
E-Commerce Product Catalog API

Initial State: 2000ms average response time, 50 req/s max throughput
Final State: 150ms average response time, 500 req/s max throughput

Optimization Journey:
*/

// ❌ INITIAL VERSION: Slow and inefficient
[ApiController]
[Route("api/[controller]")]
public class ProductsControllerV1 : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ProductsControllerV1(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts(
        string category = null,
        int page = 1,
        int pageSize = 20)
    {
        // Problem 1: No tracking disabled
        var query = _context.Products
            .Include(p => p.Category) // Problem 2: Loading full navigation
            .Include(p => p.Reviews)  // Problem 3: Loading all reviews
            .Include(p => p.Images)   // Problem 4: Loading all images
            .AsQueryable();

        if (!string.IsNullOrEmpty(category))
        {
            // Problem 5: String comparison in database
            query = query.Where(p => p.Category.Name.ToLower() == category.ToLower());
        }

        // Problem 6: No pagination before loading
        var products = await query.ToListAsync();

        // Problem 7: Pagination in memory
        var pagedProducts = products
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        // Problem 8: No caching
        // Problem 9: No compression
        // Problem 10: Returning full entities
        return Ok(pagedProducts);
    }
}

// ✅ OPTIMIZATION STEP 1: Database Query Optimization (2000ms → 800ms)
[ApiController]
[Route("api/[controller]")]
public class ProductsControllerV2 : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetProducts(
        string category = null,
        int page = 1,
        int pageSize = 20)
    {
        var query = _context.Products.AsNoTracking(); // Fix 1: Disable tracking

        if (!string.IsNullOrEmpty(category))
        {
            // Fix 2: Use indexed column
            query = query.Where(p => p.CategoryId == GetCategoryId(category));
        }

        // Fix 3: Projection instead of Include
        var products = await query
            .Skip((page - 1) * pageSize) // Fix 4: Paginate in database
            .Take(pageSize)
            .Select(p => new ProductDto // Fix 5: Select only needed fields
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                CategoryName = p.Category.Name,
                ImageUrl = p.Images.OrderBy(i => i.Order).Select(i => i.Url).FirstOrDefault(),
                ReviewCount = p.Reviews.Count,
                AverageRating = p.Reviews.Average(r => (double?)r.Rating) ?? 0
            })
            .ToListAsync();

        return Ok(products);
    }
}

// ✅ OPTIMIZATION STEP 2: Add Caching (800ms → 200ms on cache hit)
[ApiController]
[Route("api/[controller]")]
public class ProductsControllerV3 : ControllerBase
{
    private readonly IMemoryCache _cache;
    private readonly IDistributedCache _distributedCache;

    [HttpGet]
    [ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "category", "page" })]
    public async Task<IActionResult> GetProducts(
        string category = null,
        int page = 1,
        int pageSize = 20)
    {
        var cacheKey = $"products_{category}_{page}_{pageSize}";

        // Try distributed cache first (Redis)
        var cachedData = await _distributedCache.GetStringAsync(cacheKey);

        if (cachedData != null)
        {
            var products = JsonSerializer.Deserialize<List<ProductDto>>(cachedData);
            return Ok(products);
        }

        // Query database if not in cache
        var result = await GetProductsFromDatabase(category, page, pageSize);

        // Store in distributed cache
        await _distributedCache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(result),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
            });

        return Ok(result);
    }
}

// ✅ OPTIMIZATION STEP 3: Add Response Compression (200ms → 150ms perceived)
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddResponseCompression(options =>
        {
            options.EnableForHttps = true;
            options.Providers.Add<BrotliCompressionProvider>();
        });

        services.Configure<BrotliCompressionProviderOptions>(options =>
        {
            options.Level = CompressionLevel.Fastest;
        });
    }
}

// ✅ OPTIMIZATION STEP 4: Connection Pooling and DbContext Pool
services.AddDbContextPool<ApplicationDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.CommandTimeout(30);
        sqlOptions.EnableRetryOnFailure(3);
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
    });
    options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
}, poolSize: 128);

// ✅ OPTIMIZATION STEP 5: Add Database Indexes
/*
CREATE NONCLUSTERED INDEX IX_Products_CategoryId
ON Products(CategoryId)
INCLUDE (Name, Price);

CREATE NONCLUSTERED INDEX IX_Reviews_ProductId
ON Reviews(ProductId)
INCLUDE (Rating);

CREATE NONCLUSTERED INDEX IX_Images_ProductId_Order
ON Images(ProductId, [Order])
INCLUDE (Url);
*/

// ✅ FINAL OPTIMIZED VERSION
[ApiController]
[Route("api/[controller]")]
public class ProductsControllerOptimized : ControllerBase
{
    private readonly IProductService _productService;
    private readonly IOutputCacheStore _outputCache;
    private readonly ILogger<ProductsControllerOptimized> _logger;

    [HttpGet]
    [OutputCache(Duration = 300, VaryByQueryKeys = new[] { "category", "page" })]
    public async Task<IActionResult> GetProducts(
        [FromQuery] ProductQueryParameters parameters)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            var result = await _productService.GetProductsOptimizedAsync(parameters);

            stopwatch.Stop();

            _logger.LogInformation(
                "GetProducts completed in {Duration}ms for category={Category}, page={Page}",
                stopwatch.ElapsedMilliseconds,
                parameters.Category,
                parameters.Page);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            throw;
        }
    }
}

public class ProductService : IProductService
{
    private readonly ApplicationDbContext _context;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ProductService> _logger;

    public async Task<PagedResult<ProductDto>> GetProductsOptimizedAsync(
        ProductQueryParameters parameters)
    {
        // Build optimized query
        var query = _context.Products.AsNoTracking();

        if (!string.IsNullOrEmpty(parameters.Category))
        {
            query = query.Where(p => p.CategoryId == parameters.CategoryId);
        }

        if (!string.IsNullOrEmpty(parameters.SearchTerm))
        {
            query = query.Where(p => EF.Functions.Like(p.Name, $"%{parameters.SearchTerm}%"));
        }

        // Get total count (cached)
        var totalCount = await GetTotalCountCached(parameters);

        // Get paginated results with projection
        var products = await query
            .OrderByDescending(p => p.CreatedDate)
            .Skip((parameters.Page - 1) * parameters.PageSize)
            .Take(parameters.PageSize)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                CategoryName = p.Category.Name,
                ImageUrl = p.Images.OrderBy(i => i.Order).Select(i => i.Url).FirstOrDefault(),
                ReviewCount = p.Reviews.Count,
                AverageRating = p.Reviews.Average(r => (double?)r.Rating) ?? 0
            })
            .ToListAsync();

        return new PagedResult<ProductDto>
        {
            Items = products,
            TotalCount = totalCount,
            Page = parameters.Page,
            PageSize = parameters.PageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)parameters.PageSize)
        };
    }

    private async Task<int> GetTotalCountCached(ProductQueryParameters parameters)
    {
        var cacheKey = $"product_count_{parameters.Category}";

        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);

            var query = _context.Products.AsNoTracking();

            if (!string.IsNullOrEmpty(parameters.Category))
            {
                query = query.Where(p => p.CategoryId == parameters.CategoryId);
            }

            return await query.CountAsync();
        });
    }
}

/*
PERFORMANCE OPTIMIZATION RESULTS:

Metric                  | Before  | After   | Improvement
-----------------------|---------|---------|------------
Avg Response Time      | 2000ms  | 150ms   | 93% faster
P95 Response Time      | 3500ms  | 250ms   | 93% faster
Max Throughput         | 50/s    | 500/s   | 10x increase
Database Queries       | 150ms   | 15ms    | 90% faster
Payload Size          | 500KB   | 50KB    | 90% smaller
Memory per Request     | 2MB     | 200KB   | 90% less
CPU Usage (avg)        | 75%     | 25%     | 67% reduction

KEY OPTIMIZATIONS APPLIED:

1. Database (60% improvement):
   ✅ AsNoTracking() for read-only queries
   ✅ Projection instead of Include
   ✅ Database-side pagination
   ✅ Indexed columns for filtering
   ✅ Split queries for collections

2. Caching (30% improvement):
   ✅ Output caching for responses
   ✅ Distributed caching (Redis)
   ✅ Cache total counts separately
   ✅ Smart cache invalidation

3. Data Transfer (5% improvement):
   ✅ Response compression (Brotli)
   ✅ DTOs with only needed fields
   ✅ Pagination to limit data

4. Infrastructure (5% improvement):
   ✅ DbContext pooling
   ✅ Connection pooling
   ✅ Load balancing
   ✅ CDN for static assets

LESSONS LEARNED:

1. Profile First
   - Used Application Insights to identify bottlenecks
   - Database queries were the biggest issue (60% of time)

2. Optimize in Order of Impact
   - Database optimization first (biggest win)
   - Then caching (second biggest)
   - Then compression (smaller win)

3. Measure Everything
   - Before/after metrics for each change
   - Automated performance tests
   - Real-world load testing

4. Don't Over-Optimize
   - Stopped at 150ms (good enough)
   - Further optimization had diminishing returns
   - Focus shifted to other features

5. Monitor in Production
   - Set up alerts for slow requests
   - Track performance over time
   - Detect regressions quickly
*/
```

---

**Performance & Optimization Section (Q301-Q320) Complete!**

This section covered comprehensive performance optimization strategies including:
- Database query optimization and caching
- Asynchronous programming and parallel processing
- Memory management and leak prevention
- HTTP client optimization
- Response compression and minification
- Static file serving and CDN optimization
- Connection pooling and resource management
- Application startup optimization
- Performance monitoring and diagnostics
- Load testing strategies
- Background job processing
- Middleware pipeline optimization
- Profiling and tuning techniques
- Real-world optimization case studies

All 20 questions have been successfully added with detailed code examples, best practices, anti-patterns, and real-world scenarios!

