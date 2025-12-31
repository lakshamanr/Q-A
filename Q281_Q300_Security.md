# Interview Questions Q281-Q300: Security in ASP.NET Core

---

## **Q281: What is Authentication vs Authorization in ASP.NET Core?**

**Answer:**

Authentication and authorization are two distinct but related security concepts that work together to secure applications.

**Authentication** = "Who are you?" (Identity)
**Authorization** = "What can you do?" (Permissions)

**Authentication Implementation:**
```csharp
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;

// ============================================
// Configure Authentication in Program.cs
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add authentication services
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(1);
        options.SlidingExpiration = true;
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Strict;
    });

// Add authorization services
builder.Services.AddAuthorization(options =>
{
    // Policy-based authorization
    options.AddPolicy("RequireAdministratorRole", policy =>
        policy.RequireRole("Administrator"));

    options.AddPolicy("RequireManagerOrAdmin", policy =>
        policy.RequireRole("Manager", "Administrator"));

    options.AddPolicy("AtLeast21", policy =>
        policy.RequireClaim("Age", "21", "22", "23" /* ... */));

    options.AddPolicy("EmployeeOnly", policy =>
        policy.RequireClaim("EmployeeNumber"));
});

var app = builder.Build();

// Enable authentication middleware (ORDER MATTERS!)
app.UseAuthentication();  // First: Who are you?
app.UseAuthorization();   // Then: What can you do?

app.MapControllers();
app.Run();

// ============================================
// Authentication Controller
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<AccountController> _logger;

    public AccountController(IUserService userService, ILogger<AccountController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        // Validate credentials
        var user = await _userService.ValidateCredentialsAsync(
            request.Username,
            request.Password);

        if (user == null)
        {
            _logger.LogWarning("Failed login attempt for user: {Username}", request.Username);
            return Unauthorized(new { message = "Invalid username or password" });
        }

        // Create claims - information about the user
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.GivenName, user.FirstName),
            new Claim(ClaimTypes.Surname, user.LastName),
            new Claim("EmployeeNumber", user.EmployeeNumber),
            new Claim("Age", user.Age.ToString())
        };

        // Add roles
        foreach (var role in user.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        // Create claims identity
        var claimsIdentity = new ClaimsIdentity(
            claims,
            CookieAuthenticationDefaults.AuthenticationScheme);

        // Create authentication properties
        var authProperties = new AuthenticationProperties
        {
            AllowRefresh = true,
            ExpiresUtc = DateTimeOffset.UtcNow.AddHours(1),
            IsPersistent = request.RememberMe,
            IssuedUtc = DateTimeOffset.UtcNow
        };

        // Sign in the user
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(claimsIdentity),
            authProperties);

        _logger.LogInformation("User {Username} logged in successfully", user.Username);

        return Ok(new
        {
            message = "Login successful",
            user = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.Roles
            }
        });
    }

    [HttpPost("logout")]
    [Authorize] // Must be authenticated to logout
    public async Task<IActionResult> Logout()
    {
        var username = User.Identity?.Name;

        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

        _logger.LogInformation("User {Username} logged out", username);

        return Ok(new { message = "Logout successful" });
    }

    [HttpGet("profile")]
    [Authorize] // Authentication required
    public IActionResult GetProfile()
    {
        // Access user claims
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var username = User.Identity?.Name;
        var email = User.FindFirstValue(ClaimTypes.Email);
        var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value);

        return Ok(new
        {
            UserId = userId,
            Username = username,
            Email = email,
            Roles = roles,
            IsAuthenticated = User.Identity?.IsAuthenticated ?? false
        });
    }
}

// ============================================
// Authorization - Attribute-Based
// ============================================

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    // Anyone can access (no authentication required)
    [HttpGet]
    [AllowAnonymous]
    public IActionResult GetAll()
    {
        return Ok(new[] { "Product 1", "Product 2" });
    }

    // Must be authenticated
    [HttpGet("{id}")]
    [Authorize]
    public IActionResult Get(int id)
    {
        return Ok(new { Id = id, Name = "Product" });
    }

    // Must have Administrator role
    [HttpPost]
    [Authorize(Roles = "Administrator")]
    public IActionResult Create([FromBody] Product product)
    {
        return CreatedAtAction(nameof(Get), new { id = 1 }, product);
    }

    // Must have Manager OR Administrator role
    [HttpPut("{id}")]
    [Authorize(Roles = "Manager,Administrator")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        return Ok(product);
    }

    // Policy-based authorization
    [HttpDelete("{id}")]
    [Authorize(Policy = "RequireAdministratorRole")]
    public IActionResult Delete(int id)
    {
        return NoContent();
    }
}

// ============================================
// Authorization - Policy-Based
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    [HttpGet("users")]
    [Authorize(Policy = "RequireAdministratorRole")]
    public IActionResult GetUsers()
    {
        return Ok(new[] { "User1", "User2" });
    }

    [HttpGet("sensitive-data")]
    [Authorize(Policy = "EmployeeOnly")]
    public IActionResult GetSensitiveData()
    {
        var employeeNumber = User.FindFirstValue("EmployeeNumber");
        return Ok(new { Message = $"Data for employee {employeeNumber}" });
    }
}

// ============================================
// Custom Authorization Requirement
// ============================================

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
        var ageClaim = context.User.FindFirst(c => c.Type == "Age");

        if (ageClaim == null)
        {
            return Task.CompletedTask;
        }

        if (int.TryParse(ageClaim.Value, out var age))
        {
            if (age >= requirement.MinimumAge)
            {
                context.Succeed(requirement);
            }
        }

        return Task.CompletedTask;
    }
}

// Register custom handler
builder.Services.AddSingleton<IAuthorizationHandler, MinimumAgeHandler>();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AtLeast18", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));

    options.AddPolicy("AtLeast21", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(21)));
});

// ============================================
// Resource-Based Authorization
// ============================================

public class DocumentAuthorizationHandler
    : AuthorizationHandler<OperationAuthorizationRequirement, Document>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        OperationAuthorizationRequirement requirement,
        Document resource)
    {
        // Owner can do everything
        if (resource.OwnerId == context.User.FindFirstValue(ClaimTypes.NameIdentifier))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        // Admins can do everything
        if (context.User.IsInRole("Administrator"))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        // Managers can read
        if (requirement.Name == "Read" && context.User.IsInRole("Manager"))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}

[ApiController]
[Route("api/[controller]")]
public class DocumentsController : ControllerBase
{
    private readonly IAuthorizationService _authorizationService;
    private readonly IDocumentRepository _documentRepository;

    public DocumentsController(
        IAuthorizationService authorizationService,
        IDocumentRepository documentRepository)
    {
        _authorizationService = authorizationService;
        _documentRepository = documentRepository;
    }

    [HttpGet("{id}")]
    [Authorize]
    public async Task<IActionResult> GetDocument(int id)
    {
        var document = await _documentRepository.GetByIdAsync(id);

        if (document == null)
            return NotFound();

        // Check if user can read this specific document
        var authResult = await _authorizationService.AuthorizeAsync(
            User,
            document,
            "Read");

        if (!authResult.Succeeded)
        {
            return Forbid();
        }

        return Ok(document);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> UpdateDocument(int id, [FromBody] Document updatedDocument)
    {
        var document = await _documentRepository.GetByIdAsync(id);

        if (document == null)
            return NotFound();

        // Check if user can edit this specific document
        var authResult = await _authorizationService.AuthorizeAsync(
            User,
            document,
            "Edit");

        if (!authResult.Succeeded)
        {
            return Forbid(); // 403 Forbidden
        }

        await _documentRepository.UpdateAsync(updatedDocument);
        return Ok(updatedDocument);
    }
}

// ============================================
// Multiple Authentication Schemes
// ============================================

builder.Services.AddAuthentication()
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.LoginPath = "/Account/Login";
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
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

// Controller can accept either scheme
[ApiController]
[Route("api/[controller]")]
[Authorize(AuthenticationSchemes = $"{CookieAuthenticationDefaults.AuthenticationScheme},{JwtBearerDefaults.AuthenticationScheme}")]
public class HybridController : ControllerBase
{
    [HttpGet("data")]
    public IActionResult GetData()
    {
        return Ok(new { message = "Authenticated via Cookie or JWT" });
    }
}

// ============================================
// Key Differences Summary
// ============================================

/*
AUTHENTICATION:
- Verifies identity
- "Are you who you say you are?"
- Handled by authentication middleware
- Results in ClaimsPrincipal
- Examples: Cookies, JWT, OAuth, Windows Auth

AUTHORIZATION:
- Verifies permissions
- "Are you allowed to do this?"
- Handled by authorization middleware
- Checks claims, roles, policies
- Examples: [Authorize], policies, resource-based

ORDER MATTERS:
1. app.UseAuthentication() - First
2. app.UseAuthorization()  - Second

COMMON STATUS CODES:
- 401 Unauthorized = Not authenticated (should login)
- 403 Forbidden = Authenticated but not authorized (permission denied)
*/
```

---

## **Q282: How do you implement JWT (JSON Web Token) Authentication in ASP.NET Core?**

**Answer:**

JWT is a compact, URL-safe token format used for securely transmitting information between parties. Commonly used for stateless authentication in APIs.

**JWT Structure:**
```
Header.Payload.Signature

Example:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Implementation:**
```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

// ============================================
// appsettings.json Configuration
// ============================================

{
  "Jwt": {
    "Key": "YourSuperSecretKeyThatIsAtLeast32CharactersLong!",
    "Issuer": "YourApp",
    "Audience": "YourAppUsers",
    "ExpiryMinutes": 60
  }
}

// ============================================
// Program.cs - Configure JWT Authentication
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = true; // Should be true in production
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero, // Remove default 5 min tolerance

        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };

    // Custom event handlers
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
            {
                context.Response.Headers.Add("Token-Expired", "true");
            }
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            // Additional validation logic
            var userId = context.Principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            // Could check if user still exists, is active, etc.
            return Task.CompletedTask;
        },
        OnMessageReceived = context =>
        {
            // Support token in query string for SignalR
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;

            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
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

// ============================================
// JWT Token Service
// ============================================

public interface IJwtTokenService
{
    string GenerateToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal GetPrincipalFromExpiredToken(string token);
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
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));

        var credentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256);

        // Create claims
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(JwtRegisteredClaimNames.Iat,
                DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("FirstName", user.FirstName),
            new Claim("LastName", user.LastName)
        };

        // Add role claims
        var roleClaims = user.Roles.Select(role =>
            new Claim(ClaimTypes.Role, role));

        var allClaims = claims.Concat(roleClaims);

        // Create token
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: allClaims,
            expires: DateTime.UtcNow.AddMinutes(
                int.Parse(_configuration["Jwt:ExpiryMinutes"])),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    public ClaimsPrincipal GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidateIssuer = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"])),
            ValidateLifetime = false, // Don't validate lifetime for expired tokens
            ValidIssuer = _configuration["Jwt:Issuer"],
            ValidAudience = _configuration["Jwt:Audience"]
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

// ============================================
// Authentication Controller
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IJwtTokenService _tokenService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IUserService userService,
        IJwtTokenService tokenService,
        ILogger<AuthController> logger)
    {
        _userService = userService;
        _tokenService = tokenService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        // Validate credentials
        var user = await _userService.ValidateCredentialsAsync(
            request.Username,
            request.Password);

        if (user == null)
        {
            _logger.LogWarning(
                "Failed login attempt for user: {Username}",
                request.Username);

            return Unauthorized(new { message = "Invalid credentials" });
        }

        // Generate tokens
        var accessToken = _tokenService.GenerateToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken();

        // Store refresh token (in database)
        await _userService.SaveRefreshTokenAsync(
            user.Id,
            refreshToken,
            DateTime.UtcNow.AddDays(7));

        _logger.LogInformation(
            "User {Username} logged in successfully",
            user.Username);

        return Ok(new
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = 3600, // seconds
            TokenType = "Bearer",
            User = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.Roles
            }
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            // Get principal from expired access token
            var principal = _tokenService.GetPrincipalFromExpiredToken(request.AccessToken);
            var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);

            // Validate refresh token
            var savedRefreshToken = await _userService.GetRefreshTokenAsync(userId);

            if (savedRefreshToken != request.RefreshToken ||
                savedRefreshToken.ExpiryDate < DateTime.UtcNow)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            // Get user and generate new tokens
            var user = await _userService.GetByIdAsync(int.Parse(userId));

            var newAccessToken = _tokenService.GenerateToken(user);
            var newRefreshToken = _tokenService.GenerateRefreshToken();

            // Update refresh token in database
            await _userService.SaveRefreshTokenAsync(
                user.Id,
                newRefreshToken,
                DateTime.UtcNow.AddDays(7));

            return Ok(new
            {
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken,
                ExpiresIn = 3600,
                TokenType = "Bearer"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing token");
            return Unauthorized(new { message = "Invalid token" });
        }
    }

    [HttpPost("revoke")]
    [Authorize]
    public async Task<IActionResult> RevokeToken([FromBody] RevokeTokenRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        await _userService.RevokeRefreshTokenAsync(userId, request.RefreshToken);

        return NoContent();
    }

    [HttpGet("me")]
    [Authorize]
    public IActionResult GetCurrentUser()
    {
        // Access claims from JWT
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var username = User.FindFirstValue(ClaimTypes.Name);
        var email = User.FindFirstValue(ClaimTypes.Email);
        var firstName = User.FindFirstValue("FirstName");
        var lastName = User.FindFirstValue("LastName");
        var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value);

        return Ok(new
        {
            UserId = userId,
            Username = username,
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            Roles = roles
        });
    }
}

// ============================================
// Protected API Controller
// ============================================

[ApiController]
[Route("api/[controller]")]
[Authorize] // All endpoints require JWT authentication
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll()
    {
        // User is authenticated, can access claims
        var username = User.Identity?.Name;
        return Ok(new { message = $"Hello {username}", products = new[] { "P1", "P2" } });
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public IActionResult Create([FromBody] Product product)
    {
        // Only Admin role can access
        return CreatedAtAction(nameof(GetAll), product);
    }
}

// ============================================
// Client-Side Usage (JavaScript/TypeScript)
// ============================================

/*
// Login and store token
const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'user', password: 'pass' })
});

const data = await response.json();
localStorage.setItem('accessToken', data.accessToken);
localStorage.setItem('refreshToken', data.refreshToken);

// Use token in subsequent requests
const productsResponse = await fetch('/api/products', {
    headers: {
        'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
    }
});

// Handle token expiration and refresh
async function fetchWithAuth(url, options = {}) {
    const accessToken = localStorage.getItem('accessToken');

    let response = await fetch(url, {
        ...options,
        headers: {
            ...options.headers,
            'Authorization': `Bearer ${accessToken}`
        }
    });

    // If 401, try to refresh token
    if (response.status === 401) {
        const refreshToken = localStorage.getItem('refreshToken');
        const refreshResponse = await fetch('/api/auth/refresh', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                accessToken,
                refreshToken
            })
        });

        if (refreshResponse.ok) {
            const data = await refreshResponse.json();
            localStorage.setItem('accessToken', data.accessToken);
            localStorage.setItem('refreshToken', data.refreshToken);

            // Retry original request
            response = await fetch(url, {
                ...options,
                headers: {
                    ...options.headers,
                    'Authorization': `Bearer ${data.accessToken}`
                }
            });
        } else {
            // Refresh failed, redirect to login
            window.location.href = '/login';
        }
    }

    return response;
}
*/

// ============================================
// JWT Best Practices
// ============================================

/*
1. ✅ Use HTTPS only
   - Never send JWT over HTTP
   - Set RequireHttpsMetadata = true

2. ✅ Keep tokens short-lived
   - Access token: 15-60 minutes
   - Refresh token: 7-30 days

3. ✅ Use strong secret keys
   - Minimum 256 bits (32 characters)
   - Store in secure configuration (Azure Key Vault, etc.)

4. ✅ Validate all claims
   - Issuer, Audience, Expiration
   - Custom claims as needed

5. ✅ Implement token refresh
   - Use refresh tokens
   - Rotate refresh tokens

6. ✅ Store tokens securely on client
   - HttpOnly cookies (best for web)
   - Secure storage (mobile apps)
   - NOT in localStorage for sensitive apps

7. ❌ Don't store sensitive data in JWT
   - Payload is base64 encoded, not encrypted
   - Anyone can decode and read it

8. ✅ Implement token revocation
   - Store refresh tokens in database
   - Check blacklist for critical operations

9. ✅ Use appropriate algorithm
   - HS256 (symmetric) for simple scenarios
   - RS256 (asymmetric) for distributed systems

10. ✅ Set ClockSkew to Zero
    - Remove default 5-minute tolerance
    - Strict expiration validation
*/
```

---

## **Q283: How do you securely hash and verify passwords in ASP.NET Core?**

**Answer:**

Never store passwords in plain text. Use strong hashing algorithms with salts to protect user passwords.

**Implementation:**
```csharp
using System.Security.Cryptography;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using Microsoft.AspNetCore.Identity;

// ============================================
// Approach 1: Using ASP.NET Core Identity PasswordHasher (Recommended)
// ============================================

public class PasswordService
{
    private readonly IPasswordHasher<User> _passwordHasher;

    public PasswordService()
    {
        _passwordHasher = new PasswordHasher<User>();
    }

    public string HashPassword(User user, string password)
    {
        return _passwordHasher.HashPassword(user, password);
    }

    public bool VerifyPassword(User user, string hashedPassword, string providedPassword)
    {
        var result = _passwordHasher.VerifyHashedPassword(
            user,
            hashedPassword,
            providedPassword);

        return result == PasswordVerificationResult.Success ||
               result == PasswordVerificationResult.SuccessRehashNeeded;
    }
}

// Usage
public class UserService
{
    private readonly PasswordService _passwordService;
    private readonly IUserRepository _userRepository;

