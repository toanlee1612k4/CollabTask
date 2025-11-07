using CollabTask.Api.Models;
using CollabTask.Api.Dtos.Tasks;
using Task = CollabTask.Api.Models.Task; // Alias

namespace CollabTask.Api.Services.PriorityScoringService
{
    public interface IPriorityScoringService
    {
        Task<List<TaskDto>> GetSuggestedTasksAsync(Guid userId);
        System.Threading.Tasks.Task LogTaskCompletion(Task task, Guid userId); // Sửa: Thêm System.Threading.Tasks.Task để tránh nhầm lẫn
    }
}