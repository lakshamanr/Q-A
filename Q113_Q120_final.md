## **Q113: What is Azure Key Vault? How do you use it in applications?**

### **Answer:**

Azure Key Vault is a cloud service for securely storing and accessing secrets, keys, and certificates. It helps solve the problem of hardcoded credentials and sensitive data in application code.

**What Key Vault Stores:**

1. **Secrets**: Connection strings, passwords, API keys
2. **Keys**: Cryptographic keys for encryption/decryption
3. **Certificates**: SSL/TLS certificates

**Key Features:**

- Centralized secret management
- Access control with Azure AD
- Audit logging (who accessed what, when)
- Automatic secret rotation
- Integration with Azure services
- HSM-backed keys (Hardware Security Module)

**Implementation:**

```csharp
// Install: Azure.Security.KeyVault.Secrets, Azure.Identity

//appsettings.json
{
    "KeyVault": {
        "VaultUri": "https://myvault.vault.azure.net/"
    },
    "ConnectionStrings": {
        "DefaultConnection": "" // Empty - will load from Key Vault
    }
}

// Program.cs - Configure Key Vault
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Key Vault to configuration
var keyVaultUri = builder.Configuration["KeyVault:VaultUri"];
if (!string.IsNullOrEmpty(keyVaultUri))
{
    var credential = new DefaultAzureCredential(); // Uses Managed Identity in Azure
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUri),
        credential
    );
}

// Now secrets from Key Vault are available via IConfiguration
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection") // Loaded from Key Vault!
    )
);

// Using Secret Client directly
public class SecretService
{
    private readonly SecretClient _secretClient;

    public SecretService(IConfiguration configuration)
    {
        var vaultUri = configuration["KeyVault:VaultUri"];
        _secretClient = new SecretClient(
            new Uri(vaultUri),
            new DefaultAzureCredential()
        );
    }

    public async Task<string> GetSecretAsync(string secretName)
    {
        try
        {
            KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);
            return secret.Value;
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 404)
        {
            throw new Exception($"Secret '{secretName}' not found in Key Vault");
        }
    }

    public async Task SetSecretAsync(string secretName, string secretValue)
    {
        await _secretClient.SetSecretAsync(secretName, secretValue);
    }

    // Get multiple secrets efficiently
    public async Task<Dictionary<string, string>> GetSecretsAsync(params string[] secretNames)
    {
        var tasks = secretNames.Select(async name =>
        {
            var secret = await _secretClient.GetSecretAsync(name);
            return new KeyValuePair<string, string>(name, secret.Value.Value);
        });

        var results = await Task.WhenAll(tasks);
        return results.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);
    }
}
```

**Real-World Example:**

```csharp
public class PaymentService
{
    private readonly SecretClient _secretClient;

    public async Task ProcessPaymentAsync(decimal amount)
    {
        // Get payment gateway credentials from Key Vault
        var apiKey = await _secretClient.GetSecretAsync("PaymentGateway-ApiKey");
        var apiSecret = await _secretClient.GetSecretAsync("PaymentGateway-ApiSecret");

        // Use credentials securely
        var paymentGateway = new PaymentGatewayClient(apiKey.Value.Value, apiSecret.Value.Value);
        await paymentGateway.ChargeAsync(amount);

        // No hardcoded secrets in code!
    }
}
```

**Best Practices:**

1. Use Managed Identity (no credentials in code)
2. Enable soft delete and purge protection
3. Use RBAC for access control
4. Enable audit logging
5. Rotate secrets regularly
6. Use separate vaults for different environments

---

## **Q114: Explain managed identities in Azure.**

### **Answer:**

Managed Identities eliminate the need to manage credentials in code. Azure automatically handles the identity and credentials for Azure resources.

**Types:**

### **1. System-Assigned Managed Identity**

- Tied to a single Azure resource
- Created with the resource
- Deleted when resource is deleted

```csharp
// Enable in Azure Portal or CLI:
az vm identity assign --name myVM --resource-group myRG

// No credentials needed in code!
var credential = new DefaultAzureCredential();
var secretClient = new SecretClient(vaultUri, credential);

// Azure handles authentication automatically
var secret = await secretClient.GetSecretAsync("DatabasePassword");
```

### **2. User-Assigned Managed Identity**

- Standalone identity
- Can be assigned to multiple resources
- Lifecycle independent of resources

**How It Works:**

```
1. App requests token from Azure Instance Metadata Service
2. Azure validates identity
3. Returns access token
4. App uses token to access Key Vault/Storage/SQL
5. No secrets stored in application!
```

**Implementation:**

