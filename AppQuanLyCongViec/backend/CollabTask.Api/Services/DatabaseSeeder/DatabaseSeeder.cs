using CollabTask.Api.Data;
using CollabTask.Api.Models;
using Microsoft.EntityFrameworkCore;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Services.DatabaseSeeder
{
    /// <summary>
    /// Database Seeder với Dynamic Date - Dữ liệu luôn "tươi mới" so với DateTime.UtcNow
    /// Version 2.0 - Tối ưu cho AI Priority Scoring Demo
    /// </summary>
    public class DatabaseSeeder : IDatabaseSeeder
    {
        private readonly CollabTaskDbContext _context;

        private List<User> _users = new();
        private List<Workspace> _workspaces = new();
        private List<Tag> _tags = new();
        private List<Task> _tasks = new();

        // =====================================================
        // CONSTANTS CHO 6 PERSONAS
        // =====================================================
        private static readonly Guid AliceId = Guid.Parse("11111111-1111-1111-1111-111111111111");
        private static readonly Guid BobId = Guid.Parse("22222222-2222-2222-2222-222222222222");
        private static readonly Guid CharlieId = Guid.Parse("33333333-3333-3333-3333-333333333333");
        private static readonly Guid DianaId = Guid.Parse("44444444-4444-4444-4444-444444444444");
        private static readonly Guid EveId = Guid.Parse("55555555-5555-5555-5555-555555555555");
        private static readonly Guid FrankId = Guid.Parse("66666666-6666-6666-6666-666666666666");

        public DatabaseSeeder(CollabTaskDbContext context)
        {
            _context = context;
        }

        public async System.Threading.Tasks.Task SeedAsync()
        {
            Console.WriteLine("🌱 Starting database seeding (Dynamic Date Mode)...");
            Console.WriteLine($"   📅 Current UTC Time: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}");

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
            
            // CORE: Seed tasks với Dynamic Date cho từng persona
            await SeedDynamicTasksForAllPersonasAsync();
            
            await SeedUserWeightsAsync();
            await SeedCommentsAsync();
            await SeedNotificationsAsync();

            Console.WriteLine("✅ Database seeding completed successfully!");
            await PrintSummaryAsync();
        }

        public async System.Threading.Tasks.Task ClearDataAsync()
        {
            Console.WriteLine("🗑️  Clearing database...");

            // Order matters due to foreign key constraints
            // Note: UserTaskCompletionLog is mapped to UserInteractionsForAI table in DbContext
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM UserInteractionsForAI");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM UserTaskWeights");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM ActivityLogs");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Notifications");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Comments");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskTags");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Tags");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskAssignmentHistories");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskAssignments");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM TaskAttachments");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Tasks");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM WorkspaceInvitations");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM WorkspaceMembers");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Workspaces");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM Users");

            Console.WriteLine("✅ Database cleared!");
        }

        private async System.Threading.Tasks.Task SeedSystemRolesAsync()
        {
            Console.WriteLine("🔐 Seeding system roles...");

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
            Console.WriteLine("👥 Seeding 6 AI Personas...");

            var userRole = await _context.SystemRoles.FirstOrDefaultAsync(r => r.RoleName == "User");
            if (userRole == null)
            {
                throw new InvalidOperationException("User role not found. Please seed SystemRoles first.");
            }

            string passwordHash = BCrypt.Net.BCrypt.HashPassword("Password123");

            _users = new List<User>
            {
                // PERSONA 1: Alice - Perfect Performer (Thích làm xong trước hạn)
                new User
                {
                    UserID = AliceId,
                    FullName = "Alice Perfect",
                    Email = "alice@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                
                // PERSONA 2: Bob - Deadline Misser (Chuyên trễ hạn)
                new User
                {
                    UserID = BobId,
                    FullName = "Bob Late",
                    Email = "bob@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                
                // PERSONA 3: Charlie - Easy Task First (Thích việc nhẹ)
                new User
                {
                    UserID = CharlieId,
                    FullName = "Charlie Quick",
                    Email = "charlie@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                
                // PERSONA 4: Diana - High Priority First (Chỉ quan tâm độ quan trọng)
                new User
                {
                    UserID = DianaId,
                    FullName = "Diana Focus",
                    Email = "diana@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                
                // PERSONA 5: Eve - Procrastinator (Nước đến chân mới nhảy)
                new User
                {
                    UserID = EveId,
                    FullName = "Eve Procrastinate",
                    Email = "eve@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                },
                
                // PERSONA 6: Frank - Balanced (Baseline so sánh)
                new User
                {
                    UserID = FrankId,
                    FullName = "Frank Balanced",
                    Email = "frank@example.com",
                    PasswordHash = passwordHash,
                    SystemRoleID = userRole.RoleID,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                }
            };

            await _context.Users.AddRangeAsync(_users);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_users.Count} personas");
        }

        private async System.Threading.Tasks.Task SeedWorkspacesAsync()
        {
            Console.WriteLine("🏢 Seeding workspace...");

            _workspaces = new List<Workspace>
            {
                new Workspace
                {
                    WorkspaceID = Guid.NewGuid(),
                    WorkspaceName = "AI Demo Workspace",
                    Description = "Workspace for testing AI Priority Scoring with 6 personas",
                    OwnerUserID = AliceId,
                    IsPersonal = false,
                    CreatedAt = DateTime.UtcNow.AddMonths(-6)
                }
            };

            await _context.Workspaces.AddRangeAsync(_workspaces);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_workspaces.Count} workspace");
        }

        private async System.Threading.Tasks.Task SeedWorkspaceMembersAsync()
        {
            Console.WriteLine("👨‍💼 Seeding workspace members...");

            var members = new List<WorkspaceMember>();
            var roles = new[] { "Owner", "Member", "Member", "Member", "Member", "Member" };

            for (int i = 0; i < _users.Count; i++)
            {
                members.Add(new WorkspaceMember
                {
                    WorkspaceID = _workspaces[0].WorkspaceID,
                    UserID = _users[i].UserID,
                    Role = roles[i],
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
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Frontend", Color = "#3498db" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Backend", Color = "#2ecc71" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Bug", Color = "#e74c3c" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Feature", Color = "#f39c12" },
                new Tag { WorkspaceID = _workspaces[0].WorkspaceID, TagName = "Urgent", Color = "#c0392b" }
            };

            await _context.Tags.AddRangeAsync(_tags);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {_tags.Count} tags");
        }

        // =====================================================
        // CORE: DYNAMIC TASK SEEDING CHO 6 PERSONAS
        // =====================================================
        private async System.Threading.Tasks.Task SeedDynamicTasksForAllPersonasAsync()
        {
            Console.WriteLine("📝 Generating Dynamic Tasks for 6 Personas...");
            
            var now = DateTime.UtcNow;
            var workspaceId = _workspaces[0].WorkspaceID;
            
            _tasks = new List<Task>();
            var assignments = new List<TaskAssignment>();

            // =====================================================
            // PERSONA 1: ALICE PERFECT (Thích làm xong trước hạn)
            // - 5 Tasks ToDo/InProgress
            // - Deadline: T+3 đến T+7 ngày (tương lai xa)
            // - Priority: 3 High, 2 Medium
            // =====================================================
            Console.WriteLine("   👩 Alice Perfect - Deadline tương lai, High Priority...");
            
            var aliceTasks = new List<Task>
            {
                CreateTask("Thiết kế Dashboard UI", workspaceId, AliceId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(3).AddHours(10),
                    estimatedMinutes: 180),
                    
                CreateTask("Implement User Authentication", workspaceId, AliceId, 
                    status: "InProgress", 
                    priority: "High", 
                    deadline: now.AddDays(4),
                    estimatedMinutes: 240),
                    
                CreateTask("Setup CI/CD Pipeline", workspaceId, AliceId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(5),
                    estimatedMinutes: 120),
                    
                CreateTask("Write API Documentation", workspaceId, AliceId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(6),
                    estimatedMinutes: 90),
                    
                CreateTask("Code Review Sprint Tasks", workspaceId, AliceId, 
                    status: "InProgress", 
                    priority: "Medium", 
                    deadline: now.AddDays(7),
                    estimatedMinutes: 60)
            };
            
            _tasks.AddRange(aliceTasks);
            assignments.AddRange(CreateAssignments(aliceTasks, AliceId));

            // =====================================================
            // PERSONA 2: BOB LATE (Chuyên trễ hạn - DeadlineMisser)
            // - 3 Tasks ĐÃ OVERDUE
            // - 2 Tasks sắp đến hạn
            // =====================================================
            Console.WriteLine("   👨 Bob Late - 3 Overdue + 2 Sắp hạn...");
            
            var bobTasks = new List<Task>
            {
                // 🔴 OVERDUE TASKS (Deadline trong quá khứ)
                CreateTask("⚠️ [OVERDUE] Fix Critical Security Bug", workspaceId, BobId, 
                    status: "InProgress", 
                    priority: "High", 
                    deadline: now.AddDays(-2),  // Quá hạn 2 ngày
                    estimatedMinutes: 180),
                    
                CreateTask("⚠️ [OVERDUE] Update Payment Gateway", workspaceId, BobId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddHours(-5),  // Quá hạn 5 giờ
                    estimatedMinutes: 240),
                    
                CreateTask("⚠️ [OVERDUE] Database Migration Script", workspaceId, BobId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(-1),  // Quá hạn 1 ngày
                    estimatedMinutes: 120),
                
                // 🟡 SẮP ĐẾN HẠN
                CreateTask("Refactor Authentication Module", workspaceId, BobId, 
                    status: "InProgress", 
                    priority: "Medium", 
                    deadline: now.AddHours(6),  // Còn 6 giờ
                    estimatedMinutes: 150),
                    
                CreateTask("Deploy Hotfix to Production", workspaceId, BobId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(1),  // Còn 1 ngày
                    estimatedMinutes: 60)
            };
            
            _tasks.AddRange(bobTasks);
            assignments.AddRange(CreateAssignments(bobTasks, BobId));

            // =====================================================
            // PERSONA 3: CHARLIE QUICK (Thích việc nhẹ - EasyTaskFirst)
            // - 5 Tasks ngắn (15-45 phút)
            // - 5 Tasks dài (> 180 phút)
            // =====================================================
            Console.WriteLine("   👦 Charlie Quick - 5 Short + 5 Long Tasks...");
            
            var charlieTasks = new List<Task>
            {
                // ⚡ QUICK TASKS (15-45 phút) - AI phải gợi ý đầu tiên
                CreateTask("⚡ Quick: Update README.md", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddDays(5),
                    estimatedMinutes: 15),
                    
                CreateTask("⚡ Quick: Fix Typo in Homepage", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddDays(6),
                    estimatedMinutes: 20),
                    
                CreateTask("⚡ Quick: Update .env.example", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(3),
                    estimatedMinutes: 25),
                    
                CreateTask("⚡ Quick: Add Loading Spinner", workspaceId, CharlieId, 
                    status: "InProgress", 
                    priority: "Low", 
                    deadline: now.AddDays(4),
                    estimatedMinutes: 30),
                    
                CreateTask("⚡ Quick: Configure ESLint Rules", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(2),
                    estimatedMinutes: 45),
                
                // 🐢 LONG TASKS (> 180 phút) - AI không nên gợi ý
                CreateTask("🐢 Long: Implement Search Engine", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(1),  // Gấp hơn nhưng dài
                    estimatedMinutes: 480),
                    
                CreateTask("🐢 Long: Build Admin Dashboard", workspaceId, CharlieId, 
                    status: "InProgress", 
                    priority: "High", 
                    deadline: now.AddDays(2),
                    estimatedMinutes: 360),
                    
                CreateTask("🐢 Long: Database Optimization", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(3),
                    estimatedMinutes: 300),
                    
                CreateTask("🐢 Long: Write Integration Tests", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddHours(12),  // Rất gấp nhưng rất dài
                    estimatedMinutes: 240),
                    
                CreateTask("🐢 Long: Implement Caching Layer", workspaceId, CharlieId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddDays(4),
                    estimatedMinutes: 200)
            };
            
            _tasks.AddRange(charlieTasks);
            assignments.AddRange(CreateAssignments(charlieTasks, CharlieId));

            // =====================================================
            // PERSONA 4: DIANA FOCUS (Chỉ quan tâm độ quan trọng)
            // - 3 Tasks High (deadline xa)
            // - 3 Tasks Low (deadline gần)
            // AI phải xếp High lên trên Low dù Low gấp hơn
            // =====================================================
            Console.WriteLine("   👩‍💼 Diana Focus - 3 High (xa) vs 3 Low (gần)...");
            
            var dianaTasks = new List<Task>
            {
                // 🔴 HIGH PRIORITY (deadline xa) - AI phải gợi ý đầu tiên
                CreateTask("🔴 HIGH: Architect Microservices", workspaceId, DianaId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(14),  // Xa nhưng quan trọng
                    estimatedMinutes: 480),
                    
                CreateTask("🔴 HIGH: Security Audit", workspaceId, DianaId, 
                    status: "InProgress", 
                    priority: "High", 
                    deadline: now.AddDays(10),
                    estimatedMinutes: 360),
                    
                CreateTask("🔴 HIGH: Performance Optimization", workspaceId, DianaId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddDays(7),
                    estimatedMinutes: 300),
                
                // 🟢 LOW PRIORITY (deadline gần) - AI không nên ưu tiên
                CreateTask("🟢 LOW: Update Footer Links", workspaceId, DianaId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddHours(3),  // Rất gấp nhưng không quan trọng
                    estimatedMinutes: 30),
                    
                CreateTask("🟢 LOW: Fix Minor CSS Bug", workspaceId, DianaId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddHours(6),
                    estimatedMinutes: 45),
                    
                CreateTask("🟢 LOW: Update Copyright Year", workspaceId, DianaId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddDays(1),
                    estimatedMinutes: 15)
            };
            
            _tasks.AddRange(dianaTasks);
            assignments.AddRange(CreateAssignments(dianaTasks, DianaId));

            // =====================================================
            // PERSONA 5: EVE PROCRASTINATE (Nước đến chân mới nhảy)
            // - Tasks có deadline cực gần (T+1h, T+3h, T+6h)
            // =====================================================
            Console.WriteLine("   👩‍🎤 Eve Procrastinate - Deadline cực gần...");
            
            var eveTasks = new List<Task>
            {
                CreateTask("🔥 URGENT: Submit Report (1h left)", workspaceId, EveId, 
                    status: "InProgress", 
                    priority: "High", 
                    deadline: now.AddHours(1),  // Còn 1 giờ!
                    estimatedMinutes: 45),
                    
                CreateTask("🔥 URGENT: Fix Prod Bug (2h left)", workspaceId, EveId, 
                    status: "ToDo", 
                    priority: "High", 
                    deadline: now.AddHours(2),
                    estimatedMinutes: 60),
                    
                CreateTask("🔥 URGENT: Deploy Hotfix (3h left)", workspaceId, EveId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddHours(3),
                    estimatedMinutes: 30),
                    
                CreateTask("⏰ Soon: Review PR (6h left)", workspaceId, EveId, 
                    status: "ToDo", 
                    priority: "Medium", 
                    deadline: now.AddHours(6),
                    estimatedMinutes: 90),
                    
                CreateTask("⏰ Soon: Update Docs (12h left)", workspaceId, EveId, 
                    status: "ToDo", 
                    priority: "Low", 
                    deadline: now.AddHours(12),
                    estimatedMinutes: 60)
            };
            
            _tasks.AddRange(eveTasks);
            assignments.AddRange(CreateAssignments(eveTasks, EveId));

            // =====================================================
            // PERSONA 6: FRANK BALANCED (Baseline - Random mix)
            // =====================================================
            Console.WriteLine("   👨‍💻 Frank Balanced - Random baseline...");
            
            var random = new Random(42);
            var frankTasks = new List<Task>();
            
            for (int i = 1; i <= 8; i++)
            {
                var priorities = new[] { "Low", "Medium", "High" };
                var statuses = new[] { "ToDo", "InProgress" };
                
                frankTasks.Add(CreateTask(
                    $"Frank Task #{i}", 
                    workspaceId, 
                    FrankId,
                    status: statuses[random.Next(statuses.Length)],
                    priority: priorities[random.Next(priorities.Length)],
                    deadline: now.AddDays(random.Next(1, 10)),
                    estimatedMinutes: random.Next(30, 300)
                ));
            }
            
            _tasks.AddRange(frankTasks);
            assignments.AddRange(CreateAssignments(frankTasks, FrankId));

            // Save all tasks and assignments
            await _context.Tasks.AddRangeAsync(_tasks);
            await _context.TaskAssignments.AddRangeAsync(assignments);
            await _context.SaveChangesAsync();

            // Print statistics
            Console.WriteLine($"\n   📊 Task Statistics:");
            Console.WriteLine($"      Total Tasks: {_tasks.Count}");
            Console.WriteLine($"      - Alice: {aliceTasks.Count} (Future deadlines)");
            Console.WriteLine($"      - Bob: {bobTasks.Count} (3 Overdue + 2 Soon)");
            Console.WriteLine($"      - Charlie: {charlieTasks.Count} (5 Quick + 5 Long)");
            Console.WriteLine($"      - Diana: {dianaTasks.Count} (3 High + 3 Low)");
            Console.WriteLine($"      - Eve: {eveTasks.Count} (All urgent)");
            Console.WriteLine($"      - Frank: {frankTasks.Count} (Random)");
            
            var overdueCount = _tasks.Count(t => t.Deadline.HasValue && t.Deadline < now && t.Status != "Done");
            Console.WriteLine($"      - Overdue Tasks: {overdueCount}");
        }

        // =====================================================
        // USER WEIGHTS CHO 6 PERSONAS (Cold Start Prevention)
        // =====================================================
        private async System.Threading.Tasks.Task SeedUserWeightsAsync()
        {
            Console.WriteLine("⚖️  Seeding User Weights for AI...");

            var weights = new List<UserTaskWeight>
            {
                // Alice: Ưu tiên deadline vừa phải, quan tâm importance
                new UserTaskWeight 
                { 
                    UserID = AliceId, 
                    DeadlineWeight = 0.6m, 
                    ImportanceWeight = 0.3m, 
                    EffortWeight = 0.1m,
                    DominantTrait = UserTrait.Procrastinator, // Deadline-focused
                    LastUpdatedAt = DateTime.UtcNow 
                },
                
                // Bob: Cực kỳ ưu tiên deadline (để overdue tasks hiện lên đầu)
                new UserTaskWeight 
                { 
                    UserID = BobId, 
                    DeadlineWeight = 0.9m, 
                    ImportanceWeight = 0.1m, 
                    EffortWeight = 0.0m,
                    DominantTrait = UserTrait.Procrastinator, // Nước đến chân
                    LastUpdatedAt = DateTime.UtcNow 
                },
                
                // Charlie: Cực kỳ ưu tiên effort thấp (task nhanh)
                new UserTaskWeight 
                { 
                    UserID = CharlieId, 
                    DeadlineWeight = 0.1m, 
                    ImportanceWeight = 0.1m, 
                    EffortWeight = 0.8m,
                    DominantTrait = UserTrait.Sprinter, // Thích việc nhanh
                    LastUpdatedAt = DateTime.UtcNow 
                },
                
                // Diana: Cực kỳ ưu tiên importance
                new UserTaskWeight 
                { 
                    UserID = DianaId, 
                    DeadlineWeight = 0.1m, 
                    ImportanceWeight = 0.8m, 
                    EffortWeight = 0.1m,
                    DominantTrait = UserTrait.Planner, // Quan tâm quan trọng
                    LastUpdatedAt = DateTime.UtcNow 
                },
                
                // Eve: Ưu tiên deadline (giống Bob nhưng khác context)
                new UserTaskWeight 
                { 
                    UserID = EveId, 
                    DeadlineWeight = 0.8m, 
                    ImportanceWeight = 0.1m, 
                    EffortWeight = 0.1m,
                    DominantTrait = UserTrait.Procrastinator,
                    LastUpdatedAt = DateTime.UtcNow 
                },
                
                // Frank: Balanced (baseline)
                new UserTaskWeight 
                { 
                    UserID = FrankId, 
                    DeadlineWeight = 0.4m, 
                    ImportanceWeight = 0.35m, 
                    EffortWeight = 0.25m,
                    DominantTrait = UserTrait.Unknown,
                    LastUpdatedAt = DateTime.UtcNow 
                }
            };

            await _context.UserTaskWeights.AddRangeAsync(weights);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {weights.Count} user weights");
            Console.WriteLine("   📋 Weight Configuration:");
            Console.WriteLine("      - Alice: D=0.6, I=0.3, E=0.1 (Deadline-focused)");
            Console.WriteLine("      - Bob:   D=0.9, I=0.1, E=0.0 (Overdue-aware)");
            Console.WriteLine("      - Charlie: D=0.1, I=0.1, E=0.8 (Quick tasks)");
            Console.WriteLine("      - Diana: D=0.1, I=0.8, E=0.1 (Priority-focused)");
            Console.WriteLine("      - Eve:   D=0.8, I=0.1, E=0.1 (Deadline-urgent)");
            Console.WriteLine("      - Frank: D=0.4, I=0.35, E=0.25 (Balanced)");
        }

        // =====================================================
        // HELPER METHODS
        // =====================================================
        
        private Task CreateTask(
            string title, 
            Guid workspaceId, 
            Guid creatorId,
            string status,
            string priority,
            DateTime deadline,
            int estimatedMinutes)
        {
            return new Task
            {
                TaskID = Guid.NewGuid(),
                WorkspaceID = workspaceId,
                Title = title,
                Description = $"Auto-generated task for AI testing. Created at {DateTime.UtcNow:yyyy-MM-dd HH:mm}",
                Status = status,
                Priority = priority,
                Deadline = deadline,
                EstimatedTimeMinutes = estimatedMinutes,
                CreatorUserID = creatorId,
                CreatedAt = DateTime.UtcNow.AddDays(-1),
                CompletedAt = null
            };
        }

        private List<TaskAssignment> CreateAssignments(List<Task> tasks, Guid userId)
        {
            return tasks.Select(t => new TaskAssignment
            {
                TaskID = t.TaskID,
                AssigneeUserID = userId,
                AssignerUserID = userId,
                Status = t.Status == "InProgress" ? TaskAssignmentStatus.InProgress : TaskAssignmentStatus.Accepted,
                AssignedAt = t.CreatedAt,
                ResponseAt = t.CreatedAt.AddHours(1)
            }).ToList();
        }

        private async System.Threading.Tasks.Task SeedCommentsAsync()
        {
            Console.WriteLine("💬 Seeding sample comments...");

            var comments = new List<Comment>
            {
                new Comment
                {
                    CommentID = Guid.NewGuid(),
                    TaskID = _tasks[0].TaskID,
                    UserID = AliceId,
                    Content = "Đang thiết kế wireframe, dự kiến xong trước deadline 2 ngày",
                    CreatedAt = DateTime.UtcNow.AddHours(-2)
                }
            };

            await _context.Comments.AddRangeAsync(comments);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {comments.Count} comments");
        }

        private async System.Threading.Tasks.Task SeedNotificationsAsync()
        {
            Console.WriteLine("🔔 Seeding notifications...");

            var notifications = new List<Notification>
            {
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = BobId,
                    Message = "⚠️ Bạn có 3 task đã quá hạn cần xử lý ngay!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddMinutes(-30)
                },
                new Notification
                {
                    NotificationID = Guid.NewGuid(),
                    UserID = EveId,
                    Message = "🔥 Task 'Submit Report' chỉ còn 1 giờ để hoàn thành!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddMinutes(-10)
                }
            };

            await _context.Notifications.AddRangeAsync(notifications);
            await _context.SaveChangesAsync();

            Console.WriteLine($"   ✓ Created {notifications.Count} notifications");
        }

        private async System.Threading.Tasks.Task PrintSummaryAsync()
        {
            Console.WriteLine("");
            Console.WriteLine("╔══════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║                    📊 SEED DATA SUMMARY                      ║");
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            Console.WriteLine($"║  Users:              {await _context.Users.CountAsync(),5}                                  ║");
            Console.WriteLine($"║  Workspaces:         {await _context.Workspaces.CountAsync(),5}                                  ║");
            Console.WriteLine($"║  Tasks:              {await _context.Tasks.CountAsync(),5}                                  ║");
            Console.WriteLine($"║  Task Assignments:   {await _context.TaskAssignments.CountAsync(),5}                                  ║");
            Console.WriteLine($"║  User Weights:       {await _context.UserTaskWeights.CountAsync(),5}                                  ║");
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            Console.WriteLine("║  👤 TEST ACCOUNTS (Password: Password123)                    ║");
            Console.WriteLine("║    - alice@example.com   (Perfect Performer)                 ║");
            Console.WriteLine("║    - bob@example.com     (Deadline Misser - 3 Overdue)       ║");
            Console.WriteLine("║    - charlie@example.com (Easy Task First)                   ║");
            Console.WriteLine("║    - diana@example.com   (High Priority First)               ║");
            Console.WriteLine("║    - eve@example.com     (Procrastinator)                    ║");
            Console.WriteLine("║    - frank@example.com   (Balanced Baseline)                 ║");
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            Console.WriteLine("║  🎯 EXPECTED AI BEHAVIOR:                                    ║");
            Console.WriteLine("║    - Alice: High priority tasks first                        ║");
            Console.WriteLine("║    - Bob:   OVERDUE tasks at TOP (Red warning)               ║");
            Console.WriteLine("║    - Charlie: 15-45min tasks before 180min+ tasks            ║");
            Console.WriteLine("║    - Diana: High > Low (even if Low is more urgent)          ║");
            Console.WriteLine("║    - Eve: Tasks with 1-3h deadline first                     ║");
            Console.WriteLine("╚══════════════════════════════════════════════════════════════╝");
        }

        /// <summary>
        /// Tạo 1000 tasks/user để đánh giá khả năng AI sorting dựa trên thói quen
        /// Mỗi user có đặc điểm riêng biệt để test weight-based ranking
        /// </summary>
        public async System.Threading.Tasks.Task SeedLargeTaskDataForAITestingAsync()
        {
            Console.WriteLine("🚀 Starting Large-Scale AI Test Data Seeding (1000 tasks/user)...");
            Console.WriteLine($"   📅 Current UTC Time: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}");

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
            
            // CORE: Generate 1000 tasks per user
            await SeedLargeScaleTasksAsync();
            
            await SeedUserWeightsAsync();

            Console.WriteLine("✅ Large-scale AI test data seeding completed!");
            await PrintLargeScaleSummaryAsync();
        }

        /// <summary>
        /// Generate 1000 tasks per user với phân bố đặc trưng cho từng persona
        /// </summary>
        private async System.Threading.Tasks.Task SeedLargeScaleTasksAsync()
        {
            Console.WriteLine("📝 Generating 1000 Tasks per User (6000 total)...");
            
            var now = DateTime.UtcNow;
            var workspaceId = _workspaces[0].WorkspaceID;
            var random = new Random(42); // Fixed seed for reproducibility
            
            var allTasks = new List<Task>();
            var allAssignments = new List<TaskAssignment>();

            // =====================================================
            // DISTRIBUTION PATTERNS CHO 6 PERSONAS
            // =====================================================
            
            var userPatterns = new Dictionary<Guid, TaskDistributionPattern>
            {
                // ALICE: Deadline-focused (60% near deadline, 30% medium, 10% far)
                { AliceId, new TaskDistributionPattern 
                    { 
                        NearDeadlinePercent = 60, 
                        MediumDeadlinePercent = 30,
                        HighPriorityPercent = 50,
                        MediumPriorityPercent = 35,
                        ShortTaskPercent = 30,
                        MediumTaskPercent = 50
                    }
                },
                
                // BOB: Overdue-heavy (40% overdue, 30% near, 20% medium, 10% far)
                { BobId, new TaskDistributionPattern 
                    { 
                        OverduePercent = 40,
                        NearDeadlinePercent = 30, 
                        MediumDeadlinePercent = 20,
                        HighPriorityPercent = 60,
                        MediumPriorityPercent = 30,
                        ShortTaskPercent = 25,
                        MediumTaskPercent = 45
                    }
                },
                
                // CHARLIE: Quick tasks lover (70% short, 20% medium, 10% long)
                { CharlieId, new TaskDistributionPattern 
                    { 
                        NearDeadlinePercent = 30, 
                        MediumDeadlinePercent = 40,
                        HighPriorityPercent = 30,
                        MediumPriorityPercent = 40,
                        ShortTaskPercent = 70,
                        MediumTaskPercent = 20
                    }
                },
                
                // DIANA: Priority-focused (80% high priority với deadline xa)
                { DianaId, new TaskDistributionPattern 
                    { 
                        NearDeadlinePercent = 20, 
                        MediumDeadlinePercent = 30,
                        HighPriorityPercent = 80,
                        MediumPriorityPercent = 15,
                        ShortTaskPercent = 25,
                        MediumTaskPercent = 45
                    }
                },
                
                // EVE: Procrastinator (80% near deadline, deadline cực gần)
                { EveId, new TaskDistributionPattern 
                    { 
                        NearDeadlinePercent = 80, 
                        MediumDeadlinePercent = 15,
                        HighPriorityPercent = 45,
                        MediumPriorityPercent = 35,
                        ShortTaskPercent = 35,
                        MediumTaskPercent = 40
                    }
                },
                
                // FRANK: Balanced distribution
                { FrankId, new TaskDistributionPattern 
                    { 
                        NearDeadlinePercent = 33, 
                        MediumDeadlinePercent = 34,
                        HighPriorityPercent = 33,
                        MediumPriorityPercent = 34,
                        ShortTaskPercent = 33,
                        MediumTaskPercent = 34
                    }
                }
            };

            // Task title templates
            var taskPrefixes = new[] 
            { 
                "Implement", "Fix", "Design", "Review", "Update", "Test", "Deploy", "Refactor",
                "Optimize", "Document", "Configure", "Build", "Migrate", "Debug", "Analyze"
            };
            
            var taskSubjects = new[]
            {
                "API endpoint", "database schema", "user interface", "authentication flow",
                "payment gateway", "notification system", "search feature", "admin panel",
                "dashboard widget", "report generator", "cache layer", "logging system",
                "CI/CD pipeline", "security module", "performance metrics", "data export",
                "file upload", "email service", "webhook handler", "background job"
            };

            foreach (var user in _users)
            {
                var pattern = userPatterns[user.UserID];
                var userTasks = new List<Task>();
                
                Console.WriteLine($"   👤 Generating 1000 tasks for {user.FullName}...");

                for (int i = 1; i <= 1000; i++)
                {
                    // Generate deadline based on pattern
                    var deadline = GenerateDeadlineByPattern(now, random, pattern);
                    
                    // Generate priority based on pattern
                    var priority = GeneratePriorityByPattern(random, pattern);
                    
                    // Generate estimated time based on pattern
                    var estimatedMinutes = GenerateEstimatedTimeByPattern(random, pattern);
                    
                    // Generate status (70% ToDo, 25% InProgress, 5% Done)
                    var statusRoll = random.Next(100);
                    var status = statusRoll < 70 ? "ToDo" : (statusRoll < 95 ? "InProgress" : "Done");
                    
                    // Generate task title
                    var prefix = taskPrefixes[random.Next(taskPrefixes.Length)];
                    var subject = taskSubjects[random.Next(taskSubjects.Length)];
                    var title = $"{prefix} {subject} #{i}";
                    
                    var task = new Task
                    {
                        TaskID = Guid.NewGuid(),
                        WorkspaceID = workspaceId,
                        Title = title,
                        Description = $"Task for {user.FullName}. Priority: {priority}, Est: {estimatedMinutes}min",
                        Status = status,
                        Priority = priority,
                        Deadline = deadline,
                        EstimatedTimeMinutes = estimatedMinutes,
                        CreatorUserID = user.UserID,
                        CreatedAt = now.AddDays(-random.Next(1, 30)),
                        CompletedAt = status == "Done" ? now.AddDays(-random.Next(1, 7)) : null
                    };
                    
                    userTasks.Add(task);
                }
                
                allTasks.AddRange(userTasks);
                
                // Create assignments for non-Done tasks
                var assignableTasks = userTasks.Where(t => t.Status != "Done").ToList();
                allAssignments.AddRange(assignableTasks.Select(t => new TaskAssignment
                {
                    TaskID = t.TaskID,
                    AssigneeUserID = user.UserID,
                    AssignerUserID = user.UserID,
                    Status = t.Status == "InProgress" ? TaskAssignmentStatus.InProgress : TaskAssignmentStatus.Accepted,
                    AssignedAt = t.CreatedAt,
                    ResponseAt = t.CreatedAt.AddHours(random.Next(1, 24))
                }));
                
                // Print distribution stats for this user
                var overdueCount = userTasks.Count(t => t.Deadline < now && t.Status != "Done");
                var nearCount = userTasks.Count(t => t.Deadline >= now && t.Deadline <= now.AddDays(3) && t.Status != "Done");
                var highCount = userTasks.Count(t => t.Priority == "High" && t.Status != "Done");
                var shortCount = userTasks.Count(t => t.EstimatedTimeMinutes <= 60 && t.Status != "Done");
                
                Console.WriteLine($"      📊 {user.FullName}: Overdue={overdueCount}, Near={nearCount}, High={highCount}, Short={shortCount}");
            }

            // Bulk insert for better performance
            Console.WriteLine("\n   💾 Saving to database (batch insert)...");
            
            // Insert in batches to avoid memory issues
            const int batchSize = 500;
            for (int i = 0; i < allTasks.Count; i += batchSize)
            {
                var taskBatch = allTasks.Skip(i).Take(batchSize).ToList();
                await _context.Tasks.AddRangeAsync(taskBatch);
                await _context.SaveChangesAsync();
                
                if ((i + batchSize) % 2000 == 0)
                {
                    Console.WriteLine($"      ✓ Saved {Math.Min(i + batchSize, allTasks.Count)}/{allTasks.Count} tasks...");
                }
            }
            
            for (int i = 0; i < allAssignments.Count; i += batchSize)
            {
                var assignmentBatch = allAssignments.Skip(i).Take(batchSize).ToList();
                await _context.TaskAssignments.AddRangeAsync(assignmentBatch);
                await _context.SaveChangesAsync();
            }

            Console.WriteLine($"\n   ✅ Total: {allTasks.Count} tasks, {allAssignments.Count} assignments created!");
            _tasks = allTasks;
        }

        private DateTime GenerateDeadlineByPattern(DateTime now, Random random, TaskDistributionPattern pattern)
        {
            var roll = random.Next(100);
            
            // Overdue (past)
            if (roll < pattern.OverduePercent)
            {
                return now.AddDays(-random.Next(1, 14)).AddHours(-random.Next(1, 23));
            }
            
            // Near deadline (0-3 days)
            if (roll < pattern.OverduePercent + pattern.NearDeadlinePercent)
            {
                return now.AddHours(random.Next(1, 72));
            }
            
            // Medium deadline (3-10 days)
            if (roll < pattern.OverduePercent + pattern.NearDeadlinePercent + pattern.MediumDeadlinePercent)
            {
                return now.AddDays(random.Next(3, 10)).AddHours(random.Next(0, 23));
            }
            
            // Far deadline (10-30 days)
            return now.AddDays(random.Next(10, 30)).AddHours(random.Next(0, 23));
        }

        private string GeneratePriorityByPattern(Random random, TaskDistributionPattern pattern)
        {
            var roll = random.Next(100);
            
            if (roll < pattern.HighPriorityPercent)
                return "High";
            if (roll < pattern.HighPriorityPercent + pattern.MediumPriorityPercent)
                return "Medium";
            return "Low";
        }

        private int GenerateEstimatedTimeByPattern(Random random, TaskDistributionPattern pattern)
        {
            var roll = random.Next(100);
            
            // Short tasks (15-60 min)
            if (roll < pattern.ShortTaskPercent)
                return random.Next(15, 61);
            
            // Medium tasks (60-180 min)
            if (roll < pattern.ShortTaskPercent + pattern.MediumTaskPercent)
                return random.Next(60, 181);
            
            // Long tasks (180-480 min)
            return random.Next(180, 481);
        }

        private async System.Threading.Tasks.Task PrintLargeScaleSummaryAsync()
        {
            var now = DateTime.UtcNow;
            
            Console.WriteLine("\n╔══════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║          🎯 LARGE-SCALE AI TEST DATA SUMMARY                 ║");
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            Console.WriteLine($"║  📊 Total Tasks: {_tasks.Count:N0}                                      ║");
            Console.WriteLine($"║  👥 Users: 6 personas (1000 tasks each)                      ║");
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            
            foreach (var user in _users)
            {
                var userTasks = _tasks.Where(t => t.CreatorUserID == user.UserID).ToList();
                var overdueCount = userTasks.Count(t => t.Deadline < now && t.Status != "Done");
                var todoCount = userTasks.Count(t => t.Status == "ToDo");
                var highCount = userTasks.Count(t => t.Priority == "High");
                
                Console.WriteLine($"║  👤 {user.FullName,-15}: {todoCount} ToDo, {overdueCount} Overdue, {highCount} High ║");
            }
            
            Console.WriteLine("╠══════════════════════════════════════════════════════════════╣");
            Console.WriteLine("║  🧪 TEST SCENARIOS:                                          ║");
            Console.WriteLine("║  1. Bob: AI should prioritize overdue tasks FIRST            ║");
            Console.WriteLine("║  2. Charlie: AI should suggest SHORT tasks (<60min) first    ║");
            Console.WriteLine("║  3. Diana: AI should suggest HIGH priority first             ║");
            Console.WriteLine("║  4. Eve: AI should suggest NEAR deadline first               ║");
            Console.WriteLine("║  5. Frank: Balanced - compare baseline                       ║");
            Console.WriteLine("╚══════════════════════════════════════════════════════════════╝");
            
            await System.Threading.Tasks.Task.CompletedTask;
        }

        /// <summary>
        /// Pattern để định nghĩa phân bố task cho mỗi persona
        /// </summary>
        private class TaskDistributionPattern
        {
            public int OverduePercent { get; set; } = 0;
            public int NearDeadlinePercent { get; set; } = 33;
            public int MediumDeadlinePercent { get; set; } = 34;
            // FarDeadlinePercent = 100 - OverduePercent - NearDeadlinePercent - MediumDeadlinePercent
            
            public int HighPriorityPercent { get; set; } = 33;
            public int MediumPriorityPercent { get; set; } = 34;
            // LowPriorityPercent = 100 - HighPriorityPercent - MediumPriorityPercent
            
            public int ShortTaskPercent { get; set; } = 33;
            public int MediumTaskPercent { get; set; } = 34;
            // LongTaskPercent = 100 - ShortTaskPercent - MediumTaskPercent
        }
    }
}
