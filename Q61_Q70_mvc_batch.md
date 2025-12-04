# Section 2: ASP.NET MVC & Web Development (Q61-Q70)

## Q61: Explain model validation in ASP.NET MVC with data annotations

**Answer:**

Model validation in ASP.NET MVC ensures data integrity by validating user input before processing. Data annotations are attributes applied to model properties to define validation rules.

### 1. Built-in Data Annotations

```csharp
using System.ComponentModel.DataAnnotations;

public class UserRegistrationViewModel
{
    // Required validation
    [Required(ErrorMessage = "Name is required")]
    [Display(Name = "Full Name")]
    public string Name { get; set; }

    // String length validation
    [Required]
    [StringLength(100, MinimumLength = 3,
        ErrorMessage = "Username must be between 3 and 100 characters")]
    public string Username { get; set; }

    // Email validation
    [Required]
    [EmailAddress(ErrorMessage = "Invalid email address")]
    [Display(Name = "Email Address")]
    public string Email { get; set; }

    // Range validation
    [Required]
    [Range(18, 100, ErrorMessage = "Age must be between 18 and 100")]
    public int Age { get; set; }

    // RegularExpression validation
    [Required]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        ErrorMessage = "Password must contain at least 8 characters, one uppercase, one lowercase, one number and one special character")]
    [DataType(DataType.Password)]
    public string Password { get; set; }

    // Compare validation
    [Required]
    [Compare("Password", ErrorMessage = "Password and confirmation do not match")]
    [DataType(DataType.Password)]
    [Display(Name = "Confirm Password")]
    public string ConfirmPassword { get; set; }

    // Phone validation
    [Phone(ErrorMessage = "Invalid phone number")]
    [Display(Name = "Phone Number")]
    public string PhoneNumber { get; set; }

    // URL validation
    [Url(ErrorMessage = "Invalid URL format")]
    public string Website { get; set; }

    // Credit card validation
    [CreditCard(ErrorMessage = "Invalid credit card number")]
    [Display(Name = "Credit Card")]
    public string CreditCardNumber { get; set; }

    // MaxLength validation
    [MaxLength(500, ErrorMessage = "Bio cannot exceed 500 characters")]
    public string Bio { get; set; }

    // MinLength validation
    [MinLength(10, ErrorMessage = "Description must be at least 10 characters")]
    public string Description { get; set; }
}
```

### 2. Custom Data Annotations

```csharp
// Custom validation attribute - Future date
public class FutureDateAttribute : ValidationAttribute
{
    public override bool IsValid(object value)
    {
        if (value == null)
            return true;

        if (value is DateTime dateTime)
        {
            return dateTime > DateTime.Now;
        }

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return $"{name} must be a future date";
    }
}

// Custom validation attribute - Age restriction
public class MinimumAgeAttribute : ValidationAttribute
{
    private readonly int _minimumAge;

    public MinimumAgeAttribute(int minimumAge)
    {
        _minimumAge = minimumAge;
        ErrorMessage = $"You must be at least {minimumAge} years old";
    }

    public override bool IsValid(object value)
    {
        if (value == null)
            return true;

        if (value is DateTime birthDate)
        {
            var age = DateTime.Today.Year - birthDate.Year;
            if (birthDate.Date > DateTime.Today.AddYears(-age))
                age--;

            return age >= _minimumAge;
        }

        return false;
    }
}

// Custom validation attribute - File size
public class MaxFileSizeAttribute : ValidationAttribute
{
    private readonly int _maxFileSize;

    public MaxFileSizeAttribute(int maxFileSize)
    {
        _maxFileSize = maxFileSize;
    }

    public override bool IsValid(object value)
    {
        if (value == null)
            return true;

        if (value is IFormFile file)
        {
            return file.Length <= _maxFileSize;
        }

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return $"{name} cannot exceed {_maxFileSize / 1024 / 1024}MB";
    }
}

// Custom validation attribute - Allowed file extensions
public class AllowedExtensionsAttribute : ValidationAttribute
{
    private readonly string[] _extensions;

    public AllowedExtensionsAttribute(params string[] extensions)
    {
        _extensions = extensions;
    }

    public override bool IsValid(object value)
    {
        if (value == null)
            return true;

        if (value is IFormFile file)
        {
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            return _extensions.Contains(extension);
        }

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return $"{name} must be one of the following types: {string.Join(", ", _extensions)}";
    }
}

// Usage of custom attributes
public class EventViewModel
{
    [Required]
    [StringLength(200)]
    public string Title { get; set; }

    [Required]
    [FutureDate(ErrorMessage = "Event date must be in the future")]
    public DateTime EventDate { get; set; }

    [Required]
    [MinimumAge(18)]
    [Display(Name = "Date of Birth")]
    public DateTime DateOfBirth { get; set; }

    [MaxFileSize(5 * 1024 * 1024)] // 5MB
    [AllowedExtensions(".jpg", ".jpeg", ".png", ".pdf")]
    public IFormFile Attachment { get; set; }
}
```

### 3. IValidatableObject for Complex Validation

```csharp
public class BookingViewModel : IValidatableObject
{
    [Required]
    public DateTime CheckInDate { get; set; }

    [Required]
    public DateTime CheckOutDate { get; set; }

    [Required]
    [Range(1, 10)]
    public int NumberOfGuests { get; set; }

    [Required]
    public string RoomType { get; set; }

    public bool IsWeekendBooking { get; set; }

    public decimal TotalPrice { get; set; }

    // Custom validation logic
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // Check-out must be after check-in
        if (CheckOutDate <= CheckInDate)
        {
            yield return new ValidationResult(
                "Check-out date must be after check-in date",
                new[] { nameof(CheckOutDate) });
        }

        // Minimum stay validation
        var stayDuration = (CheckOutDate - CheckInDate).Days;
        if (stayDuration < 1)
        {
            yield return new ValidationResult(
                "Minimum stay is 1 night",
                new[] { nameof(CheckOutDate) });
        }

        // Weekend bookings require minimum 2 nights
        if (IsWeekendBooking && stayDuration < 2)
        {
            yield return new ValidationResult(
                "Weekend bookings require minimum 2 nights",
                new[] { nameof(CheckOutDate), nameof(IsWeekendBooking) });
        }

        // Maximum stay validation
        if (stayDuration > 30)
        {
            yield return new ValidationResult(
                "Maximum stay is 30 nights",
                new[] { nameof(CheckOutDate) });
        }

        // Business rule: Suite requires minimum 2 guests
        if (RoomType == "Suite" && NumberOfGuests < 2)
        {
            yield return new ValidationResult(
                "Suite bookings require minimum 2 guests",
                new[] { nameof(NumberOfGuests), nameof(RoomType) });
        }

        // Date range validation
        if (CheckInDate < DateTime.Today)
        {
            yield return new ValidationResult(
                "Check-in date cannot be in the past",
                new[] { nameof(CheckInDate) });
        }

        // Advance booking limit
        if (CheckInDate > DateTime.Today.AddMonths(12))
        {
            yield return new ValidationResult(
                "Bookings can only be made up to 12 months in advance",
                new[] { nameof(CheckInDate) });
        }
    }
}
```

### 4. Server-Side Validation in Controller

```csharp
public class ProductsController : Controller
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(ProductViewModel model)
    {
        // Check ModelState
        if (!ModelState.IsValid)
        {
            // Return view with validation errors
            return View(model);
        }

        // Additional business validation
        if (_productService.ProductNameExists(model.Name))
        {
            ModelState.AddModelError(nameof(model.Name),
                "A product with this name already exists");
            return View(model);
        }

        if (model.Price < model.CostPrice)
        {
            ModelState.AddModelError(nameof(model.Price),
                "Price cannot be less than cost price");
            return View(model);
        }

        // Save product
        _productService.Create(model);

        TempData["SuccessMessage"] = "Product created successfully";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Update(int id, ProductViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var existingProduct = _productService.GetById(id);
        if (existingProduct == null)
        {
            ModelState.AddModelError("", "Product not found");
            return View(model);
        }

        // Check specific fields
        var nameErrors = ModelState[nameof(model.Name)]?.Errors;
        if (nameErrors != null && nameErrors.Count > 0)
        {
            // Handle name validation errors specifically
            foreach (var error in nameErrors)
            {
                _logger.LogWarning($"Name validation error: {error.ErrorMessage}");
            }
        }

        _productService.Update(id, model);
        return RedirectToAction(nameof(Index));
    }

    // Manual validation
    [HttpPost]
    public IActionResult CreateManual(ProductViewModel model)
    {
        // Clear existing errors
        ModelState.Clear();

        // Manual validation
        if (string.IsNullOrWhiteSpace(model.Name))
        {
            ModelState.AddModelError(nameof(model.Name), "Name is required");
        }

        if (model.Price <= 0)
        {
            ModelState.AddModelError(nameof(model.Price), "Price must be greater than zero");
        }

        // Check if valid after manual validation
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        _productService.Create(model);
        return RedirectToAction(nameof(Index));
    }
}
```

### 5. Client-Side Validation (Unobtrusive JavaScript)

```html
<!-- View with client-side validation -->
@model ProductViewModel

@section Scripts {
    @* Include jQuery validation scripts *@
    <script src="~/lib/jquery-validation/dist/jquery.validate.min.js"></script>
    <script src="~/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js"></script>
}

<form asp-action="Create" method="post">
    <div asp-validation-summary="ModelOnly" class="text-danger"></div>

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
        <label asp-for="Email"></label>
        <input asp-for="Email" type="email" class="form-control" />
        <span asp-validation-for="Email" class="text-danger"></span>
    </div>

    <button type="submit" class="btn btn-primary">Submit</button>
</form>

<!-- Validation summary types -->
@* Display all errors *@
<div asp-validation-summary="All" class="text-danger"></div>

@* Display only model-level errors (not property-specific) *@
<div asp-validation-summary="ModelOnly" class="text-danger"></div>

@* Display no summary (only individual field errors) *@
<div asp-validation-summary="None" class="text-danger"></div>
```

### 6. Remote Validation (AJAX)

```csharp
// Model with remote validation
public class UserViewModel
{
    [Required]
    [StringLength(50)]
    [Remote(action: "VerifyUsername", controller: "Account",
            ErrorMessage = "Username already exists")]
    public string Username { get; set; }

    [Required]
    [EmailAddress]
    [Remote(action: "VerifyEmail", controller: "Account",
            AdditionalFields = nameof(UserId),
            ErrorMessage = "Email already in use")]
    public string Email { get; set; }

    public int? UserId { get; set; }
}

// Controller with remote validation actions
public class AccountController : Controller
{
    private readonly IUserService _userService;

    public AccountController(IUserService userService)
    {
        _userService = userService;
    }

    [AcceptVerbs("GET", "POST")]
    public IActionResult VerifyUsername(string username)
    {
        if (_userService.UsernameExists(username))
        {
            return Json($"Username '{username}' is already taken");
        }

        return Json(true);
    }

    [AcceptVerbs("GET", "POST")]
    public IActionResult VerifyEmail(string email, int? userId)
    {
        // Allow user to keep their own email during edit
        if (userId.HasValue)
        {
            var currentUser = _userService.GetById(userId.Value);
            if (currentUser?.Email == email)
            {
                return Json(true);
            }
        }

        if (_userService.EmailExists(email))
        {
            return Json($"Email '{email}' is already registered");
        }

        return Json(true);
    }

    // Advanced remote validation with complex logic
    [AcceptVerbs("GET", "POST")]
    public async Task<IActionResult> VerifyProductCode(string code, int? categoryId)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Json(true); // Let Required attribute handle this
        }

        var exists = await _productService.ProductCodeExistsAsync(code, categoryId);

        if (exists)
        {
            return Json($"Product code '{code}' already exists in this category");
        }

        // Additional validation
        if (!code.StartsWith("PRD-"))
        {
            return Json("Product code must start with 'PRD-'");
        }

        return Json(true);
    }
}
```

### 7. Conditional Validation

```csharp
// Custom conditional required attribute
public class RequiredIfAttribute : ValidationAttribute
{
    private readonly string _propertyName;
    private readonly object _desiredValue;

    public RequiredIfAttribute(string propertyName, object desiredValue)
    {
        _propertyName = propertyName;
        _desiredValue = desiredValue;
    }

    protected override ValidationResult IsValid(object value, ValidationContext context)
    {
        var property = context.ObjectType.GetProperty(_propertyName);

        if (property == null)
        {
            return new ValidationResult($"Unknown property: {_propertyName}");
        }

        var propertyValue = property.GetValue(context.ObjectInstance);

        if (Equals(propertyValue, _desiredValue))
        {
            if (value == null || string.IsNullOrWhiteSpace(value.ToString()))
            {
                return new ValidationResult(ErrorMessage ??
                    $"{context.DisplayName} is required when {_propertyName} is {_desiredValue}");
            }
        }

        return ValidationResult.Success;
    }
}

// Usage
public class ShippingViewModel
{
    [Required]
    public string ShippingMethod { get; set; } // Standard, Express, Pickup

    [RequiredIf("ShippingMethod", "Standard",
        ErrorMessage = "Delivery address is required for standard shipping")]
    public string DeliveryAddress { get; set; }

    [RequiredIf("ShippingMethod", "Pickup",
        ErrorMessage = "Store location is required for pickup")]
    public string PickupLocation { get; set; }

    [RequiredIf("ShippingMethod", "Express",
        ErrorMessage = "Phone number is required for express delivery")]
    [Phone]
    public string ContactPhone { get; set; }
}

// Another example - payment
public class PaymentViewModel
{
    [Required]
    public string PaymentMethod { get; set; } // CreditCard, BankTransfer, Cash

    [RequiredIf("PaymentMethod", "CreditCard")]
    [CreditCard]
    public string CardNumber { get; set; }

    [RequiredIf("PaymentMethod", "CreditCard")]
    [RegularExpression(@"^(0[1-9]|1[0-2])\/\d{2}$",
        ErrorMessage = "Invalid expiry date format (MM/YY)")]
    public string CardExpiry { get; set; }

    [RequiredIf("PaymentMethod", "BankTransfer")]
    public string BankAccountNumber { get; set; }
}
```

### 8. Validation Groups (FluentValidation Alternative)

```csharp
// Using FluentValidation library for complex scenarios
using FluentValidation;

public class ProductValidator : AbstractValidator<ProductViewModel>
{
    public ProductValidator()
    {
        // Basic rules
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .Length(3, 100).WithMessage("Name must be between 3 and 100 characters");

        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than zero")
            .LessThan(1000000).WithMessage("Price cannot exceed 1,000,000");

        RuleFor(x => x.Stock)
            .GreaterThanOrEqualTo(0).WithMessage("Stock cannot be negative");

        // Conditional validation
        When(x => x.IsDiscounted, () =>
        {
            RuleFor(x => x.DiscountPercent)
                .GreaterThan(0).WithMessage("Discount percent must be greater than 0")
                .LessThanOrEqualTo(100).WithMessage("Discount cannot exceed 100%");
        });

        // Custom validation
        RuleFor(x => x.DiscountedPrice)
            .Must((model, price) => price < model.Price)
            .When(x => x.IsDiscounted)
            .WithMessage("Discounted price must be less than regular price");

        // Async validation
        RuleFor(x => x.SKU)
            .NotEmpty()
            .MustAsync(async (sku, cancellation) =>
            {
                var exists = await _productRepository.SKUExistsAsync(sku);
                return !exists;
            })
            .WithMessage("SKU already exists");

        // Multiple properties
        RuleFor(x => new { x.StartDate, x.EndDate })
            .Must(x => x.EndDate > x.StartDate)
            .WithMessage("End date must be after start date");
    }
}

// Register in Startup.cs
services.AddControllersWithViews()
    .AddFluentValidation(fv => fv.RegisterValidatorsFromAssemblyContaining<ProductValidator>());
```

### 9. API Validation Response

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpPost]
    public IActionResult Create([FromBody] UserDto user)
    {
        if (!ModelState.IsValid)
        {
            // Return structured validation errors
            var errors = ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .Select(x => new
                {
                    Field = x.Key,
                    Errors = x.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                })
                .ToList();

            return BadRequest(new
            {
                Message = "Validation failed",
                Errors = errors
            });
        }

        var created = _userService.Create(user);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    // Custom validation response format
    [HttpPost("register")]
    public IActionResult Register([FromBody] RegisterDto model)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new ValidationErrorResponse
            {
                Type = "ValidationError",
                Title = "One or more validation errors occurred",
                Status = 400,
                Errors = ModelState.ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                )
            });
        }

        // Process registration
        return Ok();
    }

    [HttpGet("{id}")]
    public IActionResult GetById(int id)
    {
        var user = _userService.GetById(id);
        if (user == null)
        {
            return NotFound();
        }

        return Ok(user);
    }
}

public class ValidationErrorResponse
{
    public string Type { get; set; }
    public string Title { get; set; }
    public int Status { get; set; }
    public Dictionary<string, string[]> Errors { get; set; }
}
```

### 10. Global Validation Filter

```csharp
// Custom validation filter
public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
        {
            // For MVC, return view with model
            if (context.Controller is Controller controller)
            {
                var model = context.ActionArguments.Values.FirstOrDefault();
                context.Result = new ViewResult
                {
                    ViewData = controller.ViewData
                };
            }
            // For API, return BadRequest
            else if (context.Controller is ControllerBase)
            {
                var errors = context.ModelState
                    .Where(x => x.Value.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value.Errors.Select(e => e.ErrorMessage).ToArray()
                    );

                context.Result = new BadRequestObjectResult(new
                {
                    Message = "Validation failed",
                    Errors = errors
                });
            }
        }

        base.OnActionExecuting(context);
    }
}

// Register globally
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllersWithViews(options =>
        {
            // Automatically validate all requests
            options.Filters.Add<ValidateModelAttribute>();
        });
    }
}

// Or disable auto-validation and use attribute
[ApiController] // This enables automatic model validation
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    // Automatic validation - no need to check ModelState
    [HttpPost]
    public IActionResult Create([FromBody] ProductDto product)
    {
        // If we reach here, model is valid
        return Ok();
    }
}
```

### 11. Custom Validation Messages with Localization

```csharp
using System.ComponentModel.DataAnnotations;
using Microsoft.Extensions.Localization;

public class LocalizedProductViewModel
{
    [Required(ErrorMessageResourceType = typeof(Resources),
              ErrorMessageResourceName = "NameRequired")]
    [StringLength(100, MinimumLength = 3,
                  ErrorMessageResourceType = typeof(Resources),
                  ErrorMessageResourceName = "NameLength")]
    public string Name { get; set; }

    [Required(ErrorMessageResourceType = typeof(Resources),
              ErrorMessageResourceName = "PriceRequired")]
    [Range(0.01, 1000000,
           ErrorMessageResourceType = typeof(Resources),
           ErrorMessageResourceName = "PriceRange")]
    public decimal Price { get; set; }
}

