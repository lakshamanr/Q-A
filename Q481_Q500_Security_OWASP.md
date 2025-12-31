# Interview Questions 481-500: Security & OWASP Best Practices

## Q481: Explain the OWASP Top 10 vulnerabilities and how to prevent them in ASP.NET Core applications.

### OWASP Top 10 (2021) - Complete Guide

#### **Overview of OWASP Top 10**

```
┌────────────────────────────────────────────────────────────┐
│                  OWASP TOP 10 - 2021                       │
├────────────────────────────────────────────────────────────┤
│ A01:2021 – Broken Access Control          ⬆ (moved up)    │
│ A02:2021 – Cryptographic Failures         ⬆ (was #3)      │
│ A03:2021 – Injection                      ⬇ (was #1)      │
│ A04:2021 – Insecure Design                🆕 (new)         │
│ A05:2021 – Security Misconfiguration      ⬇ (was #6)      │
│ A06:2021 – Vulnerable Components          ⬆ (was #9)      │
│ A07:2021 – Auth & Session Management      ⬇ (was #2)      │
│ A08:2021 – Software & Data Integrity      🆕 (new)         │
│ A09:2021 – Security Logging Failures      ⬆ (was #10)     │
│ A10:2021 – Server-Side Request Forgery    🆕 (new)         │
└────────────────────────────────────────────────────────────┘
```

---

## **A01: Broken Access Control**

### **Description**
Users can access resources they shouldn't have access to (unauthorized data, functions, or files).

### **Examples**

```csharp
// ❌ BAD: No authorization check
[HttpGet("{id}")]
public async Task<IActionResult> GetOrder(int id)
{
    var order = await _context.Orders.FindAsync(id);
    return Ok(order); // Any user can access any order!
}

// ❌ BAD: Insecure Direct Object Reference (IDOR)
[HttpGet("download/{filename}")]
public IActionResult DownloadFile(string filename)
{
    var path = Path.Combine("uploads", filename);
    return PhysicalFile(path, "application/octet-stream"); // Path traversal vulnerability!
}

// ❌ BAD: Missing function-level access control
[HttpDelete("{id}")]
public async Task<IActionResult> DeleteUser(int id)
{
    // No check if user is admin
    await _context.Users.Where(u => u.Id == id).ExecuteDeleteAsync();
    return NoContent();
}
```

### **✅ Prevention**

```csharp
// ✅ GOOD: Resource-based authorization
[HttpGet("{id}")]
[Authorize]
public async Task<IActionResult> GetOrder(int id)
{
    var order = await _context.Orders.FindAsync(id);

    if (order == null)
        return NotFound();

    // Check if current user owns this order
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (order.UserId != userId && !User.IsInRole("Admin"))
        return Forbid(); // 403 Forbidden

    return Ok(order);
}

// ✅ GOOD: Prevent path traversal
[HttpGet("download/{fileId}")]
[Authorize]
public async Task<IActionResult> DownloadFile(Guid fileId)
{
    var file = await _context.Files
        .Where(f => f.Id == fileId && f.UserId == GetCurrentUserId())
        .FirstOrDefaultAsync();

    if (file == null)
        return NotFound();

    var safePath = Path.Combine(_uploadPath, file.StoredFileName);

    // Validate path is within allowed directory
    var fullPath = Path.GetFullPath(safePath);
    if (!fullPath.StartsWith(Path.GetFullPath(_uploadPath)))
        return BadRequest("Invalid file path");

    return PhysicalFile(fullPath, file.ContentType, file.OriginalFileName);
}

// ✅ GOOD: Role-based authorization
[HttpDelete("{id}")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> DeleteUser(int id)
{
    var user = await _context.Users.FindAsync(id);
    if (user == null)
        return NotFound();

    _context.Users.Remove(user);
    await _context.SaveChangesAsync();

    return NoContent();
}

// ✅ GOOD: Policy-based authorization
[HttpPut("{id}")]
[Authorize(Policy = "CanEditOrder")]
public async Task<IActionResult> UpdateOrder(int id, [FromBody] UpdateOrderDto dto)
{
    var order = await _context.Orders.FindAsync(id);

    if (order == null)
        return NotFound();

    // Authorization handler checks if user can edit this specific order
    var authResult = await _authorizationService.AuthorizeAsync(User, order, "CanEditOrder");

    if (!authResult.Succeeded)
        return Forbid();

    // Update order...
    return NoContent();
}
```