    public async Task<User> RegisterUserAsync(string username, string email, string password)
    {
        var user = new User
        {
            Username = username,
            Email = email
        };

        // Hash the password
        user.PasswordHash = _passwordService.HashPassword(user, password);

        await _userRepository.AddAsync(user);
        return user;
    }

    public async Task<User> ValidateCredentialsAsync(string username, string password)
    {
        var user = await _userRepository.GetByUsernameAsync(username);

        if (user == null)
            return null;

        // Verify the password
        var isValid = _passwordService.VerifyPassword(
            user,
            user.PasswordHash,
            password);

        return isValid ? user : null;
    }
}

// ============================================
// Approach 2: Manual PBKDF2 Implementation
// ============================================

public class ManualPasswordHasher
{
    private const int SaltSize = 128 / 8; // 128 bits
    private const int KeySize = 256 / 8; // 256 bits
    private const int Iterations = 100000; // OWASP recommendation: 100,000+
    private static readonly HashAlgorithmName Algorithm = HashAlgorithmName.SHA256;

    public string HashPassword(string password)
    {
        // Generate a random salt
        byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);

        // Hash the password
        byte[] hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            Algorithm,
            KeySize);

        // Combine salt and hash
        byte[] hashBytes = new byte[SaltSize + KeySize];
        Array.Copy(salt, 0, hashBytes, 0, SaltSize);
        Array.Copy(hash, 0, hashBytes, SaltSize, KeySize);

        // Convert to base64 for storage
        return Convert.ToBase64String(hashBytes);
    }

    public bool VerifyPassword(string password, string hashedPassword)
    {
        // Decode the stored hash
        byte[] hashBytes = Convert.FromBase64String(hashedPassword);

        // Extract the salt (first SaltSize bytes)
        byte[] salt = new byte[SaltSize];
        Array.Copy(hashBytes, 0, salt, 0, SaltSize);

        // Hash the provided password with the same salt
        byte[] hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            Algorithm,
            KeySize);

        // Extract the stored hash (remaining bytes)
        byte[] storedHash = new byte[KeySize];
        Array.Copy(hashBytes, SaltSize, storedHash, 0, KeySize);

        // Compare the hashes
        return CryptographicOperations.FixedTimeEquals(hash, storedHash);
    }
}

// ============================================
// Approach 3: Using BCrypt (via BCrypt.Net)
// ============================================

// Install: dotnet add package BCrypt.Net-Next

using BCrypt.Net;

public class BCryptPasswordHasher
{
    private const int WorkFactor = 12; // Higher = more secure but slower

    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password, WorkFactor);
    }

    public bool VerifyPassword(string password, string hashedPassword)
    {
        return BCrypt.Net.BCrypt.Verify(password, hashedPassword);
    }
}

// ============================================
// Password Strength Validation
// ============================================

public class PasswordValidator
{
    public class PasswordRequirements
    {
        public int MinLength { get; set; } = 8;
        public int MaxLength { get; set; } = 128;
        public bool RequireUppercase { get; set; } = true;
        public bool RequireLowercase { get; set; } = true;
        public bool RequireDigit { get; set; } = true;
        public bool RequireSpecialChar { get; set; } = true;
    }

    private readonly PasswordRequirements _requirements;

    public PasswordValidator(PasswordRequirements requirements = null)
    {
        _requirements = requirements ?? new PasswordRequirements();
    }

    public (bool IsValid, List<string> Errors) ValidatePassword(string password)
    {
        var errors = new List<string>();

        if (string.IsNullOrEmpty(password))
        {
            errors.Add("Password is required");
            return (false, errors);
        }

        if (password.Length < _requirements.MinLength)
        {
            errors.Add($"Password must be at least {_requirements.MinLength} characters long");
        }

        if (password.Length > _requirements.MaxLength)
        {
            errors.Add($"Password must be no more than {_requirements.MaxLength} characters long");
        }

        if (_requirements.RequireUppercase && !password.Any(char.IsUpper))
        {
            errors.Add("Password must contain at least one uppercase letter");
        }

        if (_requirements.RequireLowercase && !password.Any(char.IsLower))
        {
            errors.Add("Password must contain at least one lowercase letter");
        }

        if (_requirements.RequireDigit && !password.Any(char.IsDigit))
        {
            errors.Add("Password must contain at least one digit");
        }

        if (_requirements.RequireSpecialChar && !password.Any(ch => !char.IsLetterOrDigit(ch)))
        {
            errors.Add("Password must contain at least one special character");
        }

        // Check for common passwords
        if (IsCommonPassword(password))
        {
            errors.Add("This password is too common. Please choose a stronger password");
        }

        return (errors.Count == 0, errors);
    }

    private bool IsCommonPassword(string password)
    {
        // List of most common passwords (should be loaded from file)
        var commonPasswords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "password", "123456", "12345678", "qwerty", "abc123",
            "monkey", "1234567", "letmein", "trustno1", "dragon"
        };

        return commonPasswords.Contains(password);
    }
}

// ============================================
// Password Reset with Tokens
// ============================================

public class PasswordResetService
{
    private readonly IUserRepository _userRepository;
    private readonly IEmailService _emailService;

    public async Task<string> GeneratePasswordResetTokenAsync(string email)
    {
        var user = await _userRepository.GetByEmailAsync(email);

        if (user == null)
        {
            // Don't reveal whether email exists
            return null;
        }

        // Generate secure random token
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));

        // Store token with expiration (e.g., 1 hour)
        user.PasswordResetToken = token;
        user.PasswordResetTokenExpiry = DateTime.UtcNow.AddHours(1);

        await _userRepository.UpdateAsync(user);

        // Send email with reset link
        var resetLink = $"https://yourdomain.com/reset-password?token={token}";
        await _emailService.SendPasswordResetEmailAsync(email, resetLink);

        return token;
    }

    public async Task<bool> ResetPasswordAsync(string token, string newPassword)
    {
        var user = await _userRepository.GetByPasswordResetTokenAsync(token);

        if (user == null || user.PasswordResetTokenExpiry < DateTime.UtcNow)
        {
            return false; // Invalid or expired token
        }

        // Validate new password
        var validator = new PasswordValidator();
        var (isValid, errors) = validator.ValidatePassword(newPassword);

        if (!isValid)
        {
            throw new ValidationException(string.Join(", ", errors));
        }

        // Hash and update password
        var passwordService = new PasswordService();
        user.PasswordHash = passwordService.HashPassword(user, newPassword);

        // Clear reset token
        user.PasswordResetToken = null;
        user.PasswordResetTokenExpiry = null;

        await _userRepository.UpdateAsync(user);

        return true;
    }
}

// ============================================
// Complete Registration Example
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly PasswordValidator _passwordValidator;
    private readonly ILogger<AccountController> _logger;

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        // Validate password strength
        var (isValid, errors) = _passwordValidator.ValidatePassword(request.Password);

        if (!isValid)
        {
            return BadRequest(new { errors });
        }

        // Check if user already exists
        if (await _userService.UserExistsAsync(request.Email))
        {
            return BadRequest(new { message = "User already exists" });
        }

        // Register user (password will be hashed inside)
        var user = await _userService.RegisterUserAsync(
            request.Username,
            request.Email,
            request.Password);

        _logger.LogInformation("User {Username} registered successfully", user.Username);

        return Ok(new
        {
            message = "Registration successful",
            userId = user.Id
        });
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userService.GetByIdAsync(int.Parse(userId));

        // Verify current password
        var passwordService = new PasswordService();
        if (!passwordService.VerifyPassword(user, user.PasswordHash, request.CurrentPassword))
        {
            return BadRequest(new { message = "Current password is incorrect" });
        }

        // Validate new password
        var (isValid, errors) = _passwordValidator.ValidatePassword(request.NewPassword);

        if (!isValid)
        {
            return BadRequest(new { errors });
        }

        // Update password
        user.PasswordHash = passwordService.HashPassword(user, request.NewPassword);
        await _userService.UpdateAsync(user);

        _logger.LogInformation("User {UserId} changed password", userId);

        return Ok(new { message = "Password changed successfully" });
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use established algorithms
   - PBKDF2 (built into .NET)
   - BCrypt
   - Argon2 (newer, more secure)
   - ASP.NET Core Identity PasswordHasher

2. ❌ NEVER use these
   - Plain text storage
   - MD5
   - SHA1
   - SHA256 without salt
   - Reversible encryption

3. ✅ Use salt
   - Random per password
   - Prevents rainbow table attacks
   - Generated automatically by good libraries

4. ✅ Use sufficient iterations
   - PBKDF2: 100,000+ iterations
   - BCrypt: Work factor 12+
   - Balance security vs performance

5. ✅ Enforce password complexity
   - Minimum length (8+ chars)
   - Mix of characters
   - Avoid common passwords

6. ✅ Use timing-safe comparison
   - CryptographicOperations.FixedTimeEquals
   - Prevents timing attacks

7. ✅ Implement password reset securely
   - Time-limited tokens
   - One-time use
   - Secure random generation

8. ✅ Rate limit password attempts
   - Prevent brute force attacks
   - Lock account after failures

9. ✅ Never log passwords
   - Not in logs
   - Not in error messages
   - Not in database queries

10. ✅ Consider Multi-Factor Authentication
    - Additional security layer
    - Protects against password compromise
*/
```

---

## **Q284: How do you implement CORS (Cross-Origin Resource Sharing) in ASP.NET Core?**

**Answer:**

CORS is a security feature that controls which domains can access your API from a browser.

**Implementation:**
```csharp
// ============================================
// Program.cs - Basic CORS Setup
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Add CORS services
builder.Services.AddCors(options =>
{
    // Policy 1: Allow specific origin
    options.AddPolicy("AllowSpecificOrigin", policy =>
    {
        policy.WithOrigins("https://example.com", "https://www.example.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });

    // Policy 2: Allow any origin (development only!)
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });

    // Policy 3: Specific configuration
    options.AddPolicy("ProductionPolicy", policy =>
    {
        policy.WithOrigins("https://myapp.com")
              .WithMethods("GET", "POST", "PUT", "DELETE")
              .WithHeaders("Content-Type", "Authorization")
              .WithExposedHeaders("X-Custom-Header")
              .SetPreflightMaxAge(TimeSpan.FromMinutes(10))
              .AllowCredentials();
    });
});

var app = builder.Build();

// Enable CORS middleware (must be before UseAuthorization)
app.UseCors("AllowSpecificOrigin");

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();

// ============================================
// Controller-Level CORS
// ============================================

[ApiController]
[Route("api/[controller]")]
[EnableCors("AllowSpecificOrigin")] // Apply to entire controller
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new[] { "Product1", "Product2" });
    }

    [HttpPost]
    [EnableCors("AllowAll")] // Override for specific action
    public IActionResult Create([FromBody] Product product)
    {
        return Ok(product);
    }

    [HttpDelete("{id}")]
    [DisableCors] // Disable CORS for specific action
    public IActionResult Delete(int id)
    {
        return NoContent();
    }
}

// ============================================
// Dynamic CORS Policy
// ============================================

public class CustomCorsPolicy : ICorsPolicyProvider
{
    private readonly IConfiguration _configuration;

    public CustomCorsPolicy(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public Task<CorsPolicy> GetPolicyAsync(HttpContext context, string policyName)
    {
        // Load allowed origins from configuration or database
        var allowedOrigins = _configuration.GetSection("AllowedOrigins").Get<string[]>();

        var policy = new CorsPolicyBuilder()
            .WithOrigins(allowedOrigins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()
            .Build();

        return Task.FromResult(policy);
    }
}

/*
CORS Best Practices:
1. ✅ Never use AllowAnyOrigin() in production
2. ✅ Specify exact origins, not wildcards
3. ✅ Use AllowCredentials() carefully
4. ✅ Limit methods and headers
5. ✅ Set appropriate preflight cache time
6. ❌ Don't rely on CORS for security (it's browser-enforced)
7. ✅ Use HTTPS origins only in production
8. ✅ Place UseCors() before UseAuthorization()
*/
```

---

## **Q285: How do you prevent CSRF (Cross-Site Request Forgery) attacks?**

**Answer:**

CSRF attacks trick users into performing unwanted actions. ASP.NET Core provides anti-forgery tokens to prevent this.

**Implementation:**
```csharp
// ============================================
// Program.cs - Configure Anti-Forgery
// ============================================

builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
    options.Cookie.Name = "X-CSRF-TOKEN";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
});

// ============================================
// Razor Pages - Automatic Protection
// ============================================

// Forms automatically include anti-forgery token
<form method="post">
    @Html.AntiForgeryToken() <!-- Automatically added in .NET 6+ -->
    <input type="text" name="username" />
    <button type="submit">Submit</button>
</form>

// ============================================
// API Controllers - Manual Validation
// ============================================

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    [HttpPost("transfer")]
    [ValidateAntiForgeryToken] // Validates the token
    public IActionResult TransferMoney([FromBody] TransferRequest request)
    {
        // Process transfer
        return Ok();
    }

    // Generate token endpoint
    [HttpGet("csrf-token")]
    public IActionResult GetCsrfToken([FromServices] IAntiforgery antiforgery)
    {
        var tokens = antiforgery.GetAndStoreTokens(HttpContext);
        return Ok(new { token = tokens.RequestToken });
    }
}

// ============================================
// JavaScript Client Usage
// ============================================

/*
// Get CSRF token
const response = await fetch('/api/account/csrf-token');
const { token } = await response.json();

// Include in subsequent requests
await fetch('/api/account/transfer', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': token
    },
    body: JSON.stringify({ amount: 100, to: 'account123' })
});
*/

// ============================================
// SameSite Cookie Protection
// ============================================

builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.SameSite = SameSiteMode.Strict; // or Lax
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});

/*
CSRF Protection Best Practices:
1. ✅ Use anti-forgery tokens for state-changing operations
2. ✅ Set SameSite=Strict or Lax on cookies
3. ✅ Validate tokens on POST, PUT, DELETE
4. ✅ Use HTTPS to prevent token theft
5. ❌ Don't use GET for state-changing operations
6. ✅ Verify Origin/Referer headers
7. ✅ Use short-lived tokens
8. ✅ Require re-authentication for sensitive operations
*/
```

---

## **Q286: How do you prevent XSS (Cross-Site Scripting) attacks?**

**Answer:**

XSS attacks inject malicious scripts into web pages. Prevention requires proper encoding and validation.

**Implementation:**
```csharp
// ============================================
// Output Encoding (Razor)
// ============================================

// ✅ SAFE: Automatic HTML encoding
<div>@Model.UserInput</div>
<!-- Output: &lt;script&gt;alert('XSS')&lt;/script&gt; -->

// ❌ UNSAFE: Raw HTML
<div>@Html.Raw(Model.UserInput)</div>
<!-- Output: <script>alert('XSS')</script> - EXECUTES! -->

// ✅ SAFE: Explicit encoding
<div>@Html.Encode(Model.UserInput)</div>

// ✅ SAFE: JavaScript encoding
<script>
    var data = '@Html.JavaScriptStringEncode(Model.UserInput)';
</script>

// ✅ SAFE: URL encoding
<a href="/search?q=@Uri.EscapeDataString(Model.Query)">Search</a>

// ============================================
// Input Validation
// ============================================

public class CreatePostRequest
{
    [Required]
    [StringLength(200, MinimumLength = 1)]
    [RegularExpression(@"^[a-zA-Z0-9\s\-,.!?]*$",
        ErrorMessage = "Only alphanumeric and basic punctuation allowed")]
    public string Title { get; set; }

    [Required]
    [StringLength(5000)]
    public string Content { get; set; }
}

[ApiController]
[Route("api/[controller]")]
public class PostsController : ControllerBase
{
    [HttpPost]
    public IActionResult CreatePost([FromBody] CreatePostRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // Sanitize HTML content
        var sanitizedContent = SanitizeHtml(request.Content);

        // Store sanitized content
        return Ok();
    }

    private string SanitizeHtml(string html)
    {
        // Use HtmlSanitizer library
        var sanitizer = new HtmlSanitizer();

        // Allow only safe tags
        sanitizer.AllowedTags.Clear();
        sanitizer.AllowedTags.Add("p");
        sanitizer.AllowedTags.Add("br");
        sanitizer.AllowedTags.Add("strong");
        sanitizer.AllowedTags.Add("em");

        return sanitizer.Sanitize(html);
    }
}

// ============================================
// Content Security Policy (CSP)
// ============================================

app.Use(async (context, next) =>
{
    context.Response.Headers.Add("Content-Security-Policy",
        "default-src 'self'; " +
        "script-src 'self' 'nonce-{NONCE}'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data: https:; " +
        "font-src 'self'; " +
        "connect-src 'self'; " +
        "frame-ancestors 'none';");

    await next();
});

/*
XSS Prevention Best Practices:
1. ✅ Always encode output (Razor does this by default)
2. ❌ Never use Html.Raw() with user input
3. ✅ Validate and sanitize all user input
4. ✅ Use Content Security Policy headers
5. ✅ Set HttpOnly flag on cookies
6. ✅ Use appropriate encoding for context (HTML, JS, URL)
7. ✅ Use HTML Sanitizer for rich content
8. ✅ Implement CSP nonces for inline scripts
9. ✅ Keep frameworks and libraries updated
10. ❌ Don't trust client-side validation alone
*/
```

---

## **Q287: How do you prevent SQL Injection in ASP.NET Core?**

**Answer:**

SQL Injection occurs when user input is concatenated into SQL queries. Always use parameterized queries.

**Implementation:**
```csharp
// ============================================
// ❌ UNSAFE: String Concatenation
// ============================================

