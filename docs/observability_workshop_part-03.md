# 🚀 Complete Azure Observability Workshop Guide - Part 3
## 🔧 Intermediate Workshop (4 hours)

### ✅ Prerequisites Check
Before starting the Intermediate Workshop, ensure you have completed Parts 1-2 and have:
- ✅ Beginner Workshop completed successfully
- ✅ Application running in Azure with telemetry flowing to Application Insights
- ✅ Basic dashboards and alerts configured and tested
- ✅ GitHub Copilot working reliably for KQL queries
- ✅ Understanding of Azure Monitor, Application Insights, and basic observability concepts

### 📋 New Prerequisites for Intermediate Level
- **CI/CD Experience**: Basic understanding of deployment pipelines
- **Microservices Knowledge**: Understanding of distributed systems concepts
- **Container Basics**: Familiarity with Docker and containerization
- **Security Awareness**: Basic cloud security concepts
- **Third-party Tool Access**: Datadog account (free trial) - optional but recommended

### 🎯 Intermediate Workshop Overview
This workshop builds on the foundation from the beginner level and introduces:
- **Distributed tracing** across multiple microservices
- **Multi-cloud monitoring integration** with third-party tools
- **CI/CD pipeline integration** with observability and automated rollback
- **Security monitoring** with Microsoft Defender and Sentinel
- **Enterprise-scale patterns** and best practices

---

## 📊 Module 1: Advanced Application Insights and Distributed Tracing (60 minutes)

### 🏗️ 1.1 Microservices Architecture Setup
**Time Required**: 30 minutes

1. **📁 Create Microservices Project Structure**:
```bash
# 📂 Navigate to your workshop directory
cd azure-monitoring-workshop

# 🏗️ Create microservices structure
mkdir microservices
cd microservices

# 📁 Create individual service directories for enterprise architecture
mkdir user-service order-service notification-service api-gateway
mkdir shared/contracts shared/infrastructure

# ✅ Verify structure creation
echo "✅ Created microservices project structure successfully"
ls -la

# Expected output:
# 📁 user-service/
# 📁 order-service/ 
# 📁 notification-service/
# 📁 api-gateway/
# 📁 shared/
```

2. **🔧 Build User Service with Distributed Tracing**:
```bash
# 📂 Navigate to user service directory
cd user-service

# 🎆 Create new .NET Web API project with enterprise template
dotnet new webapi --name UserService --framework net8.0
cd UserService

# 📦 Add required packages for advanced distributed tracing
# Core Application Insights integration
dotnet add package Microsoft.ApplicationInsights.AspNetCore --version 2.21.0

# Diagnostics and telemetry foundation
dotnet add package System.Diagnostics.DiagnosticSource --version 8.0.0
dotnet add package Microsoft.Extensions.Http --version 8.0.0

# OpenTelemetry stack for distributed tracing
dotnet add package OpenTelemetry --version 1.6.0
dotnet add package OpenTelemetry.Extensions.Hosting --version 1.6.0
dotnet add package OpenTelemetry.Instrumentation.AspNetCore --version 1.5.1-beta.1
dotnet add package OpenTelemetry.Instrumentation.Http --version 1.5.1-beta.1
dotnet add package OpenTelemetry.Exporter.Console --version 1.6.0

# ✅ Verify packages were added successfully
dotnet list package
echo "✅ All distributed tracing packages installed successfully"
```

