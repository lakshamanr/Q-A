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

### Q54: What are action filters? Explain different types of filters.

**Action Filters:**
- Execute code before/after action execution
- Cross-cutting concerns (logging, caching, authorization)
- Can modify action parameters or results
- Can short-circuit the pipeline
- Applied via attributes
- Execute in specific order

**Filter Types:**
1. **Authorization Filters** - First to run, control access
2. **Resource Filters** - Run before/after rest of pipeline
3. **Action Filters** - Run before/after action method
4. **Exception Filters** - Handle exceptions
5. **Result Filters** - Run before/after result execution

**Example:**
```csharp
// ============ FILTER EXECUTION ORDER ============

/*
 * FILTER PIPELINE ORDER:
 *
 * 1. Authorization Filters (IAuthorizationFilter)
 *    ↓
 * 2. Resource Filters - Before (IResourceFilter.OnResourceExecuting)
 *    ↓
 * 3. Model Binding
 *    ↓
 * 4. Action Filters - Before (IActionFilter.OnActionExecuting)
 *    ↓
 * 5. ACTION METHOD EXECUTES
 *    ↓
 * 6. Action Filters - After (IActionFilter.OnActionExecuted)
 *    ↓
 * 7. Result Filters - Before (IResultFilter.OnResultExecuting)
 *    ↓
 * 8. RESULT EXECUTES
 *    ↓
 * 9. Result Filters - After (IResultFilter.OnResultExecuted)
 *    ↓
 * 10. Resource Filters - After (IResourceFilter.OnResourceExecuted)
 *
 * Exception Filters (IExceptionFilter) run if exception occurs at any point
 */

// ============ 1. AUTHORIZATION FILTERS ============

// Built-in authorization filter
[Authorize] // Requires authenticated user
public class SecureController : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    [Authorize(Roles = "Admin")] // Requires Admin role
    public IActionResult AdminOnly()
    {
        return View();
    }

    [Authorize(Policy = "RequireAdminRole")] // Policy-based
    public IActionResult PolicyBased()
    {
        return View();
    }

    [AllowAnonymous] // Overrides controller-level [Authorize]
    public IActionResult Public()
    {
        return View();
    }
}

// Custom authorization filter
public class CustomAuthorizationFilter : IAuthorizationFilter
{
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        // Check if user is authenticated
        if (!context.HttpContext.User.Identity.IsAuthenticated)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        // Custom authorization logic
        var apiKey = context.HttpContext.Request.Headers["X-API-Key"].ToString();
        if (string.IsNullOrEmpty(apiKey) || !IsValidApiKey(apiKey))
        {
            context.Result = new ForbidResult();
            return;
        }

        // Authorization passed, continue pipeline
    }

    private bool IsValidApiKey(string apiKey)
    {
        // Validate API key
        return apiKey == "valid-key";
    }
}

// ============ 2. RESOURCE FILTERS ============

public class CacheResourceFilter : IResourceFilter
{
    private readonly IMemoryCache _cache;

    public CacheResourceFilter(IMemoryCache cache)
    {
        _cache = cache;
    }

    // Runs BEFORE model binding and action execution
    public void OnResourceExecuting(ResourceExecutingContext context)
    {
        var cacheKey = context.HttpContext.Request.Path.ToString();

        if (_cache.TryGetValue(cacheKey, out object cachedResult))
        {
            // Short-circuit: return cached result, skip action execution
            context.Result = new ObjectResult(cachedResult);
        }
    }

    // Runs AFTER action and result execution
    public void OnResourceExecuted(ResourceExecutedContext context)
    {
        if (context.Result is ObjectResult result)
        {
            var cacheKey = context.HttpContext.Request.Path.ToString();
            _cache.Set(cacheKey, result.Value, TimeSpan.FromMinutes(5));
        }
    }
}

// Short-circuit example
public class ShortCircuitResourceFilter : IResourceFilter
{
    public void OnResourceExecuting(ResourceExecutingContext context)
    {
        // Check maintenance mode
        if (IsMaintenanceMode())
        {
            // Short-circuit pipeline - action never executes
            context.Result = new ContentResult
            {
                Content = "Site under maintenance",
                StatusCode = 503
            };
        }
    }

    public void OnResourceExecuted(ResourceExecutedContext context)
    {
        // Runs after action execution
    }

    private bool IsMaintenanceMode() => false;
}

// ============ 3. ACTION FILTERS ============

public class LogActionFilter : IActionFilter
{
    private readonly ILogger<LogActionFilter> _logger;

    public LogActionFilter(ILogger<LogActionFilter> logger)
    {
        _logger = logger;
    }

    // Runs BEFORE action method
    public void OnActionExecuting(ActionExecutingContext context)
    {
        _logger.LogInformation(
            "Executing {Controller}.{Action}",
            context.RouteData.Values["controller"],
            context.RouteData.Values["action"]);

        // Log parameters
        foreach (var arg in context.ActionArguments)
        {
            _logger.LogDebug("Parameter {Name} = {Value}", arg.Key, arg.Value);
        }

        // Can modify parameters
        if (context.ActionArguments.ContainsKey("id"))
        {
            var id = (int)context.ActionArguments["id"];
            if (id < 0)
            {
                // Short-circuit with error
                context.Result = new BadRequestObjectResult("Invalid ID");
            }
        }
    }

    // Runs AFTER action method
    public void OnActionExecuted(ActionExecutedContext context)
    {
        _logger.LogInformation(
            "Executed {Controller}.{Action} - Result: {Result}",
            context.RouteData.Values["controller"],
            context.RouteData.Values["action"],
            context.Result?.GetType().Name);

        // Check for exceptions
        if (context.Exception != null)
        {
            _logger.LogError(context.Exception, "Action threw exception");
        }
    }
}

// Timing filter
public class TimingActionFilter : IActionFilter
{
    private Stopwatch _stopwatch;

    public void OnActionExecuting(ActionExecutingContext context)
    {
        _stopwatch = Stopwatch.StartNew();
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        _stopwatch.Stop();
        var elapsed = _stopwatch.ElapsedMilliseconds;

        context.HttpContext.Response.Headers.Add(
            "X-Elapsed-Time",
            elapsed.ToString());

        if (elapsed > 1000)
        {
            // Log slow requests
            Console.WriteLine($"Slow request: {elapsed}ms");
        }
    }
}

// ============ 4. EXCEPTION FILTERS ============

public class GlobalExceptionFilter : IExceptionFilter
{
    private readonly ILogger<GlobalExceptionFilter> _logger;

    public GlobalExceptionFilter(ILogger<GlobalExceptionFilter> logger)
    {
        _logger = logger;
    }

    public void OnException(ExceptionContext context)
    {
        _logger.LogError(context.Exception, "Unhandled exception occurred");

        // Create error response
        var result = new ObjectResult(new
        {
            Error = "An error occurred processing your request",
            Message = context.Exception.Message,
            TraceId = Activity.Current?.Id ?? context.HttpContext.TraceIdentifier
        })
        {
            StatusCode = 500
        };

        // Mark exception as handled
        context.Result = result;
        context.ExceptionHandled = true;
    }
}

// Specific exception handler
public class ValidationExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is ValidationException validationEx)
        {
            context.Result = new BadRequestObjectResult(new
            {
                Error = "Validation failed",
                Errors = validationEx.Errors
            });

            context.ExceptionHandled = true;
        }
    }
}

// ============ 5. RESULT FILTERS ============

public class AddHeaderResultFilter : IResultFilter
{
    // Runs BEFORE result execution
    public void OnResultExecuting(ResultExecutingContext context)
    {
        // Add custom headers to response
        context.HttpContext.Response.Headers.Add("X-Custom-Header", "Value");
        context.HttpContext.Response.Headers.Add("X-Powered-By", "ASP.NET Core");
    }

    // Runs AFTER result execution
    public void OnResultExecuted(ResultExecutedContext context)
    {
        // Log result execution
        Console.WriteLine($"Result executed: {context.Result.GetType().Name}");
    }
}

// Format result filter
public class JsonFormattingResultFilter : IResultFilter
{
    public void OnResultExecuting(ResultExecutingContext context)
    {
        if (context.Result is ObjectResult objectResult)
        {
            // Modify result formatting
            objectResult.StatusCode = 200;
            objectResult.Value = new
            {
                Success = true,
                Data = objectResult.Value,
                Timestamp = DateTime.UtcNow
            };
        }
    }

    public void OnResultExecuted(ResultExecutedContext context)
    {
    }
}

// ============ ASYNC FILTERS ============

public class AsyncActionFilter : IAsyncActionFilter
{
    private readonly ILogger<AsyncActionFilter> _logger;

    public AsyncActionFilter(ILogger<AsyncActionFilter> logger)
    {
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // Before action execution
        _logger.LogInformation("Before action");

        // Execute action
        var resultContext = await next();

        // After action execution
        _logger.LogInformation("After action");

        if (resultContext.Exception != null)
        {
            _logger.LogError(resultContext.Exception, "Action failed");
        }
    }
}

public class AsyncResultFilter : IAsyncResultFilter
{
    public async Task OnResultExecutionAsync(
        ResultExecutingContext context,
        ResultExecutionDelegate next)
    {
        // Before result execution
        Console.WriteLine("Before result");

        // Execute result
        await next();

        // After result execution
        Console.WriteLine("After result");
    }
}

// ============ FILTER ATTRIBUTES ============

// Action filter as attribute
public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
        {
            context.Result = new BadRequestObjectResult(context.ModelState);
        }
    }
}

// Usage
[ValidateModel]
public class ProductsController : Controller
{
    [HttpPost]
    public IActionResult Create(Product product)
    {
        // ModelState is guaranteed to be valid
        return Ok(product);
    }
}

// Result filter as attribute
public class FormatResponseAttribute : ResultFilterAttribute
{
    public override void OnResultExecuting(ResultExecutingContext context)
    {
        if (context.Result is ObjectResult result)
        {
            result.Value = new
            {
                Success = true,
                Data = result.Value
            };
        }
    }
}

// ============ FILTER SCOPE ============

// Global filter (applies to all actions)
builder.Services.AddControllers(options =>
{
    options.Filters.Add<LogActionFilter>();
    options.Filters.Add<GlobalExceptionFilter>();
    options.Filters.Add(new TimingActionFilter());
});

// Controller-level filter
[ServiceFilter(typeof(LogActionFilter))]
public class HomeController : Controller
{
    // Action-level filter
    [TypeFilter(typeof(CacheResourceFilter))]
    public IActionResult Index()
    {
        return View();
    }

    // Multiple filters
    [ValidateModel]
    [FormatResponse]
    public IActionResult Create(Product product)
    {
        return Ok(product);
    }
}

// ============ FILTER ORDER ============

// Control filter execution order
[ServiceFilter(typeof(LogActionFilter), Order = 1)]
[TypeFilter(typeof(TimingActionFilter), Order = 2)]
public class OrderedController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}

// ============ DEPENDENCY INJECTION IN FILTERS ============

// ServiceFilter - filter registered in DI
public class DiActionFilter : IActionFilter
{
    private readonly IMyService _service;

    public DiActionFilter(IMyService service)
    {
        _service = service;
    }

    public void OnActionExecuting(ActionExecutingContext context)
    {
        _service.DoSomething();
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
    }
}

// Register filter
builder.Services.AddScoped<DiActionFilter>();

// Use with ServiceFilter
[ServiceFilter(typeof(DiActionFilter))]
public class MyController : Controller { }

// TypeFilter - creates new instance each time
[TypeFilter(typeof(DiActionFilter))]
public class AnotherController : Controller { }

// ============ REAL-WORLD EXAMPLES ============

// Example 1: API versioning filter
public class ApiVersionFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        var version = context.HttpContext.Request.Headers["api-version"].ToString();

        if (string.IsNullOrEmpty(version))
        {
            context.Result = new BadRequestObjectResult("API version required");
        }
        else if (version != "1.0" && version != "2.0")
        {
            context.Result = new BadRequestObjectResult("Unsupported API version");
        }
    }

    public void OnActionExecuted(ActionExecutedContext context) { }
}

// Example 2: Rate limiting filter
public class RateLimitFilter : IAsyncActionFilter
{
    private readonly IMemoryCache _cache;
    private const int MaxRequests = 100;
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(1);

    public RateLimitFilter(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var ipAddress = context.HttpContext.Connection.RemoteIpAddress?.ToString();
        var cacheKey = $"ratelimit_{ipAddress}";

        if (!_cache.TryGetValue(cacheKey, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= MaxRequests)
        {
            context.Result = new StatusCodeResult(429); // Too Many Requests
            return;
        }

        _cache.Set(cacheKey, requestCount + 1, Window);

        await next();
    }
}

// Example 3: Transaction filter
public class TransactionFilter : IAsyncActionFilter
{
    private readonly DbContext _context;

    public TransactionFilter(DbContext context)
    {
        _context = context;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            var result = await next();

            if (result.Exception == null)
            {
                await transaction.CommitAsync();
            }
            else
            {
                await transaction.RollbackAsync();
            }
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}

// ============ SUPPORTING CLASSES ============

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}

public class ValidationException : Exception
{
    public List<string> Errors { get; set; }
}

public interface IMyService
{
    void DoSomething();
}
```

**Filter Types Summary:**

| Filter Type | Interface | When It Runs | Use Case |
|------------|-----------|--------------|----------|
| Authorization | IAuthorizationFilter | First | Access control |
| Resource | IResourceFilter | Before/after pipeline | Caching, short-circuit |
| Action | IActionFilter | Before/after action | Logging, validation |
| Exception | IExceptionFilter | On exception | Error handling |
| Result | IResultFilter | Before/after result | Format response, headers |

**Filter Scope:**
- **Global**: Applied to all actions
- **Controller**: Applied to all actions in controller
- **Action**: Applied to specific action
- **Order**: Controlled via Order property

**Best Practices:**
- ✅ Use **authorization filters** for security
- ✅ Use **action filters** for logging and validation
- ✅ Use **exception filters** for centralized error handling
- ✅ Use **result filters** to modify responses
- ✅ Use **async filters** for I/O operations
- ✅ Register filters globally for cross-cutting concerns
- ❌ Don't put business logic in filters
- ❌ Don't create filters with side effects

---

## Q55: How do you implement custom action filters?

**Answer:**

Custom action filters allow you to encapsulate reusable logic that executes before or after action methods. You can create custom filters by implementing filter interfaces or deriving from attribute classes.

### 1. Synchronous Action Filter (Attribute-Based)

```csharp
// Simple custom action filter
public class CustomActionFilterAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        // Execute before the action method
        Console.WriteLine($"Before action: {context.ActionDescriptor.DisplayName}");

        // You can modify the context or short-circuit
        if (!context.ModelState.IsValid)
        {
            context.Result = new BadRequestObjectResult(context.ModelState);
        }

        base.OnActionExecuting(context);
    }

    public override void OnActionExecuted(ActionExecutedContext context)
    {
        // Execute after the action method
        Console.WriteLine($"After action: {context.ActionDescriptor.DisplayName}");

        base.OnActionExecuted(context);
    }
}

// Usage
[CustomActionFilter]
public class ProductsController : Controller
{
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok();
    }
}
```

### 2. Async Action Filter

```csharp
public class AsyncActionFilterAttribute : Attribute, IAsyncActionFilter
{
    private readonly ILogger<AsyncActionFilterAttribute> _logger;

    public AsyncActionFilterAttribute(ILogger<AsyncActionFilterAttribute> logger)
    {
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // Before action execution
        _logger.LogInformation("Before action execution");

        var stopwatch = Stopwatch.StartNew();

        // Execute the action
        var resultContext = await next();

        stopwatch.Stop();

        // After action execution
        _logger.LogInformation(
            "Action executed in {ElapsedMilliseconds}ms",
            stopwatch.ElapsedMilliseconds);

        if (resultContext.Exception != null)
        {
            _logger.LogError(
                resultContext.Exception,
                "Exception occurred during action execution");
        }
    }
}
```

### 3. Logging Filter with Dependency Injection

```csharp
public class LoggingActionFilter : IActionFilter
{
    private readonly ILogger<LoggingActionFilter> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public LoggingActionFilter(
        ILogger<LoggingActionFilter> logger,
        IHttpContextAccessor httpContextAccessor)
    {
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
    }

    public void OnActionExecuting(ActionExecutingContext context)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        var request = httpContext.Request;

        _logger.LogInformation(
            "Executing {Controller}.{Action} - Method: {Method}, Path: {Path}, User: {User}",
            context.RouteData.Values["controller"],
            context.RouteData.Values["action"],
            request.Method,
            request.Path,
            httpContext.User?.Identity?.Name ?? "Anonymous");

        // Log action parameters
        foreach (var param in context.ActionArguments)
        {
            _logger.LogDebug(
                "Parameter {ParameterName}: {ParameterValue}",
                param.Key,
                JsonSerializer.Serialize(param.Value));
        }
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        if (context.Result is ObjectResult objectResult)
        {
            _logger.LogInformation(
                "Action executed - Status: {StatusCode}, ResultType: {ResultType}",
                objectResult.StatusCode,
                objectResult.Value?.GetType().Name);
        }

        if (context.Exception != null)
        {
            _logger.LogError(
                context.Exception,
                "Exception in {Controller}.{Action}",
                context.RouteData.Values["controller"],
                context.RouteData.Values["action"]);
        }
    }
}

// Register globally
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddScoped<LoggingActionFilter>();

        services.AddControllers(options =>
        {
            options.Filters.AddService<LoggingActionFilter>();
        });
    }
}
```

### 4. Validation Filter

```csharp
public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
        {
            var errors = context.ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .Select(x => new
                {
                    Field = x.Key,
                    Errors = x.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                })
                .ToList();

            var result = new
            {
                Message = "Validation failed",
                Errors = errors
            };

            context.Result = new BadRequestObjectResult(result);
        }
    }
}

// Usage
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpPost]
    [ValidateModel]
    public IActionResult Create([FromBody] UserDto user)
    {
        // Model is already validated by the filter
        return Ok(user);
    }
}
```

### 5. Performance Monitoring Filter

