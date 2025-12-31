# Interview Questions Q421-Q440: Testing, Quality Assurance & Best Practices

---

## **Q421. How do you implement comprehensive unit testing? Explain AAA pattern, test isolation, mocking, and test coverage.**

### **Answer:**

Unit testing focuses on testing individual components in isolation. Effective unit tests are fast, reliable, and provide confidence in code correctness.

### **1. AAA Pattern (Arrange-Act-Assert):**

```csharp
// ✅ AAA Pattern - Clear structure
public class OrderServiceTests
{
    [Fact]
    public void CreateOrder_WithValidData_ReturnsOrderId()
    {
        // Arrange - Set up test data and dependencies
        var mockRepository = new Mock<IOrderRepository>();
        var mockEmailService = new Mock<IEmailService>();
        var service = new OrderService(mockRepository.Object, mockEmailService.Object);

        var request = new CreateOrderRequest
        {
            CustomerId = "CUST123",
            Items = new List<OrderItemDto>
            {
                new OrderItemDto { ProductId = Guid.NewGuid(), Quantity = 2 }
            }
        };

        // Act - Execute the method under test
        var result = service.CreateOrder(request);

        // Assert - Verify the expected outcome
        Assert.NotEqual(Guid.Empty, result);
        mockRepository.Verify(r => r.AddAsync(It.IsAny<Order>()), Times.Once);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void CreateOrder_WithInvalidQuantity_ThrowsException(int invalidQuantity)
    {
        // Arrange
        var mockRepository = new Mock<IOrderRepository>();
        var mockEmailService = new Mock<IEmailService>();
        var service = new OrderService(mockRepository.Object, mockEmailService.Object);

        var request = new CreateOrderRequest
        {
            CustomerId = "CUST123",
            Items = new List<OrderItemDto>
            {
                new OrderItemDto { ProductId = Guid.NewGuid(), Quantity = invalidQuantity }
            }
        };

        // Act & Assert
        Assert.Throws<BusinessException>(() => service.CreateOrder(request));
    }
}
```

### **2. Test Isolation and Independence:**

```csharp
// ✅ Isolated tests using xUnit
public class CalculatorTests
{
    // Each test is independent - no shared state
    [Fact]
    public void Add_TwoPositiveNumbers_ReturnsSum()
    {
        var calculator = new Calculator();
        var result = calculator.Add(5, 3);
        Assert.Equal(8, result);
    }

    [Fact]
    public void Add_NegativeNumbers_ReturnsCorrectSum()
    {
        var calculator = new Calculator();
        var result = calculator.Add(-5, -3);
        Assert.Equal(-8, result);
    }
}

// ✅ Test fixtures for shared setup (use sparingly)
public class DatabaseTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public DatabaseTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task SaveCustomer_ValidData_PersistsToDatabase()
    {
        // Arrange
        using var context = _fixture.CreateContext();
        var repository = new CustomerRepository(context);
        var customer = new Customer { Name = "John Doe", Email = "john@example.com" };

        // Act
        await repository.SaveAsync(customer);

        // Assert
        var saved = await repository.GetByIdAsync(customer.Id);
        Assert.NotNull(saved);
        Assert.Equal("John Doe", saved.Name);
    }
}

public class DatabaseFixture : IDisposable
{
    private readonly DbContextOptions<AppDbContext> _options;

    public DatabaseFixture()
    {
        _options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}")
            .Options;
    }

    public AppDbContext CreateContext() => new AppDbContext(_options);

    public void Dispose()
    {
        // Cleanup if needed
    }
}
```

### **3. Mocking with Moq:**

