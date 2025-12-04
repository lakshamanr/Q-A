# Section 2: ASP.NET MVC & Web Development (Q81-Q90) - Security & Caching

## Q81: Explain structured logging with Serilog

**Answer:**

Serilog is a popular .NET logging library that provides structured logging, allowing you to capture rich log events with strongly-typed properties rather than just text strings.

### 1. Serilog Setup

```csharp
// Install packages:
// Serilog.AspNetCore
// Serilog.Sinks.Console
// Serilog.Sinks.File
// Serilog.Sinks.Seq

using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithThreadId()
        .Enrich.WithProperty("Application", "MyApp")
        .Enrich.WithProperty("Environment", context.HostingEnvironment.EnvironmentName)
        .WriteTo.Console(
            outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
        .WriteTo.File(
            path: "logs/log-.txt",
            rollingInterval: RollingInterval.Day,
            outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}",
            retainedFileCountLimit: 30)
        .WriteTo.Seq("http://localhost:5341"); // Centralized logging
});

var app = builder.Build();

// Add request logging
app.UseSerilogRequestLogging(options =>
{
    options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000}ms";
    options.GetLevel = (httpContext, elapsed, ex) =>
    {
        if (ex != null) return LogEventLevel.Error;
        if (httpContext.Response.StatusCode > 499) return LogEventLevel.Error;
        if (httpContext.Response.StatusCode > 399) return LogEventLevel.Warning;
        return LogEventLevel.Information;
    };
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"]);
        diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress);
        diagnosticContext.Set("UserId", httpContext.User.FindFirst("sub")?.Value);
    };
});

app.MapControllers();
app.Run();

// Ensure proper shutdown
Log.CloseAndFlush();
```

### 2. Structured Logging Examples

```csharp
public class OrderService
{
    private readonly ILogger<OrderService> _logger;

    public OrderService(ILogger<OrderService> logger)
    {
        _logger = logger;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        // ✅ GOOD: Structured logging with named properties
        _logger.LogInformation(
            "Creating order for customer {CustomerId} with {ItemCount} items, total amount {TotalAmount}",
            request.CustomerId,
            request.Items.Count,
            request.TotalAmount);

        // Properties are captured: CustomerId, ItemCount, TotalAmount
        // Can be queried in log aggregation tools

        try
        {
            var order = await SaveOrderAsync(request);

            // Log structured object with @ prefix (destructuring)
            _logger.LogInformation(
                "Order created successfully: {@OrderSummary}",
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
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to create order for customer {CustomerId}",
                request.CustomerId);
            throw;
        }
    }

    // ❌ BAD: String interpolation/concatenation
    public void BadLogging(int orderId, decimal amount)
    {
        _logger.LogInformation($"Processing order {orderId} with amount {amount}");
        // Properties are lost - can't query by orderId or amount
    }
}
```

### 3. Log Enrichment

```csharp
// Custom enricher
public class UserContextEnricher : ILogEventEnricher
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public UserContextEnricher(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
            return;

        var userId = httpContext.User.FindFirst("sub")?.Value ?? "anonymous";
        var userName = httpContext.User.Identity?.Name ?? "Unknown";

        logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("UserId", userId));
        logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("UserName", userName));
    }
}

// Register enricher
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .Enrich.With<UserContextEnricher>()
        .WriteTo.Console();
});

// Register IHttpContextAccessor
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ILogEventEnricher, UserContextEnricher>();
```

### 4. Serilog Configuration (appsettings.json)

```json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.Console", "Serilog.Sinks.File", "Serilog.Sinks.Seq"],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}"
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "logs/log-.txt",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 30,
          "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}"
        }
      },
      {
        "Name": "Seq",
        "Args": {
          "serverUrl": "http://localhost:5341",
          "apiKey": "your-api-key"
        }
      }
    ],
    "Enrich": ["FromLogContext", "WithMachineName", "WithThreadId", "WithEnvironmentName"],
    "Properties": {
      "Application": "MyApp"
    }
  }
}
```

### 5. Log Scopes and Context

