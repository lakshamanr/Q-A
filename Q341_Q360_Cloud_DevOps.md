# Interview Questions: Q341-Q360 (Cloud Architecture & DevOps)

## Q341. How do you design and implement cloud-native applications in Azure?

```csharp
/*
Cloud-Native Application Design in Azure
*/

// ✅ PATTERN 1: Azure App Service with Managed Identity

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Use Azure Managed Identity for authentication
        builder.Services.AddAzureClients(clientBuilder =>
        {
            // Storage Account with Managed Identity
            clientBuilder.AddBlobServiceClient(new Uri("https://mystorageaccount.blob.core.windows.net"));

            // Key Vault with Managed Identity
            clientBuilder.AddSecretClient(new Uri("https://mykeyvault.vault.azure.net/"));

            // Service Bus with Managed Identity
            clientBuilder.AddServiceBusClient("myservicebus.servicebus.windows.net");

            // Use DefaultAzureCredential (works locally and in Azure)
            clientBuilder.UseCredential(new DefaultAzureCredential());
        });

        // Add Application Insights
        builder.Services.AddApplicationInsightsTelemetry(options =>
        {
            options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
        });

        var app = builder.Build();
        app.Run();
    }
}

// ✅ PATTERN 2: Azure Storage Integration

public class BlobStorageService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly ILogger<BlobStorageService> _logger;

    public BlobStorageService(BlobServiceClient blobServiceClient, ILogger<BlobStorageService> logger)
    {
        _blobServiceClient = blobServiceClient;
        _logger = logger;
    }

    public async Task<string> UploadFileAsync(string containerName, string fileName, Stream fileStream)
    {
        try
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.None);

            var blobClient = containerClient.GetBlobClient(fileName);

            // Upload with metadata
            var metadata = new Dictionary<string, string>
            {
                ["UploadedAt"] = DateTime.UtcNow.ToString("O"),
                ["UploadedBy"] = "ApplicationService"
            };

            await blobClient.UploadAsync(fileStream, new BlobUploadOptions
            {
                HttpHeaders = new BlobHttpHeaders
                {
                    ContentType = "application/octet-stream"
                },
                Metadata = metadata,
                Conditions = new BlobRequestConditions
                {
                    IfNoneMatch = new ETag("*") // Prevent overwrite
                }
            });

            _logger.LogInformation("Uploaded blob {FileName} to container {ContainerName}", fileName, containerName);

            return blobClient.Uri.ToString();
        }
        catch (RequestFailedException ex) when (ex.Status == 409)
        {
            _logger.LogWarning("Blob {FileName} already exists", fileName);
            throw new InvalidOperationException($"Blob {fileName} already exists", ex);
        }
    }

    public async Task<Stream> DownloadFileAsync(string containerName, string fileName)
    {
        var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
        var blobClient = containerClient.GetBlobClient(fileName);

        var response = await blobClient.DownloadStreamingAsync();
        return response.Value.Content;
    }

    public async Task<bool> DeleteFileAsync(string containerName, string fileName)
    {
        var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
        var blobClient = containerClient.GetBlobClient(fileName);

        return await blobClient.DeleteIfExistsAsync();
    }
}

// ✅ PATTERN 3: Azure Service Bus Integration

public class ServiceBusMessagePublisher
{
    private readonly ServiceBusClient _client;
    private readonly ILogger<ServiceBusMessagePublisher> _logger;

    public ServiceBusMessagePublisher(ServiceBusClient client, ILogger<ServiceBusMessagePublisher> logger)
    {
        _client = client;
        _logger = logger;
    }

    public async Task PublishMessageAsync<T>(string queueName, T message)
    {
        var sender = _client.CreateSender(queueName);

        try
        {
            var json = JsonSerializer.Serialize(message);
            var serviceBusMessage = new ServiceBusMessage(json)
            {
                ContentType = "application/json",
                MessageId = Guid.NewGuid().ToString(),
                Subject = typeof(T).Name
            };

            // Add custom properties
            serviceBusMessage.ApplicationProperties["MessageType"] = typeof(T).Name;
            serviceBusMessage.ApplicationProperties["PublishedAt"] = DateTime.UtcNow;

            await sender.SendMessageAsync(serviceBusMessage);

            _logger.LogInformation("Published message {MessageId} to queue {QueueName}",
                serviceBusMessage.MessageId, queueName);
        }
        finally
        {
            await sender.DisposeAsync();
        }
    }

    public async Task PublishBatchAsync<T>(string queueName, IEnumerable<T> messages)
    {
        var sender = _client.CreateSender(queueName);

        try
        {
            using var messageBatch = await sender.CreateMessageBatchAsync();

            foreach (var message in messages)
            {
                var json = JsonSerializer.Serialize(message);
                var serviceBusMessage = new ServiceBusMessage(json)
                {
                    ContentType = "application/json",
                    MessageId = Guid.NewGuid().ToString()
                };

                if (!messageBatch.TryAddMessage(serviceBusMessage))
                {
                    // Batch is full, send it
                    await sender.SendMessagesAsync(messageBatch);
                    messageBatch.Dispose();

                    // Create new batch
                    using var newBatch = await sender.CreateMessageBatchAsync();
                    newBatch.TryAddMessage(serviceBusMessage);
                }
            }

            if (messageBatch.Count > 0)
            {
                await sender.SendMessagesAsync(messageBatch);
            }

            _logger.LogInformation("Published batch of {Count} messages to queue {QueueName}",
                messages.Count(), queueName);
        }
        finally
        {
            await sender.DisposeAsync();
        }
    }
}

// Service Bus Message Consumer
public class ServiceBusMessageConsumer : BackgroundService
{
    private readonly ServiceBusClient _client;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ServiceBusMessageConsumer> _logger;
    private ServiceBusProcessor _processor;

    public ServiceBusMessageConsumer(
        ServiceBusClient client,
        IServiceProvider serviceProvider,
        ILogger<ServiceBusMessageConsumer> logger)
    {
        _client = client;
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _processor = _client.CreateProcessor("orders-queue", new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 10,
            AutoCompleteMessages = false,
            MaxAutoLockRenewalDuration = TimeSpan.FromMinutes(5)
        });

        _processor.ProcessMessageAsync += ProcessMessageHandler;
        _processor.ProcessErrorAsync += ErrorHandler;

        await _processor.StartProcessingAsync(stoppingToken);

        // Wait until cancellation is requested
        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    private async Task ProcessMessageHandler(ProcessMessageEventArgs args)
    {
        var messageBody = args.Message.Body.ToString();
        _logger.LogInformation("Processing message {MessageId}", args.Message.MessageId);

        try
        {
            using var scope = _serviceProvider.CreateScope();
            var orderService = scope.ServiceProvider.GetRequiredService<IOrderService>();

            var order = JsonSerializer.Deserialize<Order>(messageBody);
            await orderService.ProcessOrderAsync(order);

            // Complete the message
            await args.CompleteMessageAsync(args.Message);

            _logger.LogInformation("Successfully processed message {MessageId}", args.Message.MessageId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message {MessageId}", args.Message.MessageId);

            // Dead-letter after max retries
            if (args.Message.DeliveryCount >= 3)
            {
                await args.DeadLetterMessageAsync(args.Message, "MaxRetryExceeded", ex.Message);
            }
            else
            {
                await args.AbandonMessageAsync(args.Message);
            }
        }
    }

    private Task ErrorHandler(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Error in Service Bus processor");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await _processor.DisposeAsync();
        await base.StopAsync(cancellationToken);
    }
}

// ✅ PATTERN 4: Azure Key Vault Configuration

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add Azure Key Vault configuration
        var keyVaultUrl = builder.Configuration["KeyVault:Url"];
        if (!string.IsNullOrEmpty(keyVaultUrl))
        {
            builder.Configuration.AddAzureKeyVault(
                new Uri(keyVaultUrl),
                new DefaultAzureCredential());
        }

        // Now secrets from Key Vault are available via IConfiguration
        var connectionString = builder.Configuration["ConnectionStrings:DefaultConnection"];

        var app = builder.Build();
        app.Run();
    }
}

/*
Cloud-Native Principles for Azure:

1. Managed Services:
   ✅ Azure App Service (PaaS)
   ✅ Azure SQL Database
   ✅ Azure Cosmos DB
   ✅ Azure Service Bus
   ✅ Azure Storage
   ✅ Azure Key Vault

2. Identity & Security:
   ✅ Managed Identity (no credentials in code)
   ✅ Azure AD authentication
   ✅ Key Vault for secrets
   ✅ RBAC for access control
   ✅ Network Security Groups

3. Scalability:
   ✅ Auto-scaling (App Service, AKS)
   ✅ Azure Front Door for global distribution
   ✅ Azure CDN for static content
   ✅ Horizontal scaling

4. Resilience:
   ✅ Availability Zones
   ✅ Geo-redundancy
   ✅ Azure Traffic Manager
   ✅ Retry policies
   ✅ Circuit breakers

5. Observability:
   ✅ Application Insights
   ✅ Azure Monitor
   ✅ Log Analytics
   ✅ Distributed tracing
   ✅ Custom metrics

Best Practices:
✅ Use Managed Identity everywhere
✅ Store secrets in Key Vault
✅ Enable diagnostic logging
✅ Implement health checks
✅ Use Azure Monitor for alerts
✅ Tag resources for cost tracking
✅ Implement least privilege access
✅ Use Azure Policy for governance
✅ Enable geo-redundancy for critical data
✅ Automate infrastructure with ARM/Bicep/Terraform

Azure Services Overview:
- Compute: App Service, AKS, Container Apps, Functions
- Storage: Blob Storage, Table Storage, Queue Storage, Files
- Database: SQL Database, Cosmos DB, PostgreSQL, MySQL
- Messaging: Service Bus, Event Grid, Event Hubs
- Security: Key Vault, Azure AD, Security Center
- Monitoring: Application Insights, Monitor, Log Analytics
- Networking: VNet, Load Balancer, Application Gateway, Front Door
*/
```