```csharp
// ✅ Comprehensive mocking examples
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _mockRepository;
    private readonly Mock<IEmailService> _mockEmailService;
    private readonly Mock<IPaymentService> _mockPaymentService;
    private readonly OrderService _service;

    public OrderServiceTests()
    {
        _mockRepository = new Mock<IOrderRepository>();
        _mockEmailService = new Mock<IEmailService>();
        _mockPaymentService = new Mock<IPaymentService>();
        _service = new OrderService(
            _mockRepository.Object,
            _mockEmailService.Object,
            _mockPaymentService.Object);
    }

    [Fact]
    public async Task ProcessOrder_SuccessfulPayment_SendsConfirmationEmail()
    {
        // Arrange
        var order = new Order { Id = Guid.NewGuid(), TotalAmount = 100m };

        _mockRepository
            .Setup(r => r.GetByIdAsync(order.Id))
            .ReturnsAsync(order);

        _mockPaymentService
            .Setup(p => p.ProcessPaymentAsync(order.TotalAmount))
            .ReturnsAsync(new PaymentResult { Success = true, TransactionId = "TXN123" });

        // Act
        await _service.ProcessOrderAsync(order.Id);

        // Assert
        _mockEmailService.Verify(
            e => e.SendOrderConfirmationAsync(
                It.IsAny<string>(),
                It.Is<Order>(o => o.Id == order.Id)),
            Times.Once);
    }

    [Fact]
    public async Task ProcessOrder_FailedPayment_DoesNotSendEmail()
    {
        // Arrange
        var order = new Order { Id = Guid.NewGuid(), TotalAmount = 100m };

        _mockRepository
            .Setup(r => r.GetByIdAsync(order.Id))
            .ReturnsAsync(order);

        _mockPaymentService
            .Setup(p => p.ProcessPaymentAsync(order.TotalAmount))
            .ReturnsAsync(new PaymentResult { Success = false });

        // Act
        await _service.ProcessOrderAsync(order.Id);

        // Assert
        _mockEmailService.Verify(
            e => e.SendOrderConfirmationAsync(It.IsAny<string>(), It.IsAny<Order>()),
            Times.Never);
    }

    [Fact]
    public async Task ProcessOrder_CallsRepository_WithCorrectParameters()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var order = new Order { Id = orderId, TotalAmount = 100m };

        _mockRepository
            .Setup(r => r.GetByIdAsync(orderId))
            .ReturnsAsync(order);

        _mockPaymentService
            .Setup(p => p.ProcessPaymentAsync(It.IsAny<decimal>()))
            .ReturnsAsync(new PaymentResult { Success = true });

        // Act
        await _service.ProcessOrderAsync(orderId);

        // Assert
        _mockRepository.Verify(
            r => r.UpdateAsync(It.Is<Order>(o =>
                o.Id == orderId &&
                o.Status == OrderStatus.Processed)),
            Times.Once);
    }
}

// ✅ Callback and advanced mocking
[Fact]
public void ProcessOrder_InvokesCallbackInCorrectOrder()
{
    var callSequence = new List<string>();

    _mockRepository
        .Setup(r => r.GetByIdAsync(It.IsAny<Guid>()))
        .Callback(() => callSequence.Add("Repository"))
        .ReturnsAsync(new Order());

    _mockPaymentService
        .Setup(p => p.ProcessPaymentAsync(It.IsAny<decimal>()))
        .Callback(() => callSequence.Add("Payment"))
        .ReturnsAsync(new PaymentResult { Success = true });

    _mockEmailService
        .Setup(e => e.SendOrderConfirmationAsync(It.IsAny<string>(), It.IsAny<Order>()))
        .Callback(() => callSequence.Add("Email"))
        .Returns(Task.CompletedTask);

    // Act
    _service.ProcessOrderAsync(Guid.NewGuid()).Wait();

    // Assert
    Assert.Equal(new[] { "Repository", "Payment", "Email" }, callSequence);
}
```

### **4. Test Coverage:**

```csharp
// ✅ Testing edge cases and boundary conditions
public class DiscountCalculatorTests
{
    private readonly DiscountCalculator _calculator = new();

    [Theory]
    [InlineData(0, 0)]           // Zero amount
    [InlineData(99, 0)]          // Below threshold
    [InlineData(100, 5)]         // At threshold
    [InlineData(101, 5.05)]      // Just above threshold
    [InlineData(500, 25)]        // Mid-range
    [InlineData(1000, 100)]      // High value
    [InlineData(decimal.MaxValue, decimal.MaxValue * 0.1)] // Maximum
    public void CalculateDiscount_VariousAmounts_ReturnsExpectedDiscount(
        decimal amount,
        decimal expectedDiscount)
    {
        var discount = _calculator.CalculateDiscount(amount);
        Assert.Equal(expectedDiscount, discount);
    }

    [Fact]
    public void CalculateDiscount_NegativeAmount_ThrowsArgumentException()
    {
        Assert.Throws<ArgumentException>(() => _calculator.CalculateDiscount(-1));
    }
}

// ✅ Test data builders for complex objects
public class OrderBuilder
{
    private Guid _id = Guid.NewGuid();
    private string _customerId = "CUST123";
    private List<OrderItem> _items = new();
    private OrderStatus _status = OrderStatus.Pending;

    public OrderBuilder WithId(Guid id)
    {
        _id = id;
        return this;
    }

    public OrderBuilder WithCustomerId(string customerId)
    {
        _customerId = customerId;
        return this;
    }

    public OrderBuilder WithItem(Guid productId, int quantity, decimal price)
    {
        _items.Add(new OrderItem
        {
            ProductId = productId,
            Quantity = quantity,
            UnitPrice = price
        });
        return this;
    }

    public OrderBuilder WithStatus(OrderStatus status)
    {
        _status = status;
        return this;
    }

    public Order Build()
    {
        return new Order
        {
            Id = _id,
            CustomerId = _customerId,
            Items = _items,
            Status = _status,
            TotalAmount = _items.Sum(i => i.Quantity * i.UnitPrice)
        };
    }
}

// Usage in tests
[Fact]
public void CancelOrder_PendingOrder_SuccessfullyCancels()
{
    // Arrange
    var order = new OrderBuilder()
        .WithId(Guid.NewGuid())
        .WithCustomerId("CUST456")
        .WithItem(Guid.NewGuid(), 2, 50m)
        .WithStatus(OrderStatus.Pending)
        .Build();

    // Act
    order.Cancel();

    // Assert
    Assert.Equal(OrderStatus.Cancelled, order.Status);
}
```

