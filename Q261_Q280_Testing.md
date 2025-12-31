# .NET Interview Questions & Answers: Testing (Q261-Q280)

## Q261: What are the different types of testing in .NET? Explain Unit Testing, Integration Testing, and End-to-End Testing.

### Answer

**Testing Types** ensure code quality, reliability, and maintainability at different levels of the application.

**Key Concepts:**
- Unit Testing: Test individual components in isolation
- Integration Testing: Test component interactions
- End-to-End Testing: Test complete user workflows
- Test Pyramid: More unit tests, fewer E2E tests

### Testing Types Overview

```csharp
// ============================================
// 1. UNIT TESTING
// ============================================

// Testing a single method/class in isolation
public class Calculator
{
    public int Add(int a, int b) => a + b;
    public int Subtract(int a, int b) => a - b;
    public int Multiply(int a, int b) => a * b;
    public int Divide(int a, int b)
    {
        if (b == 0)
            throw new DivideByZeroException("Cannot divide by zero");
        return a / b;
    }
}

// Unit test - tests Calculator in isolation
public class CalculatorTests
{
    [Fact]
    public void Add_TwoPositiveNumbers_ReturnsSum()
    {
        // Arrange
        var calculator = new Calculator();

        // Act
        var result = calculator.Add(5, 3);

        // Assert
        Assert.Equal(8, result);
    }

    [Fact]
    public void Divide_ByZero_ThrowsException()
    {
        // Arrange
        var calculator = new Calculator();

        // Act & Assert
        Assert.Throws<DivideByZeroException>(() => calculator.Divide(10, 0));
    }

    [Theory]
    [InlineData(10, 5, 2)]
    [InlineData(20, 4, 5)]
    [InlineData(100, 10, 10)]
    public void Divide_ValidInputs_ReturnsQuotient(int a, int b, int expected)
    {
        // Arrange
        var calculator = new Calculator();

        // Act
        var result = calculator.Divide(a, b);

        // Assert
        Assert.Equal(expected, result);
    }
}
```

### Integration Testing

```csharp
// ============================================
// 2. INTEGRATION TESTING
// ============================================

// Service that depends on repository (real interaction)
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;

    public OrderService(IOrderRepository repository, IEmailService emailService)
    {
        _repository = repository;
        _emailService = emailService;
    }

    public async Task<int> CreateOrderAsync(Order order)
    {
        await _repository.AddAsync(order);
        await _repository.SaveChangesAsync();
        await _emailService.SendOrderConfirmationAsync(order.Id);
        return order.Id;
    }
}

// Integration test - tests real database interaction
public class OrderServiceIntegrationTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public OrderServiceIntegrationTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task CreateOrder_WithValidData_SavesToDatabase()
    {
        // Arrange
        using var context = _fixture.CreateContext();
        var repository = new OrderRepository(context);
        var emailService = new Mock<IEmailService>(); // Still mock external services
        var service = new OrderService(repository, emailService.Object);

        var order = new Order
        {
            CustomerId = 1,
            OrderDate = DateTime.UtcNow,
            TotalAmount = 100
        };

        // Act
        var orderId = await service.CreateOrderAsync(order);

        // Assert
        var savedOrder = await context.Orders.FindAsync(orderId);
        Assert.NotNull(savedOrder);
        Assert.Equal(100, savedOrder.TotalAmount);
    }
}

// Database fixture for integration tests
public class DatabaseFixture : IDisposable
{
    private readonly string _connectionString;

    public DatabaseFixture()
    {
        _connectionString = "Server=(localdb)\\mssqllocaldb;Database=TestDb;Trusted_Connection=True;";

        using var context = CreateContext();
        context.Database.EnsureCreated();
    }

    public ApplicationDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer(_connectionString)
            .Options;

        return new ApplicationDbContext(options);
    }

    public void Dispose()
    {
        using var context = CreateContext();
        context.Database.EnsureDeleted();
    }
}
```

### End-to-End Testing

```csharp
// ============================================
// 3. END-TO-END TESTING (API Testing)
// ============================================

// E2E test using WebApplicationFactory
public class OrdersApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public OrdersApiTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace real database with in-memory database
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));

                if (descriptor != null)
                    services.Remove(descriptor);

                services.AddDbContext<ApplicationDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });
            });
        });

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task CreateOrder_ValidData_ReturnsCreatedOrder()
    {
        // Arrange
        var order = new
        {
            CustomerId = 1,
            Items = new[]
            {
                new { ProductId = 1, Quantity = 2 }
            }
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", order);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var createdOrder = await response.Content.ReadFromJsonAsync<Order>();
        Assert.NotNull(createdOrder);
        Assert.True(createdOrder.Id > 0);
    }

    [Fact]
    public async Task GetOrder_ExistingId_ReturnsOrder()
    {
        // Arrange - create an order first
        var createResponse = await _client.PostAsJsonAsync("/api/orders", new
        {
            CustomerId = 1,
            Items = new[] { new { ProductId = 1, Quantity = 1 } }
        });
        var createdOrder = await createResponse.Content.ReadFromJsonAsync<Order>();

        // Act
        var getResponse = await _client.GetAsync($"/api/orders/{createdOrder.Id}");

        // Assert
        getResponse.EnsureSuccessStatusCode();
        var order = await getResponse.Content.ReadFromJsonAsync<Order>();
        Assert.Equal(createdOrder.Id, order.Id);
    }

    [Fact]
    public async Task GetOrder_NonExistingId_ReturnsNotFound()
    {
        // Act
        var response = await _client.GetAsync("/api/orders/99999");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
```

### Testing Pyramid

```csharp
// ============================================
// 4. TEST PYRAMID PRINCIPLE
// ============================================

/*
        /\
       /  \     E2E Tests (Few, Slow, Expensive)
      /____\    - Test complete user workflows
     /      \   - Use WebApplicationFactory
    /  INTE  \  Integration Tests (Some, Medium Speed)
   /  GRATION \ - Test component interactions
  /____________\  - Use real database (in-memory or test DB)
 /              \
/   UNIT TESTS   \ Unit Tests (Many, Fast, Cheap)
/__________________\ - Test individual methods/classes
                     - Use mocks for dependencies
*/

// Example breakdown for an e-commerce application:

// UNIT TESTS (70%)
// - Calculator logic
// - Validation rules
// - Business logic
// - DTOs and mappings
// - Extension methods

public class OrderValidatorTests
{
    [Fact]
    public void Validate_EmptyItems_ReturnsFalse()
    {
        var validator = new OrderValidator();
        var order = new Order { Items = new List<OrderItem>() };

        var result = validator.Validate(order);

        Assert.False(result.IsValid);
    }
}

// INTEGRATION TESTS (20%)
// - Repository + Database
// - Service + Repository
// - Message queue interactions
// - File system operations

public class OrderRepositoryIntegrationTests
{
    [Fact]
    public async Task GetOrderWithItems_IncludesRelatedData()
    {
        // Test actual EF Core query with real database
    }
}

// E2E TESTS (10%)
// - Complete user workflows
// - API endpoints
// - Authentication flows
// - Critical business scenarios

public class CheckoutFlowTests
{
    [Fact]
    public async Task CompleteCheckout_FromCartToConfirmation_Succeeds()
    {
        // Test entire checkout process
    }
}
```

### Test Organization

```csharp
// ============================================
// 5. TEST PROJECT STRUCTURE
// ============================================

/*
Solution Structure:

MyApp.sln
│
├── src/
│   ├── MyApp.Domain/           (Business logic)
│   ├── MyApp.Application/      (Use cases)
│   ├── MyApp.Infrastructure/   (Data access)
│   └── MyApp.Api/              (Web API)
│
└── tests/
    ├── MyApp.UnitTests/        (Unit tests)
    │   ├── Domain/
    │   ├── Application/
    │   └── Infrastructure/
    │
    ├── MyApp.IntegrationTests/ (Integration tests)
    │   ├── Repositories/
    │   ├── Services/
    │   └── Fixtures/
    │
    └── MyApp.E2ETests/         (End-to-end tests)
        ├── Api/
        └── Workflows/
*/

// Test naming convention
public class OrderService_CreateOrder_Tests
{
    [Fact]
    public void WithValidOrder_SavesSuccessfully()
    {
        // ClassName_MethodName_Scenario
    }

    [Fact]
    public void WithInvalidOrder_ThrowsValidationException()
    {
        // ClassName_MethodName_ExpectedResult
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Follow the Test Pyramid
// 70% Unit, 20% Integration, 10% E2E

// 2. ✅ Use AAA pattern (Arrange, Act, Assert)
[Fact]
public void TestMethod()
{
    // Arrange
    var service = new MyService();

    // Act
    var result = service.DoSomething();

    // Assert
    Assert.True(result);
}

// 3. ✅ One logical assertion per test
[Fact]
public void CreateOrder_ValidData_ReturnsOrderId()
{
    // Focus on one behavior
}

[Fact]
public void CreateOrder_ValidData_SendsConfirmationEmail()
{
    // Separate test for different behavior
}

// 4. ✅ Test behavior, not implementation
// ❌ Bad - testing implementation
[Fact]
public void CreateOrder_CallsRepositoryAddMethod()
{
    // Too focused on how it works
}

// ✅ Good - testing behavior
[Fact]
public void CreateOrder_ValidData_OrderIsPersisted()
{
    // Focus on what it does
}

// 5. ✅ Use descriptive test names
// ❌ Bad
[Fact]
public void Test1() { }

// ✅ Good
[Fact]
public void CreateOrder_WithNegativeAmount_ThrowsArgumentException() { }

// 6. ✅ Keep tests independent
// Each test should run in isolation

// 7. ✅ Fast tests
// Unit tests should run in milliseconds
// Integration tests in seconds

// 8. ✅ Deterministic tests
// Tests should always produce same result

// 9. ✅ Mock external dependencies in unit tests
// Database, APIs, file system, time

// 10. ✅ Use real dependencies in integration tests
// Test actual database queries, real HTTP calls
```

---

## Q262: Explain xUnit, NUnit, and MSTest. What are the differences and which should you use?

### Answer

**Test Frameworks** provide infrastructure for writing and running tests. The three main frameworks in .NET are xUnit, NUnit, and MSTest.

**Key Concepts:**
- Test attributes
- Assertions
- Test lifecycle
- Test discovery
- Parallelization

### xUnit

```csharp
// ============================================
// 1. xUnit (Recommended Modern Framework)
// ============================================

// Install: dotnet add package xunit
// Install: dotnet add package xunit.runner.visualstudio

public class ProductServiceTests
{
    // [Fact] - Single test case
    [Fact]
    public void GetProduct_ValidId_ReturnsProduct()
    {
        // Arrange
        var service = new ProductService();

        // Act
        var result = service.GetProduct(1);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Product 1", result.Name);
    }

    // [Theory] - Data-driven tests
    [Theory]
    [InlineData(1, "Product 1")]
    [InlineData(2, "Product 2")]
    [InlineData(3, "Product 3")]
    public void GetProduct_VariousIds_ReturnsCorrectProduct(int id, string expectedName)
    {
        // Arrange
        var service = new ProductService();

        // Act
        var result = service.GetProduct(id);

        // Assert
        Assert.Equal(expectedName, result.Name);
    }

    // [Theory] with MemberData
    [Theory]
    [MemberData(nameof(GetTestData))]
    public void CalculateDiscount_VariousScenarios(decimal price, int quantity, decimal expected)
    {
        var service = new ProductService();
        var result = service.CalculateDiscount(price, quantity);
        Assert.Equal(expected, result);
    }

    public static IEnumerable<object[]> GetTestData()
    {
        yield return new object[] { 100m, 1, 0m };
        yield return new object[] { 100m, 5, 10m };
        yield return new object[] { 100m, 10, 20m };
    }

    // xUnit doesn't have [SetUp] or [TearDown]
    // Use constructor and IDisposable instead
    private readonly ProductService _service;

    public ProductServiceTests()
    {
        // Runs before each test (like [SetUp])
        _service = new ProductService();
    }

    public void Dispose()
    {
        // Runs after each test (like [TearDown])
        _service?.Dispose();
    }
}

// Class fixtures - shared context across tests
public class DatabaseFixture : IDisposable
{
    public ApplicationDbContext Context { get; private set; }

    public DatabaseFixture()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase("TestDb")
            .Options;

        Context = new ApplicationDbContext(options);
        Context.Database.EnsureCreated();
    }

    public void Dispose()
    {
        Context.Database.EnsureDeleted();
        Context.Dispose();
    }
}

public class OrderServiceTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public OrderServiceTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public void Test_UsesSharedContext()
    {
        // Use _fixture.Context
    }
}
```

### NUnit

```csharp
// ============================================
// 2. NUnit (Mature, Feature-Rich)
// ============================================

// Install: dotnet add package NUnit
// Install: dotnet add package NUnit3TestAdapter

[TestFixture]
public class ProductServiceTests
{
    private ProductService _service;

    // [SetUp] - Runs before each test
    [SetUp]
    public void Setup()
    {
        _service = new ProductService();
    }

    // [TearDown] - Runs after each test
    [TearDown]
    public void TearDown()
    {
        _service?.Dispose();
    }

    // [OneTimeSetUp] - Runs once before all tests
    [OneTimeSetUp]
    public void OneTimeSetup()
    {
        // Initialize expensive resources
    }

    // [OneTimeTearDown] - Runs once after all tests
    [OneTimeTearDown]
    public void OneTimeTearDown()
    {
        // Cleanup expensive resources
    }

    // [Test] - Single test case
    [Test]
    public void GetProduct_ValidId_ReturnsProduct()
    {
        // Act
        var result = _service.GetProduct(1);

        // Assert
        Assert.That(result, Is.Not.Null);
        Assert.That(result.Name, Is.EqualTo("Product 1"));
    }

    // [TestCase] - Data-driven tests
    [TestCase(1, "Product 1")]
    [TestCase(2, "Product 2")]
    [TestCase(3, "Product 3")]
    public void GetProduct_VariousIds_ReturnsCorrectProduct(int id, string expectedName)
    {
        var result = _service.GetProduct(id);
        Assert.That(result.Name, Is.EqualTo(expectedName));
    }

    // [TestCaseSource] - External data source
    [TestCaseSource(nameof(DiscountTestCases))]
    public void CalculateDiscount_VariousScenarios(decimal price, int quantity, decimal expected)
    {
        var result = _service.CalculateDiscount(price, quantity);
        Assert.That(result, Is.EqualTo(expected));
    }

    private static IEnumerable<TestCaseData> DiscountTestCases()
    {
        yield return new TestCaseData(100m, 1, 0m).SetName("No discount for single item");
        yield return new TestCaseData(100m, 5, 10m).SetName("10% discount for 5 items");
        yield return new TestCaseData(100m, 10, 20m).SetName("20% discount for 10 items");
    }

    // [Category] - Group tests
    [Test]
    [Category("Integration")]
    public void Integration_Test()
    {
        // Integration test
    }

    // [Ignore] - Skip test
    [Test]
    [Ignore("Not implemented yet")]
    public void Future_Feature_Test()
    {
    }

    // Constraint-based assertions
    [Test]
    public void NUnit_Assertions_Examples()
    {
        var product = _service.GetProduct(1);

        // Equality
        Assert.That(product.Id, Is.EqualTo(1));

        // Null checks
        Assert.That(product, Is.Not.Null);

        // Type checks
        Assert.That(product, Is.InstanceOf<Product>());

        // String assertions
        Assert.That(product.Name, Does.StartWith("Product"));
        Assert.That(product.Name, Does.Contain("1"));

        // Collection assertions
        var products = _service.GetAllProducts();
        Assert.That(products, Has.Count.EqualTo(10));
        Assert.That(products, Has.Some.Property("Name").EqualTo("Product 1"));

        // Range assertions
        Assert.That(product.Price, Is.InRange(0, 1000));

        // Exception assertions
        Assert.That(() => _service.GetProduct(-1),
            Throws.TypeOf<ArgumentException>()
                  .With.Message.Contains("Invalid ID"));
    }
}
```

### MSTest

```csharp
// ============================================
// 3. MSTest (Microsoft's Framework)
// ============================================

// Install: dotnet add package MSTest.TestFramework
// Install: dotnet add package MSTest.TestAdapter

[TestClass]
public class ProductServiceTests
{
    private ProductService _service;

    // [TestInitialize] - Runs before each test
    [TestInitialize]
    public void Initialize()
    {
        _service = new ProductService();
    }

    // [TestCleanup] - Runs after each test
    [TestCleanup]
    public void Cleanup()
    {
        _service?.Dispose();
    }

    // [ClassInitialize] - Runs once before all tests
    [ClassInitialize]
    public static void ClassInitialize(TestContext context)
    {
        // Initialize expensive resources
    }

    // [ClassCleanup] - Runs once after all tests
    [ClassCleanup]
    public static void ClassCleanup()
    {
        // Cleanup expensive resources
    }

    // [TestMethod] - Single test case
    [TestMethod]
    public void GetProduct_ValidId_ReturnsProduct()
    {
        // Act
        var result = _service.GetProduct(1);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual("Product 1", result.Name);
    }

    // [DataTestMethod] - Data-driven tests
    [DataTestMethod]
    [DataRow(1, "Product 1")]
    [DataRow(2, "Product 2")]
    [DataRow(3, "Product 3")]
    public void GetProduct_VariousIds_ReturnsCorrectProduct(int id, string expectedName)
    {
        var result = _service.GetProduct(id);
        Assert.AreEqual(expectedName, result.Name);
    }

    // [DynamicData] - External data source
    [DataTestMethod]
    [DynamicData(nameof(GetDiscountTestData), DynamicDataSourceType.Method)]
    public void CalculateDiscount_VariousScenarios(decimal price, int quantity, decimal expected)
    {
        var result = _service.CalculateDiscount(price, quantity);
        Assert.AreEqual(expected, result);
    }

    private static IEnumerable<object[]> GetDiscountTestData()
    {
        yield return new object[] { 100m, 1, 0m };
        yield return new object[] { 100m, 5, 10m };
        yield return new object[] { 100m, 10, 20m };
    }

    // [TestCategory] - Group tests
    [TestMethod]
    [TestCategory("Integration")]
    public void Integration_Test()
    {
        // Integration test
    }

    // [Ignore] - Skip test
    [TestMethod]
    [Ignore]
    public void Future_Feature_Test()
    {
    }

    // MSTest assertions
    [TestMethod]
    public void MSTest_Assertions_Examples()
    {
        var product = _service.GetProduct(1);

        // Equality
        Assert.AreEqual(1, product.Id);
        Assert.AreNotEqual(2, product.Id);

        // Null checks
        Assert.IsNotNull(product);
        Assert.IsNull(product.DeletedAt);

        // Type checks
        Assert.IsInstanceOfType(product, typeof(Product));

        // Boolean
        Assert.IsTrue(product.IsActive);
        Assert.IsFalse(product.IsDeleted);

        // String assertions
        StringAssert.StartsWith(product.Name, "Product");
        StringAssert.Contains(product.Name, "1");

        // Collection assertions
        var products = _service.GetAllProducts();
        CollectionAssert.AllItemsAreNotNull(products);
        CollectionAssert.AllItemsAreInstancesOfType(products, typeof(Product));

        // Exception assertions
        Assert.ThrowsException<ArgumentException>(() => _service.GetProduct(-1));
    }
}
```

### Comparison

```csharp
// ============================================
// 4. FRAMEWORK COMPARISON
// ============================================

/*
┌─────────────────┬──────────────┬──────────────┬──────────────┐
│ Feature         │ xUnit        │ NUnit        │ MSTest       │
├─────────────────┼──────────────┼──────────────┼──────────────┤
│ Test Attribute  │ [Fact]       │ [Test]       │ [TestMethod] │
│ Data Tests      │ [Theory]     │ [TestCase]   │ [DataTest]   │
│ Setup           │ Constructor  │ [SetUp]      │ [Initialize] │
│ Teardown        │ IDisposable  │ [TearDown]   │ [Cleanup]    │
│ Parallel        │ Yes (default)│ Yes (opt-in) │ Yes (opt-in) │
│ Assertions      │ Assert.*     │ Assert.That  │ Assert.*     │
│ .NET Core       │ ✅ Excellent │ ✅ Excellent │ ✅ Excellent │
│ Community       │ ✅ Large     │ ✅ Large     │ ⚠️ Medium    │
│ Documentation   │ ✅ Good      │ ✅ Excellent │ ✅ Good      │
│ Modern Features │ ✅ Yes       │ ✅ Yes       │ ⚠️ Catching up│
└─────────────────┴──────────────┴──────────────┴──────────────┘
*/

// XUNIT - Modern, clean, recommended for new projects
// ✅ No [SetUp]/[TearDown], uses constructor/Dispose
// ✅ Parallel by default (faster)
// ✅ Used by ASP.NET Core team
// ✅ Modern design, encourages good practices
// ❌ Different syntax from traditional frameworks

// NUNIT - Feature-rich, mature
// ✅ Rich constraint-based assertions
// ✅ Lots of attributes and features
// ✅ Mature ecosystem
// ✅ Excellent documentation
// ❌ More verbose

// MSTEST - Microsoft's framework
// ✅ Integrated with Visual Studio
// ✅ Good for enterprise teams using Microsoft stack
// ✅ Improving with each version
// ❌ Historically slower to add features
// ❌ Less popular in community
```

---

### Best Practices

```csharp
// 1. ✅ Choose xUnit for new projects
// Modern, clean, used by Microsoft internally

// 2. ✅ Stick with what your team knows
// All three are production-ready

// 3. ✅ Use consistent framework across solution
// Don't mix frameworks

// 4. ✅ Leverage data-driven tests
// xUnit: [Theory]
// NUnit: [TestCase]
// MSTest: [DataTestMethod]

// 5. ✅ Use shared fixtures wisely
// xUnit: IClassFixture<T>
// NUnit: [OneTimeSetUp]
// MSTest: [ClassInitialize]

// 6. ✅ Enable parallel execution
// xUnit: Parallel by default
// NUnit: [Parallelizable]
// MSTest: [DoNotParallelize] to opt out

// 7. ✅ Migration path exists
// Can migrate between frameworks if needed
// Tools available to help

// 8. ✅ Use appropriate assertions
// All frameworks have rich assertion libraries

// 9. ✅ Consider test output
// xUnit: ITestOutputHelper
// NUnit: TestContext.Out
// MSTest: TestContext

// 10. ✅ Integration with CI/CD
// All work with Azure DevOps, GitHub Actions, etc.
```

---

## Q263: Explain Mocking in unit tests. How do you use Moq and NSubstitute?

### Answer

**Mocking** creates fake implementations of dependencies to isolate the unit being tested. Mock frameworks like Moq and NSubstitute make this easy.

**Key Concepts:**
- Test Doubles: Mocks, Stubs, Fakes, Spies
- Behavior verification
- Return value setup
- Callback handling

### Moq Framework

