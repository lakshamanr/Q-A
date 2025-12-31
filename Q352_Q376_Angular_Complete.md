# COMPREHENSIVE ANGULAR INTERVIEW QUESTIONS (Q352-Q376)

## SECTION 12: ANGULAR & FRONTEND DEVELOPMENT

---

## Q352: What is Angular? How is it different from AngularJS?

**Answer:**

**Angular** (Angular 2+) is a complete rewrite of AngularJS, built with TypeScript for modern web applications. It's a platform and framework for building client-side applications using HTML, CSS, and TypeScript.

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

### Angular Architecture

```typescript
// ============================================
// MODERN ANGULAR APPLICATION STRUCTURE
// ============================================

/*
my-angular-app/
├── src/
│   ├── app/
│   │   ├── components/          # Smart/Presentational components
│   │   ├── services/            # Business logic & API calls
│   │   ├── models/              # TypeScript interfaces/classes
│   │   ├── guards/              # Route guards
│   │   ├── interceptors/        # HTTP interceptors
│   │   ├── pipes/               # Custom pipes
│   │   ├── directives/          # Custom directives
│   │   ├── app.component.ts     # Root component
│   │   ├── app.module.ts        # Root module
│   │   └── app-routing.module.ts # Routing config
│   ├── assets/                  # Static files
│   ├── environments/            # Environment configs
│   └── styles.css              # Global styles
├── angular.json                 # Angular CLI config
├── package.json
└── tsconfig.json
*/
```

### AngularJS (1.x) Example

```javascript
// ============================================
// ANGULARJS (OLD APPROACH)
// ============================================

// Controller
angular.module('myApp', [])
  .controller('CustomerController', function($scope, $http) {
    $scope.customers = [];

    $scope.loadCustomers = function() {
      $http.get('/api/customers')
        .then(function(response) {
          $scope.customers = response.data;
        });
    };

    $scope.deleteCustomer = function(id) {
      $http.delete('/api/customers/' + id)
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
// ============================================
// MODERN ANGULAR (COMPONENT-BASED)
// ============================================

// customer.model.ts
export interface Customer {
  id: number;
  name: string;
  email: string;
  createdDate: Date;
}

// customer.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private apiUrl = '/api/customers';

  constructor(private http: HttpClient) {}

  getCustomers(): Observable<Customer[]> {
    return this.http.get<Customer[]>(this.apiUrl);
  }

  deleteCustomer(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  createCustomer(customer: Customer): Observable<Customer> {
    return this.http.post<Customer>(this.apiUrl, customer);
  }
}

// customer-list.component.ts
import { Component, OnInit } from '@angular/core';
import { CustomerService } from '../services/customer.service';
import { Customer } from '../models/customer.model';

@Component({
  selector: 'app-customer-list',
  templateUrl: './customer-list.component.html',
  styleUrls: ['./customer-list.component.css']
})
export class CustomerListComponent implements OnInit {
  customers: Customer[] = [];
  loading = false;
  error: string | null = null;

  constructor(private customerService: CustomerService) {}

  ngOnInit(): void {
    this.loadCustomers();
  }

  loadCustomers(): void {
    this.loading = true;
    this.customerService.getCustomers()
      .subscribe({
        next: (data) => {
          this.customers = data;
          this.loading = false;
        },
        error: (err) => {
          this.error = 'Failed to load customers';
          this.loading = false;
        }
      });
  }

  deleteCustomer(id: number): void {
    if (confirm('Are you sure?')) {
      this.customerService.deleteCustomer(id)
        .subscribe({
          next: () => this.loadCustomers(),
          error: (err) => console.error('Delete failed', err)
        });
    }
  }
}
```

```html
<!-- customer-list.component.html -->
<div class="customer-list">
  <h2>Customers</h2>

  <div *ngIf="loading" class="spinner">Loading...</div>

  <div *ngIf="error" class="alert alert-danger">
    {{ error }}
  </div>

  <ul *ngIf="!loading && customers.length > 0">
    <li *ngFor="let customer of customers">
      {{ customer.name }} - {{ customer.email }}
      <button (click)="deleteCustomer(customer.id)" class="btn btn-danger">
        Delete
      </button>
    </li>
  </ul>

  <div *ngIf="!loading && customers.length === 0">
    No customers found.
  </div>
</div>
```

```css
/* customer-list.component.css */
.customer-list {
  padding: 20px;
}

.spinner {
  text-align: center;
  padding: 20px;
}

ul {
  list-style: none;
  padding: 0;
}

li {
  padding: 10px;
  margin: 5px 0;
  border: 1px solid #ddd;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
```

### Why Angular (2+) is Better

#### 1. **TypeScript Benefits**

```typescript
// Strong typing prevents errors
interface Product {
  id: number;
  name: string;
  price: number;
}

// Compile-time error if wrong type
function calculateTotal(products: Product[]): number {
  return products.reduce((sum, p) => sum + p.price, 0);
}

// This would cause compile error:
// calculateTotal("not an array");  // Error!
```

#### 2. **Better Performance**

```typescript
// Angular uses Zone.js for change detection
// More efficient than AngularJS's digest cycle

// OnPush change detection for better performance
@Component({
  selector: 'app-product',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<div>{{ product.name }}</div>`
})
export class ProductComponent {
  @Input() product: Product;
}
```

#### 3. **Modularity**

```typescript
// Feature modules for better organization
@NgModule({
  declarations: [
    CustomerListComponent,
    CustomerDetailComponent,
    CustomerFormComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    CustomerRoutingModule
  ],
  providers: [CustomerService]
})
export class CustomerModule { }
```

#### 4. **Mobile Support**

```typescript
// Angular works great with Ionic for mobile apps
import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  template: `
    <ion-header>
      <ion-toolbar>
        <ion-title>My App</ion-title>
      </ion-toolbar>
    </ion-header>

    <ion-content>
      <ion-list>
        <ion-item *ngFor="let item of items">
          {{ item.name }}
        </ion-item>
      </ion-list>
    </ion-content>
  `
})
export class HomePage {
  items = [];
}
```

---

## Q353: Explain Angular architecture (components, modules, services).

**Answer:**

Angular follows a **component-based architecture** with clear separation of concerns.

### Core Building Blocks

```typescript
// ============================================
// 1. COMPONENTS (UI Logic)
// ============================================