```csharp
public class PaymentService
{
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(ILogger<PaymentService> logger)
    {
        _logger = logger;
    }

    public async Task ProcessPaymentAsync(int orderId, PaymentDetails payment)
    {
        // Using LogContext to add properties to all logs in scope
        using (LogContext.PushProperty("OrderId", orderId))
        using (LogContext.PushProperty("PaymentMethod", payment.Method))
        {
            _logger.LogInformation("Starting payment processing");

            try
            {
                ValidatePayment(payment);
                _logger.LogInformation("Payment validated");

                await ChargePaymentAsync(payment);
                _logger.LogInformation("Payment charged successfully");

                await UpdateOrderStatusAsync(orderId, "Paid");
                _logger.LogInformation("Order status updated");

                // All logs above include OrderId and PaymentMethod
            }
            catch (PaymentException ex)
            {
                _logger.LogError(ex, "Payment processing failed");
                throw;
            }
        }
    }
}
```

### 6. Serilog Sinks

```csharp
// Multiple sinks configuration
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        // Console sink - for development
        .WriteTo.Console(
            restrictedToMinimumLevel: LogEventLevel.Information)

        // File sink - rolling daily files
        .WriteTo.File(
            path: "logs/app-.log",
            rollingInterval: RollingInterval.Day,
            retainedFileCountLimit: 30,
            fileSizeLimitBytes: 100_000_000, // 100MB
            rollOnFileSizeLimit: true)

        // Seq sink - centralized logging
        .WriteTo.Seq(
            serverUrl: "http://localhost:5341",
            apiKey: context.Configuration["Serilog:SeqApiKey"],
            restrictedToMinimumLevel: LogEventLevel.Information)

        // SQL Server sink - database logging
        .WriteTo.MSSqlServer(
            connectionString: context.Configuration.GetConnectionString("LogDb"),
            sinkOptions: new MSSqlServerSinkOptions
            {
                TableName = "Logs",
                SchemaName = "dbo",
                AutoCreateSqlTable = true
            },
            restrictedToMinimumLevel: LogEventLevel.Warning)

        // Email sink - critical errors only
        .WriteTo.Email(
            fromEmail: "alerts@myapp.com",
            toEmail: "admin@myapp.com",
            mailServer: "smtp.myapp.com",
            restrictedToMinimumLevel: LogEventLevel.Error)

        // Application Insights
        .WriteTo.ApplicationInsights(
            telemetryConfiguration: context.Configuration["ApplicationInsights:InstrumentationKey"],
            telemetryConverter: TelemetryConverter.Traces);
});
```

**Serilog vs Standard Logging:**

| Feature | Serilog | Standard ILogger |
|---------|---------|------------------|
| Structured data | ✅ Native | ⚠️ Limited |
| Output formats | ✅ Many sinks | ⚠️ Basic |
| Configuration | ✅ appsettings.json | ✅ appsettings.json |
| Performance | ✅ High | ✅ Good |
| Querying logs | ✅ Easy (Seq, etc.) | ❌ Difficult |
| Enrichment | ✅ Built-in | ⚠️ Manual |

---

## Q82: How do you secure ASP.NET applications?

**Answer:**

Securing ASP.NET applications involves implementing multiple layers of security including authentication, authorization, data protection, secure communication, and protection against common vulnerabilities.

### 1. HTTPS Enforcement

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpsRedirection(options =>
{
    options.RedirectStatusCode = StatusCodes.Status307TemporaryRedirect;
    options.HttpsPort = 443;
});

