# Interview Questions: Q321-Q340 (Microservices & Distributed Systems)

## Q321. What are the key principles and patterns for designing microservices architecture in .NET?

```csharp
/*
Microservices Architecture Principles and Patterns
*/

// ✅ EXCELLENT: Well-designed microservice structure
// Product Service - Single Responsibility

// Domain Model
public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public ProductStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Domain events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    public void AddDomainEvent(IDomainEvent eventItem)
    {
        _domainEvents.Add(eventItem);
    }

    public void ClearDomainEvents()
    {
        _domainEvents.Clear();
    }

    // Business logic
    public void UpdateStock(int quantity)
    {
        if (quantity < 0 && Math.Abs(quantity) > StockQuantity)
        {
            throw new InvalidOperationException("Insufficient stock");
        }

        StockQuantity += quantity;
        UpdatedAt = DateTime.UtcNow;

        AddDomainEvent(new ProductStockUpdatedEvent(Id, StockQuantity));
    }

    public void UpdatePrice(decimal newPrice)
    {
        if (newPrice <= 0)
        {
            throw new ArgumentException("Price must be positive", nameof(newPrice));
        }

        var oldPrice = Price;
        Price = newPrice;
        UpdatedAt = DateTime.UtcNow;

        AddDomainEvent(new ProductPriceChangedEvent(Id, oldPrice, newPrice));
    }
}

// Domain Events
public interface IDomainEvent
{
    DateTime OccurredOn { get; }
}

public class ProductStockUpdatedEvent : IDomainEvent
{
    public Guid ProductId { get; }
    public int NewStockQuantity { get; }
    public DateTime OccurredOn { get; }

    public ProductStockUpdatedEvent(Guid productId, int newStockQuantity)
    {
        ProductId = productId;
        NewStockQuantity = newStockQuantity;
        OccurredOn = DateTime.UtcNow;
    }
}

public class ProductPriceChangedEvent : IDomainEvent
{
    public Guid ProductId { get; }
    public decimal OldPrice { get; }
    public decimal NewPrice { get; }
    public DateTime OccurredOn { get; }

    public ProductPriceChangedEvent(Guid productId, decimal oldPrice, decimal newPrice)
    {
        ProductId = productId;
        OldPrice = oldPrice;
        NewPrice = newPrice;
        OccurredOn = DateTime.UtcNow;
    }
}

// ✅ API Gateway Pattern
public class ApiGateway
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ApiGateway> _logger;

    public ApiGateway(IHttpClientFactory httpClientFactory, ILogger<ApiGateway> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    // Aggregates data from multiple microservices
    public async Task<ProductDetailsDto> GetProductDetailsAsync(Guid productId)
    {
        // Call Product Service
        var productTask = GetProductAsync(productId);

        // Call Inventory Service
        var inventoryTask = GetInventoryAsync(productId);

        // Call Review Service
        var reviewsTask = GetProductReviewsAsync(productId);

        // Call Pricing Service
        var pricingTask = GetPricingAsync(productId);

        await Task.WhenAll(productTask, inventoryTask, reviewsTask, pricingTask);

        return new ProductDetailsDto
        {
            Product = await productTask,
            Inventory = await inventoryTask,
            Reviews = await reviewsTask,
            Pricing = await pricingTask
        };
    }

    private async Task<ProductDto> GetProductAsync(Guid productId)
    {
        var client = _httpClientFactory.CreateClient("ProductService");
        var response = await client.GetAsync($"/api/products/{productId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<ProductDto>();
    }

    private async Task<InventoryDto> GetInventoryAsync(Guid productId)
    {
        var client = _httpClientFactory.CreateClient("InventoryService");
        var response = await client.GetAsync($"/api/inventory/{productId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<InventoryDto>();
    }

    private async Task<List<ReviewDto>> GetProductReviewsAsync(Guid productId)
    {
        var client = _httpClientFactory.CreateClient("ReviewService");
        var response = await client.GetAsync($"/api/reviews/product/{productId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<ReviewDto>>();
    }

    private async Task<PricingDto> GetPricingAsync(Guid productId)
    {
        var client = _httpClientFactory.CreateClient("PricingService");
        var response = await client.GetAsync($"/api/pricing/{productId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<PricingDto>();
    }
}

// ✅ Service Discovery Pattern
public interface IServiceDiscovery
{
    Task<ServiceEndpoint> DiscoverServiceAsync(string serviceName);
    Task RegisterServiceAsync(ServiceRegistration registration);
    Task DeregisterServiceAsync(string serviceId);
}

public class ConsulServiceDiscovery : IServiceDiscovery
{
    private readonly IConsulClient _consulClient;
    private readonly ILogger<ConsulServiceDiscovery> _logger;

    public ConsulServiceDiscovery(IConsulClient consulClient, ILogger<ConsulServiceDiscovery> logger)
    {
        _consulClient = consulClient;
        _logger = logger;
    }

    public async Task<ServiceEndpoint> DiscoverServiceAsync(string serviceName)
    {
        var services = await _consulClient.Health.Service(serviceName, null, true);

        if (!services.Response.Any())
        {
            throw new ServiceNotFoundException($"Service {serviceName} not found");
        }

        // Simple round-robin (in production, use more sophisticated load balancing)
        var service = services.Response[Random.Shared.Next(services.Response.Length)];

        return new ServiceEndpoint
        {
            ServiceName = serviceName,
            Host = service.Service.Address,
            Port = service.Service.Port,
            Scheme = "https"
        };
    }

    public async Task RegisterServiceAsync(ServiceRegistration registration)
    {
        var consulRegistration = new AgentServiceRegistration
        {
            ID = registration.ServiceId,
            Name = registration.ServiceName,
            Address = registration.Host,
            Port = registration.Port,
            Tags = registration.Tags,
            Check = new AgentServiceCheck
            {
                HTTP = $"{registration.Scheme}://{registration.Host}:{registration.Port}/health",
                Interval = TimeSpan.FromSeconds(10),
                Timeout = TimeSpan.FromSeconds(5),
                DeregisterCriticalServiceAfter = TimeSpan.FromMinutes(1)
            }
        };

        await _consulClient.Agent.ServiceRegister(consulRegistration);

        _logger.LogInformation(
            "Registered service {ServiceName} with ID {ServiceId}",
            registration.ServiceName,
            registration.ServiceId);
    }

    public async Task DeregisterServiceAsync(string serviceId)
    {
        await _consulClient.Agent.ServiceDeregister(serviceId);

        _logger.LogInformation("Deregistered service {ServiceId}", serviceId);
    }
}

public class ServiceEndpoint
{
    public string ServiceName { get; set; }
    public string Host { get; set; }
    public int Port { get; set; }
    public string Scheme { get; set; }

    public string BaseUrl => $"{Scheme}://{Host}:{Port}";
}

public class ServiceRegistration
{
    public string ServiceId { get; set; }
    public string ServiceName { get; set; }
    public string Host { get; set; }
    public int Port { get; set; }
    public string Scheme { get; set; }
    public string[] Tags { get; set; }
}

// ✅ Circuit Breaker Pattern with Polly
public class ResilientHttpClient
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ResilientHttpClient> _logger;

    public ResilientHttpClient(
        IHttpClientFactory httpClientFactory,
        ILogger<ResilientHttpClient> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<T> GetAsync<T>(string serviceName, string path)
    {
        var client = _httpClientFactory.CreateClient(serviceName);

        var response = await client.GetAsync(path);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<T>();
    }
}

// Configure resilience policies in Startup
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Circuit Breaker + Retry + Timeout policies
        services.AddHttpClient("ProductService")
            .AddTransientHttpErrorPolicy(builder =>
                builder.WaitAndRetryAsync(new[]
                {
                    TimeSpan.FromSeconds(1),
                    TimeSpan.FromSeconds(2),
                    TimeSpan.FromSeconds(3)
                }))
            .AddTransientHttpErrorPolicy(builder =>
                builder.CircuitBreakerAsync(
                    handledEventsAllowedBeforeBreaking: 3,
                    durationOfBreak: TimeSpan.FromSeconds(30)))
            .AddPolicyHandler(Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(10)));
    }
}

// ✅ Database per Service Pattern
public class ProductServiceDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }

    public ProductServiceDbContext(DbContextOptions<ProductServiceDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Product Service owns its own database schema
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("Products");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Name).IsRequired().HasMaxLength(200);
            entity.Property(p => p.Price).HasPrecision(18, 2);
            entity.HasIndex(p => p.Status);
        });

        // Don't reference entities from other services
        // Use eventual consistency via events instead
    }
}

// ✅ Saga Pattern for Distributed Transactions
public class OrderSaga
{
    private readonly IMessageBus _messageBus;
    private readonly ILogger<OrderSaga> _logger;

    public OrderSaga(IMessageBus messageBus, ILogger<OrderSaga> logger)
    {
        _messageBus = messageBus;
        _logger = logger;
    }

    public async Task<Guid> CreateOrderAsync(CreateOrderCommand command)
    {
        var orderId = Guid.NewGuid();

        try
        {
            // Step 1: Reserve Inventory
            var inventoryReserved = await _messageBus.SendAsync<ReserveInventoryCommand, bool>(
                new ReserveInventoryCommand
                {
                    OrderId = orderId,
                    Items = command.Items
                });

            if (!inventoryReserved)
            {
                throw new SagaException("Failed to reserve inventory");
            }

            // Step 2: Process Payment
            var paymentProcessed = await _messageBus.SendAsync<ProcessPaymentCommand, bool>(
                new ProcessPaymentCommand
                {
                    OrderId = orderId,
                    Amount = command.TotalAmount,
                    PaymentMethod = command.PaymentMethod
                });

            if (!paymentProcessed)
            {
                // Compensate: Release inventory
                await _messageBus.PublishAsync(new ReleaseInventoryCommand
                {
                    OrderId = orderId,
                    Items = command.Items
                });

                throw new SagaException("Payment processing failed");
            }

            // Step 3: Create Order
            await _messageBus.PublishAsync(new OrderCreatedEvent
            {
                OrderId = orderId,
                CustomerId = command.CustomerId,
                Items = command.Items,
                TotalAmount = command.TotalAmount
            });

            return orderId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Order saga failed for order {OrderId}", orderId);

            // Publish compensation events
            await CompensateAsync(orderId, command);

            throw;
        }
    }

    private async Task CompensateAsync(Guid orderId, CreateOrderCommand command)
    {
        // Compensating transactions in reverse order
        await _messageBus.PublishAsync(new CancelOrderCommand { OrderId = orderId });
        await _messageBus.PublishAsync(new RefundPaymentCommand { OrderId = orderId });
        await _messageBus.PublishAsync(new ReleaseInventoryCommand
        {
            OrderId = orderId,
            Items = command.Items
        });
    }
}

/*
Microservices Architecture Principles:

1. ✅ Single Responsibility
   - Each service owns a specific business capability
   - Clear boundaries and responsibilities

2. ✅ Autonomous
   - Services can be developed, deployed, and scaled independently
   - Own their own data store (Database per Service)

3. ✅ Decentralized
   - No central orchestration
   - Services communicate via events/messages

4. ✅ Resilient
   - Circuit breaker pattern
   - Retry policies
   - Graceful degradation

5. ✅ Observable
   - Distributed tracing
   - Centralized logging
   - Health checks

Key Patterns:

1. API Gateway
   - Single entry point
   - Request aggregation
   - Authentication/Authorization
   - Rate limiting

2. Service Discovery
   - Dynamic service location
   - Health checking
   - Load balancing

3. Circuit Breaker
   - Prevent cascading failures
   - Fast failure
   - Fallback mechanisms

4. Database per Service
   - Data autonomy
   - Independent scaling
   - Polyglot persistence

5. Saga Pattern
   - Distributed transactions
   - Compensating transactions
   - Eventual consistency

6. Event Sourcing
   - Audit trail
   - Temporal queries
   - Event replay

7. CQRS
   - Separate read/write models
   - Optimized queries
   - Scalability

Communication Patterns:
- Synchronous: HTTP/REST, gRPC
- Asynchronous: Message queues (RabbitMQ, Azure Service Bus)
- Event-driven: Event bus, Kafka

Best Practices:
✅ Design for failure
✅ Implement health checks
✅ Use correlation IDs
✅ Version your APIs
✅ Monitor everything
✅ Automate deployment
✅ Use containerization
✅ Implement proper logging
✅ Security by default
✅ Documentation as code

Tools & Technologies:
- Service Mesh: Istio, Linkerd
- Service Discovery: Consul, Eureka
- API Gateway: Ocelot, YARP, Kong
- Message Bus: RabbitMQ, Azure Service Bus, Kafka
- Orchestration: Kubernetes
- Monitoring: Prometheus, Grafana, Application Insights
*/
```

---

## Q322. How do you implement inter-service communication in microservices?