import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-product-card',        // How to use in HTML
  templateUrl: './product-card.component.html',
  styleUrls: ['./product-card.component.css']
})
export class ProductCardComponent implements OnInit {
  // Input from parent
  @Input() product: Product;

  // Output to parent
  @Output() addToCart = new EventEmitter<Product>();

  // Component state
  quantity = 1;

  constructor(
    private productService: ProductService,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    // Initialization logic
    console.log('Component initialized');
  }

  onAddToCart(): void {
    this.cartService.addItem(this.product, this.quantity);
    this.addToCart.emit(this.product);
  }

  incrementQuantity(): void {
    this.quantity++;
  }
}
```

```html
<!-- product-card.component.html -->
<div class="product-card">
  <img [src]="product.imageUrl" [alt]="product.name">
  <h3>{{ product.name }}</h3>
  <p>{{ product.description }}</p>
  <div class="price">{{ product.price | currency }}</div>

  <div class="quantity-controls">
    <button (click)="quantity = quantity - 1" [disabled]="quantity <= 1">-</button>
    <span>{{ quantity }}</span>
    <button (click)="incrementQuantity()">+</button>
  </div>

  <button (click)="onAddToCart()" class="btn-add-cart">
    Add to Cart
  </button>
</div>
```

```typescript
// ============================================
// 2. MODULES (Feature Organization)
// ============================================

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

// Components
import { ProductListComponent } from './components/product-list/product-list.component';
import { ProductDetailComponent } from './components/product-detail/product-detail.component';
import { ProductCardComponent } from './components/product-card/product-card.component';

// Services
import { ProductService } from './services/product.service';
import { CartService } from './services/cart.service';

// Routing
import { ProductRoutingModule } from './product-routing.module';

@NgModule({
  declarations: [
    // Components, Directives, Pipes
    ProductListComponent,
    ProductDetailComponent,
    ProductCardComponent
  ],
  imports: [
    // Other modules
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    ProductRoutingModule
  ],
  providers: [
    // Services (though providedIn: 'root' is preferred)
    ProductService,
    CartService
  ],
  exports: [
    // What to export for other modules
    ProductCardComponent
  ]
})
export class ProductModule { }
```

```typescript
// ============================================
// 3. SERVICES (Business Logic & Data)
// ============================================

import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, BehaviorSubject, throwError } from 'rxjs';
import { map, catchError, retry } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'  // Singleton across entire app
})
export class ProductService {
  private apiUrl = 'https://api.example.com/products';