```csharp
// Works automatically in Azure with Managed Identity enabled
public class ManagedIdentityExample
{
    // Access Key Vault
    public async Task<string> GetSecretAsync()
    {
        var credential = new DefaultAzureCredential();
        var client = new SecretClient(new Uri("https://myvault.vault.azure.net/"), credential);
        var secret = await client.GetSecretAsync("MySecret");
        return secret.Value.Value;
    }

    // Access Blob Storage
    public async Task UploadFileAsync()
    {
        var credential = new DefaultAzureCredential();
        var blobClient = new BlobServiceClient(
            new Uri("https://mystorageaccount.blob.core.windows.net"),
            credential
        );

        var containerClient = blobClient.GetBlobContainerClient("documents");
        await containerClient.GetBlobClient("file.txt").UploadAsync("data.txt");
    }

    // Access SQL Database
    public async Task QueryDatabaseAsync()
    {
        var credential = new DefaultAzureCredential();
        var token = await credential.GetTokenAsync(
            new TokenRequestContext(new[] { "https://database.windows.net/.default" })
        );

        using var connection = new SqlConnection("Server=myserver.database.windows.net;Database=mydb;");
        connection.AccessToken = token.Token;
        await connection.OpenAsync();

        // Query database
    }
}
```

**Benefits:**

- No credentials in code or configuration
- Automatic rotation of credentials
- Simplified credential management
- Better security posture
- Works seamlessly in Azure

---

## **Q115: What is Azure API Management? What problems does it solve?**

### **Answer:**

Azure API Management (APIM) is a fully managed service that helps organizations publish, secure, transform, maintain, and monitor APIs.

**Problems It Solves:**

1. **API Security**: Authentication, authorization, rate limiting
2. **API Gateway**: Single entry point for all APIs
3. **API Versioning**: Manage multiple API versions
4. **Traffic Management**: Throttling, quotas, caching
5. **Analytics**: Usage metrics, monitoring
6. **Developer Portal**: Documentation, testing
7. **Transformation**: Request/response manipulation

**Architecture:**

```
External Clients → API Management Gateway → Backend APIs

Components:
1. Gateway: Accepts API calls, enforces policies
2. Azure Portal: Manage APIs, policies, users
3. Developer Portal: API documentation, testing
```

**Implementation:**

```csharp
// No code changes needed in backend APIs!
// All policies configured in APIM

// Example backend API (stays unchanged)
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetProducts()
    {
        return Ok(products);
    }
}
```

**APIM Policies (XML):**

```xml
<!-- Rate Limiting -->
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <quota calls="10000" renewal-period="604800" />
    </inbound>
</policies>

<!-- Authentication -->
<policies>
    <inbound>
        <validate-jwt header-name="Authorization">
            <issuer-signing-keys>
                <key>{{jwt-signing-key}}</key>
            </issuer-signing-keys>
        </validate-jwt>
    </inbound>
</policies>

<!-- Response Caching -->
<policies>
    <inbound>
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
    </inbound>
    <outbound>
        <cache-store duration="3600" />
    </outbound>
</policies>
```

**Use Cases:**

- Microservices API gateway
- External API monetization
- Legacy API modernization
- Multi-channel API access
- Partner/customer API access

---

## **Q116: How do you implement rate limiting in API Management?**

### **Answer:**

Rate limiting in APIM controls the number of API calls to prevent abuse and ensure fair usage.

**Two Types:**

### **1. Rate Limit (Short-term)**

```xml
<policies>
    <inbound>
        <!-- 100 calls per 60 seconds per subscription key -->
        <rate-limit calls="100" renewal-period="60" />

        <!-- Per IP address -->
        <rate-limit-by-key calls="100" renewal-period="60"
            counter-key="@(context.Request.IpAddress)" />

        <!-- Per user -->
        <rate-limit-by-key calls="1000" renewal-period="60"
            counter-key="@(context.Request.Headers.GetValueOrDefault("user-id"))" />
    </inbound>
</policies>
```

### **2. Quota (Long-term)**

```xml
<policies>
    <inbound>
        <!-- 10,000 calls per week per subscription -->
        <quota calls="10000" renewal-period="604800" />

        <!-- Bandwidth quota -->
        <quota-by-key calls="10000" bandwidth="100000" renewal-period="604800"
            counter-key="@(context.Subscription.Id)" />
    </inbound>
</policies>
```

**Advanced Rate Limiting:**

```xml
<!-- Different limits for different tiers -->
<policies>
    <inbound>
        <choose>
            <when condition="@(context.Product.Name == "Premium")">
                <rate-limit calls="10000" renewal-period="60" />
            </when>
            <when condition="@(context.Product.Name == "Basic")">
                <rate-limit calls="100" renewal-period="60" />
            </when>
            <otherwise>
                <rate-limit calls="10" renewal-period="60" />
            </otherwise>
        </choose>
    </inbound>
</policies>
```

**Custom Error Response:**

