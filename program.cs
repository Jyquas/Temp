using Microsoft.AspNetCore.Authentication.Certificate;
using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Security.Claims;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;

var builder = WebApplication.CreateBuilder(args);

// Load domain and group SIDs from configuration
var adminGroupSid = builder.Configuration["Authentication:AdminGroupSID"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CertificateAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = NegotiateDefaults.AuthenticationScheme;
})
.AddCertificate(options =>
{
    if (builder.Environment.IsDevelopment())
    {
        options.RevocationMode = X509RevocationMode.NoCheck;
    }
    options.Events = new CertificateAuthenticationEvents
    {
        OnCertificateValidated = context =>
        {
            var certificate = context.ClientCertificate;

            // Implement your logic to validate the certificate and its chain
            bool isValidCertificate = CheckCertificate(certificate); // Your custom validation method

            if (isValidCertificate)
            {
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, certificate.Subject, ClaimValueTypes.String, context.Options.ClaimsIssuer),
                    new Claim(ClaimTypes.Name, certificate.Subject, ClaimValueTypes.String, context.Options.ClaimsIssuer),
                    new Claim("Certificate", "true") // Custom claim to mark certificate authentication
                };

                // Dynamically add group claims based on your logic
                AddGroupClaims(claims, certificate);

                context.Principal = new ClaimsPrincipal(new ClaimsIdentity(claims, context.Scheme.Name));
                context.Success();
            }
            else
            {
                context.Fail("Invalid certificate.");
            }

            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            context.NoResult(); // Prevents the default behavior which would challenge the user
            return Task.CompletedTask;
        }
    };
})
.AddNegotiate();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireCertificate", policy =>
        policy.RequireClaim("Certificate", "true"));
    options.AddPolicy("RequireAdminGroup", policy =>
        policy.Requirements.Add(new RequireAdminGroupRequirement(adminGroupSid)));
});

// Register the custom authorization handler
builder.Services.AddSingleton<IAuthorizationHandler, RequireAdminGroupHandler>();

builder.Services.AddControllers();

var app = builder.Build();

// Use custom middleware to log user information
app.UseMiddleware<UserLoggingMiddleware>();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

bool CheckCertificate(X509Certificate2 certificate)
{
    // Implement your custom certificate validation logic here
    // Example: return certificate.Subject == "CN=ValidClient";
    return true;
}

void AddGroupClaims(List<Claim> claims, X509Certificate2 certificate)
{
    // Example logic to add group claims
    // This is where you would add claims based on the certificate properties or other logic
    // Here, adding a hardcoded group SID for demonstration purposes
    claims.Add(new Claim(CustomClaimTypes.Groups, "S-1-5-21-3623811015-3361044348-30300820-1013"));
}

public static class CustomClaimTypes
{
    public const string Groups = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid";
}