// Resource file (Resources.resx)
/*
NameRequired: "Product name is required"
NameLength: "Product name must be between {2} and {1} characters"
PriceRequired: "Price is required"
PriceRange: "Price must be between {1} and {2}"
*/

// Using IStringLocalizer
public class ProductViewModelWithLocalizer
{
    private readonly IStringLocalizer<ProductViewModel> _localizer;

    [Required]
    public string Name { get; set; }

    public string GetLocalizedError(string propertyName)
    {
        return _localizer[$"{propertyName}Required"];
    }
}
```

### 12. Validation with Display Attributes

```csharp
public class EmployeeViewModel
{
    [Required]
    [Display(Name = "Employee ID", Prompt = "Enter employee ID",
             Description = "Unique identifier for the employee")]
    public string EmployeeId { get; set; }

    [Required]
    [Display(Name = "First Name", Order = 1)]
    public string FirstName { get; set; }

    [Required]
    [Display(Name = "Last Name", Order = 2)]
    public string LastName { get; set; }

    [Required]
    [EmailAddress]
    [Display(Name = "Email Address", Prompt = "name@example.com")]
    public string Email { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Date of Birth")]
    [DisplayFormat(DataFormatString = "{0:yyyy-MM-dd}", ApplyFormatInEditMode = true)]
    public DateTime DateOfBirth { get; set; }

    [DataType(DataType.Currency)]
    [Display(Name = "Annual Salary")]
    [DisplayFormat(DataFormatString = "{0:C}", ApplyFormatInEditMode = false)]
    public decimal Salary { get; set; }

    [Display(Name = "Active Employee")]
    public bool IsActive { get; set; }

    [Display(Name = "Profile Picture")]
    [DataType(DataType.Upload)]
    public IFormFile ProfilePicture { get; set; }
}
```

### 13. Validation Summary Display

```html
<!-- Display all validation errors in a summary -->
@if (!ViewData.ModelState.IsValid)
{
    <div class="alert alert-danger">
        <h4>Please correct the following errors:</h4>
        <ul>
            @foreach (var modelState in ViewData.ModelState.Values)
            {
                foreach (var error in modelState.Errors)
                {
                    <li>@error.ErrorMessage</li>
                }
            }
        </ul>
    </div>
}

<!-- Bootstrap styled validation summary -->
<div asp-validation-summary="All" class="alert alert-danger" role="alert"></div>

<!-- Custom validation summary with icons -->
@if (!ViewData.ModelState.IsValid)
{
    <div class="validation-summary">
        @foreach (var key in ViewData.ModelState.Keys)
        {
            var errors = ViewData.ModelState[key].Errors;
            if (errors.Count > 0)
            {
                <div class="validation-error">
                    <i class="fa fa-exclamation-circle"></i>
                    <strong>@key:</strong>
                    <ul>
                        @foreach (var error in errors)
                        {
                            <li>@error.ErrorMessage</li>
                        }
                    </ul>
                </div>
            }
        }
    </div>
}
```

### 14. Testing Validation

```csharp
using Xunit;
using System.ComponentModel.DataAnnotations;

public class ProductViewModelTests
{
    [Fact]
    public void Name_WhenEmpty_ShouldHaveValidationError()
    {
        // Arrange
        var model = new ProductViewModel
        {
            Name = "",
            Price = 100
        };

        var context = new ValidationContext(model);
        var results = new List<ValidationResult>();

        // Act
        var isValid = Validator.TryValidateObject(model, context, results, true);

        // Assert
        Assert.False(isValid);
        Assert.Contains(results, r => r.MemberNames.Contains(nameof(ProductViewModel.Name)));
    }

    [Fact]
    public void Price_WhenNegative_ShouldHaveValidationError()
    {
        // Arrange
        var model = new ProductViewModel
        {
            Name = "Test Product",
            Price = -10
        };

        var context = new ValidationContext(model);
        var results = new List<ValidationResult>();

        // Act
        var isValid = Validator.TryValidateObject(model, context, results, true);

        // Assert
        Assert.False(isValid);
        Assert.Contains(results, r =>
            r.MemberNames.Contains(nameof(ProductViewModel.Price)) &&
            r.ErrorMessage.Contains("greater than"));
    }

