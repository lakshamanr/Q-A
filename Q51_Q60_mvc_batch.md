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