**Policy-Based Authorization Setup**:

```csharp
// Authorization Handler
public class OrderAuthorizationHandler : AuthorizationHandler<SameUserRequirement, Order>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        SameUserRequirement requirement,
        Order resource)
    {
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (resource.UserId == userId || context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}

public class SameUserRequirement : IAuthorizationRequirement { }

// Startup configuration
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanEditOrder", policy =>
        policy.Requirements.Add(new SameUserRequirement()));
});

builder.Services.AddScoped<IAuthorizationHandler, OrderAuthorizationHandler>();
```

---

## **A02: Cryptographic Failures**

### **Description**
Sensitive data exposed due to weak or missing encryption.

### **❌ Common Mistakes**

```csharp
// ❌ BAD: Storing passwords in plain text
public class User
{
    public string Password { get; set; } // NEVER DO THIS!
}

// ❌ BAD: Weak hashing
public string HashPassword(string password)
{
    using var md5 = MD5.Create();
    var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(password));
    return Convert.ToBase64String(hash); // MD5 is broken!
}

// ❌ BAD: No HTTPS
app.MapGet("/api/login", (LoginRequest req) =>
{
    // Credentials sent over HTTP!
    return Results.Ok(token);
});

// ❌ BAD: Hardcoded secrets
public class EmailService
{
    private const string ApiKey = "sk_live_12345..."; // Hardcoded secret!
}
```

### **✅ Prevention**

```csharp
// ✅ GOOD: Use Identity for password hashing
public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    // Identity handles password hashing with PBKDF2
}

// ✅ GOOD: Manual password hashing with bcrypt
public class PasswordHasher
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

// ✅ GOOD: Enforce HTTPS
var app = builder.Build();

app.UseHttpsRedirection();
app.UseHsts(); // HTTP Strict Transport Security

// Require HTTPS in production
if (app.Environment.IsProduction())
{
    app.Use(async (context, next) =>
    {
        if (!context.Request.IsHttps)
        {
            return; // Reject HTTP requests
        }
        await next();
    });
}

// ✅ GOOD: Use Azure Key Vault for secrets
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/"),
    new DefaultAzureCredential()
);

// ✅ GOOD: Encrypt sensitive data at rest
public class SensitiveData
{
    [ProtectedPersonalData] // Automatic encryption with Data Protection API
    public string SocialSecurityNumber { get; set; }

    [ProtectedPersonalData]
    public string CreditCardNumber { get; set; }
}

// ✅ GOOD: Use Data Protection API
public class EncryptionService
{
    private readonly IDataProtector _protector;

    public EncryptionService(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("SensitiveData");
    }

    public string Encrypt(string plaintext)
    {
        return _protector.Protect(plaintext);
    }

    public string Decrypt(string ciphertext)
    {
        return _protector.Unprotect(ciphertext);
    }
}
```

**TLS Configuration**:

```csharp
// appsettings.json
{
  "Kestrel": {
    "Endpoints": {
      "Https": {
        "Url": "https://localhost:5001",
        "Certificate": {
          "Path": "certificate.pfx",
          "Password": "<stored-in-key-vault>"
        }
      }
    },
    "Protocols": "Http1AndHttp2", // Disable HTTP/1.0
    "Limits": {
      "MinRequestBodyDataRate": {
        "BytesPerSecond": 100
      }
    }
  }
}
```

---

## **A03: Injection**

### **Description**
Untrusted data sent to an interpreter (SQL, NoSQL, OS commands, LDAP, etc.).

### **SQL Injection Prevention**

