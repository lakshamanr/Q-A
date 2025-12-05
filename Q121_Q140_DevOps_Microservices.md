# AZURE DEVOPS, CONTAINERS, NETWORKING & MICROSERVICES - Q121-Q140

**Comprehensive Interview Answers with Examples and Best Practices**

---

## **Q121: What is Log Analytics workspace?**

### **Answer:**

Log Analytics workspace is a unique environment for Azure Monitor log data. Each workspace has its own data repository, configuration, and access control.

**Key Concepts:**

A workspace is where you:
- Collect logs from Azure resources
- Store and query log data
- Configure data retention
- Control access with RBAC

**Architecture:**

```
Data Sources → Log Analytics Workspace → Query & Analysis
┌─────────────────┐
│ Azure VMs       │──┐
│ App Insights    │──┤
│ Containers      │──┼──▶ ┌──────────────────────┐
│ Azure Resources │──┤    │ Log Analytics        │
│ Custom Apps     │──┤    │ Workspace            │
│ Security Events │──┘    │                      │
                          │ - Data Repository    │
                          │ - 30-730 days        │
                          │ - KQL Queries        │
                          └──────────┬───────────┘
                                     │
                          ┌──────────▼───────────┐
                          │ Analysis & Alerts    │
                          │ - Dashboards         │
                          │ - Workbooks          │
                          │ - Alert Rules        │
                          └──────────────────────┘
```

**Creating a Workspace:**

```bash
# Azure CLI
az monitor log-analytics workspace create \
    --resource-group myResourceGroup \
    --workspace-name myWorkspace \
    --location eastus \
    --retention-time 30

# Get workspace ID and key
az monitor log-analytics workspace show \
    --resource-group myResourceGroup \
    --workspace-name myWorkspace \
    --query customerId -o tsv
```

**Sending Custom Logs:**

```csharp
using Azure.Monitor.Query;
using Azure.Monitor.Query.Models;
using Azure.Identity;

public class LogAnalyticsService
{
    private readonly LogsQueryClient _client;
    private readonly string _workspaceId;

    public LogAnalyticsService(string workspaceId)
    {
        _workspaceId = workspaceId;
        _client = new LogsQueryClient(new DefaultAzureCredential());
    }

    // Query logs
    public async Task<List<LogEntry>> QueryLogsAsync(string query)
    {
        var response = await _client.QueryWorkspaceAsync(
            _workspaceId,
            query,
            new QueryTimeRange(TimeSpan.FromDays(1))
        );

        var results = new List<LogEntry>();
        foreach (var table in response.Value.AllTables)
        {
            foreach (var row in table.Rows)
            {
                results.Add(new LogEntry
                {
                    Timestamp = row.GetDateTime("TimeGenerated") ?? DateTime.MinValue,
                    Message = row.GetString("Message"),
                    Level = row.GetString("Level")
                });
            }
        }

        return results;
    }
}

// Send custom logs using HTTP Data Collector API
public class CustomLogSender
{
    private readonly string _workspaceId;
    private readonly string _sharedKey;
    private readonly HttpClient _httpClient;

    public async Task SendLogAsync(object logData, string logType)
    {
        var json = JsonSerializer.Serialize(new[] { logData });
        var date = DateTime.UtcNow.ToString("r");

        var signature = BuildSignature(
            "POST",
            json.Length,
            "application/json",
            date,
            "/api/logs"
        );

        var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://{_workspaceId}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01");

        request.Headers.Add("Authorization", signature);
        request.Headers.Add("Log-Type", logType);
        request.Headers.Add("x-ms-date", date);
        request.Content = new StringContent(json, Encoding.UTF8, "application/json");

        await _httpClient.SendAsync(request);
    }

    private string BuildSignature(string method, int contentLength,
        string contentType, string date, string resource)
    {
        var stringToHash = $"{method}\n{contentLength}\n{contentType}\nx-ms-date:{date}\n{resource}";
        var encoding = new UTF8Encoding();
        var keyBytes = Convert.FromBase64String(_sharedKey);
        var hash = new HMACSHA256(keyBytes);
        var hashBytes = hash.ComputeHash(encoding.GetBytes(stringToHash));
        return $"SharedKey {_workspaceId}:{Convert.ToBase64String(hashBytes)}";
    }
}

// Usage
var logSender = new CustomLogSender(workspaceId, sharedKey);
await logSender.SendLogAsync(new
{
    ApplicationName = "MyApp",
    Event = "UserLogin",
    UserId = "user123",
    Success = true,
    Timestamp = DateTime.UtcNow
}, "CustomApplicationLogs");
```

