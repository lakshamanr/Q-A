# Design Patterns in C# and .NET - Interview Questions (Q241-Q260)

## Q241: What are Design Patterns? Explain the main categories.

**Answer:**

**Design Patterns** are reusable solutions to commonly occurring problems in software design. They represent best practices evolved over time.

### Categories of Design Patterns

```
┌─────────────────────────────────────────────────────────┐
│                  DESIGN PATTERNS                         │
├─────────────────┬───────────────────┬───────────────────┤
│  Creational     │  Structural       │  Behavioral       │
│  (How objects   │  (How objects     │  (How objects     │
│   are created)  │   are composed)   │   interact)       │
├─────────────────┼───────────────────┼───────────────────┤
│ • Singleton     │ • Adapter         │ • Strategy        │
│ • Factory       │ • Decorator       │ • Observer        │
│ • Abstract      │ • Facade          │ • Command         │
│   Factory       │ • Composite       │ • Iterator        │
│ • Builder       │ • Proxy           │ • State           │
│ • Prototype     │ • Bridge          │ • Template Method │
│                 │ • Flyweight       │ • Chain of Resp.  │
│                 │                   │ • Mediator        │
│                 │                   │ • Memento         │
│                 │                   │ • Visitor         │
└─────────────────┴───────────────────┴───────────────────┘
```

### Why Use Design Patterns?

```csharp
// ============================================
// BENEFITS OF DESIGN PATTERNS
// ============================================

// 1. Proven Solutions
// Patterns are time-tested solutions to recurring problems

// 2. Common Vocabulary
// Team members can communicate design ideas using pattern names
// "Let's use a Factory pattern here" is clearer than explaining the entire concept

// 3. Code Reusability
// Patterns promote code reuse and reduce duplication

// 4. Maintainability
// Well-structured code using patterns is easier to maintain

// 5. Scalability
// Patterns help create flexible, scalable architectures
```

---

### Quick Reference

```csharp
// ============================================
// WHEN TO USE WHICH PATTERN
// ============================================

// CREATIONAL PATTERNS - Object Creation

// Singleton: Only one instance needed (e.g., Configuration, Logger)
public class DatabaseConnection
{
    private static DatabaseConnection _instance;
    public static DatabaseConnection Instance => _instance ??= new DatabaseConnection();
}

// Factory: Create objects without specifying exact class
public interface IPaymentProcessor { }
public class PaymentProcessorFactory
{
    public IPaymentProcessor Create(string type) => type switch
    {
        "CreditCard" => new CreditCardProcessor(),
        "PayPal" => new PayPalProcessor(),
        _ => throw new ArgumentException("Invalid type")
    };
}

// Builder: Construct complex objects step by step
var pizza = new PizzaBuilder()
    .SetSize("Large")
    .AddTopping("Cheese")
    .AddTopping("Pepperoni")
    .Build();

// STRUCTURAL PATTERNS - Object Composition

// Adapter: Make incompatible interfaces work together
public class LegacySystemAdapter : IModernInterface
{
    private LegacySystem _legacy = new();
    public void ModernMethod() => _legacy.OldMethod();
}

// Decorator: Add behavior to objects dynamically
public class LoggingDecorator : IService
{
    private IService _service;
    public void Execute()
    {
        Log("Before");
        _service.Execute();
        Log("After");
    }
}

// BEHAVIORAL PATTERNS - Object Interaction

// Strategy: Select algorithm at runtime
public class PaymentContext
{
    private IPaymentStrategy _strategy;
    public void SetStrategy(IPaymentStrategy strategy) => _strategy = strategy;
    public void Pay(decimal amount) => _strategy.Pay(amount);
}

// Observer: Notify dependents when state changes
public class StockPrice
{
    private List<IObserver> _observers = new();
    public void Attach(IObserver observer) => _observers.Add(observer);
    public void Notify() => _observers.ForEach(o => o.Update());
}
```

---

### SOLID Principles and Patterns

```csharp
// ============================================
// PATTERNS SUPPORT SOLID PRINCIPLES
// ============================================

// S - Single Responsibility Principle
// Each pattern focuses on a single responsibility

// O - Open/Closed Principle
// Strategy, Decorator: Open for extension, closed for modification

// L - Liskov Substitution Principle
// Factory, Abstract Factory: Substitutable implementations

// I - Interface Segregation Principle
// Adapter: Clients depend only on interfaces they use

// D - Dependency Inversion Principle
// Dependency Injection: Depend on abstractions, not concretions
```

---

## Q242: Explain the Singleton Pattern with thread-safe implementation.

**Answer:**

**Singleton Pattern** ensures a class has only one instance and provides global access to it.

### Basic Singleton (NOT Thread-Safe)

```csharp
// ============================================
// BASIC SINGLETON (NOT RECOMMENDED)
// ============================================

public class BasicSingleton
{
    private static BasicSingleton _instance;

    // Private constructor prevents instantiation
    private BasicSingleton()
    {
        Console.WriteLine("Singleton instance created");
    }

    public static BasicSingleton Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = new BasicSingleton();  // ❌ NOT thread-safe!
            }
            return _instance;
        }
    }

    public void DoSomething()
    {
        Console.WriteLine("Doing something");
    }
}

// Problem: Multiple threads can create multiple instances
```

---

### Thread-Safe Singleton with Lock

```csharp
// ============================================
// THREAD-SAFE SINGLETON WITH DOUBLE-CHECK LOCKING
// ============================================

public class ThreadSafeSingleton
{
    private static ThreadSafeSingleton _instance;
    private static readonly object _lock = new object();

    private ThreadSafeSingleton()
    {
        Console.WriteLine("Singleton instance created");
    }

    public static ThreadSafeSingleton Instance
    {
        get
        {
            // First check (without lock for performance)
            if (_instance == null)
            {
                lock (_lock)
                {
                    // Second check (with lock for thread safety)
                    if (_instance == null)
                    {
                        _instance = new ThreadSafeSingleton();
                    }
                }
            }
            return _instance;
        }
    }

    public void DoSomething()
    {
        Console.WriteLine("Doing something safely");
    }
}

// Usage
var instance1 = ThreadSafeSingleton.Instance;
var instance2 = ThreadSafeSingleton.Instance;
Console.WriteLine(instance1 == instance2);  // True - same instance
```

---

### Lazy<T> Singleton (Recommended)

```csharp
// ============================================
// LAZY<T> SINGLETON (BEST PRACTICE)
// ============================================

public class LazySingleton
{
    // Lazy<T> is thread-safe by default
    private static readonly Lazy<LazySingleton> _instance =
        new Lazy<LazySingleton>(() => new LazySingleton());

    private LazySingleton()
    {
        Console.WriteLine("Lazy singleton instance created");
    }

    public static LazySingleton Instance => _instance.Value;

    public void DoSomething()
    {
        Console.WriteLine("Doing something with Lazy");
    }
}

// Benefits:
// ✅ Thread-safe
// ✅ Lazy initialization
// ✅ Clean code
// ✅ High performance
```

---

### Eager Initialization Singleton

```csharp
// ============================================
// EAGER INITIALIZATION SINGLETON
// ============================================

public class EagerSingleton
{
    // Instance created at class loading time
    private static readonly EagerSingleton _instance = new EagerSingleton();

    private EagerSingleton()
    {
        Console.WriteLine("Eager singleton instance created");
    }

    public static EagerSingleton Instance => _instance;

    public void DoSomething()
    {
        Console.WriteLine("Doing something eagerly");
    }
}

// Benefits:
// ✅ Thread-safe
// ✅ Simple implementation
// ❌ Not lazy (created even if never used)
```

---

### Dependency Injection Alternative

```csharp
// ============================================
// SINGLETON WITH DI (MODERN APPROACH)
// ============================================

// Instead of classic Singleton pattern, use DI container

// Service
public interface IConfigurationService
{
    string GetSetting(string key);
}

public class ConfigurationService : IConfigurationService
{
    private readonly Dictionary<string, string> _settings = new();

    public ConfigurationService()
    {
        Console.WriteLine("Configuration service created");
        // Load settings
        _settings["AppName"] = "MyApp";
    }

    public string GetSetting(string key)
    {
        return _settings.TryGetValue(key, out var value) ? value : null;
    }
}

// Program.cs (ASP.NET Core)
builder.Services.AddSingleton<IConfigurationService, ConfigurationService>();

// Controller
public class HomeController : ControllerBase
{
    private readonly IConfigurationService _config;

    public HomeController(IConfigurationService config)
    {
        _config = config;  // Same instance injected everywhere
    }

    [HttpGet]
    public IActionResult Get()
    {
        var appName = _config.GetSetting("AppName");
        return Ok(appName);
    }
}

// Benefits of DI over Singleton:
// ✅ Testable (can inject mock)
// ✅ No global state
// ✅ Follows Dependency Inversion Principle
// ✅ Container manages lifecycle
```

---

### Real-World Examples

```csharp
// ============================================
// REAL-WORLD SINGLETON EXAMPLES
// ============================================

// Example 1: Logger
public class Logger
{
    private static readonly Lazy<Logger> _instance = new Lazy<Logger>(() => new Logger());
    private readonly StreamWriter _writer;

    private Logger()
    {
        _writer = new StreamWriter("app.log", append: true);
    }

    public static Logger Instance => _instance.Value;

    public void Log(string message)
    {
        lock (_writer)
        {
            _writer.WriteLine($"{DateTime.Now}: {message}");
            _writer.Flush();
        }
    }

    public void Dispose()
    {
        _writer?.Dispose();
    }
}

// Usage
Logger.Instance.Log("Application started");
Logger.Instance.Log("Error occurred");

// Example 2: Database Connection Pool
public class DatabaseConnectionPool
{
    private static readonly Lazy<DatabaseConnectionPool> _instance =
        new Lazy<DatabaseConnectionPool>(() => new DatabaseConnectionPool());

    private readonly Queue<SqlConnection> _connections = new();
    private readonly int _maxConnections = 10;
    private readonly object _lock = new object();

    private DatabaseConnectionPool()
    {
        // Initialize connection pool
        for (int i = 0; i < _maxConnections; i++)
        {
            _connections.Enqueue(new SqlConnection("connection_string"));
        }
    }

    public static DatabaseConnectionPool Instance => _instance.Value;

    public SqlConnection GetConnection()
    {
        lock (_lock)
        {
            if (_connections.Count > 0)
            {
                return _connections.Dequeue();
            }
            throw new InvalidOperationException("No available connections");
        }
    }

    public void ReturnConnection(SqlConnection connection)
    {
        lock (_lock)
        {
            _connections.Enqueue(connection);
        }
    }
}

// Example 3: Application Configuration
public class AppConfig
{
    private static readonly Lazy<AppConfig> _instance = new Lazy<AppConfig>(() => new AppConfig());

    private readonly Dictionary<string, string> _config = new();

    private AppConfig()
    {
        // Load configuration from file/environment
        _config["DatabaseConnection"] = Environment.GetEnvironmentVariable("DB_CONNECTION");
        _config["ApiKey"] = Environment.GetEnvironmentVariable("API_KEY");
    }

    public static AppConfig Instance => _instance.Value;

    public string this[string key] => _config.TryGetValue(key, out var value) ? value : null;
}

// Usage
var dbConnection = AppConfig.Instance["DatabaseConnection"];
```

---

### Anti-Pattern Warning

```csharp
// ============================================
// WHEN NOT TO USE SINGLETON
// ============================================

// ❌ DON'T use Singleton for:

// 1. Objects that should have multiple instances
public class User { }  // Each user should be separate instance

// 2. Objects that change state frequently
public class ShoppingCart { }  // Each user has their own cart

// 3. Objects that need to be tested with different configurations
// Use Dependency Injection instead

// 4. Objects with short lifecycle
public class HttpRequest { }  // Should be created per request

// ✅ DO use Singleton for:
// - Logger
// - Configuration
// - Cache
// - Connection pools
// - Thread pools
// - Factory objects
```

---

### Best Practices

```csharp
// 1. ✅ Use Lazy<T> for thread-safe lazy initialization
private static readonly Lazy<MySingleton> _instance = new Lazy<MySingleton>();

// 2. ✅ Make constructor private
private MySingleton() { }

// 3. ✅ Use readonly for instance field
private static readonly MySingleton _instance;

// 4. ✅ Consider IDisposable if holding resources
public class MySingleton : IDisposable
{
    public void Dispose() { /* cleanup */ }
}

// 5. ✅ Prefer Dependency Injection over Singleton
builder.Services.AddSingleton<IService, Service>();

// 6. ❌ Avoid mutable state in Singletons
// Can lead to thread-safety issues

// 7. ✅ Make thread-safe if accessed from multiple threads
private readonly object _lock = new object();

// 8. ✅ Document that class is a Singleton
/// <summary>
/// Singleton class for application configuration.
/// </summary>

// 9. ❌ Don't use for unit of work patterns
// Each operation should have its own instance

// 10. ✅ Consider using static class if no state needed
public static class MathHelper
{
    public static int Add(int a, int b) => a + b;
}
```

---

## Q243: Explain the Factory Pattern and Abstract Factory Pattern.

**Answer:**

**Factory Pattern** creates objects without specifying the exact class. **Abstract Factory Pattern** creates families of related objects.

### Simple Factory Pattern

```csharp
// ============================================
// SIMPLE FACTORY PATTERN
// ============================================

// Products
public interface IPaymentProcessor
{
    void ProcessPayment(decimal amount);
}

public class CreditCardProcessor : IPaymentProcessor
{
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} via Credit Card");
    }
}

public class PayPalProcessor : IPaymentProcessor
{
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} via PayPal");
    }
}

public class CryptoProcessor : IPaymentProcessor
{
    public void ProcessPayment(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} via Cryptocurrency");
    }
}

// Simple Factory
public class PaymentProcessorFactory
{
    public IPaymentProcessor CreateProcessor(string paymentType)
    {
        return paymentType.ToLower() switch
        {
            "creditcard" => new CreditCardProcessor(),
            "paypal" => new PayPalProcessor(),
            "crypto" => new CryptoProcessor(),
            _ => throw new ArgumentException($"Unknown payment type: {paymentType}")
        };
    }
}

// Usage
var factory = new PaymentProcessorFactory();
var processor = factory.CreateProcessor("creditcard");
processor.ProcessPayment(100.00m);

// Change payment method easily
processor = factory.CreateProcessor("paypal");
processor.ProcessPayment(50.00m);
```

---

### Factory Method Pattern

```csharp
// ============================================
// FACTORY METHOD PATTERN
// ============================================

// Product interface
public interface IDocument
{
    void Open();
    void Save();
}

// Concrete products
public class PdfDocument : IDocument
{
    public void Open() => Console.WriteLine("Opening PDF document");
    public void Save() => Console.WriteLine("Saving PDF document");
}

public class WordDocument : IDocument
{
    public void Open() => Console.WriteLine("Opening Word document");
    public void Save() => Console.WriteLine("Saving Word document");
}

public class ExcelDocument : IDocument
{
    public void Open() => Console.WriteLine("Opening Excel document");
    public void Save() => Console.WriteLine("Saving Excel document");
}

// Creator (abstract class with factory method)
public abstract class DocumentCreator
{
    // Factory method
    public abstract IDocument CreateDocument();

    // Template method using factory method
    public void OpenDocument()
    {
        var document = CreateDocument();
        document.Open();
    }
}

// Concrete creators
public class PdfDocumentCreator : DocumentCreator
{
    public override IDocument CreateDocument()
    {
        return new PdfDocument();
    }
}

public class WordDocumentCreator : DocumentCreator
{
    public override IDocument CreateDocument()
    {
        return new WordDocument();
    }
}

public class ExcelDocumentCreator : DocumentCreator
{
    public override IDocument CreateDocument()
    {
        return new ExcelDocument();
    }
}

// Usage
DocumentCreator creator = new PdfDocumentCreator();
IDocument doc = creator.CreateDocument();
doc.Open();
doc.Save();

creator = new WordDocumentCreator();
doc = creator.CreateDocument();
doc.Open();
```

---

### Abstract Factory Pattern

```csharp
// ============================================
// ABSTRACT FACTORY PATTERN
// ============================================

// Abstract products
public interface IButton
{
    void Render();
    void Click();
}

public interface ITextBox
{
    void Render();
    void Input(string text);
}

public interface ICheckbox
{
    void Render();
    void Check();
}

// Concrete products - Windows theme
public class WindowsButton : IButton
{
    public void Render() => Console.WriteLine("Rendering Windows-style button");
    public void Click() => Console.WriteLine("Windows button clicked");
}

public class WindowsTextBox : ITextBox
{
    public void Render() => Console.WriteLine("Rendering Windows-style textbox");
    public void Input(string text) => Console.WriteLine($"Windows textbox: {text}");
}

public class WindowsCheckbox : ICheckbox
{
    public void Render() => Console.WriteLine("Rendering Windows-style checkbox");
    public void Check() => Console.WriteLine("Windows checkbox checked");
}

// Concrete products - Mac theme
public class MacButton : IButton
{
    public void Render() => Console.WriteLine("Rendering Mac-style button");
    public void Click() => Console.WriteLine("Mac button clicked");
}

public class MacTextBox : ITextBox
{
    public void Render() => Console.WriteLine("Rendering Mac-style textbox");
    public void Input(string text) => Console.WriteLine($"Mac textbox: {text}");
}

public class MacCheckbox : ICheckbox
{
    public void Render() => Console.WriteLine("Rendering Mac-style checkbox");
    public void Check() => Console.WriteLine("Mac checkbox checked");
}

// Abstract Factory
public interface IUIFactory
{
    IButton CreateButton();
    ITextBox CreateTextBox();
    ICheckbox CreateCheckbox();
}

// Concrete Factories
public class WindowsUIFactory : IUIFactory
{
    public IButton CreateButton() => new WindowsButton();
    public ITextBox CreateTextBox() => new WindowsTextBox();
    public ICheckbox CreateCheckbox() => new WindowsCheckbox();
}

public class MacUIFactory : IUIFactory
{
    public IButton CreateButton() => new MacButton();
    public ITextBox CreateTextBox() => new MacTextBox();
    public ICheckbox CreateCheckbox() => new MacCheckbox();
}

// Client code
public class Application
{
    private readonly IButton _button;
    private readonly ITextBox _textBox;
    private readonly ICheckbox _checkbox;

    public Application(IUIFactory factory)
    {
        _button = factory.CreateButton();
        _textBox = factory.CreateTextBox();
        _checkbox = factory.CreateCheckbox();
    }

    public void Render()
    {
        _button.Render();
        _textBox.Render();
        _checkbox.Render();
    }

    public void Interact()
    {
        _button.Click();
        _textBox.Input("Hello World");
        _checkbox.Check();
    }
}

// Usage
IUIFactory factory;

// Detect OS
if (Environment.OSVersion.Platform == PlatformID.Win32NT)
{
    factory = new WindowsUIFactory();
}
else
{
    factory = new MacUIFactory();
}

var app = new Application(factory);
app.Render();
app.Interact();

// All UI elements are consistent (all Windows or all Mac)
```

---

### Real-World Example: Database Factory

```csharp
// ============================================
// DATABASE CONNECTION FACTORY
// ============================================

// Abstract products
public interface IDbConnection
{
    void Open();
    void Close();
    void ExecuteQuery(string query);
}

public interface IDbCommand
{
    void Execute(string sql);
    void AddParameter(string name, object value);
}

// SQL Server products
public class SqlConnection : IDbConnection
{
    public void Open() => Console.WriteLine("Opening SQL Server connection");
    public void Close() => Console.WriteLine("Closing SQL Server connection");
    public void ExecuteQuery(string query) => Console.WriteLine($"SQL Server: {query}");
}

public class SqlCommand : IDbCommand
{
    public void Execute(string sql) => Console.WriteLine($"Executing SQL: {sql}");
    public void AddParameter(string name, object value) => Console.WriteLine($"SQL Param: {name}={value}");
}

// PostgreSQL products
public class PostgresConnection : IDbConnection
{
    public void Open() => Console.WriteLine("Opening PostgreSQL connection");
    public void Close() => Console.WriteLine("Closing PostgreSQL connection");
    public void ExecuteQuery(string query) => Console.WriteLine($"PostgreSQL: {query}");
}

public class PostgresCommand : IDbCommand
{
    public void Execute(string sql) => Console.WriteLine($"Executing Postgres: {sql}");
    public void AddParameter(string name, object value) => Console.WriteLine($"Postgres Param: {name}={value}");
}

// Abstract Factory
public interface IDatabaseFactory
{
    IDbConnection CreateConnection();
    IDbCommand CreateCommand();
}

// Concrete Factories
public class SqlServerFactory : IDatabaseFactory
{
    public IDbConnection CreateConnection() => new SqlConnection();
    public IDbCommand CreateCommand() => new SqlCommand();
}

public class PostgreSqlFactory : IDatabaseFactory
{
    public IDbConnection CreateConnection() => new PostgresConnection();
    public IDbCommand CreateCommand() => new PostgresCommand();
}

// Data Access Layer
public class DataRepository
{
    private readonly IDatabaseFactory _dbFactory;

    public DataRepository(IDatabaseFactory dbFactory)
    {
        _dbFactory = dbFactory;
    }

    public void GetUsers()
    {
        using var connection = _dbFactory.CreateConnection();
        connection.Open();

        var command = _dbFactory.CreateCommand();
        command.AddParameter("@status", "active");
        command.Execute("SELECT * FROM Users WHERE Status = @status");

        connection.Close();
    }
}

// Configuration
var databaseType = Configuration["DatabaseType"]; // "SqlServer" or "PostgreSql"

IDatabaseFactory factory = databaseType switch
{
    "SqlServer" => new SqlServerFactory(),
    "PostgreSql" => new PostgreSqlFactory(),
    _ => throw new ArgumentException("Unknown database type")
};

var repository = new DataRepository(factory);
repository.GetUsers();

// Easy to switch databases by changing configuration
```

---

### Best Practices

```csharp
// 1. ✅ Use Factory when object creation is complex
// Hide complexity behind factory

// 2. ✅ Return interfaces, not concrete types
public IPaymentProcessor CreateProcessor() { }  // ✅ Good
public CreditCardProcessor CreateProcessor() { } // ❌ Bad

// 3. ✅ Use Abstract Factory for families of related objects
// UI components (Button, TextBox, Checkbox)
// Database components (Connection, Command, Transaction)

// 4. ✅ Combine with Dependency Injection
builder.Services.AddSingleton<IPaymentProcessorFactory, PaymentProcessorFactory>();

// 5. ✅ Use for cross-platform code
IUIFactory factory = OS == "Windows" ? new WindowsFactory() : new MacFactory();

// 6. ❌ Don't overuse for simple object creation
// If creating object is simple, don't need factory

// 7. ✅ Consider using generic factory
public class GenericFactory<T> where T : new()
{
    public T Create() => new T();
}

// 8. ✅ Use with Strategy pattern
var processor = factory.CreateProcessor(paymentType);
processor.ProcessPayment(amount);

// 9. ✅ Make factory methods fluent
factory.CreateProcessor()
       .WithAmount(100)
       .Process();

// 10. ✅ Document factory purpose clearly
/// <summary>
/// Creates payment processors based on payment type.
/// Supports: CreditCard, PayPal, Crypto
/// </summary>
```

---

## Q244: Explain the Builder Pattern and Fluent Interface.

**Answer:**

**Builder Pattern** constructs complex objects step by step, separating construction from representation.

### Basic Builder Pattern

```csharp
// ============================================
// BUILDER PATTERN
// ============================================

// Product
public class Pizza
{
    public string Size { get; set; }
    public string Crust { get; set; }
    public List<string> Toppings { get; set; } = new();
    public bool HasCheese { get; set; }
    public string Sauce { get; set; }

    public override string ToString()
    {
        return $"{Size} pizza with {Crust} crust, {Sauce} sauce, " +
               $"cheese: {HasCheese}, toppings: {string.Join(", ", Toppings)}";
    }
}

// Builder
public class PizzaBuilder
{
    private readonly Pizza _pizza = new();

    public PizzaBuilder SetSize(string size)
    {
        _pizza.Size = size;
        return this;  // Return this for method chaining
    }

    public PizzaBuilder SetCrust(string crust)
    {
        _pizza.Crust = crust;
        return this;
    }

    public PizzaBuilder SetSauce(string sauce)
    {
        _pizza.Sauce = sauce;
        return this;
    }

    public PizzaBuilder AddTopping(string topping)
    {
        _pizza.Toppings.Add(topping);
        return this;
    }

    public PizzaBuilder AddCheese()
    {
        _pizza.HasCheese = true;
        return this;
    }

    public Pizza Build()
    {
        // Validation before building
        if (string.IsNullOrEmpty(_pizza.Size))
            throw new InvalidOperationException("Size is required");

        if (string.IsNullOrEmpty(_pizza.Crust))
            _pizza.Crust = "Regular";  // Default value

        return _pizza;
    }
}

// Usage - Fluent interface
var pizza = new PizzaBuilder()
    .SetSize("Large")
    .SetCrust("Thin")
    .SetSauce("Tomato")
    .AddCheese()
    .AddTopping("Pepperoni")
    .AddTopping("Mushrooms")
    .AddTopping("Olives")
    .Build();

Console.WriteLine(pizza);
// Output: Large pizza with Thin crust, Tomato sauce, cheese: True,
//         toppings: Pepperoni, Mushrooms, Olives
```

---

### Builder with Director

```csharp
// ============================================
// BUILDER WITH DIRECTOR
// ============================================

// Product
public class Computer
{
    public string CPU { get; set; }
    public string RAM { get; set; }
    public string Storage { get; set; }
    public string GPU { get; set; }
    public string Motherboard { get; set; }
    public string PowerSupply { get; set; }

    public override string ToString()
    {
        return $"Computer: CPU={CPU}, RAM={RAM}, Storage={Storage}, " +
               $"GPU={GPU}, Motherboard={Motherboard}, PSU={PowerSupply}";
    }
}

// Abstract Builder
public interface IComputerBuilder
{
    IComputerBuilder SetCPU(string cpu);
    IComputerBuilder SetRAM(string ram);
    IComputerBuilder SetStorage(string storage);
    IComputerBuilder SetGPU(string gpu);
    IComputerBuilder SetMotherboard(string motherboard);
    IComputerBuilder SetPowerSupply(string psu);
    Computer Build();
}

// Concrete Builder
public class GamingComputerBuilder : IComputerBuilder
{
    private readonly Computer _computer = new();

    public IComputerBuilder SetCPU(string cpu)
    {
        _computer.CPU = cpu;
        return this;
    }

    public IComputerBuilder SetRAM(string ram)
    {
        _computer.RAM = ram;
        return this;
    }

    public IComputerBuilder SetStorage(string storage)
    {
        _computer.Storage = storage;
        return this;
    }

    public IComputerBuilder SetGPU(string gpu)
    {
        _computer.GPU = gpu;
        return this;
    }

    public IComputerBuilder SetMotherboard(string motherboard)
    {
        _computer.Motherboard = motherboard;
        return this;
    }

    public IComputerBuilder SetPowerSupply(string psu)
    {
        _computer.PowerSupply = psu;
        return this;
    }

    public Computer Build() => _computer;
}

// Director (knows how to build specific configurations)
public class ComputerDirector
{
    public Computer BuildGamingComputer(IComputerBuilder builder)
    {
        return builder
            .SetCPU("Intel i9-13900K")
            .SetRAM("32GB DDR5")
            .SetStorage("2TB NVMe SSD")
            .SetGPU("NVIDIA RTX 4090")
            .SetMotherboard("ASUS ROG Maximus")
            .SetPowerSupply("1000W 80+ Platinum")
            .Build();
    }

    public Computer BuildOfficeComputer(IComputerBuilder builder)
    {
        return builder
            .SetCPU("Intel i5-13600")
            .SetRAM("16GB DDR4")
            .SetStorage("512GB SSD")
            .SetGPU("Integrated Graphics")
            .SetMotherboard("Standard ATX")
            .SetPowerSupply("450W 80+ Bronze")
            .Build();
    }

    public Computer BuildWorkstationComputer(IComputerBuilder builder)
    {
        return builder
            .SetCPU("AMD Threadripper 3990X")
            .SetRAM("128GB DDR4 ECC")
            .SetStorage("4TB NVMe SSD")
            .SetGPU("NVIDIA Quadro RTX 8000")
            .SetMotherboard("Workstation Motherboard")
            .SetPowerSupply("1600W 80+ Titanium")
            .Build();
    }
}

// Usage
var director = new ComputerDirector();
var builder = new GamingComputerBuilder();

// Let director build specific configurations
var gamingPC = director.BuildGamingComputer(builder);
Console.WriteLine(gamingPC);

var officePC = director.BuildOfficeComputer(new GamingComputerBuilder());
Console.WriteLine(officePC);

// Or build custom configuration
var customPC = new GamingComputerBuilder()
    .SetCPU("AMD Ryzen 9 7950X")
    .SetRAM("64GB DDR5")
    .SetStorage("4TB SSD")
    .Build();
```

---

### Fluent Interface with Validation

```csharp
// ============================================
// FLUENT INTERFACE WITH VALIDATION
// ============================================

public class EmailBuilder
{
    private string _from;
    private List<string> _to = new();
    private List<string> _cc = new();
    private List<string> _bcc = new();
    private string _subject;
    private string _body;
    private List<string> _attachments = new();
    private bool _isHtml;

    public EmailBuilder From(string email)
    {
        if (!IsValidEmail(email))
            throw new ArgumentException("Invalid from email address");

        _from = email;
        return this;
    }

    public EmailBuilder To(string email)
    {
        if (!IsValidEmail(email))
            throw new ArgumentException("Invalid to email address");

        _to.Add(email);
        return this;
    }

    public EmailBuilder To(params string[] emails)
    {
        foreach (var email in emails)
        {
            To(email);
        }
        return this;
    }

    public EmailBuilder CC(string email)
    {
        if (!IsValidEmail(email))
            throw new ArgumentException("Invalid CC email address");

        _cc.Add(email);
        return this;
    }

    public EmailBuilder BCC(string email)
    {
        if (!IsValidEmail(email))
            throw new ArgumentException("Invalid BCC email address");

        _bcc.Add(email);
        return this;
    }

    public EmailBuilder Subject(string subject)
    {
        if (string.IsNullOrWhiteSpace(subject))
            throw new ArgumentException("Subject cannot be empty");

        _subject = subject;
        return this;
    }

    public EmailBuilder Body(string body)
    {
        _body = body;
        return this;
    }

    public EmailBuilder AsHtml()
    {
        _isHtml = true;
        return this;
    }

    public EmailBuilder WithAttachment(string filePath)
    {
        if (!File.Exists(filePath))
            throw new FileNotFoundException("Attachment file not found", filePath);

        _attachments.Add(filePath);
        return this;
    }

    public Email Build()
    {
        // Final validation
        if (string.IsNullOrEmpty(_from))
            throw new InvalidOperationException("From address is required");

        if (!_to.Any())
            throw new InvalidOperationException("At least one recipient is required");

        if (string.IsNullOrEmpty(_subject))
            throw new InvalidOperationException("Subject is required");

        return new Email
        {
            From = _from,
            To = _to,
            CC = _cc,
            BCC = _bcc,
            Subject = _subject,
            Body = _body ?? string.Empty,
            IsHtml = _isHtml,
            Attachments = _attachments
        };
    }

    private bool IsValidEmail(string email)
    {
        return !string.IsNullOrWhiteSpace(email) && email.Contains("@");
    }
}

public class Email
{
    public string From { get; set; }
    public List<string> To { get; set; }
    public List<string> CC { get; set; }
    public List<string> BCC { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
    public bool IsHtml { get; set; }
    public List<string> Attachments { get; set; }

    public void Send()
    {
        Console.WriteLine($"Sending email: {Subject}");
        Console.WriteLine($"From: {From}");
        Console.WriteLine($"To: {string.Join(", ", To)}");
        if (CC.Any()) Console.WriteLine($"CC: {string.Join(", ", CC)}");
        if (BCC.Any()) Console.WriteLine($"BCC: {string.Join(", ", BCC)}");
        Console.WriteLine($"HTML: {IsHtml}");
        Console.WriteLine($"Attachments: {Attachments.Count}");
    }
}

// Usage
var email = new EmailBuilder()
    .From("sender@example.com")
    .To("recipient1@example.com", "recipient2@example.com")
    .CC("manager@example.com")
    .Subject("Monthly Report")
    .Body("<h1>Report</h1><p>Here is the monthly report.</p>")
    .AsHtml()
    .WithAttachment("report.pdf")
    .Build();

email.Send();
```

---

### Real-World Example: Query Builder

```csharp
// ============================================
// SQL QUERY BUILDER
// ============================================

public class QueryBuilder
{
    private string _table;
    private List<string> _columns = new();
    private List<string> _whereConditions = new();
    private List<string> _orderBy = new();
    private int? _limit;
    private int? _offset;

    public QueryBuilder Select(params string[] columns)
    {
        _columns.AddRange(columns);
        return this;
    }

    public QueryBuilder From(string table)
    {
        _table = table;
        return this;
    }

    public QueryBuilder Where(string condition)
    {
        _whereConditions.Add(condition);
        return this;
    }

    public QueryBuilder OrderBy(string column, bool descending = false)
    {
        _orderBy.Add($"{column} {(descending ? "DESC" : "ASC")}");
        return this;
    }

    public QueryBuilder Limit(int limit)
    {
        _limit = limit;
        return this;
    }

    public QueryBuilder Offset(int offset)
    {
        _offset = offset;
        return this;
    }

    public string Build()
    {
        if (string.IsNullOrEmpty(_table))
            throw new InvalidOperationException("Table name is required");

        var query = new StringBuilder();

        // SELECT clause
        query.Append("SELECT ");
        query.Append(_columns.Any() ? string.Join(", ", _columns) : "*");

        // FROM clause
        query.Append($" FROM {_table}");

        // WHERE clause
        if (_whereConditions.Any())
        {
            query.Append(" WHERE ");
            query.Append(string.Join(" AND ", _whereConditions));
        }

        // ORDER BY clause
        if (_orderBy.Any())
        {
            query.Append(" ORDER BY ");
            query.Append(string.Join(", ", _orderBy));
        }

        // LIMIT clause
        if (_limit.HasValue)
        {
            query.Append($" LIMIT {_limit.Value}");
        }

        // OFFSET clause
        if (_offset.HasValue)
        {
            query.Append($" OFFSET {_offset.Value}");
        }

        return query.ToString();
    }

    public override string ToString() => Build();
}

// Usage
var query = new QueryBuilder()
    .Select("Id", "Name", "Email", "CreatedDate")
    .From("Users")
    .Where("Active = 1")
    .Where("Role = 'Admin'")
    .OrderBy("CreatedDate", descending: true)
    .Limit(10)
    .Offset(20)
    .Build();

Console.WriteLine(query);
// Output: SELECT Id, Name, Email, CreatedDate FROM Users
//         WHERE Active = 1 AND Role = 'Admin'
//         ORDER BY CreatedDate DESC LIMIT 10 OFFSET 20
```

---

### Best Practices

```csharp
// 1. ✅ Use Builder for complex objects with many parameters
var user = new UserBuilder()
    .SetName("John")
    .SetEmail("john@example.com")
    .SetAge(30)
    .Build();

// 2. ✅ Return 'this' for method chaining
public UserBuilder SetName(string name)
{
    _name = name;
    return this;  // Enable chaining
}

// 3. ✅ Validate in Build() method
public User Build()
{
    if (string.IsNullOrEmpty(_name))
        throw new InvalidOperationException("Name is required");
    return new User { Name = _name };
}

// 4. ✅ Provide default values
public UserBuilder()
{
    _role = "User";  // Default role
}

// 5. ✅ Make Builder immutable (optional)
public ImmutableUserBuilder WithName(string name)
{
    return new ImmutableUserBuilder { _name = name };
}

// 6. ✅ Use Director for common configurations
var director = new ComputerDirector();
var gamingPC = director.BuildGamingComputer(builder);

// 7. ✅ Separate complex construction from representation
// Builder handles construction
// Product (User, Computer) handles representation

// 8. ❌ Don't use for simple objects
// If object has 2-3 properties, constructor is fine
public class Point
{
    public Point(int x, int y) { X = x; Y = y; }  // Simple enough
}

// 9. ✅ Consider using with Factory pattern
var builder = factory.CreateBuilder("Gaming");

// 10. ✅ Provide clear method names
.SetSize()   // ✅ Clear
.Size()      // ❌ Ambiguous
.WithSize()  // ✅ Clear
```

---

## Q245: Explain the Strategy Pattern.

**Answer:**

