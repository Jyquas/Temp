using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using System.Linq;
using System.Threading.Tasks;

public class RequireAdminGroupRequirement : IAuthorizationRequirement
{
    public string AdminGroupSid { get; }

    public RequireAdminGroupRequirement(string adminGroupSid)
    {
        AdminGroupSid = adminGroupSid;
    }
}

public class RequireAdminGroupHandler : AuthorizationHandler<RequireAdminGroupRequirement>
{
    private readonly ILogger<RequireAdminGroupHandler> _logger;

    public RequireAdminGroupHandler(ILogger<RequireAdminGroupHandler> logger)
    {
        _logger = logger;
    }

    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, RequireAdminGroupRequirement requirement)
    {
        var hasClaim = context.User.Claims.Any(c => c.Type == CustomClaimTypes.Groups && c.Value == requirement.AdminGroupSid);

        if (hasClaim)
        {
            _logger.LogInformation("Authorization succeeded: User has the required admin group SID.");
            context.Succeed(requirement);
        }
        else
        {
            _logger.LogWarning("Authorization failed: User does not have the required admin group SID.");
        }

        return Task.CompletedTask;
    }
}
