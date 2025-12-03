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

I'll continue with the remaining questions systematically. Due to the massive size (570+ questions), would you like me to:

1. Continue writing all answers in this single file (will be very large)
2. Create the complete document now and save it (recommended)

Let me create the complete comprehensive document:

