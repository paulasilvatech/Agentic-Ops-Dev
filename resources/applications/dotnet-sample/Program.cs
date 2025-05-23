using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Exporter;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Instrumentation.Http;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Prometheus;
using Serilog;
using Serilog.Events;
using Serilog.Sinks.ApplicationInsights.TelemetryConverters;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog for structured logging
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithProcessId()
    .Enrich.WithThreadId()
    .Enrich.WithProperty("Application", "ObservabilityWorkshop")
    .Enrich.WithProperty("Environment", builder.Environment.EnvironmentName)
    .WriteTo.Console(outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz}] [{Level:u3}] [{SourceContext}] [{CorrelationId}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.ApplicationInsights(
        builder.Configuration["ApplicationInsights:ConnectionString"] ?? "",
        new TraceTelemetryConverter())
    .WriteTo.File("logs/app-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// Add services
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy())
    .AddCheck<DatabaseHealthCheck>("database")
    .AddCheck<ExternalServiceHealthCheck>("external-service");

builder.Services.AddHttpClient();
builder.Services.AddSingleton<MetricsService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IUserService, UserService>();

// Configure OpenTelemetry
var serviceName = "dotnet-sample-app";
var serviceVersion = "1.0.0";

builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(serviceName, serviceVersion)
        .AddAttributes(new Dictionary<string, object>
        {
            ["cloud.provider"] = Environment.GetEnvironmentVariable("CLOUD_PROVIDER") ?? "azure",
            ["deployment.environment"] = builder.Environment.EnvironmentName,
            ["host.name"] = Environment.MachineName
        }))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.Filter = (httpContext) => !httpContext.Request.Path.Value?.Contains("health") ?? true;
        })
        .AddHttpClientInstrumentation(options =>
        {
            options.RecordException = true;
        })
        .AddSource("ObservabilityWorkshop")
        .AddConsoleExporter()
        .AddOtlpExporter(options =>
        {
            options.Endpoint = new Uri(Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT") ?? "http://localhost:4317");
        })
        .AddJaegerExporter(options =>
        {
            options.AgentHost = Environment.GetEnvironmentVariable("JAEGER_AGENT_HOST") ?? "localhost";
            options.AgentPort = int.Parse(Environment.GetEnvironmentVariable("JAEGER_AGENT_PORT") ?? "6831");
        }))
    .WithMetrics(metrics => metrics
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddProcessInstrumentation()
        .AddMeter("ObservabilityWorkshop")
        .AddPrometheusExporter());

// Configure Datadog APM if enabled
if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("DD_AGENT_HOST")))
{
    builder.Services.AddSingleton<IStartupFilter>(new DatadogStartupFilter());
}

var app = builder.Build();

// Configure middleware pipeline
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<ErrorHandlingMiddleware>();