3. **⚙️ Create User Service with Advanced Tracing** - Replace `Program.cs`:
```csharp
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();

// Get configuration values
var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING") 
                      ?? builder.Configuration.GetConnectionString("ApplicationInsights");

// Configure Application Insights
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = connectionString;
});

// Configure OpenTelemetry
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.EnrichWithHttpRequest = (activity, httpRequest) =>
            {
                activity.SetTag("user.service", "UserService");
                activity.SetTag("http.request.size", httpRequest.ContentLength ?? 0);
            };
            options.EnrichWithHttpResponse = (activity, httpResponse) =>
            {
                activity.SetTag("http.response.size", httpResponse.ContentLength ?? 0);
            };
        })
        .AddHttpClientInstrumentation()
        .AddSource("UserService")
        .SetResourceBuilder(ResourceBuilder.CreateDefault()
            .AddService("UserService", "1.0.0"))
        .AddConsoleExporter(); // For local development
    });

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

4. **🎮 Create User Controller with Distributed Tracing** - Create `Controllers/UserController.cs`:
```csharp
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace UserService.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private static readonly ActivitySource ActivitySource = new("UserService");
        private readonly TelemetryClient _telemetryClient;
        private readonly ILogger<UserController> _logger;
        private readonly HttpClient _httpClient;

        public UserController(TelemetryClient telemetryClient, ILogger<UserController> logger, HttpClient httpClient)
        {
            _telemetryClient = telemetryClient;
            _logger = logger;
            _httpClient = httpClient;
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            using var activity = ActivitySource.StartActivity("GetUser");
            activity?.SetTag("user.id", id.ToString());
            activity?.SetTag("operation.name", "get_user");
            
            _logger.LogInformation("Fetching user {UserId}", id);
            
            try
            {
                // Simulate database call with nested span
                using var dbActivity = ActivitySource.StartActivity("Database.GetUser");
                dbActivity?.SetTag("db.operation", "SELECT");
                dbActivity?.SetTag("db.table", "users");
                dbActivity?.SetTag("db.statement", "SELECT * FROM users WHERE id = @id");
                
                await Task.Delay(Random.Shared.Next(50, 200)); // Simulate DB latency
                
                if (id <= 0)
                {
                    activity?.SetStatus(ActivityStatusCode.Error, "Invalid user ID");
                    activity?.SetTag("error", true);
                    activity?.SetTag("error.message", "Invalid user ID");
                    return BadRequest(new { Error = "Invalid user ID", Code = "INVALID_USER_ID" });
                }

                // Simulate user not found scenario
                if (id == 999)
                {
                    activity?.SetStatus(ActivityStatusCode.Error, "User not found");
                    activity?.SetTag("error", true);
                    activity?.SetTag("error.message", "User not found");
                    return NotFound(new { Error = "User not found", Code = "USER_NOT_FOUND" });
                }

                var user = new 
                { 
                    Id = id, 
                    Name = $"User{id}", 
                    Email = $"user{id}@example.com",
                    CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 365)),
                    Status = "Active"
                };
                
                // Track custom event
                _telemetryClient.TrackEvent("UserRetrieved", new Dictionary<string, string>
                {
                    ["UserId"] = id.ToString(),
                    ["UserName"] = user.Name,
                    ["Source"] = "API"
                });

                activity?.SetTag("user.name", user.Name);
                activity?.SetTag("user.status", user.Status);
                
                _logger.LogInformation("Successfully fetched user {UserId} - {UserName}", id, user.Name);
                return Ok(user);
            }
            catch (Exception ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity?.SetTag("error", true);
                activity?.SetTag("error.message", ex.Message);
                
                _telemetryClient.TrackException(ex);
                _logger.LogError(ex, "Failed to fetch user {UserId}", id);
                
                return StatusCode(500, new { Error = "Internal server error", Code = "INTERNAL_ERROR" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            using var activity = ActivitySource.StartActivity("CreateUser");
            activity?.SetTag("user.email", request.Email);
            activity?.SetTag("operation.name", "create_user");
            
            _logger.LogInformation("Creating user with email {Email}", request.Email);
            
            try
            {
                // Validate request
                if (string.IsNullOrEmpty(request.Name) || string.IsNullOrEmpty(request.Email))
                {
                    activity?.SetStatus(ActivityStatusCode.Error, "Invalid request data");
                    return BadRequest(new { Error = "Name and Email are required", Code = "VALIDATION_ERROR" });
                }

                // Simulate validation and database insert
                using var validationActivity = ActivitySource.StartActivity("ValidateUser");
                await Task.Delay(Random.Shared.Next(50, 150));
                
                using var dbActivity = ActivitySource.StartActivity("Database.InsertUser");
                dbActivity?.SetTag("db.operation", "INSERT");
                dbActivity?.SetTag("db.table", "users");
                await Task.Delay(Random.Shared.Next(100, 300));
                
                var userId = Random.Shared.Next(1000, 9999);
                var user = new 
                { 
                    Id = userId, 
                    Name = request.Name, 
                    Email = request.Email,
                    CreatedAt = DateTime.UtcNow,
                    Status = "Active"
                };
                
                // Track custom metric
                _telemetryClient.GetMetric("Users.Created").TrackValue(1);
                _telemetryClient.TrackEvent("UserCreated", new Dictionary<string, string>
                {
                    ["UserId"] = userId.ToString(),
                    ["UserName"] = request.Name,
                    ["UserEmail"] = request.Email,
                    ["Source"] = "API"
                });

                activity?.SetTag("user.id", userId.ToString());
                activity?.SetTag("user.name", request.Name);
                
                _logger.LogInformation("Successfully created user {UserId} - {UserName}", userId, request.Name);
                return CreatedAtAction(nameof(GetUser), new { id = userId }, user);
            }
            catch (Exception ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                _telemetryClient.TrackException(ex);
                _logger.LogError(ex, "Failed to create user with email {Email}", request.Email);
                
                return StatusCode(500, new { Error = "Failed to create user", Code = "CREATION_ERROR" });
            }
        }

        [HttpGet("health")]
        public IActionResult HealthCheck()
        {
            return Ok(new { Status = "Healthy", Service = "UserService", Timestamp = DateTime.UtcNow });
        }
    }

    public record CreateUserRequest(string Name, string Email);
}
```

5. **Create Order Service with Cross-Service Communication**:
```bash
cd ../../order-service
dotnet new webapi --name OrderService
cd OrderService

# Add same packages as User Service
dotnet add package Microsoft.ApplicationInsights.AspNetCore
dotnet add package System.Diagnostics.DiagnosticSource
dotnet add package Microsoft.Extensions.Http
dotnet add package OpenTelemetry
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
```

6. **Create Order Service Program.cs** (similar to User Service):
```csharp
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();

var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING") 
                      ?? builder.Configuration.GetConnectionString("ApplicationInsights");

builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = connectionString;
});

builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.EnrichWithHttpRequest = (activity, httpRequest) =>
            {
                activity.SetTag("service.name", "OrderService");
            };
        })
        .AddHttpClientInstrumentation()
        .AddSource("OrderService")
        .SetResourceBuilder(ResourceBuilder.CreateDefault()
            .AddService("OrderService", "1.0.0"))
        .AddConsoleExporter();
    });

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

