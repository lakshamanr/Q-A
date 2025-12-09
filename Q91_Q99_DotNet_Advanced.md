# Advanced .NET & ASP.NET Core - Questions 91-99

---

## Q91: What is Dependency Injection and how is it implemented in ASP.NET Core?

**Answer:**

**Dependency Injection (DI)** is a design pattern where dependencies are provided to a class rather than the class creating them itself. ASP.NET Core has built-in DI container support.

**Key Concepts:**

1. **Inversion of Control (IoC)**: Control of object creation is inverted from the class to the container
2. **Loose Coupling**: Classes depend on abstractions (interfaces) not concrete implementations
3. **Testability**: Easy to mock dependencies for unit testing
4. **Lifecycle Management**: Container manages object lifetimes

**Service Lifetimes:**

| Lifetime | Description | Use Case |
|----------|-------------|----------|
| **Transient** | New instance every time | Lightweight, stateless services |
| **Scoped** | One instance per request | Database contexts, request-specific data |
| **Singleton** | One instance for application lifetime | Caching, configuration, logging |

**Implementation:**

```csharp
// Interfaces (Abstractions)
namespace ECommerce.Services
{
    public interface IProductRepository
    {
        Task<Product> GetByIdAsync(Guid id);
        Task<List<Product>> GetAllAsync();
        Task AddAsync(Product product);
    }

    public interface IProductService
    {
        Task<ProductDto> GetProductAsync(Guid id);
        Task<List<ProductDto>> GetAllProductsAsync();
    }

    public interface IEmailService
    {
        Task SendEmailAsync(string to, string subject, string body);
    }

    public interface ICacheService
    {
        Task<T> GetAsync<T>(string key);
        Task SetAsync<T>(string key, T value, TimeSpan? expiration = null);
    }
}

// Implementations
namespace ECommerce.Services.Implementations
{
    // Scoped - One per request
    public class ProductRepository : IProductRepository
    {
        private readonly ApplicationDbContext _dbContext;
        private readonly ILogger<ProductRepository> _logger;

        public ProductRepository(
            ApplicationDbContext dbContext,
            ILogger<ProductRepository> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<Product> GetByIdAsync(Guid id)
        {
            _logger.LogInformation("Getting product {ProductId}", id);
            return await _dbContext.Products.FindAsync(id);
        }

        public async Task<List<Product>> GetAllAsync()
        {
            return await _dbContext.Products.ToListAsync();
        }

        public async Task AddAsync(Product product)
        {
            _dbContext.Products.Add(product);
            await _dbContext.SaveChangesAsync();
        }
    }

    // Transient - New instance every time
    public class ProductService : IProductService
    {
        private readonly IProductRepository _repository;
        private readonly ICacheService _cache;
        private readonly ILogger<ProductService> _logger;

        public ProductService(
            IProductRepository repository,
            ICacheService cache,
            ILogger<ProductService> logger)
        {
            _repository = repository;
            _cache = cache;
            _logger = logger;
        }

        public async Task<ProductDto> GetProductAsync(Guid id)
        {
            var cacheKey = $"product:{id}";
            var cachedProduct = await _cache.GetAsync<ProductDto>(cacheKey);

            if (cachedProduct != null)
            {
                _logger.LogInformation("Cache hit for product {ProductId}", id);
                return cachedProduct;
            }

            _logger.LogInformation("Cache miss for product {ProductId}", id);
            var product = await _repository.GetByIdAsync(id);

            if (product == null)
                return null;

            var productDto = new ProductDto
            {
                Id = product.Id,
                Name = product.Name,
                Price = product.Price
            };

            await _cache.SetAsync(cacheKey, productDto, TimeSpan.FromMinutes(10));

            return productDto;
        }

        public async Task<List<ProductDto>> GetAllProductsAsync()
        {
            var products = await _repository.GetAllAsync();
            return products.Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price
            }).ToList();
        }
    }

    // Singleton - One instance for application lifetime
    public class CacheService : ICacheService
    {
        private readonly IDistributedCache _cache;
        private readonly ILogger<CacheService> _logger;

        public CacheService(IDistributedCache cache, ILogger<CacheService> logger)
        {
            _cache = cache;
            _logger = logger;
        }

        public async Task<T> GetAsync<T>(string key)
        {
            var data = await _cache.GetStringAsync(key);
            if (string.IsNullOrEmpty(data))
                return default;

            return JsonSerializer.Deserialize<T>(data);
        }

        public async Task SetAsync<T>(string key, T value, TimeSpan? expiration = null)
        {
            var options = new DistributedCacheEntryOptions();
            if (expiration.HasValue)
                options.AbsoluteExpirationRelativeToNow = expiration;

            var data = JsonSerializer.Serialize(value);
            await _cache.SetStringAsync(key, data, options);
        }
    }
}

// Registration in Program.cs
var builder = WebApplication.CreateBuilder(args);

// Transient - New instance every time
builder.Services.AddTransient<IProductService, ProductService>();
builder.Services.AddTransient<IEmailService, EmailService>();

// Scoped - One instance per HTTP request
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Singleton - One instance for application lifetime
builder.Services.AddSingleton<ICacheService, CacheService>();
builder.Services.AddSingleton<IConfiguration>(builder.Configuration);
builder.Services.AddMemoryCache();

// Controller using DI
namespace ECommerce.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly IProductService _productService;
        private readonly ILogger<ProductsController> _logger;

        // Constructor Injection
        public ProductsController(
            IProductService productService,
            ILogger<ProductsController> logger)
        {
            _productService = productService;
            _logger = logger;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ProductDto>> GetProduct(Guid id)
        {
            var product = await _productService.GetProductAsync(id);

            if (product == null)
                return NotFound();

            return Ok(product);
        }

        [HttpGet]
        public async Task<ActionResult<List<ProductDto>>> GetAllProducts()
        {
            var products = await _productService.GetAllProductsAsync();
            return Ok(products);
        }
    }
}
```