---

## Q342. How do you implement Infrastructure as Code (IaC) with Terraform or ARM templates?

```csharp
/*
Infrastructure as Code - Terraform and Bicep Examples
*/

// ✅ PATTERN 1: Terraform Configuration for Azure

/*
# main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaccount"
    container_name      = "tfstate"
    key                 = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P1v3"

  tags = azurerm_resource_group.main.tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_name}-${var.environment}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true

    application_stack {
      dotnet_version = "8.0"
    }

    health_check_path = "/health"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"           = var.environment
    "ApplicationInsights__ConnectionString" = azurerm_application_insights.main.connection_string
    "KeyVault__Url"                    = azurerm_key_vault.main.vault_uri
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.main.tags
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-${var.environment}-sql"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = var.azuread_admin_object_id
  }

  tags = azurerm_resource_group.main.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "${var.project_name}-${var.environment}-db"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "S1"
  zone_redundant = false

  tags = azurerm_resource_group.main.tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
  }

  tags = azurerm_resource_group.main.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}-${var.environment}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.main.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  tags = azurerm_resource_group.main.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = azurerm_resource_group.main.tags
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.project_name}-${var.environment}-sb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  tags = azurerm_resource_group.main.tags
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "orders" {
  name         = "orders-queue"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_delivery_count                = 10
  lock_duration                     = "PT30S"
  requires_duplicate_detection      = true
  duplicate_detection_history_time_window = "PT10M"
}

# Variables file
# variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# Outputs file
# outputs.tf
output "web_app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
*/

// ✅ PATTERN 2: Azure Bicep (ARM Template DSL)

/*
// main.bicep

@description('Name of the project')
param projectName string

@description('Environment name')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Azure region')
param location string = resourceGroup().location

var resourceNamePrefix = '${projectName}-${environment}'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${resourceNamePrefix}-plan'
  location: location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${resourceNamePrefix}-app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      healthCheckPath: '/health'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'ApplicationInsights__ConnectionString'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'KeyVault__Url'
          value: keyVault.properties.vaultUri
        }
      ]
    }
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: '${resourceNamePrefix}-sql'
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssw0rd123!'  // Use Key Vault reference in production
    version: '12.0'
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: '${resourceNamePrefix}-db'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${resourceNamePrefix}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourceNamePrefix}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: environment
    Project: projectName
  }
}

// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultUrl string = keyVault.properties.vaultUri
*/

// C# Code to Deploy Terraform/Bicep via CI/CD

public class InfrastructureDeployment
{
    public async Task DeployTerraformAsync(string workingDirectory)
    {
        // Terraform Init
        await ExecuteCommandAsync("terraform", "init", workingDirectory);

        // Terraform Plan
        await ExecuteCommandAsync("terraform", "plan -out=tfplan", workingDirectory);

        // Terraform Apply
        await ExecuteCommandAsync("terraform", "apply -auto-approve tfplan", workingDirectory);
    }

    public async Task DeployBicepAsync(string bicepFile, string resourceGroup)
    {
        var deploymentName = $"deployment-{DateTime.UtcNow:yyyyMMddHHmmss}";

        // Deploy using Azure CLI
        var command = $"az deployment group create " +
                     $"--name {deploymentName} " +
                     $"--resource-group {resourceGroup} " +
                     $"--template-file {bicepFile} " +
                     $"--parameters environment=prod projectName=myapp";

        await ExecuteCommandAsync("az", command, Directory.GetCurrentDirectory());
    }

    private async Task ExecuteCommandAsync(string command, string arguments, string workingDirectory)
    {
        var processInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(processInfo);
        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
        {
            var error = await process.StandardError.ReadToEndAsync();
            throw new Exception($"Command failed: {error}");
        }
    }
}

/*
Infrastructure as Code Best Practices:

1. Version Control:
   ✅ Store IaC in Git
   ✅ Code review for infrastructure changes
   ✅ Use branching strategy
   ✅ Tag releases

2. State Management:
   ✅ Remote state (Azure Storage, S3)
   ✅ State locking
   ✅ Encrypted state
   ✅ Backup state files

3. Modularity:
   ✅ Create reusable modules
   ✅ Separate environments
   ✅ Use variables and parameters
   ✅ Follow DRY principle

4. Security:
   ✅ Store secrets in Key Vault
   ✅ Use Managed Identity
   ✅ Implement RBAC
   ✅ Scan for vulnerabilities

5. Testing:
   ✅ Validate syntax
   ✅ Plan before apply
   ✅ Test in dev environment first
   ✅ Use policy as code (Azure Policy, Sentinel)

Tools Comparison:
Terraform:
- Multi-cloud support
- Large ecosystem
- HCL language
- State management required

Bicep:
- Azure-specific
- Simpler syntax than ARM JSON
- Native Azure integration
- Transparent state management

ARM Templates:
- Azure-native
- JSON format (verbose)
- Full Azure feature support
- Complex for large deployments

Recommendation: Use Bicep for Azure-only, Terraform for multi-cloud
*/
```

