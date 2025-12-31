# Interview Questions 461-480: Advanced Testing & Technical Leadership

## Q461: How do you implement Test-Driven Development (TDD) in practice? Explain the Red-Green-Refactor cycle with a real-world example.

### Complete TDD Implementation

#### **The Red-Green-Refactor Cycle**

```
┌─────────────────────────────────────────────────┐
│          RED: Write a Failing Test              │
│  - Write test before implementation             │
│  - Test should fail (no code exists yet)        │
│  - Verify test can fail properly                │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│         GREEN: Make the Test Pass               │
│  - Write minimal code to pass the test          │
│  - Don't worry about perfection                 │
│  - Focus on making it work                      │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│          REFACTOR: Improve the Code             │
│  - Eliminate duplication                        │
│  - Improve design                               │
│  - Ensure tests still pass                      │
└────────────┬────────────────────────────────────┘
             │
             └──────► Repeat for next feature
```

#### **Real-World Example: Order Processing System**

**RED: Write the First Test**

```csharp
public class OrderServiceTests
{
    [Fact]
    public void CreateOrder_WithValidItems_ShouldCalculateTotalCorrectly()
    {
        // Arrange
        var service = new OrderService();
        var items = new List<OrderItem>
        {
            new OrderItem { ProductId = 1, Quantity = 2, UnitPrice = 10.00m },
            new OrderItem { ProductId = 2, Quantity = 1, UnitPrice = 25.00m }
        };

        // Act
        var order = service.CreateOrder("CUST123", items);

        // Assert
        Assert.Equal(45.00m, order.TotalAmount); // 2*10 + 1*25 = 45
    }
}

// This test FAILS - OrderService doesn't exist yet
// Compilation error: The type or namespace name 'OrderService' could not be found
```

**GREEN: Write Minimal Code to Pass**

```csharp
public class OrderService
{
    public Order CreateOrder(string customerId, List<OrderItem> items)
    {
        var total = 0m;
        foreach (var item in items)
        {
            total += item.Quantity * item.UnitPrice;
        }

        return new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Items = items,
            TotalAmount = total,
            Status = OrderStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
    }
}

public class Order
{
    public Guid Id { get; set; }
    public string CustomerId { get; set; }
    public List<OrderItem> Items { get; set; }
    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class OrderItem
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled
}

// Test now PASSES ✅
```

**REFACTOR: Improve the Design**

```csharp
// Add more tests first
[Fact]
public void CreateOrder_WithEmptyItems_ShouldThrowException()
{
    var service = new OrderService();
    var items = new List<OrderItem>();

    var exception = Assert.Throws<ArgumentException>(() =>
        service.CreateOrder("CUST123", items)
    );

    Assert.Equal("Order must have at least one item", exception.Message);
}

[Fact]
public void CreateOrder_WithNegativeQuantity_ShouldThrowException()
{
    var service = new OrderService();
    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = -1, UnitPrice = 10.00m }
    };

    Assert.Throws<ArgumentException>(() =>
        service.CreateOrder("CUST123", items)
    );
}

[Theory]
[InlineData(0)]
[InlineData(-10.00)]
public void CreateOrder_WithInvalidPrice_ShouldThrowException(decimal price)
{
    var service = new OrderService();
    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 1, UnitPrice = price }
    };

    Assert.Throws<ArgumentException>(() =>
        service.CreateOrder("CUST123", items)
    );
}

// Refactored implementation with validation
public class OrderService
{
    public Order CreateOrder(string customerId, List<OrderItem> items)
    {
        ValidateOrder(customerId, items);

        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Items = items,
            Status = OrderStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        order.CalculateTotal();

        return order;
    }

    private void ValidateOrder(string customerId, List<OrderItem> items)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new ArgumentException("Customer ID is required", nameof(customerId));

        if (items == null || !items.Any())
            throw new ArgumentException("Order must have at least one item", nameof(items));

        foreach (var item in items)
        {
            if (item.Quantity <= 0)
                throw new ArgumentException($"Quantity must be positive for product {item.ProductId}");

            if (item.UnitPrice <= 0)
                throw new ArgumentException($"Unit price must be positive for product {item.ProductId}");
        }
    }
}

// Refactored Order with encapsulation
public class Order
{
    public Guid Id { get; private set; }
    public string CustomerId { get; private set; }
    public List<OrderItem> Items { get; private set; } = new();
    public decimal TotalAmount { get; private set; }
    public OrderStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    internal void CalculateTotal()
    {
        TotalAmount = Items.Sum(item => item.Quantity * item.UnitPrice);
    }
}

// All tests still PASS ✅
```

#### **Advanced TDD: Testing Complex Business Logic**

**Scenario: Apply Discounts to Order**

```csharp
// RED: Test for percentage discount
[Fact]
public void ApplyDiscount_WithPercentageDiscount_ShouldReduceTotal()
{
    // Arrange
    var service = new OrderService();
    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 1, UnitPrice = 100.00m }
    };
    var order = service.CreateOrder("CUST123", items);

    // Act
    order.ApplyDiscount(new PercentageDiscount(10)); // 10% off

    // Assert
    Assert.Equal(90.00m, order.TotalAmount);
    Assert.Equal(10.00m, order.DiscountAmount);
}

// RED: Test for fixed amount discount
[Fact]
public void ApplyDiscount_WithFixedDiscount_ShouldReduceTotal()
{
    var service = new OrderService();
    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 1, UnitPrice = 100.00m }
    };
    var order = service.CreateOrder("CUST123", items);

    order.ApplyDiscount(new FixedAmountDiscount(15.00m));

    Assert.Equal(85.00m, order.TotalAmount);
    Assert.Equal(15.00m, order.DiscountAmount);
}

// RED: Test for buy-one-get-one discount
[Fact]
public void ApplyDiscount_WithBOGODiscount_ShouldApplyCorrectly()
{
    var service = new OrderService();
    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 3, UnitPrice = 20.00m }
    };
    var order = service.CreateOrder("CUST123", items);

    order.ApplyDiscount(new BuyOneGetOneDiscount(productId: 1));

    // Buy 3, get 1 free = pay for 2
    Assert.Equal(40.00m, order.TotalAmount);
    Assert.Equal(20.00m, order.DiscountAmount);
}

// GREEN: Implement using Strategy Pattern
public interface IDiscountStrategy
{
    decimal Calculate(Order order);
}

public class PercentageDiscount : IDiscountStrategy
{
    private readonly decimal _percentage;

    public PercentageDiscount(decimal percentage)
    {
        if (percentage < 0 || percentage > 100)
            throw new ArgumentException("Percentage must be between 0 and 100");

        _percentage = percentage;
    }

    public decimal Calculate(Order order)
    {
        var subtotal = order.Items.Sum(i => i.Quantity * i.UnitPrice);
        return subtotal * (_percentage / 100);
    }
}

public class FixedAmountDiscount : IDiscountStrategy
{
    private readonly decimal _amount;

    public FixedAmountDiscount(decimal amount)
    {
        if (amount < 0)
            throw new ArgumentException("Discount amount cannot be negative");

        _amount = amount;
    }

    public decimal Calculate(Order order)
    {
        var subtotal = order.Items.Sum(i => i.Quantity * i.UnitPrice);
        return Math.Min(_amount, subtotal); // Don't discount more than total
    }
}

public class BuyOneGetOneDiscount : IDiscountStrategy
{
    private readonly int _productId;

    public BuyOneGetOneDiscount(int productId)
    {
        _productId = productId;
    }

    public decimal Calculate(Order order)
    {
        var item = order.Items.FirstOrDefault(i => i.ProductId == _productId);
        if (item == null)
            return 0;

        var freeItems = item.Quantity / 2; // Every 2 items, 1 is free
        return freeItems * item.UnitPrice;
    }
}

// Enhanced Order class
public class Order
{
    public Guid Id { get; private set; }
    public string CustomerId { get; private set; }
    public List<OrderItem> Items { get; private set; } = new();
    public decimal Subtotal { get; private set; }
    public decimal DiscountAmount { get; private set; }
    public decimal TotalAmount { get; private set; }
    public OrderStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    internal void CalculateTotal()
    {
        Subtotal = Items.Sum(item => item.Quantity * item.UnitPrice);
        TotalAmount = Subtotal - DiscountAmount;
    }

    public void ApplyDiscount(IDiscountStrategy discountStrategy)
    {
        DiscountAmount = discountStrategy.Calculate(this);
        CalculateTotal();
    }
}

// All tests PASS ✅
```