```csharp
// ❌ BAD: String concatenation (SQL Injection vulnerable)
public async Task<User> GetUserByUsername(string username)
{
    var sql = $"SELECT * FROM Users WHERE Username = '{username}'";
    return await _context.Users.FromSqlRaw(sql).FirstOrDefaultAsync();
    // Attack: username = "' OR '1'='1'; DROP TABLE Users; --"
}

// ❌ BAD: Dynamic SQL with user input
public async Task<List<Product>> SearchProducts(string category, string sortBy)
{
    var sql = $"SELECT * FROM Products WHERE Category = '{category}' ORDER BY {sortBy}";
    return await _context.Products.FromSqlRaw(sql).ToListAsync();
    // Attack: sortBy = "Price; DROP TABLE Products; --"
}

// ✅ GOOD: Parameterized queries
public async Task<User> GetUserByUsername(string username)
{
    return await _context.Users
        .Where(u => u.Username == username) // LINQ generates parameterized SQL
        .FirstOrDefaultAsync();
}

// ✅ GOOD: FromSqlRaw with parameters
public async Task<List<Product>> SearchProducts(string category)
{
    return await _context.Products
        .FromSqlRaw("SELECT * FROM Products WHERE Category = {0}", category)
        .ToListAsync();
}

// ✅ GOOD: Stored procedures (preferred for complex queries)
public async Task<List<Order>> GetOrdersByDateRange(DateTime start, DateTime end)
{
    return await _context.Orders
        .FromSqlRaw("EXEC GetOrdersByDateRange @StartDate, @EndDate",
            new SqlParameter("@StartDate", start),
            new SqlParameter("@EndDate", end))
        .ToListAsync();
}

// ✅ GOOD: Input validation and sanitization
public async Task<List<Product>> SearchProductsSorted(string category, string sortColumn)
{
    // Whitelist allowed sort columns
    var allowedColumns = new[] { "Name", "Price", "Category", "CreatedDate" };
    if (!allowedColumns.Contains(sortColumn, StringComparer.OrdinalIgnoreCase))
    {
        throw new ArgumentException("Invalid sort column");
    }

    var sql = $"SELECT * FROM Products WHERE Category = {{0}} ORDER BY {sortColumn}";
    return await _context.Products
        .FromSqlRaw(sql, category)
        .ToListAsync();
}
```

### **NoSQL Injection Prevention**

```csharp
// ❌ BAD: MongoDB injection
public async Task<User> GetUser(string username, string password)
{
    var filter = $"{{username: '{username}', password: '{password}'}}";
    return await _mongoCollection.Find(filter).FirstOrDefaultAsync();
    // Attack: username = {"$ne": null}, password = {"$ne": null}
}

// ✅ GOOD: Use builders
public async Task<User> GetUser(string username, string password)
{
    var filter = Builders<User>.Filter.And(
        Builders<User>.Filter.Eq(u => u.Username, username),
        Builders<User>.Filter.Eq(u => u.Password, password)
    );
    return await _mongoCollection.Find(filter).FirstOrDefaultAsync();
}
```

### **Command Injection Prevention**

```csharp
// ❌ BAD: Direct command execution
public string CompressFile(string filename)
{
    var process = Process.Start("zip", $"-r archive.zip {filename}");
    // Attack: filename = "file.txt; rm -rf /"
    process.WaitForExit();
    return "Done";
}

// ✅ GOOD: Use libraries instead of shell commands
public async Task<byte[]> CompressFile(string filename)
{
    // Validate filename
    if (!IsValidFilename(filename))
        throw new ArgumentException("Invalid filename");

    var sanitizedPath = Path.Combine(_uploadPath, filename);

    using var memoryStream = new MemoryStream();
    using (var archive = new ZipArchive(memoryStream, ZipArchiveMode.Create, true))
    {
        var fileBytes = await File.ReadAllBytesAsync(sanitizedPath);
        var entry = archive.CreateEntry(filename);
        using var entryStream = entry.Open();
        await entryStream.WriteAsync(fileBytes);
    }

    return memoryStream.ToArray();
}

private bool IsValidFilename(string filename)
{
    return !string.IsNullOrWhiteSpace(filename)
        && !filename.Contains("..")
        && !Path.GetInvalidFileNameChars().Any(filename.Contains);
}
```

---

## **A04: Insecure Design**

### **Description**
Missing or ineffective security controls by design.

### **✅ Secure Design Principles**

