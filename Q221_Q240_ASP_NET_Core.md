# INTERVIEW QUESTIONS 221-240: ASP.NET Core & Web API

## SECTION 6: ASP.NET CORE

---

## Q221: What is ASP.NET Core? What are its advantages over ASP.NET Framework?

**Answer:**

**ASP.NET Core** is a cross-platform, high-performance, open-source framework for building modern, cloud-based, Internet-connected applications.

### Key Differences: ASP.NET Core vs ASP.NET Framework

```csharp
// ============================================
// ASP.NET CORE PROGRAM.CS (Minimal API)
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### Advantages of ASP.NET Core

#### 1. Cross-Platform

```bash
# ASP.NET Framework - Windows only
# Can only run on Windows with IIS

# ASP.NET Core - Cross-platform
# Runs on Windows, Linux, macOS

# Deploy to:
- Windows Server (IIS, Kestrel)
- Linux (Kestrel with nginx/Apache)
- macOS (for development)
- Docker containers
- Kubernetes clusters
```

```csharp
// Same code runs on all platforms
public class ProductsController : ControllerBase
{
    [HttpGet]
    public ActionResult<IEnumerable<Product>> Get()
    {
        return Ok(products);
    }
}
```

---

#### 2. High Performance

```csharp
// ============================================
// PERFORMANCE OPTIMIZATIONS
// ============================================

// Built-in performance features:

// 1. Kestrel web server (ultra-fast)
builder.WebHost.UseKestrel(options =>
{
    options.Limits.MaxConcurrentConnections = 100;
    options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB
});

// 2. Response caching
builder.Services.AddResponseCaching();
app.UseResponseCaching();

[ResponseCache(Duration = 60)]
[HttpGet]
public IActionResult GetProducts()
{
    return Ok(products);
}

// 3. Output caching (ASP.NET Core 7+)
builder.Services.AddOutputCache();
app.UseOutputCache();

[OutputCache(Duration = 60)]
[HttpGet]
public IActionResult GetProducts()
{
    return Ok(products);
}

// 4. Minimal allocations
// - Span<T> and Memory<T> usage
// - ArrayPool<T> for buffers
// - Object pooling
```

**Benchmark Results:**
```
ASP.NET Core 8.0:  7+ million requests/sec
ASP.NET Framework: 1 million requests/sec

ASP.NET Core is 7x faster!
```

---

#### 3. Dependency Injection (Built-in)

```csharp
// ============================================
// ASP.NET FRAMEWORK - Manual DI
// ============================================

// Web.config or Global.asax
public class MvcApplication : HttpApplication
{
    protected void Application_Start()
    {
        // Manual registration with third-party container
        var container = new UnityContainer();
        container.RegisterType<ICustomerRepository, CustomerRepository>();
        DependencyResolver.SetResolver(new UnityDependencyResolver(container));
    }
}

// ============================================
// ASP.NET CORE - Built-in DI
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Built-in DI container
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddSingleton<ICacheService, MemoryCacheService>();
builder.Services.AddTransient<IEmailService, EmailService>();

// Controller automatically receives dependencies
public class CustomersController : ControllerBase
{
    private readonly ICustomerRepository _repository;
    private readonly IOrderService _orderService;

    public CustomersController(
        ICustomerRepository repository,
        IOrderService orderService)
    {
        _repository = repository;
        _orderService = orderService;
    }
}
```

---

#### 4. Unified Programming Model

```csharp
// ============================================
// ASP.NET FRAMEWORK - Separate frameworks
// ============================================

// MVC for web apps
public class HomeController : Controller
{
    public ActionResult Index() => View();
}

// Web API for APIs
public class ProductsController : ApiController
{
    public IHttpActionResult Get() => Ok(products);
}

// Different base classes, different behaviors!

// ============================================
// ASP.NET CORE - Unified
// ============================================

// Same base class for everything
public class HomeController : ControllerBase
{
    // Returns view (MVC)
    [HttpGet]
    public IActionResult Index() => View();

    // Returns JSON (API)
    [HttpGet("api/data")]
    public IActionResult GetData() => Ok(data);
}
```

---

#### 5. Modular Middleware Pipeline

```csharp
// ============================================
// ASP.NET FRAMEWORK - HttpModules (rigid)
// ============================================

// Web.config
<system.webServer>
  <modules>
    <add name="CustomModule" type="MyApp.CustomModule" />
  </modules>
</system.webServer>

// ============================================
// ASP.NET CORE - Middleware (flexible)
// ============================================

var app = builder.Build();

// Middleware pipeline - fully customizable order
app.UseHttpsRedirection();        // 1. Redirect to HTTPS
app.UseStaticFiles();              // 2. Serve static files
app.UseRouting();                  // 3. Route matching
app.UseCors();                     // 4. CORS
app.UseAuthentication();           // 5. Authentication
app.UseAuthorization();            // 6. Authorization
app.UseResponseCaching();          // 7. Response caching
app.UseResponseCompression();      // 8. Compression

// Custom middleware
app.Use(async (context, next) =>
{
    // Before
    Console.WriteLine($"Request: {context.Request.Path}");

    await next();  // Call next middleware

    // After
    Console.WriteLine($"Response: {context.Response.StatusCode}");
});

app.MapControllers();              // 9. Endpoints
```

---

#### 6. Modern Configuration System

```csharp
// ============================================
// ASP.NET FRAMEWORK - Web.config only
// ============================================

<configuration>
  <appSettings>
    <add key="ConnectionString" value="..." />
  </appSettings>
</configuration>

// Code
string connStr = ConfigurationManager.AppSettings["ConnectionString"];

// ============================================
// ASP.NET CORE - Multiple sources
// ============================================

// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=..."
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "MySettings": {
    "MaxItems": 100
  }
}

// appsettings.Development.json (overrides)
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost..."
  }
}

// Configuration sources (in order of precedence):
var builder = WebApplication.CreateBuilder(args);

// 1. appsettings.json
// 2. appsettings.{Environment}.json
// 3. User secrets (Development only)
// 4. Environment variables
// 5. Command-line arguments

// Strongly-typed configuration
public class MySettings
{
    public int MaxItems { get; set; }
}

builder.Services.Configure<MySettings>(
    builder.Configuration.GetSection("MySettings"));

// Inject configuration
public class MyService
{
    private readonly MySettings _settings;

    public MyService(IOptions<MySettings> settings)
    {
        _settings = settings.Value;
    }
}
```

---

#### 7. Side-by-Side Versioning

```bash
# ASP.NET Framework
# Single version installed globally
# All apps use same version
# Updating .NET Framework affects ALL apps

# ASP.NET Core
# Each app can use different version
# Self-contained deployment includes runtime
# Updating one app doesn't affect others

# Example:
/app1/  → ASP.NET Core 6.0
/app2/  → ASP.NET Core 7.0
/app3/  → ASP.NET Core 8.0

# All running on same server!
```

---

#### 8. Cloud-Optimized

```csharp
// ============================================
// CLOUD FEATURES
// ============================================

// Environment-based configuration
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

// Health checks for Kubernetes/Load balancers
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>()
    .AddUrlGroup(new Uri("https://api.example.com"), "External API");

app.MapHealthChecks("/health");

// Distributed caching
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
});

// Application Insights integration
builder.Services.AddApplicationInsightsTelemetry();

// Docker support
// Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0
COPY bin/Release/net8.0/publish/ App/
WORKDIR /App
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

---

### Comparison Table

| Feature | ASP.NET Framework | ASP.NET Core |
|---------|------------------|--------------|
| **Platform** | Windows only | Cross-platform (Windows, Linux, macOS) |
| **Performance** | Good | Excellent (7x faster) |
| **Deployment** | IIS only | IIS, Kestrel, nginx, Apache, Docker |
| **DI** | Third-party | Built-in |
| **Configuration** | Web.config | JSON, Environment vars, User secrets |
| **Web Server** | IIS | Kestrel (cross-platform) |
| **Open Source** | Partially | Fully open source |
| **Versioning** | Global | Side-by-side |
| **Cloud** | Limited | Optimized |
| **Containers** | Difficult | First-class support |
| **Startup Time** | Slow | Fast |
| **Package Management** | NuGet (legacy) | NuGet (modern) |
| **Development** | Visual Studio | VS, VS Code, CLI |

---

### When to Use Each

**Use ASP.NET Framework when:**
- ❌ Existing large application (migration cost)
- ❌ Windows-specific dependencies (WCF, Remoting)
- ❌ .NET Framework-only libraries
- ❌ Team not ready for migration

**Use ASP.NET Core when:**
- ✅ New applications (always!)
- ✅ Need cross-platform support
- ✅ Performance is critical
- ✅ Deploying to containers/cloud
- ✅ Microservices architecture
- ✅ Modern development practices

---

### Migration Path

```csharp
// ============================================
// GRADUAL MIGRATION STRATEGY
// ============================================

// 1. Start with .NET Standard libraries
// Create .NET Standard 2.0 class libraries
// Can be referenced by both Framework and Core

// 2. Migrate business logic to .NET Standard
// MyApp.Core (. NET Standard 2.0)
public class OrderService
{
    // Works in both Framework and Core
}

// 3. Create new ASP.NET Core API alongside Framework app
// ASP.NET Framework app → IIS
// ASP.NET Core API → Kestrel

// 4. Gradually move endpoints to Core
// Use reverse proxy to route traffic

// 5. Retire Framework app when migration complete
```

---

### Real-World Example

```csharp
// ============================================
// MODERN ASP.NET CORE APP
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Dependency injection
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IOrderService, OrderService>();

// Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => { /* config */ });

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
        builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

// API documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Caching
builder.Services.AddResponseCaching();
builder.Services.AddMemoryCache();

// Health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.UseResponseCaching();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

// Controller
[ApiController]
[Route("api/[controller]")]
public class CustomersController : ControllerBase
{
    private readonly ICustomerRepository _repository;
    private readonly ILogger<CustomersController> _logger;

    public CustomersController(
        ICustomerRepository repository,
        ILogger<CustomersController> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [HttpGet]
    [ResponseCache(Duration = 60)]
    public async Task<ActionResult<IEnumerable<Customer>>> GetCustomers()
    {
        _logger.LogInformation("Getting all customers");
        var customers = await _repository.GetAllAsync();
        return Ok(customers);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Customer>> GetCustomer(int id)
    {
        var customer = await _repository.GetByIdAsync(id);

        if (customer == null)
        {
            _logger.LogWarning("Customer {CustomerId} not found", id);
            return NotFound();
        }

        return Ok(customer);
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<Customer>> CreateCustomer(Customer customer)
    {
        await _repository.AddAsync(customer);

        _logger.LogInformation("Customer {CustomerId} created", customer.Id);

        return CreatedAtAction(
            nameof(GetCustomer),
            new { id = customer.Id },
            customer);
    }
}
```

---

## Q222: Explain the ASP.NET Core request pipeline and middleware.

**Answer:**

The **request pipeline** is a sequence of middleware components that handle HTTP requests and responses. Each middleware can process the request, call the next middleware, and process the response.

### How the Pipeline Works

```
Client Request
    ↓
[Middleware 1] → Process request → Call next()
    ↓
[Middleware 2] → Process request → Call next()
    ↓
[Middleware 3] → Process request → Call next()
    ↓
[Endpoint] → Generate response
    ↑
[Middleware 3] ← Process response ←
    ↑
[Middleware 2] ← Process response ←
    ↑
[Middleware 1] ← Process response ←
    ↑
Client Response
```

### Basic Middleware Example

```csharp
// ============================================
// INLINE MIDDLEWARE
// ============================================

var app = builder.Build();

// Middleware 1: Logging
app.Use(async (context, next) =>
{
    // Before calling next middleware
    Console.WriteLine($"Request: {context.Request.Method} {context.Request.Path}");
    var stopwatch = Stopwatch.StartNew();

    await next();  // Call next middleware

    // After next middleware completes
    stopwatch.Stop();
    Console.WriteLine($"Response: {context.Response.StatusCode} ({stopwatch.ElapsedMilliseconds}ms)");
});

// Middleware 2: Custom header
app.Use(async (context, next) =>
{
    context.Response.Headers.Add("X-Custom-Header", "My Value");
    await next();
});

// Middleware 3: Short-circuit example
app.Use(async (context, next) =>
{
    if (context.Request.Path == "/blocked")
    {
        context.Response.StatusCode = 403;
        await context.Response.WriteAsync("Access Forbidden");
        return;  // Don't call next() - short-circuit!
    }

    await next();
});

app.Run();
```

---

### Standard Middleware Pipeline

```csharp
// ============================================
// TYPICAL MIDDLEWARE ORDER
// ============================================

var app = builder.Build();

// 1. Exception handling (outermost)
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();  // HTTP Strict Transport Security
}

// 2. HTTPS Redirection
app.UseHttpsRedirection();

// 3. Static files (short-circuits for static content)
app.UseStaticFiles();

// 4. Routing (match routes)
app.UseRouting();

// 5. CORS (must be after routing, before auth)
app.UseCors("MyPolicy");

// 6. Authentication
app.UseAuthentication();

// 7. Authorization
app.UseAuthorization();

// 8. Session (if needed)
app.UseSession();

// 9. Response caching
app.UseResponseCaching();

// 10. Response compression
app.UseResponseCompression();

// 11. Custom middleware
app.UseMiddleware<RequestTimingMiddleware>();

// 12. Endpoints (innermost)
app.MapControllers();
app.MapRazorPages();

app.Run();
```

**Why Order Matters:**

```csharp
// ❌ BAD - Authorization before Authentication
app.UseAuthorization();  // Can't authorize without auth!
app.UseAuthentication();

// ✅ GOOD - Authentication before Authorization
app.UseAuthentication();  // Identify user
app.UseAuthorization();   // Check permissions

// ❌ BAD - Static files after routing
app.UseRouting();
app.UseStaticFiles();  // Static files checked after routing

// ✅ GOOD - Static files before routing
app.UseStaticFiles();  // Serve static files immediately
app.UseRouting();      // Route only if not static
```

---

### Custom Middleware Class

```csharp
// ============================================
// CUSTOM MIDDLEWARE COMPONENT
// ============================================

public class RequestTimingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestTimingMiddleware> _logger;

    public RequestTimingMiddleware(
        RequestDelegate next,
        ILogger<RequestTimingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var requestPath = context.Request.Path;

        try
        {
            // Before
            _logger.LogInformation("Request started: {Path}", requestPath);

            await _next(context);  // Call next middleware

            // After
            stopwatch.Stop();
            _logger.LogInformation(
                "Request completed: {Path} - {StatusCode} ({ElapsedMs}ms)",
                requestPath,
                context.Response.StatusCode,
                stopwatch.ElapsedMilliseconds);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex,
                "Request failed: {Path} ({ElapsedMs}ms)",
                requestPath,
                stopwatch.ElapsedMilliseconds);
            throw;
        }
    }
}

// Extension method for easy registration
public static class RequestTimingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestTiming(
        this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<RequestTimingMiddleware>();
    }
}

// Usage
app.UseRequestTiming();
```

---

### Advanced Middleware Examples

#### 1. Rate Limiting Middleware

```csharp
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly int _requestLimit = 100;
    private readonly TimeSpan _timeWindow = TimeSpan.FromMinutes(1);

    public RateLimitingMiddleware(
        RequestDelegate next,
        IMemoryCache cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var cacheKey = $"RateLimit_{clientId}";

        // Get current request count
        if (!_cache.TryGetValue(cacheKey, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= _requestLimit)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            context.Response.Headers.Add("Retry-After", _timeWindow.TotalSeconds.ToString());
            await context.Response.WriteAsync("Rate limit exceeded. Try again later.");
            return;  // Short-circuit
        }

        // Increment counter
        requestCount++;
        _cache.Set(cacheKey, requestCount, _timeWindow);

        // Add rate limit headers
        context.Response.Headers.Add("X-Rate-Limit-Limit", _requestLimit.ToString());
        context.Response.Headers.Add("X-Rate-Limit-Remaining", (_requestLimit - requestCount).ToString());

        await _next(context);
    }
}
```

#### 2. Request/Response Logging Middleware

```csharp
public class RequestResponseLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestResponseLoggingMiddleware> _logger;

    public RequestResponseLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestResponseLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Log request
        context.Request.EnableBuffering();
        var requestBody = await ReadRequestBody(context.Request);

        _logger.LogInformation(
            "Request: {Method} {Path}\nHeaders: {Headers}\nBody: {Body}",
            context.Request.Method,
            context.Request.Path,
            context.Request.Headers,
            requestBody);

        // Capture response
        var originalBodyStream = context.Response.Body;
        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;

        await _next(context);

        // Log response
        context.Response.Body.Seek(0, SeekOrigin.Begin);
        var responseBodyText = await new StreamReader(context.Response.Body).ReadToEndAsync();
        context.Response.Body.Seek(0, SeekOrigin.Begin);

        _logger.LogInformation(
            "Response: {StatusCode}\nBody: {Body}",
            context.Response.StatusCode,
            responseBodyText);

        await responseBody.CopyToAsync(originalBodyStream);
    }

    private async Task<string> ReadRequestBody(HttpRequest request)
    {
        request.Body.Seek(0, SeekOrigin.Begin);
        var body = await new StreamReader(request.Body).ReadToEndAsync();
        request.Body.Seek(0, SeekOrigin.Begin);
        return body;
    }
}
```

#### 3. API Key Authentication Middleware

```csharp
public class ApiKeyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;
    private const string ApiKeyHeaderName = "X-API-Key";

    public ApiKeyMiddleware(
        RequestDelegate next,
        IConfiguration configuration)
    {
        _next = next;
        _configuration = configuration;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Skip authentication for certain paths
        if (context.Request.Path.StartsWithSegments("/health"))
        {
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue(ApiKeyHeaderName, out var providedApiKey))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("API Key is missing");
            return;
        }

        var validApiKey = _configuration["ApiKey"];

        if (!validApiKey.Equals(providedApiKey))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Invalid API Key");
            return;
        }

        await _next(context);
    }
}
```

---

### Middleware vs Filters

```csharp
// ============================================
// MIDDLEWARE - Runs for ALL requests
// ============================================

app.Use(async (context, next) =>
{
    // Runs for EVERY request (static files, API, MVC, etc.)
    await next();
});

// ============================================
// FILTERS - Runs only for MVC/API actions
// ============================================

// Action filter (runs only for controller actions)
public class LoggingActionFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        // Before action executes
        Console.WriteLine($"Executing action: {context.ActionDescriptor.DisplayName}");
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        // After action executes
        Console.WriteLine($"Executed action: {context.ActionDescriptor.DisplayName}");
    }
}

// Register globally
builder.Services.AddControllers(options =>
{
    options.Filters.Add<LoggingActionFilter>();
});

// Or use on specific controller/action
[ServiceFilter(typeof(LoggingActionFilter))]
public class ProductsController : ControllerBase
{
    // ...
}
```

---

### Terminal Middleware

```csharp
// ============================================
// TERMINAL MIDDLEWARE (doesn't call next)
// ============================================

// Run - terminal middleware (end of pipeline)
app.Run(async context =>
{
    await context.Response.WriteAsync("End of pipeline");
    // No next() - this is the end!
});

// Map - branches the pipeline
app.Map("/health", healthApp =>
{
    healthApp.Run(async context =>
    {
        await context.Response.WriteAsync("Healthy");
    });
});

// MapWhen - conditional branching
app.MapWhen(
    context => context.Request.Query.ContainsKey("debug"),
    debugApp =>
    {
        debugApp.Run(async context =>
        {
            await context.Response.WriteAsync("Debug mode");
        });
    });
```

---

### Best Practices

```csharp
// 1. ✅ Order middleware correctly
app.UseExceptionHandler("/Error");  // First
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();               // Last

// 2. ✅ Use extension methods for middleware
public static class MyMiddlewareExtensions
{
    public static IApplicationBuilder UseMyMiddleware(
        this IApplicationBuilder app)
    {
        return app.UseMiddleware<MyMiddleware>();
    }
}

// 3. ✅ Handle exceptions in middleware
public async Task InvokeAsync(HttpContext context)
{
    try
    {
        await _next(context);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in middleware");
        throw;  // Re-throw or handle
    }
}

// 4. ✅ Use dependency injection in middleware
public class MyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger _logger;

    public MyMiddleware(RequestDelegate next, ILogger<MyMiddleware> logger)
    {
        _next = next;
        _logger = logger;  // Singleton services only in constructor
    }

    public async Task InvokeAsync(
        HttpContext context,
        IMyService service)  // Scoped/Transient services in InvokeAsync
    {
        await service.DoSomethingAsync();
        await _next(context);
    }
}

// 5. ✅ Short-circuit when appropriate
if (context.Request.Path == "/health")
{
    await context.Response.WriteAsync("OK");
    return;  // Don't call next()
}

// 6. ❌ Don't modify response after next() if headers sent
await _next(context);
// Dangerous: response may have started
context.Response.Headers.Add("X-Header", "Value");  // May throw!

// 7. ✅ Check if response has started
if (!context.Response.HasStarted)
{
    context.Response.Headers.Add("X-Header", "Value");
}
```

---

---

## Q223: Explain Dependency Injection in ASP.NET Core.

**Answer:**

**Dependency Injection (DI)** is a design pattern built into ASP.NET Core that manages object dependencies and their lifetimes. It promotes loose coupling and testability.

### Service Lifetimes

```csharp
// ============================================
// THREE SERVICE LIFETIMES
// ============================================

var builder = WebApplication.CreateBuilder(args);

// 1. TRANSIENT - New instance every time
builder.Services.AddTransient<IEmailService, EmailService>();
// Use for: Lightweight, stateless services
// Created: Every time requested
// Example: Email service, HTTP clients

// 2. SCOPED - One instance per HTTP request
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<AppDbContext>();
// Use for: Database contexts, repositories, unit of work
// Created: Once per request
// Shared: Within same request
// Example: DbContext, repositories

// 3. SINGLETON - One instance for application lifetime
builder.Services.AddSingleton<ICacheService, MemoryCacheService>();
builder.Services.AddSingleton<IConfiguration>(builder.Configuration);
// Use for: Expensive to create, thread-safe services
// Created: Once when first requested
// Shared: Across all requests
// Example: Configuration, caching, logging
```

---

### Lifetime Visualization

