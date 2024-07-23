using Microsoft.AspNetCore.Authorization;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

public class CustomAuthorizationHandler : AuthorizationHandler<CustomAuthorizationRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, CustomAuthorizationRequirement requirement)
    {
        if (context.User == null || !context.User.Identity.IsAuthenticated)
        {
            return Task.CompletedTask;
        }

        var userGroups = context.User.FindAll(ClaimTypes.Role).Select(c => c.Value);

        if (userGroups.Any(g => requirement.AllowedGroups.Contains(g)))
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}

public class CustomAuthorizationRequirement : IAuthorizationRequirement
{
    public string[] AllowedGroups { get; }

    public CustomAuthorizationRequirement(params string[] allowedGroups)
    {
        AllowedGroups = allowedGroups;
    }
}
