# CollabTask API

**Collaborative Task Management System - Backend**

Built with ASP.NET Core 9.0 | Entity Framework Core | SQL Server

---

## 🚀 Quick Start

```powershell
# Navigate to project
cd D:\btnv\CollabTask\AppQuanLyCongViec\backend\CollabTask.Api

# Run the application
dotnet run

# Or use the restart script
.\restart-and-test.ps1
```

**API Server**: http://localhost:5131  
**Swagger UI**: http://localhost:5131/swagger

---

## 📖 Complete Documentation

**Read the full guide**: [BACKEND-COMPLETE-GUIDE.md](BACKEND-COMPLETE-GUIDE.md)

This comprehensive guide includes:
- ✅ All 75+ API endpoints with examples
- ✅ Authentication & Authorization (Owner/PM/Member roles)
- ✅ Database schema (6,000 pre-seeded tasks)
- ✅ AI task suggestions algorithm
- ✅ Assigned tasks system
- ✅ Testing & deployment guides
- ✅ Troubleshooting & performance tips

---

## 🎯 Key Features

- **JWT Authentication** - Secure token-based auth
- **Role-Based Authorization** - 3-tier permissions (Owner, ProjectManager, Member)
- **AI Task Suggestions** - Priority scoring algorithm (max 11 points)
- **Calendar View** - Assigned tasks with deadlines
- **Task Assignments** - Complete workflow (Pending → Accepted → InProgress → Done)
- **File Attachments** - Upload/download (10MB max, assignees only)
- **Comments & Tags** - Rich task collaboration
- **Productivity Analytics** - Dashboard, leaderboard, completion stats
- **Invitation System** - Email-based workspace invites
- **Performance Optimized** - Caching, pagination, indexes

---

## 🔑 Demo Accounts

**Password for all accounts**: `Password123`

```
alice@example.com   - 1000 tasks, 6 workspaces
bob@example.com     - 1000 tasks
charlie@example.com - 1000 tasks
diana@example.com   - 1000 tasks
eve@example.com     - 1000 tasks
frank@example.com   - 1000 tasks
```

**Total Database**: 6,000 tasks with 6 months historical data (June-Dec 2025)

---

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Get JWT token
- `POST /api/auth/logout` - Logout

### Tasks (19 endpoints)
- `GET /api/tasks` - Get my assigned tasks (paginated)
- `GET /api/tasks/calendar` - Calendar view with deadlines
- `GET /api/workspaces/{id}/tasks` - Workspace tasks
- `POST /api/workspaces/{id}/tasks` - Create task
- `PUT /api/tasks/{id}` - Update task (Owner/PM only)
- `PUT /api/tasks/{id}/status` - Change status
- `DELETE /api/tasks/{id}` - Delete task (Owner/PM only)
- `POST /api/tasks/{id}/assign` - Assign to users
- `POST /api/tasks/{id}/respond` - Accept/reject assignment
- `POST /api/tasks/{id}/request-completion` - Request approval
- `POST /api/tasks/{id}/approve-completion` - Approve (Owner/PM)

### AI & Productivity (6 endpoints)
- `GET /api/productivity/suggested-tasks` - AI recommendations
- `GET /api/productivity/dashboard` - User stats
- `GET /api/productivity/workspace/{id}` - Workspace analytics
- `GET /api/productivity/leaderboard/{id}` - Team rankings

### Workspaces (9 endpoints)
- `GET /api/workspaces` - My workspaces
- `POST /api/workspaces` - Create workspace
- `GET /api/workspaces/{id}/members` - View members
- `POST /api/workspaces/{id}/members` - Add member (Owner/PM)

### Attachments (4 endpoints)
- `POST /api/tasks/{id}/attachments` - Upload file (assignees only)
- `GET /api/tasks/{id}/attachments` - List files
- `GET /api/tasks/{id}/attachments/{fileId}/download` - Download
- `DELETE /api/tasks/{id}/attachments/{fileId}` - Delete (Owner/PM)

### Comments, Notifications, Invitations, Tags, Users
- **50+ additional endpoints** - See [BACKEND-COMPLETE-GUIDE.md](BACKEND-COMPLETE-GUIDE.md)

---

## 🗄 Database

**SQL Server LocalDB**: `(localdb)\mssqllocaldb`  
**Database Name**: `CollabTaskDb`

### Core Tables
- Users (6 demo accounts)
- Workspaces (6 workspaces)
- Tasks (6,000 tasks)
- TaskAssignments (assignment workflow)
- TaskAttachments (file storage)
- WorkspaceMembers (role-based access)
- WorkspaceInvitations (email invites)
- Comments, Tags, Notifications, ActivityLogs

### Migrations
```powershell
# Apply all migrations
dotnet ef database update

# Create new migration
dotnet ef migrations add MigrationName

# Reset database
dotnet ef database drop
dotnet ef database update
```

---

## 🧪 Testing

### Automated Tests
```powershell
# Complete test suite
.\test-complete.ps1

# Workspace tasks test
.\test-workspace-tasks.ps1

# Restart and verify
.\restart-and-test.ps1
```

### Manual Testing
1. Open Swagger UI: http://localhost:5131/swagger
2. Click "Authorize" button
3. Login with `alice@example.com` / `Password123`
4. Copy token from response
5. Enter `Bearer {token}` in authorization
6. Test any endpoint interactively

---

## 📚 Other Documentation

- **[BACKEND-COMPLETE-GUIDE.md](BACKEND-COMPLETE-GUIDE.md)** - Complete backend documentation (THIS IS THE MAIN GUIDE)
- **[FRONTEND-API-GUIDE.md](FRONTEND-API-GUIDE.md)** - Frontend integration guide

---

## 🛠 Technology Stack

- **ASP.NET Core 9.0** - Web framework
- **Entity Framework Core 9.0** - ORM
- **SQL Server LocalDB** - Database
- **JWT Bearer Tokens** - Authentication
- **Swagger/OpenAPI** - API documentation
- **Memory Cache** - Performance optimization

---

## 📊 Database Statistics

- **6,000 Tasks** (1,000 per user)
- **6 Users** with different completion patterns
- **6 Workspaces** (1 personal + shared workspaces)
- **6 Months** historical data (June-December 2025)
- **AI Training Data** from user behavior patterns

---

## 🚀 Recent Updates

### December 14, 2025
- ✅ Fixed workspace tasks API bug (empty items array)
- ✅ Implemented AI suggested tasks endpoint (priority scoring)
- ✅ Added calendar tasks endpoint (assigned tasks with deadlines)
- ✅ Enhanced authorization (assignee-only file uploads)
- ✅ Created comprehensive backend guide
- ✅ Performance optimization (database indexes, caching)

---

## 📞 Need Help?

1. **Read**: [BACKEND-COMPLETE-GUIDE.md](BACKEND-COMPLETE-GUIDE.md) (comprehensive 1000+ line guide)
2. **Test**: Use Swagger UI at http://localhost:5131/swagger
3. **Debug**: Check console logs and database with SQL Server Object Explorer
4. **Scripts**: Run PowerShell test scripts in project root

---

**Status**: ✅ Production Ready  
**Last Updated**: December 14, 2025