public async Task<User> GetUserUnsafe(string username)
{
    // NEVER DO THIS!
    var sql = $"SELECT * FROM Users WHERE Username = '{username}'";
    return await _context.Users.FromSqlRaw(sql).FirstOrDefaultAsync();

    // Attack: username = "admin' OR '1'='1"
    // Result: SELECT * FROM Users WHERE Username = 'admin' OR '1'='1'
    // Returns all users!
}

// ============================================
// ✅ SAFE: Parameterized Queries (Entity Framework)
// ============================================

public async Task<User> GetUserSafe(string username)
{
    // EF Core automatically parameterizes
    return await _context.Users
        .Where(u => u.Username == username)
        .FirstOrDefaultAsync();
}

// ✅ SAFE: FromSqlRaw with parameters
public async Task<List<User>> SearchUsersSafe(string searchTerm)
{
    return await _context.Users
        .FromSqlRaw("SELECT * FROM Users WHERE Username LIKE {0}", $"%{searchTerm}%")
        .ToListAsync();
}

// ✅ SAFE: FromSqlInterpolated
public async Task<User> GetUserByIdSafe(int userId)
{
    return await _context.Users
        .FromSqlInterpolated($"SELECT * FROM Users WHERE Id = {userId}")
        .FirstOrDefaultAsync();
}

// ============================================
// ✅ SAFE: ADO.NET with Parameters
// ============================================

public async Task<User> GetUserWithAdo(string username)
{
    using var connection = new SqlConnection(_connectionString);
    using var command = new SqlCommand(
        "SELECT * FROM Users WHERE Username = @Username",
        connection);

    // Add parameter
    command.Parameters.AddWithValue("@Username", username);

    await connection.OpenAsync();
    using var reader = await command.ExecuteReaderAsync();

    if (await reader.ReadAsync())
    {
        return new User
        {
            Id = reader.GetInt32(0),
            Username = reader.GetString(1)
        };
    }

    return null;
}

// ============================================
// ✅ SAFE: Stored Procedures
// ============================================

public async Task<List<User>> GetUsersByRoleSafe(string role)
{
    return await _context.Users
        .FromSqlRaw("EXEC GetUsersByRole @Role",
            new SqlParameter("@Role", role))
        .ToListAsync();
}

// ============================================
// ✅ SAFE: Dapper with Parameters
// ============================================

public async Task<User> GetUserWithDapper(string username)
{
    using var connection = new SqlConnection(_connectionString);

    return await connection.QueryFirstOrDefaultAsync<User>(
        "SELECT * FROM Users WHERE Username = @Username",
        new { Username = username });
}

// ============================================
// Input Validation
// ============================================

public class SearchRequest
{
    [Required]
    [StringLength(50)]
    [RegularExpression(@"^[a-zA-Z0-9_]*$",
        ErrorMessage = "Only alphanumeric characters and underscores allowed")]
    public string Username { get; set; }
}

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] SearchRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var users = await _userService.SearchUsersAsync(request.Username);
        return Ok(users);
    }
}

// ============================================
// ORM Relationships (Always Safe)
// ============================================

public async Task<List<Order>> GetUserOrders(int userId)
{
    // EF Core handles this safely
    var user = await _context.Users
        .Include(u => u.Orders)
        .ThenInclude(o => o.Items)
        .FirstOrDefaultAsync(u => u.Id == userId);

    return user?.Orders.ToList();
}

/*
SQL Injection Prevention Best Practices:
1. ✅ Always use parameterized queries
2. ✅ Use ORM (Entity Framework) when possible
3. ❌ Never concatenate user input into SQL
4. ✅ Validate and sanitize all input
5. ✅ Use stored procedures with parameters
6. ✅ Apply principle of least privilege (database permissions)
7. ✅ Use prepared statements
8. ✅ Escape special characters if concatenation is unavoidable
9. ✅ Implement input validation
10. ✅ Use SqlParameter, not string interpolation
*/
```

---

## Q288: How do you configure security headers in ASP.NET Core?

**Answer:**

Security headers protect against common web vulnerabilities by controlling browser behavior.

```csharp
// ============================================
// Program.cs - Security Headers Middleware
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHsts(options =>
{
    options.Preload = true;
    options.IncludeSubDomains = true;
    options.MaxAge = TimeSpan.FromDays(365);
});

var app = builder.Build();

// Security Headers Middleware
app.Use(async (context, next) =>
{
    // Prevent MIME type sniffing
    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");

    // Prevent clickjacking
    context.Response.Headers.Add("X-Frame-Options", "DENY");

    // XSS Protection (legacy browsers)
    context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");

    // Content Security Policy
    context.Response.Headers.Add("Content-Security-Policy",
        "default-src 'self'; " +
        "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data: https:; " +
        "font-src 'self'; " +
        "connect-src 'self'; " +
        "frame-ancestors 'none';");

    // Referrer Policy
    context.Response.Headers.Add("Referrer-Policy", "strict-origin-when-cross-origin");

    // Permissions Policy (formerly Feature Policy)
    context.Response.Headers.Add("Permissions-Policy",
        "geolocation=(), microphone=(), camera=()");

    await next();
});

// HSTS in production
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();
app.Run();

// ============================================
// Custom Security Headers Middleware
// ============================================

public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // X-Content-Type-Options
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");

        // X-Frame-Options
        context.Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");

        // Strict-Transport-Security
        if (context.Request.IsHttps)
        {
            context.Response.Headers.Add(
                "Strict-Transport-Security",
                "max-age=31536000; includeSubDomains; preload");
        }

        // Content-Security-Policy
        var csp = new StringBuilder();
        csp.Append("default-src 'self'; ");
        csp.Append("script-src 'self' 'unsafe-inline'; ");
        csp.Append("style-src 'self' 'unsafe-inline'; ");
        csp.Append("img-src 'self' data: https:; ");
        csp.Append("font-src 'self'; ");
        csp.Append("connect-src 'self'; ");
        csp.Append("frame-ancestors 'none'; ");
        csp.Append("base-uri 'self'; ");
        csp.Append("form-action 'self'");

        context.Response.Headers.Add("Content-Security-Policy", csp.ToString());

        await _next(context);
    }
}

public static class SecurityHeadersMiddlewareExtensions
{
    public static IApplicationBuilder UseSecurityHeaders(
        this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<SecurityHeadersMiddleware>();
    }
}

// Usage in Program.cs
app.UseSecurityHeaders();

// ============================================
// Configurable Security Headers
// ============================================

public class SecurityHeadersOptions
{
    public bool EnableXContentTypeOptions { get; set; } = true;
    public string XFrameOptions { get; set; } = "SAMEORIGIN";
    public bool EnableHsts { get; set; } = true;
    public int HstsMaxAge { get; set; } = 31536000;
    public string ContentSecurityPolicy { get; set; }
    public string ReferrerPolicy { get; set; } = "strict-origin-when-cross-origin";
}

public class ConfigurableSecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;
    private readonly SecurityHeadersOptions _options;

    public ConfigurableSecurityHeadersMiddleware(
        RequestDelegate next,
        IOptions<SecurityHeadersOptions> options)
    {
        _next = next;
        _options = options.Value;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (_options.EnableXContentTypeOptions)
        {
            context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
        }

        if (!string.IsNullOrEmpty(_options.XFrameOptions))
        {
            context.Response.Headers.Add("X-Frame-Options", _options.XFrameOptions);
        }

        if (_options.EnableHsts && context.Request.IsHttps)
        {
            context.Response.Headers.Add(
                "Strict-Transport-Security",
                $"max-age={_options.HstsMaxAge}; includeSubDomains");
        }

        if (!string.IsNullOrEmpty(_options.ContentSecurityPolicy))
        {
            context.Response.Headers.Add(
                "Content-Security-Policy",
                _options.ContentSecurityPolicy);
        }

        if (!string.IsNullOrEmpty(_options.ReferrerPolicy))
        {
            context.Response.Headers.Add("Referrer-Policy", _options.ReferrerPolicy);
        }

        await _next(context);
    }
}

// Configuration in appsettings.json
{
  "SecurityHeaders": {
    "EnableXContentTypeOptions": true,
    "XFrameOptions": "DENY",
    "EnableHsts": true,
    "HstsMaxAge": 31536000,
    "ContentSecurityPolicy": "default-src 'self'; script-src 'self' 'unsafe-inline';",
    "ReferrerPolicy": "no-referrer"
  }
}

// Program.cs
builder.Services.Configure<SecurityHeadersOptions>(
    builder.Configuration.GetSection("SecurityHeaders"));

/*
Key Security Headers:

1. X-Content-Type-Options: nosniff
   - Prevents MIME type sniffing

2. X-Frame-Options: DENY/SAMEORIGIN
   - Prevents clickjacking attacks

3. Strict-Transport-Security (HSTS)
   - Forces HTTPS connections

4. Content-Security-Policy (CSP)
   - Controls resource loading

5. X-XSS-Protection: 1; mode=block
   - Legacy XSS protection

6. Referrer-Policy
   - Controls referrer information

7. Permissions-Policy
   - Controls browser features

Best Practices:
- Always use HTTPS in production
- Implement CSP carefully to avoid breaking functionality
- Test headers in development
- Use report-only mode for CSP testing
- Keep headers up to date with security recommendations
*/
```

---

## Q289: How do you enforce HTTPS and configure TLS in ASP.NET Core?

**Answer:**

HTTPS and TLS configuration ensure secure communication between client and server.

```csharp
// ============================================
// Program.cs - HTTPS Configuration
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel for HTTPS
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ConfigureHttpsDefaults(httpsOptions =>
    {
        httpsOptions.SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13;
    });
});

// HSTS Configuration
builder.Services.AddHsts(options =>
{
    options.Preload = true;
    options.IncludeSubDomains = true;
    options.MaxAge = TimeSpan.FromDays(365);
    options.ExcludedHosts.Clear(); // Remove localhost exclusion in production
});

// HTTPS Redirection
builder.Services.AddHttpsRedirection(options =>
{
    options.RedirectStatusCode = StatusCodes.Status307TemporaryRedirect;
    options.HttpsPort = 5001;
});

var app = builder.Build();

// Use HSTS (production only)
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

// Redirect HTTP to HTTPS
app.UseHttpsRedirection();

app.Run();

// ============================================
// appsettings.json - Kestrel HTTPS Setup
// ============================================

{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:5000"
      },
      "Https": {
        "Url": "https://localhost:5001",
        "Certificate": {
          "Path": "certificate.pfx",
          "Password": "your-certificate-password"
        }
      }
    }
  },
  "Https": {
    "Port": 5001
  }
}

// ============================================
// Certificate Loading from Configuration
// ============================================

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.Listen(IPAddress.Any, 5000); // HTTP
    serverOptions.Listen(IPAddress.Any, 5001, listenOptions =>
    {
        // Load certificate from file
        listenOptions.UseHttps("certificate.pfx", "password");

        // Or load from certificate store
        // listenOptions.UseHttps(storeCert =>
        // {
        //     storeCert.Subject = "example.com";
        //     storeCert.Store = "My";
        //     storeCert.Location = StoreLocation.CurrentUser;
        //     storeCert.AllowInvalid = false;
        // });
    });
});

// ============================================
// Azure Key Vault Certificate
// ============================================

using Azure.Identity;
using Azure.Security.KeyVault.Certificates;

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.Listen(IPAddress.Any, 5001, listenOptions =>
    {
        listenOptions.UseHttps(async (stream, clientHelloInfo, state, cancellationToken) =>
        {
            var client = new CertificateClient(
                new Uri("https://your-keyvault.vault.azure.net/"),
                new DefaultAzureCredential());

            var certificate = await client.DownloadCertificateAsync(
                "certificate-name",
                cancellationToken: cancellationToken);

            return new SslServerAuthenticationOptions
            {
                ServerCertificate = certificate.Value
            };
        });
    });
});

// ============================================
// Require HTTPS Attribute
// ============================================

[ApiController]
[Route("api/[controller]")]
[RequireHttps]
public class SecureController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        // This endpoint requires HTTPS
        return Ok("Secure data");
    }
}

// ============================================
// Custom HTTPS Middleware
// ============================================

public class RequireHttpsMiddleware
{
    private readonly RequestDelegate _next;
    private readonly int _sslPort;

    public RequireHttpsMiddleware(RequestDelegate next, int sslPort = 443)
    {
        _next = next;
        _sslPort = sslPort;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.IsHttps)
        {
            var httpsUrl = $"https://{context.Request.Host.Host}";

            if (_sslPort != 443)
            {
                httpsUrl += $":{_sslPort}";
            }

            httpsUrl += context.Request.Path + context.Request.QueryString;

            context.Response.Redirect(httpsUrl, permanent: true);
            return;
        }

        await _next(context);
    }
}

// ============================================
// Development Certificate Setup
// ============================================

// Command line - Generate development certificate
// dotnet dev-certs https --trust

// Check certificate
// dotnet dev-certs https --check

// Clean certificates
// dotnet dev-certs https --clean

// ============================================
// Docker HTTPS Configuration
// ============================================

// Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

// docker-compose.yml
services:
  webapp:
    environment:
      - ASPNETCORE_URLS=https://+:443;http://+:80
      - ASPNETCORE_Kestrel__Certificates__Default__Path=/https/certificate.pfx
      - ASPNETCORE_Kestrel__Certificates__Default__Password=YourPassword
    volumes:
      - ./certificates:/https:ro
    ports:
      - "5000:80"
      - "5001:443"

/*
HTTPS/TLS Best Practices:

1. ✅ Always use TLS 1.2 or higher
2. ✅ Disable older protocols (SSL 3.0, TLS 1.0, TLS 1.1)
3. ✅ Use strong cipher suites
4. ✅ Enable HSTS in production
5. ✅ Redirect all HTTP to HTTPS
6. ✅ Use valid certificates from trusted CAs
7. ✅ Implement certificate pinning for mobile apps
8. ✅ Keep certificates up to date
9. ✅ Use 2048-bit or higher key length
10. ✅ Monitor certificate expiration

Certificate Management:
- Development: Use dotnet dev-certs
- Production: Use certificates from trusted CAs
- Azure: Use Azure Key Vault
- Let's Encrypt: Free automated certificates
- Renewal: Automate certificate renewal process
*/
```

---

## Q290: How do you use the Data Protection API in ASP.NET Core?

**Answer:**

The Data Protection API provides cryptographic APIs for protecting data, including encryption and decryption.

```csharp
// ============================================
// Program.cs - Data Protection Configuration
// ============================================

var builder = WebApplication.CreateBuilder(args);

// Basic Data Protection
builder.Services.AddDataProtection()
    .SetApplicationName("MyApp")
    .PersistKeysToFileSystem(new DirectoryInfo(@"C:\keys"))
    .SetDefaultKeyLifetime(TimeSpan.FromDays(90));

// Azure Blob Storage (Production)
builder.Services.AddDataProtection()
    .SetApplicationName("MyApp")
    .PersistKeysToAzureBlobStorage(
        new Uri("https://mystorageaccount.blob.core.windows.net/keys/keys.xml"))
    .ProtectKeysWithAzureKeyVault(
        new Uri("https://mykeyvault.vault.azure.net/keys/dataprotection"),
        new DefaultAzureCredential());

var app = builder.Build();
app.Run();

// ============================================
// Using Data Protection for Encryption
// ============================================

public class SecureDataService
{
    private readonly IDataProtector _protector;

    public SecureDataService(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("SecureDataService.Purpose");
    }

    public string Encrypt(string plainText)
    {
        return _protector.Protect(plainText);
    }

    public string Decrypt(string cipherText)
    {
        try
        {
            return _protector.Unprotect(cipherText);
        }
        catch (CryptographicException)
        {
            // Handle decryption failure
            return null;
        }
    }
}

// Usage
[ApiController]
[Route("api/[controller]")]
public class DataController : ControllerBase
{
    private readonly SecureDataService _secureData;

    public DataController(SecureDataService secureData)
    {
        _secureData = secureData;
    }

    [HttpPost("encrypt")]
    public IActionResult Encrypt([FromBody] string data)
    {
        var encrypted = _secureData.Encrypt(data);
        return Ok(new { encrypted });
    }

    [HttpPost("decrypt")]
    public IActionResult Decrypt([FromBody] string data)
    {
        var decrypted = _secureData.Decrypt(data);
        if (decrypted == null)
        {
            return BadRequest("Decryption failed");
        }
        return Ok(new { decrypted });
    }
}

// ============================================
// Time-Limited Data Protection
// ============================================

public class TimeLimitedProtectionService
{
    private readonly ITimeLimitedDataProtector _protector;

    public TimeLimitedProtectionService(IDataProtectionProvider provider)
    {
        var baseProtector = provider.CreateProtector("TimeLimited.Purpose");
        _protector = baseProtector.ToTimeLimitedDataProtector();
    }

    public string ProtectWithExpiration(string data, TimeSpan lifetime)
    {
        return _protector.Protect(data, lifetime);
    }

    public string UnprotectWithExpiration(string protectedData)
    {
        try
        {
            return _protector.Unprotect(protectedData, out DateTimeOffset expiration);
        }
        catch (CryptographicException ex) when (
            ex.Message.Contains("expired"))
        {
            // Data has expired
            return null;
        }
    }
}

// Example: Email verification token
public class EmailVerificationService
{
    private readonly ITimeLimitedDataProtector _protector;

    public EmailVerificationService(IDataProtectionProvider provider)
    {
        var baseProtector = provider.CreateProtector("EmailVerification");
        _protector = baseProtector.ToTimeLimitedDataProtector();
    }

    public string GenerateEmailToken(string email)
    {
        var token = _protector.Protect(
            email,
            lifetime: TimeSpan.FromHours(24));
        return WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
    }

    public string ValidateEmailToken(string token)
    {
        try
        {
            var tokenBytes = WebEncoders.Base64UrlDecode(token);
            var tokenString = Encoding.UTF8.GetString(tokenBytes);

            return _protector.Unprotect(
                tokenString,
                out DateTimeOffset expiration);
        }
        catch (CryptographicException)
        {
            return null; // Invalid or expired token
        }
    }
}