```csharp
// ============================================
// LIFETIME COMPARISON
// ============================================

public interface IOperationService
{
    Guid OperationId { get; }
}

public class OperationService : IOperationService
{
    public Guid OperationId { get; } = Guid.NewGuid();
}

// Register with different lifetimes
builder.Services.AddTransient<ITransientOperation, OperationService>();
builder.Services.AddScoped<IScopedOperation, OperationService>();
builder.Services.AddSingleton<ISingletonOperation, OperationService>();

[ApiController]
[Route("api/[controller]")]
public class LifetimeController : ControllerBase
{
    private readonly ITransientOperation _transient1;
    private readonly ITransientOperation _transient2;
    private readonly IScopedOperation _scoped1;
    private readonly IScopedOperation _scoped2;
    private readonly ISingletonOperation _singleton1;
    private readonly ISingletonOperation _singleton2;

    public LifetimeController(
        ITransientOperation transient1,
        ITransientOperation transient2,
        IScopedOperation scoped1,
        IScopedOperation scoped2,
        ISingletonOperation singleton1,
        ISingletonOperation singleton2)
    {
        _transient1 = transient1;
        _transient2 = transient2;
        _scoped1 = scoped1;
        _scoped2 = scoped2;
        _singleton1 = singleton1;
        _singleton2 = singleton2;
    }

    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            Transient1 = _transient1.OperationId,  // Different GUID
            Transient2 = _transient2.OperationId,  // Different GUID
            Scoped1 = _scoped1.OperationId,        // Same GUID (same request)
            Scoped2 = _scoped2.OperationId,        // Same GUID (same request)
            Singleton1 = _singleton1.OperationId,  // Same GUID (always)
            Singleton2 = _singleton2.OperationId   // Same GUID (always)
        });
    }
}

/*
Response:
{
  "transient1": "12345678-...",   // Different
  "transient2": "87654321-...",   // Different
  "scoped1": "abcdefgh-...",      // Same
  "scoped2": "abcdefgh-...",      // Same
  "singleton1": "xxxxxxxx-...",   // Same
  "singleton2": "xxxxxxxx-..."    // Same
}

Next request:
{
  "transient1": "new-guid-1",     // Different from previous
  "transient2": "new-guid-2",     // Different from previous
  "scoped1": "new-scoped",        // Different from previous request
  "scoped2": "new-scoped",        // Same as scoped1 this request
  "singleton1": "xxxxxxxx-...",   // SAME as previous request!
  "singleton2": "xxxxxxxx-..."    // SAME as previous request!
}
*/
```

---

### Registration Methods

```csharp
// ============================================
// DIFFERENT REGISTRATION METHODS
// ============================================

// 1. Interface → Implementation
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();

// 2. Implementation only (resolves as itself)
builder.Services.AddScoped<CustomerRepository>();

// 3. Factory method
builder.Services.AddScoped<IEmailService>(provider =>
{
    var config = provider.GetRequiredService<IConfiguration>();
    var apiKey = config["EmailService:ApiKey"];
    return new EmailService(apiKey);
});

// 4. Instance (singleton only)
var cacheService = new MemoryCacheService();
builder.Services.AddSingleton<ICacheService>(cacheService);

// 5. Multiple implementations
builder.Services.AddScoped<INotificationService, EmailNotificationService>();
builder.Services.AddScoped<INotificationService, SmsNotificationService>();

// Resolve all implementations
public class NotificationController : ControllerBase
{
    private readonly IEnumerable<INotificationService> _notificationServices;

    public NotificationController(IEnumerable<INotificationService> notificationServices)
    {
        _notificationServices = notificationServices;
        // Gets both Email and SMS services
    }
}

// 6. Try add (doesn't override existing)
builder.Services.TryAddScoped<IMyService, MyService>();
builder.Services.TryAddScoped<IMyService, AnotherService>();  // Ignored!

// 7. Replace
builder.Services.Replace(ServiceDescriptor.Scoped<IMyService, NewService>());
```

---

### Constructor Injection

```csharp
// ============================================
// CONSTRUCTOR INJECTION (Recommended)
// ============================================

public class OrderService : IOrderService
{
    private readonly ICustomerRepository _customerRepository;
    private readonly IProductRepository _productRepository;
    private readonly IEmailService _emailService;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        ICustomerRepository customerRepository,
        IProductRepository productRepository,
        IEmailService emailService,
        ILogger<OrderService> logger)
    {
        _customerRepository = customerRepository;
        _productRepository = productRepository;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderDto dto)
    {
        _logger.LogInformation("Creating order for customer {CustomerId}", dto.CustomerId);

        var customer = await _customerRepository.GetByIdAsync(dto.CustomerId);
        var product = await _productRepository.GetByIdAsync(dto.ProductId);

        var order = new Order
        {
            CustomerId = customer.Id,
            ProductId = product.Id,
            TotalAmount = product.Price * dto.Quantity
        };

        await _emailService.SendOrderConfirmationAsync(customer.Email, order);

        return order;
    }
}
```

---

### Property Injection (Not Recommended)

```csharp
// ============================================
// PROPERTY INJECTION (Avoid)
// ============================================

public class MyService
{
    // ❌ NOT supported out of the box in ASP.NET Core
    [Inject]
    public ILogger<MyService> Logger { get; set; }

    // Constructor injection is preferred
}

// If you really need it, use FromServices in controllers
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult Get([FromServices] IProductRepository repository)
    {
        var products = repository.GetAll();
        return Ok(products);
    }
}
```

---

### Service Locator Pattern (Anti-Pattern)

```csharp
// ============================================
// SERVICE LOCATOR (Anti-Pattern - Avoid!)
// ============================================

public class BadService
{
    private readonly IServiceProvider _serviceProvider;

    public BadService(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;  // ❌ Bad practice
    }

    public void DoSomething()
    {
        // ❌ Manual service resolution - hides dependencies
        var repository = _serviceProvider.GetRequiredService<ICustomerRepository>();
        repository.GetAll();
    }
}

// ✅ GOOD - Use constructor injection instead
public class GoodService
{
    private readonly ICustomerRepository _repository;

    public GoodService(ICustomerRepository repository)
    {
        _repository = repository;  // ✅ Dependency is explicit
    }

    public void DoSomething()
    {
        _repository.GetAll();
    }
}
```

---

### Manual Resolution

```csharp
// ============================================
// MANUAL SERVICE RESOLUTION
// ============================================

var app = builder.Build();

// Resolve services manually (rare cases)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;

    // Seed database
    var dbContext = services.GetRequiredService<AppDbContext>();
    await SeedData(dbContext);

    // Run migrations
    await dbContext.Database.MigrateAsync();
}

app.Run();
```

---

### Lifetime Best Practices

```csharp
// ============================================
// CAPTIVE DEPENDENCY PROBLEM
// ============================================

// ❌ BAD - Singleton depends on Scoped
public class SingletonService  // Singleton
{
    private readonly AppDbContext _context;  // Scoped!

    public SingletonService(AppDbContext context)
    {
        _context = context;
        // Problem: DbContext is scoped but captured by singleton
        // DbContext will never be disposed!
        // Will cause errors with multiple requests
    }
}

builder.Services.AddSingleton<SingletonService>();
builder.Services.AddScoped<AppDbContext>();

// ✅ GOOD - Use IServiceProvider to resolve scoped service
public class SingletonService
{
    private readonly IServiceProvider _serviceProvider;

    public SingletonService(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task DoWorkAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Use context within scope
        await context.Customers.ToListAsync();
    }  // DbContext disposed here
}

// ✅ BETTER - Don't inject scoped services into singletons!
// Redesign to avoid the dependency
```

---

### Generic Services

```csharp
// ============================================
// GENERIC SERVICES
// ============================================

// Generic interface
public interface IRepository<T> where T : class
{
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
}

// Generic implementation
public class Repository<T> : IRepository<T> where T : class
{
    private readonly AppDbContext _context;

    public Repository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<T> GetByIdAsync(int id)
    {
        return await _context.Set<T>().FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _context.Set<T>().ToListAsync();
    }

    public async Task AddAsync(T entity)
    {
        await _context.Set<T>().AddAsync(entity);
        await _context.SaveChangesAsync();
    }
}

// Register generic service
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Use in controller
public class ProductsController : ControllerBase
{
    private readonly IRepository<Product> _productRepository;

    public ProductsController(IRepository<Product> productRepository)
    {
        _productRepository = productRepository;  // Automatically resolved!
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var products = await _productRepository.GetAllAsync();
        return Ok(products);
    }
}
```

---

### Options Pattern

```csharp
// ============================================
// OPTIONS PATTERN
// ============================================

// appsettings.json
{
  "EmailSettings": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@example.com",
    "ApiKey": "secret-key"
  }
}

// Options class
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; }
    public string ApiKey { get; set; }
}

// Register options
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// Inject options
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> settings,
        ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendEmailAsync(string to, string subject, string body)
    {
        _logger.LogInformation("Sending email via {Server}:{Port}",
            _settings.SmtpServer,
            _settings.SmtpPort);

        // Send email using settings
    }
}

// IOptions vs IOptionsSnapshot vs IOptionsMonitor
builder.Services.AddScoped<IMyService, MyService>();

public class MyService
{
    // IOptions<T> - Singleton, doesn't reload on change
    public MyService(IOptions<EmailSettings> options) { }

    // IOptionsSnapshot<T> - Scoped, reloads per request
    public MyService(IOptionsSnapshot<EmailSettings> options) { }

    // IOptionsMonitor<T> - Singleton, reloads on change, notifies
    public MyService(IOptionsMonitor<EmailSettings> options)
    {
        options.OnChange(newSettings =>
        {
            // Settings changed!
        });
    }
}
```

---

### Testing with DI

```csharp
// ============================================
// TESTING WITH DEPENDENCY INJECTION
// ============================================

// Service with dependencies
public class OrderService : IOrderService
{
    private readonly ICustomerRepository _customerRepository;
    private readonly IEmailService _emailService;

    public OrderService(
        ICustomerRepository customerRepository,
        IEmailService emailService)
    {
        _customerRepository = customerRepository;
        _emailService = emailService;
    }

    public async Task<Order> CreateOrderAsync(int customerId, int productId)
    {
        var customer = await _customerRepository.GetByIdAsync(customerId);
        // Create order...
        await _emailService.SendOrderConfirmationAsync(customer.Email, order);
        return order;
    }
}

// Unit test with mocks
public class OrderServiceTests
{
    [Fact]
    public async Task CreateOrder_SendsEmailToCustomer()
    {
        // Arrange
        var mockRepository = new Mock<ICustomerRepository>();
        mockRepository
            .Setup(r => r.GetByIdAsync(It.IsAny<int>()))
            .ReturnsAsync(new Customer { Id = 1, Email = "test@example.com" });

        var mockEmailService = new Mock<IEmailService>();

        var orderService = new OrderService(
            mockRepository.Object,
            mockEmailService.Object);

        // Act
        await orderService.CreateOrderAsync(1, 1);

        // Assert
        mockEmailService.Verify(
            e => e.SendOrderConfirmationAsync("test@example.com", It.IsAny<Order>()),
            Times.Once);
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use constructor injection
public class MyService
{
    private readonly IDependency _dependency;

    public MyService(IDependency dependency)
    {
        _dependency = dependency ?? throw new ArgumentNullException(nameof(dependency));
    }
}

// 2. ✅ Choose appropriate lifetime
// - Transient: Stateless, lightweight
// - Scoped: DbContext, repositories, per-request state
// - Singleton: Configuration, caching, thread-safe services

// 3. ✅ Avoid captive dependencies
// Singleton can depend on Singleton
// Scoped can depend on Scoped or Singleton
// Transient can depend on anything
// ❌ Never: Singleton depending on Scoped/Transient

// 4. ✅ Use interfaces for abstraction
builder.Services.AddScoped<IMyService, MyService>();

// 5. ✅ Use ILogger<T> for logging
public class MyService
{
    private readonly ILogger<MyService> _logger;

    public MyService(ILogger<MyService> logger)
    {
        _logger = logger;
    }
}

// 6. ✅ Use Options pattern for configuration
builder.Services.Configure<MySettings>(configuration.GetSection("MySettings"));

// 7. ❌ Avoid service locator pattern
// Don't inject IServiceProvider unless absolutely necessary

// 8. ✅ Register services in Program.cs
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<IMyService, MyService>();

// 9. ✅ Use extension methods for related services
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddMyServices(this IServiceCollection services)
    {
        services.AddScoped<IService1, Service1>();
        services.AddScoped<IService2, Service2>();
        services.AddScoped<IService3, Service3>();
        return services;
    }
}

// Usage
builder.Services.AddMyServices();

// 10. ✅ Dispose resources properly
// Scoped and Transient services are disposed automatically
// Singleton services disposed when app shuts down
```

---

## Q224: How does configuration work in ASP.NET Core?

**Answer:**

ASP.NET Core uses a flexible configuration system that supports multiple sources with hierarchical overriding.

### Configuration Sources

```csharp
// ============================================
// DEFAULT CONFIGURATION SOURCES (in order)
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Configuration is built from multiple sources (later sources override earlier):
// 1. appsettings.json
// 2. appsettings.{Environment}.json (e.g., appsettings.Development.json)
// 3. User secrets (Development environment only)
// 4. Environment variables
// 5. Command-line arguments

// Access configuration
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var setting = builder.Configuration["MySetting"];
var nestedSetting = builder.Configuration["Section:SubSection:Key"];
```

---

### appsettings.json

```json
// ============================================
// appsettings.json
// ============================================
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=MyDb;Trusted_Connection=True;"
  },
  "AppSettings": {
    "ApplicationName": "My API",
    "MaxItemsPerPage": 50,
    "EnableCaching": true
  },
  "EmailSettings": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@example.com"
  },
  "AllowedHosts": "*"
}
```

```json
// ============================================
// appsettings.Development.json (overrides)
// ============================================
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug"  // Overrides Information
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyDb_Dev;Trusted_Connection=True;"
  },
  "EmailSettings": {
    "SmtpServer": "localhost",  // Override for dev
    "SmtpPort": 25
  }
}
```

---

### Reading Configuration

```csharp
// ============================================
// READING CONFIGURATION
// ============================================

public class MyController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public MyController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet("config")]
    public IActionResult GetConfig()
    {
        // 1. Simple value
        var appName = _configuration["AppSettings:ApplicationName"];

        // 2. Connection string
        var connStr = _configuration.GetConnectionString("DefaultConnection");

        // 3. Nested value
        var smtpServer = _configuration["EmailSettings:SmtpServer"];

        // 4. With default value
        var maxItems = _configuration.GetValue<int>("AppSettings:MaxItemsPerPage", 10);

        // 5. Check if exists
        var setting = _configuration.GetSection("AppSettings:SomeSetting");
        if (setting.Exists())
        {
            var value = setting.Value;
        }

        // 6. Get section
        var emailSection = _configuration.GetSection("EmailSettings");
        var server = emailSection["SmtpServer"];
        var port = emailSection.GetValue<int>("SmtpPort");

        return Ok(new
        {
            appName,
            connStr,
            smtpServer,
            maxItems
        });
    }
}
```

---

### Strongly-Typed Configuration (Options Pattern)

```csharp
// ============================================
// OPTIONS PATTERN (Recommended)
// ============================================

// 1. Define settings class
public class EmailSettings
{
    public const string SectionName = "EmailSettings";

    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; }
    public string ApiKey { get; set; }
    public bool EnableSsl { get; set; }
}

public class AppSettings
{
    public const string SectionName = "AppSettings";

    public string ApplicationName { get; set; }
    public int MaxItemsPerPage { get; set; }
    public bool EnableCaching { get; set; }
}

// 2. Register in Program.cs
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection(EmailSettings.SectionName));

builder.Services.Configure<AppSettings>(
    builder.Configuration.GetSection(AppSettings.SectionName));

// 3. Inject and use
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> settings,
        ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendEmailAsync(string to, string subject, string body)
    {
        _logger.LogInformation(
            "Sending email to {To} via {Server}:{Port}",
            to,
            _settings.SmtpServer,
            _settings.SmtpPort);

        using var client = new SmtpClient(_settings.SmtpServer, _settings.SmtpPort);
        // Send email...
    }
}
```

---

### Environment Variables

```bash
# ============================================
# ENVIRONMENT VARIABLES
# ============================================

# Set environment
ASPNETCORE_ENVIRONMENT=Production

# Override configuration
ConnectionStrings__DefaultConnection="Server=prod-server;..."
AppSettings__MaxItemsPerPage=100
EmailSettings__SmtpServer="smtp.production.com"

# Note: Use double underscore (__) for nested sections
# JSON: "Section:SubSection:Key"
# ENV:  Section__SubSection__Key
```

```csharp
// Access in code
var environment = builder.Environment.EnvironmentName;  // Production, Development, Staging

if (builder.Environment.IsDevelopment())
{
    // Development-specific configuration
}

if (builder.Environment.IsProduction())
{
    // Production-specific configuration
}
```

---

### User Secrets (Development Only)

```bash
# ============================================
# USER SECRETS
# ============================================

# Initialize user secrets
dotnet user-secrets init

# Set secret
dotnet user-secrets set "EmailSettings:ApiKey" "my-secret-key"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=..."

# List secrets
dotnet user-secrets list

# Remove secret
dotnet user-secrets remove "EmailSettings:ApiKey"

# Clear all secrets
dotnet user-secrets clear
```

```json
// Stored in: %APPDATA%\Microsoft\UserSecrets\{user_secrets_id}\secrets.json
{
  "EmailSettings:ApiKey": "my-secret-key",
  "ConnectionStrings:DefaultConnection": "Server=..."
}
```

```csharp
// Automatically loaded in Development
// Access like any other configuration
var apiKey = builder.Configuration["EmailSettings:ApiKey"];
```

---

### Command-Line Arguments

```bash
# ============================================
# COMMAND-LINE ARGUMENTS
# ============================================

# Run with command-line args (highest priority)
dotnet run --AppSettings:MaxItemsPerPage=200 --ConnectionStrings:DefaultConnection="Server=..."

# Or
dotnet MyApp.dll /AppSettings:MaxItemsPerPage=200
```

---

### Custom Configuration Sources

```csharp
// ============================================
// CUSTOM CONFIGURATION SOURCE
// ============================================

// 1. Database configuration source
public class DatabaseConfigurationSource : IConfigurationSource
{
    private readonly string _connectionString;

    public DatabaseConfigurationSource(string connectionString)
    {
        _connectionString = connectionString;
    }

    public IConfigurationProvider Build(IConfigurationBuilder builder)
    {
        return new DatabaseConfigurationProvider(_connectionString);
    }
}

public class DatabaseConfigurationProvider : ConfigurationProvider
{
    private readonly string _connectionString;

    public DatabaseConfigurationProvider(string connectionString)
    {
        _connectionString = connectionString;
    }

    public override void Load()
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT ConfigKey, ConfigValue FROM AppConfiguration";

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var key = reader.GetString(0);
            var value = reader.GetString(1);
            Data[key] = value;
        }
    }
}

// Extension method
public static class DatabaseConfigurationExtensions
{
    public static IConfigurationBuilder AddDatabaseConfiguration(
        this IConfigurationBuilder builder,
        string connectionString)
    {
        return builder.Add(new DatabaseConfigurationSource(connectionString));
    }
}

// Usage
var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddDatabaseConfiguration(
    builder.Configuration.GetConnectionString("DefaultConnection"));
```

---

### Configuration Validation

```csharp
// ============================================
// VALIDATE CONFIGURATION ON STARTUP
// ============================================

public class EmailSettings
{
    public string SmtpServer { get; set; }

    [Range(1, 65535)]
    public int SmtpPort { get; set; }

    [Required]
    [EmailAddress]
    public string FromEmail { get; set; }
}

// Register with validation
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("EmailSettings"))
    .ValidateDataAnnotations()  // Validate on startup
    .ValidateOnStart();         // Fail fast if invalid

// Custom validation
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("EmailSettings"))
    .Validate(settings =>
    {
        // Custom validation logic
        if (settings.SmtpPort < 1 || settings.SmtpPort > 65535)
            return false;

        if (string.IsNullOrEmpty(settings.SmtpServer))
            return false;

        return true;
    }, "Invalid email settings")
    .ValidateOnStart();
```

---

### Reloading Configuration

```csharp
// ============================================
// RELOAD CONFIGURATION ON CHANGE
// ============================================

// appsettings.json changes are automatically reloaded

// Monitor configuration changes
public class MyService
{
    private EmailSettings _settings;

    public MyService(IOptionsMonitor<EmailSettings> optionsMonitor)
    {
        _settings = optionsMonitor.CurrentValue;

        // Listen for changes
        optionsMonitor.OnChange(newSettings =>
        {
            _settings = newSettings;
            Console.WriteLine("Configuration changed!");
        });
    }
}

// Or use IOptionsSnapshot for per-request reload
public class MyController : ControllerBase
{
    private readonly IOptionsSnapshot<EmailSettings> _settings;

    public MyController(IOptionsSnapshot<EmailSettings> settings)
    {
        _settings = settings;
        // Reloaded with each request
    }

    [HttpGet]
    public IActionResult Get()
    {
        var current = _settings.Value;  // Latest config
        return Ok(current);
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use strongly-typed configuration
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// 2. ✅ Use different appsettings for each environment
// appsettings.json (base)
// appsettings.Development.json
// appsettings.Production.json
// appsettings.Staging.json

// 3. ✅ Never commit secrets to source control
// Use user secrets for development
// Use environment variables for production
// Use Azure Key Vault for sensitive data

// 4. ✅ Validate configuration on startup
builder.Services.AddOptions<EmailSettings>()
    .ValidateDataAnnotations()
    .ValidateOnStart();

// 5. ✅ Use const for section names
public class EmailSettings
{
    public const string SectionName = "EmailSettings";
}

builder.Configuration.GetSection(EmailSettings.SectionName);

// 6. ✅ Log configuration (without secrets)
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    var config = app.Services.GetRequiredService<IConfiguration>();
    foreach (var (key, value) in config.AsEnumerable())
    {
        if (!key.Contains("Password") && !key.Contains("Secret"))
        {
            app.Logger.LogInformation("{Key} = {Value}", key, value);
        }
    }
}

// 7. ✅ Use hierarchical configuration
{
  "Database": {
    "ConnectionString": "...",
    "Timeout": 30,
    "Retry": {
      "MaxRetries": 3,
      "Delay": 1000
    }
  }
}

// 8. ❌ Don't hardcode configuration values
var server = "smtp.gmail.com";  // ❌ Bad

var server = _configuration["EmailSettings:SmtpServer"];  // ✅ Good

// 9. ✅ Use IOptions<T> for scoped/transient services
// Use IOptionsSnapshot<T> for per-request reload
// Use IOptionsMonitor<T> for singleton services with change notifications

// 10. ✅ Organize settings by feature
{
  "Email": { ... },
  "Database": { ... },
  "Caching": { ... },
  "Logging": { ... }
}
```

---

## Q225: Explain Routing in ASP.NET Core.

**Answer:**

**Routing** is the mechanism that maps incoming HTTP requests to specific endpoints (controllers, actions, handlers).

### Attribute Routing (Recommended)

```csharp
// ============================================
// ATTRIBUTE ROUTING
// ============================================

[ApiController]
[Route("api/[controller]")]  // Template: api/Products
public class ProductsController : ControllerBase
{
    // GET: api/products
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(products);
    }

    // GET: api/products/5
    [HttpGet("{id}")]
    public IActionResult GetById(int id)
    {
        return Ok(product);
    }

    // GET: api/products/5/reviews
    [HttpGet("{id}/reviews")]
    public IActionResult GetReviews(int id)
    {
        return Ok(reviews);
    }

    // POST: api/products
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    // PUT: api/products/5
    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        return NoContent();
    }

    // DELETE: api/products/5
    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        return NoContent();
    }
}
```

### Route Templates

