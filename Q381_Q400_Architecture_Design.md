# Interview Questions Q381-Q400: Software Architecture & System Design

---

## **Q381. How do you design a scalable, maintainable software architecture? Explain layered architecture, clean architecture, and hexagonal architecture patterns.**

### **Answer:**

Software architecture patterns provide structure and organization to applications, making them scalable, maintainable, and testable. The main patterns include layered, clean, and hexagonal architectures.

### **1. Layered Architecture (N-Tier):**

```csharp
// ✅ Traditional Layered Architecture
/*
┌─────────────────────────┐
│   Presentation Layer    │  (Controllers, Views, API)
├─────────────────────────┤
│    Business Layer       │  (Services, Domain Logic)
├─────────────────────────┤
│   Data Access Layer     │  (Repositories, EF Context)
├─────────────────────────┤
│      Database           │  (SQL Server, etc.)
└─────────────────────────┘
*/

// Presentation Layer
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProduct(Guid id)
    {
        var product = await _productService.GetByIdAsync(id);
        return product != null ? Ok(product) : NotFound();
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request)
    {
        var productId = await _productService.CreateProductAsync(request);
        return CreatedAtAction(nameof(GetProduct), new { id = productId }, null);
    }
}

// Business Layer
public interface IProductService
{
    Task<ProductDto> GetByIdAsync(Guid id);
    Task<Guid> CreateProductAsync(CreateProductRequest request);
}

public class ProductService : IProductService
{
    private readonly IProductRepository _repository;
    private readonly IInventoryService _inventoryService;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IProductRepository repository,
        IInventoryService inventoryService,
        ILogger<ProductService> logger)
    {
        _repository = repository;
        _inventoryService = inventoryService;
        _logger = logger;
    }

    public async Task<ProductDto> GetByIdAsync(Guid id)
    {
        var product = await _repository.GetByIdAsync(id);
        if (product == null)
            return null;

        var inventory = await _inventoryService.GetInventoryAsync(id);

        return new ProductDto
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            StockQuantity = inventory.Quantity
        };
    }

    public async Task<Guid> CreateProductAsync(CreateProductRequest request)
    {
        // Business logic and validation
        if (request.Price <= 0)
            throw new BusinessException("Price must be greater than zero");

        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Price = request.Price,
            Category = request.Category,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddAsync(product);

        _logger.LogInformation("Product {ProductId} created", product.Id);

        return product.Id;
    }
}

// Data Access Layer
public interface IProductRepository
{
    Task<Product> GetByIdAsync(Guid id);
    Task AddAsync(Product product);
    Task UpdateAsync(Product product);
    Task DeleteAsync(Guid id);
}

public class ProductRepository : IProductRepository
{
    private readonly ApplicationDbContext _context;

    public ProductRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Product> GetByIdAsync(Guid id)
    {
        return await _context.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task AddAsync(Product product)
    {
        await _context.Products.AddAsync(product);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var product = await GetByIdAsync(id);
        if (product != null)
        {
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
        }
    }
}

// Domain Models
public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

### **2. Clean Architecture (Onion Architecture):**

```csharp
// ✅ Clean Architecture with dependency inversion
/*
┌───────────────────────────────────────┐
│         Presentation Layer            │  (Web, API)
│  ┌─────────────────────────────────┐  │
│  │      Application Layer          │  │  (Use Cases, DTOs)
│  │  ┌───────────────────────────┐  │  │
│  │  │     Domain Layer          │  │  │  (Entities, Interfaces)
│  │  │  (Business Logic Core)    │  │  │
│  │  └───────────────────────────┘  │  │
│  └─────────────────────────────────┘  │
└───────────────────────────────────────┘
         ↓ (Dependencies point inward)
┌───────────────────────────────────────┐
│     Infrastructure Layer              │  (EF, External Services)
└───────────────────────────────────────┘
*/

// Domain Layer (Core)
namespace Domain.Entities
{
    public class Order
    {
        public Guid Id { get; private set; }
        public string CustomerId { get; private set; }
        public DateTime OrderDate { get; private set; }
        public OrderStatus Status { get; private set; }
        private readonly List<OrderItem> _items = new();
        public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();

        public decimal TotalAmount => _items.Sum(i => i.Price * i.Quantity);

        private Order() { } // EF Constructor

        public static Order Create(string customerId)
        {
            return new Order
            {
                Id = Guid.NewGuid(),
                CustomerId = customerId,
                OrderDate = DateTime.UtcNow,
                Status = OrderStatus.Pending
            };
        }

        public void AddItem(Guid productId, string productName, decimal price, int quantity)
        {
            if (Status != OrderStatus.Pending)
                throw new DomainException("Cannot add items to a non-pending order");

            if (quantity <= 0)
                throw new DomainException("Quantity must be greater than zero");

            var item = new OrderItem
            {
                Id = Guid.NewGuid(),
                ProductId = productId,
                ProductName = productName,
                Price = price,
                Quantity = quantity
            };

            _items.Add(item);
        }

        public void Submit()
        {
            if (!_items.Any())
                throw new DomainException("Cannot submit an order with no items");

            Status = OrderStatus.Submitted;
        }

        public void Cancel()
        {
            if (Status == OrderStatus.Completed)
                throw new DomainException("Cannot cancel a completed order");

            Status = OrderStatus.Cancelled;
        }
    }

    public class OrderItem
    {
        public Guid Id { get; set; }
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public decimal Price { get; set; }
        public int Quantity { get; set; }
    }

    public enum OrderStatus
    {
        Pending,
        Submitted,
        Processing,
        Completed,
        Cancelled
    }

    public class DomainException : Exception
    {
        public DomainException(string message) : base(message) { }
    }
}

// Domain Interfaces
namespace Domain.Repositories
{
    public interface IOrderRepository
    {
        Task<Order> GetByIdAsync(Guid id);
        Task AddAsync(Order order);
        Task UpdateAsync(Order order);
    }
}

// Application Layer (Use Cases)
namespace Application.UseCases.Orders
{
    public class CreateOrderCommand
    {
        public string CustomerId { get; set; }
        public List<OrderItemDto> Items { get; set; }
    }

    public class OrderItemDto
    {
        public Guid ProductId { get; set; }
        public int Quantity { get; set; }
    }

    public class CreateOrderCommandHandler
    {
        private readonly IOrderRepository _orderRepository;
        private readonly IProductRepository _productRepository;
        private readonly IUnitOfWork _unitOfWork;

        public CreateOrderCommandHandler(
            IOrderRepository orderRepository,
            IProductRepository productRepository,
            IUnitOfWork unitOfWork)
        {
            _orderRepository = orderRepository;
            _productRepository = productRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> Handle(CreateOrderCommand command)
        {
            // Create order
            var order = Order.Create(command.CustomerId);

            // Add items
            foreach (var itemDto in command.Items)
            {
                var product = await _productRepository.GetByIdAsync(itemDto.ProductId);
                if (product == null)
                    throw new ApplicationException($"Product {itemDto.ProductId} not found");

                order.AddItem(product.Id, product.Name, product.Price, itemDto.Quantity);
            }

            // Submit order
            order.Submit();

            // Persist
            await _orderRepository.AddAsync(order);
            await _unitOfWork.CommitAsync();

            return order.Id;
        }
    }
}

// Infrastructure Layer
namespace Infrastructure.Persistence
{
    public class OrderRepository : IOrderRepository
    {
        private readonly ApplicationDbContext _context;

        public OrderRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Order> GetByIdAsync(Guid id)
        {
            return await _context.Orders
                .Include(o => o.Items)
                .FirstOrDefaultAsync(o => o.Id == id);
        }

        public async Task AddAsync(Order order)
        {
            await _context.Orders.AddAsync(order);
        }

        public async Task UpdateAsync(Order order)
        {
            _context.Orders.Update(order);
        }
    }

    public class UnitOfWork : IUnitOfWork
    {
        private readonly ApplicationDbContext _context;

        public UnitOfWork(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task CommitAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}

// Presentation Layer
namespace Web.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly CreateOrderCommandHandler _createOrderHandler;

        public OrdersController(CreateOrderCommandHandler createOrderHandler)
        {
            _createOrderHandler = createOrderHandler;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderCommand command)
        {
            var orderId = await _createOrderHandler.Handle(command);
            return CreatedAtAction(nameof(GetOrder), new { id = orderId }, null);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetOrder(Guid id)
        {
            // Implementation
            return Ok();
        }
    }
}
```

### **3. Hexagonal Architecture (Ports and Adapters):**

```csharp
// ✅ Hexagonal Architecture
/*
        ┌─────────────────────────────────────┐
        │         Adapters (Outside)          │
        │  ┌──────────┐      ┌──────────┐    │
        │  │   Web    │      │Database  │    │
        │  │   API    │      │  Adapter │    │
        │  └────┬─────┘      └─────┬────┘    │
        │       │ Port             │ Port     │
        │  ┌────┴──────────────────┴────┐    │
        │  │      Application Core       │    │
        │  │    (Business Logic)         │    │
        │  │   Domain + Use Cases        │    │
        │  └─────────────────────────────┘    │
        └─────────────────────────────────────┘
*/

// Domain Core (Hexagon Center)
namespace Core.Domain
{
    // Domain Entity
    public class Payment
    {
        public Guid Id { get; private set; }
        public decimal Amount { get; private set; }
        public string Currency { get; private set; }
        public PaymentStatus Status { get; private set; }
        public string TransactionId { get; private set; }