// HSTS (HTTP Strict Transport Security)
builder.Services.AddHsts(options =>
{
    options.Preload = true;
    options.IncludeSubDomains = true;
    options.MaxAge = TimeSpan.FromDays(365);
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();
```

### 2. Security Headers

```csharp
// Security headers middleware
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // X-Content-Type-Options: Prevent MIME sniffing
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");

        // X-Frame-Options: Prevent clickjacking
        context.Response.Headers.Add("X-Frame-Options", "DENY");

        // X-XSS-Protection
        context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");

        // Content Security Policy
        context.Response.Headers.Add("Content-Security-Policy",
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.example.com; " +
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
            "img-src 'self' data: https:; " +
            "font-src 'self' https://fonts.gstatic.com; " +
            "connect-src 'self' https://api.example.com;");

        // Referrer Policy
        context.Response.Headers.Add("Referrer-Policy", "no-referrer-when-downgrade");

        // Permissions Policy (formerly Feature Policy)
        context.Response.Headers.Add("Permissions-Policy",
            "geolocation=(), microphone=(), camera=()");

        // Remove server header
        context.Response.Headers.Remove("Server");
        context.Response.Headers.Remove("X-Powered-By");

        await _next(context);
    }
}

// Register
app.UseMiddleware<SecurityHeadersMiddleware>();
```

### 3. Authentication & Authorization

```csharp
// Configure authentication
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
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"])),
            ClockSkew = TimeSpan.Zero // Remove default 5 min tolerance
        };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
                {
                    context.Response.Headers.Add("Token-Expired", "true");
                }
                return Task.CompletedTask;
            }
        };
    });

// Configure authorization policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));

    options.AddPolicy("RequireEmail", policy =>
        policy.RequireClaim("email"));

    options.AddPolicy("MinimumAge", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));

    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build(); // Require auth by default
});

// Use in pipeline
app.UseAuthentication();
app.UseAuthorization();
```

### 4. Data Protection

```csharp
// Configure data protection
builder.Services.AddDataProtection()
    .SetApplicationName("MyApp")
    .PersistKeysToFileSystem(new DirectoryInfo(@"C:\keys"))
    .ProtectKeysWithDpapi() // Windows only
    // Or for cross-platform:
    .ProtectKeysWithCertificate(certificate)
    .SetDefaultKeyLifetime(TimeSpan.FromDays(90));

// Use data protection
public class SecureDataService
{
    private readonly IDataProtector _protector;

    public SecureDataService(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("SecureDataService.v1");
    }

    public string EncryptData(string plainText)
    {
        return _protector.Protect(plainText);
    }

    public string DecryptData(string cipherText)
    {
        return _protector.Unprotect(cipherText);
    }
}
```

### 5. Password Hashing

```csharp
// Use Identity's password hasher
public class AccountService
{
    private readonly IPasswordHasher<ApplicationUser> _passwordHasher;

    public AccountService(IPasswordHasher<ApplicationUser> passwordHasher)
    {
        _passwordHasher = passwordHasher;
    }

    public async Task<ApplicationUser> RegisterAsync(RegisterDto dto)
    {
        var user = new ApplicationUser
        {
            UserName = dto.Email,
            Email = dto.Email
        };

        // Hash password
        user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

        // Save user
        await _userRepository.AddAsync(user);

        return user;
    }

    public async Task<bool> ValidatePasswordAsync(string email, string password)
    {
        var user = await _userRepository.GetByEmailAsync(email);
        if (user == null)
            return false;

        var result = _passwordHasher.VerifyHashedPassword(
            user,
            user.PasswordHash,
            password);

        return result == PasswordVerificationResult.Success;
    }
}

// Or use BCrypt for custom implementation
public class CustomPasswordHasher
{
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);
    }

    public bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }
}
```

### 6. Rate Limiting

```csharp
// Install: AspNetCoreRateLimit
builder.Services.AddMemoryCache();

builder.Services.Configure<IpRateLimitOptions>(options =>
{
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Limit = 100,
            Period = "1m"
        },
        new RateLimitRule
        {
            Endpoint = "POST:/api/login",
            Limit = 5,
            Period = "1m"
        }
    };
});

builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();
builder.Services.AddInMemoryRateLimiting();