  // State management with BehaviorSubject
  private productsSubject = new BehaviorSubject<Product[]>([]);
  public products$ = this.productsSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadProducts();
  }

  // Get all products
  getProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.apiUrl)
      .pipe(
        retry(3),  // Retry failed requests
        map(products => products.map(p => this.mapProduct(p))),
        catchError(this.handleError)
      );
  }

  // Get single product
  getProduct(id: number): Observable<Product> {
    return this.http.get<Product>(`${this.apiUrl}/${id}`)
      .pipe(
        map(p => this.mapProduct(p)),
        catchError(this.handleError)
      );
  }

  // Search products
  searchProducts(query: string, filters?: any): Observable<Product[]> {
    let params = new HttpParams().set('q', query);

    if (filters) {
      Object.keys(filters).forEach(key => {
        params = params.set(key, filters[key]);
      });
    }

    return this.http.get<Product[]>(`${this.apiUrl}/search`, { params })
      .pipe(catchError(this.handleError));
  }

  // Create product
  createProduct(product: Product): Observable<Product> {
    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });

    return this.http.post<Product>(this.apiUrl, product, { headers })
      .pipe(
        map(p => this.mapProduct(p)),
        catchError(this.handleError)
      );
  }

  // Update product
  updateProduct(id: number, product: Partial<Product>): Observable<Product> {
    return this.http.patch<Product>(`${this.apiUrl}/${id}`, product)
      .pipe(
        map(p => this.mapProduct(p)),
        catchError(this.handleError)
      );
  }

  // Delete product
  deleteProduct(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`)
      .pipe(catchError(this.handleError));
  }

  // Private helper methods
  private loadProducts(): void {
    this.getProducts().subscribe({
      next: (products) => this.productsSubject.next(products),
      error: (err) => console.error('Failed to load products', err)
    });
  }

  private mapProduct(product: any): Product {
    return {
      ...product,
      createdDate: new Date(product.createdDate),
      price: parseFloat(product.price)
    };
  }

  private handleError(error: any): Observable<never> {
    console.error('API Error:', error);
    return throwError(() => new Error(error.message || 'Server error'));
  }
}
```

### Complete Architecture Example

```typescript
// ============================================
// E-COMMERCE APPLICATION ARCHITECTURE
// ============================================

/*
┌─────────────────────────────────────────────────────────┐
│                    APP COMPONENT                         │
│                   (Root Component)                       │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼─────────┐      ┌───────▼─────────┐
│  HEADER MODULE  │      │   MAIN ROUTER   │
│  - Navigation   │      │   OUTLET        │
│  - User Menu    │      └────────┬────────┘
└─────────────────┘               │
                         ┌────────┴────────┐
                         │                 │
                ┌────────▼────────┐ ┌─────▼──────────┐
                │ PRODUCT MODULE  │ │  CART MODULE   │
                │  - List         │ │  - Summary     │
                │  - Detail       │ │  - Checkout    │
                │  - Card         │ └────────────────┘
                └─────────────────┘
                         │
                ┌────────┴────────┐
                │                 │
        ┌───────▼────────┐ ┌─────▼──────────┐
        │ ProductService │ │  CartService   │
        │  - API Calls   │ │  - State Mgmt  │
        └────────────────┘ └────────────────┘
                │                 │
                └────────┬────────┘
                         │
                ┌────────▼────────┐
                │  HTTP CLIENT    │
                │  - Interceptors │
                │  - Auth Token   │
                └─────────────────┘
*/

// ============================================
// APP MODULE (Root Module)
// ============================================

import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

// Core modules
import { CoreModule } from './core/core.module';
import { SharedModule } from './shared/shared.module';

// Feature modules
import { ProductModule } from './features/product/product.module';
import { CartModule } from './features/cart/cart.module';
import { AuthModule } from './features/auth/auth.module';

// Root component & routing
import { AppComponent } from './app.component';
import { AppRoutingModule } from './app-routing.module';

// Interceptors
import { AuthInterceptor } from './core/interceptors/auth.interceptor';
import { ErrorInterceptor } from './core/interceptors/error.interceptor';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    // Angular modules
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,

    // App modules
    CoreModule,
    SharedModule,

    // Feature modules
    ProductModule,
    CartModule,
    AuthModule,

    // Routing (must be last)
    AppRoutingModule
  ],
  providers: [
    // HTTP Interceptors
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: ErrorInterceptor,
      multi: true
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

### Component Communication Patterns

```typescript
// ============================================
// 1. PARENT TO CHILD (@Input)
// ============================================

// Parent Component
@Component({
  selector: 'app-product-list',
  template: `
    <app-product-card
      *ngFor="let product of products"
      [product]="product"
      [showActions]="true">
    </app-product-card>
  `
})
export class ProductListComponent {
  products: Product[] = [];
}

// Child Component
@Component({
  selector: 'app-product-card',
  template: `
    <div>{{ product.name }}</div>
    <div *ngIf="showActions">
      <button>Add to Cart</button>
    </div>
  `
})
export class ProductCardComponent {
  @Input() product: Product;
  @Input() showActions = false;
}

// ============================================
// 2. CHILD TO PARENT (@Output)
// ============================================

// Child Component
@Component({
  selector: 'app-product-card',
  template: `
    <button (click)="addToCart()">Add to Cart</button>
  `
})
export class ProductCardComponent {
  @Input() product: Product;
  @Output() productAdded = new EventEmitter<Product>();

  addToCart(): void {
    this.productAdded.emit(this.product);
  }
}

// Parent Component
@Component({
  selector: 'app-product-list',
  template: `
    <app-product-card
      [product]="product"
      (productAdded)="onProductAdded($event)">
    </app-product-card>
  `
})
export class ProductListComponent {
  onProductAdded(product: Product): void {
    console.log('Product added:', product);
    this.cartService.addItem(product);
  }
}

// ============================================
// 3. SIBLING COMMUNICATION (via Service)
// ============================================

// Shared Service
@Injectable({ providedIn: 'root' })
export class CartService {
  private cartItemsSubject = new BehaviorSubject<CartItem[]>([]);
  public cartItems$ = this.cartItemsSubject.asObservable();

  addItem(product: Product, quantity: number = 1): void {
    const items = this.cartItemsSubject.value;
    items.push({ product, quantity });
    this.cartItemsSubject.next(items);
  }

  getItemCount(): number {
    return this.cartItemsSubject.value.length;
  }
}

// Component A (adds to cart)
@Component({
  selector: 'app-product-detail',
  template: `<button (click)="addToCart()">Add to Cart</button>`
})
export class ProductDetailComponent {
  constructor(private cartService: CartService) {}

  addToCart(): void {
    this.cartService.addItem(this.product);
  }
}

// Component B (shows cart count)
@Component({
  selector: 'app-cart-icon',
  template: `
    <div class="cart-icon">
      <i class="fa fa-shopping-cart"></i>
      <span class="badge">{{ itemCount$ | async }}</span>
    </div>
  `
})
export class CartIconComponent {
  itemCount$ = this.cartService.cartItems$.pipe(
    map(items => items.length)
  );

  constructor(private cartService: CartService) {}
}
```

### Dependency Injection

```typescript
// ============================================
// DEPENDENCY INJECTION HIERARCHY
// ============================================

// Root Level (Singleton - shared across app)
@Injectable({
  providedIn: 'root'
})
export class AuthService {
  // Single instance for entire app
}

// Module Level (Singleton within module)
@NgModule({
  providers: [ProductService]
})
export class ProductModule { }

// Component Level (New instance per component)
@Component({
  selector: 'app-product-detail',
  providers: [ProductDetailsService]  // New instance for each component
})
export class ProductDetailComponent { }

// ============================================
// INJECTION TOKENS
// ============================================

// Create injection token for configuration
export const API_CONFIG = new InjectionToken<ApiConfig>('api.config');

// Provide value
@NgModule({
  providers: [
    {
      provide: API_CONFIG,
      useValue: {
        baseUrl: 'https://api.example.com',
        timeout: 5000
      }
    }
  ]
})
export class AppModule { }

// Inject in service
@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(@Inject(API_CONFIG) private config: ApiConfig) {
    console.log('API Base URL:', this.config.baseUrl);
  }
}
```

---

## Q354: What are Angular components? What is a component lifecycle?

**Answer:**

**Components** are the building blocks of Angular applications. Each component controls a portion of the screen (view) and has associated logic.

### Component Anatomy

```typescript
// ============================================
// COMPLETE COMPONENT EXAMPLE
// ============================================

import {
  Component,
  OnInit,
  OnDestroy,
  OnChanges,
  SimpleChanges,
  Input,
  Output,
  EventEmitter,
  ViewChild,
  ElementRef,
  AfterViewInit
} from '@angular/core';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-user-profile',           // Component tag
  templateUrl: './user-profile.component.html',
  styleUrls: ['./user-profile.component.css'],
  // OR inline:
  // template: `<div>{{ user.name }}</div>`,
  // styles: [`div { color: blue; }`]
})
export class UserProfileComponent implements OnInit, OnDestroy, OnChanges, AfterViewInit {

  // ============================================
  // PROPERTIES
  // ============================================

  // Input from parent
  @Input() userId: number;
  @Input() showActions = true;

  // Output to parent
  @Output() userUpdated = new EventEmitter<User>();
  @Output() userDeleted = new EventEmitter<number>();

  // Component state
  user: User | null = null;
  loading = false;
  error: string | null = null;

  // ViewChild - access template elements
  @ViewChild('nameInput') nameInput!: ElementRef<HTMLInputElement>;