        public static Payment Create(decimal amount, string currency)
        {
            if (amount <= 0)
                throw new DomainException("Amount must be greater than zero");

            return new Payment
            {
                Id = Guid.NewGuid(),
                Amount = amount,
                Currency = currency,
                Status = PaymentStatus.Pending
            };
        }

        public void MarkAsProcessing(string transactionId)
        {
            TransactionId = transactionId;
            Status = PaymentStatus.Processing;
        }

        public void MarkAsCompleted()
        {
            if (Status != PaymentStatus.Processing)
                throw new DomainException("Can only complete a processing payment");

            Status = PaymentStatus.Completed;
        }

        public void MarkAsFailed()
        {
            Status = PaymentStatus.Failed;
        }
    }

    public enum PaymentStatus
    {
        Pending,
        Processing,
        Completed,
        Failed
    }
}

// Primary Ports (Driving - Inbound)
namespace Core.Ports.Inbound
{
    // Use case interface
    public interface IProcessPaymentUseCase
    {
        Task<PaymentResult> ProcessAsync(ProcessPaymentRequest request);
    }

    public class ProcessPaymentRequest
    {
        public decimal Amount { get; set; }
        public string Currency { get; set; }
        public string CardToken { get; set; }
    }

    public class PaymentResult
    {
        public Guid PaymentId { get; set; }
        public bool Success { get; set; }
        public string Message { get; set; }
    }
}

// Secondary Ports (Driven - Outbound)
namespace Core.Ports.Outbound
{
    // Port for payment gateway
    public interface IPaymentGateway
    {
        Task<GatewayResponse> ChargeAsync(decimal amount, string currency, string cardToken);
    }

    public class GatewayResponse
    {
        public bool Success { get; set; }
        public string TransactionId { get; set; }
        public string ErrorMessage { get; set; }
    }

    // Port for payment repository
    public interface IPaymentRepository
    {
        Task SaveAsync(Payment payment);
        Task<Payment> GetByIdAsync(Guid id);
    }

    // Port for notifications
    public interface INotificationService
    {
        Task SendPaymentConfirmationAsync(Guid paymentId, string email);
    }
}

// Application Service (Use Case Implementation)
namespace Core.Application
{
    public class ProcessPaymentService : IProcessPaymentUseCase
    {
        private readonly IPaymentGateway _paymentGateway;
        private readonly IPaymentRepository _paymentRepository;
        private readonly INotificationService _notificationService;
        private readonly ILogger<ProcessPaymentService> _logger;

        public ProcessPaymentService(
            IPaymentGateway paymentGateway,
            IPaymentRepository paymentRepository,
            INotificationService notificationService,
            ILogger<ProcessPaymentService> logger)
        {
            _paymentGateway = paymentGateway;
            _paymentRepository = paymentRepository;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<PaymentResult> ProcessAsync(ProcessPaymentRequest request)
        {
            try
            {
                // Create domain entity
                var payment = Payment.Create(request.Amount, request.Currency);

                // Save pending payment
                await _paymentRepository.SaveAsync(payment);

                // Charge via gateway
                var response = await _paymentGateway.ChargeAsync(
                    request.Amount,
                    request.Currency,
                    request.CardToken);

                if (response.Success)
                {
                    payment.MarkAsProcessing(response.TransactionId);
                    payment.MarkAsCompleted();
                    await _paymentRepository.SaveAsync(payment);

                    // Send notification
                    await _notificationService.SendPaymentConfirmationAsync(
                        payment.Id,
                        "customer@example.com");

                    _logger.LogInformation("Payment {PaymentId} completed successfully", payment.Id);

                    return new PaymentResult
                    {
                        PaymentId = payment.Id,
                        Success = true,
                        Message = "Payment processed successfully"
                    };
                }
                else
                {
                    payment.MarkAsFailed();
                    await _paymentRepository.SaveAsync(payment);

                    return new PaymentResult
                    {
                        PaymentId = payment.Id,
                        Success = false,
                        Message = response.ErrorMessage
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing payment");
                return new PaymentResult
                {
                    Success = false,
                    Message = "An error occurred processing the payment"
                };
            }
        }
    }
}

// Adapters (Outside the Hexagon)

// Primary Adapter - REST API
namespace Adapters.Web
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentsController : ControllerBase
    {
        private readonly IProcessPaymentUseCase _processPayment;

        public PaymentsController(IProcessPaymentUseCase processPayment)
        {
            _processPayment = processPayment;
        }

        [HttpPost]
        public async Task<IActionResult> ProcessPayment([FromBody] PaymentRequest request)
        {
            var result = await _processPayment.ProcessAsync(new ProcessPaymentRequest
            {
                Amount = request.Amount,
                Currency = request.Currency,
                CardToken = request.CardToken
            });

            return result.Success
                ? Ok(result)
                : BadRequest(result);
        }
    }

    public class PaymentRequest
    {
        public decimal Amount { get; set; }
        public string Currency { get; set; }
        public string CardToken { get; set; }
    }
}

// Secondary Adapter - Stripe Payment Gateway
namespace Adapters.PaymentGateways
{
    public class StripePaymentGateway : IPaymentGateway
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public StripePaymentGateway(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task<GatewayResponse> ChargeAsync(decimal amount, string currency, string cardToken)
        {
            try
            {
                var response = await _httpClient.PostAsJsonAsync("/v1/charges", new
                {
                    amount = (int)(amount * 100), // Stripe uses cents
                    currency = currency.ToLower(),
                    source = cardToken
                });

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<StripeChargeResponse>();
                    return new GatewayResponse
                    {
                        Success = true,
                        TransactionId = result.Id
                    };
                }

                return new GatewayResponse
                {
                    Success = false,
                    ErrorMessage = "Payment gateway error"
                };
            }
            catch (Exception ex)
            {
                return new GatewayResponse
                {
                    Success = false,
                    ErrorMessage = ex.Message
                };
            }
        }
    }

    public class StripeChargeResponse
    {
        public string Id { get; set; }
        public bool Paid { get; set; }
    }
}

// Secondary Adapter - SQL Repository
namespace Adapters.Persistence
{
    public class SqlPaymentRepository : IPaymentRepository
    {
        private readonly ApplicationDbContext _context;

        public SqlPaymentRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task SaveAsync(Payment payment)
        {
            var existing = await _context.Payments.FindAsync(payment.Id);
            if (existing == null)
            {
                await _context.Payments.AddAsync(payment);
            }
            else
            {
                _context.Payments.Update(payment);
            }

            await _context.SaveChangesAsync();
        }

        public async Task<Payment> GetByIdAsync(Guid id)
        {
            return await _context.Payments.FindAsync(id);
        }
    }
}

// Secondary Adapter - Email Notifications
namespace Adapters.Notifications
{
    public class EmailNotificationService : INotificationService
    {
        private readonly IEmailSender _emailSender;

        public EmailNotificationService(IEmailSender emailSender)
        {
            _emailSender = emailSender;
        }

        public async Task SendPaymentConfirmationAsync(Guid paymentId, string email)
        {
            await _emailSender.SendAsync(
                email,
                "Payment Confirmation",
                $"Your payment {paymentId} was processed successfully");
        }
    }
}

// Dependency Injection Setup
namespace Startup
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddHexagonalArchitecture(this IServiceCollection services)
        {
            // Core (Use Cases)
            services.AddScoped<IProcessPaymentUseCase, ProcessPaymentService>();

            // Adapters (Ports Implementation)
            services.AddScoped<IPaymentGateway, StripePaymentGateway>();
            services.AddScoped<IPaymentRepository, SqlPaymentRepository>();
            services.AddScoped<INotificationService, EmailNotificationService>();

            return services;
        }
    }
}
```

### **Architecture Comparison:**

| Aspect | Layered | Clean | Hexagonal |
|--------|---------|-------|-----------|
| **Complexity** | Low | Medium | Medium-High |
| **Testability** | Medium | High | Very High |
| **Flexibility** | Low | High | Very High |
| **Learning Curve** | Easy | Medium | Steep |
| **Best For** | Simple CRUD apps | Enterprise apps | Complex domains |
| **Dependencies** | Top-down | Inward | Ports/Adapters |
| **Coupling** | Higher | Lower | Lowest |

### **Best Practices:**

1. **Dependency Rule**: Dependencies should point inward toward business logic
2. **Separation of Concerns**: Each layer/port has a single responsibility
3. **Testability**: Business logic should be testable without infrastructure
4. **Domain-Centric**: Keep domain logic free from framework dependencies
5. **Ports and Adapters**: Define clear interfaces between core and infrastructure
6. **Use Case Driven**: Organize by use cases, not technical layers
7. **Avoid Leaky Abstractions**: Don't let infrastructure details leak into domain

### **When to Use Each:**

**Layered Architecture:**
- Small to medium applications
- CRUD-heavy applications
- Team familiar with traditional patterns
- Rapid development needed

**Clean Architecture:**
- Medium to large applications
- Long-term maintainability important
- Complex business rules
- Multiple UI or delivery mechanisms

**Hexagonal Architecture:**
- Complex domain logic
- Multiple external integrations
- Need to swap implementations easily
- High testability requirements
- Domain-Driven Design projects

---

## **Q382. Explain SOLID principles with practical C# examples. How do they improve code quality and maintainability?**

### **Answer:**

SOLID principles are five design principles that make software designs more understandable, flexible, and maintainable.

### **1. Single Responsibility Principle (SRP):**

*A class should have one, and only one, reason to change.*

```csharp
// ❌ Violates SRP - Multiple responsibilities
public class UserService
{
    public void CreateUser(User user)
    {
        // Validate user
        if (string.IsNullOrEmpty(user.Email))
            throw new ValidationException("Email is required");

        // Save to database
        using var connection = new SqlConnection("connection string");
        connection.Open();
        var command = new SqlCommand("INSERT INTO Users...", connection);
        command.ExecuteNonQuery();

        // Send email
        var smtpClient = new SmtpClient("smtp.server.com");
        smtpClient.Send(new MailMessage("from@example.com", user.Email, "Welcome", "Welcome!"));

        // Log
        File.AppendAllText("log.txt", $"User {user.Email} created");
    }
}

// ✅ Follows SRP - Single responsibility per class
public interface IUserValidator
{
    ValidationResult Validate(User user);
}

public class UserValidator : IUserValidator
{
    public ValidationResult Validate(User user)
    {
        var errors = new List<string>();

        if (string.IsNullOrEmpty(user.Email))
            errors.Add("Email is required");

        if (string.IsNullOrEmpty(user.Name))
            errors.Add("Name is required");

        return new ValidationResult
        {
            IsValid = !errors.Any(),
            Errors = errors
        };
    }
}

public interface IUserRepository
{
    Task CreateAsync(User user);
}

public class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;

    public UserRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task CreateAsync(User user)
    {
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
    }
}

public interface IEmailService
{
    Task SendWelcomeEmailAsync(string email, string name);
}

public class EmailService : IEmailService
{
    private readonly IEmailSender _emailSender;

    public EmailService(IEmailSender emailSender)
    {
        _emailSender = emailSender;
    }

    public async Task SendWelcomeEmailAsync(string email, string name)
    {
        await _emailSender.SendAsync(
            email,
            "Welcome",
            $"Welcome {name}!");
    }
}

// Orchestrator with single responsibility: coordinate user creation
public class UserService
{
    private readonly IUserValidator _validator;
    private readonly IUserRepository _repository;
    private readonly IEmailService _emailService;
    private readonly ILogger<UserService> _logger;

    public UserService(
        IUserValidator validator,
        IUserRepository repository,
        IEmailService emailService,
        ILogger<UserService> logger)
    {
        _validator = validator;
        _repository = repository;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<Result> CreateUserAsync(User user)
    {
        // Validate
        var validationResult = _validator.Validate(user);
        if (!validationResult.IsValid)
            return Result.Failure(validationResult.Errors);

        try
        {
            // Save
            await _repository.CreateAsync(user);

            // Send email
            await _emailService.SendWelcomeEmailAsync(user.Email, user.Name);

            // Log
            _logger.LogInformation("User {Email} created successfully", user.Email);

            return Result.Success();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating user {Email}", user.Email);
            return Result.Failure("An error occurred creating the user");
        }
    }
}
```

### **2. Open/Closed Principle (OCP):**

*Software entities should be open for extension but closed for modification.*

```csharp
// ❌ Violates OCP - Need to modify class to add new discount types
public class DiscountCalculator
{
    public decimal CalculateDiscount(decimal amount, string customerType)
    {
        if (customerType == "Regular")
            return amount * 0.05m;
        else if (customerType == "Premium")
            return amount * 0.10m;
        else if (customerType == "VIP")
            return amount * 0.20m;
        else
            return 0;
    }
}

// ✅ Follows OCP - Can extend without modifying existing code
public interface IDiscountStrategy
{
    decimal CalculateDiscount(decimal amount);
    bool AppliesTo(Customer customer);
}

public class RegularCustomerDiscount : IDiscountStrategy
{
    public decimal CalculateDiscount(decimal amount) => amount * 0.05m;

    public bool AppliesTo(Customer customer) =>
        customer.Type == CustomerType.Regular;
}

public class PremiumCustomerDiscount : IDiscountStrategy
{
    public decimal CalculateDiscount(decimal amount) => amount * 0.10m;

    public bool AppliesTo(Customer customer) =>
        customer.Type == CustomerType.Premium;
}

public class VIPCustomerDiscount : IDiscountStrategy
{
    public decimal CalculateDiscount(decimal amount) => amount * 0.20m;

    public bool AppliesTo(Customer customer) =>
        customer.Type == CustomerType.VIP;
}

// New discount type - just add new class, no modifications needed
public class FirstTimeCustomerDiscount : IDiscountStrategy
{
    public decimal CalculateDiscount(decimal amount) => amount * 0.15m;

    public bool AppliesTo(Customer customer) =>
        customer.OrderCount == 0;
}

public class DiscountCalculator
{
    private readonly IEnumerable<IDiscountStrategy> _discountStrategies;

    public DiscountCalculator(IEnumerable<IDiscountStrategy> discountStrategies)
    {
        _discountStrategies = discountStrategies;
    }

    public decimal CalculateDiscount(decimal amount, Customer customer)
    {
        var applicableStrategy = _discountStrategies
            .FirstOrDefault(s => s.AppliesTo(customer));

        return applicableStrategy?.CalculateDiscount(amount) ?? 0;
    }
}

// DI Registration
services.AddTransient<IDiscountStrategy, RegularCustomerDiscount>();
services.AddTransient<IDiscountStrategy, PremiumCustomerDiscount>();
services.AddTransient<IDiscountStrategy, VIPCustomerDiscount>();
services.AddTransient<IDiscountStrategy, FirstTimeCustomerDiscount>();
services.AddTransient<DiscountCalculator>();
```

### **3. Liskov Substitution Principle (LSP):**

*Objects of a superclass should be replaceable with objects of its subclasses without breaking the application.*

```csharp
// ❌ Violates LSP - Rectangle can't properly substitute Square
public class Rectangle
{
    public virtual int Width { get; set; }
    public virtual int Height { get; set; }

    public int CalculateArea() => Width * Height;
}

public class Square : Rectangle
{
    public override int Width
    {
        get => base.Width;
        set
        {
            base.Width = value;
            base.Height = value; // Violates LSP - unexpected side effect
        }
    }

    public override int Height
    {
        get => base.Height;
        set
        {
            base.Width = value;
            base.Height = value; // Violates LSP - unexpected side effect
        }
    }
}

// This breaks when using Square as Rectangle
void TestLSP()
{
    Rectangle rect = new Square();
    rect.Width = 5;
    rect.Height = 10;
    // Expected area: 50, but actual: 100 (because square sets both dimensions)
    Assert.Equal(50, rect.CalculateArea()); // FAILS!
}

// ✅ Follows LSP - Proper abstraction
public interface IShape
{
    int CalculateArea();
}

public class Rectangle : IShape
{
    public int Width { get; }
    public int Height { get; }

    public Rectangle(int width, int height)
    {
        Width = width;
        Height = height;
    }

    public int CalculateArea() => Width * Height;
}

public class Square : IShape
{
    public int SideLength { get; }

    public Square(int sideLength)
    {
        SideLength = sideLength;
    }

    public int CalculateArea() => SideLength * SideLength;
}

// Both can be used interchangeably
void TestLSP()
{
    IShape rectangle = new Rectangle(5, 10);
    IShape square = new Square(5);

    Assert.Equal(50, rectangle.CalculateArea()); // PASS
    Assert.Equal(25, square.CalculateArea()); // PASS
}

// ✅ Another LSP example - Payment processors
public interface IPaymentProcessor
{
    Task<PaymentResult> ProcessPaymentAsync(decimal amount, PaymentMethod method);
}

public class CreditCardProcessor : IPaymentProcessor
{
    public async Task<PaymentResult> ProcessPaymentAsync(decimal amount, PaymentMethod method)
    {
        // Process credit card payment
        await Task.Delay(100); // Simulate API call
        return new PaymentResult { Success = true, TransactionId = Guid.NewGuid().ToString() };
    }
}

public class PayPalProcessor : IPaymentProcessor
{
    public async Task<PaymentResult> ProcessPaymentAsync(decimal amount, PaymentMethod method)
    {
        // Process PayPal payment
        await Task.Delay(100); // Simulate API call
        return new PaymentResult { Success = true, TransactionId = Guid.NewGuid().ToString() };
    }
}

// Any IPaymentProcessor can be substituted
public class CheckoutService
{
    private readonly IPaymentProcessor _paymentProcessor;

