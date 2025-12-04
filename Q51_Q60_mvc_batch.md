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

(Continuing with Q53-Q60...)