  // Subscriptions
  private subscriptions = new Subscription();

  // ============================================
  // CONSTRUCTOR (Dependency Injection)
  // ============================================

  constructor(
    private userService: UserService,
    private notificationService: NotificationService,
    private router: Router
  ) {
    console.log('Constructor called');
    // Don't do heavy work here!
  }

  // ============================================
  // LIFECYCLE HOOKS
  // ============================================

  // 1. ngOnChanges - called when @Input() properties change
  ngOnChanges(changes: SimpleChanges): void {
    console.log('ngOnChanges called', changes);

    if (changes['userId'] && !changes['userId'].firstChange) {
      const previousId = changes['userId'].previousValue;
      const currentId = changes['userId'].currentValue;
      console.log(`User ID changed from ${previousId} to ${currentId}`);
      this.loadUser(currentId);
    }
  }

  // 2. ngOnInit - called once after first ngOnChanges
  ngOnInit(): void {
    console.log('ngOnInit called');

    // Initialize component
    this.loadUser(this.userId);

    // Subscribe to data streams
    const userUpdates$ = this.userService.userUpdates$
      .subscribe(user => {
        if (user.id === this.userId) {
          this.user = user;
        }
      });

    this.subscriptions.add(userUpdates$);
  }

  // 3. ngAfterViewInit - called after view is initialized
  ngAfterViewInit(): void {
    console.log('ngAfterViewInit called');

    // Access ViewChild elements
    if (this.nameInput) {
      this.nameInput.nativeElement.focus();
    }
  }

  // 4. ngOnDestroy - called before component is destroyed
  ngOnDestroy(): void {
    console.log('ngOnDestroy called');

    // Cleanup: unsubscribe from observables
    this.subscriptions.unsubscribe();

    // Save draft if needed
    this.saveDraft();
  }

  // ============================================
  // COMPONENT METHODS
  // ============================================

  loadUser(id: number): void {
    this.loading = true;
    this.error = null;

    this.userService.getUser(id)
      .subscribe({
        next: (user) => {
          this.user = user;
          this.loading = false;
        },
        error: (err) => {
          this.error = 'Failed to load user';
          this.loading = false;
        }
      });
  }

  updateUser(): void {
    if (!this.user) return;

    this.userService.updateUser(this.user)
      .subscribe({
        next: (updated) => {
          this.user = updated;
          this.userUpdated.emit(updated);
          this.notificationService.success('User updated successfully');
        },
        error: (err) => {
          this.notificationService.error('Failed to update user');
        }
      });
  }

  deleteUser(): void {
    if (!this.user) return;

    if (confirm('Are you sure you want to delete this user?')) {
      this.userService.deleteUser(this.user.id)
        .subscribe({
          next: () => {
            this.userDeleted.emit(this.user!.id);
            this.router.navigate(['/users']);
          },
          error: (err) => {
            this.notificationService.error('Failed to delete user');
          }
        });
    }
  }

  private saveDraft(): void {
    if (this.user) {
      localStorage.setItem('userDraft', JSON.stringify(this.user));
    }
  }
}
```

```html
<!-- user-profile.component.html -->
<div class="user-profile">
  <div *ngIf="loading" class="spinner">
    Loading user...
  </div>

  <div *ngIf="error" class="alert alert-danger">
    {{ error }}
  </div>

  <div *ngIf="!loading && user" class="user-details">
    <h2>User Profile</h2>

    <div class="form-group">
      <label>Name:</label>
      <input
        #nameInput
        type="text"
        [(ngModel)]="user.name"
        class="form-control">
    </div>

    <div class="form-group">
      <label>Email:</label>
      <input
        type="email"
        [(ngModel)]="user.email"
        class="form-control">
    </div>

    <div class="form-group">
      <label>Role:</label>
      <select [(ngModel)]="user.role" class="form-control">
        <option value="admin">Admin</option>
        <option value="user">User</option>
        <option value="guest">Guest</option>
      </select>
    </div>

    <div *ngIf="showActions" class="actions">
      <button (click)="updateUser()" class="btn btn-primary">
        Save Changes
      </button>
      <button (click)="deleteUser()" class="btn btn-danger">
        Delete User
      </button>
    </div>
  </div>
</div>
```

### Component Lifecycle Hooks (Complete Flow)

```typescript
// ============================================
// LIFECYCLE HOOKS EXECUTION ORDER
// ============================================

/*
1. constructor()
   ↓
2. ngOnChanges()        // When @Input() changes (before ngOnInit)
   ↓
3. ngOnInit()           // Initialize component (called ONCE)
   ↓
4. ngDoCheck()          // Custom change detection
   ↓
5. ngAfterContentInit() // After content projection (ng-content)
   ↓
6. ngAfterContentChecked() // After checking content
   ↓
7. ngAfterViewInit()    // After view is initialized
   ↓
8. ngAfterViewChecked() // After checking view
   ↓
   [Component is active - responds to events, data changes]
   ↓
9. ngOnChanges()        // If @Input() changes again
   ↓
10. ngOnDestroy()       // Before component is destroyed
*/

// ============================================
// PRACTICAL EXAMPLE WITH ALL HOOKS
// ============================================

@Component({
  selector: 'app-lifecycle-demo',
  template: `
    <div>
      <h3>{{ title }}</h3>
      <ng-content></ng-content>
      <div #content>View content</div>
    </div>
  `
})
export class LifecycleDemoComponent implements
  OnChanges,
  OnInit,
  DoCheck,
  AfterContentInit,
  AfterContentChecked,
  AfterViewInit,
  AfterViewChecked,
  OnDestroy {

  @Input() title: string;
  @ViewChild('content') content: ElementRef;

  constructor() {
    console.log('1. constructor');
  }

  ngOnChanges(changes: SimpleChanges): void {
    console.log('2. ngOnChanges', changes);
  }

  ngOnInit(): void {
    console.log('3. ngOnInit');
    // ✅ Initialize data, subscribe to observables
  }

  ngDoCheck(): void {
    console.log('4. ngDoCheck');
    // ⚠️ Called frequently - keep it lightweight!
  }

  ngAfterContentInit(): void {
    console.log('5. ngAfterContentInit');
    // ✅ Access to <ng-content> available
  }

  ngAfterContentChecked(): void {
    console.log('6. ngAfterContentChecked');
    // ⚠️ Called frequently
  }

  ngAfterViewInit(): void {
    console.log('7. ngAfterViewInit');
    // ✅ @ViewChild elements available now
    console.log(this.content.nativeElement);
  }

  ngAfterViewChecked(): void {
    console.log('8. ngAfterViewChecked');
    // ⚠️ Called frequently
  }

  ngOnDestroy(): void {
    console.log('9. ngOnDestroy');
    // ✅ Cleanup: unsubscribe, clear timers
  }
}
```

### Best Practices for Each Lifecycle Hook

```typescript
// ============================================
// ngOnInit - DATA INITIALIZATION
// ============================================

