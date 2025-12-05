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

(Continuing with Q35-Q50...)