    public CheckoutService(IPaymentProcessor paymentProcessor)
    {
        _paymentProcessor = paymentProcessor;
    }

    public async Task<bool> ProcessCheckoutAsync(Order order)
    {
        var result = await _paymentProcessor.ProcessPaymentAsync(
            order.TotalAmount,
            order.PaymentMethod);

        return result.Success;
    }
}
```

### **4. Interface Segregation Principle (ISP):**

*Clients should not be forced to depend on interfaces they don't use.*

```csharp
// ❌ Violates ISP - Fat interface
public interface IWorker
{
    void Work();
    void Eat();
    void Sleep();
    void GetPaid();
}

public class HumanWorker : IWorker
{
    public void Work() { /* Implementation */ }
    public void Eat() { /* Implementation */ }
    public void Sleep() { /* Implementation */ }
    public void GetPaid() { /* Implementation */ }
}

public class RobotWorker : IWorker
{
    public void Work() { /* Implementation */ }
    public void Eat() { throw new NotImplementedException(); } // ❌ Doesn't eat!
    public void Sleep() { throw new NotImplementedException(); } // ❌ Doesn't sleep!
    public void GetPaid() { throw new NotImplementedException(); } // ❌ Doesn't get paid!
}

// ✅ Follows ISP - Segregated interfaces
public interface IWorkable
{
    void Work();
}

public interface IEatable
{
    void Eat();
}

public interface ISleepable
{
    void Sleep();
}

public interface IPayable
{
    void GetPaid();
}

public class HumanWorker : IWorkable, IEatable, ISleepable, IPayable
{
    public void Work() { Console.WriteLine("Human working"); }
    public void Eat() { Console.WriteLine("Human eating"); }
    public void Sleep() { Console.WriteLine("Human sleeping"); }
    public void GetPaid() { Console.WriteLine("Human getting paid"); }
}

public class RobotWorker : IWorkable
{
    public void Work() { Console.WriteLine("Robot working 24/7"); }
}

// ✅ Real-world example - Document interfaces
public interface IReadableDocument
{
    string GetContent();
    int GetPageCount();
}

public interface IEditableDocument
{
    void SetContent(string content);
    void AddPage(string pageContent);
}

public interface IPrintableDocument
{
    byte[] PrintToPdf();
}

public interface IShareableDocument
{
    string GetShareLink();
    void SetPermissions(string userId, Permission permission);
}

// PDF document - read and print only
public class PdfDocument : IReadableDocument, IPrintableDocument
{
    public string GetContent() => "PDF content";
    public int GetPageCount() => 10;
    public byte[] PrintToPdf() => new byte[] { /* PDF bytes */ };
}

// Word document - read, edit, print, and share
public class WordDocument : IReadableDocument, IEditableDocument, IPrintableDocument, IShareableDocument
{
    private string _content;
    private List<string> _pages = new();

    public string GetContent() => _content;
    public int GetPageCount() => _pages.Count;
    public void SetContent(string content) => _content = content;
    public void AddPage(string pageContent) => _pages.Add(pageContent);
    public byte[] PrintToPdf() => new byte[] { /* PDF bytes */ };
    public string GetShareLink() => "https://share.example.com/doc123";
    public void SetPermissions(string userId, Permission permission) { /* Implementation */ }
}

// View-only document - read and share only
public class ViewOnlyDocument : IReadableDocument, IShareableDocument
{
    public string GetContent() => "Protected content";
    public int GetPageCount() => 5;
    public string GetShareLink() => "https://share.example.com/readonly123";
    public void SetPermissions(string userId, Permission permission) { /* Implementation */ }
}

// Client code only depends on what it needs
public class DocumentPrinter
{
    public void Print(IPrintableDocument document)
    {
        var pdf = document.PrintToPdf();
        // Send to printer
    }
}

public class DocumentEditor
{
    public void Edit(IEditableDocument document)
    {
        document.SetContent("New content");
    }
}
```

### **5. Dependency Inversion Principle (DIP):**

*High-level modules should not depend on low-level modules. Both should depend on abstractions.*

```csharp
// ❌ Violates DIP - High-level depends on low-level
public class EmailNotification
{
    public void Send(string message)
    {
        var smtpClient = new SmtpClient("smtp.example.com");
        smtpClient.Send("from@example.com", "to@example.com", "Subject", message);
    }
}

public class OrderProcessor // High-level
{
    private readonly EmailNotification _notification = new(); // Depends on concrete class

    public void ProcessOrder(Order order)
    {
        // Process order
        _notification.Send($"Order {order.Id} processed");
    }
}

// ✅ Follows DIP - Both depend on abstraction
public interface INotificationService // Abstraction
{
    Task SendAsync(string recipient, string message);
}

public class EmailNotificationService : INotificationService // Low-level
{
    private readonly IEmailSender _emailSender;

    public EmailNotificationService(IEmailSender emailSender)
    {
        _emailSender = emailSender;
    }

    public async Task SendAsync(string recipient, string message)
    {
        await _emailSender.SendAsync(
            recipient,
            "Order Notification",
            message);
    }
}

public class SmsNotificationService : INotificationService // Low-level
{
    private readonly ISmsSender _smsSender;

    public SmsNotificationService(ISmsSender smsSender)
    {
        _smsSender = smsSender;
    }

    public async Task SendAsync(string recipient, string message)
    {
        await _smsSender.SendAsync(recipient, message);
    }
}

public class OrderProcessor // High-level
{
    private readonly INotificationService _notificationService; // Depends on abstraction

    public OrderProcessor(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task ProcessOrderAsync(Order order)
    {
        // Process order
        await _notificationService.SendAsync(
            order.CustomerEmail,
            $"Order {order.Id} processed");
    }
}

// DI Container configuration
services.AddScoped<INotificationService, EmailNotificationService>();
// Easy to swap implementations
// services.AddScoped<INotificationService, SmsNotificationService>();

// ✅ Advanced DIP example - Data access
public interface IRepository<T> where T : class // Abstraction
{
    Task<T> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(Guid id);
}

public class SqlRepository<T> : IRepository<T> where T : class // Low-level
{
    private readonly ApplicationDbContext _context;

    public SqlRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<T> GetByIdAsync(Guid id)
    {
        return await _context.Set<T>().FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _context.Set<T>().ToListAsync();
    }