**Strategy Pattern** defines a family of algorithms, encapsulates each one, and makes them interchangeable at runtime.

### Basic Strategy Pattern

```csharp
// ============================================
// STRATEGY PATTERN
// ============================================

// Strategy interface
public interface IPaymentStrategy
{
    void Pay(decimal amount);
    bool ValidatePaymentDetails();
}

// Concrete strategies
public class CreditCardPaymentStrategy : IPaymentStrategy
{
    private readonly string _cardNumber;
    private readonly string _cvv;
    private readonly string _expiryDate;

    public CreditCardPaymentStrategy(string cardNumber, string cvv, string expiryDate)
    {
        _cardNumber = cardNumber;
        _cvv = cvv;
        _expiryDate = expiryDate;
    }

    public bool ValidatePaymentDetails()
    {
        Console.WriteLine("Validating credit card details...");
        return !string.IsNullOrEmpty(_cardNumber) &&
               !string.IsNullOrEmpty(_cvv) &&
               !string.IsNullOrEmpty(_expiryDate);
    }

    public void Pay(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} payment via Credit Card ending in {_cardNumber[^4..]}");
    }
}

public class PayPalPaymentStrategy : IPaymentStrategy
{
    private readonly string _email;
    private readonly string _password;

    public PayPalPaymentStrategy(string email, string password)
    {
        _email = email;
        _password = password;
    }

    public bool ValidatePaymentDetails()
    {
        Console.WriteLine("Validating PayPal credentials...");
        return !string.IsNullOrEmpty(_email) && !string.IsNullOrEmpty(_password);
    }

    public void Pay(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} payment via PayPal account: {_email}");
    }
}

public class CryptocurrencyPaymentStrategy : IPaymentStrategy
{
    private readonly string _walletAddress;
    private readonly string _cryptoType;

    public CryptocurrencyPaymentStrategy(string walletAddress, string cryptoType)
    {
        _walletAddress = walletAddress;
        _cryptoType = cryptoType;
    }

    public bool ValidatePaymentDetails()
    {
        Console.WriteLine("Validating crypto wallet address...");
        return !string.IsNullOrEmpty(_walletAddress);
    }

    public void Pay(decimal amount)
    {
        Console.WriteLine($"Processing ${amount} payment via {_cryptoType} to wallet: {_walletAddress}");
    }
}

// Context
public class ShoppingCart
{
    private IPaymentStrategy _paymentStrategy;
    private readonly List<(string Item, decimal Price)> _items = new();

    public void AddItem(string item, decimal price)
    {
        _items.Add((item, price));
        Console.WriteLine($"Added {item} - ${price}");
    }

    public void SetPaymentStrategy(IPaymentStrategy strategy)
    {
        _paymentStrategy = strategy;
    }

    public void Checkout()
    {
        if (_paymentStrategy == null)
        {
            throw new InvalidOperationException("Payment strategy not set");
        }

        var total = _items.Sum(x => x.Price);
        Console.WriteLine($"\nTotal: ${total}");

        if (_paymentStrategy.ValidatePaymentDetails())
        {
            _paymentStrategy.Pay(total);
            Console.WriteLine("Payment successful!\n");
        }
        else
        {
            Console.WriteLine("Payment validation failed!\n");
        }
    }
}

// Usage
var cart = new ShoppingCart();
cart.AddItem("Laptop", 1200.00m);
cart.AddItem("Mouse", 25.00m);
cart.AddItem("Keyboard", 75.00m);

// Pay with credit card
cart.SetPaymentStrategy(new CreditCardPaymentStrategy("1234-5678-9012-3456", "123", "12/25"));
cart.Checkout();

// Pay with PayPal
cart.SetPaymentStrategy(new PayPalPaymentStrategy("user@example.com", "password123"));
cart.Checkout();

// Pay with Crypto
cart.SetPaymentStrategy(new CryptocurrencyPaymentStrategy("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb", "Bitcoin"));
cart.Checkout();
```

---

### Real-World Example: Compression Strategy

```csharp
// ============================================
// COMPRESSION STRATEGY
// ============================================

public interface ICompressionStrategy
{
    byte[] Compress(byte[] data);
    byte[] Decompress(byte[] data);
    string GetCompressionType();
}

public class GzipCompressionStrategy : ICompressionStrategy
{
    public byte[] Compress(byte[] data)
    {
        using var output = new MemoryStream();
        using (var gzip = new GZipStream(output, CompressionMode.Compress))
        {
            gzip.Write(data, 0, data.Length);
        }
        return output.ToArray();
    }

    public byte[] Decompress(byte[] data)
    {
        using var input = new MemoryStream(data);
        using var output = new MemoryStream();
        using (var gzip = new GZipStream(input, CompressionMode.Decompress))
        {
            gzip.CopyTo(output);
        }
        return output.ToArray();
    }

    public string GetCompressionType() => "GZIP";
}

public class ZipCompressionStrategy : ICompressionStrategy
{
    public byte[] Compress(byte[] data)
    {
        using var output = new MemoryStream();
        using (var zip = new DeflateStream(output, CompressionMode.Compress))
        {
            zip.Write(data, 0, data.Length);
        }
        return output.ToArray();
    }

    public byte[] Decompress(byte[] data)
    {
        using var input = new MemoryStream(data);
        using var output = new MemoryStream();
        using (var zip = new DeflateStream(input, CompressionMode.Decompress))
        {
            zip.CopyTo(output);
        }
        return output.ToArray();
    }

    public string GetCompressionType() => "ZIP";
}

public class FileCompressor
{
    private ICompressionStrategy _strategy;

    public FileCompressor(ICompressionStrategy strategy)
    {
        _strategy = strategy;
    }

    public void SetStrategy(ICompressionStrategy strategy)
    {
        _strategy = strategy;
    }

    public void CompressFile(string inputPath, string outputPath)
    {
        var data = File.ReadAllBytes(inputPath);
        var compressed = _strategy.Compress(data);
        File.WriteAllBytes(outputPath, compressed);

        Console.WriteLine($"Compressed using {_strategy.GetCompressionType()}");
        Console.WriteLine($"Original size: {data.Length} bytes");
        Console.WriteLine($"Compressed size: {compressed.Length} bytes");
        Console.WriteLine($"Compression ratio: {(1 - (double)compressed.Length / data.Length) * 100:F2}%");
    }

    public void DecompressFile(string inputPath, string outputPath)
    {
        var compressed = File.ReadAllBytes(inputPath);
        var decompressed = _strategy.Decompress(compressed);
        File.WriteAllBytes(outputPath, decompressed);

        Console.WriteLine($"Decompressed using {_strategy.GetCompressionType()}");
    }
}

// Usage
var compressor = new FileCompressor(new GzipCompressionStrategy());
compressor.CompressFile("large-file.txt", "large-file.gz");

// Switch strategy
compressor.SetStrategy(new ZipCompressionStrategy());
compressor.CompressFile("large-file.txt", "large-file.zip");
```

---

### Strategy with Dependency Injection

```csharp
// ============================================
// STRATEGY WITH DI (ASP.NET CORE)
// ============================================

public interface IShippingStrategy
{
    decimal CalculateShippingCost(decimal weight, string destination);
    string GetShippingMethod();
}

public class StandardShippingStrategy : IShippingStrategy
{
    public decimal CalculateShippingCost(decimal weight, string destination)
    {
        return weight * 5.00m;  // $5 per kg
    }

    public string GetShippingMethod() => "Standard Shipping (5-7 days)";
}

public class ExpressShippingStrategy : IShippingStrategy
{
    public decimal CalculateShippingCost(decimal weight, string destination)
    {
        return weight * 15.00m;  // $15 per kg
    }

    public string GetShippingMethod() => "Express Shipping (1-2 days)";
}

public class InternationalShippingStrategy : IShippingStrategy
{
    public decimal CalculateShippingCost(decimal weight, string destination)
    {
        var baseCost = weight * 20.00m;

        // Add country-specific surcharge
        var surcharge = destination switch
        {
            "USA" => 10.00m,
            "Europe" => 15.00m,
            "Asia" => 20.00m,
            _ => 25.00m
        };

        return baseCost + surcharge;
    }

    public string GetShippingMethod() => "International Shipping (10-14 days)";
}

// Factory to select strategy
public class ShippingStrategyFactory
{
    public IShippingStrategy GetStrategy(string shippingType)
    {
        return shippingType.ToLower() switch
        {
            "standard" => new StandardShippingStrategy(),
            "express" => new ExpressShippingStrategy(),
            "international" => new InternationalShippingStrategy(),
            _ => throw new ArgumentException($"Unknown shipping type: {shippingType}")
        };
    }
}

// Service
public class OrderService
{
    private readonly ShippingStrategyFactory _shippingFactory;

    public OrderService(ShippingStrategyFactory shippingFactory)
    {
        _shippingFactory = shippingFactory;
    }

    public decimal CalculateOrderTotal(decimal productCost, decimal weight, string shippingType, string destination)
    {
        var strategy = _shippingFactory.GetStrategy(shippingType);
        var shippingCost = strategy.CalculateShippingCost(weight, destination);

        Console.WriteLine($"Shipping Method: {strategy.GetShippingMethod()}");
        Console.WriteLine($"Product Cost: ${productCost:F2}");
        Console.WriteLine($"Shipping Cost: ${shippingCost:F2}");
        Console.WriteLine($"Total: ${productCost + shippingCost:F2}");

        return productCost + shippingCost;
    }
}

// Usage in controller
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly OrderService _orderService;

    public OrdersController(OrderService orderService)
    {
        _orderService = orderService;
    }

    [HttpPost("calculate")]
    public IActionResult Calculate([FromBody] OrderRequest request)
    {
        var total = _orderService.CalculateOrderTotal(
            request.ProductCost,
            request.Weight,
            request.ShippingType,
            request.Destination);

        return Ok(new { Total = total });
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use Strategy for algorithms that can vary independently
public interface ISortingStrategy
{
    void Sort(int[] array);
}

// 2. ✅ Combine with Factory pattern
var strategy = factory.CreateStrategy(type);

// 3. ✅ Use with Dependency Injection
builder.Services.AddScoped<IPaymentStrategy, CreditCardPaymentStrategy>();

// 4. ✅ Make strategies stateless when possible
// Strategies should be reusable

// 5. ✅ Use for Open/Closed Principle
// Add new strategies without modifying existing code

// 6. ❌ Don't use if you have only one algorithm
// Strategy is for interchangeable algorithms

// 7. ✅ Document each strategy clearly
/// <summary>
/// Implements GZIP compression with high compression ratio
/// but slower performance
/// </summary>

// 8. ✅ Validate strategy before use
if (_strategy == null)
    throw new InvalidOperationException("Strategy not set");

// 9. ✅ Consider default strategy
public Context(IStrategy strategy = null)
{
    _strategy = strategy ?? new DefaultStrategy();
}

// 10. ✅ Use for runtime algorithm selection
var strategy = userChoice == "fast" ? new QuickSort() : new MergeSort();
```

---

## Q246: Explain the Observer Pattern.

**Answer:**

**Observer Pattern** defines one-to-many dependency where when one object changes state, all dependents are notified automatically.

### Basic Observer Pattern

```csharp
// ============================================
// OBSERVER PATTERN
// ============================================

// Subject interface
public interface ISubject
{
    void Attach(IObserver observer);
    void Detach(IObserver observer);
    void Notify();
}

// Observer interface
public interface IObserver
{
    void Update(ISubject subject);
}

// Concrete Subject
public class StockPrice : ISubject
{
    private readonly List<IObserver> _observers = new();
    private string _symbol;
    private decimal _price;

    public string Symbol
    {
        get => _symbol;
        set
        {
            _symbol = value;
            Notify();
        }
    }

    public decimal Price
    {
        get => _price;
        set
        {
            _price = value;
            Notify();
        }
    }

    public void Attach(IObserver observer)
    {
        if (!_observers.Contains(observer))
        {
            _observers.Add(observer);
            Console.WriteLine($"Observer attached. Total observers: {_observers.Count}");
        }
    }

    public void Detach(IObserver observer)
    {
        if (_observers.Remove(observer))
        {
            Console.WriteLine($"Observer detached. Total observers: {_observers.Count}");
        }
    }

    public void Notify()
    {
        Console.WriteLine($"\nNotifying {_observers.Count} observers about {Symbol} price change to ${Price}");
        foreach (var observer in _observers)
        {
            observer.Update(this);
        }
    }
}

// Concrete Observers
public class StockDisplay : IObserver
{
    private readonly string _name;

    public StockDisplay(string name)
    {
        _name = name;
    }

    public void Update(ISubject subject)
    {
        if (subject is StockPrice stock)
        {
            Console.WriteLine($"[{_name}] Stock {stock.Symbol} is now ${stock.Price}");
        }
    }
}

public class StockAlert : IObserver
{
    private readonly string _name;
    private readonly decimal _threshold;

    public StockAlert(string name, decimal threshold)
    {
        _name = name;
        _threshold = threshold;
    }

    public void Update(ISubject subject)
    {
        if (subject is StockPrice stock)
        {
            if (stock.Price > _threshold)
            {
                Console.WriteLine($"[{_name}] ALERT! {stock.Symbol} exceeded threshold: ${stock.Price} > ${_threshold}");
            }
        }
    }
}

// Usage
var appleStock = new StockPrice { Symbol = "AAPL", Price = 150.00m };

var display1 = new StockDisplay("Display 1");
var display2 = new StockDisplay("Display 2");
var alert = new StockAlert("High Price Alert", 175.00m);

appleStock.Attach(display1);
appleStock.Attach(display2);
appleStock.Attach(alert);

// Update price - all observers notified
appleStock.Price = 160.00m;
appleStock.Price = 180.00m;  // Triggers alert

// Detach observer
appleStock.Detach(display2);
appleStock.Price = 185.00m;  // Only display1 and alert notified
```

---

### Event-Based Observer (C# Events)

```csharp
// ============================================
// C# EVENTS (BUILT-IN OBSERVER)
// ============================================

// Event arguments
public class StockPriceChangedEventArgs : EventArgs
{
    public string Symbol { get; set; }
    public decimal OldPrice { get; set; }
    public decimal NewPrice { get; set; }
    public decimal Change => NewPrice - OldPrice;
    public decimal ChangePercent => (Change / OldPrice) * 100;
}

// Subject with events
public class Stock
{
    private string _symbol;
    private decimal _price;

    public string Symbol
    {
        get => _symbol;
        set => _symbol = value;
    }

    public decimal Price
    {
        get => _price;
        set
        {
            if (_price != value)
            {
                var oldPrice = _price;
                _price = value;
                OnPriceChanged(new StockPriceChangedEventArgs
                {
                    Symbol = _symbol,
                    OldPrice = oldPrice,
                    NewPrice = value
                });
            }
        }
    }

    // Event declaration
    public event EventHandler<StockPriceChangedEventArgs> PriceChanged;

    protected virtual void OnPriceChanged(StockPriceChangedEventArgs e)
    {
        PriceChanged?.Invoke(this, e);
    }
}

// Observers (event handlers)
public class StockMonitor
{
    public void OnStockPriceChanged(object sender, StockPriceChangedEventArgs e)
    {
        Console.WriteLine($"[Monitor] {e.Symbol}: ${e.OldPrice} → ${e.NewPrice} " +
                         $"({e.Change:+0.00;-0.00} / {e.ChangePercent:+0.00;-0.00}%)");
    }
}

public class StockLogger
{
    public void OnStockPriceChanged(object sender, StockPriceChangedEventArgs e)
    {
        Console.WriteLine($"[Logger] {DateTime.Now}: {e.Symbol} price changed to ${e.NewPrice}");
    }
}

// Usage
var stock = new Stock { Symbol = "GOOGL", Price = 100.00m };

var monitor = new StockMonitor();
var logger = new StockLogger();

// Subscribe to events
stock.PriceChanged += monitor.OnStockPriceChanged;
stock.PriceChanged += logger.OnStockPriceChanged;

// Lambda subscriber
stock.PriceChanged += (sender, e) =>
{
    if (e.ChangePercent > 5)
    {
        Console.WriteLine($"[Alert] Large price movement: {e.ChangePercent:F2}%");
    }
};

// Update price - all subscribers notified
stock.Price = 105.50m;
stock.Price = 112.00m;

// Unsubscribe
stock.PriceChanged -= monitor.OnStockPriceChanged;
stock.Price = 115.00m;  // Only logger and lambda notified
```

---

### IObservable<T> and IObserver<T> (Reactive Extensions)

```csharp
// ============================================
// REACTIVE EXTENSIONS (Rx.NET)
// ============================================

// Install: System.Reactive

public class TemperatureSensor : IObservable<int>
{
    private readonly List<IObserver<int>> _observers = new();

    public IDisposable Subscribe(IObserver<int> observer)
    {
        if (!_observers.Contains(observer))
        {
            _observers.Add(observer);
        }

        return new Unsubscriber(_observers, observer);
    }

    public void SendTemperature(int temperature)
    {
        foreach (var observer in _observers)
        {
            observer.OnNext(temperature);
        }
    }

    public void EndTransmission()
    {
        foreach (var observer in _observers)
        {
            observer.OnCompleted();
        }
        _observers.Clear();
    }

    private class Unsubscriber : IDisposable
    {
        private readonly List<IObserver<int>> _observers;
        private readonly IObserver<int> _observer;

        public Unsubscriber(List<IObserver<int>> observers, IObserver<int> observer)
        {
            _observers = observers;
            _observer = observer;
        }

        public void Dispose()
        {
            if (_observer != null && _observers.Contains(_observer))
            {
                _observers.Remove(_observer);
            }
        }
    }
}

public class TemperatureDisplay : IObserver<int>
{
    private IDisposable _unsubscriber;

    public void Subscribe(IObservable<int> provider)
    {
        _unsubscriber = provider.Subscribe(this);
    }

    public void OnCompleted()
    {
        Console.WriteLine("[Display] Temperature monitoring completed");
    }

    public void OnError(Exception error)
    {
        Console.WriteLine($"[Display] Error: {error.Message}");
    }

    public void OnNext(int value)
    {
        Console.WriteLine($"[Display] Current temperature: {value}°C");
    }

    public void Unsubscribe()
    {
        _unsubscriber?.Dispose();
    }
}

public class TemperatureAlert : IObserver<int>
{
    private readonly int _threshold;
    private IDisposable _unsubscriber;

    public TemperatureAlert(int threshold)
    {
        _threshold = threshold;
    }

    public void Subscribe(IObservable<int> provider)
    {
        _unsubscriber = provider.Subscribe(this);
    }

    public void OnCompleted()
    {
        Console.WriteLine("[Alert] Monitoring completed");
    }

    public void OnError(Exception error)
    {
        Console.WriteLine($"[Alert] Error: {error.Message}");
    }

    public void OnNext(int value)
    {
        if (value > _threshold)
        {
            Console.WriteLine($"[Alert] ⚠️ Temperature {value}°C exceeded threshold {_threshold}°C!");
        }
    }

    public void Unsubscribe()
    {
        _unsubscriber?.Dispose();
    }
}

// Usage
var sensor = new TemperatureSensor();

var display = new TemperatureDisplay();
display.Subscribe(sensor);

var alert = new TemperatureAlert(30);
alert.Subscribe(sensor);

sensor.SendTemperature(25);
sensor.SendTemperature(28);
sensor.SendTemperature(32);  // Triggers alert
sensor.SendTemperature(35);  // Triggers alert

alert.Unsubscribe();
sensor.SendTemperature(40);  // Alert not notified

sensor.EndTransmission();
```

