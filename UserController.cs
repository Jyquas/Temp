[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IActiveDirectoryService _activeDirectoryService;

    public UserController(IActiveDirectoryService activeDirectoryService)
    {
        _activeDirectoryService = activeDirectoryService;
    }

    [HttpGet("{userName}/groups")]
    public async Task<IActionResult> GetUserGroups(string userName)
    {
        var groups = await _activeDirectoryService.GetUserGroupsAsync(userName);
        return Ok(groups);
    }

    [HttpGet("{userName}/claims")]
    public async Task<IActionResult> GetUserClaims(string userName)
    {
        var claims = await _activeDirectoryService.GetUserClaimsAsync(userName);
        return Ok(claims);
    }
}