    public async Task AddAsync(T entity)
    {
        await _context.Set<T>().AddAsync(entity);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(T entity)
    {
        _context.Set<T>().Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var entity = await GetByIdAsync(id);
        if (entity != null)
        {
            _context.Set<T>().Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}

public class ProductService // High-level
{
    private readonly IRepository<Product> _repository; // Depends on abstraction

    public ProductService(IRepository<Product> repository)
    {
        _repository = repository;
    }

    public async Task<Product> GetProductAsync(Guid id)
    {
        return await _repository.GetByIdAsync(id);
    }

    public async Task CreateProductAsync(Product product)
    {
        await _repository.AddAsync(product);
    }
}

// Easy to swap implementations
services.AddScoped(typeof(IRepository<>), typeof(SqlRepository<>));
// Could easily switch to MongoDB, CosmosDB, etc.
```

### **SOLID Benefits:**

| Principle | Benefit | Without It |
|-----------|---------|------------|
| **SRP** | Easier to understand, test, maintain | God classes, tight coupling |
| **OCP** | Extensible without breaking existing code | Fragile code, regression bugs |
| **LSP** | Predictable behavior, polymorphism works | Runtime errors, unexpected behavior |
| **ISP** | Flexible, focused interfaces | Unnecessary dependencies, bloat |
| **DIP** | Loosely coupled, testable | Hard-coded dependencies, inflexible |

### **Best Practices:**

1. **SRP**: Each class should do one thing well
2. **OCP**: Use abstraction and polymorphism for extension
3. **LSP**: Ensure derived classes are truly substitutable
4. **ISP**: Keep interfaces small and focused
5. **DIP**: Depend on abstractions, inject dependencies

### **Common Violations to Avoid:**

```csharp
// ❌ Multiple anti-patterns
public class BadOrderService
{
    // Violates DIP - direct dependency on concrete class
    private readonly SqlConnection _connection = new SqlConnection("...");

    // Violates SRP - too many responsibilities
    public void ProcessOrder(Order order)
    {
        // Validation
        if (order.Items.Count == 0)
            throw new Exception("No items");

        // Database access
        _connection.Open();
        var cmd = new SqlCommand("INSERT INTO Orders...", _connection);
        cmd.ExecuteNonQuery();

        // Email sending
        var smtp = new SmtpClient();
        smtp.Send("...");

        // Logging
        File.AppendAllText("log.txt", "...");

        // Payment processing
        var paymentGateway = new PayPalGateway();
        paymentGateway.Charge(order.Total);
    }

    // Violates ISP - forces clients to depend on unused methods
    public void SendEmail() { }
    public void PrintInvoice() { }
    public void GenerateReport() { }
}
```

---

## **Q383. What is Domain-Driven Design (DDD)? Explain entities, value objects, aggregates, and bounded contexts with C# examples.**

### **Answer:**

Domain-Driven Design is an approach to software development that focuses on modeling the business domain and using that model to drive the design of the software.

### **1. Entities:**

Entities have a unique identity that persists over time and across different states.

```csharp
// ✅ Entity - Has unique identity
public class Order : Entity<Guid>
{
    public string OrderNumber { get; private set; }
    public DateTime OrderDate { get; private set; }
    public OrderStatus Status { get; private set; }
    public decimal TotalAmount { get; private set; }

    private readonly List<OrderLine> _orderLines = new();
    public IReadOnlyCollection<OrderLine> OrderLines => _orderLines.AsReadOnly();

    // Private constructor for EF
    private Order() { }

    // Factory method
    public static Order Create(string orderNumber)
    {
        return new Order
        {
            Id = Guid.NewGuid(),
            OrderNumber = orderNumber,
            OrderDate = DateTime.UtcNow,
            Status = OrderStatus.Draft
        };
    }

    // Business logic methods
    public void AddLine(Product product, int quantity, decimal unitPrice)
    {
        if (Status != OrderStatus.Draft)
            throw new DomainException("Cannot modify a non-draft order");

        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        var line = OrderLine.Create(Id, product.Id, product.Name, quantity, unitPrice);
        _orderLines.Add(line);

        RecalculateTotalAmount();
    }

    public void Submit()
    {
        if (!_orderLines.Any())
            throw new DomainException("Cannot submit an empty order");

        Status = OrderStatus.Submitted;
    }

    public void Cancel()
    {
        if (Status == OrderStatus.Shipped)
            throw new DomainException("Cannot cancel a shipped order");

        Status = OrderStatus.Cancelled;
    }

    private void RecalculateTotalAmount()
    {
        TotalAmount = _orderLines.Sum(l => l.LineTotal);
    }

    // Override Equals based on Id (entity equality)
    public override bool Equals(object obj)
    {
        if (obj is not Order other)
            return false;

        if (ReferenceEquals(this, other))
            return true;

        return Id.Equals(other.Id);
    }

    public override int GetHashCode() => Id.GetHashCode();
}

// Base entity class
public abstract class Entity<TId>
{
    public TId Id { get; protected set; }
}

public enum OrderStatus
{
    Draft,
    Submitted,
    Confirmed,
    Shipped,
    Cancelled
}
```

### **2. Value Objects:**

Value objects have no unique identity and are defined by their attributes. They are immutable and compared by value.

```csharp
// ✅ Value Object - Money
public class Money : ValueObject
{
    public decimal Amount { get; }
    public string Currency { get; }

    public Money(decimal amount, string currency)
    {
        if (amount < 0)
            throw new ArgumentException("Amount cannot be negative", nameof(amount));

        if (string.IsNullOrWhiteSpace(currency))
            throw new ArgumentException("Currency is required", nameof(currency));

        Amount = amount;
        Currency = currency.ToUpper();
    }

    // Value object operations return new instances
    public Money Add(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException("Cannot add money with different currencies");

        return new Money(Amount + other.Amount, Currency);
    }

    public Money Subtract(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException("Cannot subtract money with different currencies");

        return new Money(Amount - other.Amount, Currency);
    }

    public Money Multiply(decimal multiplier)
    {
        return new Money(Amount * multiplier, Currency);
    }

    // Value objects are compared by value
    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Amount;
        yield return Currency;
    }

    public override string ToString() => $"{Amount:N2} {Currency}";
}

// Base value object class
public abstract class ValueObject
{
    protected abstract IEnumerable<object> GetEqualityComponents();

    public override bool Equals(object obj)
    {
        if (obj == null || obj.GetType() != GetType())
            return false;

        var other = (ValueObject)obj;

        return GetEqualityComponents().SequenceEqual(other.GetEqualityComponents());
    }

    public override int GetHashCode()
    {
        return GetEqualityComponents()
            .Select(x => x?.GetHashCode() ?? 0)
            .Aggregate((x, y) => x ^ y);
    }

    public static bool operator ==(ValueObject left, ValueObject right)
    {
        if (left is null && right is null)
            return true;

        if (left is null || right is null)
            return false;

        return left.Equals(right);
    }

    public static bool operator !=(ValueObject left, ValueObject right)
    {
        return !(left == right);
    }
}

// ✅ Value Object - Address
public class Address : ValueObject
{
    public string Street { get; }
    public string City { get; }
    public string State { get; }
    public string ZipCode { get; }
    public string Country { get; }

    public Address(string street, string city, string state, string zipCode, string country)
    {
        Street = street ?? throw new ArgumentNullException(nameof(street));
        City = city ?? throw new ArgumentNullException(nameof(city));
        State = state ?? throw new ArgumentNullException(nameof(state));
        ZipCode = zipCode ?? throw new ArgumentNullException(nameof(zipCode));
        Country = country ?? throw new ArgumentNullException(nameof(country));
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Street;
        yield return City;
        yield return State;
        yield return ZipCode;
        yield return Country;
    }

    public override string ToString()
    {
        return $"{Street}, {City}, {State} {ZipCode}, {Country}";
    }
}

// ✅ Value Object - Email
public class Email : ValueObject
{
    public string Value { get; }

    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Email cannot be empty", nameof(value));

        if (!IsValidEmail(value))
            throw new ArgumentException("Invalid email format", nameof(value));

        Value = value.ToLower();
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Value;
    }

    public override string ToString() => Value;

    // Implicit conversion
    public static implicit operator string(Email email) => email.Value;
}

// Usage of value objects
public class Customer : Entity<Guid>
{
    public string Name { get; private set; }
    public Email Email { get; private set; }
    public Address ShippingAddress { get; private set; }
    public Address BillingAddress { get; private set; }

    public void UpdateEmail(Email newEmail)
    {
        Email = newEmail ?? throw new ArgumentNullException(nameof(newEmail));
    }

    public void UpdateShippingAddress(Address newAddress)
    {
        ShippingAddress = newAddress ?? throw new ArgumentNullException(nameof(newAddress));
    }
}
```

### **3. Aggregates and Aggregate Roots:**

An aggregate is a cluster of domain objects that can be treated as a single unit. The aggregate root is the entry point.

```csharp
// ✅ Aggregate Root - Order
public class Order : Entity<Guid>, IAggregateRoot
{
    // Aggregate root properties
    public string OrderNumber { get; private set; }
    public CustomerId CustomerId { get; private set; }
    public DateTime OrderDate { get; private set; }
    public OrderStatus Status { get; private set; }
    public Address ShippingAddress { get; private set; }
    public Money TotalAmount { get; private set; }

    // Aggregate members (not exposed publicly, only through root)
    private readonly List<OrderLine> _lines = new();
    public IReadOnlyCollection<OrderLine> Lines => _lines.AsReadOnly();

    private readonly List<OrderEvent> _events = new();
    public IReadOnlyCollection<OrderEvent> Events => _events.AsReadOnly();

    // Private constructor
    private Order() { }

    // Factory method
    public static Order Create(CustomerId customerId, Address shippingAddress)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            OrderNumber = GenerateOrderNumber(),
            CustomerId = customerId,
            OrderDate = DateTime.UtcNow,
            Status = OrderStatus.Draft,
            ShippingAddress = shippingAddress,
            TotalAmount = new Money(0, "USD")
        };

        order.AddEvent(new OrderCreatedEvent(order.Id, customerId));
        return order;
    }

    // Business operations (only way to modify aggregate)
    public void AddLine(ProductId productId, string productName, int quantity, Money unitPrice)
    {
        if (Status != OrderStatus.Draft)
            throw new DomainException("Cannot add lines to a non-draft order");

        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        var existingLine = _lines.FirstOrDefault(l => l.ProductId == productId);
        if (existingLine != null)
        {
            existingLine.UpdateQuantity(existingLine.Quantity + quantity);
        }
        else
        {
            var line = OrderLine.Create(Id, productId, productName, quantity, unitPrice);
            _lines.Add(line);
        }

        RecalculateTotalAmount();
        AddEvent(new OrderLineAddedEvent(Id, productId, quantity));
    }

    public void RemoveLine(Guid lineId)
    {
        if (Status != OrderStatus.Draft)
            throw new DomainException("Cannot remove lines from a non-draft order");

        var line = _lines.FirstOrDefault(l => l.Id == lineId);
        if (line != null)
        {
            _lines.Remove(line);
            RecalculateTotalAmount();
            AddEvent(new OrderLineRemovedEvent(Id, lineId));
        }
    }

    public void Submit()
    {
        if (!_lines.Any())
            throw new DomainException("Cannot submit an empty order");

        if (Status != OrderStatus.Draft)
            throw new DomainException("Only draft orders can be submitted");

        Status = OrderStatus.Submitted;
        AddEvent(new OrderSubmittedEvent(Id, TotalAmount));
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Submitted)
            throw new DomainException("Only submitted orders can be confirmed");

        Status = OrderStatus.Confirmed;
        AddEvent(new OrderConfirmedEvent(Id));
    }

    public void Ship()
    {
        if (Status != OrderStatus.Confirmed)
            throw new DomainException("Only confirmed orders can be shipped");

        Status = OrderStatus.Shipped;
        AddEvent(new OrderShippedEvent(Id, ShippingAddress));
    }