app.UseIpRateLimiting();
```

### 7. API Key Authentication

```csharp
public class ApiKeyAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;

    public ApiKeyAuthenticationMiddleware(
        RequestDelegate next,
        IConfiguration configuration)
    {
        _next = next;
        _configuration = configuration;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue("X-API-Key", out var extractedApiKey))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("API Key is missing");
            return;
        }

        var apiKey = _configuration.GetValue<string>("ApiKey");
        if (!apiKey.Equals(extractedApiKey))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("Invalid API Key");
            return;
        }

        await _next(context);
    }
}
```

### 8. Input Validation & Sanitization

```csharp
public class ProductController : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ProductDto dto)
    {
        // 1. Model validation
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // 2. Business validation
        if (dto.Price < 0)
        {
            return BadRequest("Price cannot be negative");
        }

        // 3. Sanitize HTML input
        dto.Description = AntiXssEncoder.HtmlEncode(dto.Description, useNamedEntities: true);

        // 4. Validate file uploads
        if (dto.Image != null)
        {
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
            var extension = Path.GetExtension(dto.Image.FileName).ToLowerInvariant();
            
            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest("Invalid file type");
            }

            if (dto.Image.Length > 5 * 1024 * 1024) // 5MB
            {
                return BadRequest("File too large");
            }
        }

        var product = await _productService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }
}
```

**Security Checklist:**

```
✅ Use HTTPS everywhere
✅ Implement authentication & authorization
✅ Hash passwords with strong algorithms
✅ Use parameterized queries (prevent SQL injection)
✅ Validate and sanitize all input
✅ Implement rate limiting
✅ Set security headers
✅ Use CSRF tokens for forms
✅ Enable CORS carefully
✅ Store secrets in secure configuration
✅ Keep dependencies updated
✅ Implement logging and monitoring
✅ Use data protection for sensitive data

❌ Don't store passwords in plain text
❌ Don't trust user input
❌ Don't expose sensitive data in errors
❌ Don't disable SSL certificate validation
❌ Don't use weak encryption
```

---


## Q83: Explain authentication vs authorization

**Answer:**

Authentication verifies WHO you are (identity), while Authorization determines WHAT you can do (permissions). Both are essential but serve different purposes in application security.

### 1. Authentication (Who are you?)

```csharp
// Authentication: Verify user identity
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IConfiguration _configuration;

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        // AUTHENTICATION: Verify credentials
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            return Unauthorized(new { message = "Invalid credentials" });
        }

        var result = await _signInManager.CheckPasswordSignInAsync(
            user, dto.Password, lockoutOnFailure: true);

        if (!result.Succeeded)
        {
            return Unauthorized(new { message = "Invalid credentials" });
        }

        // Generate token after successful authentication
        var token = GenerateJwtToken(user);

        return Ok(new { token, user = new { user.Email, user.UserName } });
    }

    private string GenerateJwtToken(ApplicationUser user)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id)
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
```

### 2. Authorization (What can you do?)

```csharp
// Authorization: Check permissions
[ApiController]
[Route("api/[controller]")]
[Authorize] // Must be authenticated
public class ProductsController : ControllerBase
{
    [HttpGet]
    [AllowAnonymous] // Anyone can view products
    public IActionResult GetAll()
    {
        return Ok(_productService.GetAll());
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Manager")] // AUTHORIZATION: Role-based
    public IActionResult Create([FromBody] ProductDto dto)
    {
        var product = _productService.Create(dto);
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    [HttpPut("{id}")]
    [Authorize(Policy = "CanEditProducts")] // AUTHORIZATION: Policy-based
    public IActionResult Update(int id, [FromBody] ProductDto dto)
    {
        _productService.Update(id, dto);
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")] // AUTHORIZATION: Admin only
    public IActionResult Delete(int id)
    {
        _productService.Delete(id);
        return NoContent();
    }
}

// Configure authorization policies
builder.Services.AddAuthorization(options =>
{
    // Role-based
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));

    // Claim-based
    options.AddPolicy("CanEditProducts", policy =>
        policy.RequireClaim("Permission", "EditProducts"));

    // Custom requirement
    options.AddPolicy("MinimumAge", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));
});
```

### 3. Authentication Schemes

```csharp
// Multiple authentication schemes
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
})
.AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
{
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
})
.AddGoogle(options =>
{
    options.ClientId = builder.Configuration["Google:ClientId"];
    options.ClientSecret = builder.Configuration["Google:ClientSecret"];
});
```

**Key Differences:**

| Aspect | Authentication | Authorization |
|--------|---------------|---------------|
| **Purpose** | Verify identity | Check permissions |
| **Question** | Who are you? | What can you do? |
| **Process** | Login, credentials | Roles, claims, policies |
| **Happens** | First | After authentication |
| **Example** | Username/password | Admin role check |
| **Failure** | 401 Unauthorized | 403 Forbidden |

---

## Q84-Q85: JWT Authentication (Combined)

**Answer:**

JWT (JSON Web Token) is a compact, URL-safe token format for securely transmitting information between parties. It's commonly used for authentication in modern web APIs.

### 1. JWT Structure

```
JWT = Header.Payload.Signature