```csharp
// ============================================
// ROUTE TEMPLATE PATTERNS
// ============================================

// 1. Literal segments
[Route("api/products")]

// 2. Parameter segments
[Route("api/products/{id}")]  // Matches: api/products/5

// 3. Multiple parameters
[Route("api/products/{productId}/reviews/{reviewId}")]

// 4. Optional parameters
[Route("api/products/{id?}")]  // Matches: api/products OR api/products/5

// 5. Default values
[Route("api/products/{id=1}")]  // Defaults to 1 if not provided

// 6. Constraints
[Route("api/products/{id:int}")]  // id must be integer
[Route("api/products/{id:int:min(1)}")]  // id >= 1
[Route("api/products/{name:alpha}")]  // name must be alphabetic
[Route("api/products/{date:datetime}")]  // date must be valid datetime

// 7. Catch-all parameter
[Route("api/files/{*filepath}")]  // Matches: api/files/docs/file.txt

// 8. Controller and action tokens
[Route("api/[controller]/[action]")]  // Replaces tokens with actual names
```

### Route Constraints

```csharp
// ============================================
// ROUTE CONSTRAINTS
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // Integer constraint
    [HttpGet("{id:int}")]
    public IActionResult GetById(int id) { }

    // Min/Max constraints
    [HttpGet("{id:int:min(1):max(1000)}")]
    public IActionResult GetByIdInRange(int id) { }

    // Length constraint
    [HttpGet("{name:minlength(3):maxlength(50)}")]
    public IActionResult GetByName(string name) { }

    // Regex constraint
    [HttpGet("{code:regex(^[A-Z]{{3}}-[0-9]{{4}}$)}")]  // Matches: ABC-1234
    public IActionResult GetByCode(string code) { }

    // DateTime constraint
    [HttpGet("orders/{date:datetime}")]
    public IActionResult GetOrdersByDate(DateTime date) { }

    // Guid constraint
    [HttpGet("users/{userId:guid}")]
    public IActionResult GetUser(Guid userId) { }

    // Alpha constraint (letters only)
    [HttpGet("category/{name:alpha}")]
    public IActionResult GetCategory(string name) { }

    // Composite constraints
    [HttpGet("{id:int:range(1,100)}")]
    public IActionResult GetInRange(int id) { }
}

// Common constraints:
// :int, :long, :decimal, :double, :float
// :bool
// :datetime
// :guid
// :alpha (letters only)
// :min(value), :max(value), :range(min,max)
// :minlength(value), :maxlength(value), :length(value)
// :regex(expression)
```

### Multiple Routes

```csharp
// ============================================
// MULTIPLE ROUTES PER ACTION
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // Multiple routes to same action
    [HttpGet("{id}")]
    [HttpGet("by-id/{id}")]
    [HttpGet("details/{id}")]
    public IActionResult GetById(int id)
    {
        return Ok(product);
    }

    // Different HTTP methods, same route
    [HttpGet("search")]
    public IActionResult Search([FromQuery] string term)
    {
        return Ok(results);
    }

    [HttpPost("search")]
    public IActionResult AdvancedSearch([FromBody] SearchCriteria criteria)
    {
        return Ok(results);
    }
}
```

### Route Groups (Minimal APIs)

```csharp
// ============================================
// MINIMAL API ROUTING
// ============================================

var app = builder.Build();

// Map individual endpoints
app.MapGet("/", () => "Hello World!");
app.MapGet("/products", () => products);
app.MapGet("/products/{id}", (int id) => products.FirstOrDefault(p => p.Id == id));
app.MapPost("/products", (Product product) => { /* create */ });

// Route groups
var productsGroup = app.MapGroup("/api/products");

productsGroup.MapGet("/", GetAllProducts);
productsGroup.MapGet("/{id}", GetProductById);
productsGroup.MapPost("/", CreateProduct);
productsGroup.MapPut("/{id}", UpdateProduct);
productsGroup.MapDelete("/{id}", DeleteProduct);

// With filters/middleware
var apiGroup = app.MapGroup("/api")
    .RequireAuthorization()
    .WithOpenApi();

apiGroup.MapGet("/products", GetProducts);
apiGroup.MapGet("/orders", GetOrders);
```

### Named Routes

```csharp
// ============================================
// NAMED ROUTES
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpGet("{id}", Name = "GetProduct")]
    public IActionResult GetById(int id)
    {
        return Ok(product);
    }

    [HttpPost]
    public IActionResult Create(Product product)
    {
        // Use named route to generate URL
        return CreatedAtRoute("GetProduct", new { id = product.Id }, product);
    }
}

// Generate URLs from named routes
public class LinkService
{
    private readonly LinkGenerator _linkGenerator;

    public LinkService(LinkGenerator linkGenerator)
    {
        _linkGenerator = linkGenerator;
    }

    public string GetProductUrl(int id)
    {
        return _linkGenerator.GetPathByName("GetProduct", new { id });
        // Returns: "/api/products/5"
    }

    public string GetAbsoluteUrl(HttpContext context, int id)
    {
        return _linkGenerator.GetUriByName(context, "GetProduct", new { id });
        // Returns: "https://example.com/api/products/5"
    }
}
```

### Route Ordering

```csharp
// ============================================
// ROUTE ORDERING
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // More specific routes should come first

    // 1. Literal route (highest priority)
    [HttpGet("featured")]
    public IActionResult GetFeatured() { }

    // 2. Constrained route
    [HttpGet("{id:int}")]
    public IActionResult GetById(int id) { }

    // 3. Generic route (lowest priority)
    [HttpGet("{slug}")]
    public IActionResult GetBySlug(string slug) { }

    // Order attribute (lower = higher priority)
    [HttpGet("special", Order = 1)]
    public IActionResult GetSpecial() { }

    [HttpGet("{anything}", Order = 2)]
    public IActionResult GetAnything(string anything) { }
}
```

### Query String and Route Data

```csharp
// ============================================
// QUERY STRING vs ROUTE DATA
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // Route parameter: /api/products/5
    [HttpGet("{id}")]
    public IActionResult GetById(int id)
    {
        // id from route
        return Ok(product);
    }

    // Query string: /api/products/search?term=laptop&minPrice=100
    [HttpGet("search")]
    public IActionResult Search(
        [FromQuery] string term,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice)
    {
        return Ok(results);
    }

    // Complex query object
    [HttpGet("filter")]
    public IActionResult Filter([FromQuery] ProductFilter filter)
    {
        return Ok(results);
    }

    // Mixed: route + query
    // /api/products/5/reviews?page=1&pageSize=10
    [HttpGet("{id}/reviews")]
    public IActionResult GetReviews(
        int id,  // From route
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        return Ok(reviews);
    }
}

public class ProductFilter
{
    public string? Category { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? SortBy { get; set; }
}
```

### Best Practices

```csharp
// 1. ✅ Use attribute routing (not conventional)
[Route("api/[controller]")]

// 2. ✅ Use plural nouns for resources
[Route("api/products")]  // Good
[Route("api/product")]   // Bad

// 3. ✅ Use constraints to disambiguate
[HttpGet("{id:int}")]     // Matches: /api/products/5
[HttpGet("{slug:alpha}")]  // Matches: /api/products/laptop

// 4. ✅ Use appropriate HTTP verbs
[HttpGet]     // Retrieve
[HttpPost]    // Create
[HttpPut]     // Full update
[HttpPatch]   // Partial update
[HttpDelete]  // Delete

// 5. ✅ Use versioning in routes
[Route("api/v1/products")]
[Route("api/v2/products")]

// 6. ✅ Return appropriate status codes
return Ok(data);              // 200
return Created(uri, data);    // 201
return NoContent();           // 204
return BadRequest();          // 400
return NotFound();            // 404

// 7. ❌ Don't use verbs in URLs
[Route("api/products/get")]      // Bad
[HttpGet("api/products")]        // Good

[Route("api/products/create")]   // Bad
[HttpPost("api/products")]       // Good

// 8. ✅ Use hierarchical routes for relationships
[HttpGet("customers/{customerId}/orders")]
[HttpGet("orders/{orderId}/items")]

// 9. ✅ Use query parameters for filtering/paging
[HttpGet("products?category=electronics&page=1")]

// 10. ✅ Use action names for non-CRUD operations
[HttpPost("products/{id}/activate")]
[HttpPost("orders/{id}/cancel")]
```

---

## Q226: What is Model Binding and Validation in ASP.NET Core?

**Answer:**

**Model Binding** automatically maps HTTP request data to action method parameters. **Validation** ensures the data meets specified rules.

### Model Binding Sources

```csharp
// ============================================
// MODEL BINDING SOURCES
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // 1. [FromRoute] - From URL path
    [HttpGet("{id}")]
    public IActionResult Get([FromRoute] int id) { }

    // 2. [FromQuery] - From query string
    [HttpGet("search")]
    public IActionResult Search([FromQuery] string term) { }

    // 3. [FromBody] - From request body (JSON/XML)
    [HttpPost]
    public IActionResult Create([FromBody] Product product) { }

    // 4. [FromForm] - From form data
    [HttpPost("upload")]
    public IActionResult Upload([FromForm] IFormFile file) { }

    // 5. [FromHeader] - From HTTP headers
    [HttpGet]
    public IActionResult GetWithAuth([FromHeader(Name = "Authorization")] string token) { }

    // 6. [FromServices] - From DI container
    [HttpGet("stats")]
    public IActionResult GetStats([FromServices] IProductService service) { }

    // Multiple sources
    [HttpPut("{id}")]
    public IActionResult Update(
        [FromRoute] int id,
        [FromBody] Product product,
        [FromHeader(Name = "X-Request-Id")] string requestId)
    {
        return NoContent();
    }
}
```

### Data Annotations Validation

```csharp
// ============================================
// DATA ANNOTATIONS
// ============================================

public class Product
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Product name is required")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 100 characters")]
    public string Name { get; set; }

    [Required]
    [StringLength(500)]
    public string Description { get; set; }

    [Required]
    [Range(0.01, 999999.99, ErrorMessage = "Price must be between 0.01 and 999999.99")]
    public decimal Price { get; set; }

    [Range(0, int.MaxValue)]
    public int Stock { get; set; }

    [Required]
    [RegularExpression(@"^[A-Z]{3}-\d{4}$", ErrorMessage = "SKU must be in format XXX-0000")]
    public string SKU { get; set; }

    [EmailAddress(ErrorMessage = "Invalid email address")]
    public string? ContactEmail { get; set; }

    [Url(ErrorMessage = "Invalid URL")]
    public string? Website { get; set; }

    [Phone(ErrorMessage = "Invalid phone number")]
    public string? Phone { get; set; }

    [CreditCard]
    public string? CreditCardNumber { get; set; }

    [Compare(nameof(Price), ErrorMessage = "Discount price must match price")]
    public decimal DiscountPrice { get; set; }

    [DataType(DataType.Date)]
    public DateTime CreatedDate { get; set; }
}

// Controller automatically validates
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        // ModelState automatically populated with validation errors
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // Product is valid
        return Ok(product);
    }
}
```

### Custom Validation Attributes

```csharp
// ============================================
// CUSTOM VALIDATION ATTRIBUTE
// ============================================

public class FutureDateAttribute : ValidationAttribute
{
    protected override ValidationResult IsValid(object value, ValidationContext validationContext)
    {
        if (value is DateTime date)
        {
            if (date <= DateTime.Now)
            {
                return new ValidationResult("Date must be in the future");
            }
        }

        return ValidationResult.Success;
    }
}

// Usage
public class Appointment
{
    [Required]
    [FutureDate]
    public DateTime ScheduledDate { get; set; }
}

// Complex custom validation
public class ValidProductAttribute : ValidationAttribute
{
    protected override ValidationResult IsValid(object value, ValidationContext validationContext)
    {
        var product = (Product)value;

        if (product.Price < 0)
        {
            return new ValidationResult("Price cannot be negative", new[] { nameof(Product.Price) });
        }

        if (product.Stock < 0)
        {
            return new ValidationResult("Stock cannot be negative", new[] { nameof(Product.Stock) });
        }

        if (product.DiscountPrice > product.Price)
        {
            return new ValidationResult("Discount price cannot exceed regular price");
        }

        return ValidationResult.Success;
    }
}

[ValidProduct]
public class Product
{
    // Properties...
}
```

### IValidatableObject

```csharp
// ============================================
// IVALIDATABLEOBJECT
// ============================================

public class Product : IValidatableObject
{
    [Required]
    public string Name { get; set; }

    [Required]
    [Range(0.01, 999999.99)]
    public decimal Price { get; set; }

    public decimal? DiscountPrice { get; set; }

    public DateTime? SaleStartDate { get; set; }
    public DateTime? SaleEndDate { get; set; }

    // Custom validation logic
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // Validate discount price
        if (DiscountPrice.HasValue && DiscountPrice > Price)
        {
            yield return new ValidationResult(
                "Discount price cannot exceed regular price",
                new[] { nameof(DiscountPrice) });
        }

        // Validate sale dates
        if (SaleStartDate.HasValue && SaleEndDate.HasValue)
        {
            if (SaleEndDate <= SaleStartDate)
            {
                yield return new ValidationResult(
                    "Sale end date must be after start date",
                    new[] { nameof(SaleEndDate) });
            }
        }

        // Require discount price if sale dates are set
        if (SaleStartDate.HasValue && !DiscountPrice.HasValue)
        {
            yield return new ValidationResult(
                "Discount price is required when sale dates are set",
                new[] { nameof(DiscountPrice) });
        }
    }
}
```

### FluentValidation

```csharp
// ============================================
// FLUENTVALIDATION (Third-party library)
// ============================================

// Install: FluentValidation.AspNetCore

public class ProductValidator : AbstractValidator<Product>
{
    public ProductValidator()
    {
        RuleFor(p => p.Name)
            .NotEmpty().WithMessage("Product name is required")
            .Length(3, 100).WithMessage("Name must be between 3 and 100 characters");

        RuleFor(p => p.Description)
            .NotEmpty()
            .MaximumLength(500);

        RuleFor(p => p.Price)
            .GreaterThan(0).WithMessage("Price must be greater than 0")
            .LessThan(1000000).WithMessage("Price must be less than 1000000");

        RuleFor(p => p.SKU)
            .NotEmpty()
            .Matches(@"^[A-Z]{3}-\d{4}$").WithMessage("SKU must be in format XXX-0000");

        RuleFor(p => p.DiscountPrice)
            .LessThanOrEqualTo(p => p.Price)
            .When(p => p.DiscountPrice.HasValue)
            .WithMessage("Discount price cannot exceed regular price");

        RuleFor(p => p.ContactEmail)
            .EmailAddress()
            .When(p => !string.IsNullOrEmpty(p.ContactEmail));

        // Custom validation
        RuleFor(p => p)
            .Must(BeValidProduct)
            .WithMessage("Product validation failed");
    }

    private bool BeValidProduct(Product product)
    {
        // Complex validation logic
        return product.Price > 0 && product.Stock >= 0;
    }
}

// Register in Program.cs
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<ProductValidator>();

// Controller (validation automatic)
[HttpPost]
public IActionResult Create([FromBody] Product product)
{
    // FluentValidation runs automatically
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    return Ok(product);
}
```

### Manual Validation

```csharp
// ============================================
// MANUAL VALIDATION
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        // Manual validation
        if (string.IsNullOrWhiteSpace(product.Name))
        {
            ModelState.AddModelError(nameof(product.Name), "Name is required");
        }

        if (product.Price <= 0)
        {
            ModelState.AddModelError(nameof(product.Price), "Price must be greater than 0");
        }

        // Check if valid
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        return Ok(product);
    }

    // Manual validation with TryValidateModel
    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        // Manually trigger validation
        if (!TryValidateModel(product))
        {
            return BadRequest(ModelState);
        }

        return NoContent();
    }
}
```

### Custom Error Responses

```csharp
// ============================================
// CUSTOM VALIDATION ERROR RESPONSE
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        if (!ModelState.IsValid)
        {
            // Custom error format
            var errors = ModelState
                .Where(x => x.Value.Errors.Any())
                .Select(x => new
                {
                    Field = x.Key,
                    Errors = x.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                })
                .ToArray();

            return BadRequest(new
            {
                Message = "Validation failed",
                Errors = errors
            });
        }

        return Ok(product);
    }
}

// Or configure globally
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(x => x.Value.Errors.Any())
            .Select(x => new
            {
                Field = x.Key,
                Errors = x.Value.Errors.Select(e => e.ErrorMessage)
            });

        return new BadRequestObjectResult(new
        {
            Message = "Validation failed",
            Errors = errors
        });
    };
});
```

### Complex Binding Scenarios

```csharp
// ============================================
// COMPLEX BINDING
// ============================================

// Binding collections
[HttpPost("bulk")]
public IActionResult CreateMultiple([FromBody] List<Product> products)
{
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    return Ok(products);
}

// Binding nested objects
public class Order
{
    public int OrderId { get; set; }

    [Required]
    public Customer Customer { get; set; }

    [Required]
    [MinLength(1, ErrorMessage = "At least one item is required")]
    public List<OrderItem> Items { get; set; }
}

// File upload with model
public class ProductUploadModel
{
    [Required]
    public string Name { get; set; }

    [Required]
    public IFormFile Image { get; set; }

    public List<IFormFile>? AdditionalImages { get; set; }
}

[HttpPost("upload")]
public async Task<IActionResult> Upload([FromForm] ProductUploadModel model)
{
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    // Save file
    using var stream = new FileStream(path, FileMode.Create);
    await model.Image.CopyToAsync(stream);

    return Ok();
}
```

### Best Practices

```csharp
// 1. ✅ Use [ApiController] for automatic validation
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase { }

// 2. ✅ Always validate input
if (!ModelState.IsValid)
{
    return BadRequest(ModelState);
}

// 3. ✅ Use appropriate validation attributes
[Required, StringLength(100), EmailAddress]

// 4. ✅ Provide meaningful error messages
[Required(ErrorMessage = "Product name is required")]
[Range(0.01, 999999.99, ErrorMessage = "Price must be between {1} and {2}")]

// 5. ✅ Use IValidatableObject for complex validation
public class Product : IValidatableObject
{
    public IEnumerable<ValidationResult> Validate(ValidationContext ctx) { }
}

// 6. ✅ Consider FluentValidation for complex scenarios
// More readable, testable, and powerful

// 7. ✅ Validate collections
[MinLength(1)]
public List<OrderItem> Items { get; set; }

// 8. ❌ Don't trust client-side validation alone
// Always validate on server

// 9. ✅ Return consistent error format
return BadRequest(new { message = "...", errors = [...] });

// 10. ✅ Log validation failures for monitoring
_logger.LogWarning("Validation failed for {Model}", model);
```

---

## Q227: Explain Authentication and Authorization in ASP.NET Core.

**Answer:**

**Authentication** identifies who the user is. **Authorization** determines what the user can access.

### Authentication vs Authorization

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Authentication │ --> │  Authorization   │ --> │  Access Resource│
│  (Who are you?) │     │ (What can you do?)     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Cookie Authentication

```csharp
// ============================================
// COOKIE AUTHENTICATION
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add authentication services
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(1);
        options.SlidingExpiration = true;  // Renew cookie on activity
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;  // HTTPS only
        options.Cookie.SameSite = SameSiteMode.Strict;
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers();

var app = builder.Build();

// Add authentication middleware (must be after routing, before authorization)
app.UseRouting();
app.UseAuthentication();  // Who are you?
app.UseAuthorization();   // What can you do?
app.MapControllers();

app.Run();

// Login action
[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        // Validate credentials (check against database)
        var user = await ValidateUser(model.Username, model.Password);

        if (user == null)
        {
            return Unauthorized(new { message = "Invalid credentials" });
        }

        // Create claims
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role)
        };

        // Create identity
        var claimsIdentity = new ClaimsIdentity(
            claims,
            CookieAuthenticationDefaults.AuthenticationScheme);

        // Create principal
        var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);

        // Sign in
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            claimsPrincipal,
            new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = DateTimeOffset.UtcNow.AddHours(1)
            });

        return Ok(new { message = "Login successful" });
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return Ok(new { message = "Logout successful" });
    }
}
```

---

### Role-Based Authorization

```csharp
// ============================================
// ROLE-BASED AUTHORIZATION
// ============================================

// Protect entire controller
[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    [HttpGet("users")]
    public IActionResult GetUsers()
    {
        // Only admins can access
        return Ok(users);
    }
}

// Protect specific actions
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // Anyone can view
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(products);
    }

    // Must be authenticated
    [Authorize]
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        return Ok(product);
    }

    // Only admins can delete
    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        return NoContent();
    }

    // Multiple roles
    [Authorize(Roles = "Admin,Manager")]
    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        return NoContent();
    }
}

// Add roles when creating claims
var claims = new List<Claim>
{
    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
    new Claim(ClaimTypes.Name, user.Username),
    new Claim(ClaimTypes.Role, "Admin"),
    new Claim(ClaimTypes.Role, "Manager")  // User can have multiple roles
};
```

---

### Claims-Based Authorization

```csharp
// ============================================
// CLAIMS-BASED AUTHORIZATION
// ============================================

// Add claims when authenticating
var claims = new List<Claim>
{
    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
    new Claim(ClaimTypes.Name, user.Username),
    new Claim(ClaimTypes.Email, user.Email),
    new Claim(ClaimTypes.Role, "User"),
    new Claim("Department", "Sales"),
    new Claim("EmployeeId", "12345"),
    new Claim("Region", "WestCoast"),
    new Claim("SecurityLevel", "5")
};

// Authorize by claim
[Authorize(Policy = "MustBeSalesDepartment")]
[HttpGet("sales-report")]
public IActionResult GetSalesReport()
{
    return Ok(report);
}

// Configure policies in Program.cs
builder.Services.AddAuthorization(options =>
{
    // Simple claim requirement
    options.AddPolicy("MustBeSalesDepartment", policy =>
        policy.RequireClaim("Department", "Sales"));

    // Multiple claims
    options.AddPolicy("SeniorSalesManager", policy =>
    {
        policy.RequireClaim("Department", "Sales");
        policy.RequireClaim("SecurityLevel", "8", "9", "10");
        policy.RequireRole("Manager");
    });

    // Custom requirements
    options.AddPolicy("CanEditProducts", policy =>
        policy.Requirements.Add(new CanEditProductsRequirement()));
});

// Access claims in controller
[Authorize]
[HttpGet("my-info")]
public IActionResult GetMyInfo()
{
    var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
    var username = User.FindFirstValue(ClaimTypes.Name);
    var email = User.FindFirstValue(ClaimTypes.Email);
    var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value);
    var department = User.FindFirstValue("Department");

    return Ok(new
    {
        userId,
        username,
        email,
        roles,
        department
    });
}

// Check claims programmatically
if (User.HasClaim("Department", "Sales"))
{
    // User is in sales department
}

if (User.IsInRole("Admin"))
{
    // User is admin
}
```

---

### Policy-Based Authorization

