### Q21: What is the difference between abstract class and interface?

**Abstract Class:**
- Can have implementation (concrete methods)
- Can have fields and constants
- Can have constructors
- Supports access modifiers (public, private, protected)
- Single inheritance only
- Use `abstract` keyword

**Interface:**
- Contract definition (before C# 8)
- C# 8+: Can have default implementations
- Cannot have fields (only properties)
- No constructors
- All members public by default
- Multiple inheritance supported
- Use `interface` keyword

**Example:**
```csharp
// ============ ABSTRACT CLASS ============

public abstract class Vehicle
{
    // Fields
    private string _vin;
    protected int _year;

    // Constructor
    public Vehicle(string vin, int year)
    {
        _vin = vin;
        _year = year;
    }

    // Properties
    public string VIN => _vin;
    public int Year => _year;

    // Abstract method - must be implemented
    public abstract void Start();

    // Concrete method - can be inherited as-is
    public void DisplayInfo()
    {
        Console.WriteLine($"VIN: {VIN}, Year: {Year}");
    }

    // Virtual method - can be overridden
    public virtual void Stop()
    {
        Console.WriteLine("Vehicle stopped");
    }
}

public class Car : Vehicle
{
    public Car(string vin, int year) : base(vin, year)
    {
    }

    // Must implement abstract method
    public override void Start()
    {
        Console.WriteLine("Car engine started");
    }

    // Optional override
    public override void Stop()
    {
        base.Stop();
        Console.WriteLine("Car parked");
    }
}

// ============ INTERFACE ============

public interface IVehicle
{
    // Properties (no backing field)
    string VIN { get; }
    int Year { get; }

    // Methods (no implementation in C# < 8)
    void Start();
    void Stop();

    // C# 8+ Default implementation
    void DisplayInfo()
    {
        Console.WriteLine($"VIN: {VIN}, Year: {Year}");
    }
}

public interface IDrivable
{
    void Accelerate();
    void Brake();
    int CurrentSpeed { get; }
}

// Can implement multiple interfaces
public class ModernCar : IVehicle, IDrivable
{
    public string VIN { get; }
    public int Year { get; }
    public int CurrentSpeed { get; private set; }

    public ModernCar(string vin, int year)
    {
        VIN = vin;
        Year = year;
    }

    public void Start()
    {
        Console.WriteLine("Engine started");
    }

    public void Stop()
    {
        Console.WriteLine("Engine stopped");
        CurrentSpeed = 0;
    }

    public void Accelerate()
    {
        CurrentSpeed += 10;
        Console.WriteLine($"Speed: {CurrentSpeed} mph");
    }

    public void Brake()
    {
        CurrentSpeed = Math.Max(0, CurrentSpeed - 10);
        Console.WriteLine($"Speed: {CurrentSpeed} mph");
    }
}

// ============ COMPARISON TABLE ============
```

| Feature | Abstract Class | Interface |
|---------|---------------|-----------|
| Implementation | Can have | No (C# < 8), Yes (C# 8+) |
| Fields | Yes | No |
| Constructors | Yes | No |
| Access Modifiers | All (public, private, etc.) | Public only |
| Multiple Inheritance | No (single) | Yes |
| Static Members | Yes | Yes (C# 8+) |
| When to Use | IS-A relationship | CAN-DO capability |

---

### Q22: When would you use an abstract class vs an interface?

**Use Abstract Class When:**
- Share code among related classes
- Need fields or constructors
- Need non-public members
- IS-A relationship (inheritance hierarchy)
- Need to provide base implementation

**Use Interface When:**
- Unrelated classes need same capability
- Multiple inheritance required
- Define contract/capability
- CAN-DO relationship
- Plugin architecture

**Example:**
```csharp
// ============ ABSTRACT CLASS: SHARED BEHAVIOR ============

// Use abstract class for related entities with shared logic
public abstract class Employee
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal BaseSalary { get; set; }

    // Shared logic
    public void ClockIn()
    {
        Console.WriteLine($"{Name} clocked in at {DateTime.Now}");
    }

    // Each type calculates differently
    public abstract decimal CalculateBonus();

    // Template method pattern
    public decimal GetTotalCompensation()
    {
        return BaseSalary + CalculateBonus();
    }
}

public class Manager : Employee
{
    public int TeamSize { get; set; }

    public override decimal CalculateBonus()
    {
        return BaseSalary * 0.20m * TeamSize;
    }
}

public class Developer : Employee
{
    public int ProjectsCompleted { get; set; }

    public override decimal CalculateBonus()
    {
        return 1000m * ProjectsCompleted;
    }
}

// ============ INTERFACE: CAPABILITIES ============

// Use interfaces for capabilities that unrelated classes can have
public interface IEmailable
{
    string EmailAddress { get; }
    void SendEmail(string subject, string body);
}

public interface IReportable
{
    string GenerateReport();
}

public interface IApprovable
{
    bool IsApproved { get; set; }
    void Approve();
    void Reject();
}

// Different entities can have same capabilities
public class Customer : IEmailable
{
    public string Name { get; set; }
    public string EmailAddress { get; set; }

    public void SendEmail(string subject, string body)
    {
        Console.WriteLine($"Sending to customer {EmailAddress}: {subject}");
    }
}

public class Invoice : IEmailable, IReportable, IApprovable
{
    public string EmailAddress { get; set; }
    public bool IsApproved { get; set; }

    public void SendEmail(string subject, string body)
    {
        Console.WriteLine($"Sending invoice to {EmailAddress}");
    }

    public string GenerateReport()
    {
        return "Invoice Report: ...";
    }

    public void Approve()
    {
        IsApproved = true;
        Console.WriteLine("Invoice approved");
    }

    public void Reject()
    {
        IsApproved = false;
        Console.WriteLine("Invoice rejected");
    }
}

// ============ COMBINED APPROACH ============

// Abstract class for hierarchy + interfaces for capabilities
public abstract class Document : IReportable, IApprovable
{
    public int Id { get; set; }
    public string Title { get; set; }
    public DateTime CreatedDate { get; set; }
    public bool IsApproved { get; set; }

    // Shared implementation
    protected void LogAction(string action)
    {
        Console.WriteLine($"[{DateTime.Now}] {action} on {Title}");
    }

    // Abstract - each document type differs
    public abstract string GenerateReport();

    // Concrete - all documents approve same way
    public virtual void Approve()
    {
        IsApproved = true;
        LogAction("Approved");
    }

    public virtual void Reject()
    {
        IsApproved = false;
        LogAction("Rejected");
    }
}

public class PurchaseOrder : Document
{
    public decimal Amount { get; set; }

    public override string GenerateReport()
    {
        return $"PO Report: {Title} - ${Amount}";
    }
}

public class Contract : Document
{
    public DateTime ExpirationDate { get; set; }

    public override string GenerateReport()
    {
        return $"Contract Report: {Title} - Expires {ExpirationDate:yyyy-MM-dd}";
    }
}
```

**Decision Tree:**
```
Need to share code/state?
├─ Yes → Consider Abstract Class
│  └─ Single inheritance OK? → Abstract Class
│
└─ No → Consider Interface
   └─ Multiple "capabilities" needed? → Interface

IS-A relationship? → Abstract Class
CAN-DO capability? → Interface
```

---

### Q23: Explain the sealed keyword. When would you use it?

**Sealed Keyword:**
- Prevents inheritance from class
- Prevents overriding of method
- Slight performance benefit (compiler optimization)
- Security/design enforcement
- Applied to classes and methods

**Example:**
```csharp
// ============ SEALED CLASS ============

// Cannot be inherited
public sealed class FinalImplementation
{
    public void DoSomething()
    {
        Console.WriteLine("Final implementation");
    }
}

// This will cause compilation error:
// public class Derived : FinalImplementation { }  // ERROR!

// ============ SEALED METHODS ============

public class BaseClass
{
    public virtual void Method1()
    {
        Console.WriteLine("Base Method1");
    }

    public virtual void Method2()
    {
        Console.WriteLine("Base Method2");
    }
}

public class MiddleClass : BaseClass
{
    // Override and seal - prevents further overriding
    public sealed override void Method1()
    {
        Console.WriteLine("Middle Method1 - sealed");
    }

    // Regular override - can be overridden again
    public override void Method2()
    {
        Console.WriteLine("Middle Method2");
    }
}

public class DerivedClass : MiddleClass
{
    // Cannot override Method1 - it's sealed
    // public override void Method1() { }  // ERROR!

    // Can override Method2 - not sealed
    public override void Method2()
    {
        Console.WriteLine("Derived Method2");
    }
}

// ============ REAL-WORLD USES ============

// 1. String class is sealed
// public sealed class String { ... }
// Prevents breaking core functionality

// 2. Value types are implicitly sealed
public struct Point  // Cannot inherit from struct
{
    public int X { get; set; }
    public int Y { get; set; }
}

// 3. Security-sensitive class
public sealed class CryptoHelper
{
    private readonly string _secretKey;

    public CryptoHelper(string key)
    {
        _secretKey = key;
    }

    public string Encrypt(string data)
    {
        // Encryption logic
        // Sealed to prevent malicious override
        return Convert.ToBase64String(
            System.Text.Encoding.UTF8.GetBytes(data + _secretKey));
    }
}

// 4. Complete implementation
public sealed class ConfigurationManager
{
    private static readonly Lazy<ConfigurationManager> _instance =
        new Lazy<ConfigurationManager>(() => new ConfigurationManager());

    private Dictionary<string, string> _settings;

    private ConfigurationManager()
    {
        _settings = LoadSettings();
    }

    public static ConfigurationManager Instance => _instance.Value;

    public string Get(string key)
    {
        return _settings.TryGetValue(key, out var value) ? value : null;
    }

    private Dictionary<string, string> LoadSettings()
    {
        return new Dictionary<string, string>
        {
            ["ApiUrl"] = "https://api.example.com",
            ["Timeout"] = "30"
        };
    }
}

// ============ PERFORMANCE BENEFIT ============

public class PerformanceTest
{
    public virtual void VirtualMethod() { }  // Virtual dispatch
}

public sealed class SealedPerformanceTest
{
    public void NonVirtualMethod() { }  // Direct call (slightly faster)
}

// Compiler can optimize sealed class methods
// because it knows they won't be overridden
```

**When to Use Sealed:**

✅ **Use When:**
- Prevent inheritance (design decision)
- Security-sensitive code
- Performance-critical code
- Complete, final implementation
- Singleton pattern
- Value-like semantics with classes

❌ **Don't Use When:**
- Need extensibility
- Library code (limits users)
- Testing needs mocking/substitution
- Unsure about future needs

---

### Q24: What are partial classes? What are their use cases?

**Partial Classes:**
- Split class definition across multiple files
- All parts combined at compile time
- Same namespace and assembly
- Keyword: `partial`
- Works with classes, struct

s, interfaces

**Example:**
```csharp
// ============ BASIC PARTIAL CLASS ============

// File: Person.cs
public partial class Person
{
    public int Id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
}

// File: Person.Methods.cs
public partial class Person
{
    public string GetFullName()
    {
        return $"{FirstName} {LastName}";
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"ID: {Id}, Name: {GetFullName()}");
    }
}

// Usage - compiler combines both files
var person = new Person
{
    Id = 1,
    FirstName = "John",
    LastName = "Doe"
};
person.DisplayInfo();

// ============ USE CASE 1: GENERATED CODE ============

// File: MyForm.Designer.cs (generated by designer)
public partial class MyForm : Form
{
    private Button button1;
    private TextBox textBox1;

    // This method is auto-generated
    private void InitializeComponent()
    {
        this.button1 = new Button();
        this.textBox1 = new TextBox();
        // ... designer generated code
    }
}

// File: MyForm.cs (your code)
public partial class MyForm : Form
{
    public MyForm()
    {
        InitializeComponent();
    }

    // Your custom logic
    private void button1_Click(object sender, EventArgs e)
    {
        textBox1.Text = "Button clicked!";
    }
}

// ============ USE CASE 2: SEPARATION OF CONCERNS ============

// File: Product.Properties.cs
public partial class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
}

// File: Product.Business.cs
public partial class Product
{
    public decimal GetDiscountedPrice(decimal discountPercent)
    {
        return Price * (1 - discountPercent / 100);
    }

    public bool IsAvailable()
    {
        return Stock > 0;
    }

    public void UpdateStock(int quantity)
    {
        Stock += quantity;
    }
}

// File: Product.Validation.cs
public partial class Product
{
    public bool IsValid()
    {
        return !string.IsNullOrEmpty(Name)
            && Price > 0
            && Stock >= 0;
    }

    public List<string> GetValidationErrors()
    {
        var errors = new List<string>();

        if (string.IsNullOrEmpty(Name))
            errors.Add("Name is required");

        if (Price <= 0)
            errors.Add("Price must be greater than 0");

        if (Stock < 0)
            errors.Add("Stock cannot be negative");

        return errors;
    }
}

// ============ USE CASE 3: ENTITY FRAMEWORK ============

// File: ApplicationDbContext.Generated.cs (auto-generated)
public partial class ApplicationDbContext : DbContext
{
    public DbSet<User> Users { get; set; }
    public DbSet<Order> Orders { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Generated configuration
    }
}

// File: ApplicationDbContext.cs (custom code)
public partial class ApplicationDbContext
{
    // Custom methods
    public List<User> GetActiveUsers()
    {
        return Users.Where(u => u.IsActive).ToList();
    }

    public void SeedData()
    {
        // Custom seeding logic
    }
}

// ============ USE CASE 4: LARGE CLASS ORGANIZATION ============

// File: OrderService.Core.cs
public partial class OrderService
{
    private readonly IOrderRepository _orderRepo;
    private readonly IPaymentService _paymentService;

    public OrderService(IOrderRepository orderRepo, IPaymentService paymentService)
    {
        _orderRepo = orderRepo;
        _paymentService = paymentService;
    }
}

// File: OrderService.Creation.cs
public partial class OrderService
{
    public Order CreateOrder(int customerId, List<OrderItem> items)
    {
        var order = new Order
        {
            CustomerId = customerId,
            Items = items,
            CreatedDate = DateTime.Now
        };

        return _orderRepo.Add(order);
    }

    public bool ValidateOrder(Order order)
    {
        return order.Items.Count > 0 && order.CustomerId > 0;
    }
}

// File: OrderService.Processing.cs
public partial class OrderService
{
    public void ProcessOrder(int orderId)
    {
        var order = _orderRepo.GetById(orderId);
        if (order == null) return;

        ProcessPayment(order);
        UpdateInventory(order);
        SendConfirmation(order);
    }

    private void ProcessPayment(Order order)
    {
        _paymentService.Charge(order.CustomerId, order.Total);
    }

    private void UpdateInventory(Order order)
    {
        // Update stock
    }

    private void SendConfirmation(Order order)
    {
        // Send email
    }
}

// File: OrderService.Reporting.cs
public partial class OrderService
{
    public OrderReport GenerateReport(DateTime from, DateTime to)
    {
        var orders = _orderRepo.GetByDateRange(from, to);

        return new OrderReport
        {
            TotalOrders = orders.Count,
            TotalRevenue = orders.Sum(o => o.Total),
            AverageOrderValue = orders.Average(o => o.Total)
        };
    }
}

// ============ PARTIAL METHODS ============

public partial class Customer
{
    // Partial method declaration (no implementation)
    partial void OnNameChanging(string value);

    private string _name;
    public string Name
    {
        get => _name;
        set
        {
            OnNameChanging(value);  // Called if implemented
            _name = value;
        }
    }
}

// Optional implementation in another file
public partial class Customer
{
    partial void OnNameChanging(string value)
    {
        // Validation logic
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Name cannot be empty");

        Console.WriteLine($"Name changing to: {value}");
    }
}
```

**Benefits:**
- Separate generated and custom code
- Team collaboration (different developers)
- Organize large classes
- Separation of concerns
- Tool/designer integration

**Limitations:**
- Must be in same assembly
- Must have same accessibility
- All parts must use `partial` keyword
- Cannot span different base classes

---

### Q25: Explain the static keyword and static constructors.

**Static Keyword:**
- Belongs to type, not instance
- Shared across all instances
- Accessed via class name
- Cannot access instance members
- Memory allocated once

**Static Constructor:**
- Initializes static members
- Called automatically before first use
- No access modifiers
- No parameters
- Called only once per AppDomain

**Example:**
```csharp
// ============ STATIC MEMBERS ============

public class Counter
{
    // Instance field - each object has its own
    private int _instanceCount = 0;

    // Static field - shared across all instances
    private static int _totalCount = 0;

    public Counter()
    {
        _totalCount++;
    }

    public void Increment()
    {
        _instanceCount++;
        _totalCount++;
    }

    public void Display()
    {
        Console.WriteLine($"Instance: {_instanceCount}, Total: {_totalCount}");
    }

    // Static method
    public static int GetTotalCount()
    {
        // Can only access static members
        return _totalCount;
        // return _instanceCount;  // ERROR - cannot access instance member
    }
}

// Usage
var c1 = new Counter();
c1.Increment();  // Instance: 1, Total: 1

var c2 = new Counter();
c2.Increment();  // Instance: 1, Total: 2

Console.WriteLine(Counter.GetTotalCount());  // 2

// ============ STATIC CONSTRUCTOR ============

public class Configuration
{
    // Static fields
    public static string ApiUrl { get; private set; }
    public static int Timeout { get; private set; }
    public static DateTime LoadedAt { get; private set; }

    // Static constructor - no access modifier, no parameters
    static Configuration()
    {
        Console.WriteLine("Static constructor called");

        // Initialize static members
        ApiUrl = LoadFromConfig("ApiUrl");
        Timeout = int.Parse(LoadFromConfig("Timeout"));
        LoadedAt = DateTime.Now;
    }

    private static string LoadFromConfig(string key)
    {
        // Load from config file
        return key == "ApiUrl" ? "https://api.example.com" : "30";
    }

    // Regular constructor
    public Configuration()
    {
        Console.WriteLine("Instance constructor called");
    }
}

// First access triggers static constructor
Console.WriteLine(Configuration.ApiUrl);  // Static constructor runs once
Console.WriteLine(Configuration.Timeout);  // Not called again

var config1 = new Configuration();  // Instance constructor
var config2 = new Configuration();  // Instance constructor

// ============ STATIC CLASS ============

public static class MathHelper
{
    // Cannot instantiate static class
    // var helper = new MathHelper();  // ERROR

    // All members must be static
    public static double Pi => 3.14159;

    public static int Add(int a, int b)
    {
        return a + b;
    }

    public static double CircleArea(double radius)
    {
        return Pi * radius * radius;
    }
}

// Usage
int sum = MathHelper.Add(5, 3);
double area = MathHelper.CircleArea(10);

// ============ SINGLETON PATTERN ============

public sealed class Singleton
{
    // Static instance
    private static readonly Lazy<Singleton> _instance =
        new Lazy<Singleton>(() => new Singleton());

    // Private constructor prevents external instantiation
    private Singleton()
    {
        Console.WriteLine("Singleton created");
        // Initialize
    }

    // Public static property to access instance
    public static Singleton Instance => _instance.Value;

    public void DoSomething()
    {
        Console.WriteLine("Singleton method called");
    }
}

// Usage
Singleton.Instance.DoSomething();  // Creates on first access
Singleton.Instance.DoSomething();  // Uses existing instance

// ============ STATIC CONSTRUCTOR TIMING ============

public class InitializationDemo
{
    static InitializationDemo()
    {
        Console.WriteLine("1. Static constructor");
    }

    public InitializationDemo()
    {
        Console.WriteLine("3. Instance constructor");
    }

    public static void StaticMethod()
    {
        Console.WriteLine("2. Static method");
    }
}

// Execution order
InitializationDemo.StaticMethod();  // Triggers: 1, 2
var obj = new InitializationDemo();  // Triggers: 3

// ============ REAL-WORLD EXAMPLES ============

// Logger with static configuration
public class Logger
{
    private static string _logPath;
    private static LogLevel _minLevel;

    static Logger()
    {
        _logPath = Environment.GetEnvironmentVariable("LOG_PATH")
            ?? "C:\\Logs\\app.log";
        _minLevel = LogLevel.Info;

        Console.WriteLine($"Logger initialized: {_logPath}");
    }

    public static void Log(string message, LogLevel level = LogLevel.Info)
    {
        if (level >= _minLevel)
        {
            File.AppendAllText(_logPath,
                $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{level}] {message}\n");
        }
    }
}

public enum LogLevel
{
    Debug,
    Info,
    Warning,
    Error
}

// Usage
Logger.Log("Application started");
Logger.Log("An error occurred", LogLevel.Error);

// Connection pool
public class ConnectionPool
{
    private static readonly List<DbConnection> _connections;
    private static readonly int _poolSize = 10;

    static ConnectionPool()
    {
        _connections = new List<DbConnection>();

        for (int i = 0; i < _poolSize; i++)
        {
            _connections.Add(CreateConnection());
        }

        Console.WriteLine($"Connection pool initialized with {_poolSize} connections");
    }

    private static DbConnection CreateConnection()
    {
        // Create and return connection
        return new DbConnection();
    }

    public static DbConnection GetConnection()
    {
        return _connections.FirstOrDefault(c => c.IsAvailable);
    }
}
```

**Key Points:**
- Static constructor runs once per type
- Called before first static member access or instance creation
- Cannot be called directly
- No guaranteed order for multiple static constructors
- Exception in static constructor makes type unusable

**When to Use:**
- Utility classes (Math, File operations)
- Configuration loading
- Singleton pattern
- Extension methods (must be in static class)
- Constants and shared data

---

(Continuing with Q26-Q30 in next batch...)