```csharp
/*
Inter-Service Communication Patterns
*/

// ✅ PATTERN 1: Synchronous HTTP Communication with Refit
// Install: dotnet add package Refit

// Define API interface
public interface IProductServiceClient
{
    [Get("/api/products/{id}")]
    Task<ProductDto> GetProductAsync(Guid id);

    [Get("/api/products")]
    Task<List<ProductDto>> GetProductsAsync([Query] int page, [Query] int pageSize);

    [Post("/api/products")]
    Task<ProductDto> CreateProductAsync([Body] CreateProductRequest request);

    [Put("/api/products/{id}")]
    Task<ProductDto> UpdateProductAsync(Guid id, [Body] UpdateProductRequest request);

    [Delete("/api/products/{id}")]
    Task DeleteProductAsync(Guid id);
}

// Register in DI
services.AddRefitClient<IProductServiceClient>()
    .ConfigureHttpClient((sp, client) =>
    {
        var serviceDiscovery = sp.GetRequiredService<IServiceDiscovery>();
        var endpoint = serviceDiscovery.DiscoverServiceAsync("product-service").Result;
        client.BaseAddress = new Uri(endpoint.BaseUrl);
    })
    .AddTransientHttpErrorPolicy(builder =>
        builder.WaitAndRetryAsync(3, retryAttempt =>
            TimeSpan.FromSeconds(Math.Pow(2, retryAttempt))))
    .AddTransientHttpErrorPolicy(builder =>
        builder.CircuitBreakerAsync(5, TimeSpan.FromSeconds(30)));

// Usage
public class OrderService
{
    private readonly IProductServiceClient _productClient;

    public OrderService(IProductServiceClient productClient)
    {
        _productClient = productClient;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        // Synchronous call to Product Service
        var product = await _productClient.GetProductAsync(request.ProductId);

        if (product == null)
        {
            throw new ProductNotFoundException(request.ProductId);
        }

        // Create order with product information
        var order = new Order
        {
            ProductId = product.Id,
            ProductName = product.Name,
            Price = product.Price,
            Quantity = request.Quantity
        };

        return order;
    }
}

// ✅ PATTERN 2: gRPC Communication
// Install: dotnet add package Grpc.AspNetCore
// Install: dotnet add package Grpc.Tools

// Define proto file (product.proto)
/*
syntax = "proto3";

option csharp_namespace = "ProductService.Grpc";

package product;

service ProductGrpc {
  rpc GetProduct (GetProductRequest) returns (ProductResponse);
  rpc GetProducts (GetProductsRequest) returns (ProductListResponse);
  rpc CreateProduct (CreateProductRequest) returns (ProductResponse);
  rpc UpdateProduct (UpdateProductRequest) returns (ProductResponse);
  rpc DeleteProduct (DeleteProductRequest) returns (DeleteProductResponse);
  rpc StreamProducts (StreamProductsRequest) returns (stream ProductResponse);
}

message GetProductRequest {
  string id = 1;
}

message ProductResponse {
  string id = 1;
  string name = 2;
  double price = 3;
  int32 stock_quantity = 4;
}

message GetProductsRequest {
  int32 page = 1;
  int32 page_size = 2;
}

message ProductListResponse {
  repeated ProductResponse products = 1;
  int32 total_count = 2;
}
*/

// Server implementation
public class ProductGrpcService : ProductGrpc.ProductGrpcBase
{
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductGrpcService> _logger;

    public ProductGrpcService(
        IProductRepository repository,
        ILogger<ProductGrpcService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public override async Task<ProductResponse> GetProduct(
        GetProductRequest request,
        ServerCallContext context)
    {
        if (!Guid.TryParse(request.Id, out var productId))
        {
            throw new RpcException(new Status(StatusCode.InvalidArgument, "Invalid product ID"));
        }

        var product = await _repository.GetByIdAsync(productId);

        if (product == null)
        {
            throw new RpcException(new Status(StatusCode.NotFound, "Product not found"));
        }

        return new ProductResponse
        {
            Id = product.Id.ToString(),
            Name = product.Name,
            Price = (double)product.Price,
            StockQuantity = product.StockQuantity
        };
    }

    public override async Task StreamProducts(
        StreamProductsRequest request,
        IServerStreamWriter<ProductResponse> responseStream,
        ServerCallContext context)
    {
        await foreach (var product in _repository.GetProductsStreamAsync())
        {
            if (context.CancellationToken.IsCancellationRequested)
                break;

            await responseStream.WriteAsync(new ProductResponse
            {
                Id = product.Id.ToString(),
                Name = product.Name,
                Price = (double)product.Price,
                StockQuantity = product.StockQuantity
            });
        }
    }
}

// Client usage
public class OrderServiceWithGrpc
{
    private readonly ProductGrpc.ProductGrpcClient _productClient;

    public OrderServiceWithGrpc(ProductGrpc.ProductGrpcClient productClient)
    {
        _productClient = productClient;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        var productResponse = await _productClient.GetProductAsync(
            new GetProductRequest { Id = request.ProductId.ToString() });

        var order = new Order
        {
            ProductId = Guid.Parse(productResponse.Id),
            ProductName = productResponse.Name,
            Price = (decimal)productResponse.Price,
            Quantity = request.Quantity
        };

        return order;
    }
}

// ✅ PATTERN 3: Asynchronous Message-Based Communication (RabbitMQ)
// Install: dotnet add package MassTransit.RabbitMQ

// Message contracts
public interface IProductCreatedEvent
{
    Guid ProductId { get; }
    string ProductName { get; }
    decimal Price { get; }
    DateTime CreatedAt { get; }
}

public class ProductCreatedEvent : IProductCreatedEvent
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Publisher (Product Service)
public class ProductService
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IProductRepository _repository;

    public ProductService(
        IPublishEndpoint publishEndpoint,
        IProductRepository repository)
    {
        _publishEndpoint = publishEndpoint;
        _repository = repository;
    }

    public async Task<Product> CreateProductAsync(CreateProductRequest request)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Price = request.Price,
            StockQuantity = request.StockQuantity,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddAsync(product);

        // Publish event to message bus
        await _publishEndpoint.Publish<IProductCreatedEvent>(new ProductCreatedEvent
        {
            ProductId = product.Id,
            ProductName = product.Name,
            Price = product.Price,
            CreatedAt = product.CreatedAt
        });

        return product;
    }
}

// Consumer (Catalog Service)
public class ProductCreatedConsumer : IConsumer<IProductCreatedEvent>
{
    private readonly ICatalogRepository _catalogRepository;
    private readonly ILogger<ProductCreatedConsumer> _logger;

    public ProductCreatedConsumer(
        ICatalogRepository catalogRepository,
        ILogger<ProductCreatedConsumer> logger)
    {
        _catalogRepository = catalogRepository;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<IProductCreatedEvent> context)
    {
        var message = context.Message;

        _logger.LogInformation(
            "Received ProductCreated event for product {ProductId}",
            message.ProductId);

        // Update read model in Catalog Service
        var catalogItem = new CatalogItem
        {
            ProductId = message.ProductId,
            ProductName = message.ProductName,
            Price = message.Price,
            CreatedAt = message.CreatedAt
        };

        await _catalogRepository.UpsertAsync(catalogItem);
    }
}

// Configure MassTransit
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddMassTransit(x =>
        {
            // Add consumers
            x.AddConsumer<ProductCreatedConsumer>();
            x.AddConsumer<ProductUpdatedConsumer>();

            x.UsingRabbitMq((context, cfg) =>
            {
                cfg.Host("rabbitmq://localhost", h =>
                {
                    h.Username("guest");
                    h.Password("guest");
                });

                // Configure exchange and queue
                cfg.Message<IProductCreatedEvent>(e =>
                {
                    e.SetEntityName("product-events");
                });

                cfg.ReceiveEndpoint("catalog-service-product-events", e =>
                {
                    e.ConfigureConsumer<ProductCreatedConsumer>(context);

                    // Retry policy
                    e.UseMessageRetry(r => r.Intervals(
                        TimeSpan.FromSeconds(1),
                        TimeSpan.FromSeconds(5),
                        TimeSpan.FromSeconds(10)));

                    // Circuit breaker
                    e.UseCircuitBreaker(cb =>
                    {
                        cb.TrackingPeriod = TimeSpan.FromMinutes(1);
                        cb.TripThreshold = 15;
                        cb.ActiveThreshold = 10;
                        cb.ResetInterval = TimeSpan.FromMinutes(5);
                    });
                });
            });
        });
    }
}

// ✅ PATTERN 4: Event-Driven with Azure Service Bus
public class AzureServiceBusPublisher
{
    private readonly ServiceBusClient _client;
    private readonly ILogger<AzureServiceBusPublisher> _logger;

    public AzureServiceBusPublisher(
        ServiceBusClient client,
        ILogger<AzureServiceBusPublisher> logger)
    {
        _client = client;
        _logger = logger;
    }

    public async Task PublishEventAsync<T>(string topicName, T eventData) where T : class
    {
        var sender = _client.CreateSender(topicName);

        try
        {
            var json = JsonSerializer.Serialize(eventData);
            var message = new ServiceBusMessage(json)
            {
                ContentType = "application/json",
                Subject = typeof(T).Name,
                MessageId = Guid.NewGuid().ToString(),
                CorrelationId = Activity.Current?.Id ?? Guid.NewGuid().ToString()
            };

            // Add custom properties
            message.ApplicationProperties["EventType"] = typeof(T).Name;
            message.ApplicationProperties["Timestamp"] = DateTime.UtcNow;

            await sender.SendMessageAsync(message);

            _logger.LogInformation(
                "Published event {EventType} to topic {TopicName}",
                typeof(T).Name,
                topicName);
        }
        finally
        {
            await sender.DisposeAsync();
        }
    }
}

public class AzureServiceBusSubscriber
{
    private readonly ServiceBusClient _client;
    private readonly ILogger<AzureServiceBusSubscriber> _logger;

    public AzureServiceBusSubscriber(
        ServiceBusClient client,
        ILogger<AzureServiceBusSubscriber> logger)
    {
        _client = client;
        _logger = logger;
    }

    public async Task SubscribeAsync<T>(
        string topicName,
        string subscriptionName,
        Func<T, Task> handler) where T : class
    {
        var processor = _client.CreateProcessor(topicName, subscriptionName, new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 10,
            AutoCompleteMessages = false,
            MaxAutoLockRenewalDuration = TimeSpan.FromMinutes(5)
        });

        processor.ProcessMessageAsync += async args =>
        {
            try
            {
                var body = args.Message.Body.ToString();
                var eventData = JsonSerializer.Deserialize<T>(body);

                await handler(eventData);

                await args.CompleteMessageAsync(args.Message);

                _logger.LogInformation(
                    "Processed message {MessageId} of type {EventType}",
                    args.Message.MessageId,
                    typeof(T).Name);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Error processing message {MessageId}",
                    args.Message.MessageId);

                // Dead-letter the message after max retries
                if (args.Message.DeliveryCount >= 3)
                {
                    await args.DeadLetterMessageAsync(args.Message,
                        "Max retry count exceeded",
                        ex.Message);
                }
                else
                {
                    await args.AbandonMessageAsync(args.Message);
                }
            }
        };

        processor.ProcessErrorAsync += args =>
        {
            _logger.LogError(args.Exception,
                "Error in message processor for {Topic}/{Subscription}",
                topicName,
                subscriptionName);

            return Task.CompletedTask;
        };

        await processor.StartProcessingAsync();
    }
}

/*
Inter-Service Communication Patterns:

1. Synchronous Communication:
   ✅ HTTP/REST with Refit
   - Simple, widely supported
   - Request/Response pattern
   - Coupling between services
   - Use for: Immediate responses needed

   ✅ gRPC
   - High performance (binary protocol)
   - Strongly typed contracts
   - Streaming support
   - Use for: Performance-critical paths

2. Asynchronous Communication:
   ✅ Message Queue (RabbitMQ, Azure Service Bus)
   - Decoupled services
   - Guaranteed delivery
   - Retry mechanisms
   - Use for: Background processing

   ✅ Event Bus (Kafka, Azure Event Hub)
   - Event sourcing
   - Event replay
   - High throughput
   - Use for: Event-driven architecture

When to Use:
- Synchronous: Real-time data needed, simple queries
- Asynchronous: Fire-and-forget, long-running operations

Best Practices:
✅ Use correlation IDs for tracing
✅ Implement idempotency
✅ Version your contracts
✅ Handle failures gracefully
✅ Monitor message delivery
✅ Implement circuit breakers
✅ Use dead-letter queues
✅ Log all communications
✅ Test for network partitions
✅ Document your APIs

Communication Decision Matrix:
- Real-time response needed → Synchronous (HTTP/gRPC)
- High performance required → gRPC
- Fire and forget → Async Message Queue
- Event sourcing → Event Bus
- Long-running operations → Async
- Multiple consumers → Pub/Sub pattern
*/
```

---

## Q323. How do you implement an API Gateway in .NET using Ocelot or YARP?