```csharp
public class PerformanceMonitoringFilter : IAsyncActionFilter
{
    private readonly ILogger<PerformanceMonitoringFilter> _logger;
    private readonly IMetricsService _metricsService;
    private const int WarningThresholdMs = 1000;

    public PerformanceMonitoringFilter(
        ILogger<PerformanceMonitoringFilter> logger,
        IMetricsService metricsService)
    {
        _logger = logger;
        _metricsService = metricsService;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var stopwatch = Stopwatch.StartNew();
        var actionName = $"{context.Controller.GetType().Name}.{context.ActionDescriptor.DisplayName}";

        try
        {
            var resultContext = await next();
            stopwatch.Stop();

            var elapsed = stopwatch.ElapsedMilliseconds;

            // Record metrics
            await _metricsService.RecordActionDuration(actionName, elapsed);

            // Log warning for slow actions
            if (elapsed > WarningThresholdMs)
            {
                _logger.LogWarning(
                    "Slow action detected: {ActionName} took {ElapsedMs}ms",
                    actionName,
                    elapsed);
            }
            else
            {
                _logger.LogInformation(
                    "Action {ActionName} executed in {ElapsedMs}ms",
                    actionName,
                    elapsed);
            }
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(
                ex,
                "Action {ActionName} failed after {ElapsedMs}ms",
                actionName,
                stopwatch.ElapsedMilliseconds);
            throw;
        }
    }
}
```

### 6. Caching Filter

```csharp
public class CacheActionFilter : IAsyncActionFilter
{
    private readonly IMemoryCache _cache;
    private readonly int _durationSeconds;

    public CacheActionFilter(IMemoryCache cache, int durationSeconds = 60)
    {
        _cache = cache;
        _durationSeconds = durationSeconds;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // Generate cache key from route and query string
        var request = context.HttpContext.Request;
        var cacheKey = $"{request.Path}{request.QueryString}";

        // Try to get from cache
        if (_cache.TryGetValue(cacheKey, out ObjectResult cachedResult))
        {
            context.Result = cachedResult;
            return;
        }

        // Execute action
        var executedContext = await next();

        // Cache the result
        if (executedContext.Result is ObjectResult result && result.StatusCode == 200)
        {
            _cache.Set(cacheKey, result, TimeSpan.FromSeconds(_durationSeconds));
        }
    }
}

// Attribute version
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class CacheAttribute : Attribute, IFilterFactory
{
    public int DurationSeconds { get; set; } = 60;
    public bool IsReusable => true;

    public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
    {
        var cache = serviceProvider.GetRequiredService<IMemoryCache>();
        return new CacheActionFilter(cache, DurationSeconds);
    }
}

// Usage
[HttpGet]
[Cache(DurationSeconds = 300)]
public async Task<IActionResult> GetProducts()
{
    var products = await _productService.GetAllAsync();
    return Ok(products);
}
```

### 7. Transaction Filter

```csharp
public class TransactionFilter : IAsyncActionFilter
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<TransactionFilter> _logger;

    public TransactionFilter(
        ApplicationDbContext context,
        ILogger<TransactionFilter> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // Only apply to POST, PUT, DELETE
        var method = context.HttpContext.Request.Method;
        if (method == "GET" || method == "HEAD")
        {
            await next();
            return;
        }

        await using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            var resultContext = await next();

            if (resultContext.Exception == null)
            {
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                _logger.LogInformation("Transaction committed successfully");
            }
            else
            {
                await transaction.RollbackAsync();

                _logger.LogError(
                    resultContext.Exception,
                    "Transaction rolled back due to exception");
            }
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();

            _logger.LogError(ex, "Transaction rolled back due to exception");
            throw;
        }
    }
}

// Usage
[HttpPost]
[ServiceFilter(typeof(TransactionFilter))]
public async Task<IActionResult> CreateOrder([FromBody] OrderDto order)
{
    // All database operations will be wrapped in a transaction
    var newOrder = await _orderService.CreateAsync(order);
    await _inventoryService.UpdateStockAsync(order.Items);

    return Ok(newOrder);
}
```

### 8. Rate Limiting Filter

```csharp
public class RateLimitAttribute : Attribute, IAsyncActionFilter
{
    private static readonly ConcurrentDictionary<string, (int Count, DateTime ResetTime)> _requestCounts
        = new ConcurrentDictionary<string, (int, DateTime)>();

    public int MaxRequests { get; set; } = 100;
    public int WindowSeconds { get; set; } = 60;

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var httpContext = context.HttpContext;
        var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var endpoint = $"{httpContext.Request.Method}:{httpContext.Request.Path}";
        var key = $"{ipAddress}:{endpoint}";

        var now = DateTime.UtcNow;
        var window = TimeSpan.FromSeconds(WindowSeconds);

        var (count, resetTime) = _requestCounts.AddOrUpdate(
            key,
            _ => (1, now.Add(window)),
            (_, current) =>
            {
                if (now >= current.ResetTime)
                {
                    return (1, now.Add(window));
                }
                return (current.Count + 1, current.ResetTime);
            });

        // Set rate limit headers
        httpContext.Response.Headers["X-Rate-Limit-Limit"] = MaxRequests.ToString();
        httpContext.Response.Headers["X-Rate-Limit-Remaining"] =
            Math.Max(0, MaxRequests - count).ToString();
        httpContext.Response.Headers["X-Rate-Limit-Reset"] =
            new DateTimeOffset(resetTime).ToUnixTimeSeconds().ToString();

        if (count > MaxRequests)
        {
            context.Result = new ObjectResult(new
            {
                Message = "Rate limit exceeded",
                RetryAfter = (resetTime - now).TotalSeconds
            })
            {
                StatusCode = 429
            };

            httpContext.Response.Headers["Retry-After"] =
                ((int)(resetTime - now).TotalSeconds).ToString();

            return;
        }

        await next();
    }
}

// Usage
[HttpGet]
[RateLimit(MaxRequests = 10, WindowSeconds = 60)]
public IActionResult GetSensitiveData()
{
    return Ok("Sensitive data");
}
```

### 9. Authorization Filter

```csharp
public class ApiKeyAuthorizationFilter : IAuthorizationFilter
{
    private readonly IConfiguration _configuration;
    private const string ApiKeyHeaderName = "X-Api-Key";

    public ApiKeyAuthorizationFilter(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        if (!context.HttpContext.Request.Headers.TryGetValue(
            ApiKeyHeaderName, out var extractedApiKey))
        {
            context.Result = new UnauthorizedObjectResult(new
            {
                Message = "API Key is missing"
            });
            return;
        }

        var apiKey = _configuration.GetValue<string>("ApiKey");

        if (!apiKey.Equals(extractedApiKey))
        {
            context.Result = new UnauthorizedObjectResult(new
            {
                Message = "Invalid API Key"
            });
            return;
        }

        // Authorization successful
    }
}

// Attribute version
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ApiKeyAuthorizeAttribute : Attribute, IFilterFactory
{
    public bool IsReusable => false;

    public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
    {
        var configuration = serviceProvider.GetRequiredService<IConfiguration>();
        return new ApiKeyAuthorizationFilter(configuration);
    }
}

// Usage
[ApiController]
[Route("api/[controller]")]
[ApiKeyAuthorize]
public class SecureController : ControllerBase
{
    [HttpGet]
    public IActionResult GetData()
    {
        return Ok("Secure data");
    }
}
```

### 10. Exception Filter

```csharp
public class GlobalExceptionFilter : IExceptionFilter
{
    private readonly ILogger<GlobalExceptionFilter> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionFilter(
        ILogger<GlobalExceptionFilter> logger,
        IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    public void OnException(ExceptionContext context)
    {
        _logger.LogError(
            context.Exception,
            "Unhandled exception occurred: {Message}",
            context.Exception.Message);

        var statusCode = context.Exception switch
        {
            ArgumentException => StatusCodes.Status400BadRequest,
            UnauthorizedAccessException => StatusCodes.Status401Unauthorized,
            KeyNotFoundException => StatusCodes.Status404NotFound,
            InvalidOperationException => StatusCodes.Status409Conflict,
            _ => StatusCodes.Status500InternalServerError
        };

        var response = new
        {
            Message = context.Exception.Message,
            Type = context.Exception.GetType().Name,
            StackTrace = _environment.IsDevelopment()
                ? context.Exception.StackTrace
                : null
        };

        context.Result = new ObjectResult(response)
        {
            StatusCode = statusCode
        };

        context.ExceptionHandled = true;
    }
}

// Register globally
services.AddControllers(options =>
{
    options.Filters.Add<GlobalExceptionFilter>();
});
```

### 11. Result Filter (Response Formatting)

```csharp
public class JsonResultFilter : IResultFilter
{
    public void OnResultExecuting(ResultExecutingContext context)
    {
        if (context.Result is ObjectResult objectResult)
        {
            var wrappedResult = new
            {
                Success = true,
                Data = objectResult.Value,
                Timestamp = DateTime.UtcNow,
                RequestId = context.HttpContext.TraceIdentifier
            };

            objectResult.Value = wrappedResult;
        }
    }

    public void OnResultExecuted(ResultExecutedContext context)
    {
        // After result execution
    }
}

// Usage
[HttpGet]
[ServiceFilter(typeof(JsonResultFilter))]
public IActionResult GetData()
{
    return Ok(new { Name = "Test" });
}

// Response:
// {
//   "success": true,
//   "data": { "name": "Test" },
//   "timestamp": "2024-01-15T10:30:00Z",
//   "requestId": "0HN1234567890"
// }
```

### 12. Custom Filter with Parameters

```csharp
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePermissionAttribute : Attribute, IAsyncAuthorizationFilter
{
    private readonly string _permission;

    public RequirePermissionAttribute(string permission)
    {
        _permission = permission;
    }

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;

        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        // Get user permissions from claims or database
        var permissionService = context.HttpContext.RequestServices
            .GetRequiredService<IPermissionService>();

        var userId = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var hasPermission = await permissionService.HasPermissionAsync(userId, _permission);

        if (!hasPermission)
        {
            context.Result = new ForbidResult();
        }
    }
}

// Usage
[HttpDelete("{id}")]
[RequirePermission("Products.Delete")]
public async Task<IActionResult> Delete(int id)
{
    await _productService.DeleteAsync(id);
    return NoContent();
}
```

### 13. Resource Filter (Short-Circuit)

```csharp
public class ShortCircuitResourceFilter : IResourceFilter
{
    private readonly IFeatureManager _featureManager;

    public ShortCircuitResourceFilter(IFeatureManager featureManager)
    {
        _featureManager = featureManager;
    }

    public void OnResourceExecuting(ResourceExecutingContext context)
    {
        // Check feature flag
        if (!_featureManager.IsEnabledAsync("NewApiFeature").Result)
        {
            context.Result = new ObjectResult(new
            {
                Message = "This feature is currently disabled"
            })
            {
                StatusCode = StatusCodes.Status503ServiceUnavailable
            };
        }
    }

    public void OnResourceExecuted(ResourceExecutedContext context)
    {
        // After resource execution
    }
}
```

### 14. Filter Order Control

```csharp
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, AllowMultiple = true)]
public class OrderedActionFilterAttribute : ActionFilterAttribute
{
    public string Name { get; set; }

    public OrderedActionFilterAttribute(string name, int order)
    {
        Name = name;
        Order = order;
    }

    public override void OnActionExecuting(ActionExecutingContext context)
    {
        Console.WriteLine($"[{Order}] {Name} - OnActionExecuting");
    }

    public override void OnActionExecuted(ActionExecutedContext context)
    {
        Console.WriteLine($"[{Order}] {Name} - OnActionExecuted");
    }
}

// Usage
[HttpGet]
[OrderedActionFilter("First", 1)]
[OrderedActionFilter("Second", 2)]
[OrderedActionFilter("Third", 3)]
public IActionResult GetOrdered()
{
    Console.WriteLine("Action executing");
    return Ok();
}

// Output:
// [1] First - OnActionExecuting
// [2] Second - OnActionExecuting
// [3] Third - OnActionExecuting
// Action executing
// [3] Third - OnActionExecuted
// [2] Second - OnActionExecuted
// [1] First - OnActionExecuted
```

### 15. Type Filter Factory

```csharp
public class ConfigurableLoggingFilter : IActionFilter
{
    private readonly ILogger _logger;
    private readonly string _logLevel;

    public ConfigurableLoggingFilter(ILoggerFactory loggerFactory, string logLevel)
    {
        _logger = loggerFactory.CreateLogger<ConfigurableLoggingFilter>();
        _logLevel = logLevel;
    }

    public void OnActionExecuting(ActionExecutingContext context)
    {
        Log($"Executing {context.ActionDescriptor.DisplayName}");
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        Log($"Executed {context.ActionDescriptor.DisplayName}");
    }

    private void Log(string message)
    {
        switch (_logLevel.ToLower())
        {
            case "debug":
                _logger.LogDebug(message);
                break;
            case "info":
                _logger.LogInformation(message);
                break;
            case "warning":
                _logger.LogWarning(message);
                break;
        }
    }
}

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ConfigurableLoggingAttribute : Attribute, IFilterFactory
{
    public string LogLevel { get; set; } = "Info";
    public bool IsReusable => false;

    public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
    {
        var loggerFactory = serviceProvider.GetRequiredService<ILoggerFactory>();
        return new ConfigurableLoggingFilter(loggerFactory, LogLevel);
    }
}

// Usage
[HttpGet]
[ConfigurableLogging(LogLevel = "Debug")]
public IActionResult GetData()
{
    return Ok();
}
```

### 16. Async Exception Filter

```csharp
public class AsyncExceptionFilter : IAsyncExceptionFilter
{
    private readonly ILogger<AsyncExceptionFilter> _logger;
    private readonly IEmailService _emailService;

    public AsyncExceptionFilter(
        ILogger<AsyncExceptionFilter> logger,
        IEmailService emailService)
    {
        _logger = logger;
        _emailService = emailService;
    }

    public async Task OnExceptionAsync(ExceptionContext context)
    {
        _logger.LogError(context.Exception, "Unhandled exception occurred");

        // Send notification for critical errors
        if (context.Exception is CriticalException)
        {
            await _emailService.SendErrorNotificationAsync(
                "Critical Error",
                context.Exception.ToString());
        }

        context.Result = new ObjectResult(new
        {
            Message = "An error occurred processing your request",
            TraceId = context.HttpContext.TraceIdentifier
        })
        {
            StatusCode = StatusCodes.Status500InternalServerError
        };

        context.ExceptionHandled = true;
    }
}
```

### 17. Correlation ID Filter

```csharp
public class CorrelationIdFilter : IActionFilter
{
    private const string CorrelationIdHeader = "X-Correlation-ID";

    public void OnActionExecuting(ActionExecutingContext context)
    {
        var correlationId = GetOrCreateCorrelationId(context.HttpContext);

        // Add to response headers
        context.HttpContext.Response.Headers[CorrelationIdHeader] = correlationId;

        // Add to HttpContext items for use in controllers
        context.HttpContext.Items[CorrelationIdHeader] = correlationId;
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        // No action needed
    }

    private string GetOrCreateCorrelationId(HttpContext httpContext)
    {
        if (httpContext.Request.Headers.TryGetValue(
            CorrelationIdHeader, out var correlationId))
        {
            return correlationId.ToString();
        }

        return Guid.NewGuid().ToString();
    }
}
```

### 18. Request/Response Logging Filter

```csharp
public class RequestResponseLoggingFilter : IAsyncActionFilter
{
    private readonly ILogger<RequestResponseLoggingFilter> _logger;

    public RequestResponseLoggingFilter(ILogger<RequestResponseLoggingFilter> logger)
    {
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // Log request
        var request = context.HttpContext.Request;
        _logger.LogInformation(
            "Request: {Method} {Path} {QueryString}",
            request.Method,
            request.Path,
            request.QueryString);

        // Read request body if present
        if (request.ContentLength > 0)
        {
            request.EnableBuffering();
            using var reader = new StreamReader(
                request.Body,
                encoding: Encoding.UTF8,
                detectEncodingFromByteOrderMarks: false,
                leaveOpen: true);

            var body = await reader.ReadToEndAsync();
            request.Body.Position = 0;

            _logger.LogDebug("Request Body: {Body}", body);
        }

        var resultContext = await next();

        // Log response
        if (resultContext.Result is ObjectResult objectResult)
        {
            _logger.LogInformation(
                "Response: {StatusCode} {ResultType}",
                objectResult.StatusCode,
                objectResult.Value?.GetType().Name);

            _logger.LogDebug(
                "Response Body: {Body}",
                JsonSerializer.Serialize(objectResult.Value));
        }
    }
}
```

### 19. Multiple Filter Combination

```csharp
// Combine multiple filters
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class SecureApiAttribute : Attribute, IFilterFactory
{
    public bool IsReusable => false;

    public IFilterMetadata CreateInstance(IServiceProvider serviceProvider)
    {
        return new CompositeFilter(new IFilterMetadata[]
        {
            new ApiKeyAuthorizationFilter(
                serviceProvider.GetRequiredService<IConfiguration>()),
            new RateLimitAttribute { MaxRequests = 100, WindowSeconds = 60 },
            new LoggingActionFilter(
                serviceProvider.GetRequiredService<ILogger<LoggingActionFilter>>(),
                serviceProvider.GetRequiredService<IHttpContextAccessor>()),
            new PerformanceMonitoringFilter(
                serviceProvider.GetRequiredService<ILogger<PerformanceMonitoringFilter>>(),
                serviceProvider.GetRequiredService<IMetricsService>())
        });
    }
}

// Usage
[HttpGet]
[SecureApi]
public IActionResult GetSecureData()
{
    return Ok("Secure data with multiple protections");
}
```

### 20. Filter Registration Methods

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Register filter dependencies
        services.AddScoped<LoggingActionFilter>();
        services.AddScoped<TransactionFilter>();
        services.AddScoped<PerformanceMonitoringFilter>();

        services.AddControllers(options =>
        {
            // Global filters - applied to all actions
            options.Filters.Add<GlobalExceptionFilter>();
            options.Filters.Add<CorrelationIdFilter>();

            // Service filters - with DI
            options.Filters.AddService<LoggingActionFilter>();

            // Type filters
            options.Filters.Add(typeof(PerformanceMonitoringFilter));

            // Instance filters
            options.Filters.Add(new ValidateModelAttribute());
        });
    }
}

// Controller-level registration
[ServiceFilter(typeof(TransactionFilter))]
public class OrdersController : ControllerBase
{
    // All actions will use TransactionFilter
}

