# Advanced Microservices Architecture - Questions 141-171

---

## Q141: What is a Bounded Context in Domain-Driven Design (DDD)?

**Answer:**

A **Bounded Context** is a central pattern in Domain-Driven Design (DDD) that defines explicit boundaries within which a particular domain model is defined and applicable. It's a way to divide a large, complex domain into smaller, more manageable parts, each with its own ubiquitous language and models.

**Key Characteristics:**

1. **Clear Boundaries**: Each bounded context has explicit boundaries that separate it from other contexts
2. **Ubiquitous Language**: Each context has its own domain language understood by both developers and domain experts
3. **Independent Models**: Models within a bounded context are consistent but may differ from models in other contexts
4. **Autonomous**: Each bounded context can evolve independently
5. **Context Mapping**: Defines how bounded contexts relate and integrate with each other

**Visual Representation:**

```
┌─────────────────────────────────────────────────────────────────┐
│                     E-Commerce Domain                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │  Order Context       │      │  Inventory Context   │        │
│  │                      │      │                      │        │
│  │  - Order (Aggregate) │      │  - Product           │        │
│  │  - OrderLine         │      │  - Stock             │        │
│  │  - Customer (Ref)    │      │  - Warehouse         │        │
│  │  - Product (Ref)     │◄────►│  - Reservation       │        │
│  │                      │      │                      │        │
│  └──────────────────────┘      └──────────────────────┘        │
│           │                              │                      │
│           │                              │                      │
│  ┌────────▼──────────────┐      ┌───────▼──────────────┐       │
│  │  Customer Context     │      │  Catalog Context     │       │
│  │                       │      │                      │       │
│  │  - Customer           │      │  - Product           │       │
│  │  - Address            │      │  - Category          │       │
│  │  - PaymentMethod      │      │  - Pricing           │       │
│  │  - CustomerProfile    │      │  - ProductDetails    │       │
│  │                       │      │                      │       │
│  └───────────────────────┘      └──────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Code Example - Bounded Contexts in C#:**

```csharp
// ORDER CONTEXT
namespace ECommerce.OrderContext
{
    // Product in Order Context - minimal reference
    public class Product
    {
        public Guid ProductId { get; set; }
        public string Name { get; set; }
        public decimal Price { get; set; }
    }

    // Order Aggregate Root
    public class Order
    {
        public Guid OrderId { get; private set; }
        public Guid CustomerId { get; private set; }
        public List<OrderLine> OrderLines { get; private set; }
        public OrderStatus Status { get; private set; }
        public decimal TotalAmount { get; private set; }

        public void AddOrderLine(Product product, int quantity)
        {
            var orderLine = new OrderLine
            {
                ProductId = product.ProductId,
                ProductName = product.Name,
                UnitPrice = product.Price,
                Quantity = quantity
            };
            OrderLines.Add(orderLine);
            CalculateTotal();
        }

        private void CalculateTotal()
        {
            TotalAmount = OrderLines.Sum(ol => ol.UnitPrice * ol.Quantity);
        }
    }

    public class OrderLine
    {
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
    }

    public enum OrderStatus
    {
        Pending,
        Confirmed,
        Shipped,
        Delivered,
        Cancelled
    }
}

// CATALOG CONTEXT
namespace ECommerce.CatalogContext
{
    // Product in Catalog Context - rich domain model
    public class Product
    {
        public Guid ProductId { get; private set; }
        public string Name { get; private set; }
        public string Description { get; private set; }
        public string SKU { get; private set; }
        public Category Category { get; private set; }
        public List<ProductImage> Images { get; private set; }
        public List<ProductSpecification> Specifications { get; private set; }
        public PricingInfo Pricing { get; private set; }
        public bool IsActive { get; private set; }

        public void UpdateProductInformation(string name, string description)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new DomainException("Product name cannot be empty");

            Name = name;
            Description = description;
        }

        public void SetPrice(decimal basePrice, decimal? discountPrice = null)
        {
            Pricing = new PricingInfo
            {
                BasePrice = basePrice,
                DiscountPrice = discountPrice,
                EffectivePrice = discountPrice ?? basePrice
            };
        }
    }

    public class Category
    {
        public Guid CategoryId { get; set; }
        public string Name { get; set; }
        public string Path { get; set; }
    }

    public class ProductImage
    {
        public string ImageUrl { get; set; }
        public bool IsPrimary { get; set; }
    }

    public class ProductSpecification
    {
        public string SpecificationName { get; set; }
        public string SpecificationValue { get; set; }
    }

    public class PricingInfo
    {
        public decimal BasePrice { get; set; }
        public decimal? DiscountPrice { get; set; }
        public decimal EffectivePrice { get; set; }
    }
}

// INVENTORY CONTEXT
namespace ECommerce.InventoryContext
{
    // Product in Inventory Context - focused on stock
    public class Product
    {
        public Guid ProductId { get; set; }
        public string SKU { get; set; }
    }

    public class StockItem
    {
        public Guid StockItemId { get; private set; }
        public Guid ProductId { get; private set; }
        public Guid WarehouseId { get; private set; }
        public int QuantityOnHand { get; private set; }
        public int QuantityReserved { get; private set; }
        public int QuantityAvailable => QuantityOnHand - QuantityReserved;

        public bool ReserveStock(int quantity)
        {
            if (QuantityAvailable < quantity)
                return false;

            QuantityReserved += quantity;
            return true;
        }

        public void ReleaseReservation(int quantity)
        {
            QuantityReserved -= quantity;
        }

        public void AdjustStock(int quantity, string reason)
        {
            QuantityOnHand += quantity;
        }
    }

    public class Warehouse
    {
        public Guid WarehouseId { get; set; }
        public string Name { get; set; }
        public string Location { get; set; }
    }
}
```

**Context Mapping Patterns:**

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **Shared Kernel** | Two contexts share a common model | When contexts are tightly related |
| **Customer-Supplier** | Upstream context serves downstream | Clear provider-consumer relationship |
| **Conformist** | Downstream conforms to upstream model | When you have no control over upstream |
| **Anti-Corruption Layer** | Translation layer between contexts | Protect your model from external models |
| **Published Language** | Well-documented integration format | Public APIs, cross-team integration |
| **Separate Ways** | No integration between contexts | Contexts are completely independent |
| **Partnership** | Teams collaborate on integration | Mutual dependency, shared success |

**Integration Example with Anti-Corruption Layer:**

```csharp
// Anti-Corruption Layer: Translates between Catalog and Order contexts
namespace ECommerce.OrderContext.Integration
{
    public interface ICatalogService
    {
        Task<OrderContext.Product> GetProductForOrderAsync(Guid productId);
    }

    public class CatalogServiceAdapter : ICatalogService
    {
        private readonly ICatalogApiClient _catalogClient;

        public CatalogServiceAdapter(ICatalogApiClient catalogClient)
        {
            _catalogClient = catalogClient;
        }

        public async Task<OrderContext.Product> GetProductForOrderAsync(Guid productId)
        {
            // Fetch rich product from Catalog Context
            var catalogProduct = await _catalogClient.GetProductAsync(productId);

            // Translate to Order Context's Product (simpler model)
            return new OrderContext.Product
            {
                ProductId = catalogProduct.ProductId,
                Name = catalogProduct.Name,
                Price = catalogProduct.Pricing.EffectivePrice
            };
        }
    }
}
```

**Real-World Scenario:**

In an e-commerce system:
- **Order Context** needs only basic product info (ID, name, price at time of order)
- **Catalog Context** maintains rich product details, images, specifications
- **Inventory Context** tracks stock levels across warehouses
- Each context has its own representation of "Product" tailored to its needs

**Best Practices:**

1. **Define Clear Boundaries**: Use strategic design to identify natural boundaries
2. **Ubiquitous Language**: Maintain a consistent vocabulary within each context
3. **Autonomous Databases**: Each bounded context should have its own database
4. **Explicit Integration**: Use well-defined interfaces between contexts
5. **Avoid Shared Models**: Don't share domain entities across contexts
6. **Context Maps**: Document relationships between bounded contexts
7. **Team Alignment**: Ideally, one team owns one bounded context

---

## Q142: How do you decompose a monolithic application into microservices?

**Answer:**

Decomposing a monolith into microservices is a strategic process that requires careful planning and incremental execution. The goal is to break down a large, tightly-coupled application into smaller, independent services.

**Decomposition Strategies:**

**1. By Business Capability**
```
Monolith E-Commerce App
         │
         └─► Decompose by Business Capabilities
              │
              ├─► Product Catalog Service
              ├─► Order Management Service
              ├─► Customer Service
              ├─► Inventory Service
              ├─► Payment Service
              ├─► Shipping Service
              └─► Notification Service
```

**2. By Subdomain (DDD Approach)**
```
Domain Analysis
         │
         ├─► Core Domain (unique business value)
         │   └─► Order Processing, Pricing Engine
         │
         ├─► Supporting Subdomain (necessary but not unique)
         │   └─► Inventory Management, Shipping
         │
         └─► Generic Subdomain (common to many businesses)
             └─► Authentication, Notifications
```

**Step-by-Step Decomposition Process:**

**Step 1: Analyze the Monolith**

```csharp
// Original Monolithic Application Structure
namespace ECommerce.Monolith
{
    public class OrderController
    {
        private readonly OrderService _orderService;
        private readonly ProductService _productService;
        private readonly InventoryService _inventoryService;
        private readonly PaymentService _paymentService;
        private readonly NotificationService _notificationService;

        // Tightly coupled - all services in one application
        [HttpPost("orders")]
        public async Task<IActionResult> CreateOrder(CreateOrderRequest request)
        {
            // Product validation
            var product = await _productService.GetProduct(request.ProductId);

            // Inventory check
            var inStock = await _inventoryService.CheckStock(request.ProductId, request.Quantity);

            // Create order
            var order = await _orderService.CreateOrder(request);

            // Process payment
            var payment = await _paymentService.ProcessPayment(order.Id, request.PaymentInfo);

            // Update inventory
            await _inventoryService.DeductStock(request.ProductId, request.Quantity);

            // Send notification
            await _notificationService.SendOrderConfirmation(order.Id);

            return Ok(order);
        }
    }
}
```

**Step 2: Identify Service Boundaries**

| Service | Responsibilities | Data Owned |
|---------|-----------------|------------|
| **Product Catalog** | Product info, categories, search | Products, Categories |
| **Order Management** | Order creation, tracking | Orders, OrderLines |
| **Inventory** | Stock tracking, reservations | StockItems, Warehouses |
| **Payment** | Payment processing, refunds | Transactions, PaymentMethods |
| **Customer** | Customer profiles, preferences | Customers, Addresses |
| **Notification** | Email, SMS notifications | Templates, NotificationLog |

**Step 3: Apply Strangler Fig Pattern**

```csharp
// Phase 1: Extract Product Service (first microservice)
namespace ProductCatalog.API
{
    [ApiController]
    [Route("api/products")]
    public class ProductsController : ControllerBase
    {
        private readonly IProductRepository _repository;

        [HttpGet("{id}")]
        public async Task<ActionResult<ProductDto>> GetProduct(Guid id)
        {
            var product = await _repository.GetByIdAsync(id);
            return Ok(new ProductDto
            {
                ProductId = product.ProductId,
                Name = product.Name,
                Price = product.Price,
                InStock = product.StockQuantity > 0
            });
        }
    }
}

// Monolith: Add facade to route to microservice
namespace ECommerce.Monolith
{
    public class ProductServiceFacade : IProductService
    {
        private readonly HttpClient _productServiceClient;
        private readonly LegacyProductService _legacyService;
        private readonly IFeatureToggle _featureToggle;

        public async Task<Product> GetProduct(Guid productId)
        {
            // Feature toggle: gradually migrate traffic
            if (_featureToggle.IsEnabled("UseProductMicroservice"))
            {
                // Call new microservice
                var response = await _productServiceClient.GetAsync($"api/products/{productId}");
                var productDto = await response.Content.ReadFromJsonAsync<ProductDto>();
                return MapToProduct(productDto);
            }
            else
            {
                // Use legacy monolith code
                return await _legacyService.GetProduct(productId);
            }
        }
    }
}
```

**Step 4: Handle Data Decomposition**

```csharp
// Original Monolith Database
/*
┌────────────────────────────────────┐
│     Monolith Database              │
├────────────────────────────────────┤
│  - Products Table                  │
│  - Orders Table                    │
│  - OrderLines Table                │
│  - Customers Table                 │
│  - Inventory Table                 │
│  - Payments Table                  │
└────────────────────────────────────┘
*/

// After Decomposition - Database per Service
/*
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Product DB      │  │ Order DB        │  │ Inventory DB    │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ - Products      │  │ - Orders        │  │ - StockItems    │
│ - Categories    │  │ - OrderLines    │  │ - Warehouses    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
*/

// Handle data synchronization with events
namespace OrderService.EventHandlers
{
    public class ProductPriceChangedHandler : IEventHandler<ProductPriceChangedEvent>
    {
        private readonly IOrderRepository _orderRepository;

        public async Task Handle(ProductPriceChangedEvent @event)
        {
            // Update denormalized product price in Order service
            var orders = await _orderRepository.GetPendingOrdersWithProduct(@event.ProductId);

            foreach (var order in orders)
            {
                var orderLine = order.OrderLines.First(ol => ol.ProductId == @event.ProductId);
                orderLine.CurrentPrice = @event.NewPrice;
            }

            await _orderRepository.SaveChangesAsync();
        }
    }
}
```

**Step 5: Implement Inter-Service Communication**

```csharp
// Order Service calls multiple services
namespace OrderService.Application
{
    public class CreateOrderCommandHandler
    {
        private readonly IOrderRepository _orderRepository;
        private readonly IProductServiceClient _productService;
        private readonly IInventoryServiceClient _inventoryService;
        private readonly IEventBus _eventBus;

        public async Task<OrderDto> Handle(CreateOrderCommand command)
        {
            // 1. Validate product exists (sync call)
            var product = await _productService.GetProductAsync(command.ProductId);

            // 2. Reserve inventory (sync call with compensation)
            var reservationId = await _inventoryService.ReserveStockAsync(
                command.ProductId,
                command.Quantity
            );

            try
            {
                // 3. Create order
                var order = new Order
                {
                    OrderId = Guid.NewGuid(),
                    CustomerId = command.CustomerId,
                    TotalAmount = product.Price * command.Quantity,
                    Status = OrderStatus.Pending
                };

                order.AddOrderLine(product.ProductId, product.Name, product.Price, command.Quantity);

                await _orderRepository.AddAsync(order);
                await _orderRepository.SaveChangesAsync();

                // 4. Publish event (async communication)
                await _eventBus.PublishAsync(new OrderCreatedEvent
                {
                    OrderId = order.OrderId,
                    CustomerId = order.CustomerId,
                    TotalAmount = order.TotalAmount,
                    OrderLines = order.OrderLines.Select(ol => new OrderLineDto
                    {
                        ProductId = ol.ProductId,
                        Quantity = ol.Quantity,
                        UnitPrice = ol.UnitPrice
                    }).ToList()
                });

                return MapToDto(order);
            }
            catch (Exception)
            {
                // Compensating action: release reservation
                await _inventoryService.ReleaseReservationAsync(reservationId);
                throw;
            }
        }
    }
}
```

**Migration Strategies:**

| Strategy | Description | Pros | Cons |
|----------|-------------|------|------|
| **Strangler Fig** | Gradually replace parts of monolith | Low risk, incremental | Slower migration |
| **Big Bang** | Replace entire monolith at once | Fast completion | High risk |
| **Database First** | Split database, then application | Data isolation early | Complex coordination |
| **API First** | Create service APIs, keep shared DB temporarily | Quick functional split | Shared database coupling |

**Decomposition Sequence Example:**

```
Phase 1: Extract Stateless Services
  └─► Notification Service (no complex dependencies)

Phase 2: Extract Supporting Services
  ├─► Product Catalog Service
  └─► Customer Service

Phase 3: Extract Core Services
  ├─► Inventory Service
  └─► Order Service (depends on Product, Inventory, Customer)

Phase 4: Extract Payment Service
  └─► Payment Service (high security requirements)

Phase 5: Decommission Monolith
  └─► Shut down remaining monolith components
```

**Handling Cross-Cutting Concerns:**

```csharp
// Shared libraries (not microservices)
namespace ECommerce.SharedKernel
{
    // Common value objects
    public class Money
    {
        public decimal Amount { get; }
        public string Currency { get; }
    }

    // Common interfaces
    public interface IEventBus
    {
        Task PublishAsync<T>(T @event) where T : IEvent;
    }
}

// API Gateway for cross-cutting concerns
namespace ApiGateway
{
    public class Startup
    {
        public void Configure(IApplicationBuilder app)
        {
            app.UseOcelot(configuration =>
            {
                configuration
                    .AddRateLimiting()
                    .AddAuthentication()
                    .AddCaching()
                    .AddLogging();
            }).Wait();
        }
    }
}
```

**Real-World Scenario:**

A retail company with a 10-year-old monolithic e-commerce application decides to migrate to microservices:

1. **Month 1-2**: Extract Notification Service (lowest risk, no database dependencies)
2. **Month 3-4**: Extract Product Catalog Service (read-heavy, well-defined boundary)
3. **Month 5-7**: Extract Inventory Service (complex stock management logic)
4. **Month 8-10**: Extract Order Service (core business logic, many dependencies)
5. **Month 11-12**: Decommission monolith, full microservices architecture

**Best Practices:**

1. **Start Small**: Begin with a simple, low-risk service (e.g., notifications)
2. **Database per Service**: Each microservice owns its data
3. **Use Bounded Contexts**: Apply DDD principles to identify service boundaries
4. **Event-Driven Communication**: Prefer async events over synchronous calls
5. **Implement Saga Pattern**: Handle distributed transactions
6. **API Gateway**: Centralize cross-cutting concerns
7. **Strangler Fig Pattern**: Incrementally replace monolith components
8. **Feature Toggles**: Control rollout and rollback
9. **Monitor Everything**: Implement distributed tracing and logging
10. **Automate**: Use CI/CD pipelines for each microservice

---

## Q143: Explain the Database per Service pattern in microservices.

**Answer:**

The **Database per Service** pattern is a microservices data management pattern where each microservice has its own private database that only it can access directly. No other service can access another service's database directly.

**Core Principles:**

1. **Private Database**: Each service owns its data and schema
2. **Loose Coupling**: Services are not coupled through a shared database
3. **Independent Evolution**: Each service can evolve its schema independently
4. **Technology Diversity**: Services can use different database technologies
5. **Service Encapsulation**: Data is accessed only through the service's API

**Visual Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                     API Gateway                                  │
└────────┬────────────────┬────────────────┬───────────────────────┘
         │                │                │
    ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
    │  Order   │    │ Product  │    │Inventory │
    │ Service  │    │ Service  │    │ Service  │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │                │                │
    ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
    │ Order DB │    │Product DB│    │Inventory │
    │(SQL)     │    │(MongoDB) │    │   DB     │
    │          │    │          │    │ (Redis)  │
    └──────────┘    └──────────┘    └──────────┘

    ✓ Each service has its own database
    ✓ Different database technologies
    ✓ No direct database access between services
```

**Implementation Example:**

```csharp
// ORDER SERVICE - Uses SQL Server
namespace OrderService
{
    public class OrderDbContext : DbContext
    {
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderLine> OrderLines { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Order service owns Order and OrderLine tables
            modelBuilder.Entity<Order>(entity =>
            {
                entity.ToTable("Orders");
                entity.HasKey(e => e.OrderId);
                entity.Property(e => e.OrderId).ValueGeneratedNever();

                // Denormalized customer data (no foreign key to Customer DB)
                entity.Property(e => e.CustomerId).IsRequired();
                entity.Property(e => e.CustomerName).HasMaxLength(200);
                entity.Property(e => e.CustomerEmail).HasMaxLength(200);
            });

            modelBuilder.Entity<OrderLine>(entity =>
            {
                entity.ToTable("OrderLines");
                entity.HasKey(e => e.OrderLineId);

                // Denormalized product data (snapshot at order time)
                entity.Property(e => e.ProductId).IsRequired();
                entity.Property(e => e.ProductName).HasMaxLength(300);
                entity.Property(e => e.UnitPrice).HasColumnType("decimal(18,2)");
            });
        }
    }

    public class Order
    {
        public Guid OrderId { get; set; }

        // Denormalized customer information
        public Guid CustomerId { get; set; }
        public string CustomerName { get; set; }
        public string CustomerEmail { get; set; }

        public DateTime OrderDate { get; set; }
        public OrderStatus Status { get; set; }
        public decimal TotalAmount { get; set; }

        public ICollection<OrderLine> OrderLines { get; set; }
    }

    public class OrderLine
    {
        public Guid OrderLineId { get; set; }
        public Guid OrderId { get; set; }

        // Denormalized product information (snapshot)
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public decimal UnitPrice { get; set; }

        public int Quantity { get; set; }
        public decimal LineTotal { get; set; }
    }
}

// PRODUCT SERVICE - Uses MongoDB
namespace ProductService
{
    public class Product
    {
        [BsonId]
        [BsonRepresentation(BsonType.String)]
        public Guid ProductId { get; set; }

        public string Name { get; set; }
        public string Description { get; set; }
        public string SKU { get; set; }

        [BsonRepresentation(BsonType.Decimal128)]
        public decimal Price { get; set; }

        public Category Category { get; set; }
        public List<string> Tags { get; set; }
        public List<ProductImage> Images { get; set; }
        public bool IsActive { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class ProductRepository
    {
        private readonly IMongoCollection<Product> _products;

        public ProductRepository(IMongoDatabase database)
        {
            _products = database.GetCollection<Product>("Products");
        }

        public async Task<Product> GetByIdAsync(Guid productId)
        {
            return await _products
                .Find(p => p.ProductId == productId)
                .FirstOrDefaultAsync();
        }

        public async Task<List<Product>> SearchAsync(string searchTerm)
        {
            var filter = Builders<Product>.Filter.Regex(
                p => p.Name,
                new BsonRegularExpression(searchTerm, "i")
            );

            return await _products.Find(filter).ToListAsync();
        }
    }
}

// INVENTORY SERVICE - Uses Redis for fast access
namespace InventoryService
{
    public class InventoryRepository
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly IDatabase _database;

        public InventoryRepository(IConnectionMultiplexer redis)
        {
            _redis = redis;
            _database = redis.GetDatabase();
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            string key = $"inventory:stock:{productId}";
            var value = await _database.StringGetAsync(key);
            return value.HasValue ? (int)value : 0;
        }

        public async Task<bool> ReserveStockAsync(Guid productId, int quantity)
        {
            string stockKey = $"inventory:stock:{productId}";
            string reservedKey = $"inventory:reserved:{productId}";

            // Use Redis transaction
            var transaction = _database.CreateTransaction();

            // Check if enough stock available
            var currentStock = await _database.StringGetAsync(stockKey);
            var currentReserved = await _database.StringGetAsync(reservedKey);

            int availableStock = (int)currentStock - (int)currentReserved;

            if (availableStock < quantity)
                return false;

            // Reserve stock
            transaction.StringIncrementAsync(reservedKey, quantity);

            bool committed = await transaction.ExecuteAsync();
            return committed;
        }
    }
}
```

**Data Access Patterns:**

**1. API Composition Pattern**
```csharp
// API Gateway composes data from multiple services
namespace ApiGateway.Controllers
{
    [ApiController]
    [Route("api/order-details")]
    public class OrderDetailsController : ControllerBase
    {
        private readonly IOrderServiceClient _orderService;
        private readonly IProductServiceClient _productService;
        private readonly ICustomerServiceClient _customerService;

        [HttpGet("{orderId}")]
        public async Task<ActionResult<OrderDetailsDto>> GetOrderDetails(Guid orderId)
        {
            // Parallel calls to multiple services
            var orderTask = _orderService.GetOrderAsync(orderId);
            var customerTask = _customerService.GetCustomerAsync(orderId);

            await Task.WhenAll(orderTask, customerTask);

            var order = await orderTask;
            var customer = await customerTask;

            // Get product details for each order line
            var productTasks = order.OrderLines
                .Select(ol => _productService.GetProductAsync(ol.ProductId))
                .ToList();

            var products = await Task.WhenAll(productTasks);

            // Compose final response
            return new OrderDetailsDto
            {
                OrderId = order.OrderId,
                OrderDate = order.OrderDate,
                Customer = customer,
                OrderLines = order.OrderLines.Select((ol, index) => new OrderLineDetailsDto
                {
                    Product = products[index],
                    Quantity = ol.Quantity,
                    UnitPrice = ol.UnitPrice,
                    LineTotal = ol.LineTotal
                }).ToList(),
                TotalAmount = order.TotalAmount
            };
        }
    }
}
```