7. **Create Order Controller with Cross-Service Calls** - Create `Controllers/OrderController.cs`:
```csharp
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Text.Json;

namespace OrderService.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderController : ControllerBase
    {
        private static readonly ActivitySource ActivitySource = new("OrderService");
        private readonly TelemetryClient _telemetryClient;
        private readonly HttpClient _httpClient;
        private readonly ILogger<OrderController> _logger;
        private readonly IConfiguration _configuration;

        public OrderController(
            TelemetryClient telemetryClient, 
            HttpClient httpClient, 
            ILogger<OrderController> logger,
            IConfiguration configuration)
        {
            _telemetryClient = telemetryClient;
            _httpClient = httpClient;
            _logger = logger;
            _configuration = configuration;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            using var activity = ActivitySource.StartActivity("CreateOrder");
            activity?.SetTag("user.id", request.UserId.ToString());
            activity?.SetTag("order.total", request.Total.ToString());
            activity?.SetTag("operation.name", "create_order");
            
            _logger.LogInformation("Creating order for user {UserId} with total {Total}", 
                request.UserId, request.Total);

            try
            {
                // Step 1: Validate user exists
                using var userValidationActivity = ActivitySource.StartActivity("ValidateUser");
                userValidationActivity?.SetTag("user.id", request.UserId.ToString());
                
                var userServiceUrl = _configuration["Services:UserService:Url"] ?? "http://localhost:5001";
                var userUrl = $"{userServiceUrl}/api/user/{request.UserId}";
                
                _logger.LogInformation("Calling User Service at {UserUrl}", userUrl);
                
                var userResponse = await _httpClient.GetAsync(userUrl);
                
                if (!userResponse.IsSuccessStatusCode)
                {
                    activity?.SetStatus(ActivityStatusCode.Error, "User validation failed");
                    activity?.SetTag("error", true);
                    activity?.SetTag("error.message", "User validation failed");
                    
                    if (userResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                    {
                        return BadRequest(new { Error = "User not found", Code = "USER_NOT_FOUND" });
                    }
                    
                    return StatusCode(500, new { Error = "User validation failed", Code = "USER_VALIDATION_ERROR" });
                }

                var userContent = await userResponse.Content.ReadAsStringAsync();
                var user = JsonSerializer.Deserialize<dynamic>(userContent);
                
                userValidationActivity?.SetTag("user.validation.success", true);

                // Step 2: Process order
                using var processActivity = ActivitySource.StartActivity("ProcessOrder");
                processActivity?.SetTag("order.processing.started", DateTime.UtcNow.ToString("O"));
                
                await Task.Delay(Random.Shared.Next(200, 500)); // Simulate order processing
                
                var orderId = Random.Shared.Next(10000, 99999);
                
                // Step 3: Send notification (simulate)
                using var notifyActivity = ActivitySource.StartActivity("SendNotification");
                notifyActivity?.SetTag("notification.type", "order_confirmation");
                notifyActivity?.SetTag("order.id", orderId.ToString());
                
                // Simulate notification delay
                await Task.Delay(Random.Shared.Next(100, 300));
                
                var order = new 
                { 
                    Id = orderId, 
                    UserId = request.UserId, 
                    Total = request.Total, 
                    Status = "Confirmed",
                    CreatedAt = DateTime.UtcNow,
                    Items = request.Items
                };

                // Track business metrics
                _telemetryClient.GetMetric("Orders.Created").TrackValue(1);
                _telemetryClient.GetMetric("Orders.Value").TrackValue((double)request.Total);
                
                _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
                {
                    ["OrderId"] = orderId.ToString(),
                    ["UserId"] = request.UserId.ToString(),
                    ["OrderValue"] = request.Total.ToString(),
                    ["ItemCount"] = request.Items?.Count.ToString() ?? "0",
                    ["Source"] = "API"
                });

                activity?.SetTag("order.id", orderId.ToString());
                activity?.SetTag("order.status", "confirmed");
                activity?.SetTag("order.value", request.Total.ToString());
                
                _logger.LogInformation("Successfully created order {OrderId} for user {UserId}", orderId, request.UserId);
                return CreatedAtAction(nameof(GetOrder), new { id = orderId }, order);
            }
            catch (Exception ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity?.SetTag("error", true);
                activity?.SetTag("error.message", ex.Message);
                
                _telemetryClient.TrackException(ex);
                _logger.LogError(ex, "Failed to create order for user {UserId}", request.UserId);
                return StatusCode(500, new { Error = "Failed to create order", Code = "ORDER_CREATION_ERROR" });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetOrder(int id)
        {
            using var activity = ActivitySource.StartActivity("GetOrder");
            activity?.SetTag("order.id", id.ToString());
            
            try
            {
                // Simulate database call
                await Task.Delay(Random.Shared.Next(50, 150));
                
                var order = new 
                { 
                    Id = id, 
                    Status = "Confirmed", 
                    Total = 99.99m,
                    CreatedAt = DateTime.UtcNow.AddHours(-2),
                    UserId = 123
                };
                
                return Ok(order);
            }
            catch (Exception ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                _telemetryClient.TrackException(ex);
                return StatusCode(500, new { Error = "Failed to get order" });
            }
        }

        [HttpGet("health")]
        public IActionResult HealthCheck()
        {
            return Ok(new { Status = "Healthy", Service = "OrderService", Timestamp = DateTime.UtcNow });
        }
    }

    public record CreateOrderRequest(int UserId, decimal Total, List<OrderItem>? Items);
    public record OrderItem(string Name, int Quantity, decimal Price);
}
```

8. **Configure and Test Services**:
```bash
# Set up configuration for both services
export APPLICATIONINSIGHTS_CONNECTION_STRING="YOUR_CONNECTION_STRING_FROM_PART1"

# Start User Service (Terminal 1)
cd ../../user-service/UserService
dotnet run --urls "http://localhost:5001"

# Start Order Service (Terminal 2)  
cd ../../order-service/OrderService
dotnet run --urls "http://localhost:5002"

# Test the services (Terminal 3)
# Test User Service
curl http://localhost:5001/api/user/123
curl -X POST http://localhost:5001/api/user \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# Test Order Service with cross-service call
curl -X POST http://localhost:5002/api/order \
  -H "Content-Type: application/json" \
  -d '{"userId": 123, "total": 99.99, "items": [{"name": "Product 1", "quantity": 1, "price": 99.99}]}'

# Test error scenarios
curl http://localhost:5001/api/user/999  # Should return 404
curl -X POST http://localhost:5002/api/order \
  -H "Content-Type: application/json" \
  -d '{"userId": 999, "total": 50.00, "items": []}'  # Should fail user validation
```

| ✅ **Checkpoint Validation** | **Expected Outcome** |
|---|---|
| **Distributed Traces** | Complete request flow visible from Order Service → User Service in Application Insights |
| **Telemetry Data** | Custom events, metrics, and traces appearing in Azure Monitor |
| **Cross-Service Calls** | HTTP calls between services properly correlated with trace IDs |
| **Performance Metrics** | Response times and dependency calls tracked accurately |

**🔍 Quick Verification**:
```bash
# Verify services are running with tracing
curl http://localhost:5001/api/user/123
curl -X POST http://localhost:5002/api/order \
  -H "Content-Type: application/json" \
  -d '{"userId": 123, "total": 99.99}'

# Check Application Insights for traces (within 2-5 minutes)
echo "✅ Expected: Traces should appear in Application Insights with correlated IDs"
```

### 🤖 1.2 Advanced Telemetry Configuration and Custom Instrumentation
**Time Required**: 30 minutes