// ============================================
// Purpose Hierarchy
// ============================================

public class HierarchicalProtectionService
{
    private readonly IDataProtectionProvider _provider;

    public HierarchicalProtectionService(IDataProtectionProvider provider)
    {
        _provider = provider;
    }

    public string ProtectUserData(int userId, string data)
    {
        // Create purpose: "Users.{userId}"
        var protector = _provider.CreateProtector(
            "Users",
            userId.ToString());

        return protector.Protect(data);
    }

    public string UnprotectUserData(int userId, string protectedData)
    {
        var protector = _provider.CreateProtector(
            "Users",
            userId.ToString());

        return protector.Unprotect(protectedData);
    }
}

// ============================================
// Custom Key Storage (Redis)
// ============================================

public class RedisXmlRepository : IXmlRepository
{
    private readonly IConnectionMultiplexer _redis;
    private readonly string _key = "DataProtection-Keys";

    public RedisXmlRepository(IConnectionMultiplexer redis)
    {
        _redis = redis;
    }

    public IReadOnlyCollection<XElement> GetAllElements()
    {
        var database = _redis.GetDatabase();
        var values = database.ListRange(_key);

        return values
            .Select(v => XElement.Parse(v))
            .ToList()
            .AsReadOnly();
    }

    public void StoreElement(XElement element, string friendlyName)
    {
        var database = _redis.GetDatabase();
        database.ListRightPush(_key, element.ToString());
    }
}

// Registration
builder.Services.AddSingleton<IConnectionMultiplexer>(
    ConnectionMultiplexer.Connect("localhost:6379"));

builder.Services.AddDataProtection()
    .AddKeyManagementOptions(options =>
    {
        options.XmlRepository =
            new RedisXmlRepository(
                sp.GetRequiredService<IConnectionMultiplexer>());
    });

// ============================================
// Protecting Sensitive Configuration
// ============================================

public class ConfigurationProtectionService
{
    private readonly IDataProtector _protector;
    private readonly IConfiguration _configuration;

    public ConfigurationProtectionService(
        IDataProtectionProvider provider,
        IConfiguration configuration)
    {
        _protector = provider.CreateProtector("Configuration");
        _configuration = configuration;
    }

    public string GetProtectedConnectionString(string name)
    {
        var encrypted = _configuration.GetConnectionString(name);
        if (string.IsNullOrEmpty(encrypted))
        {
            return null;
        }

        try
        {
            return _protector.Unprotect(encrypted);
        }
        catch (CryptographicException)
        {
            // Assume it's not encrypted
            return encrypted;
        }
    }

    public void ProtectConnectionString(string name, string connectionString)
    {
        var encrypted = _protector.Protect(connectionString);
        // Store encrypted value
    }
}

/*
Data Protection API Best Practices:

1. ✅ Use purpose strings to isolate protected data
2. ✅ Store keys in a secure, persistent location
3. ✅ Use Azure Key Vault in production
4. ✅ Set appropriate key lifetimes
5. ✅ Use time-limited protection for tokens
6. ✅ Handle CryptographicException gracefully
7. ✅ Share keys across web farm instances
8. ✅ Never hardcode encryption keys
9. ✅ Implement key rotation strategies
10. ✅ Use hierarchical purposes for multi-tenant apps

Key Storage Options:
- Development: File system
- Production: Azure Blob Storage + Key Vault
- Redis: For distributed applications
- Database: Custom IXmlRepository implementation

Purpose Strings:
- Isolate data by purpose
- Use hierarchical purposes for multi-tenant
- Never reuse purpose strings
*/
```

---

## Q291: How do you manage secrets and sensitive configuration in ASP.NET Core?

**Answer:**

Proper secrets management ensures sensitive data like API keys, connection strings, and passwords are never exposed.

```csharp
// ============================================
// Development - User Secrets
// ============================================

// Command line - Initialize User Secrets
// dotnet user-secrets init

// Set a secret
// dotnet user-secrets set "ApiKeys:OpenAI" "sk-xxxxxxxxxxxxxxxx"
// dotnet user-secrets set "ConnectionStrings:Database" "Server=..."

// List secrets
// dotnet user-secrets list

// Remove a secret
// dotnet user-secrets remove "ApiKeys:OpenAI"

// Clear all secrets
// dotnet user-secrets clear

// ============================================
// .csproj - User Secrets Configuration
// ============================================

<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <UserSecretsId>aspnet-MyApp-12345678</UserSecretsId>
  </PropertyGroup>
</Project>

// ============================================
// Program.cs - Accessing User Secrets
// ============================================

var builder = WebApplication.CreateBuilder(args);

// User Secrets automatically loaded in Development
// Access configuration
var openAiKey = builder.Configuration["ApiKeys:OpenAI"];
var dbConnection = builder.Configuration.GetConnectionString("Database");

// ============================================
// Azure Key Vault Integration
// ============================================

using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Azure Key Vault
if (!builder.Environment.IsDevelopment())
{
    var keyVaultUrl = builder.Configuration["KeyVault:Url"];

    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUrl),
        new DefaultAzureCredential());
}

var app = builder.Build();

// ============================================
// appsettings.json - Key Vault Reference
// ============================================

{
  "KeyVault": {
    "Url": "https://mykeyvault.vault.azure.net/"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}

// ============================================
// Secrets Service
// ============================================

public interface ISecretsService
{
    Task<string> GetSecretAsync(string key);
    Task SetSecretAsync(string key, string value);
}

public class AzureKeyVaultSecretsService : ISecretsService
{
    private readonly SecretClient _client;

    public AzureKeyVaultSecretsService(IConfiguration configuration)
    {
        var keyVaultUrl = configuration["KeyVault:Url"];
        _client = new SecretClient(
            new Uri(keyVaultUrl),
            new DefaultAzureCredential());
    }

    public async Task<string> GetSecretAsync(string key)
    {
        try
        {
            KeyVaultSecret secret = await _client.GetSecretAsync(key);
            return secret.Value;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null; // Secret not found
        }
    }

    public async Task SetSecretAsync(string key, string value)
    {
        await _client.SetSecretAsync(key, value);
    }
}

// Registration
builder.Services.AddSingleton<ISecretsService, AzureKeyVaultSecretsService>();

// ============================================
// Environment Variables
// ============================================

// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Environment variables override other configuration
var apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY");
var dbConnection = Environment.GetEnvironmentVariable("DATABASE_CONNECTION");

// Or through configuration
var apiKeyFromConfig = builder.Configuration["OpenAI:ApiKey"];

// ============================================
// Docker Secrets
// ============================================

// docker-compose.yml
version: '3.8'
services:
  webapp:
    image: myapp:latest
    environment:
      - ConnectionStrings__Database=/run/secrets/db_connection
      - ApiKeys__OpenAI=/run/secrets/openai_key
    secrets:
      - db_connection
      - openai_key

secrets:
  db_connection:
    external: true
  openai_key:
    external: true

// Read Docker secret in code
public static class DockerSecretsExtensions
{
    public static string GetDockerSecret(this IConfiguration configuration, string key)
    {
        var secretPath = configuration[key];

        if (string.IsNullOrEmpty(secretPath) || !File.Exists(secretPath))
        {
            return configuration[key];
        }

        return File.ReadAllText(secretPath).Trim();
    }
}

// Usage
var dbConnection = builder.Configuration.GetDockerSecret(
    "ConnectionStrings:Database");

// ============================================
// AWS Secrets Manager
// ============================================

using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

public class AwsSecretsService : ISecretsService
{
    private readonly IAmazonSecretsManager _client;

    public AwsSecretsService()
    {
        _client = new AmazonSecretsManagerClient();
    }

    public async Task<string> GetSecretAsync(string secretName)
    {
        var request = new GetSecretValueRequest
        {
            SecretId = secretName
        };

        try
        {
            var response = await _client.GetSecretValueAsync(request);
            return response.SecretString;
        }
        catch (ResourceNotFoundException)
        {
            return null;
        }
    }

    public async Task SetSecretAsync(string secretName, string value)
    {
        var request = new CreateSecretRequest
        {
            Name = secretName,
            SecretString = value
        };

        await _client.CreateSecretAsync(request);
    }
}

// ============================================
// Configuration Builder with Multiple Sources
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true)
    .AddEnvironmentVariables()
    .AddUserSecrets<Program>(optional: true);

if (!builder.Environment.IsDevelopment())
{
    // Production: Use Azure Key Vault
    builder.Configuration.AddAzureKeyVault(
        new Uri(builder.Configuration["KeyVault:Url"]),
        new DefaultAzureCredential());
}

// ============================================
// Strongly-Typed Configuration
// ============================================

public class ApiKeysOptions
{
    public const string SectionName = "ApiKeys";

    public string OpenAI { get; set; }
    public string Stripe { get; set; }
    public string SendGrid { get; set; }
}

public class ConnectionStringsOptions
{
    public const string SectionName = "ConnectionStrings";

    public string Database { get; set; }
    public string Redis { get; set; }
}

// Registration
builder.Services.Configure<ApiKeysOptions>(
    builder.Configuration.GetSection(ApiKeysOptions.SectionName));

builder.Services.Configure<ConnectionStringsOptions>(
    builder.Configuration.GetSection(ConnectionStringsOptions.SectionName));

// Usage
public class MyService
{
    private readonly ApiKeysOptions _apiKeys;

    public MyService(IOptions<ApiKeysOptions> apiKeys)
    {
        _apiKeys = apiKeys.Value;
    }

    public async Task CallOpenAI()
    {
        var apiKey = _apiKeys.OpenAI;
        // Use API key
    }
}

// ============================================
// Validation
// ============================================

public class ApiKeysOptionsValidator : IValidateOptions<ApiKeysOptions>
{
    public ValidateOptionsResult Validate(string name, ApiKeysOptions options)
    {
        if (string.IsNullOrEmpty(options.OpenAI))
        {
            return ValidateOptionsResult.Fail("OpenAI API key is required");
        }

        if (!options.OpenAI.StartsWith("sk-"))
        {
            return ValidateOptionsResult.Fail("Invalid OpenAI API key format");
        }

        return ValidateOptionsResult.Success;
    }
}

// Registration
builder.Services.AddSingleton<IValidateOptions<ApiKeysOptions>,
    ApiKeysOptionsValidator>();

/*
Secrets Management Best Practices:

1. ✅ NEVER commit secrets to source control
2. ✅ Use User Secrets for local development
3. ✅ Use Azure Key Vault / AWS Secrets Manager in production
4. ✅ Use environment variables for containerized apps
5. ✅ Implement proper access controls
6. ✅ Rotate secrets regularly
7. ✅ Use managed identities when possible
8. ✅ Audit secret access
9. ✅ Encrypt secrets at rest and in transit
10. ✅ Use separate secrets for each environment

Configuration Hierarchy (last wins):
1. appsettings.json
2. appsettings.{Environment}.json
3. User Secrets (Development only)
4. Environment Variables
5. Azure Key Vault / Command-line arguments

Security Checklist:
- ❌ Never hardcode secrets in code
- ❌ Never commit .env files
- ✅ Add secrets files to .gitignore
- ✅ Use different secrets per environment
- ✅ Implement least privilege access
- ✅ Monitor and log secret access
- ✅ Use strong, randomly generated secrets
*/
```

---

## Q292: How do you implement rate limiting in ASP.NET Core?

**Answer:**

Rate limiting protects APIs from abuse, DoS attacks, and ensures fair resource allocation.

```csharp
// ============================================
// ASP.NET Core 7+ Built-in Rate Limiting
// ============================================

using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

// Fixed Window Rate Limiter
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.User.Identity?.Name ?? context.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 2
            });
    });

    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;

        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            await context.HttpContext.Response.WriteAsync(
                $"Too many requests. Retry after {retryAfter.TotalSeconds} seconds.",
                token);
        }
        else
        {
            await context.HttpContext.Response.WriteAsync(
                "Too many requests. Please try again later.",
                token);
        }
    };
});

var app = builder.Build();

app.UseRateLimiter();

app.MapGet("/api/data", () => "Success")
    .RequireRateLimiting("fixed");

app.Run();

// ============================================
// Sliding Window Rate Limiter
// ============================================

builder.Services.AddRateLimiter(options =>
{
    options.AddSlidingWindowLimiter("sliding", options =>
    {
        options.PermitLimit = 100;
        options.Window = TimeSpan.FromMinutes(1);
        options.SegmentsPerWindow = 6; // 10-second segments
        options.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        options.QueueLimit = 2;
    });
});

// Usage
app.MapGet("/api/products", () => "Products")
    .RequireRateLimiting("sliding");

// ============================================
// Token Bucket Rate Limiter
// ============================================

builder.Services.AddRateLimiter(options =>
{
    options.AddTokenBucketLimiter("token", options =>
    {
        options.TokenLimit = 100;
        options.ReplenishmentPeriod = TimeSpan.FromMinutes(1);
        options.TokensPerPeriod = 100;
        options.AutoReplenishment = true;
        options.QueueLimit = 5;
    });
});

// Usage
app.MapPost("/api/orders", () => "Order created")
    .RequireRateLimiting("token");

// ============================================
// Concurrency Limiter
// ============================================

builder.Services.AddRateLimiter(options =>
{
    options.AddConcurrencyLimiter("concurrency", options =>
    {
        options.PermitLimit = 10; // Max 10 concurrent requests
        options.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        options.QueueLimit = 5;
    });
});

// Usage - Limit concurrent uploads
app.MapPost("/api/upload", async (IFormFile file) =>
{
    // Process upload
    return "Uploaded";
})
.RequireRateLimiting("concurrency");

// ============================================
// Policy-Based Rate Limiting
// ============================================

builder.Services.AddRateLimiter(options =>
{
    // Anonymous users: stricter limits
    options.AddPolicy("anonymous", context =>
    {
        if (context.User.Identity?.IsAuthenticated != true)
        {
            return RateLimitPartition.GetFixedWindowLimiter("anonymous",
                _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 10,
                    Window = TimeSpan.FromMinutes(1)
                });
        }

        // Authenticated users: generous limits
        return RateLimitPartition.GetFixedWindowLimiter(
            context.User.Identity.Name,
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            });
    });

    // Premium users: unlimited
    options.AddPolicy("premium", context =>
    {
        if (context.User.IsInRole("Premium"))
        {
            return RateLimitPartition.GetNoLimiter("premium");
        }

        return RateLimitPartition.GetFixedWindowLimiter(
            context.User.Identity?.Name ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 50,
                Window = TimeSpan.FromMinutes(1)
            });
    });
});

// ============================================
// IP-Based Rate Limiting
// ============================================

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("ip-limiter", options =>
    {
        options.PermitLimit = 100;
        options.Window = TimeSpan.FromMinutes(1);
    }).WithPartitionBy(context =>
    {
        var ipAddress = context.Connection.RemoteIpAddress?.ToString();
        return ipAddress ?? "unknown";
    });
});

// ============================================
// Custom Rate Limiter Middleware
// ============================================

public class CustomRateLimitMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly int _requestLimit;
    private readonly TimeSpan _timeWindow;

    public CustomRateLimitMiddleware(
        RequestDelegate next,
        IMemoryCache cache,
        int requestLimit = 100,
        int windowMinutes = 1)
    {
        _next = next;
        _cache = cache;
        _requestLimit = requestLimit;
        _timeWindow = TimeSpan.FromMinutes(windowMinutes);
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var key = GetClientKey(context);
        var cacheKey = $"rate_limit:{key}";

        var requestCount = _cache.GetOrCreate(cacheKey, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = _timeWindow;
            return 0;
        });

        if (requestCount >= _requestLimit)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            context.Response.Headers.Add("Retry-After", _timeWindow.TotalSeconds.ToString());

            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                retryAfter = _timeWindow.TotalSeconds
            });
            return;
        }

        _cache.Set(cacheKey, requestCount + 1, _timeWindow);

        // Add rate limit headers
        context.Response.Headers.Add("X-RateLimit-Limit", _requestLimit.ToString());
        context.Response.Headers.Add("X-RateLimit-Remaining",
            (_requestLimit - requestCount - 1).ToString());

        await _next(context);
    }

    private string GetClientKey(HttpContext context)
    {
        // Use user ID if authenticated
        if (context.User.Identity?.IsAuthenticated == true)
        {
            return context.User.Identity.Name;
        }

        // Otherwise use IP address
        return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }
}

// ============================================
// Redis-Based Distributed Rate Limiting
// ============================================

public class RedisRateLimiter
{
    private readonly IConnectionMultiplexer _redis;
    private readonly int _maxRequests;
    private readonly TimeSpan _window;

    public RedisRateLimiter(
        IConnectionMultiplexer redis,
        int maxRequests,
        TimeSpan window)
    {
        _redis = redis;
        _maxRequests = maxRequests;
        _window = window;
    }

    public async Task<bool> IsAllowedAsync(string key)
    {
        var db = _redis.GetDatabase();
        var redisKey = $"rate_limit:{key}";

        // Sliding window log algorithm
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var windowStart = now - (long)_window.TotalMilliseconds;

        // Remove old entries
        await db.SortedSetRemoveRangeByScoreAsync(
            redisKey,
            double.NegativeInfinity,
            windowStart);

        // Count requests in window
        var count = await db.SortedSetLengthAsync(redisKey);

        if (count >= _maxRequests)
        {
            return false;
        }

        // Add current request
        await db.SortedSetAddAsync(redisKey, now.ToString(), now);
        await db.KeyExpireAsync(redisKey, _window);

        return true;
    }

