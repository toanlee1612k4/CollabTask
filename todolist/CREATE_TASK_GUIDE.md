# 🎉 CREATE TASK SCREEN - HƯỚNG DẪN SỬ DỤNG

## ✅ Files đã tạo

1. **`lib/providers/create_task_provider.dart`** - State Management với Riverpod
2. **`lib/presentation/screens/tasks/create_task_screen.dart`** - UI Screen

---

## 📋 Cách sử dụng trong app

### 1. Navigation đến CreateTaskScreen

```dart
// Từ bất kỳ screen nào (VD: Dashboard, Workspace Detail)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CreateTaskScreen(
      workspaceId: 'workspace-uuid-here',
      workspaceName: 'Dự án ABC', // Optional
    ),
  ),
).then((createdTask) {
  if (createdTask != null && createdTask is TaskModel) {
    // Task vừa tạo thành công
    print('✅ Task created: ${createdTask.title}');
    // Refresh danh sách tasks
  }
});
```

### 2. Thêm FAB (Floating Action Button) vào Workspace Screen

```dart
// Trong WorkspaceDetailScreen hoặc TaskListScreen
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Tasks')),
    body: TaskListView(),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final createdTask = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTaskScreen(
              workspaceId: currentWorkspaceId,
              workspaceName: currentWorkspaceName,
            ),
          ),
        );
        
        if (createdTask != null) {
          // Refresh task list
          ref.read(tasksProvider.notifier).refresh();
        }
      },
      icon: Icon(Icons.add),
      label: Text('Tạo Task'),
    ),
  );
}
```

---

## 🎨 Tính năng UI

### ✅ Form Fields

1. **Tiêu đề** (bắt buộc):
   - TextFormField với validation
   - Max 200 ký tự
   - Icon: `Icons.title`

2. **Mô tả** (tùy chọn):
   - TextFormField multiline (4 lines)
   - Max 1000 ký tự
   - Icon: `Icons.description`

3. **Độ ưu tiên** (bắt buộc):
   - Dropdown với 4 options:
     - 🔴 **Urgent** (màu đỏ)
     - 🟠 **High** (màu cam)
     - 🔵 **Medium** (màu xanh - default)
     - ⚪ **Low** (màu xám)

4. **Deadline** (tùy chọn):
   - DatePicker + TimePicker
   - Hiển thị: `dd/MM/yyyy HH:mm`
   - **Tự động convert sang UTC** khi gửi API
   - Có nút Clear để xóa

5. **Thời gian ước tính** (tùy chọn):
   - Number input (phút)
   - Icon: `Icons.timer`

6. **Người thực hiện** (bắt buộc):
   - Multi-select checkbox list
   - Hiển thị avatar + tên thành viên
   - Highlight "(Bạn)" cho current user
   - Quick action: "Gán cho tôi"
   - Hiển thị Chips cho người đã chọn

### ✅ Validation

- ❌ Tiêu đề không được rỗng
- ❌ Deadline phải lớn hơn hiện tại
- ❌ Phải chọn ít nhất 1 assignee

### ✅ UX Features

- ✅ SingleChildScrollView - Tránh keyboard overflow
- ✅ Loading state khi load members
- ✅ Error message hiển thị đỏ ở đầu form
- ✅ Submit button disabled khi đang submit
- ✅ SnackBar thông báo thành công/thất bại
- ✅ Auto return về screen trước sau khi tạo thành công

---

## 🔧 Technical Details

### State Management (Riverpod)

```dart
// Provider
final createTaskProvider = StateNotifierProvider<CreateTaskNotifier, CreateTaskState>((ref) {
  return CreateTaskNotifier(apiClient);
});

// State
class CreateTaskState {
  final String? workspaceId;
  final List<UserModel> workspaceMembers; // Load từ API
  final bool isLoadingMembers;
  final bool isSubmitting;
  final String? error;
  final TaskModel? createdTask;
}

// Methods
class CreateTaskNotifier {
  Future<void> loadWorkspaceMembers(String workspaceId);
  Future<bool> createTask({ ... });
  void reset();
}
```

### API Calls

1. **Load Members:**
   - Endpoint: `GET /api/workspaces/{id}/members`
   - Auto-load khi mở screen

2. **Create Task:**
   - Endpoint: `POST /api/workspaces/{id}/tasks`
   - Body:
     ```json
     {
       "title": "Fix bug",
       "description": "Chi tiết...",
       "priority": "High",
       "status": "ToDo",
       "deadline": "2025-12-25T10:00:00Z", // UTC
       "estimatedTimeMinutes": 120,
       "assigneeUserIds": ["user-id-1", "user-id-2"]
     }
     ```

### DateTime Handling (QUAN TRỌNG)