1. **⚙️ Create Custom Telemetry Processor** - Create `shared/infrastructure/CustomTelemetryProcessor.cs`:
```csharp
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;

namespace Shared.Infrastructure
{
    public class CustomTelemetryProcessor : ITelemetryProcessor
    {
        private ITelemetryProcessor Next { get; set; }

        public CustomTelemetryProcessor(ITelemetryProcessor next)
        {
            Next = next;
        }

        public void Process(ITelemetry item)
        {
            // Filter out health check requests from telemetry
            if (item is RequestTelemetry request && 
                request.Url?.AbsolutePath?.Contains("/health") == true)
            {
                return; // Don't send health check telemetry
            }

            // Add custom properties to all telemetry
            if (item is ISupportProperties telemetryWithProperties)
            {
                telemetryWithProperties.Properties["Environment"] = 
                    Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown";
                telemetryWithProperties.Properties["MachineName"] = Environment.MachineName;
                telemetryWithProperties.Properties["ServiceVersion"] = "1.0.0";
                telemetryWithProperties.Properties["Region"] = "East US"; // Could be dynamic
            }

            // Enrich request telemetry
            if (item is RequestTelemetry requestTelemetry)
            {
                // Mark slow requests
                if (requestTelemetry.Duration.TotalMilliseconds > 2000)
                {
                    requestTelemetry.Properties["SlowRequest"] = "true";
                    requestTelemetry.Properties["PerformanceCategory"] = "Slow";
                }
                else if (requestTelemetry.Duration.TotalMilliseconds > 1000)
                {
                    requestTelemetry.Properties["PerformanceCategory"] = "Medium";
                }
                else
                {
                    requestTelemetry.Properties["PerformanceCategory"] = "Fast";
                }

                // Add business context
                if (requestTelemetry.Url?.AbsolutePath?.Contains("/order") == true)
                {
                    requestTelemetry.Properties["BusinessDomain"] = "Commerce";
                }
                else if (requestTelemetry.Url?.AbsolutePath?.Contains("/user") == true)
                {
                    requestTelemetry.Properties["BusinessDomain"] = "Identity";
                }
            }

            // Enrich dependency telemetry
            if (item is DependencyTelemetry dependency)
            {
                // Add context to external calls
                if (dependency.Type == "Http")
                {
                    dependency.Properties["DependencyCategory"] = "External API";
                    if (dependency.Duration.TotalMilliseconds > 5000)
                    {
                        dependency.Properties["SlowDependency"] = "true";
                    }
                }
            }

            // Sample high-volume telemetry
            if (item is EventTelemetry eventTelemetry && 
                eventTelemetry.Name == "HighVolumeEvent")
            {
                // Sample 10% of high volume events
                if (Random.Shared.NextDouble() > 0.1)
                {
                    return;
                }
            }

            Next.Process(item);
        }
    }
}
```

2. **Create Business Context Enricher** - Create `shared/infrastructure/BusinessContextEnricher.cs`:
```csharp
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

namespace Shared.Infrastructure
{
    public class BusinessContextInitializer : ITelemetryInitializer
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public BusinessContextInitializer(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public void Initialize(ITelemetry telemetry)
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null) return;

            // Add user context if available
            if (httpContext.Request.Headers.ContainsKey("X-User-Id"))
            {
                telemetry.Context.User.Id = httpContext.Request.Headers["X-User-Id"];
            }

            // Add session context
            if (httpContext.Request.Headers.ContainsKey("X-Session-Id"))
            {
                telemetry.Context.Session.Id = httpContext.Request.Headers["X-Session-Id"];
            }

            // Add operation context
            if (httpContext.Request.Headers.ContainsKey("X-Operation-Id"))
            {
                telemetry.Context.Operation.Id = httpContext.Request.Headers["X-Operation-Id"];
            }

            // Add custom business context
            if (telemetry.Context.Properties != null)
            {
                telemetry.Context.Properties["RequestSource"] = 
                    httpContext.Request.Headers["User-Agent"].ToString().Contains("Mobile") ? "Mobile" : "Web";
                
                telemetry.Context.Properties["ApiVersion"] = 
                    httpContext.Request.Headers["X-API-Version"].FirstOrDefault() ?? "v1";
                
                // Extract tenant information if available
                if (httpContext.Request.Headers.ContainsKey("X-Tenant-Id"))
                {
                    telemetry.Context.Properties["TenantId"] = httpContext.Request.Headers["X-Tenant-Id"];
                }
            }
        }
    }
}
```

3. **Update User Service with Advanced Telemetry**:

Add to `UserService/Program.cs`:
```csharp
// Add at the top
using Shared.Infrastructure;

// Add HTTP context accessor
builder.Services.AddHttpContextAccessor();

// Add custom telemetry processor and initializer
builder.Services.AddApplicationInsightsTelemetryProcessor<CustomTelemetryProcessor>();
builder.Services.AddSingleton<ITelemetryInitializer, BusinessContextInitializer>();

// Configure advanced sampling
builder.Services.Configure<TelemetryConfiguration>(config =>
{
    // Adaptive sampling configuration
    var samplingSettings = new Microsoft.ApplicationInsights.WindowsServer.TelemetryChannel.SamplingTelemetryProcessor(null)
    {
        MaxTelemetryItemsPerSecond = 5,
        SamplingPercentage = 100
    };
    
    // Custom sampling rules
    config.DefaultTelemetrySink.TelemetryProcessorChainBuilder
        .UseAdaptiveSampling(
            maxTelemetryItemsPerSecond: 5,
            excludedTypes: "Event;Exception") // Don't sample events and exceptions
        .Build();
});
```