```csharp
// ============================================
// POLICY-BASED AUTHORIZATION
// ============================================

// Custom requirement
public class MinimumAgeRequirement : IAuthorizationRequirement
{
    public int MinimumAge { get; }

    public MinimumAgeRequirement(int minimumAge)
    {
        MinimumAge = minimumAge;
    }
}

// Custom handler
public class MinimumAgeHandler : AuthorizationHandler<MinimumAgeRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        MinimumAgeRequirement requirement)
    {
        var dateOfBirthClaim = context.User.FindFirst(c => c.Type == "DateOfBirth");

        if (dateOfBirthClaim == null)
        {
            return Task.CompletedTask;  // Requirement not met
        }

        var dateOfBirth = DateTime.Parse(dateOfBirthClaim.Value);
        var age = DateTime.Today.Year - dateOfBirth.Year;

        if (dateOfBirth > DateTime.Today.AddYears(-age))
        {
            age--;
        }

        if (age >= requirement.MinimumAge)
        {
            context.Succeed(requirement);  // Requirement met
        }

        return Task.CompletedTask;
    }
}

// Register in Program.cs
builder.Services.AddSingleton<IAuthorizationHandler, MinimumAgeHandler>();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AtLeast18", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));

    options.AddPolicy("AtLeast21", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(21)));
});

// Use in controller
[Authorize(Policy = "AtLeast18")]
[HttpGet("adult-content")]
public IActionResult GetAdultContent()
{
    return Ok(content);
}

[Authorize(Policy = "AtLeast21")]
[HttpPost("purchase-alcohol")]
public IActionResult PurchaseAlcohol()
{
    return Ok();
}
```

---

### Resource-Based Authorization

```csharp
// ============================================
// RESOURCE-BASED AUTHORIZATION
// ============================================

// Requirement
public class SameAuthorRequirement : IAuthorizationRequirement { }

// Handler
public class DocumentAuthorizationHandler
    : AuthorizationHandler<SameAuthorRequirement, Document>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        SameAuthorRequirement requirement,
        Document resource)
    {
        var userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);

        // Owner can access
        if (resource.AuthorId.ToString() == userId)
        {
            context.Succeed(requirement);
        }

        // Admin can access
        if (context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}

// Register
builder.Services.AddSingleton<IAuthorizationHandler, DocumentAuthorizationHandler>();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanEditDocument", policy =>
        policy.Requirements.Add(new SameAuthorRequirement()));
});

// Controller
[ApiController]
[Route("api/documents")]
public class DocumentsController : ControllerBase
{
    private readonly IAuthorizationService _authorizationService;
    private readonly IDocumentRepository _repository;

    public DocumentsController(
        IAuthorizationService authorizationService,
        IDocumentRepository repository)
    {
        _authorizationService = authorizationService;
        _repository = repository;
    }

    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Document model)
    {
        var document = await _repository.GetByIdAsync(id);

        if (document == null)
        {
            return NotFound();
        }

        // Resource-based authorization
        var authResult = await _authorizationService.AuthorizeAsync(
            User,
            document,
            "CanEditDocument");

        if (!authResult.Succeeded)
        {
            return Forbid();  // 403 Forbidden
        }

        // User is authorized to edit
        document.Title = model.Title;
        document.Content = model.Content;
        await _repository.UpdateAsync(document);

        return NoContent();
    }
}
```

---

### Multiple Authentication Schemes

```csharp
// ============================================
// MULTIPLE AUTHENTICATION SCHEMES
// ============================================

// Program.cs
builder.Services.AddAuthentication(options =>
{
    // Default scheme for web app
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
})
.AddJwtBearer("Bearer", options =>
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
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
});

// Use specific scheme
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    // Requires JWT token
}

// Use either scheme
[Authorize(AuthenticationSchemes = "Cookie,Bearer")]
[HttpGet("secure")]
public IActionResult GetSecure()
{
    // Accepts cookie OR JWT
    return Ok();
}
```

---

### Authorization Filters

```csharp
// ============================================
// CUSTOM AUTHORIZATION FILTER
// ============================================

public class CustomAuthorizationFilter : IAsyncAuthorizationFilter
{
    private readonly ILogger<CustomAuthorizationFilter> _logger;

    public CustomAuthorizationFilter(ILogger<CustomAuthorizationFilter> logger)
    {
        _logger = logger;
    }

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;

        if (!user.Identity.IsAuthenticated)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        // Custom authorization logic
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        var hasAccess = await CheckUserAccess(userId);

        if (!hasAccess)
        {
            _logger.LogWarning("User {UserId} denied access", userId);
            context.Result = new ForbidResult();
        }
    }

    private async Task<bool> CheckUserAccess(string userId)
    {
        // Check database, cache, etc.
        return true;
    }
}

// Register globally
builder.Services.AddControllers(options =>
{
    options.Filters.Add<CustomAuthorizationFilter>();
});

// Or use on specific controller/action
[ServiceFilter(typeof(CustomAuthorizationFilter))]
public class SecureController : ControllerBase { }
```

---

### Best Practices

```csharp
// 1. ✅ Always use HTTPS for authentication
builder.Services.AddHttpsRedirection(options =>
{
    options.HttpsPort = 443;
});

// 2. ✅ Use secure cookie settings
options.Cookie.HttpOnly = true;
options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
options.Cookie.SameSite = SameSiteMode.Strict;

// 3. ✅ Implement proper password hashing
// Use BCrypt, PBKDF2, or Argon2
public class PasswordService
{
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }

    public bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }
}

// 4. ✅ Use policy-based authorization for complex rules
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAdminRole", policy => policy.RequireRole("Admin"));
});

// 5. ✅ Return appropriate status codes
return Unauthorized();  // 401 - Not authenticated
return Forbid();        // 403 - Authenticated but not authorized

// 6. ✅ Validate tokens properly
options.TokenValidationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    ClockSkew = TimeSpan.Zero  // No tolerance for expired tokens
};

// 7. ✅ Log authentication failures
_logger.LogWarning("Failed login attempt for user {Username}", username);

// 8. ❌ Never store passwords in plain text
// ❌ Never log sensitive data (passwords, tokens)

// 9. ✅ Implement rate limiting for login attempts
// 10. ✅ Use claims for fine-grained authorization
```

---

## Q228: Explain JWT (JSON Web Token) Authentication in ASP.NET Core.

**Answer:**

**JWT (JSON Web Token)** is a compact, URL-safe token format for stateless authentication.

### JWT Structure

```
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

┌─────────────────────────────────────────────────────┐
│ Header (Algorithm & Type)                            │
│ {                                                    │
│   "alg": "HS256",                                    │
│   "typ": "JWT"                                       │
│ }                                                    │
├─────────────────────────────────────────────────────┤
│ Payload (Claims)                                     │
│ {                                                    │
│   "sub": "1234567890",                               │
│   "name": "John Doe",                                │
│   "iat": 1516239022,                                 │
│   "exp": 1516242622                                  │
│ }                                                    │
├─────────────────────────────────────────────────────┤
│ Signature (Verification)                             │
│ HMACSHA256(                                          │
│   base64UrlEncode(header) + "." +                    │
│   base64UrlEncode(payload),                          │
│   secret                                             │
│ )                                                    │
└─────────────────────────────────────────────────────┘
```

### JWT Configuration

```csharp
// ============================================
// JWT AUTHENTICATION SETUP
// ============================================

// appsettings.json
{
  "Jwt": {
    "Key": "your-256-bit-secret-key-here-make-it-long-and-secure",
    "Issuer": "https://yourapp.com",
    "Audience": "https://yourapp.com",
    "ExpiryMinutes": 60,
    "RefreshTokenExpiryDays": 7
  }
}

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add JWT authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = true;  // Require HTTPS
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"])),
        ClockSkew = TimeSpan.Zero  // No tolerance for expired tokens
    };

    // Events for logging and debugging
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"Authentication failed: {context.Exception.Message}");
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            Console.WriteLine($"Token validated for {context.Principal.Identity.Name}");
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

---

### JWT Token Generation

```csharp
// ============================================
// JWT TOKEN SERVICE
// ============================================

public interface IJwtService
{
    string GenerateToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal GetPrincipalFromExpiredToken(string token);
}

public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateToken(User user)
    {
        var securityKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));

        var credentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256);

        // Create claims
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Name, user.Username),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("UserId", user.Id.ToString()),
            new Claim("Username", user.Username)
        };

        // Create token
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(
                Convert.ToDouble(_configuration["Jwt:ExpiryMinutes"])),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    public ClaimsPrincipal GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = _configuration["Jwt:Issuer"],
            ValidAudience = _configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])),
            ValidateLifetime = false  // Don't validate expiry
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(
            token,
            tokenValidationParameters,
            out SecurityToken securityToken);

        var jwtSecurityToken = securityToken as JwtSecurityToken;

        if (jwtSecurityToken == null ||
            !jwtSecurityToken.Header.Alg.Equals(
                SecurityAlgorithms.HmacSha256,
                StringComparison.InvariantCultureIgnoreCase))
        {
            throw new SecurityTokenException("Invalid token");
        }

        return principal;
    }
}

// Register service
builder.Services.AddScoped<IJwtService, JwtService>();
```

---

### Login and Token Generation

```csharp
// ============================================
// AUTHENTICATION CONTROLLER
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IJwtService _jwtService;
    private readonly IUserRepository _userRepository;
    private readonly IPasswordService _passwordService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IJwtService jwtService,
        IUserRepository userRepository,
        IPasswordService passwordService,
        ILogger<AuthController> logger)
    {
        _jwtService = jwtService;
        _userRepository = userRepository;
        _passwordService = passwordService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        // Validate credentials
        var user = await _userRepository.GetByUsernameAsync(model.Username);

        if (user == null || !_passwordService.VerifyPassword(model.Password, user.PasswordHash))
        {
            _logger.LogWarning("Failed login attempt for username: {Username}", model.Username);
            return Unauthorized(new { message = "Invalid username or password" });
        }

        // Generate tokens
        var accessToken = _jwtService.GenerateToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken();

        // Save refresh token to database
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
        await _userRepository.UpdateAsync(user);

        _logger.LogInformation("User {Username} logged in successfully", model.Username);

        return Ok(new
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = 3600,  // 1 hour in seconds
            TokenType = "Bearer",
            User = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.Role
            }
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenDto model)
    {
        // Get principal from expired access token
        ClaimsPrincipal principal;
        try
        {
            principal = _jwtService.GetPrincipalFromExpiredToken(model.AccessToken);
        }
        catch
        {
            return BadRequest(new { message = "Invalid access token" });
        }

        var username = principal.Identity.Name;
        var user = await _userRepository.GetByUsernameAsync(username);

        if (user == null ||
            user.RefreshToken != model.RefreshToken ||
            user.RefreshTokenExpiryTime <= DateTime.UtcNow)
        {
            return BadRequest(new { message = "Invalid refresh token" });
        }

        // Generate new tokens
        var newAccessToken = _jwtService.GenerateToken(user);
        var newRefreshToken = _jwtService.GenerateRefreshToken();

        // Update refresh token in database
        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
        await _userRepository.UpdateAsync(user);

        return Ok(new
        {
            AccessToken = newAccessToken,
            RefreshToken = newRefreshToken,
            ExpiresIn = 3600,
            TokenType = "Bearer"
        });
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        var username = User.Identity.Name;
        var user = await _userRepository.GetByUsernameAsync(username);

        if (user != null)
        {
            // Invalidate refresh token
            user.RefreshToken = null;
            user.RefreshTokenExpiryTime = null;
            await _userRepository.UpdateAsync(user);
        }

        return Ok(new { message = "Logged out successfully" });
    }

    [Authorize]
    [HttpGet("me")]
    public IActionResult GetCurrentUser()
    {
        var userId = User.FindFirstValue("UserId");
        var username = User.FindFirstValue(ClaimTypes.Name);
        var email = User.FindFirstValue(ClaimTypes.Email);
        var role = User.FindFirstValue(ClaimTypes.Role);

        return Ok(new
        {
            UserId = userId,
            Username = username,
            Email = email,
            Role = role
        });
    }
}

public class LoginDto
{
    [Required]
    public string Username { get; set; }

    [Required]
    public string Password { get; set; }
}

public class RefreshTokenDto
{
    [Required]
    public string AccessToken { get; set; }

    [Required]
    public string RefreshToken { get; set; }
}
```

---

### Using JWT in Protected Endpoints

```csharp
// ============================================
// PROTECTED ENDPOINTS
// ============================================

[Authorize]  // Requires valid JWT token
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll()
    {
        // Access user claims
        var userId = User.FindFirstValue("UserId");
        var username = User.FindFirstValue(ClaimTypes.Name);

        return Ok(products);
    }

    [Authorize(Roles = "Admin")]  // Requires Admin role
    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        return NoContent();
    }

    [Authorize(Policy = "RequireManagerRole")]  // Custom policy
    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        return NoContent();
    }
}

// Client sends JWT in Authorization header:
// Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### Token Blacklisting

```csharp
// ============================================
// TOKEN BLACKLIST (for logout)
// ============================================

public interface ITokenBlacklistService
{
    Task AddToBlacklist(string token);
    Task<bool> IsBlacklisted(string token);
}

public class TokenBlacklistService : ITokenBlacklistService
{
    private readonly IDistributedCache _cache;

    public TokenBlacklistService(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task AddToBlacklist(string token)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var jwtToken = tokenHandler.ReadJwtToken(token);
        var expiry = jwtToken.ValidTo;

        var options = new DistributedCacheEntryOptions
        {
            AbsoluteExpiration = expiry
        };

        await _cache.SetStringAsync($"blacklist:{token}", "true", options);
    }

    public async Task<bool> IsBlacklisted(string token)
    {
        var result = await _cache.GetStringAsync($"blacklist:{token}");
        return result != null;
    }
}

// Middleware to check blacklist
public class TokenBlacklistMiddleware
{
    private readonly RequestDelegate _next;

    public TokenBlacklistMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        ITokenBlacklistService blacklistService)
    {
        var token = context.Request.Headers["Authorization"]
            .ToString()
            .Replace("Bearer ", "");

        if (!string.IsNullOrEmpty(token) && await blacklistService.IsBlacklisted(token))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Token has been revoked");
            return;
        }

        await _next(context);
    }
}

// Register
app.UseMiddleware<TokenBlacklistMiddleware>();
```

---

### Best Practices

```csharp
// 1. ✅ Use strong, random secret keys (256-bit minimum)
"Jwt:Key": "your-256-bit-secret-key-here-make-it-long-and-secure-at-least-32-characters"

// 2. ✅ Set appropriate token expiration
AccessToken: 15-60 minutes
RefreshToken: 7-30 days

// 3. ✅ Always use HTTPS
options.RequireHttpsMetadata = true;

// 4. ✅ Validate all token parameters
ValidateIssuer = true
ValidateAudience = true
ValidateLifetime = true
ValidateIssuerSigningKey = true
ClockSkew = TimeSpan.Zero

// 5. ✅ Implement refresh tokens
// Never extend access token lifetime indefinitely

// 6. ✅ Store refresh tokens securely
// In database with expiration, not in JWT

// 7. ❌ Don't store sensitive data in JWT payload
// JWTs are base64-encoded, not encrypted!

// 8. ✅ Use CORS properly
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowSpecificOrigin", builder =>
        builder.WithOrigins("https://yourfrontend.com")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials());
});

// 9. ✅ Implement token revocation/blacklisting
// For logout and security incidents

// 10. ✅ Log authentication events
_logger.LogInformation("User {UserId} authenticated", userId);
_logger.LogWarning("Failed authentication attempt from {IP}", ipAddress);
```

---

## Q229: Explain Error Handling and Logging in ASP.NET Core.

**Answer:**

Proper error handling and logging are critical for maintaining, debugging, and monitoring applications in production.

### Global Exception Handling

```csharp
// ============================================
// EXCEPTION HANDLING MIDDLEWARE
// ============================================

// Program.cs
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    // Detailed error page for development
    app.UseDeveloperExceptionPage();
}
else
{
    // Custom error handling for production
    app.UseExceptionHandler("/Error");
    app.UseHsts();  // HTTP Strict Transport Security
}

// Alternative: Custom exception middleware
app.UseMiddleware<ExceptionHandlingMiddleware>();

app.Run();
```

---

### Custom Exception Middleware

```csharp
// ============================================
// CUSTOM EXCEPTION MIDDLEWARE
// ============================================

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IWebHostEnvironment _env;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IWebHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        _logger.LogError(exception, "An unhandled exception occurred");

        context.Response.ContentType = "application/json";

        var response = exception switch
        {
            NotFoundException notFoundEx => new ErrorResponse
            {
                StatusCode = StatusCodes.Status404NotFound,
                Message = notFoundEx.Message,
                Details = _env.IsDevelopment() ? notFoundEx.StackTrace : null
            },
            ValidationException validationEx => new ErrorResponse
            {
                StatusCode = StatusCodes.Status400BadRequest,
                Message = validationEx.Message,
                Errors = validationEx.Errors,
                Details = _env.IsDevelopment() ? validationEx.StackTrace : null
            },
            UnauthorizedAccessException => new ErrorResponse
            {
                StatusCode = StatusCodes.Status401Unauthorized,
                Message = "Unauthorized access"
            },
            ForbiddenException => new ErrorResponse
            {
                StatusCode = StatusCodes.Status403Forbidden,
                Message = "Access forbidden"
            },
            _ => new ErrorResponse
            {
                StatusCode = StatusCodes.Status500InternalServerError,
                Message = _env.IsDevelopment()
                    ? exception.Message
                    : "An internal server error occurred",
                Details = _env.IsDevelopment() ? exception.StackTrace : null
            }
        };

        context.Response.StatusCode = response.StatusCode;
        await context.Response.WriteAsJsonAsync(response);
    }
}

public class ErrorResponse
{
    public int StatusCode { get; set; }
    public string Message { get; set; }
    public Dictionary<string, string[]>? Errors { get; set; }
    public string? Details { get; set; }
}

// Custom exceptions
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }
}

public class ValidationException : Exception
{
    public Dictionary<string, string[]> Errors { get; }

    public ValidationException(Dictionary<string, string[]> errors)
        : base("Validation failed")
    {
        Errors = errors;
    }
}

public class ForbiddenException : Exception
{
    public ForbiddenException(string message = "Access forbidden") : base(message) { }
}
```

---

### Exception Filters

```csharp
// ============================================
// EXCEPTION FILTERS
// ============================================

public class CustomExceptionFilter : IExceptionFilter
{
    private readonly ILogger<CustomExceptionFilter> _logger;

    public CustomExceptionFilter(ILogger<CustomExceptionFilter> logger)
    {
        _logger = logger;
    }

    public void OnException(ExceptionContext context)
    {
        _logger.LogError(context.Exception, "Exception occurred");

        var statusCode = context.Exception switch
        {
            NotFoundException => StatusCodes.Status404NotFound,
            ValidationException => StatusCodes.Status400BadRequest,
            UnauthorizedAccessException => StatusCodes.Status401Unauthorized,
            _ => StatusCodes.Status500InternalServerError
        };

        context.Result = new ObjectResult(new
        {
            error = context.Exception.Message,
            stackTrace = context.Exception.StackTrace
        })
        {
            StatusCode = statusCode
        };

        context.ExceptionHandled = true;
    }
}

// Register globally
builder.Services.AddControllers(options =>
{
    options.Filters.Add<CustomExceptionFilter>();
});

// Or use on specific controller
[ServiceFilter(typeof(CustomExceptionFilter))]
public class ProductsController : ControllerBase { }
```

---

### Problem Details (RFC 7807)

```csharp
// ============================================
// PROBLEM DETAILS (Standardized Error Response)
// ============================================

// Program.cs
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = context =>
    {
        context.ProblemDetails.Instance = context.HttpContext.Request.Path;
        context.ProblemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;

        if (context.Exception is ValidationException validationEx)
        {
            context.ProblemDetails.Extensions["errors"] = validationEx.Errors;
        }
    };
});

// Controller usage
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        var product = _repository.GetById(id);

        if (product == null)
        {
            // Returns RFC 7807 Problem Details
            return Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Product not found",
                detail: $"Product with ID {id} was not found",
                instance: HttpContext.Request.Path);
        }

        return Ok(product);
    }

    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        if (!ModelState.IsValid)
        {
            // Automatic Problem Details for validation
            return ValidationProblem(ModelState);
        }

        return Ok(product);
    }
}

/* Response format:
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Product not found",
  "status": 404,
  "detail": "Product with ID 123 was not found",
  "instance": "/api/products/123",
  "traceId": "00-abc123..."
}
*/
```

---

### Logging Configuration

```csharp
// ============================================
// LOGGING CONFIGURATION
// ============================================

// appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  }
}

// appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  }
}

// Program.cs - Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.AddEventSourceLogger();

// Add file logging (third-party: Serilog, NLog)
builder.Logging.AddFile("logs/app-{Date}.txt");
```

---

### Using ILogger

```csharp
// ============================================
// ILOGGER USAGE
// ============================================

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IProductRepository repository,
        ILogger<ProductsController> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        _logger.LogInformation("Getting all products");

        try
        {
            var products = await _repository.GetAllAsync();

            _logger.LogInformation("Retrieved {Count} products", products.Count());

            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving products");
            throw;
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        _logger.LogInformation("Getting product {ProductId}", id);

        var product = await _repository.GetByIdAsync(id);

        if (product == null)
        {
            _logger.LogWarning("Product {ProductId} not found", id);
            return NotFound();
        }

        return Ok(product);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Product product)
    {
        _logger.LogInformation("Creating product: {ProductName}", product.Name);

        try
        {
            await _repository.AddAsync(product);

            _logger.LogInformation("Created product {ProductId}", product.Id);

            return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product {ProductName}", product.Name);
            throw;
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        _logger.LogInformation("Deleting product {ProductId}", id);

        var product = await _repository.GetByIdAsync(id);

        if (product == null)
        {
            _logger.LogWarning("Attempted to delete non-existent product {ProductId}", id);
            return NotFound();
        }

        await _repository.DeleteAsync(id);

        _logger.LogInformation("Deleted product {ProductId}", id);

        return NoContent();
    }
}
```

---

### Log Levels

```csharp
// ============================================
// LOG LEVELS
// ============================================

// Trace (0) - Very detailed, typically only enabled in development
_logger.LogTrace("Trace message - extremely detailed diagnostic info");

// Debug (1) - Detailed information for debugging
_logger.LogDebug("Debug message - detailed diagnostic info");

// Information (2) - General flow of the application
_logger.LogInformation("User {UserId} logged in", userId);

// Warning (3) - Unexpected events that don't stop the application
_logger.LogWarning("Slow query detected: {Duration}ms", duration);

// Error (4) - Errors and exceptions that can be handled
_logger.LogError(exception, "Failed to process order {OrderId}", orderId);

// Critical (5) - Critical failures requiring immediate attention
_logger.LogCritical("Database connection failed - application cannot start");

// Using structured logging (recommended)
_logger.LogInformation(
    "Order {OrderId} placed by customer {CustomerId} for {Amount:C}",
    order.Id,
    order.CustomerId,
    order.TotalAmount);

// Output: Order 123 placed by customer 456 for $99.99
```

---

### Serilog Configuration

```csharp
// ============================================
// SERILOG (Third-party logging library)
// ============================================

// Install: Serilog.AspNetCore

// Program.cs
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/log-.txt",
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.Seq("http://localhost:5341")  // Centralized logging
    .CreateLogger();

builder.Host.UseSerilog();

try
{
    Log.Information("Starting application");

    var app = builder.Build();

    // Add request logging
    app.UseSerilogRequestLogging(options =>
    {
        options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000}ms";
        options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
        {
            diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
            diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"]);
        };
    });

    app.MapControllers();
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
```

