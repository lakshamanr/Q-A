-- ============================================================================
-- SQL IMPORT SCRIPT: ANGULAR INTERVIEW QUESTIONS (Q352-Q359)
-- ============================================================================
-- Description: Import Angular & Frontend Development questions into app.db
-- Category: Angular & Frontend Development
-- Questions: Q352-Q359 (8 questions completed)
-- Date: 2025-12-31
-- ============================================================================

-- ============================================================================
-- STEP 1: INSERT CATEGORY
-- ============================================================================

INSERT INTO Categories (Name, Description, Icon, ColorCode, DisplayOrder, QuestionRangeStart, QuestionRangeEnd)
VALUES (
    'Angular & Frontend Development',
    'Comprehensive Angular framework questions covering components, modules, services, directives, data binding, lifecycle hooks, and modern frontend development patterns',
    'fab fa-angular',
    '#DD0031',
    12,
    352,
    376
);

-- ============================================================================
-- STEP 2: INSERT QUESTIONS (Q352-Q359)
-- ============================================================================
-- Note: Using inline subquery for CategoryId since SQLite doesn't support DECLARE

-- ----------------------------------------------------------------------------
-- Q352: What is Angular? How is it different from AngularJS?
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    352,
    'What is Angular? How is it different from AngularJS?',
    '**Angular** (Angular 2+) is a complete rewrite of AngularJS, built with TypeScript for modern web applications. It''s a platform and framework for building client-side applications using HTML, CSS, and TypeScript.

### Key Differences: Angular vs AngularJS

| Feature | AngularJS (1.x) | Angular (2+) |
|---------|-----------------|--------------|
| **Language** | JavaScript | TypeScript |
| **Architecture** | MVC (Model-View-Controller) | Component-based |
| **Mobile Support** | Limited | Excellent (responsive) |
| **Performance** | Slower (digest cycle) | Faster (change detection) |
| **Dependency Injection** | Function-based | Constructor-based |
| **Directives** | ng-* (ng-model, ng-repeat) | [] and () bindings |
| **Routing** | $routeProvider | @angular/router |
| **Data Binding** | Two-way by default | One-way by default |
| **CLI** | No official CLI | Angular CLI |
| **Release** | 2010 | 2016 |

### AngularJS (1.x) Example

```javascript
// Controller
angular.module(''myApp'', [])
  .controller(''CustomerController'', function($scope, $http) {
    $scope.customers = [];

    $scope.loadCustomers = function() {
      $http.get(''/api/customers'')
        .then(function(response) {
          $scope.customers = response.data;
        });
    };

    $scope.deleteCustomer = function(id) {
      $http.delete(''/api/customers/'' + id)
        .then(function() {
          $scope.loadCustomers();
        });
    };
  });
```

```html
<!-- View -->
<div ng-controller="CustomerController">
  <ul>
    <li ng-repeat="customer in customers">
      {{customer.name}}
      <button ng-click="deleteCustomer(customer.id)">Delete</button>
    </li>
  </ul>
</div>
```

### Angular (2+) Example

```typescript
// customer.model.ts
export interface Customer {
  id: number;
  name: string;
  email: string;
  createdDate: Date;
}

// customer.service.ts
@Injectable({
  providedIn: ''root''
})
export class CustomerService {
  private apiUrl = ''/api/customers'';

  constructor(private http: HttpClient) {}

  getCustomers(): Observable<Customer[]> {
    return this.http.get<Customer[]>(this.apiUrl);
  }

  deleteCustomer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}

// customer-list.component.ts
@Component({
  selector: ''app-customer-list'',
  templateUrl: ''./customer-list.component.html''
})
export class CustomerListComponent implements OnInit {
  customers: Customer[] = [];

  constructor(private customerService: CustomerService) {}

  ngOnInit(): void {
    this.loadCustomers();
  }

  loadCustomers(): void {
    this.customerService.getCustomers()
      .subscribe(data => this.customers = data);
  }

  deleteCustomer(id: number): void {
    this.customerService.deleteCustomer(id)
      .subscribe(() => this.loadCustomers());
  }
}
```

### Why Angular (2+) is Better

**TypeScript Benefits:**
- Strong typing prevents errors
- Better IDE support and autocomplete
- Interfaces and classes for better code organization

**Better Performance:**
- Zone.js for efficient change detection
- OnPush change detection strategy
- Ahead-of-Time (AOT) compilation

**Modularity:**
- Feature modules for better organization
- Lazy loading for improved performance
- Tree-shaking for smaller bundle sizes',
    1,
    'Angular,AngularJS,TypeScript,Frontend,Framework',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q353: Explain Angular architecture (components, modules, services)
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    353,
    'Explain Angular architecture (components, modules, services)',
    'Angular follows a **component-based architecture** with clear separation of concerns.

### Core Building Blocks

#### 1. COMPONENTS (UI Logic)