    [Fact]
    public void ValidModel_ShouldPassValidation()
    {
        // Arrange
        var model = new ProductViewModel
        {
            Name = "Test Product",
            Price = 99.99m,
            Stock = 10
        };

        var context = new ValidationContext(model);
        var results = new List<ValidationResult>();

        // Act
        var isValid = Validator.TryValidateObject(model, context, results, true);

        // Assert
        Assert.True(isValid);
        Assert.Empty(results);
    }
}
```

### 15. Best Practices Summary

```
✅ Always validate on server-side (client validation can be bypassed)
✅ Use data annotations for simple validation
✅ Implement IValidatableObject for complex cross-property validation
✅ Use FluentValidation for advanced scenarios
✅ Provide clear, user-friendly error messages
✅ Use localization for multi-language support
✅ Test validation logic with unit tests
✅ Use [Remote] validation for async checks
✅ Display validation errors near the input fields
✅ Use validation summary for overview of all errors

❌ Don't rely only on client-side validation
❌ Don't put business logic in validation attributes
❌ Don't create overly complex validation rules
❌ Don't forget to validate collections and nested objects
❌ Don't expose sensitive information in error messages
```

**Validation Flow:**

| Step | Client-Side | Server-Side |
|------|-------------|-------------|
| 1. User input | jQuery Validation | - |
| 2. Submit | Prevent if invalid | - |
| 3. Receive | - | Model binding |
| 4. Validate | - | Data annotations |
| 5. Custom | - | IValidatableObject |
| 6. Business | - | Controller logic |
| 7. Response | - | ModelState.IsValid |
| 8. Display | Inline errors | View with errors |

---

## Q62: What are Areas in ASP.NET MVC? How do you implement them?

**Answer:**

Areas in ASP.NET MVC provide a way to organize large applications into smaller functional groupings. Each area contains its own set of controllers, views, and models, creating logical separation within the application.

### 1. Creating an Area

```csharp
// Create Area using CLI
// dotnet aspnet-codegenerator area Admin

// Or manually create folder structure:
/*
Areas/
├── Admin/
│   ├── Controllers/
│   ├── Views/
│   │   ├── _ViewImports.cshtml
│   │   ├── _ViewStart.cshtml
│   │   └── Shared/
│   │       └── _Layout.cshtml
│   └── Models/
├── Customer/
│   ├── Controllers/
│   ├── Views/
│   └── Models/
└── Reports/
    ├── Controllers/
    ├── Views/
    └── Models/
*/

// Startup.cs or Program.cs - Configure area routing
public class Startup
{
    public void Configure(IApplicationBuilder app)
    {
        app.UseRouting();

        app.UseEndpoints(endpoints =>
        {
            // Area route (must come before default route)
            endpoints.MapControllerRoute(
                name: "areas",
                pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

            // Default route
            endpoints.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");
        });
    }
}

// Program.cs (.NET 6+)
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

var app = builder.Build();

app.UseRouting();

app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

### 2. Area Controller

```csharp
// Areas/Admin/Controllers/DashboardController.cs
using Microsoft.AspNetCore.Mvc;

namespace MyApp.Areas.Admin.Controllers
{
    [Area("Admin")] // Required attribute
    public class DashboardController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Statistics()
        {
            var stats = new
            {
                TotalUsers = 1500,
                TotalOrders = 3200,
                Revenue = 125000.00m
            };

            return View(stats);
        }
    }

    // Admin Products Controller
    [Area("Admin")]
    [Route("Admin/Products")]
    public class ProductsController : Controller
    {
        private readonly IProductService _productService;

        public ProductsController(IProductService productService)
        {
            _productService = productService;
        }

        [HttpGet]
        public IActionResult Index()
        {
            var products = _productService.GetAll();
            return View(products);
        }

        [HttpGet("Create")]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost("Create")]
        [ValidateAntiForgeryToken]
        public IActionResult Create(ProductViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            _productService.Create(model);
            TempData["SuccessMessage"] = "Product created successfully";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet("Edit/{id}")]
        public IActionResult Edit(int id)
        {
            var product = _productService.GetById(id);
            if (product == null)
            {
                return NotFound();
            }

            return View(product);
        }

        [HttpPost("Edit/{id}")]
        [ValidateAntiForgeryToken]
        public IActionResult Edit(int id, ProductViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            _productService.Update(id, model);
            TempData["SuccessMessage"] = "Product updated successfully";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost("Delete/{id}")]
        [ValidateAntiForgeryToken]
        public IActionResult Delete(int id)
        {
            _productService.Delete(id);
            TempData["SuccessMessage"] = "Product deleted successfully";
            return RedirectToAction(nameof(Index));
        }
    }
}
```

### 3. Area Views

```csharp
// Areas/Admin/Views/_ViewStart.cshtml
@{
    Layout = "_AdminLayout";
}

// Areas/Admin/Views/Shared/_AdminLayout.cshtml
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - Admin Panel</title>
    <link rel="stylesheet" href="~/css/admin.css" />
</head>
<body>
    <nav class="admin-nav">
        <div class="logo">Admin Panel</div>
        <ul>
            <li><a asp-area="Admin" asp-controller="Dashboard" asp-action="Index">Dashboard</a></li>
            <li><a asp-area="Admin" asp-controller="Products" asp-action="Index">Products</a></li>
            <li><a asp-area="Admin" asp-controller="Users" asp-action="Index">Users</a></li>
            <li><a asp-area="Admin" asp-controller="Orders" asp-action="Index">Orders</a></li>
            <li><a asp-area="Admin" asp-controller="Reports" asp-action="Index">Reports</a></li>
            <li><a asp-area="" asp-controller="Home" asp-action="Index">Back to Site</a></li>
        </ul>
    </nav>

    <div class="admin-container">
        <aside class="sidebar">
            @await RenderSectionAsync("Sidebar", required: false)
        </aside>

        <main class="admin-content">
            @if (TempData["SuccessMessage"] != null)
            {
                <div class="alert alert-success">@TempData["SuccessMessage"]</div>
            }

            @if (TempData["ErrorMessage"] != null)
            {
                <div class="alert alert-danger">@TempData["ErrorMessage"]</div>
            }

            @RenderBody()
        </main>
    </div>

    <script src="~/js/admin.js"></script>
    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>

// Areas/Admin/Views/Dashboard/Index.cshtml
@{
    ViewData["Title"] = "Admin Dashboard";
}

<h1>Dashboard</h1>

<div class="stats-grid">
    <div class="stat-card">
        <h3>Total Users</h3>
        <p class="stat-number">1,500</p>
        <a asp-area="Admin" asp-controller="Users" asp-action="Index">View All</a>
    </div>

    <div class="stat-card">
        <h3>Total Orders</h3>
        <p class="stat-number">3,200</p>
        <a asp-area="Admin" asp-controller="Orders" asp-action="Index">View All</a>
    </div>

    <div class="stat-card">
        <h3>Revenue</h3>
        <p class="stat-number">$125,000</p>
        <a asp-area="Admin" asp-controller="Reports" asp-action="Revenue">View Report</a>
    </div>

    <div class="stat-card">
        <h3>Products</h3>
        <p class="stat-number">450</p>
        <a asp-area="Admin" asp-controller="Products" asp-action="Index">Manage</a>
    </div>
</div>

// Areas/Admin/Views/Products/Index.cshtml
@model List<ProductViewModel>

@{
    ViewData["Title"] = "Products Management";
}

<div class="page-header">
    <h1>Products</h1>
    <a asp-action="Create" class="btn btn-primary">
        <i class="fa fa-plus"></i> Add Product
    </a>
</div>

<table class="table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Category</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var product in Model)
        {
            <tr>
                <td>@product.Id</td>
                <td>@product.Name</td>
                <td>@product.Price.ToString("C")</td>
                <td>@product.Stock</td>
                <td>@product.Category</td>
                <td>
                    <span class="badge badge-@(product.IsActive ? "success" : "secondary")">
                        @(product.IsActive ? "Active" : "Inactive")
                    </span>
                </td>
                <td>
                    <a asp-action="Edit" asp-route-id="@product.Id" class="btn btn-sm btn-warning">Edit</a>
                    <form asp-action="Delete" asp-route-id="@product.Id" method="post" style="display:inline;">
                        <button type="submit" class="btn btn-sm btn-danger"
                                onclick="return confirm('Delete this product?')">
                            Delete
                        </button>
                    </form>
                </td>
            </tr>
        }
    </tbody>
</table>
```

### 4. Multiple Areas Example

```csharp
// Areas/Customer/Controllers/AccountController.cs
namespace MyApp.Areas.Customer.Controllers
{
    [Area("Customer")]
    [Route("Customer/Account")]
    public class AccountController : Controller
    {
        [HttpGet("Profile")]
        public IActionResult Profile()
        {
            return View();
        }

        [HttpGet("Orders")]
        public IActionResult Orders()
        {
            return View();
        }

        [HttpGet("Settings")]
        public IActionResult Settings()
        {
            return View();
        }
    }

    [Area("Customer")]
    [Route("Customer/Orders")]
    public class OrdersController : Controller
    {
        private readonly IOrderService _orderService;

        public OrdersController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public IActionResult Index()
        {
            var customerId = GetCurrentCustomerId();
            var orders = _orderService.GetByCustomerId(customerId);
            return View(orders);
        }

        [HttpGet("Details/{id}")]
        public IActionResult Details(int id)
        {
            var order = _orderService.GetById(id);
            if (order == null || order.CustomerId != GetCurrentCustomerId())
            {
                return NotFound();
            }

            return View(order);
        }

        private int GetCurrentCustomerId()
        {
            // Get from claims or session
            return int.Parse(User.FindFirst("CustomerId")?.Value ?? "0");
        }
    }
}

// Areas/Reports/Controllers/SalesController.cs
namespace MyApp.Areas.Reports.Controllers
{
    [Area("Reports")]
    [Authorize(Roles = "Admin,Manager")]
    public class SalesController : Controller
    {
        private readonly IReportService _reportService;

        public SalesController(IReportService reportService)
        {
            _reportService = reportService;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public IActionResult Daily(DateTime? date)
        {
            var reportDate = date ?? DateTime.Today;
            var report = _reportService.GetDailySales(reportDate);
            return View(report);
        }

        [HttpGet]
        public IActionResult Monthly(int? year, int? month)
        {
            var reportYear = year ?? DateTime.Today.Year;
            var reportMonth = month ?? DateTime.Today.Month;
            var report = _reportService.GetMonthlySales(reportYear, reportMonth);
            return View(report);
        }

        [HttpGet]
        public async Task<IActionResult> ExportToPdf(DateTime startDate, DateTime endDate)
        {
            var pdfBytes = await _reportService.GenerateSalesPdfAsync(startDate, endDate);
            return File(pdfBytes, "application/pdf", $"Sales_Report_{startDate:yyyyMMdd}-{endDate:yyyyMMdd}.pdf");
        }
    }
}
```

### 5. Area Navigation and Linking

```csharp
// In any view - linking to area controllers
@* Link to Admin area *@
<a asp-area="Admin" asp-controller="Dashboard" asp-action="Index">Admin Dashboard</a>

@* Link to Customer area *@
<a asp-area="Customer" asp-controller="Account" asp-action="Profile">My Profile</a>

@* Link to non-area controller (main site) *@
<a asp-area="" asp-controller="Home" asp-action="Index">Home</a>

@* Link with route parameters *@
<a asp-area="Admin" asp-controller="Products" asp-action="Edit" asp-route-id="@product.Id">
    Edit Product
</a>

// Programmatic navigation in controller
public class SomeController : Controller
{
    public IActionResult GoToAdmin()
    {
        // Redirect to area
        return RedirectToAction("Index", "Dashboard", new { area = "Admin" });
    }

    public IActionResult GoToMainSite()
    {
        // Redirect to non-area controller
        return RedirectToAction("Index", "Home", new { area = "" });
    }

    public IActionResult GoWithParameters()
    {
        return RedirectToAction("Edit", "Products",
            new { area = "Admin", id = 123 });
    }
}

// Using Url.Action
@{
    var adminUrl = Url.Action("Index", "Dashboard", new { area = "Admin" });
    var customerUrl = Url.Action("Profile", "Account", new { area = "Customer" });
}

<a href="@adminUrl">Admin Panel</a>
<a href="@customerUrl">Customer Profile</a>
```

### 6. Area-Specific _ViewImports

```csharp
// Areas/Admin/Views/_ViewImports.cshtml
@using MyApp.Areas.Admin
@using MyApp.Areas.Admin.Models
@using MyApp.Areas.Admin.ViewModels
@using MyApp.Services
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@addTagHelper *, MyApp

// Areas/Customer/Views/_ViewImports.cshtml
@using MyApp.Areas.Customer
@using MyApp.Areas.Customer.Models
@using MyApp.Areas.Customer.ViewModels
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

// Main Views/_ViewImports.cshtml
@using MyApp
@using MyApp.Models
@using MyApp.ViewModels
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
```

### 7. Area Authorization

```csharp
// Require authentication for entire area
[Area("Admin")]
[Authorize(Roles = "Admin")]
public class DashboardController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}

// Different authorization per controller
[Area("Customer")]
[Authorize] // All authenticated users
public class ProfileController : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    [Authorize(Roles = "Premium")]
    public IActionResult PremiumFeatures()
    {
        return View();
    }
}

// Authorization filter for area
public class AdminAreaAuthorization : IAuthorizationFilter
{
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var area = context.RouteData.Values["area"]?.ToString();

        if (area == "Admin")
        {
            if (!context.HttpContext.User.IsInRole("Admin"))
            {
                context.Result = new RedirectToActionResult(
                    "AccessDenied", "Account", new { area = "" });
            }
        }
    }
}

// Register in Startup.cs
services.AddControllersWithViews(options =>
{
    options.Filters.Add<AdminAreaAuthorization>();
});
```

### 8. Area with API Controllers

```csharp
// Areas/Api/Controllers/ProductsController.cs
namespace MyApp.Areas.Api.Controllers
{
    [Area("Api")]
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly IProductService _productService;

        public ProductsController(IProductService productService)
        {
            _productService = productService;
        }

        [HttpGet]
        public IActionResult GetAll()
        {
            var products = _productService.GetAll();
            return Ok(products);
        }

        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var product = _productService.GetById(id);
            if (product == null)
            {
                return NotFound();
            }

            return Ok(product);
        }

        [HttpPost]
        public IActionResult Create([FromBody] ProductDto product)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var created = _productService.Create(product);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }
    }
}
```

### 9. Shared Resources Between Areas

```csharp
// Shared/_Layout.cshtml (used by all areas)
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>@ViewData["Title"] - My Application</title>
    <link rel="stylesheet" href="~/css/site.css" />
</head>
<body>
    <nav class="navbar">
        <a asp-area="" asp-controller="Home" asp-action="Index">Home</a>

        @if (User.IsInRole("Admin"))
        {
            <a asp-area="Admin" asp-controller="Dashboard" asp-action="Index">Admin</a>
        }

        @if (User.Identity.IsAuthenticated)
        {
            <a asp-area="Customer" asp-controller="Account" asp-action="Profile">My Account</a>
        }
    </nav>

    <main>
        @RenderBody()
    </main>

    <footer>
        &copy; @DateTime.Now.Year - My Application
    </footer>
</body>
</html>

// Shared partial views
// Views/Shared/_ProductCard.cshtml (accessible from all areas)
@model ProductViewModel

<div class="product-card">
    <img src="@Model.ImageUrl" alt="@Model.Name" />
    <h3>@Model.Name</h3>
    <p class="price">@Model.Price.ToString("C")</p>
    <a asp-area="" asp-controller="Products" asp-action="Details" asp-route-id="@Model.Id">
        View Details
    </a>
</div>
```

### 10. Custom Area Route Constraints

```csharp
// Custom route constraint for area
public class AdminAreaConstraint : IRouteConstraint
{
    public bool Match(
        HttpContext httpContext,
        IRouter route,
        string routeKey,
        RouteValueDictionary values,
        RouteDirection routeDirection)
    {
        if (values.TryGetValue("area", out var area))
        {
            var areaName = area?.ToString();
            return areaName == "Admin" &&
                   httpContext.User.IsInRole("Admin");
        }

        return false;
    }
}

// Register constraint
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddRouting(options =>
        {
            options.ConstraintMap.Add("admin", typeof(AdminAreaConstraint));
        });

        services.AddControllersWithViews();
    }

    public void Configure(IApplicationBuilder app)
    {
        app.UseRouting();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllerRoute(
                name: "admin_area",
                pattern: "{area:admin}/{controller=Dashboard}/{action=Index}/{id?}");

            endpoints.MapControllerRoute(
                name: "areas",
                pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

            endpoints.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");
        });
    }
}
```

### 11. Area Best Practices

```csharp
// ✅ Good: Organize by functional area
/*
Areas/
├── Admin/          (Administration)
├── Customer/       (Customer portal)
├── Reports/        (Reporting)
└── Api/           (API endpoints)
*/

// ✅ Good: Use area-specific models
namespace MyApp.Areas.Admin.Models
{
    public class AdminDashboardViewModel
    {
        public int TotalUsers { get; set; }
        public int TotalOrders { get; set; }
        public decimal Revenue { get; set; }
        public List<RecentActivity> Activities { get; set; }
    }
}

// ✅ Good: Consistent naming
[Area("Admin")]
public class UsersController : Controller { }

[Area("Customer")]
public class ProfileController : Controller { }

// ❌ Bad: Mixing concerns
[Area("Misc")] // Too generic
public class RandomController : Controller { }

// ✅ Good: Clear area boundaries
// Admin area handles admin tasks only
// Customer area handles customer-facing features only
// Don't mix business logic across areas

// ✅ Good: Area-specific authentication
[Area("Admin")]
[Authorize(Roles = "Admin,Manager")]
public class BaseAdminController : Controller
{
    // Common admin functionality
}

// Other admin controllers inherit
public class DashboardController : BaseAdminController
{
    public IActionResult Index()
    {
        return View();
    }
}
```

### 12. Testing Area Controllers

```csharp
using Xunit;
using Microsoft.AspNetCore.Mvc;
using Moq;

public class AdminDashboardControllerTests
{
    [Fact]
    public void Index_ReturnsViewResult()
    {
        // Arrange
        var controller = new DashboardController();

        // Act
        var result = controller.Index();

        // Assert
        var viewResult = Assert.IsType<ViewResult>(result);
    }

    [Fact]
    public void Controller_HasCorrectAreaAttribute()
    {
        // Arrange & Act
        var areaAttribute = typeof(DashboardController)
            .GetCustomAttributes(typeof(AreaAttribute), false)
            .FirstOrDefault() as AreaAttribute;

        // Assert
        Assert.NotNull(areaAttribute);
        Assert.Equal("Admin", areaAttribute.RouteValue);
    }

    [Fact]
    public void Statistics_ReturnsViewWithModel()
    {
        // Arrange
        var controller = new DashboardController();

        // Act
        var result = controller.Statistics();

        // Assert
        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.NotNull(viewResult.Model);
    }
}
```

**Areas Summary:**

| Aspect | Description |
|--------|-------------|
| **Purpose** | Organize large apps into functional modules |
| **Structure** | Separate Controllers/Views/Models folders |
| **Routing** | `{area:exists}/{controller}/{action}/{id?}` |
| **Attribute** | `[Area("AreaName")]` on controllers |
| **Links** | `asp-area="AreaName"` in views |
| **Authorization** | Per-area or per-controller |
| **ViewStart** | Area-specific layouts |
| **ViewImports** | Area-specific namespaces |

**When to Use Areas:**

```
✅ Large applications with distinct modules
✅ Different user roles (Admin, Customer, Employee)
✅ Separate functional areas (Sales, Inventory, HR)
✅ Multi-tenant applications
✅ Clear separation of concerns needed

❌ Small applications (overhead not justified)
❌ Single-purpose applications
❌ When simple folder organization suffices
```

---

## Q63: What is the difference between Server.Transfer() and Response.Redirect()?

**Answer:**

Server.Transfer() and Response.Redirect() are both used to navigate to different pages, but they work fundamentally differently in terms of where the navigation occurs and how the browser is affected.

### 1. Basic Difference Overview

```csharp
public class NavigationController : Controller
{
    private readonly IWebHostEnvironment _env;

    public NavigationController(IWebHostEnvironment env)
    {
        _env = env;
    }

    // Response.Redirect - Client-side redirect
    public IActionResult RedirectExample()
    {
        // Client receives HTTP 302 and makes new request
        return Redirect("/Home/Index");

        // Or with RedirectToAction
        return RedirectToAction("Index", "Home");

        // Permanent redirect (HTTP 301)
        return RedirectPermanent("/Home/Index");

        // Temporary redirect with specific status
        return RedirectToActionPermanent("Index", "Home");
    }

    // Server.Transfer equivalent in ASP.NET Core
    // (Note: Server.Transfer is classic ASP.NET, not in Core)
    // In ASP.NET Core, use ReExecute or internal redirects
    public async Task<IActionResult> TransferExample()
    {
        // ASP.NET Core doesn't have Server.Transfer
        // Use ReExecute for similar behavior
        HttpContext.Request.Path = "/Home/Index";
        await HttpContext.Response.CompleteAsync();

        // Or return the result directly
        var homeController = new HomeController();
        return await homeController.Index();
    }
}

// Classic ASP.NET MVC (not Core)
public class ClassicNavigationController : Controller
{
    public ActionResult RedirectMethod()
    {
        // Client-side redirect
        Response.Redirect("~/Home/Index");
        return null;
    }

    public ActionResult TransferMethod()
    {
        // Server-side transfer
        Server.Transfer("~/Home/Index");
        return null;
    }
}
```

### 2. Detailed Comparison Table

```csharp
/*
┌─────────────────────┬──────────────────────┬──────────────────────┐
│    Feature          │ Response.Redirect()  │ Server.Transfer()    │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Where Executed      │ Client-side          │ Server-side          │
│ Browser URL         │ Changes              │ Stays same           │
│ HTTP Requests       │ 2 requests           │ 1 request            │
│ Performance         │ Slower (2 trips)     │ Faster (1 trip)      │
│ Status Code         │ 302 or 301           │ No status change     │
│ Cross-domain        │ Yes                  │ No (same app only)   │
│ Preserves Form Data │ No                   │ Yes                  │
│ Query String        │ Visible in URL       │ Can be preserved     │
│ Session State       │ Available            │ Available            │
│ ViewState           │ Lost                 │ Can be preserved     │
│ Browser History     │ Added to history     │ Not in history       │
└─────────────────────┴──────────────────────┴──────────────────────┘
*/
```

### 3. Response.Redirect Detailed Examples

```csharp
public class RedirectExamplesController : Controller
{
    // Simple redirect
    public IActionResult SimpleRedirect()
    {
        return Redirect("/Products/Index");
    }

    // Redirect to action
    public IActionResult RedirectToActionExample()
    {
        return RedirectToAction("Details", "Products", new { id = 123 });
    }

    // Redirect to route
    public IActionResult RedirectToRouteExample()
    {
        return RedirectToRoute("default", new { controller = "Home", action = "Index" });
    }

    // Redirect with query string
    public IActionResult RedirectWithQueryString()
    {
        return Redirect("/Products/Search?category=electronics&page=1");
    }

    // Permanent redirect (SEO - 301)
    public IActionResult PermanentRedirectExample()
    {
        // Use for moved content, better for SEO
        return RedirectPermanent("/NewLocation/Index");
    }

    // Temporary redirect (302 - default)
    public IActionResult TemporaryRedirectExample()
    {
        // Default behavior - temporary redirect
        return Redirect("/TemporaryLocation/Index");
    }

    // Redirect to external URL
    public IActionResult ExternalRedirect()
    {
        return Redirect("https://www.example.com");
    }

    // Conditional redirect
    public IActionResult ConditionalRedirect(int userId)
    {
        var user = GetUser(userId);

        if (user == null)
        {
            return RedirectToAction("NotFound");
        }

        if (!user.IsActive)
        {
            return RedirectToAction("Inactive", new { id = userId });
        }

        return RedirectToAction("Profile", new { id = userId });
    }

    // Redirect with TempData
    public IActionResult RedirectWithMessage()
    {
        TempData["SuccessMessage"] = "Operation completed successfully";
        TempData["UserId"] = 123;

        return RedirectToAction("Confirmation");
    }

    public IActionResult Confirmation()
    {
        // TempData survives the redirect
        var message = TempData["SuccessMessage"]?.ToString();
        var userId = TempData["UserId"];

        return View();
    }

    private User GetUser(int id) => null; // Placeholder
}
```

### 4. Server.Transfer Classic ASP.NET

```csharp
// Classic ASP.NET Web Forms / MVC (Not ASP.NET Core)
public class ServerTransferController : Controller
{
    // Basic server transfer
    public ActionResult BasicTransfer()
    {
        // Transfer execution to another page
        Server.Transfer("~/Products/Index");
        return null; // Never reached
    }

    // Transfer with preserving form data
    public ActionResult TransferPreservingForm()
    {
        // Second parameter preserves form and query string
        Server.Transfer("~/Products/Process", true);
        return null;
    }

    // Transfer without preserving
    public ActionResult TransferWithoutPreserving()
    {
        // Don't preserve form data
        Server.Transfer("~/Products/Process", false);
        return null;
    }

    // Accessing original URL after transfer
    public ActionResult ProcessTransfer()
    {
        // Original URL before transfer
        string originalUrl = Request.ServerVariables["HTTP_URL"];

        // Current URL (transferred)
        string currentUrl = Request.Url.ToString();

        ViewBag.OriginalUrl = originalUrl;
        ViewBag.CurrentUrl = currentUrl;

        return View();
    }
}
```

### 5. ASP.NET Core Alternatives to Server.Transfer

```csharp
// ASP.NET Core doesn't have Server.Transfer
// Use these alternatives:

public class CoreTransferAlternativesController : Controller
{
    // Method 1: Direct action invocation
    public IActionResult DirectInvoke()
    {
        // Call another controller action directly
        var homeController = new HomeController();
        return homeController.Index();
    }

    // Method 2: Use middleware rewrite
    public IActionResult RewriteExample()
    {
        // This requires URL Rewrite middleware
        HttpContext.Request.Path = "/Home/Index";
        HttpContext.Request.QueryString = new QueryString("?id=123");

        // Return empty result - middleware handles the rest
        return new EmptyResult();
    }

    // Method 3: Return view from different action
    public IActionResult ReturnOtherView()
    {
        // Execute logic and return different view
        var model = GetProductData();
        return View("~/Views/Products/Details.cshtml", model);
    }

    // Method 4: Use HttpContext.Features for path rewrite
    public async Task<IActionResult> ReExecutePath()
    {
        var originalPath = HttpContext.Request.Path;
        var originalQueryString = HttpContext.Request.QueryString;

        // Modify request path
        HttpContext.Request.Path = "/api/products";
        HttpContext.Request.QueryString = new QueryString("?id=123");

        // Let the pipeline re-execute
        await Task.CompletedTask;

        return new EmptyResult();
    }

    private object GetProductData() => new { Id = 1, Name = "Product" };
}

// Custom middleware for server-side rewrites
public class ServerSideRewriteMiddleware
{
    private readonly RequestDelegate _next;

    public ServerSideRewriteMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value;

        // Rewrite specific paths server-side
        if (path.Equals("/old-url", StringComparison.OrdinalIgnoreCase))
        {
            context.Request.Path = "/new-url";
            // URL in browser stays "/old-url"
        }

        await _next(context);
    }
}

// Register in Program.cs
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddControllersWithViews();

        var app = builder.Build();

        // Add rewrite middleware
        app.UseMiddleware<ServerSideRewriteMiddleware>();

        app.MapControllerRoute(
            name: "default",
            pattern: "{controller=Home}/{action=Index}/{id?}");

        app.Run();
    }
}
```

### 6. Performance Comparison

```csharp
public class PerformanceComparisonController : Controller
{
    private readonly ILogger<PerformanceComparisonController> _logger;

    public PerformanceComparisonController(ILogger<PerformanceComparisonController> logger)
    {
        _logger = logger;
    }

    // Scenario 1: Response.Redirect
    // Client makes request to Step1
    // Server responds with 302 redirect
    // Client makes new request to Step2
    // Total: 2 HTTP requests
    public IActionResult Step1Redirect()
    {
        _logger.LogInformation("Step1 executing - will redirect");

        // Browser receives: HTTP/1.1 302 Found
        // Location: /Performance/Step2
        return RedirectToAction("Step2");
    }

    public IActionResult Step2()
    {
        _logger.LogInformation("Step2 executing after redirect");
        return View();
    }

    // Scenario 2: Server.Transfer equivalent
    // Client makes request
    // Server processes internally
    // Total: 1 HTTP request
    public IActionResult Step1Transfer()
    {
        _logger.LogInformation("Step1 executing - will transfer");

        // Process and return Step2's view directly
        var model = PrepareStep2Data();
        return View("Step2", model);
    }

    private object PrepareStep2Data()
    {
        return new { Message = "Data from Step1" };
    }
}

// Benchmark example
/*
Response.Redirect Performance:
- Request 1: Client → Server (Step1) = 50ms
- Response 1: Server → Client (302) = 50ms
- Request 2: Client → Server (Step2) = 50ms
- Response 2: Server → Client (View) = 50ms
Total: 200ms + network latency

Server.Transfer Performance:
- Request: Client → Server (Step1) = 50ms
- Internal processing (Step2) = 10ms
- Response: Server → Client (View) = 50ms
Total: 110ms

Performance Gain: ~45% faster
*/
```

### 7. Use Cases and Best Practices

```csharp
public class UseCasesController : Controller
{
    // ✅ Use Response.Redirect when:

    // 1. URL should change in browser
    public IActionResult AfterFormSubmission()
    {
        // POST/Redirect/GET pattern
        ProcessForm();
        return RedirectToAction("Success");
    }

    // 2. Redirecting to external site
    public IActionResult ExternalSite()
    {
        return Redirect("https://external-site.com");
    }

    // 3. SEO - permanent moved content
    public IActionResult OldUrl()
    {
        return RedirectPermanent("/new-url");
    }

    // 4. User should be able to bookmark
    public IActionResult BookmarkableResult()
    {
        return RedirectToAction("Details", new { id = 123 });
    }

    // ✅ Use Server.Transfer (or equivalent) when:

    // 1. Internal processing without client knowing
    public IActionResult InternalProcessing()
    {
        var result = ProcessData();
        return View("~/Views/Shared/Result.cshtml", result);
    }

    // 2. Preserving POST data
    public IActionResult PreservePostData()
    {
        // Get form data
        var formData = Request.Form;

        // Process and show different view
        return View("AlternateView", formData);
    }

    // 3. Avoiding double-submit
    public IActionResult AvoidDoubleSubmit()
    {
        if (Request.Method == "POST")
        {
            ProcessPayment();
            // Show confirmation without redirect
            return View("Confirmation");
        }

        return View();
    }

    // 4. Performance-critical scenarios
    public IActionResult FastInternal()
    {
        // Skip client round-trip
        var data = GetData();
        return View("FastView", data);
    }

    private void ProcessForm() { }
    private object ProcessData() => new { };
    private void ProcessPayment() { }
    private object GetData() => new { };
}
```

### 8. Security Considerations

```csharp
public class SecurityConsiderationsController : Controller
{
    // ❌ Bad: Open redirect vulnerability
    public IActionResult UnsafeRedirect(string returnUrl)
    {
        // Never redirect to user-provided URLs directly
        return Redirect(returnUrl); // Dangerous!
    }

    // ✅ Good: Validate redirect URL
    public IActionResult SafeRedirect(string returnUrl)
    {
        // Validate URL is local
        if (Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        // Or validate against whitelist
        var allowedUrls = new[] { "/home", "/products", "/about" };
        if (allowedUrls.Contains(returnUrl.ToLower()))
        {
            return Redirect(returnUrl);
        }

        // Default safe redirect
        return RedirectToAction("Index", "Home");
    }

    // ✅ Good: Use action-based redirect
    public IActionResult SafeActionRedirect(int id)
    {
        // Type-safe, no user input
        return RedirectToAction("Details", "Products", new { id });
    }

    // Server.Transfer security
    public IActionResult SecureTransfer(string target)
    {
        // ❌ Bad: Arbitrary file access
        // Server.Transfer(target); // Could access web.config!

        // ✅ Good: Whitelist allowed transfers
        var allowedPaths = new Dictionary<string, string>
        {
            ["home"] = "~/Views/Home/Index.cshtml",
            ["products"] = "~/Views/Products/Index.cshtml"
        };

        if (allowedPaths.TryGetValue(target, out var safePath))
        {
            return View(safePath);
        }

        return RedirectToAction("Index", "Home");
    }
}
```

### 9. POST-Redirect-GET Pattern

```csharp
public class PostRedirectGetController : Controller
{
    private readonly IProductService _productService;

    public PostRedirectGetController(IProductService productService)
    {
        _productService = productService;
    }

    // GET: Show form
    [HttpGet]
    public IActionResult Create()
    {
        return View();
    }

    // POST: Process form (MUST redirect)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(ProductViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var product = _productService.Create(model);

        // ✅ MUST use Redirect (not Transfer/View)
        // Prevents double-submit on browser refresh
        TempData["SuccessMessage"] = "Product created successfully";
        return RedirectToAction("Details", new { id = product.Id });
    }

    // GET: Show result
    [HttpGet]
    public IActionResult Details(int id)
    {
        var product = _productService.GetById(id);

        // Message survives redirect via TempData
        ViewBag.Message = TempData["SuccessMessage"];

        return View(product);
    }

    // ❌ Bad: Returning View after POST
    [HttpPost]
    public IActionResult BadCreate(ProductViewModel model)
    {
        _productService.Create(model);

        // Browser refresh will re-submit form!
        return View("Success");
    }
}
```

### 10. Redirect with Preserved Data

```csharp
public class DataPreservationController : Controller
{
    // Response.Redirect - use TempData
    public IActionResult RedirectWithData()
    {
        // TempData survives redirect (one request)
        TempData["Message"] = "Success";
        TempData["Data"] = JsonSerializer.Serialize(new { Id = 123, Name = "Test" });

        return RedirectToAction("Destination");
    }

    public IActionResult Destination()
    {
        var message = TempData["Message"]?.ToString();
        var dataJson = TempData["Data"]?.ToString();
        var data = JsonSerializer.Deserialize<dynamic>(dataJson);

        return View();
    }

    // Server.Transfer equivalent - direct model passing
    public IActionResult TransferWithData()
    {
        var model = new ResultViewModel
        {
            Message = "Success",
            Data = new { Id = 123, Name = "Test" }
        };

        // Direct view return with model
        return View("Destination", model);
    }

    // Persist across multiple redirects
    public IActionResult MultipleRedirects()
    {
        // Use TempData.Keep() to preserve for next request
        TempData["PersistentData"] = "Important info";
        TempData.Keep("PersistentData");

        return RedirectToAction("Intermediate");
    }

    public IActionResult Intermediate()
    {
        TempData.Keep("PersistentData"); // Keep for next request
        return RedirectToAction("Final");
    }

    public IActionResult Final()
    {
        var data = TempData["PersistentData"]; // Available here
        return View();
    }
}

public class ResultViewModel
{
    public string Message { get; set; }
    public object Data { get; set; }
}
```

### 11. URL Rewriting vs Redirecting

```csharp
// URL Rewriting (Server.Transfer like)
public class RewriteMiddleware
{
    private readonly RequestDelegate _next;

    public RewriteMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value;

        // Rewrite old URLs to new ones (server-side)
        if (path.StartsWith("/old-products/", StringComparison.OrdinalIgnoreCase))
        {
            // Extract ID from old URL
            var id = path.Replace("/old-products/", "");

            // Rewrite to new URL format
            context.Request.Path = $"/products/{id}";

            // Browser still shows /old-products/123
            // But server processes /products/123
        }

        await _next(context);
    }
}

// URL Redirecting (Response.Redirect)
public class RedirectMiddleware
{
    private readonly RequestDelegate _next;

    public RedirectMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value;

        // Redirect old URLs to new ones (client-side)
        if (path.StartsWith("/old-products/", StringComparison.OrdinalIgnoreCase))
        {
            var id = path.Replace("/old-products/", "");

            // Send redirect to client
            context.Response.Redirect($"/products/{id}", permanent: true);
            return; // Don't call next middleware
        }

        await _next(context);
    }
}
```

### 12. Testing Redirects

```csharp
using Xunit;
using Microsoft.AspNetCore.Mvc;

public class RedirectTests
{
    [Fact]
    public void Create_ValidModel_RedirectsToDetails()
    {
        // Arrange
        var controller = new ProductsController(new MockProductService());
        var model = new ProductViewModel { Name = "Test", Price = 99.99m };

        // Act
        var result = controller.Create(model);

        // Assert
        var redirectResult = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal("Details", redirectResult.ActionName);
        Assert.Equal(123, redirectResult.RouteValues["id"]);
    }

    [Fact]
    public void Redirect_ReturnsCorrectStatusCode()
    {
        // Arrange
        var controller = new NavigationController();

        // Act
        var result = controller.PermanentRedirect();

        // Assert
        var redirectResult = Assert.IsType<RedirectResult>(result);
        Assert.True(redirectResult.Permanent);
    }

    [Fact]
    public void Redirect_SetsCorrectUrl()
    {
        // Arrange
        var controller = new NavigationController();

        // Act
        var result = controller.ExternalRedirect();

        // Assert
        var redirectResult = Assert.IsType<RedirectResult>(result);
        Assert.Equal("https://www.example.com", redirectResult.Url);
    }
}
```

### 13. Best Practices Summary

```
Response.Redirect():
✅ Use for POST-Redirect-GET pattern
✅ Use when URL should change
✅ Use for external URLs
✅ Use for bookmarkable results
✅ Use for SEO (301 redirects)
✅ Better for debugging (visible in Network tab)

❌ Slower (two HTTP requests)
❌ Can't preserve form data directly
❌ Adds to browser history

Server.Transfer(): (Classic ASP.NET)
✅ Faster (single HTTP request)
✅ Can preserve form data
✅ URL stays same in browser
✅ Doesn't add to browser history

❌ Not available in ASP.NET Core
❌ Can't redirect to external URLs
❌ Can confuse users (URL doesn't match content)
❌ Not bookmarkable
❌ Harder to debug

ASP.NET Core Alternatives:
✅ Use direct View() return
✅ Use URL rewriting middleware
✅ Use action invocation
✅ More transparent and testable
```

**When to Choose:**

| Scenario | Use |
|----------|-----|
| After form POST | Response.Redirect |
| External URL | Response.Redirect |
| SEO-friendly | RedirectPermanent |
| Show different view | View() or ViewComponent |
| Internal URL rewrite | Middleware rewrite |
| Performance critical | Direct view return |
| Preserve POST data | TempData + Redirect |
| User bookmark | Response.Redirect |

---

## Q64: What is bundling and minification in ASP.NET?

**Answer:**

Bundling and minification are optimization techniques that improve page load performance by reducing the number and size of HTTP requests for static resources like CSS and JavaScript files.

### 1. Bundling Basics

```csharp
// Classic ASP.NET MVC - BundleConfig.cs
using System.Web.Optimization;

public class BundleConfig
{
    public static void RegisterBundles(BundleCollection bundles)
    {
        // JavaScript bundles
        bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
            "~/Scripts/jquery-{version}.js"));

        bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
            "~/Scripts/jquery.validate*"));

        bundles.Add(new ScriptBundle("~/bundles/modernizr").Include(
            "~/Scripts/modernizr-*"));

        bundles.Add(new ScriptBundle("~/bundles/bootstrap").Include(
            "~/Scripts/bootstrap.js"));

        // Custom application bundle
        bundles.Add(new ScriptBundle("~/bundles/app").Include(
            "~/Scripts/app/utils.js",
            "~/Scripts/app/validation.js",
            "~/Scripts/app/api.js",
            "~/Scripts/app/main.js"));

        // CSS bundles
        bundles.Add(new StyleBundle("~/Content/css").Include(
            "~/Content/bootstrap.css",
            "~/Content/site.css"));

        bundles.Add(new StyleBundle("~/Content/themes/base/css").Include(
            "~/Content/themes/base/jquery.ui.core.css",
            "~/Content/themes/base/jquery.ui.resizable.css",
            "~/Content/themes/base/jquery.ui.selectable.css",
            "~/Content/themes/base/jquery.ui.accordion.css",
            "~/Content/themes/base/jquery.ui.autocomplete.css",
            "~/Content/themes/base/jquery.ui.button.css",
            "~/Content/themes/base/jquery.ui.dialog.css",
            "~/Content/themes/base/jquery.ui.slider.css",
            "~/Content/themes/base/jquery.ui.tabs.css",
            "~/Content/themes/base/jquery.ui.datepicker.css",
            "~/Content/themes/base/jquery.ui.progressbar.css",
            "~/Content/themes/base/jquery.ui.theme.css"));

        // Enable optimization in development (normally only in production)
        #if DEBUG
            BundleTable.EnableOptimizations = false;
        #else
            BundleTable.EnableOptimizations = true;
        #endif
    }
}

// Register in Global.asax
protected void Application_Start()
{
    BundleConfig.RegisterBundles(BundleTable.Bundles);
}
```

### 2. Using Bundles in Views

```html
<!-- Classic ASP.NET MVC -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@ViewBag.Title - My Application</title>

    @* Render CSS bundles *@
    @Styles.Render("~/Content/css")
    @Styles.Render("~/Content/themes/base/css")
</head>
<body>
    <div class="container">
        @RenderBody()
    </div>

    @* Render JavaScript bundles at bottom *@
    @Scripts.Render("~/bundles/jquery")
    @Scripts.Render("~/bundles/bootstrap")
    @Scripts.Render("~/bundles/app")

    @RenderSection("scripts", required: false)
</body>
</html>

<!--
Development (EnableOptimizations = false):
Renders as individual files:
<link href="/Content/bootstrap.css" rel="stylesheet"/>
<link href="/Content/site.css" rel="stylesheet"/>

Production (EnableOptimizations = true):
Renders as single bundled file:
<link href="/Content/css?v=MHh8h6VRV0XMBbS6ygmZECOBN3CQ09gJZ_wQ10zqcdk1" rel="stylesheet"/>
-->

<!-- Conditional bundling -->
@if (HttpContext.Current.IsDebuggingEnabled)
{
    @* Development: Individual files for debugging *@
    <script src="~/Scripts/app/utils.js"></script>
    <script src="~/Scripts/app/validation.js"></script>
    <script src="~/Scripts/app/api.js"></script>
}
else
{
    @* Production: Bundled and minified *@
    @Scripts.Render("~/bundles/app")
}
```

### 3. ASP.NET Core Bundling (WebOptimizer)

```csharp
// Install NuGet package: LigerShark.WebOptimizer.Core

// Program.cs (.NET 6+)
using WebOptimizer;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

// Add WebOptimizer
builder.Services.AddWebOptimizer(pipeline =>
{
    // Bundle and minify CSS files
    pipeline.AddCssBundle("/css/bundle.css",
        "css/bootstrap.css",
        "css/site.css",
        "css/custom.css");

    // Bundle and minify JavaScript files
    pipeline.AddJavaScriptBundle("/js/bundle.js",
        "js/jquery.min.js",
        "js/bootstrap.min.js",
        "js/site.js");

    // Bundle with custom options
    pipeline.AddJavaScriptBundle("/js/app.js",
        "js/app/utils.js",
        "js/app/validation.js",
        "js/app/api.js",
        "js/app/main.js")
        .UseContentRoot();

    // Minify individual files
    pipeline.MinifyCssFiles("css/**/*.css");
    pipeline.MinifyJsFiles("js/**/*.js");

    // Compile SCSS/SASS
    pipeline.CompileScssFiles();
});

var app = builder.Build();

// Use WebOptimizer middleware
app.UseWebOptimizer();

app.UseStaticFiles();
app.UseRouting();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

// Startup.cs (.NET 5 and earlier)
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllersWithViews();

        services.AddWebOptimizer(pipeline =>
        {
            // CSS bundles
            pipeline.AddCssBundle("/css/site.min.css",
                "/css/bootstrap.css",
                "/css/site.css");

            // JS bundles
            pipeline.AddJavaScriptBundle("/js/site.min.js",
                "/js/jquery.js",
                "/js/bootstrap.js",
                "/js/site.js");

            // Custom minification settings
            pipeline.MinifyJsFiles("js/**/*.js");
            pipeline.MinifyCssFiles("css/**/*.css");
        });
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.UseWebOptimizer();
        app.UseStaticFiles();
        app.UseRouting();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");
        });
    }
}
```

### 4. ASP.NET Core View Usage

```html
<!-- _Layout.cshtml -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - My App</title>

    @* Link to bundled CSS *@
    <link rel="stylesheet" href="~/css/bundle.css" asp-append-version="true" />
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-sm">
            <!-- Navigation -->
        </nav>
    </header>

    <div class="container">
        <main role="main" class="pb-3">
            @RenderBody()
        </main>
    </div>

    <footer class="border-top footer text-muted">
        <div class="container">
            &copy; 2024 - My App
        </div>
    </footer>

    @* Bundled JavaScript *@
    <script src="~/js/bundle.js" asp-append-version="true"></script>

    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>

<!--
asp-append-version="true" adds cache-busting query string:
<link rel="stylesheet" href="/css/bundle.css?v=abc123" />

This ensures browsers load new versions when files change
-->
```

### 5. Custom Bundle Transformations

```csharp
// Classic ASP.NET MVC - Custom bundle transformer
using System.Web.Optimization;

public class CustomJsMinifier : IBundleTransform
{
    public void Process(BundleContext context, BundleResponse response)
    {
        if (context == null)
        {
            throw new ArgumentNullException(nameof(context));
        }

        if (response == null)
        {
            throw new ArgumentNullException(nameof(response));
        }

        // Custom minification logic
        var content = response.Content;

        // Remove comments
        content = System.Text.RegularExpressions.Regex.Replace(
            content,
            @"//.*?$",
            "",
            System.Text.RegularExpressions.RegexOptions.Multiline);

        // Remove whitespace
        content = System.Text.RegularExpressions.Regex.Replace(
            content,
            @"\s+",
            " ");

        response.Content = content;
        response.ContentType = "text/javascript";
    }
}

// Use custom transformer
bundles.Add(new ScriptBundle("~/bundles/custom")
    .Include("~/Scripts/app.js")
    .Transform(new CustomJsMinifier()));

// Custom CSS transformer
public class CustomCssMinifier : IBundleTransform
{
    public void Process(BundleContext context, BundleResponse response)
    {
        var content = response.Content;

        // Remove comments
        content = System.Text.RegularExpressions.Regex.Replace(
            content,
            @"/\*.*?\*/",
            "",
            System.Text.RegularExpressions.RegexOptions.Singleline);

        // Remove whitespace
        content = System.Text.RegularExpressions.Regex.Replace(
            content,
            @"\s+",
            " ");

        // Remove spaces around specific characters
        content = System.Text.RegularExpressions.Regex.Replace(
            content,
            @"\s*([{}:;,])\s*",
            "$1");

        response.Content = content.Trim();
        response.ContentType = "text/css";
    }
}
```

### 6. CDN Integration

```csharp
// Classic ASP.NET MVC - CDN fallback
public class BundleConfig
{
    public static void RegisterBundles(BundleCollection bundles)
    {
        // Use CDN with local fallback
        var jqueryBundle = new ScriptBundle("~/bundles/jquery",
            "https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js")
            .Include("~/Scripts/jquery-{version}.js");

        bundles.Add(jqueryBundle);

        var bootstrapBundle = new ScriptBundle("~/bundles/bootstrap",
            "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js")
            .Include("~/Scripts/bootstrap.js");

        bundles.Add(bootstrapBundle);

        var bootstrapCss = new StyleBundle("~/Content/bootstrap",
            "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css")
            .Include("~/Content/bootstrap.css");

        bundles.Add(bootstrapCss);

        // Enable CDN support
        bundles.UseCdn = true;
        BundleTable.EnableOptimizations = true;
    }
}

// View with CDN fallback
@Scripts.Render("~/bundles/jquery")
<script>
    // Fallback to local if CDN fails
    if (typeof jQuery == 'undefined') {
        document.write('<script src="@Url.Content("~/Scripts/jquery-3.6.0.js")"><\/script>');
    }
</script>

@Styles.Render("~/Content/bootstrap")
<script>
    // Test if Bootstrap CSS loaded
    if (!document.querySelector('.container')) {
        document.write('<link rel="stylesheet" href="@Url.Content("~/Content/bootstrap.css")" />');
    }
</script>
```

### 7. Environment-Based Bundling (ASP.NET Core)

```html
<!-- Use environment tag helper -->
<environment include="Development">
    <!-- Development: Individual files for debugging -->
    <link rel="stylesheet" href="~/css/bootstrap.css" />
    <link rel="stylesheet" href="~/css/site.css" />
    <link rel="stylesheet" href="~/css/custom.css" />
</environment>

<environment exclude="Development">
    <!-- Production: Bundled and minified -->
    <link rel="stylesheet" href="~/css/bundle.min.css" asp-append-version="true" />

    <!-- CDN with integrity check and fallback -->
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"
          asp-fallback-href="~/css/bootstrap.min.css"
          asp-fallback-test-class="sr-only"
          asp-fallback-test-property="position"
          asp-fallback-test-value="absolute"
          crossorigin="anonymous"
          integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" />
</environment>

<!-- Scripts -->
<environment include="Development">
    <script src="~/js/jquery.js"></script>
    <script src="~/js/bootstrap.js"></script>
    <script src="~/js/site.js"></script>
</environment>

<environment exclude="Development">
    <script src="~/js/bundle.min.js" asp-append-version="true"></script>

    <!-- CDN with fallback -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"
            asp-fallback-src="~/js/jquery.min.js"
            asp-fallback-test="window.jQuery"
            crossorigin="anonymous"
            integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=">
    </script>
</environment>
```

### 8. Build-Time Bundling with NPM/Gulp

```javascript
// package.json
{
  "name": "my-asp-net-app",
  "version": "1.0.0",
  "devDependencies": {
    "gulp": "^4.0.2",
    "gulp-concat": "^2.6.1",
    "gulp-uglify": "^3.0.2",
    "gulp-clean-css": "^4.3.0",
    "gulp-rename": "^2.0.0"
  },
  "scripts": {
    "build": "gulp build",
    "watch": "gulp watch"
  }
}

// gulpfile.js
const gulp = require('gulp');
const concat = require('gulp-concat');
const uglify = require('gulp-uglify');
const cleanCSS = require('gulp-clean-css');
const rename = require('gulp-rename');

// JavaScript bundling
gulp.task('bundle-js', function() {
    return gulp.src([
        'wwwroot/js/jquery.js',
        'wwwroot/js/bootstrap.js',
        'wwwroot/js/site.js'
    ])
    .pipe(concat('bundle.js'))
    .pipe(gulp.dest('wwwroot/js/dist'))
    .pipe(uglify())
    .pipe(rename({ suffix: '.min' }))
    .pipe(gulp.dest('wwwroot/js/dist'));
});

// CSS bundling
gulp.task('bundle-css', function() {
    return gulp.src([
        'wwwroot/css/bootstrap.css',
        'wwwroot/css/site.css'
    ])
    .pipe(concat('bundle.css'))
    .pipe(gulp.dest('wwwroot/css/dist'))
    .pipe(cleanCSS())
    .pipe(rename({ suffix: '.min' }))
    .pipe(gulp.dest('wwwroot/css/dist'));
});

// Watch for changes
gulp.task('watch', function() {
    gulp.watch('wwwroot/js/**/*.js', gulp.series('bundle-js'));
    gulp.watch('wwwroot/css/**/*.css', gulp.series('bundle-css'));
});

// Default build task
gulp.task('build', gulp.parallel('bundle-js', 'bundle-css'));
```

### 9. Webpack Configuration (Modern Approach)

```javascript
// webpack.config.js
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');

module.exports = (env, argv) => {
    const isProduction = argv.mode === 'production';

    return {
        mode: isProduction ? 'production' : 'development',
        entry: {
            app: './wwwroot/js/src/app.js',
            vendor: './wwwroot/js/src/vendor.js'
        },
        output: {
            path: path.resolve(__dirname, 'wwwroot/dist'),
            filename: '[name].bundle.js',
            publicPath: '/dist/'
        },
        module: {
            rules: [
                {
                    test: /\.js$/,
                    exclude: /node_modules/,
                    use: {
                        loader: 'babel-loader',
                        options: {
                            presets: ['@babel/preset-env']
                        }
                    }
                },
                {
                    test: /\.css$/,
                    use: [
                        MiniCssExtractPlugin.loader,
                        'css-loader'
                    ]
                },
                {
                    test: /\.scss$/,
                    use: [
                        MiniCssExtractPlugin.loader,
                        'css-loader',
                        'sass-loader'
                    ]
                }
            ]
        },
        plugins: [
            new MiniCssExtractPlugin({
                filename: '[name].bundle.css'
            })
        ],
        optimization: {
            minimizer: isProduction ? [
                new TerserPlugin({
                    terserOptions: {
                        compress: {
                            drop_console: true
                        }
                    }
                }),
                new OptimizeCSSAssetsPlugin({})
            ] : [],
            splitChunks: {
                cacheGroups: {
                    vendor: {
                        test: /node_modules/,
                        name: 'vendor',
                        chunks: 'all'
                    }
                }
            }
        },
        devtool: isProduction ? false : 'source-map'
    };
};

// package.json scripts
{
  "scripts": {
    "build": "webpack --mode production",
    "dev": "webpack --mode development --watch"
  }
}
```

### 10. Performance Comparison

```csharp
/*
WITHOUT Bundling and Minification:
───────────────────────────────────
Individual requests:
1. jquery.js (95 KB)
2. bootstrap.js (75 KB)
3. site.js (50 KB)
4. utils.js (30 KB)
5. validation.js (40 KB)
6. bootstrap.css (150 KB)
7. site.css (80 KB)
8. custom.css (60 KB)

Total: 8 HTTP requests
Total size: 580 KB
Page load time: ~2.5 seconds (with 6 parallel connections)

WITH Bundling and Minification:
───────────────────────────────────
Bundled requests:
1. bundle.min.js (120 KB - minified from 290 KB)
2. bundle.min.css (140 KB - minified from 290 KB)

Total: 2 HTTP requests
Total size: 260 KB (55% reduction!)
Page load time: ~0.8 seconds (68% faster!)

Performance Gains:
- 75% fewer HTTP requests
- 55% smaller file sizes
- 68% faster page load
- Better browser caching
- Reduced server load
*/

// Benchmarking bundling performance
public class BundlingBenchmark
{
    public static void MeasureLoadTime()
    {
        var stopwatch = Stopwatch.StartNew();

        // Simulate loading individual files
        var individualFiles = new[]
        {
            "jquery.js",
            "bootstrap.js",
            "site.js",
            "utils.js",
            "validation.js"
        };

        foreach (var file in individualFiles)
        {
            Thread.Sleep(50); // Simulate network latency per file
        }

        stopwatch.Stop();
        Console.WriteLine($"Individual files: {stopwatch.ElapsedMilliseconds}ms");

        stopwatch.Restart();

        // Simulate loading bundled file
        Thread.Sleep(50); // Single request latency

        stopwatch.Stop();
        Console.WriteLine($"Bundled file: {stopwatch.ElapsedMilliseconds}ms");
    }
}
```

### 11. Cache Busting Strategies

```csharp
// ASP.NET Core - Automatic cache busting
<link rel="stylesheet" href="~/css/site.css" asp-append-version="true" />
<!-- Renders as: <link rel="stylesheet" href="/css/site.css?v=abc123hash" /> -->

<script src="~/js/site.js" asp-append-version="true"></script>
<!-- Renders as: <script src="/js/site.js?v=xyz789hash"></script> -->

// The hash changes when file content changes, forcing browser to reload

// Custom tag helper for cache busting
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Security.Cryptography;
using System.Text;

[HtmlTargetElement("script", Attributes = "asp-cache-bust")]
[HtmlTargetElement("link", Attributes = "asp-cache-bust")]
public class CacheBustingTagHelper : TagHelper
{
    private readonly IWebHostEnvironment _env;

    public CacheBustingTagHelper(IWebHostEnvironment env)
    {
        _env = env;
    }

    [HtmlAttributeName("asp-cache-bust")]
    public string Src { get; set; }

    public override void Process(TagHelperContext context, TagHelperOutput output)
    {
        if (string.IsNullOrEmpty(Src))
            return;

        var filePath = Path.Combine(_env.WebRootPath, Src.TrimStart('~', '/'));

        if (!File.Exists(filePath))
            return;

        var fileInfo = new FileInfo(filePath);
        var hash = GetFileHash(filePath);

        var newSrc = $"{Src}?v={hash}";

        if (output.TagName == "script")
        {
            output.Attributes.SetAttribute("src", newSrc);
        }
        else if (output.TagName == "link")
        {
            output.Attributes.SetAttribute("href", newSrc);
        }
    }

    private string GetFileHash(string filePath)
    {
        using var md5 = MD5.Create();
        using var stream = File.OpenRead(filePath);
        var hash = md5.ComputeHash(stream);
        return Convert.ToBase64String(hash)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }
}

// Usage
<script asp-cache-bust="~/js/app.js"></script>
<link rel="stylesheet" asp-cache-bust="~/css/site.css" />
```

### 12. Testing and Debugging Bundles

```csharp
// Classic ASP.NET MVC - Debug individual files
#if DEBUG
    BundleTable.EnableOptimizations = false;
#else
    BundleTable.EnableOptimizations = true;
#endif

// Force optimization in debug mode for testing
protected void Application_Start()
{
    BundleConfig.RegisterBundles(BundleTable.Bundles);

    // Override for testing
    BundleTable.EnableOptimizations = true;
}

// View bundle contents
public class BundleDebugController : Controller
{
    public ActionResult ShowBundleContents(string bundlePath)
    {
        var bundle = BundleTable.Bundles.GetBundleFor(bundlePath);

        if (bundle == null)
        {
            return HttpNotFound();
        }

        var context = new BundleContext(new HttpContextWrapper(System.Web.HttpContext.Current),
            BundleTable.Bundles, bundlePath);

        var response = bundle.GenerateBundleResponse(context);

        var info = new
        {
            Path = bundlePath,
            ContentType = response.ContentType,
            Files = bundle.EnumerateFiles(context).Select(f => f.FullName),
            Content = response.Content
        };

        return Json(info, JsonRequestBehavior.AllowGet);
    }
}

// ASP.NET Core - Verify bundle generation
public class BundleTestController : Controller
{
    private readonly IWebHostEnvironment _env;

    public BundleTestController(IWebHostEnvironment env)
    {
        _env = env;
    }

    public IActionResult TestBundle(string bundlePath)
    {
        var fullPath = Path.Combine(_env.WebRootPath, bundlePath.TrimStart('~', '/'));

        if (!System.IO.File.Exists(fullPath))
        {
            return NotFound($"Bundle not found: {bundlePath}");
        }

        var content = System.IO.File.ReadAllText(fullPath);
        var size = new FileInfo(fullPath).Length;

        return Json(new
        {
            Path = bundlePath,
            Size = $"{size:N0} bytes",
            SizeKB = $"{size / 1024.0:F2} KB",
            Lines = content.Split('\n').Length,
            Preview = content.Substring(0, Math.Min(500, content.Length))
        });
    }
}
```

### 13. Best Practices Summary

```
Bundling Best Practices:
✅ Group related files together
✅ Create separate bundles for vendor and app code
✅ Use CDN with local fallback
✅ Bundle in production, individual files in development
✅ Place bundles at consistent URLs (/js/bundle.js, /css/bundle.css)
✅ Use source maps for debugging production bundles
✅ Implement proper cache-busting strategy
✅ Test bundle loading in all environments

Minification Best Practices:
✅ Always minify in production
✅ Keep original files for debugging
✅ Test thoroughly after minification
✅ Use established minifiers (UglifyJS, Terser, CSSNano)
✅ Don't minify already-minified files
✅ Preserve license comments if required
✅ Enable gzip compression on server

❌ Don't bundle:
- Files that change frequently separately
- Unused libraries
- Files needed only on specific pages
- Development/debug scripts in production
```

**Performance Impact:**

| Metric | Without Optimization | With Bundling & Minification |
|--------|---------------------|------------------------------|
| HTTP Requests | 10-20 | 2-4 |
| Total Size | 500-800 KB | 200-350 KB |
| Load Time | 2-4 seconds | 0.5-1.2 seconds |
| TTI (Time to Interactive) | 3-5 seconds | 1-2 seconds |
| Bandwidth Usage | High | 40-60% reduction |
| Server Load | High | Lower (fewer requests) |

---


## Q65: How do you handle errors globally in ASP.NET MVC?

**Answer:**

Global error handling ensures consistent error responses across the application and provides centralized logging and user-friendly error pages.

### 1. ASP.NET Core Global Exception Handling

```csharp
// Program.cs (.NET 6+)
using Microsoft.AspNetCore.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

var app = builder.Build();

// Development: Show detailed error pages
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseDatabaseErrorPage(); // For EF Core migrations
}
else
{
    // Production: Custom error handling
    app.UseExceptionHandler("/Error/Handle");
    app.UseStatusCodePagesWithReExecute("/Error/{0}");
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
```

### 2. Custom Exception Handler Middleware

```csharp
public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var response = exception switch
        {
            NotFoundException => (StatusCodes.Status404NotFound, "Resource not found"),
            UnauthorizedException => (StatusCodes.Status401Unauthorized, "Unauthorized access"),
            ValidationException => (StatusCodes.Status400BadRequest, exception.Message),
            _ => (StatusCodes.Status500InternalServerError, "Internal server error")
        };

        context.Response.StatusCode = response.Item1;

        var result = JsonSerializer.Serialize(new
        {
            error = new
            {
                message = response.Item2,
                statusCode = response.Item1,
                timestamp = DateTime.UtcNow
            }
        });

        return context.Response.WriteAsync(result);
    }
}

// Register in Program.cs
app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
```

### 3. Error Controller

```csharp
public class ErrorController : Controller
{
    private readonly ILogger<ErrorController> _logger;

    public ErrorController(ILogger<ErrorController> logger)
    {
        _logger = logger;
    }

    [Route("Error/Handle")]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Handle()
    {
        var exceptionFeature = HttpContext.Features.Get<IExceptionHandlerPathFeature>();

        if (exceptionFeature != null)
        {
            var exception = exceptionFeature.Error;
            var path = exceptionFeature.Path;

            _logger.LogError(exception, 
                "Error occurred at path: {Path}", path);

            var errorViewModel = new ErrorViewModel
            {
                RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier,
                Message = "An error occurred processing your request",
                StatusCode = 500
            };

            return View("Error", errorViewModel);
        }

        return View("Error");
    }

    [Route("Error/{statusCode}")]
    public IActionResult HandleStatusCode(int statusCode)
    {
        var statusCodeFeature = HttpContext.Features.Get<IStatusCodeReExecuteFeature>();

        _logger.LogWarning("Status code {StatusCode} at path: {Path}", 
            statusCode, statusCodeFeature?.OriginalPath);

        var errorViewModel = new ErrorViewModel
        {
            StatusCode = statusCode,
            Message = statusCode switch
            {
                404 => "Page not found",
                401 => "Unauthorized",
                403 => "Forbidden",
                500 => "Internal server error",
                _ => "An error occurred"
            }
        };

        return View("Error", errorViewModel);
    }
}

public class ErrorViewModel
{
    public string RequestId { get; set; }
    public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
    public string Message { get; set; }
    public int StatusCode { get; set; }
}
```

### 4. Exception Filters

```csharp
public class CustomExceptionFilter : IExceptionFilter
{
    private readonly ILogger<CustomExceptionFilter> _logger;

    public CustomExceptionFilter(ILogger<CustomExceptionFilter> logger)
    {
        _logger = logger;
    }

    public void OnException(ExceptionContext context)
    {
        var exception = context.Exception;

        _logger.LogError(exception, 
            "Exception in {Controller}.{Action}",
            context.RouteData.Values["controller"],
            context.RouteData.Values["action"]);

        // Handle specific exceptions
        if (exception is NotFoundException)
        {
            context.Result = new NotFoundObjectResult(new
            {
                error = "Resource not found",
                message = exception.Message
            });
            context.ExceptionHandled = true;
        }
        else if (exception is ValidationException validationEx)
        {
            context.Result = new BadRequestObjectResult(new
            {
                error = "Validation failed",
                errors = validationEx.Errors
            });
            context.ExceptionHandled = true;
        }
        else if (exception is UnauthorizedAccessException)
        {
            context.Result = new UnauthorizedObjectResult(new
            {
                error = "Unauthorized access"
            });
            context.ExceptionHandled = true;
        }
    }
}

// Register globally
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add<CustomExceptionFilter>();
});

// Or use attribute on specific controllers/actions
[ServiceFilter(typeof(CustomExceptionFilter))]
public class ProductsController : Controller
{
    // Actions here
}
```

### 5. Custom Exception Types

```csharp
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }
    
    public NotFoundException(string entityName, object key)
        : base($"{entityName} with key '{key}' was not found") { }
}

public class ValidationException : Exception
{
    public IDictionary<string, string[]> Errors { get; }

    public ValidationException(IDictionary<string, string[]> errors)
        : base("One or more validation errors occurred")
    {
        Errors = errors;
    }
}

public class UnauthorizedException : Exception
{
    public UnauthorizedException(string message) : base(message) { }
}

public class BusinessRuleException : Exception
{
    public string ErrorCode { get; }

    public BusinessRuleException(string message, string errorCode = null)
        : base(message)
    {
        ErrorCode = errorCode;
    }
}

// Usage in services
public class ProductService
{
    public Product GetById(int id)
    {
        var product = _repository.GetById(id);
        
        if (product == null)
        {
            throw new NotFoundException(nameof(Product), id);
        }

        return product;
    }

    public void Delete(int id)
    {
        var product = GetById(id);

        if (product.OrderCount > 0)
        {
            throw new BusinessRuleException(
                "Cannot delete product with existing orders",
                "PRODUCT_HAS_ORDERS");
        }

        _repository.Delete(product);
    }
}
```

### 6. API Error Handling

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsApiController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsApiController> _logger;

