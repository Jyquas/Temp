using Microsoft.AspNetCore.Mvc.ModelBinding;
using System.Threading.Tasks;

public class IdentityProviderDtoBinder : IModelBinder
{
    /// <summary>
    /// Binds the query parameters to the IdentityProviderDto object.
    /// </summary>
    /// <param name="bindingContext">The context for model binding.</param>
    /// <returns>A completed Task indicating the binding operation is complete.</returns>
    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        // Access the query parameters from the HTTP request.
        var query = bindingContext.HttpContext.Request.Query;

        // Create a new IdentityProviderDto object and populate its properties from the query parameters.
        var identityProviderDto = new IdentityProviderDto
        {
            // Try to get the InternalId parameter and parse it to an integer.
            // If the parameter is not present, default to 0.
            InternalId = query.TryGetValue(nameof(IdentityProviderDto.InternalId), out var internalId) ? int.Parse(internalId) : 0,

            // Try to get the PublicGuid parameter and parse it to a GUID.
            // If the parameter is not present, default to Guid.Empty.
            PublicGuid = query.TryGetValue(nameof(IdentityProviderDto.PublicGuid), out var publicGuid) ? Guid.Parse(publicGuid) : Guid.Empty,

            // Try to get the IdentityField1 parameter as a string.
            // If the parameter is not present, default to null.
            IdentityField1 = query.TryGetValue(nameof(IdentityProviderDto.IdentityField1), out var identityField1) ? identityField1.ToString() : null,

            // Try to get the IdentityField2 parameter as a string.
            // If the parameter is not present, default to null.
            IdentityField2 = query.TryGetValue(nameof(IdentityProviderDto.IdentityField2), out var identityField2) ? identityField2.ToString() : null,

            // Try to get the IdentityField3 parameter as a string.
            // If the parameter is not present, default to null.
            IdentityField3 = query.TryGetValue(nameof(IdentityProviderDto.IdentityField3), out var identityField3) ? identityField3.ToString() : null
        };

        // Set the binding result to the populated IdentityProviderDto object.
        bindingContext.Result = ModelBindingResult.Success(identityProviderDto);

        // Return a completed task.
        return Task.CompletedTask;
    }
}

public class AuditableEventDtoBinder : IModelBinder
{
    /// <summary>
    /// Binds the query parameters to the AuditableEventDto object.
    /// </summary>
    /// <param name="bindingContext">The context for model binding.</param>
    /// <returns>A completed Task indicating the binding operation is complete.</returns>
    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        // Access the query parameters from the HTTP request.
        var query = bindingContext.HttpContext.Request.Query;

        // Create a new AuditableEventDto object and populate its properties from the query parameters.
        var auditableEventDto = new AuditableEventDto
        {
            // Try to get the EventName parameter as a string.
            // If the parameter is not present, default to null.
            EventName = query.TryGetValue(nameof(AuditableEventDto.EventName), out var eventName) ? eventName.ToString() : null,

            // Try to get the EventDate parameter and parse it to a DateTime.
            // If the parameter is not present, default to null.
            EventDate = query.TryGetValue(nameof(AuditableEventDto.EventDate), out var eventDate) ? DateTime.Parse(eventDate) : (DateTime?)null
        };

        // Set the binding result to the populated AuditableEventDto object.
        bindingContext.Result = ModelBindingResult.Success(auditableEventDto);

        // Return a completed task.
        return Task.CompletedTask;
    }
}
