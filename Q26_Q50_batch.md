### Q26: What is the difference between const and readonly?

**const:**
- Compile-time constant
- Value must be known at compile time
- Implicitly static
- Cannot be changed
- Better performance (inlined)

**readonly:**
- Runtime constant
- Can be initialized in constructor
- Can be instance or static
- Value set once at runtime
- More flexible

**Example:**
```csharp
public class ConstVsReadonly
{
    // const - compile-time constant
    public const int MaxRetries = 3;
    public const string ApiVersion = "v1";
    // public const DateTime Today = DateTime.Now;  // ERROR! Not compile-time constant

    // readonly - runtime constant
    public readonly int UserId;
    public readonly DateTime CreatedAt;
    public static readonly string ConnectionString;

    // Static constructor for static readonly
    static ConstVsReadonly()
    {
        ConnectionString = LoadFromConfig();
    }

    // Instance constructor for instance readonly
    public ConstVsReadonly(int userId)
    {
        UserId = userId;
        CreatedAt = DateTime.Now;  // Runtime value
    }

    private static string LoadFromConfig()
    {
        return "Server=localhost;Database=MyDb;";
    }

    public void Example()
    {
        // const - accessed directly (no instance needed)
        Console.WriteLine(MaxRetries);

        // readonly - can be different per instance
        Console.WriteLine(UserId);
    }
}

// ============ WHEN TO USE ============

public class Configuration
{
    // const - truly constant values
    public const int MinPasswordLength = 8;
    public const int MaxPasswordLength = 128;
    public const string ApplicationName = "MyApp";

    // readonly - values determined at runtime
    public readonly Guid InstanceId;
    public readonly string Environment;
    public static readonly string MachineName;

    static Configuration()
    {
        MachineName = System.Environment.MachineName;
    }

    public Configuration(string environment)
    {
        InstanceId = Guid.NewGuid();
        Environment = environment;
    }
}

// ============ CONST INLINING ============

// Assembly 1
public class Library
{
    public const int Version = 1;
}

// Assembly 2
public class Client
{
    public void UseLibrary()
    {
        Console.WriteLine(Library.Version);  // Value "1" is inlined here
    }
}

// If you rebuild Assembly 1 with Version = 2,
// Assembly 2 still uses "1" until recompiled!

// Solution: Use readonly for values that might change
public class Library2
{
    public static readonly int Version = 1;  // Not inlined
}

// ============ COMPARISON TABLE ============
```

| Feature | const | readonly |
|---------|-------|----------|
| When set | Compile-time | Runtime |
| Where initialized | Declaration only | Declaration or constructor |
| Static/Instance | Always static | Can be either |
| Type | Value types, strings | Any type |
| Performance | Faster (inlined) | Slight overhead |
| Flexibility | Less | More |
| Versioning | Can cause issues | Safer |

---

### Q27: Explain the volatile keyword in C#.

**Volatile Keyword:**
- Prevents compiler/CPU optimizations
- Ensures latest value is read from memory
- Thread-safety hint (not guarantee)
- Used in multithreading scenarios
- No reordering of reads/writes

