public class ApiTest : IDisposable
{
    protected readonly YourDbContext _context;
    protected readonly HttpClient _client;
    private readonly TestServer _server;

    public ApiTest()
    {
        // Set up the test server and client
        var builder = new WebHostBuilder()
            .UseStartup<Startup>() // Use your startup class
            .ConfigureServices(services =>
            {
                // Replace the DB context with an in-memory version for testing
                services.AddScoped<YourDbContext>(_ =>
                {
                    var options = new DbContextOptionsBuilder<YourDbContext>()
                        .UseInMemoryDatabase(databaseName: "TestDb") // Make sure each test method has a unique name for the database if they run in parallel
                        .Options;
                    var context = new YourDbContext(options);

                    // Seed the database if necessary
                    SeedDatabase(context);

                    return context;
                });
            });

        _server = new TestServer(builder);
        _client = _server.CreateClient();

        // Assuming you have a method to get the service directly if needed
        _context = _server.Host.Services.GetService(typeof(YourDbContext)) as YourDbContext;
    }

    private void SeedDatabase(YourDbContext context)
    {
        // Seed your in-memory database
    }

    public void Dispose()
    {
        _client.Dispose();
        _server.Dispose();
    }
}