@Component({ /* ... */ })
export class ProductListComponent implements OnInit {
  products: Product[] = [];

  ngOnInit(): void {
    // ✅ Load data
    this.loadProducts();

    // ✅ Subscribe to route params
    this.route.params.subscribe(params => {
      this.categoryId = params['id'];
      this.loadProducts();
    });

    // ✅ Setup form
    this.setupForm();
  }

  // ❌ DON'T do this in constructor
  constructor(private productService: ProductService) {
    // this.loadProducts(); // BAD!
  }
}

// ============================================
// ngOnChanges - REACT TO INPUT CHANGES
// ============================================

@Component({ /* ... */ })
export class UserCardComponent implements OnChanges {
  @Input() userId: number;
  @Input() showDetails: boolean;

  user: User;

  ngOnChanges(changes: SimpleChanges): void {
    // Check if specific input changed
    if (changes['userId']) {
      const userId = changes['userId'].currentValue;

      // Avoid loading on first change if ngOnInit handles it
      if (!changes['userId'].firstChange) {
        this.loadUser(userId);
      }
    }

    // React to showDetails change
    if (changes['showDetails']) {
      this.toggleDetails(changes['showDetails'].currentValue);
    }
  }
}

// ============================================
// ngAfterViewInit - ACCESS DOM ELEMENTS
// ============================================

@Component({ /* ... */ })
export class SearchComponent implements AfterViewInit {
  @ViewChild('searchInput') searchInput: ElementRef<HTMLInputElement>;

  ngAfterViewInit(): void {
    // ✅ Focus input
    this.searchInput.nativeElement.focus();

    // ✅ Setup third-party library
    $(this.searchInput.nativeElement).autocomplete({
      source: this.suggestions
    });

    // ✅ Observe element changes
    const observer = new ResizeObserver(() => {
      console.log('Element resized');
    });
    observer.observe(this.searchInput.nativeElement);
  }
}

// ============================================
// ngOnDestroy - CLEANUP
// ============================================

@Component({ /* ... */ })
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

    // Setup interval
    this.intervalId = setInterval(() => {
      this.refreshData();
    }, 30000);
  }

  ngOnDestroy(): void {
    // ✅ Unsubscribe from all observables
    this.subscriptions.unsubscribe();

    // ✅ Clear intervals/timeouts
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }

    // ✅ Clean up event listeners
    document.removeEventListener('click', this.handleClick);

    // ✅ Save state
    this.saveComponentState();
  }
}
```

### Smart vs Presentational Components

```typescript
// ============================================
// SMART COMPONENT (Container)
// ============================================

@Component({
  selector: 'app-product-list-container',
  template: `
    <app-product-list
      [products]="products$ | async"
      [loading]="loading$ | async"
      (productSelected)="onProductSelected($event)"
      (addToCart)="onAddToCart($event)">
    </app-product-list>
  `
})
export class ProductListContainerComponent implements OnInit {
  products$ = this.productService.products$;
  loading$ = this.productService.loading$;

  constructor(
    private productService: ProductService,
    private cartService: CartService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.productService.loadProducts();
  }

  onProductSelected(product: Product): void {
    this.router.navigate(['/products', product.id]);
  }

  onAddToCart(product: Product): void {
    this.cartService.addItem(product);
  }
}

// ============================================
// PRESENTATIONAL COMPONENT (Dumb)
// ============================================

@Component({
  selector: 'app-product-list',
  changeDetection: ChangeDetectionStrategy.OnPush,  // Performance!
  template: `
    <div *ngIf="loading" class="spinner">Loading...</div>

    <div *ngIf="!loading" class="product-grid">
      <div
        *ngFor="let product of products"
        class="product-card"
        (click)="productSelected.emit(product)">

        <img [src]="product.imageUrl" [alt]="product.name">
        <h3>{{ product.name }}</h3>
        <p class="price">{{ product.price | currency }}</p>

        <button
          (click)="addToCart.emit(product); $event.stopPropagation()"
          class="btn-cart">
          Add to Cart
        </button>
      </div>
    </div>
  `
})
export class ProductListComponent {
  @Input() products: Product[] = [];
  @Input() loading = false;

  @Output() productSelected = new EventEmitter<Product>();
  @Output() addToCart = new EventEmitter<Product>();

  // No service dependencies!
  // No business logic!
  // Just presentation!
}
```

---

## Q355: Explain the Angular component lifecycle hooks.

**Answer:**

Covered in detail in Q354 above. Here's a quick reference with real-world use cases:

### Lifecycle Hooks Quick Reference

```typescript
// ============================================
// COMMON USE CASES FOR EACH HOOK
// ============================================

export class ComponentLifecycleExamples {

  // ✅ ngOnInit - Most commonly used
  ngOnInit(): void {
    // Initialize data
    this.loadData();

    // Subscribe to observables
    this.route.params.subscribe(params => {
      this.id = params['id'];
    });

    // Setup forms
    this.buildForm();
  }

