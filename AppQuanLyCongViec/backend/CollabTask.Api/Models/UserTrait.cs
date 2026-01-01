namespace CollabTask.Api.Models
{
    /// <summary>
    /// Định nghĩa Key Traits (đặc điểm làm việc) của người dùng
    /// </summary>
    public enum UserTrait
    {
        /// <summary>
        /// Người dùng chưa có đủ dữ liệu để phân loại (mặc định)
        /// </summary>
        Unknown = 0,

        /// <summary>
        /// "The Sprinter" - Người chạy nước rút
        /// Ưu tiên các task ngắn, effort thấp, làm nhanh xong nhanh
        /// Đặc điểm: EffortWeight cao (> 0.4)
        /// </summary>
        Sprinter = 1,

        /// <summary>
        /// "The Procrastinator" - Người nước đến chân mới nhảy
        /// Chỉ làm task sát deadline, chờ đến phút chót mới hành động
        /// Đặc điểm: DeadlineWeight cao (> 0.5)
        /// </summary>
        Procrastinator = 2,

        /// <summary>
        /// "The Planner" - Người quy hoạch
        /// Ưu tiên các task quan trọng bất kể thời gian hay độ khó
        /// Đặc điểm: ImportanceWeight cao (> 0.4)
        /// </summary>
        Planner = 3
    }
}
