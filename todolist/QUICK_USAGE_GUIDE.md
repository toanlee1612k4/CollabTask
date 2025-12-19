# Quick Usage Guide - New Features

## 🤖 AI Suggestions Screen

### How to Navigate:
Add this button to your dashboard or sidebar:

```dart
// Example: Add to sidebar menu
ListTile(
  leading: Icon(Icons.lightbulb_outline, color: Colors.purple),
  title: const Text('Gợi ý từ AI'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiSuggestionsScreen(
          currentUserId: authProvider.currentUser!.userId,
          currentUserRole: authProvider.currentUser!.roleName ?? 'Member',
        ),
      ),
    );
  },
),
```

### What You'll See:
- **Ranked list** of tasks sorted by AI Priority Score (highest first)
- **#1, #2, #3** get golden badges
- **Big purple badge** showing AI Score (e.g., "⭐ AI Score: 9.5")
- **Red "Quá hạn!" badge** for overdue tasks
- **Orange "Ưu tiên cao" badge** for tasks with score ≥ 8.0
- **Deadline** in local timezone (e.g., "15/12/2025 14:30")

### Actions:
- **Tap any task** → Opens TaskDetailScreen
- **Pull down** → Refresh suggestions
- **Tap refresh icon** in AppBar → Reload from API

---

## 👥 Workspace Members Management

### How to Navigate:
Add this button to your workspace detail screen (only for Owners):

```dart
// Example: In workspace AppBar actions
if (currentUserRole == 'Owner')
  IconButton(
    icon: const Icon(Icons.people),
    tooltip: 'Quản lý thành viên',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkspaceMembersScreen(
            workspaceId: workspace.workspaceId,
            currentUserId: currentUser.userId,
            currentUserRole: currentUser.roleName ?? 'Member',
          ),
        ),
      );
    },
  ),
```

### What Owners Can Do:

#### 1. View Members
- See all workspace members with:
  - Avatar (or initial letter)
  - Full name + Email
  - Role badge (Owner/ProjectManager/Member)
  - Blue "Bạn" label for yourself

#### 2. Invite New Members
- Tap **FAB button** "Mời thành viên"
- Enter email address
- New member gets **Member role** by default

#### 3. Change Member Roles
- Use **dropdown** to change role:
  - **Member** → Standard user, can only work on assigned tasks
  - **Project Manager** → Can assign tasks, approve completions
- ⚠️ Cannot change your own role

#### 4. Remove Members
- Tap **delete icon** (🗑️)
- Confirm in dialog
- ⚠️ Cannot remove yourself

---

## 🕐 DateTime Handling (Automatic)

### For Users:
**You don't need to do anything!** All times are now automatically converted:

#### When You See Times:
- **Task deadline**: Shows in YOUR local timezone
- **CreatedAt/UpdatedAt**: Shows in YOUR local timezone
- **Example**: If server has "03:00 UTC", you see "10:00" (UTC+7)

#### When You Set Times:
- **DatePicker**: Pick time in YOUR local timezone
- **Example**: You pick "10:00 AM" → Server receives "03:00 UTC"

### For Developers:
All DateTime fields now:
- **From API** → Automatically `.toLocal()`
- **To API** → Automatically `.toUtc()`

Check these files:
- `lib/data/models/models.dart` - TaskModel, UserModel
- `lib/presentation/widgets/tasks/edit_task_dialog.dart` - Deadline picker

---

## 🔐 Role-Based Permissions

### Member (Default)
✅ Can:
- View tasks
- Accept/Reject assignments
- Request completion approval
- View workspace

❌ Cannot:
- Assign tasks to others
- Approve task completions
- Change member roles
- Remove members

### Project Manager
✅ All Member permissions PLUS:
- Assign tasks to members
- **Approve/Reject** task completions
- View assignment history

❌ Cannot:
- Change member roles
- Remove members
- Delete workspace

### Owner
✅ All permissions including:
- Manage workspace members
- Change member roles (Member ↔ ProjectManager)
- Invite new members
- Remove members
- Delete workspace

---

## Example Integration in Dashboard

```dart
// In your dashboard screen
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser!;
    
    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          // Existing cards...
          
          // AI Suggestions Card
          _buildFeatureCard(
            context,
            icon: Icons.lightbulb_outline,
            title: 'Gợi ý từ AI',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiSuggestionsScreen(
                  currentUserId: currentUser.userId,
                  currentUserRole: currentUser.roleName ?? 'Member',
                ),
              ),
            ),
          ),
          
          // Members Card (only for Owners)
          if (currentUser.roleName == 'Owner')
            _buildFeatureCard(
              context,
              icon: Icons.people,
              title: 'Thành viên',
              color: Colors.indigo,
              onTap: () {
                // Show workspace selection dialog first
                _selectWorkspaceThenNavigate(context, currentUser);
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
```

---

## API Requirements Checklist

Before using these features, ensure your backend has:

- [ ] `GET /api/tasks/suggested` - Returns sorted tasks
- [ ] `GET /api/workspaces/{id}/members` - Returns members with roles
- [ ] `POST /api/workspaces/{id}/members` - Accepts `{ email: string }`
- [ ] `PATCH /api/workspaces/{id}/members/{userId}/role` - Accepts `{ newRole: string }`
- [ ] `DELETE /api/workspaces/{id}/members/{userId}` - Removes member
- [ ] All DateTime fields are in **UTC ISO-8601 format**

Test endpoint example:
```bash
# Get AI suggestions
curl http://localhost:5131/api/tasks/suggested \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected response:
[
  {
    "taskId": "...",
    "title": "Urgent task",
    "priorityScore": 9.5,
    "deadline": "2025-12-15T07:30:00.000Z",  # UTC time
    ...
  }
]
```

---

## Troubleshooting

### AI Suggestions screen is empty
- ✅ Check backend returns tasks from `/api/tasks/suggested`
- ✅ Verify you have tasks in database
- ✅ Check network tab for API errors

### Times are wrong
- ✅ Verify backend sends UTC times (e.g., "2025-12-15T07:30:00.000Z")
- ✅ Check device timezone is set correctly
- ✅ Restart app after changing timezone

### Can't see "Duyệt" button in task detail
- ✅ Check your role is "ProjectManager" or "Owner"
- ✅ Verify TaskDetailScreen receives correct `currentUserRole`

### Can't access Members screen
- ✅ Verify your role is "Owner"
- ✅ Check WorkspaceMembersScreen is passed correct `currentUserRole`

### Dropdown to change role is disabled
- ✅ You cannot change your own role
- ✅ Only Owners can change roles
