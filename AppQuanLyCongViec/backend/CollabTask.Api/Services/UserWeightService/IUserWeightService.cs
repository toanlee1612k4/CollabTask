using CollabTask.Api.Models;
using System.Threading.Tasks;

namespace CollabTask.Api.Services.UserWeightService
{
    public interface IUserWeightService
    {
        /// <summary>
        /// Học từ task vừa hoàn thành và cập nhật weights
        /// </summary>
        System.Threading.Tasks.Task LearnFromTaskCompletion(Models.Task task, Guid userId);
        
        /// <summary>
        /// Tính toán lại weights dựa trên toàn bộ lịch sử
        /// </summary>
        System.Threading.Tasks.Task RecalculateUserWeights(Guid userId);
        
        /// <summary>
        /// Lấy weights hiện tại của user (hoặc mặc định)
        /// </summary>
        System.Threading.Tasks.Task<UserTaskWeight> GetOrCreateUserWeights(Guid userId);
        
        /// <summary>
        /// Reset weights về mặc định
        /// </summary>
        System.Threading.Tasks.Task ResetUserWeights(Guid userId);

        /// <summary>
        /// Xác định User Trait dựa trên weights
        /// </summary>
        UserTrait DetermineUserTrait(UserTaskWeight weights);
    }
}