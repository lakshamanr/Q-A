# Section 2: ASP.NET MVC & Web Development (Q71-Q80)

## Q71: What is the purpose of Configure() and ConfigureServices() methods?

**Answer:**

*(Note: This expands on Q70 with additional advanced patterns and examples)*

The `Configure()` and `ConfigureServices()` methods (or their `.NET 6+` equivalents in `Program.cs`) are the foundation of ASP.NET Core application setup, separating service registration from middleware pipeline configuration.

### 1. Advanced ConfigureServices Patterns

```csharp
public class Startup
{
    public IConfiguration Configuration { get; }
    private readonly IWebHostEnvironment _env;

    public Startup(IConfiguration configuration, IWebHostEnvironment env)
    {
        Configuration = configuration;
        _env = env;
    }

    public void ConfigureServices(IServiceCollection services)
    {
        // Conditional service registration based on environment
        if (_env.IsDevelopment())
        {
            services.AddDatabaseDeveloperPageExceptionFilter();
            services.AddSingleton<IEmailSender, DevelopmentEmailSender>();
        }
        else
        {
            services.AddSingleton<IEmailSender, ProductionEmailSender>();
            services.AddApplicationInsightsTelemetry();
        }

        // Feature flag-based registration
        var useRedis = Configuration.GetValue<bool>("Features:UseRedisCache");
        if (useRedis)
        {
            services.AddStackExchangeRedisCache(options =>
            {
                options.Configuration = Configuration.GetConnectionString("Redis");
            });
        }
        else
        {
            services.AddDistributedMemoryCache();
        }

        // Decorator pattern registration
        services.AddScoped<IProductService, ProductService>();
        services.Decorate<IProductService, CachedProductService>();
        services.Decorate<IProductService, LoggingProductService>();

        // Assembly scanning for services
        services.Scan(scan => scan
            .FromAssemblyOf<Startup>()
            .AddClasses(classes => classes.AssignableTo<ITransientService>())
            .AsImplementedInterfaces()
            .WithTransientLifetime());

        // Replace existing service
        services.Replace(ServiceDescriptor.Singleton<ILogger, CustomLogger>());

        // Remove service
        services.RemoveAll<IHostedService>();

        // Try add (only if not already registered)
        services.TryAddSingleton<ICacheService, CacheService>();
    }
}
```

### 2. Service Collection Validation

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddControllersWithViews();
    
    // Register services
    services.AddScoped<IProductRepository, ProductRepository>();
    services.AddScoped<IProductService, ProductService>();

    // Validate service registrations at startup
    ValidateServiceRegistration(services);
}

private void ValidateServiceRegistration(IServiceCollection services)
{
    var requiredServices = new[]
    {
        typeof(IProductService),
        typeof(IOrderService),
        typeof(IEmailSender)
    };

    foreach (var serviceType in requiredServices)
    {
        var descriptor = services.FirstOrDefault(d => d.ServiceType == serviceType);
        if (descriptor == null)
        {
            throw new InvalidOperationException(
                $"Required service {serviceType.Name} is not registered");
        }
    }
}

// Build and validate container
public void ConfigureServices(IServiceCollection services)
{
    services.AddControllersWithViews();
    services.AddScoped<IProductService, ProductService>();

    // Build service provider to validate
    var serviceProvider = services.BuildServiceProvider();
    
    try
    {
        // Try to resolve critical services
        var productService = serviceProvider.GetRequiredService<IProductService>();
        var logger = serviceProvider.GetRequiredService<ILogger<Startup>>();
        
        logger.LogInformation("All required services validated successfully");
    }
    catch (Exception ex)
    {
        throw new InvalidOperationException("Service validation failed", ex);
    }
}
```

### 3. Advanced Configure Patterns

```csharp
public void Configure(
    IApplicationBuilder app,
    IWebHostEnvironment env,
    ILogger<Startup> logger,
    IHostApplicationLifetime lifetime)
{
    // Application lifetime events
    lifetime.ApplicationStarted.Register(() =>
    {
        logger.LogInformation("Application started at {Time}", DateTime.UtcNow);
    });

    lifetime.ApplicationStopping.Register(() =>
    {
        logger.LogWarning("Application is stopping...");
    });

    lifetime.ApplicationStopped.Register(() =>
    {
        logger.LogInformation("Application stopped");
    });

    // Conditional middleware based on configuration
    var enableSwagger = Configuration.GetValue<bool>("Features:EnableSwagger");
    if (env.IsDevelopment() || enableSwagger)
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    // Branch middleware pipeline
    app.MapWhen(
        context => context.Request.Path.StartsWithSegments("/api"),
        apiApp =>
        {
            apiApp.UseMiddleware<ApiAuthenticationMiddleware>();
            apiApp.UseMiddleware<ApiRateLimitingMiddleware>();
        });

    // Conditional error handling
    if (env.IsDevelopment())
    {
        app.UseDeveloperExceptionPage();
    }
    else if (env.IsStaging())
    {
        app.UseExceptionHandler("/Error");
        app.Use(async (context, next) =>
        {
            context.Response.Headers.Add("X-Environment", "Staging");
            await next();
        });
    }
    else // Production
    {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
        app.Use(async (context, next) =>
        {
            context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
            context.Response.Headers.Add("X-Frame-Options", "DENY");
            context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
            await next();
        });
    }

    // Standard pipeline
    app.UseHttpsRedirection();
    app.UseStaticFiles();
    app.UseRouting();
    app.UseAuthentication();
    app.UseAuthorization();

    // Endpoint configuration with metadata
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapControllerRoute(
            name: "default",
            pattern: "{controller=Home}/{action=Index}/{id?}")
            .RequireAuthorization(); // Require auth for all endpoints

        endpoints.MapHealthChecks("/health")
            .AllowAnonymous(); // Except health checks
    });

    // Warmup services after configuration
    WarmupServices(app.ApplicationServices, logger);
}

private void WarmupServices(IServiceProvider services, ILogger logger)
{
    using var scope = services.CreateScope();
    
    try
    {
        // Warm up database connection
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        dbContext.Database.CanConnect();
        
        // Warm up cache
        var cache = scope.ServiceProvider.GetRequiredService<IMemoryCache>();
        cache.Set("warmup", "complete");
        
        logger.LogInformation("Service warmup completed");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Service warmup failed");
    }
}
```

### 4. Module-Based Configuration

```csharp
// IServiceModule interface
public interface IServiceModule
{
    void ConfigureServices(IServiceCollection services, IConfiguration configuration);
}

// Database module
public class DatabaseModule : IServiceModule
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                sqlOptions =>
                {
                    sqlOptions.EnableRetryOnFailure(5);
                    sqlOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
                }));

        services.AddScoped<IUnitOfWork, UnitOfWork>();
    }
}

// Authentication module
public class AuthenticationModule : IServiceModule
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidIssuer = configuration["Jwt:Issuer"],
                    ValidAudience = configuration["Jwt:Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
                };
            });

        services.AddAuthorization(options =>
        {
            options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
            options.AddPolicy("CanEdit", policy => policy.RequireClaim("Permission", "Edit"));
        });
    }
}

// Application module
public class ApplicationModule : IServiceModule
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddSingleton<ICacheService, CacheService>();
        services.AddTransient<IEmailSender, EmailSender>();
    }
}

// Startup using modules
public class Startup
{
    private readonly List<IServiceModule> _modules = new()
    {
        new DatabaseModule(),
        new AuthenticationModule(),
        new ApplicationModule()
    };

    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllersWithViews();

        // Register all modules
        foreach (var module in _modules)
        {
            module.ConfigureServices(services, Configuration);
        }
    }
}
```

### 5. Testing Startup Configuration

```csharp
public class StartupTests
{
    [Fact]
    public void ConfigureServices_RegistersAllRequiredServices()
    {
        // Arrange
        var services = new ServiceCollection();
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string>
            {
                ["ConnectionStrings:DefaultConnection"] = "TestConnection"
            })
            .Build();
        
        var startup = new Startup(configuration);

        // Act
        startup.ConfigureServices(services);
        var serviceProvider = services.BuildServiceProvider();