**2. Event-Driven Data Synchronization**
```csharp
// Product Service publishes price change event
namespace ProductService.Domain
{
    public class Product
    {
        public void UpdatePrice(decimal newPrice)
        {
            var oldPrice = Price;
            Price = newPrice;

            // Publish domain event
            AddDomainEvent(new ProductPriceChangedEvent
            {
                ProductId = ProductId,
                OldPrice = oldPrice,
                NewPrice = newPrice,
                ChangedAt = DateTime.UtcNow
            });
        }
    }
}

// Order Service subscribes to price change events
namespace OrderService.EventHandlers
{
    public class ProductPriceChangedEventHandler : IEventHandler<ProductPriceChangedEvent>
    {
        private readonly OrderDbContext _dbContext;

        public async Task Handle(ProductPriceChangedEvent @event)
        {
            // Update denormalized product price in pending orders
            var pendingOrders = await _dbContext.OrderLines
                .Where(ol => ol.ProductId == @event.ProductId
                          && ol.Order.Status == OrderStatus.Pending)
                .ToListAsync();

            foreach (var orderLine in pendingOrders)
            {
                orderLine.UnitPrice = @event.NewPrice;
                orderLine.LineTotal = orderLine.Quantity * @event.NewPrice;
            }

            await _dbContext.SaveChangesAsync();
        }
    }
}
```

**3. CQRS with Materialized Views**
```csharp
// Read model database (denormalized for queries)
namespace OrderService.ReadModels
{
    public class OrderSummaryReadModel
    {
        public Guid OrderId { get; set; }
        public DateTime OrderDate { get; set; }

        // Denormalized customer data
        public Guid CustomerId { get; set; }
        public string CustomerName { get; set; }
        public string CustomerEmail { get; set; }

        // Denormalized product data
        public string ProductNames { get; set; }  // "Product A, Product B"

        public decimal TotalAmount { get; set; }
        public string Status { get; set; }
    }

    public class OrderReadModelUpdater : IEventHandler<OrderCreatedEvent>
    {
        private readonly IMongoCollection<OrderSummaryReadModel> _readModels;

        public async Task Handle(OrderCreatedEvent @event)
        {
            // Create optimized read model
            var readModel = new OrderSummaryReadModel
            {
                OrderId = @event.OrderId,
                OrderDate = @event.OrderDate,
                CustomerId = @event.CustomerId,
                CustomerName = @event.CustomerName,
                CustomerEmail = @event.CustomerEmail,
                ProductNames = string.Join(", ", @event.OrderLines.Select(ol => ol.ProductName)),
                TotalAmount = @event.TotalAmount,
                Status = @event.Status
            };

            await _readModels.InsertOneAsync(readModel);
        }
    }
}
```

**Challenges and Solutions:**

| Challenge | Solution |
|-----------|----------|
| **Joins across databases** | API Composition or CQRS with materialized views |
| **Distributed transactions** | Saga pattern or Event Sourcing |
| **Data consistency** | Eventual consistency with events |
| **Querying across services** | API Gateway aggregation or dedicated Query Service |
| **Data duplication** | Accept controlled denormalization |
| **Schema changes** | Versioned APIs and backward compatibility |

**Database Technology Selection:**

```csharp
// Configuration for different database types
namespace ServiceConfiguration
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            // Order Service: SQL Server (ACID transactions)
            services.AddDbContext<OrderDbContext>(options =>
                options.UseSqlServer(Configuration.GetConnectionString("OrderDb")));

            // Product Service: MongoDB (flexible schema, fast reads)
            services.AddSingleton<IMongoClient>(sp =>
            {
                var settings = MongoClientSettings.FromConnectionString(
                    Configuration.GetConnectionString("ProductDb")
                );
                return new MongoClient(settings);
            });

            // Inventory Service: Redis (in-memory, high performance)
            services.AddSingleton<IConnectionMultiplexer>(sp =>
                ConnectionMultiplexer.Connect(Configuration.GetConnectionString("InventoryCache")));

            // Search Service: Elasticsearch (full-text search)
            services.AddSingleton<IElasticClient>(sp =>
            {
                var settings = new ConnectionSettings(new Uri(Configuration["Elasticsearch:Url"]))
                    .DefaultIndex("products");
                return new ElasticClient(settings);
            });
        }
    }
}
```

**Real-World Scenario:**

An e-commerce platform uses Database per Service:
- **Order Service**: SQL Server for transactional integrity
- **Product Catalog**: MongoDB for flexible product attributes
- **Inventory**: Redis for real-time stock updates
- **Search**: Elasticsearch for fast product search
- **Analytics**: PostgreSQL with TimescaleDB for time-series data

**Best Practices:**

1. **Choose Right Database**: Match database type to service requirements
2. **Embrace Eventual Consistency**: Accept that data won't be immediately consistent
3. **Denormalize Thoughtfully**: Store copies of frequently accessed data
4. **Use Events for Sync**: Keep denormalized data updated via events
5. **Implement Idempotency**: Handle duplicate events gracefully
6. **Version Your Schema**: Support backward compatibility
7. **Monitor Data Drift**: Detect and correct inconsistencies
8. **Backup Strategy**: Each service needs its own backup plan
9. **Data Privacy**: Respect data boundaries for compliance
10. **Consider Query Needs**: Design read models for common queries

---

## Q144: What are distributed transactions and how do you handle them in microservices?

**Answer:**

**Distributed Transactions** occur when a single business operation spans multiple microservices, each with its own database. Traditional ACID transactions don't work across service boundaries, creating challenges for data consistency.

**The Problem:**

```
Traditional Monolith with ACID Transaction:
┌──────────────────────────────────────┐
│  BEGIN TRANSACTION                   │
│  1. Create Order                     │
│  2. Deduct Inventory                 │
│  3. Process Payment                  │
│  4. COMMIT or ROLLBACK               │
└──────────────────────────────────────┘
✓ All-or-nothing guarantee

Microservices Challenge:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Order     │  │  Inventory  │  │  Payment    │
│  Service    │  │   Service   │  │  Service    │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                 │
   ┌───▼────┐      ┌───▼────┐       ┌───▼────┐
   │Order DB│      │Inv. DB │       │Pay. DB │
   └────────┘      └────────┘       └────────┘

✗ Can't use single database transaction
✗ Network failures between services
✗ Partial failures possible
```

**Solutions for Distributed Transactions:**

### **1. Saga Pattern (Choreography)**

```csharp
// Event-driven approach - services react to events

// ORDER SERVICE: Initiates the saga
namespace OrderService
{
    public class CreateOrderCommandHandler
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task<OrderDto> Handle(CreateOrderCommand command)
        {
            // Step 1: Create order in PENDING state
            var order = new Order
            {
                OrderId = Guid.NewGuid(),
                CustomerId = command.CustomerId,
                Status = OrderStatus.Pending,
                TotalAmount = command.TotalAmount
            };

            await _repository.AddAsync(order);
            await _repository.SaveChangesAsync();

            // Publish event to trigger next step
            await _eventBus.PublishAsync(new OrderCreatedEvent
            {
                OrderId = order.OrderId,
                CustomerId = command.CustomerId,
                ProductId = command.ProductId,
                Quantity = command.Quantity,
                TotalAmount = command.TotalAmount
            });

            return MapToDto(order);
        }
    }

    // Compensation handler if saga fails
    public class InventoryReservationFailedHandler : IEventHandler<InventoryReservationFailedEvent>
    {
        private readonly IOrderRepository _repository;

        public async Task Handle(InventoryReservationFailedEvent @event)
        {
            // Compensate: Cancel the order
            var order = await _repository.GetByIdAsync(@event.OrderId);
            order.Cancel("Insufficient inventory");
            await _repository.SaveChangesAsync();
        }
    }
}

// INVENTORY SERVICE: Second step in saga
namespace InventoryService
{
    public class OrderCreatedEventHandler : IEventHandler<OrderCreatedEvent>
    {
        private readonly IInventoryRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task Handle(OrderCreatedEvent @event)
        {
            // Step 2: Reserve inventory
            var success = await _repository.ReserveStockAsync(
                @event.ProductId,
                @event.Quantity
            );

            if (success)
            {
                // Publish success event
                await _eventBus.PublishAsync(new InventoryReservedEvent
                {
                    OrderId = @event.OrderId,
                    ProductId = @event.ProductId,
                    Quantity = @event.Quantity,
                    ReservationId = Guid.NewGuid()
                });
            }
            else
            {
                // Publish failure event (triggers compensation)
                await _eventBus.PublishAsync(new InventoryReservationFailedEvent
                {
                    OrderId = @event.OrderId,
                    ProductId = @event.ProductId,
                    Reason = "Insufficient stock"
                });
            }
        }
    }

    // Compensation: Release reservation if payment fails
    public class PaymentFailedEventHandler : IEventHandler<PaymentFailedEvent>
    {
        private readonly IInventoryRepository _repository;

        public async Task Handle(PaymentFailedEvent @event)
        {
            // Compensate: Release reserved inventory
            await _repository.ReleaseReservationAsync(@event.ReservationId);
        }
    }
}

// PAYMENT SERVICE: Final step in saga
namespace PaymentService
{
    public class InventoryReservedEventHandler : IEventHandler<InventoryReservedEvent>
    {
        private readonly IPaymentProcessor _paymentProcessor;
        private readonly IEventBus _eventBus;

        public async Task Handle(InventoryReservedEvent @event)
        {
            // Step 3: Process payment
            var paymentResult = await _paymentProcessor.ProcessPaymentAsync(
                @event.OrderId,
                @event.TotalAmount
            );

            if (paymentResult.Success)
            {
                await _eventBus.PublishAsync(new PaymentCompletedEvent
                {
                    OrderId = @event.OrderId,
                    TransactionId = paymentResult.TransactionId
                });
            }
            else
            {
                await _eventBus.PublishAsync(new PaymentFailedEvent
                {
                    OrderId = @event.OrderId,
                    ReservationId = @event.ReservationId,
                    Reason = paymentResult.ErrorMessage
                });
            }
        }
    }
}

// ORDER SERVICE: Complete the saga
namespace OrderService
{
    public class PaymentCompletedEventHandler : IEventHandler<PaymentCompletedEvent>
    {
        private readonly IOrderRepository _repository;

        public async Task Handle(PaymentCompletedEvent @event)
        {
            // Saga completed successfully
            var order = await _repository.GetByIdAsync(@event.OrderId);
            order.Confirm(@event.TransactionId);
            await _repository.SaveChangesAsync();
        }
    }
}
```

**Saga Flow Visualization:**

```
HAPPY PATH (Success):
Order Service    Inventory Service    Payment Service
     │                  │                   │
     │──OrderCreated──►│                   │
     │                  │                   │
     │                  │──InventoryReserved►│
     │                  │                   │
     │◄────────PaymentCompleted─────────────│
     │                  │                   │
   [Confirm Order]      │                   │

FAILURE PATH (Compensation):
Order Service    Inventory Service    Payment Service
     │                  │                   │
     │──OrderCreated──►│                   │
     │                  │                   │
     │◄─InventoryReservationFailed          │
     │                  │                   │
   [Cancel Order]       │                   │

OR

Order Service    Inventory Service    Payment Service
     │                  │                   │
     │──OrderCreated──►│                   │
     │                  │                   │
     │                  │──InventoryReserved►│
     │                  │                   │
     │◄────────PaymentFailed────────────────│
     │                  │                   │
   [Cancel Order]  [Release Stock]          │
```

### **2. Saga Pattern (Orchestration)**

```csharp
// Centralized orchestrator coordinates the saga

namespace OrderService.Sagas
{
    public class CreateOrderSaga
    {
        public Guid SagaId { get; set; }
        public Guid OrderId { get; set; }
        public SagaState State { get; set; }
        public CreateOrderData Data { get; set; }
        public List<SagaStep> CompletedSteps { get; set; }
    }

    public enum SagaState
    {
        Started,
        InventoryReserved,
        PaymentProcessed,
        Completed,
        Failed,
        Compensating,
        Compensated
    }

    public class CreateOrderSagaOrchestrator
    {
        private readonly IOrderServiceClient _orderService;
        private readonly IInventoryServiceClient _inventoryService;
        private readonly IPaymentServiceClient _paymentService;
        private readonly ISagaRepository _sagaRepository;

        public async Task<SagaResult> ExecuteSagaAsync(CreateOrderCommand command)
        {
            // Create saga instance
            var saga = new CreateOrderSaga
            {
                SagaId = Guid.NewGuid(),
                State = SagaState.Started,
                Data = new CreateOrderData
                {
                    CustomerId = command.CustomerId,
                    ProductId = command.ProductId,
                    Quantity = command.Quantity,
                    TotalAmount = command.TotalAmount
                },
                CompletedSteps = new List<SagaStep>()
            };

            await _sagaRepository.SaveAsync(saga);

            try
            {
                // Step 1: Create Order
                var orderResult = await _orderService.CreateOrderAsync(new CreateOrderRequest
                {
                    CustomerId = saga.Data.CustomerId,
                    TotalAmount = saga.Data.TotalAmount
                });

                saga.OrderId = orderResult.OrderId;
                saga.CompletedSteps.Add(SagaStep.OrderCreated);
                await _sagaRepository.UpdateAsync(saga);

                // Step 2: Reserve Inventory
                var inventoryResult = await _inventoryService.ReserveStockAsync(new ReserveStockRequest
                {
                    ProductId = saga.Data.ProductId,
                    Quantity = saga.Data.Quantity
                });

                if (!inventoryResult.Success)
                {
                    saga.State = SagaState.Failed;
                    await _sagaRepository.UpdateAsync(saga);
                    await CompensateAsync(saga);
                    return SagaResult.Failure("Inventory reservation failed");
                }

                saga.Data.ReservationId = inventoryResult.ReservationId;
                saga.State = SagaState.InventoryReserved;
                saga.CompletedSteps.Add(SagaStep.InventoryReserved);
                await _sagaRepository.UpdateAsync(saga);

                // Step 3: Process Payment
                var paymentResult = await _paymentService.ProcessPaymentAsync(new ProcessPaymentRequest
                {
                    OrderId = saga.OrderId,
                    Amount = saga.Data.TotalAmount,
                    CustomerId = saga.Data.CustomerId
                });

                if (!paymentResult.Success)
                {
                    saga.State = SagaState.Failed;
                    await _sagaRepository.UpdateAsync(saga);
                    await CompensateAsync(saga);
                    return SagaResult.Failure("Payment processing failed");
                }

                saga.Data.TransactionId = paymentResult.TransactionId;
                saga.State = SagaState.PaymentProcessed;
                saga.CompletedSteps.Add(SagaStep.PaymentProcessed);
                await _sagaRepository.UpdateAsync(saga);

                // Step 4: Confirm Order
                await _orderService.ConfirmOrderAsync(saga.OrderId, saga.Data.TransactionId);

                saga.State = SagaState.Completed;
                await _sagaRepository.UpdateAsync(saga);

                return SagaResult.Success(saga.OrderId);
            }
            catch (Exception ex)
            {
                saga.State = SagaState.Failed;
                await _sagaRepository.UpdateAsync(saga);
                await CompensateAsync(saga);
                return SagaResult.Failure($"Saga failed: {ex.Message}");
            }
        }

        private async Task CompensateAsync(CreateOrderSaga saga)
        {
            saga.State = SagaState.Compensating;
            await _sagaRepository.UpdateAsync(saga);

            // Compensate in reverse order
            if (saga.CompletedSteps.Contains(SagaStep.PaymentProcessed))
            {
                await _paymentService.RefundPaymentAsync(saga.Data.TransactionId);
            }

            if (saga.CompletedSteps.Contains(SagaStep.InventoryReserved))
            {
                await _inventoryService.ReleaseReservationAsync(saga.Data.ReservationId);
            }

            if (saga.CompletedSteps.Contains(SagaStep.OrderCreated))
            {
                await _orderService.CancelOrderAsync(saga.OrderId);
            }

            saga.State = SagaState.Compensated;
            await _sagaRepository.UpdateAsync(saga);
        }
    }
}
```

### **3. Two-Phase Commit (2PC) - Not Recommended for Microservices**

```csharp
// Avoid this pattern in microservices due to tight coupling and blocking

namespace LegacyApproach
{
    public class TwoPhaseCommitCoordinator
    {
        // PHASE 1: Prepare
        public async Task<bool> PreparePhase(Guid transactionId)
        {
            var participants = new[]
            {
                _orderService,
                _inventoryService,
                _paymentService
            };

            var prepareResults = new List<bool>();

            foreach (var participant in participants)
            {
                // Each participant prepares but doesn't commit
                var canCommit = await participant.PrepareAsync(transactionId);
                prepareResults.Add(canCommit);

                if (!canCommit)
                {
                    // If any participant can't commit, abort all
                    await AbortAllParticipantsAsync(transactionId);
                    return false;
                }
            }

            return prepareResults.All(r => r);
        }

        // PHASE 2: Commit or Abort
        public async Task CommitPhase(Guid transactionId, bool shouldCommit)
        {
            var participants = new[]
            {
                _orderService,
                _inventoryService,
                _paymentService
            };

            if (shouldCommit)
            {
                foreach (var participant in participants)
                {
                    await participant.CommitAsync(transactionId);
                }
            }
            else
            {
                foreach (var participant in participants)
                {
                    await participant.AbortAsync(transactionId);
                }
            }
        }
    }

    // ❌ Problems with 2PC in Microservices:
    // 1. Blocking: Participants hold locks during prepare phase
    // 2. Single point of failure: Coordinator failure blocks all
    // 3. Performance: Synchronous, slow
    // 4. Scalability: Doesn't scale well
    // 5. Availability: Reduces system availability
}
```

### **4. Outbox Pattern (for Reliable Event Publishing)**

```csharp
// Ensures events are published reliably with database updates

namespace OrderService
{
    public class OrderDbContext : DbContext
    {
        public DbSet<Order> Orders { get; set; }
        public DbSet<OutboxMessage> OutboxMessages { get; set; }
    }

    public class OutboxMessage
    {
        public Guid Id { get; set; }
        public string EventType { get; set; }
        public string Payload { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public bool IsProcessed { get; set; }
    }

    public class CreateOrderCommandHandler
    {
        private readonly OrderDbContext _dbContext;

        public async Task<OrderDto> Handle(CreateOrderCommand command)
        {
            // Single local transaction
            using var transaction = await _dbContext.Database.BeginTransactionAsync();

            try
            {
                // 1. Create order
                var order = new Order
                {
                    OrderId = Guid.NewGuid(),
                    CustomerId = command.CustomerId,
                    TotalAmount = command.TotalAmount,
                    Status = OrderStatus.Pending
                };

                _dbContext.Orders.Add(order);

                // 2. Save event to outbox table (same transaction)
                var outboxMessage = new OutboxMessage
                {
                    Id = Guid.NewGuid(),
                    EventType = nameof(OrderCreatedEvent),
                    Payload = JsonSerializer.Serialize(new OrderCreatedEvent
                    {
                        OrderId = order.OrderId,
                        CustomerId = order.CustomerId,
                        TotalAmount = order.TotalAmount
                    }),
                    CreatedAt = DateTime.UtcNow,
                    IsProcessed = false
                };

                _dbContext.OutboxMessages.Add(outboxMessage);

                // 3. Commit transaction (both order and event saved atomically)
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();

                return MapToDto(order);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }

    // Background service publishes events from outbox
    public class OutboxPublisherService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IEventBus _eventBus;

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<OrderDbContext>();

                // Get unpublished messages
                var messages = await dbContext.OutboxMessages
                    .Where(m => !m.IsProcessed)
                    .OrderBy(m => m.CreatedAt)
                    .Take(100)
                    .ToListAsync(stoppingToken);

                foreach (var message in messages)
                {
                    try
                    {
                        // Publish event
                        var eventData = JsonSerializer.Deserialize(message.Payload, Type.GetType(message.EventType));
                        await _eventBus.PublishAsync(eventData);

                        // Mark as processed
                        message.IsProcessed = true;
                        message.ProcessedAt = DateTime.UtcNow;
                    }
                    catch (Exception ex)
                    {
                        // Log error, retry later
                        _logger.LogError(ex, "Failed to publish outbox message {MessageId}", message.Id);
                    }
                }

                await dbContext.SaveChangesAsync(stoppingToken);
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }
}
```

**Comparison of Approaches:**

| Approach | Consistency | Complexity | Performance | Scalability | Recommended? |
|----------|-------------|------------|-------------|-------------|--------------|
| **Saga (Choreography)** | Eventual | Medium | High | High | ✅ Yes |
| **Saga (Orchestration)** | Eventual | Medium-High | Medium | Medium-High | ✅ Yes |
| **2PC** | Strong | High | Low | Low | ❌ No |
| **Outbox Pattern** | Eventual | Medium | High | High | ✅ Yes (with Saga) |
| **Best Effort** | Weak | Low | High | High | ⚠️ Simple cases only |

**Real-World Scenario:**

An e-commerce order processing system uses **Saga (Choreography) + Outbox Pattern**:

1. Customer places order
2. Order Service creates order and publishes `OrderCreatedEvent` via outbox
3. Inventory Service reserves stock, publishes `InventoryReservedEvent`
4. Payment Service processes payment, publishes `PaymentCompletedEvent`
5. Order Service confirms order
6. If any step fails, compensation events trigger rollback

**Best Practices:**

1. **Use Sagas**: Prefer saga pattern over 2PC for microservices
2. **Implement Idempotency**: Handle duplicate messages gracefully
3. **Design Compensations**: Every step must have a compensation action
4. **Use Outbox Pattern**: Ensure reliable event publishing
5. **Monitor Saga State**: Track saga progress and failures
6. **Set Timeouts**: Handle stuck sagas with timeouts
7. **Log Everything**: Distributed tracing is essential
8. **Accept Eventual Consistency**: Embrace the microservices reality
9. **Handle Failures Gracefully**: Design for partial failures
10. **Test Compensation Logic**: Regularly test failure scenarios

---

## Q145: Explain Saga pattern with Choreography vs Orchestration approaches.

**Answer:**

The **Saga Pattern** is a way to manage distributed transactions in microservices by breaking them into a series of local transactions, with compensation logic to handle failures. There are two main implementation approaches: **Choreography** and **Orchestration**.

**Visual Comparison:**

```
CHOREOGRAPHY (Event-Driven, Decentralized):
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Order     │     │  Inventory  │     │  Payment    │
│  Service    │────►│   Service   │────►│  Service    │
└─────────────┘     └─────────────┘     └─────────────┘
  │publishes│         │publishes│         │publishes│
  │  event  │         │  event  │         │  event  │
  └─────────┘         └─────────┘         └─────────┘
       ▲                   ▲                   ▲
       │                   │                   │
    [Each service decides what to do based on events]

ORCHESTRATION (Command-Driven, Centralized):
                ┌──────────────────┐
                │ Saga Orchestrator│
                └────────┬─────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
   ┌─────────┐     ┌──────────┐    ┌─────────┐
   │  Order  │     │Inventory │    │ Payment │
   │ Service │     │ Service  │    │ Service │
   └─────────┘     └──────────┘    └─────────┘

   [Orchestrator tells each service what to do]
```

### **Approach 1: Choreography (Event-Driven)**

Each service publishes events and subscribes to events from other services. Services decide independently what to do when they receive an event.

**Implementation:**