```csharp
/*
API Gateway Implementation
*/

// ✅ PATTERN 1: Ocelot API Gateway
// Install: dotnet add package Ocelot

// ocelot.json configuration
/*
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/products/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "product-service",
          "Port": 443
        }
      ],
      "UpstreamPathTemplate": "/products/{everything}",
      "UpstreamHttpMethod": [ "Get", "Post", "Put", "Delete" ],
      "Key": "products",
      "QoSOptions": {
        "ExceptionsAllowedBeforeBreaking": 3,
        "DurationOfBreak": 30000,
        "TimeoutValue": 5000
      },
      "RateLimitOptions": {
        "ClientWhitelist": [],
        "EnableRateLimiting": true,
        "Period": "1s",
        "PeriodTimespan": 1,
        "Limit": 100
      },
      "FileCacheOptions": {
        "TtlSeconds": 30,
        "Region": "products"
      }
    },
    {
      "DownstreamPathTemplate": "/api/orders/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "order-service",
          "Port": 443
        }
      ],
      "UpstreamPathTemplate": "/orders/{everything}",
      "UpstreamHttpMethod": [ "Get", "Post", "Put", "Delete" ],
      "Key": "orders",
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer",
        "AllowedScopes": []
      }
    }
  ],
  "GlobalConfiguration": {
    "BaseUrl": "https://api.mycompany.com",
    "ServiceDiscoveryProvider": {
      "Type": "Consul",
      "Host": "consul",
      "Port": 8500
    },
    "RateLimitOptions": {
      "DisableRateLimitHeaders": false,
      "QuotaExceededMessage": "API rate limit exceeded",
      "HttpStatusCode": 429
    }
  }
}
*/

// Program.cs
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add Ocelot configuration
        builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

        // Add services
        builder.Services.AddOcelot(builder.Configuration)
            .AddConsul()
            .AddCacheManager(x =>
            {
                x.WithDictionaryHandle();
            });

        // Add authentication
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer("Bearer", options =>
            {
                options.Authority = "https://identity-server.com";
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateAudience = true,
                    ValidAudience = "api-gateway"
                };
            });

        var app = builder.Build();

        app.UseOcelot().Wait();

        app.Run();
    }
}

// Custom Middleware for Ocelot
public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Headers.ContainsKey("X-Correlation-ID"))
        {
            context.Request.Headers.Add("X-Correlation-ID", Guid.NewGuid().ToString());
        }

        context.Response.OnStarting(() =>
        {
            context.Response.Headers.Add("X-Correlation-ID",
                context.Request.Headers["X-Correlation-ID"].ToString());
            return Task.CompletedTask;
        });

        await _next(context);
    }
}

// Custom Delegating Handler for Ocelot
public class LoggingDelegatingHandler : DelegatingHandler
{
    private readonly ILogger<LoggingDelegatingHandler> _logger;

    public LoggingDelegatingHandler(ILogger<LoggingDelegatingHandler> logger)
    {
        _logger = logger;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var correlationId = request.Headers.Contains("X-Correlation-ID")
            ? request.Headers.GetValues("X-Correlation-ID").FirstOrDefault()
            : Guid.NewGuid().ToString();

        _logger.LogInformation(
            "Sending request to {Uri} with correlation ID {CorrelationId}",
            request.RequestUri,
            correlationId);

        var stopwatch = Stopwatch.StartNew();

        var response = await base.SendAsync(request, cancellationToken);

        stopwatch.Stop();

        _logger.LogInformation(
            "Received response from {Uri} with status {StatusCode} in {ElapsedMs}ms",
            request.RequestUri,
            response.StatusCode,
            stopwatch.ElapsedMilliseconds);

        return response;
    }
}

// ✅ PATTERN 2: YARP (Yet Another Reverse Proxy)
// Install: dotnet add package Yarp.ReverseProxy

// appsettings.json
/*
{
  "ReverseProxy": {
    "Routes": {
      "product-route": {
        "ClusterId": "product-cluster",
        "Match": {
          "Path": "/products/{**catch-all}"
        },
        "Transforms": [
          { "PathPattern": "/api/products/{**catch-all}" }
        ]
      },
      "order-route": {
        "ClusterId": "order-cluster",
        "Match": {
          "Path": "/orders/{**catch-all}"
        },
        "Transforms": [
          { "PathPattern": "/api/orders/{**catch-all}" }
        ],
        "AuthorizationPolicy": "authenticated"
      }
    },
    "Clusters": {
      "product-cluster": {
        "Destinations": {
          "product-service-1": {
            "Address": "https://product-service-1:443"
          },
          "product-service-2": {
            "Address": "https://product-service-2:443"
          }
        },
        "LoadBalancingPolicy": "RoundRobin",
        "HealthCheck": {
          "Active": {
            "Enabled": true,
            "Interval": "00:00:10",
            "Timeout": "00:00:05",
            "Path": "/health"
          }
        }
      },
      "order-cluster": {
        "Destinations": {
          "order-service": {
            "Address": "https://order-service:443"
          }
        }
      }
    }
  }
}
*/

// Program.cs with YARP
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add YARP
        builder.Services.AddReverseProxy()
            .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
            .AddTransforms(builderContext =>
            {
                // Add correlation ID
                builderContext.AddRequestTransform(async transformContext =>
                {
                    if (!transformContext.HttpContext.Request.Headers.ContainsKey("X-Correlation-ID"))
                    {
                        transformContext.ProxyRequest.Headers.Add(
                            "X-Correlation-ID",
                            Guid.NewGuid().ToString());
                    }
                });

                // Add response headers
                builderContext.AddResponseTransform(async transformContext =>
                {
                    transformContext.HttpContext.Response.Headers.Add(
                        "X-Powered-By",
                        "YARP");
                });
            });

        // Add authentication
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.Authority = "https://identity-server.com";
            });

        builder.Services.AddAuthorization(options =>
        {
            options.AddPolicy("authenticated", policy =>
                policy.RequireAuthenticatedUser());
        });

        var app = builder.Build();

        app.UseAuthentication();
        app.UseAuthorization();

        // Map reverse proxy
        app.MapReverseProxy(proxyPipeline =>
        {
            // Add custom middleware to the proxy pipeline
            proxyPipeline.Use(async (context, next) =>
            {
                var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogInformation("Proxying request to {Path}", context.Request.Path);

                await next();

                logger.LogInformation("Proxy response: {StatusCode}", context.Response.StatusCode);
            });
        });

        app.Run();
    }
}

// Custom YARP Transform
public class CustomHeaderTransform : RequestTransform
{
    public override ValueTask ApplyAsync(RequestTransformContext context)
    {
        // Add custom headers to downstream request
        context.ProxyRequest.Headers.Add("X-Gateway-Version", "1.0");
        context.ProxyRequest.Headers.Add("X-Forwarded-For",
            context.HttpContext.Connection.RemoteIpAddress?.ToString());

        return default;
    }
}

// Rate Limiting with YARP
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;

    public RateLimitingMiddleware(RequestDelegate next, IMemoryCache cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = context.User.Identity?.Name ??
                       context.Connection.RemoteIpAddress?.ToString() ??
                       "anonymous";

        var key = $"rate_limit_{clientId}";
        var limit = 100; // requests per minute
        var window = TimeSpan.FromMinutes(1);

        if (!_cache.TryGetValue(key, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= limit)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await context.Response.WriteAsync("Rate limit exceeded");
            return;
        }

        requestCount++;
        _cache.Set(key, requestCount, window);

        context.Response.Headers.Add("X-RateLimit-Limit", limit.ToString());
        context.Response.Headers.Add("X-RateLimit-Remaining", (limit - requestCount).ToString());

        await _next(context);
    }
}

// ✅ Request Aggregation Pattern
public class RequestAggregationService
{
    private readonly IHttpClientFactory _httpClientFactory;

    public RequestAggregationService(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    public async Task<OrderDetailsResponse> GetOrderDetailsAsync(Guid orderId)
    {
        // Make parallel calls to multiple services
        var orderTask = GetOrderAsync(orderId);
        var customerTask = GetCustomerFromOrderAsync(orderId);
        var productsTask = GetOrderProductsAsync(orderId);
        var shippingTask = GetShippingInfoAsync(orderId);

        await Task.WhenAll(orderTask, customerTask, productsTask, shippingTask);

        return new OrderDetailsResponse
        {
            Order = await orderTask,
            Customer = await customerTask,
            Products = await productsTask,
            Shipping = await shippingTask
        };
    }

    private async Task<OrderDto> GetOrderAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("OrderService");
        var response = await client.GetAsync($"/api/orders/{orderId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<OrderDto>();
    }

    private async Task<CustomerDto> GetCustomerFromOrderAsync(Guid orderId)
    {
        // First get order to get customer ID
        var order = await GetOrderAsync(orderId);

        var client = _httpClientFactory.CreateClient("CustomerService");
        var response = await client.GetAsync($"/api/customers/{order.CustomerId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<CustomerDto>();
    }

    private async Task<List<ProductDto>> GetOrderProductsAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("ProductService");
        var response = await client.GetAsync($"/api/orders/{orderId}/products");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<ProductDto>>();
    }

    private async Task<ShippingDto> GetShippingInfoAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("ShippingService");
        var response = await client.GetAsync($"/api/shipping/order/{orderId}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<ShippingDto>();
    }
}

/*
API Gateway Patterns:

1. Ocelot Features:
   ✅ Request routing
   ✅ Request aggregation
   ✅ Service discovery (Consul, Eureka)
   ✅ Load balancing
   ✅ Authentication/Authorization
   ✅ Rate limiting
   ✅ Caching
   ✅ Circuit breaker (QoS)
   ✅ Request/Response transformation

2. YARP Features:
   ✅ High performance (Microsoft official)
   ✅ Configuration-based routing
   ✅ Health checks
   ✅ Load balancing
   ✅ Session affinity
   ✅ Transforms pipeline
   ✅ Extensible architecture
   ✅ Active/passive health checks

Comparison:
Ocelot:
- More features out of the box
- Easier configuration
- Built-in service discovery
- Community-driven

YARP:
- Better performance
- Microsoft official
- More flexible
- Better integration with ASP.NET Core
- Actively maintained

Best Practices:
✅ Implement correlation IDs
✅ Add request/response logging
✅ Use circuit breakers
✅ Implement rate limiting
✅ Cache when appropriate
✅ Add health checks
✅ Version your APIs
✅ Implement retry policies
✅ Monitor gateway metrics
✅ Secure with authentication

Common Gateway Responsibilities:
1. Request routing
2. Authentication/Authorization
3. SSL termination
4. Rate limiting
5. Request/Response transformation
6. Caching
7. Load balancing
8. Service discovery integration
9. Monitoring and logging
10. Error handling

Performance Metrics:
- Ocelot: ~20K requests/sec
- YARP: ~100K requests/sec (5x faster)
*/
```

---

## Q324. How do you implement distributed tracing and observability in microservices?

```csharp
/*
Distributed Tracing and Observability Implementation
*/

// ✅ PATTERN 1: OpenTelemetry with Distributed Tracing
// Install: dotnet add package OpenTelemetry.Extensions.Hosting
// Install: dotnet add package OpenTelemetry.Instrumentation.AspNetCore
// Install: dotnet add package OpenTelemetry.Instrumentation.Http
// Install: dotnet add package OpenTelemetry.Instrumentation.SqlClient
// Install: dotnet add package OpenTelemetry.Exporter.Jaeger

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add OpenTelemetry
        builder.Services.AddOpenTelemetry()
            .WithTracing(tracerProviderBuilder =>
            {
                tracerProviderBuilder
                    .AddSource("ProductService")
                    .SetResourceBuilder(ResourceBuilder.CreateDefault()
                        .AddService("product-service", serviceVersion: "1.0.0")
                        .AddTelemetrySdk()
                        .AddEnvironmentVariableDetector())
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
                    .AddJaegerExporter(options =>
                    {
                        options.AgentHost = "jaeger";
                        options.AgentPort = 6831;
                    });
            })
            .WithMetrics(meterProviderBuilder =>
            {
                meterProviderBuilder
                    .AddMeter("ProductService")
                    .AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddPrometheusExporter();
            });

        var app = builder.Build();
        app.Run();
    }
}

// Custom Activity Source for manual instrumentation
public class ProductService
{
    private static readonly ActivitySource ActivitySource = new("ProductService");
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IProductRepository repository,
        ILogger<ProductService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<Product> CreateProductAsync(CreateProductRequest request)
    {
        using var activity = ActivitySource.StartActivity("CreateProduct", ActivityKind.Internal);

        // Add tags (attributes) to the span
        activity?.SetTag("product.name", request.Name);
        activity?.SetTag("product.price", request.Price);
        activity?.SetTag("product.category", request.Category);

        try
        {
            // Add event to span
            activity?.AddEvent(new ActivityEvent("ValidatingProduct"));

            ValidateProduct(request);

            activity?.AddEvent(new ActivityEvent("SavingProduct"));

            var product = new Product
            {
                Id = Guid.NewGuid(),
                Name = request.Name,
                Price = request.Price,
                Category = request.Category
            };

            await _repository.AddAsync(product);

            // Add success tag
            activity?.SetTag("product.id", product.Id.ToString());
            activity?.SetStatus(ActivityStatusCode.Ok);

            return product;
        }
        catch (Exception ex)
        {
            // Record exception in span
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity?.RecordException(ex);

            _logger.LogError(ex, "Failed to create product");
            throw;
        }
    }

    private void ValidateProduct(CreateProductRequest request)
    {
        using var activity = ActivitySource.StartActivity("ValidateProduct");

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ValidationException("Product name is required");
        }

        if (request.Price <= 0)
        {
            throw new ValidationException("Product price must be positive");
        }

        activity?.SetTag("validation.passed", true);
    }
}

// ✅ PATTERN 2: Correlation ID Middleware
public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CorrelationIdMiddleware> _logger;
    private const string CorrelationIdHeaderName = "X-Correlation-ID";

    public CorrelationIdMiddleware(
        RequestDelegate next,
        ILogger<CorrelationIdMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        string correlationId;

        if (context.Request.Headers.TryGetValue(CorrelationIdHeaderName, out var existingCorrelationId))
        {
            correlationId = existingCorrelationId.FirstOrDefault() ?? Guid.NewGuid().ToString();
        }
        else
        {
            correlationId = Guid.NewGuid().ToString();
        }

        // Add to response headers
        context.Response.Headers.Add(CorrelationIdHeaderName, correlationId);

        // Add to current activity (OpenTelemetry span)
        Activity.Current?.SetTag("correlation.id", correlationId);

        // Add to logger scope
        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = correlationId,
            ["RequestPath"] = context.Request.Path
        }))
        {
            _logger.LogInformation(
                "Request started: {Method} {Path}",
                context.Request.Method,
                context.Request.Path);

            await _next(context);

            _logger.LogInformation(
                "Request completed: {Method} {Path} - {StatusCode}",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode);
        }
    }
}

// ✅ PATTERN 3: Structured Logging with Serilog
// Install: dotnet add package Serilog.AspNetCore
// Install: dotnet add package Serilog.Sinks.Elasticsearch

public class Program
{
    public static void Main(string[] args)
    {
        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Information()
            .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
            .MinimumLevel.Override("System", LogEventLevel.Warning)
            .Enrich.FromLogContext()
            .Enrich.WithMachineName()
            .Enrich.WithEnvironmentName()
            .Enrich.WithProperty("Application", "ProductService")
            .WriteTo.Console(
                outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext} {Message:lj} {Properties:j}{NewLine}{Exception}")
            .WriteTo.Elasticsearch(new ElasticsearchSinkOptions(new Uri("http://elasticsearch:9200"))
            {
                AutoRegisterTemplate = true,
                AutoRegisterTemplateVersion = AutoRegisterTemplateVersion.ESv7,
                IndexFormat = "product-service-logs-{0:yyyy.MM.dd}",
                NumberOfShards = 2,
                NumberOfReplicas = 1,
                ModifyConnectionSettings = x => x.BasicAuthentication("elastic", "password")
            })
            .CreateLogger();

        try
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Host.UseSerilog();

            var app = builder.Build();
            app.Run();
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "Application startup failed");
        }
        finally
        {
            Log.CloseAndFlush();
        }
    }
}

// Structured logging example
public class OrderService
{
    private readonly ILogger<OrderService> _logger;

    public OrderService(ILogger<OrderService> logger)
    {
        _logger = logger;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["CustomerId"] = request.CustomerId,
            ["OrderId"] = Guid.NewGuid()
        }))
        {
            _logger.LogInformation(
                "Creating order for customer {CustomerId} with {ItemCount} items, total: {TotalAmount:C}",
                request.CustomerId,
                request.Items.Count,
                request.TotalAmount);

            try
            {
                var order = await ProcessOrderAsync(request);

                _logger.LogInformation(
                    "Order {OrderId} created successfully",
                    order.Id);

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
    }

    private async Task<Order> ProcessOrderAsync(CreateOrderRequest request)
    {
        // Implementation
        return await Task.FromResult(new Order());
    }
}

// ✅ PATTERN 4: Custom Metrics with Prometheus
// Install: dotnet add package prometheus-net.AspNetCore

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        var app = builder.Build();

        // Enable Prometheus metrics endpoint
        app.UseMetricServer(); // Exposes /metrics endpoint
        app.UseHttpMetrics();   // Collects HTTP metrics

        app.Run();
    }
}

public class ProductService
{
    private static readonly Counter ProductsCreated = Metrics
        .CreateCounter("products_created_total", "Total number of products created");

    private static readonly Histogram ProductCreationDuration = Metrics
        .CreateHistogram("product_creation_duration_seconds", "Product creation duration",
            new HistogramConfiguration
            {
                Buckets = Histogram.LinearBuckets(start: 0.1, width: 0.1, count: 10)
            });

    private static readonly Gauge ActiveProducts = Metrics
        .CreateGauge("active_products", "Number of active products");

    private readonly IProductRepository _repository;

    public async Task<Product> CreateProductAsync(CreateProductRequest request)
    {
        using (ProductCreationDuration.NewTimer())
        {
            try
            {
                var product = new Product
                {
                    Id = Guid.NewGuid(),
                    Name = request.Name,
                    Price = request.Price
                };

                await _repository.AddAsync(product);

                ProductsCreated.Inc();
                ActiveProducts.Inc();

                return product;
            }
            catch
            {
                // Metrics for failures
                ProductsCreated.WithLabels("failed").Inc();
                throw;
            }
        }
    }
}

// ✅ PATTERN 5: Health Checks
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "ready" })
            .AddSqlServer(
                connectionString: builder.Configuration.GetConnectionString("DefaultConnection"),
                name: "database",
                tags: new[] { "ready", "db" })
            .AddUrlGroup(
                new Uri("http://inventory-service/health"),
                name: "inventory-service",
                tags: new[] { "services" })
            .AddUrlGroup(
                new Uri("http://pricing-service/health"),
                name: "pricing-service",
                tags: new[] { "services" });

        var app = builder.Build();

        // Liveness probe
        app.MapHealthChecks("/health/live", new HealthCheckOptions
        {
            Predicate = _ => false // No checks, just returns healthy
        });

        // Readiness probe
        app.MapHealthChecks("/health/ready", new HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains("ready"),
            ResponseWriter = async (context, report) =>
            {
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

                context.Response.ContentType = "application/json";
                await context.Response.WriteAsync(result);
            }
        });

        app.Run();
    }
}

// Custom Health Check
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly IDbConnection _connection;

    public DatabaseHealthCheck(IDbConnection connection)
    {
        _connection = connection;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _connection.OpenAsync(cancellationToken);

            var command = _connection.CreateCommand();
            command.CommandText = "SELECT 1";
            await command.ExecuteScalarAsync(cancellationToken);

            return HealthCheckResult.Healthy("Database is accessible");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                "Database is not accessible",
                exception: ex);
        }
        finally
        {
            await _connection.CloseAsync();
        }
    }
}

/*
Observability Pillars:

1. Distributed Tracing (OpenTelemetry/Jaeger):
   ✅ Track requests across services
   ✅ Identify bottlenecks
   ✅ Understand service dependencies
   ✅ Root cause analysis
   ✅ Performance profiling

2. Logging (Serilog/ELK):
   ✅ Structured logging
   ✅ Centralized log aggregation
   ✅ Correlation IDs
   ✅ Log levels and filtering
   ✅ Search and analysis

3. Metrics (Prometheus/Grafana):
   ✅ Business metrics (orders, revenue)
   ✅ System metrics (CPU, memory)
   ✅ Application metrics (response time, errors)
   ✅ Custom metrics
   ✅ Alerting

Best Practices:
✅ Use correlation IDs across all services
✅ Implement structured logging
✅ Add context to logs and traces
✅ Monitor golden signals (latency, traffic, errors, saturation)
✅ Set up alerting for critical metrics
✅ Use sampling for high-volume traces
✅ Implement health checks
✅ Monitor dependencies
✅ Create dashboards for key metrics
✅ Regular review of observability data

Observability Stack:
- Tracing: Jaeger, Zipkin, or Application Insights
- Logging: ELK Stack (Elasticsearch, Logstash, Kibana), Seq
- Metrics: Prometheus + Grafana
- APM: Application Insights, New Relic, Datadog

Key Metrics to Track:
1. Request rate
2. Error rate
3. Duration (latency)
4. Saturation (resource usage)
5. Availability
6. Throughput
7. Queue depth
8. Cache hit ratio
*/
```