**Example:**
```csharp
// ============ WITHOUT VOLATILE ============

public class NonVolatileExample
{
    private bool _stopRequested = false;

    public void WorkerThread()
    {
        while (!_stopRequested)  // May be cached in CPU register
        {
            // Do work
            Console.Write(".");
        }
        Console.WriteLine("\nWorker stopped");
    }

    public void RequestStop()
    {
        _stopRequested = true;  // May not be visible to WorkerThread immediately
    }
}

// Problem: WorkerThread might never see _stopRequested = true
// because compiler/CPU optimized it to a register read

// ============ WITH VOLATILE ============

public class VolatileExample
{
    private volatile bool _stopRequested = false;

    public void WorkerThread()
    {
        while (!_stopRequested)  // Always reads from memory
        {
            // Do work
            Console.Write(".");
        }
        Console.WriteLine("\nWorker stopped");
    }

    public void RequestStop()
    {
        _stopRequested = true;  // Immediately visible to all threads
    }
}

// ============ REAL-WORLD EXAMPLE ============

public class DataProcessor
{
    private volatile bool _isRunning = false;
    private volatile bool _isPaused = false;
    private int _processedCount = 0;  // Not volatile - needs lock

    public void Start()
    {
        _isRunning = true;

        Task.Run(() =>
        {
            while (_isRunning)
            {
                if (!_isPaused)
                {
                    ProcessItem();
                    Interlocked.Increment(ref _processedCount);  // Thread-safe
                }
                Thread.Sleep(10);
            }
        });
    }

    public void Pause()
    {
        _isPaused = true;
    }

    public void Resume()
    {
        _isPaused = false;
    }

    public void Stop()
    {
        _isRunning = false;
    }

    private void ProcessItem()
    {
        Console.Write(".");
    }

    public int GetProcessedCount()
    {
        return _processedCount;
    }
}

// ============ VOLATILE VS LOCK ============

public class VolatileVsLock
{
    // Volatile - simple flags
    private volatile bool _flag = false;

    public void SetFlag()
    {
        _flag = true;  // Thread-safe for simple assignment
    }

    // Lock - complex operations
    private readonly object _lock = new object();
    private int _counter = 0;

    public void IncrementCounter()
    {
        lock (_lock)
        {
            _counter++;  // Read-modify-write needs lock
        }
    }
}

// ============ WHEN TO USE ============

// ✅ Good use cases for volatile:
// - Simple boolean flags
// - Status indicators
// - Stop/pause signals
// - Single-writer, multiple-reader scenarios

// ❌ Don't use volatile for:
// - Compound operations (++, --, +=)
// - Operations needing atomicity
// - Complex state changes
// - General thread safety

// ============ LIMITATIONS ============

public class VolatileLimitations
{
    private volatile int _value = 0;

    public void Increment()
    {
        _value++;  // NOT thread-safe!
        // Equivalent to:
        // int temp = _value;  // Read
        // temp = temp + 1;    // Modify
        // _value = temp;      // Write
        // Another thread can modify between read and write
    }

    // Solution: Use Interlocked or lock
    public void ThreadSafeIncrement()
    {
        Interlocked.Increment(ref _value);
    }
}

// ============ DOUBLE-CHECKED LOCKING ============

public sealed class Singleton
{
    private static volatile Singleton _instance;
    private static readonly object _lock = new object();

    private Singleton() { }

    public static Singleton Instance
    {
        get
        {
            if (_instance == null)  // First check (no lock)
            {
                lock (_lock)
                {
                    if (_instance == null)  // Second check (with lock)
                    {
                        _instance = new Singleton();
                    }
                }
            }
            return _instance;
        }
    }
}
```

**Key Points:**
- Volatile prevents caching in CPU registers
- Does NOT provide atomicity for compound operations
- Use for simple flags/status in multithreading
- Consider `Interlocked`, `lock`, or `async/await` for complex scenarios

---

### Q28: What are indexers in C#?

**Indexers:**
- Allow objects to be indexed like arrays
- Use `this` keyword with square brackets
- Can have multiple parameters
- Can be overloaded
- Similar to properties with parameters

