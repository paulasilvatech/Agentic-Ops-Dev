using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using OpenTelemetry;
using OpenTelemetry.Trace;
using OpenTelemetry.Metrics;

var builder = WebApplication.CreateBuilder(args);

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy())
    .AddCheck("database", () => HealthCheckResult.Healthy("Database is healthy"))
    .AddCheck("external-service", () => HealthCheckResult.Healthy("External service is healthy"));

// Add OpenTelemetry
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddJaegerExporter();
    })
    .WithMetrics(metricsProviderBuilder =>
    {
        metricsProviderBuilder
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddPrometheusExporter();
    });

// Add controllers
builder.Services.AddControllers();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Add health check endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");
app.MapHealthChecks("/health/live");

// Add Prometheus metrics endpoint
app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Custom metrics
var meter = new Meter("ObservabilityWorkshop.Sample");
var requestCounter = meter.CreateCounter<int>("http_requests_total", "Total number of HTTP requests");
var responseTimeHistogram = meter.CreateHistogram<double>("http_request_duration_seconds", "HTTP request duration in seconds");
var activeConnections = meter.CreateUpDownCounter<int>("active_connections", "Number of active connections");
var businessMetrics = meter.CreateCounter<int>("business_operations_total", "Total number of business operations");

// Middleware for custom metrics
app.Use(async (context, next) =>
{
    var stopwatch = Stopwatch.StartNew();
    var method = context.Request.Method;
    var path = context.Request.Path;
    
    activeConnections.Add(1);
    
    try
    {
        await next();
        
        var statusCode = context.Response.StatusCode.ToString();
        requestCounter.Add(1, new("method", method), new("status", statusCode), new("path", path));
        responseTimeHistogram.Record(stopwatch.Elapsed.TotalSeconds, new("method", method), new("status", statusCode));
    }
    finally
    {
        activeConnections.Add(-1);
        stopwatch.Stop();
    }
});

// Sample endpoints
app.MapGet("/", () => "Azure Observability Workshop - Sample Application");

app.MapGet("/api/users", () =>
{
    businessMetrics.Add(1, new("operation", "get_users"));
    return Results.Ok(new[] { 
        new { Id = 1, Name = "John Doe", Email = "john@example.com" },
        new { Id = 2, Name = "Jane Smith", Email = "jane@example.com" }
    });
});

app.MapGet("/api/users/{id:int}", (int id) =>
{
    businessMetrics.Add(1, new("operation", "get_user"));
    return Results.Ok(new { Id = id, Name = $"User {id}", Email = $"user{id}@example.com" });
});

app.MapPost("/api/users", (object user) =>
{
    businessMetrics.Add(1, new("operation", "create_user"));
    return Results.Created("/api/users/3", new { Id = 3, Name = "New User", Email = "new@example.com" });
});

app.MapGet("/api/orders", () =>
{
    businessMetrics.Add(1, new("operation", "get_orders"));
    return Results.Ok(new[] { 
        new { Id = 1, UserId = 1, Product = "Laptop", Amount = 999.99 },
        new { Id = 2, UserId = 2, Product = "Mouse", Amount = 29.99 }
    });
});

app.MapGet("/api/simulate-error", () =>
{
    businessMetrics.Add(1, new("operation", "simulate_error"));
    throw new Exception("Simulated error for testing purposes");
});

app.MapGet("/api/simulate-delay", async () =>
{
    businessMetrics.Add(1, new("operation", "simulate_delay"));
    var delay = Random.Shared.Next(100, 2000);
    await Task.Delay(delay);
    return Results.Ok(new { Message = "Delayed response", DelayMs = delay });
});

app.MapGet("/api/database-operation", async () =>
{
    businessMetrics.Add(1, new("operation", "database_query"));
    // Simulate database operation
    await Task.Delay(Random.Shared.Next(10, 100));
    return Results.Ok(new { Message = "Database operation completed", Timestamp = DateTime.UtcNow });
});

app.MapGet("/api/external-call", async (HttpClient httpClient) =>
{
    businessMetrics.Add(1, new("operation", "external_call"));
    try
    {
        // Simulate external API call
        var response = await httpClient.GetAsync("https://httpbin.org/delay/1");
        return Results.Ok(new { Message = "External call completed", StatusCode = response.StatusCode });
    }
    catch (Exception ex)
    {
        return Results.Problem($"External call failed: {ex.Message}");
    }
});

// Add HTTP client for external calls
builder.Services.AddHttpClient();

app.Run();