---

## Q325. How do you implement CQRS (Command Query Responsibility Segregation) and Event Sourcing in .NET?

```csharp
/*
CQRS and Event Sourcing Implementation
*/

// ✅ CQRS PATTERN

// Commands (Write Model)
public record CreateProductCommand(string Name, decimal Price, int StockQuantity);
public record UpdateProductPriceCommand(Guid ProductId, decimal NewPrice);
public record UpdateProductStockCommand(Guid ProductId, int Quantity);

// Command Handlers
public class CreateProductCommandHandler : ICommandHandler<CreateProductCommand, Guid>
{
    private readonly IEventStore _eventStore;
    private readonly IEventBus _eventBus;

    public CreateProductCommandHandler(IEventStore eventStore, IEventBus eventBus)
    {
        _eventStore = eventStore;
        _eventBus = eventBus;
    }

    public async Task<Guid> HandleAsync(CreateProductCommand command)
    {
        var productId = Guid.NewGuid();

        // Create domain events
        var events = new List<IDomainEvent>
        {
            new ProductCreatedEvent(
                productId,
                command.Name,
                command.Price,
                command.StockQuantity,
                DateTime.UtcNow)
        };

        // Store events
        await _eventStore.SaveEventsAsync(productId, events, -1);

        // Publish events to event bus
        foreach (var @event in events)
        {
            await _eventBus.PublishAsync(@event);
        }

        return productId;
    }
}

// Queries (Read Model)
public record GetProductByIdQuery(Guid ProductId);
public record GetProductsQuery(int Page, int PageSize);

// Query Handlers
public class GetProductByIdQueryHandler : IQueryHandler<GetProductByIdQuery, ProductReadModel>
{
    private readonly IProductReadRepository _readRepository;

    public GetProductByIdQueryHandler(IProductReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task<ProductReadModel> HandleAsync(GetProductByIdQuery query)
    {
        return await _readRepository.GetByIdAsync(query.ProductId);
    }
}

// Read Model (Denormalized for queries)
public class ProductReadModel
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string Category { get; set; }
    public decimal TotalRevenue { get; set; }
    public int TotalOrdersCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

// ✅ EVENT SOURCING PATTERN

// Domain Events
public interface IDomainEvent
{
    Guid AggregateId { get; }
    DateTime OccurredAt { get; }
    int Version { get; }
}

public record ProductCreatedEvent(
    Guid AggregateId,
    string Name,
    decimal Price,
    int StockQuantity,
    DateTime OccurredAt,
    int Version = 1) : IDomainEvent;

public record ProductPriceChangedEvent(
    Guid AggregateId,
    decimal OldPrice,
    decimal NewPrice,
    DateTime OccurredAt,
    int Version) : IDomainEvent;

public record ProductStockUpdatedEvent(
    Guid AggregateId,
    int OldStock,
    int NewStock,
    DateTime OccurredAt,
    int Version) : IDomainEvent;

// Event Store Interface
public interface IEventStore
{
    Task SaveEventsAsync(Guid aggregateId, IEnumerable<IDomainEvent> events, int expectedVersion);
    Task<IEnumerable<IDomainEvent>> GetEventsAsync(Guid aggregateId);
    Task<IEnumerable<IDomainEvent>> GetEventsAsync(Guid aggregateId, int fromVersion);
}

// Event Store Implementation (using SQL Server)
public class SqlServerEventStore : IEventStore
{
    private readonly DbContext _context;
    private readonly IEventSerializer _serializer;

    public SqlServerEventStore(DbContext context, IEventSerializer serializer)
    {
        _context = context;
        _serializer = serializer;
    }

    public async Task SaveEventsAsync(
        Guid aggregateId,
        IEnumerable<IDomainEvent> events,
        int expectedVersion)
    {
        var streamName = $"product-{aggregateId}";

        // Optimistic concurrency check
        var currentVersion = await GetCurrentVersionAsync(aggregateId);
        if (currentVersion != expectedVersion)
        {
            throw new ConcurrencyException(
                $"Expected version {expectedVersion} but found {currentVersion}");
        }

        var eventRecords = events.Select((e, i) => new EventRecord
        {
            Id = Guid.NewGuid(),
            AggregateId = aggregateId,
            StreamName = streamName,
            EventType = e.GetType().Name,
            EventData = _serializer.Serialize(e),
            Version = expectedVersion + i + 1,
            OccurredAt = e.OccurredAt
        });

        await _context.Set<EventRecord>().AddRangeAsync(eventRecords);
        await _context.SaveChangesAsync();
    }

    public async Task<IEnumerable<IDomainEvent>> GetEventsAsync(Guid aggregateId)
    {
        var streamName = $"product-{aggregateId}";

        var eventRecords = await _context.Set<EventRecord>()
            .Where(e => e.StreamName == streamName)
            .OrderBy(e => e.Version)
            .ToListAsync();

        return eventRecords.Select(e => _serializer.Deserialize(e.EventData, e.EventType));
    }

    public async Task<IEnumerable<IDomainEvent>> GetEventsAsync(Guid aggregateId, int fromVersion)
    {
        var streamName = $"product-{aggregateId}";

        var eventRecords = await _context.Set<EventRecord>()
            .Where(e => e.StreamName == streamName && e.Version > fromVersion)
            .OrderBy(e => e.Version)
            .ToListAsync();

        return eventRecords.Select(e => _serializer.Deserialize(e.EventData, e.EventType));
    }

    private async Task<int> GetCurrentVersionAsync(Guid aggregateId)
    {
        var streamName = $"product-{aggregateId}";

        var maxVersion = await _context.Set<EventRecord>()
            .Where(e => e.StreamName == streamName)
            .MaxAsync(e => (int?)e.Version);

        return maxVersion ?? -1;
    }
}

// Event Record (database entity)
public class EventRecord
{
    public Guid Id { get; set; }
    public Guid AggregateId { get; set; }
    public string StreamName { get; set; }
    public string EventType { get; set; }
    public string EventData { get; set; }
    public int Version { get; set; }
    public DateTime OccurredAt { get; set; }
}

// Aggregate Root (Event Sourced)
public class Product
{
    private readonly List<IDomainEvent> _uncommittedEvents = new();

    public Guid Id { get; private set; }
    public string Name { get; private set; }
    public decimal Price { get; private set; }
    public int StockQuantity { get; private set; }
    public int Version { get; private set; }

    // For creating new aggregate
    public static Product Create(Guid id, string name, decimal price, int stockQuantity)
    {
        var product = new Product();
        product.ApplyEvent(new ProductCreatedEvent(id, name, price, stockQuantity, DateTime.UtcNow, 1));
        return product;
    }

    // For reconstituting from event stream
    public static Product FromEvents(IEnumerable<IDomainEvent> events)
    {
        var product = new Product();
        foreach (var @event in events)
        {
            product.ApplyEvent(@event, false);
        }
        return product;
    }

    public void ChangePrice(decimal newPrice)
    {
        if (newPrice <= 0)
            throw new ArgumentException("Price must be positive");

        ApplyEvent(new ProductPriceChangedEvent(
            Id, Price, newPrice, DateTime.UtcNow, Version + 1));
    }

    public void UpdateStock(int quantity)
    {
        var newStock = StockQuantity + quantity;
        if (newStock < 0)
            throw new InvalidOperationException("Insufficient stock");

        ApplyEvent(new ProductStockUpdatedEvent(
            Id, StockQuantity, newStock, DateTime.UtcNow, Version + 1));
    }

    private void ApplyEvent(IDomainEvent @event, bool isNew = true)
    {
        // Apply event to update state
        switch (@event)
        {
            case ProductCreatedEvent e:
                Id = e.AggregateId;
                Name = e.Name;
                Price = e.Price;
                StockQuantity = e.StockQuantity;
                Version = e.Version;
                break;

            case ProductPriceChangedEvent e:
                Price = e.NewPrice;
                Version = e.Version;
                break;

            case ProductStockUpdatedEvent e:
                StockQuantity = e.NewStock;
                Version = e.Version;
                break;
        }

        if (isNew)
        {
            _uncommittedEvents.Add(@event);
        }
    }

    public IEnumerable<IDomainEvent> GetUncommittedEvents()
    {
        return _uncommittedEvents.AsReadOnly();
    }

    public void MarkEventsAsCommitted()
    {
        _uncommittedEvents.Clear();
    }
}

// ✅ READ MODEL PROJECTION

// Event Handler to update Read Model
public class ProductEventHandler :
    IEventHandler<ProductCreatedEvent>,
    IEventHandler<ProductPriceChangedEvent>,
    IEventHandler<ProductStockUpdatedEvent>
{
    private readonly IProductReadRepository _readRepository;

    public ProductEventHandler(IProductReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task HandleAsync(ProductCreatedEvent @event)
    {
        var readModel = new ProductReadModel
        {
            Id = @event.AggregateId,
            Name = @event.Name,
            Price = @event.Price,
            StockQuantity = @event.StockQuantity,
            CreatedAt = @event.OccurredAt
        };

        await _readRepository.InsertAsync(readModel);
    }

    public async Task HandleAsync(ProductPriceChangedEvent @event)
    {
        var product = await _readRepository.GetByIdAsync(@event.AggregateId);
        product.Price = @event.NewPrice;
        product.UpdatedAt = @event.OccurredAt;

        await _readRepository.UpdateAsync(product);
    }

    public async Task HandleAsync(ProductStockUpdatedEvent @event)
    {
        var product = await _readRepository.GetByIdAsync(@event.AggregateId);
        product.StockQuantity = @event.NewStock;
        product.UpdatedAt = @event.OccurredAt;

        await _readRepository.UpdateAsync(product);
    }
}

// ✅ SNAPSHOT PATTERN (for performance optimization)

public class ProductSnapshot
{
    public Guid AggregateId { get; set; }
    public int Version { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public DateTime CreatedAt { get; set; }
}

public interface ISnapshotStore
{
    Task SaveSnapshotAsync(ProductSnapshot snapshot);
    Task<ProductSnapshot> GetSnapshotAsync(Guid aggregateId);
}

public class ProductRepository
{
    private readonly IEventStore _eventStore;
    private readonly ISnapshotStore _snapshotStore;
    private const int SnapshotInterval = 100; // Create snapshot every 100 events

    public ProductRepository(IEventStore eventStore, ISnapshotStore snapshotStore)
    {
        _eventStore = eventStore;
        _snapshotStore = snapshotStore;
    }

    public async Task<Product> GetByIdAsync(Guid id)
    {
        // Try to get snapshot first
        var snapshot = await _snapshotStore.GetSnapshotAsync(id);

        IEnumerable<IDomainEvent> events;

        if (snapshot != null)
        {
            // Load events after snapshot
            events = await _eventStore.GetEventsAsync(id, snapshot.Version);
        }
        else
        {
            // Load all events
            events = await _eventStore.GetEventsAsync(id);
        }

        var product = Product.FromEvents(events);

        return product;
    }

    public async Task SaveAsync(Product product)
    {
        var uncommittedEvents = product.GetUncommittedEvents().ToList();

        await _eventStore.SaveEventsAsync(
            product.Id,
            uncommittedEvents,
            product.Version - uncommittedEvents.Count);

        product.MarkEventsAsCommitted();

        // Create snapshot if needed
        if (product.Version % SnapshotInterval == 0)
        {
            await _snapshotStore.SaveSnapshotAsync(new ProductSnapshot
            {
                AggregateId = product.Id,
                Version = product.Version,
                Name = product.Name,
                Price = product.Price,
                StockQuantity = product.StockQuantity
            });
        }
    }
}

/*
CQRS Benefits:
✅ Separate read and write optimization
✅ Independent scaling
✅ Different data models for reads/writes
✅ Improved performance
✅ Better security (separate permissions)

Event Sourcing Benefits:
✅ Complete audit trail
✅ Temporal queries (state at any point in time)
✅ Event replay for debugging
✅ Easy to add new projections
✅ Natural fit for event-driven systems

When to Use CQRS:
- Complex domain logic
- Different read/write performance needs
- Multiple read models needed
- High read/write ratio differences

When to Use Event Sourcing:
- Audit requirements
- Complex business workflows
- Need for temporal queries
- Event-driven architecture
- Compliance and regulatory needs

Best Practices:
✅ Use snapshots for performance
✅ Implement idempotent event handlers
✅ Version your events
✅ Handle event schema evolution
✅ Monitor event store performance
✅ Implement optimistic concurrency
✅ Use correlation IDs
✅ Consider eventual consistency
✅ Implement event upcasting
✅ Test event replay scenarios

Challenges:
- Eventual consistency
- Event versioning
- Query complexity
- Learning curve
- Infrastructure overhead

Tools:
- EventStore DB
- Marten (PostgreSQL)
- SQL Server
- CosmosDB
- Kafka (event log)
*/
```