```csharp
// ORDER SERVICE
namespace OrderService
{
    public class CreateOrderCommandHandler
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task<Guid> Handle(CreateOrderCommand command)
        {
            var order = new Order
            {
                OrderId = Guid.NewGuid(),
                CustomerId = command.CustomerId,
                Status = OrderStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            order.AddLine(command.ProductId, command.Quantity, command.UnitPrice);

            await _repository.AddAsync(order);
            await _repository.SaveChangesAsync();

            // Publish event - next service will react
            await _eventBus.PublishAsync(new OrderCreatedEvent
            {
                EventId = Guid.NewGuid(),
                OrderId = order.OrderId,
                CustomerId = command.CustomerId,
                ProductId = command.ProductId,
                Quantity = command.Quantity,
                TotalAmount = order.TotalAmount,
                Timestamp = DateTime.UtcNow
            });

            return order.OrderId;
        }
    }

    // Listens for inventory events
    public class InventoryReservedEventHandler : IEventHandler<InventoryReservedEvent>
    {
        private readonly IOrderRepository _repository;

        public async Task Handle(InventoryReservedEvent @event)
        {
            var order = await _repository.GetByIdAsync(@event.OrderId);
            order.InventoryReserved(@event.ReservationId);
            await _repository.SaveChangesAsync();

            // Order service doesn't tell payment service what to do
            // Payment service listens to InventoryReservedEvent independently
        }
    }

    // Compensation: Listen for failure events
    public class InventoryReservationFailedHandler : IEventHandler<InventoryReservationFailedEvent>
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task Handle(InventoryReservationFailedEvent @event)
        {
            var order = await _repository.GetByIdAsync(@event.OrderId);
            order.Cancel(@event.Reason);
            await _repository.SaveChangesAsync();

            await _eventBus.PublishAsync(new OrderCancelledEvent
            {
                OrderId = @event.OrderId,
                Reason = @event.Reason
            });
        }
    }

    // Final step: Order confirmation
    public class PaymentCompletedEventHandler : IEventHandler<PaymentCompletedEvent>
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task Handle(PaymentCompletedEvent @event)
        {
            var order = await _repository.GetByIdAsync(@event.OrderId);
            order.Complete(@event.TransactionId);
            await _repository.SaveChangesAsync();

            await _eventBus.PublishAsync(new OrderCompletedEvent
            {
                OrderId = order.OrderId,
                CompletedAt = DateTime.UtcNow
            });
        }
    }
}

// INVENTORY SERVICE
namespace InventoryService
{
    // Reacts to OrderCreatedEvent
    public class OrderCreatedEventHandler : IEventHandler<OrderCreatedEvent>
    {
        private readonly IInventoryRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task Handle(OrderCreatedEvent @event)
        {
            var reservation = await _repository.TryReserveStockAsync(
                @event.ProductId,
                @event.Quantity
            );

            if (reservation.Success)
            {
                await _eventBus.PublishAsync(new InventoryReservedEvent
                {
                    OrderId = @event.OrderId,
                    ProductId = @event.ProductId,
                    Quantity = @event.Quantity,
                    ReservationId = reservation.ReservationId,
                    Timestamp = DateTime.UtcNow
                });
            }
            else
            {
                await _eventBus.PublishAsync(new InventoryReservationFailedEvent
                {
                    OrderId = @event.OrderId,
                    ProductId = @event.ProductId,
                    Reason = "Insufficient stock",
                    Timestamp = DateTime.UtcNow
                });
            }
        }
    }

    // Compensation: Reacts to PaymentFailedEvent
    public class PaymentFailedEventHandler : IEventHandler<PaymentFailedEvent>
    {
        private readonly IInventoryRepository _repository;

        public async Task Handle(PaymentFailedEvent @event)
        {
            // Release the reservation
            await _repository.ReleaseReservationAsync(@event.ReservationId);
        }
    }

    // Compensation: Reacts to OrderCancelledEvent
    public class OrderCancelledEventHandler : IEventHandler<OrderCancelledEvent>
    {
        private readonly IInventoryRepository _repository;

        public async Task Handle(OrderCancelledEvent @event)
        {
            // Find and release reservation for this order
            var reservation = await _repository.GetReservationByOrderIdAsync(@event.OrderId);
            if (reservation != null)
            {
                await _repository.ReleaseReservationAsync(reservation.ReservationId);
            }
        }
    }
}

// PAYMENT SERVICE
namespace PaymentService
{
    // Reacts to InventoryReservedEvent (not OrderCreatedEvent)
    public class InventoryReservedEventHandler : IEventHandler<InventoryReservedEvent>
    {
        private readonly IPaymentProcessor _processor;
        private readonly IEventBus _eventBus;

        public async Task Handle(InventoryReservedEvent @event)
        {
            var paymentResult = await _processor.ProcessPaymentAsync(
                @event.OrderId,
                @event.TotalAmount
            );

            if (paymentResult.Success)
            {
                await _eventBus.PublishAsync(new PaymentCompletedEvent
                {
                    OrderId = @event.OrderId,
                    TransactionId = paymentResult.TransactionId,
                    Amount = @event.TotalAmount,
                    Timestamp = DateTime.UtcNow
                });
            }
            else
            {
                await _eventBus.PublishAsync(new PaymentFailedEvent
                {
                    OrderId = @event.OrderId,
                    ReservationId = @event.ReservationId,
                    Reason = paymentResult.ErrorMessage,
                    Timestamp = DateTime.UtcNow
                });
            }
        }
    }
}
```

**Event Flow - Choreography:**

```
HAPPY PATH:
Time  Order Service       Inventory Service      Payment Service
│
├──► CreateOrder
│    OrderCreatedEvent ──────►
│                              ReserveStock
│                         InventoryReservedEvent ──────►
│                                                    ProcessPayment
│    ◄────────── PaymentCompletedEvent ──────────────────┘
│    CompleteOrder
│

FAILURE PATH (Insufficient Stock):
Time  Order Service       Inventory Service      Payment Service
│
├──► CreateOrder
│    OrderCreatedEvent ──────►
│                              CheckStock (FAIL)
│    ◄──── InventoryReservationFailedEvent
│    CancelOrder
│    OrderCancelledEvent ──────►
│                              (No action needed)

FAILURE PATH (Payment Failed):
Time  Order Service       Inventory Service      Payment Service
│
├──► CreateOrder
│    OrderCreatedEvent ──────►
│                              ReserveStock (OK)
│                         InventoryReservedEvent ──────►
│                                                    ProcessPayment (FAIL)
│                         ◄──── PaymentFailedEvent ────┘
│                              ReleaseReservation
│    ◄──── PaymentFailedEvent
│    CancelOrder
```

### **Approach 2: Orchestration (Command-Driven)**

A central orchestrator coordinates the saga, explicitly telling each service what to do.

**Implementation:**

```csharp
// SAGA ORCHESTRATOR
namespace OrderService.Sagas
{
    public class CreateOrderSagaState
    {
        public Guid SagaId { get; set; }
        public Guid OrderId { get; set; }
        public SagaStep CurrentStep { get; set; }
        public SagaStatus Status { get; set; }
        public CreateOrderData Data { get; set; }
        public List<CompletedStep> CompletedSteps { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }

    public enum SagaStep
    {
        NotStarted,
        OrderCreated,
        InventoryReserved,
        PaymentProcessed,
        OrderConfirmed
    }

    public enum SagaStatus
    {
        Running,
        Completed,
        Failed,
        Compensating,
        Compensated
    }

    public class CreateOrderSagaOrchestrator
    {
        private readonly ISagaStateRepository _stateRepository;
        private readonly IOrderServiceClient _orderService;
        private readonly IInventoryServiceClient _inventoryService;
        private readonly IPaymentServiceClient _paymentService;
        private readonly ILogger<CreateOrderSagaOrchestrator> _logger;

        public async Task<SagaExecutionResult> ExecuteAsync(CreateOrderCommand command)
        {
            // Initialize saga state
            var sagaState = new CreateOrderSagaState
            {
                SagaId = Guid.NewGuid(),
                CurrentStep = SagaStep.NotStarted,
                Status = SagaStatus.Running,
                Data = new CreateOrderData
                {
                    CustomerId = command.CustomerId,
                    ProductId = command.ProductId,
                    Quantity = command.Quantity,
                    TotalAmount = command.TotalAmount
                },
                CompletedSteps = new List<CompletedStep>(),
                CreatedAt = DateTime.UtcNow
            };

            await _stateRepository.SaveAsync(sagaState);

            try
            {
                // STEP 1: Create Order
                _logger.LogInformation("Saga {SagaId}: Creating order", sagaState.SagaId);
                var orderResult = await _orderService.CreateOrderAsync(new CreateOrderRequest
                {
                    CustomerId = sagaState.Data.CustomerId,
                    ProductId = sagaState.Data.ProductId,
                    Quantity = sagaState.Data.Quantity,
                    TotalAmount = sagaState.Data.TotalAmount
                });

                sagaState.OrderId = orderResult.OrderId;
                sagaState.CurrentStep = SagaStep.OrderCreated;
                sagaState.CompletedSteps.Add(new CompletedStep
                {
                    Step = SagaStep.OrderCreated,
                    CompletedAt = DateTime.UtcNow,
                    Data = new { orderResult.OrderId }
                });
                await _stateRepository.UpdateAsync(sagaState);

                // STEP 2: Reserve Inventory
                _logger.LogInformation("Saga {SagaId}: Reserving inventory for order {OrderId}",
                    sagaState.SagaId, sagaState.OrderId);

                var inventoryResult = await _inventoryService.ReserveStockAsync(new ReserveStockRequest
                {
                    OrderId = sagaState.OrderId,
                    ProductId = sagaState.Data.ProductId,
                    Quantity = sagaState.Data.Quantity
                });

                if (!inventoryResult.Success)
                {
                    _logger.LogWarning("Saga {SagaId}: Inventory reservation failed", sagaState.SagaId);
                    sagaState.Status = SagaStatus.Failed;
                    await _stateRepository.UpdateAsync(sagaState);
                    await CompensateAsync(sagaState);
                    return SagaExecutionResult.Failure("Inventory reservation failed");
                }

                sagaState.Data.ReservationId = inventoryResult.ReservationId;
                sagaState.CurrentStep = SagaStep.InventoryReserved;
                sagaState.CompletedSteps.Add(new CompletedStep
                {
                    Step = SagaStep.InventoryReserved,
                    CompletedAt = DateTime.UtcNow,
                    Data = new { inventoryResult.ReservationId }
                });
                await _stateRepository.UpdateAsync(sagaState);

                // STEP 3: Process Payment
                _logger.LogInformation("Saga {SagaId}: Processing payment for order {OrderId}",
                    sagaState.SagaId, sagaState.OrderId);

                var paymentResult = await _paymentService.ProcessPaymentAsync(new ProcessPaymentRequest
                {
                    OrderId = sagaState.OrderId,
                    Amount = sagaState.Data.TotalAmount,
                    CustomerId = sagaState.Data.CustomerId
                });

                if (!paymentResult.Success)
                {
                    _logger.LogWarning("Saga {SagaId}: Payment processing failed", sagaState.SagaId);
                    sagaState.Status = SagaStatus.Failed;
                    await _stateRepository.UpdateAsync(sagaState);
                    await CompensateAsync(sagaState);
                    return SagaExecutionResult.Failure("Payment processing failed");
                }

                sagaState.Data.TransactionId = paymentResult.TransactionId;
                sagaState.CurrentStep = SagaStep.PaymentProcessed;
                sagaState.CompletedSteps.Add(new CompletedStep
                {
                    Step = SagaStep.PaymentProcessed,
                    CompletedAt = DateTime.UtcNow,
                    Data = new { paymentResult.TransactionId }
                });
                await _stateRepository.UpdateAsync(sagaState);

                // STEP 4: Confirm Order
                _logger.LogInformation("Saga {SagaId}: Confirming order {OrderId}",
                    sagaState.SagaId, sagaState.OrderId);

                await _orderService.ConfirmOrderAsync(sagaState.OrderId, sagaState.Data.TransactionId);

                sagaState.CurrentStep = SagaStep.OrderConfirmed;
                sagaState.Status = SagaStatus.Completed;
                sagaState.CompletedAt = DateTime.UtcNow;
                await _stateRepository.UpdateAsync(sagaState);

                _logger.LogInformation("Saga {SagaId}: Completed successfully", sagaState.SagaId);
                return SagaExecutionResult.Success(sagaState.OrderId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Saga {SagaId}: Exception occurred", sagaState.SagaId);
                sagaState.Status = SagaStatus.Failed;
                await _stateRepository.UpdateAsync(sagaState);
                await CompensateAsync(sagaState);
                return SagaExecutionResult.Failure($"Saga failed: {ex.Message}");
            }
        }

        private async Task CompensateAsync(CreateOrderSagaState sagaState)
        {
            _logger.LogInformation("Saga {SagaId}: Starting compensation", sagaState.SagaId);
            sagaState.Status = SagaStatus.Compensating;
            await _stateRepository.UpdateAsync(sagaState);

            // Compensate in reverse order
            var completedSteps = sagaState.CompletedSteps.OrderByDescending(s => s.CompletedAt);

            foreach (var step in completedSteps)
            {
                try
                {
                    switch (step.Step)
                    {
                        case SagaStep.PaymentProcessed:
                            _logger.LogInformation("Saga {SagaId}: Refunding payment", sagaState.SagaId);
                            await _paymentService.RefundPaymentAsync(sagaState.Data.TransactionId);
                            break;

                        case SagaStep.InventoryReserved:
                            _logger.LogInformation("Saga {SagaId}: Releasing inventory reservation", sagaState.SagaId);
                            await _inventoryService.ReleaseReservationAsync(sagaState.Data.ReservationId);
                            break;

                        case SagaStep.OrderCreated:
                            _logger.LogInformation("Saga {SagaId}: Cancelling order", sagaState.SagaId);
                            await _orderService.CancelOrderAsync(sagaState.OrderId);
                            break;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Saga {SagaId}: Compensation failed for step {Step}",
                        sagaState.SagaId, step.Step);
                    // In production: implement retry logic or manual intervention
                }
            }

            sagaState.Status = SagaStatus.Compensated;
            sagaState.CompletedAt = DateTime.UtcNow;
            await _stateRepository.UpdateAsync(sagaState);

            _logger.LogInformation("Saga {SagaId}: Compensation completed", sagaState.SagaId);
        }
    }

    // Service clients (called by orchestrator)
    public interface IOrderServiceClient
    {
        Task<CreateOrderResult> CreateOrderAsync(CreateOrderRequest request);
        Task ConfirmOrderAsync(Guid orderId, string transactionId);
        Task CancelOrderAsync(Guid orderId);
    }

    public interface IInventoryServiceClient
    {
        Task<ReserveStockResult> ReserveStockAsync(ReserveStockRequest request);
        Task ReleaseReservationAsync(Guid reservationId);
    }

    public interface IPaymentServiceClient
    {
        Task<ProcessPaymentResult> ProcessPaymentAsync(ProcessPaymentRequest request);
        Task RefundPaymentAsync(string transactionId);
    }
}
```

**Orchestration Flow:**

```
ORCHESTRATOR controls everything:

  ┌──────────────────────────────────────────────┐
  │   Create Order Saga Orchestrator             │
  └───┬────────────┬─────────────┬───────────────┘
      │            │             │
      │ 1. CREATE  │ 2. RESERVE  │ 3. PROCESS
      │   ORDER    │   INVENTORY │   PAYMENT
      │            │             │
      ▼            ▼             ▼
  ┌────────┐  ┌──────────┐  ┌─────────┐
  │ Order  │  │Inventory │  │ Payment │
  │Service │  │ Service  │  │ Service │
  └────────┘  └──────────┘  └─────────┘
      │            │             │
      │   Result   │   Result    │   Result
      │            │             │
      └────────────┴─────────────┴──────────►
                                         Back to Orchestrator

If ANY step fails:
  Orchestrator initiates compensation in reverse order
```

**Comparison Table:**

| Aspect | Choreography | Orchestration |
|--------|--------------|---------------|
| **Control** | Decentralized (each service decides) | Centralized (orchestrator decides) |
| **Coupling** | Loose (services don't know about each other) | Tighter (services know orchestrator) |
| **Complexity** | Distributed across services | Concentrated in orchestrator |
| **Visibility** | Hard to track (distributed logs) | Easy to track (single place) |
| **Failure Handling** | Each service handles own failures | Orchestrator handles all failures |
| **Scalability** | Better (no bottleneck) | Orchestrator can be bottleneck |
| **Testing** | Harder (need to test event flows) | Easier (test orchestrator logic) |
| **Debugging** | Difficult (trace across services) | Easier (single component) |
| **Flexibility** | High (easy to add new listeners) | Lower (modify orchestrator) |
| **Transaction State** | Implicit (in events) | Explicit (in saga state) |

**When to Use Each:**

**Use Choreography When:**
- Simple workflows (3-4 services)
- Services are loosely coupled
- You want maximum scalability
- Teams own independent services
- Event-driven architecture is already in place

**Use Orchestration When:**
- Complex workflows (5+ services)
- Need clear visibility into saga state
- Workflow logic changes frequently
- Need centralized monitoring
- Compensation logic is complex
- You need to support long-running processes

**Best Practices:**

1. **Idempotency**: All operations must be idempotent (both forward and compensation)
2. **Saga State**: Persist saga state for recovery
3. **Timeouts**: Set timeouts for each step
4. **Monitoring**: Implement comprehensive logging and tracing
5. **Compensation Logic**: Design compensating transactions carefully
6. **Event Versioning**: Version your events for backward compatibility
7. **Circuit Breakers**: Protect against cascading failures
8. **Dead Letter Queues**: Handle poison messages
9. **Replay Capability**: Be able to replay failed sagas
10. **Test Failures**: Regularly test compensation paths

---



## Q146: What is the API Gateway pattern?

**Answer:**

The **API Gateway pattern** is a design pattern that provides a single entry point for all clients to access microservices. It acts as a reverse proxy that routes requests to appropriate microservices, aggregates results, and handles cross-cutting concerns.

**Visual Architecture:**

```
WITHOUT API Gateway (Direct Client-to-Service):
┌──────────┐
│  Mobile  │──────┐
│   App    │      │
└──────────┘      │
                  ├──────► Product Service
┌──────────┐      │
│   Web    │──────┤
│   App    │      │
└──────────┘      ├──────► Order Service
                  │
┌──────────┐      │
│  Desktop │──────┤
│   App    │      │
└──────────┘      ├──────► Customer Service
                  │
                  └──────► Payment Service

❌ Problems:
- Each client must know all service endpoints
- Cross-cutting concerns duplicated
- No centralized security
- Difficult to version

WITH API Gateway:
┌──────────┐      ┌────────────────────┐
│  Mobile  │─────►│                    │──┐
│   App    │      │                    │  │
└──────────┘      │                    │  ├──► Product Service
                  │   API Gateway      │  │
┌──────────┐      │                    │  ├──► Order Service
│   Web    │─────►│   - Routing        │  │
│   App    │      │   - Auth           │  ├──► Customer Service
└──────────┘      │   - Rate Limiting  │  │
                  │   - Caching        │  ├──► Payment Service
┌──────────┐      │   - Logging        │──┘
│  Desktop │─────►│   - Aggregation    │
│   App    │      │                    │
└──────────┘      └────────────────────┘

✅ Benefits:
- Single entry point
- Centralized cross-cutting concerns
- Protocol translation
- Request/Response aggregation
```

**Key Responsibilities:**

1. **Request Routing**: Routes client requests to appropriate microservices
2. **Authentication & Authorization**: Validates tokens, enforces permissions
3. **Rate Limiting**: Prevents abuse and ensures fair usage
4. **Load Balancing**: Distributes traffic across service instances
5. **Response Aggregation**: Combines responses from multiple services
6. **Protocol Translation**: HTTP to gRPC, REST to GraphQL, etc.
7. **Caching**: Caches responses to reduce backend calls
8. **Logging & Monitoring**: Centralized logging and metrics
9. **Error Handling**: Standardized error responses
10. **API Versioning**: Manages multiple API versions

**Implementation with Ocelot (ASP.NET Core):**

```csharp
// Install-Package Ocelot
// Install-Package Ocelot.Cache.CacheManager

// Program.cs
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using Ocelot.Cache.CacheManager;

var builder = WebApplication.CreateBuilder(args);

// Add Ocelot configuration
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

// Add Ocelot services
builder.Services
    .AddOcelot(builder.Configuration)
    .AddCacheManager(x =>
    {
        x.WithDictionaryHandle();
    });

// Add authentication
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = "https://your-identity-server.com";
        options.Audience = "api-gateway";
    });

// Add rate limiting
builder.Services.AddRateLimiting();

var app = builder.Build();

// Use Ocelot middleware
await app.UseOcelot();

app.Run();
```

**Ocelot Configuration (ocelot.json):**

```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/products/{id}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "product-service",
          "Port": 5001
        }
      ],
      "UpstreamPathTemplate": "/products/{id}",
      "UpstreamHttpMethod": [ "Get" ],
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer",
        "AllowedScopes": []
      },
      "RateLimitOptions": {
        "ClientWhitelist": [],
        "EnableRateLimiting": true,
        "Period": "1m",
        "PeriodTimespan": 60,
        "Limit": 100
      },
      "FileCacheOptions": {
        "TtlSeconds": 60,
        "Region": "products"
      }
    },
    {
      "DownstreamPathTemplate": "/api/orders",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "order-service",
          "Port": 5002
        }
      ],
      "UpstreamPathTemplate": "/orders",
      "UpstreamHttpMethod": [ "Get", "Post" ],
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer"
      },
      "LoadBalancerOptions": {
        "Type": "RoundRobin"
      }
    },
    {
      "DownstreamPathTemplate": "/api/customers/{customerId}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "customer-service",
          "Port": 5003
        }
      ],
      "UpstreamPathTemplate": "/customers/{customerId}",
      "UpstreamHttpMethod": [ "Get", "Put" ],
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer"
      }
    },
    {
      "DownstreamPathTemplate": "/api/payments",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "payment-service",
          "Port": 5004
        }
      ],
      "UpstreamPathTemplate": "/payments",
      "UpstreamHttpMethod": [ "Post" ],
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer"
      },
      "DangerousAcceptAnyServerCertificateValidator": false
    }
  ],
  "GlobalConfiguration": {
    "BaseUrl": "https://api.mycompany.com",
    "RateLimitOptions": {
      "DisableRateLimitHeaders": false,
      "QuotaExceededMessage": "Rate limit exceeded. Try again later.",
      "HttpStatusCode": 429
    },
    "QoSOptions": {
      "ExceptionsAllowedBeforeBreaking": 3,
      "DurationOfBreak": 10000,
      "TimeoutValue": 5000
    }
  }
}
```

**Custom Aggregation Handler:**

```csharp
// Aggregate data from multiple services
namespace ApiGateway.Aggregators
{
    public class OrderDetailsAggregator
    {
        private readonly IHttpClientFactory _httpClientFactory;

        public OrderDetailsAggregator(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
        }

        public async Task<OrderDetailsResponse> AggregateAsync(Guid orderId)
        {
            // Parallel calls to multiple services
            var orderTask = GetOrderAsync(orderId);
            var customerTask = GetCustomerForOrderAsync(orderId);
            var paymentsTask = GetPaymentsForOrderAsync(orderId);

            await Task.WhenAll(orderTask, customerTask, paymentsTask);

            var order = await orderTask;
            var customer = await customerTask;
            var payments = await paymentsTask;

            // Get product details for each order line
            var productTasks = order.OrderLines
                .Select(ol => GetProductAsync(ol.ProductId))
                .ToList();

            var products = await Task.WhenAll(productTasks);

            // Aggregate the response
            return new OrderDetailsResponse
            {
                OrderId = order.OrderId,
                OrderNumber = order.OrderNumber,
                OrderDate = order.OrderDate,
                Status = order.Status,
                Customer = new CustomerSummary
                {
                    CustomerId = customer.CustomerId,
                    Name = customer.Name,
                    Email = customer.Email,
                    Phone = customer.Phone
                },
                Items = order.OrderLines.Select((ol, index) => new OrderItemDetails
                {
                    ProductId = products[index].ProductId,
                    ProductName = products[index].Name,
                    ProductImage = products[index].PrimaryImageUrl,
                    Quantity = ol.Quantity,
                    UnitPrice = ol.UnitPrice,
                    LineTotal = ol.LineTotal
                }).ToList(),
                PaymentInfo = payments.Select(p => new PaymentSummary
                {
                    TransactionId = p.TransactionId,
                    Amount = p.Amount,
                    Status = p.Status,
                    PaymentDate = p.PaymentDate
                }).ToList(),
                TotalAmount = order.TotalAmount
            };
        }

        private async Task<OrderDto> GetOrderAsync(Guid orderId)
        {
            var client = _httpClientFactory.CreateClient("OrderService");
            var response = await client.GetAsync($"/api/orders/{orderId}");
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<OrderDto>();
        }

        private async Task<CustomerDto> GetCustomerForOrderAsync(Guid orderId)
        {
            var client = _httpClientFactory.CreateClient("CustomerService");
            var response = await client.GetAsync($"/api/orders/{orderId}/customer");
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<CustomerDto>();
        }

        private async Task<ProductDto> GetProductAsync(Guid productId)
        {
            var client = _httpClientFactory.CreateClient("ProductService");
            var response = await client.GetAsync($"/api/products/{productId}");
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<ProductDto>();
        }

        private async Task<List<PaymentDto>> GetPaymentsForOrderAsync(Guid orderId)
        {
            var client = _httpClientFactory.CreateClient("PaymentService");
            var response = await client.GetAsync($"/api/orders/{orderId}/payments");
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<List<PaymentDto>>();
        }
    }

    // Register aggregator
    public static class ServiceCollectionExtensions
    {
        public static IServiceCollection AddAggregators(this IServiceCollection services)
        {
            services.AddHttpClient("OrderService", client =>
            {
                client.BaseAddress = new Uri("https://order-service:5002");
            });

            services.AddHttpClient("CustomerService", client =>
            {
                client.BaseAddress = new Uri("https://customer-service:5003");
            });

            services.AddHttpClient("ProductService", client =>
            {
                client.BaseAddress = new Uri("https://product-service:5001");
            });

            services.AddHttpClient("PaymentService", client =>
            {
                client.BaseAddress = new Uri("https://payment-service:5004");
            });

            services.AddScoped<OrderDetailsAggregator>();

            return services;
        }
    }

    // Controller using aggregator
    [ApiController]
    [Route("api/order-details")]
    public class OrderDetailsController : ControllerBase
    {
        private readonly OrderDetailsAggregator _aggregator;

        public OrderDetailsController(OrderDetailsAggregator aggregator)
        {
            _aggregator = aggregator;
        }

        [HttpGet("{orderId}")]
        public async Task<ActionResult<OrderDetailsResponse>> GetOrderDetails(Guid orderId)
        {
            var orderDetails = await _aggregator.AggregateAsync(orderId);
            return Ok(orderDetails);
        }
    }
}
```

**Real-World Scenario:**

An e-commerce platform uses API Gateway to:
1. **Mobile App**: Optimized endpoints with minimal data transfer
2. **Web App**: Rich data with pagination
3. **Partner API**: Rate-limited access to product catalog
4. **Internal Tools**: Full access without rate limits

The gateway handles:
- JWT token validation
- Rate limiting (100 req/min for free tier, 1000 req/min for premium)
- Response caching for product catalog (TTL: 5 minutes)
- Request aggregation (order details from 4 services)
- Protocol translation (REST to gRPC for internal services)

**Best Practices:**

1. **Avoid Business Logic**: Keep gateway thin, no business rules
2. **Use Circuit Breakers**: Protect backend services from cascading failures
3. **Cache Strategically**: Cache frequently accessed, rarely changing data
4. **Implement Timeouts**: Set reasonable timeouts for all downstream calls
5. **Health Checks**: Monitor backend service health
6. **Versioning**: Support multiple API versions simultaneously
7. **Security**: Always validate and sanitize inputs
8. **Logging**: Comprehensive logging with correlation IDs
9. **Monitoring**: Track latency, error rates, throughput
10. **Scalability**: Deploy multiple gateway instances with load balancing

---

## Q147: Explain the Backend for Frontend (BFF) pattern.

**Answer:**

The **Backend for Frontend (BFF)** pattern creates a separate backend service for each user interface or client type (web, mobile, desktop, partners). Each BFF is tailored to the specific needs of its frontend, optimizing the data format, aggregation, and API contracts.

**Visual Architecture:**

```
WITHOUT BFF (Generic API Gateway):
┌──────────┐      ┌─────────────┐
│  Mobile  │─────►│             │
│   App    │      │   Generic   │──► Microservices
└──────────┘      │ API Gateway │
                  │             │
┌──────────┐      │ (One size   │
│   Web    │─────►│  fits all)  │
│   App    │      │             │
└──────────┘      └─────────────┘

Problems:
- Mobile needs compact JSON, web needs rich data
- Mobile wants aggregated endpoints, web prefers granular
- Different authentication requirements
- Over-fetching or under-fetching data

WITH BFF Pattern:
┌──────────┐      ┌─────────────┐
│  Mobile  │─────►│  Mobile BFF │──► Microservices
│   App    │      │(Optimized   │    (Product, Order,
└──────────┘      │ for mobile) │     Customer, etc.)
                  └─────────────┘
┌──────────┐      ┌─────────────┐
│   Web    │─────►│   Web BFF   │──► Microservices
│   App    │      │(Optimized   │
└──────────┘      │  for web)   │
                  └─────────────┘
┌──────────┐      ┌─────────────┐
│ Partner  │─────►│ Partner BFF │──► Microservices
│   API    │      │(Optimized   │
└──────────┘      │for partners)│
                  └─────────────┘

Benefits:
✓ Each frontend gets exactly what it needs
✓ Optimized data formats per platform
✓ Independent evolution of each BFF
✓ Reduced client complexity
```

**BFF Pattern Comparison:**

| Aspect | Mobile BFF | Web BFF | Partner API BFF |
|--------|-----------|---------|-----------------|
| **Data Format** | Compact JSON | Rich, detailed | Business-focused |
| **Page Size** | 15-20 items | 50-100 items | 100-500 items |
| **Aggregation** | Heavy (reduce calls) | Moderate | Minimal |
| **Caching** | Aggressive | Moderate | Light |
| **Authentication** | JWT (OAuth2) | JWT + Session | API Key |
| **Rate Limiting** | 100 req/min | 1000 req/min | 60 req/min (varies by tier) |
| **Image Quality** | Thumbnails | Full resolution | No images |

**Real-World Scenario:**

An e-commerce platform has three BFFs:

1. **Mobile BFF**:
   - Returns product lists with only 1 image per product
   - Aggregates reviews, ratings, and stock in single endpoint
   - Implements aggressive caching (5-minute TTL)
   - Optimized for 3G/4G networks

2. **Web BFF**:
   - Returns full product details with all images
   - Provides granular endpoints for SPA lazy loading
   - Includes SEO metadata for server-side rendering
   - Supports advanced filtering and sorting

3. **Partner BFF**:
   - Exposes wholesale pricing (hidden from public)
   - Rate-limited per partner tier
   - Supports bulk operations (1000 products per request)
   - Webhook notifications for stock updates

**Best Practices:**

1. **Avoid Code Duplication**: Share common logic via libraries, but keep BFFs independent
2. **Keep BFFs Thin**: Aggregation and transformation only, no business logic
3. **Team Ownership**: Frontend team should own their BFF
4. **Independent Deployment**: Each BFF deploys independently
5. **Monitoring**: Track performance per BFF to identify platform-specific issues
6. **Versioning**: Support multiple versions for gradual client upgrades
7. **Feature Flags**: Control feature rollout per platform
8. **Caching Strategy**: Different caching per platform (mobile: aggressive, partner: minimal)

---

## Q148: What is Service Discovery and why is it needed?

**Answer:**

**Service Discovery** is a mechanism that enables microservices to automatically find and communicate with each other without hardcoding network locations. As service instances are dynamically created, destroyed, and moved (especially in containerized environments), service discovery maintains an up-to-date registry of available service instances.

**The Problem Without Service Discovery:**

```
Traditional Approach (Hardcoded URLs):
┌──────────────┐
│ Order Service│ client.BaseAddress = "https://inventory-service:5001"
└──────┬───────┘
       │ Hardcoded!
       ▼
┌──────────────┐
│  Inventory   │  Running on server1:5001
│   Service    │
└──────────────┘

❌ Problems:
1. What if Inventory Service moves to a different server?
2. What if we scale to 3 instances? Which one to call?
3. What if an instance fails? How do we know?
4. Manual configuration management nightmare
```

**With Service Discovery:**

```
Service Discovery Pattern:
┌──────────────┐       ┌─────────────────┐
│ Order Service│──────►│ Service Registry│
└──────────────┘       │   (Consul/      │
       │               │    Eureka)      │
       │ 1. Query      └────────┬────────┘
       │    "inventory-service" │
       │                        │ 2. Returns:
       │                        │    - 192.168.1.10:5001
       │                        │    - 192.168.1.11:5001
       │                        │    - 192.168.1.12:5001
       ▼                        │
┌──────────────┐                │
│  Inventory   │◄───────────────┘
│   Service    │  3. Call healthy instance
│ (3 instances)│
└──────────────┘

✅ Benefits:
- Automatic instance discovery
- Load balancing
- Health checking
- Fault tolerance
```

**Service Discovery Patterns:**

### **1. Client-Side Discovery**

```csharp
// Client queries registry and chooses instance

namespace OrderService
{
    public class InventoryServiceClient
    {
        private readonly IServiceRegistry _serviceRegistry;
        private readonly HttpClient _httpClient;
        private readonly ILoadBalancer _loadBalancer;

        public InventoryServiceClient(
            IServiceRegistry serviceRegistry,
            HttpClient httpClient,
            ILoadBalancer loadBalancer)
        {
            _serviceRegistry = serviceRegistry;
            _httpClient = httpClient;
            _loadBalancer = loadBalancer;
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            // 1. Query service registry for all healthy instances
            var instances = await _serviceRegistry.GetServiceInstancesAsync("inventory-service");

            if (instances == null || !instances.Any())
                throw new ServiceUnavailableException("No healthy inventory service instances available");

            // 2. Client selects instance using load balancing algorithm
            var selectedInstance = _loadBalancer.SelectInstance(instances);

            // 3. Make request to selected instance
            var url = $"{selectedInstance.Uri}/api/inventory/{productId}";
            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
            return result.Quantity;
        }
    }

    // Service Registry Interface
    public interface IServiceRegistry
    {
        Task<IEnumerable<ServiceInstance>> GetServiceInstancesAsync(string serviceName);
        Task RegisterServiceAsync(ServiceRegistration registration);
        Task DeregisterServiceAsync(string serviceId);
        Task SendHeartbeatAsync(string serviceId);
    }

    public class ServiceInstance
    {
        public string ServiceId { get; set; }
        public string ServiceName { get; set; }
        public string Host { get; set; }
        public int Port { get; set; }
        public Uri Uri => new Uri($"https://{Host}:{Port}");
        public Dictionary<string, string> Metadata { get; set; }
        public HealthStatus Health { get; set; }
    }

    // Load Balancer
    public interface ILoadBalancer
    {
        ServiceInstance SelectInstance(IEnumerable<ServiceInstance> instances);
    }

    public class RoundRobinLoadBalancer : ILoadBalancer
    {
        private int _currentIndex = 0;
        private readonly object _lock = new object();

        public ServiceInstance SelectInstance(IEnumerable<ServiceInstance> instances)
        {
            var instanceList = instances.ToList();

            lock (_lock)
            {
                var instance = instanceList[_currentIndex % instanceList.Count];
                _currentIndex++;
                return instance;
            }
        }
    }

    public class RandomLoadBalancer : ILoadBalancer
    {
        private readonly Random _random = new Random();

        public ServiceInstance SelectInstance(IEnumerable<ServiceInstance> instances)
        {
            var instanceList = instances.ToList();
            var index = _random.Next(instanceList.Count);
            return instanceList[index];
        }
    }
}
```

### **2. Server-Side Discovery**

```csharp
// Load balancer queries registry and routes requests

// Client doesn't know about service registry
namespace OrderService
{
    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;

        public InventoryServiceClient(IHttpClientFactory httpClientFactory)
        {
            // Client calls load balancer, not direct service
            _httpClient = httpClientFactory.CreateClient("InventoryService");
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            // Request goes to load balancer (e.g., NGINX, HAProxy, AWS ELB)
            // Load balancer queries service registry and routes to healthy instance
            var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
            return result.Quantity;
        }
    }

    // Configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHttpClient("InventoryService", client =>
            {
                // Points to load balancer, not individual service instances
                client.BaseAddress = new Uri("http://inventory-lb.local");
            });
        }
    }
}
```

**Implementation with Consul:**

```csharp
// Install-Package Consul

// Service Registration on Startup
namespace InventoryService
{
    public class ConsulServiceRegistration : IHostedService
    {
        private readonly IConsulClient _consulClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ConsulServiceRegistration> _logger;
        private string _serviceId;

        public ConsulServiceRegistration(
            IConsulClient consulClient,
            IConfiguration configuration,
            ILogger<ConsulServiceRegistration> logger)
        {
            _consulClient = consulClient;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            var serviceName = _configuration["ServiceName"];
            var serviceHost = _configuration["ServiceHost"];
            var servicePort = int.Parse(_configuration["ServicePort"]);

            _serviceId = $"{serviceName}-{Guid.NewGuid()}";

            var registration = new AgentServiceRegistration
            {
                ID = _serviceId,
                Name = serviceName,
                Address = serviceHost,
                Port = servicePort,
                Tags = new[] { "inventory", "v1", "production" },
                Check = new AgentServiceCheck
                {
                    HTTP = $"http://{serviceHost}:{servicePort}/health",
                    Interval = TimeSpan.FromSeconds(10),
                    Timeout = TimeSpan.FromSeconds(5),
                    DeregisterCriticalServiceAfter = TimeSpan.FromMinutes(1)
                }
            };

            _logger.LogInformation("Registering service {ServiceId} with Consul", _serviceId);
            await _consulClient.Agent.ServiceRegister(registration, cancellationToken);
        }

        public async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("Deregistering service {ServiceId} from Consul", _serviceId);
            await _consulClient.Agent.ServiceDeregister(_serviceId, cancellationToken);
        }
    }

    // Consul Client Configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            // Register Consul client
            services.AddSingleton<IConsulClient>(sp => new ConsulClient(config =>
            {
                config.Address = new Uri("http://consul-server:8500");
            }));

            // Register service registration hosted service
            services.AddHostedService<ConsulServiceRegistration>();

            // Add health check endpoint
            services.AddHealthChecks()
                .AddCheck<DatabaseHealthCheck>("database")
                .AddCheck<RedisHealthCheck>("redis");
        }

        public void Configure(IApplicationBuilder app)
        {
            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapHealthChecks("/health");
                endpoints.MapControllers();
            });
        }
    }
}

// Service Discovery Client
namespace OrderService
{
    public class ConsulServiceDiscovery : IServiceRegistry
    {
        private readonly IConsulClient _consulClient;
        private readonly ILogger<ConsulServiceDiscovery> _logger;

        public ConsulServiceDiscovery(IConsulClient consulClient, ILogger<ConsulServiceDiscovery> logger)
        {
            _consulClient = consulClient;
            _logger = logger;
        }

        public async Task<IEnumerable<ServiceInstance>> GetServiceInstancesAsync(string serviceName)
        {
            _logger.LogDebug("Querying Consul for service: {ServiceName}", serviceName);

            // Query Consul for healthy instances
            var queryResult = await _consulClient.Health.Service(serviceName, tag: null, passingOnly: true);

            if (queryResult.Response == null || !queryResult.Response.Any())
            {
                _logger.LogWarning("No healthy instances found for service: {ServiceName}", serviceName);
                return Enumerable.Empty<ServiceInstance>();
            }

            var instances = queryResult.Response.Select(serviceEntry => new ServiceInstance
            {
                ServiceId = serviceEntry.Service.ID,
                ServiceName = serviceEntry.Service.Service,
                Host = serviceEntry.Service.Address,
                Port = serviceEntry.Service.Port,
                Metadata = serviceEntry.Service.Tags.ToDictionary(t => t, t => t),
                Health = MapHealthStatus(serviceEntry.Checks)
            }).ToList();

            _logger.LogInformation("Found {Count} healthy instances for service: {ServiceName}",
                instances.Count, serviceName);

            return instances;
        }

        private HealthStatus MapHealthStatus(HealthCheck[] checks)
        {
            if (checks.All(c => c.Status == HealthStatus.Passing))
                return HealthStatus.Healthy;

            if (checks.Any(c => c.Status == HealthStatus.Critical))
                return HealthStatus.Unhealthy;

            return HealthStatus.Degraded;
        }
    }
}
```

**Implementation with Kubernetes Service Discovery:**

```yaml
# Kubernetes automatically provides service discovery via DNS

# inventory-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: inventory-service
  template:
    metadata:
      labels:
        app: inventory-service
    spec:
      containers:
      - name: inventory-service
        image: myregistry/inventory-service:v1
        ports:
        - containerPort: 5001
        livenessProbe:
          httpGet:
            path: /health/live
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 5001
          initialDelaySeconds: 10
          periodSeconds: 5

---
# inventory-service-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: inventory-service
spec:
  selector:
    app: inventory-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5001
  type: ClusterIP
```

```csharp
// Order Service calls inventory-service by DNS name
namespace OrderService
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHttpClient("InventoryService", client =>
            {
                // Kubernetes DNS: <service-name>.<namespace>.svc.cluster.local
                client.BaseAddress = new Uri("http://inventory-service.default.svc.cluster.local");
            });
        }
    }

    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;

        public InventoryServiceClient(IHttpClientFactory httpClientFactory)
        {
            _httpClient = httpClientFactory.CreateClient("InventoryService");
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            // Kubernetes Service provides load balancing automatically
            var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
            return result.Quantity;
        }
    }
}
```

**Health Checks Implementation:**

```csharp
// Comprehensive health checks for service discovery
namespace InventoryService
{
    public class DatabaseHealthCheck : IHealthCheck
    {
        private readonly InventoryDbContext _dbContext;

        public DatabaseHealthCheck(InventoryDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            try
            {
                await _dbContext.Database.CanConnectAsync(cancellationToken);
                return HealthCheckResult.Healthy("Database connection is healthy");
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Unhealthy("Database connection failed", ex);
            }
        }
    }

    public class RedisHealthCheck : IHealthCheck
    {
        private readonly IConnectionMultiplexer _redis;

        public RedisHealthCheck(IConnectionMultiplexer redis)
        {
            _redis = redis;
        }

        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var db = _redis.GetDatabase();
                await db.PingAsync();
                return HealthCheckResult.Healthy("Redis connection is healthy");
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Degraded("Redis connection degraded", ex);
            }
        }
    }

    // Startup configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHealthChecks()
                .AddCheck<DatabaseHealthCheck>("database", tags: new[] { "ready" })
                .AddCheck<RedisHealthCheck>("redis", tags: new[] { "ready" })
                .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" });
        }

        public void Configure(IApplicationBuilder app)
        {
            app.UseEndpoints(endpoints =>
            {
                // Liveness probe: Is the service running?
                endpoints.MapHealthChecks("/health/live", new HealthCheckOptions
                {
                    Predicate = check => check.Tags.Contains("live")
                });

                // Readiness probe: Is the service ready to accept traffic?
                endpoints.MapHealthChecks("/health/ready", new HealthCheckOptions
                {
                    Predicate = check => check.Tags.Contains("ready")
                });

                // Full health check
                endpoints.MapHealthChecks("/health", new HealthCheckOptions
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
                            })
                        });
                        await context.Response.WriteAsync(result);
                    }
                });
            });
        }
    }
}
```

**Comparison of Service Discovery Tools:**

| Tool | Type | Features | Best For |
|------|------|----------|----------|
| **Consul** | Client/Server | Service registry, health checks, KV store, DNS | General purpose, multi-cloud |
| **Eureka (Netflix)** | Client/Server | Service registry, health checks | Spring Boot, Netflix OSS stack |
| **Kubernetes** | Platform | Built-in DNS-based discovery | Container orchestration |
| **Zookeeper** | Centralized | Configuration, naming, synchronization | Distributed coordination |
| **etcd** | Distributed KV | Service registry, configuration | Kubernetes backend, CoreOS |

**Real-World Scenario:**

An e-commerce platform running on Kubernetes uses service discovery:

1. **Service Registry**: Kubernetes DNS automatically registers all services
2. **Load Balancing**: Kubernetes Service provides round-robin load balancing
3. **Health Checks**: Each service has liveness and readiness probes
4. **Dynamic Scaling**: As traffic increases, Kubernetes scales Inventory Service from 3 to 10 pods
5. **Automatic Updates**: Order Service automatically discovers new Inventory Service instances

**Best Practices:**

1. **Implement Health Checks**: Distinguish between liveness and readiness
2. **Graceful Shutdown**: Deregister from service registry before shutting down
3. **Retry Logic**: Handle temporary service unavailability
4. **Circuit Breakers**: Protect against cascading failures
5. **Caching**: Cache service locations with TTL
6. **Heartbeats**: Send regular heartbeats to prove liveness
7. **Metadata**: Include version, region, environment in registration
8. **Monitoring**: Track service registration/deregistration events
9. **Security**: Secure service registry access
10. **Fallbacks**: Have fallback strategies when service registry is unavailable

---

## Q149: Explain the Circuit Breaker pattern.

**Answer:**

The **Circuit Breaker pattern** prevents an application from repeatedly trying to execute an operation that is likely to fail, allowing it to continue without waiting for the fault to be fixed or wasting resources. It protects microservices from cascading failures.

**Visual Representation:**

```
Circuit Breaker States:

┌─────────────────┐
│     CLOSED      │  Normal operation
│  (All requests  │  Success count: OK
│   pass through) │  Failure threshold not reached
└────────┬────────┘
         │
         │ Failure threshold exceeded
         │ (e.g., 5 failures in 10 seconds)
         ▼
┌─────────────────┐
│      OPEN       │  Fail fast
│   (Requests     │  Immediately return error
│    blocked)     │  without calling service
└────────┬────────┘
         │
         │ Timeout period elapsed
         │ (e.g., 30 seconds)
         ▼
┌─────────────────┐
│   HALF-OPEN     │  Testing
│ (Limited trial  │  Allow 1 request through
│   requests)     │  to test if service recovered
└────────┬────────┘
         │
         ├─► Success? ──► Back to CLOSED
         │
         └─► Failure? ──► Back to OPEN

Without Circuit Breaker:
Client ──► Service (down) ──► Wait...timeout (30s)
       ──► Service (down) ──► Wait...timeout (30s)
       ──► Service (down) ──► Wait...timeout (30s)
       ❌ Wastes resources, slow failures

With Circuit Breaker:
Client ──► Service (down) ──► Wait...timeout (30s)
       ──► Service (down) ──► Wait...timeout (30s)
       ──► Circuit OPENS
       ──► Immediate failure (no wait) ✅
       ──► Immediate failure (no wait) ✅
```

**Implementation with Polly Library:**

```csharp
// Install-Package Polly
// Install-Package Polly.Extensions.Http

namespace OrderService
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            // Configure HttpClient with Circuit Breaker
            services.AddHttpClient("InventoryService", client =>
            {
                client.BaseAddress = new Uri("https://inventory-service");
                client.Timeout = TimeSpan.FromSeconds(10);
            })
            .AddPolicyHandler(GetCircuitBreakerPolicy())
            .AddPolicyHandler(GetRetryPolicy());
        }

        private static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
        {
            return HttpPolicyExtensions
                .HandleTransientHttpError()  // 5xx and 408 errors
                .OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.NotFound)
                .CircuitBreakerAsync(
                    handledEventsAllowedBeforeBreaking: 5,  // Open circuit after 5 failures
                    durationOfBreak: TimeSpan.FromSeconds(30),  // Stay open for 30 seconds
                    onBreak: (outcome, timespan) =>
                    {
                        // Log when circuit opens
                        Console.WriteLine($"Circuit breaker opened for {timespan.TotalSeconds}s due to: {outcome.Exception?.Message ?? outcome.Result.StatusCode.ToString()}");
                    },
                    onReset: () =>
                    {
                        // Log when circuit closes
                        Console.WriteLine("Circuit breaker reset (closed)");
                    },
                    onHalfOpen: () =>
                    {
                        // Log when circuit enters half-open state
                        Console.WriteLine("Circuit breaker half-open, testing service...");
                    }
                );
        }

        private static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
        {
            return HttpPolicyExtensions
                .HandleTransientHttpError()
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),  // Exponential backoff
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        Console.WriteLine($"Retry {retryCount} after {timespan.TotalSeconds}s delay");
                    }
                );
        }
    }

    // Using the HttpClient with Circuit Breaker
    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<InventoryServiceClient> _logger;

        public InventoryServiceClient(IHttpClientFactory httpClientFactory, ILogger<InventoryServiceClient> logger)
        {
            _httpClient = httpClientFactory.CreateClient("InventoryService");
            _logger = logger;
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/inventory/{productId}");

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Inventory service returned {StatusCode}", response.StatusCode);
                    return 0;  // Fallback: assume out of stock
                }

                var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
                return result.Quantity;
            }
            catch (BrokenCircuitException ex)
            {
                // Circuit is open - fail fast
                _logger.LogError(ex, "Circuit breaker is open for inventory service");
                return 0;  // Fallback value
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "HTTP request to inventory service failed");
                return 0;  // Fallback value
            }
        }
    }
}
```

**Advanced Circuit Breaker with Fallback:**

```csharp
namespace OrderService
{
    public class ResilientInventoryServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly IDistributedCache _cache;
        private readonly ILogger<ResilientInventoryServiceClient> _logger;
        private readonly IAsyncPolicy<int> _circuitBreakerPolicy;

        public ResilientInventoryServiceClient(
            IHttpClientFactory httpClientFactory,
            IDistributedCache cache,
            ILogger<ResilientInventoryServiceClient> logger)
        {
            _httpClient = httpClientFactory.CreateClient("InventoryService");
            _cache = cache;
            _logger = logger;
            _circuitBreakerPolicy = CreateCircuitBreakerPolicy();
        }

        private IAsyncPolicy<int> CreateCircuitBreakerPolicy()
        {
            // Define what constitutes a failure
            var circuitBreaker = Policy<int>
                .Handle<HttpRequestException>()
                .Or<TaskCanceledException>()
                .OrResult(quantity => quantity < 0)  // Treat negative quantity as error
                .CircuitBreakerAsync(
                    handledEventsAllowedBeforeBreaking: 5,
                    durationOfBreak: TimeSpan.FromSeconds(30),
                    onBreak: (result, duration) =>
                    {
                        _logger.LogWarning(
                            "Circuit breaker opened. Will stay open for {Duration}s",
                            duration.TotalSeconds
                        );
                    },
                    onReset: () => _logger.LogInformation("Circuit breaker closed"),
                    onHalfOpen: () => _logger.LogInformation("Circuit breaker half-open")
                );

            // Combine with fallback
            var fallback = Policy<int>
                .Handle<BrokenCircuitException>()
                .Or<HttpRequestException>()
                .FallbackAsync(
                    fallbackValue: async (context, cancellationToken) =>
                    {
                        // Try to get cached value
                        var productId = context["productId"] as Guid?;
                        if (productId.HasValue)
                        {
                            var cachedValue = await GetCachedStockQuantityAsync(productId.Value);
                            if (cachedValue.HasValue)
                            {
                                _logger.LogInformation(
                                    "Using cached stock quantity for product {ProductId}",
                                    productId.Value
                                );
                                return cachedValue.Value;
                            }
                        }

                        _logger.LogWarning("Fallback: Assuming out of stock");
                        return 0;  // Ultimate fallback: assume out of stock
                    },
                    onFallbackAsync: async (result, context) =>
                    {
                        _logger.LogWarning("Executing fallback due to: {Reason}",
                            result.Exception?.Message ?? "Circuit breaker open");
                        await Task.CompletedTask;
                    }
                );

            // Wrap circuit breaker with fallback
            return fallback.WrapAsync(circuitBreaker);
        }

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            var context = new Context
            {
                ["productId"] = productId
            };

            return await _circuitBreakerPolicy.ExecuteAsync(async (ctx) =>
            {
                // Make HTTP request
                var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
                response.EnsureSuccessStatusCode();

                var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();

                // Cache successful result
                await CacheStockQuantityAsync(productId, result.Quantity);

                return result.Quantity;
            }, context);
        }

        private async Task<int?> GetCachedStockQuantityAsync(Guid productId)
        {
            var cacheKey = $"stock:{productId}";
            var cachedValue = await _cache.GetStringAsync(cacheKey);

            if (string.IsNullOrEmpty(cachedValue))
                return null;

            return int.Parse(cachedValue);
        }

        private async Task CacheStockQuantityAsync(Guid productId, int quantity)
        {
            var cacheKey = $"stock:{productId}";
            await _cache.SetStringAsync(
                cacheKey,
                quantity.ToString(),
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
                }
            );
        }
    }
}
```

**Circuit Breaker with Metrics:**

```csharp
namespace OrderService
{
    public class CircuitBreakerMetrics
    {
        private long _successCount;
        private long _failureCount;
        private long _circuitOpenCount;
        private long _fallbackCount;

        public void RecordSuccess() => Interlocked.Increment(ref _successCount);
        public void RecordFailure() => Interlocked.Increment(ref _failureCount);
        public void RecordCircuitOpen() => Interlocked.Increment(ref _circuitOpenCount);
        public void RecordFallback() => Interlocked.Increment(ref _fallbackCount);

        public CircuitBreakerStats GetStats()
        {
            return new CircuitBreakerStats
            {
                SuccessCount = Interlocked.Read(ref _successCount),
                FailureCount = Interlocked.Read(ref _failureCount),
                CircuitOpenCount = Interlocked.Read(ref _circuitOpenCount),
                FallbackCount = Interlocked.Read(ref _fallbackCount),
                SuccessRate = CalculateSuccessRate()
            };
        }

        private double CalculateSuccessRate()
        {
            var total = _successCount + _failureCount;
            if (total == 0) return 100.0;
            return (_successCount / (double)total) * 100.0;
        }
    }

    public class MonitoredInventoryServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly CircuitBreakerMetrics _metrics;
        private readonly ILogger<MonitoredInventoryServiceClient> _logger;

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            var policy = Policy
                .Handle<HttpRequestException>()
                .CircuitBreakerAsync(
                    handledEventsAllowedBeforeBreaking: 5,
                    durationOfBreak: TimeSpan.FromSeconds(30),
                    onBreak: (exception, duration) =>
                    {
                        _metrics.RecordCircuitOpen();
                        _logger.LogWarning("Circuit opened for {Duration}s", duration.TotalSeconds);
                    },
                    onReset: () =>
                    {
                        _logger.LogInformation("Circuit closed. Current stats: {@Stats}", _metrics.GetStats());
                    }
                );

            try
            {
                var result = await policy.ExecuteAsync(async () =>
                {
                    var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
                    response.EnsureSuccessStatusCode();
                    return await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
                });

                _metrics.RecordSuccess();
                return result.Quantity;
            }
            catch (BrokenCircuitException)
            {
                _metrics.RecordFallback();
                _logger.LogWarning("Circuit is open, using fallback");
                return 0;
            }
            catch (Exception ex)
            {
                _metrics.RecordFailure();
                _logger.LogError(ex, "Request failed");
                return 0;
            }
        }
    }

    // Metrics endpoint
    [ApiController]
    [Route("api/metrics")]
    public class MetricsController : ControllerBase
    {
        private readonly CircuitBreakerMetrics _metrics;

        public MetricsController(CircuitBreakerMetrics metrics)
        {
            _metrics = metrics;
        }

        [HttpGet("circuit-breaker")]
        public ActionResult<CircuitBreakerStats> GetCircuitBreakerStats()
        {
            return Ok(_metrics.GetStats());
        }
    }
}
```

**Real-World Scenario:**

An e-commerce Order Service depends on Inventory Service to check stock:

1. **Normal Operation (Circuit Closed)**:
   - Order Service → Inventory Service: 200 OK
   - Stock quantity returned successfully

2. **Inventory Service Degrades**:
   - 1st request: Timeout after 10s
   - 2nd request: Timeout after 10s
   - 3rd request: Timeout after 10s
   - 4th request: Timeout after 10s
   - 5th request: Timeout after 10s
   - **Circuit Opens!**

3. **Circuit Open (Fail Fast)**:
   - 6th request: Immediate failure (no wait)
   - 7th request: Immediate failure (no wait)
   - Order Service uses cached stock data or defaults to "out of stock"

4. **After 30 seconds (Half-Open)**:
   - 1 test request sent to Inventory Service
   - If successful: Circuit closes, normal operation resumes
   - If failure: Circuit stays open for another 30s

**Best Practices:**

1. **Set Appropriate Thresholds**: Balance between false positives and protection
2. **Monitor Circuit State**: Track open/close events and alert on anomalies
3. **Implement Fallbacks**: Provide graceful degradation (cached data, default values)
4. **Use Timeouts**: Always set request timeouts to prevent hanging
5. **Combine with Retry**: Retry transient failures, then open circuit for persistent ones
6. **Test Failure Scenarios**: Regularly test circuit breaker behavior
7. **Log Circuit Events**: Log when circuits open/close for debugging
8. **Per-Endpoint Breakers**: Use separate circuit breakers for different endpoints
9. **Adjust Based on SLA**: Configure thresholds based on service SLAs
10. **Monitor Dependencies**: Track health of all downstream dependencies

---

## Q150: What is the Retry pattern and when should you use it?

**Answer:**

The **Retry pattern** automatically retries failed operations that might succeed on subsequent attempts. It's designed to handle transient faults - temporary failures that are likely to resolve quickly.

**When to Use Retry Pattern:**

✅ **Good Use Cases:**
- Network timeouts
- Temporary service unavailability
- Database connection failures
- Rate limiting (429 Too Many Requests)
- Transient cloud service errors (503 Service Unavailable)

❌ **Don't Use For:**
- Authentication/Authorization failures (401, 403)
- Not Found errors (404)
- Bad Request errors (400)
- Business logic failures
- Permanent failures

**Implementation:**

```csharp
// Simple Retry with Polly
using Polly;

namespace OrderService
{
    public class PaymentServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<PaymentServiceClient> _logger;

        public async Task<PaymentResult> ProcessPaymentAsync(ProcessPaymentRequest request)
        {
            // Define retry policy
            var retryPolicy = Policy
                .Handle<HttpRequestException>()
                .Or<TaskCanceledException>()
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),  // 2s, 4s, 8s
                    onRetry: (exception, timespan, retryCount, context) =>
                    {
                        _logger.LogWarning(
                            exception,
                            "Retry {RetryCount} after {Delay}s delay due to: {ExceptionMessage}",
                            retryCount,
                            timespan.TotalSeconds,
                            exception.Message
                        );
                    }
                );

            // Execute with retry
            return await retryPolicy.ExecuteAsync(async () =>
            {
                var response = await _httpClient.PostAsJsonAsync("/api/payments", request);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadFromJsonAsync<PaymentResult>();
            });
        }
    }
}
```

**Advanced Retry Strategies:**

```csharp
namespace OrderService
{
    public class ResilientServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger _logger;

        // 1. Exponential Backoff with Jitter
        public IAsyncPolicy<HttpResponseMessage> GetExponentialBackoffPolicy()
        {
            var random = new Random();

            return HttpPolicyExtensions
                .HandleTransientHttpError()
                .WaitAndRetryAsync(
                    retryCount: 5,
                    sleepDurationProvider: retryAttempt =>
                    {
                        var baseDelay = TimeSpan.FromSeconds(Math.Pow(2, retryAttempt));
                        var jitter = TimeSpan.FromMilliseconds(random.Next(0, 1000));  // Add jitter
                        return baseDelay + jitter;
                    },
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        _logger.LogWarning(
                            "Retry {RetryCount} after {Delay}ms",
                            retryCount,
                            timespan.TotalMilliseconds
                        );
                    }
                );
        }

        // 2. Retry Only Specific HTTP Status Codes
        public IAsyncPolicy<HttpResponseMessage> GetSelectiveRetryPolicy()
        {
            return Policy
                .HandleResult<HttpResponseMessage>(r =>
                    r.StatusCode == HttpStatusCode.RequestTimeout ||  // 408
                    r.StatusCode == HttpStatusCode.TooManyRequests ||  // 429
                    (int)r.StatusCode >= 500)  // 5xx errors
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(retryAttempt * 2)
                );
        }

        // 3. Retry with Custom Logic
        public async Task<TResult> RetryWithCustomLogicAsync<TResult>(
            Func<Task<TResult>> operation,
            Func<TResult, bool> shouldRetry,
            int maxRetries = 3)
        {
            int attempt = 0;
            while (true)
            {
                try
                {
                    attempt++;
                    var result = await operation();

                    if (!shouldRetry(result) || attempt >= maxRetries)
                        return result;

                    var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt));
                    _logger.LogWarning(
                        "Result requires retry. Attempt {Attempt}/{MaxRetries}. Waiting {Delay}s",
                        attempt,
                        maxRetries,
                        delay.TotalSeconds
                    );

                    await Task.Delay(delay);
                }
                catch (Exception ex) when (attempt < maxRetries)
                {
                    var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt));
                    _logger.LogWarning(
                        ex,
                        "Exception on attempt {Attempt}/{MaxRetries}. Retrying after {Delay}s",
                        attempt,
                        maxRetries,
                        delay.TotalSeconds
                    );

                    await Task.Delay(delay);
                }
            }
        }

        // 4. Retry with Circuit Breaker
        public IAsyncPolicy<HttpResponseMessage> GetRetryWithCircuitBreakerPolicy()
        {
            var retry = HttpPolicyExtensions
                .HandleTransientHttpError()
                .WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));

            var circuitBreaker = HttpPolicyExtensions
                .HandleTransientHttpError()
                .CircuitBreakerAsync(
                    handledEventsAllowedBeforeBreaking: 5,
                    durationOfBreak: TimeSpan.FromSeconds(30)
                );

            // Wrap retry with circuit breaker (circuit breaker is outer policy)
            return Policy.WrapAsync(circuitBreaker, retry);
        }

        // 5. Retry with Timeout
        public IAsyncPolicy<HttpResponseMessage> GetRetryWithTimeoutPolicy()
        {
            var timeout = Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(10));

            var retry = HttpPolicyExtensions
                .HandleTransientHttpError()
                .Or<TimeoutRejectedException>()  // Retry on timeout
                .WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromSeconds(retryAttempt));

            return Policy.WrapAsync(retry, timeout);
        }
    }
}
```

**Retry Configuration per HTTP Client:**

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Payment Service: Retry 3 times with exponential backoff
        services.AddHttpClient("PaymentService")
            .AddPolicyHandler(GetRetryPolicy(maxRetries: 3, baseDelaySeconds: 2))
            .AddPolicyHandler(GetCircuitBreakerPolicy());

        // Inventory Service: Retry 5 times with shorter delays (faster operation)
        services.AddHttpClient("InventoryService")
            .AddPolicyHandler(GetRetryPolicy(maxRetries: 5, baseDelaySeconds: 1));

        // Notification Service: Retry with longer delays (not time-critical)
        services.AddHttpClient("NotificationService")
            .AddPolicyHandler(GetRetryPolicy(maxRetries: 10, baseDelaySeconds: 5));
    }

    private static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy(int maxRetries, int baseDelaySeconds)
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .WaitAndRetryAsync(
                retryCount: maxRetries,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(baseDelaySeconds * retryAttempt)
            );
    }

    private static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(5, TimeSpan.FromSeconds(30));
    }
}
```

**Best Practices:**

1. **Use Exponential Backoff**: Increase delay between retries
2. **Add Jitter**: Random variation prevents thundering herd
3. **Set Max Retries**: Don't retry forever
4. **Be Selective**: Only retry transient failures
5. **Log Retries**: Track retry attempts for monitoring
6. **Combine with Circuit Breaker**: Prevent retry storms
7. **Use Timeouts**: Set operation timeouts
8. **Idempotency**: Ensure operations are safe to retry
9. **Monitor**: Track retry rates and success
10. **Test**: Verify retry logic works as expected

---

## Q151: What is the Bulkhead pattern?

**Answer:**

The **Bulkhead pattern** isolates resources (threads, connections, memory) for different parts of an application to prevent total system failure if one component fails. Like bulkheads in a ship prevent the entire vessel from sinking if one compartment floods.

**Visual Representation:**

```
WITHOUT Bulkhead (Shared Resource Pool):
┌──────────────────────────────────────┐
│   Shared Thread Pool (20 threads)    │
└───┬──────────┬──────────┬────────────┘
    │          │          │
    ▼          ▼          ▼
  Order    Inventory  Payment
  Service   Service   Service
  (Fast)    (SLOW!)   (Fast)