        // Assert
        Assert.NotNull(serviceProvider.GetService<IProductService>());
        Assert.NotNull(serviceProvider.GetService<IOrderService>());
        Assert.NotNull(serviceProvider.GetService<ApplicationDbContext>());
    }

    [Fact]
    public void Configure_SetsUpMiddlewarePipeline()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddControllersWithViews();
        services.AddLogging();
        
        var serviceProvider = services.BuildServiceProvider();
        var appBuilder = new ApplicationBuilder(serviceProvider);
        
        var startup = new Startup(new ConfigurationBuilder().Build());

        // Act
        startup.Configure(appBuilder, new TestWebHostEnvironment());

        // Assert
        var app = appBuilder.Build();
        Assert.NotNull(app);
    }
}

public class TestWebHostEnvironment : IWebHostEnvironment
{
    public string WebRootPath { get; set; } = "";
    public IFileProvider WebRootFileProvider { get; set; }
    public string ApplicationName { get; set; } = "TestApp";
    public IFileProvider ContentRootFileProvider { get; set; }
    public string ContentRootPath { get; set; } = "";
    public string EnvironmentName { get; set; } = "Development";
}
```

**Key Differences Summary:**

| Aspect | ConfigureServices | Configure |
|--------|------------------|-----------|
| **Purpose** | Register dependencies | Build request pipeline |
| **Order** | Called first | Called second |
| **Returns** | void | void |
| **Parameters** | IServiceCollection | IApplicationBuilder |
| **Can inject** | No (constructor only) | Yes (any registered service) |
| **Examples** | AddDbContext, AddScoped | UseRouting, UseAuthentication |

---

## Q72: Explain the IApplicationBuilder interface

**Answer:**

`IApplicationBuilder` is used to configure the HTTP request pipeline by adding middleware components. It's the foundation for building the middleware chain that processes every HTTP request.

### 1. IApplicationBuilder Basics

```csharp
public interface IApplicationBuilder
{
    // Core members
    IServiceProvider ApplicationServices { get; set; }
    IFeatureCollection ServerFeatures { get; }
    IDictionary<string, object> Properties { get; }
    
    // Pipeline building
    IApplicationBuilder Use(Func<RequestDelegate, RequestDelegate> middleware);
    IApplicationBuilder New();
    RequestDelegate Build();
}

// Usage in Configure method
public void Configure(IApplicationBuilder app)
{
    // app is IApplicationBuilder instance
    // Used to configure middleware pipeline
    
    app.UseHttpsRedirection();  // Extension method
    app.UseStaticFiles();        // Extension method
    app.UseRouting();            // Extension method
    
    // Each Use* method returns IApplicationBuilder for chaining
}
```

### 2. Use() Method - Adding Middleware

```csharp
// Basic Use() - Inline middleware
app.Use(async (context, next) =>
{
    // Before next middleware
    Console.WriteLine($"Request: {context.Request.Path}");
    
    await next();  // Call next middleware
    
    // After next middleware
    Console.WriteLine($"Response: {context.Response.StatusCode}");
});

// Use() with branching
app.Use(async (context, next) =>
{
    if (context.Request.Path == "/healthcheck")
    {
        await context.Response.WriteAsync("Healthy");
        return;  // Short-circuit, don't call next
    }
    
    await next();
});

// Use() with custom middleware class
app.Use(async (context, next) =>
{
    var startTime = DateTime.UtcNow;
    
    await next();
    
    var duration = DateTime.UtcNow - startTime;
    Console.WriteLine($"Request took {duration.TotalMilliseconds}ms");
});
```

### 3. UseMiddleware() - Strongly-Typed Middleware

```csharp
// Custom middleware class
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
        var sw = Stopwatch.StartNew();
        
        await _next(context);
        
        sw.Stop();
        _logger.LogInformation(
            "Request {Method} {Path} took {Duration}ms",
            context.Request.Method,
            context.Request.Path,
            sw.ElapsedMilliseconds);
    }
}

// Register with UseMiddleware
app.UseMiddleware<RequestTimingMiddleware>();

// Or create extension method
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

### 4. MapWhen() - Conditional Pipeline Branching

```csharp
// Branch pipeline based on condition
app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/api"),
    apiApp =>
    {
        // This pipeline only runs for /api/* requests
        apiApp.UseMiddleware<ApiKeyAuthenticationMiddleware>();
        apiApp.UseMiddleware<ApiRateLimitingMiddleware>();
        apiApp.Use(async (context, next) =>
        {
            context.Response.Headers.Add("X-API-Version", "1.0");
            await next();
        });
    });

// Multiple branches
app.MapWhen(
    context => context.Request.Headers["X-Legacy-Client"].Count > 0,
    legacyApp =>
    {
        legacyApp.UseMiddleware<LegacyCompatibilityMiddleware>();
    });

app.MapWhen(
    context => context.Request.Query.ContainsKey("debug"),
    debugApp =>
    {
        debugApp.UseDeveloperExceptionPage();
    });

// Complex condition
app.MapWhen(
    context =>
    {
        var path = context.Request.Path.Value;
        var isAdmin = path.StartsWith("/admin");
        var hasAdminCookie = context.Request.Cookies.ContainsKey("admin_token");
        return isAdmin && !hasAdminCookie;
    },
    adminApp =>
    {
        adminApp.Run(async context =>
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("Unauthorized");
        });
    });
```

### 5. UseWhen() - Non-Terminal Branching

```csharp
// UseWhen: Branch but rejoin main pipeline
app.UseWhen(
    context => context.Request.Path.StartsWithSegments("/api"),
    apiApp =>
    {
        apiApp.UseMiddleware<ApiLoggingMiddleware>();
        // After this, request continues to main pipeline
    });

// Difference: MapWhen vs UseWhen
app.UseWhen(
    context => context.Request.Query.ContainsKey("culture"),
    cultureApp =>
    {
        cultureApp.Use(async (context, next) =>
        {
            var culture = context.Request.Query["culture"];
            Thread.CurrentThread.CurrentCulture = new CultureInfo(culture);
            await next();
        });
        // Continues to main pipeline after this
    });

// Main pipeline continues for all requests
app.UseRouting();
app.UseEndpoints(endpoints =>
{
    endpoints.MapControllers();
});
```

### 6. Run() - Terminal Middleware

```csharp
// Run() creates terminal middleware (doesn't call next)
app.Run(async context =>
{
    await context.Response.WriteAsync("Terminal middleware - end of pipeline");
});

// Run is typically used at the end
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.UseEndpoints(endpoints =>
{
    endpoints.MapControllers();
});

// Fallback Run() for 404
app.Run(async context =>
{
    context.Response.StatusCode = 404;
    await context.Response.WriteAsync("404 - Not Found");
});

// Conditional Run()
app.MapWhen(
    context => context.Request.Path == "/ping",
    pingApp =>
    {
        pingApp.Run(async context =>
        {
            await context.Response.WriteAsync("pong");
        });
    });
```

### 7. ApplicationServices Property

```csharp
// Access dependency injection container
app.Use(async (context, next) =>
{
    // Get services from ApplicationServices
    var logger = app.ApplicationServices
        .GetRequiredService<ILogger<Startup>>();
    
    var config = app.ApplicationServices
        .GetRequiredService<IConfiguration>();
    
    logger.LogInformation("Processing request to {Path}", context.Request.Path);
    
    await next();
});

// Initialize services at startup
public void Configure(IApplicationBuilder app)
{
    // Warm up services
    using (var scope = app.ApplicationServices.CreateScope())
    {
        var dbContext = scope.ServiceProvider
            .GetRequiredService<ApplicationDbContext>();
        
        // Ensure database exists
        dbContext.Database.EnsureCreated();
        
        // Seed data
        if (!dbContext.Products.Any())
        {
            dbContext.Products.AddRange(/* seed data */);
            dbContext.SaveChanges();
        }
    }
    
    // Configure middleware
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapControllers();
    });
}
```

### 8. Properties Dictionary