---

## Q326. How do you implement microservices data management and distributed data patterns?

```csharp
/*
Microservices Data Management Patterns
*/

// ✅ PATTERN 1: Database per Service

// Product Service Database
public class ProductDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Product service owns its schema
        modelBuilder.Entity<Product>().ToTable("Products", schema: "product");
        modelBuilder.Entity<Product>().HasKey(p => p.Id);
        modelBuilder.Entity<Product>().Property(p => p.Name).IsRequired();

        // No foreign keys to other services' tables
    }
}

// Order Service Database
public class OrderDbContext : DbContext
{
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Order service owns its schema
        modelBuilder.Entity<Order>().ToTable("Orders", schema: "order");
        modelBuilder.Entity<OrderItem>().ToTable("OrderItems", schema: "order");

        // Store only ProductId reference, not FK to Product table
        modelBuilder.Entity<OrderItem>()
            .Property(oi => oi.ProductId);

        // Denormalize product data needed for queries
        modelBuilder.Entity<OrderItem>()
            .Property(oi => oi.ProductName);
    }
}

// ✅ PATTERN 2: Saga Pattern for Distributed Transactions

public interface ISagaOrchestrator<TCommand, TResult>
{
    Task<TResult> ExecuteAsync(TCommand command);
}

public class CreateOrderSagaOrchestrator : ISagaOrchestrator<CreateOrderCommand, OrderResult>
{
    private readonly IMessageBus _messageBus;
    private readonly ILogger<CreateOrderSagaOrchestrator> _logger;

    public CreateOrderSagaOrchestrator(
        IMessageBus messageBus,
        ILogger<CreateOrderSagaOrchestrator> logger)
    {
        _messageBus = messageBus;
        _logger = logger;
    }

    public async Task<OrderResult> ExecuteAsync(CreateOrderCommand command)
    {
        var sagaId = Guid.NewGuid();
        var sagaState = new CreateOrderSagaState
        {
            SagaId = sagaId,
            OrderId = Guid.NewGuid(),
            CustomerId = command.CustomerId,
            Items = command.Items,
            TotalAmount = command.TotalAmount
        };

        try
        {
            // Step 1: Validate Customer
            _logger.LogInformation("Saga {SagaId}: Validating customer", sagaId);
            var customerValid = await ValidateCustomerAsync(sagaState);
            if (!customerValid)
            {
                return OrderResult.Failed("Invalid customer");
            }
            sagaState.CustomerValidated = true;

            // Step 2: Reserve Inventory
            _logger.LogInformation("Saga {SagaId}: Reserving inventory", sagaId);
            var inventoryReserved = await ReserveInventoryAsync(sagaState);
            if (!inventoryReserved)
            {
                await CompensateAsync(sagaState);
                return OrderResult.Failed("Insufficient inventory");
            }
            sagaState.InventoryReserved = true;

            // Step 3: Process Payment
            _logger.LogInformation("Saga {SagaId}: Processing payment", sagaId);
            var paymentProcessed = await ProcessPaymentAsync(sagaState);
            if (!paymentProcessed)
            {
                await CompensateAsync(sagaState);
                return OrderResult.Failed("Payment failed");
            }
            sagaState.PaymentProcessed = true;

            // Step 4: Create Order
            _logger.LogInformation("Saga {SagaId}: Creating order", sagaId);
            await CreateOrderAsync(sagaState);
            sagaState.OrderCreated = true;

            // Step 5: Send Notification
            await SendOrderConfirmationAsync(sagaState);

            _logger.LogInformation("Saga {SagaId}: Completed successfully", sagaId);

            return OrderResult.Success(sagaState.OrderId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Saga {SagaId}: Failed, executing compensation", sagaId);
            await CompensateAsync(sagaState);
            throw;
        }
    }

    private async Task<bool> ValidateCustomerAsync(CreateOrderSagaState state)
    {
        var response = await _messageBus.SendAsync<ValidateCustomerCommand, ValidateCustomerResponse>(
            new ValidateCustomerCommand(state.CustomerId));
        return response.IsValid;
    }

    private async Task<bool> ReserveInventoryAsync(CreateOrderSagaState state)
    {
        var response = await _messageBus.SendAsync<ReserveInventoryCommand, ReserveInventoryResponse>(
            new ReserveInventoryCommand(state.OrderId, state.Items));
        state.ReservationId = response.ReservationId;
        return response.Success;
    }

    private async Task<bool> ProcessPaymentAsync(CreateOrderSagaState state)
    {
        var response = await _messageBus.SendAsync<ProcessPaymentCommand, ProcessPaymentResponse>(
            new ProcessPaymentCommand(
                state.OrderId,
                state.CustomerId,
                state.TotalAmount));
        state.PaymentId = response.PaymentId;
        return response.Success;
    }

    private async Task CreateOrderAsync(CreateOrderSagaState state)
    {
        await _messageBus.PublishAsync(new CreateOrderEvent(
            state.OrderId,
            state.CustomerId,
            state.Items,
            state.TotalAmount,
            state.PaymentId,
            state.ReservationId));
    }

    private async Task SendOrderConfirmationAsync(CreateOrderSagaState state)
    {
        await _messageBus.PublishAsync(new SendOrderConfirmationEvent(
            state.OrderId,
            state.CustomerId));
    }

    private async Task CompensateAsync(CreateOrderSagaState state)
    {
        // Execute compensating transactions in reverse order

        if (state.OrderCreated)
        {
            _logger.LogWarning("Saga {SagaId}: Canceling order", state.SagaId);
            await _messageBus.PublishAsync(new CancelOrderCommand(state.OrderId));
        }

        if (state.PaymentProcessed)
        {
            _logger.LogWarning("Saga {SagaId}: Refunding payment", state.SagaId);
            await _messageBus.PublishAsync(new RefundPaymentCommand(state.PaymentId.Value));
        }

        if (state.InventoryReserved)
        {
            _logger.LogWarning("Saga {SagaId}: Releasing inventory", state.SagaId);
            await _messageBus.PublishAsync(new ReleaseInventoryCommand(state.ReservationId.Value));
        }
    }
}

public class CreateOrderSagaState
{
    public Guid SagaId { get; set; }
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public List<OrderItemDto> Items { get; set; }
    public decimal TotalAmount { get; set; }

    public bool CustomerValidated { get; set; }
    public bool InventoryReserved { get; set; }
    public bool PaymentProcessed { get; set; }
    public bool OrderCreated { get; set; }

    public Guid? ReservationId { get; set; }
    public Guid? PaymentId { get; set; }
}

// ✅ PATTERN 3: Eventual Consistency with Outbox Pattern

public class OutboxMessage
{
    public Guid Id { get; set; }
    public string EventType { get; set; }
    public string Payload { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public int RetryCount { get; set; }
}

public class ProductService
{
    private readonly ProductDbContext _context;
    private readonly IJsonSerializer _serializer;

    public async Task<Product> CreateProductAsync(CreateProductRequest request)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // 1. Create product
            var product = new Product
            {
                Id = Guid.NewGuid(),
                Name = request.Name,
                Price = request.Price
            };

            _context.Products.Add(product);

            // 2. Add event to outbox (same transaction)
            var @event = new ProductCreatedEvent(product.Id, product.Name, product.Price);
            var outboxMessage = new OutboxMessage
            {
                Id = Guid.NewGuid(),
                EventType = nameof(ProductCreatedEvent),
                Payload = _serializer.Serialize(@event),
                CreatedAt = DateTime.UtcNow
            };

            _context.Set<OutboxMessage>().Add(outboxMessage);

            // 3. Commit transaction (atomically saves product and outbox message)
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return product;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}

// Background service to process outbox messages
public class OutboxProcessorService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IMessageBus _messageBus;
    private readonly ILogger<OutboxProcessorService> _logger;

    public OutboxProcessorService(
        IServiceProvider serviceProvider,
        IMessageBus messageBus,
        ILogger<OutboxProcessorService> logger)
    {
        _serviceProvider = serviceProvider;
        _messageBus = messageBus;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOutboxMessagesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing outbox messages");
            }

            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }

    private async Task ProcessOutboxMessagesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ProductDbContext>();

        var messages = await context.Set<OutboxMessage>()
            .Where(m => m.ProcessedAt == null && m.RetryCount < 3)
            .OrderBy(m => m.CreatedAt)
            .Take(100)
            .ToListAsync();

        foreach (var message in messages)
        {
            try
            {
                // Publish event to message bus
                var @event = DeserializeEvent(message.EventType, message.Payload);
                await _messageBus.PublishAsync(@event);

                // Mark as processed
                message.ProcessedAt = DateTime.UtcNow;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Failed to process outbox message {MessageId}",
                    message.Id);

                message.RetryCount++;
            }
        }

        await context.SaveChangesAsync();
    }

    private object DeserializeEvent(string eventType, string payload)
    {
        // Deserialize based on event type
        return eventType switch
        {
            nameof(ProductCreatedEvent) => JsonSerializer.Deserialize<ProductCreatedEvent>(payload),
            _ => throw new NotSupportedException($"Event type {eventType} not supported")
        };
    }
}

// ✅ PATTERN 4: API Composition for Queries

public class OrderDetailsComposer
{
    private readonly IHttpClientFactory _httpClientFactory;

    public OrderDetailsComposer(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    public async Task<OrderDetailsDto> GetOrderDetailsAsync(Guid orderId)
    {
        // Fetch data from multiple services in parallel
        var orderTask = GetOrderAsync(orderId);
        var customerTask = GetCustomerAsync(orderId);
        var productsTask = GetProductDetailsAsync(orderId);
        var shippingTask = GetShippingDetailsAsync(orderId);

        await Task.WhenAll(orderTask, customerTask, productsTask, shippingTask);

        // Compose the result
        return new OrderDetailsDto
        {
            Order = await orderTask,
            Customer = await customerTask,
            Products = await productsTask,
            Shipping = await shippingTask
        };
    }

    private async Task<OrderDto> GetOrderAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("OrderService");
        return await client.GetFromJsonAsync<OrderDto>($"/api/orders/{orderId}");
    }

    private async Task<CustomerDto> GetCustomerAsync(Guid orderId)
    {
        // First get the order to find customer ID
        var order = await GetOrderAsync(orderId);

        var client = _httpClientFactory.CreateClient("CustomerService");
        return await client.GetFromJsonAsync<CustomerDto>($"/api/customers/{order.CustomerId}");
    }

    private async Task<List<ProductDto>> GetProductDetailsAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("ProductService");
        return await client.GetFromJsonAsync<List<ProductDto>>($"/api/orders/{orderId}/products");
    }

    private async Task<ShippingDto> GetShippingDetailsAsync(Guid orderId)
    {
        var client = _httpClientFactory.CreateClient("ShippingService");
        return await client.GetFromJsonAsync<ShippingDto>($"/api/shipping/order/{orderId}");
    }
}

/*
Data Management Patterns:

1. Database per Service:
   ✅ Service autonomy
   ✅ Independent scaling
   ✅ Technology diversity
   ❌ Distributed transactions complexity
   ❌ Data duplication

2. Saga Pattern:
   ✅ Manages distributed transactions
   ✅ Maintains data consistency
   ✅ Compensation logic
   ❌ Complex implementation
   ❌ Harder to debug

3. Outbox Pattern:
   ✅ Guaranteed event delivery
   ✅ Atomic database + messaging
   ✅ No message loss
   ❌ Additional infrastructure
   ❌ Eventual consistency

4. API Composition:
   ✅ Real-time data aggregation
   ✅ Simple implementation
   ❌ Performance overhead
   ❌ Service coupling

5. CQRS with Materialized Views:
   ✅ Optimized read models
   ✅ Denormalized data
   ✅ Fast queries
   ❌ Eventual consistency
   ❌ Data duplication

Best Practices:
✅ Embrace eventual consistency
✅ Use idempotent operations
✅ Implement correlation IDs
✅ Monitor data consistency
✅ Use compensating transactions
✅ Version your events/APIs
✅ Implement retry mechanisms
✅ Handle partial failures
✅ Log all data operations
✅ Test distributed scenarios

Consistency Patterns:
- Strong Consistency: Distributed transactions (avoid)
- Eventual Consistency: Events, Sagas (preferred)
- Causal Consistency: Version vectors

Data Synchronization:
- Event-driven replication
- Change Data Capture (CDC)
- Database triggers + outbox
- Polling/scheduled sync
*/
```

---

## Q327. How do you implement microservices security patterns and best practices?