```typescript
@Component({
  selector: ''app-product-card'',
  templateUrl: ''./product-card.component.html'',
  styleUrls: [''./product-card.component.css'']
})
export class ProductCardComponent implements OnInit {
  @Input() product: Product;
  @Output() addToCart = new EventEmitter<Product>();

  quantity = 1;

  constructor(
    private productService: ProductService,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    console.log(''Component initialized'');
  }

  onAddToCart(): void {
    this.cartService.addItem(this.product, this.quantity);
    this.addToCart.emit(this.product);
  }
}
```

#### 2. MODULES (Feature Organization)

```typescript
@NgModule({
  declarations: [
    ProductListComponent,
    ProductDetailComponent,
    ProductCardComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    ProductRoutingModule
  ],
  providers: [
    ProductService,
    CartService
  ],
  exports: [
    ProductCardComponent
  ]
})
export class ProductModule { }
```

#### 3. SERVICES (Business Logic & Data)

```typescript
@Injectable({
  providedIn: ''root''
})
export class ProductService {
  private apiUrl = ''https://api.example.com/products'';
  private productsSubject = new BehaviorSubject<Product[]>([]);
  public products$ = this.productsSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadProducts();
  }

  getProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.apiUrl)
      .pipe(
        retry(3),
        catchError(this.handleError)
      );
  }

  createProduct(product: Product): Observable<Product> {
    return this.http.post<Product>(this.apiUrl, product)
      .pipe(catchError(this.handleError));
  }

  private handleError(error: any): Observable<never> {
    console.error(''API Error:'', error);
    return throwError(() => new Error(error.message));
  }
}
```

### Component Communication Patterns

**Parent to Child (@Input):**

```typescript
// Parent
@Component({
  template: `<app-product-card [product]="product"></app-product-card>`
})
export class ParentComponent {
  product: Product;
}

// Child
@Component({
  selector: ''app-product-card''
})
export class ChildComponent {
  @Input() product: Product;
}
```

**Child to Parent (@Output):**

```typescript
// Child
@Component({
  selector: ''app-product-card''
})
export class ChildComponent {
  @Output() productAdded = new EventEmitter<Product>();

  addToCart(): void {
    this.productAdded.emit(this.product);
  }
}

// Parent
@Component({
  template: `<app-product-card (productAdded)="onAdded($event)"></app-product-card>`
})
export class ParentComponent {
  onAdded(product: Product): void {
    console.log(''Added:'', product);
  }
}
```

**Sibling Communication (via Service):**

```typescript
@Injectable({ providedIn: ''root'' })
export class CartService {
  private cartItemsSubject = new BehaviorSubject<CartItem[]>([]);
  public cartItems$ = this.cartItemsSubject.asObservable();

  addItem(product: Product, quantity: number = 1): void {
    const items = this.cartItemsSubject.value;
    items.push({ product, quantity });
    this.cartItemsSubject.next(items);
  }
}
```

### Dependency Injection

```typescript
// Root Level (Singleton)
@Injectable({
  providedIn: ''root''
})
export class AuthService { }

// Module Level
@NgModule({
  providers: [ProductService]
})
export class ProductModule { }

// Component Level (New instance per component)
@Component({
  providers: [ProductDetailsService]
})
export class ProductDetailComponent { }
```',
    2,
    'Angular,Architecture,Components,Modules,Services,Dependency Injection',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q354: What are Angular components? What is a component lifecycle?
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    354,
    'What are Angular components? What is a component lifecycle?',
    '**Components** are the building blocks of Angular applications. Each component controls a portion of the screen (view) and has associated logic.

### Component Anatomy

```typescript
@Component({
  selector: ''app-user-profile'',
  templateUrl: ''./user-profile.component.html'',
  styleUrls: [''./user-profile.component.css'']
})
export class UserProfileComponent implements OnInit, OnDestroy, OnChanges, AfterViewInit {

  // Input from parent
  @Input() userId: number;
  @Input() showActions = true;

  // Output to parent
  @Output() userUpdated = new EventEmitter<User>();
  @Output() userDeleted = new EventEmitter<number>();

  // Component state
  user: User | null = null;
  loading = false;

  // ViewChild - access template elements
  @ViewChild(''nameInput'') nameInput!: ElementRef<HTMLInputElement>;

  constructor(
    private userService: UserService,
    private notificationService: NotificationService
  ) {
    console.log(''Constructor called'');
  }

  // Lifecycle hooks
  ngOnChanges(changes: SimpleChanges): void {
    console.log(''ngOnChanges called'', changes);
    if (changes[''userId''] && !changes[''userId''].firstChange) {
      this.loadUser(changes[''userId''].currentValue);
    }
  }

  ngOnInit(): void {
    console.log(''ngOnInit called'');
    this.loadUser(this.userId);
  }

  ngAfterViewInit(): void {
    console.log(''ngAfterViewInit called'');
    if (this.nameInput) {
      this.nameInput.nativeElement.focus();
    }
  }

  ngOnDestroy(): void {
    console.log(''ngOnDestroy called'');
    this.subscriptions.unsubscribe();
  }
}
```