// Action-level registration
public class ProductsController : ControllerBase
{
    [ServiceFilter(typeof(LoggingActionFilter))]
    [TypeFilter(typeof(PerformanceMonitoringFilter))]
    public IActionResult GetProduct(int id)
    {
        return Ok();
    }
}
```

**Filter Implementation Summary:**

| Approach | Pros | Cons | Use Case |
|----------|------|------|----------|
| ActionFilterAttribute | Simple, no DI needed | No constructor DI | Simple scenarios |
| IActionFilter | Full control | Requires registration | Complex logic |
| IAsyncActionFilter | Async support | More complex | I/O operations |
| IFilterFactory | DI support | More boilerplate | Configurable filters |
| ServiceFilter | Full DI | Requires registration | Filters with dependencies |
| TypeFilter | DI without registration | Creates new instance | One-off filters |

**Best Practices:**
- ✅ Use **async filters** for I/O operations
- ✅ Use **IFilterFactory** for filters with configuration
- ✅ Register reusable filters **globally**
- ✅ Use **ServiceFilter** for filters with dependencies
- ✅ Implement **proper exception handling**
- ✅ Set **Order property** for execution sequence
- ✅ Use **short-circuiting** to stop pipeline early
- ❌ Don't put business logic in filters
- ❌ Don't create filters with heavy dependencies
- ❌ Don't modify request/response inappropriately

---

## Q56: What is the difference between ViewBag, ViewData, and TempData?

**Answer:**

ViewBag, ViewData, and TempData are mechanisms to pass data from controllers to views in ASP.NET MVC. They differ in syntax, type safety, lifetime, and use cases.

### 1. ViewData - Dictionary-Based

```csharp
// Controller
public class HomeController : Controller
{
    public IActionResult Index()
    {
        // Store data using string keys
        ViewData["Title"] = "Home Page";
        ViewData["CurrentUser"] = "John Doe";
        ViewData["ItemCount"] = 42;
        ViewData["Products"] = new List<Product>
        {
            new Product { Id = 1, Name = "Laptop" },
            new Product { Id = 2, Name = "Mouse" }
        };

        return View();
    }
}

// View (Index.cshtml)
@{
    // Retrieve data with type casting
    var title = ViewData["Title"] as string;
    var user = ViewData["CurrentUser"] as string;
    var count = (int)ViewData["ItemCount"];
    var products = ViewData["Products"] as List<Product>;
}

<h1>@title</h1>
<p>Welcome, @user</p>
<p>Items: @count</p>

@foreach (var product in products)
{
    <div>@product.Name</div>
}
```

### 2. ViewBag - Dynamic Property

```csharp
// Controller
public class HomeController : Controller
{
    public IActionResult Index()
    {
        // Store data using dynamic properties
        ViewBag.Title = "Home Page";
        ViewBag.CurrentUser = "John Doe";
        ViewBag.ItemCount = 42;
        ViewBag.Products = new List<Product>
        {
            new Product { Id = 1, Name = "Laptop" },
            new Product { Id = 2, Name = "Mouse" }
        };

        // Can store complex objects
        ViewBag.UserInfo = new
        {
            Name = "John",
            Email = "john@example.com",
            Age = 30
        };

        return View();
    }
}

// View (Index.cshtml)
@{
    // Access directly without casting (dynamic)
    var title = ViewBag.Title;
    var user = ViewBag.CurrentUser;
    var count = ViewBag.ItemCount;
}

<h1>@ViewBag.Title</h1>
<p>Welcome, @ViewBag.CurrentUser</p>
<p>Items: @ViewBag.ItemCount</p>

@foreach (var product in ViewBag.Products)
{
    <div>@product.Name</div>
}

<div>
    Name: @ViewBag.UserInfo.Name<br/>
    Email: @ViewBag.UserInfo.Email
</div>
```

### 3. TempData - Session-Based

```csharp
// Controller - First Request
public class HomeController : Controller
{
    public IActionResult CreateOrder()
    {
        // Process order...
        var order = new Order { Id = 123, Total = 99.99m };

        // Store in TempData (persists across redirect)
        TempData["OrderId"] = order.Id;
        TempData["Message"] = "Order created successfully!";
        TempData["OrderDetails"] = order;

        // Redirect to confirmation page
        return RedirectToAction("Confirmation");
    }

    public IActionResult Confirmation()
    {
        // Retrieve data from TempData
        var orderId = TempData["OrderId"];
        var message = TempData["Message"];
        var order = TempData["OrderDetails"] as Order;

        // TempData is cleared after reading (by default)
        return View();
    }
}

// View (Confirmation.cshtml)
<h2>@TempData["Message"]</h2>
<p>Order ID: @TempData["OrderId"]</p>
```

### 4. TempData.Keep() - Preserve for Next Request

```csharp
public class OrderController : Controller
{
    public IActionResult Step1()
    {
        TempData["OrderData"] = new Order
        {
            CustomerName = "John Doe",
            Items = new List<string> { "Item1", "Item2" }
        };

        return RedirectToAction("Step2");
    }

    public IActionResult Step2()
    {
        var order = TempData["OrderData"] as Order;

        // Keep for next request (Step3)
        TempData.Keep("OrderData");

        return View();
    }

    public IActionResult Step3()
    {
        var order = TempData["OrderData"] as Order;

        // This is the last step, don't keep
        return View();
    }
}
```

### 5. TempData.Peek() - Read Without Removing

```csharp
public class OrderController : Controller
{
    public IActionResult ProcessOrder()
    {
        TempData["OrderId"] = 123;
        return RedirectToAction("Confirmation");
    }

    public IActionResult Confirmation()
    {
        // Peek - read without marking for deletion
        var orderId = TempData.Peek("OrderId");

        // Value is still available for subsequent requests
        return View();
    }

    public IActionResult Receipt()
    {
        // Still available because we used Peek()
        var orderId = TempData["OrderId"];

        return View();
    }
}
```

### 6. Comparison Example

```csharp
public class ComparisonController : Controller
{
    public IActionResult DemoViewData()
    {
        // ViewData - survives only current request
        ViewData["Message"] = "This is ViewData";
        ViewData["Count"] = 10;

        return View();
    }

    public IActionResult DemoViewBag()
    {
        // ViewBag - survives only current request
        ViewBag.Message = "This is ViewBag";
        ViewBag.Count = 10;

        return View();
    }

    public IActionResult DemoTempData()
    {
        // TempData - survives across redirects
        TempData["Message"] = "This is TempData";
        TempData["Count"] = 10;

        // This will work - TempData available after redirect
        return RedirectToAction("AfterRedirect");
    }

    public IActionResult AfterRedirect()
    {
        // TempData is available here
        var message = TempData["Message"];

        // ViewData/ViewBag would be null here
        return View();
    }
}
```

### 7. Type Safety Comparison

```csharp
public class TypeSafetyController : Controller
{
    public IActionResult Index()
    {
        var product = new Product { Id = 1, Name = "Laptop", Price = 999.99m };

        // ViewData - requires explicit casting
        ViewData["Product"] = product;
        var p1 = ViewData["Product"] as Product; // Cast required
        var p1Name = (ViewData["Product"] as Product)?.Name; // Null-safe

        // ViewBag - no casting needed (dynamic)
        ViewBag.Product = product;
        var p2 = ViewBag.Product; // No cast, but dynamic
        var p2Name = ViewBag.Product.Name; // Direct access
        // ⚠️ Runtime error if property doesn't exist

        // TempData - requires explicit casting
        TempData["Product"] = product;
        var p3 = TempData["Product"] as Product; // Cast required

        return View();
    }
}

// View
@{
    // ViewData - explicit casting
    var product1 = ViewData["Product"] as Product;
    var name1 = product1?.Name; // Compile-time safety

    // ViewBag - dynamic, no IntelliSense
    var name2 = ViewBag.Product.Name; // No compile-time checking

    // TempData - explicit casting
    var product3 = TempData["Product"] as Product;
    var name3 = product3?.Name;
}
```

### 8. Lifetime Demonstration

```csharp
public class LifetimeController : Controller
{
    // Action 1
    public IActionResult SetData()
    {
        ViewData["VD"] = "ViewData Value";
        ViewBag.VB = "ViewBag Value";
        TempData["TD"] = "TempData Value";

        return View();
    }

    // SetData View makes a form post to ProcessData
    [HttpPost]
    public IActionResult ProcessData()
    {
        // After POST from same view
        var vd = ViewData["VD"]; // null - ViewData lost
        var vb = ViewBag.VB;     // null - ViewBag lost
        var td = TempData["TD"]; // "TempData Value" - still available!

        return RedirectToAction("ShowData");
    }

    // Action 3
    public IActionResult ShowData()
    {
        // After redirect
        var vd = ViewData["VD"]; // null
        var vb = ViewBag.VB;     // null
        var td = TempData["TD"]; // "TempData Value" - available once more

        return RedirectToAction("FinalCheck");
    }

    // Action 4
    public IActionResult FinalCheck()
    {
        // After second redirect
        var td = TempData["TD"]; // null - TempData consumed

        return View();
    }
}
```

### 9. Complex Object Storage

```csharp
public class DataTransferController : Controller
{
    public IActionResult StoreComplexObject()
    {
        var viewModel = new DashboardViewModel
        {
            UserName = "John Doe",
            Stats = new Statistics
            {
                TotalOrders = 150,
                Revenue = 45000.00m
            },
            RecentOrders = new List<Order>
            {
                new Order { Id = 1, Total = 99.99m },
                new Order { Id = 2, Total = 149.99m }
            }
        };

        // ViewBag - easiest for complex objects
        ViewBag.Dashboard = viewModel;

        // ViewData - requires casting
        ViewData["Dashboard"] = viewModel;

        // TempData - for redirect scenarios
        // Note: Complex objects need JSON serialization
        TempData["Dashboard"] = JsonSerializer.Serialize(viewModel);

        return View();
    }

    public IActionResult RetrieveComplexObject()
    {
        // ViewBag
        var dash1 = ViewBag.Dashboard as DashboardViewModel;

        // ViewData
        var dash2 = ViewData["Dashboard"] as DashboardViewModel;

        // TempData (deserialize)
        var dashJson = TempData["Dashboard"] as string;
        var dash3 = JsonSerializer.Deserialize<DashboardViewModel>(dashJson);

        return View();
    }
}
```

### 10. Best Practices - ViewData

```csharp
public class ViewDataBestPracticesController : Controller
{
    // ✅ Good: Use for simple metadata
    public IActionResult Index()
    {
        ViewData["Title"] = "Products";
        ViewData["PageDescription"] = "View all products";
        return View();
    }

    // ❌ Bad: Overusing ViewData for complex data
    public IActionResult BadExample()
    {
        ViewData["Products"] = _productService.GetAll();
        ViewData["Categories"] = _categoryService.GetAll();
        ViewData["UserPreferences"] = _userService.GetPreferences();
        // Use strongly-typed models instead!
        return View();
    }

    // ✅ Good: Strongly-typed model + ViewData for metadata
    public IActionResult GoodExample()
    {
        var model = new ProductListViewModel
        {
            Products = _productService.GetAll(),
            Categories = _categoryService.GetAll()
        };

        ViewData["Title"] = "Product List";

        return View(model);
    }
}
```

### 11. Best Practices - ViewBag

```csharp
public class ViewBagBestPracticesController : Controller
{
    // ✅ Good: Quick lookups or dropdowns
    public IActionResult Create()
    {
        ViewBag.Categories = new SelectList(
            _categoryService.GetAll(),
            "Id",
            "Name");

        ViewBag.Countries = new SelectList(
            _countryService.GetAll(),
            "Code",
            "Name");

        return View();
    }

    // ❌ Bad: Property name typos (runtime error)
    public IActionResult BadExample()
    {
        ViewBag.Mesage = "Hello"; // Typo!
        return View();
    }

    // In View:
    // @ViewBag.Message // null - typo in controller!

    // ✅ Good: Consistent naming
    public IActionResult GoodExample()
    {
        ViewBag.SuccessMessage = "Operation successful";
        ViewBag.ErrorMessage = "Operation failed";
        return View();
    }
}
```

### 12. Best Practices - TempData

```csharp
public class TempDataBestPracticesController : Controller
{
    // ✅ Good: Success/error messages after redirect
    [HttpPost]
    public IActionResult Create(ProductDto product)
    {
        if (!ModelState.IsValid)
        {
            return View(product);
        }

        _productService.Create(product);

        TempData["SuccessMessage"] = "Product created successfully!";
        return RedirectToAction("Index");
    }

    // ✅ Good: Wizard/multi-step forms
    public IActionResult WizardStep1()
    {
        TempData["WizardData"] = new WizardData { Step = 1 };
        return View();
    }

    [HttpPost]
    public IActionResult WizardStep1(Step1Data data)
    {
        var wizardData = TempData["WizardData"] as WizardData;
        wizardData.Step1Data = data;
        TempData["WizardData"] = wizardData;

        return RedirectToAction("WizardStep2");
    }

    // ❌ Bad: Storing large amounts of data
    public IActionResult BadExample()
    {
        // Don't store large datasets in TempData
        TempData["AllProducts"] = _productService.GetAll(); // Bad!
        // Use database or cache instead

        return RedirectToAction("ShowProducts");
    }

    // ✅ Good: Store only identifier
    public IActionResult GoodExample()
    {
        var searchId = Guid.NewGuid();
        _cacheService.Set(searchId.ToString(), _productService.GetAll());

        TempData["SearchId"] = searchId;
        return RedirectToAction("ShowProducts");
    }
}
```

### 13. TempData Providers

```csharp
// Startup.cs or Program.cs

// Default: Session-based TempData
services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(20);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});
services.AddControllersWithViews();

app.UseSession();

// Cookie-based TempData (no server-side session)
services.AddControllersWithViews()
    .AddCookieTempDataProvider(options =>
    {
        options.Cookie.Name = "MyApp.TempData";
        options.Cookie.HttpOnly = true;
        options.Cookie.IsEssential = true;
    });
```

### 14. Custom TempData Keys (Constants)

```csharp
// Constants for TempData keys
public static class TempDataKeys
{
    public const string SuccessMessage = "SuccessMessage";
    public const string ErrorMessage = "ErrorMessage";
    public const string WarningMessage = "WarningMessage";
    public const string InfoMessage = "InfoMessage";
}

public class ProductsController : Controller
{
    [HttpPost]
    public IActionResult Create(Product product)
    {
        _productService.Create(product);

        // Use constant instead of magic string
        TempData[TempDataKeys.SuccessMessage] = "Product created!";

        return RedirectToAction("Index");
    }

    public IActionResult Index()
    {
        // Compile-time safety
        var message = TempData[TempDataKeys.SuccessMessage];

        return View();
    }
}
```

### 15. Strongly-Typed TempData (Extension Method)

```csharp
// Extension methods for type-safe TempData
public static class TempDataExtensions
{
    public static void Set<T>(this ITempDataDictionary tempData, string key, T value)
    {
        tempData[key] = JsonSerializer.Serialize(value);
    }

    public static T Get<T>(this ITempDataDictionary tempData, string key)
    {
        if (tempData.TryGetValue(key, out var value))
        {
            return JsonSerializer.Deserialize<T>((string)value);
        }
        return default;
    }

    public static T Peek<T>(this ITempDataDictionary tempData, string key)
    {
        var value = tempData.Peek(key);
        if (value != null)
        {
            return JsonSerializer.Deserialize<T>((string)value);
        }
        return default;
    }
}

// Usage
public class OrderController : Controller
{
    public IActionResult Create()
    {
        var order = new Order { Id = 123, Total = 99.99m };

        // Strongly-typed Set
        TempData.Set("CurrentOrder", order);

        return RedirectToAction("Confirmation");
    }

    public IActionResult Confirmation()
    {
        // Strongly-typed Get
        var order = TempData.Get<Order>("CurrentOrder");

        return View(order);
    }
}
```

### 16. View Component with ViewBag/ViewData

```csharp
// View Component
public class NavigationViewComponent : ViewComponent
{
    private readonly IMenuService _menuService;

    public NavigationViewComponent(IMenuService menuService)
    {
        _menuService = menuService;
    }

    public IViewComponentResult Invoke()
    {
        var menuItems = _menuService.GetMenuItems();

        // ViewData in ViewComponent
        ViewData["UserName"] = User.Identity.Name;

        // ViewBag in ViewComponent
        ViewBag.ActivePage = ViewContext.RouteData.Values["action"];

        return View(menuItems);
    }
}

// View Component View (Navigation.cshtml)
@model List<MenuItem>

<nav>
    <span>Welcome, @ViewData["UserName"]</span>
    <ul>
        @foreach (var item in Model)
        {
            <li class="@(item.Action == ViewBag.ActivePage ? "active" : "")">
                <a href="@item.Url">@item.Title</a>
            </li>
        }
    </ul>
</nav>
```

### 17. PRG Pattern (Post-Redirect-Get)

```csharp
public class AccountController : Controller
{
    // GET: Display form
    public IActionResult Register()
    {
        return View();
    }

    // POST: Process form
    [HttpPost]
    public IActionResult Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            // Return view directly (no redirect)
            return View(model);
        }

        _userService.Register(model);

        // Success: Use TempData and redirect (PRG pattern)
        TempData["SuccessMessage"] = "Registration successful! Please log in.";
        return RedirectToAction("Login");
    }

    // GET: Show login with success message
    public IActionResult Login()
    {
        // TempData available after redirect
        var message = TempData["SuccessMessage"];

        return View();
    }
}
```

### 18. Layout Page Usage

```csharp
// _Layout.cshtml
<!DOCTYPE html>
<html>
<head>
    <title>@ViewData["Title"] - My Application</title>
</head>
<body>
    @if (TempData["SuccessMessage"] != null)
    {
        <div class="alert alert-success">
            @TempData["SuccessMessage"]
        </div>
    }

    @if (TempData["ErrorMessage"] != null)
    {
        <div class="alert alert-danger">
            @TempData["ErrorMessage"]
        </div>
    }

    <header>
        <h1>@ViewBag.AppName</h1>
    </header>

    @RenderBody()
</body>
</html>