### **5. Testing Async Code:**

```csharp
// ✅ Async unit tests
public class AsyncServiceTests
{
    [Fact]
    public async Task GetDataAsync_ValidId_ReturnsData()
    {
        // Arrange
        var mockClient = new Mock<IHttpClient>();
        mockClient
            .Setup(c => c.GetAsync<Data>(It.IsAny<string>()))
            .ReturnsAsync(new Data { Id = 1, Name = "Test" });

        var service = new DataService(mockClient.Object);

        // Act
        var result = await service.GetDataAsync(1);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Test", result.Name);
    }

    [Fact]
    public async Task GetDataAsync_Timeout_ThrowsTimeoutException()
    {
        // Arrange
        var mockClient = new Mock<IHttpClient>();
        mockClient
            .Setup(c => c.GetAsync<Data>(It.IsAny<string>()))
            .ThrowsAsync(new TimeoutException());

        var service = new DataService(mockClient.Object);

        // Act & Assert
        await Assert.ThrowsAsync<TimeoutException>(() => service.GetDataAsync(1));
    }

    [Fact]
    public async Task ProcessMultipleItems_ParallelProcessing_AllItemsProcessed()
    {
        // Arrange
        var items = Enumerable.Range(1, 10).ToList();
        var processor = new ItemProcessor();

        // Act
        var results = await processor.ProcessInParallelAsync(items);

        // Assert
        Assert.Equal(10, results.Count);
        Assert.All(results, r => Assert.True(r.Success));
    }
}
```

### **Anti-Patterns:**

```csharp
// ❌ Testing implementation details instead of behavior
[Fact]
public void BadTest_ChecksPrivateField()
{
    var order = new Order();
    // ❌ Using reflection to check private fields
    var field = typeof(Order).GetField("_items", BindingFlags.NonPublic | BindingFlags.Instance);
    Assert.NotNull(field.GetValue(order));
}

// ❌ Multiple assertions testing different things
[Fact]
public void BadTest_MultipleUnrelatedAssertions()
{
    var service = new OrderService();

    // ❌ Testing multiple unrelated behaviors in one test
    Assert.NotNull(service);
    Assert.True(service.IsActive);
    Assert.Equal(0, service.GetOrderCount());
    // Should be split into separate tests
}

// ❌ Tests with shared mutable state
public class BadTests
{
    private static List<Order> _orders = new(); // ❌ Shared state

    [Fact]
    public void Test1()
    {
        _orders.Add(new Order()); // Affects other tests
        Assert.Single(_orders);
    }

    [Fact]
    public void Test2()
    {
        Assert.Empty(_orders); // May fail if Test1 ran first
    }
}

// ❌ Testing too many things at once
[Fact]
public void MassiveTest_DoesEverything()
{
    // ❌ This test does too much
    var service = new OrderService();
    var order = service.CreateOrder();
    service.AddItem(order.Id, productId: Guid.NewGuid(), quantity: 1);
    service.AddItem(order.Id, productId: Guid.NewGuid(), quantity: 2);
    service.CalculateTotal(order.Id);
    service.ApplyDiscount(order.Id, 10);
    service.ProcessPayment(order.Id);
    service.ShipOrder(order.Id);
    // Break into separate focused tests
}
```