---

### Request/Response Logging

```csharp
// ============================================
// REQUEST/RESPONSE LOGGING MIDDLEWARE
// ============================================

public class RequestResponseLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestResponseLoggingMiddleware> _logger;

    public RequestResponseLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestResponseLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Log request
        await LogRequest(context);

        // Capture response
        var originalBodyStream = context.Response.Body;
        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;

        var stopwatch = Stopwatch.StartNew();

        try
        {
            await _next(context);
            stopwatch.Stop();

            // Log response
            await LogResponse(context, stopwatch.ElapsedMilliseconds);
        }
        finally
        {
            responseBody.Seek(0, SeekOrigin.Begin);
            await responseBody.CopyToAsync(originalBodyStream);
        }
    }

    private async Task LogRequest(HttpContext context)
    {
        context.Request.EnableBuffering();

        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        context.Request.Body.Seek(0, SeekOrigin.Begin);

        _logger.LogInformation(
            "HTTP Request: {Method} {Path} {QueryString}\nHeaders: {Headers}\nBody: {Body}",
            context.Request.Method,
            context.Request.Path,
            context.Request.QueryString,
            context.Request.Headers,
            body);
    }

    private async Task LogResponse(HttpContext context, long elapsedMs)
    {
        context.Response.Body.Seek(0, SeekOrigin.Begin);
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        context.Response.Body.Seek(0, SeekOrigin.Begin);

        _logger.LogInformation(
            "HTTP Response: {StatusCode} ({ElapsedMs}ms)\nHeaders: {Headers}\nBody: {Body}",
            context.Response.StatusCode,
            elapsedMs,
            context.Response.Headers,
            body);
    }
}
```

---

### Correlation IDs

```csharp
// ============================================
// CORRELATION ID MIDDLEWARE
// ============================================

public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private const string CorrelationIdHeaderName = "X-Correlation-ID";

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ILogger<CorrelationIdMiddleware> logger)
    {
        // Get or generate correlation ID
        var correlationId = context.Request.Headers[CorrelationIdHeaderName].FirstOrDefault()
            ?? Guid.NewGuid().ToString();

        // Add to response headers
        context.Response.Headers.Add(CorrelationIdHeaderName, correlationId);

        // Add to log context
        using (logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = correlationId
        }))
        {
            await _next(context);
        }
    }
}

// Usage in controller
public class ProductsController : ControllerBase
{
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ILogger<ProductsController> logger)
    {
        _logger = logger;
    }

    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        _logger.LogInformation("Getting product {ProductId}", id);
        // Correlation ID automatically included in logs
        return Ok(product);
    }
}
```

---

### Health Checks with Logging

```csharp
// ============================================
// HEALTH CHECKS
// ============================================

// Program.cs
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database")
    .AddUrlGroup(new Uri("https://api.example.com"), "external-api")
    .AddCheck("custom-check", () =>
    {
        // Custom health check logic
        var isHealthy = CheckSomething();
        return isHealthy
            ? HealthCheckResult.Healthy("Everything is fine")
            : HealthCheckResult.Unhealthy("Something is wrong");
    });

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";

        var result = JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        });

        await context.Response.WriteAsync(result);
    }
});

// Detailed health endpoint
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => true
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

---

### Best Practices

```csharp
// 1. ✅ Use structured logging
_logger.LogInformation("Order {OrderId} created by {UserId}", orderId, userId);

// 2. ✅ Log appropriate level
_logger.LogTrace("Very detailed info");
_logger.LogDebug("Debugging info");
_logger.LogInformation("General info");
_logger.LogWarning("Warning");
_logger.LogError(ex, "Error occurred");
_logger.LogCritical(ex, "Critical failure");

// 3. ✅ Include context in logs
_logger.LogError(exception, "Failed to process order {OrderId} for customer {CustomerId}",
    order.Id, order.CustomerId);

// 4. ✅ Use correlation IDs for tracing requests
app.UseMiddleware<CorrelationIdMiddleware>();

// 5. ❌ Don't log sensitive information
_logger.LogInformation("User password: {Password}", password);  // ❌ BAD!
_logger.LogInformation("Processing payment card: {CardNumber}", cardNumber);  // ❌ BAD!

// 6. ✅ Configure different log levels per environment
// Development: Debug/Trace
// Production: Information/Warning/Error

// 7. ✅ Use centralized logging (Seq, ELK, Application Insights)
.WriteTo.Seq("http://localhost:5341")

// 8. ✅ Implement global exception handling
app.UseExceptionHandler("/Error");
app.UseMiddleware<ExceptionHandlingMiddleware>();

// 9. ✅ Return consistent error responses
// Use Problem Details (RFC 7807)

// 10. ✅ Monitor and alert on errors
// Use Application Insights, Datadog, etc.
```

---

## Q230: What is CORS and how do you configure it in ASP.NET Core?

**Answer:**

**CORS (Cross-Origin Resource Sharing)** is a security feature that allows or restricts resources on a web server to be requested from different origins (domains).

### What is CORS?

```
Same-Origin Policy:
https://example.com/api  → https://example.com/data  ✅ Allowed (same origin)

Cross-Origin Request:
https://frontend.com     → https://api.example.com    ❌ Blocked by default

CORS allows:
https://frontend.com     → https://api.example.com    ✅ Allowed with CORS
```

### Basic CORS Configuration

```csharp
// ============================================
// BASIC CORS SETUP
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add CORS services
builder.Services.AddCors(options =>
{
    // Policy 1: Allow all (not recommended for production)
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });

    // Policy 2: Specific origin
    options.AddPolicy("AllowSpecificOrigin", builder =>
    {
        builder.WithOrigins("https://example.com")
               .AllowAnyMethod()
               .AllowAnyHeader();
    });

    // Policy 3: Multiple specific origins
    options.AddPolicy("AllowMultipleOrigins", builder =>
    {
        builder.WithOrigins(
                   "https://example.com",
                   "https://app.example.com",
                   "https://admin.example.com")
               .AllowAnyMethod()
               .AllowAnyHeader();
    });

    // Policy 4: Specific methods and headers
    options.AddPolicy("RestrictedPolicy", builder =>
    {
        builder.WithOrigins("https://example.com")
               .WithMethods("GET", "POST")
               .WithHeaders("Content-Type", "Authorization");
    });

    // Policy 5: Allow credentials (cookies, auth headers)
    options.AddPolicy("AllowCredentials", builder =>
    {
        builder.WithOrigins("https://example.com")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();  // Important for cookies/auth
    });
});

var app = builder.Build();

// Apply CORS middleware (MUST be before UseAuthorization)
app.UseCors("AllowSpecificOrigin");

app.UseAuthorization();
app.MapControllers();

app.Run();
```

---

### CORS Policy per Controller/Action

```csharp
// ============================================
// APPLY CORS PER CONTROLLER/ACTION
// ============================================

// Apply to entire controller
[EnableCors("AllowSpecificOrigin")]
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(products);
    }
}

// Apply to specific action
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [EnableCors("AllowAll")]
    [HttpGet("public")]
    public IActionResult GetPublic()
    {
        return Ok(publicProducts);
    }

    [EnableCors("RestrictedPolicy")]
    [HttpGet("private")]
    public IActionResult GetPrivate()
    {
        return Ok(privateProducts);
    }

    // Disable CORS for specific action
    [DisableCors]
    [HttpGet("no-cors")]
    public IActionResult GetNoCors()
    {
        return Ok(data);
    }
}
```

---

### Advanced CORS Configuration

```csharp
// ============================================
// ADVANCED CORS CONFIGURATION
// ============================================

builder.Services.AddCors(options =>
{
    options.AddPolicy("AdvancedPolicy", builder =>
    {
        builder
            // Specific origins
            .WithOrigins("https://example.com", "https://app.example.com")

            // Specific HTTP methods
            .WithMethods("GET", "POST", "PUT", "DELETE")

            // Specific headers
            .WithHeaders("Content-Type", "Authorization", "X-Custom-Header")

            // Expose specific headers to client
            .WithExposedHeaders("X-Pagination", "X-Total-Count")

            // Allow credentials (cookies, HTTP auth)
            .AllowCredentials()

            // Preflight cache duration
            .SetPreflightMaxAge(TimeSpan.FromMinutes(10))

            // Set if origin is allowed
            .SetIsOriginAllowed(origin => new Uri(origin).Host == "example.com")

            // Set if origin is allowed (with wildcard subdomain)
            .SetIsOriginAllowedToAllowWildcardSubdomains();
    });

    // Dynamic origin check
    options.AddPolicy("DynamicOrigins", builder =>
    {
        builder.SetIsOriginAllowed(origin =>
        {
            var uri = new Uri(origin);

            // Allow all localhost origins (development)
            if (uri.Host == "localhost")
                return true;

            // Allow specific production domains
            if (uri.Host == "example.com" || uri.Host.EndsWith(".example.com"))
                return true;

            return false;
        })
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });

    // Read from configuration
    options.AddPolicy("ConfigurablePolicy", builder =>
    {
        var allowedOrigins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();

        builder.WithOrigins(allowedOrigins)
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();
    });
});
```

---

### CORS with Configuration File

```json
// ============================================
// appsettings.json
// ============================================
{
  "Cors": {
    "AllowedOrigins": [
      "https://example.com",
      "https://app.example.com",
      "https://admin.example.com"
    ],
    "AllowedMethods": ["GET", "POST", "PUT", "DELETE"],
    "AllowedHeaders": ["Content-Type", "Authorization"],
    "AllowCredentials": true
  }
}
```

```csharp
// Program.cs
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(builder =>
    {
        var corsSettings = configuration.GetSection("Cors");

        var allowedOrigins = corsSettings.GetSection("AllowedOrigins").Get<string[]>();
        var allowedMethods = corsSettings.GetSection("AllowedMethods").Get<string[]>();
        var allowedHeaders = corsSettings.GetSection("AllowedHeaders").Get<string[]>();
        var allowCredentials = corsSettings.GetValue<bool>("AllowCredentials");

        if (allowedOrigins?.Length > 0)
            builder.WithOrigins(allowedOrigins);

        if (allowedMethods?.Length > 0)
            builder.WithMethods(allowedMethods);
        else
            builder.AllowAnyMethod();

        if (allowedHeaders?.Length > 0)
            builder.WithHeaders(allowedHeaders);
        else
            builder.AllowAnyHeader();

        if (allowCredentials)
            builder.AllowCredentials();
    });
});
```

---

### Preflight Requests

```csharp
// ============================================
// PREFLIGHT REQUESTS (OPTIONS)
// ============================================

/*
Browser automatically sends preflight request before actual request:

1. Preflight Request (OPTIONS):
OPTIONS /api/products HTTP/1.1
Origin: https://example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization

2. Preflight Response:
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 600

3. Actual Request:
POST /api/products HTTP/1.1
Origin: https://example.com
Content-Type: application/json
*/

// Configure preflight cache
builder.Services.AddCors(options =>
{
    options.AddPolicy("MyPolicy", builder =>
    {
        builder.WithOrigins("https://example.com")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .SetPreflightMaxAge(TimeSpan.FromMinutes(10));  // Cache preflight for 10 min
    });
});
```

---

### Custom CORS Middleware

```csharp
// ============================================
// CUSTOM CORS MIDDLEWARE
// ============================================

public class CustomCorsMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CustomCorsMiddleware> _logger;

    public CustomCorsMiddleware(
        RequestDelegate next,
        ILogger<CustomCorsMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var origin = context.Request.Headers["Origin"].ToString();

        if (!string.IsNullOrEmpty(origin))
        {
            _logger.LogInformation("CORS request from origin: {Origin}", origin);

            if (IsOriginAllowed(origin))
            {
                context.Response.Headers.Add("Access-Control-Allow-Origin", origin);
                context.Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
                context.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization");
                context.Response.Headers.Add("Access-Control-Allow-Credentials", "true");

                // Handle preflight
                if (context.Request.Method == "OPTIONS")
                {
                    context.Response.StatusCode = StatusCodes.Status204NoContent;
                    return;
                }
            }
            else
            {
                _logger.LogWarning("CORS request rejected from origin: {Origin}", origin);
            }
        }

        await _next(context);
    }

    private bool IsOriginAllowed(string origin)
    {
        var allowedOrigins = new[]
        {
            "https://example.com",
            "https://app.example.com"
        };

        return allowedOrigins.Contains(origin);
    }
}
```

---

### Common CORS Scenarios

```csharp
// ============================================
// COMMON CORS SCENARIOS
// ============================================

// Scenario 1: React/Vue/Angular SPA calling .NET API
builder.Services.AddCors(options =>
{
    options.AddPolicy("SPAPolicy", builder =>
    {
        builder.WithOrigins("http://localhost:3000", "https://myapp.com")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();  // For cookies/auth
    });
});

// Scenario 2: Mobile app calling API (no credentials)
builder.Services.AddCors(options =>
{
    options.AddPolicy("MobilePolicy", builder =>
    {
        builder.AllowAnyOrigin()  // Mobile apps don't send Origin header
               .AllowAnyMethod()
               .AllowAnyHeader();
        // Note: Cannot use AllowCredentials() with AllowAnyOrigin()
    });
});

// Scenario 3: Multiple frontend apps (dev, staging, prod)
builder.Services.AddCors(options =>
{
    options.AddPolicy("MultiEnvironment", builder =>
    {
        var origins = new List<string>();

        if (env.IsDevelopment())
        {
            origins.AddRange(new[] { "http://localhost:3000", "http://localhost:4200" });
        }
        else if (env.IsStaging())
        {
            origins.Add("https://staging.example.com");
        }
        else if (env.IsProduction())
        {
            origins.Add("https://example.com");
        }

        builder.WithOrigins(origins.ToArray())
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();
    });
});

// Scenario 4: Public API (any origin)
builder.Services.AddCors(options =>
{
    options.AddPolicy("PublicAPI", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

// Scenario 5: Subdomain wildcard
builder.Services.AddCors(options =>
{
    options.AddPolicy("SubdomainPolicy", builder =>
    {
        builder.SetIsOriginAllowed(origin =>
        {
            var uri = new Uri(origin);
            return uri.Host.EndsWith(".example.com") || uri.Host == "example.com";
        })
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});
```

---

### CORS Troubleshooting

```csharp
// ============================================
// CORS TROUBLESHOOTING
// ============================================

// Problem 1: AllowCredentials with AllowAnyOrigin
builder.Services.AddCors(options =>
{
    options.AddPolicy("Wrong", builder =>
    {
        builder.AllowAnyOrigin()      // ❌ Cannot use both
               .AllowCredentials();    // ❌ Cannot use both
    });

    options.AddPolicy("Correct", builder =>
    {
        builder.WithOrigins("https://example.com")  // ✅ Specific origin
               .AllowCredentials();                  // ✅ With credentials
    });
});

// Problem 2: Middleware order
var app = builder.Build();

// ❌ WRONG ORDER
app.UseAuthorization();
app.UseCors("MyPolicy");  // Too late!

// ✅ CORRECT ORDER
app.UseRouting();
app.UseCors("MyPolicy");  // Before UseAuthorization
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Problem 3: Preflight not handled
// Make sure OPTIONS requests are allowed
[HttpOptions]  // Explicitly allow OPTIONS
public IActionResult Options()
{
    return Ok();
}

// Problem 4: Multiple CORS policies conflict
// Apply most specific policy
[EnableCors("SpecificPolicy")]  // Takes precedence
public class MyController : ControllerBase
{
    [EnableCors("AnotherPolicy")]  // This one is used
    public IActionResult MyAction() { }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use specific origins in production
builder.WithOrigins("https://example.com", "https://app.example.com")

// 2. ❌ Avoid AllowAnyOrigin in production
builder.AllowAnyOrigin()  // ❌ Security risk!

// 3. ✅ Use AllowCredentials with specific origins
builder.WithOrigins("https://example.com")
       .AllowCredentials();

// 4. ✅ Apply CORS middleware before authorization
app.UseRouting();
app.UseCors("MyPolicy");
app.UseAuthentication();
app.UseAuthorization();

// 5. ✅ Use environment-specific origins
if (env.IsDevelopment())
    builder.WithOrigins("http://localhost:3000");
else
    builder.WithOrigins("https://example.com");

// 6. ✅ Cache preflight requests
builder.SetPreflightMaxAge(TimeSpan.FromMinutes(10));

// 7. ✅ Log CORS requests for debugging
_logger.LogInformation("CORS request from {Origin}", origin);

// 8. ✅ Use configuration for origins
var origins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();

// 9. ❌ Don't expose sensitive headers
builder.WithExposedHeaders("X-Total-Count")  // ✅ OK
       .WithExposedHeaders("Authorization")   // ❌ Don't expose auth!

// 10. ✅ Test CORS thoroughly
// Use browser DevTools Network tab
// Check preflight (OPTIONS) requests
// Verify response headers
```

---

## Questions 221-230 Complete!

**Completed Topics:**
- ✅ Q221: ASP.NET Core Introduction
- ✅ Q222: Request Pipeline & Middleware
- ✅ Q223: Dependency Injection
- ✅ Q224: Configuration
- ✅ Q225: Routing
- ✅ Q226: Model Binding & Validation
- ✅ Q227: Authentication & Authorization
- ✅ Q228: JWT Authentication
- ✅ Q229: Error Handling & Logging
- ✅ Q230: CORS

**Remaining Questions (Q231-Q240):**
- Q231: API Versioning
- Q232: Response Caching
- Q233: Background Services
- Q234: Health Checks
- Q235: Testing ASP.NET Core
- Q236-Q240: Advanced Topics (SignalR, gRPC, Minimal APIs, Performance)

---

## Q231: Explain API Versioning in ASP.NET Core.

**Answer:**

**API Versioning** allows you to maintain multiple versions of your API to support backward compatibility while introducing new features.

### Why Version APIs?

```
Without Versioning:
Breaking change → All clients break immediately ❌

With Versioning:
Breaking change in v2 → v1 clients still work ✅
                      → v2 clients use new features ✅
```

### Installation

```bash
# Install API Versioning package
dotnet add package Asp.Versioning.Mvc
dotnet add package Asp.Versioning.Mvc.ApiExplorer
```

### URL Path Versioning (Recommended)

```csharp
// ============================================
// URL PATH VERSIONING
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add API versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;  // Add version info to response headers
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
})
.AddMvc()
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});

var app = builder.Build();
app.MapControllers();
app.Run();

// ============================================
// VERSION 1 CONTROLLER
// ============================================

[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
public class ProductsController : ControllerBase
{
    // GET: api/v1/products
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new[]
        {
            new { Id = 1, Name = "Product 1" }
        });
    }

    // GET: api/v1/products/5
    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        return Ok(new { Id = id, Name = "Product 1" });
    }
}

// ============================================
// VERSION 2 CONTROLLER
// ============================================

[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("2.0")]
public class ProductsV2Controller : ControllerBase
{
    // GET: api/v2/products
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new[]
        {
            new { Id = 1, Name = "Product 1", Description = "New field in v2" }
        });
    }

    // GET: api/v2/products/5
    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        return Ok(new
        {
            Id = id,
            Name = "Product 1",
            Description = "New field in v2",
            Price = 99.99m  // Additional field
        });
    }
}
```

---

### Query String Versioning

```csharp
// ============================================
// QUERY STRING VERSIONING
// ============================================

// Program.cs
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new QueryStringApiVersionReader("api-version");
    // Request: GET /api/products?api-version=2.0
});

// Controller
[ApiController]
[Route("api/[controller]")]
[ApiVersion("1.0")]
[ApiVersion("2.0")]
public class ProductsController : ControllerBase
{
    // GET: /api/products?api-version=1.0
    [HttpGet]
    [MapToApiVersion("1.0")]
    public IActionResult GetV1()
    {
        return Ok(new { Version = "1.0", Data = "V1 data" });
    }

    // GET: /api/products?api-version=2.0
    [HttpGet]
    [MapToApiVersion("2.0")]
    public IActionResult GetV2()
    {
        return Ok(new { Version = "2.0", Data = "V2 data with more info" });
    }
}
```

---

### Header Versioning

```csharp
// ============================================
// HEADER VERSIONING
// ============================================

// Program.cs
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new HeaderApiVersionReader("X-API-Version");
    // Request: GET /api/products
    // Header: X-API-Version: 2.0
});

// Controller
[ApiController]
[Route("api/[controller]")]
[ApiVersion("1.0")]
[ApiVersion("2.0")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public IActionResult GetV1()
    {
        return Ok(new { Version = "1.0" });
    }

    [HttpGet]
    [MapToApiVersion("2.0")]
    public IActionResult GetV2()
    {
        return Ok(new { Version = "2.0" });
    }
}
```

---

### Media Type Versioning (Accept Header)

```csharp
// ============================================
// MEDIA TYPE VERSIONING
// ============================================

// Program.cs
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ApiVersionReader = new MediaTypeApiVersionReader();
    // Request: GET /api/products
    // Header: Accept: application/json;v=2.0
});
```

---

### Multiple Version Readers

```csharp
// ============================================
// COMBINE MULTIPLE VERSION READERS
// ============================================

builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;

    // Accept version from URL, query string, OR header
    options.ApiVersionReader = ApiVersionReader.Combine(
        new UrlSegmentApiVersionReader(),
        new QueryStringApiVersionReader("api-version"),
        new HeaderApiVersionReader("X-API-Version")
    );
});

// Works with:
// GET /api/v2/products
// GET /api/products?api-version=2.0
// GET /api/products (Header: X-API-Version: 2.0)
```

---

### Version-Neutral Endpoints

```csharp
// ============================================
// VERSION-NEUTRAL ENDPOINTS
// ============================================

[ApiController]
[Route("api/[controller]")]
[ApiVersionNeutral]  // No version required
public class HealthController : ControllerBase
{
    // GET: /api/health (no version needed)
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { Status = "Healthy" });
    }
}
```

---

### Deprecating API Versions

```csharp
// ============================================
// DEPRECATE OLD VERSIONS
// ============================================