// Controller
public class HomeController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Home Page";
        ViewBag.AppName = "My MVC App";

        return View();
    }
}
```

### 19. Performance Considerations

```csharp
public class PerformanceController : Controller
{
    // ❌ Bad: Creating large objects unnecessarily
    public IActionResult BadPerformance()
    {
        // Loading all products just for count
        var allProducts = _productService.GetAll();
        ViewBag.ProductCount = allProducts.Count;

        // TempData with large object (uses session/cookie)
        TempData["AllProducts"] = allProducts; // Heavy!

        return View();
    }

    // ✅ Good: Fetch only what you need
    public IActionResult GoodPerformance()
    {
        // Get count directly
        ViewBag.ProductCount = _productService.GetCount();

        // Store only ID for lookup later
        TempData["FilterId"] = searchFilterId;

        return View();
    }
}
```

### 20. Summary Comparison Table

| Feature | ViewData | ViewBag | TempData |
|---------|----------|---------|----------|
| **Type** | Dictionary | Dynamic | Dictionary |
| **Syntax** | `ViewData["Key"]` | `ViewBag.Property` | `TempData["Key"]` |
| **Type Safety** | No (requires cast) | No (dynamic) | No (requires cast) |
| **IntelliSense** | No | No | No |
| **Null Check** | Required | Required | Required |
| **Lifetime** | Current request only | Current request only | Current + next request |
| **Persists redirect** | No | No | Yes |
| **Underlying storage** | ViewDataDictionary | ViewData (wrapper) | Session/Cookie |
| **Use case** | Simple values | Simple values | Post-Redirect-Get |
| **Performance** | Fast | Fast | Slower (serialization) |
| **Best for** | Metadata, titles | Dropdowns, lookups | Success/error messages |

**Decision Matrix:**

```
Use ViewData when:
✅ Passing simple metadata to views
✅ Setting page titles, descriptions
✅ You prefer dictionary syntax
✅ Migrating from older ASP.NET MVC

Use ViewBag when:
✅ Passing dropdown lists (SelectList)
✅ You prefer property syntax
✅ Quick prototyping
✅ Simple UI data

Use TempData when:
✅ Post-Redirect-Get pattern
✅ Showing success/error messages after redirect
✅ Multi-step wizards
✅ Data needed across redirects

DON'T use any for:
❌ Passing primary model data (use strongly-typed models)
❌ Storing large datasets
❌ Business logic
❌ Long-term storage (use session, cache, or database)
```

**Best Practice:**
Prefer **strongly-typed ViewModels** over ViewBag/ViewData/TempData for primary data. Use these mechanisms only for supplementary data like metadata, messages, and lookup lists.

---

## Q57: Explain partial views and when to use them

**Answer:**

Partial views are reusable view components that render HTML fragments. They promote code reuse, modularity, and separation of concerns in ASP.NET MVC applications.

### 1. Basic Partial View

```csharp
// _ProductCard.cshtml (partial view)
@model Product

<div class="product-card">
    <img src="@Model.ImageUrl" alt="@Model.Name" />
    <h3>@Model.Name</h3>
    <p class="price">$@Model.Price</p>
    <p class="description">@Model.Description</p>
    <button class="btn btn-primary">Add to Cart</button>
</div>

// Index.cshtml (parent view)
@model List<Product>

<h1>Our Products</h1>

<div class="product-grid">
    @foreach (var product in Model)
    {
        @await Html.PartialAsync("_ProductCard", product)
    }
</div>
```

### 2. Partial View with Strongly-Typed Model

```csharp
// Models/CommentViewModel.cs
public class CommentViewModel
{
    public int Id { get; set; }
    public string Author { get; set; }
    public string Content { get; set; }
    public DateTime CreatedAt { get; set; }
    public int Likes { get; set; }
}

// Views/Shared/_Comment.cshtml
@model CommentViewModel

<div class="comment" data-comment-id="@Model.Id">
    <div class="comment-header">
        <strong>@Model.Author</strong>
        <span class="timestamp">@Model.CreatedAt.ToString("MMM dd, yyyy")</span>
    </div>
    <div class="comment-body">
        @Model.Content
    </div>
    <div class="comment-footer">
        <button class="like-btn">
            <i class="fa fa-thumbs-up"></i> @Model.Likes
        </button>
    </div>
</div>

// Views/Post/Details.cshtml
@model PostViewModel

<article>
    <h1>@Model.Title</h1>
    <div class="post-content">@Model.Content</div>

    <section class="comments">
        <h2>Comments (@Model.Comments.Count)</h2>
        @foreach (var comment in Model.Comments)
        {
            @await Html.PartialAsync("_Comment", comment)
        }
    </section>
</article>
```

### 3. Partial View vs Partial (Async vs Sync)

```csharp
// Synchronous partial rendering (legacy, avoid)
@Html.Partial("_ProductCard", product)

// Asynchronous partial rendering (preferred)
@await Html.PartialAsync("_ProductCard", product)

// Using tag helper (ASP.NET Core - preferred)
<partial name="_ProductCard" model="product" />

// Conditional rendering with tag helper
<partial name="_ProductCard" model="product" for="Product" />
```

### 4. RenderPartial vs Partial

```csharp
// Returns IHtmlContent (can be assigned to variable)
@{
    var productCard = await Html.PartialAsync("_ProductCard", product);
}
<div class="container">
    @productCard
</div>

// Writes directly to response (better performance)
@{
    await Html.RenderPartialAsync("_ProductCard", product);
}

// Controller action returning partial view
public class ProductsController : Controller
{
    public IActionResult GetProductCard(int id)
    {
        var product = _productService.GetById(id);
        return PartialView("_ProductCard", product);
    }
}

// AJAX call to get partial view
// JavaScript
$.get('/Products/GetProductCard/123', function(html) {
    $('#product-container').html(html);
});
```

### 5. Partial View with ViewData

```csharp
// _Breadcrumb.cshtml
@model List<BreadcrumbItem>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        @foreach (var item in Model)
        {
            if (item == Model.Last())
            {
                <li class="breadcrumb-item active" aria-current="page">
                    @item.Title
                </li>
            }
            else
            {
                <li class="breadcrumb-item">
                    <a href="@item.Url">@item.Title</a>
                </li>
            }
        }
    </ol>
</nav>

// Usage with ViewData
@{
    ViewData["BreadcrumbTitle"] = "Products";
}
@await Html.PartialAsync("_Breadcrumb", Model.Breadcrumbs, ViewData)
```

### 6. Layout Partial Views

```csharp
// _Header.cshtml
@model NavigationViewModel

<header class="site-header">
    <div class="logo">
        <a href="/">
            <img src="/images/logo.png" alt="Company Logo" />
        </a>
    </div>
    <nav class="main-navigation">
        <ul>
            @foreach (var item in Model.MenuItems)
            {
                <li class="@(item.IsActive ? "active" : "")">
                    <a href="@item.Url">@item.Title</a>
                </li>
            }
        </ul>
    </nav>
    <div class="user-menu">
        @if (User.Identity.IsAuthenticated)
        {
            <span>Welcome, @User.Identity.Name</span>
            <a href="/Account/Logout">Logout</a>
        }
        else
        {
            <a href="/Account/Login">Login</a>
        }
    </div>
</header>

// _Footer.cshtml
<footer class="site-footer">
    <div class="footer-content">
        <div class="footer-links">
            <ul>
                <li><a href="/About">About Us</a></li>
                <li><a href="/Contact">Contact</a></li>
                <li><a href="/Privacy">Privacy Policy</a></li>
                <li><a href="/Terms">Terms of Service</a></li>
            </ul>
        </div>
        <div class="copyright">
            &copy; @DateTime.Now.Year Company Name. All rights reserved.
        </div>
    </div>
</footer>

// _Layout.cshtml
<!DOCTYPE html>
<html>
<head>
    <title>@ViewData["Title"]</title>
</head>
<body>
    @await Html.PartialAsync("_Header", Model.Navigation)

    <main class="content">
        @RenderBody()
    </main>

    @await Html.PartialAsync("_Footer")

    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>
```

### 7. Form Partial Views

```csharp
// _AddressForm.cshtml
@model AddressViewModel

<div class="address-form">
    <div class="form-group">
        <label asp-for="Street"></label>
        <input asp-for="Street" class="form-control" />
        <span asp-validation-for="Street" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="City"></label>
        <input asp-for="City" class="form-control" />
        <span asp-validation-for="City" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="State"></label>
        <select asp-for="State" asp-items="Model.States" class="form-control">
            <option value="">-- Select State --</option>
        </select>
        <span asp-validation-for="State" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="ZipCode"></label>
        <input asp-for="ZipCode" class="form-control" />
        <span asp-validation-for="ZipCode" class="text-danger"></span>
    </div>
</div>

// Checkout.cshtml
@model CheckoutViewModel

<form asp-action="ProcessCheckout" method="post">
    <h2>Billing Address</h2>
    @await Html.PartialAsync("_AddressForm", Model.BillingAddress)

    <div class="form-check">
        <input type="checkbox" id="sameAsShipping" />
        <label for="sameAsShipping">Same as billing address</label>
    </div>

    <h2>Shipping Address</h2>
    @await Html.PartialAsync("_AddressForm", Model.ShippingAddress)

    <button type="submit" class="btn btn-primary">Complete Purchase</button>
</form>
```

### 8. Table Partial Views

```csharp
// _OrderTable.cshtml
@model List<OrderViewModel>

<table class="table table-striped">
    <thead>
        <tr>
            <th>Order #</th>
            <th>Date</th>
            <th>Customer</th>
            <th>Total</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var order in Model)
        {
            <tr>
                <td>@order.OrderNumber</td>
                <td>@order.OrderDate.ToShortDateString()</td>
                <td>@order.CustomerName</td>
                <td>$@order.Total.ToString("N2")</td>
                <td>
                    <span class="badge badge-@order.StatusClass">
                        @order.Status
                    </span>
                </td>
                <td>
                    <a href="@Url.Action("Details", new { id = order.Id })"
                       class="btn btn-sm btn-info">View</a>
                    <a href="@Url.Action("Edit", new { id = order.Id })"
                       class="btn btn-sm btn-warning">Edit</a>
                </td>
            </tr>
        }
    </tbody>
</table>

@if (!Model.Any())
{
    <div class="alert alert-info">
        No orders found.
    </div>
}

// Dashboard.cshtml
@model DashboardViewModel

<h1>Dashboard</h1>

<section class="recent-orders">
    <h2>Recent Orders</h2>
    @await Html.PartialAsync("_OrderTable", Model.RecentOrders)
</section>
```

### 9. Modal Partial Views

```csharp
// _ConfirmDialog.cshtml
@model ConfirmDialogViewModel

<div class="modal fade" id="confirmModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">@Model.Title</h5>
                <button type="button" class="close" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p>@Model.Message</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">
                    @Model.CancelText
                </button>
                <button type="button" class="btn btn-@Model.ConfirmButtonClass"
                        id="confirmAction">
                    @Model.ConfirmText
                </button>
            </div>
        </div>
    </div>
</div>

// Controller action to return modal
public IActionResult GetDeleteConfirmation(int id)
{
    var product = _productService.GetById(id);

    var model = new ConfirmDialogViewModel
    {
        Title = "Confirm Deletion",
        Message = $"Are you sure you want to delete '{product.Name}'?",
        ConfirmText = "Delete",
        CancelText = "Cancel",
        ConfirmButtonClass = "danger"
    };

    return PartialView("_ConfirmDialog", model);
}

// AJAX call to load modal
// JavaScript
function showDeleteConfirmation(id) {
    $.get('/Products/GetDeleteConfirmation/' + id, function(html) {
        $('body').append(html);
        $('#confirmModal').modal('show');

        $('#confirmAction').click(function() {
            deleteProduct(id);
        });
    });
}
```

### 10. Pagination Partial View

```csharp
// _Pagination.cshtml
@model PaginationViewModel

@if (Model.TotalPages > 1)
{
    <nav aria-label="Page navigation">
        <ul class="pagination">
            <!-- Previous button -->
            <li class="page-item @(Model.CurrentPage == 1 ? "disabled" : "")">
                <a class="page-link"
                   href="@Model.GetPageUrl(Model.CurrentPage - 1)">
                    Previous
                </a>
            </li>

            <!-- First page -->
            @if (Model.CurrentPage > 3)
            {
                <li class="page-item">
                    <a class="page-link" href="@Model.GetPageUrl(1)">1</a>
                </li>
                <li class="page-item disabled">
                    <span class="page-link">...</span>
                </li>
            }

            <!-- Page numbers -->
            @for (int i = Math.Max(1, Model.CurrentPage - 2);
                  i <= Math.Min(Model.TotalPages, Model.CurrentPage + 2);
                  i++)
            {
                <li class="page-item @(i == Model.CurrentPage ? "active" : "")">
                    <a class="page-link" href="@Model.GetPageUrl(i)">@i</a>
                </li>
            }

            <!-- Last page -->
            @if (Model.CurrentPage < Model.TotalPages - 2)
            {
                <li class="page-item disabled">
                    <span class="page-link">...</span>
                </li>
                <li class="page-item">
                    <a class="page-link" href="@Model.GetPageUrl(Model.TotalPages)">
                        @Model.TotalPages
                    </a>
                </li>
            }

            <!-- Next button -->
            <li class="page-item @(Model.CurrentPage == Model.TotalPages ? "disabled" : "")">
                <a class="page-link"
                   href="@Model.GetPageUrl(Model.CurrentPage + 1)">
                    Next
                </a>
            </li>
        </ul>
    </nav>

    <div class="pagination-info">
        Showing @Model.StartItem - @Model.EndItem of @Model.TotalItems items
    </div>
}

// PaginationViewModel.cs
public class PaginationViewModel
{
    public int CurrentPage { get; set; }
    public int PageSize { get; set; }
    public int TotalItems { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalItems / (double)PageSize);
    public int StartItem => (CurrentPage - 1) * PageSize + 1;
    public int EndItem => Math.Min(CurrentPage * PageSize, TotalItems);

    private readonly string _baseUrl;

    public PaginationViewModel(int currentPage, int pageSize, int totalItems, string baseUrl)
    {
        CurrentPage = currentPage;
        PageSize = pageSize;
        TotalItems = totalItems;
        _baseUrl = baseUrl;
    }

    public string GetPageUrl(int page)
    {
        return $"{_baseUrl}?page={page}&pageSize={PageSize}";
    }
}

// Usage
@await Html.PartialAsync("_Pagination",
    new PaginationViewModel(Model.CurrentPage, 10, Model.TotalCount, "/Products"))
```

### 11. AJAX Partial View Updates

```csharp
// Controller
public class CartController : Controller
{
    public IActionResult AddToCart(int productId)
    {
        var cart = _cartService.AddProduct(productId);
        return PartialView("_CartSummary", cart);
    }

    public IActionResult UpdateQuantity(int productId, int quantity)
    {
        var cart = _cartService.UpdateQuantity(productId, quantity);
        return PartialView("_CartSummary", cart);
    }
}

// _CartSummary.cshtml
@model CartViewModel

<div id="cart-summary">
    <div class="cart-icon">
        <i class="fa fa-shopping-cart"></i>
        <span class="badge">@Model.ItemCount</span>
    </div>
    <div class="cart-total">
        $@Model.Total.ToString("N2")
    </div>
</div>

// JavaScript
function addToCart(productId) {
    $.post('/Cart/AddToCart', { productId: productId }, function(html) {
        $('#cart-summary').replaceWith(html);
        showNotification('Product added to cart');
    });
}

function updateQuantity(productId, quantity) {
    $.post('/Cart/UpdateQuantity', { productId, quantity }, function(html) {
        $('#cart-summary').replaceWith(html);
    });
}
```

### 12. Search Results Partial View

```csharp
// _SearchResults.cshtml
@model SearchResultsViewModel

@if (Model.Results.Any())
{
    <div class="search-results">
        <p class="results-count">
            Found @Model.TotalResults results for "@Model.Query"
        </p>

        <div class="results-list">
            @foreach (var result in Model.Results)
            {
                <div class="search-result-item">
                    <h4>
                        <a href="@result.Url">@Html.Raw(result.HighlightedTitle)</a>
                    </h4>
                    <p class="result-snippet">
                        @Html.Raw(result.Snippet)
                    </p>
                    <span class="result-url">@result.Url</span>
                </div>
            }
        </div>

        @await Html.PartialAsync("_Pagination", Model.Pagination)
    </div>
}
else
{
    <div class="no-results">
        <p>No results found for "@Model.Query"</p>
        <p>Try different keywords or check your spelling.</p>
    </div>
}

// Controller
[HttpGet]
public IActionResult Search(string query, int page = 1)
{
    var results = _searchService.Search(query, page, 10);

    if (Request.Headers["X-Requested-With"] == "XMLHttpRequest")
    {
        // AJAX request - return partial view
        return PartialView("_SearchResults", results);
    }

    // Normal request - return full view
    return View(results);
}
```

### 13. Editor Template Partial Views

```csharp
// EditorTemplates/Address.cshtml
@model AddressViewModel

<div class="address-editor">
    @Html.HiddenFor(m => m.Id)

    <div class="form-group">
        @Html.LabelFor(m => m.Street)
        @Html.EditorFor(m => m.Street, new { htmlAttributes = new { @class = "form-control" } })
        @Html.ValidationMessageFor(m => m.Street, "", new { @class = "text-danger" })
    </div>

    <div class="row">
        <div class="col-md-6">
            <div class="form-group">
                @Html.LabelFor(m => m.City)
                @Html.EditorFor(m => m.City, new { htmlAttributes = new { @class = "form-control" } })
                @Html.ValidationMessageFor(m => m.City, "", new { @class = "text-danger" })
            </div>
        </div>
        <div class="col-md-3">
            <div class="form-group">
                @Html.LabelFor(m => m.State)
                @Html.DropDownListFor(m => m.State, Model.States, "-- Select --", new { @class = "form-control" })
                @Html.ValidationMessageFor(m => m.State, "", new { @class = "text-danger" })
            </div>
        </div>
        <div class="col-md-3">
            <div class="form-group">
                @Html.LabelFor(m => m.ZipCode)
                @Html.EditorFor(m => m.ZipCode, new { htmlAttributes = new { @class = "form-control" } })
                @Html.ValidationMessageFor(m => m.ZipCode, "", new { @class = "text-danger" })
            </div>
        </div>
    </div>
</div>

// Usage
@model CustomerViewModel

<div class="customer-form">
    <h3>Billing Address</h3>
    @Html.EditorFor(m => m.BillingAddress)

    <h3>Shipping Address</h3>
    @Html.EditorFor(m => m.ShippingAddress)