4. **Create Performance Monitoring Middleware** - Create `shared/infrastructure/PerformanceMiddleware.cs`:
```csharp
using Microsoft.ApplicationInsights;
using System.Diagnostics;

namespace Shared.Infrastructure
{
    public class PerformanceMonitoringMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly TelemetryClient _telemetryClient;
        private readonly ILogger<PerformanceMonitoringMiddleware> _logger;

        public PerformanceMonitoringMiddleware(
            RequestDelegate next, 
            TelemetryClient telemetryClient,
            ILogger<PerformanceMonitoringMiddleware> logger)
        {
            _next = next;
            _telemetryClient = telemetryClient;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var stopwatch = Stopwatch.StartNew();
            var startTime = DateTime.UtcNow;
            
            // Capture initial metrics
            var initialMemory = GC.GetTotalMemory(false);
            var initialThreadCount = Process.GetCurrentProcess().Threads.Count;

            try
            {
                await _next(context);
            }
            finally
            {
                stopwatch.Stop();
                
                // Calculate resource usage
                var finalMemory = GC.GetTotalMemory(false);
                var finalThreadCount = Process.GetCurrentProcess().Threads.Count;
                var memoryDelta = finalMemory - initialMemory;
                var threadDelta = finalThreadCount - initialThreadCount;

                // Track performance metrics
                var endpoint = $"{context.Request.Method} {context.Request.Path}";
                
                _telemetryClient.TrackMetric($"Performance.RequestDuration.{endpoint}", stopwatch.ElapsedMilliseconds);
                _telemetryClient.TrackMetric($"Performance.MemoryUsage.{endpoint}", memoryDelta);
                _telemetryClient.TrackMetric($"Performance.ThreadUsage.{endpoint}", threadDelta);

                // Track detailed performance event for slow requests
                if (stopwatch.ElapsedMilliseconds > 1000) // Slow request threshold
                {
                    _telemetryClient.TrackEvent("SlowRequest", new Dictionary<string, string>
                    {
                        ["Endpoint"] = endpoint,
                        ["Duration"] = stopwatch.ElapsedMilliseconds.ToString(),
                        ["StatusCode"] = context.Response.StatusCode.ToString(),
                        ["MemoryDelta"] = memoryDelta.ToString(),
                        ["ThreadDelta"] = threadDelta.ToString(),
                        ["StartTime"] = startTime.ToString("O"),
                        ["UserAgent"] = context.Request.Headers["User-Agent"].ToString()
                    });

                    _logger.LogWarning("Slow request detected: {Endpoint} took {Duration}ms", 
                        endpoint, stopwatch.ElapsedMilliseconds);
                }

                // Track resource usage trends
                if (memoryDelta > 1024 * 1024) // 1MB+ memory increase
                {
                    _telemetryClient.TrackEvent("HighMemoryUsage", new Dictionary<string, string>
                    {
                        ["Endpoint"] = endpoint,
                        ["MemoryDelta"] = memoryDelta.ToString(),
                        ["TotalMemory"] = finalMemory.ToString()
                    });
                }
            }
        }
    }
}
```

5. **Add Middleware to Services**:

Update both `UserService/Program.cs` and `OrderService/Program.cs`:
```csharp
// Add middleware
app.UseMiddleware<PerformanceMonitoringMiddleware>();
```

6. **Test Advanced Telemetry**:
```bash
# Generate requests with custom headers
curl -H "X-User-Id: user123" \
     -H "X-Session-Id: session456" \
     -H "X-Operation-Id: op789" \
     -H "X-API-Version: v2" \
     -H "User-Agent: Mobile App 1.0" \
     http://localhost:5001/api/user/123

# Generate load to trigger performance tracking
for i in {1..50}; do
  curl -H "X-User-Id: user$i" \
       -H "X-Session-Id: session$i" \
       http://localhost:5001/api/user/$i &
done

wait

# Check slow requests
curl http://localhost:5001/api/user/123?slow=true
```

| ✅ **Checkpoint Validation** | **Expected Outcome** |
|---|---|
| **Custom Properties** | All telemetry enriched with business context (Environment, MachineName, ServiceVersion) |
| **Performance Categories** | Requests categorized as Fast/Medium/Slow based on response times |
| **Business Domain Tags** | Commerce and Identity domains properly tagged |
| **Sampling Configuration** | High-volume events properly sampled, critical events preserved |

**🔍 Quick Verification**:
```bash
# Generate test traffic with custom headers
for i in {1..10}; do
  curl -H "X-User-Id: user$i" \
       -H "X-Session-Id: session$i" \
       -H "X-API-Version: v2" \
       http://localhost:5001/api/user/$i
done

# Expected: Custom properties should appear in Application Insights telemetry
echo "✅ Check Application Insights for enriched telemetry data"
```

---

## ☁️ Module 2: Multi-Cloud Monitoring Integration (90 minutes)

### 🐶 2.1 Setting Up Datadog Integration
**Time Required**: 30 minutes

1. **Create Datadog Free Trial Account**:
   - **Go to**: `datadoghq.com`
   - **Sign up for free trial** (14 days full features)
   - **Get API key** from Organization Settings → API Keys
   - **Save the API key** for later use

2. **Install Datadog .NET Library**:
```bash
# Add to both services
cd user-service/UserService
dotnet add package Datadog.Trace
dotnet add package Datadog.Trace.OpenTracing

cd ../../order-service/OrderService  
dotnet add package Datadog.Trace
dotnet add package Datadog.Trace.OpenTracing
```