[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0", Deprecated = true)]  // Mark as deprecated
[ApiVersion("2.0")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [MapToApiVersion("1.0")]
    public IActionResult GetV1()
    {
        return Ok(new
        {
            Message = "This version is deprecated. Please use v2.0",
            Data = "V1 data"
        });
    }

    [HttpGet]
    [MapToApiVersion("2.0")]
    public IActionResult GetV2()
    {
        return Ok(new { Data = "V2 data" });
    }
}

// Response headers include:
// api-supported-versions: 1.0, 2.0
// api-deprecated-versions: 1.0
```

---

### Best Practices

```csharp
// 1. ✅ Use URL path versioning (most visible and RESTful)
[Route("api/v{version:apiVersion}/[controller]")]

// 2. ✅ Always set a default version
options.DefaultApiVersion = new ApiVersion(1, 0);
options.AssumeDefaultVersionWhenUnspecified = true;

// 3. ✅ Report supported versions in headers
options.ReportApiVersions = true;
// Response includes: api-supported-versions: 1.0, 2.0

// 4. ✅ Deprecate old versions before removing
[ApiVersion("1.0", Deprecated = true)]

// 5. ✅ Version your models separately
namespace MyApi.Models.V1 { }
namespace MyApi.Models.V2 { }

// 6. ✅ Document changes between versions
/// <summary>
/// V2.0 Changes:
/// - Added Description field
/// - Added Stock field
/// - Removed LegacyField
/// </summary>

// 7. ✅ Use semantic versioning
new ApiVersion(1, 0)      // v1.0 - Major.Minor
new ApiVersion(2, 1)      // v2.1 - Breaking changes in v2
new ApiVersion(2, 2)      // v2.2 - Non-breaking changes

// 8. ❌ Don't break existing clients
// Always maintain backward compatibility in minor versions

// 9. ✅ Integrate with Swagger for documentation
// Shows all versions in Swagger UI dropdown

// 10. ✅ Plan migration strategy
// Give users time to migrate (6-12 months)
// Send deprecation warnings
// Communicate sunset dates
```

---

## Q232: Explain Response Caching in ASP.NET Core.

**Answer:**

**Response Caching** stores server responses to reduce server load and improve performance by serving cached responses for identical requests.

### Response Caching Middleware

```csharp
// ============================================
// RESPONSE CACHING SETUP
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add response caching
builder.Services.AddResponseCaching();

var app = builder.Build();

// Add response caching middleware (must be early in pipeline)
app.UseResponseCaching();

// Optional: Custom caching rules
app.Use(async (context, next) =>
{
    context.Response.GetTypedHeaders().CacheControl =
        new Microsoft.Net.Http.Headers.CacheControlHeaderValue
        {
            Public = true,
            MaxAge = TimeSpan.FromSeconds(60)
        };

    await next();
});

app.MapControllers();
app.Run();
```

---

### ResponseCache Attribute

```csharp
// ============================================
// RESPONSE CACHE ATTRIBUTE
// ============================================

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    // Cache for 60 seconds
    [HttpGet]
    [ResponseCache(Duration = 60)]
    public IActionResult GetAll()
    {
        return Ok(products);
    }

    // Cache with location
    [HttpGet("{id}")]
    [ResponseCache(Duration = 120, Location = ResponseCacheLocation.Client)]
    public IActionResult Get(int id)
    {
        // Cached only on client side
        return Ok(product);
    }

    // Cache with VaryByQueryKeys
    [HttpGet("search")]
    [ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "term", "page" })]
    public IActionResult Search(string term, int page)
    {
        // Different cache for each query parameter combination
        return Ok(results);
    }

    // Cache with VaryByHeader
    [HttpGet("localized")]
    [ResponseCache(Duration = 600, VaryByHeader = "Accept-Language")]
    public IActionResult GetLocalized()
    {
        // Different cache for each language
        return Ok(localizedData);
    }

    // No caching
    [HttpPost]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult Create([FromBody] Product product)
    {
        // Never cache POST requests
        return Ok(product);
    }

    // Use caching profile
    [HttpGet("featured")]
    [ResponseCache(CacheProfileName = "Default30")]
    public IActionResult GetFeatured()
    {
        return Ok(featuredProducts);
    }
}
```

---

### Cache Profiles

```csharp
// ============================================
// CACHE PROFILES
// ============================================

// Program.cs
builder.Services.AddControllers(options =>
{
    // Define cache profiles
    options.CacheProfiles.Add("Default30", new CacheProfile
    {
        Duration = 30,
        Location = ResponseCacheLocation.Any
    });

    options.CacheProfiles.Add("LongCache", new CacheProfile
    {
        Duration = 3600,  // 1 hour
        Location = ResponseCacheLocation.Any,
        VaryByHeader = "User-Agent"
    });

    options.CacheProfiles.Add("NoCache", new CacheProfile
    {
        NoStore = true,
        Location = ResponseCacheLocation.None
    });
});

// Usage
[ResponseCache(CacheProfileName = "Default30")]
[HttpGet]
public IActionResult GetProducts() { }

[ResponseCache(CacheProfileName = "LongCache")]
[HttpGet("static")]
public IActionResult GetStaticData() { }

[ResponseCache(CacheProfileName = "NoCache")]
[HttpPost]
public IActionResult CreateProduct() { }
```

---

### Memory Cache (In-Process)

```csharp
// ============================================
// MEMORY CACHE (In-Process)
// ============================================

// Program.cs
builder.Services.AddMemoryCache();

// Service using memory cache
public class ProductService
{
    private readonly IMemoryCache _cache;
    private readonly IProductRepository _repository;

    public ProductService(
        IMemoryCache cache,
        IProductRepository repository)
    {
        _cache = cache;
        _repository = repository;
    }

    public async Task<IEnumerable<Product>> GetAllAsync()
    {
        const string cacheKey = "all_products";

        // Try to get from cache
        if (_cache.TryGetValue(cacheKey, out IEnumerable<Product> products))
        {
            return products;
        }

        // Not in cache, get from database
        products = await _repository.GetAllAsync();

        // Store in cache
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5),
            SlidingExpiration = TimeSpan.FromMinutes(2),
            Priority = CacheItemPriority.Normal
        };

        // Set callback for when item is removed
        cacheOptions.RegisterPostEvictionCallback((key, value, reason, state) =>
        {
            Console.WriteLine($"Cache entry {key} was removed: {reason}");
        });

        _cache.Set(cacheKey, products, cacheOptions);

        return products;
    }

    public async Task<Product> GetOrCreateAsync(int id)
    {
        var cacheKey = $"product_{id}";

        // GetOrCreateAsync pattern
        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);
            entry.SlidingExpiration = TimeSpan.FromMinutes(2);

            return await _repository.GetByIdAsync(id);
        });
    }

    public void Invalidate(int id)
    {
        var cacheKey = $"product_{id}";
        _cache.Remove(cacheKey);
    }
}
```

---

### Distributed Caching (Redis)

```csharp
// ============================================
// DISTRIBUTED CACHE (Redis)
// ============================================

// Install: Microsoft.Extensions.Caching.StackExchangeRedis

// Program.cs
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
    options.InstanceName = "MyApp_";
});

// Service using distributed cache
public class ProductService
{
    private readonly IDistributedCache _cache;
    private readonly IProductRepository _repository;

    public ProductService(
        IDistributedCache cache,
        IProductRepository repository)
    {
        _cache = cache;
        _repository = repository;
    }

    public async Task<Product> GetByIdAsync(int id)
    {
        var cacheKey = $"product_{id}";

        // Try to get from cache
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (cachedData != null)
        {
            return JsonSerializer.Deserialize<Product>(cachedData);
        }

        // Not in cache, get from database
        var product = await _repository.GetByIdAsync(id);

        // Store in cache
        var options = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5),
            SlidingExpiration = TimeSpan.FromMinutes(2)
        };

        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(product),
            options);

        return product;
    }

    public async Task UpdateAsync(Product product)
    {
        await _repository.UpdateAsync(product);

        // Invalidate cache
        var cacheKey = $"product_{product.Id}";
        await _cache.RemoveAsync(cacheKey);
    }
}
```

---

### Cache Invalidation

```csharp
// ============================================
// CACHE INVALIDATION STRATEGIES
// ============================================

public class ProductService
{
    private readonly IMemoryCache _cache;
    private readonly IProductRepository _repository;

    // Strategy 1: Time-based expiration
    public async Task<Product> GetWithTimeExpiration(int id)
    {
        var cacheKey = $"product_{id}";

        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            // Absolute expiration
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);

            // Sliding expiration (reset on access)
            entry.SlidingExpiration = TimeSpan.FromMinutes(5);

            return await _repository.GetByIdAsync(id);
        });
    }

    // Strategy 2: Manual invalidation on update
    public async Task UpdateProduct(Product product)
    {
        await _repository.UpdateAsync(product);

        // Invalidate specific item
        _cache.Remove($"product_{product.Id}");

        // Invalidate list cache
        _cache.Remove("all_products");
    }

    // Strategy 3: Cache-aside pattern
    public async Task<Product> GetCacheAside(int id)
    {
        var cacheKey = $"product_{id}";

        // 1. Try cache
        if (_cache.TryGetValue(cacheKey, out Product product))
        {
            return product;
        }

        // 2. Get from database
        product = await _repository.GetByIdAsync(id);

        // 3. Store in cache
        _cache.Set(cacheKey, product, TimeSpan.FromMinutes(5));

        return product;
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Cache static/rarely changing data
[ResponseCache(Duration = 3600)]  // 1 hour
[HttpGet("countries")]
public IActionResult GetCountries() { }

// 2. ✅ Don't cache personalized data
[ResponseCache(NoStore = true)]  // Never cache
[HttpGet("my-profile")]
public IActionResult GetMyProfile() { }

// 3. ✅ Use appropriate cache location
[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Client)]  // Client only
[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Any)]     // Client + server

// 4. ✅ Vary by relevant parameters
[ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "page", "filter" })]

// 5. ✅ Set reasonable expiration times
// Static data: hours/days
// Dynamic data: minutes
// Real-time data: no cache

// 6. ✅ Use ETags for conditional requests
Response.Headers.ETag = GenerateETag(data);
if (Request.Headers.IfNoneMatch == etag)
    return StatusCode(304);

// 7. ✅ Invalidate cache on updates
public async Task Update(Product product)
{
    await _repository.UpdateAsync(product);
    _cache.Remove($"product_{product.Id}");
}

// 8. ✅ Use distributed cache for scaled applications
builder.Services.AddStackExchangeRedisCache(...);

// 9. ❌ Don't cache sensitive data
[ResponseCache(NoStore = true)]
[HttpGet("sensitive")]
public IActionResult GetSensitive() { }

// 10. ✅ Monitor cache hit ratio
// Track: cache hits vs misses
// Adjust: duration and strategy based on metrics
```

---

## Q233: Explain Background Services and Hosted Services in ASP.NET Core.

**Answer:**

**Background Services** run long-running tasks in the background of your ASP.NET Core application, independent of HTTP requests.

### IHostedService Interface

```csharp
// ============================================
// BASIC HOSTED SERVICE
// ============================================

public class MyBackgroundService : IHostedService
{
    private readonly ILogger<MyBackgroundService> _logger;

    public MyBackgroundService(ILogger<MyBackgroundService> logger)
    {
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Background service starting");
        // Start background work here
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Background service stopping");
        // Clean up resources
        return Task.CompletedTask;
    }
}

// Register in Program.cs
builder.Services.AddHostedService<MyBackgroundService>();
```

---

### BackgroundService Base Class

```csharp
// ============================================
// BACKGROUND SERVICE (Recommended)
// ============================================

public class TimedBackgroundService : BackgroundService
{
    private readonly ILogger<TimedBackgroundService> _logger;
    private readonly TimeSpan _period = TimeSpan.FromMinutes(5);

    public TimedBackgroundService(ILogger<TimedBackgroundService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Timed Background Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Executing background task at {Time}", DateTime.UtcNow);

                await DoWorkAsync();

                await Task.Delay(_period, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in background service");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }

        _logger.LogInformation("Timed Background Service stopped");
    }

    private async Task DoWorkAsync()
    {
        // Perform background work
        _logger.LogInformation("Processing background task");
        await Task.Delay(1000);
    }
}

// Register
builder.Services.AddHostedService<TimedBackgroundService>();
```

---

### Using Scoped Services

```csharp
// ============================================
// BACKGROUND SERVICE WITH SCOPED DEPENDENCIES
// ============================================

public class DataProcessingService : BackgroundService
{
    private readonly ILogger<DataProcessingService> _logger;
    private readonly IServiceProvider _serviceProvider;

    public DataProcessingService(
        ILogger<DataProcessingService> logger,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // Create a scope for scoped services
                using (var scope = _serviceProvider.CreateScope())
                {
                    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                    var repository = scope.ServiceProvider.GetRequiredService<IOrderRepository>();

                    // Process pending orders
                    var pendingOrders = await repository.GetPendingOrdersAsync();

                    foreach (var order in pendingOrders)
                    {
                        await ProcessOrderAsync(order, repository);
                    }
                }

                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing orders");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }

    private async Task ProcessOrderAsync(Order order, IOrderRepository repository)
    {
        _logger.LogInformation("Processing order {OrderId}", order.Id);

        order.Status = OrderStatus.Processing;
        await repository.UpdateAsync(order);

        // Process order logic...
    }
}
```

---

### Queue-Based Background Service

```csharp
// ============================================
// QUEUE-BASED BACKGROUND WORKER
// ============================================

public interface IBackgroundTaskQueue
{
    ValueTask QueueBackgroundWorkItemAsync(Func<CancellationToken, ValueTask> workItem);
    ValueTask<Func<CancellationToken, ValueTask>> DequeueAsync(CancellationToken cancellationToken);
}

public class BackgroundTaskQueue : IBackgroundTaskQueue
{
    private readonly Channel<Func<CancellationToken, ValueTask>> _queue;

    public BackgroundTaskQueue(int capacity = 100)
    {
        var options = new BoundedChannelOptions(capacity)
        {
            FullMode = BoundedChannelFullMode.Wait
        };
        _queue = Channel.CreateBounded<Func<CancellationToken, ValueTask>>(options);
    }

    public async ValueTask QueueBackgroundWorkItemAsync(Func<CancellationToken, ValueTask> workItem)
    {
        await _queue.Writer.WriteAsync(workItem);
    }

    public async ValueTask<Func<CancellationToken, ValueTask>> DequeueAsync(CancellationToken cancellationToken)
    {
        return await _queue.Reader.ReadAsync(cancellationToken);
    }
}

// Background service that processes queue
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
    }
}

// Register
builder.Services.AddSingleton<IBackgroundTaskQueue, BackgroundTaskQueue>();
builder.Services.AddHostedService<QueuedHostedService>();

// Usage in controller
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
    public IActionResult ProcessOrder(int id)
    {
        // Queue background work
        _taskQueue.QueueBackgroundWorkItemAsync(async token =>
        {
            await Task.Delay(5000, token);  // Simulate work
            Console.WriteLine($"Processed order {id}");
        });

        return Accepted();
    }
}
```

---

### Periodic Timer (Modern Approach)

```csharp
// ============================================
// PERIODIC TIMER (.NET 6+)
// ============================================

public class PeriodicBackgroundService : BackgroundService
{
    private readonly ILogger<PeriodicBackgroundService> _logger;
    private readonly PeriodicTimer _timer;

    public PeriodicBackgroundService(ILogger<PeriodicBackgroundService> logger)
    {
        _logger = logger;
        _timer = new PeriodicTimer(TimeSpan.FromMinutes(5));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _timer.WaitForNextTickAsync(stoppingToken)
               && !stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Executing periodic task at {Time}", DateTime.UtcNow);
                await DoWorkAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in periodic task");
            }
        }
    }

    private async Task DoWorkAsync()
    {
        // Perform work
        await Task.Delay(1000);
    }

    public override void Dispose()
    {
        _timer.Dispose();
        base.Dispose();
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use BackgroundService base class
public class MyService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken) { }
}

// 2. ✅ Always handle cancellation tokens
while (!stoppingToken.IsCancellationRequested)
{
    await DoWork(stoppingToken);
}

// 3. ✅ Use scopes for scoped services
using (var scope = _serviceProvider.CreateScope())
{
    var service = scope.ServiceProvider.GetRequiredService<IScopedService>();
}

// 4. ✅ Handle exceptions gracefully
try
{
    await DoWork();
}
catch (Exception ex)
{
    _logger.LogError(ex, "Error occurred");
    await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
}

// 5. ✅ Log lifecycle events
_logger.LogInformation("Service starting/stopping");

// 6. ✅ Use queues for work items
builder.Services.AddSingleton<IBackgroundTaskQueue, BackgroundTaskQueue>();

// 7. ❌ Don't block the thread
await Task.Delay(...);  // ✅ Good
Thread.Sleep(...);      // ❌ Bad

// 8. ✅ Implement graceful shutdown
public override async Task StopAsync(CancellationToken cancellationToken)
{
    // Clean up resources
    await base.StopAsync(cancellationToken);
}

// 9. ✅ Use PeriodicTimer for .NET 6+
private readonly PeriodicTimer _timer = new(TimeSpan.FromMinutes(5));

// 10. ✅ Monitor background service health
// Log errors, track metrics, alert on failures
```

---

## Q234: Explain Health Checks in ASP.NET Core.

**Answer:**

**Health Checks** provide a way to monitor the health of your application and its dependencies.

### Basic Health Check

```csharp
// ============================================
// BASIC HEALTH CHECK
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// Map health check endpoint
app.MapHealthChecks("/health");

app.Run();

// GET /health
// Response: Healthy (200 OK)
```

---

### Database Health Check

```csharp
// ============================================
// DATABASE HEALTH CHECK
// ============================================

builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database")
    .AddSqlServer(
        connectionString: builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "sql-server",
        timeout: TimeSpan.FromSeconds(5),
        tags: new[] { "db", "sql" });

// Checks if database is accessible
```

---

### Custom Health Checks

```csharp
// ============================================
// CUSTOM HEALTH CHECK
// ============================================

public class ExternalApiHealthCheck : IHealthCheck
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ExternalApiHealthCheck> _logger;

    public ExternalApiHealthCheck(
        HttpClient httpClient,
        ILogger<ExternalApiHealthCheck> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("https://api.example.com/health", cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                return HealthCheckResult.Healthy("External API is healthy");
            }

            return HealthCheckResult.Degraded($"External API returned {response.StatusCode}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "External API health check failed");
            return HealthCheckResult.Unhealthy("External API is unreachable", ex);
        }
    }
}

// Register
builder.Services.AddHttpClient<ExternalApiHealthCheck>();
builder.Services.AddHealthChecks()
    .AddCheck<ExternalApiHealthCheck>("external-api", tags: new[] { "api" });
```

---

### Comprehensive Health Checks

```csharp
// ============================================
// MULTIPLE HEALTH CHECKS
// ============================================

builder.Services.AddHealthChecks()
    // Database
    .AddDbContextCheck<AppDbContext>("database", tags: new[] { "db", "ready" })

    // Redis
    .AddRedis(
        builder.Configuration.GetConnectionString("Redis"),
        name: "redis",
        tags: new[] { "cache", "ready" })

    // External API
    .AddUrlGroup(
        new Uri("https://api.example.com/health"),
        name: "external-api",
        timeout: TimeSpan.FromSeconds(5),
        tags: new[] { "api" })

    // Disk space
    .AddCheck("disk-space", () =>
    {
        var drive = new DriveInfo("C");
        var availableGB = drive.AvailableFreeSpace / 1024 / 1024 / 1024;

        if (availableGB < 10)
            return HealthCheckResult.Unhealthy($"Low disk space: {availableGB}GB");

        if (availableGB < 50)
            return HealthCheckResult.Degraded($"Disk space warning: {availableGB}GB");

        return HealthCheckResult.Healthy($"Disk space OK: {availableGB}GB");
    })

    // Memory
    .AddCheck("memory", () =>
    {
        var allocated = GC.GetTotalMemory(false) / 1024 / 1024;

        if (allocated > 1024)
            return HealthCheckResult.Unhealthy($"High memory usage: {allocated}MB");

        return HealthCheckResult.Healthy($"Memory OK: {allocated}MB");
    });
```

---

### Detailed Health Check Response

```csharp
// ============================================
// DETAILED HEALTH CHECK RESPONSE
// ============================================

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";

        var response = new
        {
            status = report.Status.ToString(),
            duration = report.TotalDuration.TotalMilliseconds,
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds,
                exception = e.Value.Exception?.Message,
                data = e.Value.Data
            }),
            timestamp = DateTime.UtcNow
        };

        await context.Response.WriteAsJsonAsync(response);
    }
});

/* Response:
{
  "status": "Healthy",
  "duration": 145.23,
  "checks": [
    {
      "name": "database",
      "status": "Healthy",
      "description": "Database connection successful",
      "duration": 23.45
    },
    {
      "name": "redis",
      "status": "Healthy",
      "duration": 12.34
    }
  ],
  "timestamp": "2024-01-15T10:30:00Z"
}
*/
```

---

### Liveness and Readiness Probes

```csharp
// ============================================
// KUBERNETES-STYLE HEALTH CHECKS
// ============================================

// Liveness: Is the app running?
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false  // No checks, just returns 200 if app is running
});

// Readiness: Is the app ready to accept traffic?
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

// Detailed health
app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = _ => true  // All checks
});

// Register checks with tags
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database", tags: new[] { "ready" })
    .AddRedis(redisConnection, tags: new[] { "ready" })
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" });
```

---

### Health Check UI

```csharp
// ============================================
// HEALTH CHECKS UI
// ============================================

// Install: AspNetCore.HealthChecks.UI

builder.Services
    .AddHealthChecks()
    .AddDbContextCheck<AppDbContext>()
    .AddRedis(redisConnection);

// Add Health Checks UI
builder.Services
    .AddHealthChecksUI(options =>
    {
        options.SetEvaluationTimeInSeconds(30);  // Check every 30 seconds
        options.MaximumHistoryEntriesPerEndpoint(50);
        options.AddHealthCheckEndpoint("API", "/health");
    })
    .AddInMemoryStorage();

var app = builder.Build();

app.MapHealthChecks("/health");
app.MapHealthChecksUI(options =>
{
    options.UIPath = "/health-ui";  // UI at /health-ui
});

// Access UI at: https://localhost:5001/health-ui
```

---

### Publisher for Monitoring

```csharp
// ============================================
// HEALTH CHECK PUBLISHER
// ============================================

public class CustomHealthCheckPublisher : IHealthCheckPublisher
{
    private readonly ILogger<CustomHealthCheckPublisher> _logger;

    public CustomHealthCheckPublisher(ILogger<CustomHealthCheckPublisher> logger)
    {
        _logger = logger;
    }

    public Task PublishAsync(HealthReport report, CancellationToken cancellationToken)
    {
        if (report.Status == HealthStatus.Unhealthy)
        {
            _logger.LogError("Application is unhealthy: {Status}", report.Status);

            // Send alert (email, Slack, PagerDuty, etc.)
            foreach (var entry in report.Entries.Where(e => e.Value.Status == HealthStatus.Unhealthy))
            {
                _logger.LogError(
                    "Check {Name} failed: {Description}",
                    entry.Key,
                    entry.Value.Description);
            }
        }

        return Task.CompletedTask;
    }
}

// Register
builder.Services.AddSingleton<IHealthCheckPublisher, CustomHealthCheckPublisher>();
builder.Services.Configure<HealthCheckPublisherOptions>(options =>
{
    options.Delay = TimeSpan.FromSeconds(5);
    options.Period = TimeSpan.FromSeconds(30);
});
```

---

### Best Practices

```csharp
// 1. ✅ Use multiple health check endpoints
app.MapHealthChecks("/health/live");   // Liveness
app.MapHealthChecks("/health/ready");  // Readiness
app.MapHealthChecks("/health");        // Detailed

// 2. ✅ Tag health checks appropriately
.AddDbContextCheck<AppDbContext>("db", tags: new[] { "ready" })

// 3. ✅ Set appropriate timeouts
.AddSqlServer(connectionString, timeout: TimeSpan.FromSeconds(5))

// 4. ✅ Include dependency checks
// Database, cache, external APIs, disk space, memory