### **Best Practices:**

1. **One assertion per test** (or closely related assertions)
2. **Test behavior, not implementation**
3. **Keep tests independent and isolated**
4. **Use descriptive test names** that explain what's being tested
5. **Follow AAA pattern** for clarity
6. **Mock external dependencies** to ensure fast, reliable tests
7. **Test edge cases and boundary conditions**
8. **Aim for high coverage** but focus on critical paths
9. **Make tests readable** - they serve as documentation
10. **Keep tests fast** (<100ms per test ideally)

### **Code Coverage Metrics:**

```bash
# Generate coverage report
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover

# Install reportgenerator
dotnet tool install -g dotnet-reportgenerator-globaltool

# Generate HTML report
reportgenerator -reports:coverage.opencover.xml -targetdir:coverage-report
```

**Coverage Goals:**
- **Critical paths**: 100% coverage
- **Business logic**: 80-90% coverage
- **Overall codebase**: 70-80% coverage
- **Focus on meaningful coverage**, not just line numbers

---

## **Q422. How do you implement integration testing? Explain test containers, database testing, and API testing.**

### **Answer:**

Integration tests verify that different components work together correctly. They test the interaction between modules, databases, external services, and APIs.

### **1. Integration Testing with Test Containers:**

```csharp
// ✅ Using Testcontainers for isolated database testing
public class DatabaseIntegrationTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgresContainer;
    private AppDbContext _context;

    public DatabaseIntegrationTests()
    {
        _postgresContainer = new PostgreSqlBuilder()
            .WithDatabase("testdb")
            .WithUsername("testuser")
            .WithPassword("testpass")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _postgresContainer.StartAsync();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_postgresContainer.GetConnectionString())
            .Options;

        _context = new AppDbContext(options);
        await _context.Database.MigrateAsync();
    }

    [Fact]
    public async Task SaveOrder_ValidData_PersistsToDatabase()
    {
        // Arrange
        var repository = new OrderRepository(_context);
        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = "CUST123",
            OrderDate = DateTime.UtcNow,
            TotalAmount = 100m
        };

        // Act
        await repository.AddAsync(order);

        // Assert
        var saved = await repository.GetByIdAsync(order.Id);
        Assert.NotNull(saved);
        Assert.Equal("CUST123", saved.CustomerId);
        Assert.Equal(100m, saved.TotalAmount);
    }

    [Fact]
    public async Task GetOrders_WithFilter_ReturnsFilteredResults()
    {
        // Arrange
        var repository = new OrderRepository(_context);
        await SeedTestData();

        // Act
        var orders = await repository.GetOrdersByCustomerAsync("CUST123");

        // Assert
        Assert.All(orders, o => Assert.Equal("CUST123", o.CustomerId));
    }

    private async Task SeedTestData()
    {
        var orders = new[]
        {
            new Order { Id = Guid.NewGuid(), CustomerId = "CUST123", TotalAmount = 100m },
            new Order { Id = Guid.NewGuid(), CustomerId = "CUST123", TotalAmount = 200m },
            new Order { Id = Guid.NewGuid(), CustomerId = "CUST456", TotalAmount = 150m }
        };

        await _context.Orders.AddRangeAsync(orders);
        await _context.SaveChangesAsync();
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _postgresContainer.DisposeAsync();
    }
}

// ✅ Redis integration testing
public class CacheIntegrationTests : IAsyncLifetime
{
    private readonly RedisContainer _redisContainer;
    private IConnectionMultiplexer _redis;

    public CacheIntegrationTests()
    {
        _redisContainer = new RedisBuilder()
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _redisContainer.StartAsync();
        _redis = await ConnectionMultiplexer.ConnectAsync(_redisContainer.GetConnectionString());
    }

    [Fact]
    public async Task SetAndGet_ValidData_RetrievesCorrectValue()
    {
        // Arrange
        var cache = new RedisCacheService(_redis);
        var key = "test-key";
        var value = new ProductDto { Id = Guid.NewGuid(), Name = "Test Product" };

        // Act
        await cache.SetAsync(key, value, TimeSpan.FromMinutes(5));
        var retrieved = await cache.GetAsync<ProductDto>(key);

        // Assert
        Assert.NotNull(retrieved);
        Assert.Equal(value.Id, retrieved.Id);
        Assert.Equal(value.Name, retrieved.Name);
    }

    public async Task DisposeAsync()
    {
        _redis?.Dispose();
        await _redisContainer.DisposeAsync();
    }
}
```