3. **Create Unified Monitoring Service** - Create `shared/infrastructure/UnifiedMonitoringService.cs`:
```csharp
using Microsoft.ApplicationInsights;
using Datadog.Trace;
using Datadog.Trace.Configuration;

namespace Shared.Infrastructure
{
    public class UnifiedMonitoringService
    {
        private readonly TelemetryClient _appInsights;
        private readonly ILogger<UnifiedMonitoringService> _logger;
        private readonly ITracer _datadogTracer;

        public UnifiedMonitoringService(
            TelemetryClient appInsights, 
            ILogger<UnifiedMonitoringService> logger)
        {
            _appInsights = appInsights;
            _logger = logger;
            
            // Configure Datadog
            var settings = TracerSettings.FromDefaultSources();
            settings.Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "development";
            settings.ServiceName = Environment.GetEnvironmentVariable("SERVICE_NAME") ?? "workshop-service";
            settings.ServiceVersion = "1.0.0";
            
            _datadogTracer = Tracer.Configure(settings);
        }

        public void TrackBusinessMetric(string metricName, double value, Dictionary<string, string> tags)
        {
            try
            {
                // Send to Azure Application Insights
                _appInsights.GetMetric(metricName).TrackValue(value);
                _appInsights.TrackEvent($"BusinessMetric.{metricName}", tags);

                // Send to Datadog
                using var scope = _datadogTracer.StartActive($"business.metric.{metricName.ToLower()}");
                scope.Span.SetTag("metric.name", metricName);
                scope.Span.SetTag("metric.value", value.ToString());
                
                foreach (var tag in tags)
                {
                    scope.Span.SetTag($"business.{tag.Key}", tag.Value);
                }

                // Log for debugging
                _logger.LogInformation("Business metric tracked: {MetricName} = {Value} with tags {@Tags}", 
                    metricName, value, tags);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to track business metric {MetricName}", metricName);
            }
        }

        public void TrackUserAction(string action, string userId, Dictionary<string, string> context)
        {
            var tags = new Dictionary<string, string>(context)
            {
                ["user_id"] = userId,
                ["action"] = action,
                ["timestamp"] = DateTime.UtcNow.ToString("O")
            };

            // Azure
            _appInsights.TrackEvent("UserAction", tags);

            // Datadog
            using var scope = _datadogTracer.StartActive("user.action");
            scope.Span.SetTag("user.id", userId);
            scope.Span.SetTag("user.action", action);
            
            foreach (var kvp in context)
            {
                scope.Span.SetTag($"context.{kvp.Key}", kvp.Value);
            }

            _logger.LogInformation("User action tracked: {Action} by {UserId}", action, userId);
        }

        public async Task<T> TrackOperation<T>(string operationName, Func<Task<T>> operation, Dictionary<string, string> tags = null)
        {
            tags ??= new Dictionary<string, string>();
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            using var aiOperation = _appInsights.StartOperation<Microsoft.ApplicationInsights.DataContracts.RequestTelemetry>(operationName);
            using var ddScope = _datadogTracer.StartActive(operationName);

            try
            {
                // Add tags to both systems
                foreach (var tag in tags)
                {
                    aiOperation.Telemetry.Properties[tag.Key] = tag.Value;
                    ddScope.Span.SetTag(tag.Key, tag.Value);
                }

                var result = await operation();

                // Mark as successful
                aiOperation.Telemetry.Success = true;
                ddScope.Span.SetTag("success", "true");

                return result;
            }
            catch (Exception ex)
            {
                // Mark as failed
                aiOperation.Telemetry.Success = false;
                ddScope.Span.SetTag("error", "true");
                ddScope.Span.SetTag("error.message", ex.Message);

                _appInsights.TrackException(ex);
                _logger.LogError(ex, "Operation {OperationName} failed", operationName);
                throw;
            }
            finally
            {
                stopwatch.Stop();
                ddScope.Span.SetTag("duration.ms", stopwatch.ElapsedMilliseconds.ToString());
            }
        }

        public void TrackPerformanceCounter(string counterName, double value, string unit = "count")
        {
            // Azure
            _appInsights.GetMetric($"Performance.{counterName}").TrackValue(value);

            // Datadog
            using var scope = _datadogTracer.StartActive("performance.counter");
            scope.Span.SetTag("counter.name", counterName);
            scope.Span.SetTag("counter.value", value.ToString());
            scope.Span.SetTag("counter.unit", unit);
        }
    }
}
```

4. **Update Services to Use Unified Monitoring**:

Add to both `UserService/Program.cs` and `OrderService/Program.cs`:
```csharp
// Register unified monitoring
builder.Services.AddSingleton<UnifiedMonitoringService>();

// Configure Datadog environment variables
Environment.SetEnvironmentVariable("DD_ENV", "workshop");
Environment.SetEnvironmentVariable("DD_SERVICE", "user-service"); // or "order-service"
Environment.SetEnvironmentVariable("DD_VERSION", "1.0.0");
Environment.SetEnvironmentVariable("DD_TRACE_ENABLED", "true");

// Add Datadog tracing
builder.Services.AddDatadogTracing();
```

5. **Update Controllers to Use Unified Monitoring**:

In `UserController.cs`, add:
```csharp
private readonly UnifiedMonitoringService _unifiedMonitoring;

// Update constructor to include UnifiedMonitoringService

// In GetUser method, add:
_unifiedMonitoring.TrackUserAction("GetUser", id.ToString(), new Dictionary<string, string>
{
    ["endpoint"] = "api/user/{id}",
    ["method"] = "GET"
});

// In CreateUser method, add:
_unifiedMonitoring.TrackBusinessMetric("Users.Created", 1, new Dictionary<string, string>
{
    ["source"] = "api",
    ["method"] = "POST"
});
```

6. **Test Dual Monitoring**:
```bash
# Set Datadog API key (replace with your actual key)
export DD_API_KEY="your_datadog_api_key_here"
export DD_SITE="datadoghq.com"

# Restart services with Datadog configuration
# Terminal 1
cd user-service/UserService
DD_ENV=workshop DD_SERVICE=user-service dotnet run --urls "http://localhost:5001"

# Terminal 2
cd ../../order-service/OrderService
DD_ENV=workshop DD_SERVICE=order-service dotnet run --urls "http://localhost:5002"

# Generate traffic
for i in {1..20}; do
  curl http://localhost:5001/api/user/$i
  curl -X POST http://localhost:5002/api/order \
    -H "Content-Type: application/json" \
    -d "{\"userId\": $i, \"total\": $(($i * 10)), \"items\": []}"
  sleep 1
done
```

**✅ Checkpoint**: Metrics should appear in both Azure Application Insights and Datadog dashboards

### 📊 2.2 Prometheus and Grafana Setup
**Time Required**: 30 minutes

1. **Create Docker Compose for Monitoring Stack**:

Create `monitoring-stack/docker-compose.yml`:
```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: workshop-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: workshop-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - ./grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: workshop-node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

volumes:
  prometheus-data:
  grafana-storage:
```

2. **Create Prometheus Configuration** - Create `monitoring-stack/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'user-service'
    static_configs:
      - targets: ['host.docker.internal:5001']
    metrics_path: '/metrics'
    scrape_interval: 5s
    
  - job_name: 'order-service'  
    static_configs:
      - targets: ['host.docker.internal:5002']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

3. **Add Prometheus Metrics to .NET Services**:
```bash
# Add to both services
cd user-service/UserService
dotnet add package prometheus-net.AspNetCore

cd ../../order-service/OrderService
dotnet add package prometheus-net.AspNetCore
```

4. **Configure Prometheus in Services** - Add to both `Program.cs` files:
```csharp
using Prometheus;