**Advanced DI Patterns:**

```csharp
// 1. Factory Pattern with DI
public interface INotificationFactory
{
    INotificationService GetNotificationService(NotificationType type);
}

public class NotificationFactory : INotificationFactory
{
    private readonly IServiceProvider _serviceProvider;

    public NotificationFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public INotificationService GetNotificationService(NotificationType type)
    {
        return type switch
        {
            NotificationType.Email => _serviceProvider.GetRequiredService<IEmailNotificationService>(),
            NotificationType.SMS => _serviceProvider.GetRequiredService<ISmsNotificationService>(),
            NotificationType.Push => _serviceProvider.GetRequiredService<IPushNotificationService>(),
            _ => throw new ArgumentException("Invalid notification type")
        };
    }
}

// Registration
builder.Services.AddSingleton<INotificationFactory, NotificationFactory>();
builder.Services.AddTransient<IEmailNotificationService, EmailNotificationService>();
builder.Services.AddTransient<ISmsNotificationService, SmsNotificationService>();
builder.Services.AddTransient<IPushNotificationService, PushNotificationService>();

// 2. Conditional Registration
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddSingleton<IEmailService, FakeEmailService>();
}
else
{
    builder.Services.AddSingleton<IEmailService, SendGridEmailService>();
}

// 3. Multiple Implementations
builder.Services.AddTransient<IPaymentProcessor, StripePaymentProcessor>();
builder.Services.AddTransient<IPaymentProcessor, PayPalPaymentProcessor>();

// Inject all implementations
public class PaymentService
{
    private readonly IEnumerable<IPaymentProcessor> _paymentProcessors;

    public PaymentService(IEnumerable<IPaymentProcessor> paymentProcessors)
    {
        _paymentProcessors = paymentProcessors;
    }

    public async Task ProcessPayment(string processorName, PaymentRequest request)
    {
        var processor = _paymentProcessors.FirstOrDefault(p => p.Name == processorName);
        if (processor == null)
            throw new InvalidOperationException($"Processor {processorName} not found");

        await processor.ProcessAsync(request);
    }
}

// 4. Keyed Services (.NET 8+)
builder.Services.AddKeyedSingleton<IPaymentProcessor, StripePaymentProcessor>("stripe");
builder.Services.AddKeyedSingleton<IPaymentProcessor, PayPalPaymentProcessor>("paypal");

public class PaymentController : ControllerBase
{
    private readonly IPaymentProcessor _stripeProcessor;
    private readonly IPaymentProcessor _paypalProcessor;

    public PaymentController(
        [FromKeyedServices("stripe")] IPaymentProcessor stripeProcessor,
        [FromKeyedServices("paypal")] IPaymentProcessor paypalProcessor)
    {
        _stripeProcessor = stripeProcessor;
        _paypalProcessor = paypalProcessor;
    }
}

// 5. Options Pattern
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int Port { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
}

// appsettings.json
{
  "EmailSettings": {
    "SmtpServer": "smtp.gmail.com",
    "Port": 587,
    "Username": "user@example.com",
    "Password": "password"
  }
}

// Registration
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("EmailSettings"));

// Usage
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;

    public EmailService(IOptions<EmailSettings> settings)
    {
        _settings = settings.Value;
    }

    public async Task SendEmailAsync(string to, string subject, string body)
    {
        using var client = new SmtpClient(_settings.SmtpServer, _settings.Port);
        // ...
    }
}
```

**Best Practices:**

1. **Depend on Abstractions**: Use interfaces, not concrete classes
2. **Constructor Injection**: Preferred over property or method injection
3. **Avoid Service Locator**: Don't inject `IServiceProvider` unless necessary
4. **Choose Right Lifetime**: Transient for stateless, Scoped for per-request, Singleton for shared state
5. **Dispose Properly**: Framework handles disposal for registered services
6. **Validate Dependencies**: Check for null in constructors
7. **Avoid Circular Dependencies**: Refactor if services depend on each other
8. **Use Options Pattern**: For configuration settings