---

### Best Practices

```csharp
// 1. ✅ Use C# events for simple observer scenarios
public event EventHandler<DataChangedEventArgs> DataChanged;

// 2. ✅ Use IObservable<T> for complex reactive scenarios
// With Rx.NET for advanced operators (Filter, Throttle, etc.)

// 3. ✅ Always provide unsubscribe mechanism
public IDisposable Subscribe(IObserver<T> observer)
{
    return new Unsubscriber(...);
}

// 4. ✅ Use weak references for long-lived subjects
// Prevents memory leaks

// 5. ✅ Thread-safe notifications
lock(_observers)
{
    foreach (var observer in _observers)
        observer.Update(this);
}

// 6. ❌ Don't notify during attach/detach
// Can cause issues if observer modifies collection

// 7. ✅ Handle observer exceptions
try
{
    observer.Update(this);
}
catch (Exception ex)
{
    // Log but don't stop notifying other observers
}

// 8. ✅ Use for event-driven architectures
// UI updates, messaging systems, reactive programming

// 9. ✅ Consider mediator pattern for complex observer networks
// When many observers and many subjects

// 10. ✅ Document notification order
// Observers notified in attachment order
```

---

## Q247: Explain the Decorator Pattern in C#. How would you implement it to add features to objects dynamically?

### Answer

The **Decorator Pattern** attaches additional responsibilities to an object dynamically. Decorators provide a flexible alternative to subclassing for extending functionality.

**Key Concepts:**
- Component Interface
- Concrete Component
- Base Decorator
- Concrete Decorators
- Composition over inheritance

### Basic Implementation

```csharp
// ============================================
// 1. BASIC DECORATOR PATTERN
// ============================================

// Component interface
public interface INotification
{
    void Send(string message);
}

// Concrete component
public class EmailNotification : INotification
{
    public void Send(string message)
    {
        Console.WriteLine($"📧 Email: {message}");
    }
}

// Base decorator
public abstract class NotificationDecorator : INotification
{
    protected INotification _notification;

    protected NotificationDecorator(INotification notification)
    {
        _notification = notification;
    }

    public virtual void Send(string message)
    {
        _notification.Send(message);
    }
}

// Concrete decorators
public class SMSDecorator : NotificationDecorator
{
    public SMSDecorator(INotification notification) : base(notification)
    {
    }

    public override void Send(string message)
    {
        base.Send(message);  // Call wrapped component
        SendSMS(message);
    }

    private void SendSMS(string message)
    {
        Console.WriteLine($"📱 SMS: {message}");
    }
}

public class SlackDecorator : NotificationDecorator
{
    public SlackDecorator(INotification notification) : base(notification)
    {
    }

    public override void Send(string message)
    {
        base.Send(message);
        SendSlack(message);
    }

    private void SendSlack(string message)
    {
        Console.WriteLine($"💬 Slack: {message}");
    }
}

public class EncryptionDecorator : NotificationDecorator
{
    public EncryptionDecorator(INotification notification) : base(notification)
    {
    }

    public override void Send(string message)
    {
        var encrypted = Encrypt(message);
        base.Send(encrypted);
    }

    private string Encrypt(string message)
    {
        Console.WriteLine("🔒 Encrypting message...");
        return $"[ENCRYPTED]{message}[/ENCRYPTED]";
    }
}

// Usage
INotification notification = new EmailNotification();
notification.Send("Basic notification");

// Add SMS capability
notification = new SMSDecorator(notification);
notification.Send("With SMS");

// Add Slack capability
notification = new SlackDecorator(notification);
notification.Send("With SMS and Slack");

// Add encryption
notification = new EncryptionDecorator(notification);
notification.Send("Encrypted, with SMS and Slack");

// Output:
// 📧 Email: Basic notification
// 📧 Email: With SMS
// 📱 SMS: With SMS
// 📧 Email: With SMS and Slack
// 📱 SMS: With SMS and Slack
// 💬 Slack: With SMS and Slack
// 🔒 Encrypting message...
// 📧 Email: [ENCRYPTED]Encrypted, with SMS and Slack[/ENCRYPTED]
// 📱 SMS: [ENCRYPTED]Encrypted, with SMS and Slack[/ENCRYPTED]
// 💬 Slack: [ENCRYPTED]Encrypted, with SMS and Slack[/ENCRYPTED]
```

### Real-World Example: Stream Processing

```csharp
// ============================================
// 2. REAL-WORLD: DATA STREAM DECORATORS
// ============================================

// Component
public interface IDataStream
{
    void Write(byte[] data);
    byte[] Read();
}

// Concrete component
public class FileDataStream : IDataStream
{
    private readonly string _filePath;
    private MemoryStream _buffer = new MemoryStream();

    public FileDataStream(string filePath)
    {
        _filePath = filePath;
    }

    public void Write(byte[] data)
    {
        Console.WriteLine($"Writing {data.Length} bytes to file: {_filePath}");
        _buffer.Write(data, 0, data.Length);
    }

    public byte[] Read()
    {
        Console.WriteLine($"Reading from file: {_filePath}");
        return _buffer.ToArray();
    }
}

// Base decorator
public abstract class DataStreamDecorator : IDataStream
{
    protected IDataStream _stream;

    protected DataStreamDecorator(IDataStream stream)
    {
        _stream = stream;
    }

    public virtual void Write(byte[] data)
    {
        _stream.Write(data);
    }

    public virtual byte[] Read()
    {
        return _stream.Read();
    }
}

// Compression decorator
public class CompressionDecorator : DataStreamDecorator
{
    public CompressionDecorator(IDataStream stream) : base(stream)
    {
    }

    public override void Write(byte[] data)
    {
        var compressed = Compress(data);
        base.Write(compressed);
    }

    public override byte[] Read()
    {
        var data = base.Read();
        return Decompress(data);
    }

    private byte[] Compress(byte[] data)
    {
        Console.WriteLine($"  🗜️ Compressing {data.Length} bytes...");
        // Simulate compression (real implementation would use GZipStream)
        return data;
    }

    private byte[] Decompress(byte[] data)
    {
        Console.WriteLine($"  📂 Decompressing {data.Length} bytes...");
        return data;
    }
}

// Encryption decorator
public class EncryptionStreamDecorator : DataStreamDecorator
{
    private readonly string _key;

    public EncryptionStreamDecorator(IDataStream stream, string key) : base(stream)
    {
        _key = key;
    }

    public override void Write(byte[] data)
    {
        var encrypted = Encrypt(data);
        base.Write(encrypted);
    }

    public override byte[] Read()
    {
        var data = base.Read();
        return Decrypt(data);
    }

    private byte[] Encrypt(byte[] data)
    {
        Console.WriteLine($"  🔐 Encrypting with key: {_key}");
        // Real implementation would use AES
        return data;
    }

    private byte[] Decrypt(byte[] data)
    {
        Console.WriteLine($"  🔓 Decrypting with key: {_key}");
        return data;
    }
}

// Logging decorator
public class LoggingDecorator : DataStreamDecorator
{
    public LoggingDecorator(IDataStream stream) : base(stream)
    {
    }

    public override void Write(byte[] data)
    {
        Console.WriteLine($"  📝 [LOG] Writing {data.Length} bytes at {DateTime.Now}");
        base.Write(data);
        Console.WriteLine($"  ✅ [LOG] Write completed");
    }

    public override byte[] Read()
    {
        Console.WriteLine($"  📝 [LOG] Reading at {DateTime.Now}");
        var data = base.Read();
        Console.WriteLine($"  ✅ [LOG] Read {data.Length} bytes");
        return data;
    }
}

// Usage
var data = Encoding.UTF8.GetBytes("Sensitive data to store");

// Create a file stream with compression, encryption, and logging
IDataStream stream = new FileDataStream("data.bin");
stream = new CompressionDecorator(stream);
stream = new EncryptionStreamDecorator(stream, "secret-key-123");
stream = new LoggingDecorator(stream);

stream.Write(data);
Console.WriteLine();
var readData = stream.Read();
```

### ASP.NET Core Example: HTTP Client Decorators

```csharp
// ============================================
// 3. ASP.NET CORE: HTTP CLIENT DECORATORS
// ============================================

public interface IHttpClient
{
    Task<string> GetAsync(string url);
}

// Concrete component
public class BasicHttpClient : IHttpClient
{
    private readonly HttpClient _httpClient;

    public BasicHttpClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string> GetAsync(string url)
    {
        var response = await _httpClient.GetAsync(url);
        return await response.Content.ReadAsStringAsync();
    }
}

// Retry decorator
public class RetryHttpClientDecorator : IHttpClient
{
    private readonly IHttpClient _httpClient;
    private readonly int _maxRetries;

    public RetryHttpClientDecorator(IHttpClient httpClient, int maxRetries = 3)
    {
        _httpClient = httpClient;
        _maxRetries = maxRetries;
    }

    public async Task<string> GetAsync(string url)
    {
        int retries = 0;
        while (true)
        {
            try
            {
                return await _httpClient.GetAsync(url);
            }
            catch (HttpRequestException) when (retries < _maxRetries)
            {
                retries++;
                Console.WriteLine($"Retry {retries}/{_maxRetries}");
                await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, retries))); // Exponential backoff
            }
        }
    }
}

// Caching decorator
public class CachingHttpClientDecorator : IHttpClient
{
    private readonly IHttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly TimeSpan _cacheDuration;

    public CachingHttpClientDecorator(
        IHttpClient httpClient,
        IMemoryCache cache,
        TimeSpan cacheDuration)
    {
        _httpClient = httpClient;
        _cache = cache;
        _cacheDuration = cacheDuration;
    }

    public async Task<string> GetAsync(string url)
    {
        if (_cache.TryGetValue(url, out string cachedResult))
        {
            Console.WriteLine($"Cache HIT for {url}");
            return cachedResult;
        }

        Console.WriteLine($"Cache MISS for {url}");
        var result = await _httpClient.GetAsync(url);

        _cache.Set(url, result, _cacheDuration);
        return result;
    }
}

// Logging decorator
public class LoggingHttpClientDecorator : IHttpClient
{
    private readonly IHttpClient _httpClient;
    private readonly ILogger<LoggingHttpClientDecorator> _logger;

    public LoggingHttpClientDecorator(
        IHttpClient httpClient,
        ILogger<LoggingHttpClientDecorator> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<string> GetAsync(string url)
    {
        var stopwatch = Stopwatch.StartNew();
        _logger.LogInformation("Requesting: {Url}", url);

        try
        {
            var result = await _httpClient.GetAsync(url);
            stopwatch.Stop();
            _logger.LogInformation(
                "Request completed: {Url} ({ElapsedMs}ms)",
                url,
                stopwatch.ElapsedMilliseconds);
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Request failed: {Url}", url);
            throw;
        }
    }
}

// DI Registration
public void ConfigureServices(IServiceCollection services)
{
    services.AddMemoryCache();
    services.AddHttpClient();

    // Register decorated HTTP client
    services.AddScoped<IHttpClient>(provider =>
    {
        var httpClientFactory = provider.GetRequiredService<IHttpClientFactory>();
        var httpClient = httpClientFactory.CreateClient();
        var logger = provider.GetRequiredService<ILogger<LoggingHttpClientDecorator>>();
        var cache = provider.GetRequiredService<IMemoryCache>();

        // Build decorator chain
        IHttpClient client = new BasicHttpClient(httpClient);
        client = new RetryHttpClientDecorator(client, maxRetries: 3);
        client = new CachingHttpClientDecorator(client, cache, TimeSpan.FromMinutes(5));
        client = new LoggingHttpClientDecorator(client, logger);

        return client;
    });
}

// Usage in controller
public class WeatherController : ControllerBase
{
    private readonly IHttpClient _httpClient;

    public WeatherController(IHttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    [HttpGet]
    public async Task<IActionResult> GetWeather()
    {
        // This call will be logged, cached, and retried on failure
        var weather = await _httpClient.GetAsync("https://api.weather.com/data");
        return Ok(weather);
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Use interfaces, not concrete classes
public interface IComponent { }

// 2. ✅ Decorator should implement same interface
public class Decorator : IComponent
{
    private IComponent _component;
}

// 3. ✅ Use for adding cross-cutting concerns
// Logging, caching, retry logic, validation, etc.

// 4. ✅ Chain decorators for multiple features
IComponent component = new ConcreteComponent();
component = new LoggingDecorator(component);
component = new CachingDecorator(component);

// 5. ✅ Consider using with DI for automatic decoration
services.Decorate<IService, LoggingDecorator>();

// 6. ❌ Don't use for significant behavior changes
// Use Strategy or State pattern instead

// 7. ✅ Keep decorators single-purpose
// Each decorator should add one feature

// 8. ✅ Consider decorator order
// Logging → Caching → Retry → Base
// Order matters!

// 9. ✅ Real .NET examples
// Stream classes: BufferedStream, CryptoStream, GZipStream
// All decorate the base Stream class

// 10. ✅ Use for runtime feature configuration
// Different decorators for different environments/users
```

---

## Q248: What is the Adapter Pattern? Provide examples of using it to integrate third-party libraries or legacy code.

### Answer

The **Adapter Pattern** converts the interface of a class into another interface that clients expect. It allows incompatible interfaces to work together without modifying their source code.

**Key Concepts:**
- Target Interface (what client expects)
- Adaptee (existing incompatible interface)
- Adapter (bridges target and adaptee)
- Object Adapter vs Class Adapter

### Basic Implementation

```csharp
// ============================================
// 1. BASIC ADAPTER PATTERN
// ============================================

// Target interface (what client expects)
public interface IPaymentProcessor
{
    PaymentResult ProcessPayment(decimal amount, string currency);
}

// Adaptee (third-party library with incompatible interface)
public class StripePaymentGateway
{
    public StripeChargeResponse Charge(int amountInCents, string currencyCode)
    {
        Console.WriteLine($"Stripe: Charging {amountInCents} cents in {currencyCode}");
        return new StripeChargeResponse
        {
            Success = true,
            TransactionId = Guid.NewGuid().ToString(),
            Message = "Payment successful"
        };
    }
}

public class StripeChargeResponse
{
    public bool Success { get; set; }
    public string TransactionId { get; set; }
    public string Message { get; set; }
}

// Adapter
public class StripeAdapter : IPaymentProcessor
{
    private readonly StripePaymentGateway _stripeGateway;

    public StripeAdapter(StripePaymentGateway stripeGateway)
    {
        _stripeGateway = stripeGateway;
    }

    public PaymentResult ProcessPayment(decimal amount, string currency)
    {
        // Convert decimal to cents
        int amountInCents = (int)(amount * 100);

        // Call Stripe's method
        var stripeResponse = _stripeGateway.Charge(amountInCents, currency);

        // Convert Stripe's response to our standard format
        return new PaymentResult
        {
            IsSuccessful = stripeResponse.Success,
            TransactionId = stripeResponse.TransactionId,
            Message = stripeResponse.Message
        };
    }
}

// Our standard payment result
public class PaymentResult
{
    public bool IsSuccessful { get; set; }
    public string TransactionId { get; set; }
    public string Message { get; set; }
}

// Another adaptee (different third-party library)
public class PayPalSDK
{
    public bool ExecutePayment(double dollarAmount, string curr)
    {
        Console.WriteLine($"PayPal: Processing ${dollarAmount} {curr}");
        return true;
    }

    public string GetLastTransactionId()
    {
        return $"PAYPAL-{Guid.NewGuid()}";
    }
}

// Adapter for PayPal
public class PayPalAdapter : IPaymentProcessor
{
    private readonly PayPalSDK _payPalSdk;

    public PayPalAdapter(PayPalSDK payPalSdk)
    {
        _payPalSdk = payPalSdk;
    }

    public PaymentResult ProcessPayment(decimal amount, string currency)
    {
        double dollarAmount = (double)amount;
        bool success = _payPalSdk.ExecutePayment(dollarAmount, currency);

        return new PaymentResult
        {
            IsSuccessful = success,
            TransactionId = _payPalSdk.GetLastTransactionId(),
            Message = success ? "Payment processed" : "Payment failed"
        };
    }
}

// Client code
public class CheckoutService
{
    private readonly IPaymentProcessor _paymentProcessor;

    public CheckoutService(IPaymentProcessor paymentProcessor)
    {
        _paymentProcessor = paymentProcessor;
    }

    public void Checkout(decimal amount)
    {
        var result = _paymentProcessor.ProcessPayment(amount, "USD");

        if (result.IsSuccessful)
        {
            Console.WriteLine($"✅ Payment successful! Transaction: {result.TransactionId}");
        }
        else
        {
            Console.WriteLine($"❌ Payment failed: {result.Message}");
        }
    }
}

// Usage - client code doesn't know about Stripe or PayPal specifics
var stripeGateway = new StripePaymentGateway();
var stripeAdapter = new StripeAdapter(stripeGateway);
var checkoutService = new CheckoutService(stripeAdapter);
checkoutService.Checkout(99.99m);

var payPalSdk = new PayPalSDK();
var payPalAdapter = new PayPalAdapter(payPalSdk);
var checkoutService2 = new CheckoutService(payPalAdapter);
checkoutService2.Checkout(49.99m);
```

### Real-World Example: Legacy Database Integration