// Health checks
app.MapHealthChecks("/health");
app.MapHealthChecks("/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

// Prometheus metrics endpoint
app.UseOpenTelemetryPrometheusScrapingEndpoint();

// API Endpoints
app.MapGet("/", () => new { 
    message = "Welcome to Observability Workshop", 
    version = serviceVersion,
    environment = app.Environment.EnvironmentName 
});

app.MapGet("/api/users", async (IUserService userService, ILogger<Program> logger) =>
{
    using var activity = Activity.Current?.Source.StartActivity("GetUsers");
    try
    {
        logger.LogInformation("Fetching all users");
        var users = await userService.GetAllUsersAsync();
        activity?.SetTag("user.count", users.Count());
        return Results.Ok(users);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error fetching users");
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        throw;
    }
});

app.MapGet("/api/users/{id}", async (int id, IUserService userService, ILogger<Program> logger) =>
{
    using var activity = Activity.Current?.Source.StartActivity("GetUserById");
    activity?.SetTag("user.id", id);
    
    try
    {
        logger.LogInformation("Fetching user {UserId}", id);
        var user = await userService.GetUserByIdAsync(id);
        if (user == null)
        {
            logger.LogWarning("User {UserId} not found", id);
            return Results.NotFound();
        }
        return Results.Ok(user);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error fetching user {UserId}", id);
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        throw;
    }
});

app.MapPost("/api/orders", async (OrderRequest request, IOrderService orderService, ILogger<Program> logger) =>
{
    using var activity = Activity.Current?.Source.StartActivity("CreateOrder");
    activity?.SetTag("order.user_id", request.UserId);
    activity?.SetTag("order.items_count", request.Items.Count);
    
    try
    {
        logger.LogInformation("Creating order for user {UserId}", request.UserId);
        var order = await orderService.CreateOrderAsync(request);
        
        // Custom metrics
        var metricsService = app.Services.GetRequiredService<MetricsService>();
        metricsService.RecordOrderCreated(order.Total);
        
        activity?.SetTag("order.id", order.Id);
        activity?.SetTag("order.total", order.Total);
        
        return Results.Created($"/api/orders/{order.Id}", order);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error creating order for user {UserId}", request.UserId);
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        throw;
    }
});

app.MapGet("/api/orders/{id}", async (int id, IOrderService orderService, ILogger<Program> logger) =>
{
    using var activity = Activity.Current?.Source.StartActivity("GetOrderById");
    activity?.SetTag("order.id", id);
    
    try
    {
        logger.LogInformation("Fetching order {OrderId}", id);
        var order = await orderService.GetOrderByIdAsync(id);
        if (order == null)
        {
            logger.LogWarning("Order {OrderId} not found", id);
            return Results.NotFound();
        }
        return Results.Ok(order);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error fetching order {OrderId}", id);
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        throw;
    }
});

// Chaos endpoint for testing
app.MapGet("/chaos/error", (ILogger<Program> logger) =>
{
    logger.LogWarning("Chaos endpoint triggered - throwing error");
    throw new InvalidOperationException("Chaos engineering test error");
});

app.MapGet("/chaos/slow", async (ILogger<Program> logger) =>
{
    var delay = Random.Shared.Next(1000, 5000);
    logger.LogWarning("Chaos endpoint triggered - slow response {Delay}ms", delay);
    await Task.Delay(delay);
    return new { message = "Slow response completed", delay };
});

app.Run();

// Middleware classes
public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CorrelationIdMiddleware> _logger;

    public CorrelationIdMiddleware(RequestDelegate next, ILogger<CorrelationIdMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault() ?? Guid.NewGuid().ToString();
        context.Items["CorrelationId"] = correlationId;
        context.Response.Headers.Add("X-Correlation-ID", correlationId);
        
        using (_logger.BeginScope(new Dictionary<string, object> { ["CorrelationId"] = correlationId }))
        {
            await _next(context);
        }
    }
}

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        
        _logger.LogInformation("Request started {Method} {Path}", 
            context.Request.Method, 
            context.Request.Path);

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            _logger.LogInformation("Request completed {Method} {Path} {StatusCode} in {Duration}ms",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode,
                stopwatch.ElapsedMilliseconds);
        }
    }
}

public class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorHandlingMiddleware> _logger;
    private readonly MetricsService _metrics;

    public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger, MetricsService metrics)
    {
        _next = next;
        _logger = logger;
        _metrics = metrics;
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
            _metrics.RecordError(ex.GetType().Name);
            
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new
            {
                error = "An error occurred processing your request",
                correlationId = context.Items["CorrelationId"]?.ToString(),
                timestamp = DateTime.UtcNow
            });
        }
    }
}

// Services
public interface IUserService
{
    Task<IEnumerable<User>> GetAllUsersAsync();
    Task<User?> GetUserByIdAsync(int id);
}

public interface IOrderService
{
    Task<Order> CreateOrderAsync(OrderRequest request);
    Task<Order?> GetOrderByIdAsync(int id);
}

public class UserService : IUserService
{
    private readonly ILogger<UserService> _logger;
    private readonly HttpClient _httpClient;
    private static readonly ActivitySource ActivitySource = new("ObservabilityWorkshop");

    public UserService(ILogger<UserService> logger, HttpClient httpClient)
    {
        _logger = logger;
        _httpClient = httpClient;
    }

    public async Task<IEnumerable<User>> GetAllUsersAsync()
    {
        using var activity = ActivitySource.StartActivity("UserService.GetAllUsers");
        
        // Simulate database call
        await Task.Delay(50);
        
        return new List<User>
        {
            new User { Id = 1, Name = "John Doe", Email = "john@example.com" },
            new User { Id = 2, Name = "Jane Smith", Email = "jane@example.com" }
        };
    }

    public async Task<User?> GetUserByIdAsync(int id)
    {
        using var activity = ActivitySource.StartActivity("UserService.GetUserById");
        activity?.SetTag("user.id", id);
        
        // Simulate database call
        await Task.Delay(30);
        
        if (id == 1)
            return new User { Id = 1, Name = "John Doe", Email = "john@example.com" };
        if (id == 2)
            return new User { Id = 2, Name = "Jane Smith", Email = "jane@example.com" };
            
        return null;
    }
}