---

## Q343. How do you implement CI/CD pipelines with Azure DevOps or GitHub Actions?

```csharp
/*
CI/CD Pipeline Implementation
*/

// ✅ PATTERN 1: Azure DevOps Pipeline (azure-pipelines.yml)

/*
# azure-pipelines.yml

trigger:
  branches:
    include:
    - main
    - develop
  paths:
    exclude:
    - docs/*
    - README.md

variables:
  buildConfiguration: 'Release'
  vmImageName: 'ubuntu-latest'
  azureSubscription: 'Azure-Subscription-Connection'

stages:
- stage: Build
  displayName: 'Build Stage'
  jobs:
  - job: Build
    displayName: 'Build Job'
    pool:
      vmImage: $(vmImageName)

    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET SDK'
      inputs:
        version: '8.x'

    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet Packages'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Build Solution'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'

    - task: DotNetCoreCLI@2
      displayName: 'Run Unit Tests'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build --collect:"XPlat Code Coverage"'

    - task: PublishCodeCoverageResults@1
      displayName: 'Publish Code Coverage'
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Agent.TempDirectory)/**/*coverage.cobertura.xml'

    - task: DotNetCoreCLI@2
      displayName: 'Publish Application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true

    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifacts'
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployDev
    displayName: 'Deploy to Dev Environment'
    pool:
      vmImage: $(vmImageName)
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure App Service'
            inputs:
              azureSubscription: $(azureSubscription)
              appType: 'webAppLinux'
              appName: 'myapp-dev-webapp'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              runtimeStack: 'DOTNETCORE|8.0'

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployProd
    displayName: 'Deploy to Production'
    pool:
      vmImage: $(vmImageName)
    environment: 'production'
    strategy:
      runOnce:
        preDeploy:
          steps:
          - task: ManualValidation@0
            displayName: 'Manual Approval'
            inputs:
              notifyUsers: 'admin@company.com'
              instructions: 'Please approve deployment to production'

        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure App Service (Slot)'
            inputs:
              azureSubscription: $(azureSubscription)
              appType: 'webAppLinux'
              appName: 'myapp-prod-webapp'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deployToSlotOrASE: true
              resourceGroupName: 'myapp-prod-rg'
              slotName: 'staging'

          - task: AzureAppServiceManage@0
            displayName: 'Swap Slots'
            inputs:
              azureSubscription: $(azureSubscription)
              action: 'Swap Slots'
              webAppName: 'myapp-prod-webapp'
              resourceGroupName: 'myapp-prod-rg'
              sourceSlot: 'staging'
              targetSlot: 'production'
*/

// ✅ PATTERN 2: GitHub Actions Workflow

/*
# .github/workflows/ci-cd.yml

name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  DOTNET_VERSION: '8.0.x'
  AZURE_WEBAPP_NAME: 'myapp-prod-webapp'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}

    - name: Restore dependencies
      run: dotnet restore

    - name: Build
      run: dotnet build --configuration Release --no-restore

    - name: Test
      run: dotnet test --configuration Release --no-build --verbosity normal --collect:"XPlat Code Coverage"

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: '**/coverage.cobertura.xml'

    - name: Publish
      run: dotnet publish --configuration Release --no-build --output ./publish

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: webapp
        path: ./publish

  security-scan:
    runs-on: ubuntu-latest
    needs: build

    steps:
    - uses: actions/checkout@v3

    - name: Run Snyk Security Scan
      uses: snyk/actions/dotnet@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

    - name: Run SonarCloud Scan
      uses: sonarsource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  deploy-dev:
    runs-on: ubuntu-latest
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/develop'
    environment:
      name: development
      url: https://myapp-dev-webapp.azurewebsites.net

    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: webapp

    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'myapp-dev-webapp'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_DEV }}
        package: .

  deploy-prod:
    runs-on: ubuntu-latest
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://myapp-prod-webapp.azurewebsites.net

    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: webapp

    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Deploy to staging slot
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        slot-name: 'staging'
        package: .

    - name: Run smoke tests
      run: |
        response=$(curl -s -o /dev/null -w "%{http_code}" https://myapp-prod-webapp-staging.azurewebsites.net/health)
        if [ $response -ne 200 ]; then
          echo "Health check failed"
          exit 1
        fi

    - name: Swap slots
      run: |
        az webapp deployment slot swap \
          --name ${{ env.AZURE_WEBAPP_NAME }} \
          --resource-group myapp-prod-rg \
          --slot staging \
          --target-slot production
*/

// C# Integration Tests in CI/CD

public class CICDIntegrationTests
{
    [Fact]
    public async Task HealthEndpoint_ReturnsHealthy()
    {
        var baseUrl = Environment.GetEnvironmentVariable("APP_URL") ?? "https://localhost:5001";

        using var client = new HttpClient { BaseAddress = new Uri(baseUrl) };
        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Healthy", content);
    }

    [Fact]
    public async Task Database_IsAccessible()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Default");

        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        Assert.Equal(ConnectionState.Open, connection.State);
    }
}

/*
CI/CD Best Practices:

1. Pipeline Structure:
   ✅ Separate build and deploy stages
   ✅ Run tests before deployment
   ✅ Security scans in pipeline
   ✅ Manual approval for production
   ✅ Deployment to staging slot first

2. Testing Strategy:
   ✅ Unit tests (fast, run always)
   ✅ Integration tests (run on merge)
   ✅ Smoke tests after deployment
   ✅ Performance tests (scheduled)
   ✅ Security scans

3. Deployment Strategy:
   ✅ Blue-green deployments
   ✅ Canary releases
   ✅ Feature flags
   ✅ Rollback capability
   ✅ Zero-downtime deployments

4. Monitoring:
   ✅ Pipeline success/failure metrics
   ✅ Deployment frequency
   ✅ Lead time for changes
   ✅ Change failure rate
   ✅ MTTR (Mean Time To Recovery)

5. Security:
   ✅ Store secrets in vault
   ✅ Scan dependencies
   ✅ Container image scanning
   ✅ Static code analysis
   ✅ Dynamic security testing

Pipeline Stages:
1. Source Control → 2. Build → 3. Test → 4. Security Scan →
5. Package → 6. Deploy to Dev → 7. Integration Tests →
8. Deploy to Staging → 9. Smoke Tests → 10. Manual Approval →
11. Deploy to Production → 12. Monitor

Tools:
- Azure DevOps (Azure-focused, enterprise)
- GitHub Actions (GitHub-integrated, flexible)
- GitLab CI/CD (All-in-one platform)
- Jenkins (Self-hosted, highly customizable)
- CircleCI (Cloud-based, fast)
*/
```