Problem: If Inventory Service is slow, it exhausts
all threads, blocking Order and Payment services!

WITH Bulkhead (Isolated Resource Pools):
┌────────────┐  ┌────────────┐  ┌────────────┐
│Order Pool  │  │Inventory   │  │Payment Pool│
│(8 threads) │  │Pool        │  │(8 threads) │
│            │  │(4 threads) │  │            │
└─────┬──────┘  └─────┬──────┘  └─────┬──────┘
      │               │               │
      ▼               ▼               ▼
    Order         Inventory       Payment
    Service       Service         Service
    (Isolated)    (Can't affect   (Isolated)
                   others!)

✅ If Inventory exhausts its 4 threads, Order and
   Payment still have their dedicated threads!
```

**Implementation with Polly:**

```csharp
// Install-Package Polly.Extensions.Http

namespace OrderService
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            // Bulkhead for Inventory Service (limit concurrent executions)
            services.AddHttpClient("InventoryService")
                .AddPolicyHandler(Policy.BulkheadAsync<HttpResponseMessage>(
                    maxParallelization: 10,  // Max 10 concurrent requests
                    maxQueuingActions: 20,   // Max 20 requests in queue
                    onBulkheadRejectedAsync: context =>
                    {
                        Console.WriteLine("Bulkhead rejected request - too many concurrent calls");
                        return Task.CompletedTask;
                    }
                ));

            // Bulkhead for Payment Service (more restrictive)
            services.AddHttpClient("PaymentService")
                .AddPolicyHandler(Policy.BulkheadAsync<HttpResponseMessage>(
                    maxParallelization: 5,   // Max 5 concurrent payment requests
                    maxQueuingActions: 10
                ));

            // Bulkhead for Notification Service (less restrictive)
            services.AddHttpClient("NotificationService")
                .AddPolicyHandler(Policy.BulkheadAsync<HttpResponseMessage>(
                    maxParallelization: 50,  // Can handle many notifications
                    maxQueuingActions: 100
                ));
        }
    }

    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger _logger;

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
                response.EnsureSuccessStatusCode();

                var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();
                return result.Quantity;
            }
            catch (BulkheadRejectedException ex)
            {
                // Bulkhead is full - request rejected
                _logger.LogWarning(ex, "Inventory service bulkhead is full");

                // Return fallback value
                return 0;  // Assume out of stock
            }
        }
    }
}
```

**Custom Bulkhead Implementation:**

```csharp
namespace OrderService.Resilience
{
    public class BulkheadExecutor
    {
        private readonly SemaphoreSlim _semaphore;
        private readonly int _maxConcurrent;
        private readonly string _bulkheadName;
        private readonly ILogger<BulkheadExecutor> _logger;

        private long _acceptedCount;
        private long _rejectedCount;
        private long _currentExecuting;

        public BulkheadExecutor(
            int maxConcurrent,
            string bulkheadName,
            ILogger<BulkheadExecutor> logger)
        {
            _maxConcurrent = maxConcurrent;
            _bulkheadName = bulkheadName;
            _logger = logger;
            _semaphore = new SemaphoreSlim(maxConcurrent, maxConcurrent);
        }

        public async Task<TResult> ExecuteAsync<TResult>(
            Func<Task<TResult>> operation,
            TimeSpan? timeout = null)
        {
            timeout ??= TimeSpan.FromSeconds(30);

            // Try to acquire semaphore slot
            var acquired = await _semaphore.WaitAsync(TimeSpan.Zero);

            if (!acquired)
            {
                Interlocked.Increment(ref _rejectedCount);
                _logger.LogWarning(
                    "Bulkhead {BulkheadName} rejected request. Current: {Current}/{Max}, Rejected: {Rejected}",
                    _bulkheadName,
                    Interlocked.Read(ref _currentExecuting),
                    _maxConcurrent,
                    Interlocked.Read(ref _rejectedCount)
                );

                throw new BulkheadRejectedException($"Bulkhead {_bulkheadName} is full");
            }

            try
            {
                Interlocked.Increment(ref _acceptedCount);
                Interlocked.Increment(ref _currentExecuting);

                _logger.LogDebug(
                    "Bulkhead {BulkheadName} accepted request. Current: {Current}/{Max}",
                    _bulkheadName,
                    Interlocked.Read(ref _currentExecuting),
                    _maxConcurrent
                );

                // Execute with timeout
                using var cts = new CancellationTokenSource(timeout.Value);
                return await operation();
            }
            finally
            {
                Interlocked.Decrement(ref _currentExecuting);
                _semaphore.Release();
            }
        }

        public BulkheadStats GetStats()
        {
            return new BulkheadStats
            {
                BulkheadName = _bulkheadName,
                MaxConcurrent = _maxConcurrent,
                CurrentExecuting = Interlocked.Read(ref _currentExecuting),
                AcceptedCount = Interlocked.Read(ref _acceptedCount),
                RejectedCount = Interlocked.Read(ref _rejectedCount),
                AvailableSlots = _maxConcurrent - (int)Interlocked.Read(ref _currentExecuting)
            };
        }
    }

    public class BulkheadStats
    {
        public string BulkheadName { get; set; }
        public int MaxConcurrent { get; set; }
        public long CurrentExecuting { get; set; }
        public long AcceptedCount { get; set; }
        public long RejectedCount { get; set; }
        public int AvailableSlots { get; set; }
        public double RejectionRate =>
            AcceptedCount + RejectedCount > 0
                ? (RejectedCount / (double)(AcceptedCount + RejectedCount)) * 100
                : 0;
    }

    // Usage
    public class PaymentServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly BulkheadExecutor _bulkhead;

        public PaymentServiceClient(
            IHttpClientFactory httpClientFactory,
            ILogger<BulkheadExecutor> logger)
        {
            _httpClient = httpClientFactory.CreateClient("PaymentService");
            _bulkhead = new BulkheadExecutor(
                maxConcurrent: 5,
                bulkheadName: "PaymentService",
                logger
            );
        }

        public async Task<PaymentResult> ProcessPaymentAsync(ProcessPaymentRequest request)
        {
            return await _bulkhead.ExecuteAsync(async () =>
            {
                var response = await _httpClient.PostAsJsonAsync("/api/payments", request);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadFromJsonAsync<PaymentResult>();
            });
        }
    }
}
```

**Bulkhead with Fallback:**

```csharp
namespace OrderService
{
    public class ResilientInventoryClient
    {
        private readonly HttpClient _httpClient;
        private readonly IDistributedCache _cache;
        private readonly BulkheadExecutor _bulkhead;
        private readonly ILogger _logger;

        public async Task<int> GetStockQuantityAsync(Guid productId)
        {
            try
            {
                return await _bulkhead.ExecuteAsync(async () =>
                {
                    var response = await _httpClient.GetAsync($"/api/inventory/{productId}");
                    response.EnsureSuccessStatusCode();

                    var result = await response.Content.ReadFromJsonAsync<StockQuantityResponse>();

                    // Cache result
                    await _cache.SetStringAsync(
                        $"stock:{productId}",
                        result.Quantity.ToString(),
                        new DistributedCacheEntryOptions
                        {
                            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
                        }
                    );

                    return result.Quantity;
                });
            }
            catch (BulkheadRejectedException)
            {
                _logger.LogWarning("Bulkhead full, using cached data for product {ProductId}", productId);

                // Fallback to cache
                var cachedValue = await _cache.GetStringAsync($"stock:{productId}");
                if (!string.IsNullOrEmpty(cachedValue))
                    return int.Parse(cachedValue);

                // Ultimate fallback
                _logger.LogWarning("No cached data available, assuming out of stock");
                return 0;
            }
        }
    }
}
```

**Best Practices:**

1. **Size Appropriately**: Based on downstream service capacity
2. **Monitor Metrics**: Track acceptance/rejection rates
3. **Implement Fallbacks**: Graceful degradation when bulkhead is full
4. **Combine with Circuit Breaker**: Both patterns complement each other
5. **Per-Service Bulkheads**: Isolate different dependencies
6. **Queue Size**: Set reasonable queue limits
7. **Test Under Load**: Verify bulkhead behavior under stress
8. **Alert on High Rejection**: Monitor rejection rates
9. **Consider Priority**: Implement priority queues if needed
10. **Document Limits**: Make capacity limits clear

---

## Q154: What is the Strangler Fig pattern?

**Answer:**

The **Strangler Fig pattern** is a migration strategy for gradually replacing a legacy system with a new system by incrementally replacing specific functionality until the old system is completely "strangled" and can be shut down.

Named after the strangler fig plant that grows around a tree, eventually replacing it.

**Visual Representation:**

```
PHASE 1: Initial State (100% Legacy)
┌──────────┐
│ Clients  │
└────┬─────┘
     │
     ▼