// 5. ✅ Use detailed responses for debugging
ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse

// 6. ✅ Implement custom health checks
public class MyHealthCheck : IHealthCheck { }

// 7. ✅ Monitor and alert on failures
// Use publishers to send alerts

// 8. ❌ Don't expose sensitive information
// Filter out connection strings, secrets in responses

// 9. ✅ Use Health Checks UI for visualization
.AddHealthChecksUI()

// 10. ✅ Integrate with orchestrators
// Kubernetes liveness and readiness probes
```

---

## Q235: How do you test ASP.NET Core applications?

**Answer:**

ASP.NET Core provides comprehensive testing support including unit testing, integration testing, and end-to-end testing.

### Unit Testing Controllers

```csharp
// ============================================
// UNIT TESTING CONTROLLERS
// ============================================

// Controller to test
public class ProductsController : ControllerBase
{
    private readonly IProductRepository _repository;

    public ProductsController(IProductRepository repository)
    {
        _repository = repository;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var product = await _repository.GetByIdAsync(id);

        if (product == null)
            return NotFound();

        return Ok(product);
    }
}

// Unit test using xUnit and Moq
public class ProductsControllerTests
{
    [Fact]
    public async Task GetById_ReturnsProduct_WhenProductExists()
    {
        // Arrange
        var mockRepo = new Mock<IProductRepository>();
        var product = new Product { Id = 1, Name = "Test Product" };
        mockRepo.Setup(r => r.GetByIdAsync(1)).ReturnsAsync(product);

        var controller = new ProductsController(mockRepo.Object);

        // Act
        var result = await controller.GetById(1);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnedProduct = Assert.IsType<Product>(okResult.Value);
        Assert.Equal(1, returnedProduct.Id);
    }

    [Fact]
    public async Task GetById_ReturnsNotFound_WhenProductDoesNotExist()
    {
        // Arrange
        var mockRepo = new Mock<IProductRepository>();
        mockRepo.Setup(r => r.GetByIdAsync(999)).ReturnsAsync((Product)null);

        var controller = new ProductsController(mockRepo.Object);

        // Act
        var result = await controller.GetById(999);

        // Assert
        Assert.IsType<NotFoundResult>(result);
    }
}
```

---

### Integration Testing with WebApplicationFactory

```csharp
// ============================================
// INTEGRATION TESTING
// ============================================

// Install: Microsoft.AspNetCore.Mvc.Testing

public class CustomWebApplicationFactory<TProgram> : WebApplicationFactory<TProgram>
    where TProgram : class
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove existing DbContext
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));

            if (descriptor != null)
                services.Remove(descriptor);

            // Add in-memory database
            services.AddDbContext<AppDbContext>(options =>
            {
                options.UseInMemoryDatabase("TestDb");
            });

            // Build service provider
            var sp = services.BuildServiceProvider();

            // Seed database
            using (var scope = sp.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                db.Database.EnsureCreated();

                // Seed test data
                db.Products.Add(new Product { Id = 1, Name = "Test Product" });
                db.SaveChanges();
            }
        });
    }
}

// Integration test
public class ProductsIntegrationTests : IClassFixture<CustomWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public ProductsIntegrationTests(CustomWebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetProducts_ReturnsSuccessAndProducts()
    {
        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        response.EnsureSuccessStatusCode();
        var products = await response.Content.ReadFromJsonAsync<List<Product>>();
        Assert.NotEmpty(products);
    }

    [Fact]
    public async Task GetProduct_ReturnsProduct_WhenExists()
    {
        // Act
        var response = await _client.GetAsync("/api/products/1");

        // Assert
        response.EnsureSuccessStatusCode();
        var product = await response.Content.ReadFromJsonAsync<Product>();
        Assert.Equal(1, product.Id);
    }

    [Fact]
    public async Task GetProduct_ReturnsNotFound_WhenDoesNotExist()
    {
        // Act
        var response = await _client.GetAsync("/api/products/999");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateProduct_ReturnsCreated()
    {
        // Arrange
        var newProduct = new { Name = "New Product", Price = 99.99m };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", newProduct);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var product = await response.Content.ReadFromJsonAsync<Product>();
        Assert.Equal("New Product", product.Name);
    }
}
```

---

### Testing with Authentication

```csharp
// ============================================
// TESTING WITH AUTHENTICATION
// ============================================

public class AuthenticatedTests : IClassFixture<CustomWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public AuthenticatedTests(CustomWebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                // Add test authentication
                services.AddAuthentication("Test")
                    .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", options => { });
            });
        }).CreateClient();
    }

    [Fact]
    public async Task SecureEndpoint_ReturnsOk_WhenAuthenticated()
    {
        // Arrange
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Test");

        // Act
        var response = await _client.GetAsync("/api/secure");

        // Assert
        response.EnsureSuccessStatusCode();
    }
}

// Test authentication handler
public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public TestAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        ISystemClock clock)
        : base(options, logger, encoder, clock)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "Test User"),
            new Claim(ClaimTypes.NameIdentifier, "123"),
            new Claim(ClaimTypes.Role, "Admin")
        };

        var identity = new ClaimsIdentity(claims, "Test");
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, "Test");

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
```

---

### Repository Testing

```csharp
// ============================================
// REPOSITORY TESTING
// ============================================

public class ProductRepositoryTests
{
    private DbContextOptions<AppDbContext> CreateNewContextOptions()
    {
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsProduct_WhenExists()
    {
        // Arrange
        var options = CreateNewContextOptions();

        using (var context = new AppDbContext(options))
        {
            context.Products.Add(new Product { Id = 1, Name = "Test" });
            await context.SaveChangesAsync();
        }

        // Act
        using (var context = new AppDbContext(options))
        {
            var repository = new ProductRepository(context);
            var product = await repository.GetByIdAsync(1);

            // Assert
            Assert.NotNull(product);
            Assert.Equal("Test", product.Name);
        }
    }

    [Fact]
    public async Task AddAsync_AddsProduct()
    {
        // Arrange
        var options = CreateNewContextOptions();
        var newProduct = new Product { Name = "New Product" };

        // Act
        using (var context = new AppDbContext(options))
        {
            var repository = new ProductRepository(context);
            await repository.AddAsync(newProduct);
        }

        // Assert
        using (var context = new AppDbContext(options))
        {
            Assert.Equal(1, await context.Products.CountAsync());
        }
    }
}
```

---

### Testing Middleware

```csharp
// ============================================
// MIDDLEWARE TESTING
// ============================================

public class CustomMiddlewareTests
{
    [Fact]
    public async Task Middleware_AddsCustomHeader()
    {
        // Arrange
        var middleware = new CustomMiddleware(next: (innerHttpContext) =>
        {
            return Task.CompletedTask;
        });

        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        Assert.True(context.Response.Headers.ContainsKey("X-Custom-Header"));
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use AAA pattern (Arrange, Act, Assert)
[Fact]
public void Test()
{
    // Arrange
    var service = new MyService();

    // Act
    var result = service.DoSomething();

    // Assert
    Assert.Equal(expected, result);
}

// 2. ✅ Use descriptive test names
[Fact]
public void GetById_ReturnsNotFound_WhenProductDoesNotExist() { }

// 3. ✅ One assertion per test (generally)
[Fact]
public void Test_OneAssertion()
{
    var result = Calculate();
    Assert.Equal(10, result);
}

// 4. ✅ Use test fixtures for shared setup
public class MyTests : IClassFixture<DatabaseFixture> { }

// 5. ✅ Test edge cases and error scenarios
[Theory]
[InlineData(null)]
[InlineData("")]
[InlineData("   ")]
public void Validate_ThrowsException_WhenInputInvalid(string input) { }

// 6. ✅ Use in-memory database for integration tests
options.UseInMemoryDatabase("TestDb");

// 7. ✅ Mock external dependencies
var mockRepo = new Mock<IProductRepository>();

// 8. ✅ Test both success and failure paths
[Fact] public void Success_Test() { }
[Fact] public void Failure_Test() { }

// 9. ✅ Use Theory for parameterized tests
[Theory]
[InlineData(1, 2, 3)]
[InlineData(5, 5, 10)]
public void Add_ReturnsSum(int a, int b, int expected) { }

// 10. ✅ Keep tests isolated and independent
// Each test should clean up after itself
```

---

## Q236: What is SignalR and how do you use it in ASP.NET Core?

**Answer:**

**SignalR** is a library for adding real-time web functionality to applications, enabling server-side code to push content to clients instantly.

### SignalR Hub

```csharp
// ============================================
// SIGNALR HUB
// ============================================

// Hub
public class ChatHub : Hub
{
    public async Task SendMessage(string user, string message)
    {
        // Broadcast to all clients
        await Clients.All.SendAsync("ReceiveMessage", user, message);
    }

    public async Task SendMessageToUser(string userId, string message)
    {
        // Send to specific user
        await Clients.User(userId).SendAsync("ReceiveMessage", message);
    }

    public async Task SendMessageToGroup(string groupName, string message)
    {
        // Send to group
        await Clients.Group(groupName).SendAsync("ReceiveMessage", message);
    }

    public async Task JoinGroup(string groupName)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        await Clients.Group(groupName).SendAsync("UserJoined", Context.ConnectionId);
    }

    public async Task LeaveGroup(string groupName)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
        await Clients.Group(groupName).SendAsync("UserLeft", Context.ConnectionId);
    }

    public override async Task OnConnectedAsync()
    {
        await Clients.All.SendAsync("UserConnected", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception exception)
    {
        await Clients.All.SendAsync("UserDisconnected", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}

// Program.cs
builder.Services.AddSignalR();

var app = builder.Build();

app.MapHub<ChatHub>("/chatHub");

app.Run();
```

---

### JavaScript Client

```javascript
// ============================================
// SIGNALR JAVASCRIPT CLIENT
// ============================================

// Install: @microsoft/signalr

const connection = new signalR.HubConnectionBuilder()
    .withUrl("/chatHub")
    .withAutomaticReconnect()
    .configureLogging(signalR.LogLevel.Information)
    .build();

// Receive messages
connection.on("ReceiveMessage", (user, message) => {
    console.log(`${user}: ${message}`);
    displayMessage(user, message);
});

// Start connection
async function start() {
    try {
        await connection.start();
        console.log("SignalR Connected");
    } catch (err) {
        console.error(err);
        setTimeout(start, 5000);
    }
}

// Send message
async function sendMessage(user, message) {
    try {
        await connection.invoke("SendMessage", user, message);
    } catch (err) {
        console.error(err);
    }
}

// Handle reconnection
connection.onreconnecting(error => {
    console.log("Reconnecting...", error);
});

connection.onreconnected(connectionId => {
    console.log("Reconnected", connectionId);
});

connection.onclose(error => {
    console.log("Connection closed", error);
});

// Start connection
start();
```

---

### .NET Client

```csharp
// ============================================
// SIGNALR .NET CLIENT
// ============================================

// Install: Microsoft.AspNetCore.SignalR.Client

var connection = new HubConnectionBuilder()
    .WithUrl("https://localhost:5001/chatHub")
    .WithAutomaticReconnect()
    .Build();

// Receive messages
connection.On<string, string>("ReceiveMessage", (user, message) =>
{
    Console.WriteLine($"{user}: {message}");
});

// Start connection
await connection.StartAsync();

// Send message
await connection.InvokeAsync("SendMessage", "User1", "Hello World!");

// Stop connection
await connection.StopAsync();
await connection.DisposeAsync();
```

---

### Strongly Typed Hubs

```csharp
// ============================================
// STRONGLY TYPED HUBS
// ============================================

// Client interface
public interface IChatClient
{
    Task ReceiveMessage(string user, string message);
    Task UserJoined(string connectionId);
    Task UserLeft(string connectionId);
}

// Hub with strongly typed clients
public class ChatHub : Hub<IChatClient>
{
    public async Task SendMessage(string user, string message)
    {
        await Clients.All.ReceiveMessage(user, message);
    }

    public override async Task OnConnectedAsync()
    {
        await Clients.All.UserJoined(Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception exception)
    {
        await Clients.All.UserLeft(Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}
```

---

### Authentication with SignalR

```csharp
// ============================================
// SIGNALR WITH AUTHENTICATION
// ============================================

// Program.cs
builder.Services.AddSignalR();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                // Get token from query string for SignalR
                var accessToken = context.Request.Query["access_token"];

                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/chatHub"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

// Hub with authorization
[Authorize]
public class SecureChatHub : Hub
{
    public async Task SendMessage(string message)
    {
        var user = Context.User.Identity.Name;
        await Clients.All.SendAsync("ReceiveMessage", user, message);
    }

    [Authorize(Roles = "Admin")]
    public async Task BroadcastAnnouncement(string message)
    {
        await Clients.All.SendAsync("ReceiveAnnouncement", message);
    }
}

// JavaScript client with token
const connection = new signalR.HubConnectionBuilder()
    .withUrl("/chatHub", {
        accessTokenFactory: () => getAccessToken()
    })
    .build();
```

---

### Real-World Examples

```csharp
// ============================================
// REAL-TIME NOTIFICATIONS HUB
// ============================================

public class NotificationHub : Hub
{
    private readonly INotificationService _notificationService;

    public NotificationHub(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User.FindFirstValue(ClaimTypes.NameIdentifier);
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");

        // Send unread notifications
        var notifications = await _notificationService.GetUnreadNotificationsAsync(userId);
        await Clients.Caller.SendAsync("ReceiveNotifications", notifications);

        await base.OnConnectedAsync();
    }

    public async Task MarkAsRead(int notificationId)
    {
        await _notificationService.MarkAsReadAsync(notificationId);
        await Clients.Caller.SendAsync("NotificationRead", notificationId);
    }
}

// Send notification from controller
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;

    public OrdersController(IHubContext<NotificationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] Order order)
    {
        // Create order...

        // Send notification to user
        await _hubContext.Clients
            .Group($"user_{order.UserId}")
            .SendAsync("ReceiveNotification", new
            {
                Message = "Order created successfully",
                OrderId = order.Id
            });

        return Ok(order);
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use strongly typed hubs
public class ChatHub : Hub<IChatClient> { }

// 2. ✅ Use groups for targeting messages
await Groups.AddToGroupAsync(Context.ConnectionId, "GroupName");

// 3. ✅ Implement automatic reconnection
.WithAutomaticReconnect()

// 4. ✅ Handle connection lifecycle
public override async Task OnConnectedAsync() { }
public override async Task OnDisconnectedAsync(Exception ex) { }

// 5. ✅ Use authentication for secure hubs
[Authorize]
public class SecureHub : Hub { }

// 6. ✅ Scale with Azure SignalR Service or Redis backplane
builder.Services.AddSignalR().AddAzureSignalR();

// 7. ✅ Send targeted messages
await Clients.User(userId).SendAsync(...);
await Clients.Group(groupName).SendAsync(...);
await Clients.Caller.SendAsync(...);

// 8. ❌ Don't perform long-running operations in hub methods
// Offload to background service

// 9. ✅ Use IHubContext for sending from outside hubs
private readonly IHubContext<ChatHub> _hubContext;

// 10. ✅ Configure CORS for SignalR
builder.Services.AddCors(options =>
{
    options.AddPolicy("SignalRPolicy", builder =>
        builder.WithOrigins("https://example.com")
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials());
});
```

---

## Q237: What is gRPC and how do you use it in ASP.NET Core?

**Answer:**

**gRPC** is a high-performance RPC (Remote Procedure Call) framework using HTTP/2 and Protocol Buffers for efficient communication between services.

### Creating a gRPC Service

```protobuf
// ============================================
// PROTO FILE (Protos/greet.proto)
// ============================================

syntax = "proto3";

option csharp_namespace = "GrpcService";

package greet;

// The greeting service definition
service Greeter {
  // Unary RPC
  rpc SayHello (HelloRequest) returns (HelloReply);

  // Server streaming
  rpc SayHellos (HelloRequest) returns (stream HelloReply);

  // Client streaming
  rpc SayHelloMany (stream HelloRequest) returns (HelloReply);

  // Bidirectional streaming
  rpc SayHelloChat (stream HelloRequest) returns (stream HelloReply);
}

message HelloRequest {
  string name = 1;
}

message HelloReply {
  string message = 1;
}
```

```csharp
// ============================================
// GRPC SERVICE IMPLEMENTATION
// ============================================

using Grpc.Core;

public class GreeterService : Greeter.GreeterBase
{
    private readonly ILogger<GreeterService> _logger;

    public GreeterService(ILogger<GreeterService> logger)
    {
        _logger = logger;
    }

    // Unary RPC - Single request, single response
    public override Task<HelloReply> SayHello(HelloRequest request, ServerCallContext context)
    {
        _logger.LogInformation("Saying hello to {Name}", request.Name);

        return Task.FromResult(new HelloReply
        {
            Message = $"Hello {request.Name}"
        });
    }

    // Server streaming - Single request, stream of responses
    public override async Task SayHellos(
        HelloRequest request,
        IServerStreamWriter<HelloReply> responseStream,
        ServerCallContext context)
    {
        for (int i = 0; i < 5; i++)
        {
            await responseStream.WriteAsync(new HelloReply
            {
                Message = $"Hello {request.Name} #{i + 1}"
            });

            await Task.Delay(1000);
        }
    }

    // Client streaming - Stream of requests, single response
    public override async Task<HelloReply> SayHelloMany(
        IAsyncStreamReader<HelloRequest> requestStream,
        ServerCallContext context)
    {
        var names = new List<string>();

        await foreach (var request in requestStream.ReadAllAsync())
        {
            names.Add(request.Name);
        }

        return new HelloReply
        {
            Message = $"Hello {string.Join(", ", names)}"
        };
    }

    // Bidirectional streaming - Stream of requests, stream of responses
    public override async Task SayHelloChat(
        IAsyncStreamReader<HelloRequest> requestStream,
        IServerStreamWriter<HelloReply> responseStream,
        ServerCallContext context)
    {
        await foreach (var request in requestStream.ReadAllAsync())
        {
            await responseStream.WriteAsync(new HelloReply
            {
                Message = $"Echo: Hello {request.Name}"
            });
        }
    }
}

// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddGrpc();

var app = builder.Build();

app.MapGrpcService<GreeterService>();

app.Run();
```

---

### gRPC Client

```csharp
// ============================================
// GRPC CLIENT
// ============================================

// Install: Grpc.Net.Client, Google.Protobuf, Grpc.Tools

using var channel = GrpcChannel.ForAddress("https://localhost:5001");
var client = new Greeter.GreeterClient(channel);

// Unary call
var reply = await client.SayHelloAsync(new HelloRequest { Name = "World" });
Console.WriteLine($"Response: {reply.Message}");

// Server streaming
var streamingCall = client.SayHellos(new HelloRequest { Name = "Streaming User" });

await foreach (var response in streamingCall.ResponseStream.ReadAllAsync())
{
    Console.WriteLine($"Received: {response.Message}");
}

// Client streaming
using var call = client.SayHelloMany();

foreach (var name in new[] { "Alice", "Bob", "Charlie" })
{
    await call.RequestStream.WriteAsync(new HelloRequest { Name = name });
}

await call.RequestStream.CompleteAsync();
var result = await call.ResponseAsync;
Console.WriteLine($"Result: {result.Message}");

// Bidirectional streaming
using var chatCall = client.SayHelloChat();

var readTask = Task.Run(async () =>
{
    await foreach (var response in chatCall.ResponseStream.ReadAllAsync())
    {
        Console.WriteLine($"Received: {response.Message}");
    }
});

for (int i = 0; i < 5; i++)
{
    await chatCall.RequestStream.WriteAsync(new HelloRequest { Name = $"User {i}" });
    await Task.Delay(1000);
}

await chatCall.RequestStream.CompleteAsync();
await readTask;
```

---

### Product Service Example

```protobuf
// ============================================
// PRODUCT SERVICE PROTO
// ============================================

syntax = "proto3";

option csharp_namespace = "ProductService";

service ProductsService {
  rpc GetProduct (GetProductRequest) returns (ProductResponse);
  rpc GetProducts (Empty) returns (stream ProductResponse);
  rpc CreateProduct (CreateProductRequest) returns (ProductResponse);
  rpc UpdateProduct (UpdateProductRequest) returns (ProductResponse);
  rpc DeleteProduct (DeleteProductRequest) returns (Empty);
}

message GetProductRequest {
  int32 id = 1;
}

message CreateProductRequest {
  string name = 1;
  double price = 2;
  string description = 3;
}

message UpdateProductRequest {
  int32 id = 1;
  string name = 2;
  double price = 3;
  string description = 4;
}

message DeleteProductRequest {
  int32 id = 1;
}

message ProductResponse {
  int32 id = 1;
  string name = 2;
  double price = 3;
  string description = 4;
}

message Empty {}
```

```csharp
// Implementation
public class ProductsService : ProductsService.ProductsServiceBase
{
    private readonly IProductRepository _repository;

    public ProductsService(IProductRepository repository)
    {
        _repository = repository;
    }

    public override async Task<ProductResponse> GetProduct(
        GetProductRequest request,
        ServerCallContext context)
    {
        var product = await _repository.GetByIdAsync(request.Id);

        if (product == null)
        {
            throw new RpcException(new Status(StatusCode.NotFound, "Product not found"));
        }

        return new ProductResponse
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            Description = product.Description
        };
    }

    public override async Task GetProducts(
        Empty request,
        IServerStreamWriter<ProductResponse> responseStream,
        ServerCallContext context)
    {
        var products = await _repository.GetAllAsync();

        foreach (var product in products)
        {
            await responseStream.WriteAsync(new ProductResponse
            {
                Id = product.Id,
                Name = product.Name,
                Price = product.Price,
                Description = product.Description
            });
        }
    }

    public override async Task<ProductResponse> CreateProduct(
        CreateProductRequest request,
        ServerCallContext context)
    {
        var product = new Product
        {
            Name = request.Name,
            Price = request.Price,
            Description = request.Description
        };

        await _repository.AddAsync(product);

        return new ProductResponse
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            Description = product.Description
        };
    }
}
```

---

### gRPC with Authentication

```csharp
// ============================================
// GRPC WITH JWT AUTHENTICATION
// ============================================

// Server
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidIssuer = "your-issuer",
            ValidAudience = "your-audience",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("your-secret-key"))
        };
    });

builder.Services.AddAuthorization();

[Authorize]
public class SecureProductsService : ProductsService.ProductsServiceBase
{
    public override async Task<ProductResponse> GetProduct(
        GetProductRequest request,
        ServerCallContext context)
    {
        var user = context.GetHttpContext().User;
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);

        // Authorized logic
    }
}

// Client with token
var credentials = CallCredentials.FromInterceptor((context, metadata) =>
{
    metadata.Add("Authorization", $"Bearer {token}");
    return Task.CompletedTask;
});

var channel = GrpcChannel.ForAddress("https://localhost:5001", new GrpcChannelOptions
{
    Credentials = ChannelCredentials.Create(new SslCredentials(), credentials)
});
```

---

### Best Practices

```csharp
// 1. ✅ Use HTTP/2 for gRPC
// gRPC requires HTTP/2

// 2. ✅ Use streaming for large datasets
public override async Task GetProducts(...) { }

