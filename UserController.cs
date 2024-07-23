using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IActiveDirectoryService _activeDirectoryService;

    public UserController(IActiveDirectoryService activeDirectoryService)
    {
        _activeDirectoryService = activeDirectoryService;
    }

    [HttpGet("groups")]
    [Authorize]
    public async Task<IActionResult> GetUserGroups()
    {
        var userName = User.Identity.Name; // Get the current authenticated user's name
        var groups = await _activeDirectoryService.GetUserGroupsAsync(userName);
        return Ok(groups);
    }

    [HttpGet("claims")]
    [Authorize]
    public async Task<IActionResult> GetUserClaims()
    {
        var userName = User.Identity.Name; // Get the current authenticated user's name
        var claims = await _activeDirectoryService.GetUserClaimsAsync(userName);
        return Ok(claims);
    }

    [HttpGet("admin-endpoint")]
    [Authorize(Policy = "RequireAdminsGroup")]
    public IActionResult AdminEndpoint()
    {
        return Ok("You have access to the admin endpoint.");
    }

    [HttpGet("user-endpoint")]
    [Authorize(Policy = "RequireUsersGroup")]
    public IActionResult UserEndpoint()
    {
        return Ok("You have access to the user endpoint.");
    }
}