```xml
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
    </inbound>
    <on-error>
        <choose>
            <when condition="@(context.LastError.Reason == "RateLimitExceeded")">
                <return-response>
                    <set-status code="429" reason="Too Many Requests" />
                    <set-header name="Retry-After" exists-action="override">
                        <value>60</value>
                    </set-header>
                    <set-body>@{
                        return new JObject(
                            new JProperty("error", "Rate limit exceeded"),
                            new JProperty("retry_after", 60)
                        ).ToString();
                    }</set-body>
                </return-response>
            </when>
        </choose>
    </on-error>
</policies>
```

---

## **Q117: Explain policies in Azure API Management.**

### **Answer:**

Policies are collections of statements that execute sequentially on request/response of an API.

**Policy Sections:**

```xml
<policies>
    <inbound>      <!-- Before forwarding to backend -->
    </inbound>
    <backend>      <!-- Before/after calling backend -->
    </backend>
    <outbound>     <!-- After receiving from backend -->
    </outbound>
    <on-error>     <!-- On error in any section -->
    </on-error>
</policies>
```

**Common Policies:**

### **1. Transformation Policies:**

```xml
<!-- Add/Modify Headers -->
<set-header name="X-Correlation-Id" exists-action="override">
    <value>@(Guid.NewGuid().ToString())</value>
</set-header>

<!-- Transform JSON -->
<set-body>@{
    var body = context.Request.Body.As<JObject>();
    body["timestamp"] = DateTime.UtcNow;
    return body.ToString();
}</set-body>

<!-- Convert XML to JSON -->
<xml-to-json kind="direct" apply="always" consider-accept-header="false" />
```

### **2. Security Policies:**

```xml
<!-- Validate JWT -->
<validate-jwt header-name="Authorization" failed-validation-httpcode="401">
    <openid-config url="https://login.microsoftonline.com/tenant/.well-known/openid-configuration" />
    <audiences>
        <audience>api://myapi</audience>
    </audiences>
    <required-claims>
        <claim name="roles" match="any">
            <value>Admin</value>
        </claim>
    </required-claims>
</validate-jwt>

<!-- IP Filtering -->
<ip-filter action="allow">
    <address>13.66.201.169</address>
    <address-range from="13.66.140.128" to="13.66.140.143" />
</ip-filter>
```

### **3. Caching Policies:**

```xml
<cache-lookup vary-by-developer="true" vary-by-developer-groups="true">
    <vary-by-header>Accept</vary-by-header>
    <vary-by-query-parameter>category</vary-by-query-parameter>
</cache-lookup>

<cache-store duration="3600" />
```

---

## **Q118: What is Azure Application Insights? What metrics does it collect?**

### **Answer:**

Application Insights is an Application Performance Management (APM) service that monitors live applications, automatically detects performance anomalies, and includes analytics tools.

**Key Metrics Collected:**

### **1. Request Metrics:**
- Request rate
- Response time
- Failure rate
- Dependency calls

### **2. Performance Metrics:**
- Server response time
- Browser page load time
- AJAX call duration
- Dependency duration

### **3. Availability:**
- Uptime percentage
- Response time from locations worldwide
- Alert on failures

### **4. Usage:**
- Page views
- User sessions
- User flows
- Custom events

**Implementation:**

```csharp
// Install: Microsoft.ApplicationInsights.AspNetCore

// Program.cs
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
});

// appsettings.json
{
    "ApplicationInsights": {
        "ConnectionString": "InstrumentationKey=xxx;IngestionEndpoint=https://..."
    }
}

// Custom Tracking
public class OrderService
{
    private readonly TelemetryClient _telemetry;

    public OrderService(TelemetryClient telemetry)
    {
        _telemetry = telemetry;
    }

    public async Task ProcessOrderAsync(Order order)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await ProcessPayment(order);

            // Track custom event
            _telemetry.TrackEvent("OrderProcessed", new Dictionary<string, string>
            {
                { "OrderId", order.Id },
                { "Amount", order.Amount.ToString() }
            });

            // Track metric
            _telemetry.TrackMetric("OrderValue", order.Amount);

            stopwatch.Stop();
            _telemetry.TrackMetric("OrderProcessingTime", stopwatch.ElapsedMilliseconds);
        }
        catch (Exception ex)
        {
            _telemetry.TrackException(ex, new Dictionary<string, string>
            {
                { "OrderId", order.Id }
            });
            throw;
        }
    }
}
```

**Queries (KQL - Kusto Query Language):**

```kusto
// Average response time by endpoint
requests
| where timestamp > ago(24h)
| summarize avg(duration) by name
| order by avg_duration desc

// Failed requests
requests
| where success == false
| project timestamp, name, resultCode, duration

// Custom events
customEvents
| where name == "OrderProcessed"
| extend OrderId = tostring(customDimensions.OrderId)
| extend Amount = todouble(customDimensions.Amount)
| summarize TotalRevenue = sum(Amount), OrderCount = count() by bin(timestamp, 1h)
```