### Component Lifecycle Hooks (Execution Order)

```
1. constructor()          // Component instantiation
   ↓
2. ngOnChanges()         // When @Input() changes (before ngOnInit)
   ↓
3. ngOnInit()            // Initialize component (called ONCE)
   ↓
4. ngDoCheck()           // Custom change detection
   ↓
5. ngAfterContentInit()  // After content projection (ng-content)
   ↓
6. ngAfterContentChecked() // After checking content
   ↓
7. ngAfterViewInit()     // After view is initialized
   ↓
8. ngAfterViewChecked()  // After checking view
   ↓
   [Component is active - responds to events]
   ↓
9. ngOnChanges()         // If @Input() changes again
   ↓
10. ngOnDestroy()        // Before component is destroyed
```

### Best Practices for Each Hook

**ngOnInit - Data Initialization:**

```typescript
ngOnInit(): void {
  // ✅ Load data
  this.loadProducts();

  // ✅ Subscribe to route params
  this.route.params.subscribe(params => {
    this.categoryId = params[''id''];
  });

  // ✅ Setup forms
  this.setupForm();
}
```

**ngOnChanges - React to Input Changes:**

```typescript
ngOnChanges(changes: SimpleChanges): void {
  if (changes[''userId'']) {
    const userId = changes[''userId''].currentValue;
    if (!changes[''userId''].firstChange) {
      this.loadUser(userId);
    }
  }
}
```

**ngAfterViewInit - Access DOM Elements:**

```typescript
ngAfterViewInit(): void {
  // ✅ Focus input
  this.searchInput.nativeElement.focus();

  // ✅ Setup third-party library
  $(this.searchInput.nativeElement).autocomplete();
}
```

**ngOnDestroy - Cleanup:**

```typescript
ngOnDestroy(): void {
  // ✅ Unsubscribe from observables
  this.subscriptions.unsubscribe();

  // ✅ Clear intervals/timeouts
  clearInterval(this.intervalId);

  // ✅ Save state
  this.saveComponentState();
}
```

### Smart vs Presentational Components

**Smart Component (Container):**

```typescript
@Component({
  template: `
    <app-product-list
      [products]="products$ | async"
      [loading]="loading$ | async"
      (productSelected)="onProductSelected($event)">
    </app-product-list>
  `
})
export class ProductListContainerComponent implements OnInit {
  products$ = this.productService.products$;
  loading$ = this.productService.loading$;

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    this.productService.loadProducts();
  }
}
```

**Presentational Component (Dumb):**

```typescript
@Component({
  selector: ''app-product-list'',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div *ngFor="let product of products">
      {{ product.name }}
    </div>
  `
})
export class ProductListComponent {
  @Input() products: Product[] = [];
  @Input() loading = false;
  @Output() productSelected = new EventEmitter<Product>();
}
```',
    2,
    'Angular,Components,Lifecycle Hooks,OnInit,OnDestroy,ViewChild',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q355: Explain the Angular component lifecycle hooks
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    355,
    'Explain the Angular component lifecycle hooks',
    'Angular component lifecycle hooks are methods that allow you to tap into key moments in a component''s life, from creation to destruction.

### Lifecycle Hooks Quick Reference

```typescript
export class ComponentLifecycleExamples {

  // ✅ ngOnInit - Most commonly used
  ngOnInit(): void {
    // Initialize data
    this.loadData();

    // Subscribe to observables
    this.route.params.subscribe(params => {
      this.id = params[''id''];
    });

    // Setup forms
    this.buildForm();
  }

  // ✅ ngOnChanges - React to @Input() changes
  ngOnChanges(changes: SimpleChanges): void {
    if (changes[''customerId''] && !changes[''customerId''].firstChange) {
      this.loadCustomerOrders(changes[''customerId''].currentValue);
    }
  }

  // ✅ ngAfterViewInit - DOM manipulation
  ngAfterViewInit(): void {
    // Focus input
    this.emailInput.nativeElement.focus();

    // Initialize charts
    this.initializeChart();

    // Setup third-party plugins
    $(this.element).datepicker();
  }

  // ✅ ngOnDestroy - Cleanup
  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    clearInterval(this.timer);
  }
}
```

### Common Use Cases

**1. ngOnInit:**
- Load data from API
- Subscribe to observables
- Initialize component state
- Setup reactive forms

**2. ngOnChanges:**
- React to parent component data changes
- Perform actions when @Input properties change
- Compare previous and current values

**3. ngDoCheck:**
- Implement custom change detection
- Detect changes Angular doesn''t catch
- ⚠️ Called very frequently - keep it lightweight

**4. ngAfterViewInit:**
- Access @ViewChild elements
- Initialize third-party libraries
- Perform DOM manipulation
- Setup event listeners

**5. ngOnDestroy:**
- Unsubscribe from observables
- Clear timers and intervals
- Remove event listeners
- Save component state

### Real-World Example

```typescript
@Component({
  selector: ''app-dashboard''
})
export class DashboardComponent implements OnInit, OnDestroy {
  private subscriptions = new Subscription();
  private intervalId: any;