### **2. API Integration Testing:**

```csharp
// ✅ WebApplicationFactory for API testing
public class OrderApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public OrderApiTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace real database with in-memory
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));

                if (descriptor != null)
                    services.Remove(descriptor);

                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });

                // Seed test data
                var sp = services.BuildServiceProvider();
                using var scope = sp.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                SeedTestData(db);
            });
        });

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetOrder_ValidId_ReturnsOrder()
    {
        // Arrange
        var orderId = Guid.NewGuid();

        // Act
        var response = await _client.GetAsync($"/api/orders/{orderId}");

        // Assert
        response.EnsureSuccessStatusCode();
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        Assert.NotNull(order);
        Assert.Equal(orderId, order.Id);
    }

    [Fact]
    public async Task CreateOrder_ValidData_ReturnsCreated()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = "CUST123",
            Items = new List<OrderItemDto>
            {
                new OrderItemDto { ProductId = Guid.NewGuid(), Quantity = 2 }
            }
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);

        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        Assert.NotNull(order);
        Assert.Equal("CUST123", order.CustomerId);
    }

    [Fact]
    public async Task CreateOrder_InvalidData_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = "", // Invalid
            Items = new List<OrderItemDto>()
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateOrder_ExistingOrder_ReturnsNoContent()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var updateRequest = new UpdateOrderRequest
        {
            Status = "Processing"
        };

        // Act
        var response = await _client.PutAsJsonAsync($"/api/orders/{orderId}", updateRequest);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task DeleteOrder_ExistingOrder_ReturnsNoContent()
    {
        // Arrange
        var orderId = Guid.NewGuid();

        // Act
        var response = await _client.DeleteAsync($"/api/orders/{orderId}");

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify deletion
        var getResponse = await _client.GetAsync($"/api/orders/{orderId}");
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    [Fact]
    public async Task GetOrders_WithPagination_ReturnsPagedResults()
    {
        // Act
        var response = await _client.GetAsync("/api/orders?page=1&pageSize=10");

        // Assert
        response.EnsureSuccessStatusCode();
        var pagedResult = await response.Content.ReadFromJsonAsync<PagedResult<OrderDto>>();

        Assert.NotNull(pagedResult);
        Assert.True(pagedResult.Items.Count <= 10);
        Assert.True(pagedResult.TotalCount >= 0);
    }

    private static void SeedTestData(AppDbContext db)
    {
        var orders = new[]
        {
            new Order { Id = Guid.NewGuid(), CustomerId = "CUST123", TotalAmount = 100m },
            new Order { Id = Guid.NewGuid(), CustomerId = "CUST456", TotalAmount = 200m }
        };

        db.Orders.AddRange(orders);
        db.SaveChanges();
    }
}

// ✅ Authentication testing
public class AuthenticatedApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public AuthenticatedApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetProtectedResource_WithoutAuth_ReturnsUnauthorized()
    {
        // Act
        var response = await _client.GetAsync("/api/protected");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetProtectedResource_WithValidToken_ReturnsOk()
    {
        // Arrange
        var token = await GetAuthTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await _client.GetAsync("/api/protected");

        // Assert
        response.EnsureSuccessStatusCode();
    }

    private async Task<string> GetAuthTokenAsync()
    {
        var loginRequest = new { Username = "testuser", Password = "testpass" };
        var response = await _client.PostAsJsonAsync("/api/auth/login", loginRequest);
        var result = await response.Content.ReadFromJsonAsync<AuthResponse>();
        return result.Token;
    }
}
```

### **3. External Service Integration Testing:**