```csharp
// ============================================
// 1. MOQ - MOST POPULAR MOCKING FRAMEWORK
// ============================================

// Install: dotnet add package Moq

public interface IEmailService
{
    void SendEmail(string to, string subject, string body);
    Task<bool> SendEmailAsync(string to, string subject, string body);
    int GetEmailCount();
}

public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;

    public OrderService(IOrderRepository repository, IEmailService emailService)
    {
        _repository = repository;
        _emailService = emailService;
    }

    public async Task<Order> CreateOrderAsync(Order order)
    {
        await _repository.AddAsync(order);
        await _repository.SaveAsync();

        _emailService.SendEmail(
            order.CustomerEmail,
            "Order Confirmation",
            $"Your order {order.Id} has been created");

        return order;
    }
}

public class OrderServiceTests
{
    [Fact]
    public async Task CreateOrder_ValidOrder_SendsConfirmationEmail()
    {
        // Arrange
        var mockRepository = new Mock<IOrderRepository>();
        var mockEmailService = new Mock<IEmailService>();

        var service = new OrderService(
            mockRepository.Object,
            mockEmailService.Object);

        var order = new Order
        {
            Id = 1,
            CustomerEmail = "customer@example.com"
        };

        // Act
        await service.CreateOrderAsync(order);

        // Assert - Verify method was called
        mockEmailService.Verify(
            x => x.SendEmail(
                "customer@example.com",
                "Order Confirmation",
                It.Is<string>(msg => msg.Contains("order 1"))),
            Times.Once);
    }

    // Setup return values
    [Fact]
    public void GetOrder_ExistingId_ReturnsOrder()
    {
        // Arrange
        var mockRepository = new Mock<IOrderRepository>();

        // Setup: when GetById is called with 1, return this order
        mockRepository
            .Setup(x => x.GetById(1))
            .Returns(new Order { Id = 1, Total = 100 });

        var service = new OrderService(mockRepository.Object, null);

        // Act
        var result = service.GetOrder(1);

        // Assert
        Assert.Equal(1, result.Id);
        Assert.Equal(100, result.Total);
    }

    // Setup async methods
    [Fact]
    public async Task SendNotification_Success_ReturnsTrue()
    {
        // Arrange
        var mockEmailService = new Mock<IEmailService>();

        mockEmailService
            .Setup(x => x.SendEmailAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>()))
            .ReturnsAsync(true);

        // Act
        var result = await mockEmailService.Object.SendEmailAsync("test@test.com", "Subject", "Body");

        // Assert
        Assert.True(result);
    }

    // Verify method was NOT called
    [Fact]
    public void CancelOrder_UnpaidOrder_DoesNotSendRefundEmail()
    {
        // Arrange
        var mockEmailService = new Mock<IEmailService>();
        var service = new OrderService(null, mockEmailService.Object);

        // Act
        service.CancelOrder(new Order { IsPaid = false });

        // Assert
        mockEmailService.Verify(
            x => x.SendEmail(
                It.IsAny<string>(),
                It.Is<string>(s => s.Contains("Refund")),
                It.IsAny<string>()),
            Times.Never);
    }

    // Setup properties
    [Fact]
    public void GetEmailCount_ReturnsSetupValue()
    {
        // Arrange
        var mockEmailService = new Mock<IEmailService>();
        mockEmailService.Setup(x => x.GetEmailCount()).Returns(42);

        // Act
        var count = mockEmailService.Object.GetEmailCount();

        // Assert
        Assert.Equal(42, count);
    }

    // Setup with callbacks
    [Fact]
    public void CreateOrder_CapturesOrderData()
    {
        // Arrange
        var mockRepository = new Mock<IOrderRepository>();
        Order capturedOrder = null;

        mockRepository
            .Setup(x => x.AddAsync(It.IsAny<Order>()))
            .Callback<Order>(order => capturedOrder = order)
            .Returns(Task.CompletedTask);

        var service = new OrderService(mockRepository.Object, null);

        // Act
        var order = new Order { Total = 100 };
        service.CreateOrderAsync(order);

        // Assert
        Assert.NotNull(capturedOrder);
        Assert.Equal(100, capturedOrder.Total);
    }

    // Setup exception throwing
    [Fact]
    public void ProcessPayment_PaymentFails_ThrowsException()
    {
        // Arrange
        var mockPaymentService = new Mock<IPaymentService>();

        mockPaymentService
            .Setup(x => x.ProcessPayment(It.IsAny<decimal>()))
            .Throws<PaymentException>();

        // Act & Assert
        Assert.Throws<PaymentException>(() =>
            mockPaymentService.Object.ProcessPayment(100));
    }

    // It.IsAny, It.Is - Argument matchers
    [Fact]
    public void ArgumentMatchers_Examples()
    {
        var mock = new Mock<IEmailService>();

        // Any string
        mock.Setup(x => x.SendEmail(
            It.IsAny<string>(),
            It.IsAny<string>(),
            It.IsAny<string>()));

        // Specific condition
        mock.Setup(x => x.SendEmail(
            It.Is<string>(email => email.EndsWith("@example.com")),
            It.IsAny<string>(),
            It.IsAny<string>()));

        // Regex match
        mock.Setup(x => x.SendEmail(
            It.IsRegex(@"^\w+@\w+\.\w+$"),
            It.IsAny<string>(),
            It.IsAny<string>()));
    }

    // Mock behavior - Strict vs Loose
    [Fact]
    public void StrictMock_UnconfiguredCall_ThrowsException()
    {
        // Strict: All calls must be explicitly setup
        var strictMock = new Mock<IEmailService>(MockBehavior.Strict);

        // This will throw because SendEmail is not setup
        Assert.Throws<MockException>(() =>
            strictMock.Object.SendEmail("test@test.com", "Subject", "Body"));
    }

    [Fact]
    public void LooseMock_UnconfiguredCall_ReturnsDefault()
    {
        // Loose (default): Unconfigured calls return default values
        var looseMock = new Mock<IEmailService>(MockBehavior.Loose);

        // This returns default(int) = 0
        var count = looseMock.Object.GetEmailCount();
        Assert.Equal(0, count);
    }
}
```

### NSubstitute Framework

```csharp
// ============================================
// 2. NSUBSTITUTE - CLEANER SYNTAX
// ============================================

// Install: dotnet add package NSubstitute

public class OrderServiceNSubstituteTests
{
    [Fact]
    public async Task CreateOrder_ValidOrder_SendsConfirmationEmail()
    {
        // Arrange
        var repository = Substitute.For<IOrderRepository>();
        var emailService = Substitute.For<IEmailService>();

        var service = new OrderService(repository, emailService);

        var order = new Order
        {
            Id = 1,
            CustomerEmail = "customer@example.com"
        };

        // Act
        await service.CreateOrderAsync(order);

        // Assert - Verify method was called
        emailService.Received(1).SendEmail(
            "customer@example.com",
            "Order Confirmation",
            Arg.Is<string>(msg => msg.Contains("order 1")));
    }

    // Setup return values
    [Fact]
    public void GetOrder_ExistingId_ReturnsOrder()
    {
        // Arrange
        var repository = Substitute.For<IOrderRepository>();

        // Setup return value
        repository.GetById(1).Returns(new Order { Id = 1, Total = 100 });

        var service = new OrderService(repository, null);

        // Act
        var result = service.GetOrder(1);

        // Assert
        Assert.Equal(1, result.Id);
    }

    // Setup async methods
    [Fact]
    public async Task SendNotification_Success_ReturnsTrue()
    {
        // Arrange
        var emailService = Substitute.For<IEmailService>();

        emailService
            .SendEmailAsync(
                Arg.Any<string>(),
                Arg.Any<string>(),
                Arg.Any<string>())
            .Returns(true);

        // Act
        var result = await emailService.SendEmailAsync("test@test.com", "Subject", "Body");

        // Assert
        Assert.True(result);
    }

    // Verify method was NOT called
    [Fact]
    public void CancelOrder_UnpaidOrder_DoesNotSendRefundEmail()
    {
        // Arrange
        var emailService = Substitute.For<IEmailService>();
        var service = new OrderService(null, emailService);

        // Act
        service.CancelOrder(new Order { IsPaid = false });

        // Assert
        emailService.DidNotReceive().SendEmail(
            Arg.Any<string>(),
            Arg.Is<string>(s => s.Contains("Refund")),
            Arg.Any<string>());
    }

    // Argument capturing
    [Fact]
    public void CreateOrder_CapturesOrderData()
    {
        // Arrange
        var repository = Substitute.For<IOrderRepository>();
        var service = new OrderService(repository, null);

        // Act
        var order = new Order { Total = 100 };
        service.CreateOrderAsync(order);

        // Assert - Get the captured argument
        repository.Received().AddAsync(Arg.Is<Order>(o => o.Total == 100));
    }

    // Throw exceptions
    [Fact]
    public void ProcessPayment_PaymentFails_ThrowsException()
    {
        // Arrange
        var paymentService = Substitute.For<IPaymentService>();

        paymentService
            .When(x => x.ProcessPayment(Arg.Any<decimal>()))
            .Do(x => throw new PaymentException());

        // Act & Assert
        Assert.Throws<PaymentException>(() =>
            paymentService.ProcessPayment(100));
    }

    // Callbacks
    [Fact]
    public void CreateOrder_ExecutesCallback()
    {
        // Arrange
        var repository = Substitute.For<IOrderRepository>();
        var callbackExecuted = false;

        repository
            .When(x => x.AddAsync(Arg.Any<Order>()))
            .Do(x => callbackExecuted = true);

        // Act
        repository.AddAsync(new Order());

        // Assert
        Assert.True(callbackExecuted);
    }

    // Argument matchers
    [Fact]
    public void ArgumentMatchers_Examples()
    {
        var emailService = Substitute.For<IEmailService>();

        // Any argument
        emailService.SendEmail(
            Arg.Any<string>(),
            Arg.Any<string>(),
            Arg.Any<string>());

        // Specific condition
        emailService.SendEmail(
            Arg.Is<string>(email => email.EndsWith("@example.com")),
            Arg.Any<string>(),
            Arg.Any<string>());
    }

    // Multiple return values
    [Fact]
    public void GetValue_MultipleCalls_ReturnsDifferentValues()
    {
        var service = Substitute.For<IService>();

        service.GetValue().Returns(1, 2, 3);

        Assert.Equal(1, service.GetValue());
        Assert.Equal(2, service.GetValue());
        Assert.Equal(3, service.GetValue());
        Assert.Equal(3, service.GetValue()); // Returns last value
    }
}
```

### Test Doubles

```csharp
// ============================================
// 3. TEST DOUBLES - Mocks, Stubs, Fakes, Spies
// ============================================

// STUB - Returns predetermined values
public class EmailServiceStub : IEmailService
{
    public void SendEmail(string to, string subject, string body)
    {
        // Does nothing
    }

    public Task<bool> SendEmailAsync(string to, string subject, string body)
    {
        return Task.FromResult(true); // Always succeeds
    }

    public int GetEmailCount()
    {
        return 0; // Predetermined value
    }
}

// FAKE - Working implementation, but simpler (e.g., in-memory database)
public class FakeOrderRepository : IOrderRepository
{
    private readonly List<Order> _orders = new();
    private int _nextId = 1;

    public Task AddAsync(Order order)
    {
        order.Id = _nextId++;
        _orders.Add(order);
        return Task.CompletedTask;
    }

    public Task<Order> GetByIdAsync(int id)
    {
        return Task.FromResult(_orders.FirstOrDefault(o => o.Id == id));
    }

    public Task<List<Order>> GetAllAsync()
    {
        return Task.FromResult(_orders.ToList());
    }
}

// SPY - Records how it was called
public class EmailServiceSpy : IEmailService
{
    public List<EmailCall> Calls { get; } = new();

    public void SendEmail(string to, string subject, string body)
    {
        Calls.Add(new EmailCall { To = to, Subject = subject, Body = body });
    }

    public Task<bool> SendEmailAsync(string to, string subject, string body)
    {
        Calls.Add(new EmailCall { To = to, Subject = subject, Body = body });
        return Task.FromResult(true);
    }

    public int GetEmailCount() => Calls.Count;
}

public class EmailCall
{
    public string To { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
}

// Usage examples
public class TestDoublesExamples
{
    [Fact]
    public void UsingStub_SimpleTest()
    {
        // Use stub when you don't care about interactions
        var emailStub = new EmailServiceStub();
        var service = new OrderService(null, emailStub);

        service.NotifyCustomer();
        // Don't verify anything - stub just returns values
    }

    [Fact]
    public async Task UsingFake_BehaviorTest()
    {
        // Use fake for testing behavior with simplified implementation
        var fakeRepository = new FakeOrderRepository();
        var service = new OrderService(fakeRepository, null);

        var order = new Order { Total = 100 };
        await service.CreateOrderAsync(order);

        var saved = await fakeRepository.GetByIdAsync(order.Id);
        Assert.Equal(100, saved.Total);
    }

    [Fact]
    public void UsingSpy_VerifyInteractions()
    {
        // Use spy to verify how methods were called
        var emailSpy = new EmailServiceSpy();
        var service = new OrderService(null, emailSpy);

        service.NotifyCustomer();

        Assert.Single(emailSpy.Calls);
        Assert.Equal("customer@example.com", emailSpy.Calls[0].To);
    }

    [Fact]
    public void UsingMock_FullControl()
    {
        // Use mock (Moq/NSubstitute) for full control and verification
        var mockEmail = new Mock<IEmailService>();

        mockEmail
            .Setup(x => x.SendEmail(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()))
            .Verifiable();

        var service = new OrderService(null, mockEmail.Object);
        service.NotifyCustomer();

        mockEmail.Verify(); // Verify all setups were called
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Mock interfaces, not concrete classes
// Prefer: Mock<IEmailService>
// Avoid: Mock<EmailService>

// 2. ✅ Use Moq or NSubstitute
// Both are production-ready
// Moq: More popular, traditional syntax
// NSubstitute: Cleaner, more readable

// 3. ✅ Don't mock value objects or DTOs
// ❌ var mockOrder = new Mock<Order>();
// ✅ var order = new Order { Id = 1 };

// 4. ✅ Verify behavior, not implementation
// ✅ Verify important interactions
mock.Verify(x => x.SendEmail(...), Times.Once);

// ❌ Over-verification
mock.Verify(x => x.GetInternalState(), Times.Once); // Too detailed

// 5. ✅ Use appropriate test doubles
// Stub: When you need return values
// Fake: When you need working implementation
// Mock: When you need to verify interactions
// Spy: When you need to record calls

// 6. ✅ Setup only what you need
// Don't setup methods that aren't called

// 7. ✅ Use argument matchers appropriately
mock.Setup(x => x.Method(It.IsAny<string>()));  // Any value
mock.Setup(x => x.Method(It.Is<string>(s => s.Length > 5))); // Specific condition

// 8. ❌ Don't mock everything
// Mock external dependencies
// Use real objects for:
// - Value objects
// - Data models
// - Simple logic

// 9. ✅ One mock verification per test
// Keep tests focused

// 10. ✅ Clean up mocks in tests
// xUnit: Use constructor/Dispose
// NUnit: Use [SetUp]/[TearDown]
```

---

## Q264: What is Test-Driven Development (TDD)? Explain the Red-Green-Refactor cycle.

### Answer

**Test-Driven Development (TDD)** is a software development approach where tests are written before the code. The Red-Green-Refactor cycle ensures code is testable, correct, and clean.

**Key Concepts:**
- Red: Write failing test
- Green: Make test pass
- Refactor: Improve code
- Test first, code second

### TDD Cycle

```csharp
// ============================================
// 1. RED-GREEN-REFACTOR CYCLE
// ============================================

/* TDD CYCLE:

   1. RED    - Write a failing test
   2. GREEN  - Write minimum code to pass
   3. REFACTOR - Improve code quality
   4. REPEAT
*/

// EXAMPLE: Building a Calculator with TDD

// === ITERATION 1: Add Method ===

// RED - Write failing test first
[Fact]
public void Add_TwoPositiveNumbers_ReturnsSum()
{
    // Arrange
    var calculator = new Calculator();  // Doesn't exist yet!

    // Act
    var result = calculator.Add(2, 3);  // Method doesn't exist!

    // Assert
    Assert.Equal(5, result);
}

// GREEN - Write minimum code to pass
public class Calculator
{
    public int Add(int a, int b)
    {
        return 5;  // Hardcoded! But test passes
    }
}

// Add another test to force real implementation
[Theory]
[InlineData(2, 3, 5)]
[InlineData(5, 7, 12)]
[InlineData(0, 0, 0)]
public void Add_VariousNumbers_ReturnsCorrectSum(int a, int b, int expected)
{
    var calculator = new Calculator();
    var result = calculator.Add(a, b);
    Assert.Equal(expected, result);
}

// GREEN - Now implement properly
public class Calculator
{
    public int Add(int a, int b)
    {
        return a + b;  // Real implementation
    }
}

// REFACTOR - Code is already simple, no refactoring needed

// === ITERATION 2: Subtract Method ===

// RED - Test first
[Fact]
public void Subtract_TwoNumbers_ReturnsDifference()
{
    var calculator = new Calculator();
    var result = calculator.Subtract(10, 3);
    Assert.Equal(7, result);
}

// GREEN - Implement
public class Calculator
{
    public int Add(int a, int b) => a + b;

    public int Subtract(int a, int b) => a - b;
}

// === ITERATION 3: Divide with validation ===

// RED - Test for normal case
[Fact]
public void Divide_ValidNumbers_ReturnsQuotient()
{
    var calculator = new Calculator();
    var result = calculator.Divide(10, 2);
    Assert.Equal(5, result);
}

// RED - Test for edge case
[Fact]
public void Divide_ByZero_ThrowsException()
{
    var calculator = new Calculator();

    Assert.Throws<DivideByZeroException>(() =>
        calculator.Divide(10, 0));
}

// GREEN - Implement
public class Calculator
{
    public int Add(int a, int b) => a + b;
    public int Subtract(int a, int b) => a - b;

    public int Divide(int a, int b)
    {
        if (b == 0)
            throw new DivideByZeroException("Cannot divide by zero");
        return a / b;
    }
}
```

### Real-World TDD Example

```csharp
// ============================================
// 2. TDD FOR SHOPPING CART
// ============================================

// REQUIREMENT: Shopping cart that can add items and calculate total

// === ITERATION 1: Create empty cart ===

// RED
[Fact]
public void NewCart_IsEmpty()
{
    var cart = new ShoppingCart();
    Assert.Equal(0, cart.ItemCount);
}

// GREEN
public class ShoppingCart
{
    public int ItemCount => 0;
}

// === ITERATION 2: Add item to cart ===

// RED
[Fact]
public void AddItem_IncreasesItemCount()
{
    var cart = new ShoppingCart();
    cart.AddItem(new CartItem { ProductId = 1, Quantity = 1, Price = 10 });

    Assert.Equal(1, cart.ItemCount);
}

// GREEN
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();

    public int ItemCount => _items.Count;

    public void AddItem(CartItem item)
    {
        _items.Add(item);
    }
}

// === ITERATION 3: Calculate total ===

// RED
[Fact]
public void GetTotal_WithItems_ReturnsCorrectSum()
{
    var cart = new ShoppingCart();
    cart.AddItem(new CartItem { ProductId = 1, Quantity = 2, Price = 10 });
    cart.AddItem(new CartItem { ProductId = 2, Quantity = 1, Price = 15 });

    var total = cart.GetTotal();

    Assert.Equal(35, total);  // (2 * 10) + (1 * 15) = 35
}

// GREEN
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();

    public int ItemCount => _items.Count;

    public void AddItem(CartItem item)
    {
        _items.Add(item);
    }

    public decimal GetTotal()
    {
        return _items.Sum(item => item.Quantity * item.Price);
    }
}

// === ITERATION 4: Add same product increases quantity ===

// RED
[Fact]
public void AddItem_SameProduct_IncreasesQuantity()
{
    var cart = new ShoppingCart();
    cart.AddItem(new CartItem { ProductId = 1, Quantity = 2, Price = 10 });
    cart.AddItem(new CartItem { ProductId = 1, Quantity = 3, Price = 10 });

    Assert.Equal(1, cart.ItemCount);  // Still one unique item
    Assert.Equal(50, cart.GetTotal()); // (2 + 3) * 10 = 50
}

// GREEN
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();

    public int ItemCount => _items.Count;

    public void AddItem(CartItem item)
    {
        var existingItem = _items.FirstOrDefault(i => i.ProductId == item.ProductId);

        if (existingItem != null)
        {
            existingItem.Quantity += item.Quantity;
        }
        else
        {
            _items.Add(item);
        }
    }

    public decimal GetTotal()
    {
        return _items.Sum(item => item.Quantity * item.Price);
    }
}

// REFACTOR - Extract method
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();

    public int ItemCount => _items.Count;

    public void AddItem(CartItem item)
    {
        var existingItem = FindItem(item.ProductId);

        if (existingItem != null)
        {
            existingItem.Quantity += item.Quantity;
        }
        else
        {
            _items.Add(item);
        }
    }

    public decimal GetTotal()
    {
        return _items.Sum(CalculateItemTotal);
    }

    private CartItem FindItem(int productId) =>
        _items.FirstOrDefault(i => i.ProductId == productId);

    private decimal CalculateItemTotal(CartItem item) =>
        item.Quantity * item.Price;
}
```

### TDD Benefits and Anti-Patterns

```csharp
// ============================================
// 3. TDD BENEFITS & ANTI-PATTERNS
// ============================================

// ✅ BENEFITS OF TDD
/*
1. Forces you to think about design before implementation
2. Ensures code is testable
3. Provides documentation through tests
4. Catches bugs early
5. Enables fearless refactoring
6. Reduces debugging time
7. Improves code quality
*/

// ❌ ANTI-PATTERNS TO AVOID

// 1. Writing tests after code (Not TDD!)
// ❌ Bad
public void ImplementFeature()
{
    // Write code first
    // Then write tests
}

// ✅ Good TDD
public void ImplementFeature()
{
    // Write test first (RED)
    // Write code to pass (GREEN)
    // Refactor (REFACTOR)
}

// 2. Testing implementation details
// ❌ Bad - fragile test
[Fact]
public void SaveOrder_CallsRepositoryAdd()
{
    var mockRepo = new Mock<IRepository>();
    var service = new OrderService(mockRepo.Object);

    service.SaveOrder(new Order());

    mockRepo.Verify(x => x.Add(It.IsAny<Order>()), Times.Once);
}

// ✅ Good - test behavior
[Fact]
public void SaveOrder_ValidOrder_OrderIsPersisted()
{
    var service = new OrderService(new FakeRepository());
    var order = new Order { Id = 1 };

    service.SaveOrder(order);

    var saved = service.GetOrder(1);
    Assert.NotNull(saved);
}

// 3. Over-mocking
// ❌ Bad - mocking too much
[Fact]
public void CalculatePrice_Test()
{
    var mockProduct = new Mock<Product>();  // Don't mock data objects!
    mockProduct.Setup(x => x.Price).Returns(100);

    var calculator = new PriceCalculator();
    var result = calculator.Calculate(mockProduct.Object);

    Assert.Equal(100, result);
}

// ✅ Good - use real objects
[Fact]
public void CalculatePrice_Product_ReturnsCorrectPrice()
{
    var product = new Product { Price = 100 };  // Real object

    var calculator = new PriceCalculator();
    var result = calculator.Calculate(product);

    Assert.Equal(100, result);
}

// 4. Large test methods
// ❌ Bad - testing multiple things
[Fact]
public void OrderService_Tests()
{
    // Test creating order
    // Test updating order
    // Test deleting order
    // ... 100 lines of test code
}

// ✅ Good - one test per behavior
[Fact]
public void CreateOrder_ValidData_ReturnsOrderId() { }

[Fact]
public void UpdateOrder_ExistingOrder_UpdatesSuccessfully() { }

[Fact]
public void DeleteOrder_ExistingOrder_DeletesSuccessfully() { }
```

### TDD Workflow

```csharp
// ============================================
// 4. PRACTICAL TDD WORKFLOW
// ============================================

// Step-by-step TDD process for a new feature

// FEATURE: User registration with email validation

// Step 1: RED - Write first failing test
[Fact]
public void Register_ValidEmail_ReturnsSuccess()
{
    var service = new UserRegistrationService();

    var result = service.Register("user@example.com", "password123");

    Assert.True(result.IsSuccess);
}

// Step 2: GREEN - Minimum code to pass
public class UserRegistrationService
{
    public RegistrationResult Register(string email, string password)
    {
        return new RegistrationResult { IsSuccess = true };
    }
}

// Step 3: RED - Add validation test
[Fact]
public void Register_InvalidEmail_ReturnsError()
{
    var service = new UserRegistrationService();

    var result = service.Register("invalid-email", "password123");

    Assert.False(result.IsSuccess);
    Assert.Equal("Invalid email format", result.ErrorMessage);
}

// Step 4: GREEN - Implement validation
public class UserRegistrationService
{
    public RegistrationResult Register(string email, string password)
    {
        if (!IsValidEmail(email))
        {
            return new RegistrationResult
            {
                IsSuccess = false,
                ErrorMessage = "Invalid email format"
            };
        }

        return new RegistrationResult { IsSuccess = true };
    }

    private bool IsValidEmail(string email)
    {
        return email.Contains("@") && email.Contains(".");
    }
}

// Step 5: REFACTOR - Improve code
public class UserRegistrationService
{
    private readonly IEmailValidator _emailValidator;

    public UserRegistrationService(IEmailValidator emailValidator)
    {
        _emailValidator = emailValidator;
    }

    public RegistrationResult Register(string email, string password)
    {
        if (!_emailValidator.IsValid(email))
        {
            return RegistrationResult.Failure("Invalid email format");
        }

        return RegistrationResult.Success();
    }
}

// Continue this cycle for each requirement...
```