    public ProductsApiController(
        IProductService productService,
        ILogger<ProductsApiController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetById(int id)
    {
        try
        {
            var product = await _productService.GetByIdAsync(id);
            return Ok(product);
        }
        catch (NotFoundException ex)
        {
            _logger.LogWarning(ex, "Product {Id} not found", id);
            return NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product {Id}", id);
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpPost]
    public async Task<ActionResult<Product>> Create([FromBody] ProductDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var product = await _productService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation failed for product creation");
            return BadRequest(new { errors = ex.Errors });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }
}

// API error response model
public class ApiErrorResponse
{
    public string Message { get; set; }
    public int StatusCode { get; set; }
    public string ErrorCode { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string TraceId { get; set; }
    public IDictionary<string, string[]> ValidationErrors { get; set; }
}
```

### 7. Logging Integration

```csharp
public class ExceptionLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionLoggingMiddleware> _logger;

    public ExceptionLoggingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            var logLevel = GetLogLevel(ex);

            _logger.Log(logLevel, ex,
                "Exception occurred: {ExceptionType} | Path: {Path} | User: {User}",
                ex.GetType().Name,
                context.Request.Path,
                context.User.Identity?.Name ?? "Anonymous");

            // Re-throw to let other middleware handle it
            throw;
        }
    }