**Data Retention:**

- Default: 30 days (free)
- Max: 730 days (2 years)
- Archive: Up to 7 years (additional cost)

**Best Practices:**

1. One workspace per environment (Dev, Prod)
2. Configure appropriate retention
3. Use resource-based RBAC
4. Enable diagnostic settings on resources
5. Create alerts for critical queries
6. Use workbooks for visualization

---

## **Q122: Explain KQL (Kusto Query Language) basics.**

### **Answer:**

KQL (Kusto Query Language) is the query language used in Azure Monitor, Log Analytics, Application Insights, and Azure Data Explorer.

**Basic Syntax:**

```kusto
// Basic structure
TableName
| operator1
| operator2
| operator3
```

**Common Operators:**

### **1. where - Filter rows**

```kusto
// Filter by time
requests
| where timestamp > ago(1h)

// Filter by condition
requests
| where resultCode == 500

// Multiple conditions
requests
| where timestamp > ago(24h) and resultCode >= 400
| where name contains "api/orders"

// In operator
requests
| where resultCode in (400, 401, 403, 404)
```

### **2. project - Select columns**

```kusto
// Select specific columns
requests
| project timestamp, name, resultCode, duration

// Rename columns
requests
| project Time=timestamp, Endpoint=name, Status=resultCode

// Computed columns
requests
| project timestamp, name, durationInSeconds = duration / 1000
```

### **3. summarize - Aggregate data**

```kusto
// Count requests per endpoint
requests
| summarize count() by name

// Average duration
requests
| summarize avg(duration) by name

// Multiple aggregations
requests
| summarize
    RequestCount = count(),
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    P95Duration = percentile(duration, 95)
    by name

// Time-based aggregation
requests
| summarize count() by bin(timestamp, 1h)

// Group by multiple columns
requests
| summarize count() by resultCode, name
```

### **4. order by / sort by - Sort results**

```kusto
requests
| summarize count() by name
| order by count_ desc

// Top 10 slowest requests
requests
| order by duration desc
| take 10
```

### **5. extend - Add calculated columns**

```kusto
requests
| extend durationInSeconds = duration / 1000
| extend isError = resultCode >= 400
| project timestamp, name, durationInSeconds, isError
```

### **6. join - Combine tables**

```kusto
requests
| join kind=inner (
    dependencies
    | where type == "SQL"
) on operation_Id
| project timestamp, requestName=name, dependencyName=name1, duration, duration1
```

### **7. union - Combine rows from multiple tables**

```kusto
union requests, exceptions
| where timestamp > ago(1h)
| project timestamp, itemType, name
```

**Real-World Examples:**

### **Example 1: Failed Requests Analysis**

```kusto
requests
| where timestamp > ago(24h)
| where success == false
| summarize
    FailureCount = count(),
    DistinctUsers = dcount(user_Id),
    SampleErrors = take_any(resultCode, 5)
    by name
| order by FailureCount desc
| take 10
```

### **Example 2: Performance Analysis**

```kusto
requests
| where timestamp > ago(7d)
| summarize
    P50 = percentile(duration, 50),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99),
    Count = count()
    by bin(timestamp, 1h), name
| render timechart
```

### **Example 3: Error Rate Calculation**

```kusto
requests
| where timestamp > ago(24h)
| summarize
    Total = count(),
    Errors = countif(success == false)
    by bin(timestamp, 5m)
| extend ErrorRate = (Errors * 100.0) / Total
| project timestamp, ErrorRate
| render timechart
```