  ngOnInit(): void {
    // Subscribe to multiple observables
    this.subscriptions.add(
      this.dataService.data$.subscribe(data => {
        this.processData(data);
      })
    );

    this.subscriptions.add(
      this.authService.user$.subscribe(user => {
        this.currentUser = user;
      })
    );

    // Setup interval for auto-refresh
    this.intervalId = setInterval(() => {
      this.refreshData();
    }, 30000);
  }

  ngOnDestroy(): void {
    // ✅ Unsubscribe from all observables
    this.subscriptions.unsubscribe();

    // ✅ Clear intervals
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }

    // ✅ Save state
    this.saveComponentState();
  }
}
```

### Execution Order Visualization

```
Component Created
      ↓
[constructor] - Dependency injection
      ↓
[ngOnChanges] - If @Input() exists
      ↓
[ngOnInit] - Component initialization ⭐ Most used
      ↓
[ngDoCheck] - Change detection
      ↓
[ngAfterContentInit] - Content projection initialized
      ↓
[ngAfterContentChecked] - Content checked
      ↓
[ngAfterViewInit] - View initialized ⭐ DOM access
      ↓
[ngAfterViewChecked] - View checked
      ↓
... Component is active ...
      ↓
[ngOnChanges] - When @Input() changes
      ↓
[ngOnDestroy] - Before destruction ⭐ Cleanup
      ↓
Component Destroyed
```',
    2,
    'Angular,Lifecycle Hooks,ngOnInit,ngOnDestroy,ngOnChanges,Component Lifecycle',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q356: What is data binding in Angular? Explain different types
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    356,
    'What is data binding in Angular? Explain different types',
    '**Data binding** synchronizes data between the component class and the template. Angular provides four types of data binding.

### 1. INTERPOLATION {{ }}

```typescript
@Component({
  template: `
    <h1>{{ title }}</h1>
    <p>Price: {{ price | currency }}</p>
    <p>Total: {{ quantity * price }}</p>
    <p>{{ getUserName() }}</p>
  `
})
export class InterpolationExample {
  title = ''My Product'';
  price = 99.99;
  quantity = 3;

  getUserName(): string {
    return this.user.firstName + '' '' + this.user.lastName;
  }
}
```

### 2. PROPERTY BINDING [property]

```typescript
@Component({
  template: `
    <!-- Element properties -->
    <img [src]="imageUrl" [alt]="imageAlt">
    <button [disabled]="isProcessing">Submit</button>
    <div [class.active]="isActive">Active Item</div>
    <div [style.color]="textColor">Colored Text</div>

    <!-- Multiple classes -->
    <div [ngClass]="{
      ''active'': isActive,
      ''disabled'': isDisabled,
      ''highlight'': needsHighlight
    }"></div>

    <!-- Multiple styles -->
    <div [ngStyle]="{
      ''color'': textColor,
      ''font-size.px'': fontSize,
      ''font-weight'': isImportant ? ''bold'' : ''normal''
    }"></div>

    <!-- Component property -->
    <app-child [product]="selectedProduct"></app-child>
  `
})
export class PropertyBindingExample {
  imageUrl = ''assets/logo.png'';
  isProcessing = false;
  isActive = true;
  textColor = ''blue'';
  fontSize = 16;
}
```

### 3. EVENT BINDING (event)

```typescript
@Component({
  template: `
    <!-- Click event -->
    <button (click)="handleClick()">Click Me</button>

    <!-- With $event -->
    <button (click)="handleClick($event)">Click with Event</button>

    <!-- Input events -->
    <input (input)="onInput($event)" (blur)="onBlur()">

    <!-- Form events -->
    <form (submit)="onSubmit($event)">
      <input (keyup.enter)="onEnter()">
      <input (keyup.escape)="onEscape()">
    </form>

    <!-- Mouse events -->
    <div
      (mouseenter)="onMouseEnter()"
      (mouseleave)="onMouseLeave()">
    </div>

    <!-- Custom component events -->
    <app-child (itemSelected)="onItemSelected($event)"></app-child>
  `
})
export class EventBindingExample {
  handleClick($event: MouseEvent): void {
    console.log(''Mouse X:'', $event.clientX);
    $event.stopPropagation();
  }

  onInput($event: Event): void {
    const value = ($event.target as HTMLInputElement).value;
    console.log(''Input value:'', value);
  }

  onSubmit($event: Event): void {
    $event.preventDefault();
    console.log(''Form submitted'');
  }
}
```

### 4. TWO-WAY BINDING [(ngModel)]

```typescript
// Import FormsModule in module
import { FormsModule } from ''@angular/forms'';