  // ✅ ngOnChanges - React to @Input() changes
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['customerId'] && !changes['customerId'].firstChange) {
      this.loadCustomerOrders(changes['customerId'].currentValue);
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

---

## Q356: What is data binding in Angular? Explain different types.

**Answer:**

**Data binding** synchronizes data between the component class and the template.

### Types of Data Binding

```typescript
// ============================================
// 1. INTERPOLATION {{ }}
// ============================================

@Component({
  template: `
    <h1>{{ title }}</h1>
    <p>Price: {{ price | currency }}</p>
    <p>Total: {{ quantity * price }}</p>
    <p>{{ getUserName() }}</p>
  `
})
export class InterpolationExample {
  title = 'My Product';
  price = 99.99;
  quantity = 3;

  getUserName(): string {
    return this.user.firstName + ' ' + this.user.lastName;
  }
}

// ============================================
// 2. PROPERTY BINDING [property]
// ============================================

@Component({
  template: `
    <!-- Element properties -->
    <img [src]="imageUrl" [alt]="imageAlt">
    <button [disabled]="isProcessing">Submit</button>
    <div [class.active]="isActive">Active Item</div>
    <div [style.color]="textColor">Colored Text</div>
    <div [style.font-size.px]="fontSize">Sized Text</div>

    <!-- Multiple classes -->
    <div [ngClass]="{
      'active': isActive,
      'disabled': isDisabled,
      'highlight': needsHighlight
    }">
    </div>

    <!-- Multiple styles -->
    <div [ngStyle]="{
      'color': textColor,
      'font-size.px': fontSize,
      'font-weight': isImportant ? 'bold' : 'normal'
    }">
    </div>

    <!-- Component property -->
    <app-child [product]="selectedProduct"></app-child>
  `
})
export class PropertyBindingExample {
  imageUrl = 'assets/logo.png';
  imageAlt = 'Company Logo';
  isProcessing = false;
  isActive = true;
  textColor = 'blue';
  fontSize = 16;
  selectedProduct: Product;
}

// ============================================
// 3. EVENT BINDING (event)
// ============================================

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
      (mouseleave)="onMouseLeave()"
      (mousemove)="onMouseMove($event)">
    </div>

    <!-- Custom component events -->
    <app-child (itemSelected)="onItemSelected($event)"></app-child>
  `
})
export class EventBindingExample {
  handleClick(): void {
    console.log('Button clicked');
  }

  handleClick($event: MouseEvent): void {
    console.log('Mouse X:', $event.clientX);
    $event.stopPropagation();
  }

  onInput($event: Event): void {
    const value = ($event.target as HTMLInputElement).value;
    console.log('Input value:', value);
  }

  onSubmit($event: Event): void {
    $event.preventDefault();
    console.log('Form submitted');
  }

  onItemSelected(item: any): void {
    console.log('Item selected:', item);
  }
}

// ============================================
// 4. TWO-WAY BINDING [(ngModel)]
// ============================================

// Import FormsModule in module
import { FormsModule } from '@angular/forms';

@Component({
  template: `
    <!-- Basic two-way binding -->
    <input [(ngModel)]="userName" placeholder="Enter name">
    <p>Hello, {{ userName }}!</p>

    <!-- Two-way binding with events -->
    <input
      [(ngModel)]="searchTerm"
      (ngModelChange)="onSearchChange($event)">

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

    <!-- Custom two-way binding -->
    <app-counter [(count)]="currentCount"></app-counter>
  `
})
export class TwoWayBindingExample {
  userName = '';
  searchTerm = '';
  agreedToTerms = false;
  selectedCountry = 'US';
  selectedOption = 'option1';
  currentCount = 0;

  countries = [
    { code: 'US', name: 'United States' },
    { code: 'UK', name: 'United Kingdom' },
    { code: 'IN', name: 'India' }
  ];

  onSearchChange(value: string): void {
    console.log('Search term changed:', value);
    this.performSearch(value);
  }
}