```csharp
/*
Microservices Security Patterns
*/

// ✅ PATTERN 1: JWT Authentication and Authorization

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add JWT Authentication
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.Authority = "https://identity-server.com";
                options.Audience = "product-api";
                options.RequireHttpsMetadata = true;

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ClockSkew = TimeSpan.Zero
                };

                // Handle token from different sources
                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        // Check for token in query string (for SignalR, etc.)
                        var accessToken = context.Request.Query["access_token"];

                        if (!string.IsNullOrEmpty(accessToken))
                        {
                            context.Token = accessToken;
                        }

                        return Task.CompletedTask;
                    },
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

        // Add Authorization Policies
        builder.Services.AddAuthorization(options =>
        {
            options.AddPolicy("RequireAdminRole", policy =>
                policy.RequireRole("Admin"));

            options.AddPolicy("RequireProductWrite", policy =>
                policy.RequireClaim("permissions", "products:write"));

            options.AddPolicy("RequireVerifiedEmail", policy =>
                policy.RequireClaim("email_verified", "true"));

            // Custom policy
            options.AddPolicy("MinimumAge", policy =>
                policy.Requirements.Add(new MinimumAgeRequirement(18)));
        });

        builder.Services.AddSingleton<IAuthorizationHandler, MinimumAgeHandler>();

        var app = builder.Build();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();
        app.Run();
    }
}

// Custom Authorization Requirement
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
        var dateOfBirth = context.User.FindFirst(c => c.Type == "date_of_birth")?.Value;

        if (string.IsNullOrEmpty(dateOfBirth))
        {
            return Task.CompletedTask;
        }

        if (DateTime.TryParse(dateOfBirth, out var dob))
        {
            var age = DateTime.Today.Year - dob.Year;
            if (dob > DateTime.Today.AddYears(-age))
            {
                age--;
            }

            if (age >= requirement.MinimumAge)
            {
                context.Succeed(requirement);
            }
        }

        return Task.CompletedTask;
    }
}

// Controller with Authorization
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    public IActionResult GetProducts()
    {
        return Ok(new[] { "Product1", "Product2" });
    }

    [HttpPost]
    [Authorize(Policy = "RequireProductWrite")]
    public IActionResult CreateProduct([FromBody] CreateProductRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userEmail = User.FindFirst(ClaimTypes.Email)?.Value;

        // Create product
        return Created("", new { Id = Guid.NewGuid() });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public IActionResult DeleteProduct(Guid id)
    {
        return NoContent();
    }
}

// ✅ PATTERN 2: Service-to-Service Authentication (Client Credentials)

public class ProductServiceClient
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ITokenService _tokenService;

    public ProductServiceClient(
        IHttpClientFactory httpClientFactory,
        ITokenService tokenService)
    {
        _httpClientFactory = httpClientFactory;
        _tokenService = tokenService;
    }

    public async Task<ProductDto> GetProductAsync(Guid productId)
    {
        // Get service-to-service token
        var token = await _tokenService.GetServiceTokenAsync("product-api");

        var client = _httpClientFactory.CreateClient("ProductService");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.GetAsync($"/api/products/{productId}");
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<ProductDto>();
    }
}

public interface ITokenService
{
    Task<string> GetServiceTokenAsync(string audience);
}

public class TokenService : ITokenService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _configuration;

    public TokenService(
        IHttpClientFactory httpClientFactory,
        IMemoryCache cache,
        IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _cache = cache;
        _configuration = configuration;
    }

    public async Task<string> GetServiceTokenAsync(string audience)
    {
        var cacheKey = $"service_token_{audience}";

        if (_cache.TryGetValue(cacheKey, out string cachedToken))
        {
            return cachedToken;
        }

        var client = _httpClientFactory.CreateClient();

        var request = new HttpRequestMessage(HttpMethod.Post, "https://identity-server.com/connect/token");
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "client_credentials",
            ["client_id"] = _configuration["ServiceClient:ClientId"],
            ["client_secret"] = _configuration["ServiceClient:ClientSecret"],
            ["scope"] = audience
        });

        var response = await client.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var tokenResponse = await response.Content.ReadFromJsonAsync<TokenResponse>();

        // Cache token with expiration
        _cache.Set(cacheKey, tokenResponse.AccessToken, TimeSpan.FromSeconds(tokenResponse.ExpiresIn - 60));

        return tokenResponse.AccessToken;
    }
}

public class TokenResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; }

    [JsonPropertyName("expires_in")]
    public int ExpiresIn { get; set; }

    [JsonPropertyName("token_type")]
    public string TokenType { get; set; }
}

// ✅ PATTERN 3: API Key Authentication for External Clients

public class ApiKeyAuthenticationHandler : AuthenticationHandler<ApiKeyAuthenticationOptions>
{
    private readonly IApiKeyValidator _apiKeyValidator;

    public ApiKeyAuthenticationHandler(
        IOptionsMonitor<ApiKeyAuthenticationOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        ISystemClock clock,
        IApiKeyValidator apiKeyValidator)
        : base(options, logger, encoder, clock)
    {
        _apiKeyValidator = apiKeyValidator;
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("X-API-Key", out var apiKeyHeaderValues))
        {
            return AuthenticateResult.Fail("API Key not provided");
        }

        var providedApiKey = apiKeyHeaderValues.FirstOrDefault();

        if (string.IsNullOrWhiteSpace(providedApiKey))
        {
            return AuthenticateResult.Fail("API Key is empty");
        }

        var apiKey = await _apiKeyValidator.ValidateAsync(providedApiKey);

        if (apiKey == null)
        {
            return AuthenticateResult.Fail("Invalid API Key");
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, apiKey.OwnerId.ToString()),
            new Claim(ClaimTypes.Name, apiKey.Name),
            new Claim("api_key_id", apiKey.Id.ToString())
        };

        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);

        return AuthenticateResult.Success(ticket);
    }
}

public class ApiKeyAuthenticationOptions : AuthenticationSchemeOptions
{
}

public interface IApiKeyValidator
{
    Task<ApiKey> ValidateAsync(string apiKey);
}

public class ApiKey
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public string Name { get; set; }
    public string Key { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

// ✅ PATTERN 4: Rate Limiting and Throttling

public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IDistributedCache _cache;
    private readonly ILogger<RateLimitingMiddleware> _logger;

    public RateLimitingMiddleware(
        RequestDelegate next,
        IDistributedCache cache,
        ILogger<RateLimitingMiddleware> logger)
    {
        _next = next;
        _cache = cache;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = GetClientId(context);
        var endpoint = context.Request.Path.ToString();

        var key = $"rate_limit:{clientId}:{endpoint}";
        var limit = 100; // requests per minute
        var window = TimeSpan.FromMinutes(1);

        var currentCount = await GetCurrentCountAsync(key);

        if (currentCount >= limit)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            context.Response.Headers.Add("Retry-After", "60");
            context.Response.Headers.Add("X-RateLimit-Limit", limit.ToString());
            context.Response.Headers.Add("X-RateLimit-Remaining", "0");

            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                message = "Too many requests. Please try again later."
            });

            _logger.LogWarning(
                "Rate limit exceeded for client {ClientId} on endpoint {Endpoint}",
                clientId,
                endpoint);

            return;
        }

        await IncrementCountAsync(key, window);

        context.Response.Headers.Add("X-RateLimit-Limit", limit.ToString());
        context.Response.Headers.Add("X-RateLimit-Remaining", (limit - currentCount - 1).ToString());

        await _next(context);
    }

    private string GetClientId(HttpContext context)
    {
        // Try to get from user claims
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            return userId;
        }

        // Try to get from API key
        var apiKey = context.Request.Headers["X-API-Key"].FirstOrDefault();
        if (!string.IsNullOrEmpty(apiKey))
        {
            return apiKey;
        }

        // Fall back to IP address
        return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }

    private async Task<int> GetCurrentCountAsync(string key)
    {
        var value = await _cache.GetStringAsync(key);
        return int.TryParse(value, out var count) ? count : 0;
    }

    private async Task IncrementCountAsync(string key, TimeSpan window)
    {
        var currentCount = await GetCurrentCountAsync(key);
        var newCount = currentCount + 1;

        await _cache.SetStringAsync(key, newCount.ToString(), new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = window
        });
    }
}

// ✅ PATTERN 5: Encryption and Data Protection

public class EncryptionService
{
    private readonly IDataProtector _protector;

    public EncryptionService(IDataProtectionProvider provider)
    {
        _protector = provider.CreateProtector("ProductService.Encryption");
    }

    public string Encrypt(string plainText)
    {
        return _protector.Protect(plainText);
    }

    public string Decrypt(string cipherText)
    {
        return _protector.Unprotect(cipherText);
    }
}

// Encrypt sensitive data at rest
public class Customer
{
    public Guid Id { get; set; }
    public string Name { get; set; }

    [EncryptedColumn]
    public string CreditCardNumber { get; set; }

    [EncryptedColumn]
    public string SSN { get; set; }
}

public class EncryptedColumnAttribute : Attribute
{
}

public class EncryptionInterceptor : SaveChangesInterceptor
{
    private readonly EncryptionService _encryptionService;

    public EncryptionInterceptor(EncryptionService encryptionService)
    {
        _encryptionService = encryptionService;
    }

    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        EncryptSensitiveData(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        EncryptSensitiveData(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void EncryptSensitiveData(DbContext context)
    {
        foreach (var entry in context.ChangeTracker.Entries())
        {
            foreach (var property in entry.Properties)
            {
                var attribute = property.Metadata.PropertyInfo?
                    .GetCustomAttribute<EncryptedColumnAttribute>();

                if (attribute != null && property.CurrentValue != null)
                {
                    var plainText = property.CurrentValue.ToString();
                    property.CurrentValue = _encryptionService.Encrypt(plainText);
                }
            }
        }
    }
}

/*
Security Best Practices:

1. Authentication & Authorization:
   ✅ Use OAuth 2.0 / OpenID Connect
   ✅ Implement JWT tokens
   ✅ Service-to-service authentication
   ✅ Fine-grained authorization
   ✅ Role-based access control (RBAC)
   ✅ Claims-based authorization

2. API Security:
   ✅ HTTPS everywhere
   ✅ API keys for external clients
   ✅ Rate limiting and throttling
   ✅ Input validation
   ✅ Output encoding
   ✅ CORS configuration

3. Data Security:
   ✅ Encrypt data at rest
   ✅ Encrypt data in transit (TLS)
   ✅ Secure secrets management
   ✅ Data masking/redaction
   ✅ Secure key storage

4. Network Security:
   ✅ Service mesh (mutual TLS)
   ✅ Network segmentation
   ✅ Firewall rules
   ✅ DDoS protection

5. Monitoring & Auditing:
   ✅ Security event logging
   ✅ Audit trails
   ✅ Intrusion detection
   ✅ Anomaly detection

Common Security Threats:
- Injection attacks (SQL, NoSQL, Command)
- Broken authentication
- Sensitive data exposure
- XML external entities (XXE)
- Broken access control
- Security misconfiguration
- Cross-site scripting (XSS)
- Insecure deserialization
- Using components with vulnerabilities
- Insufficient logging & monitoring

Security Tools:
- Identity Server / Auth0 / Azure AD
- HashiCorp Vault (secrets)
- OWASP ZAP (security testing)
- Snyk (vulnerability scanning)
- SonarQube (code analysis)
*/
```

---

## Q328. How do you containerize and orchestrate microservices with Docker and Kubernetes?

```csharp
/*
Container Orchestration with Docker and Kubernetes
*/

// ✅ PATTERN 1: Dockerfile for .NET Microservice

// Dockerfile (multi-stage build)
/*
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["ProductService/ProductService.csproj", "ProductService/"]
RUN dotnet restore "ProductService/ProductService.csproj"

# Copy source code and build
COPY ProductService/ ProductService/
WORKDIR "/src/ProductService"
RUN dotnet build "ProductService.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ProductService.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Copy published app
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

ENTRYPOINT ["dotnet", "ProductService.dll"]
*/

// ✅ PATTERN 2: Kubernetes Deployment

/*
# product-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: microservices
  labels:
    app: product-service
    version: v1
spec:
  replicas: 3
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: product-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: product-service
        version: v1
    spec:
      serviceAccountName: product-service
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: connection-string
        - name: ServiceDiscovery__ConsulUrl
          value: "http://consul:8500"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: product-service-config
      imagePullSecrets:
      - name: acr-secret
---
# product-service-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: microservices
  labels:
    app: product-service
spec:
  type: ClusterIP
  selector:
    app: product-service
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP
---
# product-service-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
  namespace: microservices
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
*/

// ✅ PATTERN 3: ConfigMap and Secrets

/*
# product-service-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-config
  namespace: microservices
data:
  appsettings.json: |
    {
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      },
      "ServiceDiscovery": {
        "ServiceName": "product-service",
        "ConsulUrl": "http://consul:8500"
      },
      "RabbitMQ": {
        "Host": "rabbitmq",
        "Port": 5672,
        "VirtualHost": "/"
      }
    }
---
# product-service-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: product-service-secrets
  namespace: microservices
type: Opaque
stringData:
  connection-string: "Server=sql-server;Database=ProductDb;User=sa;Password=YourPassword123;"
  rabbitmq-username: "guest"
  rabbitmq-password: "guest"
  jwt-secret-key: "your-256-bit-secret-key-here"
*/

// ✅ PATTERN 4: Ingress Configuration

/*
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  namespace: microservices
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.mycompany.com
    secretName: api-tls
  rules:
  - host: api.mycompany.com
    http:
      paths:
      - path: /products(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 80
      - path: /orders(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 80
      - path: /customers(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: customer-service
            port:
              number: 80
*/

// ✅ PATTERN 5: Kubernetes Health Checks in .NET

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" })
            .AddSqlServer(
                builder.Configuration.GetConnectionString("DefaultConnection"),
                name: "database",
                tags: new[] { "ready", "db" })
            .AddRabbitMQ(
                builder.Configuration.GetConnectionString("RabbitMQ"),
                name: "rabbitmq",
                tags: new[] { "ready", "messaging" })
            .AddUrlGroup(
                new Uri(builder.Configuration["ServiceDiscovery:ConsulUrl"] + "/v1/status/leader"),
                name: "consul",
                tags: new[] { "ready", "discovery" });

        var app = builder.Build();

        // Liveness probe - indicates if the app is alive
        app.MapHealthChecks("/health/live", new HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains("live")
        });

        // Readiness probe - indicates if the app is ready to receive traffic
        app.MapHealthChecks("/health/ready", new HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains("ready")
        });

        app.Run();
    }
}

// ✅ PATTERN 6: Graceful Shutdown

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Configure shutdown timeout
        builder.Host.ConfigureHostOptions(opts =>
        {
            opts.ShutdownTimeout = TimeSpan.FromSeconds(30);
        });

        // Add background services that need graceful shutdown
        builder.Services.AddHostedService<MessageProcessorService>();

        var app = builder.Build();

        app.Lifetime.ApplicationStopping.Register(() =>
        {
            Console.WriteLine("Application is stopping, draining requests...");
        });

        app.Lifetime.ApplicationStopped.Register(() =>
        {
            Console.WriteLine("Application stopped");
        });

        app.Run();
    }
}

public class MessageProcessorService : BackgroundService
{
    private readonly ILogger<MessageProcessorService> _logger;

    public MessageProcessorService(ILogger<MessageProcessorService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessMessagesAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("Message processing cancelled, shutting down gracefully");
                break;
            }

            await Task.Delay(TimeSpan.FromSeconds(1), stoppingToken);
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Stopping message processor...");
        await base.StopAsync(cancellationToken);
        _logger.LogInformation("Message processor stopped");
    }

    private async Task ProcessMessagesAsync(CancellationToken cancellationToken)
    {
        // Process messages
        await Task.CompletedTask;
    }
}

/*
Docker Best Practices:
✅ Use multi-stage builds
✅ Run as non-root user
✅ Minimize image layers
✅ Use .dockerignore file
✅ Don't store secrets in images
✅ Use specific base image tags
✅ Scan images for vulnerabilities
✅ Keep images small
✅ Use health checks
✅ Label images properly

Kubernetes Best Practices:
✅ Use namespaces for isolation
✅ Define resource limits/requests
✅ Implement liveness/readiness probes
✅ Use ConfigMaps for configuration
✅ Store secrets in Kubernetes Secrets
✅ Use Horizontal Pod Autoscaler
✅ Implement graceful shutdown
✅ Use rolling updates
✅ Configure pod disruption budgets
✅ Use service mesh for advanced features

Resource Management:
- Requests: Guaranteed resources
- Limits: Maximum resources allowed
- QoS Classes:
  * Guaranteed: requests == limits
  * Burstable: requests < limits
  * BestEffort: no requests/limits

Scaling Strategies:
1. Horizontal Pod Autoscaler (HPA): Scale based on CPU/memory/custom metrics
2. Vertical Pod Autoscaler (VPA): Adjust resource requests/limits
3. Cluster Autoscaler: Add/remove nodes based on pending pods

Deployment Strategies:
- Rolling Update: Gradual replacement (zero downtime)
- Recreate: Delete old, create new (downtime)
- Blue-Green: Deploy new version alongside old
- Canary: Gradual traffic shift to new version
*/
```