@Component({
  template: `
    <!-- Basic two-way binding -->
    <input [(ngModel)]="userName" placeholder="Enter name">
    <p>Hello, {{ userName }}!</p>

    <!-- Checkbox -->
    <input type="checkbox" [(ngModel)]="agreedToTerms">

    <!-- Select -->
    <select [(ngModel)]="selectedCountry">
      <option *ngFor="let country of countries" [value]="country.code">
        {{ country.name }}
      </option>
    </select>

    <!-- Radio buttons -->
    <label *ngFor="let option of options">
      <input
        type="radio"
        [(ngModel)]="selectedOption"
        [value]="option.value">
      {{ option.label }}
    </label>
  `
})
export class TwoWayBindingExample {
  userName = '''';
  agreedToTerms = false;
  selectedCountry = ''US'';
  selectedOption = ''option1'';
}
```

### Real-World Example: Shopping Cart

```typescript
@Component({
  selector: ''app-shopping-cart'',
  template: `
    <div class="shopping-cart">
      <!-- Interpolation -->
      <h2>{{ cartTitle }}</h2>
      <p>Total Items: {{ getTotalItems() }}</p>

      <!-- Property binding -->
      <div [class.empty]="cart.length === 0">

        <div
          *ngFor="let item of cart"
          [class.out-of-stock]="!item.inStock">

          <!-- Event binding -->
          <img [src]="item.imageUrl" (error)="onImageError($event)">

          <h3>{{ item.name }}</h3>
          <p [style.color]="item.inStock ? ''green'' : ''red''">
            {{ item.inStock ? ''In Stock'' : ''Out of Stock'' }}
          </p>

          <!-- Two-way binding -->
          <input
            type="number"
            [(ngModel)]="item.quantity"
            (ngModelChange)="onQuantityChange(item)"
            [min]="1">

          <p>Subtotal: {{ item.quantity * item.price | currency }}</p>

          <button
            (click)="removeItem(item.id)"
            [disabled]="isProcessing">
            Remove
          </button>
        </div>
      </div>

      <div class="cart-summary">
        <h3>Total: {{ getTotal() | currency }}</h3>
        <button
          (click)="checkout()"
          [disabled]="cart.length === 0">
          Checkout
        </button>
      </div>
    </div>
  `
})
export class ShoppingCartComponent {
  cartTitle = ''Shopping Cart'';
  cart: CartItem[] = [];
  isProcessing = false;

  getTotalItems(): number {
    return this.cart.reduce((sum, item) => sum + item.quantity, 0);
  }

  getTotal(): number {
    return this.cart.reduce((sum, item) => sum + (item.quantity * item.price), 0);
  }

  onQuantityChange(item: CartItem): void {
    this.cartService.updateQuantity(item.id, item.quantity).subscribe();
  }

  removeItem(itemId: number): void {
    this.cart = this.cart.filter(item => item.id !== itemId);
  }
}
```',
    2,
    'Angular,Data Binding,Interpolation,Property Binding,Event Binding,Two-Way Binding',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q357: What is one-way binding vs two-way binding?
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    357,
    'What is one-way binding vs two-way binding?',
    'Angular supports both one-way and two-way data binding, each serving different purposes.

### ONE-WAY BINDING (Component → View)

```typescript
@Component({
  template: `
    <!-- Property binding (one-way) -->
    <input [value]="userName">
    <!-- User typing won''t update userName -->

    <p>{{ message }}</p>
    <!-- message changes update view, not vice versa -->
  `
})
export class OneWayBindingExample {
  userName = ''John'';
  message = ''Hello'';

  // Component controls the data flow
  updateMessage(): void {
    this.message = ''Updated!'';  // Updates view
  }
}
```

### TWO-WAY BINDING (Component ↔ View)

```typescript
@Component({
  template: `
    <!-- Two-way binding -->
    <input [(ngModel)]="userName">
    <!-- User typing updates userName AND userName changes update view -->

    <p>Hello, {{ userName }}!</p>
  `
})
export class TwoWayBindingExample {
  userName = ''John'';
  // Both component and view can update the value
}
```

### How Two-Way Binding Works (Under the Hood)

```typescript
@Component({
  template: `
    <!-- This: -->
    <input [(ngModel)]="userName">

    <!-- Is syntactic sugar for: -->
    <input
      [ngModel]="userName"
      (ngModelChange)="userName = $event">

    <!-- Manual two-way binding -->
    <input
      [value]="searchTerm"
      (input)="searchTerm = $event.target.value">
  `
})
export class ManualTwoWayBinding {
  userName = '''';
  searchTerm = '''';
}
```

### Custom Two-Way Binding Component

```typescript
// Usage: <app-rating [(rating)]="productRating"></app-rating>

@Component({
  selector: ''app-rating'',
  template: `
    <div class="rating">
      <span
        *ngFor="let star of stars; let i = index"
        (click)="selectRating(i + 1)"
        [class.filled]="i < rating">
        ★
      </span>
    </div>
  `
})
export class RatingComponent {
  @Input() rating = 0;
  @Output() ratingChange = new EventEmitter<number>();

  stars = [1, 2, 3, 4, 5];

  selectRating(value: number): void {
    this.rating = value;
    this.ratingChange.emit(this.rating);  // Emit change
  }
}

// Parent component
@Component({
  template: `
    <app-rating [(rating)]="productRating"></app-rating>
    <p>Current rating: {{ productRating }}</p>
  `
})
export class ParentComponent {
  productRating = 3;
  // productRating updates when user clicks stars
  // Rating component updates when productRating changes
}
```

### Comparison

| Feature | One-Way Binding | Two-Way Binding |
|---------|----------------|-----------------|
| **Syntax** | `[property]` or `{{}}` | `[(ngModel)]` |
| **Direction** | Component → View only | Component ↔ View |
| **Performance** | Faster | Slightly slower |
| **Use Case** | Display data | Form inputs |
| **Updates** | Component updates view | Both can update |
| **Example** | `<p>{{ name }}</p>` | `<input [(ngModel)]="name">` |

### When to Use Each

**Use One-Way Binding:**
- Displaying data
- Passing data to child components
- Better performance (no change detection needed for view → component)

**Use Two-Way Binding:**
- Form inputs (text, select, checkbox)
- User editable data
- When you need immediate synchronization

### Best Practice: Custom Counter

```typescript
@Component({
  selector: ''app-counter'',
  template: `
    <button (click)="decrement()">-</button>
    <span>{{ count }}</span>
    <button (click)="increment()">+</button>
  `
})
export class CounterComponent {
  @Input() count = 0;
  @Output() countChange = new EventEmitter<number>();

  increment(): void {
    this.count++;
    this.countChange.emit(this.count);
  }

  decrement(): void {
    this.count--;
    this.countChange.emit(this.count);
  }
}

// Usage with two-way binding
@Component({
  template: `<app-counter [(count)]="currentCount"></app-counter>`
})
export class AppComponent {
  currentCount = 0;
}
```',
    1,
    'Angular,Data Binding,One-Way Binding,Two-Way Binding,ngModel',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q358: What is the [(ngModel)] directive?
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    358,
    'What is the [(ngModel)] directive?',
    '**ngModel** creates two-way data binding for form controls, allowing synchronization between component properties and form inputs.

### Setup (Import FormsModule)

```typescript
import { FormsModule } from ''@angular/forms'';

@NgModule({
  imports: [FormsModule]
})
export class AppModule { }
```

### Basic Usage

```typescript
@Component({
  template: `
    <!-- Text input -->
    <input [(ngModel)]="userName" placeholder="Enter name">
    <p>Hello, {{ userName }}!</p>

    <!-- Number input -->
    <input type="number" [(ngModel)]="age">
    <p>Age: {{ age }}</p>

    <!-- Textarea -->
    <textarea [(ngModel)]="comments"></textarea>

    <!-- Checkbox -->
    <label>
      <input type="checkbox" [(ngModel)]="agreed">
      I agree to terms
    </label>

    <!-- Select -->
    <select [(ngModel)]="selectedColor">
      <option value="red">Red</option>
      <option value="blue">Blue</option>
      <option value="green">Green</option>
    </select>

    <!-- Radio buttons -->
    <label>
      <input type="radio" [(ngModel)]="gender" value="male">
      Male
    </label>
    <label>
      <input type="radio" [(ngModel)]="gender" value="female">
      Female
    </label>
  `
})
export class NgModelExample {
  userName = '''';
  age = 25;
  comments = '''';
  agreed = false;
  selectedColor = ''blue'';
  gender = ''male'';
}
```

### With Events

```typescript
@Component({
  template: `
    <input
      [(ngModel)]="searchTerm"
      (ngModelChange)="onSearchChange($event)"
      placeholder="Search...">

    <p *ngIf="searchResults.length > 0">
      Found {{ searchResults.length }} results
    </p>
  `
})
export class SearchExample {
  searchTerm = '''';
  searchResults: any[] = [];