</div>
```

### 14. Display Template Partial Views

```csharp
// DisplayTemplates/Product.cshtml
@model ProductViewModel

<div class="product-display">
    <div class="product-image">
        <img src="@Model.ImageUrl" alt="@Model.Name" />
    </div>
    <div class="product-info">
        <h3>@Model.Name</h3>
        <p class="price">$@Model.Price.ToString("N2")</p>
        <p class="description">@Model.Description</p>

        @if (Model.InStock)
        {
            <span class="badge badge-success">In Stock</span>
        }
        else
        {
            <span class="badge badge-danger">Out of Stock</span>
        }

        <div class="product-meta">
            <span>SKU: @Model.SKU</span>
            <span>Category: @Model.Category</span>
        </div>
    </div>
</div>

// Usage
@model List<ProductViewModel>

<div class="product-list">
    @foreach (var product in Model)
    {
        @Html.DisplayFor(m => product)
        <!-- Or -->
        @Html.DisplayFor(m => product, "Product")
    }
</div>
```

### 15. Nested Partial Views

```csharp
// _Post.cshtml
@model PostViewModel

<article class="post">
    <header class="post-header">
        <h2>@Model.Title</h2>
        <div class="post-meta">
            @await Html.PartialAsync("_Author", Model.Author)
            <span class="post-date">@Model.PublishedDate.ToShortDateString()</span>
        </div>
    </header>

    <div class="post-content">
        @Html.Raw(Model.Content)
    </div>

    <footer class="post-footer">
        @await Html.PartialAsync("_Tags", Model.Tags)
        @await Html.PartialAsync("_ShareButtons", new ShareViewModel { Url = Model.Url, Title = Model.Title })
    </footer>

    <section class="comments">
        <h3>Comments (@Model.Comments.Count)</h3>
        @await Html.PartialAsync("_CommentList", Model.Comments)
    </section>
</article>

// _Author.cshtml
@model AuthorViewModel

<div class="author-info">
    <img src="@Model.AvatarUrl" alt="@Model.Name" class="author-avatar" />
    <span class="author-name">@Model.Name</span>
</div>

// _Tags.cshtml
@model List<TagViewModel>

<div class="post-tags">
    @foreach (var tag in Model)
    {
        <a href="@Url.Action("Index", "Posts", new { tag = tag.Slug })"
           class="tag">
            #@tag.Name
        </a>
    }
</div>

// _CommentList.cshtml
@model List<CommentViewModel>

<div class="comment-list">
    @foreach (var comment in Model)
    {
        @await Html.PartialAsync("_Comment", comment)
    }
</div>
```

### 16. Partial View with Dependency Injection

```csharp
// _UserProfile.cshtml
@model UserViewModel
@inject IUserService UserService
@inject IImageService ImageService

<div class="user-profile">
    <div class="profile-image">
        <img src="@ImageService.GetUserAvatarUrl(Model.Id, 200)"
             alt="@Model.FullName" />
    </div>
    <div class="profile-info">
        <h3>@Model.FullName</h3>
        <p>@Model.Email</p>
        <p>Member since: @Model.JoinDate.ToShortDateString()</p>

        @{
            var stats = await UserService.GetUserStatsAsync(Model.Id);
        }

        <div class="user-stats">
            <div class="stat">
                <span class="stat-value">@stats.PostCount</span>
                <span class="stat-label">Posts</span>
            </div>
            <div class="stat">
                <span class="stat-value">@stats.FollowerCount</span>
                <span class="stat-label">Followers</span>
            </div>
        </div>
    </div>
</div>
```

### 17. Conditional Partial Rendering

```csharp
// Index.cshtml
@model DashboardViewModel

<div class="dashboard">
    <h1>Dashboard</h1>

    @if (User.IsInRole("Admin"))
    {
        @await Html.PartialAsync("_AdminPanel", Model.AdminData)
    }

    @if (Model.HasNotifications)
    {
        @await Html.PartialAsync("_Notifications", Model.Notifications)
    }

    @if (Model.RecentOrders.Any())
    {
        @await Html.PartialAsync("_OrderTable", Model.RecentOrders)
    }
    else
    {
        @await Html.PartialAsync("_EmptyState", new EmptyStateViewModel
        {
            Icon = "shopping-cart",
            Title = "No orders yet",
            Message = "Start shopping to see your orders here!"
        })
    }
</div>

// _EmptyState.cshtml
@model EmptyStateViewModel

<div class="empty-state">
    <i class="fa fa-@Model.Icon fa-3x"></i>
    <h3>@Model.Title</h3>
    <p>@Model.Message</p>
    @if (!string.IsNullOrEmpty(Model.ActionUrl))
    {
        <a href="@Model.ActionUrl" class="btn btn-primary">@Model.ActionText</a>
    }
</div>
```

### 18. Caching Partial Views

```csharp
// Using output cache attribute (ASP.NET Core)
// Startup.cs
services.AddResponseCaching();
services.AddControllersWithViews();

// Controller
[ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "category" })]
public IActionResult GetProductList(string category)
{
    var products = _productService.GetByCategory(category);
    return PartialView("_ProductList", products);
}

// Using cache tag helper in view
<cache expires-after="TimeSpan.FromMinutes(5)" vary-by-query="category">
    @await Html.PartialAsync("_ProductList", Model.Products)
</cache>

// Using cache tag helper with custom key
<cache vary-by="@Model.Category" expires-sliding="TimeSpan.FromMinutes(10)">
    @await Html.PartialAsync("_ProductList", Model.Products)
</cache>
```

### 19. Testing Partial Views

```csharp
// ProductsControllerTests.cs
[Fact]
public async Task GetProductCard_ReturnsPartialView_WithProduct()
{
    // Arrange
    var productId = 1;
    var expectedProduct = new Product { Id = productId, Name = "Test Product" };
    _mockProductService.Setup(s => s.GetById(productId))
        .Returns(expectedProduct);

    var controller = new ProductsController(_mockProductService.Object);

    // Act
    var result = controller.GetProductCard(productId);

    // Assert
    var partialViewResult = Assert.IsType<PartialViewResult>(result);
    Assert.Equal("_ProductCard", partialViewResult.ViewName);
    Assert.Equal(expectedProduct, partialViewResult.Model);
}
```

### 20. Best Practices and When to Use

**When to Use Partial Views:**

```
✅ Repeating UI components (product cards, user profiles)
✅ Complex page sections (navigation, footer)
✅ AJAX-loaded content
✅ Forms used in multiple places
✅ Modals and dialogs
✅ Table rows or list items
✅ Pagination controls
✅ Search results
✅ Comments sections
✅ Social media widgets

❌ When NOT to use:
- Simple, one-time HTML blocks (use regular HTML)
- Complex business logic (use View Components instead)
- Sections requiring separate data (use View Components)
- Layout structure (use _Layout.cshtml)
```

**Partial View vs View Component:**

| Feature | Partial View | View Component |
|---------|--------------|----------------|
| **Complexity** | Simple rendering | Complex logic allowed |
| **Dependency Injection** | Limited | Full DI support |
| **Testability** | Harder to test | Easily testable |
| **Async support** | Yes | Yes |
| **Cache support** | Tag helpers | Built-in support |
| **Invocation** | From views | From views and code |
| **Best for** | UI fragments | Reusable widgets |

**Performance Tips:**

```csharp
// ✅ Good: Use async rendering
@await Html.PartialAsync("_ProductCard", product)
<partial name="_ProductCard" model="product" />

// ❌ Bad: Synchronous rendering (blocks thread)
@Html.Partial("_ProductCard", product)

// ✅ Good: Cache frequently-used partials
<cache expires-after="TimeSpan.FromMinutes(10)">
    @await Html.PartialAsync("_Footer")
</cache>

// ✅ Good: Minimize partial view nesting depth
// Maximum 2-3 levels deep

// ❌ Bad: Deep nesting (performance impact)
@await Html.PartialAsync("_Level1",
    @await Html.PartialAsync("_Level2",
        @await Html.PartialAsync("_Level3")))
```

**Naming Conventions:**
- Prefix partial view names with underscore: `_ProductCard.cshtml`
- Store shared partials in `Views/Shared/` folder
- Store controller-specific partials in controller's view folder
- Use descriptive names: `_UserProfile.cshtml`, not `_UP.cshtml`

---

## Q58: What are HTML Helpers? Create a custom HTML helper

**Answer:**

HTML Helpers are extension methods that generate HTML markup in ASP.NET MVC views. They provide a programmatic way to create HTML elements with proper encoding and attributes.

### 1. Built-in HTML Helpers

```csharp
// TextBox helpers
@Html.TextBox("Name", "John Doe")
// <input id="Name" name="Name" type="text" value="John Doe" />

@Html.TextBoxFor(m => m.Name, new { @class = "form-control", placeholder = "Enter name" })
// <input class="form-control" id="Name" name="Name" placeholder="Enter name" type="text" value="..." />

// Label helpers
@Html.Label("Name", "Full Name:")
@Html.LabelFor(m => m.Name)

// DropDownList helpers
@Html.DropDownList("CategoryId", ViewBag.Categories as SelectList)
@Html.DropDownListFor(m => m.CategoryId, Model.Categories, "-- Select Category --")

// RadioButton helpers
@Html.RadioButton("Gender", "Male", true)
@Html.RadioButtonFor(m => m.Gender, "Male")

// CheckBox helpers
@Html.CheckBox("IsActive", true)
@Html.CheckBoxFor(m => m.IsActive)

// TextArea helpers
@Html.TextArea("Description", "Default text", 5, 40, null)
@Html.TextAreaFor(m => m.Description, new { rows = 5, cols = 40 })

// Hidden field helpers
@Html.Hidden("Id", Model.Id)
@Html.HiddenFor(m => m.Id)

// Display helpers
@Html.Display("CreatedDate")
@Html.DisplayFor(m => m.CreatedDate)
@Html.DisplayTextFor(m => m.Name)

// Editor helpers
@Html.Editor("Price")
@Html.EditorFor(m => m.Price)

// Validation helpers
@Html.ValidationMessage("Name")
@Html.ValidationMessageFor(m => m.Name)
@Html.ValidationSummary(true, "Please fix the following errors:")
```

### 2. Basic Custom HTML Helper

```csharp
// HtmlHelperExtensions.cs
using Microsoft.AspNetCore.Html;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Text;

public static class HtmlHelperExtensions
{
    // Simple custom helper
    public static IHtmlContent Alert(this IHtmlHelper htmlHelper, string message, string alertType = "info")
    {
        var builder = new TagBuilder("div");
        builder.AddCssClass($"alert alert-{alertType}");
        builder.InnerHtml.Append(message);

        return builder;
    }

    // Custom Image helper
    public static IHtmlContent Image(
        this IHtmlHelper htmlHelper,
        string src,
        string alt = "",
        object htmlAttributes = null)
    {
        var img = new TagBuilder("img");
        img.Attributes["src"] = src;
        img.Attributes["alt"] = alt;

        if (htmlAttributes != null)
        {
            var attributes = HtmlHelper.AnonymousObjectToHtmlAttributes(htmlAttributes);
            img.MergeAttributes(attributes);
        }

        return img;
    }

    // Custom Submit Button helper
    public static IHtmlContent SubmitButton(
        this IHtmlHelper htmlHelper,
        string text,
        string icon = null,
        object htmlAttributes = null)
    {
        var button = new TagBuilder("button");
        button.Attributes["type"] = "submit";
        button.AddCssClass("btn btn-primary");

        if (htmlAttributes != null)
        {
            var attributes = HtmlHelper.AnonymousObjectToHtmlAttributes(htmlAttributes);
            button.MergeAttributes(attributes);
        }

        if (!string.IsNullOrEmpty(icon))
        {
            button.InnerHtml.AppendHtml($"<i class=\"{icon}\"></i> ");
        }

        button.InnerHtml.Append(text);

        return button;
    }
}

// Usage in views
@using YourNamespace.Extensions

@Html.Alert("Operation completed successfully!", "success")
// <div class="alert alert-success">Operation completed successfully!</div>

@Html.Image("/images/logo.png", "Company Logo", new { @class = "img-fluid", width = 200 })
// <img alt="Company Logo" class="img-fluid" src="/images/logo.png" width="200" />

@Html.SubmitButton("Save Changes", "fa fa-save", new { @class = "btn-lg" })
// <button class="btn btn-primary btn-lg" type="submit">
//   <i class="fa fa-save"></i> Save Changes
// </button>
```

### 3. Strongly-Typed Custom Helper

```csharp
public static class StronglyTypedHelpers
{
    // Display name with icon
    public static IHtmlContent DisplayNameWithIcon<TModel, TProperty>(
        this IHtmlHelper<TModel> htmlHelper,
        Expression<Func<TModel, TProperty>> expression,
        string icon)
    {
        var metadata = htmlHelper.GetModelExplorer(expression);
        var displayName = metadata.Metadata.DisplayName ?? metadata.Metadata.PropertyName;

        var span = new TagBuilder("span");
        span.InnerHtml.AppendHtml($"<i class=\"{icon}\"></i> ");
        span.InnerHtml.Append(displayName);

        return span;
    }

    // Conditional display helper
    public static IHtmlContent DisplayOrDefault<TModel, TProperty>(
        this IHtmlHelper<TModel> htmlHelper,
        Expression<Func<TModel, TProperty>> expression,
        string defaultValue = "N/A")
    {
        var func = expression.Compile();
        var value = func(htmlHelper.ViewData.Model);

        if (value == null || string.IsNullOrWhiteSpace(value.ToString()))
        {
            var span = new TagBuilder("span");
            span.AddCssClass("text-muted");
            span.InnerHtml.Append(defaultValue);
            return span;
        }

        return htmlHelper.DisplayFor(expression);
    }

    // Currency display helper
    public static IHtmlContent DisplayCurrency<TModel>(
        this IHtmlHelper<TModel> htmlHelper,
        Expression<Func<TModel, decimal>> expression,
        string currencySymbol = "$")
    {
        var func = expression.Compile();
        var value = func(htmlHelper.ViewData.Model);

        var span = new TagBuilder("span");
        span.AddCssClass("currency");
        span.InnerHtml.Append($"{currencySymbol}{value:N2}");

        return span;
    }
}

// Usage
@Html.DisplayNameWithIcon(m => m.Email, "fa fa-envelope")
// <span><i class="fa fa-envelope"></i> Email</span>

@Html.DisplayOrDefault(m => m.MiddleName, "Not provided")
// <span class="text-muted">Not provided</span> (if null)

@Html.DisplayCurrency(m => m.Price, "$")
// <span class="currency">$99.99</span>
```

### 4. Complex Custom Helper - Badge

```csharp
public static class BadgeHelper
{
    public static IHtmlContent Badge(
        this IHtmlHelper htmlHelper,
        string text,
        BadgeType type = BadgeType.Primary,
        bool isPill = false)
    {
        var badge = new TagBuilder("span");
        badge.AddCssClass("badge");
        badge.AddCssClass($"badge-{type.ToString().ToLower()}");

        if (isPill)
        {
            badge.AddCssClass("badge-pill");
        }

        badge.InnerHtml.Append(text);

        return badge;
    }

    public static IHtmlContent StatusBadge(
        this IHtmlHelper htmlHelper,
        string status)
    {
        var badgeType = status.ToLower() switch
        {
            "active" => BadgeType.Success,
            "pending" => BadgeType.Warning,
            "inactive" => BadgeType.Secondary,
            "error" => BadgeType.Danger,
            _ => BadgeType.Info
        };

        return htmlHelper.Badge(status, badgeType);
    }

    public static IHtmlContent CountBadge(
        this IHtmlHelper htmlHelper,
        int count,
        int warningThreshold = 10,
        int dangerThreshold = 50)
    {
        var badgeType = count switch
        {
            var c when c >= dangerThreshold => BadgeType.Danger,
            var c when c >= warningThreshold => BadgeType.Warning,
            _ => BadgeType.Info
        };

        return htmlHelper.Badge(count.ToString(), badgeType, isPill: true);
    }
}

public enum BadgeType
{
    Primary,
    Secondary,
    Success,
    Danger,
    Warning,
    Info,
    Light,
    Dark
}

// Usage
@Html.Badge("New", BadgeType.Success, isPill: true)
// <span class="badge badge-success badge-pill">New</span>

@Html.StatusBadge("Active")
// <span class="badge badge-success">Active</span>

@Html.CountBadge(15)
// <span class="badge badge-warning badge-pill">15</span>
```

### 5. Pagination Helper

```csharp
public static class PaginationHelper
{
    public static IHtmlContent Pagination(
        this IHtmlHelper htmlHelper,
        int currentPage,
        int totalPages,
        Func<int, string> urlBuilder,
        int maxPagesToShow = 5)
    {
        if (totalPages <= 1)
        {
            return HtmlString.Empty;
        }

        var nav = new TagBuilder("nav");
        nav.Attributes["aria-label"] = "Page navigation";

        var ul = new TagBuilder("ul");
        ul.AddCssClass("pagination");

        // Previous button
        var prevLi = CreatePageItem("Previous", urlBuilder(currentPage - 1), currentPage == 1);
        ul.InnerHtml.AppendHtml(prevLi);

        // Calculate page range
        int startPage = Math.Max(1, currentPage - maxPagesToShow / 2);
        int endPage = Math.Min(totalPages, startPage + maxPagesToShow - 1);

        // Adjust start if end is at max
        startPage = Math.Max(1, endPage - maxPagesToShow + 1);

        // First page
        if (startPage > 1)
        {
            ul.InnerHtml.AppendHtml(CreatePageItem("1", urlBuilder(1), false));

            if (startPage > 2)
            {
                ul.InnerHtml.AppendHtml(CreateDisabledPageItem("..."));
            }
        }

        // Page numbers
        for (int i = startPage; i <= endPage; i++)
        {
            var isActive = i == currentPage;
            ul.InnerHtml.AppendHtml(CreatePageItem(i.ToString(), urlBuilder(i), false, isActive));
        }

        // Last page
        if (endPage < totalPages)
        {
            if (endPage < totalPages - 1)
            {
                ul.InnerHtml.AppendHtml(CreateDisabledPageItem("..."));
            }

            ul.InnerHtml.AppendHtml(CreatePageItem(totalPages.ToString(), urlBuilder(totalPages), false));
        }

        // Next button
        var nextLi = CreatePageItem("Next", urlBuilder(currentPage + 1), currentPage == totalPages);
        ul.InnerHtml.AppendHtml(nextLi);

        nav.InnerHtml.AppendHtml(ul);

        return nav;
    }