### **Example 4: Dependency Call Analysis**

```kusto
dependencies
| where timestamp > ago(1h)
| where type == "SQL"
| summarize
    CallCount = count(),
    AvgDuration = avg(duration),
    FailureCount = countif(success == false)
    by name
| extend FailureRate = (FailureCount * 100.0) / CallCount
| order by AvgDuration desc
```

### **Example 5: User Activity Tracking**

```kusto
customEvents
| where name == "PageView"
| where timestamp > ago(24h)
| extend Page = tostring(customDimensions.PageName)
| summarize
    Views = count(),
    UniqueUsers = dcount(user_Id)
    by Page
| order by Views desc
```

### **Example 6: Exception Analysis**

```kusto
exceptions
| where timestamp > ago(7d)
| extend ErrorType = type
| summarize
    Count = count(),
    SampleMessage = any(outerMessage)
    by ErrorType, problemId
| order by Count desc
| take 20
```

**Advanced Techniques:**

### **1. let statements - Variables**

```kusto
let startTime = ago(24h);
let threshold = 1000;
requests
| where timestamp > startTime
| where duration > threshold
| summarize count() by name
```

### **2. Parsing JSON**

```kusto
customEvents
| extend Properties = todynamic(customDimensions)
| extend OrderId = tostring(Properties.OrderId)
| extend Amount = todouble(Properties.Amount)
| where Amount > 100
```

### **3. Regular Expressions**

```kusto
requests
| where name matches regex "api/v[0-9]+/.*"
| summarize count() by name
```

### **4. Time Series Analysis**

```kusto
requests
| where timestamp > ago(30d)
| make-series
    RequestCount = count()
    default = 0
    on timestamp
    step 1h
| render timechart
```

**Query Optimization Tips:**

1. **Filter early**: Use `where` before other operators
2. **Limit columns**: Use `project` to select only needed columns
3. **Use time filters**: Always filter by time range
4. **Avoid expensive operations**: Limit use of `distinct`, `join`
5. **Use summarize efficiently**: Aggregate data early

**Common Functions:**

```kusto
// String functions
| where name contains "api"
| where name startswith "api/v1"
| where name endswith "/orders"
| extend upper_name = toupper(name)

// Date/Time functions
| where timestamp > ago(1h)
| where timestamp between (datetime(2024-01-01) .. datetime(2024-12-31))
| extend hour = datetime_part("hour", timestamp)

// Math functions
| extend rounded = round(duration, 2)
| extend ceiling = ceiling(duration)
| extend absolute = abs(temperature)

// Aggregation functions
| summarize count(), sum(amount), avg(duration), min(price), max(price)
| summarize percentile(duration, 95), dcount(user_Id)

// Array functions
| mv-expand Tags = split(TagString, ",")
| summarize make_list(name), make_set(userId)
```

---

## **Q123: What is Azure DevOps? Explain its components.**

### **Answer:**

Azure DevOps is a suite of development tools for planning, developing, delivering, and maintaining software. It provides integrated services for the entire DevOps lifecycle.

**Five Core Services:**

### **1. Azure Boards** (Project Management)

**Features:**
- Work item tracking (User Stories, Tasks, Bugs)
- Kanban boards
- Backlogs and sprint planning
- Dashboards and reporting
- Agile, Scrum, CMMI process templates

**Example Work Item:**

```
User Story: Implement Payment Gateway
├─ Task 1: Design payment API
├─ Task 2: Integrate with Stripe
├─ Task 3: Write unit tests
└─ Task 4: Update documentation

Status: In Progress
Sprint: Sprint 23
Assigned to: John Doe
Story Points: 8
```

**Use Cases:**
- Track features and bugs
- Sprint planning
- Team collaboration
- Progress tracking

---

### **2. Azure Repos** (Source Control)