    private static LogLevel GetLogLevel(Exception exception)
    {
        return exception switch
        {
            NotFoundException => LogLevel.Warning,
            ValidationException => LogLevel.Warning,
            UnauthorizedException => LogLevel.Warning,
            _ => LogLevel.Error
        };
    }
}
```

### 8. Error Views

```html
<!-- Views/Shared/Error.cshtml -->
@model ErrorViewModel

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Error - @Model.StatusCode</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .error-container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
        }
        .error-code {
            font-size: 72px;
            font-weight: bold;
            color: #dc3545;
            margin-bottom: 20px;
        }
        .error-message {
            font-size: 24px;
            color: #333;
            margin-bottom: 30px;
        }
        .error-details {
            font-size: 14px;
            color: #666;
            margin-bottom: 30px;
        }
        .home-link {
            display: inline-block;
            padding: 12px 30px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background 0.3s;
        }
        .home-link:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">@Model.StatusCode</div>
        <div class="error-message">@Model.Message</div>
        
        @if (Model.ShowRequestId)
        {
            <div class="error-details">
                Request ID: <code>@Model.RequestId</code>
            </div>
        }
        
        <a href="/" class="home-link">Return to Home</a>
    </div>
</body>
</html>
```

### 9. Problem Details (RFC 7807)

```csharp
// Configure Problem Details
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = context =>
    {
        context.ProblemDetails.Instance = 
            $"{context.HttpContext.Request.Method} {context.HttpContext.Request.Path}";
        
        context.ProblemDetails.Extensions.TryAdd("requestId", 
            context.HttpContext.TraceIdentifier);
        
        context.ProblemDetails.Extensions.TryAdd("timestamp", 
            DateTime.UtcNow);
    };
});

// API Controller using Problem Details
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    [HttpGet("{id}")]
    public ActionResult<Order> GetById(int id)
    {
        var order = _service.GetById(id);
        
        if (order == null)
        {
            return Problem(
                title: "Order not found",
                detail: $"Order with ID {id} does not exist",
                statusCode: StatusCodes.Status404NotFound,
                instance: HttpContext.Request.Path
            );
        }

        return Ok(order);
    }

    [HttpPost]
    public ActionResult<Order> Create(OrderDto dto)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        try
        {
            var order = _service.Create(dto);
            return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
        }
        catch (BusinessRuleException ex)
        {
            return Problem(
                title: "Business rule violation",
                detail: ex.Message,
                statusCode: StatusCodes.Status422UnprocessableEntity
            );
        }
    }
}
```

### 10. Health Checks with Error Handling

```csharp
builder.Services.AddHealthChecks()
    .AddCheck("Database", () =>
    {
        try
        {
            // Check database connectivity
            using var connection = new SqlConnection(connectionString);
            connection.Open();
            return HealthCheckResult.Healthy("Database is healthy");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database is unhealthy", ex);
        }
    })
    .AddCheck("ExternalAPI", () =>
    {
        try
        {
            // Check external API
            var response = _httpClient.GetAsync("https://api.example.com/health").Result;
            return response.IsSuccessStatusCode
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Degraded("API is slow");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("API is down", ex);
        }
    });

