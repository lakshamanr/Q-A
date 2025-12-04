### Q35: Explain the async/await pattern. How does it work internally?

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