---

### Best Practices

```csharp
// 1. ✅ Always start with a failing test (RED)
// Ensures the test actually tests something

// 2. ✅ Write minimum code to pass (GREEN)
// Don't over-engineer

// 3. ✅ Refactor after tests pass
// Improve design while tests provide safety net

// 4. ✅ One test at a time
// Don't write multiple tests before implementing

// 5. ✅ Test behavior, not implementation
// Tests should survive refactoring

// 6. ✅ Keep tests simple
// Complex tests indicate complex code

// 7. ✅ Run tests frequently
// After every small change

// 8. ✅ Use meaningful test names
// Test name should describe the behavior

// 9. ✅ Don't skip refactor step
// Code quality matters

// 10. ✅ TDD is a design tool
// Not just about testing - drives better design
```

---

## Q265: How do you test async/await code? What are common pitfalls?

### Answer

Testing async code requires understanding how to properly await asynchronous operations and avoid common pitfalls.

**Key Concepts:**
- Always return Task from async tests
- Use async/await consistently
- Avoid async void
- Test timeout scenarios

### Testing Async Methods

```csharp
// ============================================
// 1. TESTING ASYNC METHODS
// ============================================

// Service with async methods
public class UserService
{
    private readonly IUserRepository _repository;

    public UserService(IUserRepository repository)
    {
        _repository = repository;
    }

    public async Task<User> GetUserAsync(int id)
    {
        await Task.Delay(100); // Simulate async work
        return await _repository.GetByIdAsync(id);
    }

    public async Task<bool> CreateUserAsync(User user)
    {
        await _repository.AddAsync(user);
        await _repository.SaveChangesAsync();
        return true;
    }
}

// ✅ CORRECT - Async test with proper await
[Fact]
public async Task GetUserAsync_ValidId_ReturnsUser()
{
    // Arrange
    var mockRepo = new Mock<IUserRepository>();
    mockRepo.Setup(x => x.GetByIdAsync(1))
        .ReturnsAsync(new User { Id = 1, Name = "John" });

    var service = new UserService(mockRepo.Object);

    // Act
    var result = await service.GetUserAsync(1);

    // Assert
    Assert.NotNull(result);
    Assert.Equal("John", result.Name);
}

// ❌ WRONG - Not awaiting async method
[Fact]
public void GetUserAsync_ValidId_ReturnsUser_WRONG()
{
    var mockRepo = new Mock<IUserRepository>();
    var service = new UserService(mockRepo.Object);

    // This doesn't actually wait for the result!
    var task = service.GetUserAsync(1);

    // Test completes before async operation finishes
    // Assert.NotNull(task.Result); // Can cause deadlocks!
}

// ✅ CORRECT - Testing multiple async calls
[Fact]
public async Task CreateMultipleUsers_AllSucceed()
{
    // Arrange
    var mockRepo = new Mock<IUserRepository>();
    mockRepo.Setup(x => x.AddAsync(It.IsAny<User>()))
        .Returns(Task.CompletedTask);
    mockRepo.Setup(x => x.SaveChangesAsync())
        .Returns(Task.CompletedTask);

    var service = new UserService(mockRepo.Object);

    // Act
    var user1Task = service.CreateUserAsync(new User { Name = "User1" });
    var user2Task = service.CreateUserAsync(new User { Name = "User2" });

    await Task.WhenAll(user1Task, user2Task);

    // Assert
    Assert.True(await user1Task);
    Assert.True(await user2Task);
}
```

### Testing Task Completion

```csharp
// ============================================
// 2. TESTING TASK STATES
// ============================================

public class AsyncOperations
{
    public async Task<string> CompletedOperation()
    {
        await Task.CompletedTask;
        return "Done";
    }

    public Task<string> SynchronousOperation()
    {
        return Task.FromResult("Instant");
    }

    public async Task<string> DelayedOperation(int milliseconds)
    {
        await Task.Delay(milliseconds);
        return "Delayed";
    }

    public async Task<string> FaultedOperation()
    {
        await Task.Delay(10);
        throw new InvalidOperationException("Operation failed");
    }
}

// Test completed task
[Fact]
public async Task CompletedOperation_ReturnsImmediately()
{
    var ops = new AsyncOperations();

    var result = await ops.CompletedOperation();

    Assert.Equal("Done", result);
}

// Test synchronous task
[Fact]
public async Task SynchronousOperation_NoDelay()
{
    var ops = new AsyncOperations();

    var stopwatch = Stopwatch.StartNew();
    var result = await ops.SynchronousOperation();
    stopwatch.Stop();

    Assert.Equal("Instant", result);
    Assert.True(stopwatch.ElapsedMilliseconds < 50);
}

// Test with timeout
[Fact]
public async Task DelayedOperation_WithTimeout_Succeeds()
{
    var ops = new AsyncOperations();

    using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
    var task = ops.DelayedOperation(100);

    var result = await task.WaitAsync(cts.Token);

    Assert.Equal("Delayed", result);
}

// Test faulted task
[Fact]
public async Task FaultedOperation_ThrowsException()
{
    var ops = new AsyncOperations();

    await Assert.ThrowsAsync<InvalidOperationException>(
        async () => await ops.FaultedOperation());
}
```

### Common Pitfalls

```csharp
// ============================================
// 3. COMMON ASYNC TESTING PITFALLS
// ============================================

// ❌ PITFALL 1: Using .Result or .Wait()
[Fact]
public void BadTest_UsingResult()
{
    var service = new UserService(null);

    // Can cause deadlocks in some contexts!
    var result = service.GetUserAsync(1).Result;

    // ✅ Use async/await instead
}

// ❌ PITFALL 2: Not awaiting in test
[Fact]
public async Task BadTest_NotAwaiting()
{
    var service = new UserService(null);

    // Test completes before this finishes!
    service.GetUserAsync(1);  // Missing await

    // Assertions may run before async operation completes
}

// ❌ PITFALL 3: async void test method
// [Fact]
// public async void BadTest_AsyncVoid()  // Never use async void!
// {
//     await service.GetUserAsync(1);
// }

// ✅ CORRECT: async Task
[Fact]
public async Task GoodTest_AsyncTask()
{
    var mockRepo = new Mock<IUserRepository>();
    mockRepo.Setup(x => x.GetByIdAsync(1))
        .ReturnsAsync(new User { Id = 1 });

    var service = new UserService(mockRepo.Object);

    var result = await service.GetUserAsync(1);

    Assert.NotNull(result);
}

// ❌ PITFALL 4: Not setting up async methods properly
[Fact]
public async Task BadMockSetup()
{
    var mockRepo = new Mock<IUserRepository>();

    // ❌ Wrong - Returns Task<Task<User>>
    mockRepo.Setup(x => x.GetByIdAsync(1))
        .Returns(Task.FromResult(Task.FromResult(new User { Id = 1 })));

    // ✅ Correct - Use ReturnsAsync
    mockRepo.Setup(x => x.GetByIdAsync(1))
        .ReturnsAsync(new User { Id = 1 });
}

// ❌ PITFALL 5: Testing fire-and-forget methods
public class BadService
{
    public void ProcessAsync(string data)
    {
        // Fire and forget - hard to test!
        Task.Run(async () =>
        {
            await Task.Delay(100);
            // Do something
        });
    }
}

// ✅ Better design - return Task
public class GoodService
{
    public async Task ProcessAsync(string data)
    {
        await Task.Delay(100);
        // Do something - can be awaited in tests
    }
}
```

### Testing with CancellationToken

```csharp
// ============================================
// 4. TESTING CANCELLATION
// ============================================

public class CancellableService
{
    public async Task<string> LongRunningOperationAsync(CancellationToken cancellationToken)
    {
        for (int i = 0; i < 10; i++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await Task.Delay(100, cancellationToken);
        }
        return "Completed";
    }
}

// Test successful completion
[Fact]
public async Task LongRunningOperation_WithoutCancellation_Completes()
{
    var service = new CancellableService();

    var result = await service.LongRunningOperationAsync(CancellationToken.None);

    Assert.Equal("Completed", result);
}

// Test cancellation
[Fact]
public async Task LongRunningOperation_WithCancellation_ThrowsOperationCanceledException()
{
    var service = new CancellableService();
    var cts = new CancellationTokenSource();

    var task = service.LongRunningOperationAsync(cts.Token);

    // Cancel after 50ms
    await Task.Delay(50);
    cts.Cancel();

    await Assert.ThrowsAsync<OperationCanceledException>(async () => await task);
}

// Test with timeout
[Fact]
public async Task LongRunningOperation_WithTimeout_Cancels()
{
    var service = new CancellableService();
    var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(200));

    await Assert.ThrowsAsync<OperationCanceledException>(
        async () => await service.LongRunningOperationAsync(cts.Token));
}
```

---

### Best Practices

```csharp
// 1. ✅ Always use async Task for test methods
[Fact]
public async Task TestMethod() { }  // ✅

// 2. ✅ Use ReturnsAsync for mocking async methods
mock.Setup(x => x.GetAsync()).ReturnsAsync(value);

// 3. ✅ Always await async calls in tests
await service.MethodAsync();

// 4. ❌ Never use .Result or .Wait() in tests
// var result = task.Result;  // Can cause deadlocks

// 5. ✅ Test cancellation scenarios
[Fact]
public async Task Method_WithCancellation_Cancels()
{
    var cts = new CancellationTokenSource();
    cts.Cancel();
    await Assert.ThrowsAsync<OperationCanceledException>(
        async () => await service.MethodAsync(cts.Token));
}

// 6. ✅ Use Task.WhenAll for parallel operations
await Task.WhenAll(task1, task2, task3);

// 7. ✅ Test timeout scenarios
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
await task.WaitAsync(cts.Token);

// 8. ✅ Return Task from async methods, not void
public async Task Method() { }  // ✅
// public async void Method() { }  // ❌

// 9. ✅ Use ValueTask for hot paths when appropriate
public ValueTask<int> GetCachedValue() { }

// 10. ✅ Test exception propagation in async code
await Assert.ThrowsAsync<SpecificException>(
    async () => await method());
```

---

## Q266: What is Code Coverage and how do you measure it in .NET?

### Answer

**Code Coverage** measures the percentage of code executed by tests. It helps identify untested code but shouldn't be the only metric for test quality.

**Key Concepts:**
- Line coverage
- Branch coverage
- Method coverage
- Coverage tools

### Measuring Code Coverage

```csharp
// ============================================
// 1. CODE COVERAGE BASICS
// ============================================

// Example class to test
public class Calculator
{
    public int Add(int a, int b)
    {
        return a + b;  // Line 1
    }

    public int Divide(int a, int b)
    {
        if (b == 0)  // Line 1 (branch)
        {
            throw new DivideByZeroException();  // Line 2
        }
        return a / b;  // Line 3
    }

    public string GetSign(int number)
    {
        if (number > 0)  // Branch 1
            return "Positive";
        else if (number < 0)  // Branch 2
            return "Negative";
        else  // Branch 3
            return "Zero";
    }
}

// Test with partial coverage
public class CalculatorTests
{
    [Fact]
    public void Add_TwoNumbers_ReturnsSum()
    {
        var calc = new Calculator();
        var result = calc.Add(2, 3);
        Assert.Equal(5, result);
    }
    // Coverage: Add method = 100%

    [Fact]
    public void Divide_ValidNumbers_ReturnsQuotient()
    {
        var calc = new Calculator();
        var result = calc.Divide(10, 2);
        Assert.Equal(5, result);
    }
    // Coverage: Divide method = 50% (only happy path, not exception branch)

    [Fact]
    public void GetSign_PositiveNumber_ReturnsPositive()
    {
        var calc = new Calculator();
        var result = calc.GetSign(5);
        Assert.Equal("Positive", result);
    }
    // Coverage: GetSign method = 33% (only one branch)
}

// Full coverage tests
public class CalculatorFullCoverageTests
{
    [Theory]
    [InlineData(2, 3, 5)]
    [InlineData(-2, 3, 1)]
    [InlineData(0, 0, 0)]
    public void Add_VariousInputs_ReturnsCorrectSum(int a, int b, int expected)
    {
        var calc = new Calculator();
        Assert.Equal(expected, calc.Add(a, b));
    }

    [Fact]
    public void Divide_ValidNumbers_ReturnsQuotient()
    {
        var calc = new Calculator();
        Assert.Equal(5, calc.Divide(10, 2));
    }

    [Fact]
    public void Divide_ByZero_ThrowsException()
    {
        var calc = new Calculator();
        Assert.Throws<DivideByZeroException>(() => calc.Divide(10, 0));
    }
    // Now Divide is 100% covered

    [Theory]
    [InlineData(5, "Positive")]
    [InlineData(-5, "Negative")]
    [InlineData(0, "Zero")]
    public void GetSign_VariousNumbers_ReturnsCorrectSign(int number, string expected)
    {
        var calc = new Calculator();
        Assert.Equal(expected, calc.GetSign(number));
    }
    // Now GetSign is 100% covered
}
```

### Using Coverlet

```bash
# ============================================
# 2. USING COVERLET FOR CODE COVERAGE
# ============================================

# Install Coverlet
dotnet add package coverlet.collector

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Output:
# Coverage file: coverage.cobertura.xml

# Generate HTML report using ReportGenerator
dotnet tool install -g dotnet-reportgenerator-globaltool

reportgenerator \
  -reports:"**/coverage.cobertura.xml" \
  -targetdir:"coveragereport" \
  -reporttypes:Html

# View report
# Open coveragereport/index.html in browser

# Set coverage threshold (fail if below 80%)
dotnet test /p:CollectCoverage=true /p:Threshold=80 /p:ThresholdType=line

# Exclude files from coverage
# Add to .csproj:
<PropertyGroup>
  <ExcludeFromCodeCoverage>true</ExcludeFromCodeCoverage>
</PropertyGroup>

# Or use attribute on specific members:
[ExcludeFromCodeCoverage]
public class GeneratedCode { }
```

### Coverage Report Example

```csharp
// ============================================
// 3. INTERPRETING COVERAGE REPORTS
// ============================================

/*
Coverage Summary:
┌─────────────────────┬──────────┬──────────┬────────────┐
│ Module              │ Line     │ Branch   │ Method     │
├─────────────────────┼──────────┼──────────┼────────────┤
│ MyApp.Core          │ 85.2%    │ 78.5%    │ 90.3%      │
│ MyApp.Services      │ 92.1%    │ 85.7%    │ 95.0%      │
│ MyApp.Controllers   │ 45.3%    │ 40.2%    │ 60.1%      │
│ MyApp.Models        │ 100%     │ 100%     │ 100%       │
└─────────────────────┴──────────┴──────────┴────────────┘

Line Coverage: % of code lines executed
Branch Coverage: % of decision branches executed
Method Coverage: % of methods executed

Good coverage:
- Critical business logic: 90%+
- Services: 80%+
- Controllers: 70%+
- Models/DTOs: Not critical (often auto-generated properties)
*/

// Example: Analyzing uncovered code
public class OrderService
{
    public decimal CalculateDiscount(Order order)
    {
        // ✅ Covered by tests
        if (order.TotalAmount > 1000)
        {
            return order.TotalAmount * 0.10m;
        }

        // ✅ Covered by tests
        if (order.TotalAmount > 500)
        {
            return order.TotalAmount * 0.05m;
        }

        // ❌ NOT covered - missing test case!
        if (order.CustomerType == CustomerType.VIP)
        {
            return order.TotalAmount * 0.15m;
        }

        // ✅ Covered by tests
        return 0;
    }
}

// Coverage report shows:
// Line Coverage: 75% (3 of 4 branches covered)
// Missing: VIP customer branch

// Add test to cover missing branch
[Fact]
public void CalculateDiscount_VIPCustomer_Returns15Percent()
{
    var order = new Order
    {
        TotalAmount = 100,
        CustomerType = CustomerType.VIP
    };
    var service = new OrderService();

    var discount = service.CalculateDiscount(order);

    Assert.Equal(15m, discount);
}
// Now coverage is 100%
```

### Coverage in CI/CD

```yaml
# ============================================
# 4. COVERAGE IN CI/CD PIPELINE
# ============================================

# Azure DevOps Pipeline
steps:
- task: DotNetCoreCLI@2
  displayName: 'Run Tests with Coverage'
  inputs:
    command: 'test'
    arguments: '--configuration Release --collect:"XPlat Code Coverage"'
    projects: '**/*Tests.csproj'

- task: PublishCodeCoverageResults@1
  displayName: 'Publish Code Coverage'
  inputs:
    codeCoverageTool: 'Cobertura'
    summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'

# GitHub Actions
- name: Test with coverage
  run: dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/**/coverage.cobertura.xml

# Quality Gate - Fail build if coverage drops
- name: Check coverage threshold
  run: |
    dotnet test /p:CollectCoverage=true \
                /p:CoverletOutputFormat=cobertura \
                /p:Threshold=80 \
                /p:ThresholdType=line \
                /p:ThresholdStat=total
```

---

### Best Practices

```csharp
// 1. ✅ Aim for high coverage on critical code
// Business logic: 90%+
// Data access: 80%+
// Controllers: 70%+

// 2. ❌ Don't aim for 100% coverage everywhere
// Some code doesn't need testing:
[ExcludeFromCodeCoverage]
public class Program
{
    public static void Main(string[] args) { }
}

// 3. ✅ Focus on branch coverage, not just line coverage
// Ensure all decision paths are tested

// 4. ✅ Use coverage to find untested code
// Not as the only metric of test quality

// 5. ✅ Test critical business logic thoroughly
[Theory]
[InlineData(...)]  // Test all branches
public void CriticalBusinessLogic_AllScenarios_Work() { }

// 6. ❌ Don't write tests just for coverage
// Write meaningful tests that verify behavior

// 7. ✅ Exclude generated code
[GeneratedCode("Tool", "Version")]
[ExcludeFromCodeCoverage]
public class Generated { }

// 8. ✅ Monitor coverage trends over time
// Set up coverage reports in CI/CD

// 9. ✅ Set reasonable coverage goals
// 80% is a good target for most projects

// 10. ✅ Coverage + Quality = Success
// High coverage with bad tests = False security
// Focus on both coverage AND test quality
```

---

## **Q267: What is FluentAssertions and how does it improve test readability?**

**Answer:**

FluentAssertions is a popular assertion library that provides a more readable and expressive syntax for writing test assertions compared to traditional assertion methods.

**Benefits:**
1. **Natural Language Syntax** - Reads like English
2. **Better Error Messages** - Detailed failure descriptions
3. **IntelliSense Support** - Discoverable API
4. **Rich Assertion Library** - Supports all common scenarios
5. **Extensible** - Create custom assertions

**Installation:**
```bash
dotnet add package FluentAssertions
```

**Basic Assertions:**
```csharp
using FluentAssertions;
using Xunit;

public class FluentAssertionsExamples
{
    // ============================================
    // String Assertions
    // ============================================

    [Fact]
    public void String_Assertions_Example()
    {
        string actual = "Hello World";

        // Traditional xUnit
        Assert.Equal("Hello World", actual);
        Assert.Contains("World", actual);
        Assert.StartsWith("Hello", actual);

        // FluentAssertions - More readable
        actual.Should().Be("Hello World");
        actual.Should().Contain("World");
        actual.Should().StartWith("Hello");
        actual.Should().EndWith("World");
        actual.Should().NotBeNullOrEmpty();
        actual.Should().HaveLength(11);
        actual.Should().Match("Hello *");
    }

    // ============================================
    // Numeric Assertions
    // ============================================

    [Fact]
    public void Numeric_Assertions_Example()
    {
        int value = 15;

        value.Should().Be(15);
        value.Should().BeGreaterThan(10);
        value.Should().BeLessThan(20);
        value.Should().BeInRange(10, 20);
        value.Should().BePositive();

        // Floating point with precision
        double pi = 3.14159;
        pi.Should().BeApproximately(3.14, 0.01);
    }

    // ============================================
    // Collection Assertions
    // ============================================

    [Fact]
    public void Collection_Assertions_Example()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 };

        numbers.Should().HaveCount(5);
        numbers.Should().Contain(3);
        numbers.Should().NotContain(10);
        numbers.Should().ContainInOrder(1, 2, 3);
        numbers.Should().OnlyContain(x => x > 0);
        numbers.Should().BeInAscendingOrder();

        var empty = new int[0];
        empty.Should().BeEmpty();
        empty.Should().NotBeNull();
    }

    // ============================================
    // Object Assertions
    // ============================================

    [Fact]
    public void Object_Assertions_Example()
    {
        var user = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            Age = 30
        };

        // Null checks
        user.Should().NotBeNull();

        // Property assertions
        user.Name.Should().Be("John Doe");
        user.Age.Should().BeGreaterThan(18);

        // Multiple property assertions
        user.Should().Match<User>(u =>
            u.Id == 1 &&
            u.Name == "John Doe");

        // Structural equality
        var expected = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            Age = 30
        };

        user.Should().BeEquivalentTo(expected);

        // Partial matching - ignore some properties
        user.Should().BeEquivalentTo(expected, options =>
            options.Excluding(u => u.Id));
    }

    // ============================================
    // Exception Assertions
    // ============================================

    [Fact]
    public void Exception_Assertions_Example()
    {
        Action act = () => throw new InvalidOperationException("Something went wrong");

        // Assert exception is thrown
        act.Should().Throw<InvalidOperationException>();

        // Assert with message
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("Something went wrong");

        // Assert with message pattern
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*went wrong*");

        // Assert inner exception
        Action actWithInner = () =>
            throw new InvalidOperationException("Outer",
                new ArgumentException("Inner"));

        actWithInner.Should().Throw<InvalidOperationException>()
            .WithInnerException<ArgumentException>()
            .WithMessage("Inner");
    }

    // ============================================
    // Async Assertions
    // ============================================

    [Fact]
    public async Task Async_Assertions_Example()
    {
        Func<Task<string>> act = async () =>
        {
            await Task.Delay(100);
            return "Result";
        };

        await act.Should().NotThrowAsync();

        var result = await act.Invoke();
        result.Should().Be("Result");

        // Assert async exception
        Func<Task> failingAct = async () =>
        {
            await Task.Delay(10);
            throw new InvalidOperationException("Async error");
        };

        await failingAct.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("Async error");
    }

    // ============================================
    // DateTime Assertions
    // ============================================

    [Fact]
    public void DateTime_Assertions_Example()
    {
        var now = DateTime.UtcNow;

        now.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
        now.Should().BeAfter(DateTime.UtcNow.AddDays(-1));
        now.Should().BeBefore(DateTime.UtcNow.AddDays(1));

        var date = new DateTime(2024, 1, 15);
        date.Should().HaveYear(2024);
        date.Should().HaveMonth(1);
        date.Should().HaveDay(15);
    }

    // ============================================
    // Custom Assertions - Extension Methods
    // ============================================

    [Fact]
    public void Custom_Assertions_Example()
    {
        var user = new User { Age = 25, IsActive = true };

        user.Should().BeValidUser();
    }
}

// ============================================
// Extension Methods for Custom Assertions
// ============================================

public static class UserAssertionExtensions
{
    public static AndConstraint<User> BeValidUser(
        this ObjectAssertions<User> assertions,
        string because = "",
        params object[] becauseArgs)
    {
        var user = assertions.Subject;

        user.Should().NotBeNull();
        user.Age.Should().BeGreaterThan(0, "age must be positive");
        user.Name.Should().NotBeNullOrEmpty("name is required");
        user.IsActive.Should().BeTrue("user must be active");

        return new AndConstraint<User>(user);
    }
}

// ============================================
// Real-World Example: Testing UserService
// ============================================

public class UserServiceTests
{
    private readonly Mock<IUserRepository> _mockRepository;
    private readonly UserService _service;

    public UserServiceTests()
    {
        _mockRepository = new Mock<IUserRepository>();
        _service = new UserService(_mockRepository.Object);
    }

    [Fact]
    public async Task GetUserById_ExistingUser_ReturnsUser()
    {
        // Arrange
        var expectedUser = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            Age = 30,
            IsActive = true
        };

        _mockRepository
            .Setup(x => x.GetByIdAsync(1))
            .ReturnsAsync(expectedUser);

        // Act
        var result = await _service.GetUserByIdAsync(1);

        // Assert - Traditional
        Assert.NotNull(result);
        Assert.Equal(1, result.Id);
        Assert.Equal("John Doe", result.Name);

        // Assert - FluentAssertions (Much more readable!)
        result.Should().NotBeNull();
        result.Should().BeEquivalentTo(expectedUser);
        result.Name.Should().Be("John Doe");
        result.Age.Should().BeGreaterThan(18);
        result.Email.Should().Contain("@");
    }

    [Fact]
    public async Task CreateUser_InvalidData_ThrowsValidationException()
    {
        // Arrange
        var invalidUser = new User { Name = "", Age = -1 };

        // Act
        Func<Task> act = async () => await _service.CreateUserAsync(invalidUser);

        // Assert - FluentAssertions provides excellent error messages
        await act.Should().ThrowAsync<ValidationException>()
            .WithMessage("*Name*required*")
            .Where(ex => ex.Errors.Any(e => e.PropertyName == "Name"));
    }

    [Fact]
    public async Task GetActiveUsers_MultipleUsers_ReturnsOnlyActive()
    {
        // Arrange
        var users = new List<User>
        {
            new User { Id = 1, Name = "Active User", IsActive = true },
            new User { Id = 2, Name = "Inactive User", IsActive = false },
            new User { Id = 3, Name = "Another Active", IsActive = true }
        };

        _mockRepository
            .Setup(x => x.GetAllAsync())
            .ReturnsAsync(users);

        // Act
        var result = await _service.GetActiveUsersAsync();

        // Assert - FluentAssertions collection assertions
        result.Should().HaveCount(2);
        result.Should().OnlyContain(u => u.IsActive);
        result.Should().Contain(u => u.Name == "Active User");
        result.Should().NotContain(u => u.Name == "Inactive User");
        result.Select(u => u.Id).Should().BeEquivalentTo(new[] { 1, 3 });
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use FluentAssertions for better readability
   - Tests become self-documenting
   - Error messages are much clearer

2. ✅ Chain assertions for related checks
   user.Should().NotBeNull()
       .And.BeEquivalentTo(expected);

3. ✅ Use BeEquivalentTo for object comparison
   - Compares by value, not reference
   - Can exclude properties
   - Handles nested objects

4. ✅ Leverage custom assertions for domain rules
   - Create extension methods for repeated validations
   - Makes tests more expressive

5. ✅ Use descriptive assertion messages
   value.Should().BeGreaterThan(0, "user age must be positive");

6. ✅ Take advantage of better error messages
   FluentAssertions shows:
   - Expected vs Actual values
   - Differences in collections
   - Which property failed in objects

7. ❌ Don't mix assertion styles
   - Stick with either FluentAssertions or traditional
   - Consistency improves readability

8. ✅ Use Should().Match for complex conditions
   user.Should().Match<User>(u =>
       u.Age > 18 && u.Email.Contains("@"));

9. ✅ Use collection assertions effectively
   - HaveCount, Contain, OnlyContain
   - BeInAscendingOrder, BeEquivalentTo

10. ✅ Combine with Moq for powerful tests
    - Mock setup for arrange
    - FluentAssertions for assert
*/
```

