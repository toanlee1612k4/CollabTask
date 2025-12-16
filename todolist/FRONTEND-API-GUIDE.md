# 📱 CollabTask API - Frontend Integration Guide

> **Hướng dẫn sử dụng API cho Frontend Developers**  
> Server: `http://localhost:5131`  
> Last Updated: December 14, 2025

---

## 🚨 Các Lỗi Thường Gặp & Cách Fix

### 1. ❌ Error: 404 `/api/productivity/stats`
**Nguyên nhân**: Endpoint không tồn tại  
**Giải pháp**: Sử dụng endpoint đúng
```dart
// ❌ SAI
final response = await dio.get('/api/productivity/stats');

// ✅ ĐÚNG - Có 2 cách
final response = await dio.get('/api/productivity/dashboard'); // Cách 1
final response = await dio.get('/api/productivity/stats');     // Cách 2 (alias mới thêm)
```

### 2. ❌ Tasks đã quá hạn vẫn xuất hiện trong đề xuất AI
**Nguyên nhân**: Đã fix ở backend - tasks quá hạn giờ bị lọc ra  
**Giải pháp**: Cập nhật UI để hiển thị trạng thái deadline đúng
```dart
// Kiểm tra deadline trong task
bool isOverdue = task.deadline != null && 
                 task.deadline!.isBefore(DateTime.now()) && 
                 task.status != 'Done';

// Tasks từ /api/tasks/suggested KHÔNG còn overdue tasks
```

### 3. ❌ Không hiển thị đúng số lượng tasks
**Nguyên nhân**: Response có pagination
```dart
// ❌ SAI - Chỉ lấy items
final tasks = response.data['items'];

// ✅ ĐÚNG - Kiểm tra totalCount và pagination
final items = response.data['items'];        // Danh sách tasks của page hiện tại
final totalCount = response.data['totalCount']; // Tổng số tasks
final currentPage = response.data['currentPage'];
final pageSize = response.data['pageSize'];
```

### 4. ❌ Token hết hạn (401 Unauthorized)
**Giải pháp**: Implement token refresh hoặc redirect về login
```dart
dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      // Token hết hạn - redirect về login
      navigateToLogin();
    }
    return handler.next(error);
  },
));
```

---

## 🔐 1. Authentication

### Login
```dart
// Request
final response = await dio.post('/api/auth/login', data: {
  'email': 'alice@example.com',
  'password': 'Password123'
});

// Response
{
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..."
}

// Lưu token và set header
final token = response.data['token'];
dio.options.headers['Authorization'] = 'Bearer $token';
```

**Demo Accounts**:
```
alice@example.com / Password123  - Perfect Performer (80% đúng hạn)
bob@example.com / Password123    - Deadline Misser (hay trễ)
charlie@example.com / Password123 - Easy Task First
diana@example.com / Password123  - High Priority First
eve@example.com / Password123    - Procrastinator
frank@example.com / Password123  - Balanced
```

---

## 👤 2. User Management

### Lấy thông tin user hiện tại
```dart
GET /api/users/me

// Response
{
  "userId": "guid",
  "fullName": "Alice Smith",
  "email": "alice@example.com",
  "roleName": "User",
  "createdAt": "2024-06-14T00:00:00Z"
}
```

### Update profile
```dart
PUT /api/users/me
{
  "fullName": "Alice Johnson",
  "email": "alice@example.com"
}
```

---

## 📁 3. Workspaces

### Lấy danh sách workspaces
```dart
GET /api/workspaces

// Response
[
  {
    "workspaceID": "guid",
    "workspaceName": "Team Alpha Workspace",
    "description": "Main collaborative workspace",
    "createdAt": "2024-06-14T00:00:00Z",
    "ownerUserID": "guid",
    "ownerName": "Alice Smith"
  }
]
```

### Lấy members của workspace
```dart
GET /api/workspaces/{workspaceId}/members

// Response
[
  {
    "userID": "guid",
    "fullName": "Alice Smith",
    "email": "alice@example.com",
    "role": "Owner",
    "joinedAt": "2024-06-14T00:00:00Z"
  },
  {
    "userID": "guid",
    "fullName": "Bob Johnson",
    "email": "bob@example.com",
    "role": "Member",
    "joinedAt": "2024-06-14T00:00:00Z"
  }
]
```