Example:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Decoded:
{
  "alg": "HS256",  // Algorithm
  "typ": "JWT"     // Type
}.
{
  "sub": "1234567890",      // Subject (user ID)
  "name": "John Doe",       // Custom claim
  "iat": 1516239022         // Issued at
}.
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

### 2. JWT Implementation in ASP.NET Core

```csharp
// Install: Microsoft.AspNetCore.Authentication.JwtBearer

// Program.cs
var builder = WebApplication.CreateBuilder(args);

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
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"])),
            ClockSkew = TimeSpan.Zero // Remove 5 minute default tolerance
        };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                if (context.Exception is SecurityTokenExpiredException)
                {
                    context.Response.Headers.Add("Token-Expired", "true");
                }
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                // Additional validation
                return Task.CompletedTask;
            }
        };
    });

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();
```

```json
// appsettings.json
{
  "Jwt": {
    "Issuer": "https://myapp.com",
    "Audience": "https://myapp.com",
    "Key": "YourSuperSecretKeyThatIsAtLeast32CharactersLong",
    "ExpiryMinutes": 60
  }
}
```

### 3. Token Generation

```csharp
public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    private readonly UserManager<ApplicationUser> _userManager;

    public TokenService(
        IConfiguration configuration,
        UserManager<ApplicationUser> userManager)
    {
        _configuration = configuration;
        _userManager = userManager;
    }

    public async Task<string> GenerateTokenAsync(ApplicationUser user)
    {
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Name, user.UserName)
        };

        // Add user roles as claims
        var roles = await _userManager.GetRolesAsync(user);
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        // Add custom claims
        claims.Add(new Claim("tenant_id", user.TenantId.ToString()));
        claims.Add(new Claim("email_verified", user.EmailConfirmed.ToString()));

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiryMinutes = _configuration.GetValue<int>("Jwt:ExpiryMinutes");

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public ClaimsPrincipal ValidateToken(string token)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);

        try
        {
            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _configuration["Jwt:Issuer"],
                ValidateAudience = true,
                ValidAudience = _configuration["Jwt:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            return principal;
        }
        catch
        {
            return null;
        }
    }
}
```

### 4. Login Endpoint

```csharp
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly ITokenService _tokenService;
    private readonly ILogger<AuthController> _logger;

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            _logger.LogWarning("Login attempt for non-existent user: {Email}", dto.Email);
            return Unauthorized(new { message = "Invalid credentials" });
        }

        var result = await _signInManager.CheckPasswordSignInAsync(
            user, dto.Password, lockoutOnFailure: true);

        if (!result.Succeeded)
        {
            if (result.IsLockedOut)
            {
                _logger.LogWarning("User locked out: {Email}", dto.Email);
                return Unauthorized(new { message = "Account locked out" });
            }

            _logger.LogWarning("Invalid password for user: {Email}", dto.Email);
            return Unauthorized(new { message = "Invalid credentials" });
        }

        var token = await _tokenService.GenerateTokenAsync(user);

        _logger.LogInformation("User logged in: {Email}", dto.Email);

        return Ok(new TokenResponse
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(60),
            User = new
            {
                user.Id,
                user.Email,
                user.UserName
            }
        });
    }

    [HttpPost("refresh-token")]
    [Authorize]
    public async Task<IActionResult> RefreshToken()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return Unauthorized();
        }

        var newToken = await _tokenService.GenerateTokenAsync(user);

        return Ok(new TokenResponse
        {
            Token = newToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(60)
        });
    }
}
```