---

## **Q268: How do you test code that uses Entity Framework Core?**

**Answer:**

Testing EF Core code requires isolating database operations. Common approaches include using InMemory database, SQLite in-memory, or test containers.

**Approach 1: EF Core InMemory Database**
```csharp
using Microsoft.EntityFrameworkCore;
using Xunit;

// ============================================
// DbContext Setup
// ============================================

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Product>()
            .HasIndex(p => p.Sku)
            .IsUnique();
    }
}

// ============================================
// Repository Implementation
// ============================================

public interface IProductRepository
{
    Task<Product> GetByIdAsync(int id);
    Task<IEnumerable<Product>> GetAllAsync();
    Task<Product> AddAsync(Product product);
    Task UpdateAsync(Product product);
    Task DeleteAsync(int id);
}

public class ProductRepository : IProductRepository
{
    private readonly ApplicationDbContext _context;

    public ProductRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Product> GetByIdAsync(int id)
    {
        return await _context.Products
            .Include(p => p.Orders)
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<IEnumerable<Product>> GetAllAsync()
    {
        return await _context.Products
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public async Task<Product> AddAsync(Product product)
    {
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return product;
    }

    public async Task UpdateAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product != null)
        {
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
        }
    }
}

// ============================================
// Testing with InMemory Database
// ============================================

public class ProductRepositoryTests : IDisposable
{
    private readonly ApplicationDbContext _context;
    private readonly ProductRepository _repository;

    public ProductRepositoryTests()
    {
        // Create InMemory database with unique name per test
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new ApplicationDbContext(options);
        _repository = new ProductRepository(_context);

        // Seed test data
        SeedTestData();
    }

    private void SeedTestData()
    {
        _context.Products.AddRange(
            new Product { Id = 1, Name = "Product 1", Price = 10.99m, Sku = "SKU001" },
            new Product { Id = 2, Name = "Product 2", Price = 20.99m, Sku = "SKU002" },
            new Product { Id = 3, Name = "Product 3", Price = 30.99m, Sku = "SKU003" }
        );
        _context.SaveChanges();
    }

    [Fact]
    public async Task GetByIdAsync_ExistingProduct_ReturnsProduct()
    {
        // Act
        var result = await _repository.GetByIdAsync(1);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(1);
        result.Name.Should().Be("Product 1");
        result.Price.Should().Be(10.99m);
    }

    [Fact]
    public async Task GetByIdAsync_NonExistingProduct_ReturnsNull()
    {
        // Act
        var result = await _repository.GetByIdAsync(999);

        // Assert
        result.Should().BeNull();
    }

    [Fact]
    public async Task GetAllAsync_ReturnsAllProducts_OrderedByName()
    {
        // Act
        var results = await _repository.GetAllAsync();

        // Assert
        results.Should().HaveCount(3);
        results.Should().BeInAscendingOrder(p => p.Name);
    }

    [Fact]
    public async Task AddAsync_ValidProduct_AddsToDatabase()
    {
        // Arrange
        var newProduct = new Product
        {
            Name = "New Product",
            Price = 40.99m,
            Sku = "SKU004"
        };

        // Act
        var result = await _repository.AddAsync(newProduct);

        // Assert
        result.Id.Should().BeGreaterThan(0);

        var savedProduct = await _context.Products.FindAsync(result.Id);
        savedProduct.Should().NotBeNull();
        savedProduct.Name.Should().Be("New Product");
    }

    [Fact]
    public async Task UpdateAsync_ExistingProduct_UpdatesInDatabase()
    {
        // Arrange
        var product = await _context.Products.FindAsync(1);
        product.Name = "Updated Product";
        product.Price = 99.99m;

        // Act
        await _repository.UpdateAsync(product);

        // Assert
        var updatedProduct = await _context.Products.FindAsync(1);
        updatedProduct.Name.Should().Be("Updated Product");
        updatedProduct.Price.Should().Be(99.99m);
    }

    [Fact]
    public async Task DeleteAsync_ExistingProduct_RemovesFromDatabase()
    {
        // Act
        await _repository.DeleteAsync(1);

        // Assert
        var deletedProduct = await _context.Products.FindAsync(1);
        deletedProduct.Should().BeNull();

        var remainingProducts = await _context.Products.CountAsync();
        remainingProducts.Should().Be(2);
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }
}

// ============================================
// Approach 2: SQLite InMemory (More Realistic)
// ============================================

public class ProductRepositorySqliteTests : IDisposable
{
    private readonly ApplicationDbContext _context;
    private readonly ProductRepository _repository;
    private readonly SqliteConnection _connection;

    public ProductRepositorySqliteTests()
    {
        // SQLite in-memory database
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new ApplicationDbContext(options);
        _context.Database.EnsureCreated(); // Create schema

        _repository = new ProductRepository(_context);
        SeedTestData();
    }

    private void SeedTestData()
    {
        _context.Products.AddRange(
            new Product { Name = "Product 1", Price = 10.99m, Sku = "SKU001" },
            new Product { Name = "Product 2", Price = 20.99m, Sku = "SKU002" }
        );
        _context.SaveChanges();
    }

    [Fact]
    public async Task UniqueConstraint_DuplicateSku_ThrowsException()
    {
        // Arrange
        var product = new Product
        {
            Name = "Duplicate",
            Price = 10m,
            Sku = "SKU001" // Duplicate SKU
        };

        // Act & Assert
        var act = async () => await _repository.AddAsync(product);

        await act.Should().ThrowAsync<DbUpdateException>();
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Close();
        _connection.Dispose();
    }
}

// ============================================
// Approach 3: Test Fixture for Shared Context
// ============================================

public class DatabaseFixture : IDisposable
{
    public ApplicationDbContext Context { get; private set; }

    public DatabaseFixture()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: "TestDatabase")
            .Options;

        Context = new ApplicationDbContext(options);

        // Seed shared test data
        Context.Products.AddRange(
            new Product { Id = 1, Name = "Shared Product 1", Price = 10m, Sku = "SHARED001" },
            new Product { Id = 2, Name = "Shared Product 2", Price = 20m, Sku = "SHARED002" }
        );
        Context.SaveChanges();
    }

    public void Dispose()
    {
        Context.Database.EnsureDeleted();
        Context.Dispose();
    }
}

public class ProductServiceTests : IClassFixture<DatabaseFixture>
{
    private readonly ApplicationDbContext _context;

    public ProductServiceTests(DatabaseFixture fixture)
    {
        _context = fixture.Context;
    }

    [Fact]
    public async Task GetExpensiveProducts_ReturnsProductsOverThreshold()
    {
        // Arrange
        var service = new ProductService(_context);

        // Act
        var results = await service.GetExpensiveProductsAsync(15m);

        // Assert
        results.Should().HaveCount(1);
        results.First().Price.Should().BeGreaterThan(15m);
    }
}

// ============================================
// Testing Complex Queries
// ============================================

public class OrderRepositoryTests
{
    [Fact]
    public async Task GetOrdersWithProducts_ReturnsCorrectData()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        using var context = new ApplicationDbContext(options);

        var product = new Product { Id = 1, Name = "Test Product", Price = 50m, Sku = "TEST001" };
        var order = new Order
        {
            Id = 1,
            OrderDate = DateTime.UtcNow,
            Products = new List<Product> { product }
        };

        context.Products.Add(product);
        context.Orders.Add(order);
        await context.SaveChangesAsync();

        var repository = new OrderRepository(context);

        // Act
        var result = await repository.GetOrderWithProductsAsync(1);

        // Assert
        result.Should().NotBeNull();
        result.Products.Should().HaveCount(1);
        result.Products.First().Name.Should().Be("Test Product");
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use unique database names per test
   - Prevents test interference
   - Use Guid.NewGuid().ToString()

2. ✅ Choose the right approach:
   - InMemory: Fast, simple scenarios
   - SQLite: More realistic, supports constraints
   - TestContainers: Real database, slower but most accurate

3. ✅ Clean up after tests
   - Call EnsureDeleted() in Dispose
   - Use IDisposable pattern

4. ✅ Seed test data consistently
   - Create helper methods for seeding
   - Use test data builders

5. ❌ Don't test EF Core itself
   - Test your repository logic
   - Test custom queries and business logic

6. ✅ Use IClassFixture for shared setup
   - Reduces test execution time
   - Be careful with state between tests

7. ✅ Test relationship loading
   - Include() and ThenInclude()
   - Lazy loading scenarios

8. ✅ Test constraint violations
   - Use SQLite for unique constraints
   - Test foreign key violations

9. ✅ Mock DbContext for unit tests
   - Use repository pattern
   - Mock repositories, not DbContext directly

10. ✅ Use async/await consistently
    - EF Core operations are async
    - Test async methods with async tests
*/
```

---

## **Q269: How do you perform Integration Testing in ASP.NET Core?**

**Answer:**

Integration testing in ASP.NET Core tests the interaction between multiple components, including controllers, middleware, database, and external services.

**Using WebApplicationFactory:**
```csharp
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http.Json;
using Xunit;

// ============================================
// Basic Integration Test Setup
// ============================================

public class ApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Get_Products_ReturnsSuccessAndCorrectContentType()
    {
        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        response.EnsureSuccessStatusCode();
        response.Content.Headers.ContentType.ToString()
            .Should().Contain("application/json");
    }

    [Fact]
    public async Task Get_ProductById_ExistingId_ReturnsProduct()
    {
        // Act
        var response = await _client.GetAsync("/api/products/1");
        var product = await response.Content.ReadFromJsonAsync<ProductDto>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        product.Should().NotBeNull();
        product.Id.Should().Be(1);
    }

    [Fact]
    public async Task Post_CreateProduct_ReturnsCreatedProduct()
    {
        // Arrange
        var newProduct = new CreateProductDto
        {
            Name = "Test Product",
            Price = 29.99m,
            Sku = "TEST001"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", newProduct);
        var createdProduct = await response.Content.ReadFromJsonAsync<ProductDto>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        createdProduct.Name.Should().Be("Test Product");
        response.Headers.Location.Should().NotBeNull();
    }
}

// ============================================
// Custom WebApplicationFactory with Test Database
// ============================================

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove the real database registration
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));

            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            // Add test database (InMemory or SQLite)
            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseInMemoryDatabase("TestDb");
            });

            // Build service provider
            var sp = services.BuildServiceProvider();

            // Create scope and seed test data
            using var scope = sp.CreateScope();
            var scopedServices = scope.ServiceProvider;
            var db = scopedServices.GetRequiredService<ApplicationDbContext>();
            var logger = scopedServices.GetRequiredService<ILogger<CustomWebApplicationFactory>>();

            db.Database.EnsureCreated();

            try
            {
                SeedTestData(db);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "An error occurred seeding the database. Error: {Message}", ex.Message);
            }
        });

        builder.UseEnvironment("Testing");
    }

    private static void SeedTestData(ApplicationDbContext db)
    {
        db.Products.AddRange(
            new Product { Id = 1, Name = "Product 1", Price = 10.99m, Sku = "SKU001" },
            new Product { Id = 2, Name = "Product 2", Price = 20.99m, Sku = "SKU002" },
            new Product { Id = 3, Name = "Product 3", Price = 30.99m, Sku = "SKU003" }
        );

        db.SaveChanges();
    }
}

// ============================================
// Using Custom Factory
// ============================================

public class ProductsControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public ProductsControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
    }

    [Theory]
    [InlineData("/api/products")]
    [InlineData("/api/products/1")]
    public async Task Get_EndpointsReturnSuccessAndCorrectContentType(string url)
    {
        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.EnsureSuccessStatusCode();
        response.Content.Headers.ContentType.ToString()
            .Should().Contain("application/json");
    }

    [Fact]
    public async Task Get_Products_ReturnsAllSeededProducts()
    {
        // Act
        var response = await _client.GetAsync("/api/products");
        var products = await response.Content.ReadFromJsonAsync<List<ProductDto>>();

        // Assert
        products.Should().HaveCount(3);
        products.Should().OnlyContain(p => p.Price > 0);
    }

    [Fact]
    public async Task Delete_Product_RemovesFromDatabase()
    {
        // Act - Delete
        var deleteResponse = await _client.DeleteAsync("/api/products/1");
        deleteResponse.EnsureSuccessStatusCode();

        // Assert - Verify deleted
        var getResponse = await _client.GetAsync("/api/products/1");
        getResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Update_Product_UpdatesInDatabase()
    {
        // Arrange
        var updateDto = new UpdateProductDto
        {
            Name = "Updated Product",
            Price = 99.99m
        };

        // Act - Update
        var response = await _client.PutAsJsonAsync("/api/products/1", updateDto);
        response.EnsureSuccessStatusCode();

        // Assert - Verify update
        var getResponse = await _client.GetAsync("/api/products/1");
        var product = await getResponse.Content.ReadFromJsonAsync<ProductDto>();

        product.Name.Should().Be("Updated Product");
        product.Price.Should().Be(99.99m);
    }
}

// ============================================
// Testing Authentication and Authorization
// ============================================

public class SecureEndpointTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public SecureEndpointTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Get_SecureEndpoint_WithoutAuth_ReturnsUnauthorized()
    {
        // Act
        var response = await _client.GetAsync("/api/admin/users");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Get_SecureEndpoint_WithAuth_ReturnsSuccess()
    {
        // Arrange - Add authorization header
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", GenerateTestToken());

        // Act
        var response = await _client.GetAsync("/api/admin/users");

        // Assert
        response.EnsureSuccessStatusCode();
    }

    private string GenerateTestToken()
    {
        // Generate test JWT token
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-secret-key-with-minimum-length"));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: "TestIssuer",
            audience: "TestAudience",
            claims: new[]
            {
                new Claim(ClaimTypes.Name, "TestUser"),
                new Claim(ClaimTypes.Role, "Admin")
            },
            expires: DateTime.Now.AddMinutes(30),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// ============================================
// Testing with Mock External Services
// ============================================

public class CustomFactoryWithMockedServices : WebApplicationFactory<Program>
{
    public Mock<IEmailService> MockEmailService { get; private set; }
    public Mock<IPaymentGateway> MockPaymentGateway { get; private set; }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        MockEmailService = new Mock<IEmailService>();
        MockPaymentGateway = new Mock<IPaymentGateway>();

        builder.ConfigureTestServices(services =>
        {
            // Replace real services with mocks
            services.AddScoped(_ => MockEmailService.Object);
            services.AddScoped(_ => MockPaymentGateway.Object);

            // Use test database
            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseInMemoryDatabase("TestDb");
            });
        });
    }
}

public class OrderIntegrationTests : IClassFixture<CustomFactoryWithMockedServices>
{
    private readonly HttpClient _client;
    private readonly CustomFactoryWithMockedServices _factory;

    public OrderIntegrationTests(CustomFactoryWithMockedServices factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateOrder_ValidOrder_SendsConfirmationEmail()
    {
        // Arrange
        _factory.MockPaymentGateway
            .Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentRequest>()))
            .ReturnsAsync(new PaymentResult { Success = true, TransactionId = "TX123" });

        var order = new CreateOrderDto
        {
            CustomerId = 1,
            Items = new[] { new OrderItemDto { ProductId = 1, Quantity = 2 } }
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", order);

        // Assert
        response.EnsureSuccessStatusCode();

        // Verify email was sent
        _factory.MockEmailService.Verify(
            x => x.SendEmailAsync(
                It.IsAny<string>(),
                "Order Confirmation",
                It.IsAny<string>()),
            Times.Once);

        // Verify payment was processed
        _factory.MockPaymentGateway.Verify(
            x => x.ProcessPaymentAsync(It.IsAny<PaymentRequest>()),
            Times.Once);
    }
}

// ============================================
// Testing Middleware
// ============================================

public class MiddlewareTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public MiddlewareTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Request_IncludesCorrelationId_InResponse()
    {
        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        response.Headers.Should().Contain(h => h.Key == "X-Correlation-ID");
    }

    [Fact]
    public async Task Request_RateLimited_ReturnsTooManyRequests()
    {
        // Act - Make multiple requests
        for (int i = 0; i < 100; i++)
        {
            await _client.GetAsync("/api/products");
        }

        var response = await _client.GetAsync("/api/products");

        // Assert
        response.StatusCode.Should().Be((HttpStatusCode)429); // Too Many Requests
    }
}

// ============================================
// Testing with Real Database (TestContainers)
// ============================================

public class RealDatabaseTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres;
    private WebApplicationFactory<Program> _factory;
    private HttpClient _client;

    public RealDatabaseTests()
    {
        _postgres = new PostgreSqlBuilder()
            .WithImage("postgres:15-alpine")
            .WithDatabase("testdb")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();

        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    services.AddDbContext<ApplicationDbContext>(options =>
                    {
                        options.UseNpgsql(_postgres.GetConnectionString());
                    });
                });
            });

        _client = _factory.CreateClient();

        // Run migrations
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await db.Database.MigrateAsync();
    }

    [Fact]
    public async Task CreateProduct_WithRealDatabase_PersistsCorrectly()
    {
        // Arrange
        var product = new CreateProductDto
        {
            Name = "Real DB Product",
            Price = 49.99m,
            Sku = "REAL001"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", product);

        // Assert
        response.EnsureSuccessStatusCode();

        // Verify in database
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var saved = await db.Products.FirstOrDefaultAsync(p => p.Sku == "REAL001");

        saved.Should().NotBeNull();
        saved.Name.Should().Be("Real DB Product");
    }

    public async Task DisposeAsync()
    {
        _client?.Dispose();
        _factory?.Dispose();
        await _postgres.DisposeAsync();
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use WebApplicationFactory for integration tests
   - Tests real HTTP pipeline
   - Includes middleware, routing, model binding

2. ✅ Customize the factory for test scenarios
   - Replace services with test doubles
   - Use test database
   - Configure test environment

3. ✅ Test complete request/response cycles
   - Full HTTP requests
   - Verify status codes, headers, body

4. ✅ Use test database, not production
   - InMemory for simple scenarios
   - SQLite for constraints
   - TestContainers for real database

5. ✅ Seed test data consistently
   - Create test data in factory
   - Reset between tests if needed

6. ✅ Test authentication and authorization
   - Generate test tokens
   - Test protected endpoints

7. ✅ Mock external dependencies
   - Use ConfigureTestServices
   - Verify interactions with mocks

8. ✅ Test middleware behavior
   - CORS, authentication, custom middleware
   - Headers, status codes

9. ❌ Don't test framework behavior
   - Focus on your code
   - Test business logic integration

10. ✅ Use IClassFixture for shared setup
    - Reuse factory across tests
    - Faster test execution
*/
```

---

## **Q270: How do you test custom Middleware in ASP.NET Core?**

**Answer:**

Testing custom middleware ensures that HTTP request/response pipeline logic works correctly.