---

## ✅ 4. Tasks - QUAN TRỌNG NHẤT

### 4.1. Lấy AI Suggested Tasks (Đề xuất thông minh)
```dart
GET /api/tasks/suggested

// Response
[
  {
    "taskId": "guid",
    "workspaceId": "guid",
    "title": "Implement user authentication",
    "description": "Add JWT authentication to the API",
    "status": "ToDo",           // ToDo, InProgress, Review, Done
    "priority": "High",         // Urgent, High, Medium, Low
    "deadline": "2025-12-20T00:00:00Z",
    "estimatedTimeMinutes": 240,
    "creatorUserId": "guid",
    "createdAt": "2025-12-14T10:00:00Z",
    "completedAt": null,
    "assigneeUserIds": ["guid1", "guid2"],
    "priorityScore": 0.85       // ⚠️ QUAN TRỌNG: Điểm ưu tiên AI (0-1)
  }
]

// ✅ Đặc điểm:
// - Tối đa 20 tasks
// - Đã sắp xếp theo priorityScore giảm dần
// - KHÔNG có tasks quá hạn (đã lọc)
// - Chỉ tasks: ToDo, InProgress, Review
```

### 4.2. Lấy My Tasks (Tasks được giao cho tôi)
```dart
GET /api/tasks?page=1&pageSize=20&status=ToDo&priority=High

// Query Parameters (TẤT CẢ optional):
// - page: số trang (default: 1)
// - pageSize: số items/trang (default: 10, max: 100)
// - status: lọc theo trạng thái
// - priority: lọc theo độ ưu tiên
// - search: tìm kiếm theo title/description

// Response với pagination
{
  "items": [
    {
      "taskId": "guid",
      "title": "Fix login bug",
      "status": "InProgress",
      "priority": "Urgent",
      "deadline": "2025-12-15T00:00:00Z",
      // ... các trường khác
    }
  ],
  "totalCount": 150,      // ⚠️ Tổng số tasks (dùng để tính số trang)
  "currentPage": 1,
  "pageSize": 20,
  "totalPages": 8
}

// ✅ Cách dùng trong UI:
final hasMore = currentPage < totalPages;
final displayText = "Showing ${items.length} of $totalCount tasks";
```

### 4.3. Lấy Workspace Tasks
```dart
GET /api/workspaces/{workspaceId}/tasks?page=1&pageSize=50

// Response: Giống /api/tasks (có pagination)
{
  "items": [...],
  "totalCount": 6000,
  "currentPage": 1,
  "pageSize": 50,
  "totalPages": 120
}
```

### 4.4. Tạo Task Mới
```dart
POST /api/workspaces/{workspaceId}/tasks
{
  "title": "Design new homepage",
  "description": "Create wireframes and mockups",
  "priority": "High",
  "deadline": "2025-12-25T00:00:00Z",
  "estimatedTimeMinutes": 360,
  "assigneeUserIds": ["guid1", "guid2"]  // Optional: giao task ngay
}

// Response: 201 Created
{
  "taskId": "guid",
  "title": "Design new homepage",
  // ... full task object
}
```

### 4.5. Update Task
```dart
PUT /api/tasks/{taskId}
{
  "title": "Updated title",
  "description": "Updated description",
  "priority": "Urgent",
  "deadline": "2025-12-30T00:00:00Z",
  "estimatedTimeMinutes": 480
}
```

### 4.6. Update Task Status
```dart
PUT /api/tasks/{taskId}/status
{
  "newStatus": "InProgress"  // ToDo, InProgress, Review, Done
}

// ⚠️ LƯU Ý: Với status "Done", nên dùng workflow approve thay vì endpoint này
```

### 4.7. Delete Task
```dart
DELETE /api/tasks/{taskId}
// Response: 204 No Content
```

---

## 🎯 5. Task Assignment Workflow