// Custom two-way binding component
@Component({
  selector: 'app-counter',
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
```

### Real-World Example: Shopping Cart

```typescript
// ============================================
// SHOPPING CART WITH ALL BINDING TYPES
// ============================================

@Component({
  selector: 'app-shopping-cart',
  template: `
    <div class="shopping-cart">
      <!-- Interpolation -->
      <h2>{{ cartTitle }}</h2>
      <p>Total Items: {{ getTotalItems() }}</p>

      <!-- Property binding -->
      <div [class.empty]="cart.length === 0">
        <p *ngIf="cart.length === 0">Your cart is empty</p>

        <div
          *ngFor="let item of cart; trackBy: trackByProductId"
          class="cart-item"
          [class.out-of-stock]="!item.inStock">

          <!-- Event binding -->
          <img
            [src]="item.imageUrl"
            [alt]="item.name"
            (error)="onImageError($event)">

          <div class="item-details">
            <h3>{{ item.name }}</h3>
            <p [style.color]="item.inStock ? 'green' : 'red'">
              {{ item.inStock ? 'In Stock' : 'Out of Stock' }}
            </p>

            <!-- Two-way binding -->
            <input
              type="number"
              [(ngModel)]="item.quantity"
              (ngModelChange)="onQuantityChange(item)"
              [min]="1"
              [max]="item.maxQuantity">

            <p>Price: {{ item.price | currency }}</p>
            <p>Subtotal: {{ item.quantity * item.price | currency }}</p>

            <!-- Event binding -->
            <button
              (click)="removeItem(item.id)"
              [disabled]="isProcessing"
              class="btn-remove">
              Remove
            </button>
          </div>
        </div>
      </div>

      <div class="cart-summary">
        <h3>Cart Summary</h3>
        <p>Subtotal: {{ getSubtotal() | currency }}</p>
        <p>Tax: {{ getTax() | currency }}</p>
        <p>Total: {{ getTotal() | currency }}</p>

        <button
          (click)="checkout()"
          [disabled]="cart.length === 0 || isProcessing"
          [class.processing]="isProcessing">
          {{ isProcessing ? 'Processing...' : 'Checkout' }}
        </button>
      </div>
    </div>
  `,
  styles: [`
    .cart-item.out-of-stock {
      opacity: 0.5;
    }
    .btn-remove:disabled {
      cursor: not-allowed;
    }
  `]
})
export class ShoppingCartComponent {
  cartTitle = 'Shopping Cart';
  cart: CartItem[] = [];
  isProcessing = false;

  getTotalItems(): number {
    return this.cart.reduce((sum, item) => sum + item.quantity, 0);
  }

  getSubtotal(): number {
    return this.cart.reduce((sum, item) => sum + (item.quantity * item.price), 0);
  }

  getTax(): number {
    return this.getSubtotal() * 0.1;  // 10% tax
  }

  getTotal(): number {
    return this.getSubtotal() + this.getTax();
  }

  onQuantityChange(item: CartItem): void {
    // Validate quantity
    if (item.quantity < 1) item.quantity = 1;
    if (item.quantity > item.maxQuantity) item.quantity = item.maxQuantity;

    // Update backend
    this.cartService.updateQuantity(item.id, item.quantity).subscribe();
  }

  removeItem(itemId: number): void {
    this.cart = this.cart.filter(item => item.id !== itemId);
    this.cartService.removeItem(itemId).subscribe();
  }

  onImageError($event: Event): void {
    ($event.target as HTMLImageElement).src = 'assets/placeholder.png';
  }

  checkout(): void {
    this.isProcessing = true;
    this.cartService.checkout(this.cart).subscribe({
      next: () => {
        this.cart = [];
        this.isProcessing = false;
      },
      error: () => {
        this.isProcessing = false;
      }
    });
  }

  trackByProductId(index: number, item: CartItem): number {
    return item.id;
  }
}
```

---

## Q357: What is one-way binding vs two-way binding?

**Answer:**

```typescript
// ============================================
// ONE-WAY BINDING (Component → View)
// ============================================

@Component({
  template: `
    <!-- Property binding (one-way) -->
    <input [value]="userName">
    <!-- User typing won't update userName -->

    <p>{{ message }}</p>
    <!-- message changes update view, not vice versa -->
  `
})
export class OneWayBindingExample {
  userName = 'John';
  message = 'Hello';

  // Component controls the data flow
  updateMessage(): void {
    this.message = 'Updated!';  // Updates view
  }
}

// ============================================
// TWO-WAY BINDING (Component ↔ View)
// ============================================

@Component({
  template: `
    <!-- Two-way binding -->
    <input [(ngModel)]="userName">
    <!-- User typing updates userName AND userName changes update view -->

    <p>Hello, {{ userName }}!</p>
  `
})
export class TwoWayBindingExample {
  userName = 'John';

  // Both component and view can update the value
}

// ============================================
// MANUAL TWO-WAY BINDING (How it works under the hood)
// ============================================

@Component({
  template: `
    <!-- This: -->
    <input [(ngModel)]="userName">

    <!-- Is syntactic sugar for: -->
    <input
      [ngModel]="userName"
      (ngModelChange)="userName = $event">

    <!-- Custom two-way binding -->
    <input
      [value]="searchTerm"
      (input)="searchTerm = $event.target.value">
  `
})
export class ManualTwoWayBinding {
  userName = '';
  searchTerm = '';
}

// ============================================
// CUSTOM TWO-WAY BINDING COMPONENT
// ============================================

// Usage: <app-rating [(rating)]="productRating"></app-rating>

@Component({
  selector: 'app-rating',
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

---

## Q358: What is the [(ngModel)] directive?

**Answer:**

**ngModel** creates two-way data binding for form controls.

```typescript
// ============================================
// SETUP (Import FormsModule)
// ============================================

import { FormsModule } from '@angular/forms';

@NgModule({
  imports: [FormsModule]
})
export class AppModule { }

// ============================================
// BASIC USAGE
// ============================================

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
  userName = '';
  age = 25;
  comments = '';
  agreed = false;
  selectedColor = 'blue';
  gender = 'male';
}

// ============================================
// WITH EVENTS
// ============================================

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
  searchTerm = '';
  searchResults: any[] = [];

  onSearchChange(value: string): void {
    console.log('Search term:', value);

    if (value.length >= 3) {
      this.searchService.search(value).subscribe(results => {
        this.searchResults = results;
      });
    } else {
      this.searchResults = [];
    }
  }
}

// ============================================
// WITH DEBOUNCE (Avoid excessive API calls)
// ============================================

@Component({
  template: `
    <input
      [(ngModel)]="searchTerm"
      (ngModelChange)="searchSubject.next($event)"
      placeholder="Search...">
  `
})
export class DebouncedSearchExample implements OnInit, OnDestroy {
  searchTerm = '';
  searchSubject = new Subject<string>();
  private subscription: Subscription;

  constructor(private searchService: SearchService) {}

  ngOnInit(): void {
    this.subscription = this.searchSubject
      .pipe(
        debounceTime(300),  // Wait 300ms after typing stops
        distinctUntilChanged(),  // Only if value changed
        switchMap(term => this.searchService.search(term))
      )
      .subscribe(results => {
        console.log('Search results:', results);
      });
  }

  ngOnDestroy(): void {
    this.subscription.unsubscribe();
  }
}

// ============================================
// OBJECT BINDING
// ============================================

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
    firstName: '',
    lastName: '',
    email: '',
    country: 'US',
    subscribeNewsletter: false
  };

  countries = [
    { code: 'US', name: 'United States' },
    { code: 'UK', name: 'United Kingdom' },
    { code: 'IN', name: 'India' }
  ];
}
```

---

## Q359: What are Angular directives? Structural vs Attribute directives.

**Answer:**

**Directives** are classes that add behavior to elements in Angular applications.

### Types of Directives

```typescript
// ============================================
// 1. STRUCTURAL DIRECTIVES (Change DOM structure)
// ============================================

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

    <!-- *ngIf with as (async pipe) -->
    <div *ngIf="user$ | async as user">
      {{ user.name }}
    </div>

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
      *ngFor="let item of items; let first = first; let last = last; let even = even"
      [class.first]="first"
      [class.last]="last"
      [class.even]="even">
      {{ item }}
    </div>

    <!-- *ngSwitch - Multiple conditions -->
    <div [ngSwitch]="userRole">
      <admin-panel *ngSwitchCase="'admin'"></admin-panel>
      <user-panel *ngSwitchCase="'user'"></user-panel>
      <guest-panel *ngSwitchDefault></guest-panel>
    </div>
  `
})
export class StructuralDirectivesExample {
  isLoggedIn = true;
  userName = 'John';
  user$ = this.authService.currentUser$;
  items = ['Item 1', 'Item 2', 'Item 3'];
  products: Product[] = [];
  userRole = 'admin';

  trackByProductId(index: number, product: Product): number {
    return product.id;
  }
}

// ============================================
// 2. ATTRIBUTE DIRECTIVES (Change appearance/behavior)
// ============================================

@Component({
  template: `
    <!-- ngClass - Add/remove CSS classes -->
    <div [ngClass]="'highlight'">Single class</div>

    <div [ngClass]="['class1', 'class2', 'class3']">Multiple classes</div>

    <div [ngClass]="{
      'active': isActive,
      'disabled': isDisabled,
      'highlight': needsHighlight
    }">
      Conditional classes
    </div>

    <!-- ngStyle - Add inline styles -->
    <div [ngStyle]="{ 'color': 'red', 'font-size': '20px' }">
      Styled text
    </div>

    <div [ngStyle]="{
      'background-color': bgColor,
      'font-size.px': fontSize,
      'padding.rem': padding,
      'font-weight': isImportant ? 'bold' : 'normal'
    }">
      Dynamic styles
    </div>

    <!-- ngModel - Two-way binding (covered earlier) -->
    <input [(ngModel)]="userName">
  `
})
export class AttributeDirectivesExample {
  isActive = true;
  isDisabled = false;
  needsHighlight = true;
  bgColor = '#f0f0f0';
  fontSize = 16;
  padding = 1;
  isImportant = true;
  userName = '';
}

// ============================================
// 3. CUSTOM ATTRIBUTE DIRECTIVE
// ============================================

// highlight.directive.ts
import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  selector: '[appHighlight]'
})
export class HighlightDirective {
  @Input() appHighlight = 'yellow';  // Default color
  @Input() defaultColor = 'transparent';

