# Implementation Summary - Audit Q7, Q8, Q12

## ✅ Q12: DateTime UTC/Local Handling (COMPLETED)

### Changes Made:
1. **TaskModel.fromJson()** - [lib/data/models/models.dart](lib/data/models/models.dart)
   - `deadline`: Convert từ UTC sang Local time khi nhận từ API
   - `createdAt`: Convert từ UTC sang Local time
   - `updatedAt`: Convert từ UTC sang Local time

2. **TaskModel.toJson()** - [lib/data/models/models.dart](lib/data/models/models.dart)
   - `deadline`: Convert từ Local sang UTC trước khi gửi lên API
   - `createdAt`: Convert từ Local sang UTC
   - `updatedAt`: Convert từ Local sang UTC

3. **EditTaskDialog** - [lib/presentation/widgets/tasks/edit_task_dialog.dart](lib/presentation/widgets/tasks/edit_task_dialog.dart)
   - Khi user chọn deadline từ DatePicker → convert sang UTC với `.toUtc().toIso8601String()`

4. **UserModel.fromJson()** - [lib/data/models/models.dart](lib/data/models/models.dart)
   - `createdAt`: Convert từ UTC sang Local time

### Expected Behavior:
- ✅ API server lưu tất cả DateTime ở format UTC (ISO-8601)
- ✅ Flutter app hiển thị DateTime theo timezone local của user
- ✅ Khi user chọn deadline "01/01/2024 10:00", server nhận được "2024-01-01T03:00:00.000Z" (nếu UTC+7)
- ✅ Khi API trả về "2024-01-01T03:00:00.000Z", app hiển thị "01/01/2024 10:00" (cho UTC+7)

---

## ✅ Q7: AI Suggestions Screen (COMPLETED)

### New Screen Created:
**AiSuggestionsScreen** - [lib/presentation/screens/ai/ai_suggestions_screen.dart](lib/presentation/screens/ai/ai_suggestions_screen.dart)

### Features:
1. **API Integration**
   - Gọi `GET /api/tasks/suggested`
   - Hiển thị list tasks theo đúng thứ tự server trả về (sorted by priorityScore DESC)

2. **UI Highlights**
   - **Rank badge**: Top 3 tasks có badge vàng, còn lại màu xám
   - **Priority Score**: Hiển thị nổi bật với gradient purple và icon ⭐
   - **Status Badges**: 
     - 🔴 "Quá hạn!" - Red badge với icon warning
     - 🟠 "Ưu tiên cao" - Orange badge (nếu priorityScore >= 8.0)
   - **Deadline**: Hiển thị thời gian với format "dd/MM/yyyy HH:mm"

3. **ListView Implementation**
   - Pull-to-refresh support
   - Empty state với message "Tuyệt vời! Không có task nào cần ưu tiên"
   - Error state với retry button
   - Tap vào card → Navigate to TaskDetailScreen

### Usage:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AiSuggestionsScreen(
      currentUserId: userId,
      currentUserRole: userRole,
    ),
  ),
);
```

### Example Card Layout:
```
┌─────────────────────────────────────┐
│ #1  [TASK TITLE]                    │
│     [Description preview...]        │
│                                     │
│     ⭐ AI Score: 9.5                │
│                                     │
│     [Quá hạn!] [Cao] [InProgress]  │
│     🕐 Deadline: 15/12/2025 14:30   │
└─────────────────────────────────────┘
```

---

## ✅ Q8: Role-Based UI (COMPLETED)

### 1. Task Detail Screen - Hide Approve Button for Members

**File**: [lib/presentation/screens/tasks/task_detail_screen.dart](lib/presentation/screens/tasks/task_detail_screen.dart)

**Existing Implementation** (Already correct):
```dart
bool get _canApprove => _canAssignTasks;

bool get _canAssignTasks => 
    widget.currentUserRole == 'Owner' || 
    widget.currentUserRole == 'ProjectManager';