**Example:**
```csharp
// ============ BASIC INDEXER ============

public class SampleCollection
{
    private string[] _items = new string[10];

    // Indexer
    public string this[int index]
    {
        get
        {
            if (index < 0 || index >= _items.Length)
                throw new IndexOutOfRangeException();
            return _items[index];
        }
        set
        {
            if (index < 0 || index >= _items.Length)
                throw new IndexOutOfRangeException();
            _items[index] = value;
        }
    }
}

// Usage
var collection = new SampleCollection();
collection[0] = "First";  // Calls setter
collection[1] = "Second";
string item = collection[0];  // Calls getter

// ============ MULTI-PARAMETER INDEXER ============

public class Matrix
{
    private int[,] _data = new int[10, 10];

    // Two-dimensional indexer
    public int this[int row, int col]
    {
        get => _data[row, col];
        set => _data[row, col] = value;
    }
}

// Usage
var matrix = new Matrix();
matrix[0, 0] = 1;
matrix[0, 1] = 2;
int value = matrix[0, 0];

// ============ STRING KEY INDEXER ============

public class PhoneBook
{
    private Dictionary<string, string> _contacts = new();

    // String indexer
    public string this[string name]
    {
        get => _contacts.TryGetValue(name, out var phone) ? phone : null;
        set
        {
            if (value == null)
                _contacts.Remove(name);
            else
                _contacts[name] = value;
        }
    }

    public int Count => _contacts.Count;
}

// Usage
var phoneBook = new PhoneBook();
phoneBook["John"] = "555-1234";
phoneBook["Jane"] = "555-5678";
string johnPhone = phoneBook["John"];

// ============ READ-ONLY INDEXER ============

public class ReadOnlyCollection
{
    private List<string> _items = new();

    public ReadOnlyCollection(IEnumerable<string> items)
    {
        _items.AddRange(items);
    }

    // Read-only indexer (no setter)
    public string this[int index]
    {
        get
        {
            if (index < 0 || index >= _items.Count)
                throw new IndexOutOfRangeException();
            return _items[index];
        }
    }

    public int Count => _items.Count;
}

// ============ REAL-WORLD EXAMPLES ============

// Configuration manager
public class AppSettings
{
    private Dictionary<string, string> _settings = new();

    public AppSettings()
    {
        LoadSettings();
    }

    public string this[string key]
    {
        get => _settings.TryGetValue(key, out var value) ? value : null;
    }

    private void LoadSettings()
    {
        _settings["ApiUrl"] = "https://api.example.com";
        _settings["Timeout"] = "30";
        _settings["MaxRetries"] = "3";
    }
}

// Usage
var settings = new AppSettings();
string apiUrl = settings["ApiUrl"];
int timeout = int.Parse(settings["Timeout"]);

// Database table accessor
public class DataTable
{
    private List<Dictionary<string, object>> _rows = new();

    public object this[int rowIndex, string columnName]
    {
        get
        {
            if (rowIndex < 0 || rowIndex >= _rows.Count)
                throw new IndexOutOfRangeException();

            return _rows[rowIndex].TryGetValue(columnName, out var value)
                ? value
                : null;
        }
        set
        {
            if (rowIndex < 0 || rowIndex >= _rows.Count)
                throw new IndexOutOfRangeException();

            _rows[rowIndex][columnName] = value;
        }
    }

    public void AddRow(Dictionary<string, object> row)
    {
        _rows.Add(row);
    }
}

// Usage
var table = new DataTable();
table.AddRow(new Dictionary<string, object>
{
    ["Id"] = 1,
    ["Name"] = "John",
    ["Age"] = 30
});

string name = table[0, "Name"].ToString();
int age = (int)table[0, "Age"];

// Sparse array
public class SparseArray<T>
{
    private Dictionary<int, T> _storage = new();

    public T this[int index]
    {
        get => _storage.TryGetValue(index, out var value) ? value : default;
        set
        {
            if (EqualityComparer<T>.Default.Equals(value, default))
                _storage.Remove(index);
            else
                _storage[index] = value;
        }
    }

    public int Count => _storage.Count;
}

// Usage - only stores non-default values
var sparseArray = new SparseArray<int>();
sparseArray[0] = 10;
sparseArray[1000] = 20;
sparseArray[1000000] = 30;  // Memory efficient!

// ============ INTERFACE WITH INDEXER ============

public interface IReadOnlyList<T>
{
    T this[int index] { get; }
    int Count { get; }
}

public class MyList<T> : IReadOnlyList<T>
{
    private List<T> _items = new();

    public T this[int index] => _items[index];

    public int Count => _items.Count;

    public void Add(T item) => _items.Add(item);
}
```

**Benefits:**
- Natural array-like syntax
- Encapsulation (validation in get/set)
- Support for different key types
- Multiple indexers with different parameters

