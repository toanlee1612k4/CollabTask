using System.Security.Claims;

namespace CollabTask.Api.Helpers
{
    public static class ClaimsPrincipalExtensions
    {
        public static Guid GetUserId(this ClaimsPrincipal user)
        {
            // Try standard ClaimTypes first, then try JWT claim name
            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier) 
                           ?? user.FindFirst("nameid")
                           ?? user.FindFirst("UserID");
                           
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
            {
                throw new InvalidOperationException("User ID not found in token.");
            }
            return userId;
        }
    }
}