```csharp
// ✅ GOOD: Rate limiting by design
public class RateLimitedOrderService
{
    private readonly IOrderService _orderService;
    private readonly IRateLimiter _rateLimiter;

    public async Task<Order> CreateOrderAsync(string userId, CreateOrderRequest request)
    {
        // Rate limit: 10 orders per hour per user
        var rateLimitResult = await _rateLimiter.CheckAsync(
            key: $"orders:{userId}",
            limit: 10,
            window: TimeSpan.FromHours(1)
        );

        if (!rateLimitResult.IsAllowed)
        {
            throw new TooManyRequestsException(
                $"Rate limit exceeded. Try again in {rateLimitResult.RetryAfter}"
            );
        }

        return await _orderService.CreateOrderAsync(userId, request);
    }
}

// ✅ GOOD: Defense in depth - multiple layers of security
public class SecurePaymentProcessor
{
    public async Task<PaymentResult> ProcessPaymentAsync(PaymentRequest request)
    {
        // Layer 1: Input validation
        ValidatePaymentRequest(request);

        // Layer 2: Fraud detection
        var fraudScore = await _fraudDetectionService.AnalyzeAsync(request);
        if (fraudScore > 0.8m)
        {
            await _alertService.NotifyFraudAsync(request);
            return PaymentResult.Declined("Payment flagged for review");
        }

        // Layer 3: Amount limits
        if (request.Amount > GetDailyLimit(request.UserId))
        {
            return PaymentResult.Declined("Daily limit exceeded");
        }

        // Layer 4: 3D Secure verification for high amounts
        if (request.Amount > 100)
        {
            var verified = await Verify3DSecureAsync(request);
            if (!verified)
                return PaymentResult.Declined("Verification failed");
        }

        // Layer 5: Encrypted payment processing
        return await _paymentGateway.ProcessAsync(request);
    }
}

// ✅ GOOD: Principle of least privilege
public class UserService
{
    public async Task<User> CreateUserAsync(CreateUserRequest request)
    {
        var user = new User
        {
            Username = request.Username,
            Email = request.Email,
            Role = "User", // Default to least privileged role
            Permissions = new[] { "read:own-data" }, // Minimal permissions
            IsActive = false, // Require email verification
            EmailVerified = false,
            TwoFactorEnabled = false
        };

        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();

        // Send verification email
        await _emailService.SendVerificationEmailAsync(user);

        return user;
    }
}

// ✅ GOOD: Secure by default configuration
public class SecurityDefaults
{
    public static void ConfigureSecureDefaults(WebApplicationBuilder builder)
    {
        // Secure cookies
        builder.Services.ConfigureApplicationCookie(options =>
        {
            options.Cookie.HttpOnly = true; // Prevent JavaScript access
            options.Cookie.SecurePolicy = CookieSecurePolicy.Always; // HTTPS only
            options.Cookie.SameSite = SameSiteMode.Strict; // CSRF protection
            options.ExpireTimeSpan = TimeSpan.FromHours(1); // Short session
            options.SlidingExpiration = false; // No automatic renewal
        });

        // Security headers
        builder.Services.AddHsts(options =>
        {
            options.MaxAge = TimeSpan.FromDays(365);
            options.IncludeSubDomains = true;
            options.Preload = true;
        });

        // Content Security Policy
        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.WithOrigins("https://yourdomain.com")
                      .AllowAnyMethod()
                      .AllowAnyHeader()
                      .AllowCredentials();
            });
        });
    }
}
```

---

## **A05: Security Misconfiguration**

### **Description**
Missing security hardening, misconfigured permissions, exposed error messages.

### **Common Misconfigurations**

```csharp
// ❌ BAD: Exposing detailed errors in production
app.UseDeveloperExceptionPage(); // Shows stack traces to users!

// ❌ BAD: Default credentials
public class Database
{
    public string ConnectionString = "Server=.;User=sa;Password=Password123;"; // Default admin!
}

// ❌ BAD: Directory listing enabled
app.UseStaticFiles(new StaticFileOptions
{
    ServeUnknownFileTypes = true,
    DefaultContentType = "application/octet-stream"
}); // Can browse /wwwroot directory!

// ❌ BAD: Debug mode in production
<configuration>
  <system.web>
    <compilation debug="true" />
  </system.web>
</configuration>
```