```csharp
// Store application-wide data
public void Configure(IApplicationBuilder app)
{
    // Add custom properties
    app.Properties["StartTime"] = DateTime.UtcNow;
    app.Properties["Version"] = "1.0.0";
    app.Properties["InstanceId"] = Guid.NewGuid();
    
    // Access in middleware
    app.Use(async (context, next) =>
    {
        var startTime = (DateTime)app.Properties["StartTime"];
        var uptime = DateTime.UtcNow - startTime;
        
        context.Response.Headers.Add("X-Uptime-Seconds", uptime.TotalSeconds.ToString());
        
        await next();
    });
}
```

### 9. ServerFeatures

```csharp
// Access server capabilities
app.Use(async (context, next) =>
{
    var serverFeatures = app.ServerFeatures;
    
    // Check if server supports HTTP/2
    var httpFeature = serverFeatures.Get<IHttpMaxRequestBodySizeFeature>();
    if (httpFeature != null)
    {
        // Set max request body size
        httpFeature.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB
    }
    
    await next();
});

// Check server capabilities
public void Configure(IApplicationBuilder app)
{
    var features = app.ServerFeatures;
    
    // Log available features
    var logger = app.ApplicationServices.GetRequiredService<ILogger<Startup>>();
    logger.LogInformation("Available server features:");
    
    foreach (var feature in features)
    {
        logger.LogInformation("  - {FeatureType}", feature.Key);
    }
}
```

### 10. New() - Create Branch

```csharp
// Create a new branch of the pipeline
var branchBuilder = app.New();

branchBuilder.UseMiddleware<CustomMiddleware1>();
branchBuilder.UseMiddleware<CustomMiddleware2>();

// Build the branch
var branchPipeline = branchBuilder.Build();

// Use the branch conditionally
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWith("/special"))
    {
        await branchPipeline(context);
    }
    else
    {
        await next();
    }
});

// More complex branching
public void Configure(IApplicationBuilder app)
{
    // Create authenticated branch
    var authenticatedBranch = app.New();
    authenticatedBranch.UseAuthentication();
    authenticatedBranch.UseAuthorization();
    authenticatedBranch.UseMiddleware<UserActivityTrackingMiddleware>();
    var authenticatedPipeline = authenticatedBranch.Build();
    
    // Create anonymous branch
    var anonymousBranch = app.New();
    anonymousBranch.UseMiddleware<RateLimitingMiddleware>();
    var anonymousPipeline = anonymousBranch.Build();
    
    // Route to appropriate branch
    app.Use(async (context, next) =>
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            await authenticatedPipeline(context);
        }
        else
        {
            await anonymousPipeline(context);
        }
    });
}
```

### 11. Build() - Create RequestDelegate

```csharp
// Build() creates the final RequestDelegate
public class CustomApplicationBuilder
{
    private readonly List<Func<RequestDelegate, RequestDelegate>> _middlewares = new();
    
    public CustomApplicationBuilder Use(Func<RequestDelegate, RequestDelegate> middleware)
    {
        _middlewares.Add(middleware);
        return this;
    }
    
    public RequestDelegate Build()
    {
        // Start with terminal middleware
        RequestDelegate app = context =>
        {
            context.Response.StatusCode = 404;
            return Task.CompletedTask;
        };
        
        // Apply middlewares in reverse order
        for (int i = _middlewares.Count - 1; i >= 0; i--)
        {
            app = _middlewares[i](app);
        }
        
        return app;
    }
}

// How ASP.NET Core uses it internally
public void Configure(IApplicationBuilder app)
{
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapControllers();
    });
    
    // Internally, app.Build() is called to create RequestDelegate
    // which becomes the main application pipeline
}
```

### 12. Extension Methods Pattern

```csharp
// Create custom extension methods
public static class CustomMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestId(this IApplicationBuilder builder)
    {
        return builder.Use(async (context, next) =>
        {
            var requestId = Guid.NewGuid().ToString();
            context.Items["RequestId"] = requestId;
            context.Response.Headers.Add("X-Request-ID", requestId);
            
            await next();
        });
    }
    
    public static IApplicationBuilder UsePerformanceMonitoring(
        this IApplicationBuilder builder,
        int thresholdMs = 1000)
    {
        return builder.UseMiddleware<PerformanceMonitoringMiddleware>(thresholdMs);
    }
    
    public static IApplicationBuilder UseCustomCaching(
        this IApplicationBuilder builder,
        Action<CachingOptions> configureOptions)
    {
        var options = new CachingOptions();
        configureOptions(options);
        
        return builder.UseMiddleware<CustomCachingMiddleware>(options);
    }
}

// Usage
app.UseRequestId();
app.UsePerformanceMonitoring(thresholdMs: 500);
app.UseCustomCaching(options =>
{
    options.Duration = TimeSpan.FromMinutes(5);
    options.VaryByHeader = "Accept-Language";
});
```

**IApplicationBuilder Summary:**

| Method | Purpose | Returns Builder | Terminal |
|--------|---------|----------------|----------|
| **Use** | Add middleware | Yes | No |
| **UseMiddleware** | Add typed middleware | Yes | No |
| **Run** | Add terminal middleware | No | Yes |
| **Map** | Branch pipeline (path-based) | No | No |
| **MapWhen** | Branch pipeline (condition) | No | No |
| **UseWhen** | Branch and rejoin | Yes | No |
| **New** | Create pipeline branch | N/A | N/A |
| **Build** | Create RequestDelegate | N/A | N/A |

---


## Q73: What are hosted services in ASP.NET Core?

**Answer:**

Hosted services are background tasks that run alongside your ASP.NET Core application. They implement `IHostedService` interface and are managed by the host's lifetime.

### 1. IHostedService Interface

```csharp
public interface IHostedService
{
    // Called when application starts
    Task StartAsync(CancellationToken cancellationToken);
    
    // Called when application stops
    Task StopAsync(CancellationToken cancellationToken);
}

// Basic implementation
public class BasicHostedService : IHostedService
{
    private readonly ILogger<BasicHostedService> _logger;

    public BasicHostedService(ILogger<BasicHostedService> logger)
    {
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Hosted service starting");
        
        // Start background work
        Task.Run(async () =>
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogInformation("Working... {Time}", DateTime.UtcNow);
                await Task.Delay(5000, cancellationToken);
            }
        }, cancellationToken);
        
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Hosted service stopping");
        return Task.CompletedTask;
    }
}

// Register in Program.cs
builder.Services.AddHostedService<BasicHostedService>();
```

### 2. BackgroundService Base Class

```csharp
// BackgroundService: Simplified IHostedService
public class TimedBackgroundService : BackgroundService
{
    private readonly ILogger<TimedBackgroundService> _logger;
    private readonly TimeSpan _period = TimeSpan.FromSeconds(30);

    public TimedBackgroundService(ILogger<TimedBackgroundService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(_period);
        
        while (!stoppingToken.IsCancellationRequested &&
               await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await DoWorkAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in timed background service");
            }
        }
    }

    private async Task DoWorkAsync()
    {
        _logger.LogInformation("Timed background service running at {Time}", DateTime.UtcNow);
        await Task.Delay(1000); // Simulate work
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Timed background service stopping");
        return base.StopAsync(cancellationToken);
    }
}

// Register
builder.Services.AddHostedService<TimedBackgroundService>();
```

### 3. Queue-Based Background Service