#### **TDD with External Dependencies (Mocking)**

```csharp
// RED: Test order creation with inventory check
[Fact]
public async Task CreateOrder_WithSufficientInventory_ShouldSucceed()
{
    // Arrange
    var mockInventory = new Mock<IInventoryService>();
    mockInventory
        .Setup(x => x.CheckAvailabilityAsync(It.IsAny<int>(), It.IsAny<int>()))
        .ReturnsAsync(true);

    var mockRepository = new Mock<IOrderRepository>();
    mockRepository
        .Setup(x => x.AddAsync(It.IsAny<Order>()))
        .ReturnsAsync((Order o) => o);

    var service = new OrderService(mockInventory.Object, mockRepository.Object);

    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 2, UnitPrice = 10.00m }
    };

    // Act
    var order = await service.CreateOrderAsync("CUST123", items);

    // Assert
    Assert.NotNull(order);
    Assert.Equal(OrderStatus.Pending, order.Status);
    mockInventory.Verify(x => x.CheckAvailabilityAsync(1, 2), Times.Once);
    mockRepository.Verify(x => x.AddAsync(It.IsAny<Order>()), Times.Once);
}

// RED: Test order creation with insufficient inventory
[Fact]
public async Task CreateOrder_WithInsufficientInventory_ShouldThrowException()
{
    var mockInventory = new Mock<IInventoryService>();
    mockInventory
        .Setup(x => x.CheckAvailabilityAsync(1, 10))
        .ReturnsAsync(false);

    var service = new OrderService(mockInventory.Object, Mock.Of<IOrderRepository>());

    var items = new List<OrderItem>
    {
        new OrderItem { ProductId = 1, Quantity = 10, UnitPrice = 10.00m }
    };

    var exception = await Assert.ThrowsAsync<InsufficientInventoryException>(() =>
        service.CreateOrderAsync("CUST123", items)
    );

    Assert.Equal("Product 1 has insufficient inventory", exception.Message);
}

// GREEN: Implementation
public class OrderService
{
    private readonly IInventoryService _inventoryService;
    private readonly IOrderRepository _orderRepository;

    public OrderService(IInventoryService inventoryService, IOrderRepository orderRepository)
    {
        _inventoryService = inventoryService;
        _orderRepository = orderRepository;
    }

    public async Task<Order> CreateOrderAsync(string customerId, List<OrderItem> items)
    {
        ValidateOrder(customerId, items);

        // Check inventory for all items
        foreach (var item in items)
        {
            var available = await _inventoryService.CheckAvailabilityAsync(
                item.ProductId,
                item.Quantity
            );

            if (!available)
            {
                throw new InsufficientInventoryException(
                    $"Product {item.ProductId} has insufficient inventory"
                );
            }
        }

        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Items = items,
            Status = OrderStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        order.CalculateTotal();

        await _orderRepository.AddAsync(order);

        return order;
    }

    private void ValidateOrder(string customerId, List<OrderItem> items)
    {
        if (string.IsNullOrWhiteSpace(customerId))
            throw new ArgumentException("Customer ID is required", nameof(customerId));

        if (items == null || !items.Any())
            throw new ArgumentException("Order must have at least one item", nameof(items));

        foreach (var item in items)
        {
            if (item.Quantity <= 0)
                throw new ArgumentException($"Quantity must be positive for product {item.ProductId}");

            if (item.UnitPrice <= 0)
                throw new ArgumentException($"Unit price must be positive for product {item.ProductId}");
        }
    }
}

public interface IInventoryService
{
    Task<bool> CheckAvailabilityAsync(int productId, int quantity);
}

public interface IOrderRepository
{
    Task<Order> AddAsync(Order order);
}

public class InsufficientInventoryException : Exception
{
    public InsufficientInventoryException(string message) : base(message) { }
}
```

#### **TDD Benefits and Best Practices**

**✅ Benefits of TDD**:

1. **Better Design**: Forces you to think about API before implementation
2. **Confidence**: Comprehensive test coverage from the start
3. **Regression Protection**: Tests catch breaking changes immediately
4. **Documentation**: Tests serve as living documentation
5. **Refactoring Safety**: Can refactor confidently with tests as safety net
6. **Faster Debugging**: Failing tests pinpoint exact problem
7. **Less Debugging Time**: Catch bugs during development, not in production

**✅ TDD Best Practices**:

```csharp
// 1. One assertion per test (when possible)
[Fact]
public void Order_WhenCreated_ShouldHavePendingStatus()
{
    var order = CreateTestOrder();
    Assert.Equal(OrderStatus.Pending, order.Status);
}

[Fact]
public void Order_WhenCreated_ShouldHaveCreationTimestamp()
{
    var before = DateTime.UtcNow;
    var order = CreateTestOrder();
    var after = DateTime.UtcNow;

    Assert.InRange(order.CreatedAt, before, after);
}

// 2. Test names should describe behavior
// Good: CreateOrder_WithInvalidQuantity_ShouldThrowException
// Bad: TestOrder1

// 3. Use Test Data Builders for complex objects
public class OrderBuilder
{
    private string _customerId = "CUST123";
    private List<OrderItem> _items = new();

    public OrderBuilder WithCustomer(string customerId)
    {
        _customerId = customerId;
        return this;
    }

    public OrderBuilder WithItem(int productId, int quantity, decimal price)
    {
        _items.Add(new OrderItem
        {
            ProductId = productId,
            Quantity = quantity,
            UnitPrice = price
        });
        return this;
    }

    public Order Build()
    {
        var service = new OrderService(
            Mock.Of<IInventoryService>(),
            Mock.Of<IOrderRepository>()
        );

        return service.CreateOrder(_customerId, _items);
    }
}

// Usage
[Fact]
public void ComplexOrderTest()
{
    var order = new OrderBuilder()
        .WithCustomer("PREMIUM123")
        .WithItem(productId: 1, quantity: 2, price: 10.00m)
        .WithItem(productId: 2, quantity: 1, price: 25.00m)
        .Build();

    Assert.Equal(45.00m, order.TotalAmount);
}

// 4. Keep tests independent
// Bad: Test2 depends on Test1 running first
// Good: Each test sets up its own data

// 5. Use meaningful test data
// Bad: CreateOrder("123", items)
// Good: CreateOrder("PREMIUM_CUSTOMER_001", items)

// 6. Test edge cases
[Theory]
[InlineData(0)]
[InlineData(-1)]
[InlineData(int.MinValue)]
public void CreateOrder_WithInvalidQuantity_ShouldThrowException(int quantity)
{
    // Test boundary conditions
}

// 7. Fast tests (< 100ms each)
// Use mocks instead of real database
// Use in-memory databases for integration tests
```