public class OrderService : IOrderService
{
    private readonly ILogger<OrderService> _logger;
    private readonly IUserService _userService;
    private static readonly ActivitySource ActivitySource = new("ObservabilityWorkshop");
    private static int _orderIdCounter = 1000;

    public OrderService(ILogger<OrderService> logger, IUserService userService)
    {
        _logger = logger;
        _userService = userService;
    }

    public async Task<Order> CreateOrderAsync(OrderRequest request)
    {
        using var activity = ActivitySource.StartActivity("OrderService.CreateOrder");
        
        // Validate user exists
        var user = await _userService.GetUserByIdAsync(request.UserId);
        if (user == null)
        {
            throw new InvalidOperationException($"User {request.UserId} not found");
        }
        
        // Calculate total
        var total = request.Items.Sum(i => i.Quantity * i.Price);
        
        // Simulate database insert
        await Task.Delay(100);
        
        var order = new Order
        {
            Id = Interlocked.Increment(ref _orderIdCounter),
            UserId = request.UserId,
            Items = request.Items,
            Total = total,
            CreatedAt = DateTime.UtcNow,
            Status = "Created"
        };
        
        _logger.LogInformation("Order {OrderId} created for user {UserId} with total {Total}",
            order.Id, order.UserId, order.Total);
            
        return order;
    }

    public async Task<Order?> GetOrderByIdAsync(int id)
    {
        using var activity = ActivitySource.StartActivity("OrderService.GetOrderById");
        activity?.SetTag("order.id", id);
        
        // Simulate database query
        await Task.Delay(50);
        
        // Return dummy data for demo
        if (id >= 1000 && id <= _orderIdCounter)
        {
            return new Order
            {
                Id = id,
                UserId = 1,
                Items = new List<OrderItem>
                {
                    new OrderItem { ProductId = 1, ProductName = "Sample Product", Quantity = 1, Price = 99.99m }
                },
                Total = 99.99m,
                CreatedAt = DateTime.UtcNow.AddMinutes(-30),
                Status = "Completed"
            };
        }
        
        return null;
    }
}

// Metrics Service
public class MetricsService
{
    private readonly Counter _ordersCreated = Metrics.CreateCounter("orders_created_total", "Total number of orders created");
    private readonly Histogram _orderValue = Metrics.CreateHistogram("order_value_dollars", "Order value in dollars");
    private readonly Counter _errors = Metrics.CreateCounter("application_errors_total", "Total number of application errors", "error_type");
    
    public void RecordOrderCreated(decimal value)
    {
        _ordersCreated.Inc();
        _orderValue.Observe((double)value);
    }
    
    public void RecordError(string errorType)
    {
        _errors.WithLabels(errorType).Inc();
    }
}

// Health Checks
public class DatabaseHealthCheck : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        // Simulate database connectivity check
        await Task.Delay(10, cancellationToken);
        
        // Randomly fail 5% of the time for demo purposes
        if (Random.Shared.Next(100) < 5)
        {
            return HealthCheckResult.Unhealthy("Database connection failed");
        }
        
        return HealthCheckResult.Healthy("Database is accessible");
    }
}

public class ExternalServiceHealthCheck : IHealthCheck
{
    private readonly HttpClient _httpClient;
    
    public ExternalServiceHealthCheck(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }
    
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            // Check external service (example)
            var response = await _httpClient.GetAsync("https://api.example.com/health", cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return HealthCheckResult.Healthy("External service is accessible");
            }
            
            return HealthCheckResult.Degraded($"External service returned {response.StatusCode}");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("External service is not accessible", ex);
        }
    }
}

// Datadog APM Integration
public class DatadogStartupFilter : IStartupFilter
{
    public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next)
    {
        return builder =>
        {
            // Configure Datadog APM middleware
            builder.Use(async (context, nextMiddleware) =>
            {
                // Add Datadog trace headers
                if (Activity.Current != null)
                {
                    context.Response.Headers.Add("X-Datadog-Trace-Id", Activity.Current.TraceId.ToString());
                    context.Response.Headers.Add("X-Datadog-Parent-Id", Activity.Current.ParentSpanId.ToString());
                }
                
                await nextMiddleware();
            });
            
            next(builder);
        };
    }
}

// Models
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
}

public class OrderRequest
{
    public int UserId { get; set; }
    public List<OrderItem> Items { get; set; } = new();
}

public class Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    public decimal Total { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Status { get; set; } = "";
}

public class OrderItem
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = "";
    public int Quantity { get; set; }
    public decimal Price { get; set; }
}