    public void Cancel()
    {
        if (Status == OrderStatus.Shipped)
            throw new DomainException("Cannot cancel a shipped order");

        Status = OrderStatus.Cancelled;
        AddEvent(new OrderCancelledEvent(Id));
    }

    // Private methods (aggregate invariants)
    private void RecalculateTotalAmount()
    {
        var total = _lines.Sum(l => l.LineTotal.Amount);
        TotalAmount = new Money(total, "USD");
    }

    private void AddEvent(OrderEvent @event)
    {
        _events.Add(@event);
    }

    private static string GenerateOrderNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";
    }

    public void ClearEvents()
    {
        _events.Clear();
    }
}

// Aggregate member (only accessible through root)
public class OrderLine : Entity<Guid>
{
    public Guid OrderId { get; private set; }
    public ProductId ProductId { get; private set; }
    public string ProductName { get; private set; }
    public int Quantity { get; private set; }
    public Money UnitPrice { get; private set; }
    public Money LineTotal { get; private set; }

    private OrderLine() { }

    internal static OrderLine Create(Guid orderId, ProductId productId, string productName, int quantity, Money unitPrice)
    {
        var line = new OrderLine
        {
            Id = Guid.NewGuid(),
            OrderId = orderId,
            ProductId = productId,
            ProductName = productName,
            Quantity = quantity,
            UnitPrice = unitPrice
        };

        line.CalculateLineTotal();
        return line;
    }

    internal void UpdateQuantity(int newQuantity)
    {
        if (newQuantity <= 0)
            throw new DomainException("Quantity must be positive");

        Quantity = newQuantity;
        CalculateLineTotal();
    }

    private void CalculateLineTotal()
    {
        LineTotal = UnitPrice.Multiply(Quantity);
    }
}

// Marker interface for aggregate roots
public interface IAggregateRoot
{
}

// Strong-typed IDs
public record CustomerId(Guid Value);
public record ProductId(Guid Value);

// Domain events
public abstract class OrderEvent
{
    public Guid OrderId { get; protected set; }
    public DateTime OccurredAt { get; protected set; } = DateTime.UtcNow;
}

public class OrderCreatedEvent : OrderEvent
{
    public CustomerId CustomerId { get; }

    public OrderCreatedEvent(Guid orderId, CustomerId customerId)
    {
        OrderId = orderId;
        CustomerId = customerId;
    }
}

public class OrderLineAddedEvent : OrderEvent
{
    public ProductId ProductId { get; }
    public int Quantity { get; }

    public OrderLineAddedEvent(Guid orderId, ProductId productId, int quantity)
    {
        OrderId = orderId;
        ProductId = productId;
        Quantity = quantity;
    }
}

public class OrderLineRemovedEvent : OrderEvent
{
    public Guid LineId { get; }

    public OrderLineRemovedEvent(Guid orderId, Guid lineId)
    {
        OrderId = orderId;
        LineId = lineId;
    }
}

public class OrderSubmittedEvent : OrderEvent
{
    public Money TotalAmount { get; }

    public OrderSubmittedEvent(Guid orderId, Money totalAmount)
    {
        OrderId = orderId;
        TotalAmount = totalAmount;
    }
}

public class OrderConfirmedEvent : OrderEvent
{
    public OrderConfirmedEvent(Guid orderId)
    {
        OrderId = orderId;
    }
}

public class OrderShippedEvent : OrderEvent
{
    public Address ShippingAddress { get; }

    public OrderShippedEvent(Guid orderId, Address shippingAddress)
    {
        OrderId = orderId;
        ShippingAddress = shippingAddress;
    }
}

public class OrderCancelledEvent : OrderEvent
{
    public OrderCancelledEvent(Guid orderId)
    {
        OrderId = orderId;
    }
}
```

### **4. Bounded Contexts:**

Bounded contexts define explicit boundaries within which a particular model is defined and applicable.

```csharp
// ✅ Bounded Context: Sales Context
namespace Sales.Domain
{
    // In Sales context, Customer is focused on purchasing
    public class Customer : Entity<Guid>
    {
        public string Name { get; private set; }
        public Email Email { get; private set; }
        public CustomerType Type { get; private set; } // Regular, Premium, VIP
        public decimal TotalPurchases { get; private set; }
        public int OrderCount { get; private set; }

        public void RecordPurchase(decimal amount)
        {
            TotalPurchases += amount;
            OrderCount++;

            // Upgrade customer type based on purchases
            if (TotalPurchases > 10000 && Type != CustomerType.VIP)
            {
                Type = CustomerType.VIP;
            }
            else if (TotalPurchases > 1000 && Type == CustomerType.Regular)
            {
                Type = CustomerType.Premium;
            }
        }

        public decimal GetDiscountPercentage()
        {
            return Type switch
            {
                CustomerType.Regular => 0,
                CustomerType.Premium => 10,
                CustomerType.VIP => 20,
                _ => 0
            };
        }
    }

    public enum CustomerType
    {
        Regular,
        Premium,
        VIP
    }
}

// ✅ Bounded Context: Support Context
namespace Support.Domain
{
    // In Support context, Customer is focused on tickets and support
    public class Customer : Entity<Guid>
    {
        public string Name { get; private set; }
        public Email Email { get; private set; }
        public SupportTier SupportTier { get; private set; }
        public int OpenTicketCount { get; private set; }
        public DateTime LastContactDate { get; private set; }

        private readonly List<SupportTicket> _tickets = new();
        public IReadOnlyCollection<SupportTicket> Tickets => _tickets.AsReadOnly();

        public void CreateTicket(string subject, string description, Priority priority)
        {
            var ticket = SupportTicket.Create(Id, subject, description, priority);
            _tickets.Add(ticket);
            OpenTicketCount++;
            LastContactDate = DateTime.UtcNow;
        }

        public void CloseTicket(Guid ticketId)
        {
            var ticket = _tickets.FirstOrDefault(t => t.Id == ticketId);
            if (ticket != null)
            {
                ticket.Close();
                OpenTicketCount--;
            }
        }

        public int GetResponseTimeMinutes()
        {
            return SupportTier switch
            {
                SupportTier.Basic => 240,      // 4 hours
                SupportTier.Business => 60,    // 1 hour
                SupportTier.Enterprise => 15,  // 15 minutes
                _ => 480                        // 8 hours
            };
        }
    }

    public enum SupportTier
    {
        Basic,
        Business,
        Enterprise
    }

    public class SupportTicket : Entity<Guid>
    {
        public Guid CustomerId { get; private set; }
        public string Subject { get; private set; }
        public string Description { get; private set; }
        public Priority Priority { get; private set; }
        public TicketStatus Status { get; private set; }
        public DateTime CreatedAt { get; private set; }
        public DateTime? ClosedAt { get; private set; }

        private SupportTicket() { }

        internal static SupportTicket Create(Guid customerId, string subject, string description, Priority priority)
        {
            return new SupportTicket
            {
                Id = Guid.NewGuid(),
                CustomerId = customerId,
                Subject = subject,
                Description = description,
                Priority = priority,
                Status = TicketStatus.Open,
                CreatedAt = DateTime.UtcNow
            };
        }

        internal void Close()
        {
            Status = TicketStatus.Closed;
            ClosedAt = DateTime.UtcNow;
        }
    }

    public enum Priority
    {
        Low,
        Normal,
        High,
        Critical
    }

    public enum TicketStatus
    {
        Open,
        InProgress,
        Resolved,
        Closed
    }
}

// ✅ Bounded Context: Shipping Context
namespace Shipping.Domain
{
    // In Shipping context, Customer is focused on delivery addresses
    public class Customer : Entity<Guid>
    {
        public string Name { get; private set; }
        public Address DefaultShippingAddress { get; private set; }

        private readonly List<Address> _savedAddresses = new();
        public IReadOnlyCollection<Address> SavedAddresses => _savedAddresses.AsReadOnly();

        public void AddSavedAddress(Address address)
        {
            if (!_savedAddresses.Contains(address))
            {
                _savedAddresses.Add(address);
            }
        }

        public void SetDefaultAddress(Address address)
        {
            DefaultShippingAddress = address;
            AddSavedAddress(address);
        }
    }

    public class Shipment : Entity<Guid>
    {
        public Guid OrderId { get; private set; }
        public Address ShippingAddress { get; private set; }
        public ShipmentStatus Status { get; private set; }
        public string TrackingNumber { get; private set; }
        public DateTime? ShippedDate { get; private set; }
        public DateTime? DeliveredDate { get; private set; }

        public static Shipment Create(Guid orderId, Address shippingAddress)
        {
            return new Shipment
            {
                Id = Guid.NewGuid(),
                OrderId = orderId,
                ShippingAddress = shippingAddress,
                Status = ShipmentStatus.Pending,
                TrackingNumber = GenerateTrackingNumber()
            };
        }

        public void Ship()
        {
            Status = ShipmentStatus.Shipped;
            ShippedDate = DateTime.UtcNow;
        }