  onSearchChange(value: string): void {
    console.log(''Search term:'', value);

    if (value.length >= 3) {
      this.searchService.search(value).subscribe(results => {
        this.searchResults = results;
      });
    } else {
      this.searchResults = [];
    }
  }
}
```

### With Debounce (Avoid Excessive API Calls)

```typescript
@Component({
  template: `
    <input
      [(ngModel)]="searchTerm"
      (ngModelChange)="searchSubject.next($event)"
      placeholder="Search...">
  `
})
export class DebouncedSearchExample implements OnInit, OnDestroy {
  searchTerm = '''';
  searchSubject = new Subject<string>();
  private subscription: Subscription;

  ngOnInit(): void {
    this.subscription = this.searchSubject
      .pipe(
        debounceTime(300),  // Wait 300ms after typing stops
        distinctUntilChanged(),  // Only if value changed
        switchMap(term => this.searchService.search(term))
      )
      .subscribe(results => {
        console.log(''Search results:'', results);
      });
  }

  ngOnDestroy(): void {
    this.subscription.unsubscribe();
  }
}
```

### Object Binding

```typescript
@Component({
  template: `
    <h3>User Profile</h3>

    <input [(ngModel)]="user.firstName" placeholder="First Name">
    <input [(ngModel)]="user.lastName" placeholder="Last Name">
    <input [(ngModel)]="user.email" placeholder="Email">

    <select [(ngModel)]="user.country">
      <option *ngFor="let country of countries" [value]="country.code">
        {{ country.name }}
      </option>
    </select>

    <label>
      <input type="checkbox" [(ngModel)]="user.subscribeNewsletter">
      Subscribe to newsletter
    </label>

    <pre>{{ user | json }}</pre>
  `
})
export class UserFormExample {
  user = {
    firstName: '''',
    lastName: '''',
    email: '''',
    country: ''US'',
    subscribeNewsletter: false
  };

  countries = [
    { code: ''US'', name: ''United States'' },
    { code: ''UK'', name: ''United Kingdom'' },
    { code: ''IN'', name: ''India'' }
  ];
}
```

### Common Use Cases

**1. Login Form:**

```typescript
@Component({
  template: `
    <form (submit)="login()">
      <input [(ngModel)]="credentials.username" name="username">
      <input [(ngModel)]="credentials.password" type="password" name="password">
      <button type="submit">Login</button>
    </form>
  `
})
export class LoginComponent {
  credentials = {
    username: '''',
    password: ''''
  };