```

**UI Behavior**:
- ✅ Chỉ **Owner** và **ProjectManager** mới thấy nút "Duyệt" và "Từ chối"
- ✅ Member thường chỉ có thể:
  - Chấp nhận/Từ chối assignment
  - Yêu cầu duyệt hoàn thành
  - Xem chi tiết task

### 2. Workspace Members Screen (NEW)

**File**: [lib/presentation/screens/workspace/workspace_members_screen.dart](lib/presentation/screens/workspace/workspace_members_screen.dart)

**Features for Owner**:
1. **View member list**
   - Avatar (hoặc initial letter)
   - Full name + Email
   - Role badge (Owner/ProjectManager/Member)
   - "Bạn" label cho current user

2. **Invite new members**
   - FAB button "Mời thành viên"
   - Dialog nhập email
   - Email validation
   - Default role: Member

3. **Change member role**
   - Dropdown với 2 options:
     - Member
     - Project Manager
   - Chỉ Owner mới thấy dropdown
   - Không thể đổi role của chính mình

4. **Remove members**
   - Icon delete button
   - Confirmation dialog
   - Không thể xóa chính mình

### Usage:
```dart
// From workspace screen
IconButton(
  icon: const Icon(Icons.people),
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
)
```

### API Endpoints Used:
1. `GET /api/workspaces/{id}/members` - Load member list
2. `POST /api/workspaces/{id}/members` - Invite member (with email)
3. `PATCH /api/workspaces/{id}/members/{userId}/role` - Change role
   ```json
   { "newRole": "ProjectManager" }
   ```
4. `DELETE /api/workspaces/{id}/members/{userId}` - Remove member

---

## Testing Checklist

### DateTime Handling:
- [ ] Tạo task với deadline "10:00 AM" → Check database có UTC time đúng
- [ ] Task có deadline UTC "03:00:00Z" → App hiển thị "10:00 AM" (UTC+7)
- [ ] Edit task deadline → Server nhận UTC time chính xác

### AI Suggestions:
- [ ] Màn hình load được list tasks từ `/api/tasks/suggested`
- [ ] Tasks hiển thị đúng thứ tự (priorityScore cao → thấp)
- [ ] Top 3 tasks có badge vàng
- [ ] Priority Score hiển thị với gradient purple
- [ ] Task overdue có badge đỏ "Quá hạn!"
- [ ] Task với priorityScore >= 8 có badge "Ưu tiên cao"
- [ ] Pull-to-refresh hoạt động
- [ ] Tap vào card navigate đến TaskDetailScreen

### Role-Based UI:
#### Task Detail:
- [ ] Member login → KHÔNG thấy nút "Duyệt"/"Từ chối"
- [ ] ProjectManager login → THẤY nút "Duyệt"/"Từ chối"
- [ ] Owner login → THẤY nút "Duyệt"/"Từ chối"

#### Workspace Members:
- [ ] Owner thấy FAB "Mời thành viên"
- [ ] Owner gửi invite qua email thành công
- [ ] Owner thấy dropdown đổi role (Member/ProjectManager)
- [ ] Dropdown KHÔNG hiển thị cho chính mình
- [ ] Đổi role Member → ProjectManager thành công
- [ ] Đổi role ProjectManager → Member thành công
- [ ] Delete member thành công (có confirmation)
- [ ] Không thể delete chính mình

---

## Integration Notes

### Add to Navigation:
Để thêm màn hình AI Suggestions vào app, update sidebar hoặc dashboard:

```dart
// In sidebar.dart or dashboard
ListTile(
  leading: const Icon(Icons.lightbulb_outline),
  title: const Text('Gợi ý từ AI'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiSuggestionsScreen(
          currentUserId: currentUser.userId,
          currentUserRole: currentUser.roleName ?? 'Member',
        ),
      ),
    );
  },
),
```

### Add Members Button to Workspace:
Update workspace detail screen:

```dart
// In workspace header
if (currentUserRole == 'Owner')
  IconButton(
    icon: const Icon(Icons.people),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkspaceMembersScreen(
            workspaceId: workspaceId,
            currentUserId: currentUserId,
            currentUserRole: currentUserRole,
          ),
        ),
      );
    },
    tooltip: 'Quản lý thành viên',
  ),
```

---

## Files Modified/Created:

### Modified:
1. `lib/data/models/models.dart` - DateTime UTC conversion
2. `lib/presentation/widgets/tasks/edit_task_dialog.dart` - Deadline UTC conversion

### Created:
1. `lib/presentation/screens/ai/ai_suggestions_screen.dart` - AI Suggestions UI
2. `lib/presentation/screens/workspace/workspace_members_screen.dart` - Members management

### Already Correct (No changes needed):
1. `lib/presentation/screens/tasks/task_detail_screen.dart` - Role check already implemented

---

## Backend Requirements

Đảm bảo backend có các endpoints sau:

1. ✅ `GET /api/tasks/suggested` - Returns tasks sorted by priorityScore DESC
2. ✅ `GET /api/workspaces/{id}/members` - Returns array of UserModel with roleName
3. ✅ `POST /api/workspaces/{id}/members` - Accept { email: string }
4. ✅ `PATCH /api/workspaces/{id}/members/{userId}/role` - Accept { newRole: string }
5. ✅ `DELETE /api/workspaces/{id}/members/{userId}` - Remove member

All DateTime fields in API responses should be in UTC ISO-8601 format.