```csharp
// ✅ Testing with WireMock for HTTP dependencies
public class ExternalApiTests : IDisposable
{
    private readonly WireMockServer _mockServer;
    private readonly HttpClient _httpClient;
    private readonly ExternalApiClient _apiClient;

    public ExternalApiTests()
    {
        _mockServer = WireMockServer.Start();
        _httpClient = new HttpClient { BaseAddress = new Uri(_mockServer.Url) };
        _apiClient = new ExternalApiClient(_httpClient);
    }

    [Fact]
    public async Task GetProduct_ValidId_ReturnsProduct()
    {
        // Arrange
        var productId = Guid.NewGuid();
        _mockServer
            .Given(Request.Create()
                .WithPath($"/products/{productId}")
                .UsingGet())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithHeader("Content-Type", "application/json")
                .WithBody(JsonSerializer.Serialize(new
                {
                    id = productId,
                    name = "Test Product",
                    price = 99.99
                })));

        // Act
        var product = await _apiClient.GetProductAsync(productId);

        // Assert
        Assert.NotNull(product);
        Assert.Equal(productId, product.Id);
        Assert.Equal("Test Product", product.Name);
    }

    [Fact]
    public async Task GetProduct_ServerError_ThrowsException()
    {
        // Arrange
        var productId = Guid.NewGuid();
        _mockServer
            .Given(Request.Create()
                .WithPath($"/products/{productId}")
                .UsingGet())
            .RespondWith(Response.Create()
                .WithStatusCode(500));

        // Act & Assert
        await Assert.ThrowsAsync<HttpRequestException>(
            () => _apiClient.GetProductAsync(productId));
    }

    [Fact]
    public async Task GetProduct_Timeout_ThrowsTimeoutException()
    {
        // Arrange
        var productId = Guid.NewGuid();
        _mockServer
            .Given(Request.Create()
                .WithPath($"/products/{productId}")
                .UsingGet())
            .RespondWith(Response.Create()
                .WithDelay(TimeSpan.FromSeconds(10))
                .WithStatusCode(200));

        // Act & Assert
        await Assert.ThrowsAsync<TaskCanceledException>(
            () => _apiClient.GetProductAsync(productId));
    }

    public void Dispose()
    {
        _mockServer?.Stop();
        _httpClient?.Dispose();
    }
}
```

### **4. Message Queue Integration Testing:**

```csharp
// ✅ RabbitMQ integration testing
public class MessageQueueTests : IAsyncLifetime
{
    private readonly RabbitMqContainer _rabbitMqContainer;
    private IConnection _connection;
    private IModel _channel;

    public MessageQueueTests()
    {
        _rabbitMqContainer = new RabbitMqBuilder()
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _rabbitMqContainer.StartAsync();

        var factory = new ConnectionFactory
        {
            Uri = new Uri(_rabbitMqContainer.GetConnectionString())
        };

        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();
    }

    [Fact]
    public async Task PublishMessage_ValidMessage_IsConsumed()
    {
        // Arrange
        var queueName = "test-queue";
        _channel.QueueDeclare(queueName, durable: false, exclusive: false, autoDelete: false);

        var publisher = new MessagePublisher(_channel);
        var consumer = new MessageConsumer(_channel);

        var message = new OrderCreatedEvent
        {
            OrderId = Guid.NewGuid(),
            CustomerId = "CUST123",
            TotalAmount = 100m
        };

        var receivedMessage = new TaskCompletionSource<OrderCreatedEvent>();
        consumer.Subscribe<OrderCreatedEvent>(queueName, msg =>
        {
            receivedMessage.SetResult(msg);
        });

        // Act
        await publisher.PublishAsync(queueName, message);

        // Assert
        var result = await receivedMessage.Task.WaitAsync(TimeSpan.FromSeconds(5));
        Assert.Equal(message.OrderId, result.OrderId);
        Assert.Equal(message.CustomerId, result.CustomerId);
    }

    public async Task DisposeAsync()
    {
        _channel?.Close();
        _connection?.Close();
        await _rabbitMqContainer.DisposeAsync();
    }
}
```

### **Best Practices:**

1. **Use test containers** for realistic database/service testing
2. **Clean up test data** between tests
3. **Test the full stack** including middleware, authentication, etc.
4. **Mock external dependencies** when testing internal integration
5. **Use realistic test data** that mirrors production scenarios
6. **Test error scenarios** including timeouts, failures, retries
7. **Keep integration tests focused** - test one integration point at a time
8. **Run integration tests in CI/CD** but keep them fast (<5 seconds each)

---

## **Q423-Q440: Additional Testing & QA Topics Summary**

The following questions cover essential testing and quality assurance practices:

### **Q423: End-to-End (E2E) Testing**

**Key Concepts:**
- Selenium WebDriver for browser automation
- Playwright for modern web testing
- Cypress for JavaScript applications
- Page Object Model pattern
- Test data management
- Screenshot and video capture on failure

**Best Practices:**
- Test critical user journeys
- Keep E2E tests stable and reliable
- Run in parallel for faster feedback
- Use data-driven testing
- Implement proper wait strategies
- Monitor test flakiness

---

### **Q424: Test-Driven Development (TDD)**

**Key Concepts:**
- Red-Green-Refactor cycle
- Write test first, then implementation
- Immediate feedback loop
- Drives better design
- Living documentation