---

## **Q119: How do you implement distributed tracing with Application Insights?**

### **Answer:**

Distributed tracing tracks requests across multiple services in microservices architecture.

**Implementation:**

```csharp
// Automatically enabled with Application Insights SDK

// Service 1: API Gateway
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly HttpClient _httpClient;
    private readonly TelemetryClient _telemetry;

    [HttpPost]
    public async Task<IActionResult> CreateOrder(Order order)
    {
        // Application Insights automatically creates parent span

        // Call Service 2 - correlation ID propagated automatically
        var response = await _httpClient.PostAsJsonAsync(
            "https://payment-service/api/payments",
            new { orderId = order.Id, amount = order.Amount }
        );

        // Call Service 3
        await _httpClient.PostAsJsonAsync(
            "https://inventory-service/api/inventory/reserve",
            new { items = order.Items }
        );

        return Ok();
    }
}

// Service 2: Payment Service
[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> ProcessPayment(PaymentRequest request)
    {
        // Automatically correlated with parent request
        _telemetry.TrackEvent("PaymentProcessed");

        return Ok();
    }
}
```

**View in Application Insights:**

```
End-to-End Transaction View:

OrdersController.CreateOrder (150ms)
├─ PaymentService.ProcessPayment (80ms)
│  └─ PaymentGateway.Charge (70ms)
└─ InventoryService.ReserveItems (40ms)
   └─ Database.Query (30ms)

Total Duration: 150ms
```

**Custom Correlation:**

```csharp
public async Task ProcessWithCustomCorrelation()
{
    using (var operation = _telemetry.StartOperation<RequestTelemetry>("CustomOperation"))
    {
        operation.Telemetry.Properties["CustomProperty"] = "Value";

        await Task.Delay(100);

        _telemetry.TrackEvent("Step1");

        await Task.Delay(50);

        _telemetry.TrackEvent("Step2");
    } // Automatically tracked
}
```

---

## **Q120: What is Azure Monitor? Explain alerts and action groups.**

### **Answer:**

Azure Monitor is a comprehensive monitoring solution that collects, analyzes, and acts on telemetry from cloud and on-premises environments.

**Components:**

1. **Metrics**: Numerical time-series data
2. **Logs**: Text-based diagnostic data
3. **Alerts**: Notifications based on conditions
4. **Action Groups**: What to do when alert fires

**Creating Alerts:**

```csharp
// Alert Rule Configuration (JSON)
{
    "name": "High CPU Alert",
    "description": "Alert when CPU > 80%",
    "severity": 2,
    "enabled": true,
    "condition": {
        "allOf": [{
            "metricName": "Percentage CPU",
            "operator": "GreaterThan",
            "threshold": 80,
            "timeAggregation": "Average",
            "windowSize": "PT5M"
        }]
    },
    "actions": {
        "actionGroups": ["/subscriptions/.../actionGroups/OnCallTeam"]
    }
}
```

**Action Groups:**

```
Action Group: "OnCallTeam"
├─ Email: devops@company.com
├─ SMS: +1-555-0100
├─ Azure Function: https://alerts.azurewebsites.net/api/alert
├─ Logic App: Ticket creation workflow
└─ Webhook: https://slack.com/webhook/alerts
```

**Programmatic Alerts:**

```csharp
using Azure.ResourceManager.Monitor;

public class AlertService
{
    public async Task CreateMetricAlertAsync()
    {
        var alertRule = new MetricAlertResource
        {
            Description = "High error rate alert",
            Severity = 1,
            Enabled = true,
            EvaluationFrequency = TimeSpan.FromMinutes(1),
            WindowSize = TimeSpan.FromMinutes(5),
            Criteria = new MetricAlertCriteria
            {
                AllOf = new[]
                {
                    new MetricCriteria
                    {
                        MetricName = "Failed Requests",
                        Operator = MetricOperator.GreaterThan,
                        Threshold = 10,
                        TimeAggregation = MetricAggregation.Total
                    }
                }
            },
            Actions = new[]
            {
                new AlertAction
                {
                    ActionGroupId = "/subscriptions/.../actionGroups/DevOpsTeam"
                }
            }
        };
    }
}
```

**Best Practices:**

1. Set appropriate thresholds
2. Use action groups for reusability
3. Configure alert severity correctly
4. Avoid alert fatigue
5. Test alerts before production
6. Document alert responses
7. Review and tune regularly

---

✅ **Completed Q100-Q120!** Comprehensive Azure Cloud Services coverage with code examples, best practices, and real-world scenarios!