**Features:**
- Git repositories (unlimited private repos)
- TFVC (Team Foundation Version Control)
- Pull requests with code review
- Branch policies
- Semantic code search

**Git Workflow:**

```bash
# Clone repository
git clone https://dev.azure.com/myorg/myproject/_git/myrepo

# Create feature branch
git checkout -b feature/payment-gateway

# Make changes and commit
git add .
git commit -m "Implement Stripe integration"

# Push to Azure Repos
git push origin feature/payment-gateway

# Create pull request (via Azure DevOps portal)
# - Request code review
# - Run build validation
# - Check policies (minimum reviewers, work item linking)
# - Merge to main after approval
```

**Branch Policies:**

```yaml
# Example branch policy for 'main' branch:
- Require minimum 2 reviewers
- Require linked work items
- Require successful build before merge
- Require comment resolution
- No force push
```

---

### **3. Azure Pipelines** (CI/CD)

**Features:**
- Build automation (CI)
- Release automation (CD)
- Multi-platform (Windows, Linux, macOS)
- Container support
- YAML pipelines
- Classic (visual) pipelines

**CI/CD Pipeline Example:**

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: UseDotNet@2
            inputs:
              version: '8.x'

          - task: DotNetCoreCLI@2
            displayName: 'Restore packages'
            inputs:
              command: 'restore'

          - task: DotNetCoreCLI@2
            displayName: 'Build solution'
            inputs:
              command: 'build'
              arguments: '--configuration $(buildConfiguration)'

          - task: DotNetCoreCLI@2
            displayName: 'Run tests'
            inputs:
              command: 'test'
              arguments: '--configuration $(buildConfiguration) --collect:"XPlat Code Coverage"'

          - task: DotNetCoreCLI@2
            displayName: 'Publish'
            inputs:
              command: 'publish'
              publishWebProjects: true
              arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'

          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: '$(Build.ArtifactStagingDirectory)'
              artifactName: 'drop'

  - stage: Deploy
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployToAzure
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'MyAzureSubscription'
                    appName: 'mywebapp'
                    package: '$(Pipeline.Workspace)/drop/*.zip'
```

---

### **4. Azure Test Plans** (Testing)

**Features:**
- Manual testing
- Exploratory testing
- Test case management
- Test execution tracking
- Integration with Azure Pipelines

**Test Case Example:**

```
Test Case: User Login
Steps:
1. Navigate to login page
2. Enter username: test@example.com
3. Enter password: ValidPassword123
4. Click "Login" button

Expected Result:
- User is redirected to dashboard
- Welcome message displays user's name
- Session cookie is set

Actual Result: [Pass/Fail]
```

---

### **5. Azure Artifacts** (Package Management)

**Features:**
- NuGet, npm, Maven, Python packages
- Universal packages
- Upstream sources
- Feed management
- Package versioning

**Publishing NuGet Package:**

```yaml
# Build and publish NuGet package
- task: DotNetCoreCLI@2
  displayName: 'Pack NuGet package'
  inputs:
    command: 'pack'
    packagesToPack: 'src/MyLibrary/MyLibrary.csproj'
    versioningScheme: 'byPrereleaseNumber'

- task: NuGetCommand@2
  displayName: 'Publish to Azure Artifacts'
  inputs:
    command: 'push'
    packagesToPush: '$(Build.ArtifactStagingDirectory)/**/*.nupkg'
    nuGetFeedType: 'internal'
    publishVstsFeed: 'MyFeed'
```

**Consuming Packages:**

```xml
<!-- nuget.config -->
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="MyAzureArtifacts"
         value="https://pkgs.dev.azure.com/myorg/_packaging/MyFeed/nuget/v3/index.json" />
  </packageSources>