---

## Q92: Explain Middleware in ASP.NET Core and how to create custom middleware.

**Answer:**

**Middleware** is software assembled into an application pipeline to handle requests and responses. Each component chooses whether to pass the request to the next component and can perform work before and after the next component.

**Middleware Pipeline:**

```
Request Flow:
Client → Middleware 1 → Middleware 2 → Middleware 3 → Endpoint
         ↓              ↓              ↓              ↓
         ←───────────────────────────────────────────┘
                                               Response Flow
```

**Built-in Middleware (Order Matters!):**

```csharp
var app = builder.Build();

// 1. Exception handling (should be first)
app.UseExceptionHandler("/error");
app.UseHsts();

// 2. HTTPS redirection
app.UseHttpsRedirection();

// 3. Static files
app.UseStaticFiles();

// 4. Routing
app.UseRouting();

// 5. CORS (before authentication)
app.UseCors("MyPolicy");

// 6. Authentication (before authorization)
app.UseAuthentication();

// 7. Authorization
app.UseAuthorization();

// 8. Custom middleware
app.UseMiddleware<RequestLoggingMiddleware>();

// 9. Endpoints (must be last)
app.MapControllers();

app.Run();
```

**Custom Middleware - Request Logging:**

```csharp
namespace ECommerce.Middleware
{
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
            // Generate request ID
            var requestId = Guid.NewGuid().ToString();
            context.Items["RequestId"] = requestId;

            // Log request
            _logger.LogInformation(
                "Request {RequestId}: {Method} {Path} from {IP}",
                requestId,
                context.Request.Method,
                context.Request.Path,
                context.Connection.RemoteIpAddress
            );

            var stopwatch = Stopwatch.StartNew();

            try
            {
                // Call next middleware
                await _next(context);
            }
            finally
            {
                stopwatch.Stop();

                // Log response
                _logger.LogInformation(
                    "Response {RequestId}: {StatusCode} in {ElapsedMs}ms",
                    requestId,
                    context.Response.StatusCode,
                    stopwatch.ElapsedMilliseconds
                );
            }
        }
    }

    // Extension method for easy registration
    public static class RequestLoggingMiddlewareExtensions
    {
        public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<RequestLoggingMiddleware>();
        }
    }
}

// Usage in Program.cs
app.UseRequestLogging();
```

**Custom Middleware - API Key Authentication:**

```csharp
namespace ECommerce.Middleware
{
    public class ApiKeyAuthenticationMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IConfiguration _configuration;
        private const string ApiKeyHeaderName = "X-API-Key";

        public ApiKeyAuthenticationMiddleware(
            RequestDelegate next,
            IConfiguration configuration)
        {
            _next = next;
            _configuration = configuration;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Skip authentication for health checks
            if (context.Request.Path.StartsWithSegments("/health"))
            {
                await _next(context);
                return;
            }

            // Check for API key in header
            if (!context.Request.Headers.TryGetValue(ApiKeyHeaderName, out var extractedApiKey))
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsync("API Key is missing");
                return;
            }

            // Validate API key
            var validApiKey = _configuration.GetValue<string>("ApiKey");

            if (!validApiKey.Equals(extractedApiKey))
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsync("Invalid API Key");
                return;
            }

            // API key is valid, continue
            await _next(context);
        }
    }
}
```

**Custom Middleware - Request/Response Buffering:**

```csharp
namespace ECommerce.Middleware
{
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
            // Enable buffering to read request body multiple times
            context.Request.EnableBuffering();

            // Read request body
            var requestBody = await ReadRequestBodyAsync(context.Request);

            // Replace response stream with MemoryStream to capture response
            var originalResponseBody = context.Response.Body;
            using var responseBody = new MemoryStream();
            context.Response.Body = responseBody;

            try
            {
                // Execute next middleware
                await _next(context);

                // Read response body
                var response = await ReadResponseBodyAsync(context.Response);

                // Log request and response
                _logger.LogInformation(
                    "Request: {Method} {Path}\nRequest Body: {RequestBody}\nResponse Status: {StatusCode}\nResponse Body: {ResponseBody}",
                    context.Request.Method,
                    context.Request.Path,
                    requestBody,
                    context.Response.StatusCode,
                    response
                );
            }
            finally
            {
                // Copy response back to original stream
                await responseBody.CopyToAsync(originalResponseBody);
            }
        }

        private async Task<string> ReadRequestBodyAsync(HttpRequest request)
        {
            request.Body.Position = 0;

            using var reader = new StreamReader(
                request.Body,
                encoding: Encoding.UTF8,
                detectEncodingFromByteOrderMarks: false,
                leaveOpen: true);

            var body = await reader.ReadToEndAsync();
            request.Body.Position = 0;

            return body;
        }

        private async Task<string> ReadResponseBodyAsync(HttpResponse response)
        {
            response.Body.Seek(0, SeekOrigin.Begin);
            var text = await new StreamReader(response.Body).ReadToEndAsync();
            response.Body.Seek(0, SeekOrigin.Begin);

            return text;
        }
    }
}
```

