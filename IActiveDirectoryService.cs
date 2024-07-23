public interface IActiveDirectoryService
{
    Task<IEnumerable<string>> GetUserGroupsAsync(string userName);
    Task<IEnumerable<Claim>> GetUserClaimsAsync(string userName);
}