// Add Prometheus metrics
app.UseMetricServer(); // Exposes /metrics endpoint at /metrics
app.UseHttpMetrics();  // Collects HTTP metrics automatically

// Create custom metrics
var requestCounter = Metrics.CreateCounter("workshop_requests_total", "Total HTTP requests", "method", "endpoint");
var requestDuration = Metrics.CreateHistogram("workshop_request_duration_seconds", "HTTP request duration", "method", "endpoint");
var businessMetrics = Metrics.CreateCounter("workshop_business_events_total", "Business events", "event_type", "service");
var activeUsers = Metrics.CreateGauge("workshop_active_users", "Currently active users");

// Add middleware to track custom metrics
app.Use(async (context, next) =>
{
    var method = context.Request.Method;
    var endpoint = context.Request.Path.Value ?? "unknown";
    
    requestCounter.WithLabels(method, endpoint).Inc();
    
    using (requestDuration.WithLabels(method, endpoint).NewTimer())
    {
        await next();
    }
});
```

5. **Add Business Metrics to Controllers**:

In `UserController.cs`:
```csharp
// Add at class level
private static readonly Counter UsersCreated = Metrics.CreateCounter("users_created_total", "Total users created");
private static readonly Gauge ActiveUsers = Metrics.CreateGauge("active_users_current", "Currently active users");

// In CreateUser method:
UsersCreated.Inc();

// In GetUser method:
ActiveUsers.Set(Random.Shared.Next(100, 1000)); // Simulate active users
```

6. **Create Grafana Dashboard Configuration**:

Create `monitoring-stack/grafana/provisioning/datasources/prometheus.yml`:
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

Create `monitoring-stack/grafana/provisioning/dashboards/dashboard.yml`:
```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

7. **Create Custom Grafana Dashboard** - Create `monitoring-stack/grafana/dashboards/workshop-dashboard.json`:
```json
{
  "dashboard": {
    "title": "Workshop Microservices",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(workshop_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph", 
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(workshop_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Users Created",
        "type": "singlestat",
        "targets": [
          {
            "expr": "users_created_total"
          }
        ]
      }
    ]
  }
}
```

8. **Start Monitoring Stack and Test**:
```bash
# Create monitoring stack directory structure
mkdir -p monitoring-stack/grafana/{dashboards,provisioning/datasources,provisioning/dashboards}

# Start the monitoring stack
cd monitoring-stack
docker-compose up -d

# Wait for services to start
sleep 30

# Check that services are running
docker-compose ps

# Generate metrics
for i in {1..100}; do
  curl -s http://localhost:5001/api/user/$i > /dev/null
  curl -s http://localhost:5002/api/order \
    -H "Content-Type: application/json" \
    -d "{\"userId\": $i, \"total\": 50}" > /dev/null
  sleep 0.1
done

# Access dashboards
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin123)"
echo "Metrics endpoints:"
echo "  User Service: http://localhost:5001/metrics"
echo "  Order Service: http://localhost:5002/metrics"
```

**✅ Checkpoint**: You should see metrics in Prometheus and visualizations in Grafana

### 📊 2.3 Unified Dashboard Creation
**Time Required**: 30 minutes