```csharp
// Background task queue interface
public interface IBackgroundTaskQueue
{
    void QueueBackgroundWorkItem(Func<CancellationToken, Task> workItem);
    Task<Func<CancellationToken, Task>> DequeueAsync(CancellationToken cancellationToken);
}

// Queue implementation
public class BackgroundTaskQueue : IBackgroundTaskQueue
{
    private readonly Channel<Func<CancellationToken, Task>> _queue;

    public BackgroundTaskQueue(int capacity = 100)
    {
        var options = new BoundedChannelOptions(capacity)
        {
            FullMode = BoundedChannelFullMode.Wait
        };
        _queue = Channel.CreateBounded<Func<CancellationToken, Task>>(options);
    }

    public void QueueBackgroundWorkItem(Func<CancellationToken, Task> workItem)
    {
        if (workItem == null)
            throw new ArgumentNullException(nameof(workItem));

        _queue.Writer.TryWrite(workItem);
    }

    public async Task<Func<CancellationToken, Task>> DequeueAsync(
        CancellationToken cancellationToken)
    {
        var workItem = await _queue.Reader.ReadAsync(cancellationToken);
        return workItem;
    }
}

// Queue processor service
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
        _logger.LogInformation("Queued hosted service starting");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var workItem = await _taskQueue.DequeueAsync(stoppingToken);
                await workItem(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Expected when stopping
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing background work item");
            }
        }
    }
}

// Register services
builder.Services.AddSingleton<IBackgroundTaskQueue, BackgroundTaskQueue>();
builder.Services.AddHostedService<QueuedHostedService>();

// Usage in controller
public class EmailController : Controller
{
    private readonly IBackgroundTaskQueue _queue;

    public EmailController(IBackgroundTaskQueue queue)
    {
        _queue = queue;
    }

    [HttpPost]
    public IActionResult SendEmail(EmailModel model)
    {
        // Queue email sending as background task
        _queue.QueueBackgroundWorkItem(async token =>
        {
            await SendEmailAsync(model.To, model.Subject, model.Body);
        });

        return Ok("Email queued for sending");
    }

    private Task SendEmailAsync(string to, string subject, string body)
    {
        // Email sending logic
        return Task.CompletedTask;
    }
}
```

### 4. Scoped Service in Hosted Service

```csharp
// ❌ WRONG: Can't inject scoped service directly
public class WrongHostedService : BackgroundService
{
    private readonly IProductService _productService; // Scoped!

    public WrongHostedService(IProductService productService)
    {
        _productService = productService; // WRONG!
    }
}

// ✅ CORRECT: Use IServiceScopeFactory
public class CorrectHostedService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CorrectHostedService> _logger;

    public CorrectHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<CorrectHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using (var scope = _scopeFactory.CreateScope())
                {
                    var productService = scope.ServiceProvider
                        .GetRequiredService<IProductService>();
                    
                    var dbContext = scope.ServiceProvider
                        .GetRequiredService<ApplicationDbContext>();
                    
                    await ProcessProductsAsync(productService, dbContext);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing products");
            }

            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }

    private async Task ProcessProductsAsync(
        IProductService productService,
        ApplicationDbContext dbContext)
    {
        var products = await productService.GetAllAsync();
        // Process products
    }
}
```

### 5. Data Seeding Hosted Service

```csharp
public class DataSeedingHostedService : IHostedService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DataSeedingHostedService> _logger;

    public DataSeedingHostedService(
        IServiceProvider serviceProvider,
        ILogger<DataSeedingHostedService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider
            .GetRequiredService<ApplicationDbContext>();

        try
        {
            // Ensure database is created
            await dbContext.Database.EnsureCreatedAsync(cancellationToken);

            // Seed data if needed
            if (!await dbContext.Products.AnyAsync(cancellationToken))
            {
                _logger.LogInformation("Seeding database");
                
                dbContext.Products.AddRange(
                    new Product { Name = "Product 1", Price = 10.99m },
                    new Product { Name = "Product 2", Price = 20.99m },
                    new Product { Name = "Product 3", Price = 30.99m }
                );

                await dbContext.SaveChangesAsync(cancellationToken);
                _logger.LogInformation("Database seeded successfully");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error seeding database");
        }
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
```

**Hosted Services Summary:**

| Type | Use Case | Lifetime |
|------|----------|----------|
| **IHostedService** | Full control over start/stop | Singleton |
| **BackgroundService** | Long-running background tasks | Singleton |
| **Queue-based** | Process queued work items | Singleton |
| **Timed tasks** | Periodic execution | Singleton |

---

## Q74: How do you implement background tasks in ASP.NET Core?

**Answer:**

Background tasks in ASP.NET Core can be implemented using hosted services, channels, or task queues for executing work outside the request/response cycle.

### 1. Simple Background Task

```csharp
public class EmailBackgroundService : BackgroundService
{
    private readonly ILogger<EmailBackgroundService> _logger;
    private readonly IConfiguration _configuration;

    public EmailBackgroundService(
        ILogger<EmailBackgroundService> logger,
        IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Email background service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessPendingEmailsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing emails");
            }

            // Wait before next iteration
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    private async Task ProcessPendingEmailsAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing pending emails");
        // Process emails
        await Task.CompletedTask;
    }
}

builder.Services.AddHostedService<EmailBackgroundService>();
```

### 2. Background Task Queue with Channel

```csharp
// Work item model
public class BackgroundWorkItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Type { get; set; }
    public object Data { get; set; }
    public DateTime QueuedAt { get; set; } = DateTime.UtcNow;
}

// Queue interface
public interface IBackgroundTaskQueue
{
    ValueTask QueueAsync(BackgroundWorkItem workItem);
    ValueTask<BackgroundWorkItem> DequeueAsync(CancellationToken cancellationToken);
}

// Queue implementation using Channel
public class BackgroundTaskQueue : IBackgroundTaskQueue
{
    private readonly Channel<BackgroundWorkItem> _queue;
    private readonly ILogger<BackgroundTaskQueue> _logger;

    public BackgroundTaskQueue(
        int capacity,
        ILogger<BackgroundTaskQueue> logger)
    {
        var options = new BoundedChannelOptions(capacity)
        {
            FullMode = BoundedChannelFullMode.Wait
        };
        _queue = Channel.CreateBounded<BackgroundWorkItem>(options);
        _logger = logger;
    }

    public async ValueTask QueueAsync(BackgroundWorkItem workItem)
    {
        if (workItem == null)
            throw new ArgumentNullException(nameof(workItem));

        await _queue.Writer.WriteAsync(workItem);
        _logger.LogInformation("Work item {Id} queued", workItem.Id);
    }

    public async ValueTask<BackgroundWorkItem> DequeueAsync(
        CancellationToken cancellationToken)
    {
        var workItem = await _queue.Reader.ReadAsync(cancellationToken);
        _logger.LogInformation("Work item {Id} dequeued", workItem.Id);
        return workItem;
    }
}

// Background processor
public class BackgroundTaskProcessor : BackgroundService
{
    private readonly IBackgroundTaskQueue _taskQueue;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<BackgroundTaskProcessor> _logger;

    public BackgroundTaskProcessor(
        IBackgroundTaskQueue taskQueue,
        IServiceScopeFactory scopeFactory,
        ILogger<BackgroundTaskProcessor> logger)
    {
        _taskQueue = taskQueue;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Background task processor started");

        await foreach (var workItem in GetWorkItemsAsync(stoppingToken))
        {
            try
            {
                await ProcessWorkItemAsync(workItem, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Error processing work item {Id}", workItem.Id);
            }
        }
    }

    private async IAsyncEnumerable<BackgroundWorkItem> GetWorkItemsAsync(
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            BackgroundWorkItem workItem = null;
            try
            {
                workItem = await _taskQueue.DequeueAsync(cancellationToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            if (workItem != null)
            {
                yield return workItem;
            }
        }
    }

    private async Task ProcessWorkItemAsync(
        BackgroundWorkItem workItem,
        CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();

        switch (workItem.Type)
        {
            case "SendEmail":
                var emailService = scope.ServiceProvider
                    .GetRequiredService<IEmailService>();
                await emailService.SendAsync(workItem.Data, cancellationToken);
                break;

            case "GenerateReport":
                var reportService = scope.ServiceProvider
                    .GetRequiredService<IReportService>();
                await reportService.GenerateAsync(workItem.Data, cancellationToken);
                break;

            case "ProcessPayment":
                var paymentService = scope.ServiceProvider
                    .GetRequiredService<IPaymentService>();
                await paymentService.ProcessAsync(workItem.Data, cancellationToken);
                break;

            default:
                _logger.LogWarning("Unknown work item type: {Type}", workItem.Type);
                break;
        }

        _logger.LogInformation(
            "Work item {Id} processed in {Duration}ms",
            workItem.Id,
            (DateTime.UtcNow - workItem.QueuedAt).TotalMilliseconds);
    }
}

// Register services
builder.Services.AddSingleton<IBackgroundTaskQueue>(sp =>
{
    var logger = sp.GetRequiredService<ILogger<BackgroundTaskQueue>>();
    return new BackgroundTaskQueue(capacity: 100, logger);
});
builder.Services.AddHostedService<BackgroundTaskProcessor>();

// Usage in controller
[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly IBackgroundTaskQueue _queue;

    public TasksController(IBackgroundTaskQueue queue)
    {
        _queue = queue;
    }

    [HttpPost("send-email")]
    public async Task<IActionResult> SendEmail([FromBody] EmailRequest request)
    {
        await _queue.QueueAsync(new BackgroundWorkItem
        {
            Type = "SendEmail",
            Data = request
        });

        return Accepted(new { message = "Email queued for processing" });
    }

    [HttpPost("generate-report")]
    public async Task<IActionResult> GenerateReport([FromBody] ReportRequest request)
    {
        await _queue.QueueAsync(new BackgroundWorkItem
        {
            Type = "GenerateReport",
            Data = request
        });

        return Accepted(new { message = "Report generation queued" });
    }
}
```