┌─────────────────┐
│  Legacy System  │
│  (Monolith)     │
│                 │
│  - Orders       │
│  - Products     │
│  - Customers    │
│  - Payments     │
└─────────────────┘

PHASE 2: Start Strangling (Products extracted)
┌──────────┐
│ Clients  │
└────┬─────┘
     │
     ▼
┌────────────────────┐
│   Routing Layer    │  (API Gateway / Proxy)
└───┬────────────┬───┘
    │            │
    │            ▼
    │     ┌──────────────┐
    │     │   Product    │  ← New microservice
    │     │  Service     │
    │     └──────────────┘
    │
    ▼
┌──────────────────┐
│ Legacy System    │
│                  │
│ - Orders         │
│ - Customers      │
│ - Payments       │
└──────────────────┘

PHASE 3: Continue Strangling (Orders extracted)
┌──────────┐
│ Clients  │
└────┬─────┘
     │
     ▼
┌────────────────────┐
│   Routing Layer    │
└───┬──────┬─────┬───┘
    │      │     │
    │      ▼     ▼
    │   ┌────┐ ┌────┐
    │   │Prod│ │Ord │  ← New microservices
    │   │Svc │ │Svc │
    │   └────┘ └────┘
    │
    ▼
┌──────────────────┐
│ Legacy System    │
│                  │
│ - Customers      │
│ - Payments       │
└──────────────────┘

PHASE 4: Legacy Decommissioned (100% New)
┌──────────┐
│ Clients  │
└────┬─────┘
     │
     ▼
┌────────────────────┐
│   API Gateway      │
└┬───┬───┬───┬───┬──┘
 │   │   │   │   │
 ▼   ▼   ▼   ▼   ▼
┌──┐┌──┐┌──┐┌──┐┌──┐
│P ││O ││C ││Pa││N │  All microservices
└──┘└──┘└──┘└──┘└──┘

Legacy System DELETED ✅
```

**Implementation with Proxy/API Gateway:**

```csharp
// API Gateway routes traffic to new or legacy system
namespace ApiGateway
{
    public class StranglerFigMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IFeatureToggleService _featureToggle;
        private readonly ILogger<StranglerFigMiddleware> _logger;

        public StranglerFigMiddleware(
            RequestDelegate next,
            IHttpClientFactory httpClientFactory,
            IFeatureToggleService featureToggle,
            ILogger<StranglerFigMiddleware> logger)
        {
            _next = next;
            _httpClientFactory = httpClientFactory;
            _featureToggle = featureToggle;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path.Value;

            // Determine routing based on path and feature toggles
            if (path.StartsWith("/api/products"))
            {
                // Products: 100% routed to new microservice
                await RouteToNewService(context, "ProductService", path);
            }
            else if (path.StartsWith("/api/orders"))
            {
                // Orders: Gradual migration using feature toggle
                var useNewService = await _featureToggle.IsEnabledAsync("NewOrderService");

                if (useNewService)
                {
                    _logger.LogInformation("Routing order request to new service");
                    await RouteToNewService(context, "OrderService", path);
                }
                else
                {
                    _logger.LogInformation("Routing order request to legacy system");
                    await RouteToLegacySystem(context, path);
                }
            }
            else if (path.StartsWith("/api/customers"))
            {
                // Customers: Canary deployment (10% to new, 90% to legacy)
                var random = new Random().Next(100);
                if (random < 10)  // 10% traffic
                {
                    _logger.LogInformation("Canary: Routing to new customer service");
                    await RouteToNewService(context, "CustomerService", path);
                }
                else
                {
                    _logger.LogInformation("Canary: Routing to legacy system");
                    await RouteToLegacySystem(context, path);
                }
            }
            else
            {
                // All other requests: Route to legacy system
                await RouteToLegacySystem(context, path);
            }
        }

        private async Task RouteToNewService(HttpContext context, string serviceName, string path)
        {
            var client = _httpClientFactory.CreateClient(serviceName);

            var proxyRequest = new HttpRequestMessage
            {
                Method = new HttpMethod(context.Request.Method),
                RequestUri = new Uri(client.BaseAddress, path + context.Request.QueryString)
            };

            // Copy headers
            foreach (var header in context.Request.Headers)
            {
                if (!proxyRequest.Headers.TryAddWithoutValidation(header.Key, header.Value.ToArray()))
                {
                    proxyRequest.Content?.Headers.TryAddWithoutValidation(header.Key, header.Value.ToArray());
                }
            }

            // Copy body
            if (context.Request.ContentLength > 0)
            {
                var streamContent = new StreamContent(context.Request.Body);
                proxyRequest.Content = streamContent;
            }

            // Forward request to new service
            var response = await client.SendAsync(proxyRequest);

            // Copy response
            context.Response.StatusCode = (int)response.StatusCode;
            foreach (var header in response.Headers)
            {
                context.Response.Headers[header.Key] = header.Value.ToArray();
            }

            await response.Content.CopyToAsync(context.Response.Body);
        }

        private async Task RouteToLegacySystem(HttpContext context, string path)
        {
            var client = _httpClientFactory.CreateClient("LegacySystem");
            // Similar implementation to RouteToNewService
            // ...
        }
    }

    // Feature Toggle Service
    public interface IFeatureToggleService
    {
        Task<bool> IsEnabledAsync(string featureName);
        Task<int> GetPercentageAsync(string featureName);
    }

    public class FeatureToggleService : IFeatureToggleService
    {
        private readonly IDistributedCache _cache;
        private readonly IConfiguration _configuration;

        public async Task<bool> IsEnabledAsync(string featureName)
        {
            // Check cache first
            var cacheKey = $"feature:{featureName}";
            var cachedValue = await _cache.GetStringAsync(cacheKey);

            if (!string.IsNullOrEmpty(cachedValue))
                return bool.Parse(cachedValue);

            // Fall back to configuration
            return _configuration.GetValue<bool>($"FeatureToggles:{featureName}", false);
        }

        public async Task<int> GetPercentageAsync(string featureName)
        {
            var cacheKey = $"feature:percentage:{featureName}";
            var cachedValue = await _cache.GetStringAsync(cacheKey);

            if (!string.IsNullOrEmpty(cachedValue))
                return int.Parse(cachedValue);

            return _configuration.GetValue<int>($"FeatureToggles:Percentage:{featureName}", 0);
        }
    }

    // Startup configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            // New microservices
            services.AddHttpClient("ProductService", client =>
            {
                client.BaseAddress = new Uri("https://product-service.local");
            });

            services.AddHttpClient("OrderService", client =>
            {
                client.BaseAddress = new Uri("https://order-service.local");
            });

            services.AddHttpClient("CustomerService", client =>
            {
                client.BaseAddress = new Uri("https://customer-service.local");
            });

            // Legacy monolith
            services.AddHttpClient("LegacySystem", client =>
            {
                client.BaseAddress = new Uri("https://legacy-system.local");
            });

            services.AddSingleton<IFeatureToggleService, FeatureToggleService>();
        }

        public void Configure(IApplicationBuilder app)
        {
            app.UseMiddleware<StranglerFigMiddleware>();
        }
    }
}
```

**Feature Toggle Configuration:**

```json
{
  "FeatureToggles": {
    "NewProductService": true,
    "NewOrderService": false,
    "NewCustomerService": false,
    "Percentage": {
      "NewOrderService": 0,
      "NewCustomerService": 10
    }
  }
}
```

**Migration Phases:**

| Phase | Service | Status | Traffic % |
|-------|---------|--------|-----------|
| **1** | Product | ✅ Complete | 100% new |
| **2** | Order | 🚧 In Progress | 0% new (feature toggle off) |
| **3** | Customer | 🧪 Canary | 10% new |
| **4** | Payment | ⏳ Planned | 0% new |
| **5** | Shipping | ⏳ Planned | 0% new |

**Best Practices:**

1. **Incremental Migration**: Extract one service at a time
2. **Feature Toggles**: Control traffic routing dynamically
3. **Dual Write**: Write to both systems during transition
4. **Read from New**: Gradually shift reads to new system
5. **Monitor Both**: Track metrics in legacy and new systems
6. **Rollback Plan**: Be able to route back to legacy quickly
7. **Data Migration**: Plan data synchronization strategy
8. **Test Thoroughly**: Test both paths extensively
9. **Gradual Rollout**: Use canary or percentage-based routing
10. **Decommission**: Only remove legacy when 100% confident

---

## Q152: What is Event Sourcing?

**Answer:**

**Event Sourcing** is a pattern where state changes are stored as a sequence of events rather than storing just the current state. Instead of updating a record in place, you append events that describe what happened.

**Traditional Approach vs Event Sourcing:**

```
TRADITIONAL (State-Based):
┌────────────────────────┐
│ Orders Table           │
├────────────────────────┤
│ OrderId: 123           │
│ Status: Shipped        │  ← Only current state
│ Total: $150            │
│ UpdatedAt: 2024-01-10  │
└────────────────────────┘

Lost history: Was it ever Pending? Confirmed? Paid?

EVENT SOURCING (Event-Based):
┌──────────────────────────────────────────┐
│ Order Events Stream (OrderId: 123)       │
├──────────────────────────────────────────┤
│ 1. OrderCreatedEvent                     │
│    - Time: 2024-01-08 10:00              │
│    - Total: $150                         │
│                                          │
│ 2. PaymentReceivedEvent                 │
│    - Time: 2024-01-08 10:05              │
│    - Amount: $150                        │
│                                          │
│ 3. OrderConfirmedEvent                  │
│    - Time: 2024-01-08 10:06              │
│                                          │
│ 4. OrderShippedEvent                    │
│    - Time: 2024-01-10 14:30              │
│    - TrackingNumber: ABC123              │
└──────────────────────────────────────────┘

Current State = Replay all events ✓
Full audit trail ✓
Can reconstruct state at any point in time ✓
```

**Implementation:**

```csharp
// Domain Events
namespace OrderService.Domain.Events
{
    public abstract class DomainEvent
    {
        public Guid EventId { get; set; } = Guid.NewGuid();
        public Guid AggregateId { get; set; }
        public int Version { get; set; }
        public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
        public string EventType => GetType().Name;
    }

    public class OrderCreatedEvent : DomainEvent
    {
        public Guid CustomerId { get; set; }
        public decimal TotalAmount { get; set; }
        public List<OrderLineDto> OrderLines { get; set; }
    }

    public class PaymentReceivedEvent : DomainEvent
    {
        public string TransactionId { get; set; }
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; }
    }

    public class OrderConfirmedEvent : DomainEvent
    {
        public DateTime ConfirmedAt { get; set; }
    }

    public class OrderShippedEvent : DomainEvent
    {
        public string TrackingNumber { get; set; }
        public string Carrier { get; set; }
        public DateTime ShippedAt { get; set; }
    }

    public class OrderCancelledEvent : DomainEvent
    {
        public string Reason { get; set; }
        public DateTime CancelledAt { get; set; }
    }
}

// Aggregate Root with Event Sourcing
namespace OrderService.Domain
{
    public class Order
    {
        private readonly List<DomainEvent> _uncommittedEvents = new List<DomainEvent>();

        public Guid OrderId { get; private set; }
        public Guid CustomerId { get; private set; }
        public OrderStatus Status { get; private set; }
        public decimal TotalAmount { get; private set; }
        public List<OrderLine> OrderLines { get; private set; } = new List<OrderLine>();
        public string TransactionId { get; private set; }
        public string TrackingNumber { get; private set; }
        public int Version { get; private set; }

        // Create new order (generates event)
        public static Order Create(Guid orderId, Guid customerId, List<OrderLine> orderLines)
        {
            var order = new Order();

            var @event = new OrderCreatedEvent
            {
                AggregateId = orderId,
                CustomerId = customerId,
                TotalAmount = orderLines.Sum(ol => ol.UnitPrice * ol.Quantity),
                OrderLines = orderLines.Select(ol => new OrderLineDto
                {
                    ProductId = ol.ProductId,
                    Quantity = ol.Quantity,
                    UnitPrice = ol.UnitPrice
                }).ToList(),
                Version = 1
            };

            order.Apply(@event);
            order._uncommittedEvents.Add(@event);

            return order;
        }

        // Business methods (generate events)
        public void ReceivePayment(string transactionId, decimal amount, string paymentMethod)
        {
            if (Status != OrderStatus.Pending)
                throw new InvalidOperationException("Cannot receive payment for non-pending order");

            var @event = new PaymentReceivedEvent
            {
                AggregateId = OrderId,
                TransactionId = transactionId,
                Amount = amount,
                PaymentMethod = paymentMethod,
                Version = Version + 1
            };

            Apply(@event);
            _uncommittedEvents.Add(@event);
        }

        public void Confirm()
        {
            if (Status != OrderStatus.PaymentReceived)
                throw new InvalidOperationException("Cannot confirm order without payment");

            var @event = new OrderConfirmedEvent
            {
                AggregateId = OrderId,
                ConfirmedAt = DateTime.UtcNow,
                Version = Version + 1
            };

            Apply(@event);
            _uncommittedEvents.Add(@event);
        }

        public void Ship(string trackingNumber, string carrier)
        {
            if (Status != OrderStatus.Confirmed)
                throw new InvalidOperationException("Cannot ship unconfirmed order");

            var @event = new OrderShippedEvent
            {
                AggregateId = OrderId,
                TrackingNumber = trackingNumber,
                Carrier = carrier,
                ShippedAt = DateTime.UtcNow,
                Version = Version + 1
            };

            Apply(@event);
            _uncommittedEvents.Add(@event);
        }

        public void Cancel(string reason)
        {
            if (Status == OrderStatus.Shipped || Status == OrderStatus.Delivered)
                throw new InvalidOperationException("Cannot cancel shipped or delivered order");

            var @event = new OrderCancelledEvent
            {
                AggregateId = OrderId,
                Reason = reason,
                CancelledAt = DateTime.UtcNow,
                Version = Version + 1
            };

            Apply(@event);
            _uncommittedEvents.Add(@event);
        }

        // Apply events to change state
        private void Apply(DomainEvent @event)
        {
            switch (@event)
            {
                case OrderCreatedEvent e:
                    OrderId = e.AggregateId;
                    CustomerId = e.CustomerId;
                    TotalAmount = e.TotalAmount;
                    OrderLines = e.OrderLines.Select(ol => new OrderLine
                    {
                        ProductId = ol.ProductId,
                        Quantity = ol.Quantity,
                        UnitPrice = ol.UnitPrice
                    }).ToList();
                    Status = OrderStatus.Pending;
                    Version = e.Version;
                    break;

                case PaymentReceivedEvent e:
                    TransactionId = e.TransactionId;
                    Status = OrderStatus.PaymentReceived;
                    Version = e.Version;
                    break;

                case OrderConfirmedEvent e:
                    Status = OrderStatus.Confirmed;
                    Version = e.Version;
                    break;

                case OrderShippedEvent e:
                    TrackingNumber = e.TrackingNumber;
                    Status = OrderStatus.Shipped;
                    Version = e.Version;
                    break;

                case OrderCancelledEvent e:
                    Status = OrderStatus.Cancelled;
                    Version = e.Version;
                    break;
            }
        }

        // Reconstitute from event history
        public static Order FromHistory(IEnumerable<DomainEvent> history)
        {
            var order = new Order();

            foreach (var @event in history.OrderBy(e => e.Version))
            {
                order.Apply(@event);
            }

            return order;
        }

        // Get uncommitted events
        public IEnumerable<DomainEvent> GetUncommittedEvents() => _uncommittedEvents;

        // Mark events as committed
        public void MarkEventsAsCommitted() => _uncommittedEvents.Clear();
    }
}

// Event Store
namespace OrderService.Infrastructure
{
    public interface IEventStore
    {
        Task SaveEventsAsync(Guid aggregateId, IEnumerable<DomainEvent> events, int expectedVersion);
        Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId);
        Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId, int fromVersion);
    }

    public class SqlEventStore : IEventStore
    {
        private readonly EventStoreDbContext _dbContext;

        public async Task SaveEventsAsync(Guid aggregateId, IEnumerable<DomainEvent> events, int expectedVersion)
        {
            // Optimistic concurrency check
            var currentVersion = await _dbContext.Events
                .Where(e => e.AggregateId == aggregateId)
                .MaxAsync(e => (int?)e.Version) ?? 0;

            if (currentVersion != expectedVersion)
                throw new ConcurrencyException($"Expected version {expectedVersion} but found {currentVersion}");

            // Save events
            foreach (var @event in events)
            {
                var eventEntity = new EventEntity
                {
                    EventId = @event.EventId,
                    AggregateId = @event.AggregateId,
                    EventType = @event.EventType,
                    EventData = JsonSerializer.Serialize(@event),
                    Version = @event.Version,
                    OccurredAt = @event.OccurredAt
                };

                _dbContext.Events.Add(eventEntity);
            }

            await _dbContext.SaveChangesAsync();
        }

        public async Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId)
        {
            var eventEntities = await _dbContext.Events
                .Where(e => e.AggregateId == aggregateId)
                .OrderBy(e => e.Version)
                .ToListAsync();

            return eventEntities.Select(DeserializeEvent);
        }

        public async Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId, int fromVersion)
        {
            var eventEntities = await _dbContext.Events
                .Where(e => e.AggregateId == aggregateId && e.Version > fromVersion)
                .OrderBy(e => e.Version)
                .ToListAsync();

            return eventEntities.Select(DeserializeEvent);
        }

        private DomainEvent DeserializeEvent(EventEntity entity)
        {
            var eventType = Type.GetType($"OrderService.Domain.Events.{entity.EventType}");
            return (DomainEvent)JsonSerializer.Deserialize(entity.EventData, eventType);
        }
    }

    // Event Store Database Schema
    public class EventStoreDbContext : DbContext
    {
        public DbSet<EventEntity> Events { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EventEntity>(entity =>
            {
                entity.ToTable("Events");
                entity.HasKey(e => e.EventId);
                entity.HasIndex(e => e.AggregateId);
                entity.HasIndex(e => new { e.AggregateId, e.Version }).IsUnique();
            });
        }
    }

    public class EventEntity
    {
        public Guid EventId { get; set; }
        public Guid AggregateId { get; set; }
        public string EventType { get; set; }
        public string EventData { get; set; }
        public int Version { get; set; }
        public DateTime OccurredAt { get; set; }
    }
}

// Repository
namespace OrderService.Infrastructure
{
    public class OrderRepository
    {
        private readonly IEventStore _eventStore;

        public async Task<Order> GetByIdAsync(Guid orderId)
        {
            var events = await _eventStore.GetEventsAsync(orderId);

            if (!events.Any())
                return null;

            return Order.FromHistory(events);
        }

        public async Task SaveAsync(Order order)
        {
            var uncommittedEvents = order.GetUncommittedEvents();

            if (!uncommittedEvents.Any())
                return;

            await _eventStore.SaveEventsAsync(
                order.OrderId,
                uncommittedEvents,
                order.Version - uncommittedEvents.Count()
            );

            order.MarkEventsAsCommitted();
        }
    }
}
```

**Snapshots for Performance:**

```csharp
// Snapshot to avoid replaying thousands of events
namespace OrderService.Domain
{
    public class OrderSnapshot
    {
        public Guid OrderId { get; set; }
        public Guid CustomerId { get; set; }
        public OrderStatus Status { get; set; }
        public decimal TotalAmount { get; set; }
        public string TransactionId { get; set; }
        public string TrackingNumber { get; set; }
        public int Version { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public interface ISnapshotStore
    {
        Task SaveSnapshotAsync(OrderSnapshot snapshot);
        Task<OrderSnapshot> GetSnapshotAsync(Guid orderId);
    }

    public class OrderRepositoryWithSnapshots
    {
        private readonly IEventStore _eventStore;
        private readonly ISnapshotStore _snapshotStore;
        private const int SnapshotInterval = 100;  // Snapshot every 100 events

        public async Task<Order> GetByIdAsync(Guid orderId)
        {
            // Try to get latest snapshot
            var snapshot = await _snapshotStore.GetSnapshotAsync(orderId);

            Order order;
            IEnumerable<DomainEvent> events;

            if (snapshot != null)
            {
                // Restore from snapshot
                order = Order.FromSnapshot(snapshot);

                // Get events after snapshot
                events = await _eventStore.GetEventsAsync(orderId, snapshot.Version);
            }
            else
            {
                // No snapshot, get all events
                events = await _eventStore.GetEventsAsync(orderId);
                order = new Order();
            }

            // Apply remaining events
            foreach (var @event in events.OrderBy(e => e.Version))
            {
                order.ApplyEvent(@event);
            }

            return order;
        }

        public async Task SaveAsync(Order order)
        {
            var uncommittedEvents = order.GetUncommittedEvents();

            if (!uncommittedEvents.Any())
                return;

            await _eventStore.SaveEventsAsync(
                order.OrderId,
                uncommittedEvents,
                order.Version - uncommittedEvents.Count()
            );

            // Create snapshot if threshold reached
            if (order.Version % SnapshotInterval == 0)
            {
                var snapshot = new OrderSnapshot
                {
                    OrderId = order.OrderId,
                    CustomerId = order.CustomerId,
                    Status = order.Status,
                    TotalAmount = order.TotalAmount,
                    TransactionId = order.TransactionId,
                    TrackingNumber = order.TrackingNumber,
                    Version = order.Version,
                    CreatedAt = DateTime.UtcNow
                };

                await _snapshotStore.SaveSnapshotAsync(snapshot);
            }

            order.MarkEventsAsCommitted();
        }
    }
}
```

**Benefits:**
1. **Complete Audit Trail**: Every state change is recorded
2. **Time Travel**: Reconstruct state at any point in time
3. **Event Replay**: Replay events to rebuild state or create projections
4. **Debugging**: See exactly what happened and when
5. **Business Intelligence**: Rich event data for analytics

**Challenges:**
1. **Query Complexity**: Need projections/read models for queries
2. **Event Schema Evolution**: Handling event versioning
3. **Storage**: More data than traditional approach
4. **Learning Curve**: Different mental model

**Best Practices:**
1. **Immutable Events**: Never modify or delete events
2. **Event Versioning**: Plan for event schema evolution
3. **Snapshots**: Use snapshots for performance
4. **Idempotency**: Ensure event handlers are idempotent
5. **Event Enrichment**: Include all necessary data in events

---

## Q153: What is CQRS (Command Query Responsibility Segregation)?

**Answer:**

**CQRS** separates read operations (queries) from write operations (commands) using different models. Commands change state, queries return data - and they use optimized, separate data stores.

**Visual Architecture:**

```
WITHOUT CQRS (Traditional):
┌──────────┐
│  Client  │
└────┬─────┘
     │
     ├─── Write (UPDATE order SET status='Shipped') ──►┐
     │                                                  │
     └─── Read (SELECT * FROM orders WHERE...)  ───────┤
                                                        │
                                                   ┌────▼─────┐
                                                   │ Database │
                                                   │(Normalized│
                                                   │  Schema) │
                                                   └──────────┘
Problems:
- Complex queries on normalized schema
- Write optimizations conflict with read optimizations
- Difficult to scale reads independently

WITH CQRS:
┌──────────┐
│  Client  │
└─┬────┬───┘
  │    │
  │    │ Queries (GET orders)
  │    └────────────────────────────────┐
  │                                     │
  │ Commands (CreateOrder)              │
  │                                     │
  ▼                                     ▼
┌──────────────┐  Events  ┌───────────────────┐
│ Write Model  │─────────►│   Read Model      │
│              │          │  (Denormalized)   │
│ - Validation │          │                   │
│ - Business   │          │ - Fast queries    │
│   Rules      │          │ - No joins        │
│ - Events     │          │ - Optimized views │
└──────┬───────┘          └─────────┬─────────┘
       │                            │
   ┌───▼────┐                  ┌────▼─────┐
   │ Write  │                  │  Read    │
   │   DB   │                  │   DB     │
   │(Events)│                  │(MongoDB) │
   └────────┘                  └──────────┘
```

**Implementation:**

```csharp
// COMMANDS (Write Side)
namespace OrderService.Commands
{
    public interface ICommand
    {
        Guid CommandId { get; }
    }