### 5.1. Giao task cho user
```dart
POST /api/tasks/{taskId}/assign
{
  "assigneeUserId": "guid",
  "message": "Please complete this by Friday"  // Optional
}

// Response
{
  "taskId": "guid",
  "assigneeUserId": "guid",
  "assignerUserId": "guid",
  "status": "Pending",  // Pending -> Accepted -> InProgress -> CompletionRequested -> Approved
  "assignedAt": "2025-12-14T10:00:00Z"
}
```

### 5.2. User respond assignment (Accept/Reject)
```dart
POST /api/tasks/{taskId}/respond
{
  "response": "Accept",  // Accept hoặc Reject
  "message": "I'll work on this task"  // Optional
}

// Response
{
  "taskId": "guid",
  "status": "Accepted",  // hoặc "Rejected"
  "responseAt": "2025-12-14T11:00:00Z"
}
```

### 5.3. Request completion (Assignee xin duyệt hoàn thành)
```dart
POST /api/tasks/{taskId}/request-completion
{
  "message": "Task completed, please review"  // Optional
}

// Response
{
  "taskId": "guid",
  "status": "CompletionRequested",
  "completionRequestedAt": "2025-12-15T10:00:00Z"
}
```

### 5.4. Approve completion (PM duyệt)
```dart
POST /api/tasks/{taskId}/approve-completion
{
  "approved": true,  // true = approve, false = reject
  "message": "Great work!"  // Optional
}

// Response (if approved)
{
  "taskId": "guid",
  "status": "Approved",
  "approvedAt": "2025-12-15T11:00:00Z",
  "task": {
    "taskId": "guid",
    "status": "Done",  // ⚠️ Task status tự động chuyển sang Done
    "completedAt": "2025-12-15T11:00:00Z"
  }
}
```

### 5.5. Lấy assignments của task
```dart
GET /api/tasks/{taskId}/assignments

// Response
[
  {
    "taskId": "guid",
    "assigneeUserId": "guid",
    "assigneeFullName": "Bob Johnson",
    "assigneeEmail": "bob@example.com",
    "assignerUserId": "guid",
    "assignerFullName": "Alice Smith",
    "status": "Accepted",
    "assignedAt": "2025-12-14T10:00:00Z",
    "responseAt": "2025-12-14T11:00:00Z"
  }
]
```

---

## 💬 6. Comments

### Thêm comment
```dart
POST /api/tasks/{taskId}/comments
{
  "content": "This looks good, but please add error handling"
}

// Response
{
  "commentID": "guid",
  "taskID": "guid",
  "userID": "guid",
  "content": "This looks good...",
  "createdAt": "2025-12-14T10:00:00Z",
  "fullName": "Alice Smith"
}
```

### Lấy comments
```dart
GET /api/tasks/{taskId}/comments

// Response
[
  {
    "commentID": "guid",
    "content": "This looks good...",
    "createdAt": "2025-12-14T10:00:00Z",
    "fullName": "Alice Smith"
  }
]
```

### Update comment
```dart
PUT /api/comments/{commentId}
{
  "content": "Updated comment text"
}
```

### Delete comment
```dart
DELETE /api/comments/{commentId}
```

---

## 📎 7. Attachments

### Upload file
```dart
POST /api/tasks/{taskId}/attachments
Content-Type: multipart/form-data

// FormData
{
  file: <binary file>
}

// Response
{
  "attachmentID": "guid",
  "taskID": "guid",
  "fileName": "document.pdf",
  "filePath": "/uploads/tasks/xxx.pdf",
  "fileSize": 1024000,
  "mimeType": "application/pdf",
  "uploadedAt": "2025-12-14T10:00:00Z",
  "uploadedByUserID": "guid",
  "uploadedByName": "Alice Smith"
}

// ⚠️ Max file size: 10MB
// ⚠️ Allowed types: pdf, doc, docx, xls, xlsx, png, jpg, jpeg, gif, txt
```

### Lấy attachments
```dart
GET /api/tasks/{taskId}/attachments

// Response
[
  {
    "attachmentID": "guid",
    "fileName": "document.pdf",
    "filePath": "/uploads/tasks/xxx.pdf",
    "fileSize": 1024000,
    "mimeType": "application/pdf",
    "uploadedAt": "2025-12-14T10:00:00Z",
    "uploadedByName": "Alice Smith"
  }
]
```