    private static TagBuilder CreatePageItem(string text, string url, bool isDisabled, bool isActive = false)
    {
        var li = new TagBuilder("li");
        li.AddCssClass("page-item");

        if (isDisabled)
        {
            li.AddCssClass("disabled");
        }

        if (isActive)
        {
            li.AddCssClass("active");
        }

        var a = new TagBuilder("a");
        a.AddCssClass("page-link");
        a.Attributes["href"] = isDisabled ? "#" : url;
        a.InnerHtml.Append(text);

        li.InnerHtml.AppendHtml(a);

        return li;
    }

    private static TagBuilder CreateDisabledPageItem(string text)
    {
        var li = new TagBuilder("li");
        li.AddCssClass("page-item");
        li.AddCssClass("disabled");

        var span = new TagBuilder("span");
        span.AddCssClass("page-link");
        span.InnerHtml.Append(text);

        li.InnerHtml.AppendHtml(span);

        return li;
    }
}

// Usage
@Html.Pagination(
    currentPage: Model.CurrentPage,
    totalPages: Model.TotalPages,
    urlBuilder: page => Url.Action("Index", new { page = page }),
    maxPagesToShow: 5)
```

### 6. Table Helper

```csharp
public static class TableHelper
{
    public static IHtmlContent Table<T>(
        this IHtmlHelper htmlHelper,
        IEnumerable<T> items,
        params Expression<Func<T, object>>[] columns)
    {
        var table = new TagBuilder("table");
        table.AddCssClass("table table-striped");

        // Create header
        var thead = new TagBuilder("thead");
        var headerRow = new TagBuilder("tr");

        foreach (var column in columns)
        {
            var th = new TagBuilder("th");
            var memberExpression = GetMemberExpression(column);
            var propertyName = memberExpression.Member.Name;
            th.InnerHtml.Append(propertyName);
            headerRow.InnerHtml.AppendHtml(th);
        }

        thead.InnerHtml.AppendHtml(headerRow);
        table.InnerHtml.AppendHtml(thead);

        // Create body
        var tbody = new TagBuilder("tbody");

        foreach (var item in items)
        {
            var row = new TagBuilder("tr");

            foreach (var column in columns)
            {
                var td = new TagBuilder("td");
                var func = column.Compile();
                var value = func(item);
                td.InnerHtml.Append(value?.ToString() ?? string.Empty);
                row.InnerHtml.AppendHtml(td);
            }

            tbody.InnerHtml.AppendHtml(row);
        }

        table.InnerHtml.AppendHtml(tbody);

        return table;
    }

    private static MemberExpression GetMemberExpression<T>(Expression<Func<T, object>> expression)
    {
        if (expression.Body is MemberExpression memberExpression)
        {
            return memberExpression;
        }

        if (expression.Body is UnaryExpression unaryExpression &&
            unaryExpression.Operand is MemberExpression operand)
        {
            return operand;
        }

        throw new ArgumentException("Invalid expression");
    }
}

// Usage
@Html.Table(Model.Products,
    p => p.Id,
    p => p.Name,
    p => p.Price,
    p => p.Stock)
```

### 7. Form Group Helper

```csharp
public static class FormHelper
{
    public static IHtmlContent FormGroupFor<TModel, TProperty>(
        this IHtmlHelper<TModel> htmlHelper,
        Expression<Func<TModel, TProperty>> expression,
        string inputType = "text",
        object htmlAttributes = null)
    {
        var div = new TagBuilder("div");
        div.AddCssClass("form-group");

        // Label
        var label = htmlHelper.LabelFor(expression, new { @class = "control-label" });
        div.InnerHtml.AppendHtml(label);

        // Input
        var attributes = new Dictionary<string, object> { { "class", "form-control" } };

        if (htmlAttributes != null)
        {
            var additionalAttributes = HtmlHelper.AnonymousObjectToHtmlAttributes(htmlAttributes);
            foreach (var attr in additionalAttributes)
            {
                attributes[attr.Key] = attr.Value;
            }
        }

        var input = inputType.ToLower() switch
        {
            "textarea" => htmlHelper.TextAreaFor(expression, attributes),
            "password" => htmlHelper.PasswordFor(expression, attributes),
            "checkbox" => htmlHelper.CheckBoxFor(expression, attributes),
            _ => htmlHelper.TextBoxFor(expression, attributes)
        };

        div.InnerHtml.AppendHtml(input);

        // Validation message
        var validation = htmlHelper.ValidationMessageFor(expression, "", new { @class = "text-danger" });
        div.InnerHtml.AppendHtml(validation);

        return div;
    }

    public static IHtmlContent DropDownFormGroupFor<TModel, TProperty>(
        this IHtmlHelper<TModel> htmlHelper,
        Expression<Func<TModel, TProperty>> expression,
        IEnumerable<SelectListItem> selectList,
        string optionLabel = null)
    {
        var div = new TagBuilder("div");
        div.AddCssClass("form-group");

        // Label
        var label = htmlHelper.LabelFor(expression, new { @class = "control-label" });
        div.InnerHtml.AppendHtml(label);

        // Dropdown
        var dropdown = htmlHelper.DropDownListFor(
            expression,
            selectList,
            optionLabel,
            new { @class = "form-control" });

        div.InnerHtml.AppendHtml(dropdown);

        // Validation message
        var validation = htmlHelper.ValidationMessageFor(expression, "", new { @class = "text-danger" });
        div.InnerHtml.AppendHtml(validation);

        return div;
    }
}

// Usage
@Html.FormGroupFor(m => m.Name)
// <div class="form-group">
//   <label class="control-label" for="Name">Name</label>
//   <input class="form-control" id="Name" name="Name" type="text" value="..." />
//   <span class="text-danger field-validation-valid" data-valmsg-for="Name"></span>
// </div>

@Html.FormGroupFor(m => m.Description, "textarea", new { rows = 5 })

@Html.DropDownFormGroupFor(m => m.CategoryId, Model.Categories, "-- Select Category --")
```

### 8. Icon Helper

```csharp
public static class IconHelper
{
    public static IHtmlContent Icon(
        this IHtmlHelper htmlHelper,
        string iconName,
        IconLibrary library = IconLibrary.FontAwesome,
        object htmlAttributes = null)
    {
        var i = new TagBuilder("i");

        var iconClass = library switch
        {
            IconLibrary.FontAwesome => $"fa fa-{iconName}",
            IconLibrary.Bootstrap => $"bi bi-{iconName}",
            IconLibrary.MaterialIcons => "material-icons",
            _ => iconName
        };

        i.AddCssClass(iconClass);

        if (library == IconLibrary.MaterialIcons)
        {
            i.InnerHtml.Append(iconName);
        }

        if (htmlAttributes != null)
        {
            var attributes = HtmlHelper.AnonymousObjectToHtmlAttributes(htmlAttributes);
            i.MergeAttributes(attributes);
        }

        return i;
    }

    public static IHtmlContent IconButton(
        this IHtmlHelper htmlHelper,
        string text,
        string iconName,
        string url,
        string buttonClass = "btn-primary")
    {
        var a = new TagBuilder("a");
        a.AddCssClass($"btn {buttonClass}");
        a.Attributes["href"] = url;

        a.InnerHtml.AppendHtml(htmlHelper.Icon(iconName));
        a.InnerHtml.Append($" {text}");

        return a;
    }
}

public enum IconLibrary
{
    FontAwesome,
    Bootstrap,
    MaterialIcons
}

// Usage
@Html.Icon("user", IconLibrary.FontAwesome)
// <i class="fa fa-user"></i>

@Html.Icon("person", IconLibrary.MaterialIcons)
// <i class="material-icons">person</i>

@Html.IconButton("Add New", "plus", Url.Action("Create"), "btn-success")
// <a class="btn btn-success" href="/Products/Create">
//   <i class="fa fa-plus"></i> Add New
// </a>
```

### 9. Card Helper

```csharp
public static class CardHelper
{
    public static IHtmlContent Card(
        this IHtmlHelper htmlHelper,
        string title,
        IHtmlContent body,
        IHtmlContent footer = null,
        string headerClass = null)
    {
        var card = new TagBuilder("div");
        card.AddCssClass("card");

        // Header
        var cardHeader = new TagBuilder("div");
        cardHeader.AddCssClass("card-header");

        if (!string.IsNullOrEmpty(headerClass))
        {
            cardHeader.AddCssClass(headerClass);
        }

        cardHeader.InnerHtml.Append(title);
        card.InnerHtml.AppendHtml(cardHeader);

        // Body
        var cardBody = new TagBuilder("div");
        cardBody.AddCssClass("card-body");
        cardBody.InnerHtml.AppendHtml(body);
        card.InnerHtml.AppendHtml(cardBody);

        // Footer (optional)
        if (footer != null)
        {
            var cardFooter = new TagBuilder("div");
            cardFooter.AddCssClass("card-footer");
            cardFooter.InnerHtml.AppendHtml(footer);
            card.InnerHtml.AppendHtml(cardFooter);
        }

        return card;
    }
}

// Usage
@{
    var bodyContent = new HtmlContentBuilder();
    bodyContent.AppendHtml("<p>This is the card body content.</p>");

    var footerContent = new HtmlContentBuilder();
    footerContent.AppendHtml("<button class=\"btn btn-primary\">Action</button>");
}

@Html.Card("Card Title", bodyContent, footerContent, "bg-primary text-white")
```

### 10. Breadcrumb Helper

```csharp
public static class BreadcrumbHelper
{
    public static IHtmlContent Breadcrumb(
        this IHtmlHelper htmlHelper,
        params BreadcrumbItem[] items)
    {
        var nav = new TagBuilder("nav");
        nav.Attributes["aria-label"] = "breadcrumb";

        var ol = new TagBuilder("ol");
        ol.AddCssClass("breadcrumb");

        for (int i = 0; i < items.Length; i++)
        {
            var item = items[i];
            var isLast = i == items.Length - 1;

            var li = new TagBuilder("li");
            li.AddCssClass("breadcrumb-item");

            if (isLast)
            {
                li.AddCssClass("active");
                li.Attributes["aria-current"] = "page";
                li.InnerHtml.Append(item.Text);
            }
            else
            {
                var a = new TagBuilder("a");
                a.Attributes["href"] = item.Url;
                a.InnerHtml.Append(item.Text);
                li.InnerHtml.AppendHtml(a);
            }

            ol.InnerHtml.AppendHtml(li);
        }

        nav.InnerHtml.AppendHtml(ol);

        return nav;
    }
}

public class BreadcrumbItem
{
    public string Text { get; set; }
    public string Url { get; set; }
}

// Usage
@Html.Breadcrumb(
    new BreadcrumbItem { Text = "Home", Url = "/" },
    new BreadcrumbItem { Text = "Products", Url = "/Products" },
    new BreadcrumbItem { Text = "Details", Url = "#" })
```

### 11. Grid Helper

```csharp
public static class GridHelper
{
    public static IHtmlContent Grid<T>(
        this IHtmlHelper htmlHelper,
        IEnumerable<T> items,
        Action<GridBuilder<T>> configure)
    {
        var builder = new GridBuilder<T>(items);
        configure(builder);

        return builder.Render();
    }
}

public class GridBuilder<T>
{
    private readonly IEnumerable<T> _items;
    private readonly List<GridColumn<T>> _columns = new List<GridColumn<T>>();
    private string _tableClass = "table table-striped";

    public GridBuilder(IEnumerable<T> items)
    {
        _items = items;
    }

    public GridBuilder<T> Column(
        string header,
        Func<T, object> valueFunc,
        Func<T, string> urlFunc = null)
    {
        _columns.Add(new GridColumn<T>
        {
            Header = header,
            ValueFunc = valueFunc,
            UrlFunc = urlFunc
        });

        return this;
    }

    public GridBuilder<T> TableClass(string cssClass)
    {
        _tableClass = cssClass;
        return this;
    }

    public IHtmlContent Render()
    {
        var table = new TagBuilder("table");
        table.AddCssClass(_tableClass);

        // Header
        var thead = new TagBuilder("thead");
        var headerRow = new TagBuilder("tr");

        foreach (var column in _columns)
        {
            var th = new TagBuilder("th");
            th.InnerHtml.Append(column.Header);
            headerRow.InnerHtml.AppendHtml(th);
        }

        thead.InnerHtml.AppendHtml(headerRow);
        table.InnerHtml.AppendHtml(thead);

        // Body
        var tbody = new TagBuilder("tbody");

        foreach (var item in _items)
        {
            var row = new TagBuilder("tr");

            foreach (var column in _columns)
            {
                var td = new TagBuilder("td");
                var value = column.ValueFunc(item);

                if (column.UrlFunc != null)
                {
                    var a = new TagBuilder("a");
                    a.Attributes["href"] = column.UrlFunc(item);
                    a.InnerHtml.Append(value?.ToString() ?? string.Empty);
                    td.InnerHtml.AppendHtml(a);
                }
                else
                {
                    td.InnerHtml.Append(value?.ToString() ?? string.Empty);
                }

                row.InnerHtml.AppendHtml(td);
            }

            tbody.InnerHtml.AppendHtml(row);
        }

        table.InnerHtml.AppendHtml(tbody);

        return table;
    }
}

public class GridColumn<T>
{
    public string Header { get; set; }
    public Func<T, object> ValueFunc { get; set; }
    public Func<T, string> UrlFunc { get; set; }
}

// Usage
@Html.Grid(Model.Products, grid => grid
    .Column("ID", p => p.Id)
    .Column("Name", p => p.Name, p => Url.Action("Details", new { id = p.Id }))
    .Column("Price", p => $"${p.Price:N2}")
    .Column("Stock", p => p.Stock)
    .TableClass("table table-bordered table-hover"))
```

### 12. Testing Custom HTML Helpers

```csharp
using Xunit;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Moq;

public class HtmlHelperExtensionsTests
{
    [Fact]
    public void Alert_GeneratesCorrectHtml()
    {
        // Arrange
        var htmlHelper = CreateHtmlHelper<object>();

        // Act
        var result = htmlHelper.Alert("Test message", "success");

        // Assert
        var html = result.ToString();
        Assert.Contains("alert alert-success", html);
        Assert.Contains("Test message", html);
    }

    [Fact]
    public void Badge_GeneratesCorrectHtml()
    {
        // Arrange
        var htmlHelper = CreateHtmlHelper<object>();

        // Act
        var result = htmlHelper.Badge("New", BadgeType.Success, isPill: true);

        // Assert
        var html = result.ToString();
        Assert.Contains("badge badge-success badge-pill", html);
        Assert.Contains("New", html);
    }

    private IHtmlHelper<T> CreateHtmlHelper<T>()
    {
        var mockHtmlHelper = new Mock<IHtmlHelper<T>>();
        return mockHtmlHelper.Object;
    }
}
```

### 13. Registration and Configuration

```csharp
// For ASP.NET Core
// _ViewImports.cshtml
@using YourNamespace.Helpers
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@addTagHelper *, YourAssemblyName

// Startup.cs or Program.cs
services.AddControllersWithViews();
```

### 14. Summary - HTML Helpers vs Tag Helpers

| Feature | HTML Helpers | Tag Helpers |
|---------|--------------|-------------|
| **Syntax** | `@Html.TextBoxFor(m => m.Name)` | `<input asp-for="Name" />` |
| **Look** | C# code | HTML-like |
| **IntelliSense** | Limited | Full HTML IntelliSense |
| **Server-side** | Yes | Yes |
| **Readability** | Less readable | More readable |
| **Learning curve** | Steeper | Easier |
| **Custom creation** | Extension methods | Tag Helper classes |
| **ASP.NET Core** | Supported (legacy) | Preferred |

**Best Practices:**

```
✅ Use Tag Helpers in ASP.NET Core (preferred)
✅ Use HTML Helpers for backward compatibility
✅ Create custom helpers for repetitive markup
✅ Use strongly-typed helpers (e.g., TextBoxFor) over weakly-typed (TextBox)
✅ Provide meaningful parameter names
✅ Include proper HTML encoding
✅ Add XML documentation to custom helpers
✅ Write unit tests for complex helpers

❌ Don't create helpers for simple HTML
❌ Don't put business logic in helpers
❌ Don't create overly complex helpers
❌ Don't forget to handle null values
```

---

## Q59: Explain the Razor view engine

**Answer:**

Razor is a markup syntax for embedding server-side code into web pages in ASP.NET MVC. It combines C# code with HTML markup using the `@` symbol and provides a clean, fast, and fluid coding workflow.

### 1. Basic Razor Syntax

```csharp
@* Single-line comment *@
@*
   Multi-line comment
   More comments here
*@

@* Code block *@
@{
    var name = "John Doe";
    var age = 30;
    var isActive = true;
}

@* Output variable *@
<h1>Welcome, @name!</h1>
<p>Age: @age</p>

@* Expression *@
<p>Next year: @(age + 1)</p>

@* HTML encoding is automatic *@
<p>@("<script>alert('XSS')</script>")</p>
@* Outputs: &lt;script&gt;alert('XSS')&lt;/script&gt; *@

@* Raw HTML output (use carefully!) *@
<div>@Html.Raw("<strong>Bold text</strong>")</div>

@* Conditional statements *@
@if (isActive)
{
    <p>User is active</p>
}
else
{
    <p>User is inactive</p>
}

@* Switch statement *@
@switch (age)
{
    case < 18:
        <p>Minor</p>
        break;
    case >= 18 and < 65:
        <p>Adult</p>
        break;
    default:
        <p>Senior</p>
        break;
}

@* Loops *@
@for (int i = 0; i < 5; i++)
{
    <p>Item @i</p>
}

@foreach (var item in Model.Items)
{
    <div>@item.Name</div>
}

@while (condition)
{
    <p>Processing...</p>
}

@* Multi-statement code block *@
@{
    var total = 0;
    foreach (var item in Model.Items)
    {
        total += item.Price;
    }
}
<p>Total: @total</p>
```

### 2. Working with Models

```csharp
@* Strongly-typed model *@
@model ProductViewModel