**Middleware Testing Approaches:**
```csharp
using Microsoft.AspNetCore.Http;
using Xunit;

// ============================================
// Custom Middleware Example
// ============================================

public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private const string CorrelationIdHeader = "X-Correlation-ID";

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Check if correlation ID exists in request
        if (!context.Request.Headers.ContainsKey(CorrelationIdHeader))
        {
            context.Request.Headers[CorrelationIdHeader] = Guid.NewGuid().ToString();
        }

        // Add correlation ID to response
        context.Response.OnStarting(() =>
        {
            context.Response.Headers[CorrelationIdHeader] =
                context.Request.Headers[CorrelationIdHeader];
            return Task.CompletedTask;
        });

        await _next(context);
    }
}

// ============================================
// Unit Testing Middleware
// ============================================

public class CorrelationIdMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_NoCorrelationId_GeneratesNewId()
    {
        // Arrange
        var context = new DefaultHttpContext();
        var next = new RequestDelegate(ctx =>
        {
            return Task.CompletedTask;
        });

        var middleware = new CorrelationIdMiddleware(next);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Request.Headers.Should().ContainKey("X-Correlation-ID");
        context.Response.Headers.Should().ContainKey("X-Correlation-ID");

        var requestId = context.Request.Headers["X-Correlation-ID"].ToString();
        var responseId = context.Response.Headers["X-Correlation-ID"].ToString();

        requestId.Should().NotBeNullOrEmpty();
        requestId.Should().Be(responseId);
        Guid.TryParse(requestId, out _).Should().BeTrue();
    }

    [Fact]
    public async Task InvokeAsync_ExistingCorrelationId_PreservesId()
    {
        // Arrange
        var expectedId = "existing-correlation-id";
        var context = new DefaultHttpContext();
        context.Request.Headers["X-Correlation-ID"] = expectedId;

        var next = new RequestDelegate(ctx => Task.CompletedTask);
        var middleware = new CorrelationIdMiddleware(next);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Request.Headers["X-Correlation-ID"].ToString()
            .Should().Be(expectedId);
        context.Response.Headers["X-Correlation-ID"].ToString()
            .Should().Be(expectedId);
    }

    [Fact]
    public async Task InvokeAsync_CallsNextMiddleware()
    {
        // Arrange
        var context = new DefaultHttpContext();
        var nextCalled = false;

        var next = new RequestDelegate(ctx =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        var middleware = new CorrelationIdMiddleware(next);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
    }
}

// ============================================
// Authentication Middleware Example
// ============================================

public class ApiKeyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IApiKeyValidator _validator;

    public ApiKeyMiddleware(RequestDelegate next, IApiKeyValidator validator)
    {
        _next = next;
        _validator = validator;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Skip authentication for certain paths
        if (context.Request.Path.StartsWithSegments("/health"))
        {
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("X-API-Key", out var apiKey))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("API Key is missing");
            return;
        }

        if (!await _validator.IsValidAsync(apiKey))
        {
            context.Response.StatusCode = 403;
            await context.Response.WriteAsync("Invalid API Key");
            return;
        }

        await _next(context);
    }
}

// ============================================
// Testing Authentication Middleware
// ============================================

public class ApiKeyMiddlewareTests
{
    private readonly Mock<IApiKeyValidator> _mockValidator;

    public ApiKeyMiddlewareTests()
    {
        _mockValidator = new Mock<IApiKeyValidator>();
    }

    [Fact]
    public async Task InvokeAsync_MissingApiKey_Returns401()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();
        var next = new RequestDelegate(ctx => Task.CompletedTask);

        var middleware = new ApiKeyMiddleware(next, _mockValidator.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Response.StatusCode.Should().Be(401);

        context.Response.Body.Seek(0, SeekOrigin.Begin);
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        body.Should().Contain("API Key is missing");
    }

    [Fact]
    public async Task InvokeAsync_InvalidApiKey_Returns403()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();
        context.Request.Headers["X-API-Key"] = "invalid-key";

        _mockValidator.Setup(x => x.IsValidAsync("invalid-key"))
            .ReturnsAsync(false);

        var next = new RequestDelegate(ctx => Task.CompletedTask);
        var middleware = new ApiKeyMiddleware(next, _mockValidator.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Response.StatusCode.Should().Be(403);

        context.Response.Body.Seek(0, SeekOrigin.Begin);
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        body.Should().Contain("Invalid API Key");
    }

    [Fact]
    public async Task InvokeAsync_ValidApiKey_CallsNext()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Request.Headers["X-API-Key"] = "valid-key";

        _mockValidator.Setup(x => x.IsValidAsync("valid-key"))
            .ReturnsAsync(true);

        var nextCalled = false;
        var next = new RequestDelegate(ctx =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        var middleware = new ApiKeyMiddleware(next, _mockValidator.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
        context.Response.StatusCode.Should().Be(200);
    }

    [Fact]
    public async Task InvokeAsync_HealthEndpoint_SkipsAuthentication()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Request.Path = "/health";

        var nextCalled = false;
        var next = new RequestDelegate(ctx =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        var middleware = new ApiKeyMiddleware(next, _mockValidator.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
        _mockValidator.Verify(x => x.IsValidAsync(It.IsAny<string>()), Times.Never);
    }
}

// ============================================
// Exception Handling Middleware
// ============================================

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation error occurred");
            await HandleValidationExceptionAsync(context, ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleValidationExceptionAsync(
        HttpContext context,
        ValidationException exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = 400;

        var response = new
        {
            error = "Validation failed",
            details = exception.Errors.Select(e => new
            {
                field = e.PropertyName,
                message = e.ErrorMessage
            })
        };

        return context.Response.WriteAsJsonAsync(response);
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = 500;

        var response = new
        {
            error = "An error occurred processing your request",
            message = exception.Message
        };

        return context.Response.WriteAsJsonAsync(response);
    }
}

// ============================================
// Testing Exception Middleware
// ============================================

public class ExceptionHandlingMiddlewareTests
{
    private readonly Mock<ILogger<ExceptionHandlingMiddleware>> _mockLogger;

    public ExceptionHandlingMiddlewareTests()
    {
        _mockLogger = new Mock<ILogger<ExceptionHandlingMiddleware>>();
    }

    [Fact]
    public async Task InvokeAsync_NoException_CallsNext()
    {
        // Arrange
        var context = new DefaultHttpContext();
        var nextCalled = false;

        var next = new RequestDelegate(ctx =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        var middleware = new ExceptionHandlingMiddleware(next, _mockLogger.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
    }

    [Fact]
    public async Task InvokeAsync_ValidationException_Returns400()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        var validationErrors = new List<ValidationFailure>
        {
            new ValidationFailure("Name", "Name is required"),
            new ValidationFailure("Email", "Invalid email format")
        };

        var next = new RequestDelegate(ctx =>
        {
            throw new ValidationException(validationErrors);
        });

        var middleware = new ExceptionHandlingMiddleware(next, _mockLogger.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Response.StatusCode.Should().Be(400);
        context.Response.ContentType.Should().Be("application/json");
    }

    [Fact]
    public async Task InvokeAsync_UnhandledException_Returns500()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        var next = new RequestDelegate(ctx =>
        {
            throw new InvalidOperationException("Something went wrong");
        });

        var middleware = new ExceptionHandlingMiddleware(next, _mockLogger.Object);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Response.StatusCode.Should().Be(500);
        context.Response.ContentType.Should().Be("application/json");

        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<InvalidOperationException>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}

// ============================================
// Integration Testing Middleware
// ============================================

public class MiddlewareIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public MiddlewareIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Request_IncludesCorrelationId_InResponse()
    {
        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        response.Headers.Should().ContainKey("X-Correlation-ID");
    }

    [Fact]
    public async Task Request_WithCorrelationId_PreservesId()
    {
        // Arrange
        var correlationId = Guid.NewGuid().ToString();
        _client.DefaultRequestHeaders.Add("X-Correlation-ID", correlationId);

        // Act
        var response = await _client.GetAsync("/api/products");

        // Assert
        response.Headers.GetValues("X-Correlation-ID")
            .Should().Contain(correlationId);
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use DefaultHttpContext for unit tests
   - Lightweight and fast
   - No need for full HTTP pipeline

2. ✅ Test middleware in isolation
   - Mock dependencies
   - Test specific middleware logic

3. ✅ Test the complete pipeline with integration tests
   - Use WebApplicationFactory
   - Test middleware interactions

4. ✅ Mock the next delegate
   - Verify it's called when appropriate
   - Verify short-circuit scenarios

5. ✅ Test error scenarios
   - Missing headers
   - Invalid data
   - Exceptions

6. ✅ Use MemoryStream for response body
   - Read response content in tests
   - Verify error messages

7. ✅ Test bypass/skip logic
   - Certain paths skip middleware
   - Optional authentication

8. ✅ Verify logging calls
   - Mock ILogger
   - Verify log levels and messages

9. ✅ Test status codes and headers
   - Correct HTTP status
   - Required headers present

10. ✅ Test async behavior
    - Properly await operations
    - Handle cancellation tokens
*/
```

---

## **Q271: What is the Test Data Builder pattern and when should you use it?**

**Answer:**

The Test Data Builder pattern provides a fluent API for creating test objects with sensible defaults, making tests more readable and maintainable.

**Implementation:**
```csharp
using Xunit;

// ============================================
// Domain Models
// ============================================

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public int Age { get; set; }
    public bool IsActive { get; set; }
    public Address Address { get; set; }
    public List<Order> Orders { get; set; } = new();
}

public class Address
{
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string ZipCode { get; set; }
}

public class Order
{
    public int Id { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal Total { get; set; }
    public List<OrderItem> Items { get; set; } = new();
}

public class OrderItem
{
    public int ProductId { get; set; }
    public string ProductName { get; set; }
    public int Quantity { get; set; }
    public decimal Price { get; set; }
}

// ============================================
// Test Data Builder Pattern
// ============================================

public class UserBuilder
{
    private int _id = 1;
    private string _name = "John Doe";
    private string _email = "john@example.com";
    private int _age = 30;
    private bool _isActive = true;
    private Address _address = new AddressBuilder().Build();
    private List<Order> _orders = new();

    public UserBuilder WithId(int id)
    {
        _id = id;
        return this;
    }

    public UserBuilder WithName(string name)
    {
        _name = name;
        return this;
    }

    public UserBuilder WithEmail(string email)
    {
        _email = email;
        return this;
    }

    public UserBuilder WithAge(int age)
    {
        _age = age;
        return this;
    }

    public UserBuilder ThatIsInactive()
    {
        _isActive = false;
        return this;
    }

    public UserBuilder ThatIsActive()
    {
        _isActive = true;
        return this;
    }

    public UserBuilder WithAddress(Address address)
    {
        _address = address;
        return this;
    }

    public UserBuilder WithAddress(Action<AddressBuilder> configure)
    {
        var builder = new AddressBuilder();
        configure(builder);
        _address = builder.Build();
        return this;
    }

    public UserBuilder WithOrder(Order order)
    {
        _orders.Add(order);
        return this;
    }

    public UserBuilder WithOrders(params Order[] orders)
    {
        _orders.AddRange(orders);
        return this;
    }

    public User Build()
    {
        return new User
        {
            Id = _id,
            Name = _name,
            Email = _email,
            Age = _age,
            IsActive = _isActive,
            Address = _address,
            Orders = _orders
        };
    }

    // Convenience method for building lists
    public static implicit operator User(UserBuilder builder) => builder.Build();
}

public class AddressBuilder
{
    private string _street = "123 Main St";
    private string _city = "Springfield";
    private string _state = "IL";
    private string _zipCode = "62701";

    public AddressBuilder OnStreet(string street)
    {
        _street = street;
        return this;
    }

    public AddressBuilder InCity(string city)
    {
        _city = city;
        return this;
    }

    public AddressBuilder InState(string state)
    {
        _state = state;
        return this;
    }

    public AddressBuilder WithZipCode(string zipCode)
    {
        _zipCode = zipCode;
        return this;
    }

    public Address Build()
    {
        return new Address
        {
            Street = _street,
            City = _city,
            State = _state,
            ZipCode = _zipCode
        };
    }

    public static implicit operator Address(AddressBuilder builder) => builder.Build();
}

public class OrderBuilder
{
    private int _id = 1;
    private DateTime _orderDate = DateTime.UtcNow;
    private decimal _total = 100m;
    private List<OrderItem> _items = new();

    public OrderBuilder WithId(int id)
    {
        _id = id;
        return this;
    }

    public OrderBuilder PlacedOn(DateTime date)
    {
        _orderDate = date;
        return this;
    }

    public OrderBuilder WithTotal(decimal total)
    {
        _total = total;
        return this;
    }

    public OrderBuilder WithItem(OrderItem item)
    {
        _items.Add(item);
        _total += item.Price * item.Quantity;
        return this;
    }

    public OrderBuilder WithItem(Action<OrderItemBuilder> configure)
    {
        var builder = new OrderItemBuilder();
        configure(builder);
        var item = builder.Build();
        _items.Add(item);
        _total += item.Price * item.Quantity;
        return this;
    }

    public Order Build()
    {
        return new Order
        {
            Id = _id,
            OrderDate = _orderDate,
            Total = _total,
            Items = _items
        };
    }

    public static implicit operator Order(OrderBuilder builder) => builder.Build();
}

public class OrderItemBuilder
{
    private int _productId = 1;
    private string _productName = "Test Product";
    private int _quantity = 1;
    private decimal _price = 10m;

    public OrderItemBuilder ForProduct(int productId, string productName)
    {
        _productId = productId;
        _productName = productName;
        return this;
    }

    public OrderItemBuilder WithQuantity(int quantity)
    {
        _quantity = quantity;
        return this;
    }

    public OrderItemBuilder AtPrice(decimal price)
    {
        _price = price;
        return this;
    }

    public OrderItem Build()
    {
        return new OrderItem
        {
            ProductId = _productId,
            ProductName = _productName,
            Quantity = _quantity,
            Price = _price
        };
    }

    public static implicit operator OrderItem(OrderItemBuilder builder) => builder.Build();
}

// ============================================
// Using Test Data Builders in Tests
// ============================================

public class UserServiceTestsWithBuilders
{
    // ❌ WITHOUT Builders - Verbose and unclear
    [Fact]
    public void CreateUser_ValidUser_Success_WithoutBuilder()
    {
        // Arrange - Too much setup noise
        var user = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            Age = 30,
            IsActive = true,
            Address = new Address
            {
                Street = "123 Main St",
                City = "Springfield",
                State = "IL",
                ZipCode = "62701"
            },
            Orders = new List<Order>()
        };

        var service = new UserService();

        // Act & Assert
        service.CreateUser(user).Should().NotThrow();
    }

    // ✅ WITH Builders - Clean and focused
    [Fact]
    public void CreateUser_ValidUser_Success_WithBuilder()
    {
        // Arrange - Only relevant details, defaults handle the rest
        var user = new UserBuilder().Build();
        var service = new UserService();

        // Act & Assert
        service.CreateUser(user).Should().NotThrow();
    }

    [Fact]
    public void CreateUser_InactiveUser_ThrowsException()
    {
        // Arrange - Focus on what matters for this test
        var user = new UserBuilder()
            .ThatIsInactive()
            .Build();

        var service = new UserService();

        // Act & Assert
        var act = () => service.CreateUser(user);
        act.Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void GetUsersByAge_FiltersCorrectly()
    {
        // Arrange - Easy to create multiple users with variations
        var users = new List<User>
        {
            new UserBuilder().WithAge(25).Build(),
            new UserBuilder().WithAge(30).Build(),
            new UserBuilder().WithAge(35).Build()
        };

        var service = new UserService(users);

        // Act
        var result = service.GetUsersAboveAge(28);

        // Assert
        result.Should().HaveCount(2);
        result.Should().OnlyContain(u => u.Age > 28);
    }

    [Fact]
    public void CreateOrder_WithMultipleItems_CalculatesTotal()
    {
        // Arrange - Fluent nested builders
        var user = new UserBuilder()
            .WithName("Jane Doe")
            .WithOrder(new OrderBuilder()
                .WithItem(item => item
                    .ForProduct(1, "Product A")
                    .WithQuantity(2)
                    .AtPrice(10m))
                .WithItem(item => item
                    .ForProduct(2, "Product B")
                    .WithQuantity(1)
                    .AtPrice(20m))
                .Build())
            .Build();

        // Assert
        user.Orders.First().Total.Should().Be(40m); // (2*10) + (1*20)
    }

    [Fact]
    public void ValidateAddress_CaliforniaAddress_Success()
    {
        // Arrange - Nested builder configuration
        var user = new UserBuilder()
            .WithAddress(addr => addr
                .InCity("Los Angeles")
                .InState("CA")
                .WithZipCode("90001"))
            .Build();

        var validator = new AddressValidator();

        // Act
        var result = validator.Validate(user.Address);

        // Assert
        result.IsValid.Should().BeTrue();
    }
}

// ============================================
// Object Mother Pattern (Alternative)
// ============================================

public static class TestUsers
{
    public static User ValidUser() =>
        new UserBuilder().Build();

    public static User InactiveUser() =>
        new UserBuilder().ThatIsInactive().Build();

    public static User UnderageUser() =>
        new UserBuilder().WithAge(16).Build();

    public static User UserWithOrders() =>
        new UserBuilder()
            .WithOrder(TestOrders.StandardOrder())
            .WithOrder(TestOrders.LargeOrder())
            .Build();

    public static User CaliforniaUser() =>
        new UserBuilder()
            .WithAddress(addr => addr
                .InState("CA")
                .InCity("Los Angeles"))
            .Build();
}

public static class TestOrders
{
    public static Order StandardOrder() =>
        new OrderBuilder()
            .WithTotal(100m)
            .Build();

    public static Order LargeOrder() =>
        new OrderBuilder()
            .WithTotal(1000m)
            .PlacedOn(DateTime.UtcNow.AddDays(-30))
            .Build();

    public static Order EmptyOrder() =>
        new OrderBuilder()
            .WithTotal(0m)
            .Build();
}

// ============================================
// Using Object Mother
// ============================================

public class UserServiceTestsWithObjectMother
{
    [Fact]
    public void ProcessOrder_ValidUser_Success()
    {
        // Arrange - Intention-revealing factory methods
        var user = TestUsers.UserWithOrders();
        var service = new OrderService();

        // Act & Assert
        service.ProcessOrders(user).Should().NotThrow();
    }

    [Fact]
    public void ValidateUser_UnderageUser_Fails()
    {
        // Arrange
        var user = TestUsers.UnderageUser();
        var validator = new UserValidator();

        // Act
        var result = validator.Validate(user);

        // Assert
        result.IsValid.Should().BeFalse();
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use builders for complex objects
   - Multiple properties
   - Nested objects
   - Collections

2. ✅ Provide sensible defaults
   - Tests only specify what's relevant
   - Reduces test setup noise

3. ✅ Use fluent API
   - Method chaining
   - Readable test code

4. ✅ Name methods descriptively
   - ThatIsInactive() vs SetActive(false)
   - InCity("LA") vs SetCity("LA")

5. ✅ Support nested configuration
   - Action<TBuilder> parameters
   - Configure child objects inline

6. ✅ Combine with Object Mother
   - Builders for flexibility
   - Object Mother for common scenarios

7. ❌ Don't over-engineer
   - Start simple
   - Add complexity when needed

8. ✅ Make builders reusable
   - Share across test projects
   - Maintain in test utilities

9. ✅ Use implicit operators (optional)
   - Automatic conversion to domain object
   - Less verbose test code

10. ✅ Keep builders in sync
    - Update when domain changes
    - Version with domain models
*/
```

---

## **Q272: How do you test exceptions and error scenarios effectively?**

**Answer:**

Testing exceptions ensures your code handles errors correctly and provides meaningful feedback.

**Exception Testing Techniques:**
```csharp
using Xunit;
using FluentAssertions;

// ============================================
// Service with Error Handling
// ============================================

public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IPaymentProcessor _paymentProcessor;
    private readonly IInventoryService _inventoryService;

    public OrderService(
        IOrderRepository repository,
        IPaymentProcessor paymentProcessor,
        IInventoryService inventoryService)
    {
        _repository = repository;
        _paymentProcessor = paymentProcessor;
        _inventoryService = inventoryService;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (request.Items == null || !request.Items.Any())
            throw new InvalidOperationException("Order must contain at least one item");

        // Check inventory
        foreach (var item in request.Items)
        {
            var available = await _inventoryService.GetAvailableQuantityAsync(item.ProductId);
            if (available < item.Quantity)
            {
                throw new InsufficientInventoryException(
                    item.ProductId,
                    item.Quantity,
                    available);
            }
        }

        // Process payment
        var paymentResult = await _paymentProcessor.ProcessPaymentAsync(
            request.PaymentInfo);

        if (!paymentResult.Success)
        {
            throw new PaymentFailedException(
                "Payment processing failed",
                paymentResult.ErrorCode);
        }

        // Create order
        var order = new Order
        {
            CustomerId = request.CustomerId,
            Items = request.Items.ToList(),
            Total = request.Items.Sum(i => i.Price * i.Quantity),
            PaymentId = paymentResult.TransactionId
        };

        try
        {
            await _repository.AddAsync(order);
            return order;
        }
        catch (DbUpdateException ex)
        {
            // Rollback payment if order creation fails
            await _paymentProcessor.RefundAsync(paymentResult.TransactionId);
            throw new OrderCreationException("Failed to create order", ex);
        }
    }

    public async Task<Order> GetOrderByIdAsync(int orderId)
    {
        if (orderId <= 0)
            throw new ArgumentException("Order ID must be positive", nameof(orderId));

        var order = await _repository.GetByIdAsync(orderId);

        if (order == null)
            throw new OrderNotFoundException(orderId);

        return order;
    }
}

// ============================================
// Custom Exceptions
// ============================================

public class InsufficientInventoryException : Exception
{
    public int ProductId { get; }
    public int RequestedQuantity { get; }
    public int AvailableQuantity { get; }

    public InsufficientInventoryException(
        int productId,
        int requestedQuantity,
        int availableQuantity)
        : base($"Insufficient inventory for product {productId}. " +
               $"Requested: {requestedQuantity}, Available: {availableQuantity}")
    {
        ProductId = productId;
        RequestedQuantity = requestedQuantity;
        AvailableQuantity = availableQuantity;
    }
}

public class PaymentFailedException : Exception
{
    public string ErrorCode { get; }

    public PaymentFailedException(string message, string errorCode)
        : base(message)
    {
        ErrorCode = errorCode;
    }
}

public class OrderNotFoundException : Exception
{
    public int OrderId { get; }

    public OrderNotFoundException(int orderId)
        : base($"Order with ID {orderId} was not found")
    {
        OrderId = orderId;
    }
}

public class OrderCreationException : Exception
{
    public OrderCreationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

// ============================================
// Testing Exceptions - Basic
// ============================================

public class OrderServiceExceptionTests
{
    private readonly Mock<IOrderRepository> _mockRepository;
    private readonly Mock<IPaymentProcessor> _mockPaymentProcessor;
    private readonly Mock<IInventoryService> _mockInventoryService;
    private readonly OrderService _service;

    public OrderServiceExceptionTests()
    {
        _mockRepository = new Mock<IOrderRepository>();
        _mockPaymentProcessor = new Mock<IPaymentProcessor>();
        _mockInventoryService = new Mock<IInventoryService>();

        _service = new OrderService(
            _mockRepository.Object,
            _mockPaymentProcessor.Object,
            _mockInventoryService.Object);
    }

    // ============================================
    // Testing ArgumentNullException
    // ============================================

    [Fact]
    public async Task CreateOrderAsync_NullRequest_ThrowsArgumentNullException()
    {
        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(null);

        // Assert - Traditional
        await Assert.ThrowsAsync<ArgumentNullException>(async () =>
            await _service.CreateOrderAsync(null));

        // Assert - FluentAssertions (Better!)
        await act.Should().ThrowAsync<ArgumentNullException>()
            .WithParameterName("request");
    }

    // ============================================
    // Testing InvalidOperationException
    // ============================================

    [Fact]
    public async Task CreateOrderAsync_EmptyItems_ThrowsInvalidOperationException()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>() // Empty
        };

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*at least one item*");
    }

    // ============================================
    // Testing Custom Exceptions
    // ============================================

    [Fact]
    public async Task CreateOrderAsync_InsufficientInventory_ThrowsInsufficientInventoryException()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>
            {
                new() { ProductId = 1, Quantity = 10, Price = 10m }
            },
            PaymentInfo = new PaymentInfo()
        };

        _mockInventoryService
            .Setup(x => x.GetAvailableQuantityAsync(1))
            .ReturnsAsync(5); // Only 5 available, 10 requested

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert - Verify exception type and properties
        await act.Should().ThrowAsync<InsufficientInventoryException>()
            .Where(ex =>
                ex.ProductId == 1 &&
                ex.RequestedQuantity == 10 &&
                ex.AvailableQuantity == 5)
            .WithMessage("*Insufficient inventory*");
    }

    [Fact]
    public async Task CreateOrderAsync_PaymentFails_ThrowsPaymentFailedException()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, Price = 10m }
            },
            PaymentInfo = new PaymentInfo()
        };

        _mockInventoryService
            .Setup(x => x.GetAvailableQuantityAsync(It.IsAny<int>()))
            .ReturnsAsync(10);

        _mockPaymentProcessor
            .Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentInfo>()))
            .ReturnsAsync(new PaymentResult
            {
                Success = false,
                ErrorCode = "INSUFFICIENT_FUNDS"
            });

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert
        await act.Should().ThrowAsync<PaymentFailedException>()
            .Where(ex => ex.ErrorCode == "INSUFFICIENT_FUNDS")
            .WithMessage("*Payment processing failed*");
    }

    // ============================================
    // Testing Exception with Inner Exception
    // ============================================

    [Fact]
    public async Task CreateOrderAsync_DatabaseError_ThrowsOrderCreationExceptionWithInner()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, Price = 10m }
            },
            PaymentInfo = new PaymentInfo()
        };

        _mockInventoryService
            .Setup(x => x.GetAvailableQuantityAsync(It.IsAny<int>()))
            .ReturnsAsync(10);

        _mockPaymentProcessor
            .Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentInfo>()))
            .ReturnsAsync(new PaymentResult
            {
                Success = true,
                TransactionId = "TX123"
            });

        var dbException = new DbUpdateException("Database error");
        _mockRepository
            .Setup(x => x.AddAsync(It.IsAny<Order>()))
            .ThrowsAsync(dbException);

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert
        await act.Should().ThrowAsync<OrderCreationException>()
            .WithMessage("*Failed to create order*")
            .WithInnerException<DbUpdateException>()
            .WithInnerMessage("*Database error*");

        // Verify refund was called
        _mockPaymentProcessor.Verify(
            x => x.RefundAsync("TX123"),
            Times.Once);
    }

    // ============================================
    // Testing ArgumentException
    // ============================================

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(-100)]
    public async Task GetOrderByIdAsync_InvalidId_ThrowsArgumentException(int invalidId)
    {
        // Act
        Func<Task> act = async () => await _service.GetOrderByIdAsync(invalidId);

        // Assert
        await act.Should().ThrowAsync<ArgumentException>()
            .WithParameterName("orderId")
            .WithMessage("*must be positive*");
    }

    // ============================================
    // Testing Not Found Exception
    // ============================================

    [Fact]
    public async Task GetOrderByIdAsync_OrderNotFound_ThrowsOrderNotFoundException()
    {
        // Arrange
        _mockRepository
            .Setup(x => x.GetByIdAsync(999))
            .ReturnsAsync((Order)null);

        // Act
        Func<Task> act = async () => await _service.GetOrderByIdAsync(999);

        // Assert
        await act.Should().ThrowAsync<OrderNotFoundException>()
            .Where(ex => ex.OrderId == 999)
            .WithMessage("*Order with ID 999 was not found*");
    }

    // ============================================
    // Testing Multiple Possible Exceptions
    // ============================================

    [Theory]
    [InlineData(1, typeof(InsufficientInventoryException))]
    [InlineData(2, typeof(PaymentFailedException))]
    public async Task CreateOrderAsync_VariousErrors_ThrowsCorrectException(
        int scenario,
        Type expectedExceptionType)
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>
            {
                new() { ProductId = 1, Quantity = 10, Price = 10m }
            },
            PaymentInfo = new PaymentInfo()
        };

        if (scenario == 1)
        {
            // Insufficient inventory scenario
            _mockInventoryService
                .Setup(x => x.GetAvailableQuantityAsync(It.IsAny<int>()))
                .ReturnsAsync(5);
        }
        else if (scenario == 2)
        {
            // Payment failure scenario
            _mockInventoryService
                .Setup(x => x.GetAvailableQuantityAsync(It.IsAny<int>()))
                .ReturnsAsync(20);

            _mockPaymentProcessor
                .Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentInfo>()))
                .ReturnsAsync(new PaymentResult { Success = false, ErrorCode = "ERROR" });
        }

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert
        await act.Should().ThrowAsync<Exception>()
            .Where(ex => ex.GetType() == expectedExceptionType);
    }

    // ============================================
    // Testing That No Exception is Thrown
    // ============================================

    [Fact]
    public async Task CreateOrderAsync_ValidRequest_DoesNotThrow()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = 1,
            Items = new List<OrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, Price = 10m }
            },
            PaymentInfo = new PaymentInfo()
        };

        _mockInventoryService
            .Setup(x => x.GetAvailableQuantityAsync(It.IsAny<int>()))
            .ReturnsAsync(10);

        _mockPaymentProcessor
            .Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentInfo>()))
            .ReturnsAsync(new PaymentResult { Success = true, TransactionId = "TX123" });

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(request);

        // Assert
        await act.Should().NotThrowAsync();
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use FluentAssertions for exception testing
   - More readable syntax
   - Better error messages
   - Property assertions

2. ✅ Test exception properties
   - Not just the exception type
   - Verify custom properties
   - Check error messages

3. ✅ Test inner exceptions
   - WithInnerException<T>()
   - Verify inner exception details

4. ✅ Use Where() for complex conditions
   - Multiple property checks
   - Custom validation logic

5. ✅ Test parameter names for ArgumentException
   - WithParameterName()
   - Ensures correct parameter is validated

6. ✅ Test exception messages
   - Use wildcards for partial matches
   - Don't be too specific (brittle tests)

7. ✅ Test cleanup on exceptions
   - Verify rollback operations
   - Check compensation logic

8. ✅ Use Theory for multiple scenarios
   - Different invalid inputs
   - Various error conditions

9. ❌ Don't test framework exceptions
   - Focus on your exception handling
   - Test business logic errors

10. ✅ Test that exceptions are NOT thrown
    - Happy path scenarios
    - NotThrowAsync()
*/
```

---

## **Q273: How do you perform Performance Testing and Benchmarking in .NET?**

**Answer:**

BenchmarkDotNet is the industry-standard library for performance benchmarking in .NET, providing accurate and reliable measurements.

**Installation and Setup:**
```bash
dotnet add package BenchmarkDotNet
```

**Basic Benchmarking:**
```csharp
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

// ============================================
// Simple Benchmark Example
// ============================================

[MemoryDiagnoser]
[RankColumn]
public class StringConcatenationBenchmark
{
    private const int Iterations = 1000;

    [Benchmark(Baseline = true)]
    public string UsingStringConcatenation()
    {
        string result = "";
        for (int i = 0; i < Iterations; i++)
        {
            result += "test";
        }
        return result;
    }

    [Benchmark]
    public string UsingStringBuilder()
    {
        var sb = new StringBuilder();
        for (int i = 0; i < Iterations; i++)
        {
            sb.Append("test");
        }
        return sb.ToString();
    }

    [Benchmark]
    public string UsingStringCreate()
    {
        return string.Create(Iterations * 4, Iterations, (span, count) =>
        {
            for (int i = 0; i < count; i++)
            {
                "test".AsSpan().CopyTo(span.Slice(i * 4, 4));
            }
        });
    }
}

// ============================================
// Running Benchmarks
// ============================================

public class Program
{
    public static void Main(string[] args)
    {
        var summary = BenchmarkRunner.Run<StringConcatenationBenchmark>();
    }
}

// ============================================
// Parameterized Benchmarks
// ============================================

[MemoryDiagnoser]
public class CollectionBenchmarks
{
    [Params(10, 100, 1000)]
    public int ItemCount { get; set; }

    private int[] _data;

    [GlobalSetup]
    public void Setup()
    {
        _data = Enumerable.Range(0, ItemCount).ToArray();
    }

    [Benchmark]
    public List<int> UsingList()
    {
        var list = new List<int>();
        foreach (var item in _data)
        {
            list.Add(item);
        }
        return list;
    }

    [Benchmark]
    public List<int> UsingListWithCapacity()
    {
        var list = new List<int>(ItemCount);
        foreach (var item in _data)
        {
            list.Add(item);
        }
        return list;
    }

    [Benchmark]
    public int[] UsingArray()
    {
        var array = new int[ItemCount];
        for (int i = 0; i < _data.Length; i++)
        {
            array[i] = _data[i];
        }
        return array;
    }

    [Benchmark]
    public Span<int> UsingSpan()
    {
        Span<int> span = stackalloc int[ItemCount];
        _data.AsSpan().CopyTo(span);
        return span;
    }
}

// ============================================
// Advanced Benchmarking Features
// ============================================

[MemoryDiagnoser]
[ThreadingDiagnoser]
[SimpleJob(RunStrategy.ColdStart, iterationCount: 5)]
public class DatabaseQueryBenchmark
{
    private ApplicationDbContext _context;

    [GlobalSetup]
    public void Setup()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase("BenchmarkDb")
            .Options;

        _context = new ApplicationDbContext(options);

        // Seed data
        _context.Products.AddRange(
            Enumerable.Range(1, 10000)
                .Select(i => new Product
                {
                    Id = i,
                    Name = $"Product {i}",
                    Price = i * 10m
                }));
        _context.SaveChanges();
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _context.Dispose();
    }

    [Benchmark]
    public async Task<List<Product>> GetAllProducts_ToList()
    {
        return await _context.Products.ToListAsync();
    }

    [Benchmark]
    public async Task<Product[]> GetAllProducts_ToArray()
    {
        return await _context.Products.ToArrayAsync();
    }

    [Benchmark]
    public async Task<List<Product>> GetAllProducts_AsNoTracking()
    {
        return await _context.Products
            .AsNoTracking()
            .ToListAsync();
    }

    [Benchmark]
    public async Task<int> CountProducts_Count()
    {
        return await _context.Products.CountAsync();
    }

    [Benchmark]
    public async Task<bool> CheckAny_Any()
    {
        return await _context.Products.AnyAsync();
    }
}

// ============================================
// Comparing LINQ Methods
// ============================================

[MemoryDiagnoser]
public class LinqBenchmarks
{
    private List<int> _data;

    [Params(100, 1000, 10000)]
    public int DataSize { get; set; }

    [GlobalSetup]
    public void Setup()
    {
        _data = Enumerable.Range(1, DataSize).ToList();
    }

    [Benchmark]
    public int Sum_Linq()
    {
        return _data.Sum();
    }

    [Benchmark]
    public int Sum_ForLoop()
    {
        int sum = 0;
        for (int i = 0; i < _data.Count; i++)
        {
            sum += _data[i];
        }
        return sum;
    }

    [Benchmark]
    public int Sum_Foreach()
    {
        int sum = 0;
        foreach (var item in _data)
        {
            sum += item;
        }
        return sum;
    }

    [Benchmark]
    public List<int> Where_Linq()
    {
        return _data.Where(x => x % 2 == 0).ToList();
    }

    [Benchmark]
    public List<int> Where_ForLoop()
    {
        var result = new List<int>();
        for (int i = 0; i < _data.Count; i++)
        {
            if (_data[i] % 2 == 0)
            {
                result.Add(_data[i]);
            }
        }
        return result;
    }
}

// ============================================
// Testing Async Performance
// ============================================

[MemoryDiagnoser]
public class AsyncBenchmarks
{
    [Benchmark]
    public async Task<int> AsyncMethod()
    {
        await Task.Delay(1);
        return 42;
    }

    [Benchmark]
    public Task<int> TaskFromResult()
    {
        return Task.FromResult(42);
    }

    [Benchmark]
    public ValueTask<int> ValueTaskReturn()
    {
        return new ValueTask<int>(42);
    }

    [Benchmark]
    public int SynchronousMethod()
    {
        return 42;
    }
}

// ============================================
// Serialization Performance
// ============================================

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
            Description = "A test product for benchmarking"
        };

        _json = JsonSerializer.Serialize(_product);
    }

    [Benchmark]
    public string Serialize_SystemTextJson()
    {
        return JsonSerializer.Serialize(_product);
    }

    [Benchmark]
    public string Serialize_NewtonsoftJson()
    {
        return Newtonsoft.Json.JsonConvert.SerializeObject(_product);
    }

    [Benchmark]
    public Product Deserialize_SystemTextJson()
    {
        return JsonSerializer.Deserialize<Product>(_json);
    }

    [Benchmark]
    public Product Deserialize_NewtonsoftJson()
    {
        return Newtonsoft.Json.JsonConvert.DeserializeObject<Product>(_json);
    }
}

// ============================================
// Load Testing Example
// ============================================

public class LoadTestingExample
{
    [Fact]
    public async Task LoadTest_HandlesConcurrentRequests()
    {
        // Arrange
        var factory = new WebApplicationFactory<Program>();
        var client = factory.CreateClient();

        int concurrentRequests = 100;
        var stopwatch = Stopwatch.StartNew();

        // Act - Send concurrent requests
        var tasks = Enumerable.Range(0, concurrentRequests)
            .Select(async i =>
            {
                var response = await client.GetAsync("/api/products");
                return response.IsSuccessStatusCode;
            });

        var results = await Task.WhenAll(tasks);
        stopwatch.Stop();

        // Assert
        results.Should().AllBeEquivalentTo(true);

        var averageTime = stopwatch.ElapsedMilliseconds / (double)concurrentRequests;
        _output.WriteLine($"Average response time: {averageTime}ms");
        _output.WriteLine($"Total time: {stopwatch.ElapsedMilliseconds}ms");

        // Performance threshold
        averageTime.Should().BeLessThan(100); // Average under 100ms
    }
}

// ============================================
// Response Time Testing
// ============================================

public class PerformanceTests
{
    [Fact]
    public async Task GetProducts_ResponseTime_UnderThreshold()
    {
        // Arrange
        var service = new ProductService(/* dependencies */);
        var stopwatch = Stopwatch.StartNew();

        // Act
        var result = await service.GetProductsAsync();
        stopwatch.Stop();

        // Assert
        result.Should().NotBeNull();
        stopwatch.ElapsedMilliseconds.Should().BeLessThan(500); // Under 500ms
    }

    [Fact]
    public async Task ProcessOrder_MemoryUsage_WithinLimits()
    {
        // Arrange
        var startMemory = GC.GetTotalMemory(true);
        var service = new OrderService(/* dependencies */);

        // Act
        for (int i = 0; i < 1000; i++)
        {
            await service.ProcessOrderAsync(new Order());
        }

        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        var endMemory = GC.GetTotalMemory(true);
        var memoryUsed = (endMemory - startMemory) / 1024 / 1024; // MB

        // Assert
        memoryUsed.Should().BeLessThan(50); // Under 50MB
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use BenchmarkDotNet for accurate measurements
   - Handles warmup, iterations, and statistics
   - Accounts for JIT compilation, GC

2. ✅ Use [MemoryDiagnoser] attribute
   - Track memory allocations
   - Identify memory-intensive operations

3. ✅ Set a baseline
   - [Benchmark(Baseline = true)]
   - Compare alternatives against baseline

4. ✅ Use parameters for different scenarios
   - [Params(10, 100, 1000)]
   - Test across various input sizes

5. ✅ GlobalSetup and GlobalCleanup
   - Initialize expensive resources once
   - Clean up properly

6. ❌ Don't benchmark in Debug mode
   - Always use Release configuration
   - Optimizations matter

7. ✅ Run benchmarks in isolation
   - Close other applications
   - Consistent environment

8. ✅ Test realistic scenarios
   - Use production-like data
   - Simulate actual workloads

9. ✅ Set performance budgets
   - Define acceptable thresholds
   - Fail tests if exceeded

10. ✅ Monitor trends over time
    - Track performance changes
    - CI/CD integration
*/
```

---

## **Q274: How do you test code that makes HTTP calls to external APIs?**

**Answer:**

Testing HTTP clients requires mocking HTTP responses to avoid dependencies on external services.

**Approaches:**
```csharp
using System.Net.Http;
using Moq;
using Moq.Protected;
using Xunit;

// ============================================
// HTTP Client Service
// ============================================

public interface IWeatherService
{
    Task<WeatherResponse> GetWeatherAsync(string city);
    Task<bool> IsServiceHealthyAsync();
}

public class WeatherService : IWeatherService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<WeatherService> _logger;

    public WeatherService(HttpClient httpClient, ILogger<WeatherService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<WeatherResponse> GetWeatherAsync(string city)
    {
        try
        {
            var response = await _httpClient.GetAsync($"/weather?q={city}");
            response.EnsureSuccessStatusCode();

            var weather = await response.Content.ReadFromJsonAsync<WeatherResponse>();
            return weather;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error fetching weather for {City}", city);
            throw new WeatherServiceException($"Failed to get weather for {city}", ex);
        }
    }

    public async Task<bool> IsServiceHealthyAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync("/health");
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}

// ============================================
// Approach 1: Mocking HttpMessageHandler
// ============================================

public class WeatherServiceTests
{
    private readonly Mock<ILogger<WeatherService>> _mockLogger;

    public WeatherServiceTests()
    {
        _mockLogger = new Mock<ILogger<WeatherService>>();
    }

    [Fact]
    public async Task GetWeatherAsync_SuccessfulResponse_ReturnsWeather()
    {
        // Arrange
        var expectedWeather = new WeatherResponse
        {
            City = "London",
            Temperature = 15.5,
            Condition = "Cloudy"
        };

        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = JsonContent.Create(expectedWeather)
            });

        var httpClient = new HttpClient(handlerMock.Object)
        {
            BaseAddress = new Uri("https://api.weather.com")
        };

        var service = new WeatherService(httpClient, _mockLogger.Object);

        // Act
        var result = await service.GetWeatherAsync("London");

        // Assert
        result.Should().NotBeNull();
        result.City.Should().Be("London");
        result.Temperature.Should().Be(15.5);
        result.Condition.Should().Be("Cloudy");

        // Verify HTTP call was made
        handlerMock.Protected().Verify(
            "SendAsync",
            Times.Once(),
            ItExpr.Is<HttpRequestMessage>(req =>
                req.Method == HttpMethod.Get &&
                req.RequestUri.ToString().Contains("weather?q=London")),
            ItExpr.IsAny<CancellationToken>());
    }

    [Fact]
    public async Task GetWeatherAsync_404NotFound_ThrowsException()
    {
        // Arrange
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.NotFound,
                Content = new StringContent("City not found")
            });

        var httpClient = new HttpClient(handlerMock.Object)
        {
            BaseAddress = new Uri("https://api.weather.com")
        };

        var service = new WeatherService(httpClient, _mockLogger.Object);

        // Act
        Func<Task> act = async () => await service.GetWeatherAsync("InvalidCity");

        // Assert
        await act.Should().ThrowAsync<WeatherServiceException>()
            .WithMessage("*Failed to get weather*");
    }

    [Fact]
    public async Task GetWeatherAsync_NetworkError_ThrowsException()
    {
        // Arrange
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ThrowsAsync(new HttpRequestException("Network error"));

        var httpClient = new HttpClient(handlerMock.Object)
        {
            BaseAddress = new Uri("https://api.weather.com")
        };

        var service = new WeatherService(httpClient, _mockLogger.Object);

        // Act
        Func<Task> act = async () => await service.GetWeatherAsync("London");

        // Assert
        await act.Should().ThrowAsync<WeatherServiceException>();

        // Verify logging
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}

// ============================================
// Approach 2: HttpClient Factory Pattern
// ============================================

public class WeatherServiceWithFactoryTests
{
    [Fact]
    public async Task GetWeatherAsync_UsingFactory_ReturnsWeather()
    {
        // Arrange
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = JsonContent.Create(new WeatherResponse
                {
                    City = "Paris",
                    Temperature = 20.0,
                    Condition = "Sunny"
                })
            });

        var mockFactory = new Mock<IHttpClientFactory>();
        mockFactory
            .Setup(x => x.CreateClient("WeatherApi"))
            .Returns(new HttpClient(handlerMock.Object)
            {
                BaseAddress = new Uri("https://api.weather.com")
            });

        var logger = new Mock<ILogger<WeatherService>>();
        var service = new WeatherService(
            mockFactory.Object.CreateClient("WeatherApi"),
            logger.Object);

        // Act
        var result = await service.GetWeatherAsync("Paris");

        // Assert
        result.Should().NotBeNull();
        result.City.Should().Be("Paris");
        result.Temperature.Should().Be(20.0);
    }
}

// ============================================
// Approach 3: WireMock for Integration Testing
// ============================================

public class WeatherServiceIntegrationTests : IAsyncLifetime
{
    private WireMockServer _wireMockServer;
    private WeatherService _service;

    public async Task InitializeAsync()
    {
        // Start WireMock server
        _wireMockServer = WireMockServer.Start();

        var httpClient = new HttpClient
        {
            BaseAddress = new Uri(_wireMockServer.Urls[0])
        };

        var logger = new Mock<ILogger<WeatherService>>();
        _service = new WeatherService(httpClient, logger.Object);

        await Task.CompletedTask;
    }

    [Fact]
    public async Task GetWeatherAsync_WithWireMock_ReturnsWeather()
    {
        // Arrange - Setup WireMock stub
        _wireMockServer
            .Given(Request.Create()
                .WithPath("/weather")
                .WithParam("q", "Berlin")
                .UsingGet())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithHeader("Content-Type", "application/json")
                .WithBodyAsJson(new WeatherResponse
                {
                    City = "Berlin",
                    Temperature = 18.0,
                    Condition = "Partly Cloudy"
                }));

        // Act
        var result = await _service.GetWeatherAsync("Berlin");

        // Assert
        result.Should().NotBeNull();
        result.City.Should().Be("Berlin");
        result.Temperature.Should().Be(18.0);

        // Verify request was made
        var requests = _wireMockServer.LogEntries;
        requests.Should().HaveCount(1);
        requests.First().RequestMessage.Path.Should().Contain("/weather");
    }

    [Fact]
    public async Task GetWeatherAsync_WithDelay_HandlesTimeout()
    {
        // Arrange - Simulate slow API
        _wireMockServer
            .Given(Request.Create()
                .WithPath("/weather")
                .UsingGet())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithDelay(TimeSpan.FromSeconds(10))
                .WithBodyAsJson(new WeatherResponse()));

        // Act & Assert
        Func<Task> act = async () => await _service.GetWeatherAsync("SlowCity");

        await act.Should().ThrowAsync<TaskCanceledException>();
    }

    public async Task DisposeAsync()
    {
        _wireMockServer?.Stop();
        _wireMockServer?.Dispose();
        await Task.CompletedTask;
    }
}

// ============================================
// Approach 4: Refit with Mock Handlers
// ============================================

// Refit interface
public interface IWeatherApi
{
    [Get("/weather?q={city}")]
    Task<WeatherResponse> GetWeatherAsync(string city);

    [Get("/health")]
    Task<HttpResponseMessage> HealthCheckAsync();
}

public class RefitWeatherServiceTests
{
    [Fact]
    public async Task GetWeatherAsync_UsingRefit_ReturnsWeather()
    {
        // Arrange
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = JsonContent.Create(new WeatherResponse
                {
                    City = "Tokyo",
                    Temperature = 25.0,
                    Condition = "Clear"
                })
            });

        var httpClient = new HttpClient(handlerMock.Object)
        {
            BaseAddress = new Uri("https://api.weather.com")
        };

        var weatherApi = RestService.For<IWeatherApi>(httpClient);

        // Act
        var result = await weatherApi.GetWeatherAsync("Tokyo");

        // Assert
        result.Should().NotBeNull();
        result.City.Should().Be("Tokyo");
    }
}

// ============================================
// Testing Retry Logic
// ============================================

public class RetryTests
{
    [Fact]
    public async Task GetWeatherAsync_RetriesOnFailure_EventuallySucceeds()
    {
        // Arrange
        int callCount = 0;
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(() =>
            {
                callCount++;
                if (callCount < 3)
                {
                    return new HttpResponseMessage(HttpStatusCode.ServiceUnavailable);
                }
                return new HttpResponseMessage
                {
                    StatusCode = HttpStatusCode.OK,
                    Content = JsonContent.Create(new WeatherResponse
                    {
                        City = "Retry City",
                        Temperature = 22.0
                    })
                };
            });

        var httpClient = new HttpClient(handlerMock.Object)
        {
            BaseAddress = new Uri("https://api.weather.com")
        };

        var service = new WeatherServiceWithRetry(httpClient);

        // Act
        var result = await service.GetWeatherAsync("Retry City");

        // Assert
        result.Should().NotBeNull();
        callCount.Should().Be(3); // Failed twice, succeeded on third attempt
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Mock HttpMessageHandler, not HttpClient
   - HttpClient is not easily mockable
   - Mock the underlying handler

2. ✅ Use HttpClient factory pattern
   - Easier to inject and test
   - Better lifetime management

3. ✅ Test different HTTP status codes
   - 200, 404, 500, etc.
   - Timeouts and network errors

4. ✅ Use WireMock for integration tests
   - Simulate real API behavior
   - Test delays, errors, edge cases

5. ✅ Verify request details
   - URL, headers, query parameters
   - Request body for POST/PUT

6. ✅ Test retry and resilience logic
   - Polly integration
   - Circuit breakers

7. ✅ Use Refit for cleaner API clients
   - Type-safe HTTP client
   - Easy to test

8. ❌ Don't make real HTTP calls in unit tests
   - Slow and unreliable
   - External dependencies

9. ✅ Test serialization/deserialization
   - Verify JSON mapping
   - Handle malformed responses

10. ✅ Set appropriate timeouts
    - Test timeout scenarios
    - CancellationToken support
*/
```