### Download file
```dart
GET /api/attachments/{attachmentId}/download
// Returns file binary
```

### Delete attachment
```dart
DELETE /api/attachments/{attachmentId}
```

---

## 🏷️ 8. Tags

### Lấy tags của workspace
```dart
GET /api/workspaces/{workspaceId}/tags

// Response
[
  {
    "tagID": "guid",
    "workspaceID": "guid",
    "tagName": "Frontend",
    "color": "#3498db"
  },
  {
    "tagID": "guid",
    "tagName": "Backend",
    "color": "#2ecc71"
  }
]
```

### Tạo tag
```dart
POST /api/workspaces/{workspaceId}/tags
{
  "tagName": "Urgent",
  "color": "#e74c3c"
}
```

### Gán tag cho task
```dart
POST /api/tasks/{taskId}/tags/{tagId}
// Response: 204 No Content
```

### Xóa tag khỏi task
```dart
DELETE /api/tasks/{taskId}/tags/{tagId}
```

### Lấy tags của task
```dart
GET /api/tasks/{taskId}/tags

// Response
[
  {
    "tagID": "guid",
    "tagName": "Frontend",
    "color": "#3498db"
  }
]
```

---

## 🔔 9. Notifications

### Lấy notifications
```dart
GET /api/notifications?page=1&pageSize=20

// Response với pagination
{
  "items": [
    {
      "notificationID": "guid",
      "userID": "guid",
      "message": "Bob accepted task: Fix login bug",
      "type": "TaskAssignment",  // TaskAssignment, TaskUpdate, Comment, Mention
      "relatedEntityID": "task-guid",
      "isRead": false,
      "createdAt": "2025-12-14T10:00:00Z"
    }
  ],
  "totalCount": 45,
  "currentPage": 1,
  "pageSize": 20,
  "totalPages": 3
}
```

### Đánh dấu đã đọc
```dart
PUT /api/notifications/{notificationId}/read
// Response: 204 No Content
```

### Đánh dấu tất cả đã đọc
```dart
PUT /api/notifications/read-all
```

### Đếm unread
```dart
GET /api/notifications/unread-count

// Response
{
  "unreadCount": 12
}
```

---

## 📊 10. Productivity Stats

### Lấy dashboard stats
```dart
GET /api/productivity/dashboard?startDate=2025-11-14&endDate=2025-12-14

// hoặc dùng alias
GET /api/productivity/stats?startDate=2025-11-14&endDate=2025-12-14

// Response
{
  "summary": {
    "totalAssigned": 150,
    "totalCompleted": 120,
    "totalPending": 5,
    "totalInProgress": 20,
    "totalAwaitingApproval": 3,
    "totalRejected": 2,
    "completionRate": 80.0,      // Percentage
    "avgCompletionDays": 3.5     // Average days to complete
  },
  "tasksByPriority": [
    { "priority": "Urgent", "count": 30 },
    { "priority": "High", "count": 50 },
    { "priority": "Medium", "count": 45 },
    { "priority": "Low", "count": 25 }
  ],
  "recentCompleted": [
    {
      "taskId": "guid",
      "taskTitle": "Fix login bug",
      "priority": "Urgent",
      "assignedAt": "2025-12-10T00:00:00Z",
      "completedAt": "2025-12-12T15:00:00Z",
      "completionDays": 2.5
    }
  ],
  "completionTrend": [
    { "date": "2025-12-01", "count": 4 },
    { "date": "2025-12-02", "count": 6 },
    // ... last 30 days
  ]
}
```

### Workspace productivity
```dart
GET /api/productivity/workspace/{workspaceId}?startDate=2025-11-14&endDate=2025-12-14

// Response
{
  "workspace": {
    "workspaceID": "guid",
    "workspaceName": "Team Alpha"
  },
  "totalTasks": 6000,
  "completedTasks": 4500,
  "completionRate": 75.0,
  "memberStats": [
    {
      "userId": "guid",
      "fullName": "Alice Smith",
      "tasksCompleted": 800,
      "avgCompletionDays": 2.8,
      "completionRate": 85.0
    }
  ],
  "tasksByStatus": [
    { "status": "Done", "count": 4500 },
    { "status": "InProgress", "count": 1000 },
    { "status": "ToDo", "count": 500 }
  ]
}
```