#### **TDD Metrics**

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| **Test Coverage** | > 80% | Confidence in refactoring |
| **Test Execution Time** | < 1 second for unit tests | Fast feedback loop |
| **Tests per Feature** | 3-10 tests | Comprehensive coverage |
| **Time in Red** | < 5 minutes | Don't write too much code |
| **Failed Tests** | 0 (in main branch) | CI/CD quality gate |

#### **❌ Common TDD Mistakes**

1. **Writing too much code before running test** - Stay disciplined with Red-Green-Refactor
2. **Not running tests frequently enough** - Run tests after every small change
3. **Testing implementation details** - Test behavior, not internal structure
4. **Skipping refactoring step** - Technical debt accumulates
5. **Not testing edge cases** - Bugs hide in boundary conditions
6. **Coupling tests to implementation** - Tests become brittle
7. **Slow tests** - Developers stop running them frequently
8. **Not following AAA pattern** - Tests become hard to understand

---

## Q462: Explain mutation testing and how it improves test quality. How would you implement it in a .NET project?

### Mutation Testing Explained

#### **What is Mutation Testing?**

Mutation testing is a technique that modifies (mutates) your source code in small ways and checks if your tests detect these changes. If tests still pass with mutated code, it means your tests aren't thorough enough.

```
┌─────────────────────────────────────────────────┐
│           Original Code                          │
│  public bool IsAdult(int age)                   │
│  {                                              │
│      return age >= 18;                          │
│  }                                              │
└────────────┬────────────────────────────────────┘
             │
             ▼ Mutation Operator Applied
┌─────────────────────────────────────────────────┐
│           Mutated Code                           │
│  public bool IsAdult(int age)                   │
│  {                                              │
│      return age > 18;  // Changed >= to >      │
│  }                                              │
└────────────┬────────────────────────────────────┘
             │
             ▼ Run Tests
┌─────────────────────────────────────────────────┐
│      Did Tests Detect the Mutation?             │
│                                                 │
│  ✅ KILLED: Tests failed (good!)                │
│     Your tests caught the bug                   │
│                                                 │
│  ❌ SURVIVED: Tests passed (bad!)               │
│     Your tests missed the bug                   │
│     Need better test coverage                   │
└─────────────────────────────────────────────────┘
```

#### **Common Mutation Operators**

```csharp
// 1. ARITHMETIC OPERATOR REPLACEMENT
// Original
int total = price + tax;

// Mutations
int total = price - tax;  // + to -
int total = price * tax;  // + to *
int total = price / tax;  // + to /
int total = price % tax;  // + to %

// 2. RELATIONAL OPERATOR REPLACEMENT
// Original
if (age >= 18)

// Mutations
if (age > 18)   // >= to >
if (age <= 18)  // >= to <=
if (age < 18)   // >= to <
if (age == 18)  // >= to ==
if (age != 18)  // >= to !=

// 3. CONDITIONAL OPERATOR REPLACEMENT
// Original
if (isActive && hasPermission)

// Mutations
if (isActive || hasPermission)  // && to ||
if (isActive)                   // Remove second condition
if (hasPermission)              // Remove first condition

// 4. NEGATION OPERATOR
// Original
if (isValid)

// Mutations
if (!isValid)  // Negate condition

// 5. CONSTANT REPLACEMENT
// Original
return age >= 18;

// Mutations
return age >= 0;   // 18 to 0
return age >= 21;  // 18 to 21
return age >= 17;  // 18 to 17

// 6. RETURN VALUE MUTATION
// Original
return true;

// Mutations
return false;  // Flip boolean

// Original
return items.Count;

// Mutations
return 0;           // Return zero
return items.Count + 1;  // Increment
return items.Count - 1;  // Decrement

// 7. STATEMENT DELETION
// Original
public void ProcessOrder(Order order)
{
    ValidateOrder(order);
    order.Status = OrderStatus.Processing;
    SaveOrder(order);
}

// Mutation
public void ProcessOrder(Order order)
{
    // ValidateOrder(order);  // Statement removed
    order.Status = OrderStatus.Processing;
    SaveOrder(order);
}
```

#### **Implementing Mutation Testing with Stryker.NET**

**1. Installation**

```bash
# Install Stryker.NET globally
dotnet tool install -g dotnet-stryker

# Or install locally in project
dotnet new tool-manifest
dotnet tool install dotnet-stryker
```

**2. Configuration (stryker-config.json)**

```json
{
  "stryker-config": {
    "project": "YourProject.csproj",
    "test-projects": [
      "YourProject.Tests.csproj"
    ],
    "reporters": [
      "html",
      "progress",
      "cleartext"
    ],
    "thresholds": {
      "high": 80,
      "low": 60,
      "break": 60
    },
    "mutate": [
      "**/*.cs",
      "!**/*Tests.cs"
    ],
    "ignore-methods": [
      "*ToString*",
      "*GetHashCode*"
    ],
    "baseline": {
      "enabled": false
    },
    "since": {
      "enabled": false
    }
  }
}
```

**3. Example: Order Service with Mutation Testing**

```csharp
// Original Implementation
public class OrderService
{
    public decimal CalculateDiscount(decimal orderTotal, string customerType)
    {
        if (orderTotal <= 0)
            throw new ArgumentException("Order total must be positive");

        if (customerType == "Premium" && orderTotal >= 100)
            return orderTotal * 0.15m; // 15% discount

        if (customerType == "Regular" && orderTotal >= 50)
            return orderTotal * 0.10m; // 10% discount

        return 0m; // No discount
    }

    public bool IsEligibleForFreeShipping(decimal orderTotal, string country)
    {
        if (country == "US" && orderTotal >= 50)
            return true;

        if (country == "CA" && orderTotal >= 75)
            return true;

        return false;
    }
}

// Initial Tests (Weak Coverage)
public class OrderServiceTests
{
    [Fact]
    public void CalculateDiscount_PremiumCustomer_ReturnsDiscount()
    {
        var service = new OrderService();
        var discount = service.CalculateDiscount(100m, "Premium");

        Assert.Equal(15m, discount);
    }

    [Fact]
    public void IsEligibleForFreeShipping_USCustomer_ReturnsTrue()
    {
        var service = new OrderService();
        var eligible = service.IsEligibleForFreeShipping(50m, "US");

        Assert.True(eligible);
    }
}
```

**4. Run Stryker**

```bash
dotnet stryker
```

**5. Stryker Report Analysis**

```
Stryker Mutation Report

╔════════════════════════════════════════════════════════════╗
║ File: OrderService.cs                                      ║
╠════════════════════════════════════════════════════════════╣
║ Line 8:  if (orderTotal <= 0)                              ║
║ Mutation: <= to <                                          ║
║ Status: SURVIVED ❌                                         ║
║ Reason: No test covers edge case orderTotal = 0           ║
╠════════════════════════════════════════════════════════════╣
║ Line 11: if (customerType == "Premium" && orderTotal >= 100) ║
║ Mutation: >= to >                                          ║
║ Status: SURVIVED ❌                                         ║
║ Reason: No test for orderTotal = 100 boundary             ║
╠════════════════════════════════════════════════════════════╣
║ Line 14: if (customerType == "Regular" && orderTotal >= 50)  ║
║ Mutation: && to ||                                         ║
║ Status: SURVIVED ❌                                         ║
║ Reason: No test verifying both conditions required        ║
╠════════════════════════════════════════════════════════════╣
║ Line 20: if (country == "US" && orderTotal >= 50)         ║
║ Mutation: >= to >                                          ║
║ Status: KILLED ✅                                           ║
║ Killed by: IsEligibleForFreeShipping_USCustomer_ReturnsTrue ║
╚════════════════════════════════════════════════════════════╝

Mutation Score: 25% (1 killed / 4 total)
```