    public class CreateOrderCommand : ICommand
    {
        public Guid CommandId { get; set; } = Guid.NewGuid();
        public Guid CustomerId { get; set; }
        public List<OrderLineDto> OrderLines { get; set; }
    }

    public class ConfirmOrderCommand : ICommand
    {
        public Guid CommandId { get; set; } = Guid.NewGuid();
        public Guid OrderId { get; set; }
    }

    public class ShipOrderCommand : ICommand
    {
        public Guid CommandId { get; set; } = Guid.NewGuid();
        public Guid OrderId { get; set; }
        public string TrackingNumber { get; set; }
        public string Carrier { get; set; }
    }

    // Command Handlers (Write Side)
    public interface ICommandHandler<TCommand> where TCommand : ICommand
    {
        Task HandleAsync(TCommand command);
    }

    public class CreateOrderCommandHandler : ICommandHandler<CreateOrderCommand>
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task HandleAsync(CreateOrderCommand command)
        {
            // Validate
            if (!command.OrderLines.Any())
                throw new ValidationException("Order must have at least one line");

            // Create aggregate
            var order = Order.Create(
                Guid.NewGuid(),
                command.CustomerId,
                command.OrderLines.Select(ol => new OrderLine
                {
                    ProductId = ol.ProductId,
                    Quantity = ol.Quantity,
                    UnitPrice = ol.UnitPrice
                }).ToList()
            );

            // Save (appends events to event store)
            await _repository.SaveAsync(order);

            // Publish events for read model updates
            foreach (var @event in order.GetUncommittedEvents())
            {
                await _eventBus.PublishAsync(@event);
            }
        }
    }

    public class ShipOrderCommandHandler : ICommandHandler<ShipOrderCommand>
    {
        private readonly IOrderRepository _repository;
        private readonly IEventBus _eventBus;

        public async Task HandleAsync(ShipOrderCommand command)
        {
            // Load aggregate from event store
            var order = await _repository.GetByIdAsync(command.OrderId);

            if (order == null)
                throw new NotFoundException($"Order {command.OrderId} not found");

            // Execute business logic (generates events)
            order.Ship(command.TrackingNumber, command.Carrier);

            // Save events
            await _repository.SaveAsync(order);

            // Publish events
            foreach (var @event in order.GetUncommittedEvents())
            {
                await _eventBus.PublishAsync(@event);
            }
        }
    }
}

// QUERIES (Read Side)
namespace OrderService.Queries
{
    public interface IQuery<TResult>
    {
    }

    public class GetOrderByIdQuery : IQuery<OrderDetailsDto>
    {
        public Guid OrderId { get; set; }
    }

    public class GetOrdersByCustomerQuery : IQuery<List<OrderSummaryDto>>
    {
        public Guid CustomerId { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    public class GetOrdersQuery : IQuery<PagedResult<OrderSummaryDto>>
    {
        public OrderStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 50;
    }

    // Query Handlers (Read Side)
    public interface IQueryHandler<TQuery, TResult> where TQuery : IQuery<TResult>
    {
        Task<TResult> HandleAsync(TQuery query);
    }

    public class GetOrderByIdQueryHandler : IQueryHandler<GetOrderByIdQuery, OrderDetailsDto>
    {
        private readonly IMongoCollection<OrderReadModel> _orders;

        public GetOrderByIdQueryHandler(IMongoDatabase database)
        {
            _orders = database.GetCollection<OrderReadModel>("Orders");
        }

        public async Task<OrderDetailsDto> HandleAsync(GetOrderByIdQuery query)
        {
            var order = await _orders
                .Find(o => o.OrderId == query.OrderId)
                .FirstOrDefaultAsync();

            if (order == null)
                return null;

            return new OrderDetailsDto
            {
                OrderId = order.OrderId,
                OrderNumber = order.OrderNumber,
                CustomerId = order.CustomerId,
                CustomerName = order.CustomerName,
                Status = order.Status,
                OrderLines = order.OrderLines,
                TotalAmount = order.TotalAmount,
                CreatedAt = order.CreatedAt,
                ShippedAt = order.ShippedAt,
                TrackingNumber = order.TrackingNumber
            };
        }
    }

    public class GetOrdersByCustomerQueryHandler : IQueryHandler<GetOrdersByCustomerQuery, List<OrderSummaryDto>>
    {
        private readonly IMongoCollection<OrderReadModel> _orders;

        public async Task<List<OrderSummaryDto>> HandleAsync(GetOrdersByCustomerQuery query)
        {
            var orders = await _orders
                .Find(o => o.CustomerId == query.CustomerId)
                .SortByDescending(o => o.CreatedAt)
                .Skip((query.Page - 1) * query.PageSize)
                .Limit(query.PageSize)
                .ToListAsync();

            return orders.Select(o => new OrderSummaryDto
            {
                OrderId = o.OrderId,
                OrderNumber = o.OrderNumber,
                Status = o.Status,
                TotalAmount = o.TotalAmount,
                CreatedAt = o.CreatedAt
            }).ToList();
        }
    }
}

// READ MODEL (Denormalized for fast queries)
namespace OrderService.ReadModels
{
    public class OrderReadModel
    {
        [BsonId]
        public Guid OrderId { get; set; }
        public string OrderNumber { get; set; }

        // Denormalized customer data
        public Guid CustomerId { get; set; }
        public string CustomerName { get; set; }
        public string CustomerEmail { get; set; }

        // Order data
        public string Status { get; set; }
        public decimal TotalAmount { get; set; }
        public List<OrderLineReadModel> OrderLines { get; set; }

        // Payment data (denormalized)
        public string TransactionId { get; set; }
        public string PaymentMethod { get; set; }

        // Shipping data (denormalized)
        public string TrackingNumber { get; set; }
        public string Carrier { get; set; }

        // Timestamps
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
        public DateTime? ShippedAt { get; set; }

        // For searching
        [BsonElement("search_text")]
        public string SearchText { get; set; }  // orderNumber + customerName + email
    }

    public class OrderLineReadModel
    {
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public string ProductImage { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal LineTotal { get; set; }
    }

    // Event Handlers update Read Model
    public class OrderEventHandlers
    {
        private readonly IMongoCollection<OrderReadModel> _orders;
        private readonly ICustomerServiceClient _customerService;

        public async Task Handle(OrderCreatedEvent @event)
        {
            // Get customer data
            var customer = await _customerService.GetCustomerAsync(@event.CustomerId);

            // Create read model
            var readModel = new OrderReadModel
            {
                OrderId = @event.AggregateId,
                OrderNumber = GenerateOrderNumber(@event.AggregateId),
                CustomerId = @event.CustomerId,
                CustomerName = customer.Name,
                CustomerEmail = customer.Email,
                Status = "Pending",
                TotalAmount = @event.TotalAmount,
                OrderLines = @event.OrderLines.Select(ol => new OrderLineReadModel
                {
                    ProductId = ol.ProductId,
                    ProductName = ol.ProductName,
                    Quantity = ol.Quantity,
                    UnitPrice = ol.UnitPrice,
                    LineTotal = ol.Quantity * ol.UnitPrice
                }).ToList(),
                CreatedAt = @event.OccurredAt,
                SearchText = $"{GenerateOrderNumber(@event.AggregateId)} {customer.Name} {customer.Email}"
            };

            await _orders.InsertOneAsync(readModel);
        }

        public async Task Handle(OrderShippedEvent @event)
        {
            var update = Builders<OrderReadModel>.Update
                .Set(o => o.Status, "Shipped")
                .Set(o => o.TrackingNumber, @event.TrackingNumber)
                .Set(o => o.Carrier, @event.Carrier)
                .Set(o => o.ShippedAt, @event.ShippedAt);

            await _orders.UpdateOneAsync(
                o => o.OrderId == @event.AggregateId,
                update
            );
        }

        private string GenerateOrderNumber(Guid orderId)
        {
            return $"ORD-{orderId.ToString().Substring(0, 8).ToUpper()}";
        }
    }
}

// API Controllers
namespace OrderService.API
{
    [ApiController]
    [Route("api/orders")]
    public class OrdersController : ControllerBase
    {
        private readonly ICommandHandler<CreateOrderCommand> _createOrderHandler;
        private readonly ICommandHandler<ShipOrderCommand> _shipOrderHandler;
        private readonly IQueryHandler<GetOrderByIdQuery, OrderDetailsDto> _getOrderByIdHandler;
        private readonly IQueryHandler<GetOrdersByCustomerQuery, List<OrderSummaryDto>> _getOrdersByCustomerHandler;

        // POST /api/orders (Command - Write)
        [HttpPost]
        public async Task<ActionResult<Guid>> CreateOrder(CreateOrderRequest request)
        {
            var command = new CreateOrderCommand
            {
                CustomerId = request.CustomerId,
                OrderLines = request.OrderLines
            };

            await _createOrderHandler.HandleAsync(command);

            return Accepted(new { OrderId = command.CommandId });
        }

        // POST /api/orders/{id}/ship (Command - Write)
        [HttpPost("{id}/ship")]
        public async Task<IActionResult> ShipOrder(Guid id, ShipOrderRequest request)
        {
            var command = new ShipOrderCommand
            {
                OrderId = id,
                TrackingNumber = request.TrackingNumber,
                Carrier = request.Carrier
            };

            await _shipOrderHandler.HandleAsync(command);

            return Accepted();
        }

        // GET /api/orders/{id} (Query - Read)
        [HttpGet("{id}")]
        public async Task<ActionResult<OrderDetailsDto>> GetOrder(Guid id)
        {
            var query = new GetOrderByIdQuery { OrderId = id };
            var result = await _getOrderByIdHandler.HandleAsync(query);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        // GET /api/customers/{customerId}/orders (Query - Read)
        [HttpGet("/api/customers/{customerId}/orders")]
        public async Task<ActionResult<List<OrderSummaryDto>>> GetCustomerOrders(
            Guid customerId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var query = new GetOrdersByCustomerQuery
            {
                CustomerId = customerId,
                Page = page,
                PageSize = pageSize
            };

            var result = await _getOrdersByCustomerHandler.HandleAsync(query);
            return Ok(result);
        }
    }
}
```

**Benefits:**
1. **Independent Scaling**: Scale reads and writes separately
2. **Optimized Models**: Write model for business logic, read model for queries
3. **Performance**: Fast queries on denormalized read models
4. **Flexibility**: Different storage technologies for reads and writes

**Best Practices:**
1. **Eventual Consistency**: Accept that read models may lag
2. **Idempotent Handlers**: Read model updates must be idempotent
3. **Separate Databases**: Use optimal storage for each side
4. **Command Validation**: Validate commands before execution
5. **Event Versioning**: Plan for event schema evolution

---

## Q155: What are the different inter-service communication patterns?

**Answer:**

Microservices communicate using **synchronous** (request-response) or **asynchronous** (event-driven) patterns. Each has specific use cases and trade-offs.

**Communication Patterns:**

| Pattern | Type | Protocol | Use Case |
|---------|------|----------|----------|
| **REST API** | Sync | HTTP/HTTPS | CRUD operations, simple queries |
| **gRPC** | Sync | HTTP/2 | High-performance, internal services |
| **Message Queue** | Async | AMQP, MQTT | Background jobs, decoupling |
| **Event Streaming** | Async | Kafka, EventHub | Real-time data pipelines |
| **GraphQL** | Sync | HTTP/HTTPS | Flexible queries, mobile/web APIs |
| **WebSockets** | Sync/Async | WS/WSS | Real-time bidirectional |

**1. Synchronous Communication (REST)**

```csharp
// Order Service calls Inventory Service synchronously
namespace OrderService
{
    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;

        public InventoryServiceClient(IHttpClientFactory httpClientFactory)
        {
            _httpClient = httpClientFactory.CreateClient("InventoryService");
        }

        public async Task<bool> CheckStockAvailabilityAsync(Guid productId, int quantity)
        {
            var response = await _httpClient.GetAsync(
                $"/api/inventory/{productId}/availability?quantity={quantity}"
            );

            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<StockAvailabilityResponse>();
            return result.IsAvailable;
        }

        public async Task<ReservationResult> ReserveStockAsync(Guid productId, int quantity)
        {
            var request = new ReserveStockRequest
            {
                ProductId = productId,
                Quantity = quantity,
                ReservationExpiryMinutes = 15
            };

            var response = await _httpClient.PostAsJsonAsync("/api/inventory/reserve", request);
            response.EnsureSuccessStatusCode();

            return await response.Content.ReadFromJsonAsync<ReservationResult>();
        }
    }

    // Usage in Order creation
    public class CreateOrderCommandHandler
    {
        private readonly IInventoryServiceClient _inventoryClient;
        private readonly IOrderRepository _orderRepository;

        public async Task<Order> Handle(CreateOrderCommand command)
        {
            // Synchronous call - waits for response
            var isAvailable = await _inventoryClient.CheckStockAvailabilityAsync(
                command.ProductId,
                command.Quantity
            );

            if (!isAvailable)
                throw new OutOfStockException();

            // Reserve stock synchronously
            var reservation = await _inventoryClient.ReserveStockAsync(
                command.ProductId,
                command.Quantity
            );

            // Create order
            var order = Order.Create(command.CustomerId, command.OrderLines);
            order.SetReservationId(reservation.ReservationId);

            await _orderRepository.SaveAsync(order);

            return order;
        }
    }
}
```

**2. Synchronous Communication (gRPC)**

```protobuf
// inventory.proto
syntax = "proto3";

package inventory;

service InventoryService {
  rpc CheckStockAvailability (CheckStockRequest) returns (StockAvailabilityResponse);
  rpc ReserveStock (ReserveStockRequest) returns (ReservationResponse);
  rpc ReleaseReservation (ReleaseReservationRequest) returns (ReleaseResponse);
}

message CheckStockRequest {
  string product_id = 1;
  int32 quantity = 2;
}

message StockAvailabilityResponse {
  bool is_available = 1;
  int32 available_quantity = 2;
  string warehouse_id = 3;
}

message ReserveStockRequest {
  string product_id = 1;
  int32 quantity = 2;
  int32 expiry_minutes = 3;
}

message ReservationResponse {
  string reservation_id = 1;
  bool success = 2;
  string error_message = 3;
}
```

```csharp
// gRPC Client
namespace OrderService.Clients
{
    public class GrpcInventoryClient
    {
        private readonly InventoryService.InventoryServiceClient _client;

        public GrpcInventoryClient(InventoryService.InventoryServiceClient client)
        {
            _client = client;
        }

        public async Task<bool> CheckStockAvailabilityAsync(Guid productId, int quantity)
        {
            var request = new CheckStockRequest
            {
                ProductId = productId.ToString(),
                Quantity = quantity
            };

            var response = await _client.CheckStockAvailabilityAsync(request);
            return response.IsAvailable;
        }

        public async Task<string> ReserveStockAsync(Guid productId, int quantity)
        {
            var request = new ReserveStockRequest
            {
                ProductId = productId.ToString(),
                Quantity = quantity,
                ExpiryMinutes = 15
            };

            var response = await _client.ReserveStockAsync(request);

            if (!response.Success)
                throw new StockReservationException(response.ErrorMessage);

            return response.ReservationId;
        }
    }

    // Startup configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddGrpcClient<InventoryService.InventoryServiceClient>(options =>
            {
                options.Address = new Uri("https://inventory-service:5001");
            });

            services.AddScoped<GrpcInventoryClient>();
        }
    }
}
```

**3. Asynchronous Communication (Message Queue)**

```csharp
// Using RabbitMQ
namespace OrderService
{
    public class OrderCreatedEventPublisher
    {
        private readonly IConnection _connection;
        private readonly IModel _channel;

        public OrderCreatedEventPublisher(IConnectionFactory connectionFactory)
        {
            _connection = connectionFactory.CreateConnection();
            _channel = _connection.CreateModel();

            // Declare exchange
            _channel.ExchangeDeclare(
                exchange: "orders",
                type: ExchangeType.Topic,
                durable: true
            );
        }

        public void PublishOrderCreated(OrderCreatedEvent @event)
        {
            var message = JsonSerializer.Serialize(@event);
            var body = Encoding.UTF8.GetBytes(message);

            var properties = _channel.CreateBasicProperties();
            properties.Persistent = true;
            properties.MessageId = @event.EventId.ToString();
            properties.Timestamp = new AmqpTimestamp(DateTimeOffset.UtcNow.ToUnixTimeSeconds());

            _channel.BasicPublish(
                exchange: "orders",
                routingKey: "order.created",
                basicProperties: properties,
                body: body
            );
        }
    }

    // Consumer in Inventory Service
    public class OrderCreatedEventConsumer : BackgroundService
    {
        private readonly IConnection _connection;
        private readonly IModel _channel;
        private readonly IServiceProvider _serviceProvider;

        public OrderCreatedEventConsumer(IConnectionFactory connectionFactory, IServiceProvider serviceProvider)
        {
            _connection = connectionFactory.CreateConnection();
            _channel = _connection.CreateModel();
            _serviceProvider = serviceProvider;

            // Declare queue
            _channel.QueueDeclare(
                queue: "inventory.order-created",
                durable: true,
                exclusive: false,
                autoDelete: false
            );

            // Bind queue to exchange
            _channel.QueueBind(
                queue: "inventory.order-created",
                exchange: "orders",
                routingKey: "order.created"
            );
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var consumer = new EventingBasicConsumer(_channel);

            consumer.Received += async (model, ea) =>
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);

                try
                {
                    var @event = JsonSerializer.Deserialize<OrderCreatedEvent>(message);

                    using var scope = _serviceProvider.CreateScope();
                    var handler = scope.ServiceProvider.GetRequiredService<IOrderCreatedEventHandler>();

                    await handler.HandleAsync(@event);

                    // Acknowledge message
                    _channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
                }
                catch (Exception ex)
                {
                    // Reject and requeue (or send to dead letter queue)
                    _channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: false);
                }
            };

            _channel.BasicConsume(
                queue: "inventory.order-created",
                autoAck: false,
                consumer: consumer
            );

            return Task.CompletedTask;
        }
    }
}
```

**4. Event Streaming (Azure Event Hub / Kafka)**

```csharp
// Producer (Order Service)
namespace OrderService
{
    public class EventHubOrderEventPublisher
    {
        private readonly EventHubProducerClient _producerClient;

        public EventHubOrderEventPublisher(string connectionString, string eventHubName)
        {
            _producerClient = new EventHubProducerClient(connectionString, eventHubName);
        }

        public async Task PublishOrderCreatedAsync(OrderCreatedEvent @event)
        {
            var eventData = new EventData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(@event)));
            eventData.Properties["EventType"] = "OrderCreated";
            eventData.Properties["EventId"] = @event.EventId.ToString();
            eventData.Properties["AggregateId"] = @event.OrderId.ToString();

            using var eventBatch = await _producerClient.CreateBatchAsync();
            eventBatch.TryAdd(eventData);

            await _producerClient.SendAsync(eventBatch);
        }
    }

    // Consumer (Inventory Service)
    public class EventHubOrderEventConsumer : BackgroundService
    {
        private readonly EventProcessorClient _processorClient;
        private readonly IServiceProvider _serviceProvider;

        public EventHubOrderEventConsumer(
            string connectionString,
            string eventHubName,
            string consumerGroup,
            BlobContainerClient checkpointStore,
            IServiceProvider serviceProvider)
        {
            _processorClient = new EventProcessorClient(
                checkpointStore,
                consumerGroup,
                connectionString,
                eventHubName
            );

            _serviceProvider = serviceProvider;

            _processorClient.ProcessEventAsync += ProcessEventHandler;
            _processorClient.ProcessErrorAsync += ProcessErrorHandler;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await _processorClient.StartProcessingAsync(stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            }

            await _processorClient.StopProcessingAsync();
        }

        private async Task ProcessEventHandler(ProcessEventArgs args)
        {
            var eventType = args.Data.Properties["EventType"].ToString();

            if (eventType == "OrderCreated")
            {
                var eventBody = Encoding.UTF8.GetString(args.Data.EventBody.ToArray());
                var @event = JsonSerializer.Deserialize<OrderCreatedEvent>(eventBody);

                using var scope = _serviceProvider.CreateScope();
                var handler = scope.ServiceProvider.GetRequiredService<IOrderCreatedEventHandler>();

                await handler.HandleAsync(@event);
            }

            // Update checkpoint
            await args.UpdateCheckpointAsync();
        }

        private Task ProcessErrorHandler(ProcessErrorEventArgs args)
        {
            Console.WriteLine($"Error: {args.Exception.Message}");
            return Task.CompletedTask;
        }
    }
}
```

**Communication Pattern Comparison:**

| Pattern | Latency | Coupling | Complexity | Best For |
|---------|---------|----------|------------|----------|
| **REST** | Low | Medium | Low | Simple CRUD, public APIs |
| **gRPC** | Very Low | Medium | Medium | Internal high-perf calls |
| **Message Queue** | High | Low | Medium | Async processing, decoupling |
| **Event Streaming** | Medium | Low | High | Real-time analytics, event sourcing |
| **GraphQL** | Low | Medium | Medium | Flexible client queries |

**Best Practices:**

1. **Use Async for Long Operations**: Don't block on network calls
2. **Implement Timeouts**: Always set request timeouts
3. **Circuit Breakers**: Protect against cascading failures
4. **Idempotency**: Ensure operations can be retried safely
5. **Service Discovery**: Don't hardcode service URLs
6. **API Versioning**: Support backward compatibility
7. **Monitoring**: Track latency, error rates, throughput
8. **Security**: Use mTLS, API keys, or OAuth2

---

## Q160: What is Distributed Tracing and why is it important?

**Answer:**

**Distributed Tracing** tracks requests as they flow through multiple microservices, creating a complete picture of the request's journey. It's essential for debugging and performance optimization in distributed systems.

**Visual Representation:**

```
WITHOUT Distributed Tracing:
User Request → API Gateway → Order Service → ???
                                           → Error!

Where did it fail? Which service is slow?
Need to check logs in 5+ services manually!

WITH Distributed Tracing:
Trace ID: abc-123-xyz

┌─────────────────────────────────────────────────────────┐
│ Request Timeline (Total: 850ms)                         │
├─────────────────────────────────────────────────────────┤
│ Span 1: API Gateway          [0ms ─── 50ms]            │
│ Span 2: Order Service        [50ms ──── 250ms]         │
│   ├─ Span 3: Inventory Call  [75ms ─ 150ms]   ✓       │
│   ├─ Span 4: Payment Call    [150ms ── 600ms] ⚠ SLOW! │
│   └─ Span 5: DB Query        [600ms ─ 625ms]  ✓       │
│ Span 6: Notification Service [250ms ── 350ms]  ✓       │
└─────────────────────────────────────────────────────────┘

✓ See complete request flow
✓ Identify bottlenecks (Payment Service is slow!)
✓ Pinpoint errors with context
```

**Implementation with Application Insights:**

```csharp
// Install-Package Microsoft.ApplicationInsights.AspNetCore

// Program.cs
using Microsoft.ApplicationInsights.Extensibility;

var builder = WebApplication.CreateBuilder(args);

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = true;
    options.EnableQuickPulseMetricStream = true;
});

// Add telemetry initializer for custom properties
builder.Services.AddSingleton<ITelemetryInitializer, CustomTelemetryInitializer>();

var app = builder.Build();

app.Run();

// Custom Telemetry Initializer
public class CustomTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        telemetry.Context.Cloud.RoleName = "OrderService";  // Service name
        telemetry.Context.Component.Version = "1.0.0";      // Service version
    }
}

// Order Service with Distributed Tracing
namespace OrderService
{
    public class CreateOrderCommandHandler
    {
        private readonly TelemetryClient _telemetryClient;
        private readonly IInventoryServiceClient _inventoryClient;
        private readonly IPaymentServiceClient _paymentClient;
        private readonly IOrderRepository _orderRepository;