### Leaderboard
```dart
GET /api/productivity/leaderboard/{workspaceId}?startDate=2025-11-14&endDate=2025-12-14

// Response
[
  {
    "userId": "guid",
    "fullName": "Alice Smith",
    "email": "alice@example.com",
    "tasksCompleted": 800,
    "avgCompletionDays": 2.8,
    "completionRate": 85.0,
    "rank": 1
  },
  {
    "userId": "guid",
    "fullName": "Diana Martinez",
    "email": "diana@example.com",
    "tasksCompleted": 750,
    "avgCompletionDays": 3.2,
    "completionRate": 82.0,
    "rank": 2
  }
]
```

---

## 📨 11. Invitations

### Gửi lời mời vào workspace
```dart
POST /api/workspaces/{workspaceId}/invitations
{
  "inviteeEmail": "newuser@example.com",
  "role": "Member",  // Member hoặc Owner
  "message": "Join our team!"  // Optional
}

// Response
{
  "invitationID": "guid",
  "workspaceID": "guid",
  "inviteeEmail": "newuser@example.com",
  "inviterUserID": "guid",
  "role": "Member",
  "status": "Pending",
  "createdAt": "2025-12-14T10:00:00Z"
}
```

### Lấy invitations đã gửi
```dart
GET /api/workspaces/{workspaceId}/invitations

// Response
[
  {
    "invitationID": "guid",
    "inviteeEmail": "newuser@example.com",
    "inviterFullName": "Alice Smith",
    "role": "Member",
    "status": "Pending",  // Pending, Accepted, Declined, Expired
    "createdAt": "2025-12-14T10:00:00Z",
    "expiresAt": "2025-12-21T10:00:00Z"
  }
]
```

### Lấy invitations nhận được
```dart
GET /api/invitations/pending

// Response
[
  {
    "invitationID": "guid",
    "workspaceID": "guid",
    "workspaceName": "Team Beta",
    "inviterFullName": "Alice Smith",
    "inviterEmail": "alice@example.com",
    "role": "Member",
    "message": "Join our team!",
    "createdAt": "2025-12-14T10:00:00Z",
    "expiresAt": "2025-12-21T10:00:00Z"
  }
]
```

### Accept invitation
```dart
POST /api/invitations/{invitationId}/accept

// Response
{
  "invitationID": "guid",
  "status": "Accepted",
  "workspace": {
    "workspaceID": "guid",
    "workspaceName": "Team Beta"
  }
}
```

### Decline invitation
```dart
POST /api/invitations/{invitationId}/decline
```

---

## 🎛️ 12. User Weights (AI Personalization)

### Lấy AI weights của user
```dart
GET /api/user-weights

// Response
{
  "userID": "guid",
  "deadlineWeight": 0.6,      // Trọng số ưu tiên deadline (0-1)
  "importanceWeight": 0.3,    // Trọng số ưu tiên độ quan trọng (0-1)
  "effortWeight": 0.1,        // Trọng số ưu tiên công sức (0-1)
  "lastUpdated": "2025-12-14T10:00:00Z"
}

// ⚠️ Tổng = 1.0 (deadlineWeight + importanceWeight + effortWeight = 1.0)
```

### Recalculate weights (AI học lại từ hành vi)
```dart
POST /api/user-weights/recalculate

// Response
{
  "userID": "guid",
  "deadlineWeight": 0.65,  // Đã cập nhật dựa trên hành vi
  "importanceWeight": 0.25,
  "effortWeight": 0.1,
  "lastUpdated": "2025-12-14T11:00:00Z"
}
```

### Reset về mặc định
```dart
POST /api/user-weights/reset

// Response
{
  "userID": "guid",
  "deadlineWeight": 0.5,   // Default
  "importanceWeight": 0.3,
  "effortWeight": 0.2,
  "lastUpdated": "2025-12-14T11:00:00Z"
}
```

---

## 🌱 13. Database Seeding