---

### Q29: Explain operator overloading with an example.

**Operator Overloading:**
- Define custom behavior for operators
- Makes custom types work with standard operators
- Uses `operator` keyword
- Must be static methods
- At least one parameter must be containing type

**Example:**
```csharp
// ============ BASIC OPERATOR OVERLOADING ============

public class Money
{
    public decimal Amount { get; }
    public string Currency { get; }

    public Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    // Addition operator
    public static Money operator +(Money m1, Money m2)
    {
        if (m1.Currency != m2.Currency)
            throw new InvalidOperationException("Currency mismatch");

        return new Money(m1.Amount + m2.Amount, m1.Currency);
    }

    // Subtraction operator
    public static Money operator -(Money m1, Money m2)
    {
        if (m1.Currency != m2.Currency)
            throw new InvalidOperationException("Currency mismatch");

        return new Money(m1.Amount - m2.Amount, m1.Currency);
    }

    // Multiplication by scalar
    public static Money operator *(Money m, decimal multiplier)
    {
        return new Money(m.Amount * multiplier, m.Currency);
    }

    // Division by scalar
    public static Money operator /(Money m, decimal divisor)
    {
        if (divisor == 0)
            throw new DivideByZeroException();

        return new Money(m.Amount / divisor, m.Currency);
    }

    // Equality operators
    public static bool operator ==(Money m1, Money m2)
    {
        if (ReferenceEquals(m1, m2)) return true;
        if (m1 is null || m2 is null) return false;
        return m1.Amount == m2.Amount && m1.Currency == m2.Currency;
    }

    public static bool operator !=(Money m1, Money m2)
    {
        return !(m1 == m2);
    }

    // Comparison operators
    public static bool operator >(Money m1, Money m2)
    {
        if (m1.Currency != m2.Currency)
            throw new InvalidOperationException("Currency mismatch");
        return m1.Amount > m2.Amount;
    }

    public static bool operator <(Money m1, Money m2)
    {
        if (m1.Currency != m2.Currency)
            throw new InvalidOperationException("Currency mismatch");
        return m1.Amount < m2.Amount;
    }

    public static bool operator >=(Money m1, Money m2)
    {
        return m1 > m2 || m1 == m2;
    }

    public static bool operator <=(Money m1, Money m2)
    {
        return m1 < m2 || m1 == m2;
    }

    // Override Object methods when overloading == and !=
    public override bool Equals(object obj)
    {
        return obj is Money money && this == money;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Amount, Currency);
    }

    public override string ToString()
    {
        return $"{Amount:C} {Currency}";
    }
}

// Usage
var price1 = new Money(100, "USD");
var price2 = new Money(50, "USD");

var total = price1 + price2;        // 150 USD
var difference = price1 - price2;   // 50 USD
var doubled = price1 * 2;           // 200 USD
var half = price1 / 2;              // 50 USD

bool isEqual = price1 == price2;    // false
bool isGreater = price1 > price2;   // true

// ============ VECTOR CLASS ============

public struct Vector2D
{
    public double X { get; }
    public double Y { get; }

    public Vector2D(double x, double y)
    {
        X = x;
        Y = y;
    }

    // Addition
    public static Vector2D operator +(Vector2D v1, Vector2D v2)
    {
        return new Vector2D(v1.X + v2.X, v1.Y + v2.Y);
    }

    // Subtraction
    public static Vector2D operator -(Vector2D v1, Vector2D v2)
    {
        return new Vector2D(v1.X - v2.X, v1.Y - v2.Y);
    }

    // Scalar multiplication
    public static Vector2D operator *(Vector2D v, double scalar)
    {
        return new Vector2D(v.X * scalar, v.Y * scalar);
    }

    public static Vector2D operator *(double scalar, Vector2D v)
    {
        return v * scalar;
    }

    // Negation (unary operator)
    public static Vector2D operator -(Vector2D v)
    {
        return new Vector2D(-v.X, -v.Y);
    }

    // Magnitude
    public double Magnitude => Math.Sqrt(X * X + Y * Y);

    public override string ToString()
    {
        return $"({X}, {Y})";
    }
}

// Usage
var v1 = new Vector2D(3, 4);
var v2 = new Vector2D(1, 2);

var sum = v1 + v2;          // (4, 6)
var diff = v1 - v2;         // (2, 2)
var scaled = v1 * 2;        // (6, 8)
var negated = -v1;          // (-3, -4)

// ============ FRACTION CLASS ============

public class Fraction
{
    public int Numerator { get; }
    public int Denominator { get; }

    public Fraction(int numerator, int denominator)
    {
        if (denominator == 0)
            throw new ArgumentException("Denominator cannot be zero");

        // Simplify
        int gcd = GCD(Math.Abs(numerator), Math.Abs(denominator));
        Numerator = numerator / gcd;
        Denominator = denominator / gcd;

        // Keep denominator positive
        if (Denominator < 0)
        {
            Numerator = -Numerator;
            Denominator = -Denominator;
        }
    }

    private static int GCD(int a, int b)
    {
        while (b != 0)
        {
            int temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }

    public static Fraction operator +(Fraction f1, Fraction f2)
    {
        return new Fraction(
            f1.Numerator * f2.Denominator + f2.Numerator * f1.Denominator,
            f1.Denominator * f2.Denominator
        );
    }

    public static Fraction operator -(Fraction f1, Fraction f2)
    {
        return new Fraction(
            f1.Numerator * f2.Denominator - f2.Numerator * f1.Denominator,
            f1.Denominator * f2.Denominator
        );
    }

    public static Fraction operator *(Fraction f1, Fraction f2)
    {
        return new Fraction(
            f1.Numerator * f2.Numerator,
            f1.Denominator * f2.Denominator
        );
    }

    public static Fraction operator /(Fraction f1, Fraction f2)
    {
        return new Fraction(
            f1.Numerator * f2.Denominator,
            f1.Denominator * f2.Numerator
        );
    }

    // Implicit conversion from int
    public static implicit operator Fraction(int value)
    {
        return new Fraction(value, 1);
    }

    // Explicit conversion to double
    public static explicit operator double(Fraction f)
    {
        return (double)f.Numerator / f.Denominator;
    }

    public override string ToString()
    {
        return Denominator == 1 ? Numerator.ToString() : $"{Numerator}/{Denominator}";
    }
}

// Usage
var f1 = new Fraction(1, 2);    // 1/2
var f2 = new Fraction(1, 3);    // 1/3

var sum = f1 + f2;              // 5/6
var product = f1 * f2;          // 1/6

Fraction f3 = 5;                // Implicit: 5/1
double d = (double)f1;          // Explicit: 0.5

// ============ OVERLOADABLE OPERATORS ============

/*
Unary operators:    +, -, !, ~, ++, --, true, false
Binary operators:   +, -, *, /, %, &, |, ^, <<, >>
Comparison:         ==, !=, <, >, <=, >=
Note: && and || cannot be overloaded directly, but & and | can be
*/
```

