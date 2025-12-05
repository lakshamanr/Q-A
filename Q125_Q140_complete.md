## **Q125-Q140: Continuation - Azure DevOps, Containers & Microservices**

**Note:** Questions 121-124 are in the main file. This covers Q125-Q140.

---

## **Q128: What are pipeline artifacts and how do you use them?**

### **Answer:**

Pipeline artifacts are files produced by one job that need to be used by other jobs or stages in your pipeline.

**Publishing Artifacts:**

```yaml
# Publish build artifacts
- task: PublishBuildArtifacts@1
  displayName: 'Publish Artifact: drop'
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'drop'
    publishLocation: 'Container'

# Or using shorthand (recommended)
- publish: '$(Build.ArtifactStagingDirectory)'
  artifact: 'WebApp'
  displayName: 'Publish Web Application'
```

**Downloading Artifacts:**

```yaml
# Download all artifacts (default)
- download: current
  displayName: 'Download all artifacts'

# Download specific artifact
- download: current
  artifact: 'WebApp'
  displayName: 'Download WebApp artifact'

# Use artifact in deployment
- task: AzureWebApp@1
  inputs:
    package: '$(Pipeline.Workspace)/WebApp/*.zip'
```

**Real-World Multi-Stage Example:**

```yaml
stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: DotNetCoreCLI@2
            displayName: 'Build Application'
            inputs:
              command: 'publish'
              publishWebProjects: true
              arguments: '--output $(Build.ArtifactStagingDirectory)/app'

          # Publish multiple artifacts
          - publish: '$(Build.ArtifactStagingDirectory)/app'
            artifact: 'Application'

          - publish: '$(Build.SourcesDirectory)/scripts'
            artifact: 'DeploymentScripts'

          - publish: '$(Build.SourcesDirectory)/database'
            artifact: 'DatabaseScripts'

  - stage: Deploy
    dependsOn: Build
    jobs:
      - deployment: DeployJob
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                # Download specific artifacts
                - download: current
                  artifact: 'Application'
                - download: current
                  artifact: 'DeploymentScripts'

                - task: AzureWebApp@1
                  inputs:
                    package: '$(Pipeline.Workspace)/Application/*.zip'

                - task: PowerShell@2
                  inputs:
                    filePath: '$(Pipeline.Workspace)/DeploymentScripts/deploy.ps1'
```

**Pipeline Artifacts vs Build Artifacts:**

```yaml
# Pipeline artifacts (newer, recommended)
- publish: '$(Build.ArtifactStagingDirectory)'
  artifact: 'WebApp'
  # Faster, more reliable

# Build artifacts (older)
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'drop'
  # Legacy, slower
```

**Best Practices:**

1. Use `publish` shorthand for pipeline artifacts
2. Name artifacts descriptively
3. Only publish what's needed
4. Use artifacts for stage-to-stage communication
5. Clean up old artifacts regularly

---

## **Q129: Explain variable groups and library in Azure DevOps.**

### **Answer:**

Variable groups store values and secrets that you can share across multiple pipelines.

**Creating Variable Groups:**

```yaml
# In Azure DevOps UI:
# Pipelines → Library → + Variable group

# Variable Group: "Production-Variables"
Variables:
- DatabaseServer: "myserver.database.windows.net"
- DatabaseName: "ProductionDB"
- ApiKey: "***" (secret)

# Link to Azure Key Vault (recommended for secrets)
Variable group → Link secrets from Azure Key Vault
```

**Using Variable Groups in Pipeline:**

```yaml
variables:
  - group: 'Production-Variables'  # Reference variable group
  - name: 'BuildConfiguration'
    value: 'Release'

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'MySubscription'
      KeyVaultName: 'MyKeyVault'
      SecretsFilter: '*'

  - script: |
      echo "Database: $(DatabaseServer)"
      echo "API URL: $(ApiUrl)"
      # Secrets are automatically masked in logs
```

**Multiple Variable Groups:**

```yaml
variables:
  - group: 'GlobalSettings'
  - group: 'Production-Secrets'
  - group: 'AppSettings'

# Variables from all groups are available
```

**Runtime Parameters:**

```yaml
parameters:
  - name: environment
    displayName: 'Target Environment'
    type: string
    default: 'dev'
    values:
      - dev
      - staging
      - production

variables:
  - ${{ if eq(parameters.environment, 'production') }}:
    - group: 'Production-Variables'
  - ${{ if eq(parameters.environment, 'dev') }}:
    - group: 'Dev-Variables'
```

---

## **Q130: What is Azure Container Registry?**

### **Answer:**

Azure Container Registry (ACR) is a managed Docker registry service for storing and managing container images and artifacts.

**Key Features:**

- Private Docker registry
- Geo-replication for global distribution
- Integrated with Azure services (AKS, App Service, etc.)
- Security scanning
- Automated builds with ACR Tasks

**Creating Registry:**