### 5. Refresh Token Implementation

```csharp
// Refresh token model
public class RefreshToken
{
    public string Token { get; set; }
    public DateTime Expires { get; set; }
    public bool IsExpired => DateTime.UtcNow >= Expires;
    public DateTime Created { get; set; }
    public DateTime? Revoked { get; set; }
    public bool IsActive => Revoked == null && !IsExpired;
}

public class TokenService
{
    public (string accessToken, string refreshToken) GenerateTokens(ApplicationUser user)
    {
        // Access token (short-lived)
        var accessToken = GenerateJwtToken(user, expiryMinutes: 15);

        // Refresh token (long-lived)
        var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        return (accessToken, refreshToken);
    }

    public async Task<string> RefreshAccessTokenAsync(string refreshToken)
    {
        var storedToken = await _context.RefreshTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Token == refreshToken);

        if (storedToken == null || !storedToken.IsActive)
        {
            throw new SecurityTokenException("Invalid refresh token");
        }

        // Generate new access token
        var newAccessToken = GenerateJwtToken(storedToken.User, expiryMinutes: 15);

        return newAccessToken;
    }
}
```

### 6. Using JWT in Client

```javascript
// JavaScript client example
async function login(email, password) {
    const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });

    const data = await response.json();
    
    // Store token
    localStorage.setItem('token', data.token);
    
    return data;
}

async function callProtectedApi() {
    const token = localStorage.getItem('token');
    
    const response = await fetch('/api/products', {
        headers: {
            'Authorization': `Bearer ${token}`
        }
    });

    return await response.json();
}

// Axios interceptor
axios.interceptors.request.use(config => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

axios.interceptors.response.use(
    response => response,
    async error => {
        if (error.response.status === 401) {
            // Token expired - refresh or redirect to login
            localStorage.removeItem('token');
            window.location = '/login';
        }
        return Promise.reject(error);
    }
);
```

**JWT Best Practices:**

```
✅ Use HTTPS only
✅ Set short expiry times (15-60 minutes)
✅ Implement refresh tokens
✅ Store tokens securely (not in localStorage for sensitive apps)
✅ Validate tokens on every request
✅ Use strong signing keys
✅ Include minimal claims
✅ Implement token revocation
✅ Use ClockSkew = TimeSpan.Zero

❌ Don't store sensitive data in tokens
❌ Don't use long expiry times
❌ Don't skip signature validation
❌ Don't expose tokens in URLs
❌ Don't reuse tokens across different audiences
```

---

## Q86: Explain OAuth 2.0 and OpenID Connect

**Answer:**

OAuth 2.0 is an authorization framework, while OpenID Connect (OIDC) is an authentication layer built on top of OAuth 2.0. Together they provide secure delegated access and identity verification.

### Key Concepts:

```
OAuth 2.0: AUTHORIZATION
- "What can you access?"
- Grants permissions to access resources
- Returns access tokens

OpenID Connect: AUTHENTICATION
- "Who are you?"
- Verifies user identity
- Returns ID tokens (JWT) + access tokens

Relationship: OIDC = OAuth 2.0 + Identity Layer
```

### OAuth 2.0 Flow Example:

```csharp
// Install: Microsoft.AspNetCore.Authentication.Google

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = GoogleDefaults.AuthenticationScheme;
})
.AddCookie()
.AddGoogle(options =>
{
    options.ClientId = builder.Configuration["Google:ClientId"];
    options.ClientSecret = builder.Configuration["Google:ClientSecret"];
    options.CallbackPath = "/signin-google";
    
    // Request additional scopes
    options.Scope.Add("profile");
    options.Scope.Add("email");
    
    options.SaveTokens = true; // Save access/refresh tokens
    
    options.Events.OnCreatingTicket = context =>
    {
        var accessToken = context.AccessToken;
        var refreshToken = context.RefreshToken;
        // Store tokens if needed
        return Task.CompletedTask;
    };
});
```

