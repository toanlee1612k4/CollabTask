using Microsoft.EntityFrameworkCore;
using CollabTask.Api.Models;

namespace CollabTask.Api.Data
{
    public class CollabTaskDbContext : DbContext
    {
        public CollabTaskDbContext(DbContextOptions<CollabTaskDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Workspace> Workspaces { get; set; }
        public DbSet<WorkspaceMember> WorkspaceMembers { get; set; }
        public DbSet<Models.Task> Tasks { get; set; }
        public DbSet<TaskAssignment> TaskAssignments { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<Tag> Tags { get; set; }
        public DbSet<TaskTag> TaskTags { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<SystemRole> SystemRoles { get; set; }
        public DbSet<UserTaskWeight> UserTaskWeights { get; set; }
        public DbSet<UserTaskCompletionLog> UserTaskCompletionLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User
            modelBuilder.Entity<User>()
                .HasKey(u => u.UserID);

            // Workspace
            modelBuilder.Entity<Workspace>()
                .HasKey(w => w.WorkspaceID);

            // WorkspaceMember - Composite Key
            modelBuilder.Entity<WorkspaceMember>()
                .HasKey(wm => new { wm.WorkspaceID, wm.UserID });

            modelBuilder.Entity<WorkspaceMember>()
                .HasOne(wm => wm.Workspace)
                .WithMany(w => w.Members)
                .HasForeignKey(wm => wm.WorkspaceID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<WorkspaceMember>()
                .HasOne(wm => wm.User)
                .WithMany(u => u.WorkspaceMemberships)
                .HasForeignKey(wm => wm.UserID)
                .OnDelete(DeleteBehavior.Restrict);

            // Task
            modelBuilder.Entity<Models.Task>()
                .HasKey(t => t.TaskID);

            modelBuilder.Entity<Models.Task>()
                .HasOne(t => t.Workspace)
                .WithMany(w => w.Tasks)
                .HasForeignKey(t => t.WorkspaceID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Models.Task>()
                .HasOne(t => t.Creator)
                .WithMany(u => u.CreatedTasks)
                .HasForeignKey(t => t.CreatorUserID)
                .OnDelete(DeleteBehavior.Restrict);

            // TaskAssignment - Composite Key
            modelBuilder.Entity<TaskAssignment>()
                .HasKey(ta => new { ta.TaskID, ta.AssigneeUserID });

            modelBuilder.Entity<TaskAssignment>()
                .HasOne(ta => ta.Task)
                .WithMany(t => t.TaskAssignments)
                .HasForeignKey(ta => ta.TaskID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TaskAssignment>()
                .HasOne(ta => ta.Assignee)
                .WithMany(u => u.TaskAssignments)
                .HasForeignKey(ta => ta.AssigneeUserID)
                .OnDelete(DeleteBehavior.Restrict);

            // UserTaskWeight
            modelBuilder.Entity<UserTaskWeight>()
                .HasKey(utw => utw.UserID);

            modelBuilder.Entity<UserTaskWeight>()
                .HasOne(utw => utw.User)
                .WithMany()
                .HasForeignKey(utw => utw.UserID)
                .OnDelete(DeleteBehavior.Cascade);

            // TaskTag - Composite Key
            modelBuilder.Entity<TaskTag>()
                .HasKey(tt => new { tt.TaskID, tt.TagID });

            modelBuilder.Entity<TaskTag>()
                .HasOne(tt => tt.Task)
                .WithMany(t => t.TaskTags)
                .HasForeignKey(tt => tt.TaskID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TaskTag>()
                .HasOne(tt => tt.Tag)
                .WithMany(t => t.TaskTags)
                .HasForeignKey(tt => tt.TagID)
                .OnDelete(DeleteBehavior.Cascade);

            // UserTaskCompletionLog - Map to UserInteractionsForAI table
            modelBuilder.Entity<UserTaskCompletionLog>()
                .ToTable("UserInteractionsForAI")
                .HasKey(utcl => utcl.InteractionID);

            modelBuilder.Entity<UserTaskCompletionLog>()
                .Property(utcl => utcl.InteractionID)
                .ValueGeneratedOnAdd();

            modelBuilder.Entity<UserTaskCompletionLog>()
                .HasOne(utcl => utcl.User)
                .WithMany()
                .HasForeignKey(utcl => utcl.UserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserTaskCompletionLog>()
                .HasOne(utcl => utcl.Task)
                .WithMany()
                .HasForeignKey(utcl => utcl.TaskID)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}