### 3. Scheduled Background Tasks

```csharp
public class ScheduledTaskService : BackgroundService
{
    private readonly ILogger<ScheduledTaskService> _logger;
    private readonly IServiceScopeFactory _scopeFactory;

    public ScheduledTaskService(
        ILogger<ScheduledTaskService> logger,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Run multiple scheduled tasks
        var tasks = new[]
        {
            RunDailyCleanupAsync(stoppingToken),
            RunHourlyHealthCheckAsync(stoppingToken),
            RunEvery5MinutesDataSyncAsync(stoppingToken)
        };

        await Task.WhenAll(tasks);
    }

    private async Task RunDailyCleanupAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            var nextRun = now.Date.AddDays(1).AddHours(2); // 2 AM tomorrow
            var delay = nextRun - now;

            await Task.Delay(delay, stoppingToken);

            try
            {
                using var scope = _scopeFactory.CreateScope();
                _logger.LogInformation("Running daily cleanup");
                // Cleanup logic
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Daily cleanup failed");
            }
        }
    }

    private async Task RunHourlyHealthCheckAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromHours(1));
        
        while (!stoppingToken.IsCancellationRequested &&
               await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                _logger.LogInformation("Running hourly health check");
                // Health check logic
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");
            }
        }
    }

    private async Task RunEvery5MinutesDataSyncAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(5));
        
        while (!stoppingToken.IsCancellationRequested &&
               await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                _logger.LogInformation("Running 5-minute data sync");
                // Data sync logic
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Data sync failed");
            }
        }
    }
}
```

**Background Tasks Best Practices:**

```
✅ Use BackgroundService for long-running tasks
✅ Use cancellation tokens for graceful shutdown
✅ Use IServiceScopeFactory for scoped dependencies
✅ Log errors and exceptions
✅ Implement retry logic with exponential backoff
✅ Monitor task health and performance
✅ Use queues for work distribution

❌ Don't block application startup
❌ Don't inject scoped services directly
❌ Don't ignore cancellation tokens
❌ Don't leave tasks unmonitored
```

---

## Q75: Explain configuration in ASP.NET Core (appsettings.json)

**Answer:**

ASP.NET Core uses a flexible configuration system that reads settings from multiple sources including JSON files, environment variables, command-line arguments, and more.

### 1. Basic Configuration (appsettings.json)

```json
// appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=MyApp;Trusted_Connection=True;",
    "RedisConnection": "localhost:6379"
  },
  "AppSettings": {
    "ApplicationName": "My Application",
    "Version": "1.0.0",
    "MaxUploadSizeMB": 10,
    "EnableFeatureX": true
  },
  "Email": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@myapp.com",
    "FromName": "My Application"
  },
  "Jwt": {
    "Issuer": "https://myapp.com",
    "Audience": "https://myapp.com",
    "Key": "your-256-bit-secret-key-here",
    "ExpiryMinutes": 60
  }
}
```

```csharp
// Access configuration in Program.cs
var builder = WebApplication.CreateBuilder(args);

// Read simple values
var appName = builder.Configuration["AppSettings:ApplicationName"];
var maxSize = builder.Configuration.GetValue<int>("AppSettings:MaxUploadSizeMB");

// Read connection strings
var connString = builder.Configuration.GetConnectionString("DefaultConnection");

// Bind to object
var emailSettings = builder.Configuration.GetSection("Email").Get<EmailSettings>();
```

### 2. Environment-Specific Configuration

```json
// appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyApp_Dev;..."
  },
  "Email": {
    "SmtpServer": "localhost",
    "SmtpPort": 25
  }
}

// appsettings.Production.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=prod-server;Database=MyApp;..."
  },
  "Email": {
    "SmtpServer": "smtp.sendgrid.net",
    "SmtpPort": 587
  }
}
```

```csharp
// Configuration precedence (last wins):
// 1. appsettings.json
// 2. appsettings.{Environment}.json
// 3. User secrets (Development only)
// 4. Environment variables
// 5. Command-line arguments

var builder = WebApplication.CreateBuilder(args);

// Automatically loads:
// - appsettings.json
// - appsettings.{Environment}.json
// - Environment variables
// - Command-line args
```

### 3. Strongly-Typed Configuration (Options Pattern)

```csharp
// Configuration classes
public class AppSettings
{
    public string ApplicationName { get; set; }
    public string Version { get; set; }
    public int MaxUploadSizeMB { get; set; }
    public bool EnableFeatureX { get; set; }
}

public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; }
    public string FromName { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
}

public class JwtSettings
{
    public string Issuer { get; set; }
    public string Audience { get; set; }
    public string Key { get; set; }
    public int ExpiryMinutes { get; set; }
}

// Register options in Program.cs
builder.Services.Configure<AppSettings>(
    builder.Configuration.GetSection("AppSettings"));

builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));

builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("Jwt"));

// Use in services
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> options,
        ILogger<EmailService> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        _logger.LogInformation(
            "Sending email via {Server}:{Port}",
            _settings.SmtpServer,
            _settings.SmtpPort);

        // Use _settings to send email
        await Task.CompletedTask;
    }
}
```

### 4. Configuration Validation

```csharp
// With data annotations
public class EmailSettings
{
    [Required]
    [RegularExpression(@"^[\w-\.]+\.[\w-]{2,4}$")]
    public string SmtpServer { get; set; }

    [Range(1, 65535)]
    public int SmtpPort { get; set; }

    [Required]
    [EmailAddress]
    public string FromEmail { get; set; }
}

// Register with validation
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("Email"))
    .ValidateDataAnnotations()
    .ValidateOnStart(); // Validate at startup

// Custom validation
builder.Services.AddOptions<AppSettings>()
    .Bind(builder.Configuration.GetSection("AppSettings"))
    .Validate(settings =>
    {
        return settings.MaxUploadSizeMB > 0 && settings.MaxUploadSizeMB <= 100;
    }, "MaxUploadSizeMB must be between 1 and 100")
    .ValidateOnStart();
```

### 5. User Secrets (Development)

```bash
# Initialize user secrets
dotnet user-secrets init

# Set secrets
dotnet user-secrets set "Email:Password" "mypassword"
dotnet user-secrets set "Jwt:Key" "my-secret-key-here"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=..."

# List secrets
dotnet user-secrets list

# Remove secret
dotnet user-secrets remove "Email:Password"

# Clear all secrets
dotnet user-secrets clear
```

```csharp
// User secrets are automatically loaded in Development
// No code changes needed - just works!
var password = builder.Configuration["Email:Password"]; // From user secrets
```

### 6. Environment Variables

```bash
# Set environment variables (Linux/Mac)
export AppSettings__ApplicationName="My App"
export Email__SmtpServer="smtp.example.com"
export ConnectionStrings__DefaultConnection="Server=..."

# Windows PowerShell
$env:AppSettings__ApplicationName="My App"
$env:Email__SmtpServer="smtp.example.com"

# Windows CMD
set AppSettings__ApplicationName=My App
set Email__SmtpServer=smtp.example.com
```

