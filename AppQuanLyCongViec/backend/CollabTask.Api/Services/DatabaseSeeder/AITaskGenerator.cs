using CollabTask.Api.Data;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Services.DatabaseSeeder
{
    /// <summary>
    /// Helper class for generating large-scale task data for AI testing
    /// </summary>
    public class AITaskGenerator
    {
        private readonly Random _random;
        private readonly List<string> _priorities = new() { "Urgent", "High", "Medium", "Low" };
        private readonly List<string> _statuses = new() { "ToDo", "InProgress", "Review", "Done" };
        
        private readonly List<string> _taskTitles = new()
        {
            "Implement login functionality", "Fix navigation bug", "Update user profile page",
            "Add search feature", "Optimize database queries", "Write unit tests",
            "Design new dashboard", "Integrate payment gateway", "Refactor authentication",
            "Update API documentation", "Fix CSS issues", "Add email notifications",
            "Implement forgot password", "Optimize images", "Add analytics tracking",
            "Fix memory leak", "Update dependencies", "Add dark mode",
            "Implement chat feature", "Fix responsive layout", "Add export functionality",
            "Optimize build process", "Fix security vulnerability", "Add multi-language support",
            "Implement caching", "Fix performance issue", "Add social login",
            "Update error handling", "Fix data validation", "Add file upload",
            "Optimize API calls", "Fix timezone issues", "Add audit logging",
            "Implement rate limiting", "Fix accessibility issues", "Add keyboard shortcuts",
            "Optimize load time", "Fix cross-browser compatibility", "Add user feedback form",
            "Implement notifications", "Fix mobile responsiveness", "Add admin dashboard",
            "Optimize memory usage", "Fix data synchronization", "Add offline mode",
            "Implement search filters", "Fix layout issues", "Add bulk operations",
            "Optimize network requests", "Fix form validation", "Add drag and drop",
            "Create landing page", "Fix broken links", "Add progress indicators",
            "Optimize rendering", "Fix state management", "Add keyboard navigation",
            "Implement auto-save", "Fix data migration", "Add export to PDF",
            "Optimize bundle size", "Fix memory leaks", "Add print functionality",
            "Implement webhooks", "Fix API integration", "Add custom themes",
            "Optimize SQL queries", "Fix authentication flow", "Add two-factor auth",
            "Implement real-time updates", "Fix session management", "Add role-based access",
            "Optimize image loading", "Fix error boundaries", "Add data visualization",
            "Implement pagination", "Fix infinite scroll", "Add sorting functionality",
            "Optimize caching strategy", "Fix redirect issues", "Add breadcrumbs",
            "Implement lazy loading", "Fix memory optimization", "Add tooltips",
            "Optimize component rendering", "Fix prop drilling", "Add loading states",
            "Implement error logging", "Fix API rate limiting", "Add retry logic",
            "Optimize database indexes", "Fix N+1 queries", "Add batch processing",
            "Implement queue system", "Fix race conditions", "Add transaction handling",
            "Optimize connection pooling", "Fix deadlocks", "Add database migration",
            "Implement backup system", "Fix data consistency", "Add monitoring",
            "Optimize server performance", "Fix scalability issues", "Add load balancing",
            "Implement CI/CD pipeline", "Fix deployment issues", "Add automated testing",
            "Optimize Docker images", "Fix environment variables", "Add health checks",
            "Implement logging framework", "Fix error tracking", "Add performance metrics",
            "Optimize resource usage", "Fix container orchestration", "Add auto-scaling"
        };

        public AITaskGenerator(int? seed = null)
        {
            _random = seed.HasValue ? new Random(seed.Value) : new Random();
        }

        /// <summary>
        /// Generate tasks for a user based on their behavior pattern
        /// </summary>
        public List<Task> GenerateTasksForUser(
            User user,
            int userIndex,
            Guid workspaceId,
            int taskCount,
            DateTime startDate,
            UserBehaviorPattern pattern)
        {
            var tasks = new List<Task>();
            var now = DateTime.UtcNow;

            for (int i = 0; i < taskCount; i++)
            {
                var createdAt = startDate.AddDays(_random.Next(0, 180)); // Tasks created over 6 months
                var task = new Task
                {
                    TaskID = Guid.NewGuid(),
                    WorkspaceID = workspaceId,
                    Title = $"[User{userIndex}] {_taskTitles[_random.Next(_taskTitles.Count)]} #{i + 1}",
                    Description = GenerateDescription(pattern),
                    CreatorUserID = user.UserID,
                    CreatedAt = createdAt
                };

                // Set priority, deadline, and status based on behavior pattern
                SetTaskProperties(task, pattern, createdAt, now);

                tasks.Add(task);
            }

            return tasks;
        }

        private void SetTaskProperties(Task task, UserBehaviorPattern pattern, DateTime createdAt, DateTime now)
        {
            switch (pattern)
            {
                case UserBehaviorPattern.PerfectPerformer:
                    // Ưu tiên High/Urgent, deadline hợp lý, hoàn thành đúng hạn
                    task.Priority = _random.Next(100) < 70 ? (_random.Next(2) == 0 ? "Urgent" : "High") : "Medium";
                    task.Deadline = createdAt.AddDays(_random.Next(3, 14));
                    task.EstimatedTimeMinutes = _random.Next(60, 480);
                    
                    // 80% tasks completed before deadline
                    if ((now - createdAt).TotalDays > 3 && _random.Next(100) < 80)
                    {
                        task.Status = "Done";
                        task.CompletedAt = task.Deadline.Value.AddHours(-_random.Next(4, 48));
                    }
                    else if (_random.Next(100) < 60)
                    {
                        task.Status = "InProgress";
                    }
                    else
                    {
                        task.Status = "ToDo";
                    }
                    break;

                case UserBehaviorPattern.DeadlineMisser:
                    // Priority random, thường trễ deadline
                    task.Priority = _priorities[_random.Next(_priorities.Count)];
                    task.Deadline = createdAt.AddDays(_random.Next(2, 10));
                    task.EstimatedTimeMinutes = _random.Next(30, 600);
                    
                    // 60% tasks overdue hoặc completed late
                    if ((now - createdAt).TotalDays > 5)
                    {
                        if (_random.Next(100) < 40)
                        {
                            task.Status = "Done";
                            task.CompletedAt = task.Deadline.Value.AddHours(_random.Next(12, 120)); // Late
                        }
                        else if (_random.Next(100) < 70)
                        {
                            task.Status = "InProgress";
                            // Still in progress but overdue
                        }
                        else
                        {
                            task.Status = "ToDo";
                        }
                    }
                    else
                    {
                        task.Status = _random.Next(3) == 0 ? "InProgress" : "ToDo";
                    }
                    break;

                case UserBehaviorPattern.EasyTaskFirst:
                    // Làm task có estimated time thấp trước
                    task.Priority = _priorities[_random.Next(_priorities.Count)];
                    task.Deadline = createdAt.AddDays(_random.Next(3, 20));
                    
                    // Phân bố estimated time: 40% easy, 40% medium, 20% hard
                    var difficulty = _random.Next(100);
                    task.EstimatedTimeMinutes = difficulty < 40 ? _random.Next(15, 90) : // Easy
                                                 difficulty < 80 ? _random.Next(90, 240) : // Medium
                                                 _random.Next(240, 600); // Hard
                    
                    // Easy tasks completed first
                    if ((now - createdAt).TotalDays > 2)
                    {
                        if (task.EstimatedTimeMinutes < 90 && _random.Next(100) < 85)
                        {
                            task.Status = "Done";
                            task.CompletedAt = createdAt.AddDays(_random.Next(1, 3));
                        }
                        else if (task.EstimatedTimeMinutes < 240 && _random.Next(100) < 50)
                        {
                            task.Status = _random.Next(2) == 0 ? "Done" : "InProgress";
                            if (task.Status == "Done")
                                task.CompletedAt = createdAt.AddDays(_random.Next(2, 7));
                        }
                        else
                        {
                            task.Status = _random.Next(100) < 30 ? "InProgress" : "ToDo";
                        }
                    }
                    else
                    {
                        task.Status = "ToDo";
                    }
                    break;

                case UserBehaviorPattern.HighPriorityFirst:
                    // Ưu tiên làm High/Urgent trước, bỏ qua Low
                    var priorityRand = _random.Next(100);
                    task.Priority = priorityRand < 30 ? "Urgent" :
                                   priorityRand < 60 ? "High" :
                                   priorityRand < 85 ? "Medium" : "Low";
                    task.Deadline = createdAt.AddDays(_random.Next(2, 15));
                    task.EstimatedTimeMinutes = _random.Next(60, 420);
                    
                    // High/Urgent completed quickly, Low often ignored
                    if ((now - createdAt).TotalDays > 3)
                    {
                        if (task.Priority == "Urgent" && _random.Next(100) < 90)
                        {
                            task.Status = "Done";
                            task.CompletedAt = createdAt.AddDays(_random.Next(1, 3));
                        }
                        else if (task.Priority == "High" && _random.Next(100) < 75)
                        {
                            task.Status = _random.Next(3) < 2 ? "Done" : "InProgress";
                            if (task.Status == "Done")
                                task.CompletedAt = createdAt.AddDays(_random.Next(2, 5));
                        }
                        else if (task.Priority == "Medium" && _random.Next(100) < 45)
                        {
                            task.Status = _random.Next(2) == 0 ? "InProgress" : "Done";
                            if (task.Status == "Done")
                                task.CompletedAt = createdAt.AddDays(_random.Next(3, 10));
                        }
                        else
                        {
                            task.Status = task.Priority == "Low" && _random.Next(100) < 70 ? "ToDo" : "InProgress";
                        }
                    }
                    else
                    {
                        task.Status = task.Priority == "Urgent" ? "InProgress" : "ToDo";
                    }
                    break;

                case UserBehaviorPattern.Procrastinator:
                    // Làm gần deadline, nhiều task overdue
                    task.Priority = _priorities[_random.Next(_priorities.Count)];
                    task.Deadline = createdAt.AddDays(_random.Next(3, 12));
                    task.EstimatedTimeMinutes = _random.Next(45, 360);
                    
                    // 70% tasks start close to deadline
                    if (task.Deadline.HasValue)
                    {
                        var daysUntilDeadline = (task.Deadline.Value - now).TotalDays;
                        
                        if (daysUntilDeadline < -5) // Overdue significantly
                        {
                            task.Status = _random.Next(100) < 40 ? "Done" : "InProgress";
                            if (task.Status == "Done")
                                task.CompletedAt = task.Deadline.Value.AddDays(_random.Next(1, 8));
                        }
                        else if (daysUntilDeadline < -1) // Recently overdue
                        {
                            task.Status = _random.Next(100) < 60 ? "InProgress" : "ToDo";
                        }
                        else if (daysUntilDeadline < 2) // Close to deadline
                        {
                            task.Status = _random.Next(100) < 70 ? "InProgress" : "ToDo";
                        }
                        else // Still have time
                        {
                            task.Status = "ToDo";
                        }
                    }
                    else
                    {
                        task.Status = "ToDo";
                    }
                    break;

                case UserBehaviorPattern.Balanced:
                default:
                    // Cân bằng, không có pattern đặc biệt
                    task.Priority = _priorities[_random.Next(_priorities.Count)];
                    task.Deadline = _random.Next(100) < 85 ? createdAt.AddDays(_random.Next(3, 14)) : null;
                    task.EstimatedTimeMinutes = _random.Next(30, 480);
                    
                    // Random completion pattern
                    if ((now - createdAt).TotalDays > 4)
                    {
                        var statusRand = _random.Next(100);
                        if (statusRand < 40)
                        {
                            task.Status = "Done";
                            task.CompletedAt = createdAt.AddDays(_random.Next(1, 10));
                        }
                        else if (statusRand < 65)
                        {
                            task.Status = "InProgress";
                        }
                        else if (statusRand < 75)
                        {
                            task.Status = "Review";
                        }
                        else
                        {
                            task.Status = "ToDo";
                        }
                    }
                    else
                    {
                        task.Status = _statuses[_random.Next(_statuses.Count - 1)]; // Exclude Done
                    }
                    break;
            }
        }

        private string GenerateDescription(UserBehaviorPattern pattern)
        {
            var descriptions = new[]
            {
                "This task requires careful attention to detail and thorough testing.",
                "Important feature that needs to be implemented according to specifications.",
                "Bug fix required to improve user experience and system stability.",
                "Enhancement to existing functionality based on user feedback.",
                "Critical issue that needs immediate attention and resolution.",
                "Optimization task to improve system performance and efficiency.",
                "Refactoring needed to improve code quality and maintainability.",
                "Documentation update to reflect current system state.",
                "Integration task requiring coordination with external systems.",
                "Testing task to ensure quality and reliability of the feature."
            };

            return $"{descriptions[_random.Next(descriptions.Length)]} [Pattern: {pattern}]";
        }
    }

    public enum UserBehaviorPattern
    {
        PerfectPerformer,    // Luôn hoàn thành đúng hạn, ưu tiên High tasks
        DeadlineMisser,      // Thường trễ deadline, làm việc không theo priority
        EasyTaskFirst,       // Làm task dễ (low estimated time) trước
        HighPriorityFirst,   // Luôn làm High/Urgent trước
        Procrastinator,      // Làm gần deadline, thường overdue
        Balanced            // Cân bằng, không có pattern rõ ràng
    }
}