  constructor(private el: ElementRef) {}

  @HostListener('mouseenter') onMouseEnter() {
    this.highlight(this.appHighlight);
  }

  @HostListener('mouseleave') onMouseLeave() {
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
    <p [appHighlight]="'lightblue'" [defaultColor]="'white'">
      Hover me (custom colors)
    </p>
  `
})
export class HighlightExample {}

// ============================================
// 4. CUSTOM STRUCTURAL DIRECTIVE
// ============================================

// unless.directive.ts
import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

@Directive({
  selector: '[appUnless]'
})
export class UnlessDirective {
  private hasView = false;

  @Input() set appUnless(condition: boolean) {
    if (!condition && !this.hasView) {
      // Create view if condition is false
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (condition && this.hasView) {
      // Remove view if condition is true
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
    <!-- Shows when isLoggedIn is false -->
  `
})
export class UnlessExample {
  isLoggedIn = false;
}

// ============================================
// 5. ADVANCED CUSTOM DIRECTIVE
// ============================================

// tooltip.directive.ts
@Directive({
  selector: '[appTooltip]'
})
export class TooltipDirective implements OnDestroy {
  @Input() appTooltip = '';
  @Input() tooltipPosition: 'top' | 'bottom' | 'left' | 'right' = 'top';

  private tooltipElement: HTMLElement | null = null;

  constructor(private el: ElementRef, private renderer: Renderer2) {}

  @HostListener('mouseenter')
  onMouseEnter(): void {
    if (!this.tooltipElement) {
      this.showTooltip();
    }
  }

  @HostListener('mouseleave')
  onMouseLeave(): void {
    if (this.tooltipElement) {
      this.hideTooltip();
    }
  }

  private showTooltip(): void {
    // Create tooltip element
    this.tooltipElement = this.renderer.createElement('span');
    this.renderer.appendChild(
      this.tooltipElement,
      this.renderer.createText(this.appTooltip)
    );

    // Add styles
    this.renderer.addClass(this.tooltipElement, 'tooltip');
    this.renderer.addClass(this.tooltipElement, `tooltip-${this.tooltipPosition}`);

    // Append to body
    this.renderer.appendChild(document.body, this.tooltipElement);

    // Position tooltip
    const hostPos = this.el.nativeElement.getBoundingClientRect();
    const tooltipPos = this.tooltipElement.getBoundingClientRect();

    let top = 0, left = 0;

    switch (this.tooltipPosition) {
      case 'top':
        top = hostPos.top - tooltipPos.height - 10;
        left = hostPos.left + (hostPos.width - tooltipPos.width) / 2;
        break;
      case 'bottom':
        top = hostPos.bottom + 10;
        left = hostPos.left + (hostPos.width - tooltipPos.width) / 2;
        break;
      // ... other positions
    }

    this.renderer.setStyle(this.tooltipElement, 'top', `${top}px`);
    this.renderer.setStyle(this.tooltipElement, 'left', `${left}px`);
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
    <button
      appTooltip="Click to save changes"
      tooltipPosition="bottom">
      Save
    </button>
  `
})
export class TooltipExample {}
```

### Real-World Example: Permission Directive

```typescript
// ============================================
// PERMISSION-BASED VISIBILITY DIRECTIVE
// ============================================

@Directive({
  selector: '[appHasPermission]'
})
export class HasPermissionDirective implements OnInit {
  @Input() appHasPermission: string | string[];

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    const permissions = Array.isArray(this.appHasPermission)
      ? this.appHasPermission
      : [this.appHasPermission];

    this.authService.currentUser$.subscribe(user => {
      if (user && this.hasPermission(user, permissions)) {
        this.viewContainer.createEmbeddedView(this.templateRef);
      } else {
        this.viewContainer.clear();
      }
    });
  }

  private hasPermission(user: User, permissions: string[]): boolean {
    return permissions.some(permission =>
      user.permissions.includes(permission)
    );
  }
}

// Usage
@Component({
  template: `
    <button *appHasPermission="'DELETE_USER'">
      Delete User
    </button>

    <div *appHasPermission="['ADMIN', 'SUPER_ADMIN']">
      Admin panel
    </div>
  `
})
export class AdminPanelComponent {}
```

---

**(File continues with Q360-Q376...)**