```csharp
// Access environment variables
var appName = builder.Configuration["AppSettings:ApplicationName"];
// Reads from: appsettings.json OR environment variable AppSettings__ApplicationName
```

### 7. Command-Line Arguments

```bash
# Run with command-line arguments
dotnet run --AppSettings:ApplicationName="My App" --Email:SmtpServer="smtp.example.com"

# Or
dotnet MyApp.dll --AppSettings:ApplicationName="My App"
```

```csharp
// Command-line args override everything
var builder = WebApplication.CreateBuilder(args); // args passed here
```

### 8. Custom Configuration Sources

```csharp
// Add custom JSON file
builder.Configuration.AddJsonFile("customsettings.json", optional: true, reloadOnChange: true);

// Add XML file
builder.Configuration.AddXmlFile("settings.xml", optional: true);

// Add INI file
builder.Configuration.AddIniFile("settings.ini", optional: true);

// Add in-memory configuration
builder.Configuration.AddInMemoryCollection(new Dictionary<string, string>
{
    ["Setting1"] = "Value1",
    ["Setting2"] = "Value2"
});

// Add Azure Key Vault
builder.Configuration.AddAzureKeyVault(
    new Uri("https://myvault.vault.azure.net/"),
    new DefaultAzureCredential());
```

**Configuration Precedence (lowest to highest):**

1. appsettings.json
2. appsettings.{Environment}.json
3. User Secrets (Development)
4. Environment Variables
5. Command-Line Arguments

---


## Q76: How do you handle multiple environments (Development, Staging, Production)?

**Answer:**

ASP.NET Core provides built-in support for managing different environments through environment-specific configuration files, environment variables, and the `IWebHostEnvironment` interface.

### 1. Environment Configuration Files

```json
// appsettings.json (Base configuration)
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AppSettings": {
    "ApplicationName": "My App",
    "Version": "1.0.0"
  }
}

// appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft": "Debug"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyApp_Dev;..."
  },
  "AppSettings": {
    "EnableDetailedErrors": true,
    "UseMockServices": true
  }
}

// appsettings.Staging.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=staging-server;Database=MyApp_Staging;..."
  },
  "AppSettings": {
    "EnableDetailedErrors": true,
    "UseMockServices": false
  }
}

// appsettings.Production.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Error"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=prod-server;Database=MyApp;..."
  },
  "AppSettings": {
    "EnableDetailedErrors": false,
    "UseMockServices": false
  }
}
```

### 2. Environment-Specific Service Registration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

var env = builder.Environment;

// Development-specific services
if (env.IsDevelopment())
{
    builder.Services.AddDatabaseDeveloperPageExceptionFilter();
    builder.Services.AddSingleton<IEmailSender, DevelopmentEmailSender>();
    builder.Services.AddSingleton<IPaymentService, MockPaymentService>();
}
else if (env.IsStaging())
{
    builder.Services.AddSingleton<IEmailSender, StagingEmailSender>();
    builder.Services.AddSingleton<IPaymentService, StagingPaymentService>();
}
else // Production
{
    builder.Services.AddSingleton<IEmailSender, ProductionEmailSender>();
    builder.Services.AddSingleton<IPaymentService, ProductionPaymentService>();
    builder.Services.AddApplicationInsightsTelemetry();
}

// Conditional service based on configuration
var useRedis = builder.Configuration.GetValue<bool>("Features:UseRedis");
if (useRedis && !env.IsDevelopment())
{
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = builder.Configuration.GetConnectionString("Redis");
    });
}
else
{
    builder.Services.AddDistributedMemoryCache();
}

var app = builder.Build();

// Environment-specific middleware
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}
else if (app.Environment.IsStaging())
{
    app.UseExceptionHandler("/Error");
    app.Use(async (context, next) =>
    {
        context.Response.Headers.Add("X-Environment", "Staging");
        await next();
    });
}
else // Production
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
    app.Use(async (context, next) =>
    {
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
        context.Response.Headers.Add("X-Frame-Options", "DENY");
        await next();
    });
}

app.Run();
```

### 3. Using IWebHostEnvironment

```csharp
public class HomeController : Controller
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<HomeController> _logger;

    public HomeController(
        IWebHostEnvironment env,
        ILogger<HomeController> logger)
    {
        _env = env;
        _logger = logger;
    }

    public IActionResult Index()
    {
        var environmentInfo = new
        {
            EnvironmentName = _env.EnvironmentName,
            IsDevelopment = _env.IsDevelopment(),
            IsStaging = _env.IsStaging(),
            IsProduction = _env.IsProduction(),
            ContentRootPath = _env.ContentRootPath,
            WebRootPath = _env.WebRootPath
        };

        _logger.LogInformation(
            "Running in {Environment} environment",
            _env.EnvironmentName);

        return View(environmentInfo);
    }

    public IActionResult DebugInfo()
    {
        // Only allow in development
        if (!_env.IsDevelopment())
        {
            return NotFound();
        }

        var debugInfo = GetDebugInformation();
        return View(debugInfo);
    }
}
```

### 4. Custom Environment Names

```csharp
// Set environment via:
// 1. Environment variable: ASPNETCORE_ENVIRONMENT=QA
// 2. launchSettings.json
// 3. Command line: dotnet run --environment="QA"

// launchSettings.json
{
  "profiles": {
    "Development": {
      "commandName": "Project",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "Staging": {
      "commandName": "Project",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Staging"
      }
    },
    "QA": {
      "commandName": "Project",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "QA"
      }
    }
  }
}

// Custom environment check
public void ConfigureServices(IServiceCollection services)
{
    var env = services.BuildServiceProvider()
        .GetRequiredService<IWebHostEnvironment>();

    if (env.IsEnvironment("QA"))
    {
        services.AddSingleton<IEmailSender, QAEmailSender>();
    }
}
```

### 5. Environment-Specific Views

```html
<!-- Use environment tag helper -->
<environment include="Development">
    <!-- Development-only content -->
    <link rel="stylesheet" href="~/css/site.css" />
    <script src="~/js/site.js"></script>
    <div class="dev-banner">Development Environment</div>
</environment>

<environment include="Staging">
    <!-- Staging-only content -->
    <link rel="stylesheet" href="~/css/site.min.css" />
    <script src="~/js/site.min.js"></script>
    <div class="staging-banner">Staging Environment</div>
</environment>

<environment include="Production">
    <!-- Production-only content -->
    <link rel="stylesheet" href="~/css/site.min.css" asp-append-version="true" />
    <script src="~/js/site.min.js" asp-append-version="true"></script>
</environment>

<environment exclude="Production">
    <!-- Show in Development and Staging only -->
    <div class="debug-toolbar">
        <a href="/swagger">API Docs</a>
        <a href="/hangfire">Background Jobs</a>
    </div>
</environment>
```

### 6. Docker Environment Configuration

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "./"]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  myapp-dev:
    image: myapp:latest
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=db;Database=MyApp_Dev;
    ports:
      - "5000:80"

  myapp-staging:
    image: myapp:latest
    environment:
      - ASPNETCORE_ENVIRONMENT=Staging
      - ConnectionStrings__DefaultConnection=Server=db;Database=MyApp_Staging;
    ports:
      - "5001:80"

  myapp-prod:
    image: myapp:latest
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=db;Database=MyApp;
    ports:
      - "5002:80"
```

### 7. Azure App Service Configuration

```bash
# Set environment via Azure CLI
az webapp config appsettings set \
  --resource-group myResourceGroup \
  --name myapp \
  --settings ASPNETCORE_ENVIRONMENT=Production

# Set connection string
az webapp config connection-string set \
  --resource-group myResourceGroup \
  --name myapp \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=..."
```

**Environment Management Best Practices:**

```
✅ Use environment-specific appsettings files
✅ Store secrets in Azure Key Vault or user secrets
✅ Use IWebHostEnvironment for environment checks
✅ Set ASPNETCORE_ENVIRONMENT correctly
✅ Test in staging before production deployment
✅ Use environment tag helpers in views
✅ Log current environment at startup

❌ Don't hardcode environment-specific values
❌ Don't commit secrets to source control
❌ Don't use production config in development
❌ Don't skip staging environment testing
```

