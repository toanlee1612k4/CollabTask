using CollabTask.Api.Helpers;
using CollabTask.Api.Services.UserWeightService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CollabTask.Api.Controllers
{
    [ApiController]
    [Route("api/user-weights")]
    [Authorize]
    public class UserWeightsController : ControllerBase
    {
        private readonly IUserWeightService _userWeightService;

        public UserWeightsController(IUserWeightService userWeightService)
        {
            _userWeightService = userWeightService;
        }

        /// <summary>
        /// Lấy weights hiện tại của user
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetMyWeights()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty)
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var weights = await _userWeightService.GetOrCreateUserWeights(userId);

            return Ok(new
            {
                userId = weights.UserID,
                deadlineWeight = weights.DeadlineWeight,
                importanceWeight = weights.ImportanceWeight,
                effortWeight = weights.EffortWeight,
                lastUpdated = weights.LastUpdatedAt,
                message = "These weights are personalized based on your task completion history"
            });
        }

        /// <summary>
        /// Kích hoạt học lại từ toàn bộ lịch sử
        /// </summary>
        [HttpPost("recalculate")]
        public async Task<IActionResult> RecalculateWeights()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty)
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            await _userWeightService.RecalculateUserWeights(userId);

            var weights = await _userWeightService.GetOrCreateUserWeights(userId);

            return Ok(new
            {
                message = "Weights recalculated successfully",
                newWeights = new
                {
                    deadlineWeight = weights.DeadlineWeight,
                    importanceWeight = weights.ImportanceWeight,
                    effortWeight = weights.EffortWeight
                }
            });
        }

        /// <summary>
        /// Reset weights về mặc định
        /// </summary>
        [HttpPost("reset")]
        public async Task<IActionResult> ResetWeights()
        {
            var userId = User.GetUserId();
            if (userId == Guid.Empty)
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            await _userWeightService.ResetUserWeights(userId);

            return Ok(new { message = "Weights reset to default values" });
        }
    }
}