    public async Task<RateLimitInfo> GetRateLimitInfoAsync(string key)
    {
        var db = _redis.GetDatabase();
        var redisKey = $"rate_limit:{key}";

        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var windowStart = now - (long)_window.TotalMilliseconds;

        await db.SortedSetRemoveRangeByScoreAsync(
            redisKey,
            double.NegativeInfinity,
            windowStart);

        var count = await db.SortedSetLengthAsync(redisKey);

        return new RateLimitInfo
        {
            Limit = _maxRequests,
            Remaining = Math.Max(0, _maxRequests - (int)count),
            ResetAt = DateTimeOffset.UtcNow.Add(_window)
        };
    }
}

public class RateLimitInfo
{
    public int Limit { get; set; }
    public int Remaining { get; set; }
    public DateTimeOffset ResetAt { get; set; }
}

// ============================================
// Action Filter for Rate Limiting
// ============================================

[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RateLimitAttribute : ActionFilterAttribute
{
    private readonly int _requestLimit;
    private readonly int _timeWindowMinutes;

    public RateLimitAttribute(int requestLimit = 100, int timeWindowMinutes = 1)
    {
        _requestLimit = requestLimit;
        _timeWindowMinutes = timeWindowMinutes;
    }

    public override async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var cache = context.HttpContext.RequestServices
            .GetRequiredService<IMemoryCache>();

        var key = GetClientKey(context.HttpContext);
        var cacheKey = $"rate_limit:{key}:{context.ActionDescriptor.Id}";

        var requestCount = cache.GetOrCreate(cacheKey, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow =
                TimeSpan.FromMinutes(_timeWindowMinutes);
            return 0;
        });

        if (requestCount >= _requestLimit)
        {
            context.Result = new ObjectResult(new
            {
                error = "Rate limit exceeded",
                limit = _requestLimit,
                windowMinutes = _timeWindowMinutes
            })
            {
                StatusCode = StatusCodes.Status429TooManyRequests
            };
            return;
        }

        cache.Set(cacheKey, requestCount + 1,
            TimeSpan.FromMinutes(_timeWindowMinutes));

        await next();
    }

    private string GetClientKey(HttpContext context)
    {
        return context.User.Identity?.Name
            ?? context.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";
    }
}

// Usage
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [RateLimit(requestLimit: 50, timeWindowMinutes: 1)]
    public IActionResult GetProducts()
    {
        return Ok("Products");
    }

    [HttpPost]
    [RateLimit(requestLimit: 10, timeWindowMinutes: 1)]
    public IActionResult CreateProduct()
    {
        return Ok("Created");
    }
}

/*
Rate Limiting Best Practices:

1. ✅ Implement rate limiting on all public APIs
2. ✅ Use different limits for different endpoints
3. ✅ Provide clear error messages with Retry-After headers
4. ✅ Use distributed caching (Redis) for scaled applications
5. ✅ Implement sliding window for accurate limiting
6. ✅ Allow higher limits for authenticated users
7. ✅ Monitor and log rate limit hits
8. ✅ Implement graceful degradation
9. ✅ Consider IP-based and user-based limiting
10. ✅ Test rate limiting in load testing

Rate Limiting Algorithms:

1. Fixed Window:
   - Simple, memory efficient
   - Can allow burst at window boundaries

2. Sliding Window:
   - More accurate than fixed window
   - Higher memory usage

3. Token Bucket:
   - Allows burst traffic
   - Good for variable rate limits

4. Concurrency Limiter:
   - Limits simultaneous requests
   - Good for resource-intensive operations

Response Headers:
- X-RateLimit-Limit: Maximum requests allowed
- X-RateLimit-Remaining: Requests remaining
- X-RateLimit-Reset: When the limit resets
- Retry-After: Seconds until retry allowed
*/
```

---

## Q293: How do you implement OAuth 2.0 and OpenID Connect authentication in ASP.NET Core?

**Answer:**

OAuth 2.0 provides authorization, while OpenID Connect adds authentication on top of OAuth 2.0.

```csharp
// ============================================
// Program.cs - OAuth 2.0 / OpenID Connect
// ============================================

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// JWT Bearer Authentication (for APIs)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = "https://your-identity-provider.com";
        options.Audience = "your-api-identifier";

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.Zero
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
            }
        };
    });

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.Run();

// ============================================
// OpenID Connect for Web Apps
// ============================================

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie()
.AddOpenIdConnect(options =>
{
    options.Authority = "https://your-identity-provider.com";
    options.ClientId = "your-client-id";
    options.ClientSecret = "your-client-secret";
    options.ResponseType = "code";
    options.SaveTokens = true;
    options.GetClaimsFromUserInfoEndpoint = true;

    options.Scope.Add("openid");
    options.Scope.Add("profile");
    options.Scope.Add("email");

    options.Events = new OpenIdConnectEvents
    {
        OnRedirectToIdentityProvider = context =>
        {
            context.ProtocolMessage.SetParameter("audience", "your-api-identifier");
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            // Custom claims transformation
            var claimsIdentity = (ClaimsIdentity)context.Principal.Identity;
            claimsIdentity.AddClaim(new Claim("custom-claim", "value"));
            return Task.CompletedTask;
        }
    };
});

// ============================================
// Auth0 Integration
// ============================================

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie()
.AddOpenIdConnect("Auth0", options =>
{
    options.Authority = $"https://{builder.Configuration["Auth0:Domain"]}";
    options.ClientId = builder.Configuration["Auth0:ClientId"];
    options.ClientSecret = builder.Configuration["Auth0:ClientSecret"];
    options.ResponseType = OpenIdConnectResponseType.Code;
    options.CallbackPath = new PathString("/callback");

    options.ClaimsIssuer = "Auth0";
    options.SaveTokens = true;

    options.Events = new OpenIdConnectEvents
    {
        OnRedirectToIdentityProviderForSignOut = (context) =>
        {
            var logoutUri = $"https://{builder.Configuration["Auth0:Domain"]}/v2/logout?client_id={builder.Configuration["Auth0:ClientId"]}";

            var postLogoutUri = context.Properties.RedirectUri;
            if (!string.IsNullOrEmpty(postLogoutUri))
            {
                if (postLogoutUri.StartsWith("/"))
                {
                    var request = context.Request;
                    postLogoutUri = request.Scheme + "://" + request.Host + request.PathBase + postLogoutUri;
                }
                logoutUri += $"&returnTo={ Uri.EscapeDataString(postLogoutUri)}";
            }

            context.Response.Redirect(logoutUri);
            context.HandleResponse();

            return Task.CompletedTask;
        }
    };
});

// ============================================
// Azure AD B2C Integration
// ============================================

builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApp(options =>
    {
        builder.Configuration.Bind("AzureAdB2C", options);
        options.Events = new OpenIdConnectEvents
        {
            OnRemoteFailure = context =>
            {
                context.HandleResponse();
                context.Response.Redirect("/Error");
                return Task.CompletedTask;
            }
        };
    });

// appsettings.json for Azure AD B2C
{
  "AzureAdB2C": {
    "Instance": "https://<your-tenant>.b2clogin.com",
    "Domain": "<your-tenant>.onmicrosoft.com",
    "ClientId": "<your-client-id>",
    "ClientSecret": "<your-client-secret>",
    "CallbackPath": "/signin-oidc",
    "SignUpSignInPolicyId": "B2C_1_signupsignin"
  }
}

// ============================================
// Protected API Endpoint
// ============================================

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SecureDataController : ControllerBase
{
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public IActionResult GetAdminData()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var email = User.FindFirst(ClaimTypes.Email)?.Value;

        return Ok(new { userId, email });
    }

    [HttpGet("user")]
    public IActionResult GetUserData()
    {
        var claims = User.Claims.Select(c => new { c.Type, c.Value });
        return Ok(claims);
    }
}

// ============================================
// Custom OAuth Client Service
// ============================================

public class OAuthClientService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    public OAuthClientService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public async Task<TokenResponse> GetTokenAsync(string username, string password)
    {
        var tokenEndpoint = _configuration["OAuth:TokenEndpoint"];
        var clientId = _configuration["OAuth:ClientId"];
        var clientSecret = _configuration["OAuth:ClientSecret"];

        var requestBody = new Dictionary<string, string>
        {
            { "grant_type", "password" },
            { "username", username },
            { "password", password },
            { "client_id", clientId },
            { "client_secret", clientSecret },
            { "scope", "openid profile email" }
        };

        var response = await _httpClient.PostAsync(
            tokenEndpoint,
            new FormUrlEncodedContent(requestBody));

        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<TokenResponse>(content);
    }

    public async Task<TokenResponse> RefreshTokenAsync(string refreshToken)
    {
        var tokenEndpoint = _configuration["OAuth:TokenEndpoint"];
        var clientId = _configuration["OAuth:ClientId"];
        var clientSecret = _configuration["OAuth:ClientSecret"];

        var requestBody = new Dictionary<string, string>
        {
            { "grant_type", "refresh_token" },
            { "refresh_token", refreshToken },
            { "client_id", clientId },
            { "client_secret", clientSecret }
        };

        var response = await _httpClient.PostAsync(
            tokenEndpoint,
            new FormUrlEncodedContent(requestBody));

        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<TokenResponse>(content);
    }
}

public class TokenResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; }

    [JsonPropertyName("refresh_token")]
    public string RefreshToken { get; set; }

    [JsonPropertyName("expires_in")]
    public int ExpiresIn { get; set; }

    [JsonPropertyName("token_type")]
    public string TokenType { get; set; }
}

// ============================================
// Token Management Middleware
// ============================================

public class TokenRefreshMiddleware
{
    private readonly RequestDelegate _next;

    public TokenRefreshMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        OAuthClientService oauthService)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var accessToken = await context.GetTokenAsync("access_token");
            var refreshToken = await context.GetTokenAsync("refresh_token");
            var expiresAt = await context.GetTokenAsync("expires_at");

            if (DateTime.Parse(expiresAt) <= DateTime.UtcNow.AddMinutes(5))
            {
                // Token is about to expire, refresh it
                var newTokens = await oauthService.RefreshTokenAsync(refreshToken);

                // Update tokens
                var authInfo = await context.AuthenticateAsync();
                authInfo.Properties.UpdateTokenValue("access_token", newTokens.AccessToken);
                authInfo.Properties.UpdateTokenValue("refresh_token", newTokens.RefreshToken);
                authInfo.Properties.UpdateTokenValue("expires_at",
                    DateTime.UtcNow.AddSeconds(newTokens.ExpiresIn).ToString("o"));

                await context.SignInAsync(authInfo.Principal, authInfo.Properties);
            }
        }

        await _next(context);
    }
}

/*
OAuth 2.0 / OpenID Connect Best Practices:

1. ✅ Use HTTPS for all OAuth endpoints
2. ✅ Validate token issuer, audience, and expiration
3. ✅ Store tokens securely
4. ✅ Implement token refresh before expiration
5. ✅ Use state parameter to prevent CSRF
6. ✅ Implement proper logout
7. ✅ Use PKCE for public clients
8. ✅ Validate redirect URIs
9. ✅ Implement proper error handling
10. ✅ Use appropriate scopes

OAuth 2.0 Grant Types:
1. Authorization Code (recommended for web apps)
2. Client Credentials (for service-to-service)
3. Refresh Token (for token renewal)
4. Resource Owner Password (legacy, avoid)

OpenID Connect Scopes:
- openid: Required for OIDC
- profile: User profile information
- email: User email address
- offline_access: Refresh token
*/
```

---

## Q294: How do you implement API key authentication in ASP.NET Core?

**Answer:**

API key authentication provides a simple way to authenticate API clients using unique keys.

```csharp
// ============================================
// API Key Authentication Handler
// ============================================

using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

public class ApiKeyAuthenticationHandler : AuthenticationHandler<ApiKeyAuthenticationOptions>
{
    private const string ApiKeyHeaderName = "X-API-Key";

    public ApiKeyAuthenticationHandler(
        IOptionsMonitor<ApiKeyAuthenticationOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        ISystemClock clock)
        : base(options, logger, encoder, clock)
    {
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(ApiKeyHeaderName, out var apiKeyHeaderValues))
        {
            return AuthenticateResult.NoResult();
        }

        var providedApiKey = apiKeyHeaderValues.FirstOrDefault();

        if (string.IsNullOrWhiteSpace(providedApiKey))
        {
            return AuthenticateResult.Fail("Invalid API Key");
        }

        var apiKey = await Options.ApiKeyProvider.ValidateAsync(providedApiKey);

        if (apiKey == null)
        {
            return AuthenticateResult.Fail("Invalid API Key");
        }

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, apiKey.Owner),
            new Claim("ApiKeyId", apiKey.Id.ToString())
        };

        claims.AddRange(apiKey.Roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);

        return AuthenticateResult.Success(ticket);
    }
}

public class ApiKeyAuthenticationOptions : AuthenticationSchemeOptions
{
    public const string DefaultScheme = "ApiKey";
    public string Scheme => DefaultScheme;
    public IApiKeyProvider ApiKeyProvider { get; set; }
}

// ============================================
// API Key Provider Interface
// ============================================

public interface IApiKeyProvider
{
    Task<ApiKey> ValidateAsync(string key);
    Task<ApiKey> CreateAsync(string owner, IEnumerable<string> roles);
    Task RevokeAsync(string key);
}

public class ApiKey
{
    public Guid Id { get; set; }
    public string Key { get; set; }
    public string Owner { get; set; }
    public List<string> Roles { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public bool IsActive { get; set; }
}

// ============================================
// In-Memory API Key Provider
// ============================================

public class InMemoryApiKeyProvider : IApiKeyProvider
{
    private readonly List<ApiKey> _apiKeys = new();
    private readonly ILogger<InMemoryApiKeyProvider> _logger;

    public InMemoryApiKeyProvider(ILogger<InMemoryApiKeyProvider> logger)
    {
        _logger = logger;
    }

    public Task<ApiKey> ValidateAsync(string key)
    {
        var apiKey = _apiKeys.FirstOrDefault(k =>
            k.Key == key &&
            k.IsActive &&
            (k.ExpiryDate == null || k.ExpiryDate > DateTime.UtcNow));

        if (apiKey != null)
        {
            _logger.LogInformation("API Key validated for {Owner}", apiKey.Owner);
        }

        return Task.FromResult(apiKey);
    }

    public Task<ApiKey> CreateAsync(string owner, IEnumerable<string> roles)
    {
        var apiKey = new ApiKey
        {
            Id = Guid.NewGuid(),
            Key = GenerateApiKey(),
            Owner = owner,
            Roles = roles.ToList(),
            CreatedDate = DateTime.UtcNow,
            IsActive = true
        };

        _apiKeys.Add(apiKey);
        _logger.LogInformation("API Key created for {Owner}", owner);

        return Task.FromResult(apiKey);
    }

    public Task RevokeAsync(string key)
    {
        var apiKey = _apiKeys.FirstOrDefault(k => k.Key == key);
        if (apiKey != null)
        {
            apiKey.IsActive = false;
            _logger.LogInformation("API Key revoked for {Owner}", apiKey.Owner);
        }

        return Task.CompletedTask;
    }

    private string GenerateApiKey()
    {
        var randomBytes = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomBytes);
        }
        return Convert.ToBase64String(randomBytes);
    }
}

// ============================================
// Database API Key Provider
// ============================================

public class DatabaseApiKeyProvider : IApiKeyProvider
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DatabaseApiKeyProvider> _logger;

    public DatabaseApiKeyProvider(
        ApplicationDbContext context,
        ILogger<DatabaseApiKeyProvider> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<ApiKey> ValidateAsync(string key)
    {
        var hashedKey = HashApiKey(key);

        var apiKey = await _context.ApiKeys
            .Where(k => k.KeyHash == hashedKey &&
                       k.IsActive &&
                       (k.ExpiryDate == null || k.ExpiryDate > DateTime.UtcNow))
            .FirstOrDefaultAsync();

        return apiKey;
    }

    public async Task<ApiKey> CreateAsync(string owner, IEnumerable<string> roles)
    {
        var key = GenerateApiKey();
        var apiKey = new ApiKey
        {
            Id = Guid.NewGuid(),
            KeyHash = HashApiKey(key),
            Owner = owner,
            Roles = roles.ToList(),
            CreatedDate = DateTime.UtcNow,
            IsActive = true
        };

        _context.ApiKeys.Add(apiKey);
        await _context.SaveChangesAsync();

        // Return the plain key only once
        apiKey.Key = key;
        return apiKey;
    }

    public async Task RevokeAsync(string key)
    {
        var hashedKey = HashApiKey(key);
        var apiKey = await _context.ApiKeys
            .FirstOrDefaultAsync(k => k.KeyHash == hashedKey);

        if (apiKey != null)
        {
            apiKey.IsActive = false;
            await _context.SaveChangesAsync();
        }
    }

    private string HashApiKey(string key)
    {
        using var sha256 = SHA256.Create();
        var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(key));
        return Convert.ToBase64String(hashBytes);
    }

    private string GenerateApiKey()
    {
        var randomBytes = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomBytes);
        }
        return Convert.ToBase64String(randomBytes);
    }
}