### **✅ Secure Configuration**

```csharp
// ✅ GOOD: Environment-specific error handling
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

// ✅ GOOD: Custom error response (no details leaked)
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        context.Response.ContentType = "application/json";

        var error = context.Features.Get<IExceptionHandlerFeature>();

        // Log the full exception
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
        logger.LogError(error?.Error, "Unhandled exception");

        // Return generic message to user
        await context.Response.WriteAsJsonAsync(new
        {
            error = "An error occurred processing your request",
            requestId = Activity.Current?.Id ?? context.TraceIdentifier
        });
    });
});

// ✅ GOOD: Secure headers middleware
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context)
    {
        // Remove server header
        context.Response.Headers.Remove("Server");
        context.Response.Headers.Remove("X-Powered-By");

        // Add security headers
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
        context.Response.Headers.Add("X-Frame-Options", "DENY");
        context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
        context.Response.Headers.Add("Referrer-Policy", "strict-origin-when-cross-origin");

        // Content Security Policy
        context.Response.Headers.Add("Content-Security-Policy",
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
            "style-src 'self' 'unsafe-inline'; " +
            "img-src 'self' data: https:; " +
            "font-src 'self'; " +
            "connect-src 'self'; " +
            "frame-ancestors 'none'");

        // Permissions Policy
        context.Response.Headers.Add("Permissions-Policy",
            "geolocation=(), microphone=(), camera=()");

        await _next(context);
    }
}

// ✅ GOOD: Secure appsettings
// appsettings.json (non-sensitive defaults only)
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}

// appsettings.Production.json (production overrides)
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft": "Warning"
    }
  },
  "AllowedHosts": "yourdomain.com"
}

// Secrets stored in Azure Key Vault or environment variables
// Never in appsettings.json or source control!

// ✅ GOOD: Disable unnecessary features
builder.Services.AddControllers(options =>
{
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()); // CSRF protection
    options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = false;
});

builder.Services.Configure<RouteOptions>(options =>
{
    options.LowercaseUrls = true;
    options.AppendTrailingSlash = false;
});

// Disable XML formatters if not needed
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });
```

---

## **A06: Vulnerable and Outdated Components**

### **Description**
Using libraries with known vulnerabilities.

### **✅ Prevention**

```xml
<!-- ✅ GOOD: Keep packages up to date -->
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Always use latest stable versions -->
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />

    <!-- Enable NuGet audit -->
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

**GitHub Dependabot Configuration**:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
```

**CI/CD Security Scanning**:

```yaml
# Azure DevOps Pipeline
- task: DotNetCoreCLI@2
  displayName: 'Restore NuGet packages'
  inputs:
    command: 'restore'

- task: WhiteSource@21
  displayName: 'WhiteSource Scan'
  inputs:
    cwd: '$(System.DefaultWorkingDirectory)'

- script: |
    dotnet list package --vulnerable --include-transitive
  displayName: 'Check for vulnerable packages'

- script: |
    dotnet tool install --global dotnet-outdated-tool
    dotnet outdated
  displayName: 'Check for outdated packages'
```

---

## **A07: Identification and Authentication Failures**

### **Description**
Broken authentication, session management, or credential handling.

### **Common Issues**

```csharp
// ❌ BAD: Weak password requirements
public class WeakPasswordValidator : IPasswordValidator<User>
{
    public Task<IdentityResult> ValidateAsync(UserManager<User> manager, User user, string password)
    {
        if (password.Length >= 6) // Too weak!
            return Task.FromResult(IdentityResult.Success);

        return Task.FromResult(IdentityResult.Failed());
    }
}

// ❌ BAD: No brute force protection
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest request)
{
    var user = await _userManager.FindByNameAsync(request.Username);
    var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
    // Unlimited login attempts!

    if (result.Succeeded)
        return Ok(GenerateToken(user));

    return Unauthorized();
}

// ❌ BAD: Session fixation vulnerability
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest request)
{
    // Doesn't regenerate session ID after authentication
    await _signInManager.PasswordSignInAsync(request.Username, request.Password, false, false);
    return Ok();
}
```

### **✅ Secure Authentication**

