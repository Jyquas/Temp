using Xunit;
using YourProjectNamespace.Controllers; // Adjust this to your actual namespace
using YourProjectNamespace.Models; // Adjust this to your actual namespace
using Microsoft.EntityFrameworkCore;
using Bogus;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

public class UserTests
{
    private readonly UsersController _controller;
    private readonly YourDbContextName _context; // Adjust YourDbContextName to your actual DbContext class

    public UserTests()
    {
        // Configure in-memory database for testing
        var options = new DbContextOptionsBuilder<YourDbContextName>()
            .UseInMemoryDatabase(databaseName: "TestDatabase")
            .Options;
        _context = new YourDbContextName(options); // Make sure to have a constructor that accepts DbContextOptions

        // Instantiate your controller here, adjusting for any dependencies it requires
        _controller = new UsersController(_context);
    }

    private Faker<User> GenerateUserFaker()
    {
        // Comprehensive Faker<User> configuration
        var faker = new Faker<User>()
            .RuleFor(u => u.Name, f => f.Name.FirstName())
            .RuleFor(u => u.Surname, f => f.Name.LastName())
            .RuleFor(u => u.DateOfBirth, f => f.Date.Past(30, DateTime.Now).Date)
            .RuleFor(u => u.CountryFullName, f => f.Address.Country())
            .RuleFor(u => u.ContactName, (f, u) => u.Name + " " + u.Surname)
            .RuleFor(u => u.ContactMethod, f => f.PickRandom(new[] { "email", "phone", "mail" }))
            .RuleFor(u => u.Email, (f, u) => u.ContactMethod == "email" ? f.Internet.Email(u.Name, u.Surname) : "")
            .RuleFor(u => u.Phone, (f, u) => u.ContactMethod == "phone" ? f.Phone.PhoneNumber() : "")
            .RuleFor(u => u.MailAddress, (f, u) => u.ContactMethod == "mail" ? f.Address.FullAddress() : "")
            .RuleFor(u => u.Occupation, f => f.PickRandom(new string[]
            {
                "Software Developer",
                "Data Scientist",
                "Project Manager",
                "Graphic Designer",
                "Systems Analyst",
                "Web Developer",
                "Product Manager",
                "Network Administrator",
                "UX/UI Designer",
                "Cybersecurity Specialist",
                "Database Administrator",
                "Cloud Solutions Architect",
                "IT Support Specialist",
                "Digital Marketing Specialist",
                "SEO Specialist",
                "Content Writer",
                "Technical Writer",
                "Business Analyst",
                "Quality Assurance Engineer",
                "Machine Learning Engineer"
            }))
            .RuleFor(u => u.StayYears, f => f.Random.Int(0, 5))
            .RuleFor(u => u.StayMonths, f => f.Random.Int(0, 12))
            .RuleFor(u => u.StayDays, f => f.Random.Int(0, 30))
            .RuleFor(u => u.HasStayDuration, (f, u) => u.StayYears > 0 || u.StayMonths > 0 || u.StayDays > 0)
            .RuleFor(u => u.AnotherCountry, f => f.Address.Country())
            .RuleFor(u => u.Q1, f => f.Random.Bool() ? "Yes" : "No")
            .RuleFor(u => u.Q2, f => f.Random.Bool() ? "Yes" : "No")
            // Add rules for Q3 to Q11 similarly
            .RuleFor(u => u.Version, "1.0")
            .RuleFor(u => u.System, f => f.PickRandom(new[] { "Windows", "macOS", "Linux" }));

        return faker;
    }

    [Fact]
    public async Task TestCreateUser()
    {
        // Generate a new User
        var newUser = GenerateUserFaker().Generate();

        // Simulate the action of creating a new user
        var result = await _controller.CreateUser(newUser); // Make sure to adjust CreateUser to your actual method name

        // Verify the outcome is as expected
        Assert.NotNull(result);
        // Add additional assertions as necessary
    }

    [Fact]
    public async Task TestBulkInsertUsers()
    {
        // Generate 100 new users
        var users = GenerateUserFaker().Generate(100);

        // Add generated users to the context
        _context.Users.AddRange(users);
        await _context.SaveChangesAsync();

        // Verify that users are added
        var insertedCount = _context.Users.Count();
        Assert.Equal(100, insertedCount);
    }

    // You can add more tests as needed
}