// ============================================
// Program.cs - Registration
// ============================================

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IApiKeyProvider, InMemoryApiKeyProvider>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = ApiKeyAuthenticationOptions.DefaultScheme;
    options.DefaultChallengeScheme = ApiKeyAuthenticationOptions.DefaultScheme;
})
.AddScheme<ApiKeyAuthenticationOptions, ApiKeyAuthenticationHandler>(
    ApiKeyAuthenticationOptions.DefaultScheme,
    options =>
    {
        options.ApiKeyProvider = builder.Services
            .BuildServiceProvider()
            .GetRequiredService<IApiKeyProvider>();
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.Run();

// ============================================
// Protected API Endpoints
// ============================================

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetProducts()
    {
        var owner = User.Identity.Name;
        return Ok($"Products for {owner}");
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public IActionResult CreateProduct([FromBody] Product product)
    {
        return Ok("Product created");
    }
}

// ============================================
// API Key Management Controller
// ============================================

[ApiController]
[Route("api/[controller]")]
public class ApiKeysController : ControllerBase
{
    private readonly IApiKeyProvider _apiKeyProvider;

    public ApiKeysController(IApiKeyProvider apiKeyProvider)
    {
        _apiKeyProvider = apiKeyProvider;
    }

    [HttpPost]
    public async Task<IActionResult> CreateApiKey([FromBody] CreateApiKeyRequest request)
    {
        var apiKey = await _apiKeyProvider.CreateAsync(
            request.Owner,
            request.Roles);

        return Ok(new
        {
            apiKey.Id,
            apiKey.Key, // Only returned once
            apiKey.Owner,
            apiKey.CreatedDate
        });
    }

    [HttpDelete("{key}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RevokeApiKey(string key)
    {
        await _apiKeyProvider.RevokeAsync(key);
        return NoContent();
    }
}

public class CreateApiKeyRequest
{
    public string Owner { get; set; }
    public List<string> Roles { get; set; }
}

// ============================================
// Rate Limiting per API Key
// ============================================

public class ApiKeyRateLimitMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;

    public ApiKeyRateLimitMiddleware(RequestDelegate next, IMemoryCache cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var apiKeyId = context.User.FindFirst("ApiKeyId")?.Value;
            var cacheKey = $"rate_limit_api_key_{apiKeyId}";

            var requestCount = _cache.GetOrCreate(cacheKey, entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1);
                return 0;
            });

            if (requestCount >= 100) // 100 requests per minute
            {
                context.Response.StatusCode = 429;
                await context.Response.WriteAsJsonAsync(new
                {
                    error = "Rate limit exceeded for this API key"
                });
                return;
            }

            _cache.Set(cacheKey, requestCount + 1, TimeSpan.FromMinutes(1));
        }

        await _next(context);
    }
}

/*
API Key Authentication Best Practices:

1. ✅ Store hashed keys in database, not plain text
2. ✅ Use HTTPS to transmit API keys
3. ✅ Implement key rotation
4. ✅ Set expiration dates for keys
5. ✅ Rate limit per API key
6. ✅ Log API key usage
7. ✅ Allow key revocation
8. ✅ Use strong random key generation
9. ✅ Implement role-based access with keys
10. ✅ Show the key only once at creation

API Key Storage:
- Never log API keys
- Hash keys before storing
- Use secure random generation
- Implement key rotation policies

Security Considerations:
- API keys are less secure than OAuth
- Best for server-to-server communication
- Combine with IP whitelisting
- Monitor for unusual usage patterns
*/
```

---

## Q295: How do you implement input validation and sanitization in ASP.NET Core?

**Answer:**

Proper input validation and sanitization prevent injection attacks and ensure data integrity.

```csharp
// ============================================
// Model Validation with Data Annotations
// ============================================

public class CreateUserRequest
{
    [Required(ErrorMessage = "Username is required")]
    [StringLength(50, MinimumLength = 3,
        ErrorMessage = "Username must be between 3 and 50 characters")]
    [RegularExpression(@"^[a-zA-Z0-9_]+$",
        ErrorMessage = "Username can only contain letters, numbers, and underscores")]
    public string Username { get; set; }

    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [StringLength(100, MinimumLength = 8,
        ErrorMessage = "Password must be at least 8 characters")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]",
        ErrorMessage = "Password must contain uppercase, lowercase, digit, and special character")]
    public string Password { get; set; }

    [Range(18, 120, ErrorMessage = "Age must be between 18 and 120")]
    public int Age { get; set; }

    [Url(ErrorMessage = "Invalid URL format")]
    public string Website { get; set; }

    [Phone(ErrorMessage = "Invalid phone number")]
    public string PhoneNumber { get; set; }
}

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpPost]
    public IActionResult CreateUser([FromBody] CreateUserRequest request)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage);

            return BadRequest(new { errors });
        }

        // Process valid request
        return Ok("User created");
    }
}

// ============================================
// Custom Validation Attributes
// ============================================

public class NoSpecialCharactersAttribute : ValidationAttribute
{
    protected override ValidationResult IsValid(
        object value,
        ValidationContext validationContext)
    {
        if (value is string str)
        {
            if (Regex.IsMatch(str, @"[<>""'%;()&+]"))
            {
                return new ValidationResult(
                    "Input contains invalid special characters");
            }
        }

        return ValidationResult.Success;
    }
}

public class SafeHtmlAttribute : ValidationAttribute
{
    protected override ValidationResult IsValid(
        object value,
        ValidationContext validationContext)
    {
        if (value is string html)
        {
            var sanitizer = new HtmlSanitizer();
            var sanitized = sanitizer.Sanitize(html);

            if (html != sanitized)
            {
                return new ValidationResult(
                    "Input contains potentially dangerous HTML");
            }
        }

        return ValidationResult.Success;
    }
}

public class CreatePostRequest
{
    [Required]
    [NoSpecialCharacters]
    public string Title { get; set; }

    [Required]
    [SafeHtml]
    public string Content { get; set; }
}

// ============================================
// FluentValidation
// ============================================

using FluentValidation;

public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required")
            .Length(3, 50).WithMessage("Username must be between 3 and 50 characters")
            .Matches(@"^[a-zA-Z0-9_]+$")
                .WithMessage("Username can only contain letters, numbers, and underscores")
            .Must(NotContainBadWords).WithMessage("Username contains inappropriate content");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MustAsync(BeUniqueEmail).WithMessage("Email already exists");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters")
            .Matches(@"[A-Z]").WithMessage("Password must contain uppercase letter")
            .Matches(@"[a-z]").WithMessage("Password must contain lowercase letter")
            .Matches(@"\d").WithMessage("Password must contain digit")
            .Matches(@"[@$!%*?&]").WithMessage("Password must contain special character");

        RuleFor(x => x.Age)
            .InclusiveBetween(18, 120).WithMessage("Age must be between 18 and 120");
    }

    private bool NotContainBadWords(string username)
    {
        var badWords = new[] { "admin", "root", "system" };
        return !badWords.Any(word =>
            username.Contains(word, StringComparison.OrdinalIgnoreCase));
    }

    private async Task<bool> BeUniqueEmail(string email, CancellationToken cancellationToken)
    {
        // Check database for existing email
        return true; // Placeholder
    }
}

// Register FluentValidation
builder.Services.AddValidatorsFromAssemblyContaining<CreateUserRequestValidator>();
builder.Services.AddFluentValidationAutoValidation();

// ============================================
// Input Sanitization Service
// ============================================

public interface IInputSanitizer
{
    string SanitizeHtml(string html);
    string SanitizeString(string input);
    string RemoveScriptTags(string input);
}

public class InputSanitizer : IInputSanitizer
{
    private readonly HtmlSanitizer _htmlSanitizer;

    public InputSanitizer()
    {
        _htmlSanitizer = new HtmlSanitizer();

        // Configure allowed tags
        _htmlSanitizer.AllowedTags.Clear();
        _htmlSanitizer.AllowedTags.Add("p");
        _htmlSanitizer.AllowedTags.Add("br");
        _htmlSanitizer.AllowedTags.Add("strong");
        _htmlSanitizer.AllowedTags.Add("em");
        _htmlSanitizer.AllowedTags.Add("a");

        // Configure allowed attributes
        _htmlSanitizer.AllowedAttributes.Clear();
        _htmlSanitizer.AllowedAttributes.Add("href");

        // Configure allowed schemes
        _htmlSanitizer.AllowedSchemes.Clear();
        _htmlSanitizer.AllowedSchemes.Add("http");
        _htmlSanitizer.AllowedSchemes.Add("https");
    }

    public string SanitizeHtml(string html)
    {
        if (string.IsNullOrWhiteSpace(html))
        {
            return html;
        }

        return _htmlSanitizer.Sanitize(html);
    }

    public string SanitizeString(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return input;
        }

        // Remove control characters
        input = Regex.Replace(input, @"[\x00-\x1F\x7F]", "");

        // Remove potentially dangerous characters
        input = input.Replace("<", "&lt;")
                     .Replace(">", "&gt;")
                     .Replace("\"", "&quot;")
                     .Replace("'", "&#x27;")
                     .Replace("/", "&#x2F;");

        return input;
    }

    public string RemoveScriptTags(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return input;
        }

        return Regex.Replace(
            input,
            @"<script[^>]*>.*?</script>",
            "",
            RegexOptions.IgnoreCase | RegexOptions.Singleline);
    }
}

// ============================================
// SQL Injection Prevention
// ============================================

public class UserService
{
    private readonly ApplicationDbContext _context;

    public UserService(ApplicationDbContext context)
    {
        _context = context;
    }

    // ✅ SAFE: Parameterized query via LINQ
    public async Task<User> GetUserSafeAsync(string username)
    {
        return await _context.Users
            .Where(u => u.Username == username)
            .FirstOrDefaultAsync();
    }

    // ✅ SAFE: FromSqlInterpolated
    public async Task<List<User>> SearchUsersSafeAsync(string searchTerm)
    {
        return await _context.Users
            .FromSqlInterpolated($"SELECT * FROM Users WHERE Username LIKE {searchTerm + "%"}")
            .ToListAsync();
    }

    // ❌ UNSAFE: String concatenation (NEVER DO THIS)
    public async Task<User> GetUserUnsafeAsync(string username)
    {
        // VULNERABLE TO SQL INJECTION
        var query = $"SELECT * FROM Users WHERE Username = '{username}'";
        return await _context.Users.FromSqlRaw(query).FirstOrDefaultAsync();
    }
}

// ============================================
// Path Traversal Prevention
// ============================================

public class FileService
{
    private readonly string _basePath;

    public FileService(IWebHostEnvironment env)
    {
        _basePath = Path.Combine(env.ContentRootPath, "uploads");
    }

    public async Task<byte[]> ReadFileSafeAsync(string filename)
    {
        // Validate and sanitize filename
        if (string.IsNullOrWhiteSpace(filename))
        {
            throw new ArgumentException("Filename cannot be empty");
        }

        // Remove path traversal attempts
        filename = Path.GetFileName(filename);

        // Construct full path
        var fullPath = Path.Combine(_basePath, filename);

        // Ensure the resolved path is within the base directory
        var normalizedPath = Path.GetFullPath(fullPath);
        var normalizedBase = Path.GetFullPath(_basePath);

        if (!normalizedPath.StartsWith(normalizedBase))
        {
            throw new UnauthorizedAccessException("Access denied");
        }

        // Validate file exists
        if (!File.Exists(normalizedPath))
        {
            throw new FileNotFoundException("File not found");
        }

        return await File.ReadAllBytesAsync(normalizedPath);
    }
}

// ============================================
// Command Injection Prevention
// ============================================

public class ProcessService
{
    // ✅ SAFE: Whitelisted commands
    public async Task<string> ExecuteSafeCommandAsync(string command, string[] args)
    {
        var allowedCommands = new HashSet<string>
        {
            "ping",
            "tracert",
            "nslookup"
        };

        if (!allowedCommands.Contains(command.ToLowerInvariant()))
        {
            throw new UnauthorizedAccessException("Command not allowed");
        }

        // Validate and sanitize arguments
        var sanitizedArgs = args
            .Select(arg => Regex.Replace(arg, @"[^a-zA-Z0-9.-]", ""))
            .ToArray();

        var processStartInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = string.Join(" ", sanitizedArgs),
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(processStartInfo);
        return await process.StandardOutput.ReadToEndAsync();
    }
}

// ============================================
// Action Filter for Input Validation
// ============================================

public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
        {
            var errors = context.ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                );

            context.Result = new BadRequestObjectResult(new
            {
                message = "Validation failed",
                errors
            });
        }
    }
}

// Global registration
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidateModelAttribute>();
});

/*
Input Validation Best Practices:

1. ✅ Validate all input (client and server-side)
2. ✅ Use whitelist validation when possible
3. ✅ Sanitize HTML input
4. ✅ Use parameterized queries for databases
5. ✅ Validate file uploads (type, size, content)
6. ✅ Implement path traversal prevention
7. ✅ Encode output to prevent XSS
8. ✅ Validate redirects and forwards
9. ✅ Use strong type validation
10. ✅ Log validation failures

Common Validation Patterns:
- Data Annotations for simple validation
- FluentValidation for complex rules
- Custom validators for business logic
- Action filters for cross-cutting concerns

Injection Prevention:
- SQL Injection: Use parameterized queries
- XSS: Encode output, sanitize HTML
- Command Injection: Whitelist commands
- Path Traversal: Validate file paths
- LDAP Injection: Use parameterized queries
*/
```

---

## Q296: How do you implement secure logging and monitoring in ASP.NET Core?

**Answer:**

Secure logging and monitoring help detect security incidents while protecting sensitive data.

```csharp
// ============================================
// Secure Logging Configuration
// ============================================

using Serilog;
using Serilog.Events;
using Serilog.Filters;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("System", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithEnvironmentName()
    .Filter.ByExcluding(Matching.WithProperty<string>("RequestPath",
        path => path.Contains("/health")))
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        "logs/app-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

builder.Host.UseSerilog();

var app = builder.Build();
app.Run();

// ============================================
// Sensitive Data Filtering
// ============================================

public class SensitiveDataFilter : ILogEventEnricher
{
    private static readonly HashSet<string> SensitiveProperties = new(StringComparer.OrdinalIgnoreCase)
    {
        "password", "token", "apikey", "secret", "authorization",
        "creditcard", "ssn", "pin"
    };

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        var properties = logEvent.Properties
            .Where(p => SensitiveProperties.Any(s =>
                p.Key.Contains(s, StringComparison.OrdinalIgnoreCase)))
            .ToList();

        foreach (var property in properties)
        {
            logEvent.RemovePropertyIfPresent(property.Key);
            logEvent.AddOrUpdateProperty(
                propertyFactory.CreateProperty(property.Key, "***REDACTED***"));
        }
    }
}

// Usage
Log.Logger = new LoggerConfiguration()
    .Enrich.With<SensitiveDataFilter>()
    .CreateLogger();

// ============================================
// Security Event Logging
// ============================================

public interface ISecurityLogger
{
    void LogSuccessfulLogin(string username, string ipAddress);
    void LogFailedLogin(string username, string ipAddress, string reason);
    void LogUnauthorizedAccess(string username, string resource);
    void LogSuspiciousActivity(string username, string activity, string details);
}

public class SecurityLogger : ISecurityLogger
{
    private readonly ILogger<SecurityLogger> _logger;

    public SecurityLogger(ILogger<SecurityLogger> logger)
    {
        _logger = logger;
    }

    public void LogSuccessfulLogin(string username, string ipAddress)
    {
        _logger.LogInformation(
            "SECURITY: Successful login for user {Username} from IP {IpAddress}",
            username, ipAddress);
    }

    public void LogFailedLogin(string username, string ipAddress, string reason)
    {
        _logger.LogWarning(
            "SECURITY: Failed login attempt for user {Username} from IP {IpAddress}. Reason: {Reason}",
            username, ipAddress, reason);
    }

    public void LogUnauthorizedAccess(string username, string resource)
    {
        _logger.LogWarning(
            "SECURITY: Unauthorized access attempt by {Username} to resource {Resource}",
            username, resource);
    }

    public void LogSuspiciousActivity(string username, string activity, string details)
    {
        _logger.LogWarning(
            "SECURITY: Suspicious activity detected. User: {Username}, Activity: {Activity}, Details: {Details}",
            username, activity, details);
    }
}

// ============================================
// Request Logging Middleware
// ============================================

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
        var sw = Stopwatch.StartNew();

        try
        {
            await _next(context);
        }
        finally
        {
            sw.Stop();

            var logLevel = context.Response.StatusCode >= 500
                ? LogLevel.Error
                : context.Response.StatusCode >= 400
                    ? LogLevel.Warning
                    : LogLevel.Information;

            _logger.Log(logLevel,
                "HTTP {Method} {Path} responded {StatusCode} in {ElapsedMilliseconds}ms from {IpAddress}",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode,
                sw.ElapsedMilliseconds,
                context.Connection.RemoteIpAddress);
        }
    }
}

// ============================================
// Audit Logging
// ============================================

public interface IAuditLogger
{
    Task LogAsync(AuditEvent auditEvent);
}

public class AuditEvent
{
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string UserId { get; set; }
    public string Username { get; set; }
    public string Action { get; set; }
    public string Resource { get; set; }
    public string IpAddress { get; set; }
    public bool Success { get; set; }
    public string Details { get; set; }
}

public class DatabaseAuditLogger : IAuditLogger
{
    private readonly ApplicationDbContext _context;

    public DatabaseAuditLogger(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task LogAsync(AuditEvent auditEvent)
    {
        _context.AuditLogs.Add(auditEvent);
        await _context.SaveChangesAsync();
    }
}

// ============================================
// Audit Action Filter
// ============================================

public class AuditAttribute : ActionFilterAttribute
{
    private readonly string _action;

    public AuditAttribute(string action)
    {
        _action = action;
    }

    public override async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var auditLogger = context.HttpContext.RequestServices
            .GetRequiredService<IAuditLogger>();

        var resultContext = await next();

        var auditEvent = new AuditEvent
        {
            UserId = context.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value,
            Username = context.HttpContext.User.Identity?.Name,
            Action = _action,
            Resource = context.HttpContext.Request.Path,
            IpAddress = context.HttpContext.Connection.RemoteIpAddress?.ToString(),
            Success = resultContext.Exception == null,
            Details = resultContext.Exception?.Message
        };

        await auditLogger.LogAsync(auditEvent);
    }
}

// Usage
[HttpDelete("{id}")]
[Audit("Delete User")]
public async Task<IActionResult> DeleteUser(int id)
{
    // Delete user logic
    return NoContent();
}

