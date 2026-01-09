using CollabTask.Api.Models;
using CollabTask.Api.Dtos.Tasks;
using Task = CollabTask.Api.Models.Task; // Alias

namespace CollabTask.Api.Services.PriorityScoringService
{
    public interface IPriorityScoringService
    {
        Task<List<TaskDto>> GetSuggestedTasksAsync(Guid userId);
        System.Threading.Tasks.Task LogTaskCompletion(Task task, Guid userId);
        
        /// <summary>
        /// Xóa cache danh sách gợi ý của user để force recalculate
        /// Gọi khi: Tạo task mới, Assign task, Hoàn thành task, Xóa task
        /// </summary>
        void InvalidateSuggestedTasksCache(Guid userId);
        
        /// <summary>
        /// Xóa cache danh sách gợi ý của nhiều users cùng lúc
        /// </summary>
        void InvalidateSuggestedTasksCacheForUsers(IEnumerable<Guid> userIds);
    }
}