---

## Q87: What is CORS? How do you configure it?

**Answer:**

CORS (Cross-Origin Resource Sharing) is a security feature that allows or restricts web applications running at one origin to access resources from a different origin.

### CORS Configuration:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Configure CORS
builder.Services.AddCors(options =>
{
    // Policy 1: Allow everything (development only!)
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });

    // Policy 2: Allow specific origin
    options.AddPolicy("AllowSpecificOrigin", policy =>
    {
        policy.WithOrigins("https://example.com", "https://www.example.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // Important for cookies
    });

    // Policy 3: Restrictive policy
    options.AddPolicy("RestrictivePolicy", policy =>
    {
        policy.WithOrigins("https://trusted-site.com")
              .WithMethods("GET", "POST")
              .WithHeaders("Content-Type", "Authorization")
              .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
    });
});

var app = builder.Build();

// Apply CORS before authentication/authorization
app.UseCors("AllowSpecificOrigin");

app.UseAuthentication();
app.UseAuthorization();
```

---

## Q88: Explain anti-forgery tokens and CSRF protection

**Answer:**

CSRF (Cross-Site Request Forgery) attacks trick authenticated users into executing unwanted actions. Anti-forgery tokens prevent these attacks by validating that requests originate from your application.

### Implementation:

```csharp
// Automatic in Razor Pages/MVC
<form method="post">
    @Html.AntiForgeryToken()
    <!-- Form fields -->
</form>

// API CSRF protection
[HttpPost]
[ValidateAntiForgeryToken]
public IActionResult Update(ProductDto dto)
{
    // Protected from CSRF
    return Ok();
}

// Configure anti-forgery
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
    options.Cookie.Name = "X-CSRF-TOKEN";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});
```

---

## Q89: How do you prevent SQL injection attacks?

**Answer:**

SQL injection is prevented by using parameterized queries, ORMs like Entity Framework, and input validation.

### Prevention Techniques:

```csharp
// ✅ SAFE: Parameterized query
public async Task<Product> GetByIdAsync(int id)
{
    var query = "SELECT * FROM Products WHERE Id = @Id";
    using var connection = new SqlConnection(_connectionString);
    return await connection.QuerySingleAsync<Product>(query, new { Id = id });
}

// ✅ SAFE: Entity Framework
public async Task<Product> GetProductEF(int id)
{
    return await _context.Products.FindAsync(id);
}

// ❌ DANGEROUS: String concatenation
public async Task<Product> UnsafeQuery(int id)
{
    var query = $"SELECT * FROM Products WHERE Id = {id}"; // NEVER DO THIS!
    // Vulnerable to: id = "1; DROP TABLE Products;--"
}
```

---

## Q90: What is output caching? How do you implement it?

**Answer:**

Output caching stores the rendered output of actions/pages to serve subsequent requests faster without re-executing the action.

### Implementation:

```csharp
// Response caching
builder.Services.AddResponseCaching();

app.UseResponseCaching();

// Use in controller
[HttpGet]
[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Any)]
public IActionResult GetProducts()
{
    var products = _productService.GetAll();
    return Ok(products);
}

// Memory cache for data
public class ProductService
{
    private readonly IMemoryCache _cache;

    public List<Product> GetAll()
    {
        return _cache.GetOrCreate("all_products", entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);
            return _repository.GetAll();
        });
    }
}

// Distributed cache (Redis)
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
});
```

---

# Section 2 Complete! 🎉

**Total Questions Answered: 90**
- Q51-Q60: MVC Fundamentals ✅
- Q61-Q70: Validation, Areas, Core Features ✅
- Q71-Q80: Configuration, Services, Logging ✅
- Q81-Q90: Security, Auth, Caching ✅

**Next: Section 3 - Azure Cloud Services (Q91-Q136)**