```dart
// ✅ User chọn: 25/12/2025 10:00 (Local Time)
final _selectedDeadline = DateTime(2025, 12, 25, 10, 0); // Local

// ✅ Gửi API: Convert sang UTC
final taskData = {
  'deadline': _selectedDeadline?.toUtc().toIso8601String(),
  // Output: "2025-12-25T03:00:00.000Z" (nếu timezone +7)
};

// ✅ Nhận từ API: Tự động convert sang Local (TaskModel.fromJson)
deadline: json['deadline'] != null 
    ? DateTime.parse(json['deadline']).toLocal() 
    : null,
```

---

## 🧪 Test Case

### Test 1: Tạo task thành công
```
Given: User mở CreateTaskScreen trong workspace "Dự án ABC"
When: 
  - Nhập title: "Implement login API"
  - Chọn priority: High
  - Chọn deadline: 30/12/2025 14:00
  - Chọn assignees: ["Alice", "Bob"]
  - Nhấn "Tạo Task"
Then:
  - API POST /api/workspaces/{id}/tasks được gọi
  - SnackBar hiển thị "✅ Tạo task thành công!"
  - Screen đóng và return TaskModel về
```

### Test 2: Validation errors
```
Given: User mở CreateTaskScreen
When: Nhấn "Tạo Task" mà không nhập gì
Then:
  - Form validation hiển thị "Vui lòng nhập tiêu đề"
  - SnackBar hiển thị "⚠️ Vui lòng chọn ít nhất một người thực hiện"
```

### Test 3: Deadline trong quá khứ
```
Given: User nhập form đầy đủ
When: Chọn deadline = 20/12/2025 (quá khứ)
  And: Nhấn "Tạo Task"
Then:
  - Error message: "Deadline phải lớn hơn thời gian hiện tại"
```

### Test 4: Multi-select assignees
```
Given: Workspace có 5 members
When: User check 3 members
Then:
  - 3 Chips hiển thị ở trên danh sách
  - Mỗi chip có nút X để bỏ chọn
  - Uncheck trong list cũng remove chip
```

---

## 📸 UI Preview

```
┌─────────────────────────────────┐
│ ← Tạo Task Mới                  │
│   Dự án ABC                     │
├─────────────────────────────────┤
│                                 │
│ [⚠️ Lỗi message hiển thị ở đây] │
│                                 │
│ 📝 Tiêu đề Task *               │
│ ┌─────────────────────────────┐ │
│ │ Nhập tiêu đề task...        │ │
│ └─────────────────────────────┘ │
│                                 │
│ 📄 Mô tả (tùy chọn)             │
│ ┌─────────────────────────────┐ │
│ │ Nhập mô tả chi tiết...      │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ 🚩 Độ ưu tiên *                 │
│ ┌─────────────────────────────┐ │
│ │ 🔵 Medium            ▼      │ │
│ └─────────────────────────────┘ │
│                                 │
│ 📅 Deadline (tùy chọn)          │
│ ┌─────────────────────────────┐ │
│ │ 25/12/2025 10:00       [X]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ⏱️ Thời gian ước tính (phút)    │
│ ┌─────────────────────────────┐ │
│ │ VD: 120                     │ │
│ └─────────────────────────────┘ │
│                                 │
│ 👥 Người thực hiện *            │
│ ┌─────────────────────────────┐ │
│ │ [Alice] [Bob] [x]           │ │
│ ├─────────────────────────────┤ │
│ │ ☑️ A Alice (Bạn)            │ │
│ │ ☑️ B Bob                    │ │
│ │ ☐  C Charlie                │ │
│ │ [+ Gán cho tôi]             │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │        TẠO TASK             │ │
│ └─────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

---

## 🚀 Next Steps

1. **Test trên app:**
   ```bash
   flutter run -d chrome
   ```

2. **Navigate từ Dashboard:**
   - Thêm button "Tạo Task" vào Workspace Detail Screen
   - Hoặc thêm vào Task List Screen

3. **Backend cần đảm bảo:**
   - `POST /api/workspaces/{id}/tasks` hoạt động
   - `GET /api/workspaces/{id}/members` trả về đúng danh sách
   - Validate assigneeUserIds phải thuộc workspace

4. **Optional enhancements:**
   - Thêm file upload cho task attachments
   - Thêm tags/labels
   - Recurring tasks (lặp lại hàng tuần)

---

## 📌 Notes

- ✅ Code tuân thủ **SOLID principles**
- ✅ UI/Logic tách biệt hoàn toàn
- ✅ Riverpod StateNotifier cho business logic
- ✅ DateTime handling đúng (UTC ↔ Local)
- ✅ SingleChildScrollView tránh keyboard overflow
- ✅ Form validation đầy đủ
- ✅ Error handling với try-catch
- ✅ Mounted checks cho async operations

**Sẵn sàng để production!** 🎉