// ============================================
// Monitoring and Alerting
// ============================================

public class SecurityMonitoringService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SecurityMonitoringService> _logger;

    public SecurityMonitoringService(
        IServiceProvider serviceProvider,
        ILogger<SecurityMonitoringService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                // Check for failed login attempts
                var recentFailedLogins = await context.AuditLogs
                    .Where(a => a.Action == "Login" &&
                               !a.Success &&
                               a.Timestamp > DateTime.UtcNow.AddMinutes(-5))
                    .GroupBy(a => a.IpAddress)
                    .Select(g => new { IpAddress = g.Key, Count = g.Count() })
                    .Where(x => x.Count > 5)
                    .ToListAsync(stoppingToken);

                foreach (var suspicious in recentFailedLogins)
                {
                    _logger.LogWarning(
                        "SECURITY ALERT: {Count} failed login attempts from IP {IpAddress} in last 5 minutes",
                        suspicious.Count, suspicious.IpAddress);

                    // Trigger alert (email, Slack, etc.)
                }

                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in security monitoring");
            }
        }
    }
}

// ============================================
// Application Insights Integration
// ============================================

builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = true;
});

builder.Services.AddApplicationInsightsTelemetryProcessor<SensitiveDataTelemetryProcessor>();

public class SensitiveDataTelemetryProcessor : ITelemetryProcessor
{
    private ITelemetryProcessor Next { get; set; }

    public SensitiveDataTelemetryProcessor(ITelemetryProcessor next)
    {
        Next = next;
    }

    public void Process(ITelemetry item)
    {
        if (item is RequestTelemetry request)
        {
            // Remove sensitive headers
            if (request.Properties.ContainsKey("Authorization"))
            {
                request.Properties["Authorization"] = "***REDACTED***";
            }
        }

        Next.Process(item);
    }
}

/*
Secure Logging Best Practices:

1. ✅ Never log sensitive data (passwords, tokens, PII)
2. ✅ Log security events (login, logout, access attempts)
3. ✅ Include context (user, IP address, timestamp)
4. ✅ Use structured logging
5. ✅ Implement log retention policies
6. ✅ Protect log files with appropriate permissions
7. ✅ Monitor logs for suspicious patterns
8. ✅ Implement alerting for security events
9. ✅ Use centralized logging in production
10. ✅ Comply with data privacy regulations

What to Log:
- Authentication events (success/failure)
- Authorization failures
- Input validation failures
- Security configuration changes
- Elevated privilege use
- Data access and modifications

What NOT to Log:
- Passwords or password hashes
- Session tokens or API keys
- Credit card numbers
- Social security numbers
- Personal health information
*/
```

---

## Q297: How do you manage dependency and package security in ASP.NET Core?

**Answer:**

Managing dependency security prevents vulnerabilities from third-party packages.

```csharp
// ============================================
// NuGet Security Scanning
// ============================================

// Install security scanning tools
// dotnet tool install --global dotnet-outdated-tool
// dotnet tool install --global dotnet-audit

// Check for outdated packages
// dotnet outdated

// Check for vulnerable packages
// dotnet list package --vulnerable

// Update packages
// dotnet outdated --upgrade

// ============================================
// .csproj Configuration
// ============================================

<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest</AnalysisLevel>

    <!-- Enable package vulnerability auditing -->
    <NuGetAudit>true</NuGetAudit>
    <NuGetAuditMode>all</NuGetAuditMode>
    <NuGetAuditLevel>low</NuGetAuditLevel>
  </PropertyGroup>

  <ItemGroup>
    <!-- Specify exact versions for security-critical packages -->
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />

    <!-- Avoid wildcards in production -->
    <!-- <PackageReference Include="SomePackage" Version="*" /> ❌ -->
  </ItemGroup>
</Project>

// ============================================
// Package Source Configuration
// ============================================

// nuget.config
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <!-- Only use trusted sources -->
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <!-- For private packages -->
    <add key="CompanyFeed" value="https://pkgs.dev.azure.com/company/_packaging/feed/nuget/v3/index.json" />
  </packageSources>

  <packageSourceCredentials>
    <CompanyFeed>
      <add key="Username" value="%NUGET_USERNAME%" />
      <add key="ClearTextPassword" value="%NUGET_PASSWORD%" />
    </CompanyFeed>
  </packageSourceCredentials>

  <config>
    <add key="signatureValidationMode" value="require" />
  </config>
</configuration>

// ============================================
// Dependency Scanning Service
// ============================================

public interface IDependencyScanner
{
    Task<List<VulnerablePackage>> ScanAsync();
}

public class VulnerablePackage
{
    public string PackageName { get; set; }
    public string CurrentVersion { get; set; }
    public string VulnerabilityId { get; set; }
    public string Severity { get; set; }
    public string FixedVersion { get; set; }
}

public class NuGetDependencyScanner : IDependencyScanner
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<NuGetDependencyScanner> _logger;

    public NuGetDependencyScanner(
        HttpClient httpClient,
        ILogger<NuGetDependencyScanner> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<List<VulnerablePackage>> ScanAsync()
    {
        // Use NuGet API to check for vulnerabilities
        var vulnerabilities = new List<VulnerablePackage>();

        // Example: Check specific package
        var response = await _httpClient.GetAsync(
            "https://api.nuget.org/v3-vulnerabilities/index.json");

        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            // Parse and process vulnerability data
        }

        return vulnerabilities;
    }
}

// ============================================
// License Compliance Checking
// ============================================

public class LicenseComplianceService
{
    private static readonly HashSet<string> AllowedLicenses = new()
    {
        "MIT",
        "Apache-2.0",
        "BSD-3-Clause",
        "ISC"
    };

    private static readonly HashSet<string> ProhibitedLicenses = new()
    {
        "GPL-3.0",
        "AGPL-3.0",
        "SSPL"
    };

    public bool IsLicenseAllowed(string license)
    {
        if (ProhibitedLicenses.Contains(license))
        {
            return false;
        }

        return AllowedLicenses.Contains(license);
    }
}

// ============================================
// GitHub Dependabot Configuration
// ============================================

// .github/dependabot.yml
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
    commit-message:
      prefix: "chore"
      include: "scope"
    # Auto-merge security updates
    automerge:
      dependency-type: "production"
      update-type: "security"

// ============================================
// CI/CD Security Checks
// ============================================

// .github/workflows/security-scan.yml
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0' # Weekly

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore dependencies
        run: dotnet restore

      - name: Check for vulnerable packages
        run: dotnet list package --vulnerable --include-transitive

      - name: Check for outdated packages
        run: |
          dotnet tool install -g dotnet-outdated-tool
          dotnet outdated --fail-on-updates

      - name: Run security audit
        run: |
          dotnet tool install -g security-scan
          security-scan **/*.csproj

// ============================================
// Runtime Dependency Validation
// ============================================

public class DependencyValidationService
{
    private readonly ILogger<DependencyValidationService> _logger;

    public DependencyValidationService(ILogger<DependencyValidationService> logger)
    {
        _logger = logger;
    }

    public void ValidateAssemblies()
    {
        var assemblies = AppDomain.CurrentDomain.GetAssemblies();

        foreach (var assembly in assemblies)
        {
            try
            {
                var name = assembly.GetName();

                // Check for unsigned assemblies
                var publicKey = name.GetPublicKey();
                if (publicKey == null || publicKey.Length == 0)
                {
                    _logger.LogWarning(
                        "SECURITY: Unsigned assembly loaded: {AssemblyName}",
                        name.Name);
                }

                // Check for old versions
                if (name.Version?.Major < 7)
                {
                    _logger.LogWarning(
                        "SECURITY: Old version of assembly {AssemblyName}: {Version}",
                        name.Name, name.Version);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating assembly");
            }
        }
    }
}

// Call during startup
var dependencyValidator = app.Services.GetRequiredService<DependencyValidationService>();
dependencyValidator.ValidateAssemblies();

/*
Dependency Security Best Practices:

1. ✅ Regularly update dependencies
2. ✅ Use exact version numbers for critical packages
3. ✅ Enable NuGet package vulnerability auditing
4. ✅ Use only trusted package sources
5. ✅ Implement automated dependency scanning
6. ✅ Review license compliance
7. ✅ Monitor security advisories
8. ✅ Use Dependabot or similar tools
9. ✅ Validate package signatures
10. ✅ Minimize dependency count

Tools for Dependency Security:
- dotnet list package --vulnerable
- dotnet-outdated
- GitHub Dependabot
- Snyk
- WhiteSource (Mend)
- OWASP Dependency-Check
- Safety (for Python deps in hybrid apps)

Update Strategy:
- Security patches: Immediately
- Minor updates: Weekly
- Major updates: Review and plan
- Breaking changes: Test thoroughly
*/
```

---

## Q298: How do you implement security testing in ASP.NET Core applications?

**Answer:**

Security testing identifies vulnerabilities before they reach production.

```csharp
// ============================================
// Authorization Testing
// ============================================

public class AuthorizationTests
{
    [Fact]
    public async Task GetAdminData_WithoutAdminRole_ReturnsForbidden()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Create JWT token without Admin role
        var token = GenerateTestToken(roles: new[] { "User" });
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await client.GetAsync("/api/admin/data");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetAdminData_WithAdminRole_ReturnsSuccess()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        var token = GenerateTestToken(roles: new[] { "Admin" });
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await client.GetAsync("/api/admin/data");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private string GenerateTestToken(string[] roles)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, "test-user"),
            new Claim(ClaimTypes.Name, "Test User")
        };

        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes("test-secret-key-for-testing-purposes-only"));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: "test-issuer",
            audience: "test-audience",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// ============================================
// Input Validation Testing
// ============================================

public class InputValidationTests
{
    [Theory]
    [InlineData("<script>alert('xss')</script>")]
    [InlineData("'; DROP TABLE Users; --")]
    [InlineData("../../../etc/passwd")]
    public async Task CreateUser_WithMaliciousInput_ReturnsBadRequest(string maliciousInput)
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        var request = new
        {
            Username = maliciousInput,
            Email = "test@example.com",
            Password = "Password123!"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/users", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateUser_WithValidInput_ReturnsSuccess()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        var request = new
        {
            Username = "validuser",
            Email = "valid@example.com",
            Password = "ValidPassword123!"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/users", request);

        // Assert
        Assert.True(response.IsSuccessStatusCode);
    }
}

// ============================================
// CSRF Protection Testing
// ============================================

public class CsrfTests
{
    [Fact]
    public async Task PostAction_WithoutAntiforgeryToken_ReturnsBadRequest()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Act
        var response = await client.PostAsync("/api/sensitive-action", null);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task PostAction_WithValidAntiforgeryToken_ReturnsSuccess()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Get antiforgery token
        var getResponse = await client.GetAsync("/api/get-token");
        var token = await getResponse.Content.ReadAsStringAsync();

        // Add token to request
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/sensitive-action");
        request.Headers.Add("X-CSRF-TOKEN", token);

        // Act
        var response = await client.SendAsync(request);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}

// ============================================
// Security Headers Testing
// ============================================

public class SecurityHeadersTests
{
    [Fact]
    public async Task Response_IncludesSecurityHeaders()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync("/");

        // Assert
        Assert.True(response.Headers.Contains("X-Content-Type-Options"));
        Assert.Equal("nosniff",
            response.Headers.GetValues("X-Content-Type-Options").First());

        Assert.True(response.Headers.Contains("X-Frame-Options"));
        Assert.True(response.Headers.Contains("Content-Security-Policy"));
        Assert.True(response.Headers.Contains("Referrer-Policy"));
    }

    [Fact]
    public async Task Response_DoesNotLeakServerInfo()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync("/");

        // Assert
        Assert.False(response.Headers.Contains("Server"));
        Assert.False(response.Headers.Contains("X-Powered-By"));
        Assert.False(response.Headers.Contains("X-AspNet-Version"));
    }
}

// ============================================
// Rate Limiting Testing
// ============================================

public class RateLimitingTests
{
    [Fact]
    public async Task ExcessiveRequests_ReturnsToMany Requests()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Act - Make 101 requests (assuming limit is 100)
        var tasks = Enumerable.Range(0, 101)
            .Select(_ => client.GetAsync("/api/products"))
            .ToList();

        var responses = await Task.WhenAll(tasks);

        // Assert
        var tooManyRequestsCount = responses
            .Count(r => r.StatusCode == HttpStatusCode.TooManyRequests);

        Assert.True(tooManyRequestsCount > 0);
    }
}

// ============================================
// Penetration Testing with OWASP ZAP
// ============================================

// Run ZAP scan in CI/CD
public class PenetrationTests
{
    [Fact(Skip = "Run manually or in CI/CD")]
    public async Task RunZapScan()
    {
        // Start application
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Configure ZAP
        var zapClient = new HttpClient
        {
            BaseAddress = new Uri("http://localhost:8080")
        };

        var targetUrl = "http://localhost:5000";

        // Start spider scan
        await zapClient.GetAsync($"/JSON/spider/action/scan/?url={targetUrl}");

        // Wait for scan to complete
        await Task.Delay(30000);

        // Start active scan
        await zapClient.GetAsync($"/JSON/ascan/action/scan/?url={targetUrl}");

        // Wait for scan to complete
        await Task.Delay(60000);

        // Get alerts
        var alertsResponse = await zapClient.GetAsync("/JSON/core/view/alerts/");
        var alerts = await alertsResponse.Content.ReadAsStringAsync();

        // Assert no high-risk vulnerabilities
        Assert.DoesNotContain("\"risk\":\"High\"", alerts);
    }
}

// ============================================
// SQL Injection Testing
// ============================================

public class SqlInjectionTests
{
    [Theory]
    [InlineData("' OR '1'='1")]
    [InlineData("1; DROP TABLE Users; --")]
    [InlineData("' UNION SELECT * FROM Users --")]
    public async Task Search_WithSqlInjection_DoesNotExpose Data(string injection)
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync($"/api/users/search?query={injection}");

        // Assert
        Assert.True(response.IsSuccessStatusCode);

        var content = await response.Content.ReadAsStringAsync();

        // Should not return unexpected data
        Assert.DoesNotContain("password", content, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("hash", content, StringComparison.OrdinalIgnoreCase);
    }
}

// ============================================
// Secrets Detection Testing
// ============================================

public class SecretsDetectionTests
{
    [Fact]
    public void SourceCode_DoesNotContainSecrets()
    {
        var sourceFiles = Directory.GetFiles(
            Directory.GetCurrentDirectory(),
            "*.cs",
            SearchOption.AllDirectories);

        var secretPatterns = new[]
        {
            @"password\s*=\s*[""'][^""']+[""']",
            @"api[_-]?key\s*=\s*[""'][^""']+[""']",
            @"secret\s*=\s*[""'][^""']+[""']",
            @"connectionstring\s*=\s*[""'][^""']+[""']"
        };

        foreach (var file in sourceFiles)
        {
            var content = File.ReadAllText(file);

            foreach (var pattern in secretPatterns)
            {
                Assert.False(
                    Regex.IsMatch(content, pattern, RegexOptions.IgnoreCase),
                    $"Potential secret found in {file}");
            }
        }
    }
}

/*
Security Testing Best Practices:

1. ✅ Test authentication and authorization
2. ✅ Test input validation and sanitization
3. ✅ Test CSRF protection
4. ✅ Test security headers
5. ✅ Test rate limiting
6. ✅ Run automated security scans
7. ✅ Test for common vulnerabilities (OWASP Top 10)
8. ✅ Perform penetration testing
9. ✅ Test secrets management
10. ✅ Include security tests in CI/CD

Security Testing Tools:
- OWASP ZAP (Zed Attack Proxy)
- Burp Suite
- SonarQube
- Snyk
- Checkmarx
- Veracode
- GitHub Advanced Security

Test Coverage:
- Authentication bypass
- Authorization failures
- Input validation
- SQL injection
- XSS attacks
- CSRF protection
- Session management
- Cryptography
- Error handling
*/
```

---

## Q299: What is the OWASP Top 10 and how do you mitigate these vulnerabilities in ASP.NET Core?

**Answer:**

The OWASP Top 10 represents the most critical web application security risks.

```csharp
// ============================================
// OWASP Top 10 (2021) Mitigation Guide
// ============================================

/*
1. A01:2021 - Broken Access Control
*/

// ❌ VULNERABLE: No authorization check
[HttpGet("admin/users")]
public IActionResult GetAllUsers()
{
    return Ok(_userService.GetAll());
}

// ✅ SECURE: Proper authorization
[HttpGet("admin/users")]
[Authorize(Roles = "Admin")]
public IActionResult GetAllUsers()
{
    return Ok(_userService.GetAll());
}

// ✅ SECURE: Resource-based authorization
[HttpPut("users/{id}")]
public async Task<IActionResult> UpdateUser(int id, UserDto dto)
{
    var user = await _userService.GetByIdAsync(id);

    var authResult = await _authService.AuthorizeAsync(
        User,
        user,
        "CanEditUser");

    if (!authResult.Succeeded)
    {
        return Forbid();
    }

    await _userService.UpdateAsync(user);
    return NoContent();
}

/*
2. A02:2021 - Cryptographic Failures
*/

// ❌ VULNERABLE: Weak hashing
public string HashPassword(string password)
{
    using var md5 = MD5.Create();
    var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(password));
    return Convert.ToBase64String(hash);
}

// ✅ SECURE: Strong hashing with ASP.NET Core Identity
public class SecurePasswordService
{
    private readonly IPasswordHasher<User> _passwordHasher;

    public SecurePasswordService(IPasswordHasher<User> passwordHasher)
    {
        _passwordHasher = passwordHasher;
    }

    public string HashPassword(User user, string password)
    {
        return _passwordHasher.HashPassword(user, password);
    }