**6. Improved Tests Based on Mutation Report**

```csharp
public class OrderServiceTests
{
    private readonly OrderService _service = new();

    // Existing tests
    [Fact]
    public void CalculateDiscount_PremiumCustomer_ReturnsDiscount()
    {
        var discount = _service.CalculateDiscount(100m, "Premium");
        Assert.Equal(15m, discount);
    }

    // NEW: Covers boundary condition (killed mutation: >= to >)
    [Theory]
    [InlineData(99.99)]
    [InlineData(100.00)]
    [InlineData(100.01)]
    public void CalculateDiscount_PremiumCustomer_BoundaryTests(decimal total)
    {
        var discount = _service.CalculateDiscount(total, "Premium");

        if (total >= 100)
            Assert.Equal(total * 0.15m, discount);
        else
            Assert.Equal(0m, discount);
    }

    // NEW: Covers edge case (killed mutation: <= to <)
    [Fact]
    public void CalculateDiscount_ZeroTotal_ThrowsException()
    {
        Assert.Throws<ArgumentException>(() =>
            _service.CalculateDiscount(0m, "Premium")
        );
    }

    // NEW: Covers negative total
    [Fact]
    public void CalculateDiscount_NegativeTotal_ThrowsException()
    {
        Assert.Throws<ArgumentException>(() =>
            _service.CalculateDiscount(-10m, "Premium")
        );
    }

    // NEW: Verifies both conditions required (killed mutation: && to ||)
    [Fact]
    public void CalculateDiscount_RegularCustomerBelowThreshold_NoDiscount()
    {
        var discount = _service.CalculateDiscount(49.99m, "Regular");
        Assert.Equal(0m, discount);
    }

    [Fact]
    public void CalculateDiscount_WrongCustomerTypeAboveThreshold_NoDiscount()
    {
        var discount = _service.CalculateDiscount(100m, "Guest");
        Assert.Equal(0m, discount);
    }

    // NEW: Comprehensive shipping tests
    [Theory]
    [InlineData("US", 49.99, false)]
    [InlineData("US", 50.00, true)]
    [InlineData("US", 75.00, true)]
    [InlineData("CA", 74.99, false)]
    [InlineData("CA", 75.00, true)]
    [InlineData("MX", 100.00, false)]
    public void IsEligibleForFreeShipping_VariousScenarios(
        string country,
        decimal total,
        bool expected)
    {
        var result = _service.IsEligibleForFreeShipping(total, country);
        Assert.Equal(expected, result);
    }
}
```

**7. After Improvements - New Stryker Report**

```
Stryker Mutation Report

╔════════════════════════════════════════════════════════════╗
║ Mutation Score: 95% (19 killed / 20 total)                ║
╠════════════════════════════════════════════════════════════╣
║ Killed Mutations: 19 ✅                                     ║
║ Survived Mutations: 1 ❌                                    ║
║ Timeout Mutations: 0 ⏱                                     ║
╠════════════════════════════════════════════════════════════╣
║ Test Strength: HIGH                                        ║
║ Code Coverage: 100%                                        ║
║ Quality Gate: PASSED ✅                                     ║
╚════════════════════════════════════════════════════════════╝
```

#### **CI/CD Integration**

```yaml
# Azure DevOps Pipeline
- task: DotNetCoreCLI@2
  displayName: 'Run Unit Tests'
  inputs:
    command: 'test'
    projects: '**/*Tests.csproj'

- task: DotNetCoreCLI@2
  displayName: 'Install Stryker'
  inputs:
    command: 'custom'
    custom: 'tool'
    arguments: 'install --global dotnet-stryker'

- script: |
    dotnet stryker --threshold-high 80 --threshold-low 60 --threshold-break 60
  displayName: 'Run Mutation Testing'
  continueOnError: false

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: 'Cobertura'
    summaryFileLocation: '**/mutation-report.html'
```

#### **Mutation Testing Metrics**

| Metric | Formula | Good Target |
|--------|---------|-------------|
| **Mutation Score** | (Killed Mutations / Total Mutations) × 100% | > 75% |
| **Test Strength** | Mutation Score | High (>80%) |
| **Code Coverage** | (Covered Lines / Total Lines) × 100% | > 80% |
| **Test Effectiveness** | Mutation Score / Code Coverage | > 0.9 |

#### **Real-World Example: Payment Processing**

```csharp
// Implementation
public class PaymentProcessor
{
    public PaymentResult ProcessPayment(decimal amount, string cardNumber)
    {
        if (amount <= 0)
            return new PaymentResult { Success = false, Error = "Invalid amount" };

        if (string.IsNullOrWhiteSpace(cardNumber) || cardNumber.Length != 16)
            return new PaymentResult { Success = false, Error = "Invalid card" };

        // Luhn algorithm check
        if (!IsValidCardNumber(cardNumber))
            return new PaymentResult { Success = false, Error = "Invalid card number" };

        if (amount > 10000)
            return new PaymentResult { Success = false, Error = "Amount exceeds limit" };

        return new PaymentResult { Success = true, TransactionId = Guid.NewGuid() };
    }

    private bool IsValidCardNumber(string cardNumber)
    {
        int sum = 0;
        bool alternate = false;

        for (int i = cardNumber.Length - 1; i >= 0; i--)
        {
            int digit = cardNumber[i] - '0';

            if (alternate)
            {
                digit *= 2;
                if (digit > 9)
                    digit -= 9;
            }

            sum += digit;
            alternate = !alternate;
        }

        return (sum % 10) == 0;
    }
}

// Comprehensive tests guided by mutation testing
public class PaymentProcessorTests
{
    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(-100)]
    public void ProcessPayment_InvalidAmount_ReturnsFailed(decimal amount)
    {
        var processor = new PaymentProcessor();
        var result = processor.ProcessPayment(amount, "4532015112830366");

        Assert.False(result.Success);
        Assert.Contains("Invalid amount", result.Error);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("123")]
    [InlineData("12345678901234567")]
    public void ProcessPayment_InvalidCardFormat_ReturnsFailed(string cardNumber)
    {
        var processor = new PaymentProcessor();
        var result = processor.ProcessPayment(100m, cardNumber);

        Assert.False(result.Success);
        Assert.Contains("Invalid card", result.Error);
    }

    [Fact]
    public void ProcessPayment_InvalidLuhnCheck_ReturnsFailed()
    {
        var processor = new PaymentProcessor();
        var result = processor.ProcessPayment(100m, "4532015112830367"); // Invalid

        Assert.False(result.Success);
        Assert.Contains("Invalid card number", result.Error);
    }

    [Theory]
    [InlineData(10000)]
    [InlineData(10000.01)]
    [InlineData(99999)]
    public void ProcessPayment_AmountExceedsLimit_ReturnsFailed(decimal amount)
    {
        var processor = new PaymentProcessor();
        var result = processor.ProcessPayment(amount, "4532015112830366");

        Assert.False(result.Success);
        Assert.Contains("exceeds limit", result.Error);
    }

    [Theory]
    [InlineData("4532015112830366")] // Visa
    [InlineData("5425233430109903")] // Mastercard
    public void ProcessPayment_ValidCard_ReturnsSuccess(string cardNumber)
    {
        var processor = new PaymentProcessor();
        var result = processor.ProcessPayment(100m, cardNumber);

        Assert.True(result.Success);
        Assert.NotEqual(Guid.Empty, result.TransactionId);
    }
}

// Mutation Score: 98% ✅
```