### Seed database (Development only)
```dart
POST /api/seed

// Response
{
  "message": "Database seeded successfully",
  "data": {
    "users": 6,
    "workspaces": 1,
    "tasks": 6000,
    "tags": 10,
    "comments": 50,
    "taskAssignments": 6000
  }
}

// ⚠️ Chỉ dùng trong development
// ⚠️ Xóa toàn bộ dữ liệu cũ trước khi seed
```

---

## 🎨 UI/UX Best Practices

### 1. Hiển thị Tasks
```dart
// ✅ Hiển thị badge cho priority
Widget _priorityBadge(String priority) {
  Color color;
  switch (priority) {
    case 'Urgent': color = Colors.red; break;
    case 'High': color = Colors.orange; break;
    case 'Medium': color = Colors.blue; break;
    case 'Low': color = Colors.grey; break;
    default: color = Colors.grey;
  }
  return Chip(label: Text(priority), backgroundColor: color);
}

// ✅ Hiển thị trạng thái deadline
Widget _deadlineBadge(DateTime? deadline, String status) {
  if (deadline == null) return SizedBox();
  
  final isOverdue = deadline.isBefore(DateTime.now()) && status != 'Done';
  final isSoon = deadline.difference(DateTime.now()).inDays <= 2;
  
  return Container(
    padding: EdgeInsets.all(4),
    color: isOverdue ? Colors.red : (isSoon ? Colors.orange : Colors.green),
    child: Text(
      DateFormat('MMM dd').format(deadline),
      style: TextStyle(color: Colors.white),
    ),
  );
}
```

### 2. Hiển thị AI Score
```dart
// ✅ Hiển thị priorityScore từ AI
Widget _aiScoreBadge(double score) {
  return Row(
    children: [
      Icon(Icons.psychology, color: Colors.purple, size: 16),
      SizedBox(width: 4),
      Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 12)),
    ],
  );
}
```

### 3. Pagination
```dart
// ✅ Infinite scroll
class TaskListView extends StatefulWidget {
  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  int currentPage = 1;
  List<Task> tasks = [];
  bool hasMore = true;
  bool loading = false;
  
  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    
    setState(() => loading = true);
    
    final response = await dio.get('/api/tasks', 
      queryParameters: {'page': currentPage, 'pageSize': 20}
    );
    
    final newTasks = (response.data['items'] as List)
      .map((e) => Task.fromJson(e))
      .toList();
    
    setState(() {
      tasks.addAll(newTasks);
      currentPage++;
      hasMore = currentPage <= response.data['totalPages'];
      loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == tasks.length) {
          loadMore();
          return Center(child: CircularProgressIndicator());
        }
        return TaskCard(task: tasks[index]);
      },
    );
  }
}
```

### 4. Real-time notifications
```dart
// ✅ Poll notifications mỗi 30 giây
Timer.periodic(Duration(seconds: 30), (timer) async {
  final response = await dio.get('/api/notifications/unread-count');
  final count = response.data['unreadCount'];
  
  if (count > 0) {
    // Update badge
    setState(() => unreadCount = count);
  }
});
```

---

## 🔍 Testing với Swagger

Mở Swagger UI: `http://localhost:5131/swagger`

1. Click **Authorize** button
2. Nhập token: `Bearer {token}` (lấy từ `/api/auth/login`)
3. Try out các endpoints

---

## 🚀 Quick Start Checklist

- [ ] Login và lưu token
- [ ] Set Authorization header cho mọi request
- [ ] Lấy workspace ID từ `/api/workspaces`
- [ ] Lấy suggested tasks từ `/api/tasks/suggested`
- [ ] Hiển thị pagination đúng cách
- [ ] Handle 401 error (token expired)
- [ ] Hiển thị deadline warning
- [ ] Show AI priority score
- [ ] Implement task assignment workflow
- [ ] Poll notifications

---

## 📞 Support

Nếu còn lỗi, kiểm tra:
1. Token có đúng format `Bearer {token}`?
2. Endpoint URL có đúng không? (kiểm tra trailing slash)
3. Request body có đúng format JSON?
4. Response có status code gì? (200, 201, 400, 401, 404, 500)
5. Check console log trong backend

**Backend logs** sẽ hiển thị chi tiết lỗi khi chạy `dotnet run`.