        public async Task<Order> Handle(CreateOrderCommand command)
        {
            using var operation = _telemetryClient.StartOperation<RequestTelemetry>("CreateOrder");
            operation.Telemetry.Properties["CustomerId"] = command.CustomerId.ToString();
            operation.Telemetry.Properties["OrderTotal"] = command.TotalAmount.ToString();

            try
            {
                // Track dependency call to Inventory Service
                using (var inventoryOperation = _telemetryClient.StartOperation<DependencyTelemetry>(
                    "CheckInventory",
                    "http",
                    "InventoryService"))
                {
                    var isAvailable = await _inventoryClient.CheckStockAvailabilityAsync(
                        command.ProductId,
                        command.Quantity
                    );

                    inventoryOperation.Telemetry.Success = isAvailable;
                    inventoryOperation.Telemetry.Properties["ProductId"] = command.ProductId.ToString();

                    if (!isAvailable)
                    {
                        throw new OutOfStockException();
                    }
                }

                // Create order
                var order = Order.Create(command.CustomerId, command.OrderLines);

                // Track dependency call to Payment Service
                using (var paymentOperation = _telemetryClient.StartOperation<DependencyTelemetry>(
                    "ProcessPayment",
                    "http",
                    "PaymentService"))
                {
                    var paymentResult = await _paymentClient.ProcessPaymentAsync(
                        order.OrderId,
                        command.TotalAmount
                    );

                    paymentOperation.Telemetry.Success = paymentResult.Success;
                    paymentOperation.Telemetry.Properties["TransactionId"] = paymentResult.TransactionId;

                    if (!paymentResult.Success)
                    {
                        throw new PaymentFailedException();
                    }

                    order.SetTransactionId(paymentResult.TransactionId);
                }

                // Save to database
                using (var dbOperation = _telemetryClient.StartOperation<DependencyTelemetry>(
                    "SaveOrder",
                    "sql",
                    "OrderDatabase"))
                {
                    await _orderRepository.SaveAsync(order);
                    dbOperation.Telemetry.Success = true;
                }

                operation.Telemetry.Success = true;
                operation.Telemetry.ResponseCode = "200";

                // Track custom event
                _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
                {
                    { "OrderId", order.OrderId.ToString() },
                    { "CustomerId", command.CustomerId.ToString() },
                    { "TotalAmount", command.TotalAmount.ToString() }
                });

                return order;
            }
            catch (Exception ex)
            {
                operation.Telemetry.Success = false;
                operation.Telemetry.ResponseCode = "500";

                _telemetryClient.TrackException(ex, new Dictionary<string, string>
                {
                    { "Operation", "CreateOrder" },
                    { "CustomerId", command.CustomerId.ToString() }
                });

                throw;
            }
        }
    }
}
```

**Propagating Trace Context (Manual):**

```csharp
// Propagate correlation ID across services
namespace OrderService
{
    public class InventoryServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public async Task<bool> CheckStockAvailabilityAsync(Guid productId, int quantity)
        {
            var request = new HttpRequestMessage(
                HttpMethod.Get,
                $"/api/inventory/{productId}/availability?quantity={quantity}"
            );

            // Propagate correlation ID
            if (_httpContextAccessor.HttpContext?.Request.Headers.TryGetValue("x-correlation-id", out var correlationId) == true)
            {
                request.Headers.Add("x-correlation-id", correlationId.ToString());
            }

            // Propagate request ID (W3C Trace Context)
            if (_httpContextAccessor.HttpContext?.Request.Headers.TryGetValue("traceparent", out var traceParent) == true)
            {
                request.Headers.Add("traceparent", traceParent.ToString());
            }

            var response = await _httpClient.SendAsync(request);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<StockAvailabilityResponse>();
            return result.IsAvailable;
        }
    }

    // Middleware to ensure correlation ID
    public class CorrelationIdMiddleware
    {
        private readonly RequestDelegate _next;
        private const string CorrelationIdHeader = "x-correlation-id";

        public CorrelationIdMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var correlationId = context.Request.Headers[CorrelationIdHeader].FirstOrDefault()
                ?? Guid.NewGuid().ToString();

            context.Items[CorrelationIdHeader] = correlationId;
            context.Response.Headers[CorrelationIdHeader] = correlationId;

            using (LogContext.PushProperty("CorrelationId", correlationId))
            {
                await _next(context);
            }
        }
    }
}
```

**OpenTelemetry Implementation:**

```csharp
// Install-Package OpenTelemetry
// Install-Package OpenTelemetry.Instrumentation.AspNetCore
// Install-Package OpenTelemetry.Instrumentation.Http
// Install-Package OpenTelemetry.Instrumentation.SqlClient
// Install-Package OpenTelemetry.Exporter.Console
// Install-Package OpenTelemetry.Exporter.Jaeger

// Program.cs
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenTelemetryTracing(tracerProviderBuilder =>
{
    tracerProviderBuilder
        .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("OrderService"))
        .AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.Filter = (httpContext) =>
            {
                // Don't trace health checks
                return !httpContext.Request.Path.StartsWithSegments("/health");
            };
        })
        .AddHttpClientInstrumentation(options =>
        {
            options.RecordException = true;
        })
        .AddSqlClientInstrumentation(options =>
        {
            options.SetDbStatementForText = true;
            options.RecordException = true;
        })
        .AddSource("OrderService")  // Custom activity source
        .AddJaegerExporter(options =>
        {
            options.AgentHost = "jaeger";
            options.AgentPort = 6831;
        })
        .AddConsoleExporter();  // For development
});

// Custom tracing
namespace OrderService
{
    public class CreateOrderCommandHandler
    {
        private static readonly ActivitySource ActivitySource = new ActivitySource("OrderService");
        private readonly IInventoryServiceClient _inventoryClient;

        public async Task<Order> Handle(CreateOrderCommand command)
        {
            using var activity = ActivitySource.StartActivity("CreateOrder", ActivityKind.Internal);
            activity?.SetTag("customerId", command.CustomerId);
            activity?.SetTag("orderTotal", command.TotalAmount);

            try
            {
                // Child span for inventory check
                using (var inventoryActivity = ActivitySource.StartActivity("CheckInventory", ActivityKind.Client))
                {
                    inventoryActivity?.SetTag("productId", command.ProductId);
                    inventoryActivity?.SetTag("quantity", command.Quantity);

                    var isAvailable = await _inventoryClient.CheckStockAvailabilityAsync(
                        command.ProductId,
                        command.Quantity
                    );

                    inventoryActivity?.SetTag("isAvailable", isAvailable);

                    if (!isAvailable)
                    {
                        inventoryActivity?.SetStatus(ActivityStatusCode.Error, "Out of stock");
                        throw new OutOfStockException();
                    }
                }

                activity?.SetStatus(ActivityStatusCode.Ok);
                activity?.AddEvent(new ActivityEvent("OrderCreatedSuccessfully"));

                return order;
            }
            catch (Exception ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity?.RecordException(ex);
                throw;
            }
        }
    }
}
```

**Querying Traces (Kusto Query - Application Insights):**

```kusto
// Find slow requests (>1 second)
requests
| where timestamp > ago(1h)
| where duration > 1000
| project timestamp, name, duration, resultCode, operation_Id
| order by duration desc
| take 20

// Trace complete request flow
let traceId = "abc-123-xyz";
union requests, dependencies
| where operation_Id == traceId
| project timestamp, itemType, name, duration, success, target
| order by timestamp asc

// Find errors with full context
exceptions
| where timestamp > ago(24h)
| join kind=inner (
    requests
    | where success == false
) on operation_Id
| project timestamp, problemId, outerMessage, request_Name, request_Url, customDimensions
| take 50
```

**Best Practices:**

1. **Use Correlation IDs**: Propagate across all services
2. **Sample Appropriately**: Don't trace 100% in production (use adaptive sampling)
3. **Add Context**: Include relevant business data in spans
4. **Standardize**: Use W3C Trace Context standard
5. **Monitor Performance**: Track P95, P99 latencies
6. **Alert on Anomalies**: Set up alerts for slow traces
7. **Visualize**: Use tools like Jaeger, Zipkin, or Application Insights
8. **Respect Privacy**: Don't log sensitive data in traces

---

## Q165: How do you handle API versioning in microservices?

**Answer:**

**API Versioning** allows you to introduce breaking changes without disrupting existing clients. Multiple versions of an API can coexist during migration periods.

**Versioning Strategies:**

**1. URI Versioning**

```csharp
// Version in URL path
namespace OrderService.Controllers
{
    // Version 1
    [ApiController]
    [Route("api/v1/orders")]
    public class OrdersV1Controller : ControllerBase
    {
        [HttpGet("{id}")]
        public async Task<ActionResult<OrderDtoV1>> GetOrder(Guid id)
        {
            var order = await _repository.GetByIdAsync(id);

            return new OrderDtoV1
            {
                Id = order.OrderId,
                Total = order.TotalAmount,
                Status = order.Status.ToString()
            };
        }

        [HttpPost]
        public async Task<ActionResult<OrderDtoV1>> CreateOrder(CreateOrderRequestV1 request)
        {
            // V1 logic
        }
    }

    // Version 2 (with breaking changes)
    [ApiController]
    [Route("api/v2/orders")]
    public class OrdersV2Controller : ControllerBase
    {
        [HttpGet("{id}")]
        public async Task<ActionResult<OrderDtoV2>> GetOrder(Guid id)
        {
            var order = await _repository.GetByIdAsync(id);

            return new OrderDtoV2
            {
                OrderId = order.OrderId,           // Changed: "Id" → "OrderId"
                TotalAmount = order.TotalAmount,    // Changed: "Total" → "TotalAmount"
                OrderStatus = new OrderStatusDto    // Changed: string → object
                {
                    Code = order.Status.ToString(),
                    DisplayName = GetStatusDisplayName(order.Status)
                },
                CreatedAt = order.CreatedAt,        // New field
                UpdatedAt = order.UpdatedAt         // New field
            };
        }

        [HttpPost]
        public async Task<ActionResult<OrderDtoV2>> CreateOrder(CreateOrderRequestV2 request)
        {
            // V2 logic with new fields
        }
    }
}
```

**2. Header Versioning**

```csharp
// Version in HTTP header
namespace OrderService.Controllers
{
    [ApiController]
    [Route("api/orders")]
    public class OrdersController : ControllerBase
    {
        [HttpGet("{id}")]
        [ApiVersion("1.0")]
        public async Task<ActionResult<OrderDtoV1>> GetOrderV1(Guid id)
        {
            // V1 response
        }

        [HttpGet("{id}")]
        [ApiVersion("2.0")]
        public async Task<ActionResult<OrderDtoV2>> GetOrderV2(Guid id)
        {
            // V2 response
        }
    }

    // Startup configuration
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddApiVersioning(options =>
            {
                options.DefaultApiVersion = new ApiVersion(1, 0);
                options.AssumeDefaultVersionWhenUnspecified = true;
                options.ReportApiVersions = true;

                // Read version from header
                options.ApiVersionReader = new HeaderApiVersionReader("api-version");
            });
        }
    }
}

// Client usage:
// GET /api/orders/123
// Header: api-version: 2.0
```

**3. Query String Versioning**

```csharp
namespace OrderService.Controllers
{
    [ApiController]
    [Route("api/orders")]
    public class OrdersController : ControllerBase
    {
        [HttpGet("{id}")]
        public async Task<ActionResult> GetOrder(
            Guid id,
            [FromQuery] string version = "1.0")
        {
            return version switch
            {
                "2.0" => Ok(await GetOrderV2Async(id)),
                "1.0" => Ok(await GetOrderV1Async(id)),
                _ => BadRequest("Unsupported API version")
            };
        }
    }
}

// Client usage:
// GET /api/orders/123?version=2.0
```

**4. Content Negotiation Versioning**

```csharp
namespace OrderService.Controllers
{
    [ApiController]
    [Route("api/orders")]
    public class OrdersController : ControllerBase
    {
        [HttpGet("{id}")]
        public async Task<ActionResult> GetOrder(Guid id)
        {
            var order = await _repository.GetByIdAsync(id);

            var acceptHeader = Request.Headers["Accept"].ToString();

            return acceptHeader switch
            {
                "application/vnd.orderservice.v2+json" => Ok(MapToV2(order)),
                "application/vnd.orderservice.v1+json" => Ok(MapToV1(order)),
                _ => Ok(MapToV1(order))  // Default to v1
            };
        }
    }
}

// Client usage:
// GET /api/orders/123
// Header: Accept: application/vnd.orderservice.v2+json
```

**Versioning with ASP.NET Core API Versioning:**

```csharp
// Install-Package Microsoft.AspNetCore.Mvc.Versioning
// Install-Package Microsoft.AspNetCore.Mvc.Versioning.ApiExplorer

// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;

    // Support multiple version readers
    options.ApiVersionReader = ApiVersionReader.Combine(
        new UrlSegmentApiVersionReader(),
        new HeaderApiVersionReader("x-api-version"),
        new MediaTypeApiVersionReader("ver")
    );
});

builder.Services.AddVersionedApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});

// Controllers
namespace OrderService.Controllers
{
    [ApiController]
    [Route("api/v{version:apiVersion}/orders")]
    [ApiVersion("1.0")]
    [ApiVersion("2.0")]
    public class OrdersController : ControllerBase
    {
        [HttpGet("{id}")]
        [MapToApiVersion("1.0")]
        public async Task<ActionResult<OrderDtoV1>> GetOrderV1(Guid id)
        {
            // V1 implementation
        }

        [HttpGet("{id}")]
        [MapToApiVersion("2.0")]
        public async Task<ActionResult<OrderDtoV2>> GetOrderV2(Guid id)
        {
            // V2 implementation
        }

        [HttpPost]
        [MapToApiVersion("1.0")]
        [MapToApiVersion("2.0")]
        public async Task<ActionResult> CreateOrder(
            CreateOrderRequest request,
            ApiVersion apiVersion)
        {
            if (apiVersion.MajorVersion == 2)
            {
                // V2 logic
            }
            else
            {
                // V1 logic
            }
        }

        // Only available in V2
        [HttpPatch("{id}")]
        [MapToApiVersion("2.0")]
        public async Task<ActionResult> UpdateOrder(Guid id, UpdateOrderRequest request)
        {
            // V2-only endpoint
        }
    }

    // Deprecated version
    [ApiController]
    [Route("api/v{version:apiVersion}/products")]
    [ApiVersion("1.0", Deprecated = true)]  // Mark as deprecated
    [ApiVersion("2.0")]
    public class ProductsController : ControllerBase
    {
        [HttpGet]
        [MapToApiVersion("1.0")]
        public async Task<ActionResult> GetProductsV1()
        {
            Response.Headers.Add("X-API-Deprecated", "This version is deprecated. Please migrate to v2.0");
            // V1 implementation
        }

        [HttpGet]
        [MapToApiVersion("2.0")]
        public async Task<ActionResult> GetProductsV2()
        {
            // V2 implementation
        }
    }
}
```

**Versioning Comparison:**

| Strategy | Pros | Cons | Best For |
|----------|------|------|----------|
| **URI** | Clear, cacheable, easy to test | URL clutter | Public APIs, REST |
| **Header** | Clean URLs, flexible | Harder to test, not cacheable | Internal APIs |
| **Query String** | Simple, backward compatible | Query pollution | Simple versioning |
| **Content Negotiation** | RESTful, flexible | Complex, less discoverable | Mature REST APIs |

**Version Lifecycle Management:**

```csharp
namespace OrderService
{
    public class ApiVersionInfo
    {
        public string Version { get; set; }
        public VersionStatus Status { get; set; }
        public DateTime? DeprecationDate { get; set; }
        public DateTime? SunsetDate { get; set; }
        public string MigrationGuide { get; set; }
    }

    public enum VersionStatus
    {
        Current,
        Deprecated,
        Sunset
    }

    [ApiController]
    [Route("api/version-info")]
    public class VersionInfoController : ControllerBase
    {
        [HttpGet]
        public ActionResult<List<ApiVersionInfo>> GetVersionInfo()
        {
            return Ok(new List<ApiVersionInfo>
            {
                new ApiVersionInfo
                {
                    Version = "2.0",
                    Status = VersionStatus.Current,
                    MigrationGuide = "https://docs.company.com/api/v2-migration"
                },
                new ApiVersionInfo
                {
                    Version = "1.0",
                    Status = VersionStatus.Deprecated,
                    DeprecationDate = new DateTime(2024, 1, 1),
                    SunsetDate = new DateTime(2024, 6, 1),
                    MigrationGuide = "https://docs.company.com/api/v1-to-v2"
                }
            });
        }
    }
}
```

**Best Practices:**

1. **URI Versioning**: Most common, easy to understand
2. **Semantic Versioning**: Use major.minor.patch (1.0.0, 2.0.0)
3. **Default Version**: Always have a default version
4. **Deprecation Policy**: Give clients time to migrate (6-12 months)
5. **Sunset Headers**: Use `Sunset` HTTP header for deprecation
6. **Documentation**: Maintain docs for all supported versions
7. **Migration Guides**: Provide clear upgrade paths
8. **Monitor Usage**: Track which versions are still in use
9. **Backward Compatibility**: Prefer additive changes when possible
10. **Version Discovery**: Provide endpoint to list supported versions

---

## Q171: What are the best practices for microservices monitoring and observability?

**Answer:**

**Observability** in microservices includes monitoring, logging, tracing, and metrics to understand system behavior and troubleshoot issues.

**Three Pillars of Observability:**

1. **Metrics** - What's happening? (CPU, memory, request rate, error rate)
2. **Logs** - Detailed context about specific events
3. **Traces** - How requests flow through services

**Implementation:**

```csharp
// Comprehensive Observability Setup

// Program.cs
using Serilog;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// 1. STRUCTURED LOGGING (Serilog)
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .Enrich.WithProperty("ServiceName", "OrderService")
    .Enrich.WithProperty("Environment", builder.Environment.EnvironmentName)
    .Enrich.WithMachineName()
    .WriteTo.Console(new CompactJsonFormatter())
    .WriteTo.ApplicationInsights(
        builder.Configuration["ApplicationInsights:ConnectionString"],
        TelemetryConverter.Traces
    )
    .WriteTo.Seq(builder.Configuration["Seq:ServerUrl"])
    .CreateLogger();

builder.Host.UseSerilog();

// 2. METRICS (Prometheus)
builder.Services.AddSingleton<OrderMetrics>();

// 3. DISTRIBUTED TRACING (OpenTelemetry)
builder.Services.AddOpenTelemetryTracing(tracerProviderBuilder =>
{
    tracerProviderBuilder
        .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("OrderService"))
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation()
        .AddJaegerExporter();
});

// 4. HEALTH CHECKS
builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("OrderDb"))
    .AddRedis(builder.Configuration.GetConnectionString("Redis"))
    .AddUrlGroup(new Uri("https://inventory-service/health"), "Inventory Service");

var app = builder.Build();

// Expose Prometheus metrics
app.UseMetricServer();  // /metrics endpoint
app.UseHttpMetrics();

// Health check endpoints
app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");

app.Run();

// Custom Metrics
namespace OrderService.Metrics
{
    public class OrderMetrics
    {
        private readonly Counter _ordersCreatedCounter;
        private readonly Histogram _orderProcessingDuration;
        private readonly Gauge _activeOrders;

        public OrderMetrics()
        {
            _ordersCreatedCounter = Metrics.CreateCounter(
                "orders_created_total",
                "Total number of orders created",
                new CounterConfiguration
                {
                    LabelNames = new[] { "status", "payment_method" }
                }
            );

            _orderProcessingDuration = Metrics.CreateHistogram(
                "order_processing_duration_seconds",
                "Order processing duration in seconds",
                new HistogramConfiguration
                {
                    LabelNames = new[] { "status" },
                    Buckets = Histogram.ExponentialBuckets(0.01, 2, 10)
                }
            );

            _activeOrders = Metrics.CreateGauge(
                "active_orders",
                "Number of active orders being processed"
            );
        }

        public void RecordOrderCreated(string status, string paymentMethod)
        {
            _ordersCreatedCounter.WithLabels(status, paymentMethod).Inc();
        }

        public void RecordOrderProcessingDuration(double durationSeconds, string status)
        {
            _orderProcessingDuration.WithLabels(status).Observe(durationSeconds);
        }

        public void IncrementActiveOrders() => _activeOrders.Inc();
        public void DecrementActiveOrders() => _activeOrders.Dec();
    }

    // Usage in handler
    public class CreateOrderCommandHandler
    {
        private readonly OrderMetrics _metrics;
        private readonly ILogger<CreateOrderCommandHandler> _logger;

        public async Task<Order> Handle(CreateOrderCommand command)
        {
            var stopwatch = Stopwatch.StartNew();
            _metrics.IncrementActiveOrders();

            try
            {
                _logger.LogInformation(
                    "Creating order for customer {CustomerId} with {ItemCount} items",
                    command.CustomerId,
                    command.OrderLines.Count
                );

                var order = Order.Create(command.CustomerId, command.OrderLines);
                await _repository.SaveAsync(order);

                stopwatch.Stop();

                _metrics.RecordOrderCreated("success", command.PaymentMethod);
                _metrics.RecordOrderProcessingDuration(stopwatch.Elapsed.TotalSeconds, "success");

                _logger.LogInformation(
                    "Order {OrderId} created successfully in {Duration}ms",
                    order.OrderId,
                    stopwatch.ElapsedMilliseconds
                );

                return order;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();

                _metrics.RecordOrderCreated("failed", command.PaymentMethod);
                _metrics.RecordOrderProcessingDuration(stopwatch.Elapsed.TotalSeconds, "failed");

                _logger.LogError(
                    ex,
                    "Failed to create order for customer {CustomerId}",
                    command.CustomerId
                );

                throw;
            }
            finally
            {
                _metrics.DecrementActiveOrders();
            }
        }
    }
}
```

**Structured Logging Best Practices:**

```csharp
namespace OrderService
{
    public class OrderService
    {
        private readonly ILogger<OrderService> _logger;

        public async Task ProcessOrder(Guid orderId)
        {
            // ✅ Good: Structured logging with properties
            _logger.LogInformation(
                "Processing order {OrderId} for customer {CustomerId}",
                orderId,
                customerId
            );

            // ❌ Bad: String interpolation
            _logger.LogInformation($"Processing order {orderId} for customer {customerId}");

            // ✅ Good: Log with correlation context
            using (LogContext.PushProperty("OrderId", orderId))
            using (LogContext.PushProperty("CustomerId", customerId))
            {
                _logger.LogInformation("Starting payment processing");
                await ProcessPayment();

                _logger.LogInformation("Payment completed");
            }

            // ✅ Good: Log levels
            _logger.LogTrace("Entering ProcessOrder method");  // Development only
            _logger.LogDebug("Order validation passed");        // Development/staging
            _logger.LogInformation("Order created");            // Normal operations
            _logger.LogWarning("Inventory low for product");    // Attention needed
            _logger.LogError(ex, "Payment failed");            // Errors
            _logger.LogCritical(ex, "Database unavailable");   // System-wide issues
        }
    }
}
```

**Monitoring Dashboard (Grafana Queries):**

```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Request duration (P95)
histogram_quantile(0.95, rate(order_processing_duration_seconds_bucket[5m]))

# Active orders
active_orders

# Orders created per minute by status
sum by (status) (rate(orders_created_total[1m]))
```

**Best Practices:**

1. **Structured Logging**: Use structured logs, not string concatenation
2. **Correlation IDs**: Track requests across services
3. **Metrics**: Track RED metrics (Rate, Errors, Duration)
4. **Distributed Tracing**: Use for debugging complex flows
5. **Health Checks**: Liveness and readiness probes
6. **Alerting**: Set up alerts for critical metrics
7. **Dashboards**: Create service-specific dashboards
8. **Log Aggregation**: Centralize logs (ELK, Seq, Splunk)
9. **Sampling**: Sample traces in production
10. **Security**: Don't log sensitive data

---

## Summary: Q141-Q171 Completed! ✅

All advanced microservices architecture questions have been comprehensively answered with production-ready code examples, best practices, and real-world scenarios!