---

## Q329. How do you implement comprehensive testing strategies for microservices?

```csharp
/*
Microservices Testing Strategies
*/

// ✅ PATTERN 1: Unit Testing

// Unit test for service logic
public class ProductServiceTests
{
    private readonly Mock<IProductRepository> _repositoryMock;
    private readonly Mock<IEventBus> _eventBusMock;
    private readonly Mock<ILogger<ProductService>> _loggerMock;
    private readonly ProductService _sut; // System Under Test

    public ProductServiceTests()
    {
        _repositoryMock = new Mock<IProductRepository>();
        _eventBusMock = new Mock<IEventBus>();
        _loggerMock = new Mock<ILogger<ProductService>>();
        _sut = new ProductService(_repositoryMock.Object, _eventBusMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task CreateProductAsync_ValidProduct_ReturnsProduct()
    {
        // Arrange
        var request = new CreateProductRequest
        {
            Name = "Test Product",
            Price = 99.99m,
            StockQuantity = 10
        };

        _repositoryMock
            .Setup(r => r.AddAsync(It.IsAny<Product>()))
            .Returns(Task.CompletedTask);

        // Act
        var result = await _sut.CreateProductAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(request.Name, result.Name);
        Assert.Equal(request.Price, result.Price);

        _repositoryMock.Verify(r => r.AddAsync(It.IsAny<Product>()), Times.Once);
        _eventBusMock.Verify(e => e.PublishAsync(It.IsAny<ProductCreatedEvent>()), Times.Once);
    }

    [Fact]
    public async Task UpdateProductPriceAsync_NegativePrice_ThrowsException()
    {
        // Arrange
        var productId = Guid.NewGuid();
        var newPrice = -10m;

        // Act & Assert
        await Assert.ThrowsAsync<ArgumentException>(
            () => _sut.UpdateProductPriceAsync(productId, newPrice));
    }
}

// ✅ PATTERN 2: Integration Testing

public class ProductApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ProductApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace production services with test doubles
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<ProductDbContext>));

                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                // Use in-memory database
                services.AddDbContext<ProductDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });

                // Build service provider
                var sp = services.BuildServiceProvider();

                using var scope = sp.CreateScope();
                var scopedServices = scope.ServiceProvider;
                var db = scopedServices.GetRequiredService<ProductDbContext>();

                // Ensure database is created
                db.Database.EnsureCreated();

                // Seed test data
                SeedDatabase(db);
            });
        });

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetProduct_ExistingId_ReturnsProduct()
    {
        // Arrange
        var productId = Guid.Parse("00000000-0000-0000-0000-000000000001");

        // Act
        var response = await _client.GetAsync($"/api/products/{productId}");

        // Assert
        response.EnsureSuccessStatusCode();
        var product = await response.Content.ReadFromJsonAsync<ProductDto>();

        Assert.NotNull(product);
        Assert.Equal(productId, product.Id);
    }

    [Fact]
    public async Task CreateProduct_ValidRequest_ReturnsCreated()
    {
        // Arrange
        var request = new CreateProductRequest
        {
            Name = "New Product",
            Price = 29.99m,
            StockQuantity = 100
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/products", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var product = await response.Content.ReadFromJsonAsync<ProductDto>();

        Assert.NotNull(product);
        Assert.Equal(request.Name, product.Name);
    }

    private void SeedDatabase(ProductDbContext db)
    {
        db.Products.Add(new Product
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            Name = "Test Product",
            Price = 9.99m,
            StockQuantity = 50
        });

        db.SaveChanges();
    }
}

// ✅ PATTERN 3: Contract Testing (Consumer-Driven Contracts)

// Install: dotnet add package PactNet

public class ProductServiceConsumerTests : IDisposable
{
    private readonly IPactBuilderV3 _pact;
    private readonly int _mockServerPort = 9222;

    public ProductServiceConsumerTests()
    {
        var pactConfig = new PactConfig
        {
            PactDir = Path.Join("..", "..", "..", "pacts"),
            LogDir = Path.Join("..", "..", "..", "logs")
        };

        _pact = Pact.V3("OrderService", "ProductService", pactConfig)
            .WithHttpInteractions(_mockServerPort);
    }

    [Fact]
    public async Task GetProduct_WhenProductExists_ReturnsProduct()
    {
        // Arrange
        var productId = Guid.NewGuid();

        _pact
            .UponReceiving("A request to get a product by ID")
                .WithRequest(HttpMethod.Get, $"/api/products/{productId}")
                .WithHeader("Accept", "application/json")
            .WillRespond()
                .WithStatus(HttpStatusCode.OK)
                .WithHeader("Content-Type", "application/json")
                .WithJsonBody(new
                {
                    id = productId,
                    name = "Test Product",
                    price = 99.99,
                    stockQuantity = 10
                });

        await _pact.VerifyAsync(async ctx =>
        {
            // Act
            var client = new HttpClient { BaseAddress = ctx.MockServerUri };
            var response = await client.GetAsync($"/api/products/{productId}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var product = await response.Content.ReadFromJsonAsync<ProductDto>();
            Assert.NotNull(product);
            Assert.Equal(productId, product.Id);
        });
    }

    public void Dispose()
    {
        _pact.Dispose();
    }
}

// ✅ PATTERN 4: End-to-End Testing

public class OrderWorkflowE2ETests : IClassFixture<MicroservicesTestFixture>
{
    private readonly MicroservicesTestFixture _fixture;

    public OrderWorkflowE2ETests(MicroservicesTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task CompleteOrderWorkflow_Success()
    {
        // Arrange
        var customerId = await CreateCustomerAsync();
        var productId = await CreateProductAsync();

        // Act - Create Order
        var orderRequest = new CreateOrderRequest
        {
            CustomerId = customerId,
            Items = new[]
            {
                new OrderItemDto
                {
                    ProductId = productId,
                    Quantity = 2,
                    Price = 99.99m
                }
            },
            TotalAmount = 199.98m
        };

        var orderResponse = await _fixture.OrderServiceClient.PostAsJsonAsync(
            "/api/orders",
            orderRequest);

        // Assert - Order Created
        Assert.Equal(HttpStatusCode.Created, orderResponse.StatusCode);
        var order = await orderResponse.Content.ReadFromJsonAsync<OrderDto>();
        Assert.NotNull(order);

        // Verify - Inventory Reserved
        await Task.Delay(TimeSpan.FromSeconds(2)); // Wait for async processing

        var inventoryResponse = await _fixture.InventoryServiceClient.GetAsync(
            $"/api/inventory/{productId}");
        var inventory = await inventoryResponse.Content.ReadFromJsonAsync<InventoryDto>();

        Assert.NotNull(inventory);
        Assert.Equal(8, inventory.AvailableQuantity); // 10 - 2

        // Verify - Payment Processed
        var paymentResponse = await _fixture.PaymentServiceClient.GetAsync(
            $"/api/payments/order/{order.Id}");
        var payment = await paymentResponse.Content.ReadFromJsonAsync<PaymentDto>();

        Assert.NotNull(payment);
        Assert.Equal("Completed", payment.Status);
    }

    private async Task<Guid> CreateCustomerAsync()
    {
        var customer = new CreateCustomerRequest
        {
            Name = "Test Customer",
            Email = "test@example.com"
        };

        var response = await _fixture.CustomerServiceClient.PostAsJsonAsync(
            "/api/customers",
            customer);

        var result = await response.Content.ReadFromJsonAsync<CustomerDto>();
        return result.Id;
    }

    private async Task<Guid> CreateProductAsync()
    {
        var product = new CreateProductRequest
        {
            Name = "Test Product",
            Price = 99.99m,
            StockQuantity = 10
        };

        var response = await _fixture.ProductServiceClient.PostAsJsonAsync(
            "/api/products",
            product);

        var result = await response.Content.ReadFromJsonAsync<ProductDto>();
        return result.Id;
    }
}

// Test Fixture for E2E tests
public class MicroservicesTestFixture : IAsyncLifetime
{
    public HttpClient ProductServiceClient { get; private set; }
    public HttpClient OrderServiceClient { get; private set; }
    public HttpClient CustomerServiceClient { get; private set; }
    public HttpClient InventoryServiceClient { get; private set; }
    public HttpClient PaymentServiceClient { get; private set; }

    private DockerCompose _dockerCompose;

    public async Task InitializeAsync()
    {
        // Start all services using Docker Compose
        _dockerCompose = new DockerCompose("docker-compose.test.yml");
        await _dockerCompose.UpAsync();

        // Wait for services to be ready
        await WaitForServicesAsync();

        // Initialize HTTP clients
        ProductServiceClient = new HttpClient { BaseAddress = new Uri("http://localhost:5001") };
        OrderServiceClient = new HttpClient { BaseAddress = new Uri("http://localhost:5002") };
        CustomerServiceClient = new HttpClient { BaseAddress = new Uri("http://localhost:5003") };
        InventoryServiceClient = new HttpClient { BaseAddress = new Uri("http://localhost:5004") };
        PaymentServiceClient = new HttpClient { BaseAddress = new Uri("http://localhost:5005") };
    }

    public async Task DisposeAsync()
    {
        ProductServiceClient?.Dispose();
        OrderServiceClient?.Dispose();
        CustomerServiceClient?.Dispose();
        InventoryServiceClient?.Dispose();
        PaymentServiceClient?.Dispose();

        await _dockerCompose.DownAsync();
    }

    private async Task WaitForServicesAsync()
    {
        var healthEndpoints = new[]
        {
            "http://localhost:5001/health",
            "http://localhost:5002/health",
            "http://localhost:5003/health",
            "http://localhost:5004/health",
            "http://localhost:5005/health"
        };

        using var client = new HttpClient();
        var maxRetries = 30;

        foreach (var endpoint in healthEndpoints)
        {
            for (int i = 0; i < maxRetries; i++)
            {
                try
                {
                    var response = await client.GetAsync(endpoint);
                    if (response.IsSuccessStatusCode)
                    {
                        break;
                    }
                }
                catch
                {
                    if (i == maxRetries - 1)
                    {
                        throw new Exception($"Service at {endpoint} failed to start");
                    }
                }

                await Task.Delay(TimeSpan.FromSeconds(2));
            }
        }
    }
}

// ✅ PATTERN 5: Performance Testing

public class PerformanceTests
{
    [Fact]
    public async Task GetProduct_UnderLoad_MeetsPerformanceRequirements()
    {
        // Arrange
        var client = new HttpClient { BaseAddress = new Uri("http://localhost:5001") };
        var productId = Guid.NewGuid();
        var requestCount = 1000;
        var maxDurationMs = 5000; // 5 seconds for 1000 requests

        // Act
        var stopwatch = Stopwatch.StartNew();
        var tasks = Enumerable.Range(0, requestCount)
            .Select(_ => client.GetAsync($"/api/products/{productId}"))
            .ToArray();

        await Task.WhenAll(tasks);
        stopwatch.Stop();

        // Assert
        Assert.True(stopwatch.ElapsedMilliseconds < maxDurationMs,
            $"Performance test failed. Expected < {maxDurationMs}ms, actual: {stopwatch.ElapsedMilliseconds}ms");

        var successfulRequests = tasks.Count(t => t.Result.IsSuccessStatusCode);
        var successRate = (double)successfulRequests / requestCount * 100;

        Assert.True(successRate >= 99,
            $"Success rate too low. Expected >= 99%, actual: {successRate:F2}%");
    }
}

/*
Testing Pyramid for Microservices:

1. Unit Tests (70%):
   ✅ Fast execution
   ✅ Test business logic
   ✅ High code coverage
   ✅ Mock dependencies

2. Integration Tests (20%):
   ✅ Test API endpoints
   ✅ Test database interactions
   ✅ Test message handling
   ✅ Use test doubles/containers

3. Contract Tests (5%):
   ✅ Verify service contracts
   ✅ Consumer-driven
   ✅ Prevent breaking changes
   ✅ Test API compatibility

4. End-to-End Tests (5%):
   ✅ Test complete workflows
   ✅ Test service integration
   ✅ Use Docker Compose
   ✅ Test critical paths only

Testing Best Practices:
✅ Follow AAA pattern (Arrange, Act, Assert)
✅ Use descriptive test names
✅ One assertion per test (when possible)
✅ Use test data builders
✅ Mock external dependencies
✅ Test edge cases and error paths
✅ Use test containers for integration tests
✅ Implement contract testing
✅ Automate tests in CI/CD
✅ Monitor test execution time

Testing Tools:
- Unit: xUnit, NUnit, MSTest
- Mocking: Moq, NSubstitute
- Integration: WebApplicationFactory, Testcontainers
- Contract: Pact
- E2E: SpecFlow, Selenium
- Performance: K6, JMeter, NBomber
- API: Postman, REST Client
*/
```

---

## Q330. How do you implement deployment strategies for microservices (Blue-Green, Canary, Rolling)?