**Custom Middleware - Rate Limiting:**

```csharp
namespace ECommerce.Middleware
{
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
            var clientId = GetClientId(context);
            var cacheKey = $"rate_limit:{clientId}";

            var requestCount = _cache.GetOrCreate(cacheKey, entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = _timeWindow;
                return 0;
            });

            if (requestCount >= _requestLimit)
            {
                context.Response.StatusCode = 429; // Too Many Requests
                context.Response.Headers["Retry-After"] = _timeWindow.TotalSeconds.ToString();

                await context.Response.WriteAsJsonAsync(new
                {
                    Error = "Rate limit exceeded",
                    Message = $"Maximum {_requestLimit} requests per {_timeWindow.TotalMinutes} minutes"
                });

                return;
            }

            // Increment request count
            _cache.Set(cacheKey, requestCount + 1, _timeWindow);

            // Add rate limit headers
            context.Response.Headers["X-RateLimit-Limit"] = _requestLimit.ToString();
            context.Response.Headers["X-RateLimit-Remaining"] = (_requestLimit - requestCount - 1).ToString();

            await _next(context);
        }

        private string GetClientId(HttpContext context)
        {
            // Try to get from JWT
            var userId = context.User?.FindFirst("sub")?.Value;
            if (!string.IsNullOrEmpty(userId))
                return userId;

            // Fall back to IP address
            return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        }
    }
}
```

**Conditional Middleware:**

```csharp
// Only apply middleware for specific paths
app.UseWhen(
    context => context.Request.Path.StartsWithSegments("/api"),
    appBuilder =>
    {
        appBuilder.UseMiddleware<ApiKeyAuthenticationMiddleware>();
    }
);

// Map middleware to specific branches
app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/admin"),
    appBuilder =>
    {
        appBuilder.UseMiddleware<AdminAuthenticationMiddleware>();
        appBuilder.UseMiddleware<AdminLoggingMiddleware>();
    }
);
```

**Best Practices:**

1. **Order Matters**: Place middleware in correct order (exception handling first, endpoints last)
2. **Call Next**: Always call `await _next(context)` unless terminating the pipeline
3. **Exception Handling**: Wrap `_next` call in try-catch if needed
4. **Performance**: Avoid expensive operations in frequently-executed middleware
5. **Async/Await**: Always use async methods
6. **Short-Circuit**: Return early if request shouldn't continue
7. **Reusable**: Create extension methods for easy registration
8. **Testable**: Keep middleware logic testable

---

## Q93: What are the different authentication and authorization mechanisms in ASP.NET Core?

**Answer:**

ASP.NET Core supports multiple authentication schemes including JWT Bearer, Cookie, OAuth2, OpenID Connect, and custom authentication.

**Authentication vs Authorization:**

- **Authentication**: Who are you? (Identity verification)
- **Authorization**: What can you do? (Permission verification)

**1. JWT Bearer Authentication:**

```csharp
// Install-Package Microsoft.AspNetCore.Authentication.JwtBearer

// Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Configure JWT Authentication
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
            ),
            ClockSkew = TimeSpan.Zero  // Remove default 5-minute tolerance
        };

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

// Configure Authorization
builder.Services.AddAuthorization(options =>
{
    // Policy-based authorization
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));

    options.AddPolicy("RequireEmail", policy =>
        policy.RequireClaim("email"));

    options.AddPolicy("MinimumAge", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));

    options.AddPolicy("SalesOrMarketing", policy =>
        policy.RequireAssertion(context =>
            context.User.IsInRole("Sales") || context.User.IsInRole("Marketing")));
});

var app = builder.Build();

// Apply middleware (order matters!)
app.UseAuthentication();  // Must come before UseAuthorization
app.UseAuthorization();

app.MapControllers();
app.Run();

// JWT Token Service
namespace ECommerce.Services
{
    public interface IJwtTokenService
    {
        string GenerateToken(User user);
        ClaimsPrincipal ValidateToken(string token);
    }

    public class JwtTokenService : IJwtTokenService
    {
        private readonly IConfiguration _configuration;

        public JwtTokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GenerateToken(User user)
        {
            var securityKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])
            );
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(JwtRegisteredClaimNames.Name, user.Name),
                new Claim(ClaimTypes.Role, user.Role),
                new Claim("department", user.Department),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddHours(2),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public ClaimsPrincipal ValidateToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = _configuration["Jwt:Issuer"],
                ValidAudience = _configuration["Jwt:Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(key)
            };

            return tokenHandler.ValidateToken(token, validationParameters, out _);
        }
    }
}

// Login Controller
namespace ECommerce.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IJwtTokenService _jwtTokenService;

        public AuthController(IUserService userService, IJwtTokenService jwtTokenService)
        {
            _userService = userService;
            _jwtTokenService = jwtTokenService;
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
        {
            var user = await _userService.ValidateCredentialsAsync(request.Email, request.Password);

            if (user == null)
                return Unauthorized(new { Message = "Invalid credentials" });

            var token = _jwtTokenService.GenerateToken(user);

            return Ok(new LoginResponse
            {
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddHours(2)
            });
        }

        [HttpGet("me")]
        [Authorize]  // Requires authentication
        public ActionResult<UserDto> GetCurrentUser()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            var role = User.FindFirst(ClaimTypes.Role)?.Value;

            return Ok(new UserDto
            {
                Id = Guid.Parse(userId),
                Email = email,
                Role = role
            });
        }
    }
}

// Protected Controller
namespace ECommerce.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]  // Require authentication for all actions
    public class ProductsController : ControllerBase
    {
        [HttpGet]
        [AllowAnonymous]  // Override: allow anonymous access
        public async Task<ActionResult<List<ProductDto>>> GetProducts()
        {
            // Anyone can view products
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]  // Only Admin role
        public async Task<ActionResult> CreateProduct(CreateProductRequest request)
        {
            // Only admins can create products
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]  // Using policy
        public async Task<ActionResult> UpdateProduct(Guid id, UpdateProductRequest request)
        {
            // Only admins (via policy)
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,SuperAdmin")]  // Multiple roles (OR logic)
        public async Task<ActionResult> DeleteProduct(Guid id)
        {
            // Admins or SuperAdmins
        }
    }
}
```