```csharp
// ============================================
// 2. REAL-WORLD: LEGACY DATABASE ADAPTER
// ============================================

// Target interface (modern repository pattern)
public interface ICustomerRepository
{
    Task<Customer> GetByIdAsync(int id);
    Task<IEnumerable<Customer>> GetAllAsync();
    Task<int> CreateAsync(Customer customer);
    Task UpdateAsync(Customer customer);
}

// Modern entity
public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public DateTime CreatedDate { get; set; }
}

// Legacy database class (cannot modify - third-party or old code)
public class LegacyCustomerDatabase
{
    public DataTable GetCustomer(int customerId)
    {
        Console.WriteLine($"[Legacy] SELECT * FROM Customers WHERE ID = {customerId}");
        var dt = new DataTable();
        dt.Columns.Add("CustomerID", typeof(int));
        dt.Columns.Add("FullName", typeof(string));
        dt.Columns.Add("EmailAddress", typeof(string));
        dt.Columns.Add("CreateDate", typeof(DateTime));

        dt.Rows.Add(customerId, "John Doe", "john@example.com", DateTime.Now);
        return dt;
    }

    public DataTable GetAllCustomers()
    {
        Console.WriteLine("[Legacy] SELECT * FROM Customers");
        var dt = new DataTable();
        dt.Columns.Add("CustomerID", typeof(int));
        dt.Columns.Add("FullName", typeof(string));
        dt.Columns.Add("EmailAddress", typeof(string));
        dt.Columns.Add("CreateDate", typeof(DateTime));

        dt.Rows.Add(1, "John Doe", "john@example.com", DateTime.Now);
        dt.Rows.Add(2, "Jane Smith", "jane@example.com", DateTime.Now);
        return dt;
    }

    public int InsertCustomer(string name, string email)
    {
        Console.WriteLine($"[Legacy] INSERT INTO Customers VALUES ('{name}', '{email}')");
        return new Random().Next(1000, 9999);
    }

    public void UpdateCustomer(int id, string name, string email)
    {
        Console.WriteLine($"[Legacy] UPDATE Customers SET FullName='{name}', EmailAddress='{email}' WHERE CustomerID={id}");
    }
}

// Adapter that makes legacy code work with modern interface
public class LegacyCustomerAdapter : ICustomerRepository
{
    private readonly LegacyCustomerDatabase _legacyDb;

    public LegacyCustomerAdapter(LegacyCustomerDatabase legacyDb)
    {
        _legacyDb = legacyDb;
    }

    public Task<Customer> GetByIdAsync(int id)
    {
        var dataTable = _legacyDb.GetCustomer(id);

        if (dataTable.Rows.Count == 0)
            return Task.FromResult<Customer>(null);

        var row = dataTable.Rows[0];
        var customer = new Customer
        {
            Id = (int)row["CustomerID"],
            Name = (string)row["FullName"],
            Email = (string)row["EmailAddress"],
            CreatedDate = (DateTime)row["CreateDate"]
        };

        return Task.FromResult(customer);
    }

    public Task<IEnumerable<Customer>> GetAllAsync()
    {
        var dataTable = _legacyDb.GetAllCustomers();
        var customers = new List<Customer>();

        foreach (DataRow row in dataTable.Rows)
        {
            customers.Add(new Customer
            {
                Id = (int)row["CustomerID"],
                Name = (string)row["FullName"],
                Email = (string)row["EmailAddress"],
                CreatedDate = (DateTime)row["CreateDate"]
            });
        }

        return Task.FromResult<IEnumerable<Customer>>(customers);
    }

    public Task<int> CreateAsync(Customer customer)
    {
        int id = _legacyDb.InsertCustomer(customer.Name, customer.Email);
        return Task.FromResult(id);
    }

    public Task UpdateAsync(Customer customer)
    {
        _legacyDb.UpdateCustomer(customer.Id, customer.Name, customer.Email);
        return Task.CompletedTask;
    }
}

// Modern service using the adapter
public class CustomerService
{
    private readonly ICustomerRepository _repository;

    public CustomerService(ICustomerRepository repository)
    {
        _repository = repository;
    }

    public async Task ProcessCustomerAsync(int id)
    {
        var customer = await _repository.GetByIdAsync(id);
        Console.WriteLine($"Processing: {customer.Name} ({customer.Email})");
    }
}

// Usage - service doesn't know it's using legacy code
var legacyDb = new LegacyCustomerDatabase();
var adapter = new LegacyCustomerAdapter(legacyDb);
var service = new CustomerService(adapter);
await service.ProcessCustomerAsync(1);
```

### ASP.NET Core Example: Multiple Logging Providers

```csharp
// ============================================
// 3. ASP.NET CORE: LOGGING ADAPTER
// ============================================

// Target interface (our standard logging interface)
public interface IApplicationLogger
{
    void LogInfo(string message, params object[] args);
    void LogError(string message, Exception ex);
    void LogWarning(string message);
}

// Adaptee 1: Microsoft.Extensions.Logging
public class MicrosoftLoggingAdapter : IApplicationLogger
{
    private readonly ILogger<MicrosoftLoggingAdapter> _logger;

    public MicrosoftLoggingAdapter(ILogger<MicrosoftLoggingAdapter> logger)
    {
        _logger = logger;
    }

    public void LogInfo(string message, params object[] args)
    {
        _logger.LogInformation(message, args);
    }

    public void LogError(string message, Exception ex)
    {
        _logger.LogError(ex, message);
    }

    public void LogWarning(string message)
    {
        _logger.LogWarning(message);
    }
}

// Adaptee 2: Serilog (third-party library)
public class SerilogAdapter : IApplicationLogger
{
    private readonly Serilog.ILogger _serilogLogger;

    public SerilogAdapter(Serilog.ILogger serilogLogger)
    {
        _serilogLogger = serilogLogger;
    }

    public void LogInfo(string message, params object[] args)
    {
        _serilogLogger.Information(message, args);
    }

    public void LogError(string message, Exception ex)
    {
        _serilogLogger.Error(ex, message);
    }

    public void LogWarning(string message)
    {
        _serilogLogger.Warning(message);
    }
}

// Adaptee 3: NLog (another third-party library)
public class NLogAdapter : IApplicationLogger
{
    private readonly NLog.Logger _nlogLogger;

    public NLogAdapter()
    {
        _nlogLogger = NLog.LogManager.GetCurrentClassLogger();
    }

    public void LogInfo(string message, params object[] args)
    {
        _nlogLogger.Info(message, args);
    }

    public void LogError(string message, Exception ex)
    {
        _nlogLogger.Error(ex, message);
    }

    public void LogWarning(string message)
    {
        _nlogLogger.Warn(message);
    }
}

// Adaptee 4: Legacy custom logging system
public class LegacyLogger
{
    public void WriteLog(string level, string text)
    {
        Console.WriteLine($"[{level}] {DateTime.Now}: {text}");
    }

    public void WriteException(Exception exception)
    {
        Console.WriteLine($"[EXCEPTION] {DateTime.Now}: {exception.Message}");
    }
}

public class LegacyLoggerAdapter : IApplicationLogger
{
    private readonly LegacyLogger _legacyLogger;

    public LegacyLoggerAdapter(LegacyLogger legacyLogger)
    {
        _legacyLogger = legacyLogger;
    }

    public void LogInfo(string message, params object[] args)
    {
        var formattedMessage = string.Format(message, args);
        _legacyLogger.WriteLog("INFO", formattedMessage);
    }

    public void LogError(string message, Exception ex)
    {
        _legacyLogger.WriteLog("ERROR", message);
        _legacyLogger.WriteException(ex);
    }

    public void LogWarning(string message)
    {
        _legacyLogger.WriteLog("WARNING", message);
    }
}

// DI Configuration
public void ConfigureServices(IServiceCollection services)
{
    // Choose which adapter to use based on configuration
    var loggingProvider = Configuration["Logging:Provider"];

    switch (loggingProvider)
    {
        case "Serilog":
            var serilogLogger = new LoggerConfiguration()
                .WriteTo.Console()
                .CreateLogger();
            services.AddSingleton<IApplicationLogger>(
                new SerilogAdapter(serilogLogger));
            break;

        case "NLog":
            services.AddSingleton<IApplicationLogger, NLogAdapter>();
            break;

        case "Legacy":
            services.AddSingleton<IApplicationLogger>(
                new LegacyLoggerAdapter(new LegacyLogger()));
            break;

        default:
            services.AddSingleton<IApplicationLogger, MicrosoftLoggingAdapter>();
            break;
    }
}

// Service using the logger - doesn't know which implementation
public class OrderService
{
    private readonly IApplicationLogger _logger;

    public OrderService(IApplicationLogger logger)
    {
        _logger = logger;
    }

    public void ProcessOrder(int orderId)
    {
        try
        {
            _logger.LogInfo("Processing order {OrderId}", orderId);

            // Process order logic

            _logger.LogInfo("Order {OrderId} processed successfully", orderId);
        }
        catch (Exception ex)
        {
            _logger.LogError("Failed to process order {OrderId}", ex);
            throw;
        }
    }
}
```

### Two-Way Adapter Example

```csharp
// ============================================
// 4. TWO-WAY ADAPTER (Bidirectional)
// ============================================

// Interface 1
public interface IXmlSerializer
{
    string SerializeToXml<T>(T obj);
    T DeserializeFromXml<T>(string xml);
}

// Interface 2
public interface IJsonSerializer
{
    string SerializeToJson<T>(T obj);
    T DeserializeFromJson<T>(string json);
}

// Two-way adapter
public class SerializerAdapter : IXmlSerializer, IJsonSerializer
{
    private readonly System.Xml.Serialization.XmlSerializer _xmlSerializer;
    private readonly JsonSerializerOptions _jsonOptions;

    public SerializerAdapter()
    {
        _jsonOptions = new JsonSerializerOptions { WriteIndented = true };
    }

    // IXmlSerializer implementation
    public string SerializeToXml<T>(T obj)
    {
        _xmlSerializer = new System.Xml.Serialization.XmlSerializer(typeof(T));
        using var stringWriter = new StringWriter();
        _xmlSerializer.Serialize(stringWriter, obj);
        return stringWriter.ToString();
    }

    public T DeserializeFromXml<T>(string xml)
    {
        _xmlSerializer = new System.Xml.Serialization.XmlSerializer(typeof(T));
        using var stringReader = new StringReader(xml);
        return (T)_xmlSerializer.Deserialize(stringReader);
    }

    // IJsonSerializer implementation
    public string SerializeToJson<T>(T obj)
    {
        return JsonSerializer.Serialize(obj, _jsonOptions);
    }

    public T DeserializeFromJson<T>(string json)
    {
        return JsonSerializer.Deserialize<T>(json, _jsonOptions);
    }
}

// Usage - same adapter works with both interfaces
var adapter = new SerializerAdapter();

// Use as XML serializer
IXmlSerializer xmlSerializer = adapter;
var xml = xmlSerializer.SerializeToXml(customer);

// Use as JSON serializer
IJsonSerializer jsonSerializer = adapter;
var json = jsonSerializer.SerializeToJson(customer);
```

---

### Best Practices

```csharp
// 1. ✅ Use when you can't modify existing code
// Third-party libraries, legacy systems, external APIs

// 2. ✅ Object Adapter (composition) over Class Adapter (inheritance)
public class Adapter : ITarget
{
    private Adaptee _adaptee;  // ✅ Composition
}

public class Adapter : Adaptee, ITarget  // ❌ Inheritance (less flexible)
{
}

// 3. ✅ One adapter per incompatible interface
// Don't create god adapters that adapt everything

// 4. ✅ Keep adapters thin
// Only translate interfaces, don't add business logic

// 5. ✅ Use for data format conversion
// XML ↔ JSON, DataTable ↔ Entity, etc.

// 6. ✅ Combine with Factory pattern
public class PaymentProcessorFactory
{
    public IPaymentProcessor Create(string provider)
    {
        return provider switch
        {
            "Stripe" => new StripeAdapter(new StripePaymentGateway()),
            "PayPal" => new PayPalAdapter(new PayPalSDK()),
            _ => throw new ArgumentException("Unknown provider")
        };
    }
}

// 7. ✅ Document what you're adapting
// [Adapter] Adapts StripePaymentGateway to IPaymentProcessor

// 8. ✅ Real-world .NET examples
// - DbDataAdapter (adapts DataSet to database)
// - StreamReader/StreamWriter (adapts Stream to text operations)
// - HttpClient wrappers

// 9. ❌ Don't overuse
// If you control both interfaces, consider refactoring instead

// 10. ✅ Use with Dependency Injection
// Makes swapping implementations easy
services.AddScoped<IPaymentProcessor, StripeAdapter>();
```

---

## Q249: Explain the Repository and Unit of Work patterns. How do they work together in Entity Framework Core applications?

### Answer

The **Repository Pattern** abstracts data access logic and provides a collection-like interface for accessing domain objects. The **Unit of Work Pattern** maintains a list of objects affected by a business transaction and coordinates writing changes to the database.

**Key Concepts:**
- Repository: Encapsulates data access
- Unit of Work: Manages transactions
- Separation of concerns
- Testability

### Basic Implementation

```csharp
// ============================================
// 1. BASIC REPOSITORY PATTERN
// ============================================

// Entity
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int CategoryId { get; set; }
    public Category Category { get; set; }
}

public class Category
{
    public int Id { get; set; }
    public string Name { get; set; }
    public List<Product> Products { get; set; }
}

// Generic repository interface
public interface IRepository<T> where T : class
{
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    void Update(T entity);
    void Remove(T entity);
    void RemoveRange(IEnumerable<T> entities);
}

// Generic repository implementation
public class Repository<T> : IRepository<T> where T : class
{
    protected readonly DbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(DbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }

    public virtual async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }

    public virtual async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.Where(predicate).ToListAsync();
    }

    public virtual async Task AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
    }

    public virtual async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
    }

    public virtual void Update(T entity)
    {
        _dbSet.Update(entity);
    }

    public virtual void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }

    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
    }
}

// Specific repository interface
public interface IProductRepository : IRepository<Product>
{
    Task<IEnumerable<Product>> GetProductsInPriceRangeAsync(decimal minPrice, decimal maxPrice);
    Task<IEnumerable<Product>> GetProductsByCategoryAsync(int categoryId);
}

// Specific repository implementation
public class ProductRepository : Repository<Product>, IProductRepository
{
    public ProductRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Product>> GetProductsInPriceRangeAsync(decimal minPrice, decimal maxPrice)
    {
        return await _dbSet
            .Where(p => p.Price >= minPrice && p.Price <= maxPrice)
            .Include(p => p.Category)
            .ToListAsync();
    }

    public async Task<IEnumerable<Product>> GetProductsByCategoryAsync(int categoryId)
    {
        return await _dbSet
            .Where(p => p.CategoryId == categoryId)
            .Include(p => p.Category)
            .ToListAsync();
    }
}
```

### Unit of Work Pattern

```csharp
// ============================================
// 2. UNIT OF WORK PATTERN
// ============================================

// Unit of Work interface
public interface IUnitOfWork : IDisposable
{
    IProductRepository Products { get; }
    ICategoryRepository Categories { get; }
    IOrderRepository Orders { get; }

    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}

// Unit of Work implementation
public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction _transaction;

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;

        // Initialize repositories
        Products = new ProductRepository(_context);
        Categories = new CategoryRepository(_context);
        Orders = new OrderRepository(_context);
    }

    public IProductRepository Products { get; private set; }
    public ICategoryRepository Categories { get; private set; }
    public IOrderRepository Orders { get; private set; }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        try
        {
            await SaveChangesAsync();
            await _transaction?.CommitAsync();
        }
        catch
        {
            await RollbackTransactionAsync();
            throw;
        }
        finally
        {
            if (_transaction != null)
            {
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }
    }

    public async Task RollbackTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}

// DbContext
public class ApplicationDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<Order> Orders { get; set; }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Product>()
            .HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId);
    }
}
```

### Real-World Example: E-Commerce Order Processing

```csharp
// ============================================
// 3. REAL-WORLD: E-COMMERCE WITH UOW
// ============================================

public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; }
    public List<OrderItem> Items { get; set; } = new();
}

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public Product Product { get; set; }
}

public interface IOrderRepository : IRepository<Order>
{
    Task<Order> GetOrderWithItemsAsync(int orderId);
    Task<IEnumerable<Order>> GetCustomerOrdersAsync(int customerId);
}

public class OrderRepository : Repository<Order>, IOrderRepository
{
    public OrderRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Order> GetOrderWithItemsAsync(int orderId)
    {
        return await _dbSet
            .Include(o => o.Items)
            .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }

    public async Task<IEnumerable<Order>> GetCustomerOrdersAsync(int customerId)
    {
        return await _dbSet
            .Where(o => o.CustomerId == customerId)
            .Include(o => o.Items)
            .OrderByDescending(o => o.OrderDate)
            .ToListAsync();
    }
}

// Service using Unit of Work
public class OrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<OrderService> _logger;

    public OrderService(IUnitOfWork unitOfWork, ILogger<OrderService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<int> CreateOrderAsync(int customerId, List<(int ProductId, int Quantity)> items)
    {
        try
        {
            await _unitOfWork.BeginTransactionAsync();

            // Create order
            var order = new Order
            {
                CustomerId = customerId,
                OrderDate = DateTime.UtcNow,
                Status = "Pending"
            };

            await _unitOfWork.Orders.AddAsync(order);
            await _unitOfWork.SaveChangesAsync(); // Save to get order ID

            // Add order items and update inventory
            decimal totalAmount = 0;

            foreach (var (productId, quantity) in items)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(productId);

                if (product == null)
                {
                    throw new InvalidOperationException($"Product {productId} not found");
                }

                var orderItem = new OrderItem
                {
                    OrderId = order.Id,
                    ProductId = productId,
                    Quantity = quantity,
                    UnitPrice = product.Price
                };

                order.Items.Add(orderItem);
                totalAmount += product.Price * quantity;

                // Update product inventory (if you have stock tracking)
                // product.Stock -= quantity;
                // _unitOfWork.Products.Update(product);
            }

            order.TotalAmount = totalAmount;
            _unitOfWork.Orders.Update(order);

            await _unitOfWork.CommitTransactionAsync();

            _logger.LogInformation("Order {OrderId} created successfully", order.Id);
            return order.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create order for customer {CustomerId}", customerId);
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }

    public async Task CancelOrderAsync(int orderId)
    {
        try
        {
            await _unitOfWork.BeginTransactionAsync();

            var order = await _unitOfWork.Orders.GetOrderWithItemsAsync(orderId);

            if (order == null)
            {
                throw new InvalidOperationException($"Order {orderId} not found");
            }

            if (order.Status == "Shipped")
            {
                throw new InvalidOperationException("Cannot cancel shipped orders");
            }

            // Restore inventory
            foreach (var item in order.Items)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId);
                // product.Stock += item.Quantity;
                // _unitOfWork.Products.Update(product);
            }

            order.Status = "Cancelled";
            _unitOfWork.Orders.Update(order);

            await _unitOfWork.CommitTransactionAsync();

            _logger.LogInformation("Order {OrderId} cancelled", orderId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cancel order {OrderId}", orderId);
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
}
```