#### **✅ Mutation Testing Benefits**

1. **Finds Weak Tests**: Identifies tests that don't actually verify behavior
2. **Improves Test Quality**: Forces you to write meaningful assertions
3. **Catches Edge Cases**: Reveals missing boundary condition tests
4. **Validates Coverage**: 100% code coverage doesn't mean good tests
5. **Regression Protection**: Better tests catch future bugs
6. **Documentation**: Shows what tests actually verify

#### **❌ Challenges and Limitations**

1. **Slow Execution**: Can take minutes to hours for large codebases
2. **False Positives**: Some mutations may be equivalent to original code
3. **Configuration Overhead**: Needs tuning for each project
4. **CI/CD Integration**: Adds time to build pipeline
5. **Learning Curve**: Team needs to understand mutation concepts

**Solutions**:
- Run mutation tests nightly, not on every commit
- Use incremental mutation testing (only changed files)
- Configure timeout limits
- Use baseline to compare against previous runs
- Focus on critical code paths first

---

## Q463: How do you implement performance testing? Explain load testing, stress testing, and soak testing with tools and metrics.

### Performance Testing Comprehensive Guide

#### **Types of Performance Testing**

```
┌──────────────────────────────────────────────────────────┐
│              PERFORMANCE TESTING TYPES                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. LOAD TESTING                                         │
│     ┌────────────────────────────────┐                  │
│     │ Normal to Peak Load            │                  │
│     │ Expected Users: 1000-5000      │                  │
│     │ Duration: 30-60 minutes        │                  │
│     │ Goal: Verify performance       │                  │
│     │       under expected load      │                  │
│     └────────────────────────────────┘                  │
│                                                          │
│  2. STRESS TESTING                                       │
│     ┌────────────────────────────────┐                  │
│     │ Beyond Peak Load               │                  │
│     │ Expected Users: 10,000+        │                  │
│     │ Duration: Until failure        │                  │
│     │ Goal: Find breaking point      │                  │
│     └────────────────────────────────┘                  │
│                                                          │
│  3. SOAK TESTING                                         │
│     ┌────────────────────────────────┐                  │
│     │ Sustained Normal Load          │                  │
│     │ Expected Users: 1000           │                  │
│     │ Duration: 8-24 hours           │                  │
│     │ Goal: Find memory leaks        │                  │
│     └────────────────────────────────┘                  │
│                                                          │
│  4. SPIKE TESTING                                        │
│     ┌────────────────────────────────┐                  │
│     │ Sudden Load Increase           │                  │
│     │ 100 → 10,000 users in 1 min    │                  │
│     │ Duration: Short bursts         │                  │
│     │ Goal: Test auto-scaling        │                  │
│     └────────────────────────────────┘                  │
│                                                          │
│  5. SCALABILITY TESTING                                  │
│     ┌────────────────────────────────┐                  │
│     │ Gradual Load Increase          │                  │
│     │ 100 → 200 → 500 → 1000 users   │                  │
│     │ Duration: 2-4 hours            │                  │
│     │ Goal: Capacity planning        │                  │
│     └────────────────────────────────┘                  │
└──────────────────────────────────────────────────────────┘
```

#### **1. Load Testing with K6**

**Installation**

```bash
# Install K6
choco install k6          # Windows
brew install k6           # macOS
sudo apt install k6       # Linux
```

**Load Test Script (load-test.js)**

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
    stages: [
        { duration: '2m', target: 100 },   // Ramp up to 100 users
        { duration: '5m', target: 100 },   // Stay at 100 users
        { duration: '2m', target: 200 },   // Ramp up to 200 users
        { duration: '5m', target: 200 },   // Stay at 200 users
        { duration: '2m', target: 0 },     // Ramp down to 0
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'],  // 95% of requests < 500ms
        http_req_failed: ['rate<0.01'],    // Error rate < 1%
        errors: ['rate<0.1'],
    },
};

// Test data
const BASE_URL = 'https://api.yourapp.com';
const AUTH_TOKEN = 'your-auth-token';

export default function () {
    // 1. List products
    let listResponse = http.get(`${BASE_URL}/api/products`, {
        headers: {
            'Authorization': `Bearer ${AUTH_TOKEN}`,
            'Content-Type': 'application/json',
        },
    });

    check(listResponse, {
        'product list status is 200': (r) => r.status === 200,
        'product list has data': (r) => JSON.parse(r.body).length > 0,
        'response time < 200ms': (r) => r.timings.duration < 200,
    }) || errorRate.add(1);

    sleep(1);

    // 2. Get product details
    const productId = JSON.parse(listResponse.body)[0].id;
    let detailResponse = http.get(`${BASE_URL}/api/products/${productId}`, {
        headers: { 'Authorization': `Bearer ${AUTH_TOKEN}` },
    });

    check(detailResponse, {
        'product detail status is 200': (r) => r.status === 200,
        'product has name': (r) => JSON.parse(r.body).name !== undefined,
    }) || errorRate.add(1);

    sleep(1);

    // 3. Create order
    const orderPayload = JSON.stringify({
        customerId: 'CUST123',
        items: [
            { productId: productId, quantity: 2 }
        ]
    });

    let orderResponse = http.post(`${BASE_URL}/api/orders`, orderPayload, {
        headers: {
            'Authorization': `Bearer ${AUTH_TOKEN}`,
            'Content-Type': 'application/json',
        },
    });

    check(orderResponse, {
        'order creation status is 201': (r) => r.status === 201,
        'order has ID': (r) => JSON.parse(r.body).id !== undefined,
        'order creation < 500ms': (r) => r.timings.duration < 500,
    }) || errorRate.add(1);

    sleep(2);
}