  login(): void {
    this.authService.login(this.credentials).subscribe();
  }
}
```

**2. Filter/Search:**

```typescript
@Component({
  template: `
    <input [(ngModel)]="filter" placeholder="Filter products...">
    <div *ngFor="let product of filteredProducts">
      {{ product.name }}
    </div>
  `
})
export class ProductListComponent {
  filter = '''';
  products: Product[] = [];

  get filteredProducts(): Product[] {
    return this.products.filter(p =>
      p.name.toLowerCase().includes(this.filter.toLowerCase())
    );
  }
}
```',
    1,
    'Angular,ngModel,Two-Way Binding,Forms,FormsModule',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ----------------------------------------------------------------------------
-- Q359: What are Angular directives? Structural vs Attribute directives
-- ----------------------------------------------------------------------------

INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES (
    359,
    'What are Angular directives? Structural vs Attribute directives',
    '**Directives** are classes that add behavior to elements in Angular applications. There are three types: **Structural**, **Attribute**, and **Component** directives.

### 1. STRUCTURAL DIRECTIVES (Change DOM Structure)

Structural directives change the DOM layout by adding or removing elements.

```typescript
@Component({
  template: `
    <!-- *ngIf - Conditionally add/remove element -->
    <div *ngIf="isLoggedIn">
      Welcome, {{ userName }}!
    </div>

    <div *ngIf="isLoggedIn; else loginTemplate">
      Dashboard content
    </div>
    <ng-template #loginTemplate>
      <p>Please log in</p>
    </ng-template>

    <!-- *ngFor - Repeat element -->
    <ul>
      <li *ngFor="let item of items">{{ item }}</li>
    </ul>

    <!-- *ngFor with index and trackBy -->
    <div *ngFor="let product of products; let i = index; trackBy: trackByProductId">
      {{ i + 1 }}. {{ product.name }}
    </div>

    <!-- *ngFor with first, last, even, odd -->
    <div
      *ngFor="let item of items; let first = first; let last = last"
      [class.first]="first"
      [class.last]="last">
      {{ item }}
    </div>

    <!-- *ngSwitch - Multiple conditions -->
    <div [ngSwitch]="userRole">
      <admin-panel *ngSwitchCase="''admin''"></admin-panel>
      <user-panel *ngSwitchCase="''user''"></user-panel>
      <guest-panel *ngSwitchDefault></guest-panel>
    </div>
  `
})
export class StructuralDirectivesExample {
  isLoggedIn = true;
  userName = ''John'';
  items = [''Item 1'', ''Item 2'', ''Item 3''];
  products: Product[] = [];
  userRole = ''admin'';

  trackByProductId(index: number, product: Product): number {
    return product.id;
  }
}
```

### 2. ATTRIBUTE DIRECTIVES (Change Appearance/Behavior)

Attribute directives change the appearance or behavior of an element.

```typescript
@Component({
  template: `
    <!-- ngClass - Add/remove CSS classes -->
    <div [ngClass]="{
      ''active'': isActive,
      ''disabled'': isDisabled,
      ''highlight'': needsHighlight
    }">
      Conditional classes
    </div>

    <!-- ngStyle - Add inline styles -->
    <div [ngStyle]="{
      ''background-color'': bgColor,
      ''font-size.px'': fontSize,
      ''font-weight'': isImportant ? ''bold'' : ''normal''
    }">
      Dynamic styles
    </div>
  `
})
export class AttributeDirectivesExample {
  isActive = true;
  isDisabled = false;
  needsHighlight = true;
  bgColor = ''#f0f0f0'';
  fontSize = 16;
  isImportant = true;
}
```

### 3. CUSTOM ATTRIBUTE DIRECTIVE

```typescript
// highlight.directive.ts
import { Directive, ElementRef, HostListener, Input } from ''@angular/core'';

@Directive({
  selector: ''[appHighlight]''
})
export class HighlightDirective {
  @Input() appHighlight = ''yellow'';
  @Input() defaultColor = ''transparent'';

  constructor(private el: ElementRef) {}

  @HostListener(''mouseenter'') onMouseEnter() {
    this.highlight(this.appHighlight);
  }

  @HostListener(''mouseleave'') onMouseLeave() {
    this.highlight(this.defaultColor);
  }

  private highlight(color: string) {
    this.el.nativeElement.style.backgroundColor = color;
  }
}

// Usage
@Component({
  template: `
    <p appHighlight>Hover me (default yellow)</p>
    <p [appHighlight]="''lightblue''" [defaultColor]="''white''">
      Hover me (custom colors)
    </p>
  `
})
export class HighlightExample {}
```

### 4. CUSTOM STRUCTURAL DIRECTIVE

```typescript
// unless.directive.ts
import { Directive, Input, TemplateRef, ViewContainerRef } from ''@angular/core'';

@Directive({
  selector: ''[appUnless]''
})
export class UnlessDirective {
  private hasView = false;

  @Input() set appUnless(condition: boolean) {
    if (!condition && !this.hasView) {
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (condition && this.hasView) {
      this.viewContainer.clear();
      this.hasView = false;
    }
  }

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef
  ) {}
}

// Usage (opposite of *ngIf)
@Component({
  template: `
    <p *appUnless="isLoggedIn">Please log in</p>
  `
})
export class UnlessExample {
  isLoggedIn = false;
}
```

### 5. Advanced Custom Directive: Tooltip

```typescript
@Directive({
  selector: ''[appTooltip]''
})
export class TooltipDirective implements OnDestroy {
  @Input() appTooltip = '''';
  @Input() tooltipPosition: ''top'' | ''bottom'' = ''top'';