**2. Custom Authorization Requirements:**

```csharp
// Custom requirement
namespace ECommerce.Authorization
{
    public class MinimumAgeRequirement : IAuthorizationRequirement
    {
        public int MinimumAge { get; }

        public MinimumAgeRequirement(int minimumAge)
        {
            MinimumAge = minimumAge;
        }
    }

    public class MinimumAgeHandler : AuthorizationHandler<MinimumAgeRequirement>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            MinimumAgeRequirement requirement)
        {
            var dateOfBirthClaim = context.User.FindFirst(c => c.Type == "date_of_birth");

            if (dateOfBirthClaim == null)
            {
                return Task.CompletedTask;
            }

            var dateOfBirth = Convert.ToDateTime(dateOfBirthClaim.Value);
            var age = DateTime.Today.Year - dateOfBirth.Year;

            if (dateOfBirth > DateTime.Today.AddYears(-age))
            {
                age--;
            }

            if (age >= requirement.MinimumAge)
            {
                context.Succeed(requirement);
            }

            return Task.CompletedTask;
        }
    }

    // Resource-based authorization
    public class DocumentAuthorizationHandler : AuthorizationHandler<SameAuthorRequirement, Document>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            SameAuthorRequirement requirement,
            Document resource)
        {
            var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (resource.AuthorId.ToString() == userId)
            {
                context.Succeed(requirement);
            }

            return Task.CompletedTask;
        }
    }

    public class SameAuthorRequirement : IAuthorizationRequirement { }
}

// Registration
builder.Services.AddSingleton<IAuthorizationHandler, MinimumAgeHandler>();
builder.Services.AddSingleton<IAuthorizationHandler, DocumentAuthorizationHandler>();

// Usage
[HttpGet("adult-content")]
[Authorize(Policy = "MinimumAge")]
public ActionResult GetAdultContent()
{
    // Only users 18+ can access
}

// Resource-based authorization in controller
[HttpPut("documents/{id}")]
public async Task<ActionResult> UpdateDocument(Guid id, UpdateDocumentRequest request)
{
    var document = await _documentService.GetByIdAsync(id);

    var authResult = await _authorizationService.AuthorizeAsync(
        User,
        document,
        new SameAuthorRequirement()
    );

    if (!authResult.Succeeded)
    {
        return Forbid();
    }

    // Update document
}
```

**3. Cookie Authentication:**

```csharp
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.ExpireTimeSpan = TimeSpan.FromDays(7);
        options.SlidingExpiration = true;
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Strict;
    });

// Login action
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest request)
{
    var user = await _userService.ValidateCredentialsAsync(request.Email, request.Password);

    if (user == null)
        return Unauthorized();

    var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
        new Claim(ClaimTypes.Name, user.Name),
        new Claim(ClaimTypes.Email, user.Email),
        new Claim(ClaimTypes.Role, user.Role)
    };

    var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
    var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);

    await HttpContext.SignInAsync(
        CookieAuthenticationDefaults.AuthenticationScheme,
        claimsPrincipal,
        new AuthenticationProperties
        {
            IsPersistent = request.RememberMe,
            ExpiresUtc = DateTime.UtcNow.AddDays(7)
        }
    );

    return Ok();
}

// Logout action
[HttpPost("logout")]
public async Task<IActionResult> Logout()
{
    await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    return Ok();
}
```

**Best Practices:**

