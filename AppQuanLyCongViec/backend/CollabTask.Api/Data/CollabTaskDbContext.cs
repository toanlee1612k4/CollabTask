using Microsoft.EntityFrameworkCore;
using CollabTask.Api.Models;
using Task = CollabTask.Api.Models.Task;

namespace CollabTask.Api.Data
{
    public class CollabTaskDbContext : DbContext
    {
        public CollabTaskDbContext(DbContextOptions<CollabTaskDbContext> options) : base(options) { }

        // DbSets
        public DbSet<User> Users { get; set; }
        public DbSet<SystemRole> SystemRoles { get; set; }
        public DbSet<Workspace> Workspaces { get; set; }
        public DbSet<WorkspaceMember> WorkspaceMembers { get; set; }
        public DbSet<Task> Tasks { get; set; } // Dòng này giờ đã rõ ràng
        public DbSet<TaskAssignment> TaskAssignments { get; set; }
        public DbSet<Tag> Tags { get; set; }
        public DbSet<TaskTag> TaskTags { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<UserInteractionForAI> UserInteractionsForAI { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Seed data for SystemRoles
            modelBuilder.Entity<SystemRole>().HasData(
                new SystemRole { RoleID = 1, RoleName = "SystemAdmin" },
                new SystemRole { RoleID = 2, RoleName = "User" }
            );

            // Configure composite keys
            modelBuilder.Entity<WorkspaceMember>()
                .HasKey(wm => new { wm.WorkspaceID, wm.UserID });

            modelBuilder.Entity<TaskAssignment>()
                .HasKey(ta => new { ta.TaskID, ta.AssigneeUserID });

            modelBuilder.Entity<TaskTag>()
                .HasKey(tt => new { tt.TaskID, tt.TagID });

            // Configure relationships
            modelBuilder.Entity<User>()
                .HasOne(u => u.SystemRole)
                .WithMany(sr => sr.Users)
                .HasForeignKey(u => u.SystemRoleID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Workspace>()
                .HasOne(w => w.Owner)
                .WithMany(u => u.OwnedWorkspaces)
                .HasForeignKey(w => w.OwnerUserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<WorkspaceMember>()
                .HasOne(wm => wm.Workspace)
                .WithMany(w => w.Members)
                .HasForeignKey(wm => wm.WorkspaceID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<WorkspaceMember>()
                .HasOne(wm => wm.User)
                .WithMany(u => u.WorkspaceMemberships)
                .HasForeignKey(wm => wm.UserID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Task>()
                .HasOne(t => t.Workspace)
                .WithMany(w => w.Tasks)
                .HasForeignKey(t => t.WorkspaceID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Task>()
                .HasOne(t => t.Creator)
                .WithMany(u => u.CreatedTasks)
                .HasForeignKey(t => t.CreatorUserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TaskAssignment>()
                .HasOne(ta => ta.Task)
                .WithMany(t => t.TaskAssignments)
                .HasForeignKey(ta => ta.TaskID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TaskAssignment>()
                .HasOne(ta => ta.Assignee)
                .WithMany(u => u.TaskAssignments)
                .HasForeignKey(ta => ta.AssigneeUserID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Tag>()
                .HasOne(tag => tag.Workspace)
                .WithMany(w => w.Tags)
                .HasForeignKey(tag => tag.WorkspaceID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TaskTag>()
                .HasOne(tt => tt.Task)
                .WithMany(t => t.TaskTags)
                .HasForeignKey(tt => tt.TaskID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TaskTag>()
                .HasOne(tt => tt.Tag)
                .WithMany(tag => tag.TaskTags)
                .HasForeignKey(tt => tt.TagID)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Comment>()
                .HasOne(c => c.Task)
                .WithMany(t => t.Comments)
                .HasForeignKey(c => c.TaskID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Comment>()
                .HasOne(c => c.User)
                .WithMany(u => u.Comments)
                .HasForeignKey(c => c.UserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserID)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ActivityLog>()
                .HasOne(al => al.User)
                .WithMany(u => u.ActivityLogs)
                .HasForeignKey(al => al.UserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserInteractionForAI>()
                .HasOne(ui => ui.User)
                .WithMany()
                .HasForeignKey(ui => ui.UserID)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserInteractionForAI>()
                .HasOne(ui => ui.Task)
                .WithMany()
                .HasForeignKey(ui => ui.TaskID)
                .OnDelete(DeleteBehavior.Restrict);

            // Configure indexes for performance
            modelBuilder.Entity<Task>()
                .HasIndex(t => t.WorkspaceID);

            modelBuilder.Entity<Task>()
                .HasIndex(t => t.Status);

            modelBuilder.Entity<TaskAssignment>()
                .HasIndex(ta => ta.AssigneeUserID);

            modelBuilder.Entity<WorkspaceMember>()
                .HasIndex(wm => wm.UserID);

            // Configure unique constraints
            modelBuilder.Entity<Tag>()
                .HasIndex(tag => new { tag.WorkspaceID, tag.TagName })
                .IsUnique();
        }
    }
}