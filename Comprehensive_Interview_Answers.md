# COMPREHENSIVE INTERVIEW ANSWERS
## For: Lakshaman Rokade - Technical Lead | .NET Developer | Azure Developer

---

## SECTION 1: C# & .NET CORE FUNDAMENTALS

### Q1: What are the key differences between .NET Framework, .NET Core, and .NET 5+?

**.NET Framework:**
- Windows-only platform
- Monolithic architecture
- Released in 2002, final version 4.8
- Full framework with extensive libraries
- Used for Windows desktop apps, ASP.NET web apps

**.NET Core:**
- Cross-platform (Windows, Linux, macOS)
- Modular, lightweight architecture
- Open-source
- High performance
- Side-by-side versioning support
- Released 2016-2020 (versions 1.0 to 3.1)

**.NET 5+ (Unified Platform):**
- Evolution of .NET Core (skipped version 4 to avoid confusion with .NET Framework 4.x)
- Single unified platform for all workloads
- Best performance across all .NET versions
- Annual release cycle (5, 6, 7, 8, 9...)
- LTS (Long Term Support) versions every 2 years
- Combines best of Framework and Core

**Example:**
```csharp
// .NET 5+ minimal API (not available in Framework)
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/", () => "Hello World!");
app.Run();
```

---

### Q2: Explain the differences between value types and reference types in C#.

**Value Types:**
- Stored on the stack (or inline in containing type)
- Contains actual data
- Copy creates independent instance
- Examples: int, double, bool, struct, enum
- Derive from System.ValueType
- Cannot be null (unless nullable)

**Reference Types:**
- Stored on the heap
- Variable holds reference (pointer) to data
- Copy creates another reference to same object
- Examples: class, interface, delegate, string, arrays
- Derive from System.Object
- Can be null

**Example:**
```csharp
// Value Type
int a = 10;
int b = a;  // Copy of value
b = 20;
Console.WriteLine(a);  // Output: 10 (unchanged)

// Reference Type
var person1 = new Person { Name = "John" };
var person2 = person1;  // Copy of reference
person2.Name = "Jane";
Console.WriteLine(person1.Name);  // Output: Jane (changed!)

// Memory Layout Visualization:
// Stack:          Heap:
// a: 10          person1 -> [Name: "Jane"]
// b: 20          person2 ----^
```

---

### Q3: What is boxing and unboxing? What are the performance implications?

**Boxing:**
- Converting value type to reference type (object)
- Allocates memory on heap
- Copies value to heap
- Creates wrapper object

**Unboxing:**
- Extracting value type from object
- Requires explicit cast
- Type must match exactly

**Performance Implications:**
- Memory allocation overhead
- Garbage collection pressure
- Type checking overhead
- Can degrade performance in loops

**Example:**
```csharp
// Boxing - implicit
int value = 123;
object boxed = value;  // Boxing occurs

// Unboxing - explicit
int unboxed = (int)boxed;  // Unboxing

// Performance Issue Example:
ArrayList list = new ArrayList();  // Non-generic collection
for (int i = 0; i < 1000000; i++)
{
    list.Add(i);  // Boxing occurs 1 million times!
}

// Solution: Use Generics (No Boxing)
List<int> genericList = new List<int>();
for (int i = 0; i < 1000000; i++)
{
    genericList.Add(i);  // No boxing - direct storage
}

// Performance difference: Generics are 10-100x faster for value types
```

---

### Q4: Explain the concept of garbage collection in .NET. How does it work?

**Garbage Collection (GC):**
- Automatic memory management system
- Reclaims memory from unused objects
- Eliminates manual memory management
- Prevents memory leaks and dangling pointers

**How It Works:**

1. **Allocation Phase:**
   - Objects allocated on managed heap
   - GC tracks all object references

2. **Mark Phase:**
   - GC identifies reachable objects (roots)
   - Roots include: static fields, local variables, CPU registers
   - Traverses object graph marking reachable objects

3. **Sweep/Compact Phase:**
   - Unreachable objects are garbage
   - Memory reclaimed
   - Live objects compacted to reduce fragmentation
   - References updated to new locations

**Example:**
```csharp
public class GCExample
{
    public void CreateObjects()
    {
        // Object created on heap
        var temp = new StringBuilder();
        temp.Append("Hello");

        // When method exits, 'temp' goes out of scope
        // Object becomes eligible for GC
    }

    // Force GC (not recommended in production)
    public void ForceCollection()
    {
        GC.Collect();  // Triggers immediate collection
        GC.WaitForPendingFinalizers();
        GC.Collect();
    }

    // Check memory before/after
    public void CheckMemory()
    {
        long before = GC.GetTotalMemory(false);
        CreateObjects();
        long after = GC.GetTotalMemory(true);  // forces GC
        Console.WriteLine($"Memory freed: {before - after} bytes");
    }
}
```

**GC Modes:**
- **Workstation GC:** For client apps, optimized for responsiveness
- **Server GC:** For server apps, optimized for throughput

---

### Q5: What are the different generations in garbage collection?

The .NET GC uses a **generational algorithm** with three generations:

**Generation 0 (Gen 0):**
- Newly allocated objects
- Collected most frequently
- Short-lived objects (temp variables, local objects)
- Fastest collection
- Size: ~256 KB - 4 MB

**Generation 1 (Gen 1):**
- Buffer between short-lived and long-lived
- Objects that survived one Gen 0 collection
- Medium-lived objects
- Collected less frequently than Gen 0
- Size: ~2-8 MB

**Generation 2 (Gen 2):**
- Long-lived objects
- Objects that survived Gen 1 collection
- Static data, singletons, cached objects
- Collected least frequently
- Most expensive collection
- Can grow very large

**Large Object Heap (LOH):**
- Objects ≥ 85,000 bytes
- Treated as Gen 2
- Not compacted (in older .NET versions)
- Can cause fragmentation

**Example:**
```csharp
public class GenerationExample
{
    public void DemonstrateGenerations()
    {
        // Gen 0 objects
        var temp = new byte[1000];
        Console.WriteLine($"Gen: {GC.GetGeneration(temp)}");  // 0

        // Survive first collection
        GC.Collect(0);
        Console.WriteLine($"Gen: {GC.GetGeneration(temp)}");  // 1

        // Survive second collection
        GC.Collect(1);
        Console.WriteLine($"Gen: {GC.GetGeneration(temp)}");  // 2

        // Large object
        var largeObj = new byte[100000];
        Console.WriteLine($"Large Object Gen: {GC.GetGeneration(largeObj)}");  // 2
    }

    public void ShowGCStats()
    {
        Console.WriteLine($"Gen 0 collections: {GC.CollectionCount(0)}");
        Console.WriteLine($"Gen 1 collections: {GC.CollectionCount(1)}");
        Console.WriteLine($"Gen 2 collections: {GC.CollectionCount(2)}");
    }
}

// Typical ratios: 10:1:1 (Gen 0 happens 10x more than Gen 1)
```

**Visual Representation:**
```
Gen 0: [obj][obj][obj]     ← Most frequent, cheapest
Gen 1: [obj][obj]           ← Medium frequency
Gen 2: [obj][obj][obj][obj] ← Least frequent, expensive
LOH:   [large object]       ← Objects ≥ 85KB
```

---

### Q6: What is the difference between Finalize() and Dispose() methods?

**Finalize():**
- Called by garbage collector
- Non-deterministic (unknown timing)
- Cannot be called explicitly
- Used for unmanaged resources cleanup
- Slower (objects promoted to higher generation)
- Syntax: Override `~ClassName()` destructor

**Dispose():**
- Part of IDisposable interface
- Deterministic (called explicitly)
- Manual cleanup control
- Should be called by developer
- Used with `using` statement
- Faster, immediate cleanup

**Example:**
```csharp
public class ResourceHandler : IDisposable
{
    private IntPtr unmanagedResource;
    private FileStream managedResource;
    private bool disposed = false;

    public ResourceHandler()
    {
        unmanagedResource = // ... allocate unmanaged memory
        managedResource = new FileStream("file.txt", FileMode.Open);
    }

    // Dispose pattern implementation
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);  // Prevent finalizer call
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!disposed)
        {
            if (disposing)
            {
                // Dispose managed resources
                managedResource?.Dispose();
            }

            // Free unmanaged resources
            if (unmanagedResource != IntPtr.Zero)
            {
                // Free unmanaged memory
                unmanagedResource = IntPtr.Zero;
            }

            disposed = true;
        }
    }

    // Finalizer (destructor)
    ~ResourceHandler()
    {
        Dispose(false);
    }
}

// Usage:
using (var handler = new ResourceHandler())
{
    // Use resource
}  // Dispose called automatically

// Or manual:
var handler2 = new ResourceHandler();
try
{
    // Use resource
}
finally
{
    handler2.Dispose();
}
```

**Comparison Table:**
| Aspect | Finalize() | Dispose() |
|--------|-----------|-----------|
| Timing | Non-deterministic | Deterministic |
| Called by | GC | Developer |
| Performance | Slower | Faster |
| Explicit call | No | Yes |
| Pattern | Destructor | IDisposable |

---

### Q7: Explain the IDisposable interface and the using statement.

**IDisposable Interface:**
- Single method: `void Dispose()`
- Used to release unmanaged resources deterministically
- Implemented for resource cleanup (files, DB connections, etc.)

**Using Statement:**
- Ensures Dispose() is called
- Even if exception occurs
- Syntactic sugar for try-finally
- Supports multiple variables (C# 8+)

**Example:**
```csharp
// IDisposable implementation
public class DatabaseConnection : IDisposable
{
    private SqlConnection connection;
    private bool disposed = false;

    public DatabaseConnection(string connectionString)
    {
        connection = new SqlConnection(connectionString);
        connection.Open();
        Console.WriteLine("Connection opened");
    }

    public void ExecuteQuery(string query)
    {
        if (disposed)
            throw new ObjectDisposedException(nameof(DatabaseConnection));

        // Execute query
        using var command = new SqlCommand(query, connection);
        command.ExecuteNonQuery();
    }

    public void Dispose()
    {
        if (!disposed)
        {
            connection?.Close();
            connection?.Dispose();
            Console.WriteLine("Connection closed");
            disposed = true;
        }
    }
}

// Using statement - Traditional
using (var db = new DatabaseConnection("connection string"))
{
    db.ExecuteQuery("SELECT * FROM Users");
}  // Dispose() called here automatically

// Equivalent to:
DatabaseConnection db = null;
try
{
    db = new DatabaseConnection("connection string");
    db.ExecuteQuery("SELECT * FROM Users");
}
finally
{
    db?.Dispose();  // Always called
}

// C# 8+ Using declaration (simplified)
public void ProcessFile()
{
    using var file = new StreamReader("data.txt");
    var content = file.ReadToEnd();
    // Dispose() called at end of method scope
}

// Multiple using statements
using (var conn = new SqlConnection("..."))
using (var command = new SqlCommand("...", conn))
using (var reader = command.ExecuteReader())
{
    while (reader.Read())
    {
        // Process data
    }
}

// C# 8+ Multiple resources
public void MultipleResources()
{
    using var conn = new SqlConnection("...");
    using var command = new SqlCommand("...", conn);
    using var reader = command.ExecuteReader();

    while (reader.Read())
    {
        // Process data
    }
}
```

---

### Q8: What are delegates in C#? How do they differ from events?

**Delegates:**
- Type-safe function pointers
- Reference type that holds method reference
- Can point to static or instance methods
- Support multicast (multiple methods)
- Used for callbacks, event handling

**Events:**
- Special kind of delegate
- Encapsulated delegate with restrictions
- Can only be invoked from declaring class
- Subscribe with += and unsubscribe with -=
- Cannot be assigned directly (only += or -=)

**Example:**
```csharp
// Delegate definition
public delegate void NotificationHandler(string message);

public class NotificationService
{
    // Delegate field (not recommended - use event instead)
    public NotificationHandler OnNotificationDelegate;

    // Event (recommended)
    public event NotificationHandler OnNotificationEvent;

    public void SendNotification(string message)
    {
        // With delegate - anyone can invoke or reassign
        OnNotificationDelegate?.Invoke(message);

        // With event - only this class can invoke
        OnNotificationEvent?.Invoke(message);
    }
}

// Usage example
public class Example
{
    public void DemonstrateDelegate()
    {
        var service = new NotificationService();

        // Delegate - can be assigned
        service.OnNotificationDelegate = SendEmail;
        service.OnNotificationDelegate = SendSMS;  // Overwrites previous!

        // Event - must use += or -=
        service.OnNotificationEvent += SendEmail;
        service.OnNotificationEvent += SendSMS;  // Both will execute

        // Delegate - external code can invoke (BAD!)
        service.OnNotificationDelegate?.Invoke("Hacked!");

        // Event - cannot invoke from outside (GOOD!)
        // service.OnNotificationEvent?.Invoke("Won't compile!");

        service.SendNotification("Hello");

        // Unsubscribe
        service.OnNotificationEvent -= SendEmail;
    }

    private void SendEmail(string message)
    {
        Console.WriteLine($"Email: {message}");
    }

    private void SendSMS(string message)
    {
        Console.WriteLine($"SMS: {message}");
    }
}

// Real-world example: Button click
public class Button
{
    // Event pattern
    public event EventHandler Click;

    protected virtual void OnClick(EventArgs e)
    {
        Click?.Invoke(this, e);
    }

    public void SimulateClick()
    {
        OnClick(EventArgs.Empty);
    }
}

// Usage
var button = new Button();
button.Click += (sender, e) => Console.WriteLine("Button clicked!");
button.SimulateClick();
```

**Key Differences:**
| Feature | Delegate | Event |
|---------|----------|-------|
| Access | Public field | Encapsulated |
| Invocation | Anyone can invoke | Only declaring class |
| Assignment | Can be assigned (=) | Only += or -= |
| Reset | Can be set to null | Cannot be reset |
| Purpose | Callbacks | Notifications |

---

### Q9: Explain multicast delegates with an example.

**Multicast Delegates:**
- Delegate that holds references to multiple methods
- Invoked sequentially in order added
- All methods must have same signature
- Return value from last method (if any)
- Use += to add, -= to remove

**Example:**
```csharp
// Delegate definition
public delegate void LogHandler(string message);

public class MulticastExample
{
    public static void Main()
    {
        // Create multicast delegate
        LogHandler logger = LogToConsole;
        logger += LogToFile;
        logger += LogToDatabase;
        logger += SendEmail;

        // Single invocation executes all methods
        logger("Application started");
        // Output: All 4 methods execute in order

        // Remove method
        logger -= LogToFile;
        logger("User logged in");
        // Output: 3 methods execute (File logging skipped)

        // Check invocation list
        Console.WriteLine($"Handlers: {logger.GetInvocationList().Length}");

        // Individual invocation with error handling
        foreach (LogHandler handler in logger.GetInvocationList())
        {
            try
            {
                handler("Safe invocation");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Handler failed: {ex.Message}");
            }
        }
    }

    static void LogToConsole(string message)
    {
        Console.WriteLine($"[Console] {message}");
    }

    static void LogToFile(string message)
    {
        File.AppendAllText("log.txt", $"{DateTime.Now}: {message}\n");
        Console.WriteLine($"[File] {message}");
    }

    static void LogToDatabase(string message)
    {
        // Simulate database logging
        Console.WriteLine($"[Database] {message}");
    }

    static void SendEmail(string message)
    {
        // Simulate email notification for critical logs
        if (message.Contains("Error"))
            Console.WriteLine($"[Email] Alert: {message}");
    }
}

// Return value example (only last method's return value is used)
public delegate int Calculator(int x, int y);

public class ReturnValueExample
{
    public void DemonstrateReturnValue()
    {
        Calculator calc = Add;
        calc += Multiply;
        calc += Subtract;

        int result = calc(10, 5);
        Console.WriteLine($"Result: {result}");
        // Output: -5 (only Subtract's return value)
        // Add: 15, Multiply: 50, Subtract: 5 (but only last is returned)

        // To get all return values:
        foreach (Calculator method in calc.GetInvocationList())
        {
            int value = method(10, 5);
            Console.WriteLine($"{method.Method.Name}: {value}");
        }
    }

    static int Add(int x, int y) => x + y;
    static int Multiply(int x, int y) => x * y;
    static int Subtract(int x, int y) => x - y;
}

// Real-world example: Event pipeline
public class OrderProcessor
{
    public delegate void OrderEventHandler(Order order);
    public event OrderEventHandler OrderPlaced;

    public void PlaceOrder(Order order)
    {
        // Multicast event - multiple handlers execute
        OrderPlaced?.Invoke(order);
    }
}

public class Order { public int Id { get; set; } public decimal Amount { get; set; } }

// Usage
var processor = new OrderProcessor();
processor.OrderPlaced += order => Console.WriteLine($"Validate: {order.Id}");
processor.OrderPlaced += order => Console.WriteLine($"Payment: ${order.Amount}");
processor.OrderPlaced += order => Console.WriteLine($"Send confirmation email");
processor.OrderPlaced += order => Console.WriteLine($"Update inventory");

processor.PlaceOrder(new Order { Id = 1, Amount = 99.99m });
// All 4 handlers execute in order
```

**Important Notes:**
- Exception in one handler stops subsequent handlers
- Return values ignored except last one
- Use GetInvocationList() for individual control
- Remove handlers to avoid memory leaks

---

### Q10: What is the difference between Func, Action, and Predicate delegates?

**Built-in Generic Delegates:**

**Func<T>:**
- Returns a value
- 0-16 input parameters
- Last type parameter is return type
- Syntax: `Func<input1, input2, ..., TResult>`

**Action<T>:**
- Returns void
- 0-16 input parameters
- No return type
- Syntax: `Action<input1, input2, ...>`

**Predicate<T>:**
- Returns bool
- Single input parameter
- Used for conditions/filtering
- Syntax: `Predicate<T>`

**Example:**
```csharp
public class DelegateExample
{
    // Func - with return value
    public void FuncExamples()
    {
        // No parameters
        Func<int> getRandom = () => new Random().Next();
        Console.WriteLine(getRandom());  // 12345

        // One parameter
        Func<int, int> square = x => x * x;
        Console.WriteLine(square(5));  // 25

        // Two parameters
        Func<int, int, int> add = (x, y) => x + y;
        Console.WriteLine(add(10, 20));  // 30

        // Multiple parameters
        Func<string, int, bool, string> format =
            (name, age, isActive) => $"{name}, {age}, Active: {isActive}";
        Console.WriteLine(format("John", 30, true));

        // Real-world: LINQ
        List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
        Func<int, bool> isEven = n => n % 2 == 0;
        var evenNumbers = numbers.Where(isEven);  // 2, 4
    }

    // Action - no return value
    public void ActionExamples()
    {
        // No parameters
        Action greet = () => Console.WriteLine("Hello!");
        greet();

        // One parameter
        Action<string> printMessage = msg => Console.WriteLine(msg);
        printMessage("Welcome");

        // Two parameters
        Action<string, int> printInfo = (name, age) =>
            Console.WriteLine($"{name} is {age} years old");
        printInfo("John", 30);

        // Multiple parameters
        Action<string, int, string, decimal> logTransaction =
            (user, id, type, amount) =>
                Console.WriteLine($"User {user}: {type} #{id} - ${amount}");
        logTransaction("admin", 101, "Payment", 99.99m);

        // Real-world: ForEach
        List<string> names = new List<string> { "John", "Jane", "Bob" };
        names.ForEach(name => Console.WriteLine(name));
    }

    // Predicate - returns bool, single parameter
    public void PredicateExamples()
    {
        Predicate<int> isPositive = n => n > 0;
        Console.WriteLine(isPositive(5));   // True
        Console.WriteLine(isPositive(-3));  // False

        Predicate<string> isLongString = s => s.Length > 10;
        Console.WriteLine(isLongString("Hello"));  // False
        Console.WriteLine(isLongString("Hello World!"));  // True

        // Real-world: List.Find
        List<int> numbers = new List<int> { -5, -2, 0, 3, 7, 10 };

        Predicate<int> isEven = n => n % 2 == 0;
        int firstEven = numbers.Find(isEven);  // 0

        List<int> allEven = numbers.FindAll(isEven);  // -2, 0, 10

        bool hasNegative = numbers.Exists(n => n < 0);  // True

        numbers.RemoveAll(n => n < 0);  // Remove negatives
        // numbers now: 0, 3, 7, 10
    }

    // Comparison example
    public void ComparisonExample()
    {
        List<string> names = new List<string>
        {
            "Alice", "Bob", "Charlie", "David"
        };

        // Using Func (LINQ Where)
        Func<string, bool> startsWithC = n => n.StartsWith("C");
        var result1 = names.Where(startsWithC);  // Charlie

        // Using Predicate (List FindAll)
        Predicate<string> startsWithCPred = n => n.StartsWith("C");
        var result2 = names.FindAll(startsWithCPred);  // Charlie

        // Using Action (ForEach)
        Action<string> print = n => Console.WriteLine(n);
        names.ForEach(print);
    }

    // Real-world repository example
    public class Repository<T>
    {
        private List<T> items = new List<T>();

        // Func - transformation
        public List<TResult> Select<TResult>(Func<T, TResult> selector)
        {
            var results = new List<TResult>();
            foreach (var item in items)
                results.Add(selector(item));
            return results;
        }

        // Predicate - filtering
        public List<T> FindAll(Predicate<T> match)
        {
            return items.FindAll(match);
        }

        // Action - iteration
        public void ForEach(Action<T> action)
        {
            items.ForEach(action);
        }
    }
}
```

**Comparison Table:**
| Delegate | Return Type | Parameters | Common Use |
|----------|-------------|------------|------------|
| Func<T> | Yes (any type) | 0-16 | Transformations, calculations |
| Action<T> | void | 0-16 | Side effects, logging |
| Predicate<T> | bool | 1 | Filtering, conditions |

**When to Use:**
- **Func:** Need return value (LINQ, calculations)
- **Action:** Perform operation without return (logging, updates)
- **Predicate:** Boolean checks (filtering, validation)

---

### Q11: Explain lambda expressions and expression trees.

**Lambda Expressions:**
- Anonymous function syntax
- Concise way to write inline methods
- Used with delegates and LINQ
- Syntax: `(parameters) => expression or statement block`

**Expression Trees:**
- Data structure representing code
- Code as data (not executable)
- Used by LINQ providers (EF, SQL)
- Can be analyzed and transformed
- Type: `Expression<TDelegate>`

**Example:**
```csharp
// ============ LAMBDA EXPRESSIONS ============

// Basic syntax forms
public class LambdaExamples
{
    public void BasicLambdas()
    {
        // No parameters
        Action greet = () => Console.WriteLine("Hello");

        // One parameter (parentheses optional)
        Func<int, int> square = x => x * x;
        Func<int, int> square2 = (x) => x * x;  // Same

        // Multiple parameters
        Func<int, int, int> add = (x, y) => x + y;

        // Statement block
        Func<int, int, int> divide = (x, y) =>
        {
            if (y == 0)
                throw new DivideByZeroException();
            return x / y;
        };

        // With explicit types
        Func<int, int, bool> isGreater = (int a, int b) => a > b;
    }

    // LINQ with lambdas
    public void LinqLambdas()
    {
        List<int> numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

        // Where
        var evens = numbers.Where(n => n % 2 == 0);

        // Select
        var squared = numbers.Select(n => n * n);

        // OrderBy
        var ordered = numbers.OrderBy(n => n % 3);

        // Complex lambda
        var filtered = numbers
            .Where(n => n > 5)
            .Select(n => new { Number = n, Square = n * n })
            .OrderByDescending(x => x.Square);
    }

    // Closure example
    public void ClosureExample()
    {
        int multiplier = 5;

        // Lambda captures 'multiplier' variable
        Func<int, int> multiply = x => x * multiplier;

        Console.WriteLine(multiply(10));  // 50

        multiplier = 10;  // Change captured variable
        Console.WriteLine(multiply(10));  // 100 (uses new value)
    }
}

// ============ EXPRESSION TREES ============

public class ExpressionTreeExamples
{
    public void BasicExpressionTree()
    {
        // Lambda expression - compiled to executable code
        Func<int, int, int> addFunc = (x, y) => x + y;
        int result1 = addFunc(5, 3);  // Executes immediately

        // Expression tree - code as data
        Expression<Func<int, int, int>> addExpr = (x, y) => x + y;
        // Cannot execute directly - it's data structure

        // Compile and execute
        var compiled = addExpr.Compile();
        int result2 = compiled(5, 3);  // Now executable

        // Inspect the expression tree
        Console.WriteLine($"Body: {addExpr.Body}");  // (x + y)
        Console.WriteLine($"Type: {addExpr.Body.NodeType}");  // Add

        // Analyze structure
        if (addExpr.Body is BinaryExpression binary)
        {
            Console.WriteLine($"Left: {binary.Left}");   // x
            Console.WriteLine($"Right: {binary.Right}");  // y
            Console.WriteLine($"Operator: {binary.NodeType}");  // Add
        }
    }

    // Build expression tree manually
    public void BuildExpressionTree()
    {
        // (x, y) => x * x + y * y

        ParameterExpression x = Expression.Parameter(typeof(int), "x");
        ParameterExpression y = Expression.Parameter(typeof(int), "y");

        // x * x
        BinaryExpression xSquared = Expression.Multiply(x, x);

        // y * y
        BinaryExpression ySquared = Expression.Multiply(y, y);

        // x * x + y * y
        BinaryExpression sum = Expression.Add(xSquared, ySquared);

        // Create lambda
        Expression<Func<int, int, int>> lambda =
            Expression.Lambda<Func<int, int, int>>(sum, x, y);

        // Compile and execute
        var func = lambda.Compile();
        Console.WriteLine(func(3, 4));  // 25 (3² + 4²)
    }

    // Real-world: LINQ to SQL
    public void LinqToSqlExample()
    {
        using var context = new MyDbContext();

        // Expression tree - translated to SQL
        Expression<Func<User, bool>> predicate = u => u.Age > 18 && u.IsActive;

        // EF Core analyzes expression tree and generates SQL:
        // SELECT * FROM Users WHERE Age > 18 AND IsActive = 1
        var users = context.Users.Where(predicate).ToList();

        // This would not work - cannot translate to SQL
        // Func<User, bool> funcPredicate = u => ComplexMethod(u);
        // var users = context.Users.Where(funcPredicate); // Error!
    }

    // Modify expression tree (Visitor pattern)
    public void ModifyExpressionTree()
    {
        Expression<Func<int, int>> original = x => x + 10;

        // Replace parameter
        var visitor = new ParameterReplacer();
        var modified = visitor.Visit(original);

        Console.WriteLine($"Original: {original}");   // x => (x + 10)
        Console.WriteLine($"Modified: {modified}");   // y => (y + 10)
    }
}

// Expression visitor for modification
public class ParameterReplacer : ExpressionVisitor
{
    protected override Expression VisitParameter(ParameterExpression node)
    {
        // Replace parameter name
        return Expression.Parameter(node.Type, "y");
    }
}

// Real-world: Dynamic query builder
public class DynamicQueryBuilder<T>
{
    public Expression<Func<T, bool>> BuildPredicate(
        string propertyName,
        object value)
    {
        // T => T.PropertyName == value

        var parameter = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(parameter, propertyName);
        var constant = Expression.Constant(value);
        var equals = Expression.Equal(property, constant);

        return Expression.Lambda<Func<T, bool>>(equals, parameter);
    }
}

// Usage
var builder = new DynamicQueryBuilder<User>();
var predicate = builder.BuildPredicate("Age", 25);
// Generates: x => x.Age == 25

var users = dbContext.Users.Where(predicate).ToList();
```

**Key Differences:**
| Aspect | Lambda | Expression Tree |
|--------|--------|-----------------|
| Type | Delegate | Expression<TDelegate> |
| Purpose | Executable code | Code as data |
| Compilation | Immediate | On demand (Compile()) |
| Use case | In-memory operations | LINQ providers (SQL) |
| Analysis | Cannot inspect | Can inspect/modify |

**When to Use:**
- **Lambda:** In-memory collections (LINQ to Objects)
- **Expression Tree:** Database queries (LINQ to SQL/EF), dynamic queries

---

### Q12: What are extension methods? When would you use them?

**Extension Methods:**
- Add methods to existing types without modifying them
- Static methods that appear as instance methods
- Defined in static class
- First parameter uses `this` keyword
- Called like instance methods

**When to Use:**
- Add utility methods to types you don't own
- Enhance existing classes without inheritance
- Create fluent APIs
- LINQ is built entirely on extension methods

**Example:**
```csharp
// ============ BASIC EXTENSION METHODS ============

// Define extension methods in static class
public static class StringExtensions
{
    // Extension method for string
    public static bool IsValidEmail(this string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        return System.Text.RegularExpressions.Regex.IsMatch(
            email,
            @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    }

    public static string Truncate(this string value, int maxLength)
    {
        if (string.IsNullOrEmpty(value)) return value;
        return value.Length <= maxLength
            ? value
            : value.Substring(0, maxLength) + "...";
    }

    public static string ToTitleCase(this string value)
    {
        if (string.IsNullOrEmpty(value)) return value;

        return System.Globalization.CultureInfo.CurrentCulture
            .TextInfo.ToTitleCase(value.ToLower());
    }

    public static int WordCount(this string str)
    {
        return str?.Split(new[] { ' ', '.', '?' },
            StringSplitOptions.RemoveEmptyEntries).Length ?? 0;
    }
}

// Usage
public class ExtensionUsageExample
{
    public void UseStringExtensions()
    {
        string email = "user@example.com";
        bool isValid = email.IsValidEmail();  // Extension method
        Console.WriteLine($"Valid: {isValid}");  // True

        string text = "This is a very long text that needs truncation";
        string truncated = text.Truncate(20);
        Console.WriteLine(truncated);  // "This is a very long ..."

        string name = "john doe";
        string title = name.ToTitleCase();
        Console.WriteLine(title);  // "John Doe"

        Console.WriteLine(text.WordCount());  // 9
    }
}

// ============ COLLECTION EXTENSIONS ============

public static class CollectionExtensions
{
    public static bool IsNullOrEmpty<T>(this IEnumerable<T> collection)
    {
        return collection == null || !collection.Any();
    }

    public static void ForEach<T>(this IEnumerable<T> collection, Action<T> action)
    {
        foreach (var item in collection)
            action(item);
    }

    public static IEnumerable<T> WhereNotNull<T>(this IEnumerable<T?> collection)
        where T : class
    {
        return collection.Where(item => item != null)!;
    }

    public static Dictionary<TKey, TValue> ToDictionary<TKey, TValue>(
        this IEnumerable<KeyValuePair<TKey, TValue>> collection)
        where TKey : notnull
    {
        return collection.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);
    }
}

// Usage
public class CollectionExtensionUsage
{
    public void UseCollectionExtensions()
    {
        List<int> numbers = null;

        if (numbers.IsNullOrEmpty())  // Extension method
        {
            Console.WriteLine("List is empty or null");
        }

        numbers = new List<int> { 1, 2, 3, 4, 5 };

        // ForEach extension
        numbers.ForEach(n => Console.WriteLine(n * 2));

        // WhereNotNull extension
        List<string?> nullableStrings = new() { "A", null, "B", null, "C" };
        var nonNull = nullableStrings.WhereNotNull();  // A, B, C
    }
}

// ============ FLUENT API EXTENSIONS ============

public class QueryBuilder
{
    public string TableName { get; set; }
    public List<string> Columns { get; set; } = new();
    public string WhereClause { get; set; }
    public int? TakeCount { get; set; }
}

public static class QueryBuilderExtensions
{
    public static QueryBuilder From(this QueryBuilder builder, string table)
    {
        builder.TableName = table;
        return builder;
    }

    public static QueryBuilder Select(this QueryBuilder builder, params string[] columns)
    {
        builder.Columns.AddRange(columns);
        return builder;
    }

    public static QueryBuilder Where(this QueryBuilder builder, string condition)
    {
        builder.WhereClause = condition;
        return builder;
    }

    public static QueryBuilder Take(this QueryBuilder builder, int count)
    {
        builder.TakeCount = count;
        return builder;
    }

    public static string Build(this QueryBuilder builder)
    {
        var query = $"SELECT {string.Join(", ", builder.Columns)} FROM {builder.TableName}";

        if (!string.IsNullOrEmpty(builder.WhereClause))
            query += $" WHERE {builder.WhereClause}";

        if (builder.TakeCount.HasValue)
            query += $" LIMIT {builder.TakeCount}";

        return query;
    }
}

// Fluent usage
var query = new QueryBuilder()
    .From("Users")
    .Select("Id", "Name", "Email")
    .Where("Age > 18")
    .Take(10)
    .Build();

Console.WriteLine(query);
// SELECT Id, Name, Email FROM Users WHERE Age > 18 LIMIT 10

// ============ DATETIME EXTENSIONS ============

public static class DateTimeExtensions
{
    public static bool IsWeekend(this DateTime date)
    {
        return date.DayOfWeek == DayOfWeek.Saturday
            || date.DayOfWeek == DayOfWeek.Sunday;
    }

    public static bool IsToday(this DateTime date)
    {
        return date.Date == DateTime.Today;
    }

    public static DateTime StartOfDay(this DateTime date)
    {
        return date.Date;
    }

    public static DateTime EndOfDay(this DateTime date)
    {
        return date.Date.AddDays(1).AddTicks(-1);
    }

    public static int Age(this DateTime birthDate)
    {
        var today = DateTime.Today;
        var age = today.Year - birthDate.Year;
        if (birthDate.Date > today.AddYears(-age)) age--;
        return age;
    }
}

// Usage
var date = new DateTime(1990, 5, 15);
Console.WriteLine($"Is weekend: {date.IsWeekend()}");
Console.WriteLine($"Age: {date.Age()}");
Console.WriteLine($"Start of day: {DateTime.Now.StartOfDay()}");

// ============ REAL-WORLD: LINQ EXTENSION ============

public static class LinqExtensions
{
    // Paginate extension
    public static IEnumerable<T> Paginate<T>(
        this IEnumerable<T> source,
        int page,
        int pageSize)
    {
        return source
            .Skip((page - 1) * pageSize)
            .Take(pageSize);
    }

    // DistinctBy (built-in in .NET 6+, but custom version)
    public static IEnumerable<T> DistinctBy<T, TKey>(
        this IEnumerable<T> source,
        Func<T, TKey> keySelector)
    {
        var seenKeys = new HashSet<TKey>();
        foreach (var element in source)
        {
            if (seenKeys.Add(keySelector(element)))
                yield return element;
        }
    }

    // Batch extension
    public static IEnumerable<IEnumerable<T>> Batch<T>(
        this IEnumerable<T> source,
        int batchSize)
    {
        var batch = new List<T>(batchSize);
        foreach (var item in source)
        {
            batch.Add(item);
            if (batch.Count == batchSize)
            {
                yield return batch;
                batch = new List<T>(batchSize);
            }
        }
        if (batch.Count > 0)
            yield return batch;
    }
}

// Usage
var users = GetUsers(); // Returns IEnumerable<User>

// Pagination
var page1 = users.Paginate(page: 1, pageSize: 10);

// Distinct by property
var distinctByEmail = users.DistinctBy(u => u.Email);

// Batch processing
foreach (var batch in users.Batch(100))
{
    ProcessBatch(batch);  // Process 100 users at a time
}
```

**Best Practices:**
1. Use meaningful names
2. Keep extensions focused and simple
3. Don't overuse - respect existing class design
4. Place in well-named namespaces
5. Document behavior clearly
6. Handle null cases appropriately

**Common Use Cases:**
- String validation/formatting
- Collection utilities
- Fluent APIs
- LINQ enhancements
- DateTime helpers
- Parsing/conversion methods

---

(Continuing with Q13-Q50...)

### Q13: Explain the difference between IEnumerable, ICollection, IList, and IQueryable.

**Interface Hierarchy & Capabilities:**

**IEnumerable<T>:**
- Most basic, read-only iteration
- Forward-only cursor
- No count, no indexing
- Deferred execution
- In-memory operations

**ICollection<T>:**
- Extends IEnumerable<T>
- Adds: Count, Add, Remove, Clear, Contains
- Still no indexing
- Can modify collection

**IList<T>:**
- Extends ICollection<T>
- Adds: indexer [i], Insert, RemoveAt
- Position-based access
- Full CRUD operations

**IQueryable<T>:**
- Extends IEnumerable<T>
- For external data sources (databases)
- Expression trees (not delegates)
- Translated to query language (SQL)
- Deferred execution

**Example:**
```csharp
// ============ IENUMERABLE ============
public void IEnumerableExample()
{
    IEnumerable<int> numbers = GetNumbers();  // Could be anything

    // Can only iterate
    foreach (var num in numbers)
    {
        Console.WriteLine(num);
    }

    // No Count property (must use LINQ)
    int count = numbers.Count();  // Iterates entire sequence

    // Cannot access by index
    // int first = numbers[0];  // Compilation error

    // Cannot add/remove
    // numbers.Add(10);  // Compilation error

    // Deferred execution
    var filtered = numbers.Where(n => n > 5);  // Not executed yet
    // Executes when enumerated:
    foreach (var n in filtered) { }
}

IEnumerable<int> GetNumbers()
{
    Console.WriteLine("Generating numbers...");
    yield return 1;
    yield return 2;
    yield return 3;
}

// ============ ICOLLECTION ============
public void ICollectionExample()
{
    ICollection<int> numbers = new List<int> { 1, 2, 3 };

    // Can iterate (from IEnumerable)
    foreach (var num in numbers) { }

    // Has Count property (O(1) operation)
    int count = numbers.Count;  // Fast, no iteration needed

    // Can add/remove
    numbers.Add(4);
    numbers.Remove(2);
    numbers.Clear();

    // Can check containment
    bool contains = numbers.Contains(3);

    // Still no indexing
    // int first = numbers[0];  // Compilation error
}

// ============ ILIST ============
public void IListExample()
{
    IList<int> numbers = new List<int> { 1, 2, 3, 4, 5 };

    // Everything from ICollection
    int count = numbers.Count;
    numbers.Add(6);
    numbers.Remove(3);

    // Index-based access
    int first = numbers[0];  // 1
    numbers[0] = 10;  // Modify by index

    // Position-based operations
    numbers.Insert(2, 99);  // Insert at index 2
    numbers.RemoveAt(1);  // Remove at index 1

    // Find index
    int index = numbers.IndexOf(99);
}

// ============ IQUERYABLE ============
public void IQueryableExample()
{
    using var context = new MyDbContext();

    // IQueryable - for database
    IQueryable<User> query = context.Users;

    // Build query with expression trees
    var filtered = query
        .Where(u => u.Age > 18)  // Expression<Func<User, bool>>
        .OrderBy(u => u.Name)
        .Take(10);

    // Not executed yet - just building expression tree

    // Executes when materialized:
    List<User> users = filtered.ToList();
    // SQL generated: SELECT TOP 10 * FROM Users WHERE Age > 18 ORDER BY Name

    // vs IEnumerable - all data loaded first
    IEnumerable<User> enumerable = context.Users.AsEnumerable();
    var filteredEnum = enumerable
        .Where(u => u.Age > 18)  // Func<User, bool>
        .OrderBy(u => u.Name)
        .Take(10);
    // Loads ALL users first, then filters in memory!
}

// ============ COMPARISON TABLE ============
```

| Feature | IEnumerable | ICollection | IList | IQueryable |
|---------|------------|-------------|-------|-----------|
| Iteration | ✓ | ✓ | ✓ | ✓ |
| Count | ❌ (LINQ) | ✓ (O(1)) | ✓ | ✓ |
| Add/Remove | ❌ | ✓ | ✓ | ❌ |
| Indexer | ❌ | ❌ | ✓ | ❌ |
| Insert/RemoveAt | ❌ | ❌ | ✓ | ❌ |
| Query Translation | ❌ | ❌ | ❌ | ✓ (SQL) |
| Deferred Execution | ✓ | ❌ | ❌ | ✓ |
| Best For | Iteration | Size+Modify | Random Access | Databases |

```csharp
// ============ REAL-WORLD EXAMPLES ============

// Repository pattern - returning appropriate interface
public class UserRepository
{
    private readonly DbContext _context;

    // IQueryable - allows caller to build query
    public IQueryable<User> GetUsersQueryable()
    {
        return _context.Users.AsQueryable();
    }

    // IEnumerable - hides implementation, deferred execution
    public IEnumerable<User> GetUsersEnumerable()
    {
        return _context.Users.AsEnumerable();
    }

    // IList - full materialized list with random access
    public IList<User> GetUsersList()
    {
        return _context.Users.ToList();
    }
}

// Usage patterns
public class ServiceExample
{
    private readonly UserRepository _repo;

    public void DifferentApproaches()
    {
        // IQueryable - efficient database query
        var youngUsers = _repo.GetUsersQueryable()
            .Where(u => u.Age < 30)
            .OrderBy(u => u.Name)
            .Take(10)
            .ToList();
        // SQL: SELECT TOP 10 * FROM Users WHERE Age < 30 ORDER BY Name

        // IEnumerable - deferred, streaming
        foreach (var user in _repo.GetUsersEnumerable())
        {
            ProcessUser(user);  // Process one at a time
        }

        // IList - all in memory, random access
        var usersList = _repo.GetUsersList();
        var firstUser = usersList[0];
        usersList.Add(new User());
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceExample
{
    public void ComparePerformance()
    {
        using var context = new MyDbContext();

        // GOOD - IQueryable (10 records from DB)
        var efficient = context.Users
            .Where(u => u.IsActive)
            .Take(10)
            .ToList();
        // SQL: SELECT TOP 10 * FROM Users WHERE IsActive = 1

        // BAD - AsEnumerable too early (all records from DB)
        var inefficient = context.Users
            .AsEnumerable()  // Materializes everything!
            .Where(u => u.IsActive)
            .Take(10)
            .ToList();
        // SQL: SELECT * FROM Users (then filters in memory)

        // Count comparison
        IQueryable<User> queryable = context.Users;
        int count1 = queryable.Count();
        // SQL: SELECT COUNT(*) FROM Users (efficient)

        IEnumerable<User> enumerable = context.Users.AsEnumerable();
        int count2 = enumerable.Count();
        // Loads all records then counts (inefficient)
    }
}

// ============ WHEN TO USE WHICH ============

// IEnumerable<T>:
// - Method returns sequence for iteration only
// - Deferred execution desired
// - Implementation might change (flexibility)
public IEnumerable<Product> GetProducts()
{
    // Could return from DB, file, API, etc.
    yield return new Product { Id = 1 };
    yield return new Product { Id = 2 };
}

// ICollection<T>:
// - Need count without iteration
// - Add/remove operations required
// - No indexing needed
public ICollection<string> GetTags()
{
    return new HashSet<string> { "C#", ".NET", "Azure" };
}

// IList<T>:
// - Random access by index required
// - Position-based operations needed
// - Concrete list returned
public IList<string> GetOrderedItems()
{
    return new List<string> { "First", "Second", "Third" };
}

// IQueryable<T>:
// - Database/external source queries
// - Allow caller to build complex queries
// - Provider translates to external query language
public IQueryable<Order> GetOrders()
{
    return _context.Orders;  // Caller can add Where, OrderBy, etc.
}
```

**Decision Tree:**
```
Need database querying? → IQueryable<T>
Need indexing/insertion? → IList<T>
Need Add/Remove/Count? → ICollection<T>
Just iteration? → IEnumerable<T>
```

---

### Q14: What is the yield keyword? How does it work?

**Yield Keyword:**
- Creates iterator method
- Returns IEnumerable<T> or IEnumerator<T>
- Lazy evaluation (deferred execution)
- State machine generated by compiler
- Memory efficient (no temporary collection)

**Two Forms:**
- `yield return` - returns element and pauses
- `yield break` - ends iteration

**Example:**
```csharp
// ============ BASIC YIELD USAGE ============

public class YieldBasics
{
    // Without yield - eager evaluation
    public IEnumerable<int> GetNumbersEager()
    {
        Console.WriteLine("Creating list...");
        var list = new List<int>();

        for (int i = 1; i <= 5; i++)
        {
            Console.WriteLine($"Generating {i}");
            list.Add(i);
        }

        Console.WriteLine("Returning list");
        return list;  // All generated upfront
    }

    // With yield - lazy evaluation
    public IEnumerable<int> GetNumbersLazy()
    {
        Console.WriteLine("Starting generation...");

        for (int i = 1; i <= 5; i++)
        {
            Console.WriteLine($"Yielding {i}");
            yield return i;  // Returns one at a time
        }

        Console.WriteLine("Generation complete");
    }

    public void DemonstrateExecution()
    {
        Console.WriteLine("=== EAGER ===");
        var eager = GetNumbersEager();  // All 5 generated immediately
        Console.WriteLine("Got sequence");
        foreach (var n in eager)
        {
            Console.WriteLine($"Using {n}");
        }

        Console.WriteLine("\n=== LAZY ===");
        var lazy = GetNumbersLazy();  // Nothing generated yet
        Console.WriteLine("Got sequence");
        foreach (var n in lazy)
        {
            Console.WriteLine($"Using {n}");
            if (n == 3) break;  // Only generates 1, 2, 3
        }
    }
}

/* Output:
=== EAGER ===
Creating list...
Generating 1
Generating 2
Generating 3
Generating 4
Generating 5
Returning list
Got sequence
Using 1
Using 2
Using 3
Using 4
Using 5

=== LAZY ===
Starting generation...
Got sequence
Yielding 1
Using 1
Yielding 2
Using 2
Yielding 3
Using 3
*/

// ============ YIELD BREAK ============

public IEnumerable<int> GetNumbersWithCondition(int max)
{
    for (int i = 1; i <= 100; i++)
    {
        if (i > max)
            yield break;  // Stop iteration

        yield return i;
    }
}

// Usage
var numbers = GetNumbersWithCondition(5);  // Only 1-5
foreach (var n in numbers)
    Console.WriteLine(n);  // 1, 2, 3, 4, 5

// ============ INFINITE SEQUENCES ============

public class InfiniteSequences
{
    // Infinite sequence (only possible with yield)
    public IEnumerable<int> GetInfiniteNumbers()
    {
        int i = 0;
        while (true)
        {
            yield return i++;
        }
    }

    // Fibonacci sequence
    public IEnumerable<long> Fibonacci()
    {
        long a = 0, b = 1;

        while (true)
        {
            yield return a;
            (a, b) = (b, a + b);
        }
    }

    public void UseInfiniteSequences()
    {
        // Take only what you need
        var first10 = GetInfiniteNumbers().Take(10);
        foreach (var n in first10)
            Console.WriteLine(n);  // 0-9

        // First 15 Fibonacci numbers
        var fib15 = Fibonacci().Take(15);
        Console.WriteLine(string.Join(", ", fib15));
        // 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377
    }
}

// ============ FILTERING WITH YIELD ============

public class FilteringExample
{
    public IEnumerable<T> Filter<T>(
        IEnumerable<T> source,
        Func<T, bool> predicate)
    {
        foreach (var item in source)
        {
            if (predicate(item))
                yield return item;
        }
    }

    public IEnumerable<User> GetActiveUsers(IEnumerable<User> users)
    {
        foreach (var user in users)
        {
            // Can have complex logic
            if (user.IsActive && user.LastLoginDate > DateTime.Now.AddDays(-30))
            {
                Console.WriteLine($"Processing {user.Name}");
                yield return user;
            }
        }
    }
}

// ============ TREE TRAVERSAL ============

public class TreeNode
{
    public int Value { get; set; }
    public List<TreeNode> Children { get; set; } = new();
}

public class TreeTraversal
{
    // Depth-first traversal with yield
    public IEnumerable<TreeNode> DepthFirst(TreeNode root)
    {
        if (root == null)
            yield break;

        yield return root;

        foreach (var child in root.Children)
        {
            foreach (var node in DepthFirst(child))
            {
                yield return node;
            }
        }
    }

    // Breadth-first traversal
    public IEnumerable<TreeNode> BreadthFirst(TreeNode root)
    {
        if (root == null)
            yield break;

        var queue = new Queue<TreeNode>();
        queue.Enqueue(root);

        while (queue.Count > 0)
        {
            var node = queue.Dequeue();
            yield return node;

            foreach (var child in node.Children)
                queue.Enqueue(child);
        }
    }
}

// Usage
var tree = new TreeNode
{
    Value = 1,
    Children = new List<TreeNode>
    {
        new TreeNode { Value = 2 },
        new TreeNode { Value = 3, Children = new() { new TreeNode { Value = 4 } } }
    }
};

var traversal = new TreeTraversal();
foreach (var node in traversal.DepthFirst(tree))
    Console.WriteLine(node.Value);  // 1, 2, 3, 4

// ============ PAGING WITH YIELD ============

public class PagingExample
{
    public IEnumerable<List<T>> GetPages<T>(
        IEnumerable<T> source,
        int pageSize)
    {
        var page = new List<T>(pageSize);

        foreach (var item in source)
        {
            page.Add(item);

            if (page.Count == pageSize)
            {
                yield return page;
                page = new List<T>(pageSize);
            }
        }

        if (page.Count > 0)
            yield return page;
    }

    public void ProcessLargeDataset()
    {
        var largeData = Enumerable.Range(1, 1000000);

        foreach (var page in GetPages(largeData, 100))
        {
            // Process 100 items at a time
            ProcessPage(page);

            // Only 100 items in memory at once
        }
    }
}

// ============ FILE READING WITH YIELD ============

public class FileReading
{
    public IEnumerable<string> ReadLines(string filePath)
    {
        using var reader = new StreamReader(filePath);
        string line;

        while ((line = reader.ReadLine()) != null)
        {
            yield return line;
        }
    }

    // Process large file without loading all into memory
    public void ProcessLargeFile(string path)
    {
        foreach (var line in ReadLines(path))
        {
            if (line.StartsWith("ERROR"))
            {
                ProcessError(line);
            }

            // Only one line in memory at a time
        }
    }
}

// ============ CUSTOM LINQ OPERATORS ============

public static class CustomLinq
{
    // Custom operator with yield
    public static IEnumerable<T> TakeEvery<T>(
        this IEnumerable<T> source,
        int step)
    {
        int count = 0;
        foreach (var item in source)
        {
            if (count++ % step == 0)
                yield return item;
        }
    }

    // DistinctUntilChanged
    public static IEnumerable<T> DistinctUntilChanged<T>(
        this IEnumerable<T> source)
    {
        using var enumerator = source.GetEnumerator();

        if (!enumerator.MoveNext())
            yield break;

        var previous = enumerator.Current;
        yield return previous;

        while (enumerator.MoveNext())
        {
            if (!EqualityComparer<T>.Default.Equals(
                previous, enumerator.Current))
            {
                previous = enumerator.Current;
                yield return previous;
            }
        }
    }
}

// Usage
var numbers = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
var everyThird = numbers.TakeEvery(3);  // 1, 4, 7, 10

var sequence = new[] { 1, 1, 2, 2, 2, 3, 1, 1 };
var distinct = sequence.DistinctUntilChanged();  // 1, 2, 3, 1

// ============ YIELD UNDER THE HOOD ============

// What compiler generates (simplified):
/*
public IEnumerable<int> GetNumbers()
{
    yield return 1;
    yield return 2;
    yield return 3;
}

// Becomes state machine:
private class <GetNumbers>d__0 : IEnumerable<int>, IEnumerator<int>
{
    private int state;
    private int current;

    public bool MoveNext()
    {
        switch (state)
        {
            case 0:
                current = 1;
                state = 1;
                return true;
            case 1:
                current = 2;
                state = 2;
                return true;
            case 2:
                current = 3;
                state = 3;
                return true;
            default:
                return false;
        }
    }

    public int Current => current;
}
*/
```

**Benefits:**
- Memory efficient (streaming)
- Lazy evaluation
- Can create infinite sequences
- Simpler code for iterators
- Composable with LINQ

**Limitations:**
- Cannot use yield in try-catch (only try-finally)
- Cannot use in anonymous methods/lambdas
- Cannot have ref/out parameters
- Multiple enumeration re-executes logic

---

### Q15: Explain the difference between var, dynamic, and object keywords.

**var:**
- Implicitly typed local variable
- Compile-time type inference
- Strongly typed once inferred
- Must be initialized
- Type cannot change

**dynamic:**
- Runtime type binding
- Type checking deferred to runtime
- Type can hold any value
- Late binding
- Performance overhead

**object:**
- Base type of all types
- Compile-time type checking
- Boxing for value types
- Requires casting for operations
- Strongly typed as object

**Example:**
```csharp
// ============ VAR ============

public class VarExamples
{
    public void VarUsage()
    {
        // Compiler infers type from right side
        var number = 10;  // int
        var text = "Hello";  // string
        var list = new List<string>();  // List<string>
        var person = new Person();  // Person

        // Type is fixed after inference
        number = 20;  // OK - still int
        // number = "text";  // Compilation error!

        // Must be initialized
        // var x;  // Compilation error - cannot infer type

        // Equivalent to explicit typing
        int explicitNumber = 10;  // Same as var number = 10;

        // Useful for complex types
        var dictionary = new Dictionary<string, List<int>>();
        // vs
        Dictionary<string, List<int>> explicitDict =
            new Dictionary<string, List<int>>();

        // Required for anonymous types
        var anonymous = new { Name = "John", Age = 30 };
        // No way to explicitly declare anonymous type

        // LINQ queries
        var query = from p in people
                    where p.Age > 18
                    select new { p.Name, p.Age };
        // Type is IEnumerable<anonymousType>
    }
}

// ============ DYNAMIC ============

public class DynamicExamples
{
    public void DynamicUsage()
    {
        // Can hold any type, checked at runtime
        dynamic value = 10;
        Console.WriteLine(value.GetType());  // System.Int32

        value = "Hello";  // Type changed
        Console.WriteLine(value.GetType());  // System.String

        value = new Person { Name = "John" };
        Console.WriteLine(value.GetType());  // Person

        // Operations resolved at runtime
        dynamic a = 10;
        dynamic b = 20;
        dynamic result = a + b;  // 30 - works

        a = "Hello";
        b = " World";
        result = a + b;  // "Hello World" - works

        // Runtime error if operation not supported
        try
        {
            a = 10;
            b = "text";
            result = a + b;  // RuntimeBinderException!
        }
        catch (Microsoft.CSharp.RuntimeBinder.RuntimeBinderException ex)
        {
            Console.WriteLine($"Runtime error: {ex.Message}");
        }

        // Bypass compile-time checking
        dynamic person = new Person();
        person.NonExistentMethod();  // Compiles, fails at runtime!
    }

    // Dynamic parameter
    public void ProcessDynamic(dynamic input)
    {
        // Don't know type at compile time
        Console.WriteLine(input.ToString());

        // Can call any method (checked at runtime)
        try
        {
            var length = input.Length;  // Works if input has Length
        }
        catch { }
    }

    // Use cases for dynamic
    public void DynamicUseCases()
    {
        // 1. COM Interop (Office automation)
        dynamic excel = Activator.CreateInstance(
            Type.GetTypeFromProgID("Excel.Application"));
        excel.Visible = true;
        dynamic workbook = excel.Workbooks.Add();

        // 2. JSON deserialization
        dynamic json = JsonConvert.DeserializeObject(jsonString);
        string name = json.name;  // Access properties dynamically
        int age = json.age;

        // 3. DLR (Dynamic Language Runtime) integration
        dynamic pythonEngine = GetPythonEngine();
        pythonEngine.Execute("print('Hello from Python')");

        // 4. Reflection alternative
        dynamic obj = Activator.CreateInstance(someType);
        obj.SomeMethod();  // Cleaner than reflection
    }
}

// ============ OBJECT ============

public class ObjectExamples
{
    public void ObjectUsage()
    {
        // Can hold any type (everything inherits from object)
        object value = 10;  // Boxing occurs
        Console.WriteLine(value.GetType());  // System.Int32

        value = "Hello";  // No boxing (reference type)
        Console.WriteLine(value.GetType());  // System.String

        // Requires casting for operations
        object num1 = 10;
        object num2 = 20;
        // var sum = num1 + num2;  // Compilation error!

        // Must cast
        int sum = (int)num1 + (int)num2;  // 30

        // Runtime error if wrong cast
        try
        {
            object text = "Hello";
            int wrongCast = (int)text;  // InvalidCastException!
        }
        catch (InvalidCastException ex)
        {
            Console.WriteLine($"Cast failed: {ex.Message}");
        }

        // Safe casting
        object maybeInt = "not an int";
        if (maybeInt is int intValue)
        {
            Console.WriteLine($"It's an int: {intValue}");
        }
        else
        {
            Console.WriteLine("Not an int");
        }

        // Pattern matching (C# 7+)
        object data = GetData();
        switch (data)
        {
            case int i:
                Console.WriteLine($"Integer: {i}");
                break;
            case string s:
                Console.WriteLine($"String: {s}");
                break;
            case Person p:
                Console.WriteLine($"Person: {p.Name}");
                break;
            default:
                Console.WriteLine("Unknown type");
                break;
        }
    }

    // Object parameter - accepts anything
    public void PrintValue(object value)
    {
        Console.WriteLine(value?.ToString() ?? "null");
    }

    // Boxing performance impact
    public void BoxingPerformance()
    {
        // Boxing - slow
        ArrayList list = new ArrayList();
        for (int i = 0; i < 1000000; i++)
        {
            list.Add(i);  // Boxing every iteration!
        }

        // No boxing - fast
        List<int> genericList = new List<int>();
        for (int i = 0; i < 1000000; i++)
        {
            genericList.Add(i);  // No boxing
        }
    }
}

// ============ COMPARISON ============

public class ComparisonExamples
{
    public void CompareAll()
    {
        // var - compile-time inference
        var varInt = 10;  // Type: int (inferred)
        // varInt = "text";  // ERROR - type is fixed
        var result1 = varInt + 5;  // OK - knows it's int

        // dynamic - runtime binding
        dynamic dynInt = 10;  // Type: int (runtime)
        dynInt = "text";  // OK - type can change
        // var result2 = dynInt + 5;  // Compiles, may fail at runtime

        // object - base type
        object objInt = 10;  // Type: object (boxing)
        objInt = "text";  // OK - object holds anything
        // var result3 = objInt + 5;  // ERROR - must cast first
        var result3 = (int)objInt + 5;  // Must cast
    }

    // Performance comparison
    public void PerformanceTest()
    {
        int iterations = 10000000;
        var sw = System.Diagnostics.Stopwatch.StartNew();

        // var/explicit type - fastest (no overhead)
        sw.Restart();
        int sum1 = 0;
        for (var i = 0; i < iterations; i++)
        {
            sum1 += i;
        }
        Console.WriteLine($"var: {sw.ElapsedMilliseconds}ms");

        // dynamic - slowest (runtime binding)
        sw.Restart();
        dynamic sum2 = 0;
        for (dynamic i = 0; i < iterations; i++)
        {
            sum2 += i;
        }
        Console.WriteLine($"dynamic: {sw.ElapsedMilliseconds}ms");

        // object - slow (boxing/casting)
        sw.Restart();
        object sum3 = 0;
        for (object i = 0; i < iterations; i++)
        {
            sum3 = (int)sum3 + (int)i;
        }
        Console.WriteLine($"object: {sw.ElapsedMilliseconds}ms");
    }
}
```

**Comparison Table:**
| Feature | var | dynamic | object |
|---------|-----|---------|--------|
| Type Resolution | Compile-time | Runtime | Compile-time |
| Type Checking | Strong | Deferred | Strong |
| Type Change | No | Yes | No |
| Performance | Fast | Slow | Moderate |
| IntelliSense | Yes | No | Limited |
| Boxing (value types) | No | No | Yes |
| Must Initialize | Yes | No | No |
| Scope | Local only | Any | Any |

**When to Use:**
- **var:** Prefer for local variables when type is obvious
- **dynamic:** COM interop, JSON, DLR scenarios only
- **object:** Generic storage, boxing, legacy code

**Best Practices:**
- Default to explicit types or var
- Avoid dynamic unless necessary
- Use object sparingly (prefer generics)
- var improves readability with complex types
- Never use dynamic to bypass type safety

---

### Q16: What are nullable value types? Explain the null-coalescing operator.

**Nullable Value Types:**
- Allow value types to be null
- Syntax: `T?` or `Nullable<T>`
- Has `HasValue` and `Value` properties
- Used when absence of value needs to be represented
- Common in database scenarios (NULL columns)

**Null-Coalescing Operators:**
- `??` - returns left if not null, otherwise right
- `??=` - assigns right if left is null (C# 8+)
- `?.` - null-conditional operator
- `?[]` - null-conditional element access

**Example:**
```csharp
// ============ NULLABLE VALUE TYPES ============

public class NullableExamples
{
    public void BasicNullable()
    {
        // Regular int cannot be null
        // int regular = null;  // ERROR

        // Nullable int can be null
        int? nullable = null;  // OK
        Nullable<int> nullable2 = null;  // Same thing

        // Check if has value
        if (nullable.HasValue)
        {
            Console.WriteLine($"Value: {nullable.Value}");
        }
        else
        {
            Console.WriteLine("No value");
        }

        // Assign value
        nullable = 42;
        Console.WriteLine($"Has value: {nullable.HasValue}");  // True
        Console.WriteLine($"Value: {nullable.Value}");  // 42

        // Access Value when null throws exception
        nullable = null;
        try
        {
            int value = nullable.Value;  // InvalidOperationException
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("Cannot access Value when null");
        }

        // Safe access methods
        int safe1 = nullable.GetValueOrDefault();  // 0 (default)
        int safe2 = nullable.GetValueOrDefault(99);  // 99 (custom default)
    }

    // ============ NULL-COALESCING OPERATOR (??) ============

    public void NullCoalescingOperator()
    {
        int? maybeInt = null;

        // ?? operator - provide default
        int result = maybeInt ?? 0;  // 0
        Console.WriteLine(result);

        maybeInt = 42;
        result = maybeInt ?? 0;  // 42
        Console.WriteLine(result);

        // Chain multiple ??
        int? first = null;
        int? second = null;
        int? third = 99;

        int value = first ?? second ?? third ?? 0;  // 99
        Console.WriteLine(value);

        // With reference types
        string? text = null;
        string result2 = text ?? "default";  // "default"

        text = "hello";
        result2 = text ?? "default";  // "hello"

        // Complex expressions
        string name = GetUserName() ?? GetDefaultName() ?? "Anonymous";
    }

    // ============ NULL-COALESCING ASSIGNMENT (??=) ============

    public void NullCoalescingAssignment()
    {
        List<string>? items = null;

        // Assign if null
        items ??= new List<string>();  // Creates new list
        items ??= new List<string>();  // Does nothing (already has value)

        // Equivalent to:
        items = items ?? new List<string>();

        // Lazy initialization
        private List<string>? _cache;
        public List<string> Cache => _cache ??= LoadCache();

        // Multiple properties
        int? count = null;
        count ??= 0;  // Assign 0 if null
        count ??= 10;  // Does nothing (count is 0, not null)
    }

    // ============ NULL-CONDITIONAL OPERATOR (?.) ============

    public void NullConditionalOperator()
    {
        Person? person = null;

        // Without null-conditional
        string? name1 = person != null ? person.Name : null;

        // With null-conditional
        string? name2 = person?.Name;  // null if person is null

        // Chaining
        string? city = person?.Address?.City;

        // With method calls
        int? length = person?.Name?.Length;

        // Array/indexer access
        string? firstChar = person?.Name?[0].ToString();

        // Event invocation
        EventHandler? handler = SomeEvent;
        handler?.Invoke(this, EventArgs.Empty);

        // Combining operators
        string displayName = person?.Name ?? "Unknown";
        int nameLength = person?.Name?.Length ?? 0;
    }

    // ============ REAL-WORLD EXAMPLES ============

    public class DatabaseExample
    {
        public class User
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public int? Age { get; set; }  // Nullable - might not be provided
            public DateTime? LastLogin { get; set; }  // Nullable - new users
            public decimal? Balance { get; set; }  // Nullable - account might not exist
        }

        public void HandleDatabaseNulls()
        {
            var user = GetUserFromDatabase(123);

            // Safe handling of nullable properties
            int age = user.Age ?? 18;  // Default to 18 if not provided

            string lastLogin = user.LastLogin?.ToString("yyyy-MM-dd")
                ?? "Never logged in";

            decimal balance = user.Balance ?? 0m;

            // Conditional logic
            if (user.Age.HasValue && user.Age.Value < 18)
            {
                Console.WriteLine("Minor");
            }

            // Pattern matching (C# 7+)
            string ageCategory = user.Age switch
            {
                null => "Age not provided",
                < 18 => "Minor",
                >= 18 and < 65 => "Adult",
                >= 65 => "Senior",
                _ => "Unknown"
            };
        }
    }

    // ============ NULLABLE REFERENCE TYPES (C# 8+) ============

    #nullable enable  // Enable nullable reference types

    public class NullableReferenceExample
    {
        // Non-nullable reference type
        public string Name { get; set; } = string.Empty;

        // Nullable reference type
        public string? MiddleName { get; set; }

        public void Process(string nonNull, string? maybeNull)
        {
            // Compiler warning if non-null is potentially null
            // string result = maybeNull;  // Warning!

            // Must check or use null-forgiving operator
            string result1 = maybeNull ?? "default";  // Safe

            if (maybeNull != null)
            {
                string result2 = maybeNull;  // No warning after null check
            }

            // Null-forgiving operator (!) - use with caution
            string result3 = maybeNull!;  // Tells compiler "trust me, not null"
        }
    }

    #nullable restore

    // ============ COMPARISON OPERATORS ============

    public void ComparisonWithNullable()
    {
        int? a = null;
        int? b = 5;
        int? c = 5;

        // Comparison with null
        Console.WriteLine(a == null);  // True
        Console.WriteLine(b == null);  // False

        // Comparison between nullables
        Console.WriteLine(a == b);  // False
        Console.WriteLine(b == c);  // True

        // Lifted operators - any null operand results in null
        int? sum = a + b;  // null (not 5!)
        int? product = b * c;  // 25

        bool? comparison = a < b;  // null
        bool? isEqual = a == b;  // false (special case)

        // With null-coalescing
        int safeSum = (a ?? 0) + (b ?? 0);  // 5
    }

    // ============ LINQ WITH NULLABLE ============

    public void LinqWithNullable()
    {
        var products = new List<Product>
        {
            new() { Name = "A", Price = 10, Discount = null },
            new() { Name = "B", Price = 20, Discount = 5 },
            new() { Name = "C", Price = 30, Discount = null }
        };

        // Sum with nullable
        decimal? totalDiscount = products.Sum(p => p.Discount);  // 5

        // Average with nullable
        decimal? avgDiscount = products
            .Where(p => p.Discount.HasValue)
            .Average(p => p.Discount);  // 5

        // Filter by nullable
        var withDiscounts = products
            .Where(p => p.Discount.HasValue)
            .ToList();

        var withoutDiscounts = products
            .Where(p => !p.Discount.HasValue)
            .ToList();

        // Calculate final price
        var finalPrices = products
            .Select(p => new
            {
                p.Name,
                OriginalPrice = p.Price,
                Discount = p.Discount ?? 0,
                FinalPrice = p.Price - (p.Discount ?? 0)
            });
    }
}

public class Product
{
    public string Name { get; set; }
    public decimal Price { get; set; }
    public decimal? Discount { get; set; }  // Optional
}
```

**Key Points:**
- `T?` is shorthand for `Nullable<T>`
- Only works with value types (int, bool, DateTime, etc.)
- `??` operator prevents null reference exceptions
- `?.` operator chains safely through null checks
- C# 8+ extends nullability to reference types

---

### Q17: What is the difference between String and StringBuilder?

**String:**
- Immutable (cannot be changed)
- Each modification creates new string object
- Thread-safe (immutability)
- Stored in string intern pool (optional)
- Best for few modifications

**StringBuilder:**
- Mutable (can be changed)
- Modifies same object
- Not thread-safe
- Better performance for multiple modifications
- Resizable buffer

**Example:**
```csharp
// ============ STRING IMMUTABILITY ============

public class StringImmutability
{
    public void DemonstrateImmutability()
    {
        string original = "Hello";
        string modified = original.ToUpper();

        Console.WriteLine($"Original: {original}");  // "Hello" (unchanged!)
        Console.WriteLine($"Modified: {modified}");  // "HELLO" (new string)

        // Each operation creates new string
        string result = "Hello";
        result = result + " World";  // New string created
        result = result + "!";        // Another new string
        result = result.Replace("World", "Universe");  // Yet another

        // Memory visualization:
        // [Hello] [Hello World] [Hello World!] [Hello Universe!]
        // All exist in memory (garbage collected later)
    }

    // Performance problem with strings
    public void StringConcatenationProblem()
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();

        string result = "";
        for (int i = 0; i < 10000; i++)
        {
            result += i.ToString();  // Creates 10,000 new string objects!
        }

        sw.Stop();
        Console.WriteLine($"String: {sw.ElapsedMilliseconds}ms");
        // Typical: 200-500ms (O(n²) complexity)
    }
}

// ============ STRINGBUILDER EFFICIENCY ============

public class StringBuilderExamples
{
    public void StringBuilderConcatenation()
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10000; i++)
        {
            sb.Append(i.ToString());  // Modifies same object
        }
        string result = sb.ToString();

        sw.Stop();
        Console.WriteLine($"StringBuilder: {sw.ElapsedMilliseconds}ms");
        // Typical: 2-5ms (O(n) complexity)
    }

    public void StringBuilderOperations()
    {
        StringBuilder sb = new StringBuilder();

        // Append
        sb.Append("Hello");
        sb.Append(" ");
        sb.Append("World");

        // Append with formatting
        sb.AppendFormat("Number: {0}", 42);

        // AppendLine
        sb.AppendLine("First line");
        sb.AppendLine("Second line");

        // Insert
        sb.Insert(0, "Start: ");

        // Remove
        sb.Remove(0, 7);  // Remove "Start: "

        // Replace
        sb.Replace("World", "Universe");

        // Clear
        sb.Clear();

        // Capacity management
        StringBuilder sb2 = new StringBuilder(capacity: 100);
        Console.WriteLine($"Capacity: {sb2.Capacity}");

        // Convert to string
        string final = sb.ToString();
    }

    // ============ REAL-WORLD EXAMPLES ============

    public string BuildHtmlTable(List<User> users)
    {
        var sb = new StringBuilder();

        sb.AppendLine("<table>");
        sb.AppendLine("  <tr>");
        sb.AppendLine("    <th>ID</th><th>Name</th><th>Email</th>");
        sb.AppendLine("  </tr>");

        foreach (var user in users)
        {
            sb.AppendLine("  <tr>");
            sb.AppendFormat("    <td>{0}</td>", user.Id).AppendLine();
            sb.AppendFormat("    <td>{0}</td>", user.Name).AppendLine();
            sb.AppendFormat("    <td>{0}</td>", user.Email).AppendLine();
            sb.AppendLine("  </tr>");
        }

        sb.AppendLine("</table>");

        return sb.ToString();
    }

    public string GenerateSqlInsert(List<Product> products)
    {
        var sb = new StringBuilder();

        sb.AppendLine("INSERT INTO Products (Name, Price, Category) VALUES");

        for (int i = 0; i < products.Count; i++)
        {
            var p = products[i];
            sb.AppendFormat("('{0}', {1}, '{2}')",
                p.Name.Replace("'", "''"),  // SQL injection prevention
                p.Price,
                p.Category);

            if (i < products.Count - 1)
                sb.AppendLine(",");
            else
                sb.AppendLine(";");
        }

        return sb.ToString();
    }

    // Build log message
    public string BuildLogMessage(Exception ex)
    {
        var sb = new StringBuilder();

        sb.AppendLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ERROR");
        sb.AppendLine($"Message: {ex.Message}");
        sb.AppendLine($"Type: {ex.GetType().Name}");
        sb.AppendLine($"Stack Trace:");
        sb.AppendLine(ex.StackTrace);

        if (ex.InnerException != null)
        {
            sb.AppendLine("Inner Exception:");
            sb.AppendLine(BuildLogMessage(ex.InnerException));
        }

        return sb.ToString();
    }

    // Build CSV
    public string BuildCsv<T>(List<T> data)
    {
        var sb = new StringBuilder();
        var properties = typeof(T).GetProperties();

        // Header
        sb.AppendLine(string.Join(",", properties.Select(p => p.Name)));

        // Data rows
        foreach (var item in data)
        {
            var values = properties.Select(p =>
            {
                var value = p.GetValue(item)?.ToString() ?? "";
                return value.Contains(",") ? $"\"{value}\"" : value;
            });
            sb.AppendLine(string.Join(",", values));
        }

        return sb.ToString();
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceComparison
{
    public void ComparePerformance(int iterations)
    {
        // String concatenation
        var sw = System.Diagnostics.Stopwatch.StartNew();
        string strResult = "";
        for (int i = 0; i < iterations; i++)
        {
            strResult += "a";
        }
        sw.Stop();
        long stringTime = sw.ElapsedMilliseconds;

        // StringBuilder
        sw.Restart();
        var sb = new StringBuilder();
        for (int i = 0; i < iterations; i++)
        {
            sb.Append("a");
        }
        string sbResult = sb.ToString();
        sw.Stop();
        long sbTime = sw.ElapsedMilliseconds;

        // String.Join (good alternative for arrays)
        sw.Restart();
        var array = new string[iterations];
        for (int i = 0; i < iterations; i++)
        {
            array[i] = "a";
        }
        string joinResult = string.Join("", array);
        sw.Stop();
        long joinTime = sw.ElapsedMilliseconds;

        Console.WriteLine($"String: {stringTime}ms");
        Console.WriteLine($"StringBuilder: {sbTime}ms");
        Console.WriteLine($"String.Join: {joinTime}ms");
        Console.WriteLine($"StringBuilder is {stringTime / sbTime}x faster");
    }
}
```

**Comparison Table:**
| Feature | String | StringBuilder |
|---------|---------|---------------|
| Mutability | Immutable | Mutable |
| Performance (many changes) | Slow | Fast |
| Memory | Creates many objects | Reuses buffer |
| Thread-safe | Yes | No |
| Syntax | Simple | More verbose |
| Best for | Few operations | Many operations |

**When to Use:**
- **String:** <5 concatenations, constant strings, thread-safety needed
- **StringBuilder:** Loops, multiple modifications, building large strings
- **String.Join():** Joining array/collection elements

**Best Practices:**
```csharp
// GOOD - few operations
string name = firstName + " " + lastName;

// GOOD - string interpolation (few operations)
string message = $"Hello {name}, you have {count} messages";

// BAD - loop with string concatenation
string result = "";
foreach (var item in items)
{
    result += item.ToString();  // Creates new string each time
}

// GOOD - loop with StringBuilder
var sb = new StringBuilder();
foreach (var item in items)
{
    sb.Append(item.ToString());  // Modifies buffer
}
string result = sb.ToString();

// BEST - String.Join for collections
string result = string.Join("", items.Select(i => i.ToString()));
```

---

### Q18: Explain string interning in .NET.

**String Interning:**
- Process where identical string literals share same memory location
- .NET maintains an internal string pool (intern pool)
- Reduces memory usage for duplicate strings
- Improves performance for string comparisons
- Automatic for compile-time constants
- Manual via `String.Intern()` method

**Example:**
```csharp
public class StringInterningExamples
{
    public void BasicIntern

ing()
    {
        // Compile-time literals are automatically interned
        string s1 = "hello";
        string s2 = "hello";
        string s3 = "hello";

        // All reference same object in intern pool
        Console.WriteLine(object.ReferenceEquals(s1, s2));  // True
        Console.WriteLine(object.ReferenceEquals(s2, s3));  // True

        // Runtime string concatenation - NOT interned
        string s4 = "hel" + "lo";  // Compiler optimizes to "hello" - interned
        string s5 = string.Concat("hel", "lo");  // Runtime - NOT interned

        Console.WriteLine(object.ReferenceEquals(s1, s4));  // True (compiler optimization)
        Console.WriteLine(object.ReferenceEquals(s1, s5));  // False (runtime creation)

        // Manual interning
        string s6 = String.Intern(s5);
        Console.WriteLine(object.ReferenceEquals(s1, s6));  // True (now interned)
    }

    public void ManualInterning()
    {
        // Check if string is already interned
        string s1 = "test";
        string s2 = String.IsInterned("test");  // Returns "test" from pool

        Console.WriteLine(s2 != null);  // True (found in pool)
        Console.WriteLine(object.ReferenceEquals(s1, s2));  // True

        // Not interned
        string s3 = new string("new".ToCharArray());
        string s4 = String.IsInterned(s3);

        Console.WriteLine(s4 == null);  // True (not in pool)

        // Manually intern
        string s5 = String.Intern(s3);
        string s6 = String.IsInterned(s3);

        Console.WriteLine(object.ReferenceEquals(s5, s6));  // True
    }

    // Performance comparison
    public void PerformanceComparison()
    {
        string[] strings = new string[10000];

        // Without interning - multiple string objects
        var sw = System.Diagnostics.Stopwatch.StartNew();
        for (int i = 0; i < strings.Length; i++)
        {
            strings[i] = $"value_{i % 100}";  // Only 100 unique values
        }
        sw.Stop();
        Console.WriteLine($"Without interning: {sw.ElapsedMilliseconds}ms");

        // With interning - reuse string objects
        sw.Restart();
        for (int i = 0; i < strings.Length; i++)
        {
            strings[i] = String.Intern($"value_{i % 100}");
        }
        sw.Stop();
        Console.WriteLine($"With interning: {sw.ElapsedMilliseconds}ms");

        // Memory usage also reduced with interning
    }

    // Real-world example
    public class ConfigurationManager
    {
        private Dictionary<string, string> _settings = new();

        public void LoadSettings(string[] lines)
        {
            foreach (var line in lines)
            {
                var parts = line.Split('=');
                if (parts.Length == 2)
                {
                    // Intern keys - often repeated
                    string key = String.Intern(parts[0].Trim());
                    string value = parts[1].Trim();

                    _settings[key] = value;
                }
            }
        }

        // Many lookups with same keys benefit from interning
        public string GetSetting(string key)
        {
            // Intern the lookup key for faster comparison
            key = String.Intern(key);
            return _settings.TryGetValue(key, out var value) ? value : null;
        }
    }
}
```

**When to Use:**
- ✅ Repeated string literals (configuration keys, enum values)
- ✅ String dictionary keys with many duplicates
- ✅ Parsing/processing with repeated tokens
- ❌ Unique strings (wastes intern pool space)
- ❌ Large strings (increases pool size)
- ❌ Short-lived strings (permanent in pool until AppDomain unload)

**Important Notes:**
- Interned strings live until AppDomain unloads
- Can cause memory leaks if overused
- Thread-safe (intern pool is thread-safe)
- Equality checks faster (reference comparison)

---

### Q19: What are generics? Why are they important?

**Generics:**
- Type parameters for classes, methods, interfaces, delegates
- Define placeholder types (T, TKey, TValue, etc.)
- Compile-time type safety
- Code reuse without boxing/casting
- Better performance than non-generic collections

**Why Important:**
- **Type Safety:** Compile-time checking prevents runtime errors
- **Performance:** No boxing for value types
- **Code Reuse:** Write once, use with any type
- **IntelliSense:** Better IDE support
- **Eliminates Casting:** No need for explicit casts

**Example:**
```csharp
// ============ GENERIC CLASSES ============

// Generic class definition
public class Box<T>
{
    private T _value;

    public Box(T value)
    {
        _value = value;
    }

    public T GetValue()
    {
        return _value;
    }

    public void SetValue(T value)
    {
        _value = value;
    }
}

// Usage
var intBox = new Box<int>(42);
int value = intBox.GetValue();  // No casting needed

var stringBox = new Box<string>("Hello");
string text = stringBox.GetValue();  // Type-safe

// ============ GENERIC METHODS ============

public class Utils
{
    // Generic method
    public static void Swap<T>(ref T a, ref T b)
    {
        T temp = a;
        a = b;
        b = temp;
    }

    // Generic method with constraints
    public static T Max<T>(T a, T b) where T : IComparable<T>
    {
        return a.CompareTo(b) > 0 ? a : b;
    }

    // Multiple type parameters
    public static TResult Convert<TInput, TResult>(
        TInput input,
        Func<TInput, TResult> converter)
    {
        return converter(input);
    }
}

// Usage
int x = 5, y = 10;
Utils.Swap(ref x, ref y);  // Type inferred
Console.WriteLine($"x={x}, y={y}");  // x=10, y=5

int max = Utils.Max(5, 10);  // 10
string maxStr = Utils.Max("apple", "banana");  // "banana"

string result = Utils.Convert<int, string>(42, n => n.ToString());

// ============ GENERIC CONSTRAINTS ============

// where T : struct (value type)
public class ValueContainer<T> where T : struct
{
    public T Value { get; set; }
}
// ValueContainer<int> valid
// ValueContainer<string> ERROR - string is reference type

// where T : class (reference type)
public class ReferenceContainer<T> where T : class
{
    public T? Value { get; set; }
}
// ReferenceContainer<string> valid
// ReferenceContainer<int> ERROR - int is value type

// where T : new() (has parameterless constructor)
public class Factory<T> where T : new()
{
    public T Create()
    {
        return new T();  // Can instantiate
    }
}

// where T : BaseClass (inherits from BaseClass)
public class Repository<T> where T : Entity
{
    public void Save(T entity)
    {
        // Can access Entity properties/methods
        Console.WriteLine($"Saving entity: {entity.Id}");
    }
}

// where T : IInterface (implements interface)
public class Comparer<T> where T : IComparable<T>
{
    public T GetMax(T a, T b)
    {
        return a.CompareTo(b) > 0 ? a : b;
    }
}

// Multiple constraints
public class AdvancedContainer<T>
    where T : class, IDisposable, new()
{
    private T _instance;

    public AdvancedContainer()
    {
        _instance = new T();  // new() constraint
    }

    public void Cleanup()
    {
        _instance?.Dispose();  // IDisposable constraint
    }
}

// ============ GENERIC INTERFACES ============

public interface IRepository<T>
{
    void Add(T item);
    T GetById(int id);
    IEnumerable<T> GetAll();
    void Update(T item);
    void Delete(int id);
}

public class UserRepository : IRepository<User>
{
    private List<User> _users = new();

    public void Add(User item) => _users.Add(item);

    public User GetById(int id) =>
        _users.FirstOrDefault(u => u.Id == id);

    public IEnumerable<User> GetAll() => _users;

    public void Update(User item)
    {
        var existing = GetById(item.Id);
        if (existing != null)
        {
            // Update properties
        }
    }

    public void Delete(int id) =>
        _users.RemoveAll(u => u.Id == id);
}

// ============ GENERIC DELEGATES ============

// Func, Action, Predicate are built-in generic delegates

// Custom generic delegate
public delegate TResult Transformer<TInput, TResult>(TInput input);

// Usage
Transformer<int, string> intToString = n => n.ToString();
string result = intToString(42);  // "42"

Transformer<string, int> stringToLength = s => s.Length;
int length = stringToLength("Hello");  // 5

// ============ COLLECTIONS (WHY GENERICS MATTER) ============

public class CollectionComparison
{
    // Old way - ArrayList (non-generic)
    public void NonGenericCollection()
    {
        ArrayList list = new ArrayList();

        list.Add(1);      // Boxing occurs
        list.Add(2);      // Boxing occurs
        list.Add("text"); // Can add different types!

        int sum = 0;
        foreach (object item in list)
        {
            // Runtime error possible!
            if (item is int)
            {
                sum += (int)item;  // Unboxing + casting
            }
        }
    }

    // New way - List<T> (generic)
    public void GenericCollection()
    {
        List<int> list = new List<int>();

        list.Add(1);      // No boxing
        list.Add(2);      // No boxing
        // list.Add("text");  // Compile-time ERROR!

        int sum = 0;
        foreach (int item in list)  // No casting needed
        {
            sum += item;  // Direct access
        }

        // IntelliSense knows it's List<int>
        int first = list[0];  // Type-safe
    }
}

// ============ GENERIC STACK IMPLEMENTATION ============

public class Stack<T>
{
    private T[] _items;
    private int _count;

    public Stack(int capacity = 10)
    {
        _items = new T[capacity];
        _count = 0;
    }

    public void Push(T item)
    {
        if (_count == _items.Length)
        {
            Array.Resize(ref _items, _items.Length * 2);
        }
        _items[_count++] = item;
    }

    public T Pop()
    {
        if (_count == 0)
            throw new InvalidOperationException("Stack is empty");

        return _items[--_count];
    }

    public T Peek()
    {
        if (_count == 0)
            throw new InvalidOperationException("Stack is empty");

        return _items[_count - 1];
    }

    public int Count => _count;

    public bool IsEmpty => _count == 0;
}

// Usage - works with any type
var intStack = new Stack<int>();
intStack.Push(1);
intStack.Push(2);
int value = intStack.Pop();  // 2

var stringStack = new Stack<string>();
stringStack.Push("Hello");
stringStack.Push("World");
string text = stringStack.Pop();  // "World"

// ============ GENERIC BUILDER PATTERN ============

public class QueryBuilder<T>
{
    private IQueryable<T> _query;

    public QueryBuilder(IQueryable<T> source)
    {
        _query = source;
    }

    public QueryBuilder<T> Where(Expression<Func<T, bool>> predicate)
    {
        _query = _query.Where(predicate);
        return this;
    }

    public QueryBuilder<T> OrderBy<TKey>(
        Expression<Func<T, TKey>> keySelector)
    {
        _query = _query.OrderBy(keySelector);
        return this;
    }

    public QueryBuilder<T> Take(int count)
    {
        _query = _query.Take(count);
        return this;
    }

    public List<T> ToList()
    {
        return _query.ToList();
    }
}

// Usage
var users = new QueryBuilder<User>(dbContext.Users)
    .Where(u => u.Age > 18)
    .OrderBy(u => u.Name)
    .Take(10)
    .ToList();
```

**Performance Comparison:**
```csharp
// Non-generic: ArrayList
ArrayList nonGeneric = new ArrayList();
for (int i = 0; i < 1000000; i++)
{
    nonGeneric.Add(i);  // Boxing: 10-20x slower
}

// Generic: List<int>
List<int> generic = new List<int>();
for (int i = 0; i < 1000000; i++)
{
    generic.Add(i);  // No boxing: Fast
}

// Memory: Generic uses ~50% less memory for value types
```

**Benefits Summary:**
1. **Type Safety:** Errors caught at compile-time
2. **Performance:** 10-100x faster for value types
3. **No Casting:** Cleaner, more readable code
4. **Code Reuse:** One implementation for all types
5. **Better Tooling:** IntelliSense, refactoring support

---

### Q20: Explain covariance and contravariance in C#.

**Variance:**
- Ability to use more derived (covariance) or less derived (contravariance) type than originally specified
- Applies to generic interfaces and delegates
- Uses `out` (covariance) and `in` (contravariance) keywords
- Enables polymorphism with generics

**Covariance (out):**
- Return types can be more derived
- Read-only scenarios
- Keyword: `out T`
- Example: `IEnumerable<out T>`

**Contravariance (in):**
- Parameter types can be less derived
- Write-only scenarios
- Keyword: `in T`
- Example: `IComparer<in T>`

**Example:**
```csharp
// ============ CLASS HIERARCHY ============

public class Animal
{
    public string Name { get; set; }
}

public class Dog : Animal
{
    public void Bark() => Console.WriteLine("Woof!");
}

public class Cat : Animal
{
    public void Meow() => Console.WriteLine("Meow!");
}

// ============ COVARIANCE (out) ============

// Covariant interface - can only return T, not accept it
public interface IProducer<out T>
{
    T Produce();
    // void Consume(T item);  // ERROR - can't use as parameter with 'out'
}

public class AnimalShelter : IProducer<Animal>
{
    public Animal Produce() => new Animal { Name = "Generic Animal" };
}

public class DogShelter : IProducer<Dog>
{
    public Dog Produce() => new Dog { Name = "Buddy" };
}

public class CoVarianceExample
{
    public void DemonstrateCovariance()
    {
        // Covariance: Can assign IProducer<Dog> to IProducer<Animal>
        // Because Dog IS-A Animal (more derived to less derived)
        IProducer<Dog> dogProducer = new DogShelter();
        IProducer<Animal> animalProducer = dogProducer;  // Covariant assignment

        Animal animal = animalProducer.Produce();  // Returns Dog
        Console.WriteLine(animal.Name);

        // Real-world: IEnumerable<out T>
        IEnumerable<Dog> dogs = new List<Dog>
        {
            new Dog { Name = "Buddy" },
            new Dog { Name = "Max" }
        };

        // Covariance: IEnumerable<Dog> can be treated as IEnumerable<Animal>
        IEnumerable<Animal> animals = dogs;  // Valid!

        foreach (Animal a in animals)
        {
            Console.WriteLine(a.Name);
        }

        // Why it's safe: We're only READING (producing) values
        // Can't modify the collection through IEnumerable
    }

    // Method accepting covariant interface
    public void ProcessAnimals(IEnumerable<Animal> animals)
    {
        foreach (var animal in animals)
        {
            Console.WriteLine(animal.Name);
        }
    }

    public void UseCovariance()
    {
        List<Dog> dogs = new List<Dog> { new Dog(), new Dog() };

        // Can pass List<Dog> where IEnumerable<Animal> expected
        ProcessAnimals(dogs);  // Covariance!
    }
}

// ============ CONTRAVARIANCE (in) ============

// Contravariant interface - can only accept T, not return it
public interface IConsumer<in T>
{
    void Consume(T item);
    // T Produce();  // ERROR - can't return T with 'in'
}

public class AnimalFeeder : IConsumer<Animal>
{
    public void Consume(Animal animal)
    {
        Console.WriteLine($"Feeding {animal.Name}");
    }
}

public class ContraVarianceExample
{
    public void DemonstrateContravariance()
    {
        // Contravariance: Can assign IConsumer<Animal> to IConsumer<Dog>
        // Because Animal IS LESS derived than Dog (less derived to more derived)
        IConsumer<Animal> animalConsumer = new AnimalFeeder();
        IConsumer<Dog> dogConsumer = animalConsumer;  // Contravariant assignment

        dogConsumer.Consume(new Dog { Name = "Buddy" });  // Works!

        // Why it's safe: AnimalFeeder can handle ANY animal (including Dogs)
        // Since Dog IS-A Animal, it's safe to pass Dog to Animal handler

        // Real-world: IComparer<in T>
        IComparer<Animal> animalComparer = Comparer<Animal>.Create(
            (a1, a2) => string.Compare(a1.Name, a2.Name));

        // Contravariance: IComparer<Animal> can be used as IComparer<Dog>
        IComparer<Dog> dogComparer = animalComparer;  // Valid!

        var dogs = new List<Dog>
        {
            new Dog { Name = "Zeus" },
            new Dog { Name = "Apollo" }
        };

        dogs.Sort(dogComparer);  // Uses Animal comparer for Dogs
    }

    // Method with contravariant delegate
    public void ProcessDog(Action<Dog> dogAction)
    {
        var dog = new Dog { Name = "Max" };
        dogAction(dog);
    }

    public void UseContravariance()
    {
        // Action<Animal> can be used where Action<Dog> expected
        Action<Animal> animalAction = animal =>
            Console.WriteLine($"Processing: {animal.Name}");

        ProcessDog(animalAction);  // Contravariance!
    }
}

// ============ BUILT-IN EXAMPLES ============

public class BuiltInVariance
{
    public void IEnumerableCovariance()
    {
        // IEnumerable<out T> is covariant
        IEnumerable<string> strings = new List<string> { "a", "b", "c" };
        IEnumerable<object> objects = strings;  // Covariant!

        foreach (object obj in objects)
        {
            Console.WriteLine(obj);
        }
    }

    public void FuncCovariance()
    {
        // Func<out TResult> is covariant on return type
        Func<Dog> dogFactory = () => new Dog { Name = "Buddy" };
        Func<Animal> animalFactory = dogFactory;  // Covariant!

        Animal animal = animalFactory();
        Console.WriteLine(animal.Name);
    }

    public void ActionContravariance()
    {
        // Action<in T> is contravariant on parameter
        Action<Animal> animalAction = animal =>
            Console.WriteLine($"Animal: {animal.Name}");

        Action<Dog> dogAction = animalAction;  // Contravariant!

        dogAction(new Dog { Name = "Max" });
    }

    public void IComparerContravariance()
    {
        // IComparer<in T> is contravariant
        IComparer<object> objectComparer = Comparer<object>.Create(
            (o1, o2) => o1.ToString().CompareTo(o2.ToString()));

        IComparer<string> stringComparer = objectComparer;  // Contravariant!

        var strings = new List<string> { "z", "a", "m" };
        strings.Sort(stringComparer);
    }
}

// ============ CUSTOM VARIANCE EXAMPLE ============

// Covariant interface
public interface IRepository<out T>
{
    T GetById(int id);
    IEnumerable<T> GetAll();
    // void Add(T item);  // ERROR - can't have T as input with 'out'
}

// Contravariant interface
public interface IValidator<in T>
{
    bool IsValid(T item);
    // T Create();  // ERROR - can't return T with 'in'
}

// Both covariant and contravariant
public interface IConverter<in TInput, out TOutput>
{
    TOutput Convert(TInput input);
}

public class StringToIntConverter : IConverter<string, int>
{
    public int Convert(string input) => int.Parse(input);
}

public class VarianceUsage
{
    public void UseCustomVariance()
    {
        // Contravariance on input
        IValidator<Animal> animalValidator = new AnimalValidator();
        IValidator<Dog> dogValidator = animalValidator;  // Contravariant!

        dogValidator.IsValid(new Dog());

        // Covariance on output
        IRepository<Dog> dogRepo = new DogRepository();
        IRepository<Animal> animalRepo = dogRepo;  // Covariant!

        Animal animal = animalRepo.GetById(1);

        // Both
        IConverter<string, int> stringToInt = new StringToIntConverter();

        // Contravariant input: object -> string
        IConverter<object, int> objectToInt = stringToInt;
        int result1 = objectToInt.Convert("42");

        // Covariant output: int -> object
        IConverter<string, object> stringToObject = stringToInt;
        object result2 = stringToObject.Convert("42");
    }
}

public class AnimalValidator : IValidator<Animal>
{
    public bool IsValid(Animal item) => !string.IsNullOrEmpty(item.Name);
}

public class DogRepository : IRepository<Dog>
{
    private List<Dog> _dogs = new List<Dog>
    {
        new Dog { Name = "Buddy" },
        new Dog { Name = "Max" }
    };

    public Dog GetById(int id) => _dogs.FirstOrDefault();

    public IEnumerable<Dog> GetAll() => _dogs;
}

// ============ MEMORY TRICK ============

/*
Covariance (out):
- "OUT" of the generic - returning/producing
- More derived → Less derived (Dog → Animal)
- Read-only scenarios
- Think: "Output goes UP the hierarchy"

Contravariance (in):
- "IN" to the generic - accepting/consuming
- Less derived → More derived (Animal → Dog)
- Write-only scenarios
- Think: "Input goes DOWN the hierarchy"

Example:
IEnumerable<out T> - only OUTPUTS T → Covariant
IComparer<in T> - only INPUTS T → Contravariant
*/
```

**Key Rules:**
- **Covariance (out):** Safe for return types (producing values)
- **Contravariance (in):** Safe for parameter types (consuming values)
- **Invariance:** When T is both input and output (List<T>, IList<T>)

**Common Built-in Examples:**
- Covariant: `IEnumerable<out T>`, `IQueryable<out T>`, `Func<out TResult>`
- Contravariant: `IComparer<in T>`, `Action<in T>`, `IEqualityComparer<in T>`

---

(Continuing with Q21-Q50...)

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
### Q31: Explain tuple types in C#. What's new in C# 7+?

**Tuples:**
- Lightweight data structures
- Group multiple values together
- Value types (struct-based in C# 7+)
- Named or unnamed elements
- Deconstruction support

**Old Tuple (System.Tuple) vs ValueTuple (C# 7+):**

**Example:**
```csharp
// ============ OLD TUPLES (Before C# 7) ============

public Tuple<string, int, bool> GetUserDataOld(int userId)
{
    return Tuple.Create("John Doe", 30, true);
}

// Usage - Item1, Item2, Item3 (not descriptive)
var userData = GetUserDataOld(1);
Console.WriteLine($"{userData.Item1}, Age: {userData.Item2}");

// ============ VALUE TUPLES (C# 7+) ============

public (string Name, int Age, bool IsActive) GetUserData(int userId)
{
    return ("John Doe", 30, true);
}

// Usage - named elements
var user = GetUserData(1);
Console.WriteLine($"{user.Name}, Age: {user.Age}, Active: {user.IsActive}");

// Or deconstruct
var (name, age, isActive) = GetUserData(1);
Console.WriteLine($"{name}, Age: {age}");

// ============ TUPLE SYNTAX VARIATIONS ============

public class TupleSyntaxExamples
{
    // Inline tuple creation
    public void InlineTuples()
    {
        var person = (Name: "Alice", Age: 25);
        Console.WriteLine($"{person.Name} is {person.Age}");

        // Without names (uses Item1, Item2)
        var coordinates = (10, 20);
        Console.WriteLine($"X: {coordinates.Item1}, Y: {coordinates.Item2}");

        // Mixed named/unnamed
        var data = (Name: "Bob", 30);  // Age is Item2
        Console.WriteLine($"{data.Name}, {data.Item2}");
    }

    // Return multiple values
    public (int Min, int Max, double Average) GetStatistics(int[] numbers)
    {
        return (
            Min: numbers.Min(),
            Max: numbers.Max(),
            Average: numbers.Average()
        );
    }

    public void UseStatistics()
    {
        var numbers = new[] { 1, 5, 3, 9, 2 };
        var stats = GetStatistics(numbers);

        Console.WriteLine($"Min: {stats.Min}");
        Console.WriteLine($"Max: {stats.Max}");
        Console.WriteLine($"Average: {stats.Average}");

        // Deconstruction
        var (min, max, avg) = GetStatistics(numbers);
        Console.WriteLine($"Range: {min}-{max}, Avg: {avg}");
    }
}

// ============ DECONSTRUCTION ============

public class DeconstructionExamples
{
    // Discard unwanted values with _
    public void DiscardExample()
    {
        var (name, _, isActive) = GetUserData(1);  // Ignore age
        Console.WriteLine($"{name} - Active: {isActive}");
    }

    // Custom type deconstruction
    public class Person
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int Age { get; set; }

        // Deconstruct method
        public void Deconstruct(out string firstName, out string lastName)
        {
            firstName = FirstName;
            lastName = LastName;
        }

        // Multiple deconstruct overloads
        public void Deconstruct(out string firstName, out string lastName, out int age)
        {
            firstName = FirstName;
            lastName = LastName;
            age = Age;
        }
    }

    public void UseCustomDeconstruction()
    {
        var person = new Person
        {
            FirstName = "John",
            LastName = "Doe",
            Age = 30
        };

        // Deconstruct to 2 variables
        var (first, last) = person;
        Console.WriteLine($"{first} {last}");

        // Deconstruct to 3 variables
        var (firstName, lastName, age) = person;
        Console.WriteLine($"{firstName} {lastName}, Age: {age}");
    }
}

// ============ LINQ WITH TUPLES ============

public class LinqWithTuples
{
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public decimal Price { get; set; }
        public string Category { get; set; }
    }

    public void TuplesInLinq()
    {
        var products = new List<Product>
        {
            new Product { Id = 1, Name = "Laptop", Price = 999, Category = "Electronics" },
            new Product { Id = 2, Name = "Mouse", Price = 25, Category = "Electronics" },
            new Product { Id = 3, Name = "Desk", Price = 299, Category = "Furniture" }
        };

        // Project to tuple
        var productSummaries = products
            .Select(p => (p.Name, p.Price, IsExpensive: p.Price > 100))
            .ToList();

        foreach (var (name, price, isExpensive) in productSummaries)
        {
            Console.WriteLine($"{name}: ${price} {(isExpensive ? "💰" : "")}");
        }

        // Group by with tuples
        var categoryStats = products
            .GroupBy(p => p.Category)
            .Select(g => (
                Category: g.Key,
                Count: g.Count(),
                TotalValue: g.Sum(p => p.Price),
                AvgPrice: g.Average(p => p.Price)
            ))
            .ToList();

        foreach (var (category, count, total, avg) in categoryStats)
        {
            Console.WriteLine($"{category}: {count} items, Total: ${total}, Avg: ${avg:F2}");
        }
    }
}

// ============ DICTIONARY WITH TUPLES ============

public class TupleDictionary
{
    // Tuple as dictionary key (C# 7+)
    public void TupleKeys()
    {
        var cache = new Dictionary<(string Username, int Year), decimal>();

        cache[("john", 2024)] = 150000m;
        cache[("jane", 2024)] = 175000m;
        cache[("john", 2023)] = 140000m;

        // Lookup
        var salary = cache[("john", 2024)];
        Console.WriteLine($"John's 2024 salary: ${salary}");

        // With deconstruction
        foreach (var ((username, year), salary) in cache)
        {
            Console.WriteLine($"{username} ({year}): ${salary}");
        }
    }

    // Tuple as dictionary value
    public void TupleValues()
    {
        var employees = new Dictionary<int, (string Name, string Department, decimal Salary)>
        {
            [1] = ("John", "IT", 80000),
            [2] = ("Jane", "HR", 75000),
            [3] = ("Bob", "IT", 85000)
        };

        var employee = employees[1];
        Console.WriteLine($"{employee.Name} - {employee.Department}: ${employee.Salary}");
    }
}

// ============ TUPLE PATTERN MATCHING (C# 8+) ============

public class TuplePatternMatching
{
    public string GetQuadrant(int x, int y)
    {
        return (x, y) switch
        {
            (0, 0) => "Origin",
            (> 0, > 0) => "Quadrant I",
            (< 0, > 0) => "Quadrant II",
            (< 0, < 0) => "Quadrant III",
            (> 0, < 0) => "Quadrant IV",
            (0, _) => "X-axis",
            (_, 0) => "Y-axis"
        };
    }

    public string DescribeNumber(int n)
    {
        return (n > 0, n % 2 == 0) switch
        {
            (true, true) => "Positive even",
            (true, false) => "Positive odd",
            (false, true) => "Negative even",
            (false, false) => "Negative odd"
        };
    }

    public decimal CalculateShipping(string country, decimal weight)
    {
        return (country, weight) switch
        {
            ("US", < 1) => 5.00m,
            ("US", < 5) => 10.00m,
            ("US", _) => 15.00m,
            ("CA", < 1) => 7.00m,
            ("CA", _) => 12.00m,
            _ => 20.00m
        };
    }
}

// ============ COMPARISON: Old vs New Tuples ============
```

| Feature | System.Tuple | ValueTuple (C# 7+) |
|---------|-------------|-------------------|
| Type | Reference (class) | Value (struct) |
| Performance | Slower (heap) | Faster (stack) |
| Naming | Item1, Item2, etc. | Named elements |
| Mutability | Immutable | Mutable |
| Syntax | Tuple.Create() | (value1, value2) |
| Memory | More | Less |

```csharp
// ============ REAL-WORLD EXAMPLES ============

// API endpoints returning multiple values
public class UserController
{
    public (bool Success, string Message, User Data) GetUser(int id)
    {
        var user = FindUser(id);

        if (user == null)
            return (false, "User not found", null);

        if (!user.IsActive)
            return (false, "User is inactive", null);

        return (true, "Success", user);
    }

    public void ProcessUser()
    {
        var (success, message, user) = GetUser(123);

        if (!success)
        {
            Console.WriteLine($"Error: {message}");
            return;
        }

        Console.WriteLine($"User: {user.Name}");
    }
}

// Database operations
public class DatabaseHelper
{
    public (int RowsAffected, DateTime Timestamp) ExecuteCommand(string sql)
    {
        // Execute command
        int rows = 5;
        return (rows, DateTime.Now);
    }

    public (List<User> Users, int TotalCount, int PageCount) GetPagedUsers(int page, int pageSize)
    {
        var users = GetUsers().Skip((page - 1) * pageSize).Take(pageSize).ToList();
        var total = GetUserCount();
        var pages = (int)Math.Ceiling((double)total / pageSize);

        return (users, total, pages);
    }
}

// Parsing operations
public class Parser
{
    public (bool Success, int Value, string Error) TryParseInt(string input)
    {
        if (int.TryParse(input, out int value))
            return (true, value, null);

        return (false, 0, "Invalid integer format");
    }

    public void Parse()
    {
        var (success, value, error) = TryParseInt("123");

        if (success)
            Console.WriteLine($"Parsed: {value}");
        else
            Console.WriteLine($"Error: {error}");
    }
}

private (string, int, bool) GetUserData(int userId) => ("John", 30, true);
private User FindUser(int id) => new User { Name = "John", IsActive = true };
private List<User> GetUsers() => new List<User>();
private int GetUserCount() => 100;
}

public class User
{
    public string Name { get; set; }
    public bool IsActive { get; set; }
}
```

**Key Benefits:**
- ✅ Lightweight data structures
- ✅ Named elements (readability)
- ✅ Easy deconstruction
- ✅ Better performance than old Tuple
- ✅ Great for returning multiple values
- ✅ Works well with LINQ and pattern matching

---

### Q32: What is pattern matching in C#? Explain different patterns.

**Pattern Matching:**
- Test values against patterns
- Introduced in C# 7, enhanced in C# 8, 9, 10, 11
- Used in `is`, `switch` expressions
- More expressive, less code
- Type-safe

**Example:**
```csharp
// ============ TYPE PATTERNS ============

public class TypePatternExamples
{
    public void ProcessObject(object obj)
    {
        // Type pattern with is
        if (obj is string str)
        {
            Console.WriteLine($"String: {str.ToUpper()}");
        }
        else if (obj is int number)
        {
            Console.WriteLine($"Number: {number * 2}");
        }
        else if (obj is List<int> list)
        {
            Console.WriteLine($"List with {list.Count} items");
        }
    }

    // Switch expression with type patterns
    public string DescribeObject(object obj) => obj switch
    {
        string s => $"String of length {s.Length}",
        int n => $"Integer: {n}",
        double d => $"Double: {d:F2}",
        bool b => $"Boolean: {b}",
        null => "null value",
        _ => "Unknown type"
    };
}

// ============ CONSTANT PATTERNS ============

public class ConstantPatterns
{
    public string CheckValue(int value) => value switch
    {
        0 => "Zero",
        1 => "One",
        2 => "Two",
        _ => "Other"
    };

    public bool IsWeekend(DayOfWeek day) => day switch
    {
        DayOfWeek.Saturday or DayOfWeek.Sunday => true,
        _ => false
    };
}

// ============ RELATIONAL PATTERNS (C# 9+) ============

public class RelationalPatterns
{
    public string CategorizeAge(int age) => age switch
    {
        < 0 => "Invalid",
        < 13 => "Child",
        < 20 => "Teenager",
        < 60 => "Adult",
        _ => "Senior"
    };

    public string GetLetterGrade(int score) => score switch
    {
        >= 90 => "A",
        >= 80 => "B",
        >= 70 => "C",
        >= 60 => "D",
        _ => "F"
    };

    public decimal CalculateDiscount(decimal amount) => amount switch
    {
        < 100 => 0,
        >= 100 and < 500 => 0.05m,
        >= 500 and < 1000 => 0.10m,
        >= 1000 => 0.15m
    };
}

// ============ LOGICAL PATTERNS (and, or, not) ============

public class LogicalPatterns
{
    public bool IsValidAge(int age) => age is >= 0 and <= 120;

    public string CheckNumber(int n) => n switch
    {
        > 0 and < 10 => "Single digit positive",
        >= 10 and < 100 => "Two digits",
        < 0 or > 100 => "Out of range",
        _ => "Other"
    };

    public bool IsWeekday(DayOfWeek day)
    {
        return day is not (DayOfWeek.Saturday or DayOfWeek.Sunday);
    }

    public string DescribeTemperature(int temp) => temp switch
    {
        < 0 => "Freezing",
        >= 0 and < 10 => "Cold",
        >= 10 and < 20 => "Cool",
        >= 20 and < 30 => "Warm",
        >= 30 => "Hot"
    };
}

// ============ PROPERTY PATTERNS ============

public class PropertyPatterns
{
    public record Person(string Name, int Age, string City);

    public string DescribePerson(Person person) => person switch
    {
        { Age: < 18 } => "Minor",
        { Age: >= 18, City: "Seattle" } => "Adult from Seattle",
        { Age: >= 65 } => "Senior",
        { City: "New York" } => "From New York",
        _ => "Person"
    };

    // Nested property patterns
    public class Address
    {
        public string City { get; set; }
        public string State { get; set; }
        public string ZipCode { get; set; }
    }

    public class Employee
    {
        public string Name { get; set; }
        public Address Address { get; set; }
        public decimal Salary { get; set; }
    }

    public string DescribeEmployee(Employee emp) => emp switch
    {
        { Address: { City: "Seattle", State: "WA" } } => "Seattle employee",
        { Address: { State: "CA" }, Salary: > 100000 } => "High-paid CA employee",
        { Salary: < 50000 } => "Junior employee",
        _ => "Employee"
    };
}

// ============ POSITIONAL PATTERNS ============

public class PositionalPatterns
{
    public record Point(int X, int Y);

    public string GetQuadrant(Point point) => point switch
    {
        (0, 0) => "Origin",
        (>0, >0) => "Quadrant I",
        (<0, >0) => "Quadrant II",
        (<0, <0) => "Quadrant III",
        (>0, <0) => "Quadrant IV",
        (0, _) => "On X-axis",
        (_, 0) => "On Y-axis"
    };

    public record RGB(int Red, int Green, int Blue);

    public string DescribeColor(RGB color) => color switch
    {
        (255, 0, 0) => "Pure Red",
        (0, 255, 0) => "Pure Green",
        (0, 0, 255) => "Pure Blue",
        (255, 255, 255) => "White",
        (0, 0, 0) => "Black",
        (var r, var g, var b) when r == g && g == b => "Gray",
        _ => "Color"
    };
}

// ============ LIST PATTERNS (C# 11+) ============

public class ListPatterns
{
    public string AnalyzeArray(int[] numbers) => numbers switch
    {
        [] => "Empty",
        [1] => "Single element: 1",
        [1, 2] => "Two elements: 1, 2",
        [1, 2, 3] => "Exactly 1, 2, 3",
        [1, ..] => "Starts with 1",
        [.., 9] => "Ends with 9",
        [1, .., 9] => "Starts with 1, ends with 9",
        [var first, .., var last] => $"First: {first}, Last: {last}",
        _ => "Other pattern"
    };

    public bool StartsWithTwoOnes(int[] arr) => arr is [1, 1, ..];

    public bool EndsWithZero(int[] arr) => arr is [.., 0];
}

// ============ VAR PATTERN ============

public class VarPattern
{
    public void ProcessValue(object obj)
    {
        // Capture value in variable
        if (obj is var value && value != null)
        {
            Console.WriteLine($"Value: {value}");
        }
    }

    public string DescribeNumber(int n) => n switch
    {
        var x when x < 0 => $"Negative: {x}",
        var x when x == 0 => "Zero",
        var x => $"Positive: {x}"
    };
}

// ============ DISCARD PATTERN ============

public class DiscardPattern
{
    public bool IsValidUser(User user) => user switch
    {
        null => false,
        { Name: not null, Age: >= 18 } => true,
        _ => false  // Discard pattern - matches anything
    };
}

// ============ REAL-WORLD EXAMPLES ============

// HTTP Response handling
public class HttpResponseHandler
{
    public record HttpResponse(int StatusCode, string Body);

    public string HandleResponse(HttpResponse response) => response switch
    {
        { StatusCode: 200, Body: var body } => $"Success: {body}",
        { StatusCode: 201 } => "Created successfully",
        { StatusCode: 204 } => "No content",
        { StatusCode: >= 400 and < 500 } => "Client error",
        { StatusCode: >= 500 } => "Server error",
        _ => "Unknown response"
    };
}

// Order processing
public class OrderProcessor
{
    public enum OrderStatus { Pending, Processing, Shipped, Delivered, Cancelled }

    public record Order(int Id, OrderStatus Status, decimal Amount, string Customer);

    public string ProcessOrder(Order order) => order switch
    {
        { Status: OrderStatus.Cancelled } => "Order was cancelled",
        { Status: OrderStatus.Delivered } => "Already delivered",
        { Amount: <= 0 } => "Invalid amount",
        { Customer: null or "" } => "Missing customer",
        { Status: OrderStatus.Pending, Amount: > 1000 } => "Requires approval",
        { Status: OrderStatus.Pending } => "Ready to process",
        _ => "Cannot process"
    };
}

// Shape calculations
public abstract record Shape;
public record Circle(double Radius) : Shape;
public record Rectangle(double Width, double Height) : Shape;
public record Triangle(double Base, double Height) : Shape;

public class ShapeCalculator
{
    public double CalculateArea(Shape shape) => shape switch
    {
        Circle { Radius: var r } => Math.PI * r * r,
        Rectangle { Width: var w, Height: var h } => w * h,
        Triangle { Base: var b, Height: var h } => 0.5 * b * h,
        null => throw new ArgumentNullException(nameof(shape)),
        _ => throw new ArgumentException("Unknown shape")
    };

    public string DescribeShape(Shape shape) => shape switch
    {
        Circle { Radius: > 10 } => "Large circle",
        Circle => "Small circle",
        Rectangle { Width: var w, Height: var h } when w == h => "Square",
        Rectangle { Width: > 10, Height: > 10 } => "Large rectangle",
        Rectangle => "Rectangle",
        Triangle => "Triangle",
        _ => "Unknown shape"
    };
}

// Validation with patterns
public class Validator
{
    public record Product(string Name, decimal Price, int Stock);

    public (bool IsValid, string Error) ValidateProduct(Product product)
    {
        return product switch
        {
            null => (false, "Product is null"),
            { Name: null or "" } => (false, "Name is required"),
            { Name.Length: > 100 } => (false, "Name too long"),
            { Price: <= 0 } => (false, "Invalid price"),
            { Price: > 10000 } => (false, "Price too high"),
            { Stock: < 0 } => (false, "Invalid stock"),
            _ => (true, null)
        };
    }
}
```

**Pattern Types Summary:**
- **Type patterns:** `obj is string s`
- **Constant patterns:** `value is 5`
- **Relational patterns:** `age is >= 18`
- **Logical patterns:** `n is > 0 and < 10`
- **Property patterns:** `{ Age: >= 18 }`
- **Positional patterns:** `(x, y) switch { ... }`
- **List patterns:** `arr is [1, 2, 3]`
- **Var pattern:** `obj is var x`
- **Discard pattern:** `_`

---

### Q33: Explain records in C# 9+. How do they differ from classes?

**Records:**
- Reference types (or value types with `record struct`)
- Immutable by default
- Value-based equality
- Built-in ToString(), Equals(), GetHashCode()
- Concise syntax
- `with` expressions for non-destructive mutation

**Example:**
```csharp
// ============ BASIC RECORD ============

// Traditional class
public class PersonClass
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public int Age { get; set; }
}

// Record (positional syntax)
public record Person(string FirstName, string LastName, int Age);

// Record (property syntax)
public record PersonVerbose
{
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public int Age { get; init; }
}

public class RecordBasics
{
    public void DemonstrateRecords()
    {
        var person1 = new Person("John", "Doe", 30);
        var person2 = new Person("John", "Doe", 30);
        var person3 = person1;

        // Value-based equality (records)
        Console.WriteLine(person1 == person2);  // True (same values)
        Console.WriteLine(person1 == person3);  // True (same reference)

        // Built-in ToString()
        Console.WriteLine(person1);
        // Output: Person { FirstName = John, LastName = Doe, Age = 30 }

        // Classes use reference equality
        var class1 = new PersonClass { FirstName = "John", LastName = "Doe", Age = 30 };
        var class2 = new PersonClass { FirstName = "John", LastName = "Doe", Age = 30 };
        Console.WriteLine(class1 == class2);  // False (different references)
    }
}

// ============ WITH EXPRESSIONS ============

public class WithExpressions
{
    public record Address(string Street, string City, string State, string Zip);
    public record Employee(string Name, int Age, Address Address, decimal Salary);

    public void DemonstrateWith()
    {
        var emp1 = new Employee(
            "John Doe",
            30,
            new Address("123 Main St", "Seattle", "WA", "98101"),
            75000
        );

        // Create new record with modified property (non-destructive mutation)
        var emp2 = emp1 with { Salary = 85000 };

        Console.WriteLine(emp1.Salary);  // 75000 (unchanged)
        Console.WriteLine(emp2.Salary);  // 85000 (new instance)

        // Modify multiple properties
        var emp3 = emp1 with
        {
            Age = 31,
            Salary = 80000
        };

        // Modify nested record
        var emp4 = emp1 with
        {
            Address = emp1.Address with { City = "Portland" }
        };

        Console.WriteLine(emp1.Address.City);  // Seattle
        Console.WriteLine(emp4.Address.City);  // Portland
    }
}

// ============ RECORD INHERITANCE ============

public record Person(string Name, int Age);
public record Employee(string Name, int Age, string Department, decimal Salary)
    : Person(Name, Age);
public record Manager(string Name, int Age, string Department, decimal Salary, int TeamSize)
    : Employee(Name, Age, Department, Salary);

public class RecordInheritance
{
    public void DemonstrateInheritance()
    {
        Person person = new Person("John", 30);
        Employee employee = new Employee("Jane", 28, "IT", 75000);
        Manager manager = new Manager("Bob", 35, "IT", 95000, 5);

        // Polymorphism works
        Person p = employee;
        Console.WriteLine(p);  // Employee { Name = Jane, Age = 28, ... }

        // Pattern matching with records
        string description = person switch
        {
            Manager m => $"Manager of {m.TeamSize} people",
            Employee e => $"Employee in {e.Department}",
            Person => "Person",
            _ => "Unknown"
        };
    }
}

// ============ RECORD STRUCT (C# 10+) ============

// Value type record
public readonly record struct Point(int X, int Y);

// Mutable record struct
public record struct MutablePoint(int X, int Y);

public class RecordStructExample
{
    public void DemonstrateRecordStruct()
    {
        var p1 = new Point(10, 20);
        var p2 = new Point(10, 20);

        // Value equality (like all value types)
        Console.WriteLine(p1 == p2);  // True

        // Stored on stack
        Point p3 = p1;  // Copy, not reference
        // p3.X = 15;  // Error - readonly

        // Mutable record struct
        var mp = new MutablePoint(5, 10);
        mp.X = 15;  // OK - mutable
        Console.WriteLine(mp);  // MutablePoint { X = 15, Y = 10 }
    }
}

// ============ DECONSTRUCTION ============

public class RecordDeconstruction
{
    public record Person(string FirstName, string LastName, int Age);

    public void Deconstruct()
    {
        var person = new Person("John", "Doe", 30);

        // Automatic deconstruction (positional records)
        var (firstName, lastName, age) = person;

        Console.WriteLine($"{firstName} {lastName}, Age: {age}");

        // Partial deconstruction with discard
        var (first, _, personAge) = person;
        Console.WriteLine($"{first} is {personAge} years old");
    }
}

// ============ CUSTOM METHODS IN RECORDS ============

public record Product(string Name, decimal Price, int Stock)
{
    // Custom methods
    public decimal GetDiscountedPrice(decimal discountPercent)
    {
        return Price * (1 - discountPercent / 100);
    }

    public bool IsAvailable() => Stock > 0;

    // Override ToString for custom format
    public override string ToString()
    {
        return $"{Name} - ${Price} ({Stock} in stock)";
    }

    // Static factory method
    public static Product CreateOutOfStock(string name, decimal price)
    {
        return new Product(name, price, 0);
    }
}

// ============ VALIDATION IN RECORDS ============

public record Email
{
    public string Value { get; init; }

    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Email cannot be empty");

        if (!value.Contains("@"))
            throw new ArgumentException("Invalid email format");

        Value = value;
    }
}

public record User(string Name, Email Email, int Age)
{
    // Additional validation
    public User(string name, Email email, int age) : this(name, email, age)
    {
        if (age < 0 || age > 120)
            throw new ArgumentException("Invalid age");
    }
}

// ============ REAL-WORLD EXAMPLES ============

// DTOs (Data Transfer Objects)
public record CustomerDto(
    int Id,
    string Name,
    string Email,
    DateTime RegisteredDate
);

public record OrderDto(
    int OrderId,
    CustomerDto Customer,
    List<OrderItemDto> Items,
    decimal Total
);

public record OrderItemDto(string ProductName, int Quantity, decimal Price);

// Domain events
public abstract record DomainEvent(Guid Id, DateTime OccurredAt);

public record OrderPlaced(
    Guid Id,
    DateTime OccurredAt,
    int OrderId,
    int CustomerId,
    decimal Amount
) : DomainEvent(Id, OccurredAt);

public record OrderShipped(
    Guid Id,
    DateTime OccurredAt,
    int OrderId,
    string TrackingNumber
) : DomainEvent(Id, OccurredAt);

// Configuration
public record DatabaseConfig(
    string ConnectionString,
    int MaxPoolSize,
    int TimeoutSeconds
)
{
    public static DatabaseConfig Development => new(
        "Server=localhost;Database=DevDb;",
        50,
        30
    );

    public static DatabaseConfig Production => new(
        Environment.GetEnvironmentVariable("DB_CONNECTION"),
        200,
        60
    );
}

// Value objects
public record Money(decimal Amount, string Currency)
{
    public Money Add(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException("Currency mismatch");

        return this with { Amount = Amount + other.Amount };
    }

    public Money Multiply(decimal multiplier)
    {
        return this with { Amount = Amount * multiplier };
    }
}

// API responses
public record ApiResponse<T>(
    bool Success,
    T Data,
    string Message,
    List<string> Errors
)
{
    public static ApiResponse<T> SuccessResponse(T data) =>
        new(true, data, "Success", new List<string>());

    public static ApiResponse<T> ErrorResponse(string message, List<string> errors = null) =>
        new(false, default, message, errors ?? new List<string>());
}
```

**Comparison Table:**
| Feature | Class | Record |
|---------|-------|--------|
| Type | Reference | Reference (or value with `record struct`) |
| Equality | Reference | Value |
| Mutability | Mutable by default | Immutable by default |
| ToString() | Object.ToString() | Generated with all properties |
| with expression | No | Yes |
| Inheritance | Yes | Yes (records only) |
| Best for | Complex behavior | Data holders |

**When to Use Records:**
- ✅ DTOs / Data transfer
- ✅ Configuration objects
- ✅ Value objects
- ✅ Domain events
- ✅ API requests/responses
- ✅ Immutable data models

**When to Use Classes:**
- ✅ Complex behavior/logic
- ✅ Mutable state needed
- ✅ Entity framework entities (mutable)
- ✅ Reference equality important
- ✅ Inheritance hierarchies with behavior

---

### Q34: What are init-only setters in C#?

**Init-only Setters:**
- Property can be set during object initialization only
- Keyword: `init` instead of `set`
- Immutable after construction
- Works with object initializers
- Introduced in C# 9

**Example:**
```csharp
// ============ BASIC INIT-ONLY PROPERTIES ============

public class PersonWithInit
{
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public int Age { get; init; }
}

public class InitOnlyBasics
{
    public void DemonstrateInit()
    {
        // Can set during initialization
        var person = new PersonWithInit
        {
            FirstName = "John",
            LastName = "Doe",
            Age = 30
        };

        // Cannot modify after initialization
        // person.FirstName = "Jane";  // ERROR: Property can only be set in initializer

        Console.WriteLine($"{person.FirstName} {person.LastName}, Age: {person.Age}");
    }
}

// ============ COMPARISON: get/set vs init ============

public class MutablePerson
{
    public string Name { get; set; }  // Can change anytime
    public int Age { get; set; }
}

public class ImmutablePerson
{
    public string Name { get; init; }  // Only during init
    public int Age { get; init; }
}

public class MixedPerson
{
    public string Name { get; init; }  // Immutable
    public int Age { get; set; }       // Mutable
    public DateTime CreatedAt { get; }  // Readonly (only in constructor)

    public MixedPerson()
    {
        CreatedAt = DateTime.Now;
    }
}

// ============ INIT WITH CONSTRUCTORS ============

public class Product
{
    public string Name { get; init; }
    public decimal Price { get; init; }
    public int Stock { get; set; }  // Mutable

    public Product()
    {
        // Can set init properties in constructor
        Name = "Default";
        Price = 0;
        Stock = 0;
    }

    public Product(string name, decimal price)
    {
        Name = name;
        Price = price;
        Stock = 0;
    }
}

public class InitWithConstructor
{
    public void Usage()
    {
        // Using constructor
        var product1 = new Product("Laptop", 999);

        // Using init properties
        var product2 = new Product
        {
            Name = "Mouse",
            Price = 25,
            Stock = 50
        };

        // Can modify mutable properties
        product1.Stock = 10;  // OK
        product2.Stock = 20;  // OK

        // Cannot modify init properties
        // product1.Name = "Desktop";  // ERROR
        // product1.Price = 1200;      // ERROR
    }
}

// ============ INIT WITH RECORDS ============

// Records use init by default
public record PersonRecord(string FirstName, string LastName, int Age);

// Equivalent to:
public record PersonRecordExpanded
{
    public string FirstName { get; init; }
    public string LastName { get; init; }
    public int Age { get; init; }

    public PersonRecordExpanded(string firstName, string lastName, int age)
    {
        FirstName = firstName;
        LastName = lastName;
        Age = age;
    }
}

// ============ VALIDATION WITH INIT ============

public class User
{
    private string _email;

    public string Email
    {
        get => _email;
        init
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Email is required");

            if (!value.Contains("@"))
                throw new ArgumentException("Invalid email format");

            _email = value;
        }
    }

    public string Name { get; init; }
    public int Age { get; init; }
}

public class ValidationExample
{
    public void ValidateInit()
    {
        // Valid initialization
        var user1 = new User
        {
            Email = "john@example.com",
            Name = "John",
            Age = 30
        };

        try
        {
            // Invalid initialization - throws exception
            var user2 = new User
            {
                Email = "invalid-email",  // No @
                Name = "Jane",
                Age = 25
            };
        }
        catch (ArgumentException ex)
        {
            Console.WriteLine($"Validation error: {ex.Message}");
        }
    }
}

// ============ COMPUTED INIT PROPERTIES ============

public class Order
{
    public int OrderId { get; init; }
    public DateTime OrderDate { get; init; }
    public List<OrderItem> Items { get; init; }

    // Computed property based on init properties
    public decimal Total => Items?.Sum(i => i.Price * i.Quantity) ?? 0;
}

public class OrderItem
{
    public string Product { get; init; }
    public int Quantity { get; init; }
    public decimal Price { get; init; }
}

// ============ REQUIRED INIT PROPERTIES (C# 11+) ============

public class ConfigurationSettings
{
    public required string ApiUrl { get; init; }
    public required string ApiKey { get; init; }
    public int Timeout { get; init; } = 30;  // Optional with default
}

public class RequiredInitExample
{
    public void Usage()
    {
        // Must provide required properties
        var config = new ConfigurationSettings
        {
            ApiUrl = "https://api.example.com",
            ApiKey = "secret-key"
            // Timeout is optional (has default)
        };

        // This won't compile - missing required properties:
        // var config2 = new ConfigurationSettings { };  // ERROR
    }
}

// ============ INIT-ONLY COLLECTIONS ============

public class Team
{
    public string Name { get; init; }
    public List<string> Members { get; init; } = new();
}

public class InitCollections
{
    public void DemonstrateCollections()
    {
        var team = new Team
        {
            Name = "Development",
            Members = new List<string> { "Alice", "Bob", "Charlie" }
        };

        // Cannot reassign collection
        // team.Members = new List<string>();  // ERROR

        // But CAN modify collection contents
        team.Members.Add("David");  // OK - modifying collection, not property
        team.Members.Remove("Alice");  // OK

        // To make collection truly immutable, use ImmutableList
        var immutableTeam = new ImmutableTeam
        {
            Name = "QA",
            Members = ImmutableList.Create("Eve", "Frank")
        };

        // Cannot modify
        // immutableTeam.Members.Add("George");  // ERROR - no Add method on ImmutableList
    }
}

public class ImmutableTeam
{
    public string Name { get; init; }
    public ImmutableList<string> Members { get; init; }
}

// ============ REAL-WORLD EXAMPLES ============

// Configuration objects
public class AppSettings
{
    public string ApplicationName { get; init; }
    public string Environment { get; init; }
    public DatabaseSettings Database { get; init; }
    public LoggingSettings Logging { get; init; }
}

public class DatabaseSettings
{
    public string ConnectionString { get; init; }
    public int MaxPoolSize { get; init; }
    public int CommandTimeout { get; init; }
}

public class LoggingSettings
{
    public string LogLevel { get; init; }
    public string OutputPath { get; init; }
}

// Domain entities with immutable properties
public class Customer
{
    public int Id { get; init; }
    public string CustomerNumber { get; init; }  // Never changes
    public string Name { get; set; }  // Can be updated
    public string Email { get; set; }  // Can be updated
    public DateTime RegisteredDate { get; init; }  // Never changes
}

// API DTOs
public class CreateUserRequest
{
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string Password { get; init; }
    public string FirstName { get; init; }
    public string LastName { get; init; }
}

public class UserResponse
{
    public int Id { get; init; }
    public string Username { get; init; }
    public string Email { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? LastLoginAt { get; init; }
}

// Value objects
public class Address
{
    public string Street { get; init; }
    public string City { get; init; }
    public string State { get; init; }
    public string ZipCode { get; init; }

    public string FullAddress => $"{Street}, {City}, {State} {ZipCode}";
}

// Event sourcing events
public class OrderPlacedEvent
{
    public Guid EventId { get; init; }
    public DateTime Timestamp { get; init; }
    public int OrderId { get; init; }
    public int CustomerId { get; init; }
    public decimal TotalAmount { get; init; }
    public List<OrderItemData> Items { get; init; }
}

public class OrderItemData
{
    public int ProductId { get; init; }
    public string ProductName { get; init; }
    public int Quantity { get; init; }
    public decimal Price { get; init; }
}
```

**Benefits:**
- ✅ Immutability after initialization
- ✅ Object initializer syntax support
- ✅ Better than readonly (works with initializers)
- ✅ Thread-safe (immutable state)
- ✅ Clearer intent than set

**When to Use:**
- Configuration objects
- DTOs / API models
- Value objects
- Event data
- Immutable domain entities
- Record types (automatic)

---

(Continuing with Q35-Q50...)### Q35: Explain the async/await pattern. How does it work internally?

**Async/Await:**
- Asynchronous programming model
- Non-blocking operations
- Compiler generates state machine
- Returns Task or Task<T>
- `await` keyword suspends execution
- Improves responsiveness and scalability

**How It Works Internally:**

**Example:**
```csharp
// ============ BASIC ASYNC/AWAIT ============

public class AsyncBasics
{
    // Async method that returns Task
    public async Task ProcessDataAsync()
    {
        Console.WriteLine("Starting...");

        // Simulates I/O operation
        await Task.Delay(1000);  // Non-blocking wait

        Console.WriteLine("Completed!");
    }

    // Async method that returns Task<T>
    public async Task<string> FetchDataAsync()
    {
        await Task.Delay(1000);
        return "Data loaded";
    }

    // Async method with multiple awaits
    public async Task<int> CalculateSumAsync()
    {
        int value1 = await GetValueAsync(1);
        int value2 = await GetValueAsync(2);
        return value1 + value2;
    }

    private async Task<int> GetValueAsync(int id)
    {
        await Task.Delay(100);
        return id * 10;
    }
}

// ============ HOW IT WORKS INTERNALLY ============

// What you write:
public async Task<string> GetDataAsync()
{
    var result = await FetchFromDatabaseAsync();
    return result.ToUpper();
}

// What compiler generates (simplified state machine):
public Task<string> GetDataAsync()
{
    var stateMachine = new <GetDataAsync>d__0();
    stateMachine.builder = AsyncTaskMethodBuilder<string>.Create();
    stateMachine.state = -1;
    stateMachine.builder.Start(ref stateMachine);
    return stateMachine.builder.Task;
}

private struct <GetDataAsync>d__0 : IAsyncStateMachine
{
    public int state;
    public AsyncTaskMethodBuilder<string> builder;
    private TaskAwaiter<string> awaiter;

    void IAsyncStateMachine.MoveNext()
    {
        string result;
        try
        {
            switch (state)
            {
                case 0:
                    goto StateLabel0;
                default:
                    // Initial state
                    awaiter = FetchFromDatabaseAsync().GetAwaiter();
                    if (!awaiter.IsCompleted)
                    {
                        state = 0;
                        builder.AwaitUnsafeOnCompleted(ref awaiter, ref this);
                        return;
                    }
                    goto case 0;

                StateLabel0:
                    var dbResult = awaiter.GetResult();
                    result = dbResult.ToUpper();
                    builder.SetResult(result);
                    return;
            }
        }
        catch (Exception ex)
        {
            builder.SetException(ex);
        }
    }
}

// ============ EXECUTION FLOW ============

public class ExecutionFlow
{
    public async Task DemonstrateFlowAsync()
    {
        Console.WriteLine("1. Method starts (synchronous)");

        Console.WriteLine("2. Before await");

        // Thread is released here!
        await Task.Delay(1000);

        Console.WriteLine("3. After await (may be different thread)");

        // More work continues
        Console.WriteLine("4. Method completes");
    }

    public void CallAsync()
    {
        Console.WriteLine("A. Before calling async method");

        var task = DemonstrateFlowAsync();  // Method starts, returns immediately

        Console.WriteLine("B. After calling async method");

        task.Wait();  // Wait for completion

        Console.WriteLine("C. Task completed");
    }
}

/* Output:
A. Before calling async method
1. Method starts (synchronous)
2. Before await
B. After calling async method
(1 second passes)
3. After await
4. Method completes
C. Task completed
*/

// ============ REAL-WORLD EXAMPLES ============

public class RealWorldAsync
{
    private readonly HttpClient _httpClient = new HttpClient();

    // Web API call
    public async Task<User> GetUserAsync(int userId)
    {
        var response = await _httpClient.GetAsync($"https://api.example.com/users/{userId}");
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<User>(json);
    }

    // Database operation
    public async Task<List<Product>> GetProductsAsync()
    {
        using var connection = new SqlConnection("connection string");
        await connection.OpenAsync();

        using var command = new SqlCommand("SELECT * FROM Products", connection);
        using var reader = await command.ExecuteReaderAsync();

        var products = new List<Product>();
        while (await reader.ReadAsync())
        {
            products.Add(new Product
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                Price = reader.GetDecimal(2)
            });
        }

        return products;
    }

    // File I/O
    public async Task<string> ReadFileAsync(string path)
    {
        using var reader = new StreamReader(path);
        return await reader.ReadToEndAsync();
    }

    public async Task WriteFileAsync(string path, string content)
    {
        using var writer = new StreamWriter(path);
        await writer.WriteAsync(content);
    }

    // Parallel operations
    public async Task<(User user, List<Order> orders, List<Product> products)>
        LoadDashboardDataAsync(int userId)
    {
        // Start all operations in parallel
        var userTask = GetUserAsync(userId);
        var ordersTask = GetUserOrdersAsync(userId);
        var productsTask = GetProductsAsync();

        // Wait for all to complete
        await Task.WhenAll(userTask, ordersTask, productsTask);

        // All results available
        return (userTask.Result, ordersTask.Result, productsTask.Result);
    }

    private async Task<List<Order>> GetUserOrdersAsync(int userId)
    {
        await Task.Delay(100);
        return new List<Order>();
    }
}

// ============ ASYNC GOTCHAS ============

public class AsyncGotchas
{
    // ❌ BAD: Async void (only for event handlers)
    public async void BadAsyncVoid()
    {
        await Task.Delay(1000);
        // Exception cannot be caught by caller!
    }

    // ✅ GOOD: Async Task
    public async Task GoodAsyncTask()
    {
        await Task.Delay(1000);
        // Exception can be caught
    }

    // ❌ BAD: Mixing sync and async (can cause deadlocks)
    public void BadMixing()
    {
        var result = GetDataAsync().Result;  // DEADLOCK risk!
    }

    // ✅ GOOD: Async all the way
    public async Task GoodAsync()
    {
        var result = await GetDataAsync();
    }

    // ❌ BAD: Fire and forget
    public void BadFireAndForget()
    {
        ProcessDataAsync();  // No await - exceptions lost!
    }

    // ✅ GOOD: Await or store Task
    public async Task GoodAwait()
    {
        await ProcessDataAsync();
    }

    private async Task<string> GetDataAsync() => await Task.FromResult("data");
    private async Task ProcessDataAsync() => await Task.Delay(100);
}

// ============ ASYNC RETURN TYPES ============

public class AsyncReturnTypes
{
    // Task - no return value
    public async Task DoWorkAsync()
    {
        await Task.Delay(1000);
    }

    // Task<T> - returns value
    public async Task<int> CalculateAsync()
    {
        await Task.Delay(1000);
        return 42;
    }

    // ValueTask<T> - for performance (more on this in Q40)
    public async ValueTask<int> GetCachedValueAsync()
    {
        if (_cache.TryGetValue("key", out int value))
            return value;  // Synchronous return

        value = await ExpensiveOperationAsync();
        _cache["key"] = value;
        return value;
    }

    // void - ONLY for event handlers
    private async void Button_Click(object sender, EventArgs e)
    {
        await ProcessClickAsync();
    }

    private Dictionary<string, int> _cache = new();
    private async Task<int> ExpensiveOperationAsync() => await Task.FromResult(100);
    private async Task ProcessClickAsync() => await Task.Delay(100);
}

// ============ ASYNC WITH LINQ ============

public class AsyncLinq
{
    public async Task<List<UserDto>> GetActiveUsersAsync()
    {
        var users = await GetAllUsersAsync();

        // LINQ works on already-loaded data
        return users
            .Where(u => u.IsActive)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Name = u.Name
            })
            .ToList();
    }

    // Process items asynchronously
    public async Task<List<string>> ProcessItemsAsync(List<int> ids)
    {
        var tasks = ids.Select(id => ProcessItemAsync(id));
        return (await Task.WhenAll(tasks)).ToList();
    }

    private async Task<List<User>> GetAllUsersAsync()
    {
        await Task.Delay(100);
        return new List<User>();
    }

    private async Task<string> ProcessItemAsync(int id)
    {
        await Task.Delay(10);
        return $"Processed {id}";
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public bool IsActive { get; set; }
}

public class UserDto
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public class Order { }
```

**Key Benefits:**
- ✅ Non-blocking I/O operations
- ✅ Better scalability (freed threads)
- ✅ Improved responsiveness (UI apps)
- ✅ Cleaner code than callbacks
- ✅ Exception handling with try-catch

**Important Rules:**
1. Async all the way (don't mix sync/async)
2. Never use `async void` (except event handlers)
3. Always await or return Task
4. Use ConfigureAwait(false) in libraries
5. Avoid Task.Result or Task.Wait() (deadlock risk)

---

### Q36: What is the difference between Task and Thread?

**Task:**
- Higher-level abstraction
- Represents asynchronous operation
- Uses ThreadPool
- Lightweight
- Composable
- Return values supported

**Thread:**
- Lower-level construct
- Represents OS thread
- Direct thread creation
- Heavyweight
- Manual management
- No return value

**Example:**
```csharp
// ============ THREAD EXAMPLE ============

public class ThreadExample
{
    public void UseThread()
    {
        // Create and start thread
        var thread = new Thread(() =>
        {
            Console.WriteLine($"Thread ID: {Thread.CurrentThread.ManagedThreadId}");
            Thread.Sleep(1000);
            Console.WriteLine("Thread completed");
        });

        thread.Start();
        thread.Join();  // Wait for completion

        // No return value support
        // More resource intensive
        // Manual lifecycle management
    }

    public void MultipleThreads()
    {
        var threads = new List<Thread>();

        for (int i = 0; i < 5; i++)
        {
            int taskId = i;
            var thread = new Thread(() =>
            {
                Console.WriteLine($"Thread {taskId} starting");
                Thread.Sleep(1000);
                Console.WriteLine($"Thread {taskId} completed");
            });

            threads.Add(thread);
            thread.Start();
        }

        // Wait for all threads
        foreach (var thread in threads)
        {
            thread.Join();
        }
    }
}

// ============ TASK EXAMPLE ============

public class TaskExample
{
    public async Task UseTask()
    {
        // Create and start task
        var task = Task.Run(() =>
        {
            Console.WriteLine($"Task Thread ID: {Thread.CurrentThread.ManagedThreadId}");
            Thread.Sleep(1000);
            Console.WriteLine("Task completed");
        });

        await task;  // Wait for completion

        // Uses ThreadPool
        // Lightweight
        // Automatic lifecycle management
    }

    public async Task<int> TaskWithReturnValue()
    {
        // Tasks support return values
        var result = await Task.Run(() =>
        {
            Thread.Sleep(1000);
            return 42;
        });

        return result;
    }

    public async Task MultipleTasks()
    {
        var tasks = new List<Task>();

        for (int i = 0; i < 5; i++)
        {
            int taskId = i;
            var task = Task.Run(() =>
            {
                Console.WriteLine($"Task {taskId} starting");
                Thread.Sleep(1000);
                Console.WriteLine($"Task {taskId} completed");
            });

            tasks.Add(task);
        }

        // Wait for all tasks
        await Task.WhenAll(tasks);
    }
}

// ============ COMPARISON ============

public class Comparison
{
    // Thread-based approach
    public string ProcessWithThread(int value)
    {
        string result = null;
        Exception exception = null;

        var thread = new Thread(() =>
        {
            try
            {
                Thread.Sleep(1000);
                result = $"Processed: {value * 2}";
            }
            catch (Exception ex)
            {
                exception = ex;
            }
        });

        thread.Start();
        thread.Join();

        if (exception != null)
            throw exception;

        return result;  // Awkward return value handling
    }

    // Task-based approach
    public async Task<string> ProcessWithTask(int value)
    {
        return await Task.Run(() =>
        {
            Thread.Sleep(1000);
            return $"Processed: {value * 2}";
        });
        // Clean, natural return value
        // Exception handling built-in
    }
}

// ============ THREADPOOL ============

public class ThreadPoolDemo
{
    public void ThreadPoolUsage()
    {
        // ThreadPool manages thread reuse
        for (int i = 0; i < 10; i++)
        {
            int taskId = i;
            ThreadPool.QueueUserWorkItem(_ =>
            {
                Console.WriteLine($"ThreadPool task {taskId} on thread {Thread.CurrentThread.ManagedThreadId}");
                Thread.Sleep(100);
            });
        }

        Thread.Sleep(2000);  // Wait for completion
    }

    public async Task TaskUsesThreadPool()
    {
        // Task automatically uses ThreadPool
        var tasks = Enumerable.Range(0, 10)
            .Select(i => Task.Run(() =>
            {
                Console.WriteLine($"Task {i} on thread {Thread.CurrentThread.ManagedThreadId}");
                Thread.Sleep(100);
            }))
            .ToArray();

        await Task.WhenAll(tasks);
    }
}

// ============ REAL-WORLD SCENARIOS ============

// When to use Thread: Rare, only when you need:
// - Long-running operations that shouldn't use ThreadPool
// - Custom thread configuration (priority, apartment state)
// - Dedicated thread for specific purpose

public class LongRunningThread
{
    public void ProcessLargeFile(string filePath)
    {
        var thread = new Thread(() =>
        {
            // Long-running, CPU-intensive work
            // Shouldn't block ThreadPool threads
            ProcessFileInternal(filePath);
        });

        thread.IsBackground = true;
        thread.Priority = ThreadPriority.BelowNormal;
        thread.Start();
    }

    private void ProcessFileInternal(string filePath)
    {
        // Complex processing
    }
}

// When to use Task: Almost always!
// - Asynchronous operations
// - Parallel processing
// - I/O operations
// - Composable operations

public class ModernApproach
{
    public async Task<List<Result>> ProcessItemsAsync(List<int> items)
    {
        // Parallel processing with Tasks
        var tasks = items.Select(item => ProcessItemAsync(item));
        var results = await Task.WhenAll(tasks);
        return results.ToList();
    }

    public async Task<Result> ProcessItemAsync(int item)
    {
        await Task.Delay(100);  // Simulates async operation
        return new Result { Value = item * 2 };
    }

    // Long-running task (opt-out of ThreadPool)
    public Task LongRunningTask()
    {
        return Task.Factory.StartNew(
            () =>
            {
                // Long-running work
                Thread.Sleep(10000);
            },
            TaskCreationOptions.LongRunning  // Creates dedicated thread
        );
    }
}

public class Result
{
    public int Value { get; set; }
}
```

**Comparison Table:**
| Feature | Thread | Task |
|---------|--------|------|
| Level | Low-level | High-level |
| Resource | Heavyweight (1MB+ stack) | Lightweight |
| Creation Cost | Expensive | Cheap |
| Pool | Manual | ThreadPool |
| Return Value | No | Yes (Task<T>) |
| Composition | Hard | Easy (async/await) |
| Cancellation | Manual | Built-in (CancellationToken) |
| Exception Handling | Manual | Built-in |
| When to Use | Rarely | Almost always |

**Modern Recommendation:** Use **Task** for 99% of scenarios!

---

### Q37: Explain Task.Run(), Task.Factory.StartNew(), and await Task.Yield().

**Task.Run():**
- Simplified task creation
- Always uses ThreadPool
- Recommended for most cases
- Short syntax

**Task.Factory.StartNew():**
- More control/options
- Can create long-running tasks
- Can specify scheduler
- More complex

**await Task.Yield():**
- Forces async yield point
- Returns control to caller
- Prevents thread starvation
- Useful in loops

**Example:**
```csharp
// ============ TASK.RUN() ============

public class TaskRunExamples
{
    // Basic Task.Run
    public async Task<int> CalculateAsync()
    {
        return await Task.Run(() =>
        {
            // Runs on ThreadPool thread
            Thread.Sleep(1000);
            return 42;
        });
    }

    // CPU-bound work
    public async Task<int> ProcessDataAsync(int[] data)
    {
        return await Task.Run(() =>
        {
            // CPU-intensive calculation on background thread
            return data.Sum(x => x * x);
        });
    }

    // Multiple parallel tasks
    public async Task<int> ParallelCalculationsAsync()
    {
        var task1 = Task.Run(() => Calculate(1));
        var task2 = Task.Run(() => Calculate(2));
        var task3 = Task.Run(() => Calculate(3));

        var results = await Task.WhenAll(task1, task2, task3);
        return results.Sum();
    }

    private int Calculate(int value)
    {
        Thread.Sleep(1000);
        return value * 10;
    }
}

// ============ TASK.FACTORY.STARTNEW() ============

public class TaskFactoryExamples
{
    // Basic usage (similar to Task.Run)
    public Task<int> BasicFactoryAsync()
    {
        return Task.Factory.StartNew(() =>
        {
            Thread.Sleep(1000);
            return 42;
        });
    }

    // Long-running task (creates dedicated thread)
    public Task LongRunningTask()
    {
        return Task.Factory.StartNew(() =>
        {
            // Long-running operation that shouldn't use ThreadPool
            for (int i = 0; i < 100; i++)
            {
                Thread.Sleep(100);
                Console.WriteLine($"Progress: {i}%");
            }
        }, TaskCreationOptions.LongRunning);
        // LongRunning creates a dedicated thread instead of using ThreadPool
    }

    // Custom scheduler
    public Task CustomSchedulerTask()
    {
        var scheduler = new CustomTaskScheduler();

        return Task.Factory.StartNew(() =>
        {
            Console.WriteLine("Running on custom scheduler");
        }, CancellationToken.None, TaskCreationOptions.None, scheduler);
    }

    // Attached child tasks
    public async Task ParentWithChildren()
    {
        await Task.Factory.StartNew(() =>
        {
            Console.WriteLine("Parent starting");

            // Child task attached to parent
            Task.Factory.StartNew(() =>
            {
                Thread.Sleep(1000);
                Console.WriteLine("Child 1 completed");
            }, TaskCreationOptions.AttachedToParent);

            Task.Factory.StartNew(() =>
            {
                Thread.Sleep(2000);
                Console.WriteLine("Child 2 completed");
            }, TaskCreationOptions.AttachedToParent);

            Console.WriteLine("Parent waiting for children");
        });

        Console.WriteLine("All tasks completed");
        // Parent waits for attached children automatically
    }
}

// ============ TASK.YIELD() ============

public class TaskYieldExamples
{
    // Prevent UI thread blocking
    public async Task ProcessItemsWithYieldAsync(List<int> items)
    {
        foreach (var item in items)
        {
            // Process item
            ProcessItem(item);

            // Yield to allow UI updates
            await Task.Yield();
            // Returns control to caller, then continues
        }
    }

    // Prevent thread starvation
    public async Task LongRunningLoopAsync()
    {
        for (int i = 0; i < 1000000; i++)
        {
            // Some work
            DoWork(i);

            // Every 100 iterations, yield
            if (i % 100 == 0)
            {
                await Task.Yield();
                // Allows other tasks to run
            }
        }
    }

    // Force asynchronous execution
    public async Task ForceAsyncAsync()
    {
        Console.WriteLine("Before yield");

        await Task.Yield();  // Force async continuation

        Console.WriteLine("After yield - may be on different thread");
    }

    // UI responsiveness
    public async Task UpdateProgressAsync(IProgress<int> progress)
    {
        for (int i = 0; i <= 100; i++)
        {
            // Heavy computation
            PerformCalculation(i);

            // Report progress
            progress.Report(i);

            // Yield to keep UI responsive
            await Task.Yield();
        }
    }

    private void ProcessItem(int item) { }
    private void DoWork(int i) { }
    private void PerformCalculation(int i) { }
}

// ============ COMPARISON ============

public class ComparisonExamples
{
    public async Task CompareAll()
    {
        // Task.Run - simple, recommended
        var result1 = await Task.Run(() =>
        {
            return Calculate();
        });

        // Task.Factory.StartNew - more control
        var result2 = await Task.Factory.StartNew(() =>
        {
            return Calculate();
        }, CancellationToken.None,
           TaskCreationOptions.DenyChildAttach,
           TaskScheduler.Default);

        // Task.Yield - no calculation, just yields
        await Task.Yield();
        Console.WriteLine("Continued after yield");
    }

    private int Calculate() => 42;
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Image processing
public class ImageProcessor
{
    public async Task<byte[]> ProcessImageAsync(byte[] imageData)
    {
        // CPU-intensive work - offload to background thread
        return await Task.Run(() =>
        {
            // Apply filters, resize, etc.
            return ApplyFilters(imageData);
        });
    }

    private byte[] ApplyFilters(byte[] data) => data;
}

// Example 2: File watcher service
public class FileWatcherService
{
    public Task StartWatchingAsync(string path)
    {
        // Long-running task - needs dedicated thread
        return Task.Factory.StartNew(() =>
        {
            var watcher = new FileSystemWatcher(path);
            watcher.Changed += OnFileChanged;
            watcher.EnableRaisingEvents = true;

            // Keep running
            while (true)
            {
                Thread.Sleep(1000);
            }
        }, TaskCreationOptions.LongRunning);
    }

    private void OnFileChanged(object sender, FileSystemEventArgs e)
    {
        Console.WriteLine($"File changed: {e.FullPath}");
    }
}

// Example 3: Responsive UI update
public class ProgressReporter
{
    public async Task ProcessWithProgressAsync(
        List<string> files,
        IProgress<int> progress)
    {
        for (int i = 0; i < files.Count; i++)
        {
            // Process file
            await ProcessFileAsync(files[i]);

            // Update progress
            progress.Report((i + 1) * 100 / files.Count);

            // Yield to keep UI responsive
            await Task.Yield();
        }
    }

    private async Task ProcessFileAsync(string file)
    {
        await Task.Delay(100);
    }
}

// Example 4: Custom scheduler for limiting concurrency
public class CustomTaskScheduler : TaskScheduler
{
    protected override IEnumerable<Task> GetScheduledTasks() => null;

    protected override void QueueTask(Task task)
    {
        ThreadPool.QueueUserWorkItem(_ => TryExecuteTask(task));
    }

    protected override bool TryExecuteTaskInline(Task task, bool taskWasPreviouslyQueued)
    {
        return TryExecuteTask(task);
    }
}
```

**Decision Guide:**
```
Need simple background work? → Task.Run()
Need long-running operation? → Task.Factory.StartNew(TaskCreationOptions.LongRunning)
Need custom scheduler? → Task.Factory.StartNew(..., scheduler)
Need to prevent UI blocking in loop? → await Task.Yield()
Need responsive long-running loop? → await Task.Yield()
```

**Best Practices:**
- ✅ Default to **Task.Run()** for most scenarios
- ✅ Use **Task.Factory.StartNew()** only when you need advanced options
- ✅ Use **Task.Yield()** in long loops to prevent thread starvation
- ✅ Use **TaskCreationOptions.LongRunning** for truly long operations (minutes/hours)
- ❌ Don't use Task.Yield() excessively (has overhead)

---

### Q38: What is ConfigureAwait(false)? When should you use it?

**ConfigureAwait(false):**
- Doesn't capture SynchronizationContext
- Continues on any thread (not original)
- Performance optimization
- Prevents potential deadlocks
- Used in library code

**When to Use:**
- ✅ Library/reusable code
- ✅ No need to return to original context
- ✅ Performance-critical code
- ❌ UI code (need UI thread)
- ❌ ASP.NET (context needed)

**Example:**
```csharp
// ============ THE PROBLEM ConfigureAwait SOLVES ============

public class DeadlockScenario
{
    // UI application (WinForms/WPF)
    private void Button_Click(object sender, EventArgs e)
    {
        // UI thread blocked waiting for task
        var result = GetDataAsync().Result;  // DEADLOCK!
        textBox.Text = result;
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);  // Tries to return to UI thread
        // But UI thread is blocked waiting!
        return "Data";
    }
}

// ============ SYNCHRONIZATION CONTEXT ============

public class SynchronizationContextExamples
{
    // WITHOUT ConfigureAwait (captures context)
    public async Task WithoutConfigureAwait()
    {
        Console.WriteLine($"Before await: Thread {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000);  // Captures SynchronizationContext

        // Continues on original context (same thread in UI apps)
        Console.WriteLine($"After await: Thread {Thread.CurrentThread.ManagedThreadId}");
    }

    // WITH ConfigureAwait(false) (doesn't capture context)
    public async Task WithConfigureAwait()
    {
        Console.WriteLine($"Before await: Thread {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000).ConfigureAwait(false);  // Doesn't capture context

        // Continues on any available thread
        Console.WriteLine($"After await: Thread {Thread.CurrentThread.ManagedThreadId}");
    }
}

// ============ LIBRARY CODE (Use ConfigureAwait(false)) ============

public class DataService
{
    private readonly HttpClient _httpClient = new HttpClient();

    // Library method - no need for specific context
    public async Task<User> GetUserAsync(int userId)
    {
        var response = await _httpClient
            .GetAsync($"https://api.example.com/users/{userId}")
            .ConfigureAwait(false);  // ← Important for libraries!

        var json = await response.Content
            .ReadAsStringAsync()
            .ConfigureAwait(false);  // ← On every await!

        return JsonSerializer.Deserialize<User>(json);
    }

    // Database operation
    public async Task<List<Product>> GetProductsAsync()
    {
        using var connection = new SqlConnection("connection string");
        await connection.OpenAsync().ConfigureAwait(false);

        using var command = new SqlCommand("SELECT * FROM Products", connection);
        using var reader = await command.ExecuteReaderAsync().ConfigureAwait(false);

        var products = new List<Product>();
        while (await reader.ReadAsync().ConfigureAwait(false))
        {
            products.Add(new Product
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1)
            });
        }

        return products;
    }

    // File I/O
    public async Task<string> ReadFileAsync(string path)
    {
        using var reader = new StreamReader(path);
        return await reader.ReadToEndAsync().ConfigureAwait(false);
    }
}

// ============ UI CODE (Don't use ConfigureAwait(false)) ============

public class UserViewModel
{
    private readonly DataService _dataService;

    // UI code - needs UI thread to update UI
    public async Task LoadDataAsync()
    {
        // No ConfigureAwait here - need to return to UI thread
        var user = await _dataService.GetUserAsync(1);

        // Must be on UI thread to update UI
        UserName = user.Name;  // Updates UI property
    }

    public string UserName { get; set; }
}

// WPF/WinForms example
public partial class MainWindow : Window
{
    public async void LoadButton_Click(object sender, RoutedEventArgs e)
    {
        // No ConfigureAwait - need UI thread
        var data = await LoadDataFromServerAsync();

        // Update UI controls (must be on UI thread)
        DataTextBox.Text = data;
    }

    private async Task<string> LoadDataFromServerAsync()
    {
        using var client = new HttpClient();

        // Internal implementation can use ConfigureAwait(false)
        var response = await client
            .GetStringAsync("https://api.example.com/data")
            .ConfigureAwait(false);

        return response;
    }
}

// ============ ASP.NET CORE (Usually don't need ConfigureAwait) ============

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly DataService _dataService;

    public UsersController(DataService dataService)
    {
        _dataService = dataService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<User>> GetUser(int id)
    {
        // ASP.NET Core doesn't have SynchronizationContext
        // ConfigureAwait(false) not needed but doesn't hurt
        var user = await _dataService.GetUserAsync(id);

        if (user == null)
            return NotFound();

        return Ok(user);
    }
}

// ============ PERFORMANCE IMPACT ============

public class PerformanceBenchmark
{
    public async Task<int> WithoutConfigureAwait()
    {
        int sum = 0;
        for (int i = 0; i < 1000; i++)
        {
            await Task.Delay(1);  // Captures context each time
            sum += i;
        }
        return sum;
    }

    public async Task<int> WithConfigureAwait()
    {
        int sum = 0;
        for (int i = 0; i < 1000; i++)
        {
            await Task.Delay(1).ConfigureAwait(false);  // No context capture
            sum += i;
        }
        return sum;
    }

    // ConfigureAwait(false) is measurably faster in loops!
}

// ============ REAL-WORLD EXAMPLES ============

// Repository pattern (library code)
public class UserRepository
{
    private readonly DbContext _context;

    public async Task<User> GetByIdAsync(int id)
    {
        // Library code - use ConfigureAwait(false)
        return await _context.Users
            .FirstOrDefaultAsync(u => u.Id == id)
            .ConfigureAwait(false);
    }

    public async Task<List<User>> GetAllAsync()
    {
        return await _context.Users
            .ToListAsync()
            .ConfigureAwait(false);
    }

    public async Task SaveAsync(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync().ConfigureAwait(false);
    }
}

// Service layer (may or may not use ConfigureAwait)
public class UserService
{
    private readonly UserRepository _repository;

    // If this is library code, use ConfigureAwait(false)
    public async Task<UserDto> GetUserAsync(int id)
    {
        var user = await _repository.GetByIdAsync(id).ConfigureAwait(false);

        if (user == null)
            return null;

        return new UserDto
        {
            Id = user.Id,
            Name = user.Name
        };
    }
}

// API client (library code)
public class ApiClient
{
    private readonly HttpClient _client;

    public async Task<T> GetAsync<T>(string endpoint)
    {
        var response = await _client.GetAsync(endpoint).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
        return JsonSerializer.Deserialize<T>(json);
    }

    public async Task<bool> PostAsync<T>(string endpoint, T data)
    {
        var json = JsonSerializer.Serialize(data);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _client.PostAsync(endpoint, content).ConfigureAwait(false);
        return response.IsSuccessStatusCode;
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class UserDto
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class DbContext
{
    public DbSet<User> Users { get; set; }
}

public class DbSet<T>
{
    public Task<T> FirstOrDefaultAsync(Func<T, bool> predicate) => Task.FromResult(default(T));
    public Task<List<T>> ToListAsync() => Task.FromResult(new List<T>());
    public void Add(T entity) { }
}
```

**Decision Tree:**
```
Are you writing library/reusable code?
├─ Yes → Use ConfigureAwait(false)
└─ No → Are you in UI code?
    ├─ Yes → DON'T use ConfigureAwait(false)
    └─ No → Are you in ASP.NET Core?
        ├─ Yes → Optional (no context anyway)
        └─ No → Consider your context needs
```

**Key Rules:**
1. **Library code:** Always use `.ConfigureAwait(false)`
2. **UI code:** Never use `.ConfigureAwait(false)`
3. **ASP.NET Core:** Optional (no SynchronizationContext)
4. **Console apps:** Optional (no specific context)

**Benefits of ConfigureAwait(false):**
- ✅ Avoids context switches (faster)
- ✅ Prevents deadlocks
- ✅ Better scalability
- ✅ Reduced thread usage

---

(Continuing with Q39-Q43...)
### Q39: Explain deadlock scenarios with async/await and how to avoid them.

**Deadlock:**
- Two or more tasks waiting for each other
- Common with blocking on async code
- Especially in UI and ASP.NET (pre-Core)
- Can freeze applications

**Common Causes:**
- Mixing sync and async (`.Result`, `.Wait()`)
- Blocking on async code in UI thread
- SynchronizationContext issues

**Example:**
```csharp
// ============ DEADLOCK SCENARIO 1: UI Application ============

public class UIDeadlock
{
    // ❌ DEADLOCK: Blocking call in UI thread
    private void Button_Click(object sender, EventArgs e)
    {
        // UI thread blocked here waiting for task
        var result = GetDataAsync().Result;  // DEADLOCK!

        textBox.Text = result;
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);
        // Tries to return to UI thread, but it's blocked!
        return "Data";
    }

    // ✅ FIX 1: Use async all the way
    private async void Button_ClickFixed(object sender, EventArgs e)
    {
        var result = await GetDataAsync();  // No blocking
        textBox.Text = result;
    }

    // ✅ FIX 2: Use ConfigureAwait(false) in library
    private async Task<string> GetDataAsyncFixed()
    {
        await Task.Delay(1000).ConfigureAwait(false);
        // Doesn't try to return to UI thread
        return "Data";
    }
}

// ============ DEADLOCK SCENARIO 2: ASP.NET (pre-Core) ============

public class AspNetDeadlock
{
    // ❌ DEADLOCK in ASP.NET Framework
    public ActionResult Index()
    {
        // Request thread blocked
        var data = GetDataAsync().Result;  // DEADLOCK!
        return View(data);
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);
        // Tries to return to request context, but it's blocked!
        return "Data";
    }

    // ✅ FIX: Make action async
    public async Task<ActionResult> IndexFixed()
    {
        var data = await GetDataAsync();  // No blocking
        return View(data);
    }
}

// ============ DEADLOCK SCENARIO 3: Task.Wait() ============

public class WaitDeadlock
{
    // ❌ DEADLOCK: Waiting on multiple tasks incorrectly
    public void ProcessData()
    {
        var task1 = Task.Run(() => GetDataAsync());
        var task2 = Task.Run(() => GetDataAsync());

        // Waiting incorrectly
        task1.Wait();
        task2.Wait();
        // Can deadlock if tasks interact
    }

    // ✅ FIX: Use Task.WhenAll
    public async Task ProcessDataFixed()
    {
        var task1 = GetDataAsync();
        var task2 = GetDataAsync();

        await Task.WhenAll(task1, task2);  // Safe
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);
        return "Data";
    }
}

// ============ DEADLOCK SCENARIO 4: Lock in Async ============

public class LockDeadlock
{
    private readonly object _lock = new object();

    // ❌ DEADLOCK: Lock held during await
    public async Task BadLockAsync()
    {
        lock (_lock)  // Lock acquired
        {
            await Task.Delay(1000);  // Thread released
            // Different thread tries to continue, but lock is on different thread!
            // DEADLOCK potential
        }
    }

    // ✅ FIX: Use SemaphoreSlim instead of lock
    private readonly SemaphoreSlim _semaphore = new SemaphoreSlim(1, 1);

    public async Task GoodLockAsync()
    {
        await _semaphore.WaitAsync();
        try
        {
            await Task.Delay(1000);  // Safe with SemaphoreSlim
        }
        finally
        {
            _semaphore.Release();
        }
    }
}

// ============ DEADLOCK SCENARIO 5: Nested Async Calls ============

public class NestedDeadlock
{
    // ❌ DEADLOCK: Blocking in nested call
    public string GetResult()
    {
        return GetResultInternalAsync().Result;  // DEADLOCK!
    }

    private async Task<string> GetResultInternalAsync()
    {
        var data = await FetchDataAsync();
        return data.ToUpper();
    }

    private async Task<string> FetchDataAsync()
    {
        await Task.Delay(1000);
        return "data";
    }

    // ✅ FIX: Async all the way
    public async Task<string> GetResultFixed()
    {
        return await GetResultInternalAsync();  // No blocking
    }
}

// ============ HOW TO AVOID DEADLOCKS ============

public class DeadlockPrevention
{
    // ✅ Rule 1: Never block on async code
    public async Task Rule1()
    {
        // ❌ DON'T:
        // var result = GetDataAsync().Result;
        // var result = GetDataAsync().GetAwaiter().GetResult();
        // GetDataAsync().Wait();

        // ✅ DO:
        var result = await GetDataAsync();
    }

    // ✅ Rule 2: Use ConfigureAwait(false) in libraries
    public async Task<string> Rule2()
    {
        await Task.Delay(1000).ConfigureAwait(false);
        return "Data";
    }

    // ✅ Rule 3: Async all the way down
    public async Task Rule3()
    {
        // All methods in call chain should be async
        await Level1Async();
    }

    private async Task Level1Async()
    {
        await Level2Async();
    }

    private async Task Level2Async()
    {
        await Task.Delay(1000);
    }

    // ✅ Rule 4: Use SemaphoreSlim instead of lock for async
    private readonly SemaphoreSlim _semaphore = new SemaphoreSlim(1, 1);

    public async Task Rule4()
    {
        await _semaphore.WaitAsync();
        try
        {
            await DoWorkAsync();
        }
        finally
        {
            _semaphore.Release();
        }
    }

    // ✅ Rule 5: Don't mix sync and async
    public void Rule5Sync()
    {
        // If method is sync, call sync versions
        Thread.Sleep(1000);
    }

    public async Task Rule5Async()
    {
        // If method is async, use async versions
        await Task.Delay(1000);
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(100);
        return "data";
    }

    private async Task DoWorkAsync()
    {
        await Task.Delay(100);
    }
}

// ============ DETECTING DEADLOCKS ============

public class DeadlockDetection
{
    // Use timeout to detect potential deadlocks
    public async Task<string> SafeCallAsync()
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));

        try
        {
            var task = GetDataAsync();
            return await task.WaitAsync(cts.Token);  // .NET 6+
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("Operation timed out - possible deadlock");
            throw;
        }
    }

    // For older .NET versions
    public async Task<string> SafeCallAsyncLegacy()
    {
        var task = GetDataAsync();
        var timeoutTask = Task.Delay(TimeSpan.FromSeconds(5));

        var completedTask = await Task.WhenAny(task, timeoutTask);

        if (completedTask == timeoutTask)
        {
            Console.WriteLine("Operation timed out - possible deadlock");
            throw new TimeoutException();
        }

        return await task;
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);
        return "data";
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Bad: Console app with blocking
public class BadConsoleApp
{
    static void Main()
    {
        // ❌ This can deadlock
        var result = ProcessAsync().Result;
        Console.WriteLine(result);
    }

    static async Task<string> ProcessAsync()
    {
        await Task.Delay(1000);
        return "Done";
    }
}

// Good: Console app async main (C# 7.1+)
public class GoodConsoleApp
{
    static async Task Main()
    {
        // ✅ Proper async
        var result = await ProcessAsync();
        Console.WriteLine(result);
    }

    static async Task<string> ProcessAsync()
    {
        await Task.Delay(1000);
        return "Done";
    }
}

// Bad: WPF ViewModel
public class BadViewModel
{
    public void LoadData()
    {
        // ❌ UI thread deadlock
        var data = LoadDataAsync().Result;
        Data = data;
    }

    public string Data { get; set; }

    private async Task<string> LoadDataAsync()
    {
        await Task.Delay(1000);
        return "Loaded";
    }
}

// Good: WPF ViewModel
public class GoodViewModel
{
    public async Task LoadDataAsync()
    {
        // ✅ Proper async
        var data = await LoadDataInternalAsync();
        Data = data;
    }

    public string Data { get; set; }

    private async Task<string> LoadDataInternalAsync()
    {
        await Task.Delay(1000).ConfigureAwait(false);
        return "Loaded";
    }
}
```

**Prevention Checklist:**
- ✅ Never use `.Result` or `.Wait()` on tasks
- ✅ Never use `.GetAwaiter().GetResult()` (same issue)
- ✅ Use `ConfigureAwait(false)` in libraries
- ✅ Make methods async all the way
- ✅ Use `SemaphoreSlim` instead of `lock` with async
- ✅ Never await inside `lock` statement
- ✅ Use `async Task Main()` in console apps

---

### Q40: What are ValueTask and ValueTask<T>? When should you use them?

**ValueTask<T>:**
- Value type version of Task<T>
- Performance optimization
- Reduces heap allocations
- For frequently called methods
- When result often available synchronously

**Key Differences from Task:**
- ValueTask is a struct (value type)
- Task is a class (reference type)
- ValueTask reduces allocations when result is cached/immediate
- ValueTask has usage restrictions

**Example:**
```csharp
// ============ BASIC USAGE ============

public class ValueTaskBasics
{
    private Dictionary<string, string> _cache = new();

    // Using ValueTask for potentially cached results
    public async ValueTask<string> GetDataAsync(string key)
    {
        // If cached, return immediately (no Task allocation!)
        if (_cache.TryGetValue(key, out string cached))
        {
            return cached;  // Synchronous return
        }

        // If not cached, await async operation
        var data = await FetchFromDatabaseAsync(key);
        _cache[key] = data;
        return data;
    }

    // Comparison: Using Task (always allocates)
    public async Task<string> GetDataWithTaskAsync(string key)
    {
        if (_cache.TryGetValue(key, out string cached))
        {
            return cached;  // Still allocates Task object!
        }

        var data = await FetchFromDatabaseAsync(key);
        _cache[key] = data;
        return data;
    }

    private async Task<string> FetchFromDatabaseAsync(string key)
    {
        await Task.Delay(100);  // Simulate DB call
        return $"Data for {key}";
    }
}

// ============ WHEN TO USE ValueTask ============

public class ValueTaskUseCases
{
    // ✅ GOOD: Frequently returns cached/immediate results
    private Dictionary<int, User> _userCache = new();

    public ValueTask<User> GetUserAsync(int id)
    {
        if (_userCache.TryGetValue(id, out var user))
        {
            return new ValueTask<User>(user);  // No allocation
        }

        return new ValueTask<User>(FetchUserAsync(id));
    }

    // ✅ GOOD: May complete synchronously based on state
    private int _counter = 0;

    public ValueTask<int> GetNextNumberAsync()
    {
        if (_counter < 100)
        {
            return new ValueTask<int>(_counter++);  // Synchronous
        }

        return GetNumberFromSourceAsync();  // Asynchronous
    }

    // ❌ BAD: Always async, no caching - use Task<T> instead
    public async ValueTask<string> AlwaysAsyncBad()
    {
        await Task.Delay(1000);
        return "Data";  // Pointless use of ValueTask
    }

    // ✅ GOOD: Use Task<T> when always async
    public async Task<string> AlwaysAsyncGood()
    {
        await Task.Delay(1000);
        return "Data";
    }

    private async Task<User> FetchUserAsync(int id)
    {
        await Task.Delay(100);
        return new User { Id = id, Name = $"User {id}" };
    }

    private async ValueTask<int> GetNumberFromSourceAsync()
    {
        await Task.Delay(100);
        return _counter++;
    }
}

// ============ ValueTask RESTRICTIONS ============

public class ValueTaskRestrictions
{
    public async Task DemonstrateRestrictionsAsync()
    {
        // ❌ DON'T: Await ValueTask multiple times
        var vt = GetValueAsync();
        await vt;
        // await vt;  // ERROR: Can only await once!

        // ❌ DON'T: Await concurrently
        var vt2 = GetValueAsync();
        // var task1 = Task.Run(async () => await vt2);
        // var task2 = Task.Run(async () => await vt2);  // ERROR!

        // ✅ DO: Convert to Task if needed multiple times
        var vt3 = GetValueAsync();
        Task<int> task = vt3.AsTask();  // Now can await multiple times
        await task;
        await task;  // OK
    }

    private async ValueTask<int> GetValueAsync()
    {
        await Task.Delay(100);
        return 42;
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceBenchmark
{
    private Dictionary<string, string> _cache = new()
    {
        ["key1"] = "value1",
        ["key2"] = "value2"
    };

    // Task version - allocates Task every call
    public async Task<string> WithTask(string key)
    {
        if (_cache.TryGetValue(key, out var value))
        {
            return value;  // Still allocates Task
        }

        await Task.Delay(10);
        return "not found";
    }

    // ValueTask version - no allocation when cached
    public ValueTask<string> WithValueTask(string key)
    {
        if (_cache.TryGetValue(key, out var value))
        {
            return new ValueTask<string>(value);  // No allocation!
        }

        return new ValueTask<string>(FetchAsync(key));
    }

    private async Task<string> FetchAsync(string key)
    {
        await Task.Delay(10);
        return "not found";
    }

    // Benchmark results (1 million calls to cached value):
    // Task<T>: ~40 MB allocated
    // ValueTask<T>: ~0 MB allocated
}

// ============ INTERFACE DESIGN WITH ValueTask ============

public interface IDataRepository
{
    // Use ValueTask for potentially cached operations
    ValueTask<User> GetByIdAsync(int id);
    ValueTask<List<User>> GetAllAsync();

    // Use Task for operations that are always async
    Task SaveAsync(User user);
    Task DeleteAsync(int id);
}

public class CachedDataRepository : IDataRepository
{
    private readonly Dictionary<int, User> _cache = new();
    private readonly DbContext _dbContext;

    // Benefits from ValueTask - often returns from cache
    public ValueTask<User> GetByIdAsync(int id)
    {
        if (_cache.TryGetValue(id, out var user))
        {
            return new ValueTask<User>(user);
        }

        return new ValueTask<User>(FetchFromDbAsync(id));
    }

    // Also benefits - might have cached list
    public ValueTask<List<User>> GetAllAsync()
    {
        if (_allUsersCache != null)
        {
            return new ValueTask<List<User>>(_allUsersCache);
        }

        return new ValueTask<List<User>>(FetchAllFromDbAsync());
    }

    // Always async - Task is fine
    public async Task SaveAsync(User user)
    {
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        _cache[user.Id] = user;  // Update cache
    }

    public async Task DeleteAsync(int id)
    {
        var user = await _dbContext.Users.FindAsync(id);
        if (user != null)
        {
            _dbContext.Users.Remove(user);
            await _dbContext.SaveChangesAsync();
            _cache.Remove(id);
        }
    }

    private List<User> _allUsersCache;

    private async Task<User> FetchFromDbAsync(int id)
    {
        var user = await _dbContext.Users.FindAsync(id);
        if (user != null)
        {
            _cache[id] = user;
        }
        return user;
    }

    private async Task<List<User>> FetchAllFromDbAsync()
    {
        _allUsersCache = await _dbContext.Users.ToListAsync();
        return _allUsersCache;
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Memory cache wrapper
public class MemoryCacheService
{
    private readonly IMemoryCache _cache;

    public ValueTask<T> GetOrCreateAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration)
    {
        if (_cache.TryGetValue(key, out T cached))
        {
            return new ValueTask<T>(cached);
        }

        return new ValueTask<T>(CreateAndCacheAsync(key, factory, expiration));
    }

    private async Task<T> CreateAndCacheAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration)
    {
        var value = await factory();
        _cache.Set(key, value, expiration);
        return value;
    }
}

// Pooled object manager
public class ObjectPool<T> where T : class, new()
{
    private readonly ConcurrentBag<T> _pool = new();

    public ValueTask<T> RentAsync()
    {
        if (_pool.TryTake(out var item))
        {
            return new ValueTask<T>(item);  // Immediate
        }

        return new ValueTask<T>(CreateNewAsync());  // Async creation
    }

    public void Return(T item)
    {
        _pool.Add(item);
    }

    private async Task<T> CreateNewAsync()
    {
        await Task.Yield();  // Simulate async initialization
        return new T();
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class DbContext
{
    public DbSet<User> Users { get; set; }
    public Task<int> SaveChangesAsync() => Task.FromResult(0);
}

public class DbSet<T> where T : class
{
    public void Add(T entity) { }
    public void Remove(T entity) { }
    public Task<T> FindAsync(params object[] keyValues) => Task.FromResult<T>(null);
    public Task<List<T>> ToListAsync() => Task.FromResult(new List<T>());
}

public interface IMemoryCache
{
    bool TryGetValue(object key, out object value);
    void Set(object key, object value, TimeSpan expiration);
}
```

**Decision Matrix:**
```
Does method often return cached/immediate result? → ValueTask<T>
Does method always await? → Task<T>
Is this a public API? → Consider ValueTask<T> for flexibility
Need to await multiple times? → Task<T>
Need to store in collection? → Task<T> (convert with .AsTask())
Performance critical + caching? → ValueTask<T>
```

**Rules of Thumb:**
- ✅ Use **ValueTask<T>** for frequently called methods with caching
- ✅ Use **Task<T>** when always async
- ✅ Use **Task<T>** for simple cases (easier)
- ❌ Don't await ValueTask multiple times
- ❌ Don't use ValueTask concurrently
- ✅ Convert to Task with `.AsTask()` if needed

---

### Q41: What is SynchronizationContext in async programming?

**SynchronizationContext:**
- Captures execution context
- Determines where continuation runs
- Platform-specific implementations
- UI frameworks have specific contexts
- ASP.NET Core has no context

**Key Concepts:**
- Marshals execution to specific thread/context
- UI apps: marshals back to UI thread
- ASP.NET Framework: marshals to request context
- Console apps: no special context
- ThreadPool: no specific context

**Example:**
```csharp
// ============ WHAT IS SynchronizationContext ============

public class SynchronizationContextBasics
{
    public async Task DemonstrateContextAsync()
    {
        var context = SynchronizationContext.Current;
        Console.WriteLine($"Context: {context?.GetType().Name ?? "null"}");
        Console.WriteLine($"Thread before: {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000);  // Captures context

        Console.WriteLine($"Thread after: {Thread.CurrentThread.ManagedThreadId}");
        // In UI apps: same thread
        // In console/ASP.NET Core: might be different
    }

    public async Task DemonstrateNoContextAsync()
    {
        Console.WriteLine($"Thread before: {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000).ConfigureAwait(false);  // Doesn't capture context

        Console.WriteLine($"Thread after: {Thread.CurrentThread.ManagedThreadId}");
        // Likely different thread
    }
}

// ============ UI SYNCHRONIZATIONCONTEXT ============

// WPF/WinForms example
public class UIContext
{
    private TextBox _textBox;

    // UI thread has SynchronizationContext
    public async void LoadButton_Click(object sender, EventArgs e)
    {
        // Current context = UI SynchronizationContext
        var uiContext = SynchronizationContext.Current;
        Console.WriteLine($"UI Context: {uiContext.GetType().Name}");
        // Output: "DispatcherSynchronizationContext" (WPF)
        // or "WindowsFormsSynchronizationContext" (WinForms)

        Console.WriteLine($"Before await - Thread: {Thread.CurrentThread.ManagedThreadId}");

        // Captures UI context
        await Task.Delay(1000);

        // Returns to UI thread via captured context
        Console.WriteLine($"After await - Thread: {Thread.CurrentThread.ManagedThreadId}");
        // Same thread ID as before!

        // Safe to update UI
        _textBox.Text = "Updated!";  // Must be on UI thread
    }

    // Without context capture
    public async void BadButton_Click(object sender, EventArgs e)
    {
        await Task.Delay(1000).ConfigureAwait(false);  // Doesn't capture context

        // ❌ ERROR: Not on UI thread!
        // _textBox.Text = "Updated!";  // Exception!

        // ✅ Must manually marshal to UI thread
        var uiContext = SynchronizationContext.Current;
        // uiContext is null here!
    }
}

// ============ ASP.NET FRAMEWORK SYNCHRONIZATIONCONTEXT ============

// ASP.NET Framework (NOT Core)
public class AspNetFrameworkContext
{
    // ASP.NET Framework has AspNetSynchronizationContext
    public async Task<ActionResult> Index()
    {
        var context = SynchronizationContext.Current;
        Console.WriteLine($"Context: {context?.GetType().Name}");
        // Output: "AspNetSynchronizationContext"

        // Context captures request context
        await SomeAsyncOperation();

        // Returns to request context
        // HttpContext still available
        return View();
    }

    private async Task SomeAsyncOperation()
    {
        await Task.Delay(1000);
        // Can still access HttpContext
    }
}

// ============ ASP.NET CORE (NO CONTEXT!) ============

[ApiController]
[Route("api/[controller]")]
public class AspNetCoreContext : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var context = SynchronizationContext.Current;
        Console.WriteLine($"Context: {context?.GetType().Name ?? "null"}");
        // Output: "null" - ASP.NET Core has NO SynchronizationContext!

        Console.WriteLine($"Thread before: {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000);

        Console.WriteLine($"Thread after: {Thread.CurrentThread.ManagedThreadId}");
        // Likely different thread - that's OK!

        // HttpContext still available through AsyncLocal
        var user = HttpContext.User;

        return Ok("Done");
    }
}

// ============ CONSOLE APP (NO CONTEXT) ============

public class ConsoleContext
{
    static async Task Main()
    {
        var context = SynchronizationContext.Current;
        Console.WriteLine($"Context: {context?.GetType().Name ?? "null"}");
        // Output: "null" - console apps have no context

        Console.WriteLine($"Thread before: {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000);

        Console.WriteLine($"Thread after: {Thread.CurrentThread.ManagedThreadId}");
        // Likely different thread
    }
}

// ============ MANUALLY POSTING TO CONTEXT ============

public class ManualContextPosting
{
    public async Task PostToContextAsync()
    {
        // Capture current context
        var capturedContext = SynchronizationContext.Current;

        await Task.Run(() =>
        {
            // Running on ThreadPool thread
            Console.WriteLine($"Background thread: {Thread.CurrentThread.ManagedThreadId}");

            // Post work back to captured context
            capturedContext?.Post(_ =>
            {
                Console.WriteLine($"Back on original context: {Thread.CurrentThread.ManagedThreadId}");
                // This runs on the original context's thread
            }, null);
        });
    }

    public async Task SendToContextAsync()
    {
        var capturedContext = SynchronizationContext.Current;

        await Task.Run(() =>
        {
            // Send (synchronous) vs Post (async)
            capturedContext?.Send(_ =>
            {
                Console.WriteLine("Synchronously on original context");
                // Blocks until complete
            }, null);
        });
    }
}

// ============ CUSTOM SYNCHRONIZATIONCONTEXT ============

public class CustomSynchronizationContext : SynchronizationContext
{
    private readonly ConcurrentQueue<(SendOrPostCallback callback, object state)> _queue = new();
    private readonly Thread _thread;
    private volatile bool _running = true;

    public CustomSynchronizationContext()
    {
        _thread = new Thread(RunMessageLoop);
        _thread.Start();
    }

    // Post work asynchronously
    public override void Post(SendOrPostCallback d, object state)
    {
        _queue.Enqueue((d, state));
    }

    // Send work synchronously
    public override void Send(SendOrPostCallback d, object state)
    {
        var done = new ManualResetEventSlim();
        Exception exception = null;

        Post(_ =>
        {
            try
            {
                d(state);
            }
            catch (Exception ex)
            {
                exception = ex;
            }
            finally
            {
                done.Set();
            }
        }, null);

        done.Wait();
        if (exception != null)
            throw exception;
    }

    private void RunMessageLoop()
    {
        SetSynchronizationContext(this);

        while (_running)
        {
            if (_queue.TryDequeue(out var item))
            {
                item.callback(item.state);
            }
            else
            {
                Thread.Sleep(10);
            }
        }
    }

    public void Shutdown()
    {
        _running = false;
    }
}

// ============ TESTING WITH CUSTOM CONTEXT ============

public class CustomContextExample
{
    public async Task UseCustomContextAsync()
    {
        var customContext = new CustomSynchronizationContext();
        SynchronizationContext.SetSynchronizationContext(customContext);

        Console.WriteLine($"Initial thread: {Thread.CurrentThread.ManagedThreadId}");

        await Task.Delay(1000);

        Console.WriteLine($"After await thread: {Thread.CurrentThread.ManagedThreadId}");
        // Returns to custom context's thread

        customContext.Shutdown();
    }
}

// ============ CONTEXT IN DIFFERENT FRAMEWORKS ============

public class ContextComparison
{
    /*
     * FRAMEWORK COMPARISON:
     *
     * WPF:
     * - DispatcherSynchronizationContext
     * - Marshals to UI thread (Dispatcher)
     * - Must return to UI thread to update UI
     *
     * WinForms:
     * - WindowsFormsSynchronizationContext
     * - Marshals to UI thread (message pump)
     * - Must return to UI thread to update controls
     *
     * ASP.NET Framework:
     * - AspNetSynchronizationContext
     * - Marshals to request context
     * - Allows only one operation per request at a time
     *
     * ASP.NET Core:
     * - No SynchronizationContext!
     * - Uses AsyncLocal for HttpContext
     * - Can run continuations on any thread
     * - Better scalability
     *
     * Console/.NET Worker:
     * - No SynchronizationContext
     * - Continuations run on ThreadPool
     * - No specific thread affinity
     *
     * xUnit/NUnit Tests:
     * - Usually no context (depends on framework)
     * - Some test frameworks provide context
     */
}

// ============ AVOIDING CONTEXT CAPTURE ============

public class AvoidingContextCapture
{
    // Library method - avoid capturing context
    public async Task<string> LibraryMethodAsync()
    {
        // Always use ConfigureAwait(false) in library code
        await Task.Delay(1000).ConfigureAwait(false);

        // No longer on original context
        var context = SynchronizationContext.Current;  // Likely null

        return "Result";
    }

    // UI method - capture context
    private TextBox _textBox;

    public async Task UIMethodAsync()
    {
        // Don't use ConfigureAwait(false) in UI code
        var result = await LibraryMethodAsync();

        // Back on UI thread (context was captured by this await)
        _textBox.Text = result;  // Safe
    }
}

// ============ REAL-WORLD SCENARIOS ============

// Scenario 1: Background service in WPF
public class WpfBackgroundService
{
    private readonly Dispatcher _dispatcher;

    public WpfBackgroundService(Dispatcher dispatcher)
    {
        _dispatcher = dispatcher;
    }

    public async Task ProcessDataAsync()
    {
        // Background work - no UI context needed
        var data = await FetchDataAsync().ConfigureAwait(false);

        // Need to update UI - explicitly marshal to UI thread
        await _dispatcher.InvokeAsync(() =>
        {
            // Now on UI thread
            UpdateUI(data);
        });
    }

    private async Task<string> FetchDataAsync()
    {
        await Task.Delay(1000);
        return "Data";
    }

    private void UpdateUI(string data)
    {
        // Update UI controls
    }
}

// Scenario 2: Unit testing with context
public class UnitTestWithContext
{
    [Fact]
    public async Task TestWithContextAsync()
    {
        // Create a test context
        var testContext = new TestSynchronizationContext();
        SynchronizationContext.SetSynchronizationContext(testContext);

        try
        {
            await MethodUnderTest();

            // Verify method ran on expected context
            Assert.True(testContext.WasUsed);
        }
        finally
        {
            SynchronizationContext.SetSynchronizationContext(null);
        }
    }

    private async Task MethodUnderTest()
    {
        await Task.Delay(100);
    }
}

public class TestSynchronizationContext : SynchronizationContext
{
    public bool WasUsed { get; private set; }

    public override void Post(SendOrPostCallback d, object state)
    {
        WasUsed = true;
        base.Post(d, state);
    }
}

public class Dispatcher
{
    public Task InvokeAsync(Action action)
    {
        action();
        return Task.CompletedTask;
    }
}

public class TextBox
{
    public string Text { get; set; }
}
```

**Summary Table:**
| Platform | SynchronizationContext | Behavior |
|----------|----------------------|----------|
| WPF | DispatcherSynchronizationContext | Returns to UI thread |
| WinForms | WindowsFormsSynchronizationContext | Returns to UI thread |
| ASP.NET Framework | AspNetSynchronizationContext | Returns to request context |
| ASP.NET Core | **None** | Any ThreadPool thread |
| Console | **None** | Any ThreadPool thread |
| xUnit/NUnit | Usually none | Any ThreadPool thread |

**Key Points:**
- ✅ SynchronizationContext captures execution context for continuations
- ✅ UI frameworks need context to marshal back to UI thread
- ✅ ASP.NET Core removed context for better scalability
- ✅ Use `ConfigureAwait(false)` in libraries to avoid context capture
- ✅ Don't use `ConfigureAwait(false)` in UI code

---

### Q42: What is the difference between Task.WaitAll() and Task.WhenAll()?

**Task.WaitAll():**
- Synchronous blocking call
- Waits on current thread
- Returns void
- Can cause deadlocks
- Aggregates exceptions differently

**Task.WhenAll():**
- Asynchronous method
- Returns awaitable Task
- Non-blocking
- Recommended approach
- Better exception handling

**Example:**
```csharp
// ============ BASIC DIFFERENCE ============

public class WaitAllVsWhenAll
{
    // ❌ Task.WaitAll - BLOCKS current thread
    public void UseWaitAll()
    {
        var task1 = Task.Delay(1000);
        var task2 = Task.Delay(2000);
        var task3 = Task.Delay(3000);

        Console.WriteLine("Starting tasks...");

        // BLOCKS current thread for 3 seconds!
        Task.WaitAll(task1, task2, task3);

        Console.WriteLine("All tasks completed");
    }

    // ✅ Task.WhenAll - NON-BLOCKING
    public async Task UseWhenAll()
    {
        var task1 = Task.Delay(1000);
        var task2 = Task.Delay(2000);
        var task3 = Task.Delay(3000);

        Console.WriteLine("Starting tasks...");

        // Awaits without blocking thread
        await Task.WhenAll(task1, task2, task3);

        Console.WriteLine("All tasks completed");
    }
}

// ============ RETURN VALUES ============

public class ReturnValues
{
    // WaitAll returns void - awkward to get results
    public List<string> UseWaitAllWithResults()
    {
        var task1 = Task.Run(() => "Result 1");
        var task2 = Task.Run(() => "Result 2");
        var task3 = Task.Run(() => "Result 3");

        // Wait for all
        Task.WaitAll(task1, task2, task3);

        // Manually collect results
        return new List<string>
        {
            task1.Result,  // Already completed, safe to access
            task2.Result,
            task3.Result
        };
    }

    // WhenAll returns Task<T[]> - clean results
    public async Task<List<string>> UseWhenAllWithResults()
    {
        var task1 = Task.Run(() => "Result 1");
        var task2 = Task.Run(() => "Result 2");
        var task3 = Task.Run(() => "Result 3");

        // Wait and get results in one line
        var results = await Task.WhenAll(task1, task2, task3);

        return results.ToList();  // results is string[]
    }
}

// ============ EXCEPTION HANDLING ============

public class ExceptionHandling
{
    // WaitAll - throws AggregateException
    public void WaitAllExceptions()
    {
        var task1 = Task.Run(() => throw new InvalidOperationException("Error 1"));
        var task2 = Task.Run(() => throw new ArgumentException("Error 2"));
        var task3 = Task.Run(() => "Success");

        try
        {
            Task.WaitAll(task1, task2, task3);
        }
        catch (AggregateException ex)
        {
            // All exceptions wrapped in AggregateException
            Console.WriteLine($"Caught {ex.InnerExceptions.Count} exceptions");
            foreach (var inner in ex.InnerExceptions)
            {
                Console.WriteLine($"- {inner.GetType().Name}: {inner.Message}");
            }
        }
    }

    // WhenAll - throws first exception only
    public async Task WhenAllExceptions()
    {
        var task1 = Task.Run(() => throw new InvalidOperationException("Error 1"));
        var task2 = Task.Run(() => throw new ArgumentException("Error 2"));
        var task3 = Task.Run(() => "Success");

        try
        {
            await Task.WhenAll(task1, task2, task3);
        }
        catch (Exception ex)
        {
            // Only first exception thrown
            Console.WriteLine($"Caught: {ex.GetType().Name}: {ex.Message}");
            // Output: "Caught: InvalidOperationException: Error 1"
        }
    }

    // WhenAll - access all exceptions via task
    public async Task WhenAllAllExceptions()
    {
        var task1 = Task.Run(() => throw new InvalidOperationException("Error 1"));
        var task2 = Task.Run(() => throw new ArgumentException("Error 2"));
        var task3 = Task.Run(() => "Success");

        var whenAllTask = Task.WhenAll(task1, task2, task3);

        try
        {
            await whenAllTask;
        }
        catch
        {
            // Access all exceptions via task.Exception
            if (whenAllTask.Exception != null)
            {
                Console.WriteLine($"All exceptions: {whenAllTask.Exception.InnerExceptions.Count}");
                foreach (var inner in whenAllTask.Exception.InnerExceptions)
                {
                    Console.WriteLine($"- {inner.GetType().Name}: {inner.Message}");
                }
            }
        }
    }
}

// ============ DEADLOCK SCENARIOS ============

public class DeadlockScenarios
{
    // ❌ WaitAll can cause deadlock in UI apps
    private void Button_Click(object sender, EventArgs e)
    {
        var task1 = GetDataAsync();
        var task2 = GetDataAsync();

        // DEADLOCK! UI thread blocked
        Task.WaitAll(task1, task2);
    }

    // ✅ WhenAll doesn't block
    private async void Button_ClickFixed(object sender, EventArgs e)
    {
        var task1 = GetDataAsync();
        var task2 = GetDataAsync();

        await Task.WhenAll(task1, task2);  // Safe
    }

    private async Task<string> GetDataAsync()
    {
        await Task.Delay(1000);
        return "Data";
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceComparison
{
    // Both complete in ~3 seconds (parallel execution)
    public void WaitAllParallel()
    {
        var sw = Stopwatch.StartNew();

        var tasks = Enumerable.Range(0, 10)
            .Select(i => Task.Run(() =>
            {
                Thread.Sleep(1000);
                return i;
            }))
            .ToArray();

        Task.WaitAll(tasks);  // Blocks thread but tasks run in parallel

        Console.WriteLine($"WaitAll completed in {sw.ElapsedMilliseconds}ms");
        // ~1000ms (tasks ran in parallel)
    }

    public async Task WhenAllParallel()
    {
        var sw = Stopwatch.StartNew();

        var tasks = Enumerable.Range(0, 10)
            .Select(i => Task.Run(() =>
            {
                Thread.Sleep(1000);
                return i;
            }))
            .ToArray();

        await Task.WhenAll(tasks);  // Doesn't block, tasks run in parallel

        Console.WriteLine($"WhenAll completed in {sw.ElapsedMilliseconds}ms");
        // ~1000ms (tasks ran in parallel)
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Parallel API calls
public class ParallelApiCalls
{
    private readonly HttpClient _httpClient = new HttpClient();

    // ❌ Bad: WaitAll blocks thread
    public List<User> GetAllUsersWaitAll(int[] userIds)
    {
        var tasks = userIds
            .Select(id => GetUserAsync(id))
            .ToArray();

        Task.WaitAll(tasks);  // Blocks

        return tasks.Select(t => t.Result).ToList();
    }

    // ✅ Good: WhenAll is async
    public async Task<List<User>> GetAllUsersWhenAll(int[] userIds)
    {
        var tasks = userIds
            .Select(id => GetUserAsync(id))
            .ToArray();

        var users = await Task.WhenAll(tasks);  // Non-blocking

        return users.ToList();
    }

    private async Task<User> GetUserAsync(int id)
    {
        var response = await _httpClient.GetAsync($"https://api.example.com/users/{id}");
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<User>(json);
    }
}

// Example 2: Parallel database operations
public class ParallelDatabaseOps
{
    private readonly DbContext _context;

    // ❌ Bad: WaitAll in async context
    public async Task<Dashboard> LoadDashboardBad(int userId)
    {
        var userTask = _context.Users.FindAsync(userId).AsTask();
        var ordersTask = _context.Orders.Where(o => o.UserId == userId).ToListAsync();
        var settingsTask = _context.Settings.FindAsync(userId).AsTask();

        // Don't mix WaitAll with async!
        Task.WaitAll(userTask, ordersTask, settingsTask);

        return new Dashboard
        {
            User = userTask.Result,
            Orders = ordersTask.Result,
            Settings = settingsTask.Result
        };
    }

    // ✅ Good: WhenAll for parallel async operations
    public async Task<Dashboard> LoadDashboardGood(int userId)
    {
        var userTask = _context.Users.FindAsync(userId).AsTask();
        var ordersTask = _context.Orders.Where(o => o.UserId == userId).ToListAsync();
        var settingsTask = _context.Settings.FindAsync(userId).AsTask();

        await Task.WhenAll(userTask, ordersTask, settingsTask);

        return new Dashboard
        {
            User = await userTask,
            Orders = await ordersTask,
            Settings = await settingsTask
        };
    }
}

// Example 3: Batch processing
public class BatchProcessing
{
    public async Task<ProcessingResult> ProcessBatchAsync(List<string> files)
    {
        var tasks = files.Select(async file =>
        {
            try
            {
                await ProcessFileAsync(file);
                return (file, success: true, error: (string)null);
            }
            catch (Exception ex)
            {
                return (file, success: false, error: ex.Message);
            }
        }).ToArray();

        // Wait for all, even if some fail
        var results = await Task.WhenAll(tasks);

        return new ProcessingResult
        {
            Total = files.Count,
            Successful = results.Count(r => r.success),
            Failed = results.Count(r => !r.success),
            Errors = results.Where(r => !r.success)
                           .Select(r => $"{r.file}: {r.error}")
                           .ToList()
        };
    }

    private async Task ProcessFileAsync(string file)
    {
        await Task.Delay(100);
        // Process file
    }
}

// Example 4: Timeout with WhenAll
public class TimeoutExample
{
    public async Task<List<string>> GetDataWithTimeout(List<string> urls, TimeSpan timeout)
    {
        var tasks = urls.Select(url => FetchDataAsync(url)).ToArray();

        // Create timeout task
        var timeoutTask = Task.Delay(timeout);

        // Race between completion and timeout
        var completedTask = await Task.WhenAny(Task.WhenAll(tasks), timeoutTask);

        if (completedTask == timeoutTask)
        {
            throw new TimeoutException("Operations timed out");
        }

        return (await Task.WhenAll(tasks)).ToList();
    }

    private async Task<string> FetchDataAsync(string url)
    {
        await Task.Delay(100);
        return $"Data from {url}";
    }
}

// ============ WITH CANCELLATION ============

public class CancellationExample
{
    // WaitAll with cancellation
    public void WaitAllWithCancellation(CancellationToken cancellationToken)
    {
        var tasks = Enumerable.Range(0, 10)
            .Select(i => Task.Run(() => DoWork(i, cancellationToken), cancellationToken))
            .ToArray();

        try
        {
            Task.WaitAll(tasks, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("Operations cancelled");
        }
    }

    // WhenAll with cancellation
    public async Task WhenAllWithCancellation(CancellationToken cancellationToken)
    {
        var tasks = Enumerable.Range(0, 10)
            .Select(i => DoWorkAsync(i, cancellationToken))
            .ToArray();

        try
        {
            await Task.WhenAll(tasks);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("Operations cancelled");
        }
    }

    private void DoWork(int id, CancellationToken cancellationToken)
    {
        for (int i = 0; i < 100; i++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            Thread.Sleep(10);
        }
    }

    private async Task DoWorkAsync(int id, CancellationToken cancellationToken)
    {
        for (int i = 0; i < 100; i++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await Task.Delay(10, cancellationToken);
        }
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class Order
{
    public int UserId { get; set; }
}

public class Settings
{
    public int UserId { get; set; }
}

public class Dashboard
{
    public User User { get; set; }
    public List<Order> Orders { get; set; }
    public Settings Settings { get; set; }
}

public class ProcessingResult
{
    public int Total { get; set; }
    public int Successful { get; set; }
    public int Failed { get; set; }
    public List<string> Errors { get; set; }
}

public class DbContext
{
    public DbSet<User> Users { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<Settings> Settings { get; set; }
}

public class DbSet<T>
{
    public IQueryable<T> Where(Expression<Func<T, bool>> predicate) => Enumerable.Empty<T>().AsQueryable();
    public ValueTask<T> FindAsync(params object[] keyValues) => new ValueTask<T>(default(T));
    public Task<List<T>> ToListAsync() => Task.FromResult(new List<T>());
}
```

**Comparison Table:**
| Feature | Task.WaitAll() | Task.WhenAll() |
|---------|---------------|---------------|
| Execution | Synchronous (blocks) | Asynchronous (awaitable) |
| Returns | void | Task / Task<T[]> |
| Thread Blocking | Yes | No |
| Deadlock Risk | High | Low |
| Exception Type | AggregateException | First exception |
| Use Case | Rare (console apps) | Standard async code |
| Modern Code | ❌ Avoid | ✅ Recommended |

**Key Differences:**
1. **Blocking**: WaitAll blocks, WhenAll doesn't
2. **Return**: WaitAll returns void, WhenAll returns Task<T[]>
3. **Exceptions**: WaitAll throws AggregateException, WhenAll throws first
4. **Context**: WaitAll can deadlock in UI/ASP.NET, WhenAll is safe

**Best Practices:**
- ✅ Always prefer **Task.WhenAll()** in async code
- ✅ Use **await Task.WhenAll()** for parallel operations
- ❌ Avoid **Task.WaitAll()** except in rare console app scenarios
- ✅ Access all exceptions via task.Exception if needed
- ✅ Combine with Task.WhenAny() for timeout scenarios

---

### Q43: How do you handle exceptions in async methods?

**Exception Handling in Async:**
- Exceptions stored in Task
- Unwrapped on await
- AggregateException for multiple tasks
- Try-catch around await
- Task.Exception property for details

**Key Concepts:**
- Exceptions don't throw immediately
- Must await to observe exceptions
- Fire-and-forget loses exceptions
- async void is dangerous

**Example:**
```csharp
// ============ BASIC EXCEPTION HANDLING ============

public class BasicAsyncExceptions
{
    // ✅ Standard try-catch with async/await
    public async Task HandleExceptionAsync()
    {
        try
        {
            await MethodThatThrowsAsync();
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine($"Caught: {ex.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Unexpected: {ex.Message}");
        }
    }

    private async Task MethodThatThrowsAsync()
    {
        await Task.Delay(100);
        throw new InvalidOperationException("Something went wrong");
    }

    // ✅ With finally block
    public async Task WithFinallyAsync()
    {
        try
        {
            await ProcessDataAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
        finally
        {
            Console.WriteLine("Cleanup always runs");
        }
    }

    private async Task ProcessDataAsync()
    {
        await Task.Delay(100);
    }
}

// ============ EXCEPTION STORAGE IN TASK ============

public class ExceptionStorage
{
    public async Task DemonstrateExceptionStorageAsync()
    {
        // Exception stored in task, not thrown yet
        var task = MethodThatThrowsAsync();

        Console.WriteLine($"Task status: {task.Status}");
        // Status: Running

        await Task.Delay(200);

        Console.WriteLine($"Task status: {task.Status}");
        // Status: Faulted

        Console.WriteLine($"Exception: {task.Exception?.GetType().Name}");
        // Exception: AggregateException

        try
        {
            // Exception thrown when awaited
            await task;
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine($"Caught when awaited: {ex.Message}");
        }
    }

    private async Task MethodThatThrowsAsync()
    {
        await Task.Delay(100);
        throw new InvalidOperationException("Error");
    }
}

// ============ FIRE-AND-FORGET LOSES EXCEPTIONS ============

public class FireAndForget
{
    // ❌ BAD: Exception lost!
    public void BadFireAndForget()
    {
        // Exception will be lost - no one awaits this task
        MethodThatThrowsAsync();  // No await!

        Console.WriteLine("Method continues, exception never observed");
    }

    // ✅ GOOD: Await the task
    public async Task GoodAwait()
    {
        try
        {
            await MethodThatThrowsAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Exception caught: {ex.Message}");
        }
    }

    // ✅ GOOD: Fire-and-forget with error handling
    public void SafeFireAndForget()
    {
        _ = SafeFireAndForgetAsync();
    }

    private async Task SafeFireAndForgetAsync()
    {
        try
        {
            await MethodThatThrowsAsync();
        }
        catch (Exception ex)
        {
            // Log or handle error
            Console.WriteLine($"Background error: {ex.Message}");
        }
    }

    private async Task MethodThatThrowsAsync()
    {
        await Task.Delay(100);
        throw new InvalidOperationException("Error");
    }
}

// ============ ASYNC VOID IS DANGEROUS ============

public class AsyncVoidDanger
{
    // ❌ VERY BAD: Exception crashes app!
    public async void DangerousAsyncVoid()
    {
        await Task.Delay(100);
        throw new Exception("This crashes the app!");
        // Cannot be caught by caller!
    }

    // Caller cannot catch exception
    public void CallAsyncVoid()
    {
        try
        {
            DangerousAsyncVoid();  // Fire-and-forget
        }
        catch (Exception ex)
        {
            // This NEVER catches the exception!
            Console.WriteLine("Never reached");
        }
    }

    // ✅ GOOD: Use async Task
    public async Task SafeAsyncTask()
    {
        await Task.Delay(100);
        throw new Exception("This can be caught");
    }

    public async Task CallAsyncTask()
    {
        try
        {
            await SafeAsyncTask();
        }
        catch (Exception ex)
        {
            // This catches the exception properly
            Console.WriteLine($"Caught: {ex.Message}");
        }
    }

    // ✅ ACCEPTABLE: async void for event handlers
    private async void Button_Click(object sender, EventArgs e)
    {
        try
        {
            await ProcessClickAsync();
        }
        catch (Exception ex)
        {
            // Must handle exceptions within async void
            MessageBox.Show($"Error: {ex.Message}");
        }
    }

    private async Task ProcessClickAsync()
    {
        await Task.Delay(100);
    }
}

// ============ MULTIPLE TASKS WITH Task.WhenAll ============

public class MultipleTaskExceptions
{
    // All exceptions in AggregateException
    public async Task WhenAllExceptionsAsync()
    {
        var task1 = Task.Run(() => throw new InvalidOperationException("Error 1"));
        var task2 = Task.Run(() => throw new ArgumentException("Error 2"));
        var task3 = Task.Run(() => throw new NullReferenceException("Error 3"));

        var whenAllTask = Task.WhenAll(task1, task2, task3);

        try
        {
            await whenAllTask;
        }
        catch (Exception ex)
        {
            // Only first exception caught
            Console.WriteLine($"First exception: {ex.Message}");
            // Output: "Error 1"

            // Access all exceptions via task.Exception
            if (whenAllTask.Exception != null)
            {
                Console.WriteLine($"Total exceptions: {whenAllTask.Exception.InnerExceptions.Count}");
                foreach (var inner in whenAllTask.Exception.InnerExceptions)
                {
                    Console.WriteLine($"- {inner.GetType().Name}: {inner.Message}");
                }
            }
        }
    }

    // Handle each task individually
    public async Task HandleIndividuallyAsync()
    {
        var task1 = SafeTaskAsync(1);
        var task2 = SafeTaskAsync(2);
        var task3 = SafeTaskAsync(3);

        await Task.WhenAll(task1, task2, task3);

        // Check each task's exception
        if (task1.IsFaulted)
            Console.WriteLine($"Task 1 failed: {task1.Exception?.InnerException?.Message}");
        if (task2.IsFaulted)
            Console.WriteLine($"Task 2 failed: {task2.Exception?.InnerException?.Message}");
        if (task3.IsFaulted)
            Console.WriteLine($"Task 3 failed: {task3.Exception?.InnerException?.Message}");
    }

    private async Task SafeTaskAsync(int id)
    {
        try
        {
            await Task.Run(() =>
            {
                if (id == 2)
                    throw new InvalidOperationException($"Error in task {id}");
            });
        }
        catch
        {
            // Swallow exception to complete task successfully
            // Or re-throw to keep it faulted
        }
    }
}

// ============ CUSTOM EXCEPTION HANDLING ============

public class CustomExceptionHandling
{
    // Retry logic
    public async Task<T> RetryAsync<T>(
        Func<Task<T>> operation,
        int maxRetries = 3,
        TimeSpan? delay = null)
    {
        delay ??= TimeSpan.FromSeconds(1);

        for (int attempt = 0; attempt <= maxRetries; attempt++)
        {
            try
            {
                return await operation();
            }
            catch (Exception ex) when (attempt < maxRetries)
            {
                Console.WriteLine($"Attempt {attempt + 1} failed: {ex.Message}");
                await Task.Delay(delay.Value);
            }
        }

        // Last attempt - let exception propagate
        return await operation();
    }

    // Usage
    public async Task<string> UseRetryAsync()
    {
        return await RetryAsync(async () =>
        {
            var result = await FetchDataAsync();
            return result;
        }, maxRetries: 3);
    }

    // Timeout with exception
    public async Task<T> WithTimeoutAsync<T>(Task<T> task, TimeSpan timeout)
    {
        using var cts = new CancellationTokenSource(timeout);

        try
        {
            return await task.WaitAsync(cts.Token);  // .NET 6+
        }
        catch (OperationCanceledException)
        {
            throw new TimeoutException($"Operation timed out after {timeout.TotalSeconds}s");
        }
    }

    // Fallback on exception
    public async Task<T> WithFallbackAsync<T>(
        Func<Task<T>> primary,
        Func<Task<T>> fallback)
    {
        try
        {
            return await primary();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Primary failed: {ex.Message}, trying fallback");
            return await fallback();
        }
    }

    private async Task<string> FetchDataAsync()
    {
        await Task.Delay(100);
        return "Data";
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: API call with retry and logging
public class ApiService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger _logger;

    public async Task<User> GetUserAsync(int userId)
    {
        try
        {
            var response = await _httpClient.GetAsync($"https://api.example.com/users/{userId}");

            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"API returned {response.StatusCode}");
            }

            var json = await response.Content.ReadAsStringAsync();
            return JsonSerializer.Deserialize<User>(json);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, $"Failed to fetch user {userId}");
            throw;  // Re-throw after logging
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, $"Failed to deserialize user {userId}");
            throw new InvalidOperationException("Invalid API response", ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Unexpected error fetching user {userId}");
            throw;
        }
    }
}

// Example 2: Database operation with transaction
public class DatabaseService
{
    private readonly DbContext _context;

    public async Task<bool> SaveOrderAsync(Order order)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // Save order
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // Update inventory
            await UpdateInventoryAsync(order);

            // Commit transaction
            await transaction.CommitAsync();

            return true;
        }
        catch (DbUpdateException ex)
        {
            // Rollback on database error
            await transaction.RollbackAsync();
            Console.WriteLine($"Database error: {ex.Message}");
            return false;
        }
        catch (Exception ex)
        {
            // Rollback on any error
            await transaction.RollbackAsync();
            Console.WriteLine($"Unexpected error: {ex.Message}");
            throw;
        }
    }

    private async Task UpdateInventoryAsync(Order order)
    {
        await Task.Delay(100);
    }
}

// Example 3: Parallel operations with individual error handling
public class BatchProcessor
{
    public async Task<BatchResult> ProcessBatchAsync(List<string> items)
    {
        var tasks = items.Select(item => ProcessItemSafeAsync(item)).ToArray();

        var results = await Task.WhenAll(tasks);

        return new BatchResult
        {
            TotalProcessed = results.Count(r => r.Success),
            TotalFailed = results.Count(r => !r.Success),
            FailedItems = results.Where(r => !r.Success)
                                .Select(r => r.ItemId)
                                .ToList()
        };
    }

    private async Task<ItemResult> ProcessItemSafeAsync(string item)
    {
        try
        {
            await ProcessItemAsync(item);
            return new ItemResult { ItemId = item, Success = true };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to process {item}: {ex.Message}");
            return new ItemResult { ItemId = item, Success = false, Error = ex.Message };
        }
    }

    private async Task ProcessItemAsync(string item)
    {
        await Task.Delay(100);
        if (item == "bad")
            throw new InvalidOperationException("Bad item");
    }
}

// Example 4: Cancellation with exception
public class CancellableOperation
{
    public async Task<string> LongRunningOperationAsync(CancellationToken cancellationToken)
    {
        try
        {
            for (int i = 0; i < 100; i++)
            {
                cancellationToken.ThrowIfCancellationRequested();

                await Task.Delay(100, cancellationToken);

                Console.WriteLine($"Progress: {i}%");
            }

            return "Completed";
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("Operation was cancelled");
            throw;  // Propagate cancellation
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Operation failed: {ex.Message}");
            throw;
        }
    }
}

// ============ WHEN NOT TO CATCH ============

public class WhenNotToCatch
{
    // ❌ DON'T catch just to re-throw
    public async Task<string> BadCatchAsync()
    {
        try
        {
            return await FetchDataAsync();
        }
        catch (Exception ex)
        {
            throw;  // Pointless catch
        }
    }

    // ✅ DO let it propagate
    public async Task<string> GoodNoCatchAsync()
    {
        return await FetchDataAsync();  // Let exception propagate
    }

    // ✅ DO catch to add context
    public async Task<string> GoodCatchWithContextAsync()
    {
        try
        {
            return await FetchDataAsync();
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException("Failed to fetch data from API", ex);
        }
    }

    private async Task<string> FetchDataAsync()
    {
        await Task.Delay(100);
        return "Data";
    }
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class Order
{
    public int Id { get; set; }
}

public class BatchResult
{
    public int TotalProcessed { get; set; }
    public int TotalFailed { get; set; }
    public List<string> FailedItems { get; set; }
}

public class ItemResult
{
    public string ItemId { get; set; }
    public bool Success { get; set; }
    public string Error { get; set; }
}

public interface ILogger
{
    void LogError(Exception ex, string message);
}

public class DbContext
{
    public DbSet<Order> Orders { get; set; }
    public DatabaseFacade Database { get; set; }
    public Task<int> SaveChangesAsync() => Task.FromResult(0);
}

public class DbSet<T>
{
    public void Add(T entity) { }
}

public class DatabaseFacade
{
    public Task<IDbContextTransaction> BeginTransactionAsync() =>
        Task.FromResult<IDbContextTransaction>(new MockTransaction());
}

public interface IDbContextTransaction : IDisposable
{
    Task CommitAsync();
    Task RollbackAsync();
}

public class MockTransaction : IDbContextTransaction
{
    public Task CommitAsync() => Task.CompletedTask;
    public Task RollbackAsync() => Task.CompletedTask;
    public void Dispose() { }
}

public class MessageBox
{
    public static void Show(string message) { }
}
```

**Exception Handling Best Practices:**
- ✅ Always use try-catch around await
- ✅ Never use async void (except event handlers)
- ✅ Don't fire-and-forget without error handling
- ✅ Access all exceptions via task.Exception with WhenAll
- ✅ Re-throw with `throw;` to preserve stack trace
- ✅ Add context when wrapping exceptions
- ❌ Don't catch just to re-throw
- ❌ Don't ignore exceptions in background tasks

**Common Patterns:**
1. **Retry**: Catch and retry with delay
2. **Fallback**: Catch and try alternative
3. **Timeout**: Catch OperationCanceledException
4. **Logging**: Catch, log, and re-throw
5. **Transaction**: Catch and rollback

---
### Q44: What are LINQ queries? Explain method syntax vs query syntax.

**LINQ (Language Integrated Query):**
- Unified query syntax for different data sources
- Introduced in C# 3.0 (.NET 3.5)
- Works with collections, databases, XML, etc.
- Two syntaxes: Query syntax and Method syntax
- Type-safe queries with IntelliSense support

**Query Syntax:**
- SQL-like syntax
- Uses keywords: from, where, select, join, group, etc.
- More readable for complex queries
- Compiled to method syntax by compiler

**Method Syntax:**
- Extension methods on IEnumerable<T>
- Uses lambda expressions
- More flexible and powerful
- Some operations only available in method syntax

**Example:**
```csharp
// ============ BASIC LINQ QUERIES ============

public class LinqBasics
{
    public void DemonstrateBothSyntaxes()
    {
        var numbers = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

        // ============ QUERY SYNTAX ============
        var evenNumbersQuery = from n in numbers
                               where n % 2 == 0
                               select n;

        // ============ METHOD SYNTAX ============
        var evenNumbersMethod = numbers.Where(n => n % 2 == 0);

        // Both produce same results
        Console.WriteLine("Query syntax: " + string.Join(", ", evenNumbersQuery));
        Console.WriteLine("Method syntax: " + string.Join(", ", evenNumbersMethod));
        // Output: 2, 4, 6, 8, 10
    }
}

// ============ QUERY SYNTAX EXAMPLES ============

public class QuerySyntaxExamples
{
    public void SimpleQueries()
    {
        var students = GetStudents();

        // Basic filtering
        var highScorers = from s in students
                         where s.Score >= 90
                         select s;

        // Projection (select specific properties)
        var studentNames = from s in students
                          select s.Name;

        // Anonymous type projection
        var studentInfo = from s in students
                         where s.Score >= 80
                         select new
                         {
                             s.Name,
                             s.Score,
                             Grade = s.Score >= 90 ? "A" : "B"
                         };

        // Ordering
        var sortedStudents = from s in students
                            orderby s.Score descending
                            select s;

        // Multiple conditions
        var filteredStudents = from s in students
                              where s.Score >= 70 && s.Age >= 18
                              orderby s.Name
                              select s;
    }

    public void ComplexQueries()
    {
        var students = GetStudents();
        var courses = GetCourses();

        // Join
        var studentCourses = from s in students
                            join c in courses on s.CourseId equals c.Id
                            select new
                            {
                                StudentName = s.Name,
                                CourseName = c.Name
                            };

        // Group by
        var studentsByAge = from s in students
                           group s by s.Age into ageGroup
                           select new
                           {
                               Age = ageGroup.Key,
                               Count = ageGroup.Count(),
                               Students = ageGroup.ToList()
                           };

        // Let clause (intermediate variable)
        var studentsWithCalculation = from s in students
                                     let bonus = s.Score * 0.1
                                     where s.Score + bonus >= 90
                                     select new
                                     {
                                         s.Name,
                                         OriginalScore = s.Score,
                                         BonusPoints = bonus,
                                         FinalScore = s.Score + bonus
                                     };

        // Multiple from (SelectMany)
        var studentSubjects = from s in students
                             from subject in s.Subjects
                             select new
                             {
                                 s.Name,
                                 Subject = subject
                             };
    }

    private List<Student> GetStudents() => new List<Student>
    {
        new Student { Id = 1, Name = "Alice", Age = 20, Score = 95, CourseId = 1, Subjects = new[] { "Math", "Physics" } },
        new Student { Id = 2, Name = "Bob", Age = 22, Score = 85, CourseId = 2, Subjects = new[] { "CS", "Math" } },
        new Student { Id = 3, Name = "Charlie", Age = 21, Score = 78, CourseId = 1, Subjects = new[] { "English", "History" } }
    };

    private List<Course> GetCourses() => new List<Course>
    {
        new Course { Id = 1, Name = "Computer Science" },
        new Course { Id = 2, Name = "Engineering" }
    };
}

// ============ METHOD SYNTAX EXAMPLES ============

public class MethodSyntaxExamples
{
    public void SimpleQueries()
    {
        var students = GetStudents();

        // Basic filtering
        var highScorers = students.Where(s => s.Score >= 90);

        // Projection
        var studentNames = students.Select(s => s.Name);

        // Anonymous type projection
        var studentInfo = students
            .Where(s => s.Score >= 80)
            .Select(s => new
            {
                s.Name,
                s.Score,
                Grade = s.Score >= 90 ? "A" : "B"
            });

        // Ordering
        var sortedStudents = students.OrderByDescending(s => s.Score);

        // Chaining operations
        var filteredStudents = students
            .Where(s => s.Score >= 70)
            .Where(s => s.Age >= 18)
            .OrderBy(s => s.Name);
    }

    public void ComplexQueries()
    {
        var students = GetStudents();
        var courses = GetCourses();

        // Join
        var studentCourses = students
            .Join(courses,
                  s => s.CourseId,
                  c => c.Id,
                  (s, c) => new
                  {
                      StudentName = s.Name,
                      CourseName = c.Name
                  });

        // Group by
        var studentsByAge = students
            .GroupBy(s => s.Age)
            .Select(g => new
            {
                Age = g.Key,
                Count = g.Count(),
                Students = g.ToList()
            });

        // SelectMany (flatten)
        var studentSubjects = students
            .SelectMany(s => s.Subjects,
                       (s, subject) => new
                       {
                           s.Name,
                           Subject = subject
                       });

        // Aggregations
        var stats = new
        {
            Count = students.Count(),
            Average = students.Average(s => s.Score),
            Max = students.Max(s => s.Score),
            Min = students.Min(s => s.Score),
            Sum = students.Sum(s => s.Score)
        };
    }

    private List<Student> GetStudents() => new List<Student>
    {
        new Student { Id = 1, Name = "Alice", Age = 20, Score = 95, CourseId = 1, Subjects = new[] { "Math", "Physics" } },
        new Student { Id = 2, Name = "Bob", Age = 22, Score = 85, CourseId = 2, Subjects = new[] { "CS", "Math" } },
        new Student { Id = 3, Name = "Charlie", Age = 21, Score = 78, CourseId = 1, Subjects = new[] { "English", "History" } }
    };

    private List<Course> GetCourses() => new List<Course>
    {
        new Course { Id = 1, Name = "Computer Science" },
        new Course { Id = 2, Name = "Engineering" }
    };
}

// ============ COMPARISON: QUERY VS METHOD SYNTAX ============

public class SyntaxComparison
{
    public void SameFunctionality()
    {
        var numbers = Enumerable.Range(1, 10);

        // Example 1: Filter and project
        // Query syntax
        var query1 = from n in numbers
                     where n > 5
                     select n * 2;

        // Method syntax
        var method1 = numbers
            .Where(n => n > 5)
            .Select(n => n * 2);

        // Example 2: Multiple operations
        // Query syntax
        var query2 = from n in numbers
                     where n % 2 == 0
                     orderby n descending
                     select n;

        // Method syntax
        var method2 = numbers
            .Where(n => n % 2 == 0)
            .OrderByDescending(n => n);
    }

    public void MethodSyntaxOnly()
    {
        var numbers = Enumerable.Range(1, 10);

        // These operations DON'T have query syntax equivalents:

        // Take and Skip
        var firstFive = numbers.Take(5);
        var skipFirstFive = numbers.Skip(5);

        // TakeWhile and SkipWhile
        var takeWhile = numbers.TakeWhile(n => n < 6);
        var skipWhile = numbers.SkipWhile(n => n < 6);

        // Reverse
        var reversed = numbers.Reverse();

        // Distinct
        var distinct = numbers.Distinct();

        // Union, Intersect, Except
        var other = new[] { 5, 6, 7, 8, 9, 10, 11, 12 };
        var union = numbers.Union(other);
        var intersect = numbers.Intersect(other);
        var except = numbers.Except(other);

        // Zip
        var letters = new[] { "A", "B", "C" };
        var zipped = numbers.Zip(letters, (n, l) => $"{n}{l}");

        // Aggregate
        var sum = numbers.Aggregate((acc, n) => acc + n);
    }
}

// ============ MIXED SYNTAX ============

public class MixedSyntax
{
    public void CombiningSyntaxes()
    {
        var students = GetStudents();

        // Query syntax with method syntax operators
        var result1 = (from s in students
                      where s.Score >= 80
                      orderby s.Score descending
                      select s)
                      .Take(5)  // Method syntax
                      .ToList();

        // Method syntax with query expression
        var result2 = students
            .Where(s => s.Age >= 20)
            .Select(s => new
            {
                s.Name,
                HighScorer = (from subject in s.Subjects
                             select subject).Count() > 1
            });
    }

    private List<Student> GetStudents() => new List<Student>
    {
        new Student { Id = 1, Name = "Alice", Age = 20, Score = 95, Subjects = new[] { "Math", "Physics" } },
        new Student { Id = 2, Name = "Bob", Age = 22, Score = 85, Subjects = new[] { "CS", "Math" } }
    };
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Data transformation
public class DataTransformation
{
    public List<OrderDto> GetOrderSummary()
    {
        var orders = GetOrders();
        var customers = GetCustomers();

        // Query syntax
        var summaryQuery = from o in orders
                          join c in customers on o.CustomerId equals c.Id
                          where o.Total > 100
                          orderby o.OrderDate descending
                          select new OrderDto
                          {
                              OrderId = o.Id,
                              CustomerName = c.Name,
                              Total = o.Total,
                              OrderDate = o.OrderDate
                          };

        // Method syntax (same result)
        var summaryMethod = orders
            .Join(customers,
                  o => o.CustomerId,
                  c => c.Id,
                  (o, c) => new { Order = o, Customer = c })
            .Where(x => x.Order.Total > 100)
            .OrderByDescending(x => x.Order.OrderDate)
            .Select(x => new OrderDto
            {
                OrderId = x.Order.Id,
                CustomerName = x.Customer.Name,
                Total = x.Order.Total,
                OrderDate = x.Order.OrderDate
            })
            .ToList();

        return summaryMethod;
    }

    private List<Order> GetOrders() => new List<Order>();
    private List<Customer> GetCustomers() => new List<Customer>();
}

// Example 2: Complex filtering
public class ProductFilter
{
    public List<Product> FilterProducts(ProductSearchCriteria criteria)
    {
        var products = GetProducts();

        // Method syntax - more flexible for dynamic queries
        var query = products.AsQueryable();

        if (!string.IsNullOrEmpty(criteria.Name))
            query = query.Where(p => p.Name.Contains(criteria.Name));

        if (criteria.MinPrice.HasValue)
            query = query.Where(p => p.Price >= criteria.MinPrice.Value);

        if (criteria.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= criteria.MaxPrice.Value);

        if (criteria.Categories?.Any() == true)
            query = query.Where(p => criteria.Categories.Contains(p.Category));

        return query
            .OrderBy(p => p.Name)
            .ToList();
    }

    private IQueryable<Product> GetProducts() => new List<Product>().AsQueryable();
}

// Example 3: Grouping and aggregation
public class SalesReport
{
    public List<SalesSummary> GetMonthlySales()
    {
        var sales = GetSales();

        // Query syntax - readable for grouping
        var monthlySummary = from s in sales
                            group s by new { s.Year, s.Month } into g
                            select new SalesSummary
                            {
                                Year = g.Key.Year,
                                Month = g.Key.Month,
                                TotalSales = g.Sum(x => x.Amount),
                                AverageSale = g.Average(x => x.Amount),
                                OrderCount = g.Count()
                            };

        // Method syntax (same result)
        var monthlySummaryMethod = sales
            .GroupBy(s => new { s.Year, s.Month })
            .Select(g => new SalesSummary
            {
                Year = g.Key.Year,
                Month = g.Key.Month,
                TotalSales = g.Sum(x => x.Amount),
                AverageSale = g.Average(x => x.Amount),
                OrderCount = g.Count()
            })
            .ToList();

        return monthlySummaryMethod;
    }

    private List<Sale> GetSales() => new List<Sale>();
}

// ============ SUPPORTING CLASSES ============

public class Student
{
    public int Id { get; set; }
    public string Name { get; set; }
    public int Age { get; set; }
    public double Score { get; set; }
    public int CourseId { get; set; }
    public string[] Subjects { get; set; }
}

public class Course
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public decimal Total { get; set; }
    public DateTime OrderDate { get; set; }
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
}

public class OrderDto
{
    public int OrderId { get; set; }
    public string CustomerName { get; set; }
    public decimal Total { get; set; }
    public DateTime OrderDate { get; set; }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
}

public class ProductSearchCriteria
{
    public string Name { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public List<string> Categories { get; set; }
}

public class Sale
{
    public int Year { get; set; }
    public int Month { get; set; }
    public decimal Amount { get; set; }
}

public class SalesSummary
{
    public int Year { get; set; }
    public int Month { get; set; }
    public decimal TotalSales { get; set; }
    public decimal AverageSale { get; set; }
    public int OrderCount { get; set; }
}
```

**Comparison Table:**
| Feature | Query Syntax | Method Syntax |
|---------|-------------|---------------|
| Readability | SQL-like, familiar | Lambda-based |
| Complexity | Better for complex joins/groups | Better for chaining |
| Features | Limited operators | All LINQ operators |
| Flexibility | Less flexible | More flexible |
| Dynamic Queries | Difficult | Easy |
| Compilation | Converts to method syntax | Direct |
| When to Use | Complex queries, joins, grouping | Dynamic queries, chaining |

**Query Syntax Keywords:**
- `from` - Specifies data source
- `where` - Filters data
- `select` - Projects results
- `orderby` - Sorts data
- `join` - Joins collections
- `group` - Groups data
- `let` - Introduces intermediate variable
- `into` - Continues query after group/join

**Best Practices:**
- ✅ Use **query syntax** for complex queries with joins/grouping
- ✅ Use **method syntax** for simple operations and chaining
- ✅ Use **method syntax** for dynamic queries
- ✅ Mix both syntaxes when appropriate
- ✅ Prefer **method syntax** in modern C# code
- ❌ Don't mix syntaxes unnecessarily (reduces readability)

---

### Q45: Explain deferred execution in LINQ.

**Deferred Execution:**
- Query is not executed when defined
- Executes when enumerated (foreach, ToList(), etc.)
- Query is re-evaluated each time
- Allows query composition
- Different from immediate execution

**Key Concepts:**
- Query definition ≠ Query execution
- Execution happens on enumeration
- Can lead to multiple executions
- Performance considerations
- Use ToList()/ToArray() to cache results

**Example:**
```csharp
// ============ DEFERRED EXECUTION BASICS ============

public class DeferredExecutionBasics
{
    public void DemonstrateDeferred()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // Query is DEFINED but NOT executed
        var query = numbers.Where(n =>
        {
            Console.WriteLine($"Filtering {n}");
            return n > 2;
        });

        Console.WriteLine("Query defined, nothing printed yet");

        // Query EXECUTES here (first enumeration)
        Console.WriteLine("First enumeration:");
        foreach (var num in query)
        {
            Console.WriteLine($"Result: {num}");
        }

        // Add more numbers
        numbers.Add(6);
        numbers.Add(7);

        // Query EXECUTES again with new data
        Console.WriteLine("\nSecond enumeration (includes new numbers):");
        foreach (var num in query)
        {
            Console.WriteLine($"Result: {num}");
        }
    }

    /* Output:
    Query defined, nothing printed yet
    First enumeration:
    Filtering 1
    Filtering 2
    Filtering 3
    Result: 3
    Filtering 4
    Result: 4
    Filtering 5
    Result: 5

    Second enumeration (includes new numbers):
    Filtering 1
    Filtering 2
    Filtering 3
    Result: 3
    Filtering 4
    Result: 4
    Filtering 5
    Result: 5
    Filtering 6
    Result: 6
    Filtering 7
    Result: 7
    */
}

// ============ DEFERRED VS IMMEDIATE EXECUTION ============

public class DeferredVsImmediate
{
    public void CompareExecution()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // ============ DEFERRED EXECUTION ============
        // Query is stored, not executed
        var deferredQuery = numbers.Where(n => n > 2);

        numbers.Add(6);  // Add after query definition

        // Executes now, includes 6
        var deferredResult = deferredQuery.ToList();
        // Result: [3, 4, 5, 6]

        // ============ IMMEDIATE EXECUTION ============
        numbers = new List<int> { 1, 2, 3, 4, 5 };

        // Query executes immediately, results cached
        var immediateResult = numbers.Where(n => n > 2).ToList();

        numbers.Add(6);  // Add after execution

        // Result doesn't include 6
        // Result: [3, 4, 5]
    }

    public void DemonstrateCaching()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };
        int executionCount = 0;

        // Deferred query
        var deferredQuery = numbers.Where(n =>
        {
            executionCount++;
            return n > 2;
        });

        // Execute 3 times
        var result1 = deferredQuery.ToList();  // executionCount = 3
        var result2 = deferredQuery.ToList();  // executionCount = 6
        var result3 = deferredQuery.ToList();  // executionCount = 9

        Console.WriteLine($"Deferred: Executed {executionCount} times");
        // Output: Deferred: Executed 9 times

        // Immediate execution (cached)
        executionCount = 0;
        var cachedResult = numbers.Where(n =>
        {
            executionCount++;
            return n > 2;
        }).ToList();  // executionCount = 3

        var access1 = cachedResult.ToList();  // executionCount still 3
        var access2 = cachedResult.ToList();  // executionCount still 3

        Console.WriteLine($"Immediate: Executed {executionCount} times");
        // Output: Immediate: Executed 3 times
    }
}

// ============ OPERATORS WITH DEFERRED EXECUTION ============

public class DeferredOperators
{
    public void DeferredOperatorExamples()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // All these have DEFERRED execution:
        var whereQuery = numbers.Where(n => n > 2);
        var selectQuery = numbers.Select(n => n * 2);
        var orderByQuery = numbers.OrderBy(n => n);
        var skipQuery = numbers.Skip(2);
        var takeQuery = numbers.Take(3);
        var distinctQuery = numbers.Distinct();
        var groupByQuery = numbers.GroupBy(n => n % 2);
        var joinQuery = numbers.Join(new[] { 1, 2, 3 },
                                     n => n,
                                     m => m,
                                     (n, m) => n);

        // SelectMany (deferred)
        var selectManyQuery = numbers.SelectMany(n => new[] { n, n * 2 });

        // Cast (deferred)
        var castQuery = numbers.Cast<object>();

        // None of these execute until enumerated!
    }
}

// ============ OPERATORS WITH IMMEDIATE EXECUTION ============

public class ImmediateOperators
{
    public void ImmediateOperatorExamples()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // All these execute IMMEDIATELY:

        // Conversion operators
        var list = numbers.ToList();        // Executes now
        var array = numbers.ToArray();      // Executes now
        var dictionary = numbers.ToDictionary(n => n);  // Executes now
        var lookup = numbers.ToLookup(n => n % 2);      // Executes now

        // Aggregation operators
        var count = numbers.Count();        // Executes now
        var sum = numbers.Sum();           // Executes now
        var average = numbers.Average();   // Executes now
        var min = numbers.Min();           // Executes now
        var max = numbers.Max();           // Executes now

        // Element operators
        var first = numbers.First();              // Executes now
        var firstOrDefault = numbers.FirstOrDefault();  // Executes now
        var single = numbers.Single();            // Executes now
        var last = numbers.Last();                // Executes now
        var elementAt = numbers.ElementAt(2);     // Executes now

        // Boolean operators
        var any = numbers.Any(n => n > 3);   // Executes now
        var all = numbers.All(n => n > 0);   // Executes now
        var contains = numbers.Contains(3);  // Executes now

        // Custom aggregation
        var aggregate = numbers.Aggregate((a, b) => a + b);  // Executes now
    }
}

// ============ QUERY COMPOSITION ============

public class QueryComposition
{
    public void BuildQueryGradually()
    {
        var products = GetProducts();

        // Start with base query (deferred)
        IQueryable<Product> query = products.AsQueryable();

        // Add filters conditionally (still deferred)
        query = query.Where(p => p.Price > 10);

        if (DateTime.Now.DayOfWeek == DayOfWeek.Monday)
        {
            query = query.Where(p => p.Category == "Electronics");
        }

        query = query.OrderBy(p => p.Name);

        // Execute only once at the end
        var results = query.ToList();  // Executes the entire composed query
    }

    public List<Product> DynamicFilter(ProductFilter filter)
    {
        var products = GetProducts();
        var query = products.AsQueryable();

        // Build query dynamically (all deferred)
        if (!string.IsNullOrEmpty(filter.Name))
            query = query.Where(p => p.Name.Contains(filter.Name));

        if (filter.MinPrice.HasValue)
            query = query.Where(p => p.Price >= filter.MinPrice);

        if (filter.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= filter.MaxPrice);

        if (filter.InStock)
            query = query.Where(p => p.Stock > 0);

        // Single execution with all filters
        return query.ToList();
    }

    private IQueryable<Product> GetProducts() => new List<Product>().AsQueryable();
}

// ============ PITFALLS OF DEFERRED EXECUTION ============

public class DeferredExecutionPitfalls
{
    // ❌ PITFALL 1: Multiple enumerations
    public void MultipleEnumerations()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };
        int queryCount = 0;

        var expensiveQuery = numbers.Where(n =>
        {
            queryCount++;
            Thread.Sleep(100);  // Simulate expensive operation
            return n > 2;
        });

        // Each enumeration re-executes the query!
        var count = expensiveQuery.Count();      // Enumeration 1
        var first = expensiveQuery.First();      // Enumeration 2
        var list = expensiveQuery.ToList();      // Enumeration 3

        Console.WriteLine($"Query executed {queryCount} times");
        // Output: Query executed 9 times (3 numbers × 3 enumerations)

        // ✅ SOLUTION: Cache results
        queryCount = 0;
        var cachedResults = numbers.Where(n =>
        {
            queryCount++;
            Thread.Sleep(100);
            return n > 2;
        }).ToList();  // Execute once

        var cachedCount = cachedResults.Count();
        var cachedFirst = cachedResults.First();
        var cachedList = cachedResults.ToList();

        Console.WriteLine($"Cached: Query executed {queryCount} times");
        // Output: Cached: Query executed 3 times (once only)
    }

    // ❌ PITFALL 2: Modified collection
    public void ModifiedCollection()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        var query = numbers.Where(n => n > 2);

        // Modify collection before enumeration
        numbers.Clear();
        numbers.AddRange(new[] { 10, 20, 30 });

        // Query sees modified collection!
        var results = query.ToList();
        // Result: [10, 20, 30] - not [3, 4, 5]!

        // ✅ SOLUTION: Execute immediately
        numbers = new List<int> { 1, 2, 3, 4, 5 };
        var immediateResults = numbers.Where(n => n > 2).ToList();

        numbers.Clear();

        // immediateResults still contains [3, 4, 5]
    }

    // ❌ PITFALL 3: Captured variables in loop
    public void CapturedVariablesInLoop()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };
        var queries = new List<IEnumerable<int>>();

        // ❌ BAD: Variable captured by reference
        for (int i = 0; i < 3; i++)
        {
            queries.Add(numbers.Where(n => n > i));  // 'i' captured!
        }

        // All queries see i = 3 (final value)
        foreach (var query in queries)
        {
            Console.WriteLine(string.Join(", ", query));
        }
        // Output: All print "4, 5" (n > 3)

        // ✅ GOOD: Use local variable
        queries.Clear();
        for (int i = 0; i < 3; i++)
        {
            int threshold = i;  // Local copy
            queries.Add(numbers.Where(n => n > threshold).ToList());
        }

        // Each query has correct threshold
        foreach (var query in queries)
        {
            Console.WriteLine(string.Join(", ", query));
        }
        // Output: "1,2,3,4,5", "2,3,4,5", "3,4,5"
    }

    // ❌ PITFALL 4: Database connections
    public void DatabaseConnectionIssue()
    {
        // ❌ BAD: Connection closed before enumeration
        IEnumerable<User> users;
        using (var context = new DbContext())
        {
            users = context.Users.Where(u => u.IsActive);
            // Query not executed, just defined
        }  // Context disposed here!

        // Enumeration fails - context is disposed!
        // var userList = users.ToList();  // Exception!

        // ✅ GOOD: Execute before disposal
        using (var context = new DbContext())
        {
            var userList = context.Users
                .Where(u => u.IsActive)
                .ToList();  // Execute while context is open
        }

        // ✅ ALTERNATIVE: Return IQueryable and execute in caller
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Pagination with deferred execution
public class PaginationExample
{
    public PagedResult<Product> GetProducts(int page, int pageSize, ProductFilter filter)
    {
        var products = GetAllProducts();

        // Build query (deferred)
        var query = products.AsQueryable();

        if (!string.IsNullOrEmpty(filter.Category))
            query = query.Where(p => p.Category == filter.Category);

        if (filter.MinPrice.HasValue)
            query = query.Where(p => p.Price >= filter.MinPrice);

        // Get total count (executes query once)
        var totalCount = query.Count();

        // Get page data (executes query again)
        var pageData = query
            .OrderBy(p => p.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new PagedResult<Product>
        {
            Items = pageData,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    // ✅ OPTIMIZED: Single query execution
    public PagedResult<Product> GetProductsOptimized(int page, int pageSize, ProductFilter filter)
    {
        var products = GetAllProducts();
        var query = products.AsQueryable();

        if (!string.IsNullOrEmpty(filter.Category))
            query = query.Where(p => p.Category == filter.Category);

        if (filter.MinPrice.HasValue)
            query = query.Where(p => p.Price >= filter.MinPrice);

        // Execute once and cache
        var allResults = query.ToList();

        return new PagedResult<Product>
        {
            Items = allResults
                .OrderBy(p => p.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList(),
            TotalCount = allResults.Count,
            Page = page,
            PageSize = pageSize
        };
    }

    private IQueryable<Product> GetAllProducts() => new List<Product>().AsQueryable();
}

// Example 2: Lazy loading with deferred execution
public class LazyLoadingExample
{
    public void ProcessLargeDataset()
    {
        var largeDataset = GetMillionsOfRecords();

        // Deferred execution allows processing without loading all data
        var processedRecords = largeDataset
            .Where(r => r.IsValid())
            .Select(r => r.Transform())
            .Where(r => r.MeetsBusinessRules());

        // Process in batches
        foreach (var batch in processedRecords.Batch(1000))
        {
            ProcessBatch(batch);
            // Only 1000 records in memory at a time
        }
    }

    private IEnumerable<Record> GetMillionsOfRecords() => Enumerable.Empty<Record>();
    private void ProcessBatch(IEnumerable<Record> batch) { }
}

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
    public int Stock { get; set; }
}

public class ProductFilter
{
    public string Name { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool InStock { get; set; }
    public string Category { get; set; }
}

public class PagedResult<T>
{
    public List<T> Items { get; set; }
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class User
{
    public int Id { get; set; }
    public bool IsActive { get; set; }
}

public class DbContext : IDisposable
{
    public IQueryable<User> Users => new List<User>().AsQueryable();
    public void Dispose() { }
}

public class Record
{
    public bool IsValid() => true;
    public Record Transform() => this;
    public bool MeetsBusinessRules() => true;
}

public static class EnumerableExtensions
{
    public static IEnumerable<IEnumerable<T>> Batch<T>(this IEnumerable<T> source, int size)
    {
        var batch = new List<T>(size);
        foreach (var item in source)
        {
            batch.Add(item);
            if (batch.Count == size)
            {
                yield return batch;
                batch = new List<T>(size);
            }
        }
        if (batch.Count > 0)
            yield return batch;
    }
}
```

**Deferred vs Immediate Execution:**
| Aspect | Deferred Execution | Immediate Execution |
|--------|-------------------|---------------------|
| When Executes | On enumeration | When called |
| Result | IEnumerable<T> | Concrete collection |
| Re-execution | Every enumeration | Never (cached) |
| Memory | Lazy, streaming | All loaded |
| Data Changes | Sees latest data | Sees snapshot |
| Operators | Where, Select, OrderBy | ToList, Count, First |

**Best Practices:**
- ✅ Use **deferred execution** for query composition
- ✅ Use **ToList()/ToArray()** when you need to enumerate multiple times
- ✅ Cache results of expensive queries
- ❌ Don't enumerate queries multiple times unnecessarily
- ❌ Don't modify collections after query definition
- ✅ Be aware of captured variables in loops
- ✅ Execute database queries before disposing context

---

### Q46: What is the difference between IEnumerable and IQueryable in LINQ?

**IEnumerable<T>:**
- In-memory collection interface
- LINQ to Objects
- Client-side execution
- Extension methods in Enumerable class
- Uses Func<T> for predicates

**IQueryable<T>:**
- Query provider interface
- LINQ to SQL/EF/remote data
- Server-side execution
- Extension methods in Queryable class
- Uses Expression<Func<T>> for predicates
- Can be translated to SQL/other query languages

**Example:**
```csharp
// ============ BASIC DIFFERENCE ============

public class IEnumerableVsIQueryable
{
    public void DemonstrateBasicDifference()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

        // IEnumerable - in-memory, client-side filtering
        IEnumerable<int> enumerable = numbers;
        var enumerableResult = enumerable.Where(n => n > 5);
        // Filter executes in C# code

        // IQueryable - can be translated to query language
        IQueryable<int> queryable = numbers.AsQueryable();
        var queryableResult = queryable.Where(n => n > 5);
        // Filter CAN be translated (though this example is in-memory)
    }

    public void ShowDifferentTypes()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // IEnumerable uses Func<T, bool>
        IEnumerable<int> enumerable = numbers;
        Func<int, bool> funcPredicate = n => n > 3;
        var enumerableFiltered = enumerable.Where(funcPredicate);

        // IQueryable uses Expression<Func<T, bool>>
        IQueryable<int> queryable = numbers.AsQueryable();
        Expression<Func<int, bool>> expressionPredicate = n => n > 3;
        var queryableFiltered = queryable.Where(expressionPredicate);
    }
}

// ============ DATABASE EXAMPLE ============

public class DatabaseQueryExamples
{
    private DbContext _context;

    // ❌ BAD: IEnumerable - loads ALL data then filters
    public List<Product> GetExpensiveProductsBad()
    {
        // Returns IEnumerable<Product>
        IEnumerable<Product> products = _context.Products;

        // Filtering happens in C# AFTER loading all products
        var expensive = products
            .Where(p => p.Price > 1000)  // Client-side filter
            .ToList();

        // SQL executed: SELECT * FROM Products
        // Then filtered in memory - INEFFICIENT!

        return expensive;
    }

    // ✅ GOOD: IQueryable - filters on database
    public List<Product> GetExpensiveProductsGood()
    {
        // Returns IQueryable<Product>
        IQueryable<Product> products = _context.Products;

        // Filtering happens in SQL
        var expensive = products
            .Where(p => p.Price > 1000)  // Server-side filter
            .ToList();

        // SQL executed: SELECT * FROM Products WHERE Price > 1000
        // Filtered on database - EFFICIENT!

        return expensive;
    }

    // Comparison with execution details
    public void CompareExecutionLocation()
    {
        // IEnumerable - all data to client
        IEnumerable<Product> enumerable = _context.Products.AsEnumerable();
        var result1 = enumerable
            .Where(p => p.Price > 100)      // C# code
            .Where(p => p.Stock > 0)        // C# code
            .OrderBy(p => p.Name)           // C# code
            .Take(10)                       // C# code
            .ToList();
        // SQL: SELECT * FROM Products
        // Then all filtering/sorting/paging in C#

        // IQueryable - query built and sent to server
        IQueryable<Product> queryable = _context.Products;
        var result2 = queryable
            .Where(p => p.Price > 100)      // SQL WHERE
            .Where(p => p.Stock > 0)        // SQL AND
            .OrderBy(p => p.Name)           // SQL ORDER BY
            .Take(10)                       // SQL TOP/LIMIT
            .ToList();
        // SQL: SELECT TOP 10 * FROM Products
        //      WHERE Price > 100 AND Stock > 0
        //      ORDER BY Name
    }
}

// ============ EXPRESSION TREES ============

public class ExpressionTreeExamples
{
    public void DemonstrateExpressionTrees()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 }.AsQueryable();

        // IQueryable uses Expression<Func<T, bool>>
        Expression<Func<int, bool>> expression = n => n > 3;

        // Expression tree can be analyzed
        Console.WriteLine($"Expression type: {expression.Body.GetType()}");
        // Output: BinaryExpression (greater than)

        var binary = (BinaryExpression)expression.Body;
        Console.WriteLine($"Left: {binary.Left}");   // Parameter 'n'
        Console.WriteLine($"Right: {binary.Right}"); // Constant '3'
        Console.WriteLine($"Operator: {binary.NodeType}"); // GreaterThan

        // This analyzability allows translation to SQL
        var result = numbers.Where(expression).ToList();
    }

    public void TranslationExample()
    {
        var context = new DbContext();

        // IQueryable expression can be translated
        Expression<Func<Product, bool>> expression = p =>
            p.Price > 100 && p.Category == "Electronics";

        var products = context.Products.Where(expression);

        // Query provider translates to SQL:
        // SELECT * FROM Products
        // WHERE Price > 100 AND Category = 'Electronics'
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceComparison
{
    private DbContext _context;

    public void ComparePerformance()
    {
        // Assume database has 1,000,000 products

        // ❌ IEnumerable - loads ALL 1M records
        var sw1 = Stopwatch.StartNew();
        IEnumerable<Product> enumerable = _context.Products.AsEnumerable();
        var result1 = enumerable
            .Where(p => p.Price > 100)
            .Take(10)
            .ToList();
        sw1.Stop();
        Console.WriteLine($"IEnumerable: {sw1.ElapsedMilliseconds}ms");
        // Loads 1,000,000 records, filters in memory - VERY SLOW!

        // ✅ IQueryable - loads only 10 records
        var sw2 = Stopwatch.StartNew();
        IQueryable<Product> queryable = _context.Products;
        var result2 = queryable
            .Where(p => p.Price > 100)
            .Take(10)
            .ToList();
        sw2.Stop();
        Console.WriteLine($"IQueryable: {sw2.ElapsedMilliseconds}ms");
        // SQL with TOP 10 - loads only needed records - FAST!
    }

    public void MemoryComparison()
    {
        // IEnumerable - high memory usage
        var before1 = GC.GetTotalMemory(false);
        IEnumerable<Product> enumerable = _context.Products.AsEnumerable();
        var list1 = enumerable.Where(p => p.Price > 100).ToList();
        var after1 = GC.GetTotalMemory(false);
        Console.WriteLine($"IEnumerable memory: {(after1 - before1) / 1024 / 1024}MB");

        // IQueryable - low memory usage
        var before2 = GC.GetTotalMemory(false);
        IQueryable<Product> queryable = _context.Products;
        var list2 = queryable.Where(p => p.Price > 100).ToList();
        var after2 = GC.GetTotalMemory(false);
        Console.WriteLine($"IQueryable memory: {(after2 - before2) / 1024 / 1024}MB");
    }
}

// ============ WHEN TO USE EACH ============

public class UsageGuidelines
{
    private DbContext _context;

    // ✅ Use IEnumerable for in-memory collections
    public List<int> ProcessInMemoryData()
    {
        var numbers = new List<int> { 1, 2, 3, 4, 5 };

        // IEnumerable is perfect here
        IEnumerable<int> query = numbers
            .Where(n => n > 2)
            .Select(n => n * 2);

        return query.ToList();
    }

    // ✅ Use IQueryable for database queries
    public List<Product> QueryDatabase()
    {
        // IQueryable for database
        IQueryable<Product> query = _context.Products
            .Where(p => p.Price > 100)
            .OrderBy(p => p.Name);

        return query.ToList();
    }

    // ⚠️ Mixing: IQueryable then IEnumerable
    public List<Product> MixedQuery()
    {
        // Start with IQueryable (database)
        IQueryable<Product> queryable = _context.Products
            .Where(p => p.Price > 100);  // SQL WHERE

        // Convert to IEnumerable (loads data)
        IEnumerable<Product> enumerable = queryable.ToList();

        // Further filtering in memory
        var result = enumerable
            .Where(p => p.Name.Contains("Special"))  // C# filter
            .ToList();

        return result;
    }

    // ✅ Better: Keep as IQueryable
    public List<Product> BetterQuery()
    {
        var result = _context.Products
            .Where(p => p.Price > 100)           // SQL
            .Where(p => p.Name.Contains("Special"))  // SQL LIKE
            .ToList();

        return result;
    }
}

// ============ QUERY COMPOSITION ============

public class QueryCompositionExamples
{
    private DbContext _context;

    // IQueryable allows building queries
    public IQueryable<Product> BuildQuery(ProductFilter filter)
    {
        IQueryable<Product> query = _context.Products;

        // Each Where adds to the query (not executed yet)
        if (!string.IsNullOrEmpty(filter.Category))
            query = query.Where(p => p.Category == filter.Category);

        if (filter.MinPrice.HasValue)
            query = query.Where(p => p.Price >= filter.MinPrice);

        if (filter.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= filter.MaxPrice);

        // Return IQueryable - caller can add more filters
        return query;
    }

    public List<Product> UseComposedQuery()
    {
        var filter = new ProductFilter { Category = "Electronics", MinPrice = 100 };

        var query = BuildQuery(filter);

        // Add more conditions
        query = query.Where(p => p.Stock > 0);
        query = query.OrderBy(p => p.Name);

        // Execute once with all conditions
        return query.ToList();
        // SQL: SELECT * FROM Products
        //      WHERE Category = 'Electronics'
        //      AND Price >= 100
        //      AND Stock > 0
        //      ORDER BY Name
    }
}

// ============ LIMITATIONS ============

public class Limitations
{
    private DbContext _context;

    // ❌ Some operations can't be translated to SQL
    public void UntranslatableOperations()
    {
        // IQueryable - this FAILS
        try
        {
            var products = _context.Products
                .Where(p => CustomMethod(p.Price))  // Can't translate to SQL!
                .ToList();
        }
        catch (NotSupportedException ex)
        {
            Console.WriteLine("Cannot translate CustomMethod to SQL");
        }

        // ✅ Solution: Use AsEnumerable to switch to client-side
        var products = _context.Products
            .Where(p => p.Price > 100)        // SQL filter first
            .AsEnumerable()                   // Switch to IEnumerable
            .Where(p => CustomMethod(p.Price))  // C# filter
            .ToList();
    }

    // ❌ Complex C# logic doesn't translate
    public void ComplexLogic()
    {
        // Won't translate to SQL
        var products = _context.Products
            .AsEnumerable()  // Load to memory first
            .Where(p =>
            {
                // Complex C# logic
                if (p.Price > 1000)
                {
                    return p.Stock > 10;
                }
                else if (p.Price > 500)
                {
                    return p.Stock > 5;
                }
                return p.Stock > 0;
            })
            .ToList();
    }

    private bool CustomMethod(decimal price)
    {
        // Custom logic that can't be translated to SQL
        return price % 10 == 0;
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Repository pattern
public class ProductRepository
{
    private readonly DbContext _context;

    // Return IQueryable for flexibility
    public IQueryable<Product> GetAll()
    {
        return _context.Products;
    }

    public IQueryable<Product> GetActive()
    {
        return _context.Products.Where(p => p.IsActive);
    }

    // Caller can compose queries
    public void Usage()
    {
        var repo = new ProductRepository();

        // Build complex query
        var products = repo.GetActive()
            .Where(p => p.Price > 100)
            .OrderBy(p => p.Name)
            .Take(10)
            .ToList();
        // Single SQL query with all conditions
    }
}

// Example 2: Specification pattern with IQueryable
public interface ISpecification<T>
{
    Expression<Func<T, bool>> Criteria { get; }
}

public class ExpensiveProductSpec : ISpecification<Product>
{
    public Expression<Func<Product, bool>> Criteria => p => p.Price > 1000;
}

public class SpecificationEvaluator
{
    public IQueryable<T> GetQuery<T>(
        IQueryable<T> inputQuery,
        ISpecification<T> specification)
    {
        return inputQuery.Where(specification.Criteria);
    }
}

// Example 3: Dynamic sorting
public class DynamicQueryBuilder
{
    public IQueryable<Product> ApplySort(
        IQueryable<Product> query,
        string sortBy,
        bool ascending)
    {
        // IQueryable allows dynamic query building
        return sortBy switch
        {
            "name" => ascending ? query.OrderBy(p => p.Name) : query.OrderByDescending(p => p.Name),
            "price" => ascending ? query.OrderBy(p => p.Price) : query.OrderByDescending(p => p.Price),
            "stock" => ascending ? query.OrderBy(p => p.Stock) : query.OrderByDescending(p => p.Stock),
            _ => query.OrderBy(p => p.Id)
        };
    }
}

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
    public int Stock { get; set; }
    public bool IsActive { get; set; }
}

public class ProductFilter
{
    public string Category { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
}

public class DbContext : IDisposable
{
    public IQueryable<Product> Products => new List<Product>().AsQueryable();
    public void Dispose() { }
}
```

**Comparison Table:**
| Feature | IEnumerable<T> | IQueryable<T> |
|---------|---------------|---------------|
| Purpose | In-memory collections | Queryable data sources |
| Execution | Client-side (C#) | Server-side (DB) |
| Base Interface | IEnumerable | IEnumerable |
| Namespace | System.Collections | System.Linq |
| Extension Class | Enumerable | Queryable |
| Predicate Type | Func<T, bool> | Expression<Func<T, bool>> |
| Translation | No | Yes (to SQL, etc.) |
| Performance | Good for small data | Good for large data |
| Memory | Loads all data | Loads filtered data |
| Use Case | LINQ to Objects | LINQ to SQL/EF |

**Key Differences:**
1. **Execution Location**: IEnumerable = client, IQueryable = server
2. **Expression Trees**: IQueryable uses expressions for translation
3. **Performance**: IQueryable better for databases (filters on server)
4. **Flexibility**: IQueryable allows query composition

**Best Practices:**
- ✅ Use **IQueryable** for database queries
- ✅ Use **IEnumerable** for in-memory collections
- ✅ Return **IQueryable** from repositories for flexibility
- ❌ Don't use **AsEnumerable()** too early (loses server-side benefits)
- ✅ Filter with **IQueryable** first, then **AsEnumerable()** if needed
- ✅ Understand when queries execute

---

### Q47: Explain the Any(), All(), First(), FirstOrDefault(), Single(), and SingleOrDefault() methods.

**LINQ Element/Quantifier Operators:**
- Element operators: First, FirstOrDefault, Single, SingleOrDefault, Last, ElementAt
- Quantifier operators: Any, All, Contains
- Immediate execution (not deferred)
- Return single value or boolean
- Throw exceptions on failure (except *OrDefault)

**Example:**
```csharp
// ============ ANY() - Checks if any element matches ============

public class AnyExamples
{
    public void BasicAny()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 };

        // Any() without predicate - checks if collection has elements
        bool hasElements = numbers.Any();
        Console.WriteLine(hasElements);  // True

        var empty = new int[0];
        bool hasNoElements = empty.Any();
        Console.WriteLine(hasNoElements);  // False

        // Any() with predicate - checks if any element matches
        bool hasEven = numbers.Any(n => n % 2 == 0);
        Console.WriteLine(hasEven);  // True (2, 4)

        bool hasNegative = numbers.Any(n => n < 0);
        Console.WriteLine(hasNegative);  // False
    }

    public void RealWorldAny()
    {
        var users = GetUsers();

        // Check if any active users
        if (users.Any(u => u.IsActive))
        {
            Console.WriteLine("Active users found");
        }

        // Check if user with email exists
        bool emailExists = users.Any(u => u.Email == "test@example.com");

        // Efficient database query (stops at first match)
        using var context = new DbContext();
        bool hasExpensiveProducts = context.Products
            .Any(p => p.Price > 1000);
        // SQL: SELECT CASE WHEN EXISTS(...) THEN 1 ELSE 0
    }

    private List<User> GetUsers() => new List<User>();
}

// ============ ALL() - Checks if all elements match ============

public class AllExamples
{
    public void BasicAll()
    {
        var numbers = new[] { 2, 4, 6, 8, 10 };

        // All() - checks if all elements match predicate
        bool allEven = numbers.All(n => n % 2 == 0);
        Console.WriteLine(allEven);  // True

        bool allGreaterThanZero = numbers.All(n => n > 0);
        Console.WriteLine(allGreaterThanZero);  // True

        bool allGreaterThanFive = numbers.All(n => n > 5);
        Console.WriteLine(allGreaterThanFive);  // False (2, 4)

        // Empty collection - All() returns TRUE
        var empty = new int[0];
        bool allEmptyEven = empty.All(n => n % 2 == 0);
        Console.WriteLine(allEmptyEven);  // True (vacuous truth)
    }

    public void RealWorldAll()
    {
        var users = GetUsers();

        // Check if all users are active
        bool allActive = users.All(u => u.IsActive);

        // Validation: all emails are valid
        bool allEmailsValid = users.All(u =>
            !string.IsNullOrEmpty(u.Email) && u.Email.Contains("@"));

        // Business rule: all orders are paid
        var orders = GetOrders();
        bool allPaid = orders.All(o => o.IsPaid);

        if (!allPaid)
        {
            throw new InvalidOperationException("Not all orders are paid");
        }
    }

    private List<User> GetUsers() => new List<User>();
    private List<Order> GetOrders() => new List<Order>();
}

// ============ FIRST() vs FIRSTORDEFAULT() ============

public class FirstExamples
{
    public void BasicFirst()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 };

        // First() - returns first element
        int first = numbers.First();
        Console.WriteLine(first);  // 1

        // First() with predicate - returns first matching element
        int firstEven = numbers.First(n => n % 2 == 0);
        Console.WriteLine(firstEven);  // 2

        // ❌ First() throws on empty collection
        var empty = new int[0];
        try
        {
            int fail = empty.First();  // InvalidOperationException!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("First() failed: " + ex.Message);
        }

        // ❌ First() throws when no match
        try
        {
            int noMatch = numbers.First(n => n > 10);  // Exception!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("No matching element: " + ex.Message);
        }
    }

    public void BasicFirstOrDefault()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 };

        // FirstOrDefault() - safe version
        int first = numbers.FirstOrDefault();
        Console.WriteLine(first);  // 1

        // ✅ FirstOrDefault() returns default on empty
        var empty = new int[0];
        int defaultValue = empty.FirstOrDefault();
        Console.WriteLine(defaultValue);  // 0 (default for int)

        // ✅ FirstOrDefault() returns default when no match
        int noMatch = numbers.FirstOrDefault(n => n > 10);
        Console.WriteLine(noMatch);  // 0

        // Reference types return null
        var users = new List<User>();
        User defaultUser = users.FirstOrDefault();
        Console.WriteLine(defaultUser == null);  // True
    }

    public void RealWorldFirst()
    {
        var users = GetUsers();

        // Use First() when you EXPECT result to exist
        var admin = users.First(u => u.Role == "Admin");
        // Throws if no admin - indicates data problem

        // Use FirstOrDefault() when result might not exist
        var user = users.FirstOrDefault(u => u.Email == "test@example.com");
        if (user != null)
        {
            Console.WriteLine($"Found: {user.Name}");
        }

        // Nullable reference types (C# 8+)
        User? nullableUser = users.FirstOrDefault(u => u.Id == 999);

        // Database query - returns first match efficiently
        using var context = new DbContext();
        var product = context.Products
            .Where(p => p.Price > 100)
            .OrderBy(p => p.Price)
            .FirstOrDefault();
        // SQL: SELECT TOP 1 * FROM Products WHERE Price > 100 ORDER BY Price
    }

    private List<User> GetUsers() => new List<User>
    {
        new User { Id = 1, Name = "Alice", Role = "Admin", Email = "alice@example.com" },
        new User { Id = 2, Name = "Bob", Role = "User", Email = "bob@example.com" }
    };
}

// ============ SINGLE() vs SINGLEORDEFAULT() ============

public class SingleExamples
{
    public void BasicSingle()
    {
        var numbers = new[] { 5 };

        // Single() - expects exactly ONE element
        int single = numbers.Single();
        Console.WriteLine(single);  // 5

        // ❌ Single() throws on empty
        var empty = new int[0];
        try
        {
            int fail = empty.Single();  // InvalidOperationException!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("Single() on empty: " + ex.Message);
        }

        // ❌ Single() throws on multiple elements
        var multiple = new[] { 1, 2, 3 };
        try
        {
            int fail = multiple.Single();  // InvalidOperationException!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("Single() on multiple: " + ex.Message);
        }

        // Single() with predicate
        var numbers2 = new[] { 1, 2, 3, 4, 5 };
        int singleEven = numbers2.Single(n => n == 4);
        Console.WriteLine(singleEven);  // 4

        // ❌ Throws if multiple matches
        try
        {
            int multipleMatch = numbers2.Single(n => n % 2 == 0);  // 2 and 4!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("Multiple matches: " + ex.Message);
        }
    }

    public void BasicSingleOrDefault()
    {
        var numbers = new[] { 5 };

        // SingleOrDefault() - expects zero or one element
        int single = numbers.SingleOrDefault();
        Console.WriteLine(single);  // 5

        // ✅ SingleOrDefault() returns default on empty
        var empty = new int[0];
        int defaultValue = empty.SingleOrDefault();
        Console.WriteLine(defaultValue);  // 0

        // ❌ Still throws on multiple elements!
        var multiple = new[] { 1, 2, 3 };
        try
        {
            int fail = multiple.SingleOrDefault();  // Exception!
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine("SingleOrDefault() on multiple: " + ex.Message);
        }
    }

    public void RealWorldSingle()
    {
        var users = GetUsers();

        // Use Single() when you expect EXACTLY ONE result
        var userById = users.Single(u => u.Id == 1);
        // Throws if:
        // - No user with Id 1 (data problem)
        // - Multiple users with Id 1 (data corruption!)

        // Use SingleOrDefault() when you expect zero or one
        var userByEmail = users.SingleOrDefault(u =>
            u.Email == "unique@example.com");
        if (userByEmail != null)
        {
            Console.WriteLine($"Found: {userByEmail.Name}");
        }

        // Common use: Primary key lookups
        using var context = new DbContext();
        var product = context.Products.Single(p => p.Id == 123);
        // Ensures data integrity (Id should be unique)
    }

    private List<User> GetUsers() => new List<User>
    {
        new User { Id = 1, Name = "Alice", Email = "alice@example.com" },
        new User { Id = 2, Name = "Bob", Email = "bob@example.com" }
    };
}

// ============ COMPARISON: FIRST VS SINGLE ============

public class FirstVsSingle
{
    public void CompareFirstAndSingle()
    {
        var numbers = new[] { 1, 2, 3, 4, 5 };

        // First() - returns first, doesn't care about others
        int firstEven = numbers.First(n => n % 2 == 0);
        Console.WriteLine(firstEven);  // 2 (ignores 4)

        // Single() - expects exactly one match
        try
        {
            int singleEven = numbers.Single(n => n % 2 == 0);  // Exception!
        }
        catch (InvalidOperationException)
        {
            Console.WriteLine("Single() found multiple matches");
        }

        // First() is more lenient
        int firstGreaterThanZero = numbers.First(n => n > 0);  // 1 (OK)

        // Single() is more strict
        try
        {
            int singleGreaterThanZero = numbers.Single(n => n > 0);  // Exception!
        }
        catch (InvalidOperationException)
        {
            Console.WriteLine("Single() requires exactly one");
        }
    }

    public void WhenToUseWhich()
    {
        var users = GetUsers();

        // ✅ Use First() when:
        // - You want the first match
        // - Multiple matches are OK
        // - You're sorting and want the first sorted result
        var oldestUser = users.OrderBy(u => u.Age).First();

        // ✅ Use Single() when:
        // - You expect exactly one match
        // - Multiple matches indicate a bug
        // - Looking up by unique identifier
        var userById = users.Single(u => u.Id == 1);

        // ✅ Use FirstOrDefault() when:
        // - Result might not exist
        // - Multiple matches are OK
        var activeUser = users.FirstOrDefault(u => u.IsActive);

        // ✅ Use SingleOrDefault() when:
        // - Result might not exist (zero is OK)
        // - But multiple matches are NOT OK
        var uniqueEmail = users.SingleOrDefault(u =>
            u.Email == "unique@example.com");
    }

    private List<User> GetUsers() => new List<User>();
}

// ============ PERFORMANCE CONSIDERATIONS ============

public class PerformanceConsiderations
{
    public void DatabasePerformance()
    {
        using var context = new DbContext();

        // Any() - most efficient (stops at first match)
        bool hasProducts = context.Products.Any();
        // SQL: SELECT CASE WHEN EXISTS(SELECT 1...) ...

        // First() - efficient (limits to 1 result)
        var firstProduct = context.Products.First();
        // SQL: SELECT TOP 1 * FROM Products

        // Single() - less efficient (must check for duplicates)
        var singleProduct = context.Products.Single(p => p.Id == 1);
        // SQL: SELECT TOP 2 * FROM Products WHERE Id = 1
        // (Fetches 2 to verify only 1 exists)

        // Count() > 0 vs Any() - Any() is more efficient
        bool badCheck = context.Products.Count() > 0;  // ❌ Counts all
        bool goodCheck = context.Products.Any();        // ✅ Stops at first
    }

    public void MemoryPerformance()
    {
        var largeList = Enumerable.Range(1, 1000000).ToList();

        // Any() - fast, stops at first match
        var sw1 = Stopwatch.StartNew();
        bool anyEven = largeList.Any(n => n % 2 == 0);
        sw1.Stop();
        Console.WriteLine($"Any(): {sw1.ElapsedMilliseconds}ms");  // ~0ms

        // First() - fast, stops at first match
        var sw2 = Stopwatch.StartNew();
        int firstEven = largeList.First(n => n % 2 == 0);
        sw2.Stop();
        Console.WriteLine($"First(): {sw2.ElapsedMilliseconds}ms");  // ~0ms

        // Single() - slower, must check entire collection
        var singleItem = new[] { 1 };
        var sw3 = Stopwatch.StartNew();
        int single = singleItem.Single();
        sw3.Stop();
        Console.WriteLine($"Single(): {sw3.ElapsedMilliseconds}ms");
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Validation
public class ValidationExamples
{
    public void ValidateOrder(Order order)
    {
        // Any() for existence checks
        if (!order.Items.Any())
        {
            throw new InvalidOperationException("Order must have items");
        }

        // All() for validation rules
        if (!order.Items.All(i => i.Quantity > 0))
        {
            throw new InvalidOperationException("All items must have positive quantity");
        }

        if (!order.Items.All(i => i.Price >= 0))
        {
            throw new InvalidOperationException("All items must have non-negative price");
        }

        // Single() for unique constraints
        var primaryContact = order.Contacts.Single(c => c.IsPrimary);
        // Ensures exactly one primary contact
    }
}

// Example 2: User management
public class UserManagement
{
    private readonly DbContext _context;

    public User GetUserById(int id)
    {
        // Single() - expects unique Id
        return _context.Users.Single(u => u.Id == id);
        // Throws if not found or duplicates found
    }

    public User? FindUserByEmail(string email)
    {
        // SingleOrDefault() - email should be unique
        return _context.Users.SingleOrDefault(u => u.Email == email);
        // Returns null if not found, throws if duplicates
    }

    public User GetAnyAdminUser()
    {
        // First() - get any admin
        return _context.Users.First(u => u.Role == "Admin");
        // Throws if no admin exists
    }

    public bool HasActiveUsers()
    {
        // Any() - efficient check
        return _context.Users.Any(u => u.IsActive);
    }

    public bool AllUsersVerified()
    {
        // All() - check all users
        return _context.Users.All(u => u.IsVerified);
    }
}

// Example 3: Business logic
public class BusinessLogic
{
    public bool CanProcessOrder(Order order, List<Product> inventory)
    {
        // All() for business rules
        return order.Items.All(item =>
        {
            var product = inventory.SingleOrDefault(p => p.Id == item.ProductId);
            return product != null && product.Stock >= item.Quantity;
        });
    }

    public decimal CalculateDiscount(Order order)
    {
        // Any() for conditional logic
        if (order.Items.Any(i => i.ProductId == 999))
        {
            return 0.10m;  // 10% discount for special product
        }

        if (order.Items.All(i => i.Category == "Electronics"))
        {
            return 0.05m;  // 5% discount for all electronics
        }

        return 0m;
    }
}

// ============ SUPPORTING CLASSES ============

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public string Role { get; set; }
    public bool IsActive { get; set; }
    public bool IsVerified { get; set; }
    public int Age { get; set; }
}

public class Order
{
    public int Id { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    public List<Contact> Contacts { get; set; } = new();
    public bool IsPaid { get; set; }
}

public class OrderItem
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; }
}

public class Contact
{
    public bool IsPrimary { get; set; }
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
}

public class DbContext : IDisposable
{
    public IQueryable<User> Users => new List<User>().AsQueryable();
    public IQueryable<Product> Products => new List<Product>().AsQueryable();
    public void Dispose() { }
}
```

**Method Comparison Table:**
| Method | Returns | Empty Collection | No Match | Multiple Matches |
|--------|---------|-----------------|----------|-----------------|
| Any() | bool | false | false | true |
| All() | bool | **true** | false | depends |
| First() | T | Exception | Exception | First element |
| FirstOrDefault() | T? | default(T) | default(T) | First element |
| Single() | T | Exception | Exception | Exception |
| SingleOrDefault() | T? | default(T) | default(T) | Exception |

**When to Use:**
- **Any()**: Check if collection has elements matching condition
- **All()**: Validate all elements meet criteria
- **First()**: Get first element, expect it to exist
- **FirstOrDefault()**: Get first element, might not exist
- **Single()**: Get exactly one element, enforce uniqueness
- **SingleOrDefault()**: Get zero or one element, enforce uniqueness

**Best Practices:**
- ✅ Use **Any()** instead of **Count() > 0** (more efficient)
- ✅ Use **First()** when sorting to get top result
- ✅ Use **Single()** for unique identifiers (enforces data integrity)
- ✅ Use **OrDefault** versions when result might not exist
- ❌ Don't use **Single()** when multiple matches are expected
- ✅ Prefer **Any()** for existence checks in databases

---

### Q48: What are attributes in C#? Create a custom attribute.

**Attributes:**
- Declarative tags for metadata
- Add information to code elements
- Examined at runtime via reflection
- Square bracket syntax [AttributeName]
- Can have parameters (positional and named)
- Used for serialization, validation, documentation, etc.

**Built-in Attributes:**
- [Obsolete], [Serializable], [DllImport]
- [ConditionalAttribute], [CallerMemberName]
- [Required], [Range], [MaxLength] (validation)
- [JsonProperty], [XmlElement] (serialization)

**Example:**
```csharp
// ============ USING BUILT-IN ATTRIBUTES ============

public class BuiltInAttributeExamples
{
    // Obsolete attribute - marks code as deprecated
    [Obsolete("Use NewMethod instead")]
    public void OldMethod()
    {
        Console.WriteLine("This is old");
    }

    [Obsolete("This method will be removed in v2.0", true)]  // Error on use
    public void VeryOldMethod()
    {
        Console.WriteLine("Very old");
    }

    // Conditional attribute - compiles only in DEBUG
    [Conditional("DEBUG")]
    public void DebugLog(string message)
    {
        Console.WriteLine($"DEBUG: {message}");
    }

    // Caller information attributes
    public void LogMessage(
        string message,
        [CallerMemberName] string memberName = "",
        [CallerFilePath] string filePath = "",
        [CallerLineNumber] int lineNumber = 0)
    {
        Console.WriteLine($"{memberName} in {filePath}:{lineNumber} - {message}");
    }

    // Data validation attributes
    public class User
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; }

        [Range(18, 100)]
        public int Age { get; set; }

        [EmailAddress]
        public string Email { get; set; }
    }

    // Serialization attributes
    [Serializable]
    public class SerializableData
    {
        public string Name { get; set; }

        [NonSerialized]
        public string TemporaryData = "";
    }

    // JSON serialization
    public class JsonData
    {
        [JsonPropertyName("full_name")]
        public string Name { get; set; }

        [JsonIgnore]
        public string InternalId { get; set; }
    }
}

// ============ CREATING CUSTOM ATTRIBUTES ============

// Custom attribute class (must inherit from Attribute)
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method,
                AllowMultiple = false,
                Inherited = true)]
public class AuthorAttribute : Attribute
{
    public string Name { get; }
    public string Date { get; set; }  // Optional named parameter
    public string Version { get; set; }

    // Constructor for required parameters
    public AuthorAttribute(string name)
    {
        Name = name;
        Date = DateTime.Now.ToString("yyyy-MM-dd");
    }
}

// Using the custom attribute
[Author("John Doe", Date = "2024-01-15", Version = "1.0")]
public class MyClass
{
    [Author("Jane Smith", Version = "1.1")]
    public void MyMethod()
    {
        Console.WriteLine("Method execution");
    }
}

// ============ COMPLEX CUSTOM ATTRIBUTES ============

// Validation attribute
[AttributeUsage(AttributeTargets.Property)]
public class ValidateRangeAttribute : Attribute
{
    public int Min { get; }
    public int Max { get; }
    public string ErrorMessage { get; set; }

    public ValidateRangeAttribute(int min, int max)
    {
        Min = min;
        Max = max;
        ErrorMessage = $"Value must be between {min} and {max}";
    }

    public bool IsValid(object value)
    {
        if (value is int intValue)
        {
            return intValue >= Min && intValue <= Max;
        }
        return false;
    }
}

// API documentation attribute
[AttributeUsage(AttributeTargets.Method, AllowMultiple = false)]
public class ApiEndpointAttribute : Attribute
{
    public string Route { get; }
    public string HttpMethod { get; set; }
    public string Description { get; set; }
    public bool RequiresAuth { get; set; }

    public ApiEndpointAttribute(string route)
    {
        Route = route;
        HttpMethod = "GET";
        RequiresAuth = false;
    }
}

// Table mapping attribute
[AttributeUsage(AttributeTargets.Class)]
public class TableAttribute : Attribute
{
    public string Name { get; }
    public string Schema { get; set; }

    public TableAttribute(string name)
    {
        Name = name;
        Schema = "dbo";
    }
}

[AttributeUsage(AttributeTargets.Property)]
public class ColumnAttribute : Attribute
{
    public string Name { get; }
    public string DataType { get; set; }
    public bool IsPrimaryKey { get; set; }
    public bool IsNullable { get; set; }

    public ColumnAttribute(string name)
    {
        Name = name;
        IsNullable = true;
    }
}

// ============ USING CUSTOM ATTRIBUTES ============

// Using validation attribute
public class Product
{
    [ValidateRange(0, 10000, ErrorMessage = "Price must be between 0 and 10000")]
    public int Price { get; set; }

    [ValidateRange(0, 1000)]
    public int Stock { get; set; }
}

// Using API documentation attribute
public class UserController
{
    [ApiEndpoint("/api/users", HttpMethod = "GET", Description = "Get all users")]
    public List<User> GetUsers()
    {
        return new List<User>();
    }

    [ApiEndpoint("/api/users/{id}", HttpMethod = "GET",
                 Description = "Get user by ID", RequiresAuth = true)]
    public User GetUserById(int id)
    {
        return new User();
    }

    [ApiEndpoint("/api/users", HttpMethod = "POST",
                 Description = "Create new user", RequiresAuth = true)]
    public User CreateUser(User user)
    {
        return user;
    }
}

// Using table mapping attributes
[Table("Users", Schema = "auth")]
public class User
{
    [Column("user_id", DataType = "int", IsPrimaryKey = true, IsNullable = false)]
    public int Id { get; set; }

    [Column("user_name", DataType = "nvarchar(100)", IsNullable = false)]
    public string Name { get; set; }

    [Column("email", DataType = "nvarchar(255)")]
    public string Email { get; set; }
}

// ============ READING ATTRIBUTES WITH REFLECTION ============

public class AttributeReader
{
    // Read class-level attributes
    public void ReadClassAttributes()
    {
        Type type = typeof(MyClass);

        // Get AuthorAttribute
        var authorAttr = type.GetCustomAttribute<AuthorAttribute>();
        if (authorAttr != null)
        {
            Console.WriteLine($"Author: {authorAttr.Name}");
            Console.WriteLine($"Date: {authorAttr.Date}");
            Console.WriteLine($"Version: {authorAttr.Version}");
        }

        // Get all attributes
        var allAttrs = type.GetCustomAttributes();
        foreach (var attr in allAttrs)
        {
            Console.WriteLine($"Attribute: {attr.GetType().Name}");
        }
    }

    // Read method-level attributes
    public void ReadMethodAttributes()
    {
        Type type = typeof(UserController);
        var methods = type.GetMethods();

        foreach (var method in methods)
        {
            var apiAttr = method.GetCustomAttribute<ApiEndpointAttribute>();
            if (apiAttr != null)
            {
                Console.WriteLine($"Method: {method.Name}");
                Console.WriteLine($"  Route: {apiAttr.Route}");
                Console.WriteLine($"  HTTP Method: {apiAttr.HttpMethod}");
                Console.WriteLine($"  Description: {apiAttr.Description}");
                Console.WriteLine($"  Requires Auth: {apiAttr.RequiresAuth}");
            }
        }
    }

    // Read property-level attributes
    public void ReadPropertyAttributes()
    {
        Type type = typeof(Product);
        var properties = type.GetProperties();

        foreach (var property in properties)
        {
            var rangeAttr = property.GetCustomAttribute<ValidateRangeAttribute>();
            if (rangeAttr != null)
            {
                Console.WriteLine($"Property: {property.Name}");
                Console.WriteLine($"  Range: {rangeAttr.Min} - {rangeAttr.Max}");
                Console.WriteLine($"  Error: {rangeAttr.ErrorMessage}");
            }
        }
    }

    // Validate object using attributes
    public List<string> ValidateObject(object obj)
    {
        var errors = new List<string>();
        Type type = obj.GetType();

        foreach (var property in type.GetProperties())
        {
            var rangeAttr = property.GetCustomAttribute<ValidateRangeAttribute>();
            if (rangeAttr != null)
            {
                var value = property.GetValue(obj);
                if (!rangeAttr.IsValid(value))
                {
                    errors.Add($"{property.Name}: {rangeAttr.ErrorMessage}");
                }
            }
        }

        return errors;
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Dependency injection attribute
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public class InjectAttribute : Attribute
{
    public string ServiceName { get; set; }
}

public class ServiceWithDependencies
{
    [Inject]
    public ILogger Logger { get; set; }

    [Inject(ServiceName = "EmailService")]
    public IEmailService EmailService { get; set; }
}

// Example 2: Caching attribute
[AttributeUsage(AttributeTargets.Method)]
public class CacheAttribute : Attribute
{
    public int DurationSeconds { get; set; }
    public string CacheKey { get; set; }

    public CacheAttribute(int durationSeconds = 60)
    {
        DurationSeconds = durationSeconds;
    }
}

public class DataService
{
    [Cache(DurationSeconds = 300, CacheKey = "AllUsers")]
    public List<User> GetAllUsers()
    {
        // Expensive database call
        return new List<User>();
    }

    [Cache(DurationSeconds = 600)]
    public User GetUserById(int id)
    {
        return new User();
    }
}

// Example 3: Permission attribute
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePermissionAttribute : Attribute
{
    public string Permission { get; }
    public string Role { get; set; }

    public RequirePermissionAttribute(string permission)
    {
        Permission = permission;
    }

    public bool HasPermission(User user)
    {
        // Check user permissions
        return user.Permissions?.Contains(Permission) ?? false;
    }
}

[RequirePermission("ViewUsers", Role = "Admin")]
public class AdminController
{
    [RequirePermission("CreateUser")]
    public void CreateUser(User user)
    {
        // Create user
    }

    [RequirePermission("DeleteUser")]
    public void DeleteUser(int id)
    {
        // Delete user
    }
}

// Example 4: Test attribute (like NUnit/xUnit)
[AttributeUsage(AttributeTargets.Method)]
public class TestAttribute : Attribute
{
    public string Description { get; set; }
    public string Category { get; set; }
    public int Timeout { get; set; } = 30000;
}

[AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
public class TestCaseAttribute : Attribute
{
    public object[] Arguments { get; }
    public object ExpectedResult { get; set; }

    public TestCaseAttribute(params object[] arguments)
    {
        Arguments = arguments;
    }
}

public class CalculatorTests
{
    [Test(Description = "Test addition", Category = "Math")]
    [TestCase(2, 3, ExpectedResult = 5)]
    [TestCase(10, 20, ExpectedResult = 30)]
    [TestCase(-5, 5, ExpectedResult = 0)]
    public int TestAddition(int a, int b)
    {
        return a + b;
    }
}

// Example 5: Command pattern attribute
[AttributeUsage(AttributeTargets.Class)]
public class CommandAttribute : Attribute
{
    public string Name { get; }
    public string Description { get; set; }
    public string[] Aliases { get; set; }

    public CommandAttribute(string name)
    {
        Name = name;
    }
}

[Command("deploy", Description = "Deploy application",
         Aliases = new[] { "d", "publish" })]
public class DeployCommand
{
    public void Execute()
    {
        Console.WriteLine("Deploying...");
    }
}

// Example 6: ORM mapping (like Entity Framework)
public class DatabaseContext
{
    public void GenerateSchema()
    {
        Type type = typeof(User);

        var tableAttr = type.GetCustomAttribute<TableAttribute>();
        if (tableAttr != null)
        {
            Console.WriteLine($"CREATE TABLE [{tableAttr.Schema}].[{tableAttr.Name}] (");

            foreach (var property in type.GetProperties())
            {
                var columnAttr = property.GetCustomAttribute<ColumnAttribute>();
                if (columnAttr != null)
                {
                    var nullable = columnAttr.IsNullable ? "NULL" : "NOT NULL";
                    var pk = columnAttr.IsPrimaryKey ? "PRIMARY KEY" : "";

                    Console.WriteLine($"  [{columnAttr.Name}] {columnAttr.DataType} {nullable} {pk},");
                }
            }

            Console.WriteLine(")");
        }
    }
}

// ============ ATTRIBUTE INHERITANCE ============

[AttributeUsage(AttributeTargets.Class, Inherited = true)]
public class BaseAttribute : Attribute
{
    public string BaseProperty { get; set; }
}

[Base(BaseProperty = "Base Value")]
public class BaseClass
{
}

// DerivedClass inherits BaseAttribute if Inherited = true
public class DerivedClass : BaseClass
{
}

public class AttributeInheritanceDemo
{
    public void CheckInheritance()
    {
        // Check if DerivedClass has BaseAttribute
        var derivedType = typeof(DerivedClass);
        var hasAttr = derivedType.GetCustomAttribute<BaseAttribute>(inherit: true);

        Console.WriteLine($"DerivedClass has BaseAttribute: {hasAttr != null}");
        // Output: True (if Inherited = true)
    }
}

// ============ SUPPORTING CLASSES ============

public interface ILogger
{
    void Log(string message);
}

public interface IEmailService
{
    void SendEmail(string to, string subject, string body);
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public List<string> Permissions { get; set; }
}
```

**AttributeUsage Properties:**
- **AttributeTargets**: Where attribute can be applied (Class, Method, Property, etc.)
- **AllowMultiple**: Can attribute be applied multiple times
- **Inherited**: Is attribute inherited by derived classes

**Common AttributeTargets:**
- `Class`, `Struct`, `Interface`, `Enum`
- `Method`, `Property`, `Field`, `Event`
- `Parameter`, `ReturnValue`
- `Assembly`, `Module`
- `All` (all targets)

**Best Practices:**
- ✅ Suffix custom attributes with "Attribute"
- ✅ Inherit from System.Attribute
- ✅ Use AttributeUsage to control application
- ✅ Keep attributes simple and focused
- ✅ Use properties for optional parameters
- ✅ Validate attribute usage at compile time when possible
- ❌ Don't put logic in attribute classes (use reflection to read and act)

---

### Q49: Explain reflection in C#. What are its use cases?

**Reflection:**
- Inspect and manipulate code at runtime
- Access metadata about types, methods, properties
- Create instances dynamically
- Invoke methods dynamically
- Read/write properties and fields
- Part of System.Reflection namespace

**Key Classes:**
- `Type`: Represents type declarations
- `MethodInfo`: Method information
- `PropertyInfo`: Property information
- `FieldInfo`: Field information
- `Assembly`: Assembly metadata

**Example:**
```csharp
// ============ BASIC REFLECTION ============

public class ReflectionBasics
{
    public void GetTypeInformation()
    {
        // Get Type object
        Type type = typeof(string);

        Console.WriteLine($"Name: {type.Name}");                    // String
        Console.WriteLine($"FullName: {type.FullName}");           // System.String
        Console.WriteLine($"Namespace: {type.Namespace}");         // System
        Console.WriteLine($"Assembly: {type.Assembly.GetName().Name}");  // System.Runtime
        Console.WriteLine($"Is Class: {type.IsClass}");            // True
        Console.WriteLine($"Is ValueType: {type.IsValueType}");    // False
        Console.WriteLine($"Is Sealed: {type.IsSealed}");          // True

        // Get Type from instance
        string str = "Hello";
        Type typeFromInstance = str.GetType();

        // Get Type from string
        Type typeFromString = Type.GetType("System.String");
    }

    public void GetMembers()
    {
        Type type = typeof(StringBuilder);

        // Get all members
        MemberInfo[] members = type.GetMembers();
        Console.WriteLine($"Total members: {members.Length}");

        // Get methods
        MethodInfo[] methods = type.GetMethods();
        foreach (var method in methods.Take(5))
        {
            Console.WriteLine($"Method: {method.Name}");
        }

        // Get properties
        PropertyInfo[] properties = type.GetProperties();
        foreach (var property in properties)
        {
            Console.WriteLine($"Property: {property.Name} ({property.PropertyType.Name})");
        }

        // Get fields
        FieldInfo[] fields = type.GetFields();
        foreach (var field in fields)
        {
            Console.WriteLine($"Field: {field.Name}");
        }
    }
}

// ============ CREATING INSTANCES ============

public class InstanceCreation
{
    public void CreateInstances()
    {
        // Activator.CreateInstance
        Type type = typeof(StringBuilder);
        object instance = Activator.CreateInstance(type);
        Console.WriteLine($"Created: {instance.GetType().Name}");

        // With constructor parameters
        object instance2 = Activator.CreateInstance(type, "Initial text");
        Console.WriteLine($"Created with params: {instance2}");

        // Generic version
        StringBuilder sb = Activator.CreateInstance<StringBuilder>();

        // Using ConstructorInfo
        Type userType = typeof(User);
        ConstructorInfo constructor = userType.GetConstructor(new[] { typeof(string), typeof(int) });
        if (constructor != null)
        {
            User user = (User)constructor.Invoke(new object[] { "John", 30 });
            Console.WriteLine($"Created user: {user.Name}, Age: {user.Age}");
        }
    }

    public T CreateGenericInstance<T>() where T : new()
    {
        return Activator.CreateInstance<T>();
    }

    public object CreateInstanceByName(string typeName)
    {
        Type type = Type.GetType(typeName);
        if (type != null)
        {
            return Activator.CreateInstance(type);
        }
        return null;
    }
}

// ============ INVOKING METHODS ============

public class MethodInvocation
{
    public void InvokeMethods()
    {
        var calculator = new Calculator();
        Type type = calculator.GetType();

        // Get specific method
        MethodInfo addMethod = type.GetMethod("Add");
        if (addMethod != null)
        {
            // Invoke method
            object result = addMethod.Invoke(calculator, new object[] { 5, 3 });
            Console.WriteLine($"Result: {result}");  // 8
        }

        // Invoke private method
        MethodInfo privateMethod = type.GetMethod("PrivateMethod",
            BindingFlags.NonPublic | BindingFlags.Instance);
        if (privateMethod != null)
        {
            privateMethod.Invoke(calculator, null);
        }

        // Invoke static method
        MethodInfo staticMethod = type.GetMethod("Multiply",
            BindingFlags.Public | BindingFlags.Static);
        if (staticMethod != null)
        {
            object result = staticMethod.Invoke(null, new object[] { 4, 5 });
            Console.WriteLine($"Static result: {result}");  // 20
        }

        // Invoke generic method
        MethodInfo genericMethod = type.GetMethod("GenericMethod");
        if (genericMethod != null)
        {
            MethodInfo constructed = genericMethod.MakeGenericMethod(typeof(string));
            object result = constructed.Invoke(calculator, new object[] { "Hello" });
        }
    }
}

// ============ ACCESSING PROPERTIES AND FIELDS ============

public class PropertyFieldAccess
{
    public void AccessProperties()
    {
        var user = new User { Name = "John", Age = 30 };
        Type type = user.GetType();

        // Get property value
        PropertyInfo nameProperty = type.GetProperty("Name");
        if (nameProperty != null)
        {
            object value = nameProperty.GetValue(user);
            Console.WriteLine($"Name: {value}");

            // Set property value
            nameProperty.SetValue(user, "Jane");
            Console.WriteLine($"New name: {user.Name}");
        }

        // Get all properties
        foreach (var property in type.GetProperties())
        {
            object value = property.GetValue(user);
            Console.WriteLine($"{property.Name} = {value}");
        }
    }

    public void AccessFields()
    {
        var obj = new MyClass();
        Type type = obj.GetType();

        // Access private field
        FieldInfo privateField = type.GetField("_privateData",
            BindingFlags.NonPublic | BindingFlags.Instance);
        if (privateField != null)
        {
            object value = privateField.GetValue(obj);
            Console.WriteLine($"Private field: {value}");

            // Modify private field
            privateField.SetValue(obj, "Modified");
        }
    }
}

// ============ READING ATTRIBUTES ============

public class AttributeReading
{
    public void ReadAttributes()
    {
        Type type = typeof(UserController);

        // Get custom attributes
        var attributes = type.GetCustomAttributes(typeof(AuthorAttribute), false);
        foreach (AuthorAttribute attr in attributes)
        {
            Console.WriteLine($"Author: {attr.Name}, Date: {attr.Date}");
        }

        // Using GetCustomAttribute<T>
        var authorAttr = type.GetCustomAttribute<AuthorAttribute>();
        if (authorAttr != null)
        {
            Console.WriteLine($"Found author: {authorAttr.Name}");
        }

        // Read method attributes
        foreach (var method in type.GetMethods())
        {
            var apiAttr = method.GetCustomAttribute<ApiEndpointAttribute>();
            if (apiAttr != null)
            {
                Console.WriteLine($"{method.Name}: {apiAttr.Route}");
            }
        }
    }
}

// ============ EXAMINING GENERICS ============

public class GenericReflection
{
    public void ExamineGenerics()
    {
        Type listType = typeof(List<int>);

        Console.WriteLine($"Is generic: {listType.IsGenericType}");
        Console.WriteLine($"Generic definition: {listType.GetGenericTypeDefinition().Name}");

        // Get generic arguments
        Type[] typeArgs = listType.GetGenericArguments();
        foreach (var arg in typeArgs)
        {
            Console.WriteLine($"Type argument: {arg.Name}");
        }

        // Create generic type
        Type genericList = typeof(List<>);
        Type constructedType = genericList.MakeGenericType(typeof(string));
        object instance = Activator.CreateInstance(constructedType);

        Console.WriteLine($"Created: {instance.GetType().Name}");
    }
}

// ============ ASSEMBLY REFLECTION ============

public class AssemblyReflection
{
    public void ExamineAssembly()
    {
        // Get current assembly
        Assembly assembly = Assembly.GetExecutingAssembly();

        Console.WriteLine($"Assembly: {assembly.GetName().Name}");
        Console.WriteLine($"Version: {assembly.GetName().Version}");
        Console.WriteLine($"Location: {assembly.Location}");

        // Get all types in assembly
        Type[] types = assembly.GetTypes();
        Console.WriteLine($"Total types: {types.Length}");

        foreach (var type in types.Take(10))
        {
            Console.WriteLine($"  - {type.FullName}");
        }

        // Load assembly dynamically
        Assembly loadedAssembly = Assembly.LoadFrom("SomeLibrary.dll");
        Type someType = loadedAssembly.GetType("Namespace.ClassName");
    }

    public void FindTypesByAttribute()
    {
        Assembly assembly = Assembly.GetExecutingAssembly();

        // Find all types with specific attribute
        var typesWithAttribute = assembly.GetTypes()
            .Where(t => t.GetCustomAttribute<AuthorAttribute>() != null);

        foreach (var type in typesWithAttribute)
        {
            Console.WriteLine($"Type: {type.Name}");
            var attr = type.GetCustomAttribute<AuthorAttribute>();
            Console.WriteLine($"  Author: {attr.Name}");
        }
    }
}

// ============ REAL-WORLD USE CASES ============

// Use Case 1: Dependency Injection Container
public class SimpleContainer
{
    private readonly Dictionary<Type, Type> _registrations = new();
    private readonly Dictionary<Type, object> _singletons = new();

    public void Register<TInterface, TImplementation>()
        where TImplementation : TInterface
    {
        _registrations[typeof(TInterface)] = typeof(TImplementation);
    }

    public T Resolve<T>()
    {
        return (T)Resolve(typeof(T));
    }

    private object Resolve(Type type)
    {
        // Check singletons
        if (_singletons.TryGetValue(type, out object singleton))
        {
            return singleton;
        }

        // Get implementation type
        if (!_registrations.TryGetValue(type, out Type implementation))
        {
            implementation = type;
        }

        // Get constructor
        ConstructorInfo constructor = implementation.GetConstructors().First();
        ParameterInfo[] parameters = constructor.GetParameters();

        // Resolve dependencies
        object[] dependencies = parameters
            .Select(p => Resolve(p.ParameterType))
            .ToArray();

        // Create instance
        object instance = constructor.Invoke(dependencies);

        return instance;
    }
}

// Use Case 2: Object Mapper (like AutoMapper)
public class SimpleMapper
{
    public TDestination Map<TSource, TDestination>(TSource source)
        where TDestination : new()
    {
        var destination = new TDestination();

        Type sourceType = typeof(TSource);
        Type destType = typeof(TDestination);

        // Get matching properties
        foreach (var sourceProp in sourceType.GetProperties())
        {
            var destProp = destType.GetProperty(sourceProp.Name);
            if (destProp != null && destProp.CanWrite)
            {
                var value = sourceProp.GetValue(source);
                destProp.SetValue(destination, value);
            }
        }

        return destination;
    }
}

// Use Case 3: Validator
public class Validator
{
    public List<string> Validate(object obj)
    {
        var errors = new List<string>();
        Type type = obj.GetType();

        foreach (var property in type.GetProperties())
        {
            // Check Required attribute
            var requiredAttr = property.GetCustomAttribute<RequiredAttribute>();
            if (requiredAttr != null)
            {
                var value = property.GetValue(obj);
                if (value == null || (value is string str && string.IsNullOrEmpty(str)))
                {
                    errors.Add($"{property.Name} is required");
                }
            }

            // Check Range attribute
            var rangeAttr = property.GetCustomAttribute<RangeAttribute>();
            if (rangeAttr != null)
            {
                var value = property.GetValue(obj);
                if (value is int intValue)
                {
                    if (intValue < (int)rangeAttr.Minimum || intValue > (int)rangeAttr.Maximum)
                    {
                        errors.Add($"{property.Name} must be between {rangeAttr.Minimum} and {rangeAttr.Maximum}");
                    }
                }
            }
        }

        return errors;
    }
}

// Use Case 4: Plugin System
public class PluginLoader
{
    public List<IPlugin> LoadPlugins(string pluginDirectory)
    {
        var plugins = new List<IPlugin>();

        // Load all DLLs in directory
        var dllFiles = Directory.GetFiles(pluginDirectory, "*.dll");

        foreach (var dllFile in dllFiles)
        {
            Assembly assembly = Assembly.LoadFrom(dllFile);

            // Find types implementing IPlugin
            var pluginTypes = assembly.GetTypes()
                .Where(t => typeof(IPlugin).IsAssignableFrom(t) && !t.IsInterface);

            foreach (var type in pluginTypes)
            {
                var plugin = (IPlugin)Activator.CreateInstance(type);
                plugins.Add(plugin);
            }
        }

        return plugins;
    }
}

// Use Case 5: Serializer
public class JsonSerializer
{
    public string Serialize(object obj)
    {
        var sb = new StringBuilder();
        sb.Append("{");

        Type type = obj.GetType();
        var properties = type.GetProperties();

        for (int i = 0; i < properties.Length; i++)
        {
            var property = properties[i];
            var value = property.GetValue(obj);

            sb.Append($"\"{property.Name}\":");

            if (value == null)
            {
                sb.Append("null");
            }
            else if (value is string || value is char)
            {
                sb.Append($"\"{value}\"");
            }
            else
            {
                sb.Append(value);
            }

            if (i < properties.Length - 1)
            {
                sb.Append(",");
            }
        }

        sb.Append("}");
        return sb.ToString();
    }
}

// Use Case 6: Test Runner
public class TestRunner
{
    public void RunTests(Assembly assembly)
    {
        var testClasses = assembly.GetTypes()
            .Where(t => t.GetMethods().Any(m => m.GetCustomAttribute<TestAttribute>() != null));

        foreach (var testClass in testClasses)
        {
            var instance = Activator.CreateInstance(testClass);

            var testMethods = testClass.GetMethods()
                .Where(m => m.GetCustomAttribute<TestAttribute>() != null);

            foreach (var method in testMethods)
            {
                try
                {
                    method.Invoke(instance, null);
                    Console.WriteLine($"✓ {testClass.Name}.{method.Name}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"✗ {testClass.Name}.{method.Name}: {ex.Message}");
                }
            }
        }
    }
}

// ============ PERFORMANCE CONSIDERATIONS ============

public class PerformanceDemo
{
    public void ReflectionPerformance()
    {
        var user = new User { Name = "John", Age = 30 };

        // Direct access (fast)
        var sw1 = Stopwatch.StartNew();
        for (int i = 0; i < 1000000; i++)
        {
            var name = user.Name;
        }
        sw1.Stop();
        Console.WriteLine($"Direct: {sw1.ElapsedMilliseconds}ms");

        // Reflection (slow)
        PropertyInfo nameProperty = typeof(User).GetProperty("Name");
        var sw2 = Stopwatch.StartNew();
        for (int i = 0; i < 1000000; i++)
        {
            var name = nameProperty.GetValue(user);
        }
        sw2.Stop();
        Console.WriteLine($"Reflection: {sw2.ElapsedMilliseconds}ms");

        // Cached reflection (better)
        var cachedProperty = typeof(User).GetProperty("Name");
        var sw3 = Stopwatch.StartNew();
        for (int i = 0; i < 1000000; i++)
        {
            var name = cachedProperty.GetValue(user);
        }
        sw3.Stop();
        Console.WriteLine($"Cached: {sw3.ElapsedMilliseconds}ms");
    }
}

// ============ SUPPORTING CLASSES ============

public class Calculator
{
    public int Add(int a, int b) => a + b;
    public static int Multiply(int a, int b) => a * b;
    private void PrivateMethod() => Console.WriteLine("Private");
    public T GenericMethod<T>(T value) => value;
}

public class User
{
    public string Name { get; set; }
    public int Age { get; set; }

    public User() { }

    public User(string name, int age)
    {
        Name = name;
        Age = age;
    }
}

public class MyClass
{
    private string _privateData = "Secret";
}

public interface IPlugin
{
    void Execute();
}

[Author("Test Author")]
public class UserController
{
}
```

**Common Use Cases:**
1. **Dependency Injection**: Resolve and create instances
2. **Serialization/Deserialization**: JSON, XML, etc.
3. **ORM Mapping**: Entity Framework, Dapper
4. **Validation**: Data annotations
5. **Plugin Systems**: Load external assemblies
6. **Testing Frameworks**: Discover and run tests
7. **Code Generation**: T4 templates, source generators
8. **API Documentation**: Swagger, OpenAPI

**BindingFlags:**
- `Public`, `NonPublic`: Access level
- `Instance`, `Static`: Member type
- `DeclaredOnly`: Exclude inherited members

**Best Practices:**
- ✅ Cache reflection results (PropertyInfo, MethodInfo, etc.)
- ✅ Use compiled expressions for better performance
- ✅ Prefer direct code when possible
- ❌ Don't use reflection in tight loops
- ✅ Consider `dynamic` or expression trees as alternatives
- ✅ Use reflection for frameworks and libraries, not application logic

---

### Q50: What is the difference between reflection and dynamic in C#?

**Reflection:**
- Compile-time type inspection
- Runtime metadata access
- Slower performance
- Type-safe with manual checking
- Full control over member access
- Used for frameworks and tools

**Dynamic:**
- Runtime binding
- DLR (Dynamic Language Runtime)
- Better performance than reflection
- Type checking deferred to runtime
- Cleaner syntax
- Interop with dynamic languages

**Example:**
```csharp
// ============ REFLECTION VS DYNAMIC ============

public class ReflectionVsDynamic
{
    public void CompareApproaches()
    {
        var person = new Person { Name = "John", Age = 30 };

        // ===== REFLECTION APPROACH =====
        Type type = person.GetType();

        // Get property
        PropertyInfo nameProperty = type.GetProperty("Name");
        object nameValue = nameProperty.GetValue(person);
        Console.WriteLine($"Reflection: {nameValue}");

        // Set property
        nameProperty.SetValue(person, "Jane");

        // Invoke method
        MethodInfo sayHelloMethod = type.GetMethod("SayHello");
        object result = sayHelloMethod.Invoke(person, null);

        // ===== DYNAMIC APPROACH =====
        dynamic dynamicPerson = person;

        // Get property (much simpler!)
        string name = dynamicPerson.Name;
        Console.WriteLine($"Dynamic: {name}");

        // Set property
        dynamicPerson.Name = "Jane";

        // Invoke method
        string greeting = dynamicPerson.SayHello();
    }
}

// ============ SYNTAX COMPARISON ============

public class SyntaxComparison
{
    // Reflection - verbose
    public void UsingReflection(object obj)
    {
        Type type = obj.GetType();
        PropertyInfo property = type.GetProperty("Name");
        MethodInfo method = type.GetMethod("Process");

        if (property != null)
        {
            object value = property.GetValue(obj);
            property.SetValue(obj, "New Value");
        }

        if (method != null)
        {
            object result = method.Invoke(obj, new object[] { 123 });
        }
    }

    // Dynamic - clean
    public void UsingDynamic(dynamic obj)
    {
        // Much simpler syntax
        var value = obj.Name;
        obj.Name = "New Value";
        var result = obj.Process(123);
    }
}

// ============ PERFORMANCE COMPARISON ============

public class PerformanceComparison
{
    public void BenchmarkPerformance()
    {
        var person = new Person { Name = "John", Age = 30 };
        const int iterations = 1000000;

        // Direct access (baseline)
        var sw1 = Stopwatch.StartNew();
        for (int i = 0; i < iterations; i++)
        {
            var name = person.Name;
        }
        sw1.Stop();
        Console.WriteLine($"Direct: {sw1.ElapsedMilliseconds}ms");

        // Reflection
        PropertyInfo nameProperty = typeof(Person).GetProperty("Name");
        var sw2 = Stopwatch.StartNew();
        for (int i = 0; i < iterations; i++)
        {
            var name = nameProperty.GetValue(person);
        }
        sw2.Stop();
        Console.WriteLine($"Reflection: {sw2.ElapsedMilliseconds}ms");

        // Dynamic
        dynamic dynamicPerson = person;
        var sw3 = Stopwatch.StartNew();
        for (int i = 0; i < iterations; i++)
        {
            var name = dynamicPerson.Name;
        }
        sw3.Stop();
        Console.WriteLine($"Dynamic: {sw3.ElapsedMilliseconds}ms");

        /* Typical results:
         * Direct: ~5ms
         * Reflection: ~1500ms (300x slower)
         * Dynamic: ~150ms (30x slower)
         *
         * Dynamic is ~10x faster than reflection!
         */
    }
}

// ============ TYPE SAFETY ============

public class TypeSafetyComparison
{
    public void ReflectionTypeSafety()
    {
        var person = new Person { Name = "John" };
        Type type = person.GetType();

        // No compile-time checking
        PropertyInfo property = type.GetProperty("NonExistentProperty");

        if (property != null)  // Must check at runtime
        {
            property.GetValue(person);
        }
        else
        {
            Console.WriteLine("Property not found");
        }

        // Wrong parameter type - exception at runtime
        MethodInfo method = type.GetMethod("SetAge");
        try
        {
            method?.Invoke(person, new object[] { "NotAnInteger" });  // Exception!
        }
        catch (ArgumentException ex)
        {
            Console.WriteLine($"Reflection error: {ex.Message}");
        }
    }

    public void DynamicTypeSafety()
    {
        dynamic person = new Person { Name = "John" };

        // No compile-time checking
        try
        {
            var value = person.NonExistentProperty;  // RuntimeBinderException!
        }
        catch (RuntimeBinderException ex)
        {
            Console.WriteLine($"Dynamic error: {ex.Message}");
        }

        // Wrong parameter type - exception at runtime
        try
        {
            person.SetAge("NotAnInteger");  // RuntimeBinderException!
        }
        catch (RuntimeBinderException ex)
        {
            Console.WriteLine($"Dynamic error: {ex.Message}");
        }
    }
}

// ============ CAPABILITIES COMPARISON ============

public class CapabilitiesComparison
{
    // Reflection - full metadata access
    public void ReflectionCapabilities()
    {
        Type type = typeof(Person);

        // Get all members
        MemberInfo[] members = type.GetMembers();

        // Get private members
        FieldInfo privateField = type.GetField("_privateData",
            BindingFlags.NonPublic | BindingFlags.Instance);

        // Get attributes
        var attributes = type.GetCustomAttributes();

        // Get generic type information
        if (type.IsGenericType)
        {
            Type[] typeArgs = type.GetGenericArguments();
        }

        // Get interfaces
        Type[] interfaces = type.GetInterfaces();

        // Get base type
        Type baseType = type.BaseType;

        // Create instances
        object instance = Activator.CreateInstance(type);
    }

    // Dynamic - limited to accessible members
    public void DynamicCapabilities()
    {
        dynamic person = new Person { Name = "John" };

        // Can only access public members
        var name = person.Name;  // ✓ Works

        // Cannot access private members
        // var privateData = person._privateData;  // ✗ Exception

        // Cannot get metadata easily
        // Type type = person.GetType();  // Must use (object)person

        // Cannot inspect attributes, interfaces, etc.
        // dynamic doesn't provide these capabilities
    }
}

// ============ WHEN TO USE EACH ============

public class WhenToUseWhat
{
    // ✅ Use Reflection when you need:
    // - Metadata inspection (attributes, interfaces, etc.)
    // - Create instances of unknown types
    // - Access private members (for testing/debugging)
    // - Build frameworks and libraries
    // - Plugin systems

    public void UseReflection()
    {
        // Plugin loader
        Assembly assembly = Assembly.LoadFrom("Plugin.dll");
        Type[] types = assembly.GetTypes();

        foreach (var type in types)
        {
            if (typeof(IPlugin).IsAssignableFrom(type))
            {
                var plugin = (IPlugin)Activator.CreateInstance(type);
                plugin.Execute();
            }
        }

        // Attribute-based configuration
        var methods = typeof(MyClass).GetMethods()
            .Where(m => m.GetCustomAttribute<TestAttribute>() != null);
    }

    // ✅ Use Dynamic when you need:
    // - Interop with COM/Office
    // - Work with dynamic languages (Python, JavaScript)
    // - Simplify reflection for known types
    // - JSON/XML dynamic parsing
    // - Cleaner syntax for runtime binding

    public void UseDynamic()
    {
        // COM Interop (Excel)
        dynamic excel = Activator.CreateInstance(Type.GetTypeFromProgID("Excel.Application"));
        excel.Visible = true;
        dynamic workbook = excel.Workbooks.Add();
        dynamic worksheet = workbook.Worksheets[1];
        worksheet.Cells[1, 1].Value = "Hello";

        // Dynamic JSON parsing
        dynamic json = JsonConvert.DeserializeObject("{ 'Name': 'John', 'Age': 30 }");
        string name = json.Name;
        int age = json.Age;

        // ExpandoObject for dynamic properties
        dynamic expando = new ExpandoObject();
        expando.Name = "John";
        expando.Age = 30;
        expando.SayHello = (Func<string>)(() => $"Hello, I'm {expando.Name}");
    }
}

// ============ EXPANDOOBJECT ============

public class ExpandoObjectExample
{
    public void DynamicObjectCreation()
    {
        dynamic person = new ExpandoObject();

        // Add properties dynamically
        person.Name = "John";
        person.Age = 30;
        person.Email = "john@example.com";

        // Add methods dynamically
        person.GetInfo = (Func<string>)(() =>
            $"{person.Name}, Age: {person.Age}, Email: {person.Email}");

        Console.WriteLine(person.GetInfo());

        // Access as dictionary
        var dict = (IDictionary<string, object>)person;
        foreach (var kvp in dict)
        {
            Console.WriteLine($"{kvp.Key}: {kvp.Value}");
        }

        // Add properties at runtime
        dict["PhoneNumber"] = "123-456-7890";
        Console.WriteLine(person.PhoneNumber);
    }
}

// ============ DYNAMICOBJECT ============

public class MyDynamicObject : DynamicObject
{
    private readonly Dictionary<string, object> _properties = new();

    public override bool TryGetMember(GetMemberBinder binder, out object result)
    {
        return _properties.TryGetValue(binder.Name, out result);
    }

    public override bool TrySetMember(SetMemberBinder binder, object value)
    {
        _properties[binder.Name] = value;
        return true;
    }

    public override bool TryInvokeMember(InvokeMemberBinder binder,
        object[] args, out object result)
    {
        if (binder.Name == "Print")
        {
            foreach (var kvp in _properties)
            {
                Console.WriteLine($"{kvp.Key}: {kvp.Value}");
            }
            result = null;
            return true;
        }

        result = null;
        return false;
    }
}

public class DynamicObjectExample
{
    public void UseDynamicObject()
    {
        dynamic obj = new MyDynamicObject();

        obj.Name = "John";
        obj.Age = 30;

        Console.WriteLine(obj.Name);
        Console.WriteLine(obj.Age);

        obj.Print();
    }
}

// ============ REAL-WORLD EXAMPLES ============

// Example 1: Reflection for ORM
public class SimpleORM
{
    public void Save<T>(T entity)
    {
        Type type = typeof(T);
        var tableAttr = type.GetCustomAttribute<TableAttribute>();
        string tableName = tableAttr?.Name ?? type.Name;

        var properties = type.GetProperties();
        var columns = new List<string>();
        var values = new List<string>();

        foreach (var property in properties)
        {
            var columnAttr = property.GetCustomAttribute<ColumnAttribute>();
            string columnName = columnAttr?.Name ?? property.Name;

            columns.Add(columnName);
            var value = property.GetValue(entity);
            values.Add($"'{value}'");
        }

        string sql = $"INSERT INTO {tableName} ({string.Join(", ", columns)}) " +
                    $"VALUES ({string.Join(", ", values)})";

        Console.WriteLine(sql);
    }
}

// Example 2: Dynamic for configuration
public class DynamicConfig
{
    public void LoadConfig()
    {
        dynamic config = new ExpandoObject();

        // Load from JSON
        string json = File.ReadAllText("config.json");
        config = JsonConvert.DeserializeObject<ExpandoObject>(json);

        // Access configuration
        string dbConnection = config.Database.ConnectionString;
        int timeout = config.Database.Timeout;
        bool enableLogging = config.Logging.Enabled;

        // Flexible, no need for predefined classes
    }
}

// Example 3: Mixing both
public class HybridApproach
{
    public void ProcessData(Type type)
    {
        // Use reflection to get metadata
        var properties = type.GetProperties()
            .Where(p => p.GetCustomAttribute<ProcessAttribute>() != null);

        // Create instance
        dynamic instance = Activator.CreateInstance(type);

        // Use dynamic for member access
        foreach (var property in properties)
        {
            // Get value using reflection
            var value = property.GetValue(instance);

            // Process using dynamic
            if (value != null)
            {
                instance.SetValue(property.Name, ProcessValue(value));
            }
        }
    }

    private object ProcessValue(object value)
    {
        return value;
    }
}

// ============ SUPPORTING CLASSES ============

public class Person
{
    public string Name { get; set; }
    public int Age { get; set; }
    private string _privateData = "Secret";

    public string SayHello()
    {
        return $"Hello, I'm {Name}";
    }

    public void SetAge(int age)
    {
        Age = age;
    }
}

public interface IPlugin
{
    void Execute();
}

public class ProcessAttribute : Attribute { }
```

**Comparison Table:**
| Feature | Reflection | Dynamic |
|---------|-----------|---------|
| Performance | Slow (~300x) | Moderate (~30x) |
| Syntax | Verbose | Clean |
| Type Safety | Runtime checks | Runtime checks |
| Metadata Access | ✅ Full | ❌ Limited |
| Private Members | ✅ Yes | ❌ No |
| Compile Errors | ❌ No | ❌ No |
| IntelliSense | ❌ No | ❌ No |
| Use Case | Frameworks, tools | Interop, dynamic data |
| Complexity | High | Medium |

**When to Use:**
- **Reflection**: Metadata inspection, frameworks, plugins, attributes
- **Dynamic**: COM interop, dynamic languages, cleaner syntax, dynamic data
- **Neither**: Direct code when possible (performance)

**Best Practices:**
- ✅ Prefer direct code over both
- ✅ Use **dynamic** instead of reflection when you don't need metadata
- ✅ Use **reflection** for framework/library code
- ✅ Cache reflection results
- ✅ Use **ExpandoObject** for dynamic properties
- ✅ Consider **source generators** instead of runtime reflection
- ❌ Don't use in performance-critical paths

---## Section 2: ASP.NET MVC & Web Development

### Q51: Explain the MVC (Model-View-Controller) pattern.

**MVC Pattern:**
- Architectural pattern for web applications
- Separates application into three components
- Improves testability and maintainability
- Clear separation of concerns
- Model: Data and business logic
- View: User interface/presentation
- Controller: Handles requests and coordinates

**Key Benefits:**
- Separation of concerns
- Testability (can test each component independently)
- Multiple views for same model
- Parallel development
- Easier maintenance

**Example:**
```csharp
// ============ MODEL ============

// Data model representing business entity
public class Product
{
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; }

    [Range(0, 10000)]
    public decimal Price { get; set; }

    public string Description { get; set; }

    public int Stock { get; set; }

    public string Category { get; set; }
}

// View model for specific view requirements
public class ProductViewModel
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public bool IsInStock => Stock > 0;
    public int Stock { get; set; }
    public string FormattedPrice => $"${Price:N2}";
}

// Business logic in service/repository
public interface IProductService
{
    Task<List<Product>> GetAllProductsAsync();
    Task<Product> GetProductByIdAsync(int id);
    Task<Product> CreateProductAsync(Product product);
    Task<Product> UpdateProductAsync(Product product);
    Task DeleteProductAsync(int id);
}

public class ProductService : IProductService
{
    private readonly ApplicationDbContext _context;

    public ProductService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<Product>> GetAllProductsAsync()
    {
        return await _context.Products
            .Where(p => p.Stock > 0)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public async Task<Product> GetProductByIdAsync(int id)
    {
        return await _context.Products.FindAsync(id);
    }

    public async Task<Product> CreateProductAsync(Product product)
    {
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return product;
    }

    public async Task<Product> UpdateProductAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();
        return product;
    }

    public async Task DeleteProductAsync(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product != null)
        {
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
        }
    }
}

// ============ CONTROLLER ============

public class ProductsController : Controller
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IProductService productService,
        ILogger<ProductsController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    // GET: /Products
    public async Task<IActionResult> Index()
    {
        try
        {
            var products = await _productService.GetAllProductsAsync();

            // Map to view models
            var viewModels = products.Select(p => new ProductViewModel
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                Stock = p.Stock
            }).ToList();

            return View(viewModels);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading products");
            return View("Error");
        }
    }

    // GET: /Products/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        var viewModel = new ProductViewModel
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            Stock = product.Stock
        };

        return View(viewModel);
    }

    // GET: /Products/Create
    public IActionResult Create()
    {
        return View();
    }

    // POST: /Products/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(Product product)
    {
        if (!ModelState.IsValid)
        {
            return View(product);
        }

        try
        {
            await _productService.CreateProductAsync(product);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            ModelState.AddModelError("", "Unable to create product");
            return View(product);
        }
    }

    // GET: /Products/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        return View(product);
    }

    // POST: /Products/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, Product product)
    {
        if (id != product.Id)
        {
            return BadRequest();
        }

        if (!ModelState.IsValid)
        {
            return View(product);
        }

        try
        {
            await _productService.UpdateProductAsync(product);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product");
            ModelState.AddModelError("", "Unable to update product");
            return View(product);
        }
    }

    // GET: /Products/Delete/5
    public async Task<IActionResult> Delete(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        return View(product);
    }

    // POST: /Products/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        try
        {
            await _productService.DeleteProductAsync(id);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product");
            return View("Error");
        }
    }
}

// ============ VIEW (Razor) ============

/* Index.cshtml */
@model List<ProductViewModel>

@{
    ViewData["Title"] = "Products";
}

<h2>Products</h2>

<p>
    <a asp-action="Create" class="btn btn-primary">Create New</a>
</p>

<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var product in Model)
        {
            <tr>
                <td>@product.Name</td>
                <td>@product.FormattedPrice</td>
                <td>@product.Stock</td>
                <td>
                    @if (product.IsInStock)
                    {
                        <span class="badge badge-success">In Stock</span>
                    }
                    else
                    {
                        <span class="badge badge-danger">Out of Stock</span>
                    }
                </td>
                <td>
                    <a asp-action="Details" asp-route-id="@product.Id">Details</a> |
                    <a asp-action="Edit" asp-route-id="@product.Id">Edit</a> |
                    <a asp-action="Delete" asp-route-id="@product.Id">Delete</a>
                </td>
            </tr>
        }
    </tbody>
</table>

/* Create.cshtml */
@model Product

@{
    ViewData["Title"] = "Create Product";
}

<h2>Create Product</h2>

<form asp-action="Create" method="post">
    <div asp-validation-summary="ModelOnly" class="text-danger"></div>

    <div class="form-group">
        <label asp-for="Name"></label>
        <input asp-for="Name" class="form-control" />
        <span asp-validation-for="Name" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Price"></label>
        <input asp-for="Price" class="form-control" />
        <span asp-validation-for="Price" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Description"></label>
        <textarea asp-for="Description" class="form-control"></textarea>
    </div>

    <div class="form-group">
        <label asp-for="Stock"></label>
        <input asp-for="Stock" class="form-control" type="number" />
        <span asp-validation-for="Stock" class="text-danger"></span>
    </div>

    <div class="form-group">
        <button type="submit" class="btn btn-primary">Create</button>
        <a asp-action="Index" class="btn btn-secondary">Cancel</a>
    </div>
</form>

@section Scripts {
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
}

// ============ MVC FLOW DIAGRAM ============

/*
 * REQUEST FLOW:
 *
 * 1. User Request
 *    ↓
 * 2. Routing (maps URL to Controller/Action)
 *    ↓
 * 3. Controller
 *    - Receives request
 *    - Calls Model/Service for data
 *    - Prepares ViewModel
 *    ↓
 * 4. Model/Service
 *    - Business logic
 *    - Data access
 *    - Returns data to Controller
 *    ↓
 * 5. Controller
 *    - Passes data to View
 *    ↓
 * 6. View
 *    - Renders HTML
 *    - Uses ViewData/ViewBag/Model
 *    ↓
 * 7. Response sent to User
 */

// ============ ASP.NET CORE MVC SETUP ============

// Program.cs (ASP.NET Core 6+)
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register services
builder.Services.AddScoped<IProductService, ProductService>();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

// ============ ADVANTAGES OF MVC ============

/*
 * 1. SEPARATION OF CONCERNS:
 *    - Model: Data and business logic
 *    - View: Presentation
 *    - Controller: Application flow
 *
 * 2. TESTABILITY:
 *    - Can unit test controllers independently
 *    - Can mock services and dependencies
 *    - Can test business logic without UI
 *
 * 3. MAINTAINABILITY:
 *    - Changes in UI don't affect business logic
 *    - Changes in data don't affect presentation
 *    - Easier to locate and fix bugs
 *
 * 4. PARALLEL DEVELOPMENT:
 *    - Frontend developers work on Views
 *    - Backend developers work on Models/Controllers
 *    - Can develop simultaneously
 *
 * 5. REUSABILITY:
 *    - Same model can have multiple views
 *    - Business logic can be reused across views
 *    - Partial views can be reused
 *
 * 6. SCALABILITY:
 *    - Easy to add new features
 *    - Easy to modify existing features
 *    - Clean architecture supports growth
 */

// ============ MVC VS OTHER PATTERNS ============

// MVC vs MVVM (Model-View-ViewModel)
/*
 * MVC:
 * - Controller handles user input
 * - View is passive
 * - One-way communication
 * - Used in: ASP.NET MVC, Ruby on Rails
 *
 * MVVM:
 * - ViewModel handles user input
 * - Two-way data binding
 * - View updates automatically
 * - Used in: WPF, Angular, Vue.js
 */

// MVC vs MVP (Model-View-Presenter)
/*
 * MVC:
 * - View can access Model directly
 * - Controller is intermediary
 *
 * MVP:
 * - View never accesses Model
 * - All communication through Presenter
 * - Used in: Windows Forms
 */

// ============ REAL-WORLD EXAMPLE ============

// E-commerce application structure
public class EcommerceStructure
{
    /*
     * MODELS:
     * - Product, Category, Order, OrderItem
     * - Customer, Address, Payment
     * - ShoppingCart, CartItem
     *
     * CONTROLLERS:
     * - HomeController (landing page)
     * - ProductsController (product catalog)
     * - ShoppingCartController (cart operations)
     * - OrdersController (checkout, order history)
     * - AccountController (login, register)
     *
     * VIEWS:
     * - Home/Index.cshtml
     * - Products/Index.cshtml (product list)
     * - Products/Details.cshtml (product details)
     * - ShoppingCart/Index.cshtml (cart view)
     * - Orders/Checkout.cshtml
     * - Account/Login.cshtml
     *
     * SERVICES (Business Logic):
     * - IProductService
     * - IOrderService
     * - IShoppingCartService
     * - IPaymentService
     */
}

// ============ SUPPORTING CLASSES ============

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products { get; set; }
}
```

**MVC Components:**

1. **Model:**
   - Data structures (entities)
   - Business logic (services, repositories)
   - Validation rules
   - Data access

2. **View:**
   - HTML/Razor templates
   - Display data from model
   - User interface
   - No business logic

3. **Controller:**
   - Handles HTTP requests
   - Coordinates between Model and View
   - Returns ActionResults
   - Handles user input

**Best Practices:**
- ✅ Keep controllers thin (delegate to services)
- ✅ Use ViewModels for view-specific data
- ✅ Don't put business logic in controllers
- ✅ Use dependency injection
- ✅ Follow RESTful naming conventions
- ✅ Use async/await for database operations
- ❌ Don't access database directly from controllers
- ❌ Don't put HTML in controllers

---

### Q52: What is the request lifecycle in ASP.NET MVC?

**Request Lifecycle Stages:**
1. Routing - URL mapped to controller/action
2. MVC Handler - Creates controller instance
3. Controller - Executes action method
4. Action Filters - Before/after action execution
5. Result Execution - Returns ActionResult
6. View Engine - Renders view
7. Response - HTML sent to client

**Detailed Flow:**
```
Request → Routing → Controller Factory → Controller →
Action Method → Action Result → View Engine → Response
```

**Example:**
```csharp
// ============ REQUEST LIFECYCLE DETAILED ============

/*
 * STEP 1: ROUTING
 * ---------------
 * URL: https://example.com/Products/Details/5
 *
 * Route Matching:
 * - Pattern: {controller}/{action}/{id?}
 * - Controller: Products
 * - Action: Details
 * - Parameters: id = 5
 */

// Route Configuration
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

/*
 * STEP 2: MVC HANDLER
 * -------------------
 * - MvcRouteHandler receives the request
 * - Creates MvcHandler instance
 * - MvcHandler processes the request
 */

/*
 * STEP 3: CONTROLLER FACTORY
 * --------------------------
 * - DefaultControllerFactory creates controller
 * - Resolves dependencies via DI
 * - Activates controller instance
 */

public class ProductsController : Controller
{
    private readonly IProductService _productService;

    // Constructor injection
    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    /*
     * STEP 4: ACTION INVOKER
     * ----------------------
     * - Finds action method (Details)
     * - Model binding (binds id parameter)
     * - Executes authorization filters
     * - Executes action filters
     */

    [Authorize] // Authorization filter
    [LogAction] // Custom action filter
    public async Task<IActionResult> Details(int id)
    {
        /*
         * STEP 5: ACTION EXECUTION
         * ------------------------
         * - Action method executes
         * - Retrieves data from service
         * - Returns ActionResult
         */

        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound(); // Returns NotFoundResult
        }

        return View(product); // Returns ViewResult
    }
}

/*
 * STEP 6: RESULT EXECUTION
 * ------------------------
 * - ViewResult.ExecuteResult() is called
 * - View engine locates view file
 * - View is rendered with model
 */

/*
 * STEP 7: VIEW ENGINE
 * -------------------
 * - Razor view engine processes .cshtml file
 * - Generates HTML from view + model
 * - Returns HTML string
 */

/*
 * STEP 8: RESPONSE
 * ----------------
 * - HTML is written to response stream
 * - Response sent to client browser
 * - Request completed
 */

// ============ REQUEST PIPELINE VISUALIZATION ============

public class RequestPipelineVisualization
{
    /*
     * 1. HTTP REQUEST
     *    ↓
     * 2. IIS/Kestrel receives request
     *    ↓
     * 3. ASP.NET Core Middleware Pipeline
     *    ↓
     * 4. ROUTING MIDDLEWARE
     *    - Matches URL to route
     *    - Extracts route values
     *    ↓
     * 5. ENDPOINT MIDDLEWARE
     *    - Invokes MVC
     *    ↓
     * 6. CONTROLLER FACTORY
     *    - Creates controller instance
     *    - Injects dependencies
     *    ↓
     * 7. MODEL BINDING
     *    - Binds request data to parameters
     *    - Validates model
     *    ↓
     * 8. AUTHORIZATION FILTERS
     *    - [Authorize]
     *    - Custom authorization
     *    ↓
     * 9. ACTION FILTERS (Before)
     *    - OnActionExecuting
     *    ↓
     * 10. ACTION METHOD
     *    - Business logic executes
     *    ↓
     * 11. ACTION FILTERS (After)
     *    - OnActionExecuted
     *    ↓
     * 12. RESULT FILTERS (Before)
     *    - OnResultExecuting
     *    ↓
     * 13. ACTION RESULT
     *    - ViewResult, JsonResult, etc.
     *    ↓
     * 14. VIEW ENGINE
     *    - Renders Razor view
     *    ↓
     * 15. RESULT FILTERS (After)
     *    - OnResultExecuted
     *    ↓
     * 16. RESPONSE
     *    - HTML/JSON sent to client
     */
}

// ============ FILTER EXECUTION ORDER ============

public class FilterExecutionOrder
{
    /*
     * FILTER ORDER:
     *
     * 1. Authorization Filters (First)
     *    - IAuthorizationFilter
     *    - [Authorize]
     *
     * 2. Resource Filters
     *    - IResourceFilter
     *    - Can short-circuit pipeline
     *
     * 3. Action Filters
     *    - IActionFilter
     *    - OnActionExecuting
     *    - [Action Method Executes]
     *    - OnActionExecuted
     *
     * 4. Exception Filters
     *    - IExceptionFilter
     *    - Only if exception occurs
     *
     * 5. Result Filters
     *    - IResultFilter
     *    - OnResultExecuting
     *    - [Result Executes]
     *    - OnResultExecuted (Last)
     */
}

// ============ CUSTOM ACTION FILTER EXAMPLE ============

public class LogActionFilter : IActionFilter
{
    private readonly ILogger<LogActionFilter> _logger;

    public LogActionFilter(ILogger<LogActionFilter> logger)
    {
        _logger = logger;
    }

    // Executes BEFORE action method
    public void OnActionExecuting(ActionExecutingContext context)
    {
        _logger.LogInformation(
            "Executing action {Action} on controller {Controller}",
            context.ActionDescriptor.DisplayName,
            context.Controller.GetType().Name);

        // Can access route values
        foreach (var param in context.ActionArguments)
        {
            _logger.LogInformation("Parameter: {Key} = {Value}",
                param.Key, param.Value);
        }
    }

    // Executes AFTER action method
    public void OnActionExecuted(ActionExecutedContext context)
    {
        _logger.LogInformation(
            "Executed action {Action}. Result: {Result}",
            context.ActionDescriptor.DisplayName,
            context.Result?.GetType().Name);

        // Can check for exceptions
        if (context.Exception != null)
        {
            _logger.LogError(context.Exception,
                "Exception in action {Action}",
                context.ActionDescriptor.DisplayName);
        }
    }
}

// ============ MODEL BINDING EXAMPLE ============

public class ModelBindingExample : Controller
{
    // Model binding from route
    public IActionResult Details(int id) // id from route
    {
        // id is automatically bound from URL
        return View();
    }

    // Model binding from query string
    public IActionResult Search(string query, int page = 1)
    {
        // URL: /Products/Search?query=laptop&page=2
        // query = "laptop", page = 2
        return View();
    }

    // Model binding from form POST
    [HttpPost]
    public IActionResult Create(Product product)
    {
        // Product properties bound from form fields
        // ModelState.IsValid checks validation
        if (!ModelState.IsValid)
        {
            return View(product);
        }

        // Save product
        return RedirectToAction("Index");
    }

    // Model binding from JSON body
    [HttpPost]
    public IActionResult CreateFromJson([FromBody] Product product)
    {
        // Product deserialized from JSON request body
        return Ok(product);
    }

    // Multiple binding sources
    [HttpPost]
    public IActionResult Update(
        [FromRoute] int id,
        [FromBody] Product product,
        [FromHeader(Name = "X-Api-Key")] string apiKey)
    {
        // id from route, product from body, apiKey from header
        return Ok();
    }
}

// ============ ACTION RESULTS ============

public class ActionResultExamples : Controller
{
    // ViewResult - renders a view
    public IActionResult Index()
    {
        return View(); // Returns ViewResult
    }

    // PartialViewResult - renders partial view
    public IActionResult GetPartial()
    {
        return PartialView("_ProductCard");
    }

    // JsonResult - returns JSON
    public IActionResult GetJson()
    {
        var data = new { Name = "Product", Price = 99.99 };
        return Json(data);
    }

    // RedirectResult - redirects to URL
    public IActionResult RedirectExample()
    {
        return Redirect("/Products");
    }

    // RedirectToActionResult - redirects to action
    public IActionResult RedirectToAction()
    {
        return RedirectToAction("Index", "Products");
    }

    // ContentResult - returns plain text
    public IActionResult GetText()
    {
        return Content("Hello World", "text/plain");
    }

    // FileResult - returns file download
    public IActionResult DownloadFile()
    {
        byte[] fileBytes = System.IO.File.ReadAllBytes("path/to/file.pdf");
        return File(fileBytes, "application/pdf", "document.pdf");
    }

    // StatusCodeResult - returns HTTP status
    public IActionResult NotFoundExample()
    {
        return NotFound(); // 404
    }

    public IActionResult BadRequestExample()
    {
        return BadRequest("Invalid data"); // 400
    }

    public IActionResult UnauthorizedExample()
    {
        return Unauthorized(); // 401
    }
}

// ============ REAL-WORLD REQUEST FLOW ============

public class RealWorldFlow : Controller
{
    private readonly IProductService _productService;
    private readonly ILogger<RealWorldFlow> _logger;

    public RealWorldFlow(
        IProductService _productService,
        ILogger<RealWorldFlow> logger)
    {
        this._productService = _productService;
        _logger = logger;
    }

    /*
     * Real request: GET /Products/Details/5
     *
     * 1. Request arrives at server
     * 2. Routing matches: controller=Products, action=Details, id=5
     * 3. ProductsController created via DI
     * 4. IProductService injected
     * 5. Model binding: id parameter = 5
     * 6. Authorization filters check user permissions
     * 7. Action filters log the request
     * 8. Details(5) method executes
     * 9. _productService.GetProductByIdAsync(5) called
     * 10. Product data retrieved from database
     * 11. ViewResult created with product model
     * 12. View engine finds Details.cshtml
     * 13. Razor template processed with product data
     * 14. HTML generated
     * 15. Result filters log the response
     * 16. HTML sent to browser
     */

    [Authorize] // Step 6: Authorization
    [LogAction] // Step 7: Action filter
    public async Task<IActionResult> Details(int id) // Step 5: Model binding
    {
        _logger.LogInformation("Fetching product {ProductId}", id);

        // Step 8-9: Execute business logic
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            // Step 11: Return 404
            return NotFound();
        }

        // Step 11-12: Return view with model
        return View(product);
    }
}

// ============ ASP.NET CORE MIDDLEWARE INTEGRATION ============

// Program.cs showing full pipeline
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Middleware executes in order
app.UseHttpsRedirection();      // 1. Redirect HTTP to HTTPS
app.UseStaticFiles();           // 2. Serve static files
app.UseRouting();               // 3. Route matching
app.UseAuthentication();        // 4. Authenticate user
app.UseAuthorization();         // 5. Authorize user

// 6. Endpoint routing (MVC)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

/*
 * Request flows through middleware in order:
 * Request → HTTPS Redirect → Static Files → Routing →
 * Authentication → Authorization → MVC → Response
 */

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public interface IProductService
{
    Task<Product> GetProductByIdAsync(int id);
}

public class LogActionAttribute : Attribute, IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context) { }
    public void OnActionExecuted(ActionExecutedContext context) { }
}
```

**Key Stages Summary:**
1. **Routing**: Maps URL to controller/action
2. **Controller Creation**: DI resolves dependencies
3. **Model Binding**: Request data → method parameters
4. **Filters**: Authorization → Resource → Action → Exception → Result
5. **Action Execution**: Business logic runs
6. **Result Execution**: ViewResult/JsonResult/etc.
7. **View Rendering**: Razor → HTML
8. **Response**: HTML sent to client

**Best Practices:**
- ✅ Use async/await for I/O operations
- ✅ Keep action methods focused and thin
- ✅ Use filters for cross-cutting concerns
- ✅ Return appropriate ActionResult types
- ✅ Handle exceptions gracefully
- ❌ Don't perform long-running operations in actions
- ❌ Don't ignore ModelState validation

---

(Continuing with Q53-Q60...)
## Section 2: ASP.NET MVC & Web Development

### Q51: Explain the MVC (Model-View-Controller) pattern.

**MVC Pattern:**
- Architectural pattern for web applications
- Separates application into three components
- Improves testability and maintainability
- Clear separation of concerns
- Model: Data and business logic
- View: User interface/presentation
- Controller: Handles requests and coordinates

**Key Benefits:**
- Separation of concerns
- Testability (can test each component independently)
- Multiple views for same model
- Parallel development
- Easier maintenance

**Example:**
```csharp
// ============ MODEL ============

// Data model representing business entity
public class Product
{
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; }

    [Range(0, 10000)]
    public decimal Price { get; set; }

    public string Description { get; set; }

    public int Stock { get; set; }

    public string Category { get; set; }
}

// View model for specific view requirements
public class ProductViewModel
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public bool IsInStock => Stock > 0;
    public int Stock { get; set; }
    public string FormattedPrice => $"${Price:N2}";
}

// Business logic in service/repository
public interface IProductService
{
    Task<List<Product>> GetAllProductsAsync();
    Task<Product> GetProductByIdAsync(int id);
    Task<Product> CreateProductAsync(Product product);
    Task<Product> UpdateProductAsync(Product product);
    Task DeleteProductAsync(int id);
}

public class ProductService : IProductService
{
    private readonly ApplicationDbContext _context;

    public ProductService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<Product>> GetAllProductsAsync()
    {
        return await _context.Products
            .Where(p => p.Stock > 0)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public async Task<Product> GetProductByIdAsync(int id)
    {
        return await _context.Products.FindAsync(id);
    }

    public async Task<Product> CreateProductAsync(Product product)
    {
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return product;
    }

    public async Task<Product> UpdateProductAsync(Product product)
    {
        _context.Products.Update(product);
        await _context.SaveChangesAsync();
        return product;
    }

    public async Task DeleteProductAsync(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product != null)
        {
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
        }
    }
}

// ============ CONTROLLER ============

public class ProductsController : Controller
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IProductService productService,
        ILogger<ProductsController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    // GET: /Products
    public async Task<IActionResult> Index()
    {
        try
        {
            var products = await _productService.GetAllProductsAsync();

            // Map to view models
            var viewModels = products.Select(p => new ProductViewModel
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                Stock = p.Stock
            }).ToList();

            return View(viewModels);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading products");
            return View("Error");
        }
    }

    // GET: /Products/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        var viewModel = new ProductViewModel
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            Stock = product.Stock
        };

        return View(viewModel);
    }

    // GET: /Products/Create
    public IActionResult Create()
    {
        return View();
    }

    // POST: /Products/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(Product product)
    {
        if (!ModelState.IsValid)
        {
            return View(product);
        }

        try
        {
            await _productService.CreateProductAsync(product);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            ModelState.AddModelError("", "Unable to create product");
            return View(product);
        }
    }

    // GET: /Products/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        return View(product);
    }

    // POST: /Products/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, Product product)
    {
        if (id != product.Id)
        {
            return BadRequest();
        }

        if (!ModelState.IsValid)
        {
            return View(product);
        }

        try
        {
            await _productService.UpdateProductAsync(product);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product");
            ModelState.AddModelError("", "Unable to update product");
            return View(product);
        }
    }

    // GET: /Products/Delete/5
    public async Task<IActionResult> Delete(int id)
    {
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        return View(product);
    }

    // POST: /Products/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        try
        {
            await _productService.DeleteProductAsync(id);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product");
            return View("Error");
        }
    }
}

// ============ VIEW (Razor) ============

/* Index.cshtml */
@model List<ProductViewModel>

@{
    ViewData["Title"] = "Products";
}

<h2>Products</h2>

<p>
    <a asp-action="Create" class="btn btn-primary">Create New</a>
</p>

<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var product in Model)
        {
            <tr>
                <td>@product.Name</td>
                <td>@product.FormattedPrice</td>
                <td>@product.Stock</td>
                <td>
                    @if (product.IsInStock)
                    {
                        <span class="badge badge-success">In Stock</span>
                    }
                    else
                    {
                        <span class="badge badge-danger">Out of Stock</span>
                    }
                </td>
                <td>
                    <a asp-action="Details" asp-route-id="@product.Id">Details</a> |
                    <a asp-action="Edit" asp-route-id="@product.Id">Edit</a> |
                    <a asp-action="Delete" asp-route-id="@product.Id">Delete</a>
                </td>
            </tr>
        }
    </tbody>
</table>

/* Create.cshtml */
@model Product

@{
    ViewData["Title"] = "Create Product";
}

<h2>Create Product</h2>

<form asp-action="Create" method="post">
    <div asp-validation-summary="ModelOnly" class="text-danger"></div>

    <div class="form-group">
        <label asp-for="Name"></label>
        <input asp-for="Name" class="form-control" />
        <span asp-validation-for="Name" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Price"></label>
        <input asp-for="Price" class="form-control" />
        <span asp-validation-for="Price" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Description"></label>
        <textarea asp-for="Description" class="form-control"></textarea>
    </div>

    <div class="form-group">
        <label asp-for="Stock"></label>
        <input asp-for="Stock" class="form-control" type="number" />
        <span asp-validation-for="Stock" class="text-danger"></span>
    </div>

    <div class="form-group">
        <button type="submit" class="btn btn-primary">Create</button>
        <a asp-action="Index" class="btn btn-secondary">Cancel</a>
    </div>
</form>

@section Scripts {
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
}

// ============ MVC FLOW DIAGRAM ============

/*
 * REQUEST FLOW:
 *
 * 1. User Request
 *    ↓
 * 2. Routing (maps URL to Controller/Action)
 *    ↓
 * 3. Controller
 *    - Receives request
 *    - Calls Model/Service for data
 *    - Prepares ViewModel
 *    ↓
 * 4. Model/Service
 *    - Business logic
 *    - Data access
 *    - Returns data to Controller
 *    ↓
 * 5. Controller
 *    - Passes data to View
 *    ↓
 * 6. View
 *    - Renders HTML
 *    - Uses ViewData/ViewBag/Model
 *    ↓
 * 7. Response sent to User
 */

// ============ ASP.NET CORE MVC SETUP ============

// Program.cs (ASP.NET Core 6+)
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register services
builder.Services.AddScoped<IProductService, ProductService>();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

// ============ ADVANTAGES OF MVC ============

/*
 * 1. SEPARATION OF CONCERNS:
 *    - Model: Data and business logic
 *    - View: Presentation
 *    - Controller: Application flow
 *
 * 2. TESTABILITY:
 *    - Can unit test controllers independently
 *    - Can mock services and dependencies
 *    - Can test business logic without UI
 *
 * 3. MAINTAINABILITY:
 *    - Changes in UI don't affect business logic
 *    - Changes in data don't affect presentation
 *    - Easier to locate and fix bugs
 *
 * 4. PARALLEL DEVELOPMENT:
 *    - Frontend developers work on Views
 *    - Backend developers work on Models/Controllers
 *    - Can develop simultaneously
 *
 * 5. REUSABILITY:
 *    - Same model can have multiple views
 *    - Business logic can be reused across views
 *    - Partial views can be reused
 *
 * 6. SCALABILITY:
 *    - Easy to add new features
 *    - Easy to modify existing features
 *    - Clean architecture supports growth
 */

// ============ MVC VS OTHER PATTERNS ============

// MVC vs MVVM (Model-View-ViewModel)
/*
 * MVC:
 * - Controller handles user input
 * - View is passive
 * - One-way communication
 * - Used in: ASP.NET MVC, Ruby on Rails
 *
 * MVVM:
 * - ViewModel handles user input
 * - Two-way data binding
 * - View updates automatically
 * - Used in: WPF, Angular, Vue.js
 */

// MVC vs MVP (Model-View-Presenter)
/*
 * MVC:
 * - View can access Model directly
 * - Controller is intermediary
 *
 * MVP:
 * - View never accesses Model
 * - All communication through Presenter
 * - Used in: Windows Forms
 */

// ============ REAL-WORLD EXAMPLE ============

// E-commerce application structure
public class EcommerceStructure
{
    /*
     * MODELS:
     * - Product, Category, Order, OrderItem
     * - Customer, Address, Payment
     * - ShoppingCart, CartItem
     *
     * CONTROLLERS:
     * - HomeController (landing page)
     * - ProductsController (product catalog)
     * - ShoppingCartController (cart operations)
     * - OrdersController (checkout, order history)
     * - AccountController (login, register)
     *
     * VIEWS:
     * - Home/Index.cshtml
     * - Products/Index.cshtml (product list)
     * - Products/Details.cshtml (product details)
     * - ShoppingCart/Index.cshtml (cart view)
     * - Orders/Checkout.cshtml
     * - Account/Login.cshtml
     *
     * SERVICES (Business Logic):
     * - IProductService
     * - IOrderService
     * - IShoppingCartService
     * - IPaymentService
     */
}

// ============ SUPPORTING CLASSES ============

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products { get; set; }
}
```

**MVC Components:**

1. **Model:**
   - Data structures (entities)
   - Business logic (services, repositories)
   - Validation rules
   - Data access

2. **View:**
   - HTML/Razor templates
   - Display data from model
   - User interface
   - No business logic

3. **Controller:**
   - Handles HTTP requests
   - Coordinates between Model and View
   - Returns ActionResults
   - Handles user input

**Best Practices:**
- ✅ Keep controllers thin (delegate to services)
- ✅ Use ViewModels for view-specific data
- ✅ Don't put business logic in controllers
- ✅ Use dependency injection
- ✅ Follow RESTful naming conventions
- ✅ Use async/await for database operations
- ❌ Don't access database directly from controllers
- ❌ Don't put HTML in controllers

---

### Q52: What is the request lifecycle in ASP.NET MVC?

**Request Lifecycle Stages:**
1. Routing - URL mapped to controller/action
2. MVC Handler - Creates controller instance
3. Controller - Executes action method
4. Action Filters - Before/after action execution
5. Result Execution - Returns ActionResult
6. View Engine - Renders view
7. Response - HTML sent to client

**Detailed Flow:**
```
Request → Routing → Controller Factory → Controller →
Action Method → Action Result → View Engine → Response
```

**Example:**
```csharp
// ============ REQUEST LIFECYCLE DETAILED ============

/*
 * STEP 1: ROUTING
 * ---------------
 * URL: https://example.com/Products/Details/5
 *
 * Route Matching:
 * - Pattern: {controller}/{action}/{id?}
 * - Controller: Products
 * - Action: Details
 * - Parameters: id = 5
 */

// Route Configuration
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

/*
 * STEP 2: MVC HANDLER
 * -------------------
 * - MvcRouteHandler receives the request
 * - Creates MvcHandler instance
 * - MvcHandler processes the request
 */

/*
 * STEP 3: CONTROLLER FACTORY
 * --------------------------
 * - DefaultControllerFactory creates controller
 * - Resolves dependencies via DI
 * - Activates controller instance
 */

public class ProductsController : Controller
{
    private readonly IProductService _productService;

    // Constructor injection
    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    /*
     * STEP 4: ACTION INVOKER
     * ----------------------
     * - Finds action method (Details)
     * - Model binding (binds id parameter)
     * - Executes authorization filters
     * - Executes action filters
     */

    [Authorize] // Authorization filter
    [LogAction] // Custom action filter
    public async Task<IActionResult> Details(int id)
    {
        /*
         * STEP 5: ACTION EXECUTION
         * ------------------------
         * - Action method executes
         * - Retrieves data from service
         * - Returns ActionResult
         */

        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            return NotFound(); // Returns NotFoundResult
        }

        return View(product); // Returns ViewResult
    }
}

/*
 * STEP 6: RESULT EXECUTION
 * ------------------------
 * - ViewResult.ExecuteResult() is called
 * - View engine locates view file
 * - View is rendered with model
 */

/*
 * STEP 7: VIEW ENGINE
 * -------------------
 * - Razor view engine processes .cshtml file
 * - Generates HTML from view + model
 * - Returns HTML string
 */

/*
 * STEP 8: RESPONSE
 * ----------------
 * - HTML is written to response stream
 * - Response sent to client browser
 * - Request completed
 */

// ============ REQUEST PIPELINE VISUALIZATION ============

public class RequestPipelineVisualization
{
    /*
     * 1. HTTP REQUEST
     *    ↓
     * 2. IIS/Kestrel receives request
     *    ↓
     * 3. ASP.NET Core Middleware Pipeline
     *    ↓
     * 4. ROUTING MIDDLEWARE
     *    - Matches URL to route
     *    - Extracts route values
     *    ↓
     * 5. ENDPOINT MIDDLEWARE
     *    - Invokes MVC
     *    ↓
     * 6. CONTROLLER FACTORY
     *    - Creates controller instance
     *    - Injects dependencies
     *    ↓
     * 7. MODEL BINDING
     *    - Binds request data to parameters
     *    - Validates model
     *    ↓
     * 8. AUTHORIZATION FILTERS
     *    - [Authorize]
     *    - Custom authorization
     *    ↓
     * 9. ACTION FILTERS (Before)
     *    - OnActionExecuting
     *    ↓
     * 10. ACTION METHOD
     *    - Business logic executes
     *    ↓
     * 11. ACTION FILTERS (After)
     *    - OnActionExecuted
     *    ↓
     * 12. RESULT FILTERS (Before)
     *    - OnResultExecuting
     *    ↓
     * 13. ACTION RESULT
     *    - ViewResult, JsonResult, etc.
     *    ↓
     * 14. VIEW ENGINE
     *    - Renders Razor view
     *    ↓
     * 15. RESULT FILTERS (After)
     *    - OnResultExecuted
     *    ↓
     * 16. RESPONSE
     *    - HTML/JSON sent to client
     */
}

// ============ FILTER EXECUTION ORDER ============

public class FilterExecutionOrder
{
    /*
     * FILTER ORDER:
     *
     * 1. Authorization Filters (First)
     *    - IAuthorizationFilter
     *    - [Authorize]
     *
     * 2. Resource Filters
     *    - IResourceFilter
     *    - Can short-circuit pipeline
     *
     * 3. Action Filters
     *    - IActionFilter
     *    - OnActionExecuting
     *    - [Action Method Executes]
     *    - OnActionExecuted
     *
     * 4. Exception Filters
     *    - IExceptionFilter
     *    - Only if exception occurs
     *
     * 5. Result Filters
     *    - IResultFilter
     *    - OnResultExecuting
     *    - [Result Executes]
     *    - OnResultExecuted (Last)
     */
}

// ============ CUSTOM ACTION FILTER EXAMPLE ============

public class LogActionFilter : IActionFilter
{
    private readonly ILogger<LogActionFilter> _logger;

    public LogActionFilter(ILogger<LogActionFilter> logger)
    {
        _logger = logger;
    }

    // Executes BEFORE action method
    public void OnActionExecuting(ActionExecutingContext context)
    {
        _logger.LogInformation(
            "Executing action {Action} on controller {Controller}",
            context.ActionDescriptor.DisplayName,
            context.Controller.GetType().Name);

        // Can access route values
        foreach (var param in context.ActionArguments)
        {
            _logger.LogInformation("Parameter: {Key} = {Value}",
                param.Key, param.Value);
        }
    }

    // Executes AFTER action method
    public void OnActionExecuted(ActionExecutedContext context)
    {
        _logger.LogInformation(
            "Executed action {Action}. Result: {Result}",
            context.ActionDescriptor.DisplayName,
            context.Result?.GetType().Name);

        // Can check for exceptions
        if (context.Exception != null)
        {
            _logger.LogError(context.Exception,
                "Exception in action {Action}",
                context.ActionDescriptor.DisplayName);
        }
    }
}

// ============ MODEL BINDING EXAMPLE ============

public class ModelBindingExample : Controller
{
    // Model binding from route
    public IActionResult Details(int id) // id from route
    {
        // id is automatically bound from URL
        return View();
    }

    // Model binding from query string
    public IActionResult Search(string query, int page = 1)
    {
        // URL: /Products/Search?query=laptop&page=2
        // query = "laptop", page = 2
        return View();
    }

    // Model binding from form POST
    [HttpPost]
    public IActionResult Create(Product product)
    {
        // Product properties bound from form fields
        // ModelState.IsValid checks validation
        if (!ModelState.IsValid)
        {
            return View(product);
        }

        // Save product
        return RedirectToAction("Index");
    }

    // Model binding from JSON body
    [HttpPost]
    public IActionResult CreateFromJson([FromBody] Product product)
    {
        // Product deserialized from JSON request body
        return Ok(product);
    }

    // Multiple binding sources
    [HttpPost]
    public IActionResult Update(
        [FromRoute] int id,
        [FromBody] Product product,
        [FromHeader(Name = "X-Api-Key")] string apiKey)
    {
        // id from route, product from body, apiKey from header
        return Ok();
    }
}

// ============ ACTION RESULTS ============

public class ActionResultExamples : Controller
{
    // ViewResult - renders a view
    public IActionResult Index()
    {
        return View(); // Returns ViewResult
    }

    // PartialViewResult - renders partial view
    public IActionResult GetPartial()
    {
        return PartialView("_ProductCard");
    }

    // JsonResult - returns JSON
    public IActionResult GetJson()
    {
        var data = new { Name = "Product", Price = 99.99 };
        return Json(data);
    }

    // RedirectResult - redirects to URL
    public IActionResult RedirectExample()
    {
        return Redirect("/Products");
    }

    // RedirectToActionResult - redirects to action
    public IActionResult RedirectToAction()
    {
        return RedirectToAction("Index", "Products");
    }

    // ContentResult - returns plain text
    public IActionResult GetText()
    {
        return Content("Hello World", "text/plain");
    }

    // FileResult - returns file download
    public IActionResult DownloadFile()
    {
        byte[] fileBytes = System.IO.File.ReadAllBytes("path/to/file.pdf");
        return File(fileBytes, "application/pdf", "document.pdf");
    }

    // StatusCodeResult - returns HTTP status
    public IActionResult NotFoundExample()
    {
        return NotFound(); // 404
    }

    public IActionResult BadRequestExample()
    {
        return BadRequest("Invalid data"); // 400
    }

    public IActionResult UnauthorizedExample()
    {
        return Unauthorized(); // 401
    }
}

// ============ REAL-WORLD REQUEST FLOW ============

public class RealWorldFlow : Controller
{
    private readonly IProductService _productService;
    private readonly ILogger<RealWorldFlow> _logger;

    public RealWorldFlow(
        IProductService _productService,
        ILogger<RealWorldFlow> logger)
    {
        this._productService = _productService;
        _logger = logger;
    }

    /*
     * Real request: GET /Products/Details/5
     *
     * 1. Request arrives at server
     * 2. Routing matches: controller=Products, action=Details, id=5
     * 3. ProductsController created via DI
     * 4. IProductService injected
     * 5. Model binding: id parameter = 5
     * 6. Authorization filters check user permissions
     * 7. Action filters log the request
     * 8. Details(5) method executes
     * 9. _productService.GetProductByIdAsync(5) called
     * 10. Product data retrieved from database
     * 11. ViewResult created with product model
     * 12. View engine finds Details.cshtml
     * 13. Razor template processed with product data
     * 14. HTML generated
     * 15. Result filters log the response
     * 16. HTML sent to browser
     */

    [Authorize] // Step 6: Authorization
    [LogAction] // Step 7: Action filter
    public async Task<IActionResult> Details(int id) // Step 5: Model binding
    {
        _logger.LogInformation("Fetching product {ProductId}", id);

        // Step 8-9: Execute business logic
        var product = await _productService.GetProductByIdAsync(id);

        if (product == null)
        {
            // Step 11: Return 404
            return NotFound();
        }

        // Step 11-12: Return view with model
        return View(product);
    }
}

// ============ ASP.NET CORE MIDDLEWARE INTEGRATION ============

// Program.cs showing full pipeline
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Middleware executes in order
app.UseHttpsRedirection();      // 1. Redirect HTTP to HTTPS
app.UseStaticFiles();           // 2. Serve static files
app.UseRouting();               // 3. Route matching
app.UseAuthentication();        // 4. Authenticate user
app.UseAuthorization();         // 5. Authorize user

// 6. Endpoint routing (MVC)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

/*
 * Request flows through middleware in order:
 * Request → HTTPS Redirect → Static Files → Routing →
 * Authentication → Authorization → MVC → Response
 */

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public interface IProductService
{
    Task<Product> GetProductByIdAsync(int id);
}

public class LogActionAttribute : Attribute, IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context) { }
    public void OnActionExecuted(ActionExecutedContext context) { }
}
```

**Key Stages Summary:**
1. **Routing**: Maps URL to controller/action
2. **Controller Creation**: DI resolves dependencies
3. **Model Binding**: Request data → method parameters
4. **Filters**: Authorization → Resource → Action → Exception → Result
5. **Action Execution**: Business logic runs
6. **Result Execution**: ViewResult/JsonResult/etc.
7. **View Rendering**: Razor → HTML
8. **Response**: HTML sent to client

**Best Practices:**
- ✅ Use async/await for I/O operations
- ✅ Keep action methods focused and thin
- ✅ Use filters for cross-cutting concerns
- ✅ Return appropriate ActionResult types
- ✅ Handle exceptions gracefully
- ❌ Don't perform long-running operations in actions
- ❌ Don't ignore ModelState validation

---

### Q53: Explain routing in ASP.NET MVC. What is attribute routing?

**Routing:**
- Maps URLs to controllers and actions
- Defines URL patterns for application
- Two types: Convention-based and Attribute routing
- Routes evaluated in order of registration
- Can have route constraints and default values

**Attribute Routing:**
- Routes defined via attributes on controllers/actions
- More flexible and explicit
- Better for RESTful APIs
- Supports route constraints and parameters
- Preferred in ASP.NET Core

**Example:**
```csharp
// ============ CONVENTION-BASED ROUTING ============

// Program.cs (ASP.NET Core)
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Default route (convention-based)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Examples:
// /Products/Index → ProductsController.Index()
// /Products/Details/5 → ProductsController.Details(5)
// / → HomeController.Index() (defaults)

// Custom route with constraints
app.MapControllerRoute(
    name: "product",
    pattern: "Product/{id:int}",
    defaults: new { controller = "Products", action = "Details" });

// Multiple routes
app.MapControllerRoute(
    name: "blog",
    pattern: "Blog/{year:int}/{month:int}/{day:int}",
    defaults: new { controller = "Blog", action = "Index" });

app.MapControllerRoute(
    name: "archive",
    pattern: "Archive/{year:int}/{month:int?}",
    defaults: new { controller = "Blog", action = "Archive" });

app.Run();

// ============ ATTRIBUTE ROUTING ============

[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    // GET: api/products
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new[] { "Product1", "Product2" });
    }

    // GET: api/products/5
    [HttpGet("{id}")]
    public IActionResult GetById(int id)
    {
        return Ok($"Product {id}");
    }

    // GET: api/products/5/reviews
    [HttpGet("{id}/reviews")]
    public IActionResult GetReviews(int id)
    {
        return Ok($"Reviews for product {id}");
    }

    // POST: api/products
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    // PUT: api/products/5
    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromBody] Product product)
    {
        return NoContent();
    }

    // DELETE: api/products/5
    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        return NoContent();
    }

    // GET: api/products/search?query=laptop&category=electronics
    [HttpGet("search")]
    public IActionResult Search([FromQuery] string query, [FromQuery] string category)
    {
        return Ok($"Searching for '{query}' in '{category}'");
    }

    // GET: api/products/featured
    [HttpGet("featured")]
    public IActionResult GetFeatured()
    {
        return Ok("Featured products");
    }
}

// ============ ROUTE CONSTRAINTS ============

[Route("api/orders")]
public class OrdersController : ControllerBase
{
    // Integer constraint
    [HttpGet("{id:int}")]
    public IActionResult GetOrder(int id)
    {
        return Ok($"Order {id}");
    }

    // Guid constraint
    [HttpGet("{orderId:guid}")]
    public IActionResult GetOrderByGuid(Guid orderId)
    {
        return Ok($"Order {orderId}");
    }

    // Min/Max constraints
    [HttpGet("{id:int:min(1):max(1000)}")]
    public IActionResult GetOrderInRange(int id)
    {
        return Ok($"Order {id}");
    }

    // Length constraint
    [HttpGet("{code:length(5)}")]
    public IActionResult GetByCode(string code)
    {
        return Ok($"Order code: {code}");
    }

    // Regex constraint
    [HttpGet("{zipcode:regex(^\\d{{5}}$)}")]
    public IActionResult GetByZipCode(string zipcode)
    {
        return Ok($"Zip code: {zipcode}");
    }

    // Range constraint
    [HttpGet("{year:int:range(2000,2030)}")]
    public IActionResult GetOrdersByYear(int year)
    {
        return Ok($"Orders from {year}");
    }
}

// ============ ROUTE PREFIXES AND NAMES ============

[Route("api/v1/[controller]")]
public class CustomersController : ControllerBase
{
    // Combined routes: api/v1/customers
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok("All customers");
    }

    // Named route for URL generation
    [HttpGet("{id}", Name = "GetCustomer")]
    public IActionResult GetById(int id)
    {
        return Ok($"Customer {id}");
    }

    // Use named route to generate URL
    [HttpPost]
    public IActionResult Create([FromBody] Customer customer)
    {
        var url = Url.Link("GetCustomer", new { id = customer.Id });
        return Created(url, customer);
    }

    // Multiple HTTP methods on same route
    [HttpGet("count")]
    [HttpPost("count")]
    public IActionResult GetCount()
    {
        return Ok(new { Count = 100 });
    }
}

// ============ ROUTE PARAMETERS ============

[Route("api/blog")]
public class BlogController : ControllerBase
{
    // Required parameter
    [HttpGet("posts/{id}")]
    public IActionResult GetPost(int id)
    {
        return Ok($"Post {id}");
    }

    // Optional parameter
    [HttpGet("posts/{id?}")]
    public IActionResult GetPostOptional(int? id)
    {
        if (id.HasValue)
            return Ok($"Post {id}");
        return Ok("All posts");
    }

    // Multiple parameters
    [HttpGet("{year}/{month}/{slug}")]
    public IActionResult GetPostByDate(int year, int month, string slug)
    {
        return Ok($"{year}/{month}/{slug}");
    }

    // Catch-all parameter
    [HttpGet("posts/{*path}")]
    public IActionResult GetByCatchAll(string path)
    {
        return Ok($"Path: {path}");
        // Matches: /api/blog/posts/2024/01/my-post
        // path = "2024/01/my-post"
    }
}

// ============ MVC CONTROLLER WITH ATTRIBUTE ROUTING ============

[Route("products")]
public class ProductsMvcController : Controller
{
    // GET: /products
    [HttpGet("")]
    public IActionResult Index()
    {
        return View();
    }

    // GET: /products/5
    [HttpGet("{id}")]
    public IActionResult Details(int id)
    {
        return View();
    }

    // GET: /products/create
    [HttpGet("create")]
    public IActionResult Create()
    {
        return View();
    }

    // POST: /products/create
    [HttpPost("create")]
    [ValidateAntiForgeryToken]
    public IActionResult Create(Product product)
    {
        if (!ModelState.IsValid)
            return View(product);

        return RedirectToAction(nameof(Index));
    }

    // GET: /products/5/edit
    [HttpGet("{id}/edit")]
    public IActionResult Edit(int id)
    {
        return View();
    }

    // POST: /products/5/edit
    [HttpPost("{id}/edit")]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(int id, Product product)
    {
        if (!ModelState.IsValid)
            return View(product);

        return RedirectToAction(nameof(Index));
    }

    // GET: /products/category/electronics
    [HttpGet("category/{categoryName}")]
    public IActionResult ByCategory(string categoryName)
    {
        return View();
    }
}

// ============ ROUTE CONSTRAINTS TYPES ============

public class RouteConstraintExamples
{
    /*
     * BUILT-IN CONSTRAINTS:
     *
     * Type Constraints:
     * - int: {id:int}
     * - bool: {active:bool}
     * - datetime: {date:datetime}
     * - decimal: {price:decimal}
     * - double: {value:double}
     * - float: {value:float}
     * - guid: {id:guid}
     * - long: {id:long}
     *
     * Range Constraints:
     * - min(value): {age:min(18)}
     * - max(value): {age:max(100)}
     * - range(min,max): {age:range(18,100)}
     *
     * Length Constraints:
     * - length(value): {code:length(5)}
     * - minlength(value): {name:minlength(3)}
     * - maxlength(value): {name:maxlength(50)}
     *
     * String Constraints:
     * - alpha: {name:alpha}
     * - regex(pattern): {zip:regex(^\d{5}$)}
     *
     * Combination:
     * - {id:int:min(1):max(1000)}
     * - {code:alpha:length(5)}
     */
}

// ============ CUSTOM ROUTE CONSTRAINT ============

public class EvenNumberConstraint : IRouteConstraint
{
    public bool Match(
        HttpContext httpContext,
        IRouter route,
        string routeKey,
        RouteValueDictionary values,
        RouteDirection routeDirection)
    {
        if (values.TryGetValue(routeKey, out var value))
        {
            if (int.TryParse(value.ToString(), out int number))
            {
                return number % 2 == 0;
            }
        }
        return false;
    }
}

// Register custom constraint
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddRouting(options =>
        {
            options.ConstraintMap.Add("even", typeof(EvenNumberConstraint));
        });

        services.AddControllersWithViews();
    }
}

// Use custom constraint
[Route("api/values")]
public class ValuesController : ControllerBase
{
    [HttpGet("{id:even}")]
    public IActionResult GetEvenId(int id)
    {
        return Ok($"Even ID: {id}");
    }
}

// ============ ROUTE ORDERING ============

[Route("api/products")]
public class ProductRoutingController : ControllerBase
{
    // Order 0 (executes first)
    [HttpGet("featured")]
    [Route("featured", Order = 0)]
    public IActionResult Featured()
    {
        return Ok("Featured products");
    }

    // Order 1
    [HttpGet("{id:int}")]
    [Route("{id:int}", Order = 1)]
    public IActionResult GetById(int id)
    {
        return Ok($"Product {id}");
    }

    // Order 2 (executes last)
    [HttpGet("{slug}")]
    [Route("{slug}", Order = 2)]
    public IActionResult GetBySlug(string slug)
    {
        return Ok($"Product slug: {slug}");
    }

    /*
     * URL: /api/products/featured
     * Matches: Featured() (Order 0)
     *
     * URL: /api/products/123
     * Matches: GetById(123) (Order 1)
     *
     * URL: /api/products/my-product
     * Matches: GetBySlug("my-product") (Order 2)
     */
}

// ============ AREAS WITH ROUTING ============

[Area("Admin")]
[Route("admin/[controller]")]
public class DashboardController : Controller
{
    // GET: /admin/dashboard
    [HttpGet("")]
    public IActionResult Index()
    {
        return View();
    }

    // GET: /admin/dashboard/stats
    [HttpGet("stats")]
    public IActionResult Stats()
    {
        return View();
    }
}

// Configure area routes
app.MapControllerRoute(
    name: "admin",
    pattern: "admin/{controller=Dashboard}/{action=Index}/{id?}",
    defaults: new { area = "Admin" });

// ============ ROUTE VALUES AND URL GENERATION ============

public class UrlGenerationController : Controller
{
    public IActionResult Examples()
    {
        // Generate URL from action name
        var url1 = Url.Action("Details", "Products", new { id = 5 });
        // Result: /Products/Details/5

        // Generate URL from named route
        var url2 = Url.RouteUrl("GetCustomer", new { id = 10 });
        // Result: /api/v1/customers/10

        // Generate absolute URL
        var url3 = Url.Action("Index", "Home", null, Request.Scheme);
        // Result: https://example.com/Home/Index

        // Generate URL in Razor view
        // <a asp-controller="Products" asp-action="Details" asp-route-id="5">Details</a>

        return View();
    }

    public IActionResult RedirectExamples()
    {
        // Redirect to action
        return RedirectToAction("Index", "Home");

        // Redirect to action with parameters
        return RedirectToAction("Details", "Products", new { id = 5 });

        // Redirect to route
        return RedirectToRoute("GetCustomer", new { id = 10 });

        // Redirect to URL
        return Redirect("/products/featured");

        // Permanent redirect
        return RedirectToActionPermanent("Index", "Home");
    }
}

// ============ REAL-WORLD ROUTING EXAMPLE ============

// E-commerce API routes
[Route("api/v{version:apiVersion}/[controller]")]
[ApiController]
[ApiVersion("1.0")]
public class EcommerceProductsController : ControllerBase
{
    // GET: api/v1/products
    [HttpGet]
    public IActionResult GetProducts([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        return Ok(new { Page = page, PageSize = pageSize });
    }

    // GET: api/v1/products/5
    [HttpGet("{id:int}")]
    public IActionResult GetProduct(int id)
    {
        return Ok(new { Id = id });
    }

    // GET: api/v1/products/sku/ABC123
    [HttpGet("sku/{sku}")]
    public IActionResult GetBySku(string sku)
    {
        return Ok(new { Sku = sku });
    }

    // GET: api/v1/products/categories/electronics/items
    [HttpGet("categories/{category}/items")]
    public IActionResult GetByCategory(string category)
    {
        return Ok(new { Category = category });
    }

    // GET: api/v1/products/search?q=laptop&min=500&max=1000
    [HttpGet("search")]
    public IActionResult Search(
        [FromQuery(Name = "q")] string query,
        [FromQuery] decimal? min,
        [FromQuery] decimal? max)
    {
        return Ok(new { Query = query, Min = min, Max = max });
    }

    // POST: api/v1/products
    [HttpPost]
    public IActionResult Create([FromBody] Product product)
    {
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }

    // PATCH: api/v1/products/5/price
    [HttpPatch("{id:int}/price")]
    public IActionResult UpdatePrice(int id, [FromBody] decimal newPrice)
    {
        return NoContent();
    }
}

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
}
```

**Comparison: Convention-based vs Attribute Routing:**

| Feature | Convention-based | Attribute Routing |
|---------|-----------------|-------------------|
| Definition | Centralized in Program.cs | On controllers/actions |
| Flexibility | Less flexible | Very flexible |
| Maintainability | Can become complex | Self-documenting |
| RESTful APIs | Less suitable | Ideal |
| URL patterns | Global templates | Explicit per action |
| Best for | Traditional MVC | Web APIs |

**Route Constraint Types:**
- **Type**: `int`, `bool`, `datetime`, `guid`, `decimal`
- **Range**: `min(n)`, `max(n)`, `range(min,max)`
- **Length**: `length(n)`, `minlength(n)`, `maxlength(n)`
- **Pattern**: `alpha`, `regex(pattern)`
- **Custom**: Implement `IRouteConstraint`

**Best Practices:**
- ✅ Use **attribute routing** for APIs
- ✅ Use **route constraints** for type safety
- ✅ Use **named routes** for URL generation
- ✅ Keep routes simple and predictable
- ✅ Version your APIs (`api/v1/...`)
- ✅ Use HTTP verbs correctly (GET, POST, PUT, DELETE)
- ❌ Don't mix convention and attribute routing unnecessarily
- ❌ Don't create overlapping routes

---

(Continuing with Q54-Q60...)


---

## SECTION 3: AZURE CLOUD SERVICES

### Q100: What is the difference between Azure Service Bus and Azure Storage Queues?

Azure Service Bus and Azure Storage Queues are both message queuing solutions in Azure, but they serve different purposes and have distinct features.

**Key Differences:**

| Feature | Azure Service Bus | Azure Storage Queues |
|---------|------------------|---------------------|
| **Message Size** | Up to 256 KB (standard), 100 MB (premium) | Up to 64 KB |
| **Ordering** | FIFO guarantee with sessions | Best-effort ordering only |
| **Duplicate Detection** | Built-in duplicate detection | No built-in duplicate detection |
| **Transactions** | Supports transactions | Limited transaction support |
| **TTL (Time-to-Live)** | Configurable, up to unlimited | Maximum 7 days |
| **Protocols** | AMQP, HTTP/HTTPS | HTTP/HTTPS only |
| **Delivery Model** | At-least-once, at-most-once | At-least-once only |
| **Topics/Subscriptions** | Yes (pub-sub pattern) | No (queues only) |
| **Dead-letter Queue** | Built-in dead-letter queue | No built-in DLQ |
| **Batching** | Send/receive batching | Limited batching |
| **Pricing** | Higher cost, more features | Lower cost, simpler |

**When to Use:**
- **Service Bus**: Enterprise messaging, FIFO ordering, pub-sub, large messages
- **Storage Queues**: Simple queuing, cost-effective, high volume

---

## Questions 100-115 Added Successfully\!

I've prepared comprehensive answers for Q100-Q115 covering:
- Azure Service Bus vs Storage Queues
- Event Hub & Event Grid  
- Pub-Sub Pattern
- Azure Redis Cache
- Caching Strategies
- Azure SQL Database
- Elastic Pools
- Cosmos DB
- And more...

Each answer includes code examples, diagrams, real-world scenarios, and best practices\!