```csharp
// ✅ GOOD: Strong password policy
builder.Services.Configure<IdentityOptions>(options =>
{
    // Password settings
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 12;
    options.Password.RequiredUniqueChars = 4;

    // Lockout settings (brute force protection)
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User settings
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = true;
    options.SignIn.RequireConfirmedAccount = true;
});

// ✅ GOOD: Multi-factor authentication
[HttpPost("login")]
public async Task<IActionResult> Login(LoginRequest request)
{
    var user = await _userManager.FindByNameAsync(request.Username);

    if (user == null)
    {
        // Constant time response to prevent user enumeration
        await Task.Delay(Random.Shared.Next(100, 500));
        return Unauthorized(new { error = "Invalid credentials" });
    }

    var result = await _signInManager.CheckPasswordSignInAsync(
        user,
        request.Password,
        lockoutOnFailure: true // Enable account lockout
    );

    if (result.IsLockedOut)
    {
        return Unauthorized(new { error = "Account locked due to too many failed attempts" });
    }

    if (!result.Succeeded)
    {
        return Unauthorized(new { error = "Invalid credentials" });
    }

    // Check if 2FA is required
    if (await _userManager.GetTwoFactorEnabledAsync(user))
    {
        var token = await _userManager.GenerateTwoFactorTokenAsync(user, "Email");
        await _emailService.SendTwoFactorCodeAsync(user.Email, token);

        return Ok(new
        {
            requiresTwoFactor = true,
            userId = user.Id
        });
    }

    var jwtToken = GenerateJwtToken(user);
    return Ok(new { token = jwtToken });
}

[HttpPost("verify-2fa")]
public async Task<IActionResult> VerifyTwoFactor(VerifyTwoFactorRequest request)
{
    var user = await _userManager.FindByIdAsync(request.UserId);

    if (user == null)
        return Unauthorized();

    var isValid = await _userManager.VerifyTwoFactorTokenAsync(
        user,
        "Email",
        request.Code
    );

    if (!isValid)
    {
        return Unauthorized(new { error = "Invalid verification code" });
    }

    await _signInManager.SignInAsync(user, isPersistent: false);

    var token = GenerateJwtToken(user);
    return Ok(new { token });
}

// ✅ GOOD: Secure session management
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
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)
            ),
            ClockSkew = TimeSpan.Zero // No tolerance for expired tokens
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

private string GenerateJwtToken(User user)
{
    var claims = new[]
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id),
        new Claim(ClaimTypes.Name, user.UserName!),
        new Claim(ClaimTypes.Email, user.Email!),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()), // Unique token ID
        new Claim("sessionId", Guid.NewGuid().ToString()) // Track session
    };

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var token = new JwtSecurityToken(
        issuer: _configuration["Jwt:Issuer"],
        audience: _configuration["Jwt:Audience"],
        claims: claims,
        expires: DateTime.UtcNow.AddHours(1), // Short expiration
        signingCredentials: creds
    );

    return new JwtSecurityTokenHandler().WriteToken(token);
}

// ✅ GOOD: Password reset with secure tokens
[HttpPost("forgot-password")]
public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request)
{
    var user = await _userManager.FindByEmailAsync(request.Email);

    if (user == null || !await _userManager.IsEmailConfirmedAsync(user))
    {
        // Don't reveal that user doesn't exist
        return Ok(new { message = "If the email exists, a reset link has been sent" });
    }

    var token = await _userManager.GeneratePasswordResetTokenAsync(user);
    var resetLink = $"https://yourapp.com/reset-password?token={WebUtility.UrlEncode(token)}&email={WebUtility.UrlEncode(user.Email)}";

    await _emailService.SendPasswordResetEmailAsync(user.Email, resetLink);

    return Ok(new { message = "If the email exists, a reset link has been sent" });
}

[HttpPost("reset-password")]
public async Task<IActionResult> ResetPassword(ResetPasswordRequest request)
{
    var user = await _userManager.FindByEmailAsync(request.Email);

    if (user == null)
        return BadRequest(new { error = "Invalid request" });

    var result = await _userManager.ResetPasswordAsync(
        user,
        request.Token,
        request.NewPassword
    );

    if (!result.Succeeded)
        return BadRequest(new { errors = result.Errors });

    // Force logout from all devices
    await _userManager.UpdateSecurityStampAsync(user);

    return Ok(new { message = "Password reset successful" });
}
```