---

## **Q275: What are common Testing Best Practices and Anti-Patterns?**

**Answer:**

Understanding best practices and avoiding anti-patterns ensures tests are maintainable, reliable, and valuable.

**Best Practices:**
```csharp
// ============================================
// ✅ GOOD: AAA Pattern (Arrange, Act, Assert)
// ============================================

[Fact]
public async Task CreateOrder_ValidData_CreatesSuccessfully()
{
    // Arrange - Setup
    var mockRepository = new Mock<IOrderRepository>();
    var service = new OrderService(mockRepository.Object);
    var order = new Order { Id = 1, Total = 100m };

    // Act - Execute the operation
    var result = await service.CreateOrderAsync(order);

    // Assert - Verify the outcome
    result.Should().NotBeNull();
    result.Id.Should().Be(1);
    mockRepository.Verify(x => x.AddAsync(It.IsAny<Order>()), Times.Once);
}

// ============================================
// ❌ BAD: Multiple Acts/Asserts (Hard to debug)
// ============================================

[Fact]
public async Task MultipleOperations_BadExample()
{
    var service = new OrderService();

    var order1 = await service.CreateOrderAsync(new Order());
    order1.Should().NotBeNull(); // First assert

    var order2 = await service.CreateOrderAsync(new Order());
    order2.Should().NotBeNull(); // Second assert

    var orders = await service.GetAllOrdersAsync();
    orders.Should().HaveCount(2); // Third assert
    // If this fails, which operation is the problem?
}

// ============================================
// ✅ GOOD: One Assertion Per Test (Single Responsibility)
// ============================================

[Fact]
public async Task CreateOrder_ValidData_ReturnsOrder()
{
    var service = new OrderService();
    var result = await service.CreateOrderAsync(new Order());
    result.Should().NotBeNull();
}

[Fact]
public async Task CreateOrder_ValidData_SavesToRepository()
{
    var mockRepo = new Mock<IOrderRepository>();
    var service = new OrderService(mockRepo.Object);

    await service.CreateOrderAsync(new Order());

    mockRepo.Verify(x => x.AddAsync(It.IsAny<Order>()), Times.Once);
}

// ============================================
// ❌ ANTI-PATTERN: Logic in Tests
// ============================================

[Fact]
public void CalculateTotal_WithItems_ReturnsCorrectTotal_BAD()
{
    var items = new List<OrderItem>();
    decimal expectedTotal = 0;

    // ❌ Logic in test - calculating expected value
    for (int i = 1; i <= 10; i++)
    {
        items.Add(new OrderItem { Price = i * 10m, Quantity = 2 });
        expectedTotal += i * 10m * 2;
    }

    var order = new Order { Items = items };
    var result = order.CalculateTotal();

    result.Should().Be(expectedTotal); // What if the loop logic is wrong?
}

// ============================================
// ✅ GOOD: Explicit Expected Values
// ============================================

[Fact]
public void CalculateTotal_WithItems_ReturnsCorrectTotal_GOOD()
{
    // Arrange - Explicit, verifiable data
    var items = new List<OrderItem>
    {
        new() { Price = 10m, Quantity = 2 }, // 20
        new() { Price = 20m, Quantity = 1 }, // 20
        new() { Price = 30m, Quantity = 3 }  // 90
    };

    var order = new Order { Items = items };

    // Act
    var result = order.CalculateTotal();

    // Assert - Explicit expected value
    result.Should().Be(130m); // 20 + 20 + 90
}

// ============================================
// ❌ ANTI-PATTERN: Fragile Tests (Coupled to Implementation)
// ============================================

[Fact]
public async Task ProcessOrder_CallsMethodsInOrder_BAD()
{
    var mockRepo = new Mock<IOrderRepository>();
    var mockValidator = new Mock<IOrderValidator>();
    var mockEmailService = new Mock<IEmailService>();
    var service = new OrderService(mockRepo.Object, mockValidator.Object, mockEmailService.Object);

    // ❌ Testing internal implementation details
    await service.ProcessOrderAsync(new Order());

    // Breaks if internal order changes
    mockValidator.Verify(x => x.ValidateAsync(It.IsAny<Order>()), Times.Once);
    mockRepo.Verify(x => x.SaveAsync(It.IsAny<Order>()), Times.Once);
    mockEmailService.Verify(x => x.SendConfirmationAsync(It.IsAny<string>()), Times.Once);
}

// ============================================
// ✅ GOOD: Testing Behavior, Not Implementation
// ============================================

[Fact]
public async Task ProcessOrder_ValidOrder_SendsConfirmation()
{
    // Arrange
    var mockEmailService = new Mock<IEmailService>();
    var service = new OrderService(mockEmailService.Object);
    var order = new Order { CustomerEmail = "test@example.com" };

    // Act
    await service.ProcessOrderAsync(order);

    // Assert - Test the observable behavior
    mockEmailService.Verify(
        x => x.SendConfirmationAsync("test@example.com"),
        Times.Once);
}

// ============================================
// ❌ ANTI-PATTERN: Test Interdependence
// ============================================

public class OrderServiceTests_BAD
{
    private static Order _sharedOrder; // ❌ Shared state

    [Fact]
    public async Task Test1_CreateOrder()
    {
        var service = new OrderService();
        _sharedOrder = await service.CreateOrderAsync(new Order());
        _sharedOrder.Should().NotBeNull();
    }

    [Fact]
    public async Task Test2_UpdateOrder() // ❌ Depends on Test1
    {
        var service = new OrderService();
        _sharedOrder.Total = 200m;
        await service.UpdateOrderAsync(_sharedOrder);
        _sharedOrder.Total.Should().Be(200m);
    }
}

// ============================================
// ✅ GOOD: Independent Tests
// ============================================

public class OrderServiceTests_GOOD
{
    [Fact]
    public async Task CreateOrder_ValidData_ReturnsOrder()
    {
        // Arrange - Fresh setup for each test
        var service = new OrderService();
        var order = new Order { Total = 100m };

        // Act
        var result = await service.CreateOrderAsync(order);

        // Assert
        result.Should().NotBeNull();
    }

    [Fact]
    public async Task UpdateOrder_ExistingOrder_UpdatesSuccessfully()
    {
        // Arrange - Independent setup
        var service = new OrderService();
        var order = new Order { Id = 1, Total = 100m };

        // Act
        order.Total = 200m;
        await service.UpdateOrderAsync(order);

        // Assert
        order.Total.Should().Be(200m);
    }
}

// ============================================
// ❌ ANTI-PATTERN: Ignoring Async/Await
// ============================================

[Fact]
public void GetUserAsync_BAD()
{
    var service = new UserService();

    // ❌ Using .Result blocks the thread
    var user = service.GetUserAsync(1).Result;

    user.Should().NotBeNull();
}

// ============================================
// ✅ GOOD: Proper Async Testing
// ============================================

[Fact]
public async Task GetUserAsync_GOOD()
{
    var service = new UserService();

    // ✅ Properly awaited
    var user = await service.GetUserAsync(1);

    user.Should().NotBeNull();
}

// ============================================
// ❌ ANTI-PATTERN: Excessive Mocking
// ============================================

[Fact]
public async Task ProcessPayment_ExcessiveMocking_BAD()
{
    // ❌ Mocking everything, including simple DTOs
    var mockOrder = new Mock<IOrder>();
    var mockCustomer = new Mock<ICustomer>();
    var mockPaymentInfo = new Mock<IPaymentInfo>();
    var mockLogger = new Mock<ILogger>();
    var mockConfig = new Mock<IConfiguration>();
    var mockCache = new Mock<ICache>();

    // Test becomes unreadable and brittle
}

// ============================================
// ✅ GOOD: Mock Only Dependencies
// ============================================

[Fact]
public async Task ProcessPayment_MinimalMocking_GOOD()
{
    // Arrange - Only mock external dependencies
    var mockPaymentGateway = new Mock<IPaymentGateway>();
    mockPaymentGateway
        .Setup(x => x.ChargeAsync(It.IsAny<decimal>()))
        .ReturnsAsync(new PaymentResult { Success = true });

    // Use real objects for simple value types
    var order = new Order { Total = 100m };
    var service = new PaymentService(mockPaymentGateway.Object);

    // Act
    var result = await service.ProcessPaymentAsync(order);

    // Assert
    result.Success.Should().BeTrue();
}

// ============================================
// ❌ ANTI-PATTERN: Testing Private Methods
// ============================================

public class CalculatorTests_BAD
{
    [Fact]
    public void TestPrivateMethod_BAD()
    {
        var calculator = new Calculator();

        // ❌ Using reflection to test private methods
        var method = typeof(Calculator).GetMethod(
            "PrivateValidate",
            BindingFlags.NonPublic | BindingFlags.Instance);

        var result = method.Invoke(calculator, new object[] { 5 });

        result.Should().Be(true);
    }
}

// ============================================
// ✅ GOOD: Test Through Public Interface
// ============================================

public class CalculatorTests_GOOD
{
    [Fact]
    public void Calculate_InvalidInput_ThrowsException()
    {
        // Arrange
        var calculator = new Calculator();

        // Act & Assert - Private validation is tested indirectly
        var act = () => calculator.Calculate(-1);
        act.Should().Throw<ArgumentException>();
    }
}

// ============================================
// ❌ ANTI-PATTERN: Conditional Logic in Tests
// ============================================

[Theory]
[InlineData(1, 10)]
[InlineData(2, 20)]
[InlineData(3, 30)]
public void GetPrice_WithDiscount_BAD(int productId, decimal expectedPrice)
{
    var service = new PricingService();
    var price = service.GetPrice(productId);

    // ❌ Conditional logic in test
    if (productId == 1)
    {
        price.Should().BeGreaterThan(5);
    }
    else if (productId == 2)
    {
        price.Should().BeLessThan(25);
    }
    else
    {
        price.Should().Be(expectedPrice);
    }
}

// ============================================
// ✅ GOOD: Separate Tests for Each Scenario
// ============================================

[Fact]
public void GetPrice_Product1_ReturnsCorrectPrice()
{
    var service = new PricingService();
    var price = service.GetPrice(1);
    price.Should().Be(10m);
}

[Fact]
public void GetPrice_Product2_ReturnsCorrectPrice()
{
    var service = new PricingService();
    var price = service.GetPrice(2);
    price.Should().Be(20m);
}

// ============================================
// ✅ GOOD: Descriptive Test Names
// ============================================

// ❌ BAD: Vague names
[Fact]
public void Test1() { }

[Fact]
public void TestOrder() { }

// ✅ GOOD: Descriptive names
[Fact]
public void CreateOrder_WithNullCustomer_ThrowsArgumentNullException() { }

[Fact]
public void CalculateDiscount_ForPremiumCustomer_Returns20PercentOff() { }

// ============================================
// Summary of Best Practices
// ============================================

/*
BEST PRACTICES:
1. ✅ Follow AAA pattern (Arrange, Act, Assert)
2. ✅ One logical assertion per test
3. ✅ Test behavior, not implementation
4. ✅ Make tests independent and isolated
5. ✅ Use descriptive test names
6. ✅ Use async/await properly
7. ✅ Mock only external dependencies
8. ✅ Use explicit expected values
9. ✅ Keep tests simple and readable
10. ✅ Test through public interfaces

ANTI-PATTERNS TO AVOID:
1. ❌ Multiple acts/asserts in one test
2. ❌ Logic in tests (loops, conditionals)
3. ❌ Testing implementation details
4. ❌ Test interdependence
5. ❌ Ignoring async/await
6. ❌ Excessive mocking
7. ❌ Testing private methods
8. ❌ Conditional logic in tests
9. ❌ Vague test names
10. ❌ Shared state between tests
*/
```

---

## **Q276: How do you test Background Services and Hosted Services in ASP.NET Core?**

**Answer:**

Background services run long-running operations. Testing them requires special techniques to control their lifecycle and timing.

**Testing Strategies:**
```csharp
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

// ============================================
// Background Service Example
// ============================================

public class OrderProcessingService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<OrderProcessingService> _logger;

    public OrderProcessingService(
        IServiceProvider serviceProvider,
        ILogger<OrderProcessingService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Order Processing Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var orderService = scope.ServiceProvider.GetRequiredService<IOrderService>();

                await orderService.ProcessPendingOrdersAsync();

                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Service is stopping
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing orders");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }

        _logger.LogInformation("Order Processing Service stopped");
    }
}

// ============================================
// Approach 1: Direct Testing with CancellationToken
// ============================================

public class OrderProcessingServiceTests
{
    [Fact]
    public async Task ExecuteAsync_ProcessesPendingOrders()
    {
        // Arrange
        var mockOrderService = new Mock<IOrderService>();
        mockOrderService
            .Setup(x => x.ProcessPendingOrdersAsync())
            .ReturnsAsync(5); // 5 orders processed

        var serviceProvider = new ServiceCollection()
            .AddScoped(_ => mockOrderService.Object)
            .BuildServiceProvider();

        var logger = new Mock<ILogger<OrderProcessingService>>();
        var service = new OrderProcessingService(serviceProvider, logger.Object);

        // Use CancellationTokenSource with timeout
        var cts = new CancellationTokenSource();

        // Act - Start the service
        var executeTask = service.StartAsync(cts.Token);

        // Wait for at least one iteration
        await Task.Delay(100);

        // Stop the service
        cts.Cancel();
        await service.StopAsync(CancellationToken.None);

        // Assert
        mockOrderService.Verify(
            x => x.ProcessPendingOrdersAsync(),
            Times.AtLeastOnce);
    }

    [Fact]
    public async Task ExecuteAsync_HandlesExceptions_ContinuesProcessing()
    {
        // Arrange
        int callCount = 0;
        var mockOrderService = new Mock<IOrderService>();
        mockOrderService
            .Setup(x => x.ProcessPendingOrdersAsync())
            .Returns(() =>
            {
                callCount++;
                if (callCount == 1)
                    throw new InvalidOperationException("First call fails");
                return Task.FromResult(0);
            });

        var serviceProvider = new ServiceCollection()
            .AddScoped(_ => mockOrderService.Object)
            .BuildServiceProvider();

        var mockLogger = new Mock<ILogger<OrderProcessingService>>();
        var service = new OrderProcessingService(serviceProvider, mockLogger.Object);

        var cts = new CancellationTokenSource();

        // Act
        var executeTask = service.StartAsync(cts.Token);
        await Task.Delay(500); // Wait for error and retry
        cts.Cancel();
        await service.StopAsync(CancellationToken.None);

        // Assert - Service should have retried after error
        callCount.Should().BeGreaterThan(1);

        // Verify error was logged
        mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<InvalidOperationException>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}

// ============================================
// Testable Background Service Design
// ============================================

public class TestableOrderProcessingService : BackgroundService
{
    private readonly IOrderService _orderService;
    private readonly ILogger<TestableOrderProcessingService> _logger;
    private readonly TimeSpan _delay;

    public TestableOrderProcessingService(
        IOrderService orderService,
        ILogger<TestableOrderProcessingService> logger,
        TimeSpan? delay = null)
    {
        _orderService = orderService;
        _logger = logger;
        _delay = delay ?? TimeSpan.FromMinutes(5); // Configurable delay for testing
    }

    // Expose for testing
    public async Task ProcessOnceAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await _orderService.ProcessPendingOrdersAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing orders");
            throw;
        }
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOnceAsync(stoppingToken);
                await Task.Delay(_delay, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Background service error");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }
}

// ============================================
// Testing Testable Background Service
// ============================================

public class TestableOrderProcessingServiceTests
{
    [Fact]
    public async Task ProcessOnceAsync_ProcessesPendingOrders()
    {
        // Arrange
        var mockOrderService = new Mock<IOrderService>();
        mockOrderService
            .Setup(x => x.ProcessPendingOrdersAsync())
            .ReturnsAsync(3);

        var mockLogger = new Mock<ILogger<TestableOrderProcessingService>>();
        var service = new TestableOrderProcessingService(
            mockOrderService.Object,
            mockLogger.Object,
            TimeSpan.FromMilliseconds(100)); // Short delay for testing

        // Act - Test single iteration directly
        await service.ProcessOnceAsync();

        // Assert
        mockOrderService.Verify(
            x => x.ProcessPendingOrdersAsync(),
            Times.Once);
    }

    [Fact]
    public async Task ProcessOnceAsync_ErrorOccurs_LogsAndThrows()
    {
        // Arrange
        var mockOrderService = new Mock<IOrderService>();
        mockOrderService
            .Setup(x => x.ProcessPendingOrdersAsync())
            .ThrowsAsync(new InvalidOperationException("Test error"));

        var mockLogger = new Mock<ILogger<TestableOrderProcessingService>>();
        var service = new TestableOrderProcessingService(
            mockOrderService.Object,
            mockLogger.Object);

        // Act
        Func<Task> act = async () => await service.ProcessOnceAsync();

        // Assert
        await act.Should().ThrowAsync<InvalidOperationException>();

        mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<InvalidOperationException>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}

// ============================================
// Timed Hosted Service
// ============================================

public class TimedDataCleanupService : IHostedService, IDisposable
{
    private readonly ILogger<TimedDataCleanupService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private Timer _timer;

    public TimedDataCleanupService(
        ILogger<TimedDataCleanupService> logger,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Timed Cleanup Service starting");

        _timer = new Timer(
            DoWork,
            null,
            TimeSpan.Zero,
            TimeSpan.FromHours(24));

        return Task.CompletedTask;
    }

    private async void DoWork(object state)
    {
        using var scope = _serviceProvider.CreateScope();
        var dataService = scope.ServiceProvider.GetRequiredService<IDataService>();

        try
        {
            var deletedCount = await dataService.DeleteOldRecordsAsync();
            _logger.LogInformation("Deleted {Count} old records", deletedCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during cleanup");
        }
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Timed Cleanup Service stopping");
        _timer?.Change(Timeout.Infinite, 0);
        return Task.CompletedTask;
    }

    public void Dispose()
    {
        _timer?.Dispose();
    }
}

// ============================================
// Testing Timed Hosted Service
// ============================================

public class TimedDataCleanupServiceTests : IDisposable
{
    private readonly Mock<IDataService> _mockDataService;
    private readonly ServiceProvider _serviceProvider;
    private readonly TimedDataCleanupService _service;

    public TimedDataCleanupServiceTests()
    {
        _mockDataService = new Mock<IDataService>();

        _serviceProvider = new ServiceCollection()
            .AddScoped(_ => _mockDataService.Object)
            .BuildServiceProvider();

        var mockLogger = new Mock<ILogger<TimedDataCleanupService>>();
        _service = new TimedDataCleanupService(mockLogger.Object, _serviceProvider);
    }

    [Fact]
    public async Task StartAsync_TriggersInitialCleanup()
    {
        // Arrange
        _mockDataService
            .Setup(x => x.DeleteOldRecordsAsync())
            .ReturnsAsync(10);

        // Act
        await _service.StartAsync(CancellationToken.None);

        // Wait for timer to execute
        await Task.Delay(500);

        // Assert
        _mockDataService.Verify(
            x => x.DeleteOldRecordsAsync(),
            Times.AtLeastOnce);

        // Cleanup
        await _service.StopAsync(CancellationToken.None);
    }

    public void Dispose()
    {
        _service?.Dispose();
        _serviceProvider?.Dispose();
    }
}

// ============================================
// Integration Testing with WebApplicationFactory
// ============================================

public class BackgroundServiceIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public BackgroundServiceIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace background service with test version
                services.AddHostedService<TestableOrderProcessingService>();
            });
        });
    }

    [Fact]
    public async Task BackgroundService_RunsInApplication()
    {
        // Arrange - Start the application
        using var scope = _factory.Services.CreateScope();
        var hostedServices = scope.ServiceProvider
            .GetServices<IHostedService>()
            .OfType<TestableOrderProcessingService>();

        // Assert - Service is registered
        hostedServices.Should().NotBeEmpty();
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Make background work testable
   - Extract core logic to testable methods
   - Use dependency injection

2. ✅ Use configurable delays
   - TimeSpan parameters for testing
   - Short delays in tests

3. ✅ Test error handling
   - Exceptions don't crash service
   - Proper logging

4. ✅ Use CancellationToken correctly
   - Respond to cancellation
   - Clean shutdown

5. ✅ Test lifecycle
   - StartAsync
   - StopAsync
   - Dispose

6. ✅ Avoid long delays in tests
   - Use short timeouts
   - Test iterations directly

7. ✅ Mock dependencies
   - IServiceProvider for scopes
   - Actual services

8. ✅ Verify logging
   - Startup/shutdown
   - Errors

9. ✅ Test timer-based services carefully
   - May need longer waits
   - Use Task.Delay strategically

10. ✅ Integration tests for full lifecycle
    - WebApplicationFactory
    - Actual hosting environment
*/
```

---

## **Q277: What is Snapshot Testing and when should you use it?**

**Answer:**

Snapshot testing captures the output of a function and compares it to a stored "snapshot". Useful for testing complex output that doesn't change frequently.

**Implementation:**
```csharp
using Snapshooter.Xunit;
using Xunit;

// ============================================
// Installation
// ============================================

// dotnet add package Snapshooter.Xunit

// ============================================
// Basic Snapshot Testing
// ============================================

public class ApiResponseSnapshotTests
{
    [Fact]
    public void GetProduct_ReturnsExpectedStructure()
    {
        // Arrange
        var service = new ProductService();

        // Act
        var product = service.GetProductById(1);

        // Assert - Creates snapshot on first run, compares on subsequent runs
        Snapshot.Match(product);
    }

    [Fact]
    public void GetProductList_ReturnsExpectedStructure()
    {
        // Arrange
        var service = new ProductService();

        // Act
        var products = service.GetAllProducts();

        // Assert
        Snapshot.Match(products);
    }
}

// ============================================
// Snapshot with Custom Settings
// ============================================

public class CustomSnapshotTests
{
    [Fact]
    public void GetOrder_IgnoresDynamicFields()
    {
        // Arrange
        var order = new Order
        {
            Id = 1,
            OrderDate = DateTime.UtcNow, // Changes each run
            Total = 100m,
            Items = new List<OrderItem>
            {
                new() { ProductId = 1, Quantity = 2, Price = 50m }
            }
        };

        // Assert - Ignore dynamic fields
        Snapshot.Match(order, matchOptions => matchOptions
            .IgnoreField("OrderDate")
            .IgnoreField("**.Id")); // Ignore all Id fields
    }

    [Fact]
    public void GetUser_SnapshotWithAssert()
    {
        var user = new User
        {
            Id = 1,
            Name = "John Doe",
            Email = "john@example.com",
            CreatedAt = new DateTime(2024, 1, 1)
        };

        // Combine snapshot with assertions
        Snapshot.Match(user, matchOptions => matchOptions
            .Assert(fieldOption =>
            {
                // Additional assertions
                Assert.Equal("John Doe", fieldOption.Field<string>("Name"));
                Assert.Contains("@", fieldOption.Field<string>("Email"));
            }));
    }
}

// ============================================
// API Response Snapshot Testing
// ============================================

public class ApiSnapshotTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public ApiSnapshotTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetProducts_ReturnsExpectedResponse()
    {
        // Act
        var response = await _client.GetAsync("/api/products");
        var content = await response.Content.ReadAsStringAsync();
        var products = JsonSerializer.Deserialize<List<ProductDto>>(content);

        // Assert - Snapshot the response
        Snapshot.Match(products, matchOptions => matchOptions
            .IgnoreField("**.Id")
            .IgnoreField("**.CreatedAt"));
    }

    [Fact]
    public async Task GetProduct_NotFound_ReturnsExpectedError()
    {
        // Act
        var response = await _client.GetAsync("/api/products/999");
        var content = await response.Content.ReadAsStringAsync();

        // Assert - Snapshot error response
        Snapshot.Match(new
        {
            StatusCode = (int)response.StatusCode,
            Content = content
        });
    }
}

// ============================================
// HTML/UI Snapshot Testing
// ============================================

public class RazorPageSnapshotTests
{
    [Fact]
    public void ProductCard_RendersCorrectly()
    {
        // Arrange
        var product = new Product
        {
            Id = 1,
            Name = "Test Product",
            Price = 29.99m,
            Description = "A test product"
        };

        var viewModel = new ProductViewModel(product);

        // Act - Render view to string
        var html = RenderViewToString(viewModel);

        // Assert - Snapshot the HTML
        Snapshot.Match(html);
    }
}

// ============================================
// When to Use Snapshot Testing
// ============================================

/*
✅ GOOD use cases:
1. API response structures
   - Verify contract hasn't changed
   - Catch unintended modifications

2. Complex object graphs
   - Nested objects
   - Large data structures

3. Configuration objects
   - Settings and options
   - Schema verification

4. UI component output
   - HTML rendering
   - JSON responses

5. Serialization testing
   - JSON/XML output
   - Format verification

❌ BAD use cases:
1. Dynamic data (timestamps, GUIDs)
   - Changes every run
   - Defeats the purpose

2. Simple assertions
   - Use regular assertions instead
   - More explicit and clear

3. Frequently changing code
   - Constant snapshot updates
   - Maintenance burden

4. Random or time-dependent data
   - Test becomes flaky
   - Need to ignore too many fields
*/

// ============================================
// Approval Testing (Similar Concept)
// ============================================

public class ApprovalTests
{
    [Fact]
    public void GenerateReport_CreatesExpectedOutput()
    {
        // Arrange
        var report = new ReportGenerator();
        var data = new ReportData
        {
            Title = "Monthly Sales",
            Items = new[] { "Item 1", "Item 2", "Item 3" }
        };

        // Act
        var output = report.Generate(data);

        // Assert - Save to approval file
        // First run: creates .approved.txt file
        // Subsequent runs: compares to .approved.txt
        ApprovalTests.Approvals.Verify(output);
    }
}

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Use for complex output
   - Large objects
   - API responses
   - Configuration

2. ✅ Ignore dynamic fields
   - Timestamps
   - GUIDs
   - Random data

3. ✅ Review snapshot changes carefully
   - Ensure changes are intentional
   - Part of code review

4. ✅ Keep snapshots in source control
   - Track changes
   - Version history

5. ❌ Don't snapshot everything
   - Use when appropriate
   - Combine with traditional assertions

6. ✅ Update snapshots intentionally
   - Review before updating
   - Document why

7. ✅ Use descriptive test names
   - Snapshot files named after test
   - Easy to identify

8. ✅ Combine with other testing approaches
   - Not a replacement for unit tests
   - Complementary technique

9. ❌ Don't use for simple values
   - Use Assert.Equal() instead
   - More explicit

10. ✅ Test data should be deterministic
    - Same input = same output
    - Avoid randomness
*/
```