app.MapHealthChecks("/health");
```

**Best Practices:**

```
✅ Use exception middleware for global handling
✅ Log all errors with context
✅ Return appropriate HTTP status codes
✅ Provide user-friendly error messages
✅ Hide sensitive error details in production
✅ Use custom exception types for domain errors
✅ Implement retry logic for transient failures
✅ Monitor and alert on errors

❌ Don't expose stack traces in production
❌ Don't log sensitive information
❌ Don't use exceptions for flow control
❌ Don't ignore exceptions silently
```

---

## Q66: Explain the concept of middleware in ASP.NET Core

**Answer:**

Middleware is software that's assembled into an application pipeline to handle requests and responses. Each component in the pipeline can choose to pass the request to the next component or short-circuit the pipeline.

### 1. Middleware Pipeline Basics

```csharp
// Program.cs - Middleware pipeline order matters!
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

var app = builder.Build();

// 1. Exception handling (catch errors from later middleware)
app.UseExceptionHandler("/Error");
app.UseHsts();

// 2. HTTPS redirection
app.UseHttpsRedirection();

// 3. Static files (short-circuits if file found)
app.UseStaticFiles();

// 4. Routing (matches endpoints)
app.UseRouting();

// 5. CORS (if needed)
app.UseCors();

// 6. Authentication (who are you?)
app.UseAuthentication();

// 7. Authorization (what can you do?)
app.UseAuthorization();

// 8. Session (if needed)
app.UseSession();

// 9. Endpoints (execute matched endpoint)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

/*
Request Flow:
Browser → HTTPS Redirect → Static Files → Routing → 
Authentication → Authorization → Endpoint → Response
*/
```

### 2. Custom Middleware (Inline)

```csharp
// Simple inline middleware using Use()
app.Use(async (context, next) =>
{
    // Before next middleware
    Console.WriteLine($"Request: {context.Request.Path}");
    
    await next(); // Call next middleware
    
    // After next middleware
    Console.WriteLine($"Response: {context.Response.StatusCode}");
});

// Short-circuit middleware (doesn't call next)
app.Use(async (context, next) =>
{
    if (context.Request.Path == "/health")
    {
        context.Response.StatusCode = 200;
        await context.Response.WriteAsync("Healthy");
        return; // Don't call next
    }
    
    await next();
});

// Run() - Terminal middleware (always last)
app.Run(async context =>
{
    await context.Response.WriteAsync("End of pipeline");
});
```

### 3. Custom Middleware Class

```csharp
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(
        RequestDelegate next,
        ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var startTime = DateTime.UtcNow;
        var requestId = Guid.NewGuid().ToString();

        _logger.LogInformation(
            "Request {RequestId}: {Method} {Path} started at {Time}",
            requestId,
            context.Request.Method,
            context.Request.Path,
            startTime);

        try
        {
            await _next(context); // Call next middleware

            var duration = DateTime.UtcNow - startTime;
            _logger.LogInformation(
                "Request {RequestId}: completed with {StatusCode} in {Duration}ms",
                requestId,
                context.Response.StatusCode,
                duration.TotalMilliseconds);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Request {RequestId}: failed with exception",
                requestId);
            throw;
        }
    }
}

// Extension method for easy registration
public static class RequestLoggingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(
        this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<RequestLoggingMiddleware>();
    }
}

// Register in Program.cs
app.UseRequestLogging();
```

### 4. Authentication Middleware

```csharp
public class ApiKeyAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;

    public ApiKeyAuthenticationMiddleware(
        RequestDelegate next,
        IConfiguration configuration)
    {
        _next = next;
        _configuration = configuration;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Skip authentication for certain paths
        if (context.Request.Path.StartsWithSegments("/health") ||
            context.Request.Path.StartsWithSegments("/public"))
        {
            await _next(context);
            return;
        }

        // Check for API key in header
        if (!context.Request.Headers.TryGetValue("X-API-Key", out var apiKey))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsJsonAsync(new { error = "API key is missing" });
            return;
        }

        // Validate API key
        var validApiKey = _configuration["ApiKey"];
        if (apiKey != validApiKey)
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsJsonAsync(new { error = "Invalid API key" });
            return;
        }

        // Set user information
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "API User"),
            new Claim(ClaimTypes.Role, "ApiClient")
        };
        var identity = new ClaimsIdentity(claims, "ApiKey");
        context.User = new ClaimsPrincipal(identity);

        await _next(context);
    }
}
```

### 5. Response Caching Middleware

```csharp
public class ResponseCachingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;

    public ResponseCachingMiddleware(
        RequestDelegate next,
        IMemoryCache cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Only cache GET requests
        if (context.Request.Method != HttpMethods.Get)
        {
            await _next(context);
            return;
        }

        var cacheKey = $"response_{context.Request.Path}{context.Request.QueryString}";

        // Try to get from cache
        if (_cache.TryGetValue(cacheKey, out byte[] cachedResponse))
        {
            context.Response.StatusCode = 200;
            context.Response.ContentType = "application/json";
            await context.Response.Body.WriteAsync(cachedResponse);
            context.Response.Headers.Add("X-Cache", "HIT");
            return;
        }

        // Capture response
        var originalBodyStream = context.Response.Body;
        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;

        await _next(context);

        // Cache successful responses
        if (context.Response.StatusCode == 200)
        {
            responseBody.Seek(0, SeekOrigin.Begin);
            var response = await new StreamReader(responseBody).ReadToEndAsync();
            
            _cache.Set(cacheKey, Encoding.UTF8.GetBytes(response), TimeSpan.FromMinutes(5));
            
            context.Response.Headers.Add("X-Cache", "MISS");
        }

        // Copy cached response to original stream
        responseBody.Seek(0, SeekOrigin.Begin);
        await responseBody.CopyToAsync(originalBodyStream);
    }
}
```

### 6. Request/Response Modification

```csharp
public class RequestModificationMiddleware
{
    private readonly RequestDelegate _next;

    public RequestModificationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Add custom header to request
        context.Request.Headers.Add("X-Custom-Header", "CustomValue");

        // Read request body
        context.Request.EnableBuffering();
        var requestBody = await new StreamReader(context.Request.Body).ReadToEndAsync();
        context.Request.Body.Position = 0;

        // Modify request
        // ... perform modifications

        await _next(context);

        // Add custom header to response
        context.Response.Headers.Add("X-Processed-By", "CustomMiddleware");
        context.Response.Headers.Add("X-Request-Time", DateTime.UtcNow.ToString("o"));
    }
}

public class ResponseCompressionMiddleware
{
    private readonly RequestDelegate _next;

    public ResponseCompressionMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var acceptEncoding = context.Request.Headers["Accept-Encoding"].ToString();

        if (acceptEncoding.Contains("gzip"))
        {
            var originalBodyStream = context.Response.Body;

            using var compressedStream = new MemoryStream();
            using (var gzipStream = new GZipStream(compressedStream, CompressionMode.Compress))
            {
                context.Response.Body = gzipStream;
                await _next(context);
            }

            context.Response.Headers.Add("Content-Encoding", "gzip");
            context.Response.ContentLength = compressedStream.Length;

            compressedStream.Seek(0, SeekOrigin.Begin);
            await compressedStream.CopyToAsync(originalBodyStream);
            context.Response.Body = originalBodyStream;
        }
        else
        {
            await _next(context);
        }
    }
}
```

### 7. Conditional Middleware

```csharp
// Use middleware only for specific paths
app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/api"),
    appBuilder =>
    {
        appBuilder.UseMiddleware<ApiKeyAuthenticationMiddleware>();
        appBuilder.UseMiddleware<RateLimitingMiddleware>();
    });

// Use middleware based on environment
if (app.Environment.IsDevelopment())
{
    app.UseMiddleware<DevelopmentLoggingMiddleware>();
}
else
{
    app.UseMiddleware<ProductionMonitoringMiddleware>();
}

// Branch based on condition
app.UseWhen(
    context => context.Request.Query.ContainsKey("debug"),
    appBuilder =>
    {
        appBuilder.UseMiddleware<DebugMiddleware>();
    });
```

### 8. Middleware Ordering

```csharp
/*
CORRECT ORDER (Recommended):
1. ExceptionHandler - Catch all exceptions
2. HSTS - Security
3. HttpsRedirection - Force HTTPS
4. StaticFiles - Serve static files early
5. Routing - Match endpoints
6. CORS - Cross-origin requests
7. Authentication - Identity user
8. Authorization - Check permissions
9. Custom Business Logic
10. Session - State management
11. ResponseCaching
12. Endpoints - Execute matched endpoint

WHY THIS ORDER:
- Security first (HTTPS, HSTS)
- Static files before routing (performance)
- Authentication before authorization
- CORS before authentication
- Custom logic after auth/authz
- Endpoints last
*/

var app = builder.Build();

// ✅ CORRECT ORDER
app.UseExceptionHandler("/Error");
app.UseHsts();
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.UseSession();
app.UseResponseCaching();
app.MapControllers();

// ❌ WRONG ORDER - Authorization before Authentication
app.UseAuthorization();  // WRONG!
app.UseAuthentication(); // WRONG!
```

### 9. Rate Limiting Middleware

```csharp
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly int _requestLimit = 100;
    private readonly TimeSpan _timeWindow = TimeSpan.FromMinutes(1);

    public RateLimitingMiddleware(
        RequestDelegate next,
        IMemoryCache cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = GetClientIdentifier(context);
        var cacheKey = $"ratelimit_{clientId}";

        if (!_cache.TryGetValue(cacheKey, out int requestCount))
        {
            requestCount = 0;
        }

        if (requestCount >= _requestLimit)
        {
            context.Response.StatusCode = 429; // Too Many Requests
            context.Response.Headers.Add("Retry-After", _timeWindow.TotalSeconds.ToString());
            
            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                retryAfter = _timeWindow.TotalSeconds
            });
            return;
        }

        // Increment counter
        _cache.Set(cacheKey, requestCount + 1, _timeWindow);

        // Add rate limit headers
        context.Response.Headers.Add("X-RateLimit-Limit", _requestLimit.ToString());
        context.Response.Headers.Add("X-RateLimit-Remaining", (_requestLimit - requestCount - 1).ToString());

        await _next(context);
    }

    private string GetClientIdentifier(HttpContext context)
    {
        // Use IP address or API key
        return context.Connection.RemoteIpAddress?.ToString() 
            ?? context.Request.Headers["X-API-Key"].ToString() 
            ?? "unknown";
    }
}
```

### 10. Middleware Best Practices

```csharp
// ✅ Good: Middleware with proper error handling
public class SafeMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<SafeMiddleware> _logger;

    public SafeMiddleware(RequestDelegate next, ILogger<SafeMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            // Validate context
            if (context == null)
                throw new ArgumentNullException(nameof(context));

            // Do work
            await ProcessRequestAsync(context);

            // Call next middleware
            await _next(context);

            // Do cleanup
            await CleanupAsync(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in middleware");
            throw; // Re-throw to let error handling middleware catch it
        }
    }

    private Task ProcessRequestAsync(HttpContext context)
    {
        // Processing logic
        return Task.CompletedTask;
    }

    private Task CleanupAsync(HttpContext context)
    {
        // Cleanup logic
        return Task.CompletedTask;
    }
}

// ❌ Bad: Blocking operations
public class BadMiddleware
{
    private readonly RequestDelegate _next;

    public BadMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // ❌ BAD: Blocking call
        Thread.Sleep(1000);

        // ❌ BAD: Sync over async
        _next(context).Wait();
    }
}
```

**Middleware Summary:**

| Aspect | Description |
|--------|-------------|
| **Order** | Critical - wrong order breaks functionality |
| **Purpose** | Handle cross-cutting concerns |
| **Execution** | Sequential pipeline |
| **Short-circuit** | Can stop pipeline execution |
| **Dependencies** | Inject via constructor |
| **Async** | Always use async/await |

---

## Q67: What is Dependency Injection in ASP.NET Core?

**Answer:**

Dependency Injection (DI) is a design pattern that implements Inversion of Control (IoC) for resolving dependencies. ASP.NET Core has built-in DI container that manages object lifecycles and dependencies.

### 1. Basic DI Concepts

```csharp
// Interface
public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string body);
}

// Implementation
public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IConfiguration configuration,
        ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendEmailAsync(string to, string subject, string body)
    {
        _logger.LogInformation("Sending email to {To}", to);
        
        var smtpServer = _configuration["Email:SmtpServer"];
        // Send email logic
        
        await Task.CompletedTask;
    }
}

// Register service
builder.Services.AddScoped<IEmailService, EmailService>();

// Use in controller
public class AccountController : Controller
{
    private readonly IEmailService _emailService;

    public AccountController(IEmailService emailService)
    {
        _emailService = emailService;
    }

    [HttpPost]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        // Create user...
        
        await _emailService.SendEmailAsync(
            model.Email,
            "Welcome",
            "Welcome to our site!");

        return RedirectToAction("Index");
    }
}
```

### 2. Service Lifetimes

```csharp
// TRANSIENT: New instance every time
// Use for: Lightweight, stateless services
builder.Services.AddTransient<ITransientService, TransientService>();

public interface ITransientService
{
    Guid InstanceId { get; }
}

public class TransientService : ITransientService
{
    public Guid InstanceId { get; } = Guid.NewGuid();
}

// SCOPED: One instance per request
// Use for: Database contexts, repository pattern, request-specific data
builder.Services.AddScoped<IScopedService, ScopedService>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString)); // DbContext is Scoped by default

public interface IScopedService
{
    Guid InstanceId { get; }
}

public class ScopedService : IScopedService
{
    public Guid InstanceId { get; } = Guid.NewGuid();
}

// SINGLETON: One instance for application lifetime
// Use for: Configuration, caching, logging
builder.Services.AddSingleton<ISingletonService, SingletonService>();
builder.Services.AddSingleton<IMemoryCache, MemoryCache>();

public interface ISingletonService
{
    Guid InstanceId { get; }
}

public class SingletonService : ISingletonService
{
    public Guid InstanceId { get; } = Guid.NewGuid();
}

// Demonstration
public class LifetimeController : Controller
{
    private readonly ITransientService _transient1;
    private readonly ITransientService _transient2;
    private readonly IScopedService _scoped1;
    private readonly IScopedService _scoped2;
    private readonly ISingletonService _singleton1;
    private readonly ISingletonService _singleton2;

    public LifetimeController(
        ITransientService transient1,
        ITransientService transient2,
        IScopedService scoped1,
        IScopedService scoped2,
        ISingletonService singleton1,
        ISingletonService singleton2)
    {
        _transient1 = transient1;
        _transient2 = transient2;
        _scoped1 = scoped1;
        _scoped2 = scoped2;
        _singleton1 = singleton1;
        _singleton2 = singleton2;
    }

    public IActionResult Index()
    {
        var model = new
        {
            Transient1 = _transient1.InstanceId,
            Transient2 = _transient2.InstanceId, // Different ID
            Scoped1 = _scoped1.InstanceId,
            Scoped2 = _scoped2.InstanceId,       // Same ID (same request)
            Singleton1 = _singleton1.InstanceId,
            Singleton2 = _singleton2.InstanceId   // Same ID (always)
        };

        return Json(model);
    }
}

/*
Output example:
{
    "Transient1": "a1b2c3d4-...",  // Unique
    "Transient2": "e5f6g7h8-...",  // Unique
    "Scoped1": "i9j0k1l2-...",     // Same within request
    "Scoped2": "i9j0k1l2-...",     // Same within request
    "Singleton1": "m3n4o5p6-...",  // Same always
    "Singleton2": "m3n4o5p6-..."   // Same always
}
*/
```

### 3. Repository Pattern with DI

```csharp
// Generic repository interface
public interface IRepository<T> where T : class
{
    Task<T> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(int id);
}

// Generic repository implementation
public class Repository<T> : IRepository<T> where T : class
{
    private readonly ApplicationDbContext _context;
    private readonly DbSet<T> _dbSet;

    public Repository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }

    public async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task UpdateAsync(T entity)
    {
        _dbSet.Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(int id)
    {
        var entity = await GetByIdAsync(id);
        if (entity != null)
        {
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}

// Specific repository
public interface IProductRepository : IRepository<Product>
{
    Task<IEnumerable<Product>> GetByCategory(string category);
    Task<IEnumerable<Product>> SearchByName(string name);
}

public class ProductRepository : Repository<Product>, IProductRepository
{
    private readonly ApplicationDbContext _context;

    public ProductRepository(ApplicationDbContext context) : base(context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Product>> GetByCategory(string category)
    {
        return await _context.Products
            .Where(p => p.Category == category)
            .ToListAsync();
    }

    public async Task<IEnumerable<Product>> SearchByName(string name)
    {
        return await _context.Products
            .Where(p => p.Name.Contains(name))
            .ToListAsync();
    }
}

// Register services
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IProductRepository, ProductRepository>();

// Use in service layer
public class ProductService
{
    private readonly IProductRepository _productRepository;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IProductRepository productRepository,
        ILogger<ProductService> logger)
    {
        _productRepository = productRepository;
        _logger = logger;
    }

    public async Task<Product> GetByIdAsync(int id)
    {
        _logger.LogInformation("Getting product {Id}", id);
        return await _productRepository.GetByIdAsync(id);
    }
}

// Register service
builder.Services.AddScoped<ProductService>();
```

### 4. Multiple Implementations

```csharp
// Multiple implementations of same interface
public interface INotificationService
{
    Task SendAsync(string message);
}

public class EmailNotificationService : INotificationService
{
    public async Task SendAsync(string message)
    {
        // Send email
        await Task.CompletedTask;
    }
}

public class SmsNotificationService : INotificationService
{
    public async Task SendAsync(string message)
    {
        // Send SMS
        await Task.CompletedTask;
    }
}

public class PushNotificationService : INotificationService
{
    public async Task SendAsync(string message)
    {
        // Send push notification
        await Task.CompletedTask;
    }
}

// Register all implementations
builder.Services.AddScoped<INotificationService, EmailNotificationService>();
builder.Services.AddScoped<INotificationService, SmsNotificationService>();
builder.Services.AddScoped<INotificationService, PushNotificationService>();

// Use all implementations
public class NotificationController : Controller
{
    private readonly IEnumerable<INotificationService> _notificationServices;

    public NotificationController(IEnumerable<INotificationService> notificationServices)
    {
        _notificationServices = notificationServices;
    }

    [HttpPost]
    public async Task<IActionResult> SendToAll(string message)
    {
        foreach (var service in _notificationServices)
        {
            await service.SendAsync(message);
        }

        return Ok("Notifications sent");
    }
}

// Named services using factory
builder.Services.AddScoped<Func<string, INotificationService>>(serviceProvider => key =>
{
    return key switch
    {
        "email" => serviceProvider.GetService<EmailNotificationService>(),
        "sms" => serviceProvider.GetService<SmsNotificationService>(),
        "push" => serviceProvider.GetService<PushNotificationService>(),
        _ => throw new KeyNotFoundException()
    };
});
```

### 5. Factory Pattern with DI

```csharp
public interface IReportGenerator
{
    byte[] Generate(ReportData data);
}

public class PdfReportGenerator : IReportGenerator
{
    public byte[] Generate(ReportData data)
    {
        // Generate PDF
        return new byte[0];
    }
}

public class ExcelReportGenerator : IReportGenerator
{
    public byte[] Generate(ReportData data)
    {
        // Generate Excel
        return new byte[0];
    }
}

public class CsvReportGenerator : IReportGenerator
{
    public byte[] Generate(ReportData data)
    {
        // Generate CSV
        return new byte[0];
    }
}

// Factory interface
public interface IReportGeneratorFactory
{
    IReportGenerator Create(string reportType);
}

// Factory implementation
public class ReportGeneratorFactory : IReportGeneratorFactory
{
    private readonly IServiceProvider _serviceProvider;

    public ReportGeneratorFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public IReportGenerator Create(string reportType)
    {
        return reportType.ToLower() switch
        {
            "pdf" => _serviceProvider.GetRequiredService<PdfReportGenerator>(),
            "excel" => _serviceProvider.GetRequiredService<ExcelReportGenerator>(),
            "csv" => _serviceProvider.GetRequiredService<CsvReportGenerator>(),
            _ => throw new ArgumentException($"Unknown report type: {reportType}")
        };
    }
}

// Register services
builder.Services.AddTransient<PdfReportGenerator>();
builder.Services.AddTransient<ExcelReportGenerator>();
builder.Services.AddTransient<CsvReportGenerator>();
builder.Services.AddScoped<IReportGeneratorFactory, ReportGeneratorFactory>();

// Use factory
public class ReportsController : Controller
{
    private readonly IReportGeneratorFactory _factory;

    public ReportsController(IReportGeneratorFactory factory)
    {
        _factory = factory;
    }

    [HttpGet]
    public IActionResult Generate(string type)
    {
        var generator = _factory.Create(type);
        var report = generator.Generate(new ReportData());

        return File(report, GetContentType(type), $"report.{type}");
    }

    private string GetContentType(string type) => type switch
    {
        "pdf" => "application/pdf",
        "excel" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "csv" => "text/csv",
        _ => "application/octet-stream"
    };
}
```

### 6. Options Pattern

```csharp
// Configuration class
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }
    public string FromEmail { get; set; }
}