<h1>@Model.Name</h1>
<p>Price: $@Model.Price.ToString("N2")</p>
<p>Description: @Model.Description</p>

@* Accessing nested properties *@
<p>Category: @Model.Category.Name</p>
<p>Supplier: @Model.Supplier.Company</p>

@* Collections *@
@model List<ProductViewModel>

<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Price</th>
            <th>Stock</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var product in Model)
        {
            <tr>
                <td>@product.Name</td>
                <td>@product.Price.ToString("C")</td>
                <td>@product.Stock</td>
            </tr>
        }
    </tbody>
</table>

@* Null-conditional operator *@
<p>Manager: @Model.Manager?.Name ?? "Not assigned"</p>
```

### 3. Layout Pages

```csharp
// _Layout.cshtml
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - My Application</title>
    <link rel="stylesheet" href="~/css/site.css" />

    @* Optional section for additional head content *@
    @await RenderSectionAsync("Head", required: false)
</head>
<body>
    <header>
        <nav>
            @* Navigation content *@
        </nav>
    </header>

    <main>
        @* Main content from views *@
        @RenderBody()
    </main>

    <footer>
        <p>&copy; @DateTime.Now.Year - My Application</p>
    </footer>

    <script src="~/js/site.js"></script>

    @* Required section for scripts *@
    @await RenderSectionAsync("Scripts", required: true)
</body>
</html>

// Index.cshtml (using the layout)
@{
    ViewData["Title"] = "Home Page";
    Layout = "_Layout"; // Or set in _ViewStart.cshtml
}

<h1>@ViewData["Title"]</h1>
<p>Welcome to our application!</p>

@section Head {
    <link rel="stylesheet" href="~/css/home.css" />
}

@section Scripts {
    <script src="~/js/home.js"></script>
}

// _ViewStart.cshtml (auto-applied to all views)
@{
    Layout = "_Layout";
}
```

### 4. Partial Views

```csharp
@* Render partial view *@
@await Html.PartialAsync("_ProductCard", product)

@* Using tag helper *@
<partial name="_ProductCard" model="product" />

@* Partial with ViewData *@
@await Html.PartialAsync("_Breadcrumb", Model.Breadcrumbs, ViewData)

@* Conditional partial rendering *@
@if (User.IsInRole("Admin"))
{
    <partial name="_AdminTools" />
}
```

### 5. View Components

```csharp
@* Invoke view component *@
@await Component.InvokeAsync("Navigation", new { activeMenu = "Home" })

@* Tag helper syntax *@
<vc:navigation active-menu="Home"></vc:navigation>

@* With anonymous object *@
@await Component.InvokeAsync("ShoppingCart", new
{
    userId = Model.UserId,
    showMiniCart = true
})
```

### 6. Tag Helpers

```csharp
@* Form tag helpers *@
<form asp-controller="Products" asp-action="Create" method="post">
    <div class="form-group">
        <label asp-for="Name"></label>
        <input asp-for="Name" class="form-control" />
        <span asp-validation-for="Name" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="CategoryId"></label>
        <select asp-for="CategoryId" asp-items="Model.Categories" class="form-control">
            <option value="">-- Select Category --</option>
        </select>
        <span asp-validation-for="CategoryId" class="text-danger"></span>
    </div>

    <button type="submit" class="btn btn-primary">Create</button>
</form>

@* Anchor tag helper *@
<a asp-controller="Products" asp-action="Details" asp-route-id="@product.Id">
    View Details
</a>

@* Image tag helper (cache busting) *@
<img src="~/images/logo.png" asp-append-version="true" alt="Logo" />

@* Environment tag helper *@
<environment include="Development">
    <script src="~/js/site.js"></script>
</environment>

<environment exclude="Development">
    <script src="~/js/site.min.js" asp-append-version="true"></script>
</environment>

@* Cache tag helper *@
<cache expires-after="TimeSpan.FromMinutes(10)">
    @* Expensive content to generate *@
    @await Component.InvokeAsync("PopularProducts")
</cache>

<cache vary-by-user="true" expires-sliding="TimeSpan.FromMinutes(5)">
    @* User-specific cached content *@
    <div>Welcome, @User.Identity.Name</div>
</cache>
```

### 7. Directives

```csharp
@* Model directive *@
@model ProductViewModel

@* Using directive *@
@using MyApp.ViewModels
@using MyApp.Helpers

@* Inject directive (dependency injection in views) *@
@inject IProductService ProductService
@inject IConfiguration Configuration

@{
    var featuredProducts = await ProductService.GetFeaturedAsync();
    var appName = Configuration["AppName"];
}

<h1>@appName</h1>
@foreach (var product in featuredProducts)
{
    <div>@product.Name</div>
}

@* Inherits directive *@
@inherits CustomRazorPage<ProductViewModel>

@* AddTagHelper directive *@
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@addTagHelper *, MyApp

@* RemoveTagHelper directive *@
@removeTagHelper Microsoft.AspNetCore.Mvc.TagHelpers.FormTagHelper, Microsoft.AspNetCore.Mvc.TagHelpers

@* TagHelperPrefix directive *@
@tagHelperPrefix app

@* Functions directive *@
@functions {
    public string FormatPrice(decimal price)
    {
        return $"${price:N2}";
    }

    public bool IsDiscounted(Product product)
    {
        return product.DiscountPercent > 0;
    }
}

<p>Price: @FormatPrice(Model.Price)</p>
@if (IsDiscounted(Model))
{
    <span class="badge badge-danger">On Sale!</span>
}
```

### 8. ViewData, ViewBag, and TempData

```csharp
@* ViewData (dictionary) *@
@{
    ViewData["Title"] = "Home Page";
    ViewData["MetaDescription"] = "Welcome to our site";
}

<h1>@ViewData["Title"]</h1>
<meta name="description" content="@ViewData["MetaDescription"]" />

@* ViewBag (dynamic) *@
@{
    ViewBag.Title = "Products";
    ViewBag.Categories = new SelectList(categories, "Id", "Name");
}

<h1>@ViewBag.Title</h1>
<select asp-items="@ViewBag.Categories"></select>

@* TempData (persists across redirect) *@
@if (TempData["SuccessMessage"] != null)
{
    <div class="alert alert-success">
        @TempData["SuccessMessage"]
    </div>
}

@if (TempData["ErrorMessage"] != null)
{
    <div class="alert alert-danger">
        @TempData["ErrorMessage"]
    </div>
}
```

### 9. Helper Methods and Reusable Code

```csharp
@* Helper method *@
@helper RenderProduct(Product product)
{
    <div class="product-card">
        <h3>@product.Name</h3>
        <p>@product.Price.ToString("C")</p>
    </div>
}

@* Note: @helper is not supported in ASP.NET Core. Use local functions instead *@

@* ASP.NET Core approach - Local function *@
@{
    void RenderProduct(Product product)
    {
        <div class="product-card">
            <h3>@product.Name</h3>
            <p>@product.Price.ToString("C")</p>
        </div>
    }
}

@foreach (var product in Model.Products)
{
    RenderProduct(product);
}

@* Template delegate *@
@{
    Func<Product, IHtmlContent> productTemplate = @<div class="product">
        <h3>@item.Name</h3>
        <p>$@item.Price</p>
    </div>;
}

@foreach (var product in Model.Products)
{
    @productTemplate(product)
}
```

### 10. String Interpolation and Expressions

```csharp
@* Simple expressions *@
<p>@Model.Name</p>

@* Complex expressions require parentheses *@
<p>@(Model.FirstName + " " + Model.LastName)</p>

@* String interpolation *@
@{
    var firstName = "John";
    var lastName = "Doe";
}
<p>@($"{firstName} {lastName}")</p>

@* Escape @ symbol *@
<p>Email: user@@example.com</p>

@* Conditional (ternary) operator *@
<span class="badge badge-@(Model.IsActive ? "success" : "secondary")">
    @(Model.IsActive ? "Active" : "Inactive")
</span>

@* Null-coalescing operator *@
<p>Description: @(Model.Description ?? "No description available")</p>
```

### 11. ViewImports and ViewStart

```csharp
// _ViewImports.cshtml (global using and directives)
@using MyApp
@using MyApp.ViewModels
@using MyApp.Extensions
@using Microsoft.AspNetCore.Mvc.Localization

@inject IViewLocalizer Localizer
@inject IHtmlLocalizer<SharedResource> SharedLocalizer

@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@addTagHelper *, MyApp.TagHelpers

// _ViewStart.cshtml (runs before each view)
@{
    Layout = "_Layout";
}

// Can also have folder-specific _ViewStart.cshtml
// /Views/Admin/_ViewStart.cshtml
@{
    Layout = "_AdminLayout";
}
```

### 12. HTML Encoding

```csharp
@* Automatic HTML encoding *@
@{
    var userInput = "<script>alert('XSS');</script>";
}
<p>@userInput</p>
@* Output: &lt;script&gt;alert('XSS');&lt;/script&gt; *@

@* Raw HTML output (unsafe!) *@
<div>@Html.Raw(userInput)</div>
@* Output: <script>alert('XSS');</script> (actual script tag!) *@

@* Safe approach - use AntiXss or sanitize first *@
@{
    var sanitizedHtml = HtmlSanitizer.Sanitize(userInput);
}
<div>@Html.Raw(sanitizedHtml)</div>
```

### 13. Working with URLs

```csharp
@* Generate URL *@
<a href="@Url.Action("Details", "Products", new { id = product.Id })">
    View Details
</a>

<a href="@Url.RouteUrl("ProductDetails", new { id = product.Id })">
    View Details
</a>

@* Absolute URL *@
<a href="@Url.Action("Details", "Products", new { id = 1 }, protocol: Request.Scheme)">
    Full URL
</a>

@* Content URL (for static files) *@
<link rel="stylesheet" href="@Url.Content("~/css/site.css")" />
<script src="@Url.Content("~/js/site.js")"></script>
```

### 14. Sections and Optional Sections

```csharp
// Layout
<!DOCTYPE html>
<html>
<head>
    @* Required section *@
    @await RenderSectionAsync("Styles", required: true)
</head>
<body>
    @RenderBody()

    @* Optional section *@
    @await RenderSectionAsync("Scripts", required: false)

    @* Optional section with default content *@
    @if (IsSectionDefined("Footer"))
    {
        @await RenderSectionAsync("Footer")
    }
    else
    {
        <footer>
            <p>Default footer content</p>
        </footer>
    }
</body>
</html>

// View
@section Styles {
    <link rel="stylesheet" href="~/css/custom.css" />
}

@section Scripts {
    <script src="~/js/custom.js"></script>
    <script>
        $(document).ready(function() {
            // Custom JavaScript
        });
    </script>
}

@section Footer {
    <footer>
        <p>Custom footer for this page</p>
    </footer>
}
```

### 15. Razor Pages (Alternative to MVC Views)

```csharp
// Index.cshtml.cs (Page Model)
public class IndexModel : PageModel
{
    private readonly IProductService _productService;

    public IndexModel(IProductService productService)
    {
        _productService = productService;
    }

    public List<Product> Products { get; set; }

    [BindProperty]
    public SearchFilter Filter { get; set; }

    public async Task OnGetAsync()
    {
        Products = await _productService.GetAllAsync();
    }

    public async Task<IActionResult> OnPostSearchAsync()
    {
        Products = await _productService.SearchAsync(Filter);
        return Page();
    }
}

// Index.cshtml (Razor Page)
@page
@model IndexModel
@{
    ViewData["Title"] = "Products";
}

<h1>Products</h1>

<form method="post" asp-page-handler="Search">
    <input asp-for="Filter.Keyword" class="form-control" />
    <button type="submit" class="btn btn-primary">Search</button>
</form>

<div class="products">
    @foreach (var product in Model.Products)
    {
        <div class="product-card">
            <h3>@product.Name</h3>
            <p>@product.Price.ToString("C")</p>
        </div>
    }
</div>
```

### 16. Advanced Razor Features

```csharp
@* Conditional attributes *@
<div class="product @(Model.IsNew ? "new-product" : "")"
     data-id="@Model.Id">
    @Model.Name
</div>

@* Attribute with conditional rendering *@
<input type="text"
       value="@Model.Value"
       disabled="@(Model.IsReadOnly ? "disabled" : null)" />

@* Multiple attributes conditionally *@
<button class="btn @(Model.IsPrimary ? "btn-primary" : "btn-secondary")"
        @(Model.IsDisabled ? "disabled" : "")>
    @Model.Text
</button>

@* Async operations in views (use sparingly) *@
@{
    var data = await SomeAsyncOperation();
}
<div>@data</div>

@* LINQ in Razor *@
@{
    var activeProducts = Model.Products.Where(p => p.IsActive).OrderBy(p => p.Name);
    var totalPrice = Model.Items.Sum(i => i.Price);
    var maxPrice = Model.Products.Max(p => p.Price);
}

<p>Total: @totalPrice.ToString("C")</p>
<p>Max Price: @maxPrice.ToString("C")</p>

@foreach (var product in activeProducts)
{
    <div>@product.Name</div>
}
```

### 17. Error Handling in Views

```csharp
@* Try-catch in code block *@
@{
    try
    {
        var result = SomeOperation();
    }
    catch (Exception ex)
    {
        <div class="alert alert-danger">
            Error: @ex.Message
        </div>
    }
}

@* Null checking *@
@if (Model?.Products != null && Model.Products.Any())
{
    @foreach (var product in Model.Products)
    {
        <div>@product.Name</div>
    }
}
else
{
    <p>No products found.</p>
}

@* Display error view *@
@if (ViewData.ModelState.ErrorCount > 0)
{
    <div class="alert alert-danger">
        <ul>
            @foreach (var error in ViewData.ModelState.Values.SelectMany(v => v.Errors))
            {
                <li>@error.ErrorMessage</li>
            }
        </ul>
    </div>
}
```

### 18. Localization in Razor

```csharp
@using Microsoft.AspNetCore.Mvc.Localization
@inject IViewLocalizer Localizer

<h1>@Localizer["Welcome"]</h1>
<p>@Localizer["ProductCount", Model.Products.Count]</p>

@* With HTML in resource *@
<div>@Localizer["<strong>Important</strong>: Read this carefully"]</div>

@* Shared resources *@
@inject IHtmlLocalizer<SharedResource> SharedLocalizer

<p>@SharedLocalizer["CommonMessage"]</p>
```

### 19. Performance Optimization

```csharp
@* Cache expensive operations *@
<cache expires-after="TimeSpan.FromMinutes(10)" vary-by="@Model.Category">
    @{
        var expensiveData = GetExpensiveData();
    }
    @foreach (var item in expensiveData)
    {
        <div>@item</div>
    }
</cache>

@* Distributed cache *@
<distributed-cache name="products" expires-after="TimeSpan.FromHours(1)">
    @await Component.InvokeAsync("ProductList")
</distributed-cache>

@* Preload scripts *@
<link rel="preload" href="~/js/app.js" as="script" />
<link rel="prefetch" href="~/css/styles.css" as="style" />
```

### 20. Best Practices

```csharp
// ✅ Good: Keep views simple
@model ProductViewModel

<h1>@Model.Name</h1>
<p>@Model.Description</p>

// ❌ Bad: Complex logic in views
@{
    var processedData = Model.Products
        .Where(p => p.IsActive && p.Stock > 0)
        .Select(p => new
        {
            p.Name,
            DiscountedPrice = p.Price * (1 - p.DiscountPercent / 100),
            Category = GetCategoryName(p.CategoryId) // Don't do this!
        })
        .OrderBy(p => p.DiscountedPrice)
        .Take(10)
        .ToList();
}
// Instead, move this logic to the controller or view model!

// ✅ Good: Use strongly-typed models
@model ProductViewModel
<h1>@Model.Name</h1>

// ❌ Bad: Use ViewBag for everything
<h1>@ViewBag.ProductName</h1>

// ✅ Good: Use tag helpers (ASP.NET Core)
<input asp-for="Name" class="form-control" />

// ❌ Bad: Inline HTML helpers where tag helpers suffice
@Html.TextBoxFor(m => m.Name, new { @class = "form-control" })

// ✅ Good: Proper null checking
@if (Model?.User?.Address != null)
{
    <p>@Model.User.Address.Street</p>
}

// ❌ Bad: Assuming values exist
<p>@Model.User.Address.Street</p> @* NullReferenceException! *@
```

**Key Features Summary:**

| Feature | Description | Example |
|---------|-------------|---------|
| **@ symbol** | Transition from HTML to C# | `@Model.Name` |
| **Code blocks** | Multi-statement C# code | `@{ var x = 10; }` |
| **Expressions** | Parenthesized expressions | `@(1 + 1)` |
| **Control structures** | if, foreach, for, while, switch | `@if (condition) { }` |
| **HTML encoding** | Automatic XSS protection | `@userInput` (encoded) |
| **Raw output** | Unencoded HTML | `@Html.Raw(html)` |
| **Comments** | Razor comments | `@* comment *@` |
| **Directives** | @model, @using, @inject | `@model ProductViewModel` |
| **Layouts** | Master pages | `@RenderBody()` |
| **Sections** | Named content blocks | `@section Scripts { }` |
| **Partial views** | Reusable components | `<partial name="_Card" />` |
| **Tag helpers** | HTML-friendly syntax | `<input asp-for="Name" />` |

**Advantages:**
- Clean, minimalist syntax
- IntelliSense support
- Type safety with strongly-typed models
- Automatic HTML encoding (XSS protection)
- Seamless C# integration
- Unit testable (Razor syntax parsers)

---

## Q60: What is model binding in ASP.NET MVC?

**Answer:**

Model binding is the process of automatically mapping HTTP request data to action method parameters in ASP.NET MVC. It converts incoming data from various sources (query strings, form data, route values, headers, body) into .NET types.

### 1. Simple Model Binding

```csharp
// Controller
public class ProductsController : Controller
{
    // Binding from query string: /Products/Search?keyword=laptop
    [HttpGet]
    public IActionResult Search(string keyword)
    {
        var results = _productService.Search(keyword);
        return View(results);
    }

    // Binding from route data: /Products/Details/5
    [HttpGet]
    [Route("Products/Details/{id}")]
    public IActionResult Details(int id)
    {
        var product = _productService.GetById(id);
        return View(product);
    }