</configuration>
```

---

**Integration Example - Full DevOps Workflow:**

```
Developer Workflow:
┌─────────────────────────────────────────────────────────────┐
│ 1. PLAN (Azure Boards)                                      │
│    - Create user story: "Add shopping cart"                 │
│    - Break down into tasks                                  │
│    - Assign to sprint                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 2. CODE (Azure Repos)                                       │
│    - Create feature branch                                  │
│    - Write code                                             │
│    - Commit changes                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 3. BUILD (Azure Pipelines - CI)                            │
│    - Trigger on commit                                      │
│    - Compile code                                           │
│    - Run unit tests                                         │
│    - Code quality checks                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 4. TEST (Azure Test Plans)                                 │
│    - Automated tests in pipeline                            │
│    - Manual test execution                                  │
│    - Test results tracked                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 5. RELEASE (Azure Pipelines - CD)                          │
│    - Deploy to Dev → Test → Production                     │
│    - Approval gates                                         │
│    - Automated deployments                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 6. MONITOR (Azure Monitor/App Insights)                    │
│    - Performance metrics                                    │
│    - Error tracking                                         │
│    - Usage analytics                                        │
└─────────────────────────────────────────────────────────────┘
```

**Pricing:**

- **Free tier**: 5 users, unlimited private Git repos, 1800 pipeline minutes/month
- **Basic**: $6/user/month
- **Basic + Test Plans**: $52/user/month

**Best Practices:**

1. **Use Git for version control** (not TFVC)
2. **Implement branch policies** to enforce code quality
3. **Automate builds and deployments** with pipelines
4. **Link commits to work items** for traceability
5. **Use YAML pipelines** for version-controlled CI/CD
6. **Implement pull request reviews** mandatory
7. **Use Azure Artifacts** for internal packages
8. **Track work in Boards** for transparency

---

## **Q124: How do you create a CI/CD pipeline in Azure DevOps?**

### **Answer:**

A CI/CD pipeline automates building, testing, and deploying applications. Here's a comprehensive guide to creating pipelines in Azure DevOps.

**Step-by-Step: Creating a CI/CD Pipeline**

### **Step 1: Prepare Your Application**

```csharp
// Sample ASP.NET Core application structure
MyWebApp/
├── src/
│   ├── MyWebApp/
│   │   ├── Controllers/
│   │   ├── Models/
│   │   ├── Program.cs
│   │   └── MyWebApp.csproj
│   └── MyWebApp.Tests/
│       ├── UnitTests.cs
│       └── MyWebApp.Tests.csproj
├── azure-pipelines.yml
└── MyWebApp.sln
```

### **Step 2: Create YAML Pipeline**

```yaml
# azure-pipelines.yml
name: $(Date:yyyyMMdd)$(Rev:.r)

trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - README.md
      - docs/*

pr:
  branches:
    include:
      - main

variables:
  buildConfiguration: 'Release'
  azureSubscription: 'MyAzureServiceConnection'
  webAppName: 'mywebapp-prod'

stages:
  # ============================================
  # STAGE 1: BUILD & TEST
  # ============================================
  - stage: Build
    displayName: 'Build and Test'
    jobs:
      - job: BuildJob
        displayName: 'Build Application'
        pool:
          vmImage: 'ubuntu-latest'

        steps:
          # Install .NET SDK
          - task: UseDotNet@2
            displayName: 'Install .NET 8 SDK'
            inputs:
              version: '8.x'
              includePreviewVersions: false

          # Restore NuGet packages
          - task: DotNetCoreCLI@2
            displayName: 'Restore NuGet Packages'
            inputs:
              command: 'restore'
              projects: '**/*.csproj'

          # Build solution
          - task: DotNetCoreCLI@2
            displayName: 'Build Solution'
            inputs:
              command: 'build'
              projects: '**/*.csproj'
              arguments: '--configuration $(buildConfiguration) --no-restore'

          # Run unit tests
          - task: DotNetCoreCLI@2
            displayName: 'Run Unit Tests'
            inputs:
              command: 'test'
              projects: '**/*Tests.csproj'
              arguments: >
                --configuration $(buildConfiguration)
                --no-build
                --collect:"XPlat Code Coverage"
                --logger trx
                --results-directory $(Agent.TempDirectory)/TestResults

          # Publish test results
          - task: PublishTestResults@2
            displayName: 'Publish Test Results'
            condition: succeededOrFailed()
            inputs:
              testResultsFormat: 'VSTest'
              testResultsFiles: '$(Agent.TempDirectory)/TestResults/**/*.trx'
              mergeTestResults: true
              failTaskOnFailedTests: true

          # Publish code coverage
          - task: PublishCodeCoverageResults@1
            displayName: 'Publish Code Coverage'
            inputs:
              codeCoverageTool: 'Cobertura'
              summaryFileLocation: '$(Agent.TempDirectory)/TestResults/**/coverage.cobertura.xml'

          # Publish application
          - task: DotNetCoreCLI@2
            displayName: 'Publish Application'
            inputs:
              command: 'publish'
              publishWebProjects: true
              arguments: >
                --configuration $(buildConfiguration)
                --output $(Build.ArtifactStagingDirectory)
                --no-build
              zipAfterPublish: true

          # Publish artifacts
          - task: PublishBuildArtifacts@1
            displayName: 'Publish Build Artifacts'
            inputs:
              pathToPublish: '$(Build.ArtifactStagingDirectory)'
              artifactName: 'drop'
              publishLocation: 'Container'

  # ============================================
  # STAGE 2: DEPLOY TO DEV
  # ============================================
  - stage: DeployDev
    displayName: 'Deploy to Dev'
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - deployment: DeployDevJob
        displayName: 'Deploy to Dev Environment'
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'Development'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebApp@1
                  displayName: 'Deploy to Azure Web App (Dev)'
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    appType: 'webAppLinux'
                    appName: 'mywebapp-dev'
                    package: '$(Pipeline.Workspace)/drop/*.zip'
                    runtimeStack: 'DOTNETCORE|8.0'

                - task: AzureAppServiceSettings@1
                  displayName: 'Update App Settings'
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    appName: 'mywebapp-dev'
                    resourceGroupName: 'myResourceGroup'
                    appSettings: |
                      [
                        {
                          "name": "ASPNETCORE_ENVIRONMENT",
                          "value": "Development",
                          "slotSetting": false
                        },
                        {
                          "name": "ApplicationInsights:InstrumentationKey",
                          "value": "$(AppInsights_InstrumentationKey_Dev)",
                          "slotSetting": false
                        }
                      ]

  # ============================================
  # STAGE 3: DEPLOY TO STAGING
  # ============================================
  - stage: DeployStaging
    displayName: 'Deploy to Staging'
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployStaging
        displayName: 'Deploy to Staging Environment'
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'Staging'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebApp@1
                  displayName: 'Deploy to Azure Web App (Staging)'
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    appType: 'webAppLinux'
                    appName: 'mywebapp-staging'
                    package: '$(Pipeline.Workspace)/drop/*.zip'
                    deploymentMethod: 'zipDeploy'

                # Run smoke tests
                - task: PowerShell@2
                  displayName: 'Run Smoke Tests'
                  inputs:
                    targetType: 'inline'
                    script: |
                      $response = Invoke-WebRequest -Uri "https://mywebapp-staging.azurewebsites.net/health" -UseBasicParsing
                      if ($response.StatusCode -ne 200) {
                        Write-Error "Health check failed"
                        exit 1
                      }
                      Write-Host "Health check passed"

  # ============================================
  # STAGE 4: DEPLOY TO PRODUCTION
  # ============================================
  - stage: DeployProduction
    displayName: 'Deploy to Production'
    dependsOn: DeployStaging
    condition: succeeded()
    jobs:
      - deployment: DeployProduction
        displayName: 'Deploy to Production Environment'
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                # Blue-Green deployment using slots
                - task: AzureWebApp@1
                  displayName: 'Deploy to Staging Slot'
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    appType: 'webAppLinux'
                    appName: '$(webAppName)'
                    package: '$(Pipeline.Workspace)/drop/*.zip'
                    deployToSlotOrASE: true
                    resourceGroupName: 'myResourceGroup'
                    slotName: 'staging'

                # Warm up staging slot
                - task: PowerShell@2
                  displayName: 'Warm up Staging Slot'
                  inputs:
                    targetType: 'inline'
                    script: |
                      Start-Sleep -Seconds 30
                      Invoke-WebRequest -Uri "https://$(webAppName)-staging.azurewebsites.net" -UseBasicParsing

                # Swap slots
                - task: AzureAppServiceManage@0
                  displayName: 'Swap Staging to Production'
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    action: 'Swap Slots'
                    webAppName: '$(webAppName)'
                    resourceGroupName: 'myResourceGroup'
                    sourceSlot: 'staging'
                    targetSlot: 'production'

                # Post-deployment validation
                - task: PowerShell@2
                  displayName: 'Validate Production Deployment'
                  inputs:
                    targetType: 'inline'
                    script: |
                      $maxAttempts = 5
                      $attempt = 0
                      $success = $false

                      while ($attempt -lt $maxAttempts -and -not $success) {
                        try {
                          $response = Invoke-WebRequest -Uri "https://$(webAppName).azurewebsites.net/health" -UseBasicParsing
                          if ($response.StatusCode -eq 200) {
                            Write-Host "Production validation successful"
                            $success = $true
                          }
                        }
                        catch {
                          $attempt++
                          Write-Warning "Attempt $attempt failed, retrying..."
                          Start-Sleep -Seconds 10
                        }
                      }

                      if (-not $success) {
                        Write-Error "Production validation failed after $maxAttempts attempts"
                        exit 1
                      }
