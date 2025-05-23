using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using OpenTelemetry.Trace;

namespace UserService;

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
public class UsersController : ControllerBase
{
    private static readonly ActivitySource ActivitySource = new("UserService");
    private static readonly Meter Meter = new("UserService");
    private static readonly Counter<int> RequestCounter = Meter.CreateCounter<int>("user_requests_total");
    private static readonly Histogram<double> RequestDuration = Meter.CreateHistogram<double>("user_request_duration_seconds");

    private readonly HttpClient _httpClient;
    private readonly ILogger<UsersController> _logger;

    public UsersController(HttpClient httpClient, ILogger<UsersController> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers()
    {
        using var activity = ActivitySource.StartActivity("GetUsers");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching all users");
            
            activity?.SetTag("operation", "get_users");
            activity?.SetTag("user.count", "2");

            RequestCounter.Add(1, new("endpoint", "get_users"), new("method", "GET"));

            var users = new[]
            {
                new { Id = 1, Name = "John Doe", Email = "john@example.com", Department = "Engineering" },
                new { Id = 2, Name = "Jane Smith", Email = "jane@example.com", Department = "Marketing" }
            };

            // Simulate some processing time
            await Task.Delay(Random.Shared.Next(10, 100));

            _logger.LogInformation("Successfully fetched {UserCount} users", users.Length);
            return Ok(users);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching users");
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_users"));
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUser(int id)
    {
        using var activity = ActivitySource.StartActivity("GetUser");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching user with ID: {UserId}", id);
            
            activity?.SetTag("operation", "get_user");
            activity?.SetTag("user.id", id.ToString());

            RequestCounter.Add(1, new("endpoint", "get_user"), new("method", "GET"));

            // Simulate database lookup
            await Task.Delay(Random.Shared.Next(5, 50));

            if (id <= 0)
            {
                _logger.LogWarning("Invalid user ID: {UserId}", id);
                return BadRequest("Invalid user ID");
            }

            if (id > 1000)
            {
                _logger.LogWarning("User not found: {UserId}", id);
                return NotFound();
            }

            var user = new { Id = id, Name = $"User {id}", Email = $"user{id}@example.com", Department = "Engineering" };

            _logger.LogInformation("Successfully fetched user: {UserId}", id);
            return Ok(user);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching user {UserId}", id);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_user"));
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
    {
        using var activity = ActivitySource.StartActivity("CreateUser");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Creating new user: {UserName}", request.Name);
            
            activity?.SetTag("operation", "create_user");
            activity?.SetTag("user.name", request.Name);

            RequestCounter.Add(1, new("endpoint", "create_user"), new("method", "POST"));

            // Validate request
            if (string.IsNullOrEmpty(request.Name) || string.IsNullOrEmpty(request.Email))
            {
                _logger.LogWarning("Invalid user creation request");
                return BadRequest("Name and Email are required");
            }

            // Simulate database save
            await Task.Delay(Random.Shared.Next(20, 100));

            var newUser = new { Id = Random.Shared.Next(1000, 9999), Name = request.Name, Email = request.Email, Department = request.Department ?? "General" };

            _logger.LogInformation("Successfully created user: {UserId}", newUser.Id);
            return CreatedAtAction(nameof(GetUser), new { id = newUser.Id }, newUser);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating user");
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "create_user"));
        }
    }

    [HttpGet("{id}/orders")]
    public async Task<IActionResult> GetUserOrders(int id)
    {
        using var activity = ActivitySource.StartActivity("GetUserOrders");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            _logger.LogInformation("Fetching orders for user: {UserId}", id);
            
            activity?.SetTag("operation", "get_user_orders");
            activity?.SetTag("user.id", id.ToString());

            RequestCounter.Add(1, new("endpoint", "get_user_orders"), new("method", "GET"));

            // Call Order Service
            var orderServiceUrl = Environment.GetEnvironmentVariable("ORDER_SERVICE_URL") ?? "http://order-service";
            var response = await _httpClient.GetAsync($"{orderServiceUrl}/api/orders/user/{id}");

            if (response.IsSuccessStatusCode)
            {
                var orders = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Successfully fetched orders for user: {UserId}", id);
                return Ok(orders);
            }
            else
            {
                _logger.LogWarning("Failed to fetch orders for user: {UserId}, Status: {StatusCode}", id, response.StatusCode);
                return StatusCode((int)response.StatusCode, "Failed to fetch orders");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching orders for user {UserId}", id);
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            throw;
        }
        finally
        {
            RequestDuration.Record(stopwatch.Elapsed.TotalSeconds, new("endpoint", "get_user_orders"));
        }
    }
}

public class CreateUserRequest
{
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string? Department { get; set; }
}