```bash
# Create ACR
az acr create \
  --resource-group myResourceGroup \
  --name myregistry \
  --sku Premium \
  --location eastus

# Login to ACR
az acr login --name myregistry

# Or Docker login
docker login myregistry.azurecr.io
```

**Building and Pushing Images:**

```bash
# Build image locally
docker build -t myapp:v1 .

# Tag for ACR
docker tag myapp:v1 myregistry.azurecr.io/myapp:v1

# Push to ACR
docker push myregistry.azurecr.io/myapp:v1

# Or use ACR Tasks (build in Azure)
az acr build --registry myregistry --image myapp:v1 .
```

**Using in Pipeline:**

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerRegistryServiceConnection: 'MyACRConnection'
  imageRepository: 'myapp'
  containerRegistry: 'myregistry.azurecr.io'
  tag: '$(Build.BuildId)'

stages:
  - stage: Build
    jobs:
      - job: BuildAndPush
        steps:
          - task: Docker@2
            displayName: 'Build and push image'
            inputs:
              command: 'buildAndPush'
              repository: '$(imageRepository)'
              dockerfile: '**/Dockerfile'
              containerRegistry: '$(dockerRegistryServiceConnection)'
              tags: |
                $(tag)
                latest
```

**Deploying from ACR:**

```yaml
- task: AzureWebAppContainer@1
  inputs:
    azureSubscription: 'MySubscription'
    appName: 'myapp'
    containers: 'myregistry.azurecr.io/myapp:$(tag)'
```

---

## **Q131: What is Azure Kubernetes Service (AKS)?**

### **Answer:**

Azure Kubernetes Service (AKS) is a managed Kubernetes container orchestration service that simplifies deploying and managing containerized applications.

**Key Features:**

- Managed Kubernetes control plane (free)
- Automatic upgrades and patching
- Integrated with Azure services
- Built-in monitoring with Azure Monitor
- Autoscaling (horizontal pod autoscaler, cluster autoscaler)
- Azure AD integration

**Creating AKS Cluster:**

```bash
# Create AKS cluster
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

# Verify connection
kubectl get nodes
```

**Deploying Application:**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: myapp
```

**Deploy to AKS:**

```bash
kubectl apply -f deployment.yaml
kubectl get services
```

**Pipeline Deployment to AKS:**

```yaml
stages:
  - stage: Deploy
    jobs:
      - deployment: DeployToAKS
        environment: 'Production.myAKSCluster'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: KubernetesManifest@0
                  inputs:
                    action: 'deploy'
                    kubernetesServiceConnection: 'MyAKSConnection'
                    namespace: 'production'
                    manifests: |
                      $(Pipeline.Workspace)/manifests/deployment.yaml
                      $(Pipeline.Workspace)/manifests/service.yaml
```

---

## **Q137: What are microservices? How do they differ from monolithic architecture?**

### **Answer:**

Microservices is an architectural style where an application is composed of small, independent services that communicate over well-defined APIs.

**Monolithic vs Microservices:**

```
MONOLITHIC ARCHITECTURE:
┌─────────────────────────────────────┐
│                                     │
│  Single Application                 │
│  ┌─────────────────────────────┐   │
│  │ User Interface Layer        │   │
│  ├─────────────────────────────┤   │
│  │ Business Logic Layer        │   │
│  │  - Orders                   │   │
│  │  - Payments                 │   │
│  │  - Inventory                │   │
│  │  - Customers                │   │
│  ├─────────────────────────────┤   │
│  │ Data Access Layer           │   │
│  └─────────────────────────────┘   │
│           │                         │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │    Single Database          │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

Deployed as single unit
All features tightly coupled


MICROSERVICES ARCHITECTURE:
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Order    │  │ Payment  │  │Inventory │  │Customer  │
│ Service  │  │ Service  │  │ Service  │  │ Service  │
│          │  │          │  │          │  │          │
│ API      │  │ API      │  │ API      │  │ API      │
│ Logic    │  │ Logic    │  │ Logic    │  │ Logic    │
│ DB       │  │ DB       │  │ DB       │  │ DB       │
└─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘
      │             │              │             │
      └─────────────┴──────────────┴─────────────┘
                    │
              ┌─────▼─────┐
              │ API       │
              │ Gateway   │
              └───────────┘

Each service independently deployable
Loose coupling between services
```

**Comparison Table:**

| Aspect | Monolithic | Microservices |
|--------|-----------|---------------|
| **Deployment** | Single unit | Independent services |
| **Scaling** | Scale entire app | Scale individual services |
| **Technology** | Single stack | Polyglot (multiple stacks) |
| **Database** | Shared database | Database per service |
| **Development** | One large team | Multiple small teams |
| **Testing** | Test entire app | Test each service |
| **Deployment Risk** | High (all or nothing) | Low (isolated changes) |
| **Complexity** | Simple initially | Complex overall |
| **Performance** | Fast (in-process) | Network overhead |