```

### **Step 3: Set Up Service Connection**

```bash
# In Azure DevOps:
# 1. Project Settings → Service connections
# 2. New service connection → Azure Resource Manager
# 3. Service principal (automatic)
# 4. Select subscription and resource group
# 5. Name: MyAzureServiceConnection
```

### **Step 4: Configure Pipeline Variables**

```yaml
# In Azure DevOps UI or YAML
variables:
  - group: 'Production-Variables'  # Variable group
  - name: 'AppInsights_InstrumentationKey_Dev'
    value: 'your-key-here'
  - name: 'ConnectionStrings.Database'
    value: '$(DatabaseConnectionString)'  # From variable group
```

### **Step 5: Set Up Environments with Approvals**

```yaml
# Azure DevOps → Pipelines → Environments
# Create environments: Development, Staging, Production

# Add approval gates to Production:
# - Require approval from specific users
# - Add checks (Azure Function, REST API)
# - Set timeout for approvals
```

**Advanced Features:**

### **1. Matrix Build (Multiple Platforms)**

```yaml
strategy:
  matrix:
    Linux:
      imageName: 'ubuntu-latest'
    Windows:
      imageName: 'windows-latest'
    macOS:
      imageName: 'macOS-latest'
  maxParallel: 3

pool:
  vmImage: $(imageName)
```

### **2. Template Reusability**

```yaml
# templates/build-template.yml
parameters:
  - name: buildConfiguration
    type: string
    default: 'Release'

steps:
  - task: DotNetCoreCLI@2
    inputs:
      command: 'build'
      arguments: '--configuration ${{ parameters.buildConfiguration }}'

# azure-pipelines.yml
steps:
  - template: templates/build-template.yml
    parameters:
      buildConfiguration: 'Release'
```

### **3. Conditional Execution**

```yaml
- task: PublishBuildArtifacts@1
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))

- task: PowerShell@2
  condition: failed()  # Only run on failure
  inputs:
    script: 'Write-Host "Build failed, sending notification"'
```

**Best Practices:**

1. **Use YAML pipelines** for version control
2. **Implement multi-stage pipelines** (Build → Test → Deploy)
3. **Add approval gates** for production
4. **Use variable groups** for secrets
5. **Enable branch policies** to require pipeline success
6. **Implement proper testing** at each stage
7. **Use deployment slots** for zero-downtime deployments
8. **Monitor pipeline metrics** (success rate, duration)

---

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