### ASP.NET Core with Dependency Injection

```csharp
// ============================================
// 4. ASP.NET CORE INTEGRATION
// ============================================

// Startup.cs or Program.cs
public void ConfigureServices(IServiceCollection services)
{
    // Register DbContext
    services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));

    // Register Unit of Work
    services.AddScoped<IUnitOfWork, UnitOfWork>();

    // Or register repositories individually
    services.AddScoped<IProductRepository, ProductRepository>();
    services.AddScoped<ICategoryRepository, CategoryRepository>();

    // Register services
    services.AddScoped<OrderService>();
}

// Controller using Unit of Work
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public ProductsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
    {
        var products = await _unitOfWork.Products.GetAllAsync();
        return Ok(products);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetProduct(int id)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        return Ok(product);
    }

    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct(Product product)
    {
        await _unitOfWork.Products.AddAsync(product);
        await _unitOfWork.SaveChangesAsync();

        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProduct(int id, Product product)
    {
        if (id != product.Id)
        {
            return BadRequest();
        }

        _unitOfWork.Products.Update(product);

        try
        {
            await _unitOfWork.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            var exists = await _unitOfWork.Products.GetByIdAsync(id);
            if (exists == null)
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        _unitOfWork.Products.Remove(product);
        await _unitOfWork.SaveChangesAsync();

        return NoContent();
    }

    // Complex operation using multiple repositories
    [HttpPost("category/{categoryId}/products")]
    public async Task<IActionResult> AddProductsToCategory(
        int categoryId,
        List<Product> products)
    {
        try
        {
            await _unitOfWork.BeginTransactionAsync();

            var category = await _unitOfWork.Categories.GetByIdAsync(categoryId);

            if (category == null)
            {
                return NotFound("Category not found");
            }

            foreach (var product in products)
            {
                product.CategoryId = categoryId;
                await _unitOfWork.Products.AddAsync(product);
            }

            await _unitOfWork.CommitTransactionAsync();

            return Ok($"Added {products.Count} products to category {category.Name}");
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            return StatusCode(500, $"Error: {ex.Message}");
        }
    }
}
```

### Specification Pattern with Repository

```csharp
// ============================================
// 5. SPECIFICATION PATTERN (Advanced)
// ============================================

// Base specification
public interface ISpecification<T>
{
    Expression<Func<T, bool>> Criteria { get; }
    List<Expression<Func<T, object>>> Includes { get; }
    Expression<Func<T, object>> OrderBy { get; }
    Expression<Func<T, object>> OrderByDescending { get; }
    int Take { get; }
    int Skip { get; }
    bool IsPagingEnabled { get; }
}

public abstract class BaseSpecification<T> : ISpecification<T>
{
    public Expression<Func<T, bool>> Criteria { get; }
    public List<Expression<Func<T, object>>> Includes { get; } = new();
    public Expression<Func<T, object>> OrderBy { get; private set; }
    public Expression<Func<T, object>> OrderByDescending { get; private set; }
    public int Take { get; private set; }
    public int Skip { get; private set; }
    public bool IsPagingEnabled { get; private set; }

    protected BaseSpecification(Expression<Func<T, bool>> criteria)
    {
        Criteria = criteria;
    }

    protected void AddInclude(Expression<Func<T, object>> includeExpression)
    {
        Includes.Add(includeExpression);
    }

    protected void ApplyOrderBy(Expression<Func<T, object>> orderByExpression)
    {
        OrderBy = orderByExpression;
    }

    protected void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescExpression)
    {
        OrderByDescending = orderByDescExpression;
    }

    protected void ApplyPaging(int skip, int take)
    {
        Skip = skip;
        Take = take;
        IsPagingEnabled = true;
    }
}

// Specific specification
public class ProductsInPriceRangeSpec : BaseSpecification<Product>
{
    public ProductsInPriceRangeSpec(decimal minPrice, decimal maxPrice)
        : base(p => p.Price >= minPrice && p.Price <= maxPrice)
    {
        AddInclude(p => p.Category);
        ApplyOrderBy(p => p.Price);
    }
}

// Repository with specification support
public interface IRepository<T> where T : class
{
    Task<T> GetEntityWithSpec(ISpecification<T> spec);
    Task<IEnumerable<T>> ListAsync(ISpecification<T> spec);
    Task<int> CountAsync(ISpecification<T> spec);
}

// Implementation
public static class SpecificationEvaluator<T> where T : class
{
    public static IQueryable<T> GetQuery(IQueryable<T> inputQuery, ISpecification<T> spec)
    {
        var query = inputQuery;

        if (spec.Criteria != null)
        {
            query = query.Where(spec.Criteria);
        }

        query = spec.Includes.Aggregate(query, (current, include) => current.Include(include));

        if (spec.OrderBy != null)
        {
            query = query.OrderBy(spec.OrderBy);
        }
        else if (spec.OrderByDescending != null)
        {
            query = query.OrderByDescending(spec.OrderByDescending);
        }

        if (spec.IsPagingEnabled)
        {
            query = query.Skip(spec.Skip).Take(spec.Take);
        }

        return query;
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ EF Core DbContext already implements Unit of Work
// Consider whether you need an additional UOW abstraction

// 2. ✅ Use repository for complex queries only
// Simple CRUD? DbContext is enough
var products = await _context.Products.ToListAsync(); // ✅ Simple

// Complex query with business logic? Use repository
var products = await _productRepository.GetActiveProductsWithInventory(); // ✅

// 3. ✅ Don't expose IQueryable from repositories
// ❌ Bad
IQueryable<Product> GetProducts();

// ✅ Good
Task<IEnumerable<Product>> GetProductsAsync();

// 4. ✅ Register as Scoped in DI
services.AddScoped<IUnitOfWork, UnitOfWork>();

// 5. ✅ One DbContext per request (Scoped lifetime)
// Don't create long-lived DbContext instances

// 6. ✅ Use async methods
await _unitOfWork.SaveChangesAsync();

// 7. ❌ Don't create repositories for every entity
// Only create repositories when needed for complex operations

// 8. ✅ Handle transactions at service layer
public class OrderService
{
    public async Task CreateOrder()
    {
        await _unitOfWork.BeginTransactionAsync();
        try
        {
            // Multiple operations
            await _unitOfWork.CommitTransactionAsync();
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
}

// 9. ✅ Keep repositories focused
// One repository per aggregate root

// 10. ⚠️ Consider simpler alternatives
// For simple CRUD apps, direct DbContext usage might be enough
// Repository pattern adds value for:
// - Complex domain logic
// - Multiple data sources
// - Testing with mocks
// - Encapsulating query logic
```

---

## Q250: Explain Dependency Injection as a design pattern. How is it implemented in ASP.NET Core's built-in DI container?

### Answer

**Dependency Injection (DI)** is a design pattern where objects receive their dependencies from external sources rather than creating them internally. It implements Inversion of Control (IoC), promoting loose coupling and testability.

**Key Concepts:**
- Constructor Injection
- Property Injection
- Method Injection
- Service Lifetimes (Transient, Scoped, Singleton)

### Basic Implementation Without DI

```csharp
// ============================================
// 1. WITHOUT DEPENDENCY INJECTION (Tight Coupling)
// ============================================

// Bad example - tight coupling
public class EmailNotificationService
{
    private readonly SmtpClient _smtpClient;

    public EmailNotificationService()
    {
        // ❌ Creating dependency inside the class
        _smtpClient = new SmtpClient("smtp.example.com");
    }

    public void SendNotification(string to, string message)
    {
        _smtpClient.Send(to, message);
    }
}

public class OrderService
{
    private readonly EmailNotificationService _notificationService;

    public OrderService()
    {
        // ❌ Creating dependency inside the class
        _notificationService = new EmailNotificationService();
    }

    public void ProcessOrder(Order order)
    {
        // Process order
        _notificationService.SendNotification(order.CustomerEmail, "Order processed");
    }
}

// Problems:
// - Hard to test (cannot mock EmailNotificationService)
// - Tight coupling
// - Cannot change implementation
// - Creates dependencies internally
```

### With Dependency Injection

```csharp
// ============================================
// 2. WITH DEPENDENCY INJECTION (Loose Coupling)
// ============================================

// Interface
public interface INotificationService
{
    void SendNotification(string to, string message);
    Task SendNotificationAsync(string to, string message);
}

// Implementation 1
public class EmailNotificationService : INotificationService
{
    private readonly IEmailClient _emailClient;
    private readonly ILogger<EmailNotificationService> _logger;

    // ✅ Constructor injection
    public EmailNotificationService(
        IEmailClient emailClient,
        ILogger<EmailNotificationService> logger)
    {
        _emailClient = emailClient;
        _logger = logger;
    }

    public void SendNotification(string to, string message)
    {
        _logger.LogInformation("Sending email to {To}", to);
        _emailClient.Send(to, message);
    }

    public async Task SendNotificationAsync(string to, string message)
    {
        _logger.LogInformation("Sending email to {To}", to);
        await _emailClient.SendAsync(to, message);
    }
}

// Implementation 2
public class SmsNotificationService : INotificationService
{
    private readonly ISmsClient _smsClient;
    private readonly ILogger<SmsNotificationService> _logger;

    public SmsNotificationService(
        ISmsClient smsClient,
        ILogger<SmsNotificationService> logger)
    {
        _smsClient = smsClient;
        _logger = logger;
    }

    public void SendNotification(string to, string message)
    {
        _logger.LogInformation("Sending SMS to {To}", to);
        _smsClient.Send(to, message);
    }

    public async Task SendNotificationAsync(string to, string message)
    {
        _logger.LogInformation("Sending SMS to {To}", to);
        await _smsClient.SendAsync(to, message);
    }
}

// Consumer
public class OrderService
{
    private readonly INotificationService _notificationService;
    private readonly IOrderRepository _orderRepository;
    private readonly ILogger<OrderService> _logger;

    // ✅ Dependencies injected via constructor
    public OrderService(
        INotificationService notificationService,
        IOrderRepository orderRepository,
        ILogger<OrderService> logger)
    {
        _notificationService = notificationService;
        _orderRepository = orderRepository;
        _logger = logger;
    }

    public async Task ProcessOrderAsync(Order order)
    {
        _logger.LogInformation("Processing order {OrderId}", order.Id);

        await _orderRepository.AddAsync(order);
        await _orderRepository.SaveChangesAsync();

        await _notificationService.SendNotificationAsync(
            order.CustomerEmail,
            $"Order {order.Id} processed successfully");
    }
}
```

### ASP.NET Core DI Container

```csharp
// ============================================
// 3. ASP.NET CORE DI REGISTRATION
// ============================================

// Program.cs (ASP.NET Core 6+)
var builder = WebApplication.CreateBuilder(args);

// ===== SERVICE LIFETIMES =====

// 1. TRANSIENT - New instance every time
// Use for: Lightweight, stateless services
builder.Services.AddTransient<IEmailClient, SmtpEmailClient>();
builder.Services.AddTransient<IGuidGenerator, GuidGenerator>();

// 2. SCOPED - One instance per HTTP request
// Use for: DbContext, repositories, request-specific services
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<OrderService>();

// 3. SINGLETON - One instance for application lifetime
// Use for: Configuration, caching, thread-safe services
builder.Services.AddSingleton<IMemoryCache, MemoryCache>();
builder.Services.AddSingleton<ICacheService, CacheService>();

// ===== REGISTRATION METHODS =====

// Register with implementation type
builder.Services.AddScoped<INotificationService, EmailNotificationService>();

// Register with factory method
builder.Services.AddScoped<INotificationService>(provider =>
{
    var logger = provider.GetRequiredService<ILogger<EmailNotificationService>>();
    var emailClient = provider.GetRequiredService<IEmailClient>();
    return new EmailNotificationService(emailClient, logger);
});

// Register with instance
var config = new AppConfiguration { ApiKey = "12345" };
builder.Services.AddSingleton(config);

// Register multiple implementations
builder.Services.AddScoped<INotificationService, EmailNotificationService>();
builder.Services.AddScoped<INotificationService, SmsNotificationService>();

// TryAdd - only registers if not already registered
builder.Services.TryAddScoped<INotificationService, EmailNotificationService>();

// TryAddEnumerable - for multiple implementations
builder.Services.TryAddEnumerable(
    ServiceDescriptor.Scoped<INotificationService, EmailNotificationService>());

var app = builder.Build();
```

### Service Lifetime Examples

```csharp
// ============================================
// 4. SERVICE LIFETIME DEMONSTRATION
// ============================================

// Transient service
public interface IGuidGenerator
{
    Guid Generate();
    Guid InstanceId { get; }
}

public class GuidGenerator : IGuidGenerator
{
    public Guid InstanceId { get; } = Guid.NewGuid();

    public Guid Generate() => Guid.NewGuid();
}

// Scoped service
public class RequestContext
{
    public Guid RequestId { get; } = Guid.NewGuid();
    public DateTime RequestTime { get; } = DateTime.UtcNow;
}

// Singleton service
public class AppSettings
{
    public string ApplicationName { get; set; }
    public string Version { get; set; }
}

// Controller demonstrating lifetimes
[ApiController]
[Route("api/[controller]")]
public class LifetimeController : ControllerBase
{
    private readonly IGuidGenerator _transient1;
    private readonly IGuidGenerator _transient2;
    private readonly RequestContext _scoped1;
    private readonly RequestContext _scoped2;
    private readonly AppSettings _singleton1;
    private readonly AppSettings _singleton2;

    public LifetimeController(
        [FromServices] IEnumerable<IGuidGenerator> transients,
        RequestContext scoped1,
        [FromServices] RequestContext scoped2,
        AppSettings singleton1,
        [FromServices] AppSettings singleton2)
    {
        var transientList = transients.ToList();
        _transient1 = transientList[0];
        _transient2 = transientList[1];
        _scoped1 = scoped1;
        _scoped2 = scoped2;
        _singleton1 = singleton1;
        _singleton2 = singleton2;
    }

    [HttpGet("lifetimes")]
    public IActionResult GetLifetimes()
    {
        return Ok(new
        {
            Transient = new
            {
                Instance1 = _transient1.InstanceId,
                Instance2 = _transient2.InstanceId,
                AreSame = _transient1.InstanceId == _transient2.InstanceId  // false
            },
            Scoped = new
            {
                Instance1 = _scoped1.RequestId,
                Instance2 = _scoped2.RequestId,
                AreSame = _scoped1.RequestId == _scoped2.RequestId  // true
            },
            Singleton = new
            {
                Instance1 = _singleton1.ApplicationName,
                Instance2 = _singleton2.ApplicationName,
                AreSame = ReferenceEquals(_singleton1, _singleton2)  // true
            }
        });
    }
}
```

### Advanced DI Patterns

```csharp
// ============================================
// 5. ADVANCED DI PATTERNS
// ============================================

// Named/Keyed Services (ASP.NET Core 8+)
builder.Services.AddKeyedScoped<INotificationService, EmailNotificationService>("email");
builder.Services.AddKeyedScoped<INotificationService, SmsNotificationService>("sms");
builder.Services.AddKeyedScoped<INotificationService, PushNotificationService>("push");

public class NotificationOrchestrator
{
    private readonly INotificationService _emailService;
    private readonly INotificationService _smsService;

    public NotificationOrchestrator(
        [FromKeyedServices("email")] INotificationService emailService,
        [FromKeyedServices("sms")] INotificationService smsService)
    {
        _emailService = emailService;
        _smsService = smsService;
    }
}

// Factory Pattern with DI
public interface INotificationServiceFactory
{
    INotificationService Create(string type);
}

public class NotificationServiceFactory : INotificationServiceFactory
{
    private readonly IServiceProvider _serviceProvider;

    public NotificationServiceFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public INotificationService Create(string type)
    {
        return type.ToLower() switch
        {
            "email" => _serviceProvider.GetKeyedService<INotificationService>("email"),
            "sms" => _serviceProvider.GetKeyedService<INotificationService>("sms"),
            "push" => _serviceProvider.GetKeyedService<INotificationService>("push"),
            _ => throw new ArgumentException($"Unknown notification type: {type}")
        };
    }
}

// Decorator Pattern with DI
public class LoggingNotificationDecorator : INotificationService
{
    private readonly INotificationService _inner;
    private readonly ILogger<LoggingNotificationDecorator> _logger;

    public LoggingNotificationDecorator(
        INotificationService inner,
        ILogger<LoggingNotificationDecorator> logger)
    {
        _inner = inner;
        _logger = logger;
    }

    public void SendNotification(string to, string message)
    {
        _logger.LogInformation("Sending notification to {To}", to);
        try
        {
            _inner.SendNotification(to, message);
            _logger.LogInformation("Notification sent successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification");
            throw;
        }
    }

    public async Task SendNotificationAsync(string to, string message)
    {
        _logger.LogInformation("Sending notification to {To}", to);
        try
        {
            await _inner.SendNotificationAsync(to, message);
            _logger.LogInformation("Notification sent successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification");
            throw;
        }
    }
}

// Register decorator
builder.Services.AddScoped<EmailNotificationService>();
builder.Services.AddScoped<INotificationService>(provider =>
{
    var emailService = provider.GetRequiredService<EmailNotificationService>();
    var logger = provider.GetRequiredService<ILogger<LoggingNotificationDecorator>>();
    return new LoggingNotificationDecorator(emailService, logger);
});

// Options Pattern with DI
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int Port { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
}

// appsettings.json
/*
{
  "EmailSettings": {
    "SmtpServer": "smtp.example.com",
    "Port": 587,
    "Username": "user@example.com",
    "Password": "password"
  }
}
*/

// Registration
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// Usage
public class EmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> settings,
        ILogger<EmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public void SendEmail(string to, string message)
    {
        _logger.LogInformation(
            "Connecting to SMTP server {Server}:{Port}",
            _settings.SmtpServer,
            _settings.Port);
        // Send email logic
    }
}

// IServiceScopeFactory for background services
public class BackgroundOrderProcessor : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<BackgroundOrderProcessor> _logger;

    public BackgroundOrderProcessor(
        IServiceScopeFactory scopeFactory,
        ILogger<BackgroundOrderProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // Create a scope for each iteration
            using var scope = _scopeFactory.CreateScope();

            var orderService = scope.ServiceProvider.GetRequiredService<OrderService>();
            await orderService.ProcessPendingOrdersAsync();

            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }
}
```