export function handleSummary(data) {
    return {
        'summary.json': JSON.stringify(data),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}
```

**Run Load Test**

```bash
k6 run load-test.js

# Run with custom settings
k6 run --vus 100 --duration 30s load-test.js

# Run with cloud reporting
k6 run --out cloud load-test.js
```

**Load Test Results**

```
          /\      |‾‾| /‾‾/   /‾‾/
     /\  /  \     |  |/  /   /  /
    /  \/    \    |     (   /   ‾‾\
   /          \   |  |\  \ |  (‾)  |
  / __________ \  |__| \__\ \_____/ .io

  execution: local
     script: load-test.js
     output: -

  scenarios: (100.00%) 1 scenario, 200 max VUs, 18m30s max duration

     ✓ product list status is 200
     ✓ product list has data
     ✓ response time < 200ms
     ✓ product detail status is 200
     ✓ product has name
     ✓ order creation status is 201
     ✓ order has ID
     ✓ order creation < 500ms

     checks.........................: 99.97% ✓ 45234    ✗ 14
     data_received..................: 145 MB 810 kB/s
     data_sent......................: 25 MB  141 kB/s
     http_req_blocked...............: avg=1.2ms   min=0s     med=1ms    max=125ms  p(90)=2ms    p(95)=3ms
     http_req_connecting............: avg=0.5ms   min=0s     med=0s     max=85ms   p(90)=1ms    p(95)=2ms
   ✓ http_req_duration..............: avg=145ms   min=45ms   med=120ms  max=950ms  p(90)=280ms  p(95)=450ms
       { expected_response:true }...: avg=143ms   min=45ms   med=120ms  max=850ms  p(90)=275ms  p(95)=445ms
   ✓ http_req_failed................: 0.01%  ✓ 14       ✗ 15072
     http_req_receiving.............: avg=2.5ms   min=0s     med=1.2ms  max=45ms   p(90)=5ms    p(95)=8ms
     http_req_sending...............: avg=0.8ms   min=0s     med=0.5ms  max=12ms   p(90)=1.5ms  p(95)=2ms
     http_req_tls_handshaking.......: avg=0ms     min=0s     med=0s     max=0ms    p(90)=0s     p(95)=0s
     http_req_waiting...............: avg=142ms   min=43ms   med=118ms  max=945ms  p(90)=275ms  p(95)=442ms
     http_reqs......................: 15086  84.4/s
     iteration_duration.............: avg=4.2s    min=4.1s   med=4.2s   max=5.1s   p(90)=4.5s   p(95)=4.7s
     iterations.....................: 5028   28.1/s
     vus............................: 1      min=1      max=200
     vus_max........................: 200    min=200    max=200

✅ PASSED: All thresholds met
```

#### **2. Stress Testing**

**Stress Test Configuration**

```javascript
// stress-test.js
export const options = {
    stages: [
        { duration: '2m', target: 100 },    // Normal load
        { duration: '5m', target: 500 },    // High load
        { duration: '2m', target: 1000 },   // Stress load
        { duration: '5m', target: 2000 },   // Beyond capacity
        { duration: '5m', target: 5000 },   // Breaking point
        { duration: '10m', target: 0 },     // Recovery
    ],
    thresholds: {
        http_req_duration: ['p(99)<3000'],  // Relaxed for stress test
        http_req_failed: ['rate<0.5'],      // Allow up to 50% errors
    },
};
```

**Stress Test Analysis**

```
Stress Test Results:

User Load vs Response Time:
├─ 100 users  → 150ms avg (✅ Optimal)
├─ 500 users  → 250ms avg (✅ Acceptable)
├─ 1000 users → 450ms avg (⚠️ Degraded)
├─ 2000 users → 1200ms avg (⚠️ Poor)
├─ 5000 users → 8500ms avg (❌ Breaking point)
└─ Recovery   → 180ms avg (✅ System recovered)

Findings:
1. System handles 1000 concurrent users acceptably
2. Degradation begins at 1500 users
3. Breaking point at 5000 users (CPU at 95%)
4. Memory leaks detected (increased from 2GB to 8GB)
5. Database connection pool exhausted at 2500 users

Recommendations:
✅ Set auto-scaling threshold at 1000 users
✅ Increase database connection pool from 100 to 300
✅ Implement request throttling at 2000 req/s
✅ Add caching layer (Redis) for read-heavy endpoints
✅ Optimize slow database queries (3 identified)
```

#### **3. Soak Testing**

**Soak Test Configuration**

```javascript
// soak-test.js
export const options = {
    stages: [
        { duration: '5m', target: 100 },     // Ramp up
        { duration: '8h', target: 100 },     // Sustained load for 8 hours
        { duration: '5m', target: 0 },       // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    // Simulate realistic user behavior
    const scenarios = [
        () => browseProducts(),
        () => searchProducts(),
        () => viewProductDetails(),
        () => addToCart(),
        () => checkout(),
    ];

    const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
    scenario();

    sleep(Math.random() * 3 + 2); // Random think time 2-5 seconds
}

function browseProducts() {
    http.get(`${BASE_URL}/api/products?page=1&size=20`);
}

function searchProducts() {
    const query = ['laptop', 'phone', 'tablet'][Math.floor(Math.random() * 3)];
    http.get(`${BASE_URL}/api/products/search?q=${query}`);
}

// ... other scenarios
```

**Soak Test Monitoring**

```csharp
// Application Insights Custom Metrics
public class PerformanceMonitor
{
    private readonly TelemetryClient _telemetry;
    private readonly PerformanceCounter _cpuCounter;
    private readonly PerformanceCounter _memoryCounter;

    public PerformanceMonitor(TelemetryClient telemetry)
    {
        _telemetry = telemetry;
        _cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
        _memoryCounter = new PerformanceCounter("Memory", "Available MBytes");
    }

    public void TrackSystemMetrics()
    {
        var metrics = new Dictionary<string, double>
        {
            ["CPU Usage"] = _cpuCounter.NextValue(),
            ["Available Memory (MB)"] = _memoryCounter.NextValue(),
            ["GC Gen0 Collections"] = GC.CollectionCount(0),
            ["GC Gen1 Collections"] = GC.CollectionCount(1),
            ["GC Gen2 Collections"] = GC.CollectionCount(2),
            ["Thread Count"] = Process.GetCurrentProcess().Threads.Count
        };

        foreach (var metric in metrics)
        {
            _telemetry.TrackMetric(metric.Key, metric.Value);
        }
    }
}

// Background service to track metrics
public class MetricsCollectionService : BackgroundService
{
    private readonly PerformanceMonitor _monitor;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            _monitor.TrackSystemMetrics();
            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }
}
```

**Soak Test Results**

```
8-Hour Soak Test Results:

Memory Usage Over Time:
Hour 0: 512 MB
Hour 1: 580 MB
Hour 2: 650 MB  ⚠️ +12% increase
Hour 3: 720 MB  ⚠️ +23% increase
Hour 4: 795 MB  ⚠️ +35% increase
Hour 5: 870 MB  ❌ +41% increase (Memory leak suspected)
Hour 6: 940 MB  ❌ +46% increase
Hour 7: 1015 MB ❌ +50% increase
Hour 8: 1080 MB ❌ +53% increase

Issues Found:
1. ❌ Memory Leak: HttpClient instances not disposed
   Location: ProductService.cs:45
   Fix: Use IHttpClientFactory

2. ❌ Connection Pool Exhaustion
   Database connections not returned to pool
   Fix: Wrap DbContext in using statements

3. ❌ Event Handler Memory Leak
   Event handlers not unsubscribed
   Fix: Implement IDisposable properly

4. ⚠️ Cache Growing Unbounded
   No expiration policy on in-memory cache
   Fix: Set sliding expiration (30 minutes)

Response Time Degradation:
Hour 0-2: 150ms avg (✅ Stable)
Hour 3-5: 185ms avg (⚠️ +23%)
Hour 6-8: 225ms avg (❌ +50%)

Conclusion:
System NOT ready for production. Memory leaks must be fixed.
Re-run soak test after fixes applied.
```

#### **4. Azure Load Testing (Cloud-Based)**

**Test Configuration (load-test.yaml)**

```yaml
version: v0.1
testName: ProductionLoadTest
testPlan: load-test.jmx
engineInstances: 10

failureCriteria:
  - avg(response_time_ms) > 500
  - percentage(error) > 5
  - avg(latency) > 300

autoStop:
  errorPercentage: 90
  timeWindow: 60

env:
  - name: API_URL
    value: https://api.yourapp.com
  - name: API_KEY
    value: ${{ secrets.API_KEY }}

resourceConfiguration:
  engineSize: MEDIUM
  parallelCopies: 10
```

**Run Azure Load Test**

```bash
# Azure CLI
az load test create \
  --name "production-load-test" \
  --test-plan load-test.jmx \
  --engine-instances 10 \
  --resource-group my-rg \
  --load-test-resource my-load-test

# Monitor test
az load test show \
  --name "production-load-test" \
  --resource-group my-rg \
  --load-test-resource my-load-test
```

#### **Performance Testing Metrics**

| Metric | Description | Good Target | Tool |
|--------|-------------|-------------|------|
| **Response Time** | Time to complete request | p95 < 500ms | K6, JMeter |
| **Throughput** | Requests per second | 1000+ req/s | K6 |
| **Error Rate** | Percentage of failed requests | < 1% | K6, App Insights |
| **CPU Usage** | Server CPU utilization | < 70% | Azure Monitor |
| **Memory Usage** | RAM consumption | < 80%, stable | Azure Monitor |
| **Database Queries** | Query duration | p95 < 100ms | SQL Profiler |
| **Connection Pool** | Active/idle connections | < 80% capacity | SQL DMVs |
| **GC Pressure** | Garbage collection frequency | Gen2 < 5/min | PerfView |

#### **Performance Testing Best Practices**

```csharp
// 1. Application Insights Integration for Performance Tracking
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = false; // Full telemetry during load tests
    options.EnablePerformanceCounterCollectionModule = true;
});

