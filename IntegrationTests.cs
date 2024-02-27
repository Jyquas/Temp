public class IntegrationTests : IClassFixture<CustomWebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public IntegrationTests(CustomWebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestSomethingAsync()
    {
        // Use _client to make HTTP requests to your application
        var response = await _client.GetAsync("/api/some-endpoint");
        response.EnsureSuccessStatusCode();

        // Assertions...
    }
}