  private tooltipElement: HTMLElement | null = null;

  constructor(private el: ElementRef, private renderer: Renderer2) {}

  @HostListener(''mouseenter'')
  onMouseEnter(): void {
    this.showTooltip();
  }

  @HostListener(''mouseleave'')
  onMouseLeave(): void {
    this.hideTooltip();
  }

  private showTooltip(): void {
    this.tooltipElement = this.renderer.createElement(''span'');
    this.renderer.appendChild(
      this.tooltipElement,
      this.renderer.createText(this.appTooltip)
    );
    this.renderer.addClass(this.tooltipElement, ''tooltip'');
    this.renderer.appendChild(document.body, this.tooltipElement);
  }

  private hideTooltip(): void {
    if (this.tooltipElement) {
      this.renderer.removeChild(document.body, this.tooltipElement);
      this.tooltipElement = null;
    }
  }

  ngOnDestroy(): void {
    this.hideTooltip();
  }
}

// Usage
@Component({
  template: `
    <button appTooltip="Click to save" tooltipPosition="bottom">
      Save
    </button>
  `
})
export class TooltipExample {}
```

### Comparison: Structural vs Attribute

| Feature | Structural Directives | Attribute Directives |
|---------|---------------------|---------------------|
| **Purpose** | Change DOM structure | Change element behavior/appearance |
| **Syntax** | `*ngIf`, `*ngFor` | `[ngClass]`, `[ngStyle]` |
| **DOM** | Add/remove elements | Modify existing elements |
| **Examples** | `*ngIf`, `*ngFor`, `*ngSwitch` | `ngClass`, `ngStyle`, `ngModel` |
| **Custom** | `*appUnless` | `appHighlight`, `appTooltip` |

### Best Practices

**1. Use trackBy with *ngFor:**

```typescript
<div *ngFor="let item of items; trackBy: trackById">
  {{ item.name }}
</div>

trackById(index: number, item: any): number {
  return item.id;
}
```

**2. Prefer Structural Directives over ngShow/ngHide:**

```typescript
<!-- ✅ Good - Removes from DOM -->
<div *ngIf="isVisible">Content</div>

<!-- ❌ Bad - Still in DOM, just hidden -->
<div [hidden]="!isVisible">Content</div>
```

**3. Use HostListener for event handling:**

```typescript
@Directive({ selector: ''[appClickTracker]'' })
export class ClickTrackerDirective {
  @HostListener(''click'', [''$event''])
  onClick(event: MouseEvent): void {
    console.log(''Element clicked'', event);
  }
}
```',
    2,
    'Angular,Directives,Structural Directives,Attribute Directives,ngIf,ngFor,Custom Directives',
    (SELECT Id FROM Categories WHERE QuestionRangeStart = 352),
    1
);

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

SELECT
    q.QuestionNumber,
    q.Title,
    q.Difficulty,
    c.Name AS Category,
    q.Tags
FROM Questions q
INNER JOIN Categories c ON q.CategoryId = c.Id
WHERE q.QuestionNumber BETWEEN 352 AND 359
ORDER BY q.QuestionNumber;

-- ============================================================================
-- END OF IMPORT SCRIPT
-- ============================================================================