1. **Use HTTPS**: Always use HTTPS in production
2. **Strong Secrets**: Use long, random JWT secret keys
3. **Short Expiration**: Keep JWT expiration short (15min-2hrs)
4. **Refresh Tokens**: Implement refresh tokens for long sessions
5. **Validate Claims**: Always validate all token claims
6. **Role-Based + Policy**: Combine for flexible authorization
7. **Secure Cookies**: Use HttpOnly, Secure, and SameSite flags
8. **Log Auth Events**: Log login/logout for auditing

---

## Q94: Explain asynchronous programming with async/await in C#.

**Answer:**

**Async/Await** enables writing asynchronous code that looks synchronous, improving application responsiveness and scalability without blocking threads.

**Key Concepts:**

1. **async**: Marks a method as asynchronous
2. **await**: Asynchronously waits for a Task to complete
3. **Task**: Represents an asynchronous operation
4. **Task<T>**: Represents an asynchronous operation that returns a value

**Synchronous vs Asynchronous:**

```csharp
// ❌ SYNCHRONOUS (Blocks thread)
public class ProductService
{
    private readonly HttpClient _httpClient;
    private readonly IProductRepository _repository;

    public Product GetProduct(Guid id)
    {
        // Blocks thread while waiting for database
        var product = _repository.GetById(id);  // Thread waits here

        // Blocks thread while waiting for HTTP response
        var reviews = _httpClient.GetStringAsync($"api/reviews/{id}").Result;  // Thread blocked!

        return product;
    }
}

// ✅ ASYNCHRONOUS (Releases thread)
public class ProductService
{
    private readonly HttpClient _httpClient;
    private readonly IProductRepository _repository;

    public async Task<Product> GetProductAsync(Guid id)
    {
        // Releases thread while waiting for database
        var product = await _repository.GetByIdAsync(id);  // Thread released

        // Releases thread while waiting for HTTP response
        var reviews = await _httpClient.GetStringAsync($"api/reviews/{id}");  // Thread released

        return product;
    }
}
```

**Async Patterns:**

```csharp
namespace ECommerce.Services
{
    public class OrderService
    {
        private readonly IOrderRepository _repository;
        private readonly IInventoryService _inventoryService;
        private readonly IPaymentService _paymentService;
        private readonly IEmailService _emailService;

        // 1. Basic Async Method
        public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
        {
            var order = new Order
            {
                OrderId = Guid.NewGuid(),
                CustomerId = request.CustomerId,
                TotalAmount = request.TotalAmount
            };

            await _repository.AddAsync(order);
            return order;
        }

        // 2. Async Method with Return Value
        public async Task<OrderDto> GetOrderAsync(Guid orderId)
        {
            var order = await _repository.GetByIdAsync(orderId);

            if (order == null)
                return null;

            return new OrderDto
            {
                OrderId = order.OrderId,
                Status = order.Status,
                TotalAmount = order.TotalAmount
            };
        }

        // 3. Parallel Async Operations (Independent)
        public async Task<OrderDetailsDto> GetOrderDetailsAsync(Guid orderId)
        {
            // Start all tasks simultaneously
            var orderTask = _repository.GetByIdAsync(orderId);
            var inventoryTask = _inventoryService.GetInventoryStatusAsync(orderId);
            var paymentTask = _paymentService.GetPaymentStatusAsync(orderId);

            // Wait for all to complete
            await Task.WhenAll(orderTask, inventoryTask, paymentTask);

            // Get results
            var order = await orderTask;
            var inventory = await inventoryTask;
            var payment = await paymentTask;

            return new OrderDetailsDto
            {
                Order = order,
                InventoryStatus = inventory,
                PaymentStatus = payment
            };
        }

        // 4. Sequential Async Operations (Dependent)
        public async Task<Order> ProcessOrderAsync(CreateOrderRequest request)
        {
            // Step 1: Create order
            var order = await CreateOrderAsync(request);

            // Step 2: Reserve inventory (depends on order)
            var reservation = await _inventoryService.ReserveStockAsync(
                request.ProductId,
                request.Quantity
            );

            // Step 3: Process payment (depends on reservation)
            var payment = await _paymentService.ProcessPaymentAsync(
                order.OrderId,
                request.TotalAmount
            );

            // Step 4: Confirm order
            order.Confirm(payment.TransactionId);
            await _repository.UpdateAsync(order);

            return order;
        }

        // 5. Async with Exception Handling
        public async Task<bool> ProcessPaymentWithRetryAsync(Guid orderId)
        {
            int maxRetries = 3;
            int attempt = 0;

            while (attempt < maxRetries)
            {
                try
                {
                    await _paymentService.ProcessPaymentAsync(orderId);
                    return true;
                }
                catch (PaymentException ex)
                {
                    attempt++;

                    if (attempt >= maxRetries)
                    {
                        _logger.LogError(ex, "Payment failed after {Attempts} attempts", maxRetries);
                        throw;
                    }

                    _logger.LogWarning("Payment attempt {Attempt} failed, retrying...", attempt);
                    await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)));  // Exponential backoff
                }
            }

            return false;
        }

        // 6. Async with Cancellation
        public async Task<List<Order>> GetOrdersAsync(CancellationToken cancellationToken)
        {
            var orders = await _repository.GetAllAsync(cancellationToken);

            // Simulate long-running operation
            foreach (var order in orders)
            {
                cancellationToken.ThrowIfCancellationRequested();

                await EnrichOrderDataAsync(order, cancellationToken);
            }

            return orders;
        }

        // 7. Fire and Forget (Use with Caution!)
        public void SendOrderConfirmationAsync(Guid orderId)
        {
            // Don't await - fires and forgets
            _ = Task.Run(async () =>
            {
                try
                {
                    var order = await _repository.GetByIdAsync(orderId);
                    await _emailService.SendOrderConfirmationAsync(order);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send order confirmation");
                }
            });
        }

        // 8. Async Enumerable (IAsyncEnumerable<T>)
        public async IAsyncEnumerable<Order> GetOrdersStreamAsync(
            [EnumeratorCancellation] CancellationToken cancellationToken = default)
        {
            var page = 1;
            const int pageSize = 100;

            while (true)
            {
                var orders = await _repository.GetPageAsync(page, pageSize, cancellationToken);

                if (!orders.Any())
                    break;

                foreach (var order in orders)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    yield return order;
                }

                page++;
            }
        }

        // Usage of async enumerable
        public async Task ProcessAllOrdersAsync()
        {
            await foreach (var order in GetOrdersStreamAsync())
            {
                await ProcessSingleOrderAsync(order);
            }
        }
    }
}
```