---

## Q344-Q360. Essential Cloud & DevOps Patterns (Summary)

```csharp
/*
Comprehensive Cloud & DevOps Best Practices
This section covers Q344-Q360 with essential patterns and practices
*/

// Q344: Serverless Architecture (Azure Functions / AWS Lambda)
// Q345: Monitoring & APM (Application Insights, Prometheus)
// Q346: Cost Optimization in Cloud
// Q347: Multi-Cloud Strategies
// Q348: Disaster Recovery & Business Continuity
// Q349: Container Security
// Q350: GitOps Implementation
// Q351: Service Mesh (Istio, Linkerd)
// Q352: Chaos Engineering
// Q353: Progressive Delivery & Feature Flags
// Q354: API Management
// Q355: Database DevOps
// Q356: Observability as Code
// Q357: DevSecOps Practices
// Q358: Platform Engineering
// Q359: FinOps & Cloud Financial Management
// Q360: Continuous Improvement & Team Culture

/*
=================================================================
Q344: SERVERLESS ARCHITECTURE
=================================================================
*/

// Azure Functions - HTTP Trigger Example
[Function("GetProduct")]
public async Task<HttpResponseData> GetProduct(
    [HttpTrigger(AuthorizationLevel.Function, "get", Route = "products/{id}")] HttpRequestData req,
    string id)
{
    var product = await _productService.GetByIdAsync(Guid.Parse(id));
    var response = req.CreateResponse(HttpStatusCode.OK);
    await response.WriteAsJsonAsync(product);
    return response;
}

// Queue Trigger for Background Processing
[Function("ProcessOrder")]
public async Task ProcessOrder(
    [QueueTrigger("orders-queue")] OrderMessage order,
    FunctionContext context)
{
    await _orderService.ProcessAsync(order);
}

/*
Serverless Best Practices:
✅ Keep functions small and focused
✅ Use dependency injection
✅ Implement proper error handling
✅ Optimize cold start time
✅ Monitor function performance
*/

/*
=================================================================
Q345: MONITORING & APPLICATION PERFORMANCE MANAGEMENT
=================================================================
*/

// Application Insights Integration
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = true;
});

// Custom Metrics Tracking
public class MetricsService
{
    private readonly TelemetryClient _telemetryClient;

    public void TrackOrderValue(decimal value)
    {
        _telemetryClient.GetMetric("OrderValue").TrackValue((double)value);
    }

    public void TrackDependency(string name, TimeSpan duration, bool success)
    {
        _telemetryClient.TrackDependency("HTTP", name, null, DateTimeOffset.UtcNow, duration, success);
    }
}

/*
Monitoring Best Practices:
✅ Structured logging with correlation IDs
✅ Track business and technical metrics
✅ Set up proactive alerts
✅ Monitor SLIs and SLOs
✅ Implement distributed tracing
*/

/*
=================================================================
Q346: COST OPTIMIZATION
=================================================================
*/

/*
Cost Optimization Strategies:

1. Right-Sizing:
   - Monitor resource utilization
   - Use appropriate VM/service tiers
   - Implement auto-scaling
   - Shut down dev/test environments

2. Reserved Capacity:
   - Reserved Instances (save up to 72%)
   - Savings Plans
   - Hybrid Benefit licensing

3. Storage Optimization:
   - Use appropriate storage tiers (Hot/Cool/Archive)
   - Implement lifecycle policies
   - Compress and deduplicate data
   - Delete unused resources

4. Cost Monitoring:
   - Set up budgets and alerts
   - Tag resources for cost allocation
   - Regular cost reviews
   - Use Azure Cost Management / AWS Cost Explorer

Azure Cost Savings Tips:
✅ Use Azure Spot VMs for non-critical workloads
✅ Enable auto-shutdown for VMs
✅ Use Azure Advisor recommendations
✅ Implement resource tagging
✅ Review and delete unused resources monthly
*/

/*
=================================================================
Q347: MULTI-CLOUD & HYBRID STRATEGIES
=================================================================
*/

// Cloud-Agnostic Storage Interface
public interface ICloudStorageService
{
    Task UploadAsync(string fileName, Stream content);
    Task<Stream> DownloadAsync(string fileName);
}

// Azure Implementation
public class AzureBlobStorage : ICloudStorageService
{
    private readonly BlobServiceClient _client;
    public async Task UploadAsync(string fileName, Stream content)
    {
        var container = _client.GetBlobContainerClient("uploads");
        await container.GetBlobClient(fileName).UploadAsync(content);
    }
}

// AWS Implementation
public class AwsS3Storage : ICloudStorageService
{
    private readonly IAmazonS3 _client;
    public async Task UploadAsync(string fileName, Stream content)
    {
        await _client.PutObjectAsync(new PutObjectRequest
        {
            BucketName = "uploads",
            Key = fileName,
            InputStream = content
        });
    }
}

/*
Multi-Cloud Considerations:
✅ Avoid vendor lock-in
✅ Use abstraction layers
✅ Consistent monitoring
✅ Unified security policies
❌ Increased complexity
❌ Higher operational costs
*/

/*
=================================================================
Q348: DISASTER RECOVERY & BUSINESS CONTINUITY
=================================================================
*/

/*
Disaster Recovery Tiers:

Tier 1 - Critical (RPO < 1hr, RTO < 4hrs):
- Active-active geo-replication
- Auto-failover groups
- Real-time data replication
- Example: Payment systems, authentication

Tier 2 - Important (RPO < 4hrs, RTO < 8hrs):
- Geo-redundant storage
- Periodic backups
- Manual failover
- Example: E-commerce, CRM

Tier 3 - Standard (RPO < 24hrs, RTO < 24hrs):
- Regular backups
- Archive storage
- Recovery on demand
- Example: Reporting, analytics

Azure DR Services:
✅ Azure Site Recovery
✅ Geo-redundant Storage (GRS)
✅ SQL Database geo-replication
✅ Traffic Manager for failover
✅ Azure Backup

DR Best Practices:
✅ Regular backup testing
✅ Document runbooks
✅ Automated failover where possible
✅ Regular DR drills
✅ Monitor RPO/RTO metrics
*/

/*
=================================================================
Q349: CONTAINER SECURITY
=================================================================
*/

/*
Container Security Best Practices:

1. Image Security:
   ✅ Scan for vulnerabilities (Trivy, Snyk)
   ✅ Use minimal base images
   ✅ Sign and verify images
   ✅ Use private registries
   ✅ Regular updates

2. Runtime Security:
   ✅ Run as non-root user
   ✅ Read-only file systems
   ✅ Resource limits
   ✅ Network policies
   ✅ Pod Security Standards

3. Secrets Management:
   ✅ Kubernetes Secrets
   ✅ External vaults (Azure Key Vault)
   ✅ Rotate secrets regularly
   ✅ Encrypt at rest
   ✅ Least privilege access

Dockerfile Security Example:
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -D appuser
USER appuser
WORKDIR /app
COPY --chown=appuser:appuser . .
*/

/*
=================================================================
Q350-Q360: ADVANCED DEVOPS TOPICS SUMMARY
=================================================================
*/

/*
Q350: GitOps
- Flux CD / Argo CD
- Git as single source of truth
- Automated deployments
- Self-healing infrastructure

Q351: Service Mesh (Istio, Linkerd)
- Traffic management
- mTLS between services
- Observability
- Policy enforcement

Q352: Chaos Engineering
- Fault injection testing
- Resilience validation
- Azure Chaos Studio
- Netflix Chaos Monkey principles

Q353: Progressive Delivery
- Feature flags (LaunchDarkly, Unleash)
- Canary deployments
- A/B testing
- Gradual rollouts

Q354: API Management
- Azure API Management
- Rate limiting
- Authentication/Authorization
- Analytics and monitoring

Q355: Database DevOps
- Schema migrations (FluentMigrator, EF Migrations)
- Version control for database
- Automated deployments
- Backup and restore automation

Q356: Observability as Code
- Terraform for monitoring
- Automated dashboard creation
- SLO/SLI definitions in code
- Alert as code

Q357: DevSecOps
- Shift left security
- SAST/DAST in pipeline
- Dependency scanning
- Compliance automation
- Security gates in CI/CD

Q358: Platform Engineering
- Internal developer platforms
- Self-service infrastructure
- Golden paths
- Developer experience optimization

Q359: FinOps
- Cloud cost management
- Chargeback/showback models
- Optimization recommendations
- Budget forecasting
- Cost anomaly detection

Q360: Continuous Improvement
- DORA metrics tracking
- Retrospectives
- Blameless postmortems
- Learning culture
- Experimentation mindset
*/

/*
=================================================================
DORA METRICS (DevOps Research and Assessment)
=================================================================
*/

/*
Four Key Metrics:

1. Deployment Frequency
   Elite: Multiple times per day
   High: Once per day to once per week
   Medium: Once per week to once per month
   Low: Less than once per month

2. Lead Time for Changes
   Elite: Less than one hour
   High: Less than one day
   Medium: One day to one week
   Low: More than one week

3. Change Failure Rate
   Elite: 0-15%
   High: 16-30%
   Medium: 31-45%
   Low: 46-60%

4. Mean Time to Recovery (MTTR)
   Elite: Less than one hour
   High: Less than one day
   Medium: One day to one week
   Low: More than one week

How to Improve:
✅ Automate everything possible
✅ Implement comprehensive testing
✅ Use feature flags
✅ Improve monitoring and alerting
✅ Practice blameless postmortems
✅ Invest in developer experience
*/

/*
=================================================================
MODERN DEVOPS STACK
=================================================================
*/

/*
Recommended Toolchain:

Source Control:
- Git (GitHub, Azure Repos, GitLab)

CI/CD:
- GitHub Actions
- Azure Pipelines
- GitLab CI/CD

Infrastructure as Code:
- Terraform (multi-cloud)
- Bicep (Azure)
- Pulumi (programmatic)

Containers & Orchestration:
- Docker
- Kubernetes
- Azure Container Apps

Monitoring & Observability:
- Prometheus + Grafana
- Application Insights
- ELK Stack
- Jaeger (distributed tracing)

Security:
- Snyk (vulnerability scanning)
- SonarQube (code quality)
- Azure Security Center
- Trivy (container scanning)

Collaboration:
- Slack / Microsoft Teams
- Jira / Azure Boards
- Confluence / Wiki

Cloud Providers:
- Azure (Microsoft ecosystem)
- AWS (market leader)
- GCP (data/ML focused)
*/

/*
=================================================================
DEVOPS CULTURE & BEST PRACTICES
=================================================================
*/

/*
DevOps Principles:

1. Collaboration:
   ✅ Break down silos
   ✅ Shared responsibility
   ✅ Cross-functional teams
   ✅ Open communication

2. Automation:
   ✅ Automate repetitive tasks
   ✅ Infrastructure as Code
   ✅ Automated testing
   ✅ CI/CD pipelines

3. Continuous Improvement:
   ✅ Regular retrospectives
   ✅ Metrics-driven decisions
   ✅ Experimentation culture
   ✅ Learn from failures

4. Customer Focus:
   ✅ Fast feedback loops
   ✅ Value stream optimization
   ✅ User-centric development
   ✅ Continuous delivery

Success Factors:
✅ Executive support
✅ Team autonomy
✅ Psychological safety
✅ Learning opportunities
✅ Modern tooling
✅ Clear goals and metrics
✅ Celebrate successes
✅ Blameless culture

Remember: DevOps is a culture and mindset, not just tools and practices.
Success comes from continuous learning, collaboration, and improvement.
*/
```

---

**End of Q341-Q360: Cloud Architecture & DevOps**

This comprehensive section covers all essential cloud and DevOps topics:

**Core Cloud Topics (Q341-Q343)**:
- Azure cloud-native development with Managed Identity
- Infrastructure as Code (Terraform, Bicep, ARM)
- CI/CD pipelines (Azure DevOps, GitHub Actions)

**Extended Topics (Q344-Q360)**:
- Serverless architecture patterns
- Monitoring and APM strategies
- Cost optimization techniques
- Multi-cloud and hybrid approaches
- Disaster recovery planning
- Container security
- GitOps implementation
- Service mesh patterns
- Chaos engineering
- Progressive delivery
- API management
- Database DevOps
- Observability as code
- DevSecOps integration
- Platform engineering
- FinOps practices
- Continuous improvement culture

**Key Takeaways**:
- DORA metrics for measuring DevOps performance
- Modern DevOps toolchain recommendations
- Cultural principles for DevOps success
- Practical code examples and configurations
- Best practices for production systems

Total: 20 comprehensive questions covering the complete cloud and DevOps landscape for senior-level interviews.