// 2. Custom Performance Tracking
public class PerformanceTrackingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly TelemetryClient _telemetry;

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

            _telemetry.TrackMetric(new MetricTelemetry
            {
                Name = "Request Duration",
                Sum = sw.ElapsedMilliseconds,
                Properties =
                {
                    ["Endpoint"] = context.Request.Path,
                    ["Method"] = context.Request.Method,
                    ["StatusCode"] = context.Response.StatusCode.ToString()
                }
            });

            if (sw.ElapsedMilliseconds > 500)
            {
                _telemetry.TrackTrace($"Slow request: {context.Request.Path} took {sw.ElapsedMilliseconds}ms",
                    SeverityLevel.Warning);
            }
        }
    }
}

// 3. Database Query Performance Tracking
public class PerformantDbContext : DbContext
{
    private readonly TelemetryClient _telemetry;

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.LogTo(query =>
        {
            // Track slow queries
            if (query.Contains("ExecutedDbCommand"))
            {
                var duration = ExtractDuration(query);
                if (duration > 100) // > 100ms
                {
                    _telemetry.TrackTrace($"Slow query: {query}", SeverityLevel.Warning);
                }
            }
        });
    }
}

// 4. Circuit Breaker for External Dependencies
services.AddHttpClient("ProductService")
    .AddPolicyHandler(GetRetryPolicy())
    .AddPolicyHandler(GetCircuitBreakerPolicy());

static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        .CircuitBreakerAsync(5, TimeSpan.FromSeconds(30));
}
```

#### **✅ Performance Testing Checklist**

**Before Testing**:
- [ ] Define performance requirements (SLA, SLO)
- [ ] Identify critical user journeys
- [ ] Set up monitoring (Application Insights, Prometheus)
- [ ] Prepare test data
- [ ] Configure load test environment (match production)
- [ ] Baseline performance (single user)

**During Testing**:
- [ ] Monitor real-time metrics
- [ ] Track error logs
- [ ] Watch resource utilization (CPU, memory, disk, network)
- [ ] Monitor database performance
- [ ] Check cache hit ratios
- [ ] Observe auto-scaling behavior

**After Testing**:
- [ ] Analyze results against thresholds
- [ ] Identify bottlenecks
- [ ] Document findings
- [ ] Create optimization backlog
- [ ] Re-test after optimizations
- [ ] Update capacity planning

#### **Common Performance Bottlenecks and Solutions**

```csharp
// ❌ Problem: N+1 Query
var orders = await context.Orders.ToListAsync();
foreach (var order in orders)
{
    var customer = await context.Customers.FindAsync(order.CustomerId); // N+1!
}

// ✅ Solution: Eager Loading
var orders = await context.Orders
    .Include(o => o.Customer)
    .ToListAsync();

// ❌ Problem: Synchronous I/O blocking threads
var response = httpClient.GetAsync(url).Result; // Blocks thread!

// ✅ Solution: Async/await
var response = await httpClient.GetAsync(url);

// ❌ Problem: Large result sets without pagination
var products = await context.Products.ToListAsync(); // Returns 100,000 items!

// ✅ Solution: Pagination
var products = await context.Products
    .OrderBy(p => p.Id)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();

// ❌ Problem: No caching for expensive operations
public async Task<List<Category>> GetCategoriesAsync()
{
    return await context.Categories.ToListAsync(); // DB hit every time
}

// ✅ Solution: Distributed cache
public async Task<List<Category>> GetCategoriesAsync()
{
    const string cacheKey = "categories";
    var cached = await _cache.GetStringAsync(cacheKey);

    if (cached != null)
        return JsonSerializer.Deserialize<List<Category>>(cached);

    var categories = await context.Categories.ToListAsync();

    await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(categories),
        new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1)
        });

    return categories;
}
```

---

## Q464-Q480: Leadership & Technical Excellence Summary

The following questions cover essential leadership and technical excellence topics for senior engineers:

### **Q464: Code Review Best Practices**

**Key Principles**:
- Review for correctness, design, readability, maintainability
- Provide constructive feedback (avoid "you should", use "consider")
- Focus on important issues (don't nitpick formatting)
- Approve if no blocking issues (minor issues can be follow-up)
- Review within 24 hours
- Use automated tools for style/formatting

**Checklist**:
- ✅ Does it solve the problem?
- ✅ Is the code readable and maintainable?
- ✅ Are there tests?
- ✅ Are there security issues?
- ✅ Is error handling appropriate?
- ✅ Is performance acceptable?
- ✅ Is it properly documented?

---

### **Q465: Technical Debt Management**

**Strategies**:
- Track technical debt in backlog
- Allocate 20% capacity for debt reduction
- Boy Scout Rule: Leave code better than you found it
- Refactor during feature work (when safe)
- Create ADRs (Architecture Decision Records)
- Balance speed vs quality

**Debt Classification**:
- **Critical**: Security vulnerabilities, data loss risks
- **High**: Performance issues, stability problems
- **Medium**: Poor code structure, missing tests
- **Low**: Code smells, minor refactoring

---

### **Q466: Mentoring Junior Developers**

**Effective Practices**:
- Pair programming sessions
- Code review as teaching opportunity
- Assign progressively challenging tasks
- Provide constructive feedback
- Share resources and learning paths
- Encourage questions and experimentation
- Set clear expectations
- Celebrate growth and achievements

---

### **Q467: Making Architectural Decisions**

**Decision Framework**:
1. **Understand Requirements**: Functional and non-functional
2. **Research Options**: Evaluate alternatives
3. **Consider Trade-offs**: Performance, scalability, cost, complexity
4. **Prototype**: Build POCs for unclear choices
5. **Document**: Create ADR (Architecture Decision Record)
6. **Review**: Get team input
7. **Iterate**: Be willing to change if needed

**ADR Template**:
```markdown
# ADR-001: Use Redis for Distributed Caching

## Status
Accepted

## Context
Need distributed cache for session storage and API responses.
Current in-memory cache doesn't work with multiple instances.

## Decision
Implement Redis for distributed caching.

## Consequences
**Positive**:
- Handles 100K+ ops/sec
- Built-in persistence options
- Rich data structures

**Negative**:
- Additional infrastructure cost ($50/month)
- Operational complexity
- Network latency (1-5ms)