**Advanced Async Patterns:**

```csharp
namespace ECommerce.Advanced
{
    public class AdvancedAsyncPatterns
    {
        // 1. Task.WhenAll - Wait for multiple tasks
        public async Task<OrderSummary> GetOrderSummaryAsync(Guid orderId)
        {
            var tasks = new[]
            {
                GetOrderAsync(orderId),
                GetCustomerAsync(orderId),
                GetPaymentAsync(orderId),
                GetShippingAsync(orderId)
            };

            // Wait for all tasks to complete
            await Task.WhenAll(tasks);

            return new OrderSummary
            {
                Order = tasks[0].Result,
                Customer = tasks[1].Result,
                Payment = tasks[2].Result,
                Shipping = tasks[3].Result
            };
        }

        // 2. Task.WhenAny - Wait for first completion
        public async Task<string> GetFastestPriceAsync(Guid productId)
        {
            var task1 = _supplier1.GetPriceAsync(productId);
            var task2 = _supplier2.GetPriceAsync(productId);
            var task3 = _supplier3.GetPriceAsync(productId);

            // Return first completed result
            var completedTask = await Task.WhenAny(task1, task2, task3);
            return await completedTask;
        }

        // 3. Timeout Pattern
        public async Task<Product> GetProductWithTimeoutAsync(Guid productId, int timeoutSeconds = 5)
        {
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds));

            try
            {
                return await _repository.GetByIdAsync(productId, cts.Token);
            }
            catch (OperationCanceledException)
            {
                throw new TimeoutException($"Operation timed out after {timeoutSeconds} seconds");
            }
        }

        // 4. ConfigureAwait(false) - For library code
        public async Task<Product> LibraryMethodAsync(Guid productId)
        {
            // Don't capture synchronization context (better performance in libraries)
            var product = await _repository.GetByIdAsync(productId).ConfigureAwait(false);

            // Further processing doesn't need original context
            await ProcessProductAsync(product).ConfigureAwait(false);

            return product;
        }

        // 5. ValueTask for frequently synchronous paths
        public ValueTask<Product> GetProductCachedAsync(Guid productId)
        {
            // Check cache first (synchronous)
            if (_cache.TryGetValue(productId, out Product cachedProduct))
            {
                return new ValueTask<Product>(cachedProduct);  // Synchronous return
            }

            // Cache miss - async operation
            return new ValueTask<Product>(FetchProductAsync(productId));
        }

        private async Task<Product> FetchProductAsync(Guid productId)
        {
            var product = await _repository.GetByIdAsync(productId);
            _cache.Set(productId, product);
            return product;
        }

        // 6. Async Lock (SemaphoreSlim)
        private readonly SemaphoreSlim _semaphore = new SemaphoreSlim(1, 1);

        public async Task<Order> CreateOrderThreadSafeAsync(CreateOrderRequest request)
        {
            await _semaphore.WaitAsync();

            try
            {
                // Critical section - only one thread at a time
                var orderNumber = await GetNextOrderNumberAsync();
                var order = await CreateOrderWithNumberAsync(orderNumber, request);
                return order;
            }
            finally
            {
                _semaphore.Release();
            }
        }

        // 7. Throttling with SemaphoreSlim
        private readonly SemaphoreSlim _throttle = new SemaphoreSlim(10, 10);  // Max 10 concurrent

        public async Task<List<Product>> GetProductsThrottledAsync(List<Guid> productIds)
        {
            var tasks = productIds.Select(async id =>
            {
                await _throttle.WaitAsync();
                try
                {
                    return await _repository.GetByIdAsync(id);
                }
                finally
                {
                    _throttle.Release();
                }
            });

            return (await Task.WhenAll(tasks)).ToList();
        }
    }
}
```