    public bool VerifyPassword(User user, string hashedPassword, string providedPassword)
    {
        var result = _passwordHasher.VerifyHashedPassword(
            user,
            hashedPassword,
            providedPassword);

        return result == PasswordVerificationResult.Success;
    }
}

// ✅ SECURE: Data encryption at rest
builder.Services.AddDataProtection()
    .PersistKeysToAzureBlobStorage(...)
    .ProtectKeysWithAzureKeyVault(...);

// ✅ SECURE: HTTPS enforcement
builder.Services.AddHsts(options =>
{
    options.MaxAge = TimeSpan.FromDays(365);
    options.IncludeSubDomains = true;
    options.Preload = true;
});

app.UseHttpsRedirection();
app.UseHsts();

/*
3. A03:2021 - Injection
*/

// ❌ VULNERABLE: SQL Injection
public async Task<User> GetUserUnsafe(string username)
{
    var query = $"SELECT * FROM Users WHERE Username = '{username}'";
    return await _context.Users.FromSqlRaw(query).FirstOrDefaultAsync();
}

// ✅ SECURE: Parameterized query
public async Task<User> GetUserSafe(string username)
{
    return await _context.Users
        .Where(u => u.Username == username)
        .FirstOrDefaultAsync();
}

// ✅ SECURE: Input validation
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery, Required, MaxLength(50)] string query)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var results = await _userService.SearchAsync(query);
        return Ok(results);
    }
}

/*
4. A04:2021 - Insecure Design
*/

// ✅ SECURE: Implement security by design
public class SecureOrderService
{
    private readonly IAuthorizationService _authService;
    private readonly IAuditLogger _auditLogger;
    private readonly IRateLimiter _rateLimiter;

    // Rate limiting
    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        var userId = _httpContext.User.GetUserId();

        // Check rate limit
        if (!await _rateLimiter.IsAllowedAsync(userId))
        {
            throw new TooManyRequestsException();
        }

        // Validate business rules
        if (request.TotalAmount > 10000 && !await IsVerifiedUserAsync(userId))
        {
            throw new UnauthorizedOperationException(
                "Account verification required for large orders");
        }

        // Create order with audit trail
        var order = await _orderRepository.CreateAsync(request);

        await _auditLogger.LogAsync(new AuditEvent
        {
            UserId = userId,
            Action = "CreateOrder",
            Resource = $"Order/{order.Id}",
            Success = true
        });

        return order;
    }
}

/*
5. A05:2021 - Security Misconfiguration
*/

// ✅ SECURE: Proper configuration
var builder = WebApplication.CreateBuilder(args);

// Remove server header
builder.WebHost.ConfigureKestrel(options =>
{
    options.AddServerHeader = false;
});

// Configure security options
builder.Services.AddControllers(options =>
{
    // Require HTTPS
    options.Filters.Add(new RequireHttpsAttribute());

    // Disable automatic model validation for security-sensitive endpoints
    options.SuppressModelStateInvalidFilter = false;
});

// Remove unnecessary services
// builder.Services.AddDirectoryBrowser(); // ❌ Don't enable in production

var app = builder.Build();

// Disable detailed errors in production
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

// Don't expose Swagger in production
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

/*
6. A06:2021 - Vulnerable and Outdated Components
*/

// ✅ SECURE: Regular updates and scanning
// .csproj
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <NuGetAudit>true</NuGetAudit>
    <NuGetAuditMode>all</NuGetAuditMode>
    <NuGetAuditLevel>low</NuGetAuditLevel>
  </PropertyGroup>
</Project>

// Run regularly:
// dotnet list package --vulnerable
// dotnet outdated

/*
7. A07:2021 - Identification and Authentication Failures
*/

// ✅ SECURE: Multi-factor authentication
builder.Services.AddIdentity<User, Role>(options =>
{
    // Password requirements
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 12;

    // Lockout settings
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User settings
    options.User.RequireUniqueEmail = true;

    // Sign-in settings
    options.SignIn.RequireConfirmedEmail = true;
    options.SignIn.RequireConfirmedAccount = true;
})
.AddDefaultTokenProviders();

// ✅ SECURE: Session management
builder.Services.AddSession(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.IdleTimeout = TimeSpan.FromMinutes(20);
});

/*
8. A08:2021 - Software and Data Integrity Failures
*/

// ✅ SECURE: Verify package integrity
// Use package signature verification in nuget.config
<config>
  <add key="signatureValidationMode" value="require" />
</config>

// ✅ SECURE: Implement integrity checks
public class FileIntegrityService
{
    public async Task<bool> VerifyFileIntegrityAsync(
        string filePath,
        string expectedHash)
    {
        using var sha256 = SHA256.Create();
        using var stream = File.OpenRead(filePath);

        var computedHash = await sha256.ComputeHashAsync(stream);
        var computedHashString = Convert.ToBase64String(computedHash);

        return computedHashString == expectedHash;
    }
}

/*
9. A09:2021 - Security Logging and Monitoring Failures
*/

// ✅ SECURE: Comprehensive logging
public class SecurityEventLogger
{
    private readonly ILogger<SecurityEventLogger> _logger;

    public void LogSecurityEvent(SecurityEvent evt)
    {
        _logger.LogWarning(
            "SECURITY: {EventType} - User: {User}, IP: {IP}, Resource: {Resource}, Success: {Success}",
            evt.EventType,
            evt.Username,
            evt.IpAddress,
            evt.Resource,
            evt.Success);

        // Send to SIEM system
        // SendToSiem(evt);
    }
}

// ✅ SECURE: Monitoring
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddHealthChecks();

/*
10. A10:2021 - Server-Side Request Forgery (SSRF)
*/

// ❌ VULNERABLE: No URL validation
public async Task<string> FetchUrlUnsafe(string url)
{
    using var client = new HttpClient();
    return await client.GetStringAsync(url);
}

// ✅ SECURE: URL whitelist validation
public class SsrfProtectedHttpService
{
    private static readonly HashSet<string> AllowedHosts = new()
    {
        "api.example.com",
        "data.example.com"
    };

    public async Task<string> FetchUrlSafe(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
        {
            throw new ArgumentException("Invalid URL");
        }

        // Block private IP ranges
        if (IsPrivateIp(uri.Host))
        {
            throw new UnauthorizedAccessException("Private IPs not allowed");
        }

        // Whitelist allowed hosts
        if (!AllowedHosts.Contains(uri.Host))
        {
            throw new UnauthorizedAccessException("Host not allowed");
        }

        using var client = new HttpClient();
        return await client.GetStringAsync(uri);
    }

    private bool IsPrivateIp(string host)
    {
        if (!IPAddress.TryParse(host, out var ip))
        {
            return false;
        }

        var bytes = ip.GetAddressBytes();

        return bytes[0] == 10 ||
               (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
               (bytes[0] == 192 && bytes[1] == 168) ||
               bytes[0] == 127;
    }
}

/*
OWASP Top 10 Mitigation Summary:

1. Broken Access Control:
   - Use [Authorize] attributes
   - Implement resource-based authorization
   - Deny by default

2. Cryptographic Failures:
   - Use strong algorithms (AES-256, SHA-256)
   - Enforce HTTPS
   - Use ASP.NET Core Data Protection

3. Injection:
   - Use parameterized queries
   - Validate and sanitize input
   - Use ORM (Entity Framework)

4. Insecure Design:
   - Security by design
   - Threat modeling
   - Secure development lifecycle

5. Security Misconfiguration:
   - Harden configurations
   - Remove unnecessary features
   - Keep frameworks updated

6. Vulnerable Components:
   - Regular dependency scanning
   - Keep packages updated
   - Use package vulnerability auditing

7. Authentication Failures:
   - Implement MFA
   - Strong password policies
   - Account lockout

8. Software Integrity Failures:
   - Verify package signatures
   - Use trusted sources
   - Implement integrity checks

9. Logging Failures:
   - Log security events
   - Protect log files
   - Monitor and alert

10. SSRF:
    - Validate and whitelist URLs
    - Block private IP ranges
    - Implement network segmentation
*/
```

---

## Q300: Security Best Practices Summary - Comprehensive Checklist

**Answer:**

A comprehensive security checklist for ASP.NET Core applications.

```csharp
/*
============================================
ASP.NET CORE SECURITY CHECKLIST
============================================

AUTHENTICATION & AUTHORIZATION
✅ Use ASP.NET Core Identity for user management
✅ Implement multi-factor authentication (MFA)
✅ Use strong password policies (12+ characters, complexity)
✅ Implement account lockout after failed attempts
✅ Use OAuth 2.0/OpenID Connect for third-party auth
✅ Implement role-based and policy-based authorization
✅ Use [Authorize] attributes on all protected endpoints
✅ Validate JWT tokens properly (issuer, audience, expiration)
✅ Implement token refresh before expiration
✅ Use secure session management

DATA PROTECTION
✅ Enforce HTTPS everywhere (UseHttpsRedirection)
✅ Use HSTS with long max-age
✅ Implement proper encryption (AES-256)
✅ Use ASP.NET Core Data Protection API
✅ Hash passwords with strong algorithms (PBKDF2, BCrypt, Argon2)
✅ Never store passwords in plain text
✅ Protect sensitive data at rest and in transit
✅ Implement proper key management (Azure Key Vault)
✅ Use TLS 1.2 or 1.3 only
✅ Rotate encryption keys regularly

INPUT VALIDATION & OUTPUT ENCODING
✅ Validate all user input on server-side
✅ Use Data Annotations or FluentValidation
✅ Implement whitelist validation
✅ Sanitize HTML input
✅ Use parameterized queries (prevent SQL injection)
✅ Encode output to prevent XSS
✅ Validate file uploads (type, size, content)
✅ Implement path traversal prevention
✅ Use CSP (Content Security Policy)
✅ Validate and sanitize redirects

API SECURITY
✅ Implement rate limiting
✅ Use API versioning
✅ Implement proper CORS policies
✅ Use API keys or OAuth for authentication
✅ Implement request/response logging
✅ Use HTTPS for all API endpoints
✅ Implement request size limits
✅ Use anti-forgery tokens for state-changing operations
✅ Implement proper error handling (no stack traces in production)
✅ Use API gateways for additional security layer

SECURITY HEADERS
✅ X-Content-Type-Options: nosniff
✅ X-Frame-Options: DENY or SAMEORIGIN
✅ X-XSS-Protection: 1; mode=block
✅ Content-Security-Policy (CSP)
✅ Referrer-Policy: strict-origin-when-cross-origin
✅ Permissions-Policy (Feature-Policy)
✅ Strict-Transport-Security (HSTS)
✅ Remove Server header
✅ Remove X-Powered-By header
✅ Implement CSP reporting

DEPENDENCY MANAGEMENT
✅ Keep all packages up to date
✅ Enable NuGet package vulnerability auditing
✅ Run dependency scanning regularly
✅ Use exact version numbers for critical packages
✅ Remove unused dependencies
✅ Use only trusted package sources
✅ Verify package signatures
✅ Implement Dependabot or similar automation
✅ Review package licenses
✅ Monitor security advisories

SECRETS MANAGEMENT
✅ Never commit secrets to source control
✅ Use User Secrets for local development
✅ Use Azure Key Vault / AWS Secrets Manager in production
✅ Use environment variables for containerized apps
✅ Implement proper access controls
✅ Rotate secrets regularly
✅ Use managed identities when possible
✅ Audit secret access
✅ Encrypt secrets at rest
✅ Use separate secrets per environment

LOGGING & MONITORING
✅ Log all security events
✅ Never log sensitive data (passwords, tokens)
✅ Implement centralized logging
✅ Monitor for suspicious patterns
✅ Implement alerting for security events
✅ Log authentication attempts (success/failure)
✅ Log authorization failures
✅ Protect log files with proper permissions
✅ Implement log retention policies
✅ Use structured logging

ERROR HANDLING
✅ Implement global exception handling
✅ Never expose stack traces in production
✅ Use custom error pages
✅ Log all exceptions
✅ Return generic error messages to clients
✅ Implement proper HTTP status codes
✅ Don't leak implementation details
✅ Handle database errors securely
✅ Implement circuit breakers
✅ Use health checks

CONFIGURATION
✅ Harden application configuration
✅ Disable unnecessary features
✅ Remove default accounts and credentials
✅ Disable directory browsing
✅ Implement proper file permissions
✅ Use secure defaults
✅ Disable detailed errors in production
✅ Remove development tools in production
✅ Configure timeout values
✅ Implement proper cache headers

TESTING
✅ Implement security unit tests
✅ Test authentication and authorization
✅ Test input validation
✅ Test for common vulnerabilities (OWASP Top 10)
✅ Run automated security scans (OWASP ZAP, Burp Suite)
✅ Perform penetration testing
✅ Test rate limiting
✅ Test CSRF protection
✅ Include security tests in CI/CD
✅ Regular security code reviews

DEPLOYMENT & INFRASTRUCTURE
✅ Use least privilege principle
✅ Implement network segmentation
✅ Use Web Application Firewall (WAF)
✅ Implement DDoS protection
✅ Use secure container images
✅ Scan containers for vulnerabilities
✅ Implement secure CI/CD pipelines
✅ Use infrastructure as code
✅ Regular security patches
✅ Implement disaster recovery plan

COMPLIANCE & GOVERNANCE
✅ Comply with GDPR / CCPA / HIPAA
✅ Implement data retention policies
✅ Provide user data export/deletion
✅ Implement audit trails
✅ Document security procedures
✅ Conduct regular security training
✅ Implement incident response plan
✅ Regular security assessments
✅ Third-party security audits
✅ Maintain security documentation

CSRF PROTECTION
✅ Use anti-forgery tokens
✅ Implement SameSite cookies
✅ Validate origin and referer headers
✅ Use double-submit cookie pattern
✅ Implement CORS properly
✅ Protect all state-changing operations
✅ Use POST for state-changing operations
✅ Implement token validation
✅ Set proper cookie attributes
✅ Use secure cookie flags

FILE UPLOAD SECURITY
✅ Validate file types
✅ Limit file sizes
✅ Scan files for malware
✅ Store files outside web root
✅ Use unique file names
✅ Implement virus scanning
✅ Validate file content (not just extension)
✅ Implement download rate limiting
✅ Use Content-Disposition headers
✅ Implement file access controls

SESSION MANAGEMENT
✅ Use secure session cookies
✅ Implement session timeout
✅ Regenerate session IDs after login
✅ Use HttpOnly cookies
✅ Use Secure cookie flag
✅ Implement SameSite cookies
✅ Use distributed cache for sessions
✅ Implement session fixation prevention
✅ Clear sessions on logout
✅ Monitor active sessions

DATABASE SECURITY
✅ Use parameterized queries
✅ Implement principle of least privilege
✅ Encrypt sensitive data in database
✅ Use connection pooling securely
✅ Implement database auditing
✅ Regular database backups
✅ Secure database connections
✅ Implement row-level security
✅ Monitor database access
✅ Use separate accounts per application

============================================
SECURITY IMPLEMENTATION CHECKLIST
============================================

Program.cs Essential Security Configuration:
*/

var builder = WebApplication.CreateBuilder(args);

// 1. HTTPS & HSTS
builder.Services.AddHsts(options =>
{
    options.MaxAge = TimeSpan.FromDays(365);
    options.IncludeSubDomains = true;
    options.Preload = true;
});

builder.Services.AddHttpsRedirection(options =>
{
    options.RedirectStatusCode = StatusCodes.Status308PermanentRedirect;
});

// 2. Authentication & Authorization
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});

// 3. CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("SecurePolicy", policy =>
    {
        policy.WithOrigins("https://trusted-domain.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// 4. Rate Limiting
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(
        context => RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.User.Identity?.Name ?? context.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            }));
});

// 5. Anti-forgery
builder.Services.AddAntiforgery(options =>
{
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.Cookie.HttpOnly = true;
});

// 6. Data Protection
builder.Services.AddDataProtection()
    .PersistKeysToAzureBlobStorage(...)
    .ProtectKeysWithAzureKeyVault(...);

// 7. Session Security
builder.Services.AddSession(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.IdleTimeout = TimeSpan.FromMinutes(20);
});

var app = builder.Build();

// Middleware order is important!
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseSecurityHeaders(); // Custom middleware
app.UseCors("SecurePolicy");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.UseSession();

app.MapControllers();
app.Run();

/*
============================================
FINAL SECURITY REMINDERS
============================================

1. Security is a process, not a product
2. Defense in depth - multiple layers of security
3. Principle of least privilege
4. Fail securely - secure defaults
5. Keep it simple - complexity is the enemy of security
6. Never trust user input
7. Stay updated on security advisories
8. Regular security training for team
9. Incident response plan ready
10. Security is everyone's responsibility

CONTINUOUS IMPROVEMENT:
- Regular security audits
- Penetration testing
- Code reviews with security focus
- Threat modeling
- Stay informed about new vulnerabilities
- Update dependencies regularly
- Monitor security logs
- Learn from security incidents

RESOURCES:
- OWASP Top 10
- Microsoft Security Development Lifecycle (SDL)
- CWE Top 25
- NIST Cybersecurity Framework
- ASP.NET Core Security Documentation
- Azure Security Best Practices

Remember: Security is not a one-time task but an ongoing process!
*/
```

---

**This completes all 20 Security questions (Q281-Q300) covering:**
1. Authentication & Authorization
2. JWT Authentication
3. Password Hashing & Security
4. CORS Configuration
5. CSRF Protection
6. XSS Prevention
7. SQL Injection Prevention
8. Security Headers
9. HTTPS/TLS Configuration
10. Data Protection API
11. Secrets Management
12. Rate Limiting
13. OAuth 2.0 / OpenID Connect
14. API Key Authentication
15. Input Validation & Sanitization
16. Secure Logging & Monitoring
17. Dependency & Package Security
18. Security Testing
19. OWASP Top 10 Mitigation
20. Comprehensive Security Best Practices

---