```csharp
/*
Deployment Strategies for Microservices
*/

// ✅ PATTERN 1: Blue-Green Deployment with Kubernetes

/*
# Blue Deployment (Current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-blue
  namespace: microservices
  labels:
    app: product-service
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: product-service
      version: blue
  template:
    metadata:
      labels:
        app: product-service
        version: blue
    spec:
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:1.0.0
        ports:
        - containerPort: 8080
---
# Green Deployment (New)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-green
  namespace: microservices
  labels:
    app: product-service
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: product-service
      version: green
  template:
    metadata:
      labels:
        app: product-service
        version: green
    spec:
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:2.0.0
        ports:
        - containerPort: 8080
---
# Service (points to blue initially)
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: microservices
spec:
  selector:
    app: product-service
    version: blue  # Switch to 'green' to deploy
  ports:
  - port: 80
    targetPort: 8080
*/

// Blue-Green Deployment Script
public class BlueGreenDeployment
{
    public async Task DeployAsync(string newVersion)
    {
        // Step 1: Deploy green environment
        Console.WriteLine("Deploying green environment...");
        await DeployGreenEnvironmentAsync(newVersion);

        // Step 2: Run smoke tests on green
        Console.WriteLine("Running smoke tests on green...");
        var testsPass = await RunSmokeTestsAsync("green");

        if (!testsPass)
        {
            Console.WriteLine("Smoke tests failed, rolling back...");
            await DeleteGreenEnvironmentAsync();
            throw new Exception("Deployment failed: smoke tests");
        }

        // Step 3: Switch traffic to green
        Console.WriteLine("Switching traffic to green...");
        await SwitchTrafficToGreenAsync();

        // Step 4: Monitor for issues
        Console.WriteLine("Monitoring green environment...");
        await Task.Delay(TimeSpan.FromMinutes(5));

        var isHealthy = await MonitorHealthAsync("green");

        if (!isHealthy)
        {
            Console.WriteLine("Health check failed, rolling back to blue...");
            await SwitchTrafficToBlueAsync();
            throw new Exception("Deployment failed: health check");
        }

        // Step 5: Delete blue environment
        Console.WriteLine("Deployment successful, removing blue environment...");
        await DeleteBlueEnvironmentAsync();
    }

    private async Task DeployGreenEnvironmentAsync(string version)
    {
        await ExecuteKubectlAsync($"apply -f product-service-green.yaml");
        await WaitForPodsReadyAsync("version=green");
    }

    private async Task<bool> RunSmokeTestsAsync(string environment)
    {
        var serviceUrl = environment == "green"
            ? "http://product-service-green/health"
            : "http://product-service-blue/health";

        using var client = new HttpClient();
        var response = await client.GetAsync(serviceUrl);
        return response.IsSuccessStatusCode;
    }

    private async Task SwitchTrafficToGreenAsync()
    {
        await ExecuteKubectlAsync(
            "patch service product-service -p '{\"spec\":{\"selector\":{\"version\":\"green\"}}}'");
    }

    private async Task SwitchTrafficToBlueAsync()
    {
        await ExecuteKubectlAsync(
            "patch service product-service -p '{\"spec\":{\"selector\":{\"version\":\"blue\"}}}'");
    }

    private async Task DeleteBlueEnvironmentAsync()
    {
        await ExecuteKubectlAsync("delete deployment product-service-blue");
    }

    private async Task DeleteGreenEnvironmentAsync()
    {
        await ExecuteKubectlAsync("delete deployment product-service-green");
    }

    private async Task<bool> MonitorHealthAsync(string environment)
    {
        // Monitor metrics, error rates, response times
        return await Task.FromResult(true);
    }

    private async Task ExecuteKubectlAsync(string command)
    {
        // Execute kubectl command
        await Task.CompletedTask;
    }

    private async Task WaitForPodsReadyAsync(string selector)
    {
        // Wait for pods to be ready
        await Task.CompletedTask;
    }
}

// ✅ PATTERN 2: Canary Deployment

/*
# Main Deployment (Stable)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-stable
  namespace: microservices
spec:
  replicas: 9  # 90% of traffic
  selector:
    matchLabels:
      app: product-service
      track: stable
  template:
    metadata:
      labels:
        app: product-service
        track: stable
        version: v1
    spec:
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:1.0.0
---
# Canary Deployment (New Version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-canary
  namespace: microservices
spec:
  replicas: 1  # 10% of traffic
  selector:
    matchLabels:
      app: product-service
      track: canary
  template:
    metadata:
      labels:
        app: product-service
        track: canary
        version: v2
    spec:
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:2.0.0
---
# Service (routes to both stable and canary)
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: microservices
spec:
  selector:
    app: product-service  # Routes to both stable and canary
  ports:
  - port: 80
    targetPort: 8080
*/

// Canary Deployment with Progressive Traffic Shifting
public class CanaryDeployment
{
    public async Task DeployAsync(string newVersion)
    {
        // Step 1: Deploy canary with 10% traffic
        Console.WriteLine("Deploying canary with 10% traffic...");
        await DeployCanaryAsync(newVersion, replicasCanary: 1, replicasStable: 9);

        // Step 2: Monitor metrics for canary
        await MonitorAndValidateAsync(duration: TimeSpan.FromMinutes(10));

        // Step 3: Increase to 25% traffic
        Console.WriteLine("Increasing canary traffic to 25%...");
        await ScaleCanaryAsync(replicasCanary: 3, replicasStable: 9);
        await MonitorAndValidateAsync(duration: TimeSpan.FromMinutes(10));

        // Step 4: Increase to 50% traffic
        Console.WriteLine("Increasing canary traffic to 50%...");
        await ScaleCanaryAsync(replicasCanary: 5, replicasStable: 5);
        await MonitorAndValidateAsync(duration: TimeSpan.FromMinutes(10));

        // Step 5: Promote canary to stable
        Console.WriteLine("Promoting canary to stable...");
        await PromoteCanaryToStableAsync(newVersion);

        // Step 6: Remove old stable deployment
        Console.WriteLine("Removing old stable deployment...");
        await RemoveOldStableAsync();
    }

    private async Task DeployCanaryAsync(string version, int replicasCanary, int replicasStable)
    {
        await ExecuteKubectlAsync($"scale deployment product-service-stable --replicas={replicasStable}");
        await ExecuteKubectlAsync($"apply -f product-service-canary.yaml");
        await ExecuteKubectlAsync($"scale deployment product-service-canary --replicas={replicasCanary}");
    }

    private async Task MonitorAndValidateAsync(TimeSpan duration)
    {
        var endTime = DateTime.UtcNow.Add(duration);

        while (DateTime.UtcNow < endTime)
        {
            var metrics = await CollectMetricsAsync();

            if (metrics.ErrorRate > 0.01) // 1% error rate threshold
            {
                Console.WriteLine("Error rate too high, rolling back...");
                await RollbackCanaryAsync();
                throw new Exception("Canary deployment failed: high error rate");
            }

            if (metrics.AverageLatencyMs > 500) // 500ms latency threshold
            {
                Console.WriteLine("Latency too high, rolling back...");
                await RollbackCanaryAsync();
                throw new Exception("Canary deployment failed: high latency");
            }

            await Task.Delay(TimeSpan.FromSeconds(30));
        }
    }

    private async Task<DeploymentMetrics> CollectMetricsAsync()
    {
        // Collect metrics from Prometheus, Application Insights, etc.
        return new DeploymentMetrics
        {
            ErrorRate = 0.001,
            AverageLatencyMs = 150,
            RequestsPerSecond = 1000
        };
    }

    private async Task ScaleCanaryAsync(int replicasCanary, int replicasStable)
    {
        await ExecuteKubectlAsync($"scale deployment product-service-canary --replicas={replicasCanary}");
        await ExecuteKubectlAsync($"scale deployment product-service-stable --replicas={replicasStable}");
        await WaitForPodsReadyAsync("app=product-service");
    }

    private async Task PromoteCanaryToStableAsync(string version)
    {
        // Update stable deployment to use canary version
        await ExecuteKubectlAsync(
            $"set image deployment/product-service-stable product-service=myregistry.azurecr.io/product-service:{version}");
        await ExecuteKubectlAsync("scale deployment product-service-stable --replicas=10");
    }

    private async Task RemoveOldStableAsync()
    {
        await ExecuteKubectlAsync("delete deployment product-service-canary");
    }

    private async Task RollbackCanaryAsync()
    {
        await ExecuteKubectlAsync("scale deployment product-service-canary --replicas=0");
        await ExecuteKubectlAsync("scale deployment product-service-stable --replicas=10");
    }

    private async Task ExecuteKubectlAsync(string command)
    {
        await Task.CompletedTask;
    }

    private async Task WaitForPodsReadyAsync(string selector)
    {
        await Task.CompletedTask;
    }
}

public class DeploymentMetrics
{
    public double ErrorRate { get; set; }
    public double AverageLatencyMs { get; set; }
    public double RequestsPerSecond { get; set; }
}

// ✅ PATTERN 3: Rolling Update (Built into Kubernetes)

/*
# Deployment with Rolling Update Strategy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: microservices
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Max pods above desired count
      maxUnavailable: 1  # Max pods unavailable during update
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: myregistry.azurecr.io/product-service:2.0.0
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
*/

// Monitor Rolling Update
public class RollingUpdateMonitor
{
    public async Task MonitorRollingUpdateAsync(string deploymentName)
    {
        Console.WriteLine($"Monitoring rolling update for {deploymentName}...");

        while (true)
        {
            var status = await GetDeploymentStatusAsync(deploymentName);

            Console.WriteLine($"Updated: {status.UpdatedReplicas}/{status.Replicas}");
            Console.WriteLine($"Ready: {status.ReadyReplicas}/{status.Replicas}");
            Console.WriteLine($"Available: {status.AvailableReplicas}/{status.Replicas}");

            if (status.UpdatedReplicas == status.Replicas &&
                status.ReadyReplicas == status.Replicas &&
                status.AvailableReplicas == status.Replicas)
            {
                Console.WriteLine("Rolling update completed successfully!");
                break;
            }

            if (status.Conditions.Any(c => c.Type == "Progressing" && c.Status == "False"))
            {
                Console.WriteLine("Rolling update failed!");
                throw new Exception("Deployment failed to progress");
            }

            await Task.Delay(TimeSpan.FromSeconds(5));
        }
    }

    private async Task<DeploymentStatus> GetDeploymentStatusAsync(string deploymentName)
    {
        // Query Kubernetes API for deployment status
        return new DeploymentStatus
        {
            Replicas = 10,
            UpdatedReplicas = 8,
            ReadyReplicas = 8,
            AvailableReplicas = 8,
            Conditions = new List<DeploymentCondition>()
        };
    }
}

public class DeploymentStatus
{
    public int Replicas { get; set; }
    public int UpdatedReplicas { get; set; }
    public int ReadyReplicas { get; set; }
    public int AvailableReplicas { get; set; }
    public List<DeploymentCondition> Conditions { get; set; }
}

public class DeploymentCondition
{
    public string Type { get; set; }
    public string Status { get; set; }
}

/*
Deployment Strategy Comparison:

1. Blue-Green:
   ✅ Zero downtime
   ✅ Instant rollback
   ✅ Full testing before switch
   ❌ Requires 2x resources
   ❌ All-or-nothing switch

2. Canary:
   ✅ Gradual rollout
   ✅ Risk mitigation
   ✅ Real user feedback
   ❌ Complex to implement
   ❌ Longer deployment time

3. Rolling Update:
   ✅ Built into Kubernetes
   ✅ Resource efficient
   ✅ Automatic
   ❌ Slower rollback
   ❌ Mixed versions during deploy

Best Practices:
✅ Implement health checks
✅ Monitor key metrics during deployment
✅ Define rollback criteria
✅ Automate deployment process
✅ Test in staging first
✅ Use feature flags
✅ Implement smoke tests
✅ Monitor error rates and latency
✅ Have rollback plan ready
✅ Document deployment procedures

Key Metrics to Monitor:
- Error rate
- Response time (p50, p95, p99)
- Request rate
- CPU/Memory usage
- Database connections
- Queue depth
- Custom business metrics
*/
```

---

## Q331. How do you implement distributed caching strategies in microservices?

```csharp
/*
Distributed Caching in Microservices - Redis Implementation
*/

// Install: dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis

public class RedisCacheService : ICacheService
{
    private readonly IDistributedCache _cache;

    public async Task<T> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, TimeSpan? expiration = null)
    {
        var cached = await GetAsync<T>(key);
        if (cached != null) return cached;

        var value = await factory();
        await SetAsync(key, value, expiration);
        return value;
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan? expiration = null)
    {
        var json = JsonSerializer.Serialize(value);
        await _cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = expiration ?? TimeSpan.FromMinutes(5)
        });
    }
}

/*
Caching Best Practices:
✅ Use appropriate TTL values
✅ Implement cache invalidation
✅ Handle cache failures gracefully
✅ Monitor cache hit/miss ratio
✅ Use distributed locks for critical sections
*/
```

---

## Q332-Q340. Final Microservices Topics

```csharp
/*
Remaining Essential Microservices Patterns and Best Practices
*/

// Q332: Resilience Patterns (Bulkhead, Timeout, Fallback)
// - Bulkhead: Isolate resources to prevent cascading failures
// - Timeout: Prevent indefinite waiting
// - Fallback: Provide degraded functionality

// Q333: API Versioning
// - URL Path: /api/v1/products
// - Header: X-API-Version: 1.0
// - Query String: ?api-version=1.0

// Q334: Orchestration vs Choreography
// - Orchestration: Centralized control (better for complex workflows)
// - Choreography: Event-driven, decentralized (better for scalability)

// Q335-Q340: Additional Critical Topics
// - Service Mesh (Istio, Linkerd)
// - Monitoring and Alerting (Prometheus, Grafana)
// - Migration Strategies (Strangler Fig Pattern)
// - Scalability Patterns (HPA, Caching, Sharding)
// - Best Practices and Anti-Patterns

/*
Microservices Success Factors:

✅ DO:
- Design around business capabilities
- Decentralize data management
- Automate deployment
- Design for failure
- Evolve incrementally

❌ DON'T:
- Share databases between services
- Create distributed monoliths
- Skip monitoring and observability
- Ignore data consistency challenges
- Over-engineer prematurely

Final Recommendations:
1. Start with a monolith if you're small
2. Extract microservices when teams grow
3. Invest heavily in DevOps and automation
4. Build observability from day one
5. Accept eventual consistency
6. Focus on business value, not architecture
*/
```

---

**End of Q321-Q340: Microservices & Distributed Systems**

This comprehensive section covers:
- Microservices architecture principles and patterns
- Inter-service communication (REST, gRPC, messaging)
- API Gateway implementation (Ocelot, YARP)
- Distributed tracing and observability (OpenTelemetry)
- CQRS and Event Sourcing
- Data management and consistency patterns
- Security (JWT, OAuth, encryption)
- Docker and Kubernetes orchestration
- Testing strategies (unit, integration, contract, E2E)
- Deployment strategies (Blue-Green, Canary, Rolling)
- Distributed caching with Redis
- Resilience patterns (Circuit Breaker, Bulkhead, Retry)
- API versioning
- Orchestration vs Choreography
- Best practices and anti-patterns

Total: 20 detailed questions with production-ready code examples and architectural guidance for building scalable, resilient microservices systems.

