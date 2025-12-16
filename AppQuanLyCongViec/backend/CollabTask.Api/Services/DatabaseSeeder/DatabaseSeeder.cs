using CollabTask.Api.Data;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Services.DatabaseSeeder
{
    public class DatabaseSeeder : IDatabaseSeeder
    {
        private readonly CollabTaskDbContext _context;

        private List<User> _users = new();
        private List<Workspace> _workspaces = new();
        private List<Tag> _tags = new();
        private List<Task> _tasks = new();
        private AITaskGenerator _taskGenerator = null!;

        public DatabaseSeeder(CollabTaskDbContext context)
        {
            _context = context;
            _taskGenerator = new AITaskGenerator(42);
        }

        public async System.Threading.Tasks.Task SeedAsync()
        {
            Console.WriteLine("🌱 Starting database seeding...");

            await SeedSystemRolesAsync();

            if (await _context.Users.AnyAsync())
            {
                Console.WriteLine("⚠️  Users already exist. Run ClearDataAsync() first if you want to reseed.");
                return;
            }

            await SeedUsersAsync();
            await SeedWorkspacesAsync();
            await SeedWorkspaceMembersAsync();
            await SeedTagsAsync();
            await SeedTasksAsync();
            await SeedTaskAssignmentsAsync();
            await SeedTaskAssignmentHistoryAsync();
            await SeedTaskTagsAsync();
            await SeedCommentsAsync();
            await SeedUserWeightsAsync();
            await SeedUserInteractionsAsync();
            await SeedNotificationsAsync();

            Console.WriteLine("✅ Database seeding completed successfully!");
            await PrintSummaryAsync();
        }

        public async System.Threading.Tasks.Task ClearDataAsync()
        {
            Console.WriteLine("🗑️  Clearing database...");

            await _context.Database.ExecuteSqlRawAsync("DELETE FROM UserInteractionsForAI");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM UserTaskWeights");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM ActivityLogs");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Notifications");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Comments");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskTags");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Tags");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskAssignmentHistories");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskAssignments");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Tasks");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM WorkspaceMembers");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Workspaces");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Users");

            Console.WriteLine("✅ Database cleared!");
        }

        private async System.Threading.Tasks.Task SeedSystemRolesAsync()
        {
            Console.WriteLine("🔐 Seeding system roles...");

            // Check if roles already exist
            if (await _context.SystemRoles.AnyAsync())
            {
                Console.WriteLine("   ⚠️  System roles already exist, skipping...");
                return;
            }

            await _context.Database.ExecuteSqlRawAsync(@"
                SET IDENTITY_INSERT SystemRoles ON;
                INSERT INTO SystemRoles (RoleID, RoleName) VALUES (1, 'Admin');
                INSERT INTO SystemRoles (RoleID, RoleName) VALUES (2, 'User');
                SET IDENTITY_INSERT SystemRoles OFF;
            ");

            Console.WriteLine("   ✓ Created 2 system roles");
        }

        private async System.Threading.Tasks.Task SeedUsersAsync()
        {
            Console.WriteLine("👥 Seeding users with different behavior patterns...");

            var userRole = await _context.SystemRoles.FirstOrDefaultAsync(r => r.RoleName == "User");
            if (userRole == null)
            {
                throw new InvalidOperationException("User role not found. Please seed SystemRoles first.");
            }

            string passwordHash = BCrypt.Net.BCrypt.HashPassword("Password123");

            _users = new List<User>
            {
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Alice Perfect (High Achiever)",
                    Email = "alice@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                // User 2: Deadline Misser - Thường trễ deadline, làm không theo priority
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Bob Late (Deadline Misser)",
                    Email = "bob@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                // User 3: Easy Task First - Làm task dễ (low estimated time) trước
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Charlie Quick (Easy First)",
                    Email = "charlie@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                // User 4: High Priority First - Luôn làm High/Urgent trước
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Diana Focus (Priority Driven)",
                    Email = "diana@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                // User 5: Procrastinator - Làm gần deadline, thường overdue
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Eve Procrastinate (Last Minute)",
                    Email = "eve@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                // User 6: Balanced - Cân bằng, không có pattern rõ ràng
                new User
                {
                    UserID = Guid.NewGuid(),
                    FullName = "Frank Balanced (Normal)",
                    Email = "frank@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                }
            };

            await _context.Users.AddRangeAsync(_users);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_users.Count} users with behavioral patterns");
        }

        private async System.Threading.Tasks.Task SeedWorkspacesAsync()
        {
            Console.WriteLine("🏢 Seeding workspaces...");

            _workspaces = new List<Workspace>
            {
                // Main collaborative workspace with all users
                new Workspace
                {
                    WorkspaceID = Guid.NewGuid(),
                    WorkspaceName = "AI Testing Workspace - Comprehensive Tasks",
                    Description = "Workspace for testing AI priority scoring algorithm with 1000+ tasks",
                    OwnerUserID = _users[0].UserID,
                    IsPersonal = false,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                }
            };

            await _context.Workspaces.AddRangeAsync(_workspaces);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_workspaces.Count} workspaces");
        }

        private async System.Threading.Tasks.Task SeedWorkspaceMembersAsync()
        {
            Console.WriteLine("👨‍💼 Seeding workspace members...");

            var members = new List<WorkspaceMember>();

            // Add all users to main workspace
            for (int i = 0; i < _users.Count; i++)
            {
                members.Add(new WorkspaceMember
                {
                    WorkspaceID = _workspaces[0].WorkspaceID,
                    UserID = _users[i].UserID,
                    Role = i == 0 ? "Owner" : "Member",
                    JoinedAt = DateTime.UtcNow.AddMonths(-6)
                });
            }

            await _context.WorkspaceMembers.AddRangeAsync(members);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {members.Count} workspace members");
        }

        private async System.Threading.Tasks.Task SeedTagsAsync()
        {
            Console.WriteLine("🏷️  Seeding tags...");

            _tags = new List<Tag>
            {
                // Common tags for the main workspace
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Frontend", Color = "#3498db" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Backend", Color = "#2ecc71" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Database", Color = "#9b59b6" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Bug", Color = "#e74c3c" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Feature", Color = "#f39c12" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Mobile", Color = "#34495e" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "API", Color = "#e67e22" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Security", Color = "#c0392b" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Testing", Color = "#ff6b6b" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Documentation", Color = "#4ecdc4" }
            };

            await _context.Tags.AddRangeAsync(_tags);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_tags.Count} tags");
        }

        private async System.Threading.Tasks.Task SeedTasksAsync()
        {
            Console.WriteLine("📝 Generating 1200+ tasks with behavioral patterns for AI testing...");

            var startDate = DateTime.UtcNow.AddMonths(-6);
            var patterns = new[]
            {
                UserBehaviorPattern.PerfectPerformer,
                UserBehaviorPattern.DeadlineMisser,
                UserBehaviorPattern.EasyTaskFirst,
                UserBehaviorPattern.HighPriorityFirst,
                UserBehaviorPattern.Procrastinator,
                UserBehaviorPattern.Balanced
            };

            _tasks = new List<Task>();

            for (int i = 0; i < _users.Count; i++)
            {
                Console.WriteLine($"   Generating tasks for {_users[i].FullName} ({patterns[i]})...");
                var userTasks = _taskGenerator.GenerateTasksForUser(
                    _users[i],
                    i,
                    _workspaces[0].WorkspaceID,
                    1000, // 1000 tasks per user = 6000 total tasks
                    startDate,
                    patterns[i]
                );
                _tasks.AddRange(userTasks);
            }

            await _context.Tasks.AddRangeAsync(_tasks);
            await _context.SaveChangesAsync();

            // Statistics
            Console.WriteLine($"   ✓ Created {_tasks.Count} tasks:");
            Console.WriteLine($"      - Urgent: {_tasks.Count(t => t.Priority == "Urgent")}");
            Console.WriteLine($"      - High: {_tasks.Count(t => t.Priority == "High")}");
            Console.WriteLine($"      - Medium: {_tasks.Count(t => t.Priority == "Medium")}");
            Console.WriteLine($"      - Low: {_tasks.Count(t => t.Priority == "Low")}");
            Console.WriteLine($"      - Done: {_tasks.Count(t => t.Status == "Done")}");
            Console.WriteLine($"      - InProgress: {_tasks.Count(t => t.Status == "InProgress")}");
            Console.WriteLine($"      - Review: {_tasks.Count(t => t.Status == "Review")}");
            Console.WriteLine($"      - ToDo: {_tasks.Count(t => t.Status == "ToDo")}");
            Console.WriteLine($"      - Overdue: {_tasks.Count(t => t.Deadline.HasValue && t.Deadline < DateTime.UtcNow && t.Status != "Done")}");
        }

        private async System.Threading.Tasks.Task SeedTaskAssignmentsAsync()
        {
            Console.WriteLine("👤 Seeding task assignments for all tasks...");

            var assignments = new List<TaskAssignment>();
            
            // Auto-assign all tasks to their creator
            // Each user gets their own 1000 tasks assigned to them
            foreach (var task in _tasks)
            {
                var creator = _users.FirstOrDefault(u => u.UserID == task.CreatorUserID);
                if (creator != null)
                {
                    var assignment = new TaskAssignment
                    {
                        TaskID = task.TaskID,
                        AssigneeUserID = creator.UserID,
                        AssignerUserID = creator.UserID, // Self-assigned
                        Status = task.Status == "Done" ? TaskAssignmentStatus.Approved : 
                                task.Status == "InProgress" ? TaskAssignmentStatus.InProgress :
                                TaskAssignmentStatus.Accepted,
                        AssignedAt = task.CreatedAt,
                        ResponseAt = task.CreatedAt.AddHours(1)
                    };

                    // If task is done, mark assignment as approved
                    if (task.Status == "Done" && task.CompletedAt.HasValue)
                    {
                        assignment.CompletionRequestedAt = task.CompletedAt.Value.AddHours(-1);
                        assignment.ApprovedAt = task.CompletedAt;
                        assignment.ApprovedByUserId = creator.UserID;
                    }

                    assignments.Add(assignment);
                }
            }

            await _context.TaskAssignments.AddRangeAsync(assignments);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {assignments.Count} task assignments");
        }

        private async System.Threading.Tasks.Task SeedTaskAssignmentHistoryAsync()
        {
            Console.WriteLine("📜 Seeding task assignment history...");

            var histories = new List<TaskAssignmentHistory>
            {
                // Task 3 was assigned, accepted, completed, and approved
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[3].TaskID,
                    AssigneeUserID = _users[1].UserID,
                    ActionByUserID = _users[0].UserID,
                    Action = "Assigned",
                    NewStatus = "Pending",
                    ActionAt = DateTime.UtcNow.AddDays(-7)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[3].TaskID,
                    AssigneeUserID = _users[1].UserID,
                    ActionByUserID = _users[1].UserID,
                    Action = "Accepted",
                    PreviousStatus = "Pending",
                    NewStatus = "Accepted",
                    ActionAt = DateTime.UtcNow.AddDays(-7).AddHours(1)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[3].TaskID,
                    AssigneeUserID = _users[1].UserID,
                    ActionByUserID = _users[1].UserID,
                    Action = "CompletionRequested",
                    PreviousStatus = "Accepted",
                    NewStatus = "CompletionRequested",
                    Note = "Task completed, please review",
                    ActionAt = DateTime.UtcNow.AddDays(-1)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[3].TaskID,
                    AssigneeUserID = _users[1].UserID,
                    ActionByUserID = _users[0].UserID,
                    Action = "Approved",
                    PreviousStatus = "CompletionRequested",
                    NewStatus = "Approved",
                    Note = "Good work!",
                    ActionAt = DateTime.UtcNow.AddDays(-1).AddHours(3)
                },

                // Task 6 was rejected
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[6].TaskID,
                    AssigneeUserID = _users[3].UserID,
                    ActionByUserID = _users[1].UserID,
                    Action = "Assigned",
                    NewStatus = "Pending",
                    ActionAt = DateTime.UtcNow.AddDays(-2)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[6].TaskID,
                    AssigneeUserID = _users[3].UserID,
                    ActionByUserID = _users[3].UserID,
                    Action = "Rejected",
                    PreviousStatus = "Pending",
                    NewStatus = "Rejected",
                    Note = "I don't have enough security knowledge for this task",
                    ActionAt = DateTime.UtcNow.AddDays(-2).AddHours(1)
                },

                // Task 2 completion request
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[2].TaskID,
                    AssigneeUserID = _users[2].UserID,
                    ActionByUserID = _users[0].UserID,
                    Action = "Assigned",
                    NewStatus = "Pending",
                    ActionAt = DateTime.UtcNow.AddDays(-6)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[2].TaskID,
                    AssigneeUserID = _users[2].UserID,
                    ActionByUserID = _users[2].UserID,
                    Action = "Accepted",
                    PreviousStatus = "Pending",
                    NewStatus = "Accepted",
                    ActionAt = DateTime.UtcNow.AddDays(-6).AddHours(1)
                },
                new TaskAssignmentHistory
                {
                    HistoryID = Guid.NewGuid(),
                    TaskID = _tasks[2].TaskID,
                    AssigneeUserID = _users[2].UserID,
                    ActionByUserID = _users[2].UserID,
                    Action = "CompletionRequested",
                    PreviousStatus = "Accepted",
                    NewStatus = "CompletionRequested",
                    Note = "Database integration completed",
                    ActionAt = DateTime.UtcNow.AddHours(-2)
                }
            };

            await _context.TaskAssignmentHistories.AddRangeAsync(histories);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {histories.Count} task assignment history records");
        }

        private async System.Threading.Tasks.Task SeedTaskTagsAsync()
        {
            Console.WriteLine("🔖 Seeding task tags...");

            var taskTags = new List<TaskTag>
            {
                // Task 0: Frontend + Feature
                new TaskTag { TaskID = _tasks[0].TaskID, TagID = _tags[0].TagID },
                new TaskTag { TaskID = _tasks[0].TaskID, TagID = _tags[4].TagID },

                // Task 1: Backend + Feature
                new TaskTag { TaskID = _tasks[1].TaskID, TagID = _tags[1].TagID },
                new TaskTag { TaskID = _tasks[1].TaskID, TagID = _tags[4].TagID },

                // Task 2: Backend
                new TaskTag { TaskID = _tasks[2].TaskID, TagID = _tags[1].TagID },

                // Task 3: Frontend + Bug
                new TaskTag { TaskID = _tasks[3].TaskID, TagID = _tags[0].TagID },
                new TaskTag { TaskID = _tasks[3].TaskID, TagID = _tags[3].TagID },

                // Task 5: iOS + Android
                new TaskTag { TaskID = _tasks[5].TaskID, TagID = _tags[5].TagID },
                new TaskTag { TaskID = _tasks[5].TaskID, TagID = _tags[6].TagID },

                // Task 6: Security
                new TaskTag { TaskID = _tasks[6].TaskID, TagID = _tags[8].TagID },

                // Task 7: Security
                new TaskTag { TaskID = _tasks[7].TaskID, TagID = _tags[8].TagID },

                // Task 8: Content
                new TaskTag { TaskID = _tasks[8].TaskID, TagID = _tags[10].TagID },

                // Task 9: Social Media
                new TaskTag { TaskID = _tasks[9].TaskID, TagID = _tags[9].TagID }
            };

            await _context.TaskTags.AddRangeAsync(taskTags);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {taskTags.Count} task-tag relationships");
        }

        private async System.Threading.Tasks.Task SeedCommentsAsync()
        {
            Console.WriteLine("💬 Seeding comments...");

            var comments = new List<Comment>
            {
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[0].TaskID,
                    UserID = _users[0].UserID,
                    Content = "Hãy tham khảo design từ đối thủ ABC để có ý tưởng",
                    CreatedAt = DateTime.UtcNow
                },
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[0].TaskID,
                    UserID = _users[1].UserID,
                    Content = "Ok anh, em sẽ research và đưa ra 3 phương án thiết kế",
                    CreatedAt = DateTime.UtcNow.AddMinutes(30)
                },
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[1].TaskID,
                    UserID = _users[2].UserID,
                    Content = "API đã xong phần đăng ký, đang làm phần login",
                    CreatedAt = DateTime.UtcNow.AddHours(-2)
                },
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[3].TaskID,
                    UserID = _users[1].UserID,
                    Content = "Bug này do state management không đúng, đang fix",
                    CreatedAt = DateTime.UtcNow.AddHours(-1)
                },
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[5].TaskID,
                    UserID = _users[2].UserID,
                    Content = "iOS version đã hoàn thành 80%",
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[9].TaskID,
                    UserID = _users[3].UserID,
                    Content = "Budget cho campaign này là 10 triệu đồng",
                    CreatedAt = DateTime.UtcNow.AddHours(-3)
                }
            };

            await _context.Comments.AddRangeAsync(comments);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {comments.Count} comments");
        }

        private async System.Threading.Tasks.Task SeedUserWeightsAsync()
        {
            Console.WriteLine("⚖️  Seeding user weights...");

            var weights = new List<UserTaskWeight>
            {
                // User A - Ưu tiên deadline
                new UserTaskWeight 
                { 
                    UserID = _users[0].UserID, 
                    DeadlineWeight = 0.6m, 
                    ImportanceWeight = 0.25m, 
                    EffortWeight = 0.15m, 
                    LastUpdatedAt = DateTime.UtcNow 
                },
                // User B - Ưu tiên importance
                new UserTaskWeight 
                { 
                    UserID = _users[1].UserID, 
                    DeadlineWeight = 0.3m, 
                    ImportanceWeight = 0.55m, 
                    EffortWeight = 0.15m, 
                    LastUpdatedAt = DateTime.UtcNow 
                },
                // User C - Cân bằng
                new UserTaskWeight 
                { 
                    UserID = _users[2].UserID, 
                    DeadlineWeight = 0.4m, 
                    ImportanceWeight = 0.35m, 
                    EffortWeight = 0.25m, 
                    LastUpdatedAt = DateTime.UtcNow 
                },
                // User D - Ưu tiên task nhanh
                new UserTaskWeight 
                { 
                    UserID = _users[3].UserID, 
                    DeadlineWeight = 0.25m, 
                    ImportanceWeight = 0.3m, 
                    EffortWeight = 0.45m, 
                    LastUpdatedAt = DateTime.UtcNow 
                }
            };

            await _context.UserTaskWeights.AddRangeAsync(weights);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {weights.Count} user weights");
        }

        private async System.Threading.Tasks.Task SeedUserInteractionsAsync()
        {
            Console.WriteLine("🤖 Seeding AI interactions...");

            var interactions = new List<UserTaskCompletionLog>
            {
                // User D hoàn thành task marketing
                new UserTaskCompletionLog
                {
                    UserID = _users[3].UserID,
                    TaskID = _tasks[10].TaskID,
                    CompletedTimestamp = DateTime.UtcNow.AddDays(-4),
                    DeadlineScore = 0.7m,
                    ImportanceScore = 0.6m,
                    EffortScore = 0.8m,
                    WasSuggested = true
                },
                // User B hoàn thành task banner
                new UserTaskCompletionLog
                {
                    UserID = _users[1].UserID,
                    TaskID = _tasks[11].TaskID,
                    CompletedTimestamp = DateTime.UtcNow.AddDays(-6),
                    DeadlineScore = 0.5m,
                    ImportanceScore = 1.0m,
                    EffortScore = 0.7m,
                    WasSuggested = true
                },
                // Thêm một số interaction giả lập từ quá khứ để có đủ data cho AI
                new UserTaskCompletionLog
                {
                    UserID = _users[1].UserID,
                    TaskID = _tasks[0].TaskID,
                    CompletedTimestamp = DateTime.UtcNow.AddDays(-10),
                    DeadlineScore = 0.9m,
                    ImportanceScore = 1.0m,
                    EffortScore = 0.6m,
                    WasSuggested = true
                },
                new UserTaskCompletionLog
                {
                    UserID = _users[1].UserID,
                    TaskID = _tasks[1].TaskID,
                    CompletedTimestamp = DateTime.UtcNow.AddDays(-12),
                    DeadlineScore = 0.8m,
                    ImportanceScore = 1.0m,
                    EffortScore = 0.7m,
                    WasSuggested = true
                },
                new UserTaskCompletionLog
                {
                    UserID = _users[2].UserID,
                    TaskID = _tasks[2].TaskID,
                    CompletedTimestamp = DateTime.UtcNow.AddDays(-15),
                    DeadlineScore = 0.6m,
                    ImportanceScore = 0.6m,
                    EffortScore = 0.5m,
                    WasSuggested = false
                }
            };

            await _context.UserTaskCompletionLogs.AddRangeAsync(interactions);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {interactions.Count} AI interactions");
        }

        private async System.Threading.Tasks.Task SeedNotificationsAsync()
        {
            Console.WriteLine("🔔 Seeding notifications...");

            var notifications = new List<Notification>
            {
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = _users[1].UserID,
                    Message = "Bạn được gán vào task \"Thiết kế giao diện trang chủ\"",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = _users[2].UserID,
                    Message = "Task \"Xây dựng API đăng nhập\" sắp đến hạn",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddHours(-1)
                },
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = _users[1].UserID,
                    Message = "Task \"Fix bug hiển thị giỏ hàng\" đã quá hạn!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddHours(-3)
                },
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = _users[3].UserID,
                    Message = "Bạn có 2 task ưu tiên cao cần hoàn thành tuần này",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = _users[0].UserID,
                    Message = "Trần Thị B đã comment vào task của bạn",
                    IsRead = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                }
            };

            await _context.Notifications.AddRangeAsync(notifications);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {notifications.Count} notifications");
        }

        private async System.Threading.Tasks.Task PrintSummaryAsync()
        {
            Console.WriteLine("");
            Console.WriteLine("========================================");
            Console.WriteLine("📊 SEED DATA SUMMARY");
            Console.WriteLine("========================================");
            Console.WriteLine($"Users:                {await _context.Users.CountAsync()}");
            Console.WriteLine($"Workspaces:           {await _context.Workspaces.CountAsync()}");
            Console.WriteLine($"Workspace Members:    {await _context.WorkspaceMembers.CountAsync()}");
            Console.WriteLine($"Tasks:                {await _context.Tasks.CountAsync()}");
            Console.WriteLine($"Task Assignments:     {await _context.TaskAssignments.CountAsync()}");
            Console.WriteLine($"Tags:                 {await _context.Tags.CountAsync()}");
            Console.WriteLine($"Task Tags:            {await _context.TaskTags.CountAsync()}");
            Console.WriteLine($"Comments:             {await _context.Comments.CountAsync()}");
            Console.WriteLine($"User Weights:         {await _context.UserTaskWeights.CountAsync()}");
            Console.WriteLine($"AI Interactions:      {await _context.UserTaskCompletionLogs.CountAsync()}");
            Console.WriteLine($"Notifications:        {await _context.Notifications.CountAsync()}");
            Console.WriteLine("========================================");
            Console.WriteLine("");
            Console.WriteLine("👤 TEST ACCOUNTS (Password: Password123):");
            foreach (var user in _users.Take(4))
            {
                Console.WriteLine($"   - {user.Email}");
            }
            Console.WriteLine($"   - {_users[4].Email} (Password: Admin123)");
            Console.WriteLine("");
            Console.WriteLine("🚀 Ready to test AI Priority Scoring!");
            Console.WriteLine("========================================");
        }

        public async System.Threading.Tasks.Task SeedLargeTaskDataForAITestingAsync()
        {
            Console.WriteLine("🤖 Starting AI Test Data Seeding (1000 tasks per user)...");

            // Check if we have users
            var users = await _context.Users.Where(u => u.SystemRoleID == 2).ToListAsync();
            if (!users.Any())
            {
                Console.WriteLine("⚠️  No regular users found. Please run SeedAsync() first.");
                return;
            }

            var workspaces = await _context.Workspaces.ToListAsync();
            if (!workspaces.Any())
            {
                Console.WriteLine("⚠️  No workspaces found. Please run SeedAsync() first.");
                return;
            }

            Console.WriteLine($"📋 Found {users.Count} users and {workspaces.Count} workspaces");

            var random = new Random(42); // Fixed seed for reproducibility
            var tasksToAdd = new List<Task>();
            var assignmentsToAdd = new List<TaskAssignment>();

            string[] statuses = { "ToDo", "InProgress", "Done", "Overdue" };
            string[] priorities = { "Low", "Medium", "High" };
            
            string[] taskTitles = {
                "Implement feature", "Fix bug in", "Design UI for", "Write tests for",
                "Update documentation", "Review code", "Optimize performance", "Refactor",
                "Create API endpoint", "Database migration", "Security audit", "Setup CI/CD",
                "User research", "Create wireframe", "Integration testing", "Deploy to production",
                "Code review meeting", "Sprint planning", "Bug triage", "Performance testing"
            };

            string[] taskDescriptions = {
                "High priority task requiring immediate attention",
                "Medium complexity work item",
                "Quick task that can be completed in a few hours",
                "Complex task requiring coordination with team",
                "Routine maintenance work",
                "Critical bug affecting production",
                "Enhancement request from stakeholders",
                "Technical debt reduction",
                "Customer-facing feature",
                "Internal tooling improvement"
            };

            int totalTasks = 0;

            foreach (var user in users)
            {
                Console.WriteLine($"   Creating 1000 tasks for user {user.FullName}...");

                // Get workspaces where this user is a member
                var userWorkspaces = await _context.WorkspaceMembers
                    .Where(wm => wm.UserID == user.UserID)
                    .Select(wm => wm.WorkspaceID)
                    .ToListAsync();

                if (!userWorkspaces.Any())
                {
                    Console.WriteLine($"   ⚠️  User {user.FullName} has no workspace memberships. Skipping...");
                    continue;
                }

                for (int i = 0; i < 1000; i++)
                {
                    var workspaceId = userWorkspaces[random.Next(userWorkspaces.Count)];
                    
                    // Generate varied deadlines (30% overdue, 20% today-3days, 30% 4-14days, 20% 15-60days)
                    DateTime deadline;
                    double deadlineRand = random.NextDouble();
                    if (deadlineRand < 0.30) // 30% overdue
                    {
                        deadline = DateTime.UtcNow.AddDays(-random.Next(1, 15));
                    }
                    else if (deadlineRand < 0.50) // 20% urgent (0-3 days)
                    {
                        deadline = DateTime.UtcNow.AddDays(random.Next(0, 4));
                    }
                    else if (deadlineRand < 0.80) // 30% medium term (4-14 days)
                    {
                        deadline = DateTime.UtcNow.AddDays(random.Next(4, 15));
                    }
                    else // 20% long term (15-60 days)
                    {
                        deadline = DateTime.UtcNow.AddDays(random.Next(15, 61));
                    }

                    // Generate status based on deadline
                    string status;
                    if (deadline < DateTime.UtcNow && random.NextDouble() < 0.7)
                    {
                        status = "Overdue";
                    }
                    else if (random.NextDouble() < 0.15)
                    {
                        status = "Done";
                    }
                    else if (random.NextDouble() < 0.3)
                    {
                        status = "InProgress";
                    }
                    else
                    {
                        status = "ToDo";
                    }

                    // Varied priorities (25% Low, 45% Medium, 30% High)
                    string priority;
                    double priorityRand = random.NextDouble();
                    if (priorityRand < 0.25)
                        priority = "Low";
                    else if (priorityRand < 0.70)
                        priority = "Medium";
                    else
                        priority = "High";

                    // Varied estimated time (20% quick <60min, 50% medium 60-240min, 30% long 240-480min)
                    int estimatedTime;
                    double timeRand = random.NextDouble();
                    if (timeRand < 0.20)
                        estimatedTime = random.Next(15, 61); // Quick tasks
                    else if (timeRand < 0.70)
                        estimatedTime = random.Next(60, 241); // Medium tasks
                    else
                        estimatedTime = random.Next(240, 481); // Long tasks

                    var taskTitle = $"{taskTitles[random.Next(taskTitles.Length)]} #{i + 1}";
                    var taskDescription = taskDescriptions[random.Next(taskDescriptions.Length)];

                    var newTask = new Task
                    {
                        TaskID = Guid.NewGuid(),
                        WorkspaceID = workspaceId,
                        Title = taskTitle,
                        Description = taskDescription,
                        Status = status,
                        Priority = priority,
                        Deadline = deadline,
                        EstimatedTimeMinutes = estimatedTime,
                        CreatorUserID = user.UserID,
                        CreatedAt = DateTime.UtcNow.AddDays(-random.Next(0, 30)),
                        CompletedAt = status == "Done" ? DateTime.UtcNow.AddDays(-random.Next(1, 10)) : null
                    };

                    tasksToAdd.Add(newTask);

                    // Create task assignment
                    assignmentsToAdd.Add(new TaskAssignment
                    {
                        TaskID = newTask.TaskID,
                        AssigneeUserID = user.UserID,
                        AssignedAt = newTask.CreatedAt
                    });

                    totalTasks++;

                    // Save in batches of 500 to avoid memory issues
                    if (tasksToAdd.Count >= 500)
                    {
                        await _context.Tasks.AddRangeAsync(tasksToAdd);
                        await _context.TaskAssignments.AddRangeAsync(assignmentsToAdd);
                        await _context.SaveChangesAsync();
                        
                        Console.WriteLine($"      Progress: {totalTasks} tasks created...");
                        
                        tasksToAdd.Clear();
                        assignmentsToAdd.Clear();
                    }
                }

                Console.WriteLine($"   ✓ Completed 1000 tasks for {user.FullName}");
            }

            // Save remaining tasks
            if (tasksToAdd.Any())
            {
                await _context.Tasks.AddRangeAsync(tasksToAdd);
                await _context.TaskAssignments.AddRangeAsync(assignmentsToAdd);
                await _context.SaveChangesAsync();
            }

            Console.WriteLine("");
            Console.WriteLine("========================================");
            Console.WriteLine("✅ AI TEST DATA SEEDING COMPLETED!");
            Console.WriteLine("========================================");
            Console.WriteLine($"Total Tasks Created:     {totalTasks}");
            Console.WriteLine($"Tasks Per User:          {totalTasks / users.Count}");
            Console.WriteLine($"Users with Tasks:        {users.Count}");
            Console.WriteLine("");
            Console.WriteLine("📊 TASK DISTRIBUTION:");
            
            var tasksByStatus = await _context.Tasks.GroupBy(t => t.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();
            
            foreach (var stat in tasksByStatus)
            {
                Console.WriteLine($"   {stat.Status,-15} {stat.Count,6} tasks");
            }
            
            Console.WriteLine("");
            
            var tasksByPriority = await _context.Tasks.GroupBy(t => t.Priority)
                .Select(g => new { Priority = g.Key, Count = g.Count() })
                .ToListAsync();
            
            foreach (var stat in tasksByPriority)
            {
                Console.WriteLine($"   {stat.Priority,-15} {stat.Count,6} tasks");
            }
            
            Console.WriteLine("========================================");
            Console.WriteLine("🤖 Ready to test AI Priority Scoring with large dataset!");
            Console.WriteLine("========================================");
        }
    }
}
