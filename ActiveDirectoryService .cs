using System.DirectoryServices.AccountManagement;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;

public class ActiveDirectoryService : IActiveDirectoryService
{
    private readonly string _domain;
    private readonly List<string> _targetGroups;

    public ActiveDirectoryService(IConfiguration configuration)
    {
        _domain = configuration["ActiveDirectory:Domain"];
        _targetGroups = configuration.GetSection("TargetGroups").Get<List<string>>();
    }

    public async Task<IEnumerable<string>> GetUserGroupsAsync(string userName)
    {
        return await Task.Run(() =>
        {
            using (var context = new PrincipalContext(ContextType.Domain, _domain))
            using (var user = UserPrincipal.FindByIdentity(context, IdentityType.SamAccountName, userName))
            {
                if (user == null)
                    return Enumerable.Empty<string>();

                var groups = user.GetGroups()
                    .Where(g => _targetGroups.Contains(g.Name))
                    .Select(g => g.Name)
                    .ToList();
                return groups;
            }
        });
    }

    public async Task<IEnumerable<Claim>> GetUserClaimsAsync(string userName)
    {
        return await Task.Run(() =>
        {
            var claims = new List<Claim>();

            using (var context = new PrincipalContext(ContextType.Domain, _domain))
            using (var user = UserPrincipal.FindByIdentity(context, IdentityType.SamAccountName, userName))
            {
                if (user == null)
                    return claims;

                // Add user claims. You can customize this to include any claims from AD
                if (user.EmailAddress != null)
                    claims.Add(new Claim(ClaimTypes.Email, user.EmailAddress));
                if (user.DisplayName != null)
                    claims.Add(new Claim(ClaimTypes.Name, user.DisplayName));

                // Add group claims
                var groups = user.GetAuthorizationGroups()
                    .Where(g => _targetGroups.Contains(g.Name))
                    .ToList();

                foreach (var group in groups)
                {
                    claims.Add(new Claim(ClaimTypes.Role, group.Name));
                }
            }

            return claims;
        });
    }
}