// appsettings.json
/*
{
  "EmailSettings": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "Username": "user@example.com",
    "Password": "password",
    "FromEmail": "noreply@example.com"
  }
}
*/

// Register options
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// Use in service
public class EmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailSettings> options,
        ILogger<EmailService> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        _logger.LogInformation(
            "Sending email via {Server}:{Port}",
            _settings.SmtpServer,
            _settings.SmtpPort);

        // Use _settings to send email
        await Task.CompletedTask;
    }
}

// Validate options
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("EmailSettings"))
    .ValidateDataAnnotations()
    .ValidateOnStart();

public class EmailSettings
{
    [Required]
    [RegularExpression(@"^[\w-\.]+\.[\w-]{2,4}$")]
    public string SmtpServer { get; set; }

    [Range(1, 65535)]
    public int SmtpPort { get; set; }

    [Required]
    [EmailAddress]
    public string FromEmail { get; set; }
}
```

### 7. Scoped Service in Singleton (Anti-pattern)

```csharp
// ❌ BAD: Scoped service in Singleton (CAPTIVE DEPENDENCY)
public class SingletonService
{
    private readonly IScopedService _scopedService; // WRONG!

    public SingletonService(IScopedService scopedService)
    {
        _scopedService = scopedService; // Scoped service becomes singleton!
    }
}

// ✅ GOOD: Use IServiceProvider to resolve scoped service
public class SingletonService
{
    private readonly IServiceProvider _serviceProvider;

    public SingletonService(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task DoWorkAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var scopedService = scope.ServiceProvider.GetRequiredService<IScopedService>();
        
        // Use scopedService
        await scopedService.ProcessAsync();
    }
}

// ✅ GOOD: Use IServiceScopeFactory
public class SingletonService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public SingletonService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    public async Task DoWorkAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var scopedService = scope.ServiceProvider.GetRequiredService<IScopedService>();
        
        await scopedService.ProcessAsync();
    }
}
```

### 8. Manual Service Resolution

```csharp
// Using IServiceProvider
public class ManualResolutionController : Controller
{
    private readonly IServiceProvider _serviceProvider;

    public ManualResolutionController(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public IActionResult Index()
    {
        // Get required service (throws if not found)
        var emailService = _serviceProvider.GetRequiredService<IEmailService>();

        // Get optional service (returns null if not found)
        var optionalService = _serviceProvider.GetService<IOptionalService>();

        // Get all implementations
        var notificationServices = _serviceProvider.GetServices<INotificationService>();

        return View();
    }
}

// HttpContext service resolution
public class HomeController : Controller
{
    public IActionResult Index()
    {
        // Resolve from HttpContext
        var emailService = HttpContext.RequestServices
            .GetRequiredService<IEmailService>();

        return View();
    }
}
```

### 9. Third-Party DI Containers

```csharp
// Autofac integration
using Autofac;
using Autofac.Extensions.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

// Use Autofac
builder.Host.UseServiceProviderFactory(new AutofacServiceProviderFactory());

builder.Host.ConfigureContainer<ContainerBuilder>(containerBuilder =>
{
    // Register services with Autofac
    containerBuilder.RegisterType<EmailService>()
        .As<IEmailService>()
        .InstancePerLifetimeScope();

    // Property injection
    containerBuilder.RegisterType<ProductService>()
        .PropertiesAutowired();

    // Assembly scanning
    containerBuilder.RegisterAssemblyTypes(typeof(Program).Assembly)
        .Where(t => t.Name.EndsWith("Service"))
        .AsImplementedInterfaces()
        .InstancePerLifetimeScope();
});

var app = builder.Build();
```

**DI Best Practices:**

```
✅ Prefer constructor injection over property injection
✅ Use interfaces for abstraction
✅ Register services in correct lifetime
✅ Avoid service locator pattern
✅ Use Options pattern for configuration
✅ Validate dependencies at startup
✅ Keep constructors simple

❌ Don't inject scoped services into singletons
❌ Don't create circular dependencies
❌ Don't use IServiceProvider everywhere
❌ Don't register concrete classes when interface exists
```

---


## Q68: Explain service lifetimes: Transient, Scoped, and Singleton

**Answer:**

Service lifetimes determine how long service instances live and when they're created/destroyed in ASP.NET Core's dependency injection container.

### 1. Transient Lifetime

```csharp
// TRANSIENT: New instance every time it's requested
builder.Services.AddTransient<ITransientService, TransientService>();

public interface ITransientService
{
    Guid Id { get; }
    void DoWork();
}

public class TransientService : ITransientService
{
    public Guid Id { get; } = Guid.NewGuid();

    public void DoWork()
    {
        Console.WriteLine($"Transient {Id} working");
    }
}

// Example: Multiple injections get different instances
public class TransientExampleController : Controller
{
    private readonly ITransientService _transient1;
    private readonly ITransientService _transient2;
    private readonly ITransientService _transient3;

    public TransientExampleController(
        ITransientService transient1,
        ITransientService transient2,
        ITransientService transient3)
    {
        _transient1 = transient1;
        _transient2 = transient2;
        _transient3 = transient3;
    }

    public IActionResult Index()
    {
        // All three will have DIFFERENT IDs
        var ids = new
        {
            First = _transient1.Id,    // e.g., 12345678-...
            Second = _transient2.Id,   // e.g., 87654321-... (different!)
            Third = _transient3.Id     // e.g., abcd1234-... (different!)
        };

        return Json(ids);
    }
}

// Use cases for Transient:
// ✅ Lightweight services
// ✅ Stateless services
// ✅ Services with no shared state
// ✅ Services that perform a single operation

// Examples:
builder.Services.AddTransient<IEmailSender, EmailSender>();
builder.Services.AddTransient<IValidator<T>, Validator<T>>();
builder.Services.AddTransient<IMapper, AutoMapper>();
```

### 2. Scoped Lifetime

```csharp
// SCOPED: One instance per HTTP request (or scope)
builder.Services.AddScoped<IScopedService, ScopedService>();

public interface IScopedService
{
    Guid Id { get; }
    void DoWork();
}

public class ScopedService : IScopedService
{
    public Guid Id { get; } = Guid.NewGuid();

    public void DoWork()
    {
        Console.WriteLine($"Scoped {Id} working");
    }
}

// Example: Same instance within a request
public class ScopedExampleController : Controller
{
    private readonly IScopedService _scoped1;
    private readonly IScopedService _scoped2;

    public ScopedExampleController(
        IScopedService scoped1,
        IScopedService scoped2)
    {
        _scoped1 = scoped1;
        _scoped2 = scoped2;
    }

    public IActionResult Index([FromServices] IScopedService scoped3)
    {
        // All three will have the SAME ID (same request)
        var ids = new
        {
            FromConstructor1 = _scoped1.Id, // e.g., aaaabbbb-...
            FromConstructor2 = _scoped2.Id, // e.g., aaaabbbb-... (same!)
            FromParameter = scoped3.Id       // e.g., aaaabbbb-... (same!)
        };

        return Json(ids);
    }
}

// Use cases for Scoped:
// ✅ Database contexts (DbContext)
// ✅ Unit of Work pattern
// ✅ Repository pattern
// ✅ Request-specific data
// ✅ Services that need to maintain state within a request

// Examples:
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddDbContext<AppDbContext>(); // Scoped by default
```

### 3. Singleton Lifetime

```csharp
// SINGLETON: One instance for the entire application lifetime
builder.Services.AddSingleton<ISingletonService, SingletonService>();

public interface ISingletonService
{
    Guid Id { get; }
    int Counter { get; }
    void IncrementCounter();
}

public class SingletonService : ISingletonService
{
    private int _counter = 0;

    public Guid Id { get; } = Guid.NewGuid();
    public int Counter => _counter;

    public void IncrementCounter()
    {
        Interlocked.Increment(ref _counter);
    }
}

// Example: Same instance always
public class SingletonExampleController : Controller
{
    private readonly ISingletonService _singleton1;
    private readonly ISingletonService _singleton2;

    public SingletonExampleController(
        ISingletonService singleton1,
        ISingletonService singleton2)
    {
        _singleton1 = singleton1;
        _singleton2 = singleton2;
    }

    public IActionResult Index([FromServices] ISingletonService singleton3)
    {
        _singleton1.IncrementCounter();

        // All three will have the SAME ID (always, across all requests)
        var info = new
        {
            FromConstructor1 = _singleton1.Id, // e.g., zzzzxxxx-...
            FromConstructor2 = _singleton2.Id, // e.g., zzzzxxxx-... (same!)
            FromParameter = singleton3.Id,      // e.g., zzzzxxxx-... (same!)
            Counter = _singleton1.Counter       // Increments across requests!
        };

        return Json(info);
    }
}

// Use cases for Singleton:
// ✅ Configuration services
// ✅ Caching services
// ✅ Logging services
// ✅ State that must be shared across requests
// ✅ Thread-safe stateless services
// ⚠️ MUST be thread-safe!

// Examples:
builder.Services.AddSingleton<IMemoryCache, MemoryCache>();
builder.Services.AddSingleton<IConfiguration>(builder.Configuration);
builder.Services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
```

### 4. Lifetime Comparison

```csharp
public class LifetimeDemoController : Controller
{
    private readonly ITransientService _transient;
    private readonly IScopedService _scoped;
    private readonly ISingletonService _singleton;

    public LifetimeDemoController(
        ITransientService transient,
        IScopedService scoped,
        ISingletonService singleton)
    {
        _transient = transient;
        _scoped = scoped;
        _singleton = singleton;
    }

    public IActionResult Compare()
    {
        var result = new
        {
            Request1 = GetIds(),
            Request2 = GetIds() // Simulate checking twice
        };

        return Json(result);
    }

    private object GetIds()
    {
        return new
        {
            Transient = _transient.Id,  // Always different
            Scoped = _scoped.Id,         // Same within request
            Singleton = _singleton.Id    // Always same
        };
    }
}

/*
Example Output:
{
  "Request1": {
    "Transient": "aaa-111",   ← Different each time
    "Scoped": "bbb-222",      ← Same in Request 1
    "Singleton": "ccc-333"    ← Always same
  },
  "Request2": {
    "Transient": "aaa-444",   ← Different again!
    "Scoped": "bbb-555",      ← Different (new request)
    "Singleton": "ccc-333"    ← Still same!
  }
}
*/
```

### 5. Lifetime Visualization

```csharp
/*
APPLICATION LIFETIME
┌───────────────────────────────────────────────────────┐
│                                                       │
│  SINGLETON (Lives entire app lifetime)               │
│  Instance A ═══════════════════════════════════════  │
│                                                       │
│                                                       │
│  REQUEST 1                    REQUEST 2              │
│  ┌─────────────────┐          ┌──────────────────┐  │
│  │                 │          │                  │  │
│  │ SCOPED          │          │ SCOPED           │  │
│  │ Instance B      │          │ Instance D       │  │
│  │ ═══════════     │          │ ══════════       │  │
│  │                 │          │                  │  │
│  │ TRANSIENT       │          │ TRANSIENT        │  │
│  │ Inst C1 ═══     │          │ Inst E1 ═══     │  │
│  │ Inst C2   ═══   │          │ Inst E2   ═══   │  │
│  │ Inst C3     ═══ │          │ Inst E3     ═══ │  │
│  │                 │          │                  │  │
│  └─────────────────┘          └──────────────────┘  │
│                                                       │
└───────────────────────────────────────────────────────┘
*/
```

### 6. Captive Dependency Anti-Pattern

```csharp
// ❌ DANGEROUS: Scoped service captured by Singleton
public class SingletonService
{
    private readonly IScopedService _scopedService; // WRONG!

    // This makes the scoped service effectively a singleton
    // Can cause stale data, memory leaks, threading issues
    public SingletonService(IScopedService scopedService)
    {
        _scopedService = scopedService; // ⚠️ Captive dependency!
    }
}

// ✅ CORRECT: Use IServiceScopeFactory
public class SingletonService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public SingletonService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    public async Task DoWorkAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var scopedService = scope.ServiceProvider
            .GetRequiredService<IScopedService>();
        
        await scopedService.ProcessAsync();
        
        // scopedService is disposed when scope ends
    }
}

// ❌ DANGEROUS: Transient service with IDisposable in Singleton
public class ExpensiveDisposableService : IDisposable
{
    public void Dispose()
    {
        // Cleanup
    }
}

builder.Services.AddTransient<ExpensiveDisposableService>(); // Will never be disposed!

// ✅ CORRECT: Use scoped or singleton for IDisposable services
builder.Services.AddScoped<ExpensiveDisposableService>();
```

### 7. Real-World Examples

```csharp
// Transient: Email sender (stateless, lightweight)
public class EmailSender : IEmailSender
{
    private readonly SmtpClient _smtpClient;

    public EmailSender(IOptions<EmailSettings> settings)
    {
        _smtpClient = new SmtpClient(settings.Value.Host);
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        await _smtpClient.SendMailAsync(to, subject, body);
    }
}
builder.Services.AddTransient<IEmailSender, EmailSender>();

// Scoped: Database context (request-specific, trackable)
public class ApplicationDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
}
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString)); // Scoped by default

// Scoped: Unit of Work (coordinates multiple repositories)
public class UnitOfWork : IUnitOfWork, IDisposable
{
    private readonly ApplicationDbContext _context;
    private IProductRepository _products;
    private IOrderRepository _orders;

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
    }

    public IProductRepository Products => 
        _products ??= new ProductRepository(_context);

    public IOrderRepository Orders => 
        _orders ??= new OrderRepository(_context);

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public void Dispose()
    {
        _context?.Dispose();
    }
}
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Singleton: Cache service (shared state, thread-safe)
public class CacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public CacheService(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task<T> GetOrCreateAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration)
    {
        if (_cache.TryGetValue(key, out T value))
        {
            return value;
        }

        await _semaphore.WaitAsync();
        try
        {
            // Double-check after acquiring lock
            if (_cache.TryGetValue(key, out value))
            {
                return value;
            }

            value = await factory();
            _cache.Set(key, value, expiration);
            return value;
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
builder.Services.AddSingleton<ICacheService, CacheService>();
```

### 8. Lifetime Decision Tree

```csharp
/*
Choose Lifetime:

Is the service thread-safe and stateless?
├─ YES: Can it be shared across the entire app?
│   ├─ YES: → SINGLETON
│   └─ NO: → TRANSIENT or SCOPED
└─ NO: Does it need to maintain state per request?
    ├─ YES: → SCOPED
    └─ NO: → TRANSIENT

Special cases:
- DbContext → SCOPED (always)
- IMemoryCache → SINGLETON
- ILogger<T> → SINGLETON
- HttpClient (via IHttpClientFactory) → managed by factory
- Services with IDisposable → avoid TRANSIENT
*/
```

### 9. Performance Considerations

```csharp
// Transient overhead
/*
10,000 requests:
- Transient: 10,000 instances created
- Scoped: 10,000 instances created (1 per request)
- Singleton: 1 instance created

Memory pressure:
- Transient: High (if services are heavy)
- Scoped: Medium (lifetime bound to request)
- Singleton: Low (but held forever)
*/

// Heavy service example
public class HeavyService
{
    private readonly byte[] _largeBuffer = new byte[1024 * 1024]; // 1MB

    // If Transient: 1MB × 10,000 = 10GB memory pressure!
    // If Scoped: 1MB per concurrent request
    // If Singleton: 1MB total
}

// ❌ BAD: Heavy transient service
builder.Services.AddTransient<HeavyService>(); // Creates 1MB every time!

// ✅ GOOD: Make it singleton if thread-safe
builder.Services.AddSingleton<HeavyService>();

// ✅ GOOD: Or use object pooling
builder.Services.AddSingleton<ObjectPool<HeavyService>>();
```

### 10. Testing Lifetimes

```csharp
public class LifetimeTests
{
    [Fact]
    public void Transient_CreatesDifferentInstances()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddTransient<ITransientService, TransientService>();
        var provider = services.BuildServiceProvider();

        // Act
        var instance1 = provider.GetService<ITransientService>();
        var instance2 = provider.GetService<ITransientService>();

        // Assert
        Assert.NotSame(instance1, instance2);
    }

    [Fact]
    public void Scoped_CreatesSameInstanceInScope()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddScoped<IScopedService, ScopedService>();
        var provider = services.BuildServiceProvider();

        // Act & Assert
        using (var scope = provider.CreateScope())
        {
            var instance1 = scope.ServiceProvider.GetService<IScopedService>();
            var instance2 = scope.ServiceProvider.GetService<IScopedService>();
            
            Assert.Same(instance1, instance2); // Same in scope
        }

        // Different scope = different instance
        using (var scope = provider.CreateScope())
        {
            var instance3 = scope.ServiceProvider.GetService<IScopedService>();
            // instance3 is different from instance1 and instance2
        }
    }

    [Fact]
    public void Singleton_CreatesOneInstance()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddSingleton<ISingletonService, SingletonService>();
        var provider = services.BuildServiceProvider();

        // Act
        var instance1 = provider.GetService<ISingletonService>();
        var instance2 = provider.GetService<ISingletonService>();

        using (var scope = provider.CreateScope())
        {
            var instance3 = scope.ServiceProvider.GetService<ISingletonService>();
            
            // Assert - all same instance
            Assert.Same(instance1, instance2);
            Assert.Same(instance1, instance3);
        }
    }
}
```

**Lifetime Summary:**

| Lifetime | Created | Disposed | Use For | Thread-Safe? |
|----------|---------|----------|---------|--------------|
| **Transient** | Every time | After use | Lightweight, stateless | Yes (new instance) |
| **Scoped** | Per request | End of request | DbContext, repositories | Yes (per request) |
| **Singleton** | Once | App shutdown | Config, cache, logging | MUST BE! |

---

## Q69: How do you configure services in ASP.NET Core?

**Answer:**

Service configuration in ASP.NET Core is done in the `Program.cs` file (or `Startup.cs` in older versions) using the built-in dependency injection container.

### 1. Basic Service Registration

```csharp
// Program.cs (.NET 6+)
var builder = WebApplication.CreateBuilder(args);