---

## **Q278: What is Contract Testing and how does it apply to Microservices?**

**Answer:**

Contract testing ensures that services can communicate correctly by verifying that a provider's API matches the consumer's expectations.

**Implementation with Pact:**
```csharp
using PactNet;
using Xunit;

// ============================================
// Consumer Side (Order Service)
// ============================================

// Consumer defines what it expects from the provider
public class ProductApiConsumerTests : IDisposable
{
    private readonly IPactBuilderV3 _pactBuilder;
    private readonly ITestOutputHelper _output;

    public ProductApiConsumerTests(ITestOutputHelper output)
    {
        _output = output;

        var pactConfig = new PactConfig
        {
            PactDir = Path.Combine("..", "..", "..", "pacts"),
            LogDir = Path.Combine("..", "..", "..", "logs")
        };

        _pactBuilder = Pact.V3("OrderService", "ProductService", pactConfig)
            .WithHttpInteractions();
    }

    [Fact]
    public async Task GetProduct_ExistingProduct_ReturnsProduct()
    {
        // Arrange - Define the expected interaction
        _pactBuilder
            .UponReceiving("A GET request for product 1")
                .Given("Product 1 exists")
                .WithRequest(HttpMethod.Get, "/api/products/1")
                .WithHeader("Accept", "application/json")
            .WillRespond()
                .WithStatus(200)
                .WithHeader("Content-Type", "application/json")
                .WithJsonBody(new
                {
                    id = 1,
                    name = Match.Type("Product Name"),
                    price = Match.Decimal(29.99m),
                    inStock = Match.Boolean(true)
                });

        // Act - Execute test against mock
        await _pactBuilder.VerifyAsync(async ctx =>
        {
            var client = new HttpClient { BaseAddress = ctx.MockServerUri };
            var productService = new ProductApiClient(client);

            var product = await productService.GetProductAsync(1);

            // Assert - Verify consumer can handle the response
            Assert.NotNull(product);
            Assert.Equal(1, product.Id);
            Assert.NotNull(product.Name);
        });
    }

    [Fact]
    public async Task GetProduct_NonExistentProduct_Returns404()
    {
        // Arrange
        _pactBuilder
            .UponReceiving("A GET request for non-existent product")
                .Given("Product 999 does not exist")
                .WithRequest(HttpMethod.Get, "/api/products/999")
            .WillRespond()
                .WithStatus(404)
                .WithHeader("Content-Type", "application/json")
                .WithJsonBody(new
                {
                    error = Match.Type("Product not found"),
                    productId = 999
                });

        // Act & Assert
        await _pactBuilder.VerifyAsync(async ctx =>
        {
            var client = new HttpClient { BaseAddress = ctx.MockServerUri };
            var productService = new ProductApiClient(client);

            var exception = await Assert.ThrowsAsync<ProductNotFoundException>(
                () => productService.GetProductAsync(999));

            Assert.Equal(999, exception.ProductId);
        });
    }

    [Fact]
    public async Task CreateProduct_ValidProduct_ReturnsCreatedProduct()
    {
        // Arrange
        var newProduct = new CreateProductRequest
        {
            Name = "New Product",
            Price = 49.99m
        };

        _pactBuilder
            .UponReceiving("A POST request to create product")
                .Given("User is authenticated")
                .WithRequest(HttpMethod.Post, "/api/products")
                .WithHeader("Content-Type", "application/json")
                .WithJsonBody(newProduct)
            .WillRespond()
                .WithStatus(201)
                .WithHeader("Content-Type", "application/json")
                .WithHeader("Location", Match.Regex("/api/products/\\d+", "/api/products/123"))
                .WithJsonBody(new
                {
                    id = Match.Integer(123),
                    name = "New Product",
                    price = 49.99m
                });

        // Act & Assert
        await _pactBuilder.VerifyAsync(async ctx =>
        {
            var client = new HttpClient { BaseAddress = ctx.MockServerUri };
            var productService = new ProductApiClient(client);

            var created = await productService.CreateProductAsync(newProduct);

            Assert.NotNull(created);
            Assert.True(created.Id > 0);
            Assert.Equal("New Product", created.Name);
        });
    }

    public void Dispose()
    {
        // Pact file is generated here
        _pactBuilder.Dispose();
    }
}

// ============================================
// Provider Side (Product Service)
// ============================================

// Provider verifies it can fulfill the contract
public class ProductServiceProviderTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ProductServiceProviderTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public void EnsureProviderHonorsContract()
    {
        // Arrange
        var config = new PactVerifierConfig
        {
            Outputters = new List<IOutput>
            {
                new XUnitOutput(/* ITestOutputHelper */)
            }
        };

        var pactPath = Path.Combine("..", "..", "..", "pacts", "OrderService-ProductService.json");

        // Act & Assert
        new PactVerifier(config)
            .ServiceProvider("ProductService", _factory.Server.BaseAddress)
            .WithFileSource(new FileInfo(pactPath))
            .WithProviderStateUrl(new Uri(_factory.Server.BaseAddress, "/provider-states"))
            .Verify();
    }
}

// ============================================
// Provider States Endpoint
// ============================================

[ApiController]
[Route("provider-states")]
public class ProviderStatesController : ControllerBase
{
    private readonly IServiceProvider _serviceProvider;

    public ProviderStatesController(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    [HttpPost]
    public async Task<IActionResult> SetupState([FromBody] ProviderState state)
    {
        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        switch (state.State)
        {
            case "Product 1 exists":
                dbContext.Products.Add(new Product
                {
                    Id = 1,
                    Name = "Test Product",
                    Price = 29.99m,
                    InStock = true
                });
                await dbContext.SaveChangesAsync();
                break;

            case "Product 999 does not exist":
                // Ensure product doesn't exist
                var product = await dbContext.Products.FindAsync(999);
                if (product != null)
                {
                    dbContext.Products.Remove(product);
                    await dbContext.SaveChangesAsync();
                }
                break;

            case "User is authenticated":
                // Setup authentication state
                break;
        }

        return Ok();
    }
}

// ============================================
// Alternative: JSON Schema Contract Testing
// ============================================

public class JsonSchemaContractTests
{
    [Fact]
    public async Task GetProduct_ResponseMatchesSchema()
    {
        // Arrange
        var schema = @"{
            'type': 'object',
            'properties': {
                'id': { 'type': 'integer' },
                'name': { 'type': 'string' },
                'price': { 'type': 'number' },
                'inStock': { 'type': 'boolean' }
            },
            'required': ['id', 'name', 'price']
        }";

        var client = new HttpClient();

        // Act
        var response = await client.GetAsync("https://api.example.com/products/1");
        var content = await response.Content.ReadAsStringAsync();

        // Assert - Validate against schema
        var schemaObject = JSchema.Parse(schema);
        var json = JObject.Parse(content);

        json.IsValid(schemaObject).Should().BeTrue();
    }
}

// ============================================
// Consumer-Driven Contract Testing Workflow
// ============================================

/*
1. Consumer writes tests defining expectations
   - What requests will be made
   - What responses are expected
   - Generates contract (pact file)

2. Contract published to broker (optional)
   - Central storage for contracts
   - Version management

3. Provider verifies contract
   - Runs tests against actual implementation
   - Ensures it can fulfill consumer needs

4. CI/CD Integration
   - Consumer tests run on consumer changes
   - Provider tests run on provider changes
   - Can-I-Deploy check before deployment

BENEFITS:
✅ Catch breaking changes early
✅ Independent service deployment
✅ Documentation of API contracts
✅ Prevents integration issues
✅ Enables parallel development

WHEN TO USE:
✅ Microservices architecture
✅ Multiple teams/services
✅ Frequent API changes
✅ Independent deployments
✅ Need for confidence in integration
*/

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Test business-critical interactions
   - Focus on important flows
   - Not every endpoint needs a contract

2. ✅ Keep contracts minimal
   - Only test what consumer needs
   - Avoid over-specification

3. ✅ Use provider states
   - Setup test data
   - Configure scenarios

4. ✅ Version contracts
   - Track changes
   - Support multiple versions

5. ✅ Integrate with CI/CD
   - Run on every commit
   - Block incompatible changes

6. ✅ Use a Pact Broker
   - Centralized storage
   - Better workflow

7. ❌ Don't duplicate functional tests
   - Focus on contract, not business logic
   - Keep tests fast

8. ✅ Test error scenarios
   - 404, 500, validation errors
   - Consumer handles errors correctly

9. ✅ Use matchers wisely
   - Match.Type() for flexibility
   - Exact values when important

10. ✅ Consumer and provider collaborate
    - Discuss contracts
    - Shared understanding
*/
```

---

## **Q279: What is Property-Based Testing?**

**Answer:**

Property-based testing generates random test cases to verify that properties of code hold true for a wide range of inputs.

**Implementation with FsCheck:**
```csharp
using FsCheck;
using FsCheck.Xunit;
using Xunit;

// ============================================
// Installation
// ============================================

// dotnet add package FsCheck.Xunit

// ============================================
// Basic Property-Based Tests
// ============================================

public class PropertyBasedTests
{
    [Property]
    public bool Reverse_Twice_ReturnsOriginal(int[] array)
    {
        // Property: Reversing an array twice returns the original
        var reversed = array.Reverse().ToArray();
        var reversedTwice = reversed.Reverse().ToArray();

        return array.SequenceEqual(reversedTwice);
    }

    [Property]
    public bool Addition_IsCommutative(int a, int b)
    {
        // Property: a + b == b + a
        return a + b == b + a;
    }

    [Property]
    public bool StringLength_AfterToLower_RemainsTheSame(string str)
    {
        // Skip null strings
        if (str == null) return true;

        // Property: ToLower doesn't change length
        return str.Length == str.ToLower().Length;
    }

    [Property]
    public Property List_Filter_Count_LessThanOrEqual_OriginalCount(int[] list)
    {
        // Property: Filtering always returns <= original count
        return Prop.ForAll<Func<int, bool>>(
            predicate =>
            {
                var filtered = list.Where(predicate).ToArray();
                return filtered.Length <= list.Length;
            });
    }
}

// ============================================
// Testing Business Logic
// ============================================

public class ShoppingCartProperties
{
    [Property]
    public bool AddItem_IncreasesTotal(decimal price, int quantity)
    {
        // Only test positive values
        if (price <= 0 || quantity <= 0) return true;

        var cart = new ShoppingCart();
        var initialTotal = cart.Total;

        cart.AddItem(new CartItem { Price = price, Quantity = quantity });

        return cart.Total > initialTotal;
    }

    [Property]
    public bool RemoveItem_DecreasesTotal(decimal price, int quantity)
    {
        if (price <= 0 || quantity <= 0) return true;

        var cart = new ShoppingCart();
        var item = new CartItem { Price = price, Quantity = quantity };

        cart.AddItem(item);
        var totalAfterAdd = cart.Total;

        cart.RemoveItem(item);
        var totalAfterRemove = cart.Total;

        return totalAfterRemove < totalAfterAdd;
    }

    [Property]
    public Property Cart_TotalPrice_SumOfItems(List<decimal> prices)
    {
        return (prices != null && prices.All(p => p >= 0))
            .ToProperty()
            .And(() =>
            {
                var cart = new ShoppingCart();

                foreach (var price in prices)
                {
                    cart.AddItem(new CartItem { Price = price, Quantity = 1 });
                }

                var expected = prices.Sum();
                return Math.Abs(cart.Total - expected) < 0.01m;
            });
    }
}

// ============================================
// Custom Generators
// ============================================

public class CustomGenerators
{
    // Generate valid email addresses
    public static Arbitrary<string> EmailAddresses()
    {
        return Arb.From(
            Gen.Elements("user", "admin", "test")
                .SelectMany(name =>
                    Gen.Elements("example.com", "test.com", "mail.com")
                        .Select(domain => $"{name}@{domain}")));
    }

    // Generate positive integers
    public static Arbitrary<int> PositiveInts()
    {
        return Arb.From(Gen.Choose(1, int.MaxValue));
    }

    // Generate valid products
    public static Arbitrary<Product> ValidProducts()
    {
        return Arb.From(
            from name in Arb.Generate<string>().Where(s => !string.IsNullOrEmpty(s))
            from price in Gen.Choose(1, 10000).Select(p => p / 100m)
            from stock in Gen.Choose(0, 1000)
            select new Product
            {
                Name = name,
                Price = price,
                Stock = stock
            });
    }
}

// ============================================
// Using Custom Generators
// ============================================

public class CustomGeneratorTests
{
    [Property(Arbitrary = new[] { typeof(CustomGenerators) })]
    public bool EmailValidator_ValidEmail_ReturnsTrue(string email)
    {
        var validator = new EmailValidator();
        return validator.IsValid(email);
    }

    [Property(Arbitrary = new[] { typeof(CustomGenerators) })]
    public bool CreateProduct_ValidProduct_Succeeds(Product product)
    {
        var service = new ProductService();

        try
        {
            service.CreateProduct(product);
            return true;
        }
        catch
        {
            return false; // Should not throw for valid products
        }
    }
}

// ============================================
// Shrinking - Finding Minimal Failing Case
// ============================================

public class ShrinkingExample
{
    [Property]
    public bool BuggyFunction_Property(int[] numbers)
    {
        // This function has a bug with empty arrays
        if (numbers.Length == 0)
            throw new ArgumentException("Array cannot be empty");

        return numbers.Sum() >= numbers.Min();
    }
    // FsCheck will shrink the failing case to the smallest example
    // Instead of a large random array, it finds: []
}

// ============================================
// Stateful Property Testing
// ============================================

public class BankAccountModel
{
    private decimal _balance = 0;

    public class Deposit
    {
        public decimal Amount { get; set; }
        public override string ToString() => $"Deposit({Amount})";
    }

    public class Withdraw
    {
        public decimal Amount { get; set; }
        public override string ToString() => $"Withdraw({Amount})";
    }

    public class DepositSpec : ICommandGenerator<BankAccountModel, BankAccount>
    {
        public Gen<Command<BankAccountModel, BankAccount>> Generator =>
            from amount in Gen.Choose(1, 1000).Select(a => a / 100m)
            select (Command<BankAccountModel, BankAccount>)new DepositCommand(amount);

        private class DepositCommand : Command<BankAccountModel, BankAccount>
        {
            private readonly decimal _amount;

            public DepositCommand(decimal amount)
            {
                _amount = amount;
            }

            public override BankAccount RunActual(BankAccount sut)
            {
                sut.Deposit(_amount);
                return sut;
            }

            public override BankAccountModel RunModel(BankAccountModel model)
            {
                model._balance += _amount;
                return model;
            }

            public override Property Post(BankAccountModel model, BankAccount sut)
            {
                return (Math.Abs(sut.Balance - model._balance) < 0.01m).ToProperty()
                    .Label($"Balance should be {model._balance}, but was {sut.Balance}");
            }

            public override string ToString() => $"Deposit({_amount})";
        }
    }
}

// ============================================
// Comparing with Example-Based Testing
// ============================================

public class ComparisonTests
{
    // ❌ Example-Based: Limited coverage
    [Theory]
    [InlineData(1, 2, 3)]
    [InlineData(5, 3, 8)]
    [InlineData(-1, 1, 0)]
    public void Add_ExampleBased(int a, int b, int expected)
    {
        var result = Calculator.Add(a, b);
        result.Should().Be(expected);
    }

    // ✅ Property-Based: Comprehensive coverage
    [Property]
    public bool Add_PropertyBased(int a, int b)
    {
        var result = Calculator.Add(a, b);

        // Properties that should always hold
        return result == a + b &&
               result - a == b &&
               result - b == a;
    }
}

// ============================================
// When to Use Property-Based Testing
// ============================================

/*
✅ GOOD use cases:
1. Algorithms and data structures
   - Sorting, searching
   - Collections operations

2. Mathematical properties
   - Commutative, associative
   - Inverse operations

3. Serialization/Deserialization
   - Round-trip properties
   - Format preservation

4. Parsers and validators
   - Valid input handling
   - Error cases

5. Business rules
   - Invariants
   - Constraints

❌ When to avoid:
1. UI testing
   - Not deterministic enough
   - Hard to define properties

2. External dependencies
   - Databases, APIs
   - Non-deterministic

3. Time-dependent operations
   - Current date/time
   - Random behavior

4. Complex workflows
   - Hard to express as properties
   - Better suited for example-based tests
*/

// ============================================
// Best Practices
// ============================================

/*
1. ✅ Start with simple properties
   - Build understanding
   - Add complexity gradually

2. ✅ Combine with example-based tests
   - Use both approaches
   - Complementary, not replacement

3. ✅ Think in terms of invariants
   - What should always be true?
   - Mathematical properties

4. ✅ Use custom generators
   - Generate valid domain objects
   - Constrain inputs appropriately

5. ✅ Leverage shrinking
   - Find minimal failing cases
   - Easier debugging

6. ✅ Test inverse operations
   - Serialize/Deserialize
   - Encrypt/Decrypt
   - Add/Remove

7. ✅ Configure test counts
   - More iterations for critical code
   - Balance time vs coverage

8. ❌ Don't test framework code
   - Focus on your logic
   - Framework is already tested

9. ✅ Use properties for edge cases
   - Find bugs you didn't think of
   - Unexpected inputs

10. ✅ Document discovered properties
    - Codify business rules
    - Living documentation
*/
```

---

## **Q280: Summary - Testing in .NET Ecosystem**

**Answer:**

A comprehensive overview of testing practices covered in Q261-Q280.

**Testing Pyramid:**
```
     /\
    /E2E\         - Few, slow, expensive
   /------\       - Test complete user journeys
  /Integration\   - Moderate number
 /------------\   - Test component interactions
/  Unit Tests  \  - Many, fast, cheap
----------------  - Test individual components
```

**Key Testing Types Covered:**

**1. Unit Testing (Q261-Q264)**
- Test individual components in isolation
- Fast, reliable, easy to maintain
- Frameworks: xUnit, NUnit, MSTest
- Mocking: Moq, NSubstitute
- Assertions: FluentAssertions
- TDD: Red-Green-Refactor cycle

**2. Integration Testing (Q268-Q269)**
- Test component interactions
- Database testing (EF Core InMemory, SQLite)
- API testing (WebApplicationFactory)
- TestContainers for real databases

**3. End-to-End Testing (Q269)**
- Test complete user workflows
- Browser automation (Selenium, Playwright)
- API testing with full stack

**4. Specialized Testing:**
- **Performance Testing (Q273)**: BenchmarkDotNet
- **HTTP Client Testing (Q274)**: Mock HttpMessageHandler, WireMock
- **Middleware Testing (Q270)**: DefaultHttpContext
- **Background Services (Q276)**: CancellationToken, testable design
- **Exception Testing (Q272)**: FluentAssertions exception assertions
- **Contract Testing (Q278)**: Pact for microservices
- **Property-Based Testing (Q279)**: FsCheck
- **Snapshot Testing (Q277)**: Snapshooter

**5. Best Practices (Q275)**
- AAA Pattern (Arrange, Act, Assert)
- Test behavior, not implementation
- Independent, isolated tests
- Descriptive test names
- Avoid logic in tests
- Mock only external dependencies

**Testing Patterns:**
```csharp
// Test Data Builder (Q271)
var user = new UserBuilder()
    .WithName("John")
    .WithAge(30)
    .Build();

// Object Mother
var user = TestUsers.ValidUser();

// FluentAssertions (Q267)
result.Should().NotBeNull();
result.Should().BeEquivalentTo(expected);

// Exception Testing (Q272)
await act.Should().ThrowAsync<InvalidOperationException>()
    .WithMessage("*error*");
```

**Testing Anti-Patterns to Avoid:**
```csharp
// ❌ Multiple acts/asserts
// ❌ Logic in tests
// ❌ Test interdependence
// ❌ Testing implementation details
// ❌ Ignoring async/await
// ❌ Excessive mocking
// ❌ Testing private methods
// ❌ Shared state between tests
```

**Testing Tools Ecosystem:**

| Category | Tools |
|----------|-------|
| Unit Testing | xUnit, NUnit, MSTest |
| Mocking | Moq, NSubstitute, FakeItEasy |
| Assertions | FluentAssertions, Shouldly |
| Coverage | Coverlet, ReportGenerator |
| Performance | BenchmarkDotNet |
| Integration | WebApplicationFactory, TestServer |
| Containers | TestContainers |
| HTTP Mocking | WireMock.Net |
| Contract | Pact.Net |
| Property-Based | FsCheck |
| Snapshot | Snapshooter, ApprovalTests |

**Testing in CI/CD:**
```bash
# Run tests
dotnet test

# With coverage
dotnet test --collect:"XPlat Code Coverage"

# Generate report
reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coverage"

# Fail if coverage below threshold
dotnet test /p:CollectCoverage=true /p:Threshold=80
```

**Key Takeaways:**
1. ✅ Write tests at appropriate levels
2. ✅ Focus on behavior, not implementation
3. ✅ Keep tests fast and reliable
4. ✅ Use right tool for the job
5. ✅ Automate testing in CI/CD
6. ✅ Maintain tests like production code
7. ✅ Balance coverage with quality
8. ✅ Test edge cases and errors
9. ✅ Use TDD when appropriate
10. ✅ Continuous improvement

**Testing Mindset:**
- Tests are living documentation
- Good tests enable refactoring
- Test code quality matters
- Fast feedback is crucial
- Coverage ≠ Quality
- Test what can break
- Simplicity over cleverness

---

**END OF Q261-Q280: Testing Questions Complete** ✅

---
