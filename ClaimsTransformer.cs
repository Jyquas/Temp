using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Configuration;
using System.Security.Claims;

public class ClaimsTransformer : IClaimsTransformation
{
    private readonly IActiveDirectoryService _activeDirectoryService;
    private readonly List<string> _targetGroups;

    public ClaimsTransformer(IActiveDirectoryService activeDirectoryService, IConfiguration configuration)
    {
        _activeDirectoryService = activeDirectoryService;
        _targetGroups = configuration.GetSection("TargetGroups").Get<List<string>>();
    }

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        if (principal.Identity.IsAuthenticated)
        {
            string userName = null;

            if (principal.Identity is WindowsIdentity windowsIdentity)
            {
                userName = windowsIdentity.Name;
            }
            else if (principal.Identity.AuthenticationType == CertificateAuthenticationDefaults.AuthenticationScheme)
            {
                userName = principal.FindFirst(ClaimTypes.Name)?.Value;
            }

            if (userName != null)
            {
                var userGroups = await _activeDirectoryService.GetUserGroupsAsync(userName);

                // Filter user groups to include only those in the target groups
                var claims = userGroups
                    .Where(group => _targetGroups.Contains(group))
                    .Select(group => new Claim(ClaimTypes.Role, group))
                    .ToList();

                var appIdentity = new ClaimsIdentity(claims);
                principal.AddIdentity(appIdentity);
            }
        }

        return principal;
    }
}