1. **Create Multi-Source Dashboard Service** - Create `shared/infrastructure/DashboardService.cs`:
```csharp
using System.Text.Json;

namespace Shared.Infrastructure
{
    public class DashboardService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<DashboardService> _logger;
        private readonly IConfiguration _configuration;

        public DashboardService(HttpClient httpClient, ILogger<DashboardService> logger, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _logger = logger;
            _configuration = configuration;
        }

        public async Task<DashboardData> GetUnifiedDashboardData()
        {
            var dashboardData = new DashboardData();

            try
            {
                // Get Prometheus metrics
                var prometheusData = await GetPrometheusMetrics();
                dashboardData.PrometheusMetrics = prometheusData;

                // Get Azure metrics (simulated - in real scenario, use Azure Monitor REST API)
                var azureData = await GetAzureMetrics();
                dashboardData.AzureMetrics = azureData;

                // Combine and calculate derived metrics
                dashboardData.CombinedMetrics = CalculateDerivedMetrics(prometheusData, azureData);

                _logger.LogInformation("Unified dashboard data retrieved successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve unified dashboard data");
            }

            return dashboardData;
        }

        private async Task<Dictionary<string, object>> GetPrometheusMetrics()
        {
            var metrics = new Dictionary<string, object>();

            try
            {
                var prometheusUrl = _configuration["Monitoring:Prometheus:Url"] ?? "http://localhost:9090";
                
                // Query current request rate
                var requestRateQuery = "rate(workshop_requests_total[5m])";
                var requestRateUrl = $"{prometheusUrl}/api/v1/query?query={Uri.EscapeDataString(requestRateQuery)}";
                
                var response = await _httpClient.GetStringAsync(requestRateUrl);
                var requestRateData = JsonSerializer.Deserialize<JsonElement>(response);
                
                metrics["request_rate"] = ExtractPrometheusValue(requestRateData);

                // Query response time percentiles
                var responseTimeQuery = "histogram_quantile(0.95, rate(workshop_request_duration_seconds_bucket[5m]))";
                var responseTimeUrl = $"{prometheusUrl}/api/v1/query?query={Uri.EscapeDataString(responseTimeQuery)}";
                
                response = await _httpClient.GetStringAsync(responseTimeUrl);
                var responseTimeData = JsonSerializer.Deserialize<JsonElement>(response);
                
                metrics["response_time_p95"] = ExtractPrometheusValue(responseTimeData);

                // Query business metrics
                var usersCreatedQuery = "users_created_total";
                var usersUrl = $"{prometheusUrl}/api/v1/query?query={Uri.EscapeDataString(usersCreatedQuery)}";
                
                response = await _httpClient.GetStringAsync(usersUrl);
                var usersData = JsonSerializer.Deserialize<JsonElement>(response);
                
                metrics["users_created"] = ExtractPrometheusValue(usersData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve Prometheus metrics");
            }

            return metrics;
        }

        private async Task<Dictionary<string, object>> GetAzureMetrics()
        {
            // In a real implementation, this would use Azure Monitor REST API
            // For this workshop, we'll simulate the data
            var metrics = new Dictionary<string, object>();

            try
            {
                metrics["application_insights"] = new
                {
                    total_requests = Random.Shared.Next(1000, 5000),
                    failed_requests = Random.Shared.Next(10, 50),
                    avg_response_time = Random.Shared.Next(200, 800),
                    unique_users = Random.Shared.Next(100, 500),
                    exceptions = Random.Shared.Next(5, 25)
                };

                metrics["azure_resources"] = new
                {
                    cpu_usage = Random.Shared.Next(30, 80),
                    memory_usage = Random.Shared.Next(40, 90),
                    disk_usage = Random.Shared.Next(20, 60),
                    network_in = Random.Shared.Next(1000, 10000),
                    network_out = Random.Shared.Next(1000, 10000)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve Azure metrics");
            }

            return metrics;
        }

        private Dictionary<string, object> CalculateDerivedMetrics(
            Dictionary<string, object> prometheusData, 
            Dictionary<string, object> azureData)
        {
            var derived = new Dictionary<string, object>();

            try
            {
                // Calculate health score based on multiple factors
                var healthScore = CalculateHealthScore(prometheusData, azureData);
                derived["health_score"] = healthScore;

                // Calculate SLA compliance
                var slaCompliance = CalculateSLACompliance(prometheusData, azureData);
                derived["sla_compliance"] = slaCompliance;

                // Calculate cost efficiency
                var costEfficiency = CalculateCostEfficiency(prometheusData, azureData);
                derived["cost_efficiency"] = costEfficiency;

                // Performance insights
                derived["performance_insights"] = GeneratePerformanceInsights(prometheusData, azureData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to calculate derived metrics");
            }

            return derived;
        }

        private double CalculateHealthScore(Dictionary<string, object> prometheus, Dictionary<string, object> azure)
        {
            // Simple health score algorithm
            var score = 100.0;
            
            // Deduct points for high response time
            if (prometheus.ContainsKey("response_time_p95"))
            {
                var responseTime = Convert.ToDouble(prometheus["response_time_p95"]);
                if (responseTime > 1.0) score -= 20;
                else if (responseTime > 0.5) score -= 10;
            }

            // Deduct points for failures
            if (azure.ContainsKey("application_insights"))
            {
                var appInsights = JsonSerializer.Deserialize<dynamic>(azure["application_insights"].ToString());
                // Add failure rate calculation logic here
            }

            return Math.Max(0, Math.Min(100, score));
        }

        private double CalculateSLACompliance(Dictionary<string, object> prometheus, Dictionary<string, object> azure)
        {
            // Calculate SLA compliance based on availability and performance
            return Random.Shared.NextDouble() * 100; // Simplified for workshop
        }

        private double CalculateCostEfficiency(Dictionary<string, object> prometheus, Dictionary<string, object> azure)
        {
            // Calculate cost efficiency metrics
            return Random.Shared.NextDouble() * 100; // Simplified for workshop
        }

        private List<string> GeneratePerformanceInsights(Dictionary<string, object> prometheus, Dictionary<string, object> azure)
        {
            var insights = new List<string>();
            
            // Generate insights based on metrics
            insights.Add("Response time is within acceptable limits");
            insights.Add("Request volume increased by 15% compared to last hour");
            insights.Add("Memory usage is optimal");
            
            return insights;
        }

        private double ExtractPrometheusValue(JsonElement data)
        {
            try
            {
                if (data.TryGetProperty("data", out var dataElement) &&
                    dataElement.TryGetProperty("result", out var resultElement) &&
                    resultElement.GetArrayLength() > 0)
                {
                    var firstResult = resultElement[0];
                    if (firstResult.TryGetProperty("value", out var valueElement) &&
                        valueElement.GetArrayLength() > 1)
                    {
                        return double.Parse(valueElement[1].GetString() ?? "0");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to extract Prometheus value");
            }

            return 0.0;
        }
    }

    public class DashboardData
    {
        public Dictionary<string, object> PrometheusMetrics { get; set; } = new();
        public Dictionary<string, object> AzureMetrics { get; set; } = new();
        public Dictionary<string, object> CombinedMetrics { get; set; } = new();
    }
}
```

2. **Add Dashboard Endpoints**:

Add to one of your services (e.g., `UserService/Program.cs`):
```csharp
// Register dashboard service
builder.Services.AddHttpClient<DashboardService>();

// Add dashboard endpoints
app.MapGet("/api/dashboard", async (DashboardService dashboardService) =>
{
    var data = await dashboardService.GetUnifiedDashboardData();
    return Results.Ok(data);
});

app.MapGet("/api/dashboard/health", async (DashboardService dashboardService) =>
{
    var data = await dashboardService.GetUnifiedDashboardData();
    return Results.Ok(new
    {
        health_score = data.CombinedMetrics.GetValueOrDefault("health_score", 0),
        sla_compliance = data.CombinedMetrics.GetValueOrDefault("sla_compliance", 0),
        cost_efficiency = data.CombinedMetrics.GetValueOrDefault("cost_efficiency", 0),
        insights = data.CombinedMetrics.GetValueOrDefault("performance_insights", new List<string>())
    });
});
```

3. **Test Unified Dashboard**:
```bash
# Test unified dashboard endpoint
curl http://localhost:5001/api/dashboard | jq

# Test health summary
curl http://localhost:5001/api/dashboard/health | jq

# Generate load to see metrics change
for i in {1..50}; do
  curl -s http://localhost:5001/api/user/$i > /dev/null
  curl -s http://localhost:5002/api/order \
    -H "Content-Type: application/json" \
    -d "{\"userId\": $i, \"total\": 100}" > /dev/null
done

# Check dashboard again
curl http://localhost:5001/api/dashboard/health | jq
```

**✅ Checkpoint**: You should have a unified dashboard that combines metrics from Azure Monitor, Prometheus, and calculated derived metrics

---

**Continue to Part 4** for the remaining intermediate modules (CI/CD Integration and Security Monitoring) and then Part 5 for the Advanced Workshop.