---

## Q77-Q78: Options Pattern and IOptions<T> (Combined)

**Answer:**

The Options pattern provides strongly-typed access to groups of related settings, with support for validation, reloading, and multiple instances.

### 1. Basic Options Pattern

```csharp
// Configuration class
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; }
    public string FromName { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
    public bool EnableSsl { get; set; }
}

// appsettings.json
{
  "Email": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@myapp.com",
    "FromName": "My Application",
    "EnableSsl": true
  }
}

// Register options
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));

// Use in service with IOptions<T>
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> options,
        ILogger<EmailService> logger)
    {
        _settings = options.Value; // Get current value
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        using var client = new SmtpClient(_settings.SmtpServer, _settings.SmtpPort);
        client.EnableSsl = _settings.EnableSsl;
        
        if (!string.IsNullOrEmpty(_settings.Username))
        {
            client.Credentials = new NetworkCredential(
                _settings.Username, 
                _settings.Password);
        }

        var message = new MailMessage(_settings.FromEmail, to, subject, body);
        await client.SendMailAsync(message);
    }
}
```

### 2. IOptions, IOptionsSnapshot, IOptionsMonitor

```csharp
// IOptions<T>: Singleton, doesn't support reloading
public class ServiceWithOptions
{
    private readonly AppSettings _settings;

    public ServiceWithOptions(IOptions<AppSettings> options)
    {
        _settings = options.Value;
        // Value is cached, won't change
    }
}

// IOptionsSnapshot<T>: Scoped, recomputed per request
public class ServiceWithSnapshot
{
    private readonly AppSettings _settings;

    public ServiceWithSnapshot(IOptionsSnapshot<AppSettings> options)
    {
        _settings = options.Value;
        // Recomputed for each HTTP request
        // Can handle changes between requests
    }
}

// IOptionsMonitor<T>: Singleton, supports change notifications
public class ServiceWithMonitor
{
    private AppSettings _settings;
    private readonly IOptionsMonitor<AppSettings> _monitor;

    public ServiceWithMonitor(IOptionsMonitor<AppSettings> monitor)
    {
        _monitor = monitor;
        _settings = monitor.CurrentValue;

        // React to configuration changes
        monitor.OnChange(settings =>
        {
            _settings = settings;
            Console.WriteLine("Configuration changed!");
        });
    }

    public void DoWork()
    {
        // Always use latest settings
        var currentSettings = _monitor.CurrentValue;
    }
}

// Comparison
/*
┌─────────────────┬───────────┬──────────┬────────────────┐
│ Interface       │ Lifetime  │ Reloads  │ Change Events  │
├─────────────────┼───────────┼──────────┼────────────────┤
│ IOptions<T>     │ Singleton │ No       │ No             │
│ IOptionsSnapshot│ Scoped    │ Yes      │ No             │
│ IOptionsMonitor │ Singleton │ Yes      │ Yes            │
└─────────────────┴───────────┴──────────┴────────────────┘
*/
```

### 3. Options Validation

```csharp
// With Data Annotations
public class ApiSettings
{
    [Required]
    [Url]
    public string BaseUrl { get; set; }

    [Required]
    [MinLength(32)]
    public string ApiKey { get; set; }

    [Range(1, 300)]
    public int TimeoutSeconds { get; set; } = 30;

    [Range(1, 10)]
    public int RetryCount { get; set; } = 3;
}

// Register with validation
builder.Services.AddOptions<ApiSettings>()
    .Bind(builder.Configuration.GetSection("Api"))
    .ValidateDataAnnotations()
    .ValidateOnStart(); // Fail fast at startup

// Custom validation
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("Email"))
    .Validate(settings =>
    {
        if (settings.SmtpPort < 1 || settings.SmtpPort > 65535)
            return false;
        
        if (settings.EnableSsl && settings.SmtpPort == 25)
            return false;

        return true;
    }, "Invalid email configuration")
    .ValidateOnStart();

// Complex validation with dependencies
builder.Services.AddOptions<DatabaseSettings>()
    .Bind(builder.Configuration.GetSection("Database"))
    .Validate<ILogger<DatabaseSettings>>((settings, logger) =>
    {
        if (string.IsNullOrEmpty(settings.ConnectionString))
        {
            logger.LogError("Connection string is required");
            return false;
        }

        try
        {
            using var connection = new SqlConnection(settings.ConnectionString);
            connection.Open();
            logger.LogInformation("Database connection validated");
            return true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to connect to database");
            return false;
        }
    })
    .ValidateOnStart();
```

### 4. Named Options

```csharp
// Multiple instances of same options type
public class ApiClientSettings
{
    public string BaseUrl { get; set; }
    public string ApiKey { get; set; }
    public int TimeoutSeconds { get; set; }
}

// appsettings.json
{
  "GitHub": {
    "BaseUrl": "https://api.github.com",
    "ApiKey": "github-key",
    "TimeoutSeconds": 30
  },
  "Stripe": {
    "BaseUrl": "https://api.stripe.com",
    "ApiKey": "stripe-key",
    "TimeoutSeconds": 60
  }
}

// Register named options
builder.Services.Configure<ApiClientSettings>("GitHub",
    builder.Configuration.GetSection("GitHub"));

builder.Services.Configure<ApiClientSettings>("Stripe",
    builder.Configuration.GetSection("Stripe"));

// Use named options
public class MultiApiService
{
    private readonly ApiClientSettings _githubSettings;
    private readonly ApiClientSettings _stripeSettings;

    public MultiApiService(IOptionsSnapshot<ApiClientSettings> options)
    {
        _githubSettings = options.Get("GitHub");
        _stripeSettings = options.Get("Stripe");
    }

    public async Task<string> GetFromGitHub()
    {
        var client = new HttpClient { BaseAddress = new Uri(_githubSettings.BaseUrl) };
        client.DefaultRequestHeaders.Add("Authorization", $"Bearer {_githubSettings.ApiKey}");
        // Use client
        return await Task.FromResult("GitHub data");
    }

    public async Task<string> GetFromStripe()
    {
        var client = new HttpClient { BaseAddress = new Uri(_stripeSettings.BaseUrl) };
        client.DefaultRequestHeaders.Add("Authorization", $"Bearer {_stripeSettings.ApiKey}");
        // Use client
        return await Task.FromResult("Stripe data");
    }
}
```

### 5. Post-Configure Options

```csharp
// Modify options after binding
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));

builder.Services.PostConfigure<EmailSettings>(settings =>
{
    // Apply defaults
    if (string.IsNullOrEmpty(settings.FromName))
    {
        settings.FromName = "My Application";
    }

    // Override based on environment
    if (builder.Environment.IsDevelopment())
    {
        settings.SmtpServer = "localhost";
        settings.SmtpPort = 25;
    }
});

// Multiple post-configure (executed in order)
builder.Services.PostConfigure<AppSettings>(settings =>
{
    settings.Version = Assembly.GetExecutingAssembly()
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
        ?.InformationalVersion ?? "1.0.0";
});
```

### 6. Options Factory

```csharp
// Custom options factory
public class CustomOptionsFactory<TOptions> : IOptionsFactory<TOptions>
    where TOptions : class, new()
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<CustomOptionsFactory<TOptions>> _logger;

    public CustomOptionsFactory(
        IConfiguration configuration,
        ILogger<CustomOptionsFactory<TOptions>> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public TOptions Create(string name)
    {
        var options = new TOptions();
        
        // Bind from configuration
        _configuration.GetSection(name).Bind(options);
        
        // Log creation
        _logger.LogInformation("Created options for {Name}", name);
        
        return options;
    }
}

// Register custom factory
builder.Services.AddSingleton<IOptionsFactory<EmailSettings>, CustomOptionsFactory<EmailSettings>>();
```

### 7. Reload Configuration on Change