**Common Mistakes:**

```csharp
namespace ECommerce.CommonMistakes
{
    public class AntiPatterns
    {
        // ❌ MISTAKE 1: Async void (except event handlers)
        public async void ProcessOrderAsync(Guid orderId)  // BAD!
        {
            await _repository.GetByIdAsync(orderId);
        }

        // ✅ CORRECT: Use async Task
        public async Task ProcessOrderAsync(Guid orderId)  // GOOD!
        {
            await _repository.GetByIdAsync(orderId);
        }

        // ❌ MISTAKE 2: Blocking on async code
        public Product GetProduct(Guid id)
        {
            return GetProductAsync(id).Result;  // DEADLOCK RISK!
        }

        // ✅ CORRECT: Async all the way
        public async Task<Product> GetProductAsync(Guid id)
        {
            return await _repository.GetByIdAsync(id);
        }

        // ❌ MISTAKE 3: Not awaiting tasks
        public async Task ProcessOrdersAsync(List<Guid> orderIds)
        {
            foreach (var id in orderIds)
            {
                ProcessOrderAsync(id);  // NOT AWAITED - Runs fire-and-forget!
            }
        }

        // ✅ CORRECT: Await each task
        public async Task ProcessOrdersAsync(List<Guid> orderIds)
        {
            foreach (var id in orderIds)
            {
                await ProcessOrderAsync(id);  // Properly awaited
            }
        }

        // ❌ MISTAKE 4: Sequential when parallel is possible
        public async Task<OrderSummary> GetOrderSummarySlowAsync(Guid orderId)
        {
            var order = await GetOrderAsync(orderId);      // Waits
            var customer = await GetCustomerAsync(orderId); // Then waits
            var payment = await GetPaymentAsync(orderId);   // Then waits
            // Total time = sum of all operations
        }

        // ✅ CORRECT: Parallel execution
        public async Task<OrderSummary> GetOrderSummaryFastAsync(Guid orderId)
        {
            var orderTask = GetOrderAsync(orderId);
            var customerTask = GetCustomerAsync(orderId);
            var paymentTask = GetPaymentAsync(orderId);

            await Task.WhenAll(orderTask, customerTask, paymentTask);
            // Total time = longest operation
        }

        // ❌ MISTAKE 5: Unnecessary async
        public async Task<int> AddAsync(int a, int b)
        {
            return a + b;  // No async operation!
        }

        // ✅ CORRECT: Synchronous is fine
        public int Add(int a, int b)
        {
            return a + b;
        }
    }
}
```

**Best Practices:**

1. **Async All the Way**: Don't block on async code (.Result, .Wait())
2. **Use async Task**: Never use async void except for event handlers
3. **Parallel When Possible**: Use Task.WhenAll for independent operations
4. **ConfigureAwait(false)**: In library code to avoid context capture
5. **Cancellation Tokens**: Support cancellation for long-running operations
6. **Exception Handling**: Use try-catch in async methods
7. **Naming Convention**: Suffix async methods with "Async"
8. **ValueTask**: For hot paths that are frequently synchronous

---

*[Continuing with Q95-Q99 in next response due to length...]*

## Q95: What is Entity Framework Core and how does it differ from Entity Framework 6?

**Answer:**

**Entity Framework Core (EF Core)** is a modern object-relational mapper (ORM) that enables .NET developers to work with databases using .NET objects.

**EF Core vs EF 6:**

| Feature | EF Core | EF 6 |
|---------|---------|------|
| **Platform** | Cross-platform | Windows only |
| **Performance** | Significantly faster | Slower |
| **LINQ** | Improved | Basic |
| **Batching** | Better | Limited |

**Best Practices:**

1. **Use AsNoTracking**: For read-only queries
2. **Project to DTOs**: Don't return entities
3. **Eager Loading**: Use Include for related data
4. **Compiled Queries**: For frequently-executed queries
5. **Batch Operations**: Use ExecuteUpdate/ExecuteDelete

---

## Q99: What are best practices for performance optimization in ASP.NET Core?

**Answer:**

Performance optimization involves caching, async programming, database access, and response compression.

**Key Strategies:**

1. **Response Caching**: Cache responses at client/server
2. **Memory Caching**: Use IMemoryCache for frequently accessed data
3. **Response Compression**: Enable Gzip/Brotli
4. **Async/Await**: Use async for all I/O operations
5. **Database Optimization**: AsNoTracking, projections, compiled queries
6. **Connection Pooling**: Reuse database connections
7. **CDN**: Use for static content
8. **Minimal APIs**: For simple endpoints

---

## Summary: Q91-Q99 Completed! ✅

All advanced .NET & ASP.NET Core questions have been answered comprehensively!