**Rules:**
- Must be `public static`
- Return type is usually the containing type
- For ==, also override !=
- For <, also provide >
- For <=, also provide >=
- Override `Equals()` and `GetHashCode()` when overloading ==

---

### Q30: What are anonymous types? When are they useful?

**Anonymous Types:**
- Compiler-generated types
- Read-only properties
- No explicit type name
- Created using `new { }` syntax
- Useful for LINQ projections
- Local scope only

**Example:**
```csharp
// ============ BASIC ANONYMOUS TYPE ============

public void BasicAnonymousType()
{
    // Compiler generates a class with Name and Age properties
    var person = new { Name = "John", Age = 30 };

    Console.WriteLine($"Name: {person.Name}, Age: {person.Age}");

    // Properties are read-only
    // person.Name = "Jane";  // ERROR - cannot modify

    // Type is anonymous - cannot declare explicitly
    // SomeType person2 = new { Name = "Jane", Age = 25 };  // ERROR
}

// ============ LINQ PROJECTIONS ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
    public int Stock { get; set; }
}

public void LinqProjections()
{
    var products = new List<Product>
    {
        new Product { Id = 1, Name = "Laptop", Price = 999, Category = "Electronics", Stock = 10 },
        new Product { Id = 2, Name = "Mouse", Price = 25, Category = "Electronics", Stock = 50 },
        new Product { Id = 3, Name = "Desk", Price = 299, Category = "Furniture", Stock = 5 }
    };

    // Project to anonymous type
    var productSummary = products
        .Select(p => new
        {
            p.Name,
            p.Price,
            IsExpensive = p.Price > 100,
            Status = p.Stock > 0 ? "In Stock" : "Out of Stock"
        })
        .ToList();

    foreach (var item in productSummary)
    {
        Console.WriteLine($"{item.Name}: ${item.Price} - {item.Status}");
    }
}

// ============ GROUPING WITH ANONYMOUS TYPES ============

public void GroupingExample()
{
    var products = GetProducts();

    // Group by category and calculate stats
    var categoryStats = products
        .GroupBy(p => p.Category)
        .Select(g => new
        {
            Category = g.Key,
            Count = g.Count(),
            TotalValue = g.Sum(p => p.Price * p.Stock),
            AveragePrice = g.Average(p => p.Price),
            Products = g.Select(p => p.Name).ToList()
        })
        .ToList();

    foreach (var stat in categoryStats)
    {
        Console.WriteLine($"\nCategory: {stat.Category}");
        Console.WriteLine($"  Count: {stat.Count}");
        Console.WriteLine($"  Total Value: ${stat.TotalValue}");
        Console.WriteLine($"  Average Price: ${stat.AveragePrice:F2}");
        Console.WriteLine($"  Products: {string.Join(", ", stat.Products)}");
    }
}

// ============ JOINING WITH ANONYMOUS TYPES ============

public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public decimal Amount { get; set; }
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
}

public void JoinExample()
{
    var customers = new List<Customer>
    {
        new Customer { Id = 1, Name = "John", Email = "john@example.com" },
        new Customer { Id = 2, Name = "Jane", Email = "jane@example.com" }
    };

    var orders = new List<Order>
    {
        new Order { Id = 101, CustomerId = 1, Amount = 100 },
        new Order { Id = 102, CustomerId = 1, Amount = 200 },
        new Order { Id = 103, CustomerId = 2, Amount = 150 }
    };

    // Join and project to anonymous type
    var customerOrders = customers
        .Join(orders,
            c => c.Id,
            o => o.CustomerId,
            (c, o) => new
            {
                CustomerName = c.Name,
                CustomerEmail = c.Email,
                OrderId = o.Id,
                OrderAmount = o.Amount
            })
        .ToList();

    foreach (var item in customerOrders)
    {
        Console.WriteLine($"{item.CustomerName} - Order #{item.OrderId}: ${item.OrderAmount}");
    }
}

// ============ RETURNING ANONYMOUS TYPES ============

// Cannot directly return anonymous type - must use dynamic or object
public dynamic GetProductSummary(int productId)
{
    var product = GetProducts().FirstOrDefault(p => p.Id == productId);

    if (product == null) return null;

    return new
    {
        product.Name,
        product.Price,
        IsAvailable = product.Stock > 0
    };
}

// Better: Define a proper class for return types
public class ProductSummary
{
    public string Name { get; set; }
    public decimal Price { get; set; }
    public bool IsAvailable { get; set; }
}

public ProductSummary GetProductSummaryTyped(int productId)
{
    var product = GetProducts().FirstOrDefault(p => p.Id == productId);

    if (product == null) return null;

    return new ProductSummary
    {
        Name = product.Name,
        Price = product.Price,
        IsAvailable = product.Stock > 0
    };
}

// ============ NESTED ANONYMOUS TYPES ============

public void NestedAnonymousTypes()
{
    var company = new
    {
        Name = "Tech Corp",
        Founded = 2020,
        Address = new
        {
            Street = "123 Main St",
            City = "Seattle",
            Zip = "98101"
        },
        Employees = new[]
        {
            new { Name = "Alice", Role = "Developer" },
            new { Name = "Bob", Role = "Manager" }
        }
    };

    Console.WriteLine($"{company.Name} - {company.Address.City}");
    foreach (var emp in company.Employees)
    {
        Console.WriteLine($"  {emp.Name}: {emp.Role}");
    }
}

// ============ ANONYMOUS TYPE EQUALITY ============

public void AnonymousTypeEquality()
{
    var person1 = new { Name = "John", Age = 30 };
    var person2 = new { Name = "John", Age = 30 };
    var person3 = new { Name = "Jane", Age = 30 };

    // Same property names, types, and order = same anonymous type
    Console.WriteLine(person1.Equals(person2));  // True (value equality)
    Console.WriteLine(person1.Equals(person3));  // False (different values)
    Console.WriteLine(person1 == person2);       // False (different instances)
}

// ============ REAL-WORLD USE CASES ============

// 1. API Response Shaping
public IActionResult GetUserDashboard(int userId)
{
    var user = GetUser(userId);
    var recentOrders = GetRecentOrders(userId).Take(5);
    var stats = CalculateUserStats(userId);

    // Shape response without creating DTO class
    var dashboard = new
    {
        User = new
        {
            user.Name,
            user.Email,
            MemberSince = user.CreatedDate
        },
        RecentOrders = recentOrders.Select(o => new
        {
            o.Id,
            o.Date,
            o.Total,
            o.Status
        }),
        Statistics = new
        {
            stats.TotalOrders,
            stats.TotalSpent,
            stats.AverageOrderValue
        }
    };

    return Ok(dashboard);
}

// 2. Debugging/Logging
public void LogProductInfo(Product product)
{
    var logEntry = new
    {
        Timestamp = DateTime.Now,
        ProductInfo = new
        {
            product.Id,
            product.Name,
            product.Price
        },
        Metadata = new
        {
            MachineName = Environment.MachineName,
            User = Environment.UserName
        }
    };

    Console.WriteLine(JsonSerializer.Serialize(logEntry));
}

// 3. Temporary Data Transformation
public void ProcessData()
{
    var rawData = LoadRawData();

    // Transform temporarily without creating class
    var processed = rawData
        .Select(d => new
        {
            Original = d,
            Normalized = NormalizeValue(d.Value),
            Category = CategorizeValue(d.Value)
        })
        .Where(d => d.Normalized > 0.5)
        .OrderByDescending(d => d.Normalized)
        .ToList();

    // Use processed data locally
    foreach (var item in processed)
    {
        Console.WriteLine($"{item.Category}: {item.Normalized:F2}");
    }
}

private List<Product> GetProducts() => new List<Product>();
private Product GetProduct(int id) => null;
private User GetUser(int id) => null;
private List<Order> GetRecentOrders(int userId) => new List<Order>();
private UserStats CalculateUserStats(int userId) => new UserStats();
private List<DataPoint> LoadRawData() => new List<DataPoint>();
private double NormalizeValue(double value) => value;
private string CategorizeValue(double value) => "Category";
}

public class User
{
    public string Name { get; set; }
    public string Email { get; set; }
    public DateTime CreatedDate { get; set; }
}

public class UserStats
{
    public int TotalOrders { get; set; }
    public decimal TotalSpent { get; set; }
    public decimal AverageOrderValue { get; set; }
}

public class DataPoint
{
    public double Value { get; set; }
}
```

**When to Use:**
✅ LINQ queries/projections
✅ Temporary data shapes
✅ Grouping/aggregating data
✅ Local method scope
✅ API response shaping (quick prototyping)

❌ Return types from methods
❌ Public APIs
❌ Storing in collections across methods
❌ Complex business logic
❌ When type will be reused

---

(Continuing with Q31-Q50 next...)