## Alternatives Considered
- Memcached: Lacks persistence
- SQL Server: Too slow for caching
```

---

### **Q468: Handling Production Incidents**

**Incident Response Process**:
1. **Detect**: Monitoring alerts, user reports
2. **Triage**: Assess severity (P0-P4)
3. **Communicate**: Notify stakeholders, create incident channel
4. **Investigate**: Check logs, metrics, recent deployments
5. **Mitigate**: Apply hotfix or rollback
6. **Resolve**: Verify fix in production
7. **Post-Mortem**: Blameless retrospective within 48 hours

**Post-Mortem Template**:
```markdown
# Incident Post-Mortem: API Outage (2024-01-15)

## Summary
API was down for 45 minutes (14:00-14:45 UTC).
Affected 1,200 users. No data loss.

## Timeline
- 14:00: Deployment to production
- 14:05: Error rate spike to 50%
- 14:10: Incident declared (P1)
- 14:15: Root cause identified (connection pool exhaustion)
- 14:30: Rollback initiated
- 14:45: Service restored

## Root Cause
Database connection pool size was reduced from 200 to 50
in recent deployment. Under load, pool was exhausted.

## Action Items
1. [P0] Revert connection pool to 200 (Done)
2. [P1] Add connection pool monitoring alert (John, 2024-01-18)
3. [P2] Implement load testing in CI/CD (Sarah, 2024-01-25)
4. [P3] Review all config changes in PRs (Team, ongoing)

## Lessons Learned
- Configuration changes need same rigor as code changes
- Need better visibility into connection pool usage
- Load testing would have caught this
```

---

### **Q469: Communicating with Stakeholders**

**Best Practices**:
- Use business language, not technical jargon
- Focus on value and outcomes, not implementation
- Be honest about risks and trade-offs
- Provide options with recommendations
- Use visuals (diagrams, charts)
- Set realistic expectations
- Regular updates (especially for long projects)
- Listen actively and clarify requirements

**Example**:
```
❌ Bad: "We need to refactor the repository layer to use
          the specification pattern for better testability."

✅ Good: "I recommend spending 2 weeks improving our data
          access layer. This will reduce bugs by making the
          code easier to test, and make future features 30%
          faster to develop. The system will continue working
          during this refactoring with no downtime."
```

---

### **Q470: Building High-Performing Teams**

**Key Elements**:
1. **Psychological Safety**: Team members feel safe to take risks
2. **Dependability**: Team delivers on commitments
3. **Structure & Clarity**: Clear roles and goals
4. **Meaning**: Work has personal significance
5. **Impact**: Work matters and creates value

**Practices**:
- Regular 1-on-1s with team members
- Team retrospectives
- Celebrate successes
- Learn from failures (blameless)
- Invest in learning and development
- Remove blockers
- Foster collaboration
- Lead by example

---

### **Q471: Time Management & Prioritization**

**Eisenhower Matrix**:
```
┌─────────────────┬─────────────────┐
│  URGENT &       │  NOT URGENT &   │
│  IMPORTANT      │  IMPORTANT      │
│                 │                 │
│  Do First       │  Schedule       │
│  - Production   │  - Planning     │
│    incidents    │  - Learning     │
│  - Critical     │  - Refactoring  │
│    bugs         │  - Team growth  │
└─────────────────┼─────────────────┤
│  URGENT &       │  NOT URGENT &   │
│  NOT IMPORTANT  │  NOT IMPORTANT  │
│                 │                 │
│  Delegate       │  Eliminate      │
│  - Meetings     │  - Busy work    │
│  - Interrupts   │  - Time wasters │
└─────────────────┴─────────────────┘
```

**Techniques**:
- Time blocking for focused work
- Pomodoro technique (25 min focus + 5 min break)
- Deep work in mornings
- Batch similar tasks
- Say no to non-essential requests
- Use calendar for everything

---

### **Q472: Conflict Resolution**

**Steps**:
1. **Listen**: Understand both perspectives
2. **Empathize**: Acknowledge feelings
3. **Find Common Ground**: Shared goals
4. **Explore Solutions**: Brainstorm options
5. **Agree on Action**: Clear next steps
6. **Follow Up**: Ensure resolution

**Example Conflict**: Two engineers disagree on tech choice

**Resolution**:
```
1. Listen to both arguments
2. Define evaluation criteria (performance, cost, learning curve)
3. Create comparison matrix
4. Build POCs if needed
5. Make data-driven decision
6. Document decision (ADR)
7. Support chosen approach as team
```

---

### **Q473-Q480: Additional Leadership Topics**

**Q473: Setting SMART Goals**
- Specific, Measurable, Achievable, Relevant, Time-bound
- Example: "Reduce API p95 latency from 500ms to 200ms by Q2"

**Q474: Giving Effective Feedback**
- SBI Model: Situation, Behavior, Impact
- Timely and specific
- Balance positive and constructive
- Focus on behavior, not personality

**Q475: Delegation**
- Match task to skill level
- Provide context and expectations
- Give ownership, not just tasks
- Check in, but don't micromanage
- Recognize achievements

**Q476: Managing Remote Teams**
- Over-communicate
- Document everything
- Async-first communication
- Regular video check-ins
- Build team culture intentionally
- Respect time zones
- Trust and autonomy

**Q477: Career Development Planning**
- Individual Development Plans (IDPs)
- Growth frameworks (IC vs Management track)
- Regular career conversations
- Provide growth opportunities
- Support conference attendance and learning

**Q478: Technical Writing & Documentation**
- README files for all projects
- API documentation (OpenAPI/Swagger)
- Architecture diagrams (C4 model)
- Runbooks for operations
- ADRs for decisions
- Knowledge sharing (wiki, blog)

**Q479: Interview & Hiring**
- Define role requirements clearly
- Structured interviews (same questions)
- Assess technical skills and culture fit
- Collaborative coding exercises
- Check references
- Diverse interview panel

**Q480: Continuous Learning**
- Read books and blogs
- Attend conferences and meetups
- Online courses (Pluralsight, Udemy)
- Side projects
- Contribute to open source
- Follow industry leaders
- Learn adjacent skills (DevOps, UX, Product)

---

## Summary

**Total Coverage for Q461-Q480:**

1. **Q461**: Test-Driven Development (TDD) with Red-Green-Refactor cycle
2. **Q462**: Mutation testing with Stryker.NET
3. **Q463**: Performance testing (load, stress, soak) with K6 and Azure Load Testing
4. **Q464**: Code review best practices
5. **Q465**: Technical debt management
6. **Q466**: Mentoring junior developers
7. **Q467**: Making architectural decisions
8. **Q468**: Handling production incidents
9. **Q469**: Communicating with stakeholders
10. **Q470**: Building high-performing teams
11. **Q471**: Time management and prioritization
12. **Q472**: Conflict resolution
13. **Q473**: Setting SMART goals
14. **Q474**: Giving effective feedback
15. **Q475**: Delegation strategies
16. **Q476**: Managing remote teams
17. **Q477**: Career development planning
18. **Q478**: Technical writing and documentation
19. **Q479**: Interview and hiring practices
20. **Q480**: Continuous learning strategies

This comprehensive set covers all essential advanced testing and technical leadership topics for senior-level software engineering roles, emphasizing:
- Advanced testing methodologies
- Leadership and people management
- Communication and stakeholder management
- Career development and growth
- Continuous improvement

---

**End of Q461-Q480: Advanced Testing & Technical Leadership**