**Example Implementation:**

```csharp
// MONOLITHIC: All in one application
public class MonolithicOrderController : ControllerBase
{
    private readonly AppDbContext _db;

    [HttpPost]
    public async Task<IActionResult> CreateOrder(Order order)
    {
        // Order logic
        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        // Payment logic (same app)
        var payment = new Payment { OrderId = order.Id, Amount = order.Total };
        _db.Payments.Add(payment);

        // Inventory logic (same app)
        foreach (var item in order.Items)
        {
            var product = await _db.Products.FindAsync(item.ProductId);
            product.Stock -= item.Quantity;
        }

        // Customer logic (same app)
        var customer = await _db.Customers.FindAsync(order.CustomerId);
        customer.TotalOrders++;

        await _db.SaveChangesAsync();
        return Ok();
    }
}

// MICROSERVICES: Separate services
// Order Service
public class OrderController : ControllerBase
{
    private readonly OrderDbContext _db;
    private readonly IMessageBus _messageBus;
    private readonly IHttpClientFactory _httpClientFactory;

    [HttpPost]
    public async Task<IActionResult> CreateOrder(Order order)
    {
        // Order service handles ONLY orders
        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        // Publish event for other services
        await _messageBus.PublishAsync(new OrderCreatedEvent
        {
            OrderId = order.Id,
            CustomerId = order.CustomerId,
            Items = order.Items,
            Total = order.Total
        });

        // Or call other services via HTTP
        var paymentClient = _httpClientFactory.CreateClient("PaymentService");
        await paymentClient.PostAsJsonAsync("/api/payments", new
        {
            OrderId = order.Id,
            Amount = order.Total
        });

        return Ok();
    }
}

// Payment Service (separate application)
public class PaymentController : ControllerBase
{
    private readonly PaymentDbContext _db;  // Own database

    [HttpPost]
    public async Task<IActionResult> ProcessPayment(PaymentRequest request)
    {
        // Payment service handles ONLY payments
        var payment = new Payment
        {
            OrderId = request.OrderId,
            Amount = request.Amount,
            Status = "Processed"
        };

        _db.Payments.Add(payment);
        await _db.SaveChangesAsync();

        return Ok();
    }
}
```

**When to Use Each:**

**Use Monolithic When:**
- Small team
- Simple domain
- Rapid prototyping
- Limited resources
- Startup phase

**Use Microservices When:**
- Large team
- Complex domain
- Need independent scaling
- Different tech stacks needed
- Mature organization

**Advantages of Microservices:**

✅ Independent deployment
✅ Technology diversity
✅ Resilience (failure isolation)
✅ Scalability (scale what you need)
✅ Team autonomy
✅ Easier to understand (smaller codebases)

**Disadvantages of Microservices:**

❌ Increased complexity
❌ Network latency
❌ Distributed data management
❌ Testing complexity
❌ Deployment complexity
❌ Debugging challenges

---

## **Q138-Q140: Summary**

**Q138: Advantages and disadvantages** - Covered in Q137

**Q139: Microservices Design Principles:**

1. **Single Responsibility** - One service, one purpose
2. **Loose Coupling** - Services are independent
3. **High Cohesion** - Related functionality together
4. **Autonomous** - Can be developed/deployed independently
5. **API-First** - Well-defined contracts
6. **Database per Service** - Own data store
7. **Decentralized Governance** - Teams choose tech stack
8. **Failure Isolation** - Circuit breakers, bulkheads

**Q140: Domain-Driven Design (DDD):**

DDD is an approach to software development that focuses on understanding the business domain and modeling software accordingly.

**Key Concepts:**

- **Bounded Context**: Clear boundaries around models
- **Ubiquitous Language**: Common language between devs and business
- **Aggregates**: Cluster of domain objects
- **Entities**: Objects with identity
- **Value Objects**: Immutable objects without identity
- **Domain Events**: Significant occurrences in the domain

**DDD + Microservices:**

```
E-commerce Domain:

┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│ Order Context      │  │ Payment Context    │  │ Inventory Context  │
│                    │  │                    │  │                    │
│ - Order (Entity)   │  │ - Payment (Entity) │  │ - Product (Entity) │
│ - OrderItem (VO)   │  │ - Amount (VO)      │  │ - Stock (VO)       │
│ - PlaceOrder       │  │ - ProcessPayment   │  │ - Reserve          │
│                    │  │                    │  │                    │
│ → OrderService     │  │ → PaymentService   │  │ → InventoryService │
└────────────────────┘  └────────────────────┘  └────────────────────┘

Each bounded context = One microservice
```

---

✅ **COMPLETED Q121-Q140!**
- Azure DevOps (Pipelines, Agents, YAML)
- Containers (ACR, AKS)
- Microservices Architecture
- Domain-Driven Design

Ready for next section!