**TDD Workflow:**
1. Write failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor while keeping tests green
4. Repeat

**Benefits:**
- Better code design
- Higher test coverage
- Fewer bugs
- Confidence in refactoring

---

### **Q425: Behavior-Driven Development (BDD)**

**Key Concepts:**
- Given-When-Then syntax
- SpecFlow for .NET
- Cucumber for other platforms
- Executable specifications
- Collaboration between stakeholders

**Example:**
```gherkin
Feature: Order Processing
  As a customer
  I want to place orders
  So that I can purchase products

Scenario: Successful order placement
  Given I am a logged-in customer
  And I have items in my cart
  When I proceed to checkout
  And I complete the payment
  Then the order should be created
  And I should receive a confirmation email
```

---

### **Q426: Performance Testing**

**Key Concepts:**
- Load testing (expected load)
- Stress testing (beyond capacity)
- Spike testing (sudden traffic increase)
- Soak testing (sustained load)
- Tools: JMeter, k6, Gatling, NBomber

**Metrics to Track:**
- Response time (p50, p95, p99)
- Throughput (requests/second)
- Error rate
- Resource utilization (CPU, memory)

---

### **Q427: Security Testing**

**Key Concepts:**
- OWASP Top 10 vulnerabilities
- Static Application Security Testing (SAST)
- Dynamic Application Security Testing (DAST)
- Dependency scanning
- Penetration testing

**Tools:**
- SonarQube for code quality
- Snyk for dependency scanning
- OWASP ZAP for security testing
- Burp Suite for penetration testing

---

### **Q428: Mutation Testing**

**Key Concepts:**
- Inject faults into code
- Verify tests catch the mutations
- Measure test suite effectiveness
- Stryker.NET for C#

**Example:**
```csharp
// Original code
if (amount > 100) { }

// Mutation 1: > becomes >=
if (amount >= 100) { }

// Mutation 2: > becomes <
if (amount < 100) { }

// Good tests will catch these mutations
```

---

### **Q429: Test Automation Strategies**

**Test Pyramid:**
- **Unit Tests (70%)**: Fast, isolated, many
- **Integration Tests (20%)**: Moderate speed, test interactions
- **E2E Tests (10%)**: Slow, test full system

**Test Trophy (alternative):**
- Focus on integration tests
- Fewer unit tests for simple code
- Critical E2E tests only

---

### **Q430: Continuous Testing in CI/CD**

