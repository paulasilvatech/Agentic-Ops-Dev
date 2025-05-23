using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using OpenTelemetry.Trace;

namespace OrderService;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add OpenTelemetry
        builder.Services.AddOpenTelemetry()
            .WithTracing(tracerProviderBuilder =>
            {
                tracerProviderBuilder
                    .AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddJaegerExporter();
            });

        builder.Services.AddControllers();
        builder.Services.AddHttpClient();
        builder.Services.AddHealthChecks();

        var app = builder.Build();

        app.MapHealthChecks("/health");
        app.UseRouting();
        app.MapControllers();

        app.Run();
    }
}

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private static readonly ActivitySource ActivitySource = new("OrderService");
    private static readonly Meter Meter = new("OrderService");
    private static readonly Counter<int> RequestCounter = Meter.CreateCounter<int>("order_requests_total");
    private static readonly Histogram<double> RequestDuration = Meter.CreateHistogram<double>("order_request_duration_seconds");
    private static readonly Counter<int> OrdersCreated = Meter.CreateCounter<int>("orders_created_total");
    private static readonly Histogram<double> OrderValue = Meter.CreateHistogram<double>("order_value_dollars");

    private readonly HttpClient _httpClient;
    private readonly ILogger<OrdersController> _logger;

    // Simulated in-memory data store
    private static readonly List<Order> Orders = new()
    {
        new Order { Id = 1, UserId = 1, Product = "Laptop", Amount = 999.99m, Status = "Completed", CreatedAt = DateTime.UtcNow.AddDays(-5) },
        new Order { Id = 2, UserId = 1, Product = "Mouse", Amount = 29.99m, Status = "Completed", CreatedAt = DateTime.UtcNow.AddDays(-3) },
        new Order { Id = 3, UserId = 2, Product = "Keyboard", Amount = 79.99m, Status = "Processing", CreatedAt = DateTime.UtcNow.AddDays(-1) },
        new Order { Id = 4, UserId = 2, Product = "Monitor", Amount = 299.99m, Status = "Shipped", CreatedAt = DateTime.UtcNow.AddHours(-12) }
    };

    public OrdersController(HttpClient httpClient, ILogger<OrdersController> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetOrders()
    {
        using var activity = ActivitySource.StartActivity("GetOrders");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching all orders");
            
            activity?.SetTag("operation", "get_orders");
            activity?.SetTag("order.count", Orders.Count.ToString());

            RequestCounter.Add(1, new("endpoint", "get_orders"), new("method", "GET"));

            // Simulate database query
            await Task.Delay(Random.Shared.Next(10, 100));

            _logger.LogInformation("Successfully fetched {OrderCount} orders", Orders.Count);
            return Ok(Orders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching orders");
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_orders"));
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetOrder(int id)
    {
        using var activity = ActivitySource.StartActivity("GetOrder");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching order with ID: {OrderId}", id);
            
            activity?.SetTag("operation", "get_order");
            activity?.SetTag("order.id", id.ToString());

            RequestCounter.Add(1, new("endpoint", "get_order"), new("method", "GET"));

            // Simulate database lookup
            await Task.Delay(Random.Shared.Next(5, 50));

            var order = Orders.FirstOrDefault(o => o.Id == id);
            if (order == null)
            {
                _logger.LogWarning("Order not found: {OrderId}", id);
                return NotFound();
            }

            activity?.SetTag("order.status", order.Status);
            activity?.SetTag("order.amount", order.Amount.ToString());

            _logger.LogInformation("Successfully fetched order: {OrderId}", id);
            return Ok(order);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching order {OrderId}", id);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_order"));
        }
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetOrdersByUser(int userId)
    {
        using var activity = ActivitySource.StartActivity("GetOrdersByUser");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching orders for user: {UserId}", userId);
            
            activity?.SetTag("operation", "get_orders_by_user");
            activity?.SetTag("user.id", userId.ToString());

            RequestCounter.Add(1, new("endpoint", "get_orders_by_user"), new("method", "GET"));

            // Simulate database query
            await Task.Delay(Random.Shared.Next(10, 80));

            var userOrders = Orders.Where(o => o.UserId == userId).ToList();
            
            activity?.SetTag("order.count", userOrders.Count.ToString());

            _logger.LogInformation("Successfully fetched {OrderCount} orders for user: {UserId}", userOrders.Count, userId);
            return Ok(userOrders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching orders for user {UserId}", userId);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_orders_by_user"));
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        using var activity = ActivitySource.StartActivity("CreateOrder");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Creating new order for user: {UserId}", request.UserId);
            
            activity?.SetTag("operation", "create_order");
            activity?.SetTag("user.id", request.UserId.ToString());
            activity?.SetTag("order.product", request.Product);
            activity?.SetTag("order.amount", request.Amount.ToString());

            RequestCounter.Add(1, new("endpoint", "create_order"), new("method", "POST"));

            // Validate request
            if (request.UserId <= 0 || string.IsNullOrEmpty(request.Product) || request.Amount <= 0)
            {
                _logger.LogWarning("Invalid order creation request");
                return BadRequest("Valid UserId, Product, and Amount are required");
            }

            // Validate user exists by calling User Service
            var userServiceUrl = Environment.GetEnvironmentVariable("USER_SERVICE_URL") ?? "http://user-service";
            var userResponse = await _httpClient.GetAsync($"{userServiceUrl}/api/users/{request.UserId}");
            
            if (!userResponse.IsSuccessStatusCode)
            {
                _logger.LogWarning("User not found: {UserId}", request.UserId);
                return BadRequest("User not found");
            }

            // Simulate order processing
            await Task.Delay(Random.Shared.Next(50, 200));

            var newOrder = new Order
            {
                Id = Orders.Max(o => o.Id) + 1,
                UserId = request.UserId,
                Product = request.Product,
                Amount = request.Amount,
                Status = "Processing",
                CreatedAt = DateTime.UtcNow
            };

            Orders.Add(newOrder);

            // Record business metrics
            OrdersCreated.Add(1, new("product", request.Product), new("status", "created"));
            OrderValue.Record((double)request.Amount, new("product", request.Product));

            _logger.LogInformation("Successfully created order: {OrderId}", newOrder.Id);
            return CreatedAtAction(nameof(GetOrder), new { id = newOrder.Id }, newOrder);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order");
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "create_order"));
        }
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusRequest request)
    {
        using var activity = ActivitySource.StartActivity("UpdateOrderStatus");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Updating status for order: {OrderId} to {Status}", id, request.Status);
            
            activity?.SetTag("operation", "update_order_status");
            activity?.SetTag("order.id", id.ToString());
            activity?.SetTag("order.new_status", request.Status);

            RequestCounter.Add(1, new("endpoint", "update_order_status"), new("method", "PUT"));

            // Simulate database update
            await Task.Delay(Random.Shared.Next(20, 100));

            var order = Orders.FirstOrDefault(o => o.Id == id);
            if (order == null)
            {
                _logger.LogWarning("Order not found: {OrderId}", id);
                return NotFound();
            }

            var oldStatus = order.Status;
            order.Status = request.Status;

            _logger.LogInformation("Successfully updated order {OrderId} status from {OldStatus} to {NewStatus}", id, oldStatus, request.Status);
            return Ok(order);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order status {OrderId}", id);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "update_order_status"));
        }
    }
}

public class Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Product { get; set; } = "";
    public decimal Amount { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

public class CreateOrderRequest
{
    public int UserId { get; set; }
    public string Product { get; set; } = "";
    public decimal Amount { get; set; }
}

public class UpdateOrderStatusRequest
{
    public string Status { get; set; } = "";
}