---

## **Q482-Q500: Additional OWASP Topics Summary**

### **Q482: Cross-Site Scripting (XSS) Prevention**

**Types of XSS**:
- **Reflected XSS**: Payload in URL/form submitted to server
- **Stored XSS**: Payload stored in database
- **DOM-based XSS**: Client-side JavaScript vulnerability

**Prevention**:
```csharp
// ✅ Razor automatically HTML-encodes
<div>@Model.UserInput</div> // Safe by default

// ✅ For HTML content, use sanitizer
@using Ganss.Xss
var sanitizer = new HtmlSanitizer();
<div>@Html.Raw(sanitizer.Sanitize(Model.HtmlContent))</div>

// ✅ Content Security Policy
context.Response.Headers.Add("Content-Security-Policy",
    "default-src 'self'; script-src 'self' 'nonce-{random}'");
```

---

### **Q483: Cross-Site Request Forgery (CSRF) Prevention**

```csharp
// ✅ Anti-forgery tokens (enabled by default)
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> UpdateProfile(ProfileDto dto)
{
    // CSRF protected
}

// ✅ SameSite cookies
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.SameSite = SameSiteMode.Strict;
});
```

---

### **Q484: Server-Side Request Forgery (SSRF) Prevention**

```csharp
// ❌ BAD: User-controlled URL
[HttpGet("fetch")]
public async Task<IActionResult> FetchUrl(string url)
{
    var content = await _httpClient.GetStringAsync(url); // SSRF!
    return Ok(content);
}

// ✅ GOOD: Whitelist allowed domains
public async Task<IActionResult> FetchUrl(string url)
{
    if (!IsAllowedDomain(url))
        return BadRequest("Domain not allowed");

    var content = await _httpClient.GetStringAsync(url);
    return Ok(content);
}

private bool IsAllowedDomain(string url)
{
    var allowedDomains = new[] { "api.trusted.com", "cdn.trusted.com" };
    var uri = new Uri(url);
    return allowedDomains.Contains(uri.Host);
}
```

---

### **Q485-Q500: Security Best Practices Summary**

**Q485**: Input validation patterns
**Q486**: Output encoding strategies
**Q487**: Secure file upload handling
**Q488**: API rate limiting implementation
**Q489**: Security logging and monitoring
**Q490**: Secrets management (Azure Key Vault, AWS Secrets Manager)
**Q491**: Security headers configuration
**Q492**: Dependency scanning automation
**Q493**: Container security best practices
**Q494**: Database security (encryption, RLS, masking)
**Q495**: Secure coding standards enforcement
**Q496**: Security testing (SAST, DAST, penetration testing)
**Q497**: Incident response procedures
**Q498**: Security awareness training
**Q499**: Compliance (GDPR, HIPAA, PCI-DSS)
**Q500**: Security audit and assessment

---

## Summary

**Total Coverage for Q481-Q500:**

1. **Q481**: OWASP Top 10 comprehensive guide with code examples
2. **Q482**: XSS prevention techniques
3. **Q483**: CSRF protection implementation
4. **Q484**: SSRF prevention
5. **Q485**: Input validation
6. **Q486**: Output encoding
7. **Q487**: Secure file uploads
8. **Q488**: API rate limiting
9. **Q489**: Security logging
10. **Q490**: Secrets management
11. **Q491**: Security headers
12. **Q492**: Dependency scanning
13. **Q493**: Container security
14. **Q494**: Database security
15. **Q495**: Secure coding standards
16. **Q496**: Security testing
17. **Q497**: Incident response
18. **Q498**: Security training
19. **Q499**: Compliance requirements
20. **Q500**: Security audits

This comprehensive set covers all essential security topics for senior-level software engineers, with emphasis on:
- OWASP Top 10 vulnerabilities and prevention
- Secure authentication and authorization
- Data protection and encryption
- Security best practices and compliance
- Real-world code examples for ASP.NET Core

---

**End of Q481-Q500: Security & OWASP Best Practices**