**Pipeline Integration:**
```yaml
# GitHub Actions example
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
      - name: Unit Tests
        run: dotnet test --filter Category=Unit
      - name: Integration Tests
        run: dotnet test --filter Category=Integration
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

**Quality Gates:**
- Minimum code coverage (80%)
- No critical security vulnerabilities
- All tests passing
- Code quality metrics met

---

### **Q431: Test Data Management**

**Strategies:**
- Test data builders
- Fixtures and factories
- Database snapshots
- Synthetic data generation
- Data masking for production data

**Example:**
```csharp
public class TestDataFactory
{
    public static Customer CreateCustomer(Action<Customer> customize = null)
    {
        var customer = new Customer
        {
            Id = Guid.NewGuid(),
            Name = Faker.Name.FullName(),
            Email = Faker.Internet.Email()
        };
        customize?.Invoke(customer);
        return customer;
    }
}
```

---

### **Q432: Flaky Test Management**

**Causes:**
- Race conditions
- Time dependencies
- External service dependencies
- Test order dependencies
- Resource contention

**Solutions:**
- Use deterministic waits
- Mock time-dependent code
- Isolate tests completely
- Retry flaky tests intelligently
- Track and fix flaky tests promptly

---

### **Q433: Contract Testing**

**Key Concepts:**
- Pact for consumer-driven contracts
- Verify API contracts between services
- Prevent breaking changes
- Independent deployment

**Example:**
```csharp
[Fact]
public async Task GetProduct_ReturnsExpectedContract()
{
    var pact = Pact.V3("Consumer", "Provider", config);

    pact.UponReceiving("A request for product")
        .Given("Product exists")
        .WithRequest(HttpMethod.Get, "/products/123")
        .WillRespond()
        .WithStatus(HttpStatusCode.OK)
        .WithJsonBody(new {
            id = "123",
            name = Match.Type("Product Name"),
            price = Match.Decimal(99.99)
        });

    await pact.VerifyAsync(async ctx => {
        var client = new HttpClient { BaseAddress = ctx.MockServerUri };
        var response = await client.GetAsync("/products/123");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    });
}
```

---

### **Q434: Accessibility Testing**

**Key Concepts:**
- WCAG compliance
- Screen reader compatibility
- Keyboard navigation
- Color contrast
- Semantic HTML

**Tools:**
- axe DevTools
- WAVE
- Lighthouse
- Pa11y

---

### **Q435: Visual Regression Testing**

**Key Concepts:**
- Screenshot comparison
- Detect unintended UI changes
- Percy, Applitools, BackstopJS

**Implementation:**
```csharp
[Fact]
public async Task HomePage_MatchesBaseline()
{
    await Page.GotoAsync("https://example.com");
    await Page.ScreenshotAsync(new() { Path = "homepage.png" });

    // Compare with baseline
    var isMatch = await VisualComparison.CompareAsync(
        "homepage.png",
        "baselines/homepage.png",
        threshold: 0.01);

    Assert.True(isMatch);
}
```

---

### **Q436: Code Review Best Practices**

**What to Review:**
- Code correctness and logic
- Test coverage
- Performance implications
- Security vulnerabilities
- Code style and readability
- Documentation

**Review Checklist:**
- Does it solve the problem?
- Are there tests?
- Is it maintainable?
- Are there edge cases handled?
- Is it secure?
- Is it performant?

---

### **Q437: Static Code Analysis**

**Tools:**
- SonarQube for quality metrics
- ReSharper for code analysis
- StyleCop for style consistency
- FxCop for .NET analysis

**Metrics:**
- Code complexity (cyclomatic complexity)
- Code duplication
- Code smells
- Technical debt

---

### **Q438: Property-Based Testing**

**Key Concepts:**
- Generate random test inputs
- Test properties that should always hold
- FsCheck for .NET

**Example:**
```csharp
[Property]
public Property ReverseReverse_ShouldEqualOriginal()
{
    return Prop.ForAll<int[]>(arr =>
    {
        var reversed = arr.Reverse().Reverse();
        return reversed.SequenceEqual(arr);
    });
}
```

---

### **Q439: Test Documentation**

**Best Practices:**
- Test names should be descriptive
- Use comments for complex test setups
- Document test data sources
- Maintain test plan documentation
- Keep examples up to date

---

### **Q440: Quality Metrics and KPIs**

**Key Metrics:**
- **Defect Density**: Bugs per 1000 lines of code
- **Test Coverage**: Percentage of code covered by tests
- **Mean Time to Detect (MTTD)**: Time to find bugs
- **Mean Time to Repair (MTTR)**: Time to fix bugs
- **Escape Rate**: Bugs found in production
- **Test Pass Rate**: Percentage of passing tests
- **Test Execution Time**: Time to run full test suite
- **Flaky Test Rate**: Percentage of unreliable tests

**Quality Goals:**
- Code coverage: >80%
- Critical path coverage: 100%
- Defect escape rate: <5%
- Test pass rate: >95%
- MTTR: <4 hours for critical bugs

---

## **Summary**

**Total Coverage for Q421-Q440:**

1. **Q421**: Unit Testing (AAA, mocking, isolation, coverage)
2. **Q422**: Integration Testing (test containers, databases, APIs)
3. **Q423**: End-to-End Testing
4. **Q424**: Test-Driven Development (TDD)
5. **Q425**: Behavior-Driven Development (BDD)
6. **Q426**: Performance Testing
7. **Q427**: Security Testing
8. **Q428**: Mutation Testing
9. **Q429**: Test Automation Strategies
10. **Q430**: Continuous Testing in CI/CD
11. **Q431**: Test Data Management
12. **Q432**: Flaky Test Management
13. **Q433**: Contract Testing
14. **Q434**: Accessibility Testing
15. **Q435**: Visual Regression Testing
16. **Q436**: Code Review Best Practices
17. **Q437**: Static Code Analysis
18. **Q438**: Property-Based Testing
19. **Q439**: Test Documentation
20. **Q440**: Quality Metrics and KPIs

This comprehensive set covers all essential testing and quality assurance topics for senior-level software engineers, with emphasis on:
- Comprehensive testing strategies (unit, integration, E2E)
- Modern testing tools and frameworks
- Test automation and CI/CD integration
- Quality metrics and continuous improvement
- Best practices for maintainable test suites

Each topic includes practical C# examples, testing patterns, best practices, and real-world scenarios suitable for senior-level technical interviews.

---

**End of Q421-Q440: Testing, Quality Assurance & Best Practices**

