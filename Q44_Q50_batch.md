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

---