        public void Deliver()
        {
            Status = ShipmentStatus.Delivered;
            DeliveredDate = DateTime.UtcNow;
        }

        private static string GenerateTrackingNumber()
        {
            return $"TRK{DateTime.UtcNow:yyyyMMddHHmmss}{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";
        }
    }

    public enum ShipmentStatus
    {
        Pending,
        Shipped,
        InTransit,
        Delivered
    }
}

// Context mapping using Anti-Corruption Layer (ACL)
namespace Sales.Infrastructure.Integration
{
    // Anti-Corruption Layer for translating between contexts
    public class SalesCustomerToShippingCustomerAdapter
    {
        public Shipping.Domain.Customer ToShippingCustomer(Sales.Domain.Customer salesCustomer, Address defaultAddress)
        {
            // Translate from Sales context to Shipping context
            // Prevent Sales domain concepts from leaking into Shipping
            return new Shipping.Domain.Customer
            {
                Id = salesCustomer.Id,
                Name = salesCustomer.Name,
                DefaultShippingAddress = defaultAddress
            };
        }
    }

    public class SalesCustomerToSupportCustomerAdapter
    {
        public Support.Domain.Customer ToSupportCustomer(Sales.Domain.Customer salesCustomer)
        {
            // Determine support tier based on customer type
            var supportTier = salesCustomer.Type switch
            {
                Sales.Domain.CustomerType.Regular => Support.Domain.SupportTier.Basic,
                Sales.Domain.CustomerType.Premium => Support.Domain.SupportTier.Business,
                Sales.Domain.CustomerType.VIP => Support.Domain.SupportTier.Enterprise,
                _ => Support.Domain.SupportTier.Basic
            };

            return new Support.Domain.Customer
            {
                Id = salesCustomer.Id,
                Name = salesCustomer.Name,
                Email = salesCustomer.Email,
                SupportTier = supportTier
            };
        }
    }
}
```

### **DDD Key Concepts Summary:**

| Concept | Definition | Example |
|---------|------------|---------|
| **Entity** | Object with unique identity | Order, Customer, Product |
| **Value Object** | Object defined by attributes, immutable | Money, Address, Email |
| **Aggregate** | Cluster of objects treated as a unit | Order + OrderLines |
| **Aggregate Root** | Entry point to the aggregate | Order (not OrderLine directly) |
| **Bounded Context** | Explicit boundary for a model | Sales, Support, Shipping |
| **Domain Event** | Something that happened in the domain | OrderCreated, OrderShipped |
| **Repository** | Abstraction for data access | IOrderRepository |

### **Best Practices:**

1. **Entities**: Use unique ID, implement business logic, ensure consistency
2. **Value Objects**: Make immutable, implement value equality, validate in constructor
3. **Aggregates**: Enforce invariants, access members only through root, keep small
4. **Bounded Contexts**: Clear boundaries, explicit interfaces, prevent concept leakage
5. **Ubiquitous Language**: Use domain terminology in code
6. **Domain Events**: Track what happened, enable loose coupling

---

## **Q384-Q400: Essential Architecture & Design Patterns Summary**

The following questions cover comprehensive architecture and design patterns essential for senior-level software architects:

### **Q384: CQRS (Command Query Responsibility Segregation)**

**Key Concepts:**
- Separate read and write models
- Commands change state, queries return data
- Eventual consistency between read and write stores
- Optimized read models for specific queries
- Event sourcing integration

**Implementation Pattern:**
```csharp
// Command side
public class CreateOrderCommand : IRequest<Guid>
{
    public string CustomerId { get; set; }
    public List<OrderItemDto> Items { get; set; }
}

public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Guid>
{
    private readonly IOrderRepository _repository;
    private readonly IEventBus _eventBus;

    public async Task<Guid> Handle(CreateOrderCommand command, CancellationToken cancellationToken)
    {
        var order = Order.Create(command.CustomerId);
        foreach (var item in command.Items)
        {
            order.AddItem(item.ProductId, item.Quantity);
        }

        await _repository.SaveAsync(order);
        await _eventBus.PublishAsync(new OrderCreatedEvent(order.Id));

        return order.Id;
    }
}

// Query side
public class GetOrderQuery : IRequest<OrderDto>
{
    public Guid OrderId { get; set; }
}

public class GetOrderQueryHandler : IRequestHandler<GetOrderQuery, OrderDto>
{
    private readonly IOrderReadRepository _readRepository;

    public async Task<OrderDto> Handle(GetOrderQuery query, CancellationToken cancellationToken)
    {
        return await _readRepository.GetByIdAsync(query.OrderId);
    }
}

// Read model (denormalized, optimized for queries)
public class OrderDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; }
    public string CustomerName { get; set; }
    public decimal TotalAmount { get; set; }
    public List<OrderItemDto> Items { get; set; }
}
```

**Best Practices:**
- Use MediatR for command/query dispatching
- Keep command models thin (data transfer only)
- Optimize read models for specific UI needs
- Use event handlers to update read models
- Consider eventual consistency trade-offs

---

### **Q385: Event Sourcing**

**Key Concepts:**
- Store events instead of current state
- Rebuild state by replaying events
- Complete audit trail
- Temporal queries (state at any point in time)
- Event store as source of truth

**Implementation Pattern:**
```csharp
// Domain events
public abstract class DomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public class OrderCreatedEvent : DomainEvent
{
    public Guid OrderId { get; set; }
    public string CustomerId { get; set; }
}

public class OrderItemAddedEvent : DomainEvent
{
    public Guid OrderId { get; set; }
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
}

// Event-sourced aggregate
public class Order
{
    private List<DomainEvent> _uncommittedEvents = new();
    public IReadOnlyList<DomainEvent> UncommittedEvents => _uncommittedEvents;

    public Guid Id { get; private set; }
    public string CustomerId { get; private set; }
    private List<OrderItem> _items = new();

    // Apply events to rebuild state
    public void Apply(DomainEvent @event)
    {
        When(@event);
        _uncommittedEvents.Add(@event);
    }

    private void When(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreatedEvent e:
                Id = e.OrderId;
                CustomerId = e.CustomerId;
                break;
            case OrderItemAddedEvent e:
                _items.Add(new OrderItem(e.ProductId, e.Quantity));
                break;
        }
    }

    // Rebuild from event stream
    public static Order FromEvents(IEnumerable<DomainEvent> events)
    {
        var order = new Order();
        foreach (var @event in events)
        {
            order.When(@event);
        }
        return order;
    }
}

// Event store
public interface IEventStore
{
    Task SaveEventsAsync(Guid aggregateId, IEnumerable<DomainEvent> events, int expectedVersion);
    Task<IEnumerable<DomainEvent>> GetEventsAsync(Guid aggregateId);
}
```

**Best Practices:**
- Implement snapshots for performance
- Version events for schema evolution
- Use event upcasting for compatibility
- Store events immutably
- Consider event store technology (EventStoreDB, Marten)

---

### **Q386: Repository Pattern**

**Key Concepts:**
- Abstraction over data access
- Collection-like interface
- Hides persistence details
- Unit testable
- Aggregate-oriented

**Best Practices:**
- One repository per aggregate root
- Generic repository for simple cases only
- Avoid IQueryable leaking
- Use specification pattern for complex queries
- Keep repositories focused

---

### **Q387: Unit of Work Pattern**

**Key Concepts:**
- Maintains list of objects affected by transaction
- Coordinates writes to database
- Ensures consistency
- Reduces database round-trips

**Implementation:**
```csharp
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}

public class UnitOfWork : IUnitOfWork
{
    private readonly DbContext _context;
    private IDbContextTransaction _transaction;

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        await SaveChangesAsync();
        await _transaction.CommitAsync();
    }

    public async Task RollbackTransactionAsync()
    {
        await _transaction.RollbackAsync();
    }
}
```

---

### **Q388: Specification Pattern**

**Key Concepts:**
- Encapsulates business rules
- Composable predicates
- Reusable query logic
- Testable in isolation

**Implementation:**
```csharp
public abstract class Specification<T>
{
    public abstract Expression<Func<T, bool>> ToExpression();

    public bool IsSatisfiedBy(T entity)
    {
        return ToExpression().Compile()(entity);
    }

    public Specification<T> And(Specification<T> other)
    {
        return new AndSpecification<T>(this, other);
    }

    public Specification<T> Or(Specification<T> other)
    {
        return new OrSpecification<T>(this, other);
    }
}

public class ActiveCustomerSpecification : Specification<Customer>
{
    public override Expression<Func<Customer, bool>> ToExpression()
    {
        return customer => customer.IsActive && !customer.IsDeleted;
    }
}

// Usage
var activeSpec = new ActiveCustomerSpecification();
var premiumSpec = new PremiumCustomerSpecification();
var activePremium = activeSpec.And(premiumSpec);

var customers = await _repository.FindAsync(activePremium.ToExpression());
```

---

### **Q389: Factory Pattern**

**Key Concepts:**
- Encapsulates object creation
- Hides creation complexity
- Returns interface/base class
- Supports polymorphism

**Types:**
- Simple Factory
- Factory Method
- Abstract Factory

---

### **Q390: Strategy Pattern**

**Key Concepts:**
- Defines family of algorithms
- Encapsulates each algorithm
- Makes them interchangeable
- Runtime algorithm selection

**Use Cases:**
- Payment processing
- Shipping calculation
- Tax calculation
- Discount strategies

---

### **Q391: Decorator Pattern**

**Key Concepts:**
- Adds behavior to objects dynamically
- Wraps original object
- Implements same interface
- Composition over inheritance

**Use Cases:**
- Caching decorator
- Logging decorator
- Retry decorator
- Validation decorator

---

### **Q392: Observer Pattern**

**Key Concepts:**
- One-to-many dependency
- Subject notifies observers
- Loose coupling
- Event-driven architecture

**Modern Implementation:**
- Domain events
- Event bus (MediatR)
- Pub/Sub messaging
- Reactive extensions (Rx)

---

### **Q393: Chain of Responsibility**

**Key Concepts:**
- Chain of handlers
- Each handler decides to process or pass
- Decouples sender and receiver
- Flexible handler ordering

**Use Cases:**
- Request validation pipeline
- Authentication/authorization chain
- Logging pipeline
- Exception handling chain

---

### **Q394: Template Method Pattern**

**Key Concepts:**
- Defines algorithm skeleton
- Subclasses implement specific steps
- Promotes code reuse
- Hollywood principle (don't call us, we'll call you)

---

### **Q395: Adapter Pattern**

**Key Concepts:**
- Converts one interface to another
- Enables incompatible interfaces to work together
- Wraps existing class
- Anti-Corruption Layer in DDD

**Use Cases:**
- Third-party library integration
- Legacy system integration
- Cross-context communication in DDD

---

### **Q396: API Design Best Practices**

**RESTful API Design:**
- Resource-based URLs
- HTTP verbs (GET, POST, PUT, DELETE)
- Proper status codes (200, 201, 400, 404, 500)
- Versioning (URL, header, content negotiation)
- HATEOAS for discoverability
- Pagination, filtering, sorting
- Rate limiting
- Consistent error responses
- API documentation (OpenAPI/Swagger)

**GraphQL Considerations:**
- Client-specified queries
- No over/under-fetching
- Single endpoint
- Schema-first design
- N+1 query problem mitigation

---

### **Q397: Microservices Patterns**

**Service Design Patterns:**
- **API Gateway**: Single entry point
- **Service Discovery**: Dynamic service location
- **Circuit Breaker**: Fault tolerance
- **Saga**: Distributed transactions
- **Event-Driven**: Asynchronous communication
- **CQRS**: Separate read/write models
- **Sidecar**: Cross-cutting concerns
- **Strangler Fig**: Legacy migration

**Data Patterns:**
- Database per service
- Shared database (anti-pattern)
- Event sourcing
- CQRS
- Saga pattern
- Outbox pattern
- API composition

---

### **Q398: Caching Strategies**

**Caching Levels:**
```csharp
// 1. In-Memory Cache (IMemoryCache)
_cache.Set("key", value, TimeSpan.FromMinutes(5));

// 2. Distributed Cache (Redis)
await _distributedCache.SetStringAsync("key", json, new DistributedCacheEntryOptions
{
    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
});

// 3. Response Caching
[ResponseCache(Duration = 60)]
public IActionResult Get() { }

// 4. Output Caching (.NET 7+)
app.MapGet("/", () => "Hello").CacheOutput();
```

**Cache Invalidation Strategies:**
- Time-based expiration (TTL)
- Event-based invalidation
- Cache-aside pattern
- Write-through cache
- Write-behind cache
- Refresh-ahead cache

**Best Practices:**
- Cache expensive operations
- Set appropriate TTL
- Handle cache miss gracefully
- Monitor cache hit ratio
- Use cache keys wisely
- Consider memory limits

---

### **Q399: Scalability Patterns**

**Horizontal vs Vertical Scaling:**
- **Horizontal**: Add more servers (scale out)
- **Vertical**: Add more resources to server (scale up)

**Scalability Patterns:**
```csharp
// Load Balancing
// - Round-robin
// - Least connections
// - IP hash
// - Weighted distribution

// Database Sharding
public interface IShardingStrategy
{
    int GetShardId(string key);
}

public class HashShardingStrategy : IShardingStrategy
{
    private readonly int _shardCount;

    public int GetShardId(string key)
    {
        return Math.Abs(key.GetHashCode() % _shardCount);
    }
}

// Read Replicas
public interface IDatabaseSelector
{
    DbContext GetReadContext();
    DbContext GetWriteContext();
}

// Async Processing
public class AsyncProcessor
{
    private readonly IBackgroundJobClient _jobClient;

    public void ProcessAsync(Order order)
    {
        _jobClient.Enqueue(() => ProcessOrderAsync(order.Id));
    }
}
```

**Scalability Best Practices:**
- Stateless services
- Database connection pooling
- Async/await for I/O operations
- Message queues for decoupling
- CDN for static content
- Caching at multiple levels
- Database indexing
- Read replicas for read-heavy workloads

---

### **Q400: System Design Principles**

**CAP Theorem:**
- **Consistency**: All nodes see same data
- **Availability**: Every request gets response
- **Partition Tolerance**: System continues despite network partition
- *Can only choose 2 of 3*

**SOLID Recap:**
- Single Responsibility
- Open/Closed
- Liskov Substitution
- Interface Segregation
- Dependency Inversion

**DRY (Don't Repeat Yourself):**
- Extract reusable logic
- Use inheritance/composition
- Avoid code duplication

**KISS (Keep It Simple, Stupid):**
- Simplest solution that works
- Avoid over-engineering
- Clear and readable code

**YAGNI (You Aren't Gonna Need It):**
- Don't add functionality until needed
- Avoid premature optimization
- Focus on current requirements

**Separation of Concerns:**
- Each module has distinct responsibility
- Reduces coupling
- Improves maintainability

**Fail Fast Principle:**
- Detect errors early
- Validate input immediately
- Throw exceptions for invalid state
- Don't hide errors

**Principle of Least Astonishment:**
- Code should behave as expected
- Consistent naming conventions
- Follow framework conventions
- Predictable behavior

**Performance Principles:**
```csharp
// 1. Measure before optimizing
[Benchmark]
public void MeasurePerformance() { }

// 2. Use appropriate data structures
// Dictionary<TKey, TValue> for O(1) lookup
// HashSet<T> for O(1) contains
// List<T> for sequential access

// 3. Async for I/O-bound operations
public async Task<Data> GetDataAsync()
{
    return await _httpClient.GetFromJsonAsync<Data>("url");
}

// 4. Use Span<T>/Memory<T> for high-performance scenarios
public void ProcessData(ReadOnlySpan<byte> data)
{
    // Zero-allocation processing
}

// 5. Pool expensive objects
private static readonly ArrayPool<byte> _pool = ArrayPool<byte>.Shared;

public void UsePooling()
{
    var buffer = _pool.Rent(1024);
    try
    {
        // Use buffer
    }
    finally
    {
        _pool.Return(buffer);
    }
}
```

**Security Principles:**
- Defense in depth
- Least privilege
- Secure by default
- Never trust user input
- Encrypt sensitive data
- Use parameterized queries
- Implement proper authentication/authorization
- Regular security audits

**Testing Principles:**
- Test pyramid: Unit > Integration > E2E
- AAA pattern (Arrange, Act, Assert)
- One assertion per test
- Test behavior, not implementation
- Mock external dependencies
- Achieve meaningful coverage (not just %)

---

## **Summary**

**Total Coverage for Q381-Q400:**

1. **Q381**: Architecture patterns (Layered, Clean, Hexagonal)
2. **Q382**: SOLID principles with practical examples
3. **Q383**: Domain-Driven Design (Entities, Value Objects, Aggregates, Bounded Contexts)
4. **Q384**: CQRS (Command Query Responsibility Segregation)
5. **Q385**: Event Sourcing
6. **Q386**: Repository Pattern
7. **Q387**: Unit of Work Pattern
8. **Q388**: Specification Pattern
9. **Q389**: Factory Pattern
10. **Q390**: Strategy Pattern
11. **Q391**: Decorator Pattern
12. **Q392**: Observer Pattern
13. **Q393**: Chain of Responsibility
14. **Q394**: Template Method Pattern
15. **Q395**: Adapter Pattern
16. **Q396**: API Design Best Practices (REST, GraphQL)
17. **Q397**: Microservices Patterns
18. **Q398**: Caching Strategies
19. **Q399**: Scalability Patterns
20. **Q400**: System Design Principles (CAP, SOLID, DRY, KISS, YAGNI)

This comprehensive set covers all essential software architecture and design patterns for senior-level software architects and engineers, with emphasis on:
- Architectural patterns and trade-offs
- SOLID and DDD principles
- Design patterns (GoF and modern)
- Scalability and performance
- Best practices and principles

Each topic includes practical C# code examples, best practices, and real-world application scenarios suitable for senior-level technical interviews.

---

**End of Q381-Q400: Software Architecture & System Design**