    // Multiple parameters
    // /Products/Filter?category=electronics&minPrice=100&maxPrice=500
    [HttpGet]
    public IActionResult Filter(string category, decimal minPrice, decimal maxPrice)
    {
        var products = _productService.Filter(category, minPrice, maxPrice);
        return View(products);
    }
}
```

### 2. Complex Model Binding (Form Data)

```csharp
// Model
public class ProductViewModel
{
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; }

    [Required]
    [Range(0.01, 10000)]
    public decimal Price { get; set; }

    public string Description { get; set; }

    public int CategoryId { get; set; }

    public bool IsActive { get; set; }

    public DateTime ReleaseDate { get; set; }

    public List<string> Tags { get; set; }
}

// Controller
[HttpPost]
public IActionResult Create(ProductViewModel model)
{
    if (!ModelState.IsValid)
    {
        return View(model);
    }

    _productService.Create(model);
    return RedirectToAction("Index");
}

// View (Create.cshtml)
@model ProductViewModel

<form asp-action="Create" method="post">
    <div class="form-group">
        <label asp-for="Name"></label>
        <input asp-for="Name" class="form-control" />
        <span asp-validation-for="Name" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Price"></label>
        <input asp-for="Price" type="number" step="0.01" class="form-control" />
        <span asp-validation-for="Price" class="text-danger"></span>
    </div>

    <div class="form-group">
        <label asp-for="Description"></label>
        <textarea asp-for="Description" class="form-control" rows="5"></textarea>
    </div>

    <div class="form-group">
        <label asp-for="CategoryId"></label>
        <select asp-for="CategoryId" asp-items="ViewBag.Categories" class="form-control">
            <option value="">-- Select Category --</option>
        </select>
        <span asp-validation-for="CategoryId" class="text-danger"></span>
    </div>

    <div class="form-check">
        <input asp-for="IsActive" class="form-check-input" />
        <label asp-for="IsActive" class="form-check-label"></label>
    </div>

    <div class="form-group">
        <label asp-for="ReleaseDate"></label>
        <input asp-for="ReleaseDate" type="date" class="form-control" />
    </div>

    <button type="submit" class="btn btn-primary">Create</button>
</form>
```

### 3. Binding Sources

```csharp
public class OrdersController : ControllerBase
{
    // From route: /api/orders/123
    [HttpGet("{id}")]
    public IActionResult Get([FromRoute] int id)
    {
        var order = _orderService.GetById(id);
        return Ok(order);
    }

    // From query string: /api/orders?status=pending&page=1
    [HttpGet]
    public IActionResult GetAll([FromQuery] string status, [FromQuery] int page = 1)
    {
        var orders = _orderService.GetByStatus(status, page);
        return Ok(orders);
    }

    // From request body (JSON)
    [HttpPost]
    public IActionResult Create([FromBody] OrderDto order)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var created = _orderService.Create(order);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }

    // From header
    [HttpGet]
    public IActionResult GetWithAuth([FromHeader(Name = "X-Api-Key")] string apiKey)
    {
        if (!_authService.ValidateApiKey(apiKey))
        {
            return Unauthorized();
        }

        return Ok();
    }

    // From form data
    [HttpPost]
    public IActionResult Upload([FromForm] IFormFile file, [FromForm] string description)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest("No file uploaded");
        }

        _fileService.Save(file, description);
        return Ok();
    }

    // Multiple sources
    [HttpPut("{id}")]
    public IActionResult Update(
        [FromRoute] int id,
        [FromBody] OrderDto order,
        [FromHeader(Name = "X-Request-Id")] string requestId)
    {
        _orderService.Update(id, order, requestId);
        return NoContent();
    }
}
```

### 4. Collection Binding

```csharp
// Binding arrays/lists from query string
// /Products/BulkUpdate?ids=1&ids=2&ids=3
[HttpGet]
public IActionResult BulkUpdate([FromQuery] List<int> ids)
{
    var products = _productService.GetByIds(ids);
    return View(products);
}

// Alternative syntax: /Products/BulkUpdate?ids=1,2,3
[HttpGet]
public IActionResult BulkUpdate([FromQuery] string ids)
{
    var idList = ids.Split(',').Select(int.Parse).ToList();
    var products = _productService.GetByIds(idList);
    return View(products);
}

// Binding complex collections from form
public class OrderViewModel
{
    public int CustomerId { get; set; }
    public List<OrderItemViewModel> Items { get; set; }
}

public class OrderItemViewModel
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal Price { get; set; }
}

// View
<form asp-action="CreateOrder" method="post">
    <input asp-for="CustomerId" type="hidden" />

    @for (int i = 0; i < Model.Items.Count; i++)
    {
        <div class="order-item">
            <input asp-for="Items[i].ProductId" type="hidden" />

            <label>Quantity:</label>
            <input asp-for="Items[i].Quantity" type="number" />

            <label>Price:</label>
            <input asp-for="Items[i].Price" type="number" step="0.01" />
        </div>
    }

    <button type="submit">Create Order</button>
</form>

// Controller
[HttpPost]
public IActionResult CreateOrder(OrderViewModel model)
{
    if (!ModelState.IsValid)
    {
        return View(model);
    }

    _orderService.Create(model);
    return RedirectToAction("Confirmation");
}

// Posted form data:
// CustomerId=123
// Items[0].ProductId=1
// Items[0].Quantity=2
// Items[0].Price=99.99
// Items[1].ProductId=2
// Items[1].Quantity=1
// Items[1].Price=149.99
```

### 5. Nested Model Binding

```csharp
public class CustomerViewModel
{
    public int Id { get; set; }
    public string Name { get; set; }
    public AddressViewModel BillingAddress { get; set; }
    public AddressViewModel ShippingAddress { get; set; }
    public List<ContactViewModel> Contacts { get; set; }
}

public class AddressViewModel
{
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string ZipCode { get; set; }
}

public class ContactViewModel
{
    public string Type { get; set; } // Phone, Email
    public string Value { get; set; }
}

// View
<form asp-action="CreateCustomer" method="post">
    <input asp-for="Name" class="form-control" />

    <h3>Billing Address</h3>
    <input asp-for="BillingAddress.Street" class="form-control" />
    <input asp-for="BillingAddress.City" class="form-control" />
    <input asp-for="BillingAddress.State" class="form-control" />
    <input asp-for="BillingAddress.ZipCode" class="form-control" />

    <h3>Shipping Address</h3>
    <input asp-for="ShippingAddress.Street" class="form-control" />
    <input asp-for="ShippingAddress.City" class="form-control" />
    <input asp-for="ShippingAddress.State" class="form-control" />
    <input asp-for="ShippingAddress.ZipCode" class="form-control" />

    <h3>Contacts</h3>
    @for (int i = 0; i < Model.Contacts.Count; i++)
    {
        <select asp-for="Contacts[i].Type" class="form-control">
            <option value="Phone">Phone</option>
            <option value="Email">Email</option>
        </select>
        <input asp-for="Contacts[i].Value" class="form-control" />
    }

    <button type="submit">Create</button>
</form>

// Form data:
// Name=John Doe
// BillingAddress.Street=123 Main St
// BillingAddress.City=New York
// BillingAddress.State=NY
// BillingAddress.ZipCode=10001
// ShippingAddress.Street=456 Oak Ave
// ... etc
// Contacts[0].Type=Phone
// Contacts[0].Value=555-1234
// Contacts[1].Type=Email
// Contacts[1].Value=john@example.com
```

### 6. Custom Model Binder

```csharp
// Custom model binder for DateTime with specific format
public class CustomDateTimeBinder : IModelBinder
{
    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        if (bindingContext == null)
        {
            throw new ArgumentNullException(nameof(bindingContext));
        }

        var modelName = bindingContext.ModelName;
        var valueProviderResult = bindingContext.ValueProvider.GetValue(modelName);

        if (valueProviderResult == ValueProviderResult.None)
        {
            return Task.CompletedTask;
        }

        bindingContext.ModelState.SetModelValue(modelName, valueProviderResult);

        var value = valueProviderResult.FirstValue;

        if (string.IsNullOrEmpty(value))
        {
            return Task.CompletedTask;
        }

        // Try to parse with custom format
        if (DateTime.TryParseExact(value, "yyyy-MM-dd",
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out var dateTime))
        {
            bindingContext.Result = ModelBindingResult.Success(dateTime);
        }
        else
        {
            bindingContext.ModelState.AddModelError(
                modelName,
                $"DateTime should be in format 'yyyy-MM-dd'");
        }

        return Task.CompletedTask;
    }
}

// Apply custom binder
public class ProductViewModel
{
    [ModelBinder(BinderType = typeof(CustomDateTimeBinder))]
    public DateTime ReleaseDate { get; set; }
}

// Or register globally
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers(options =>
        {
            options.ModelBinderProviders.Insert(0, new CustomDateTimeBinderProvider());
        });
    }
}

public class CustomDateTimeBinderProvider : IModelBinderProvider
{
    public IModelBinder GetBinder(ModelBinderProviderContext context)
    {
        if (context.Metadata.ModelType == typeof(DateTime) ||
            context.Metadata.ModelType == typeof(DateTime?))
        {
            return new CustomDateTimeBinder();
        }

        return null;
    }
}
```

### 7. Model Binding with File Uploads

```csharp
// Single file upload
[HttpPost]
public async Task<IActionResult> UploadFile(IFormFile file)
{
    if (file == null || file.Length == 0)
    {
        return BadRequest("No file selected");
    }

    var filePath = Path.Combine(_uploadPath, file.FileName);

    using (var stream = new FileStream(filePath, FileMode.Create))
    {
        await file.CopyToAsync(stream);
    }

    return Ok(new { fileName = file.FileName, size = file.Length });
}

// Multiple files
[HttpPost]
public async Task<IActionResult> UploadMultipleFiles(List<IFormFile> files)
{
    var uploadedFiles = new List<string>();

    foreach (var file in files)
    {
        if (file.Length > 0)
        {
            var filePath = Path.Combine(_uploadPath, file.FileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            uploadedFiles.Add(file.FileName);
        }
    }

    return Ok(new { count = uploadedFiles.Count, files = uploadedFiles });
}

// File upload with model
public class ProductUploadViewModel
{
    [Required]
    public string Name { get; set; }

    [Required]
    public decimal Price { get; set; }

    [Required]
    public IFormFile Image { get; set; }

    public List<IFormFile> AdditionalImages { get; set; }
}

[HttpPost]
public async Task<IActionResult> CreateWithImage(ProductUploadViewModel model)
{
    if (!ModelState.IsValid)
    {
        return BadRequest(ModelState);
    }

    // Save main image
    var mainImagePath = await SaveFileAsync(model.Image);

    // Save additional images
    var additionalImagePaths = new List<string>();
    if (model.AdditionalImages != null)
    {
        foreach (var image in model.AdditionalImages)
        {
            var imagePath = await SaveFileAsync(image);
            additionalImagePaths.Add(imagePath);
        }
    }

    var product = new Product
    {
        Name = model.Name,
        Price = model.Price,
        MainImage = mainImagePath,
        AdditionalImages = additionalImagePaths
    };

    _productService.Create(product);

    return Ok();
}

// View
<form asp-action="CreateWithImage" method="post" enctype="multipart/form-data">
    <input asp-for="Name" class="form-control" />
    <input asp-for="Price" class="form-control" />

    <label>Main Image:</label>
    <input asp-for="Image" type="file" accept="image/*" />

    <label>Additional Images:</label>
    <input asp-for="AdditionalImages" type="file" accept="image/*" multiple />

    <button type="submit">Create</button>
</form>
```

### 8. Bind Attribute (Include/Exclude Properties)

```csharp
// Include specific properties
[HttpPost]
public IActionResult Create([Bind("Name,Price,CategoryId")] Product product)
{
    // Only Name, Price, and CategoryId will be bound
    // Other properties will be ignored even if posted
    _productService.Create(product);
    return RedirectToAction("Index");
}

// Exclude specific properties
[HttpPost]
public IActionResult Update([Bind(Exclude = "Id,CreatedDate")] Product product)
{
    // Id and CreatedDate will not be bound from form data
    _productService.Update(product);
    return RedirectToAction("Index");
}

// Prefix for model binding
[HttpPost]
public IActionResult CreateOrder([Bind(Prefix = "Order")] OrderViewModel model)
{
    // Binds from Order.CustomerId, Order.TotalAmount, etc.
    _orderService.Create(model);
    return Ok();
}

// Multiple models with different prefixes
[HttpPost]
public IActionResult CreateCustomerWithAddress(
    [Bind(Prefix = "Customer")] CustomerViewModel customer,
    [Bind(Prefix = "Address")] AddressViewModel address)
{
    var customerId = _customerService.Create(customer);
    _addressService.Create(customerId, address);
    return RedirectToAction("Index");
}
```

### 9. Model Binding with JSON

```csharp
// Binding complex JSON from request body
public class ComplexOrderDto
{
    public int CustomerId { get; set; }
    public DateTime OrderDate { get; set; }
    public List<OrderItemDto> Items { get; set; }
    public ShippingAddressDto ShippingAddress { get; set; }
    public PaymentInfoDto Payment { get; set; }
}

public class OrderItemDto
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class ShippingAddressDto
{
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string ZipCode { get; set; }
}

public class PaymentInfoDto
{
    public string Method { get; set; } // CreditCard, PayPal
    public string TransactionId { get; set; }
    public decimal Amount { get; set; }
}

[HttpPost]
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    [HttpPost]
    public IActionResult CreateComplexOrder([FromBody] ComplexOrderDto order)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var orderId = _orderService.ProcessOrder(order);

        return CreatedAtAction(nameof(GetOrder), new { id = orderId }, order);
    }
}

// JSON request body:
/*
{
    "customerId": 123,
    "orderDate": "2024-01-15T10:30:00",
    "items": [
        {
            "productId": 1,
            "quantity": 2,
            "unitPrice": 99.99
        },
        {
            "productId": 2,
            "quantity": 1,
            "unitPrice": 149.99
        }
    ],
    "shippingAddress": {
        "street": "123 Main St",
        "city": "New York",
        "state": "NY",
        "zipCode": "10001"
    },
    "payment": {
        "method": "CreditCard",
        "transactionId": "TXN-12345",
        "amount": 349.97
    }
}
*/
```

### 10. Model Binding Validation

```csharp
// Model with data annotations
public class RegisterViewModel
{
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string Email { get; set; }

    [Required]
    [StringLength(100, MinimumLength = 6,
        ErrorMessage = "Password must be between 6 and 100 characters")]
    [DataType(DataType.Password)]
    public string Password { get; set; }

    [Required]
    [Compare("Password", ErrorMessage = "Passwords do not match")]
    [DataType(DataType.Password)]
    public string ConfirmPassword { get; set; }

    [Required]
    [StringLength(50)]
    public string FirstName { get; set; }

    [Required]
    [StringLength(50)]
    public string LastName { get; set; }

    [Required]
    [Range(18, 120, ErrorMessage = "Age must be between 18 and 120")]
    public int Age { get; set; }

    [Url(ErrorMessage = "Invalid URL format")]
    public string Website { get; set; }

    [Phone(ErrorMessage = "Invalid phone number")]
    public string PhoneNumber { get; set; }

    [RegularExpression(@"^\d{5}(-\d{4})?$",
        ErrorMessage = "Invalid ZIP code format")]
    public string ZipCode { get; set; }

    [Required]
    public bool AgreeToTerms { get; set; }
}

// Controller with validation
[HttpPost]
public IActionResult Register(RegisterViewModel model)
{
    // Model binding automatically validates

    if (!ModelState.IsValid)
    {
        // Return view with validation errors
        return View(model);
    }

    // Process registration
    _userService.Register(model);

    TempData["SuccessMessage"] = "Registration successful!";
    return RedirectToAction("Login");
}

// Checking specific properties
if (!ModelState.IsValid)
{
    var emailErrors = ModelState["Email"]?.Errors;
    if (emailErrors != null && emailErrors.Count > 0)
    {
        foreach (var error in emailErrors)
        {
            // Log or handle email-specific errors
            Console.WriteLine(error.ErrorMessage);
        }
    }

    return BadRequest(ModelState);
}

// Custom validation logic
if (!ModelState.IsValid)
{
    return View(model);
}

// Additional business validation
if (_userService.EmailExists(model.Email))
{
    ModelState.AddModelError("Email", "This email is already registered");
    return View(model);
}

if (!_termsService.ValidateVersion(model.TermsVersion))
{
    ModelState.AddModelError("AgreeToTerms", "Please accept the latest terms");
    return View(model);
}

// API response with validation errors
if (!ModelState.IsValid)
{
    var errors = ModelState
        .Where(x => x.Value.Errors.Count > 0)
        .Select(x => new
        {
            Field = x.Key,
            Errors = x.Value.Errors.Select(e => e.ErrorMessage).ToArray()
        })
        .ToList();

    return BadRequest(new { Message = "Validation failed", Errors = errors });
}
```

### 11. Model Binding Order of Precedence

```csharp
/*
Model Binding searches for data in this order:

1. Form values (HTTP POST)
2. Route values (e.g., {id} in URL)
3. Query string parameters

If a value is found in multiple sources, the first match is used.
*/

// Example: /Products/Update/5?id=10
[HttpPost]
[Route("Products/Update/{id}")]
public IActionResult Update(int id, ProductViewModel model)
{
    // id = 5 (from route, takes precedence over query string)
    // model binds from form data
    return Ok();
}

// Override binding order with attributes
[HttpPost]
public IActionResult Create(
    [FromRoute] int id,        // Only from route
    [FromQuery] string filter,  // Only from query string
    [FromBody] ProductDto product, // Only from request body
    [FromHeader(Name = "X-Api-Key")] string apiKey) // Only from header
{
    return Ok();
}
```

### 12. Best Practices

```
✅ Use strongly-typed models (avoid primitive obsession)
✅ Apply data annotations for validation
✅ Use [Bind] attribute carefully (can prevent over-posting attacks)
✅ Validate ModelState before processing
✅ Use specific binding sources ([FromBody], [FromQuery], etc.) in APIs
✅ Create separate DTOs/ViewModels (don't bind directly to domain entities)
✅ Handle file uploads with IFormFile
✅ Use custom model binders for complex scenarios
✅ Provide clear validation error messages

❌ Don't bind directly to database entities
❌ Don't trust client data without validation
❌ Don't expose sensitive properties to binding
❌ Don't put complex logic in custom model binders
❌ Don't ignore ModelState.IsValid
```

---