### Testing with DI

```csharp
// ============================================
// 6. UNIT TESTING WITH DI
// ============================================

public class OrderServiceTests
{
    [Fact]
    public async Task ProcessOrder_SendsNotification()
    {
        // Arrange
        var mockNotificationService = new Mock<INotificationService>();
        var mockRepository = new Mock<IOrderRepository>();
        var mockLogger = new Mock<ILogger<OrderService>>();

        var orderService = new OrderService(
            mockNotificationService.Object,
            mockRepository.Object,
            mockLogger.Object);

        var order = new Order
        {
            Id = 1,
            CustomerEmail = "customer@example.com"
        };

        // Act
        await orderService.ProcessOrderAsync(order);

        // Assert
        mockNotificationService.Verify(
            x => x.SendNotificationAsync(
                "customer@example.com",
                It.Is<string>(msg => msg.Contains("Order 1"))),
            Times.Once);

        mockRepository.Verify(
            x => x.AddAsync(order),
            Times.Once);
    }
}

// Integration testing with WebApplicationFactory
public class OrdersControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public OrdersControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace real services with test doubles
                services.RemoveAll<INotificationService>();
                services.AddScoped<INotificationService, FakeNotificationService>();
            });
        });
    }

    [Fact]
    public async Task CreateOrder_ReturnsSuccess()
    {
        var client = _factory.CreateClient();

        var order = new Order { CustomerEmail = "test@example.com" };
        var response = await client.PostAsJsonAsync("/api/orders", order);

        response.EnsureSuccessStatusCode();
    }
}
```

---

### Best Practices

```csharp
// 1. ✅ Prefer constructor injection
public class Service
{
    private readonly IDependency _dependency;

    public Service(IDependency dependency)  // ✅
    {
        _dependency = dependency;
    }
}

// 2. ❌ Avoid service locator anti-pattern
public class Service
{
    public void DoWork(IServiceProvider provider)  // ❌
    {
        var dependency = provider.GetService<IDependency>();
    }
}

// 3. ✅ Use the correct lifetime
// Transient: Stateless, lightweight
// Scoped: Per-request, DbContext
// Singleton: Thread-safe, configuration

// 4. ✅ Validate dependencies
public Service(IDependency dependency)
{
    _dependency = dependency ?? throw new ArgumentNullException(nameof(dependency));
}

// 5. ❌ Don't inject Scoped into Singleton
// This creates a captive dependency
builder.Services.AddSingleton<MySingleton>();  // ❌ If it depends on scoped service
builder.Services.AddScoped<MyScoped>();

// 6. ✅ Use IOptions<T> for configuration
public Service(IOptions<MySettings> options)  // ✅

// 7. ✅ Dispose properly handled by DI container
// No need to implement IDisposable unless you have unmanaged resources

// 8. ✅ Use IServiceScopeFactory in background services
// Required to create scoped services in singleton context

// 9. ✅ Keep constructors simple
// Don't do work in constructors, just assign dependencies

// 10. ✅ Register interfaces, not implementations
builder.Services.AddScoped<IService, ServiceImpl>();  // ✅
builder.Services.AddScoped<ServiceImpl>();  // ❌ Less flexible
```

---

## Q251: What is the CQRS (Command Query Responsibility Segregation) pattern? When and how would you implement it in .NET?

### Answer

**CQRS (Command Query Responsibility Segregation)** separates read and write operations into different models. Commands modify state, Queries return data. This separation allows independent scaling and optimization of reads vs writes.

**Key Concepts:**
- Commands: Change state, don't return data
- Queries: Return data, don't change state
- Separate models for reading and writing
- Event sourcing (optional)

### Basic CQRS Implementation

```csharp
// ============================================
// 1. BASIC CQRS PATTERN
// ============================================

// Command (writes) - modifies state
public class CreateProductCommand
{
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int CategoryId { get; set; }
}

public class UpdateProductCommand
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public class DeleteProductCommand
{
    public int Id { get; set; }
}

// Query (reads) - returns data
public class GetProductByIdQuery
{
    public int Id { get; set; }
}

public class GetProductsQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string SearchTerm { get; set; }
}

// Command Handler
public interface ICommandHandler<in TCommand>
{
    Task HandleAsync(TCommand command);
}

public class CreateProductCommandHandler : ICommandHandler<CreateProductCommand>
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CreateProductCommandHandler> _logger;

    public CreateProductCommandHandler(
        ApplicationDbContext context,
        ILogger<CreateProductCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task HandleAsync(CreateProductCommand command)
    {
        var product = new Product
        {
            Name = command.Name,
            Price = command.Price,
            CategoryId = command.CategoryId
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Product created: {ProductId}", product.Id);
    }
}

// Query Handler
public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query);
}

public class GetProductByIdQueryHandler : IQueryHandler<GetProductByIdQuery, ProductDto>
{
    private readonly ApplicationDbContext _context;

    public GetProductByIdQueryHandler(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ProductDto> HandleAsync(GetProductByIdQuery query)
    {
        return await _context.Products
            .Where(p => p.Id == query.Id)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                CategoryName = p.Category.Name
            })
            .FirstOrDefaultAsync();
    }
}

// DTOs for queries
public class ProductDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string CategoryName { get; set; }
}

// Controller
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ICommandHandler<CreateProductCommand> _createProductHandler;
    private readonly IQueryHandler<GetProductByIdQuery, ProductDto> _getProductHandler;

    public ProductsController(
        ICommandHandler<CreateProductCommand> createProductHandler,
        IQueryHandler<GetProductByIdQuery, ProductDto> getProductHandler)
    {
        _createProductHandler = createProductHandler;
        _getProductHandler = getProductHandler;
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct(CreateProductCommand command)
    {
        await _createProductHandler.HandleAsync(command);
        return Ok();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(int id)
    {
        var product = await _getProductHandler.HandleAsync(new GetProductByIdQuery { Id = id });

        if (product == null)
            return NotFound();

        return Ok(product);
    }
}
```

### CQRS with MediatR

```csharp
// ============================================
// 2. CQRS WITH MEDIATR
// ============================================

// Install-Package MediatR

// Command
public class CreateOrderCommand : IRequest<int>
{
    public int CustomerId { get; set; }
    public List<OrderItemDto> Items { get; set; }
}

public class OrderItemDto
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
}

// Command Handler
public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, int>
{
    private readonly ApplicationDbContext _context;
    private readonly IMediator _mediator;

    public CreateOrderCommandHandler(
        ApplicationDbContext context,
        IMediator mediator)
    {
        _context = context;
        _mediator = mediator;
    }

    public async Task<int> Handle(CreateOrderCommand request, CancellationToken cancellationToken)
    {
        var order = new Order
        {
            CustomerId = request.CustomerId,
            OrderDate = DateTime.UtcNow,
            Status = "Pending"
        };

        foreach (var item in request.Items)
        {
            var product = await _context.Products.FindAsync(item.ProductId);

            order.Items.Add(new OrderItem
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                UnitPrice = product.Price
            });
        }

        order.TotalAmount = order.Items.Sum(i => i.Quantity * i.UnitPrice);

        _context.Orders.Add(order);
        await _context.SaveChangesAsync(cancellationToken);

        // Publish domain event
        await _mediator.Publish(new OrderCreatedEvent { OrderId = order.Id }, cancellationToken);

        return order.Id;
    }
}

// Query
public class GetOrderByIdQuery : IRequest<OrderDetailDto>
{
    public int OrderId { get; set; }
}

public class OrderDetailDto
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; }
    public List<OrderItemDetailDto> Items { get; set; }
}

public class OrderItemDetailDto
{
    public int ProductId { get; set; }
    public string ProductName { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
}

// Query Handler
public class GetOrderByIdQueryHandler : IRequestHandler<GetOrderByIdQuery, OrderDetailDto>
{
    private readonly ApplicationDbContext _context;

    public GetOrderByIdQueryHandler(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<OrderDetailDto> Handle(GetOrderByIdQuery request, CancellationToken cancellationToken)
    {
        return await _context.Orders
            .Where(o => o.Id == request.OrderId)
            .Select(o => new OrderDetailDto
            {
                Id = o.Id,
                CustomerId = o.CustomerId,
                CustomerName = o.Customer.Name,
                OrderDate = o.OrderDate,
                TotalAmount = o.TotalAmount,
                Status = o.Status,
                Items = o.Items.Select(i => new OrderItemDetailDto
                {
                    ProductId = i.ProductId,
                    ProductName = i.Product.Name,
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice,
                    TotalPrice = i.Quantity * i.UnitPrice
                }).ToList()
            })
            .FirstOrDefaultAsync(cancellationToken);
    }
}

// Domain Event
public class OrderCreatedEvent : INotification
{
    public int OrderId { get; set; }
}

// Event Handler
public class OrderCreatedEventHandler : INotificationHandler<OrderCreatedEvent>
{
    private readonly ILogger<OrderCreatedEventHandler> _logger;
    private readonly IEmailService _emailService;

    public OrderCreatedEventHandler(
        ILogger<OrderCreatedEventHandler> logger,
        IEmailService emailService)
    {
        _logger = logger;
        _emailService = emailService;
    }

    public async Task Handle(OrderCreatedEvent notification, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Order created: {OrderId}", notification.OrderId);

        // Send confirmation email
        await _emailService.SendOrderConfirmationAsync(notification.OrderId);
    }
}

// Controller
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IMediator _mediator;

    public OrdersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<ActionResult<int>> CreateOrder(CreateOrderCommand command)
    {
        var orderId = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetOrder), new { id = orderId }, orderId);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDetailDto>> GetOrder(int id)
    {
        var order = await _mediator.Send(new GetOrderByIdQuery { OrderId = id });

        if (order == null)
            return NotFound();

        return Ok(order);
    }
}

// DI Registration
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(Program).Assembly));
```

### CQRS with Separate Read/Write Databases

```csharp
// ============================================
// 3. CQRS WITH SEPARATE DATABASES
// ============================================

// Write Model (Command Side)
public class WriteDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }

    public WriteDbContext(DbContextOptions<WriteDbContext> options) : base(options)
    {
    }
}

// Read Model (Query Side) - Denormalized for performance
public class ReadDbContext : DbContext
{
    public DbSet<ProductReadModel> Products { get; set; }
    public DbSet<OrderReadModel> Orders { get; set; }

    public ReadDbContext(DbContextOptions<ReadDbContext> options) : base(options)
    {
    }
}

// Read Models - Optimized for queries
public class ProductReadModel
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string CategoryName { get; set; }
    public int StockQuantity { get; set; }
    public DateTime LastUpdated { get; set; }
}

public class OrderReadModel
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; }
    public string CustomerEmail { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; }
    public int ItemCount { get; set; }
    public string ItemsSummary { get; set; }  // Denormalized
}

// Command Handler - Writes to write DB
public class CreateProductCommandHandler : IRequestHandler<CreateProductCommand, int>
{
    private readonly WriteDbContext _writeDb;
    private readonly IMediator _mediator;

    public CreateProductCommandHandler(WriteDbContext writeDb, IMediator mediator)
    {
        _writeDb = writeDb;
        _mediator = mediator;
    }

    public async Task<int> Handle(CreateProductCommand request, CancellationToken cancellationToken)
    {
        var product = new Product
        {
            Name = request.Name,
            Price = request.Price,
            CategoryId = request.CategoryId
        };

        _writeDb.Products.Add(product);
        await _writeDb.SaveChangesAsync(cancellationToken);

        // Publish event to update read model
        await _mediator.Publish(new ProductCreatedEvent
        {
            ProductId = product.Id,
            Name = product.Name,
            Price = product.Price,
            CategoryId = product.CategoryId
        }, cancellationToken);

        return product.Id;
    }
}

// Event Handler - Updates read model
public class ProductCreatedEventHandler : INotificationHandler<ProductCreatedEvent>
{
    private readonly ReadDbContext _readDb;
    private readonly WriteDbContext _writeDb;

    public ProductCreatedEventHandler(ReadDbContext readDb, WriteDbContext writeDb)
    {
        _readDb = readDb;
        _writeDb = writeDb;
    }

    public async Task Handle(ProductCreatedEvent notification, CancellationToken cancellationToken)
    {
        // Fetch additional data from write model
        var category = await _writeDb.Categories.FindAsync(notification.CategoryId);

        // Update read model
        var readModel = new ProductReadModel
        {
            Id = notification.ProductId,
            Name = notification.Name,
            Price = notification.Price,
            CategoryName = category.Name,
            StockQuantity = 0,
            LastUpdated = DateTime.UtcNow
        };

        _readDb.Products.Add(readModel);
        await _readDb.SaveChangesAsync(cancellationToken);
    }
}

// Query Handler - Reads from read DB
public class GetProductsQueryHandler : IRequestHandler<GetProductsQuery, List<ProductReadModel>>
{
    private readonly ReadDbContext _readDb;

    public GetProductsQueryHandler(ReadDbContext readDb)
    {
        _readDb = readDb;
    }

    public async Task<List<ProductReadModel>> Handle(GetProductsQuery request, CancellationToken cancellationToken)
    {
        var query = _readDb.Products.AsQueryable();

        if (!string.IsNullOrEmpty(request.SearchTerm))
        {
            query = query.Where(p => p.Name.Contains(request.SearchTerm) ||
                                      p.CategoryName.Contains(request.SearchTerm));
        }

        return await query
            .OrderBy(p => p.Name)
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync(cancellationToken);
    }
}

// DI Registration
builder.Services.AddDbContext<WriteDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("WriteDb")));

builder.Services.AddDbContext<ReadDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ReadDb")));
```

### Validation and Pipeline Behaviors

```csharp
// ============================================
// 4. VALIDATION WITH FLUENT VALIDATION
// ============================================

// Install-Package FluentValidation
// Install-Package FluentValidation.DependencyInjectionExtensions

// Validator
public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .GreaterThan(0)
            .WithMessage("Customer ID must be provided");

        RuleFor(x => x.Items)
            .NotEmpty()
            .WithMessage("Order must contain at least one item");

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(x => x.ProductId)
                .GreaterThan(0);

            item.RuleFor(x => x.Quantity)
                .GreaterThan(0)
                .WithMessage("Quantity must be greater than 0");
        });
    }
}

// Validation Pipeline Behavior
public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (!_validators.Any())
        {
            return await next();
        }

        var context = new ValidationContext<TRequest>(request);

        var validationResults = await Task.WhenAll(
            _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

        var failures = validationResults
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Any())
        {
            throw new ValidationException(failures);
        }

        return await next();
    }
}

// Logging Pipeline Behavior
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling {RequestName}", typeof(TRequest).Name);

        var stopwatch = Stopwatch.StartNew();

        try
        {
            var response = await next();

            stopwatch.Stop();
            _logger.LogInformation(
                "Handled {RequestName} in {ElapsedMs}ms",
                typeof(TRequest).Name,
                stopwatch.ElapsedMilliseconds);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling {RequestName}", typeof(TRequest).Name);
            throw;
        }
    }
}

// DI Registration
builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly);
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
});
```

---

### Best Practices

```csharp
// 1. ✅ Commands don't return data (except ID for created entities)
public class CreateOrderCommand : IRequest<int>  // ✅ Returns ID only
{
}

// 2. ✅ Queries don't modify state
public class GetOrderQuery : IRequest<OrderDto>  // ✅ Read-only
{
}

// 3. ✅ Use DTOs for queries, not domain entities
public class ProductDto  // ✅ Optimized for client needs
{
    public int Id { get; set; }
    public string Name { get; set; }
}

// 4. ✅ Validate commands, not queries
// Commands change state, so validate them
// Queries just return data

// 5. ✅ Use MediatR for clean architecture
// Decouples controllers from handlers

// 6. ⚠️ Consider eventual consistency
// With separate read/write models, there may be a delay

// 7. ✅ Use read models for complex queries
// Denormalize data for performance

// 8. ✅ CQRS is beneficial when:
// - Different read/write scalability needs
// - Complex domain logic
// - Different optimization strategies
// - Event sourcing

// 9. ❌ Don't use CQRS for simple CRUD apps
// Overhead not worth it for basic operations

// 10. ✅ Combine with other patterns
// - Event Sourcing
// - Domain Events
// - Repository Pattern
// - Unit of Work
```

---

## Q252: Explain the Template Method pattern. How is it different from Strategy pattern?

### Answer

The **Template Method Pattern** defines the skeleton of an algorithm in a base class, allowing subclasses to override specific steps without changing the algorithm's structure.

**Key Concepts:**
- Abstract base class defines template
- Subclasses implement specific steps
- Algorithm structure is fixed
- Uses inheritance

### Basic Implementation

```csharp
// ============================================
// 1. TEMPLATE METHOD PATTERN
// ============================================

// Abstract class with template method
public abstract class DataImporter
{
    // Template method - defines algorithm skeleton
    public void Import(string filePath)
    {
        Console.WriteLine("Starting import process...");

        var data = ReadFile(filePath);
        ValidateData(data);
        var processedData = ProcessData(data);
        SaveData(processedData);
        NotifyCompletion();

        Console.WriteLine("Import completed.");
    }

    // Concrete method
    private void NotifyCompletion()
    {
        Console.WriteLine("✅ Data import completed successfully");
    }

    // Abstract methods - subclasses must implement
    protected abstract string ReadFile(string filePath);
    protected abstract void ValidateData(string data);
    protected abstract object ProcessData(string data);
    protected abstract void SaveData(object data);
}

// Concrete implementation 1
public class CsvDataImporter : DataImporter
{
    protected override string ReadFile(string filePath)
    {
        Console.WriteLine($"Reading CSV file: {filePath}");
        return "csv,data,here";
    }

    protected override void ValidateData(string data)
    {
        Console.WriteLine("Validating CSV format");
        if (string.IsNullOrEmpty(data))
        {
            throw new InvalidDataException("CSV data is empty");
        }
    }

    protected override object ProcessData(string data)
    {
        Console.WriteLine("Processing CSV data");
        var rows = data.Split('\n');
        return rows;
    }

    protected override void SaveData(object data)
    {
        Console.WriteLine($"Saving {((string[])data).Length} CSV rows to database");
    }
}

// Concrete implementation 2
public class JsonDataImporter : DataImporter
{
    protected override string ReadFile(string filePath)
    {
        Console.WriteLine($"Reading JSON file: {filePath}");
        return "{\"data\": \"value\"}";
    }

    protected override void ValidateData(string data)
    {
        Console.WriteLine("Validating JSON format");
        // Validate JSON structure
    }

    protected override object ProcessData(string data)
    {
        Console.WriteLine("Parsing JSON data");
        return JsonSerializer.Deserialize<Dictionary<string, object>>(data);
    }

    protected override void SaveData(object data)
    {
        Console.WriteLine("Saving JSON data to database");
    }
}

// Usage
DataImporter csvImporter = new CsvDataImporter();
csvImporter.Import("data.csv");

DataImporter jsonImporter = new JsonDataImporter();
jsonImporter.Import("data.json");
```

### Template Method vs Strategy Pattern

```csharp
// ============================================
// 2. COMPARISON: TEMPLATE METHOD VS STRATEGY
// ============================================

// TEMPLATE METHOD - Uses inheritance, fixed algorithm structure
public abstract class PaymentProcessor
{
    public void ProcessPayment(decimal amount)
    {
        ValidateAmount(amount);
        DeductAmount(amount);
        RecordTransaction(amount);
        SendConfirmation();
    }

    private void ValidateAmount(decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be positive");
    }

    // Subclasses override this
    protected abstract void DeductAmount(decimal amount);

    private void RecordTransaction(decimal amount)
    {
        Console.WriteLine($"Recording transaction: ${amount}");
    }

    private void SendConfirmation()
    {
        Console.WriteLine("Confirmation sent");
    }
}

public class CreditCardProcessor : PaymentProcessor
{
    protected override void DeductAmount(decimal amount)
    {
        Console.WriteLine($"Charging credit card: ${amount}");
    }
}

// STRATEGY - Uses composition, flexible algorithm selection
public interface IPaymentStrategy
{
    void Pay(decimal amount);
}

public class CreditCardStrategy : IPaymentStrategy
{
    public void Pay(decimal amount)
    {
        Console.WriteLine($"Charging credit card: ${amount}");
    }
}

public class PaymentContext
{
    private IPaymentStrategy _strategy;

    public void SetStrategy(IPaymentStrategy strategy)
    {
        _strategy = strategy;
    }

    public void ProcessPayment(decimal amount)
    {
        // Can change strategy at runtime
        _strategy.Pay(amount);
    }
}
```

### Best Practices

```csharp
// 1. ✅ Use Template Method when:
// - Algorithm structure should be fixed
// - Subclasses share common behavior
// - Control flow is defined by parent

// 2. ✅ Use Strategy when:
// - Need to switch algorithms at runtime
// - Want composition over inheritance
// - Multiple independent variations

// 3. ✅ Use hooks for optional steps
public abstract class BaseProcessor
{
    public void Process()
    {
        PreProcess();
        DoProcess();
        PostProcess();
    }

    protected virtual void PreProcess() { }  // Hook - optional
    protected abstract void DoProcess();      // Required
    protected virtual void PostProcess() { }  // Hook - optional
}
```

---

## Q253: What is the Command Pattern? How would you implement it for undo/redo functionality?

### Answer

The **Command Pattern** encapsulates a request as an object, allowing you to parameterize clients with different requests, queue requests, and support undoable operations.

**Key Concepts:**
- Encapsulate requests as objects
- Decouple invoker from receiver
- Support undo/redo
- Command queuing

### Basic Implementation

```csharp
// ============================================
// 1. COMMAND PATTERN - BASIC
// ============================================

// Command interface
public interface ICommand
{
    void Execute();
    void Undo();
}

// Receiver
public class TextEditor
{
    public StringBuilder Content { get; } = new StringBuilder();

    public void InsertText(string text, int position)
    {
        Content.Insert(position, text);
        Console.WriteLine($"Inserted: '{text}' at position {position}");
    }

    public void DeleteText(int position, int length)
    {
        Content.Remove(position, length);
        Console.WriteLine($"Deleted {length} characters at position {position}");
    }

    public string GetText() => Content.ToString();
}

// Concrete Commands
public class InsertTextCommand : ICommand
{
    private readonly TextEditor _editor;
    private readonly string _text;
    private readonly int _position;

    public InsertTextCommand(TextEditor editor, string text, int position)
    {
        _editor = editor;
        _text = text;
        _position = position;
    }

    public void Execute()
    {
        _editor.InsertText(_text, _position);
    }

    public void Undo()
    {
        _editor.DeleteText(_position, _text.Length);
    }
}

public class DeleteTextCommand : ICommand
{
    private readonly TextEditor _editor;
    private readonly int _position;
    private readonly int _length;
    private string _deletedText;

    public DeleteTextCommand(TextEditor editor, int position, int length)
    {
        _editor = editor;
        _position = position;
        _length = length;
    }

    public void Execute()
    {
        _deletedText = _editor.Content.ToString(_position, _length);
        _editor.DeleteText(_position, _length);
    }

    public void Undo()
    {
        _editor.InsertText(_deletedText, _position);
    }
}

// Invoker
public class CommandManager
{
    private readonly Stack<ICommand> _undoStack = new();
    private readonly Stack<ICommand> _redoStack = new();

    public void ExecuteCommand(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear(); // Clear redo stack on new command
    }

    public void Undo()
    {
        if (_undoStack.Count == 0)
        {
            Console.WriteLine("Nothing to undo");
            return;
        }

        var command = _undoStack.Pop();
        command.Undo();
        _redoStack.Push(command);
    }

    public void Redo()
    {
        if (_redoStack.Count == 0)
        {
            Console.WriteLine("Nothing to redo");
            return;
        }

        var command = _redoStack.Pop();
        command.Execute();
        _undoStack.Push(command);
    }
}

// Usage
var editor = new TextEditor();
var commandManager = new CommandManager();

commandManager.ExecuteCommand(new InsertTextCommand(editor, "Hello", 0));
commandManager.ExecuteCommand(new InsertTextCommand(editor, " World", 5));
Console.WriteLine($"Text: {editor.GetText()}");

commandManager.Undo();
Console.WriteLine($"After undo: {editor.GetText()}");

commandManager.Redo();
Console.WriteLine($"After redo: {editor.GetText()}");
```

### Best Practices

```csharp
// 1. ✅ Commands should be immutable
// Store all necessary state during construction

// 2. ✅ Use for undo/redo functionality
// Keep command history in stacks

// 3. ✅ Use for queuing operations
// Background processing, task scheduling

// 4. ✅ Use with CQRS pattern
// Commands represent state changes
```

---

## Q254: What is the Proxy Pattern? Provide examples of different proxy types in C#.

### Answer

The **Proxy Pattern** provides a surrogate or placeholder for another object to control access to it.

**Types:**
- Virtual Proxy (lazy loading)
- Protection Proxy (access control)
- Remote Proxy (remote objects)
- Caching Proxy (cache results)

### Implementation

```csharp
// ============================================
// 1. VIRTUAL PROXY (Lazy Loading)
// ============================================

public interface IImage
{
    void Display();
}

public class RealImage : IImage
{
    private readonly string _filename;

    public RealImage(string filename)
    {
        _filename = filename;
        LoadFromDisk();
    }

    private void LoadFromDisk()
    {
        Console.WriteLine($"Loading image from disk: {_filename}");
        Thread.Sleep(1000); // Simulate expensive operation
    }

    public void Display()
    {
        Console.WriteLine($"Displaying {_filename}");
    }
}

public class ImageProxy : IImage
{
    private RealImage _realImage;
    private readonly string _filename;

    public ImageProxy(string filename)
    {
        _filename = filename;
    }

    public void Display()
    {
        // Lazy initialization
        if (_realImage == null)
        {
            _realImage = new RealImage(_filename);
        }

        _realImage.Display();
    }
}

// Usage
IImage image = new ImageProxy("large-image.jpg");
// Image not loaded yet

image.Display();  // Loads and displays
image.Display();  // Just displays (already loaded)
```

### Best Practices

```csharp
// 1. ✅ Virtual Proxy for lazy loading
// 2. ✅ Protection Proxy for access control
// 3. ✅ Caching Proxy for performance
// 4. ✅ .NET examples: Lazy<T>, EF Core lazy loading
```

---

## Q255: Explain the Facade Pattern. How does it simplify complex subsystems?

### Answer

The **Facade Pattern** provides a unified, simplified interface to a complex subsystem.

### Implementation

```csharp
// ============================================
// FACADE PATTERN
// ============================================

// Complex subsystem classes
public class PaymentProcessor
{
    public bool ProcessPayment(decimal amount) => true;
}

public class InventorySystem
{
    public bool CheckStock(int productId) => true;
    public void ReserveItem(int productId) { }
}

public class ShippingService
{
    public void ArrangeShipping(string address) { }
}

// Facade
public class OrderFacade
{
    private readonly PaymentProcessor _payment = new();
    private readonly InventorySystem _inventory = new();
    private readonly ShippingService _shipping = new();

    public bool PlaceOrder(int productId, decimal amount, string address)
    {
        if (!_inventory.CheckStock(productId))
            return false;

        if (!_payment.ProcessPayment(amount))
            return false;

        _inventory.ReserveItem(productId);
        _shipping.ArrangeShipping(address);

        return true;
    }
}

// Simple usage
var orderFacade = new OrderFacade();
orderFacade.PlaceOrder(123, 99.99m, "123 Main St");
```

---

## Q256: What is the Composite Pattern? When would you use it?

### Answer

The **Composite Pattern** composes objects into tree structures to represent part-whole hierarchies.

### Implementation

```csharp
// ============================================
// COMPOSITE PATTERN
// ============================================

public interface IFileSystemItem
{
    string Name { get; }
    long GetSize();
    void Display(int depth = 0);
}

public class File : IFileSystemItem
{
    public string Name { get; }
    private long _size;

    public File(string name, long size)
    {
        Name = name;
        _size = size;
    }

    public long GetSize() => _size;

    public void Display(int depth = 0)
    {
        Console.WriteLine($"{new string(' ', depth)}- {Name} ({_size} bytes)");
    }
}

public class Directory : IFileSystemItem
{
    public string Name { get; }
    private List<IFileSystemItem> _items = new();

    public Directory(string name) => Name = name;

    public void Add(IFileSystemItem item) => _items.Add(item);

    public long GetSize() => _items.Sum(item => item.GetSize());

    public void Display(int depth = 0)
    {
        Console.WriteLine($"{new string(' ', depth)}+ {Name}/");
        foreach (var item in _items)
        {
            item.Display(depth + 2);
        }
    }
}

// Usage
var root = new Directory("root");
root.Add(new File("file1.txt", 100));

var subDir = new Directory("docs");
subDir.Add(new File("doc1.pdf", 500));
root.Add(subDir);

root.Display();
Console.WriteLine($"Total size: {root.GetSize()} bytes");
```

---

## Q257: Explain the Chain of Responsibility pattern and its use cases.

### Answer

The **Chain of Responsibility** pattern passes requests along a chain of handlers until one handles it.

### Implementation

```csharp
// ============================================
// CHAIN OF RESPONSIBILITY
// ============================================

public abstract class ExpenseApprover
{
    protected ExpenseApprover _nextApprover;

    public void SetNext(ExpenseApprover nextApprover)
    {
        _nextApprover = nextApprover;
    }

    public abstract void ApproveExpense(decimal amount);
}

public class Manager : ExpenseApprover
{
    public override void ApproveExpense(decimal amount)
    {
        if (amount <= 1000)
            Console.WriteLine($"Manager approved ${amount}");
        else
            _nextApprover?.ApproveExpense(amount);
    }
}

public class Director : ExpenseApprover
{
    public override void ApproveExpense(decimal amount)
    {
        if (amount <= 5000)
            Console.WriteLine($"Director approved ${amount}");
        else
            _nextApprover?.ApproveExpense(amount);
    }
}

public class CEO : ExpenseApprover
{
    public override void ApproveExpense(decimal amount)
    {
        Console.WriteLine($"CEO approved ${amount}");
    }
}

// Usage
var manager = new Manager();
var director = new Director();
var ceo = new CEO();

manager.SetNext(director);
director.SetNext(ceo);

manager.ApproveExpense(500);   // Manager approves
manager.ApproveExpense(3000);  // Director approves
manager.ApproveExpense(10000); // CEO approves
```

---

## Q258: What is the Mediator Pattern? How does it reduce coupling?

### Answer

The **Mediator Pattern** defines an object that encapsulates how a set of objects interact, promoting loose coupling.

### Implementation

```csharp
// ============================================
// MEDIATOR PATTERN
// ============================================

public interface IChatMediator
{
    void SendMessage(string message, User user);
    void AddUser(User user);
}

public class ChatRoom : IChatMediator
{
    private List<User> _users = new();

    public void AddUser(User user)
    {
        _users.Add(user);
    }

    public void SendMessage(string message, User sender)
    {
        foreach (var user in _users.Where(u => u != sender))
        {
            user.Receive(message, sender);
        }
    }
}

public class User
{
    private IChatMediator _mediator;
    public string Name { get; }

    public User(string name, IChatMediator mediator)
    {
        Name = name;
        _mediator = mediator;
    }

    public void Send(string message)
    {
        Console.WriteLine($"{Name} sends: {message}");
        _mediator.SendMessage(message, this);
    }

    public void Receive(string message, User sender)
    {
        Console.WriteLine($"{Name} received from {sender.Name}: {message}");
    }
}

// Usage
var chatRoom = new ChatRoom();
var user1 = new User("Alice", chatRoom);
var user2 = new User("Bob", chatRoom);

chatRoom.AddUser(user1);
chatRoom.AddUser(user2);

user1.Send("Hello!");
```

---

## Q259: Explain the State Pattern and when to use it.

### Answer

The **State Pattern** allows an object to alter its behavior when its internal state changes.

### Implementation

```csharp
// ============================================
// STATE PATTERN
// ============================================

public interface IOrderState
{
    void Process(Order order);
    void Cancel(Order order);
}

public class Order
{
    public IOrderState State { get; set; }

    public Order()
    {
        State = new PendingState();
    }

    public void Process() => State.Process(this);
    public void Cancel() => State.Cancel(this);
}

public class PendingState : IOrderState
{
    public void Process(Order order)
    {
        Console.WriteLine("Processing order...");
        order.State = new ProcessingState();
    }

    public void Cancel(Order order)
    {
        Console.WriteLine("Order cancelled");
        order.State = new CancelledState();
    }
}

public class ProcessingState : IOrderState
{
    public void Process(Order order)
    {
        Console.WriteLine("Shipping order...");
        order.State = new ShippedState();
    }

    public void Cancel(Order order)
    {
        Console.WriteLine("Cannot cancel processing order");
    }
}

public class ShippedState : IOrderState
{
    public void Process(Order order)
    {
        Console.WriteLine("Order already shipped");
    }

    public void Cancel(Order order)
    {
        Console.WriteLine("Cannot cancel shipped order");
    }
}

public class CancelledState : IOrderState
{
    public void Process(Order order)
    {
        Console.WriteLine("Cannot process cancelled order");
    }

    public void Cancel(Order order)
    {
        Console.WriteLine("Order already cancelled");
    }
}

// Usage
var order = new Order();
order.Process();  // Pending -> Processing
order.Process();  // Processing -> Shipped
order.Cancel();   // Cannot cancel shipped order
```

---

## Q260: What is the Specification Pattern? How does it work with repositories?

### Answer

The **Specification Pattern** encapsulates business rules and query logic into reusable, combinable objects.

### Implementation

```csharp
// ============================================
// SPECIFICATION PATTERN
// ============================================

public interface ISpecification<T>
{
    bool IsSatisfiedBy(T entity);
    Expression<Func<T, bool>> ToExpression();
}

public class ProductInStockSpecification : ISpecification<Product>
{
    public bool IsSatisfiedBy(Product entity) => entity.StockQuantity > 0;

    public Expression<Func<Product, bool>> ToExpression() => p => p.StockQuantity > 0;
}

public class ProductInPriceRangeSpecification : ISpecification<Product>
{
    private readonly decimal _minPrice;
    private readonly decimal _maxPrice;

    public ProductInPriceRangeSpecification(decimal minPrice, decimal maxPrice)
    {
        _minPrice = minPrice;
        _maxPrice = maxPrice;
    }

    public bool IsSatisfiedBy(Product entity) =>
        entity.Price >= _minPrice && entity.Price <= _maxPrice;

    public Expression<Func<Product, bool>> ToExpression() =>
        p => p.Price >= _minPrice && p.Price <= _maxPrice;
}

// Combining specifications
public class AndSpecification<T> : ISpecification<T>
{
    private readonly ISpecification<T> _left;
    private readonly ISpecification<T> _right;

    public AndSpecification(ISpecification<T> left, ISpecification<T> right)
    {
        _left = left;
        _right = right;
    }

    public bool IsSatisfiedBy(T entity) =>
        _left.IsSatisfiedBy(entity) && _right.IsSatisfiedBy(entity);

    public Expression<Func<T, bool>> ToExpression()
    {
        var leftExpr = _left.ToExpression();
        var rightExpr = _right.ToExpression();

        var param = Expression.Parameter(typeof(T));
        var combined = Expression.AndAlso(
            Expression.Invoke(leftExpr, param),
            Expression.Invoke(rightExpr, param));

        return Expression.Lambda<Func<T, bool>>(combined, param);
    }
}

// Usage with repository
public class ProductRepository
{
    private readonly DbContext _context;

    public async Task<List<Product>> FindAsync(ISpecification<Product> spec)
    {
        return await _context.Set<Product>()
            .Where(spec.ToExpression())
            .ToListAsync();
    }
}

// Usage
var inStock = new ProductInStockSpecification();
var affordablePrice = new ProductInPriceRangeSpecification(10, 100);
var affordableAndInStock = new AndSpecification<Product>(inStock, affordablePrice);

var products = await repository.FindAsync(affordableAndInStock);
```

### Best Practices

```csharp
// 1. ✅ Use for complex business rules
// 2. ✅ Make specifications composable (AND, OR, NOT)
// 3. ✅ Keep specifications focused on single responsibility
// 4. ✅ Use with Repository pattern for queries
```

---

**End of Design Patterns Q&A (Q241-Q260)**

---