// Add MVC services
builder.Services.AddControllersWithViews();

// Add Razor Pages
builder.Services.AddRazorPages();

// Add API controllers
builder.Services.AddControllers();

// Add API with views
builder.Services.AddControllersWithViews()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
        options.JsonSerializerOptions.WriteIndented = true;
    });

// Configure custom services
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddSingleton<ICacheService, CacheService>();
builder.Services.AddTransient<IEmailService, EmailService>();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
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
```

### 2. Database Configuration

```csharp
// SQL Server
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
            sqlOptions.CommandTimeout(60);
        }));

// PostgreSQL
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PostgresConnection")));

// MySQL
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(
        builder.Configuration.GetConnectionString("MySqlConnection"),
        ServerVersion.AutoDetect(builder.Configuration.GetConnectionString("MySqlConnection"))));

// In-Memory (for testing)
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseInMemoryDatabase("TestDatabase"));

// Multiple DbContexts
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("AppDb")));

builder.Services.AddDbContext<IdentityDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("IdentityDb")));

// Connection string in appsettings.json
/*
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=MyApp;Trusted_Connection=True;",
    "PostgresConnection": "Host=localhost;Database=myapp;Username=postgres;Password=password",
    "MySqlConnection": "Server=localhost;Database=myapp;User=root;Password=password;"
  }
}
*/
```

### 3. Authentication & Authorization

```csharp
// Cookie Authentication
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(1);
        options.SlidingExpiration = true;
    });

// JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
        };
    });

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    // Password settings
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 8;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireLowercase = true;

    // Lockout settings
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User settings
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// Authorization policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireRole("Admin"));

    options.AddPolicy("MinimumAge", policy =>
        policy.Requirements.Add(new MinimumAgeRequirement(18)));

    options.AddPolicy("CanEditProduct", policy =>
        policy.RequireClaim("Permission", "EditProduct"));
});
```

### 4. Caching Configuration

```csharp
// In-Memory Cache
builder.Services.AddMemoryCache(options =>
{
    options.SizeLimit = 1024; // Limit size
    options.CompactionPercentage = 0.25; // Compact when 75% full
    options.ExpirationScanFrequency = TimeSpan.FromMinutes(5);
});

// Distributed Cache - Redis
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
    options.InstanceName = "MyApp_";
});

// Distributed Cache - SQL Server
builder.Services.AddDistributedSqlServerCache(options =>
{
    options.ConnectionString = builder.Configuration.GetConnectionString("CacheDb");
    options.SchemaName = "dbo";
    options.TableName = "AppCache";
});

// Response Caching
builder.Services.AddResponseCaching(options =>
{
    options.MaximumBodySize = 1024;
    options.UseCaseSensitivePaths = true;
});
```

### 5. HTTP Client Configuration

```csharp
// Basic HTTP Client
builder.Services.AddHttpClient();

// Named client
builder.Services.AddHttpClient("GitHub", client =>
{
    client.BaseAddress = new Uri("https://api.github.com/");
    client.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");
    client.DefaultRequestHeaders.Add("User-Agent", "MyApp");
});

// Typed client
builder.Services.AddHttpClient<IGitHubService, GitHubService>(client =>
{
    client.BaseAddress = new Uri("https://api.github.com/");
});

// With Polly (retry policy)
builder.Services.AddHttpClient("RetryClient")
    .AddTransientHttpErrorPolicy(policy =>
        policy.WaitAndRetryAsync(3, retryAttempt =>
            TimeSpan.FromSeconds(Math.Pow(2, retryAttempt))))
    .AddTransientHttpErrorPolicy(policy =>
        policy.CircuitBreakerAsync(5, TimeSpan.FromSeconds(30)));

// With custom message handler
builder.Services.AddHttpClient("CustomClient")
    .AddHttpMessageHandler<AuthenticationHandler>();
```

### 6. Logging Configuration

```csharp
// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
builder.Logging.AddEventSourceLogger();

// Set log levels
builder.Logging.AddFilter("Microsoft", LogLevel.Warning);
builder.Logging.AddFilter("System", LogLevel.Warning);
builder.Logging.AddFilter("MyApp", LogLevel.Information);

// Serilog
builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day)
        .WriteTo.Seq("http://localhost:5341");
});

// appsettings.json logging configuration
/*
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  }
}
*/
```

### 7. CORS Configuration

```csharp
// Add CORS
builder.Services.AddCors(options =>
{
    // Default policy
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });

    // Named policy
    options.AddPolicy("AllowSpecificOrigin", policy =>
    {
        policy.WithOrigins("https://example.com", "https://www.example.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });

    // Restrictive policy
    options.AddPolicy("RestrictivePolicy", policy =>
    {
        policy.WithOrigins("https://trusted-site.com")
              .WithMethods("GET", "POST")
              .WithHeaders("Content-Type", "Authorization")
              .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
    });
});

// Use CORS in pipeline
app.UseCors("AllowSpecificOrigin");
```

### 8. Options Pattern Configuration

```csharp
// Configuration class
public class EmailSettings
{
    public string SmtpServer { get; set; }
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; }
    public string FromName { get; set; }
}

public class AppSettings
{
    public string ApplicationName { get; set; }
    public string Version { get; set; }
    public int MaxUploadSize { get; set; }
}

// Register options
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("Email"));

builder.Services.Configure<AppSettings>(
    builder.Configuration.GetSection("App"));

// Validate options
builder.Services.AddOptions<EmailSettings>()
    .Bind(builder.Configuration.GetSection("Email"))
    .ValidateDataAnnotations()
    .ValidateOnStart();

// Use in service
public class EmailService
{
    private readonly EmailSettings _settings;

    public EmailService(IOptions<EmailSettings> options)
    {
        _settings = options.Value;
    }
}

// appsettings.json
/*
{
  "Email": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@example.com",
    "FromName": "My App"
  },
  "App": {
    "ApplicationName": "My Application",
    "Version": "1.0.0",
    "MaxUploadSize": 10485760
  }
}
*/
```

### 9. Health Checks

```csharp
// Add health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())
    .AddSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "database",
        timeout: TimeSpan.FromSeconds(3))
    .AddRedis(
        builder.Configuration.GetConnectionString("Redis"),
        name: "redis")
    .AddUrlGroup(
        new Uri("https://api.example.com/health"),
        name: "external-api")
    .AddCheck<CustomHealthCheck>("custom-check");

// Custom health check
public class CustomHealthCheck : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        // Check something
        var isHealthy = await CheckSomethingAsync();

        return isHealthy
            ? HealthCheckResult.Healthy("Everything is fine")
            : HealthCheckResult.Unhealthy("Something is wrong");
    }

    private Task<bool> CheckSomethingAsync() => Task.FromResult(true);
}

// Use health checks
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

### 10. Session Configuration

```csharp
// Add session
builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});

// Use session
app.UseSession();

// In controller
public class HomeController : Controller
{
    public IActionResult Index()
    {
        HttpContext.Session.SetString("Username", "John");
        HttpContext.Session.SetInt32("UserId", 123);

        var username = HttpContext.Session.GetString("Username");
        var userId = HttpContext.Session.GetInt32("UserId");

        return View();
    }
}
```

**Service Configuration Best Practices:**

```
✅ Register services with appropriate lifetime
✅ Use Options pattern for configuration
✅ Configure services in logical groups
✅ Use extension methods for clean organization
✅ Validate configuration at startup
✅ Use IServiceCollection extensions
✅ Keep Program.cs clean and organized

❌ Don't register services in wrong lifetime
❌ Don't hard-code configuration values
❌ Don't mix configuration and business logic
❌ Don't ignore validation
```

---

## Q70: What is the purpose of Configure() and ConfigureServices() methods?

**Answer:**

In ASP.NET Core (pre-.NET 6), `ConfigureServices()` registers services with the DI container, while `Configure()` sets up the HTTP request pipeline with middleware. In .NET 6+, these are simplified in `Program.cs`.

### 1. Classic Startup.cs Pattern (.NET 5 and earlier)

```csharp
public class Startup
{
    public IConfiguration Configuration { get; }

    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    // ConfigureServices: Register services with DI container
    // Called FIRST by the runtime
    // Purpose: Add services to the container
    public void ConfigureServices(IServiceCollection services)
    {
        // Add framework services
        services.AddControllersWithViews();
        services.AddRazorPages();

        // Add database
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));

        // Add Identity
        services.AddIdentity<ApplicationUser, IdentityRole>()
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

        // Add custom services
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddSingleton<ICacheService, CacheService>();

        // Add authentication
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidIssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(Configuration["Jwt:Key"]))
                };
            });

        // Add CORS
        services.AddCors(options =>
        {
            options.AddPolicy("AllowAll", policy =>
            {
                policy.AllowAnyOrigin()
                      .AllowAnyMethod()
                      .AllowAnyHeader();
            });
        });
    }

    // Configure: Set up HTTP request pipeline
    // Called SECOND by the runtime
    // Purpose: Configure middleware pipeline
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        // Middleware order matters!

        // 1. Exception handling
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
            app.UseDatabaseErrorPage();
        }
        else
        {
            app.UseExceptionHandler("/Error");
            app.UseHsts();
        }

        // 2. HTTPS redirection
        app.UseHttpsRedirection();

        // 3. Static files
        app.UseStaticFiles();

        // 4. Routing
        app.UseRouting();

        // 5. CORS
        app.UseCors("AllowAll");

        // 6. Authentication
        app.UseAuthentication();

        // 7. Authorization
        app.UseAuthorization();

        // 8. Session (if needed)
        app.UseSession();

        // 9. Custom middleware
        app.UseMiddleware<RequestLoggingMiddleware>();

        // 10. Endpoints
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");
            
            endpoints.MapRazorPages();
            
            endpoints.MapHealthChecks("/health");
        });
    }
}
```

### 2. Modern Program.cs Pattern (.NET 6+)

```csharp
// Program.cs - Combines ConfigureServices and Configure
var builder = WebApplication.CreateBuilder(args);

// ═══════════════════════════════════════════════════════
// SERVICE CONFIGURATION (was ConfigureServices)
// ═══════════════════════════════════════════════════════

builder.Services.AddControllersWithViews();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddSingleton<ICacheService, CacheService>();

var app = builder.Build();

// ═══════════════════════════════════════════════════════
// MIDDLEWARE PIPELINE (was Configure)
// ═══════════════════════════════════════════════════════

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

### 3. Environment-Specific Configuration

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllersWithViews();
    }

    // Development-specific configuration
    public void ConfigureDevelopmentServices(IServiceCollection services)
    {
        ConfigureServices(services);
        
        // Add development-only services
        services.AddDatabaseDeveloperPageExceptionFilter();
    }

    // Production-specific configuration
    public void ConfigureProductionServices(IServiceCollection services)
    {
        ConfigureServices(services);
        
        // Add production-only services
        services.AddApplicationInsightsTelemetry();
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }
        else
        {
            app.UseExceptionHandler("/Error");
            app.UseHsts();
        }

        app.UseStaticFiles();
        app.UseRouting();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }

    // Environment-specific Configure
    public void ConfigureDevelopment(IApplicationBuilder app)
    {
        app.UseDeveloperExceptionPage();
        app.UseMiddleware<DevelopmentLoggingMiddleware>();
        
        Configure(app, null);
    }

    public void ConfigureProduction(IApplicationBuilder app)
    {
        app.UseExceptionHandler("/Error");
        app.UseMiddleware<ProductionMonitoringMiddleware>();
        
        Configure(app, null);
    }
}
```

### 4. Extension Methods for Organization

```csharp
// ServiceCollectionExtensions.cs
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Add repositories
        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<ICustomerRepository, CustomerRepository>();

        // Add services
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<ICustomerService, CustomerService>();

        // Add utilities
        services.AddSingleton<IEmailSender, EmailSender>();
        services.AddSingleton<ICacheManager, CacheManager>();

        return services;
    }

    public static IServiceCollection AddDatabaseConfiguration(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                sqlOptions =>
                {
                    sqlOptions.EnableRetryOnFailure(5);
                    sqlOptions.CommandTimeout(30);
                }));

        return services;
    }

    public static IServiceCollection AddAuthenticationConfiguration(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidIssuer = configuration["Jwt:Issuer"],
                    ValidAudience = configuration["Jwt:Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
                };
            });

        return services;
    }
}

// ApplicationBuilderExtensions.cs
public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder UseCustomExceptionHandler(
        this IApplicationBuilder app)
    {
        return app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
    }

    public static IApplicationBuilder UseRequestLogging(
        this IApplicationBuilder app)
    {
        return app.UseMiddleware<RequestLoggingMiddleware>();
    }
}

// Usage in Startup.cs
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllersWithViews();
        services.AddDatabaseConfiguration(Configuration);
        services.AddAuthenticationConfiguration(Configuration);
        services.AddApplicationServices(Configuration);
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.UseCustomExceptionHandler();
        app.UseHttpsRedirection();
        app.UseStaticFiles();
        app.UseRouting();
        app.UseRequestLogging();
        app.UseAuthentication();
        app.UseAuthorization();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}
```

### 5. Accessing Services in Configure

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddSingleton<ICustomService, CustomService>();
        services.AddControllersWithViews();
    }

    // Inject services needed during configuration
    public void Configure(
        IApplicationBuilder app,
        IWebHostEnvironment env,
        ILogger<Startup> logger,
        ICustomService customService) // Can inject any registered service
    {
        logger.LogInformation("Configuring application...");

        // Use injected service
        customService.Initialize();

        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseRouting();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });

        logger.LogInformation("Application configured successfully");
    }
}
```

### 6. Seed Data During Startup

```csharp
public class Startup
{
    public void Configure(
        IApplicationBuilder app,
        IWebHostEnvironment env,
        ApplicationDbContext dbContext,
        UserManager<ApplicationUser> userManager)
    {
        // Ensure database is created
        dbContext.Database.EnsureCreated();

        // Seed data
        if (!dbContext.Products.Any())
        {
            dbContext.Products.AddRange(
                new Product { Name = "Product 1", Price = 10.99m },
                new Product { Name = "Product 2", Price = 20.99m }
            );
            dbContext.SaveChanges();
        }

        // Create default admin user
        SeedUsers(userManager).Wait();

        // Configure middleware
        app.UseRouting();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }

    private async Task SeedUsers(UserManager<ApplicationUser> userManager)
    {
        if (!userManager.Users.Any())
        {
            var adminUser = new ApplicationUser
            {
                UserName = "admin@example.com",
                Email = "admin@example.com"
            };

            await userManager.CreateAsync(adminUser, "Admin@123");
            await userManager.AddToRoleAsync(adminUser, "Admin");
        }
    }
}
```

### 7. Key Differences

```csharp
/*
ConfigureServices():
┌─────────────────────────────────────────────────┐
│ Purpose: Register services with DI container   │
│ When: Called FIRST                             │
│ Return: void                                    │
│ Access: IServiceCollection                     │
│ Examples:                                       │
│   - AddControllers()                            │
│   - AddDbContext()                              │
│   - AddScoped<IService, Service>()              │
│   - Configure<Options>()                        │
└─────────────────────────────────────────────────┘

Configure():
┌─────────────────────────────────────────────────┐
│ Purpose: Configure HTTP request pipeline       │
│ When: Called SECOND (after services)           │
│ Return: void                                    │
│ Access: IApplicationBuilder                    │
│ Examples:                                       │
│   - UseRouting()                                │
│   - UseAuthentication()                         │
│   - UseMiddleware<T>()                          │
│   - MapControllers()                            │
└─────────────────────────────────────────────────┘

Execution Order:
1. Constructor (Startup)
2. ConfigureServices() → Register all services
3. Configure() → Build middleware pipeline
4. Application starts → Handle requests
*/
```

### 8. Common Patterns

```csharp
// Pattern 1: Modular configuration
public void ConfigureServices(IServiceCollection services)
{
    ConfigureDatabase(services);
    ConfigureAuthentication(services);
    ConfigureApplicationServices(services);
}

private void ConfigureDatabase(IServiceCollection services)
{
    services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlServer(Configuration.GetConnectionString("Default")));
}

private void ConfigureAuthentication(IServiceCollection services)
{
    services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
        .AddCookie();
}

private void ConfigureApplicationServices(IServiceCollection services)
{
    services.AddScoped<IProductService, ProductService>();
}

// Pattern 2: Conditional registration
public void ConfigureServices(IServiceCollection services)
{
    services.AddControllersWithViews();

    if (Configuration.GetValue<bool>("Features:UseRedisCache"))
    {
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = Configuration.GetConnectionString("Redis");
        });
    }
    else
    {
        services.AddDistributedMemoryCache();
    }
}

// Pattern 3: Feature flags
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    var useDetailedErrors = Configuration.GetValue<bool>("Features:DetailedErrors");

    if (env.IsDevelopment() || useDetailedErrors)
    {
        app.UseDeveloperExceptionPage();
    }
    else
    {
        app.UseExceptionHandler("/Error");
    }
}
```

**Summary:**

| Method | Purpose | When | What It Does |
|--------|---------|------|--------------|
| **ConfigureServices** | Register services | Called first | Adds services to DI container |
| **Configure** | Setup pipeline | Called second | Adds middleware to pipeline |

---