// 3. ✅ Handle errors with RpcException
throw new RpcException(new Status(StatusCode.NotFound, "Not found"));

// 4. ✅ Use interceptors for cross-cutting concerns
builder.Services.AddGrpc(options =>
{
    options.Interceptors.Add<LoggingInterceptor>();
});

// 5. ✅ Enable detailed errors in development
builder.Services.AddGrpc(options =>
{
    options.EnableDetailedErrors = true;
});

// 6. ✅ Use Protocol Buffers for efficient serialization
// Faster than JSON

// 7. ✅ Implement health checks
service Health {
  rpc Check(HealthCheckRequest) returns (HealthCheckResponse);
}

// 8. ✅ Use deadlines/timeouts
var call = client.SayHelloAsync(request, deadline: DateTime.UtcNow.AddSeconds(5));

// 9. ✅ Configure max message size for large payloads
builder.Services.AddGrpc(options =>
{
    options.MaxReceiveMessageSize = 16 * 1024 * 1024; // 16MB
});

// 10. ✅ Use gRPC-Web for browser clients
builder.Services.AddGrpc().AddJsonTranscoding();
```

---

## Q238: What are Minimal APIs in ASP.NET Core?

**Answer:**

**Minimal APIs** provide a simplified approach to building HTTP APIs with minimal code and configuration.

### Basic Minimal API

```csharp
// ============================================
// MINIMAL API BASICS
// ============================================

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

// Simple GET endpoint
app.MapGet("/", () => "Hello World!");

// GET with route parameter
app.MapGet("/products/{id}", (int id) => new { Id = id, Name = "Product" });

// GET with query parameters
app.MapGet("/search", (string? term, int page = 1) =>
{
    return new { Term = term, Page = page };
});

// POST endpoint
app.MapPost("/products", (Product product) =>
{
    return Results.Created($"/products/{product.Id}", product);
});

// PUT endpoint
app.MapPut("/products/{id}", (int id, Product product) =>
{
    return Results.NoContent();
});

// DELETE endpoint
app.MapDelete("/products/{id}", (int id) =>
{
    return Results.NoContent();
});

app.Run();

record Product(int Id, string Name, decimal Price);
```

---

### Dependency Injection in Minimal APIs

```csharp
// ============================================
// MINIMAL API WITH SERVICES
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Register services
builder.Services.AddDbContext<AppDbContext>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();

var app = builder.Build();

// Inject services
app.MapGet("/products", async (IProductRepository repository) =>
{
    var products = await repository.GetAllAsync();
    return Results.Ok(products);
});

app.MapGet("/products/{id}", async (int id, IProductRepository repository) =>
{
    var product = await repository.GetByIdAsync(id);

    return product is null
        ? Results.NotFound()
        : Results.Ok(product);
});

app.MapPost("/products", async (Product product, IProductRepository repository) =>
{
    await repository.AddAsync(product);
    return Results.Created($"/products/{product.Id}", product);
});

app.Run();
```

---

### Route Groups and Organization

```csharp
// ============================================
// ROUTE GROUPS
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();

var app = builder.Build();

// Create route group
var productsGroup = app.MapGroup("/api/products");

productsGroup.MapGet("/", GetAllProducts);
productsGroup.MapGet("/{id}", GetProduct);
productsGroup.MapPost("/", CreateProduct);
productsGroup.MapPut("/{id}", UpdateProduct);
productsGroup.MapDelete("/{id}", DeleteProduct);

app.Run();

// Handler methods
static async Task<IResult> GetAllProducts(IProductRepository repository)
{
    var products = await repository.GetAllAsync();
    return Results.Ok(products);
}

static async Task<IResult> GetProduct(int id, IProductRepository repository)
{
    var product = await repository.GetByIdAsync(id);
    return product is null ? Results.NotFound() : Results.Ok(product);
}

static async Task<IResult> CreateProduct(Product product, IProductRepository repository)
{
    await repository.AddAsync(product);
    return Results.Created($"/api/products/{product.Id}", product);
}

static async Task<IResult> UpdateProduct(int id, Product product, IProductRepository repository)
{
    await repository.UpdateAsync(product);
    return Results.NoContent();
}

static async Task<IResult> DeleteProduct(int id, IProductRepository repository)
{
    await repository.DeleteAsync(id);
    return Results.NoContent();
}
```

---

### Validation and Filters

```csharp
// ============================================
// VALIDATION AND FILTERS
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add validation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddValidatorsFromAssemblyContaining<ProductValidator>();

var app = builder.Build();

// Endpoint with validation
app.MapPost("/products", async (Product product, IValidator<Product> validator, IProductRepository repository) =>
{
    var validationResult = await validator.ValidateAsync(product);

    if (!validationResult.IsValid)
    {
        return Results.ValidationProblem(validationResult.ToDictionary());
    }

    await repository.AddAsync(product);
    return Results.Created($"/products/{product.Id}", product);
});

// Add endpoint filter
app.MapGet("/products/{id}", async (int id, IProductRepository repository) =>
{
    var product = await repository.GetByIdAsync(id);
    return product is null ? Results.NotFound() : Results.Ok(product);
})
.AddEndpointFilter(async (context, next) =>
{
    // Before execution
    Console.WriteLine("Before endpoint execution");

    var result = await next(context);

    // After execution
    Console.WriteLine("After endpoint execution");

    return result;
});

app.Run();
```

---

### Authentication and Authorization

```csharp
// ============================================
// MINIMAL API WITH AUTH
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer();

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

// Public endpoint
app.MapGet("/public", () => "Public data");

// Authenticated endpoint
app.MapGet("/secure", () => "Secure data")
    .RequireAuthorization();

// Role-based endpoint
app.MapGet("/admin", () => "Admin data")
    .RequireAuthorization("Admin");

// Policy-based endpoint
app.MapPost("/products", async (Product product, IProductRepository repository) =>
{
    await repository.AddAsync(product);
    return Results.Created($"/products/{product.Id}", product);
})
.RequireAuthorization(policy => policy.RequireRole("Admin", "Manager"));

app.Run();
```

---

### OpenAPI/Swagger Support

```csharp
// ============================================
// MINIMAL API WITH SWAGGER
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Documented endpoints
app.MapGet("/products", async (IProductRepository repository) =>
{
    return await repository.GetAllAsync();
})
.WithName("GetProducts")
.WithTags("Products")
.WithOpenApi();

app.MapPost("/products", async (Product product, IProductRepository repository) =>
{
    await repository.AddAsync(product);
    return Results.Created($"/products/{product.Id}", product);
})
.WithName("CreateProduct")
.WithTags("Products")
.Produces<Product>(StatusCodes.Status201Created)
.ProducesValidationProblem()
.WithOpenApi();

app.Run();
```

---

### Best Practices

```csharp
// 1. ✅ Use route groups for organization
var apiGroup = app.MapGroup("/api");

// 2. ✅ Extract handlers to methods for complex logic
static async Task<IResult> ComplexHandler(...) { }

// 3. ✅ Use Results helpers for responses
return Results.Ok(data);
return Results.NotFound();
return Results.BadRequest();

// 4. ✅ Add OpenAPI documentation
.WithOpenApi()
.WithTags("Products")

// 5. ✅ Use endpoint filters for cross-cutting concerns
.AddEndpointFilter<LoggingFilter>()

// 6. ✅ Leverage dependency injection
app.MapGet("/", (IService service) => service.DoWork());

// 7. ✅ Use validation
var validationResult = await validator.ValidateAsync(model);

// 8. ✅ Apply authorization
.RequireAuthorization("PolicyName")

// 9. ✅ Use typed results for better testing
return TypedResults.Ok(data);

// 10. ✅ Keep it minimal - use controllers for complex scenarios
// Minimal APIs are great for simple APIs
// Use controllers for complex scenarios with many actions
```

---

## Q239: What are the key performance optimization techniques in ASP.NET Core?

**Answer:**

Performance optimization in ASP.NET Core involves multiple strategies to improve response times, throughput, and resource utilization.

### Response Compression

```csharp
// ============================================
// RESPONSE COMPRESSION
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});

builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});

var app = builder.Build();

app.UseResponseCompression();

app.Run();
```

---

### Async/Await Best Practices

```csharp
// ============================================
// ASYNC/AWAIT OPTIMIZATION
// ============================================

// ✅ GOOD - Async all the way
[HttpGet]
public async Task<IActionResult> GetData()
{
    var data = await _repository.GetDataAsync();
    return Ok(data);
}

// ❌ BAD - Blocking async code
[HttpGet]
public IActionResult GetDataBad()
{
    var data = _repository.GetDataAsync().Result;  // Blocks thread!
    return Ok(data);
}

// ✅ GOOD - Parallel execution
public async Task<IActionResult> GetMultipleData()
{
    var task1 = _repository.GetData1Async();
    var task2 = _repository.GetData2Async();
    var task3 = _repository.GetData3Async();

    await Task.WhenAll(task1, task2, task3);

    return Ok(new { task1.Result, task2.Result, task3.Result });
}

// ✅ GOOD - ValueTask for hot paths
public async ValueTask<Product> GetCachedProductAsync(int id)
{
    if (_cache.TryGetValue(id, out Product product))
    {
        return product;  // Synchronous path
    }

    product = await _repository.GetByIdAsync(id);
    _cache.Set(id, product);
    return product;
}
```

---

### Connection Pooling

```csharp
// ============================================
// DATABASE CONNECTION POOLING
// ============================================

// ✅ GOOD - Connection pooling enabled by default
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// Configure pool size
var connectionString = "Server=...;Max Pool Size=100;Min Pool Size=10;";

// ✅ GOOD - HttpClient pooling
builder.Services.AddHttpClient<IExternalApiService, ExternalApiService>()
    .SetHandlerLifetime(TimeSpan.FromMinutes(5));

// ❌ BAD - Creating HttpClient in controller
public class BadController : ControllerBase
{
    public async Task<IActionResult> Get()
    {
        using var client = new HttpClient();  // Don't do this!
        var response = await client.GetAsync("https://api.example.com");
        return Ok(response);
    }
}
```

---

### Output Caching (.NET 7+)

```csharp
// ============================================
// OUTPUT CACHING
// ============================================

builder.Services.AddOutputCache(options =>
{
    options.AddBasePolicy(builder => builder.Expire(TimeSpan.FromSeconds(10)));
});

var app = builder.Build();

app.UseOutputCache();

app.MapGet("/products", async (IProductRepository repository) =>
{
    return await repository.GetAllAsync();
})
.CacheOutput(policy => policy.Expire(TimeSpan.FromMinutes(5)));

app.Run();
```

---

### Object Pooling

```csharp
// ============================================
// OBJECT POOLING
// ============================================

// Create object pool
public class MyObjectPool
{
    private readonly ObjectPool<StringBuilder> _pool;

    public MyObjectPool()
    {
        var provider = new DefaultObjectPoolProvider();
        _pool = provider.Create(new StringBuilderPooledObjectPolicy());
    }

    public string ProcessData(string input)
    {
        var sb = _pool.Get();
        try
        {
            sb.Clear();
            sb.Append("Processed: ");
            sb.Append(input);
            return sb.ToString();
        }
        finally
        {
            _pool.Return(sb);
        }
    }
}

// ArrayPool for byte arrays
public class ImageProcessor
{
    public byte[] ProcessImage(byte[] input)
    {
        var buffer = ArrayPool<byte>.Shared.Rent(1024);
        try
        {
            // Process image
            return buffer;
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }
}
```

---

### Lazy Loading and Pagination

```csharp
// ============================================
// PAGINATION
// ============================================

public class PagedResult<T>
{
    public List<T> Items { get; set; }
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
}

[HttpGet]
public async Task<ActionResult<PagedResult<Product>>> GetProducts(
    int page = 1,
    int pageSize = 10)
{
    var query = _context.Products.AsQueryable();

    var totalCount = await query.CountAsync();

    var items = await query
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync();

    return new PagedResult<Product>
    {
        Items = items,
        TotalCount = totalCount,
        PageNumber = page,
        PageSize = pageSize
    };
}
```

---

### Response Caching

```csharp
// ============================================
// RESPONSE CACHING HEADERS
// ============================================

[HttpGet("{id}")]
[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Any)]
public async Task<IActionResult> GetProduct(int id)
{
    var product = await _repository.GetByIdAsync(id);

    if (product == null)
        return NotFound();

    // Set ETag for conditional requests
    var etag = $"\"{product.Id}-{product.LastModified.Ticks}\"";
    Response.Headers.ETag = etag;

    // Check If-None-Match
    if (Request.Headers.IfNoneMatch == etag)
    {
        return StatusCode(StatusCodes.Status304NotModified);
    }

    return Ok(product);
}
```

---

### JSON Serialization Optimization

```csharp
// ============================================
// JSON OPTIMIZATION
// ============================================

// Use System.Text.Json (faster than Newtonsoft.Json)
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
        options.JsonSerializerOptions.WriteIndented = false;  // Smaller payload
    });

// Source generators for better performance (.NET 6+)
[JsonSerializable(typeof(Product))]
[JsonSerializable(typeof(List<Product>))]
public partial class AppJsonContext : JsonSerializerContext
{
}

// Use in minimal API
app.MapGet("/products", async (IProductRepository repository) =>
{
    var products = await repository.GetAllAsync();
    return Results.Json(products, AppJsonContext.Default.ListProduct);
});
```

---

### Database Query Optimization

```csharp
// ============================================
// EF CORE OPTIMIZATION
// ============================================

// ✅ GOOD - Projection (Select only needed fields)
var products = await _context.Products
    .Select(p => new { p.Id, p.Name, p.Price })
    .ToListAsync();

// ✅ GOOD - AsNoTracking for read-only queries
var products = await _context.Products
    .AsNoTracking()
    .ToListAsync();

// ✅ GOOD - Include for eager loading
var orders = await _context.Orders
    .Include(o => o.Customer)
    .Include(o => o.Items)
    .ToListAsync();

// ✅ GOOD - Split queries for collections
var orders = await _context.Orders
    .Include(o => o.Items)
    .AsSplitQuery()
    .ToListAsync();

// ✅ GOOD - Compiled queries for frequently used queries
private static readonly Func<AppDbContext, int, Task<Product>> GetProductById =
    EF.CompileAsyncQuery((AppDbContext context, int id) =>
        context.Products.FirstOrDefault(p => p.Id == id));

public async Task<Product> GetProductAsync(int id)
{
    return await GetProductById(_context, id);
}

// ✅ GOOD - Batch operations
await _context.Products.Where(p => p.Price < 10).ExecuteDeleteAsync();
await _context.Products.Where(p => p.InStock == false)
    .ExecuteUpdateAsync(s => s.SetProperty(p => p.Discontinued, true));
```

---

### Minimize Allocations

```csharp
// ============================================
// REDUCE ALLOCATIONS
// ============================================

// ✅ GOOD - String interpolation with DefaultInterpolatedStringHandler
public string FormatProduct(Product product)
{
    return $"Product: {product.Name}, Price: {product.Price:C}";
}

// ✅ GOOD - Span<T> for string manipulation
public ReadOnlySpan<char> ParseProductCode(string input)
{
    return input.AsSpan(0, 10);
}

// ✅ GOOD - stackalloc for small arrays
public void ProcessSmallArray()
{
    Span<int> numbers = stackalloc int[10];
    for (int i = 0; i < numbers.Length; i++)
    {
        numbers[i] = i * 2;
    }
}

// ✅ GOOD - Avoid boxing
int value = 42;
Console.WriteLine(value);  // No boxing

// ❌ BAD - Boxing
object boxed = value;  // Boxing!
Console.WriteLine(boxed);
```

---

### Best Practices

```csharp
// 1. ✅ Use async/await properly
public async Task<IActionResult> Get()
{
    var data = await _service.GetDataAsync();
    return Ok(data);
}

// 2. ✅ Enable response compression
builder.Services.AddResponseCompression();

// 3. ✅ Use connection pooling
// Enabled by default for DbContext and HttpClient

// 4. ✅ Implement caching strategies
builder.Services.AddResponseCaching();
builder.Services.AddMemoryCache();
builder.Services.AddDistributedRedisCache();

// 5. ✅ Use pagination for large datasets
.Skip((page - 1) * pageSize).Take(pageSize)

// 6. ✅ Optimize database queries
.AsNoTracking()
.Select(p => new { p.Id, p.Name })

// 7. ✅ Use CDN for static files
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.CacheControl = "public,max-age=31536000";
    }
});

// 8. ✅ Profile and measure
// Use Application Insights, dotnet-counters, BenchmarkDotNet

// 9. ✅ Minimize middleware
// Only use middleware you need

// 10. ✅ Use HTTP/2 and HTTP/3
builder.WebHost.ConfigureKestrel(options =>
{
    options.ConfigureHttpsDefaults(https =>
    {
        https.SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13;
    });
});
```

---

## Q240: How do you deploy and host ASP.NET Core applications?

**Answer:**

ASP.NET Core applications can be deployed to various platforms including IIS, Azure, Docker, and Linux servers.

### Publishing the Application

```bash
# ============================================
# PUBLISH COMMANDS
# ============================================

# Development build
dotnet build

# Release build
dotnet build -c Release

# Publish (self-contained)
dotnet publish -c Release -r win-x64 --self-contained

# Publish (framework-dependent)
dotnet publish -c Release

# Publish to folder
dotnet publish -c Release -o ./publish

# Publish with single file
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true

# Publish trimmed (smaller size)
dotnet publish -c Release -r linux-x64 --self-contained -p:PublishTrimmed=true
```

---

### Deploying to IIS

```xml
<!-- ============================================
     WEB.CONFIG FOR IIS
     ============================================ -->

<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet"
                  arguments=".\MyApp.dll"
                  stdoutLogEnabled="false"
                  stdoutLogFile=".\logs\stdout"
                  hostingModel="inprocess" />
    </system.webServer>
  </location>
</configuration>
```

```powershell
# Install ASP.NET Core Hosting Bundle on IIS server
# https://dotnet.microsoft.com/download/dotnet

# Create IIS application pool (.NET CLR version: No Managed Code)
# Deploy files to wwwroot folder
# Configure app pool identity and permissions
```

---

### Deploying to Azure App Service

```bash
# ============================================
# AZURE DEPLOYMENT
# ============================================

# Install Azure CLI
# Login to Azure
az login

# Create resource group
az group create --name myResourceGroup --location eastus

# Create App Service plan
az appservice plan create \
  --name myAppServicePlan \
  --resource-group myResourceGroup \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group myResourceGroup \
  --plan myAppServicePlan \
  --name myapp-uniquename \
  --runtime "DOTNET|8.0"

# Deploy from local git
az webapp deployment source config-local-git \
  --name myapp-uniquename \
  --resource-group myResourceGroup

# Or deploy zip file
az webapp deployment source config-zip \
  --resource-group myResourceGroup \
  --name myapp-uniquename \
  --src myapp.zip

# Configure app settings
az webapp config appsettings set \
  --resource-group myResourceGroup \
  --name myapp-uniquename \
  --settings ConnectionStrings__DefaultConnection="Server=..."
```

---

### Docker Deployment

```dockerfile
# ============================================
# DOCKERFILE
# ============================================

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApp/MyApp.csproj", "MyApp/"]
RUN dotnet restore "MyApp/MyApp.csproj"
COPY . .
WORKDIR "/src/MyApp"
RUN dotnet build "MyApp.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "MyApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 80
EXPOSE 443
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

```yaml
# ============================================
# DOCKER-COMPOSE.YML
# ============================================

version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "5000:80"
      - "5001:443"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=db;Database=MyApp;User=sa;Password=YourPassword123
    depends_on:
      - db

  db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourPassword123
    ports:
      - "1433:1433"
    volumes:
      - sql_data:/var/opt/mssql

volumes:
  sql_data:
```

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop
docker-compose down
```

---

### Kubernetes Deployment

```yaml
# ============================================
# KUBERNETES DEPLOYMENT
# ============================================

# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: connection-string
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5

---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: myapp

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

```bash
# Deploy to Kubernetes
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# View pods
kubectl get pods

# View logs
kubectl logs -f deployment/myapp-deployment

# Scale
kubectl scale deployment/myapp-deployment --replicas=5

# Update image
kubectl set image deployment/myapp-deployment myapp=myregistry.azurecr.io/myapp:v2
```

---

### Linux Server Deployment

```bash
# ============================================
# DEPLOY TO LINUX (Ubuntu)
# ============================================

# Install .NET Runtime
wget https://dot.net/v1/dotnet-install.sh
sudo chmod +x dotnet-install.sh
sudo ./dotnet-install.sh --channel 8.0 --runtime aspnetcore

# Create systemd service file
sudo nano /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My ASP.NET Core App
After=network.target

[Service]
WorkingDirectory=/var/www/myapp
ExecStart=/usr/bin/dotnet /var/www/myapp/MyApp.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=myapp
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
sudo systemctl status myapp.service

# Configure Nginx as reverse proxy
sudo nano /etc/nginx/sites-available/myapp
```

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site and restart Nginx
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL with Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

---

### Environment-Specific Configuration

```json
// ============================================
// APPSETTINGS FILES
// ============================================

// appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}

// appsettings.Development.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyApp_Dev"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Debug"
    }
  }
}

// appsettings.Production.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=prod-server;Database=MyApp_Prod"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  }
}
```

```csharp
// Use environment variables
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("CONNECTION_STRING");
```

---

### Best Practices

```csharp
// 1. ✅ Use environment-specific configuration
ASPNETCORE_ENVIRONMENT=Production

// 2. ✅ Enable HTTPS
app.UseHttpsRedirection();

// 3. ✅ Use health checks
app.MapHealthChecks("/health");

// 4. ✅ Implement logging
builder.Services.AddLogging();

// 5. ✅ Use secrets management
// Azure Key Vault, AWS Secrets Manager, environment variables

// 6. ✅ Enable response compression
builder.Services.AddResponseCompression();

// 7. ✅ Configure reverse proxy headers
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

// 8. ✅ Monitor application
// Application Insights, ELK Stack, Prometheus

// 9. ✅ Use CI/CD pipelines
// Azure DevOps, GitHub Actions, GitLab CI

// 10. ✅ Implement graceful shutdown
builder.Services.Configure<HostOptions>(options =>
{
    options.ShutdownTimeout = TimeSpan.FromSeconds(30);
});
```

---

## Questions 221-240 Complete!

**All 20 ASP.NET Core Questions Completed!**

✅ Q221: ASP.NET Core Introduction
✅ Q222: Request Pipeline & Middleware
✅ Q223: Dependency Injection
✅ Q224: Configuration
✅ Q225: Routing
✅ Q226: Model Binding & Validation
✅ Q227: Authentication & Authorization
✅ Q228: JWT Authentication
✅ Q229: Error Handling & Logging
✅ Q230: CORS
✅ Q231: API Versioning
✅ Q232: Response Caching
✅ Q233: Background Services
✅ Q234: Health Checks
✅ Q235: Testing
✅ Q236: SignalR
✅ Q237: gRPC
✅ Q238: Minimal APIs
✅ Q239: Performance Optimization
✅ Q240: Deployment & Hosting

🎉 **Complete ASP.NET Core Interview Question Set (Q221-Q240)** 🎉