```csharp
// appsettings.json loaded with reloadOnChange: true by default
var builder = WebApplication.CreateBuilder(args);

// Explicitly set reloadOnChange
builder.Configuration.AddJsonFile(
    "appsettings.json",
    optional: false,
    reloadOnChange: true); // File changes trigger reload

builder.Configuration.AddJsonFile(
    $"appsettings.{builder.Environment.EnvironmentName}.json",
    optional: true,
    reloadOnChange: true);

// Service that reacts to changes
public class ConfigReloadService : BackgroundService
{
    private readonly IOptionsMonitor<AppSettings> _monitor;
    private readonly ILogger<ConfigReloadService> _logger;

    public ConfigReloadService(
        IOptionsMonitor<AppSettings> monitor,
        ILogger<ConfigReloadService> logger)
    {
        _monitor = monitor;
        _logger = logger;

        // Subscribe to changes
        monitor.OnChange(settings =>
        {
            _logger.LogWarning(
                "Configuration changed! New value: {Value}",
                settings.SomeSetting);
            
            // React to change
            HandleConfigurationChange(settings);
        });
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var currentSettings = _monitor.CurrentValue;
            _logger.LogInformation("Current setting: {Value}", currentSettings.SomeSetting);
            
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    private void HandleConfigurationChange(AppSettings settings)
    {
        // Restart services, refresh caches, etc.
    }
}
```

**Options Pattern Summary:**

| Feature | IOptions | IOptionsSnapshot | IOptionsMonitor |
|---------|----------|------------------|-----------------|
| Lifetime | Singleton | Scoped | Singleton |
| Reloads config | No | Per request | Real-time |
| Change notifications | No | No | Yes |
| Performance | Best | Good | Good |
| Use for | Static config | Per-request values | Dynamic config |

---

## Q79-Q80: Logging in ASP.NET Core (Combined)

**Answer:**

ASP.NET Core has built-in logging infrastructure with support for multiple providers, structured logging, and six log levels.

### 1. Log Levels

```csharp
// Six log levels (lowest to highest severity)
public enum LogLevel
{
    Trace = 0,      // Most detailed, contains sensitive data
    Debug = 1,      // Debug information, development only
    Information = 2, // General flow of application
    Warning = 3,     // Abnormal events, not errors
    Error = 4,       // Error events, needs attention
    Critical = 5,    // Critical failures
    None = 6        // Disable logging
}

// Using log levels
public class ProductService
{
    private readonly ILogger<ProductService> _logger;

    public ProductService(ILogger<ProductService> logger)
    {
        _logger = logger;
    }

    public async Task<Product> GetByIdAsync(int id)
    {
        _logger.LogTrace("Trace: Getting product {Id}", id);
        _logger.LogDebug("Debug: Checking cache for product {Id}", id);
        
        var product = await FindProductAsync(id);
        
        if (product == null)
        {
            _logger.LogWarning("Warning: Product {Id} not found", id);
            return null;
        }

        _logger.LogInformation("Information: Product {Id} retrieved successfully", id);
        return product;
    }

    public async Task<Product> CreateAsync(ProductDto dto)
    {
        try
        {
            _logger.LogInformation("Creating product: {Name}", dto.Name);
            
            var product = await SaveProductAsync(dto);
            
            _logger.LogInformation("Product created with ID: {Id}", product.Id);
            return product;
        }
        catch (DbUpdateException ex)
        {
            _logger.LogError(ex, "Database error creating product: {Name}", dto.Name);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Critical error creating product: {Name}", dto.Name);
            throw;
        }
    }
}
```

### 2. Logging Configuration

```json
// appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information",
      "Microsoft.EntityFrameworkCore": "Warning",
      "System": "Warning",
      "MyApp": "Debug"
    }
  }
}

// appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft": "Information"
    }
  }
}

// appsettings.Production.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft": "Error"
    }
  }
}
```

```csharp
// Configure logging in Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.AddEventSourceLogger();

// Add filters
builder.Logging.AddFilter("Microsoft", LogLevel.Warning);
builder.Logging.AddFilter("System", LogLevel.Warning);
builder.Logging.AddFilter((category, level) =>
{
    // Custom filtering logic
    return level >= LogLevel.Information;
});

// Set minimum level
builder.Logging.SetMinimumLevel(LogLevel.Information);
```

### 3. Structured Logging

```csharp
public class OrderService
{
    private readonly ILogger<OrderService> _logger;

    public OrderService(ILogger<OrderService> logger)
    {
        _logger = logger;
    }

    public async Task<Order> CreateOrderAsync(OrderDto dto)
    {
        // ✅ GOOD: Structured logging with named parameters
        _logger.LogInformation(
            "Creating order for customer {CustomerId} with {ItemCount} items totaling {Total}",
            dto.CustomerId,
            dto.Items.Count,
            dto.TotalAmount);

        // ❌ BAD: String concatenation
        _logger.LogInformation(
            $"Creating order for customer {dto.CustomerId} with {dto.Items.Count} items");

        var order = await SaveOrderAsync(dto);

        // Log with complex object
        _logger.LogInformation(
            "Order created: {@Order}",
            new 
            {
                order.Id,
                order.CustomerId,
                order.TotalAmount,
                ItemCount = order.Items.Count,
                CreatedAt = order.CreatedAt
            });

        return order;
    }

    public async Task ProcessPaymentAsync(int orderId, decimal amount)
    {
        using (_logger.BeginScope("OrderId:{OrderId}", orderId))
        {
            _logger.LogInformation("Starting payment processing for amount {Amount}", amount);
            
            try
            {
                await ChargePaymentAsync(orderId, amount);
                _logger.LogInformation("Payment successful");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Payment failed");
                throw;
            }
        }
        // Scope automatically includes OrderId in all logs
    }
}
```

### 4. Log Scopes

```csharp
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = Guid.NewGuid().ToString();
        
        // Create scope for entire request
        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["RequestId"] = requestId,
            ["RequestPath"] = context.Request.Path,
            ["RequestMethod"] = context.Request.Method,
            ["UserAgent"] = context.Request.Headers["User-Agent"].ToString()
        }))
        {
            _logger.LogInformation("Request started");
            
            var sw = Stopwatch.StartNew();
            
            try
            {
                await _next(context);
                
                sw.Stop();
                _logger.LogInformation(
                    "Request completed with status {StatusCode} in {Duration}ms",
                    context.Response.StatusCode,
                    sw.ElapsedMilliseconds);
            }
            catch (Exception ex)
            {
                sw.Stop();
                _logger.LogError(ex,
                    "Request failed after {Duration}ms",
                    sw.ElapsedMilliseconds);
                throw;
            }
        }
    }
}
```

### 5. Serilog Integration

```csharp
// Install: Serilog.AspNetCore
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithEnvironmentName()
        .WriteTo.Console(
            outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
        .WriteTo.File(
            path: "logs/log-.txt",
            rollingInterval: RollingInterval.Day,
            outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
        .WriteTo.Seq("http://localhost:5341") // Centralized logging
        .WriteTo.ApplicationInsights(
            context.Configuration["ApplicationInsights:InstrumentationKey"],
            TelemetryConverter.Traces);
});

var app = builder.Build();

// Add Serilog request logging
app.UseSerilogRequestLogging(options =>
{
    options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000}ms";
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"]);
        diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress);
    };
});

app.Run();

// Ensure Serilog cleanup
Log.CloseAndFlush();
```

```json
// appsettings.json for Serilog
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "Console"
      },
      {
        "Name": "File",
        "Args": {
          "path": "logs/log-.txt",
          "rollingInterval": "Day"
        }
      },
      {
        "Name": "Seq",
        "Args": {
          "serverUrl": "http://localhost:5341"
        }
      }
    ],
    "Enrich": ["FromLogContext", "WithMachineName", "WithThreadId"]
  }
}
```

**Logging Best Practices:**

```
✅ Use structured logging with named parameters
✅ Choose appropriate log levels
✅ Use log scopes for request correlation
✅ Don't log sensitive information (passwords, tokens)
✅ Use async logging for high volume
✅ Configure different levels per environment
✅ Use centralized logging (Seq, ELK, Application Insights)
✅ Include correlation IDs in logs

❌ Don't log in loops (use aggregation)
❌ Don't use string interpolation (use structured params)
❌ Don't log entire objects with sensitive data
❌ Don't ignore log levels
❌ Don't log synchronously in hot paths
```

---

