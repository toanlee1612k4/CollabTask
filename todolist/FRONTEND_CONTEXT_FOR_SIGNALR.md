# 📋 CONTEXT FILE - FRONTEND ARCHITECTURE (CollabTask)
## Chuẩn bị tích hợp Real-time với SignalR

**Ngày tạo:** 02/01/2026  
**Mục đích:** Context cho việc triển khai SignalR Real-time Notifications

---

## 1️⃣ STATE MANAGEMENT

### **Framework:** Flutter Riverpod 2.4.9 + Provider 6.1.5

**Setup Architecture:**
- **Main Setup:** `lib/main.dart`
- **Riverpod Providers:** `lib/providers/`
  - `auth_provider.dart` - Authentication state (Riverpod)
  - `ai_suggestions_provider.dart` - AI suggestions (Riverpod)
  - `create_task_provider.dart` - Create task form (Riverpod)
- **Legacy Provider:** `lib/core/providers/legacy_providers.dart`
  - `AuthProvider`, `TaskProvider`, `WorkspaceProvider`, `ThemeProvider` (dùng Provider cũ)

**Cấu trúc main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API client
  apiClient.initialize();
  
  // Setup 401 handler
  apiClient.onUnauthorized = () {
    print('🚨 API returned 401 - User will be logged out');
  };
  
  runApp(
    ProviderScope( // ✅ Riverpod root
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CollabTaskApp(),
    ),
  );
}

class CollabTaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider( // ⚠️ Legacy Provider wrapper
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => TaskProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(...),
    );
  }
}
```

**⚠️ Lưu ý khi implement SignalR:**
- Dùng **Riverpod StateNotifierProvider** cho SignalR state
- Có thể cần listen cả **legacy Provider** để tương thích screens cũ
- Auth state có sẵn `AuthNotifier` (Riverpod) + `AuthProvider` (legacy)

---

## 2️⃣ API CLIENT

### **HTTP Library:** Dio 5.4.0

**File:** `lib/data/services/api_client.dart`

**Singleton Pattern:**
```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  String? _token;
  
  // Callback for 401 unauthorized
  void Function()? onUnauthorized;

  // Expose Dio instance for custom requests
  Dio get dio => _dio;

  // Base URL
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5131'; // ✅ Backend URL
    }
    return 'http://localhost:5131';
  }
}
```

**Global Instance:**
```dart
// Trong main.dart
final ApiClient apiClient = ApiClient();

void main() async {
  apiClient.initialize();
  // ...
}
```

**Interceptor (401 Handler):**
```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    if (_token != null) {
      options.headers['Authorization'] = 'Bearer $_token'; // ✅ JWT Token
    }
    handler.next(options);
  },
  onError: (error, handler) async {
    // Handle 401 Unauthorized
    if (error.response?.statusCode == 401) {
      print('🚨 401 Unauthorized - Logging out user');
      await clearToken();
      onUnauthorized?.call(); // ✅ Trigger logout
    }
    handler.next(error);
  },
));
```

**Base URL cho SignalR Hub:**
- **Backend:** `http://localhost:5131`
- **SignalR Hub URL (dự kiến):** `http://localhost:5131/hubs/notifications`

**Token Management:**
```dart
Future<void> setToken(String token) async {
  _token = token;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<void> loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString('auth_token');
}
```

---

## 3️⃣ DATA MODELS

### **File:** `lib/data/models/models.dart`

### 📦 **TaskModel**
```dart
class TaskModel {
  final String taskId;
  final String title;
  final String? description;
  final String status; // "ToDo", "InProgress", "Completed", "Overdue"
  final String priority; // "Urgent", "High", "Medium", "Low"
  final DateTime? deadline;
  final int? estimatedTimeMinutes;
  final double priorityScore; // AI Score (0-10)
  final String? aiReason; // AI explanation
  final String? workspaceId;
  final List<String> assigneeUserIds; // ✅ Danh sách người được gán
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  TaskModel({
    required this.taskId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.deadline,
    this.estimatedTimeMinutes,
    required this.priorityScore,
    this.aiReason,
    this.workspaceId,
    List<String>? assigneeUserIds,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  }) : assigneeUserIds = assigneeUserIds ?? [];

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'ToDo',
      priority: json['priority'] ?? 'Medium',
      // ✅ Convert UTC to local time when receiving from API
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']).toLocal() 
          : null,
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
      priorityScore: (json['priorityScore'] ?? 0.0).toDouble(),
      aiReason: json['aiReason']?.toString() ?? json['reason']?.toString(),
      workspaceId: json['workspaceId']?.toString(),
      assigneeUserIds: (json['assigneeUserIds'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal() 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']).toLocal() 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']).toLocal() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      // ✅ Convert local time to UTC when sending to API
      'deadline': deadline?.toUtc().toIso8601String(),
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'priorityScore': priorityScore,
      'workspaceId': workspaceId,
      'assigneeUserIds': assigneeUserIds,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
    };
  }

  // Helper methods
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && status != 'Completed';
  }

  bool get isHighPriority => priorityScore >= 8.0;
}
```

### 👤 **UserModel**
```dart
class UserModel {
  final String userId;
  final String email;
  final String? fullName;
  final String? avatar;
  final DateTime? createdAt;
  final String? roleName; // Role in workspace (Owner, ProjectManager, Member)

  UserModel({
    required this.userId,
    required this.email,
    this.fullName,
    this.avatar,
    this.createdAt,
    this.roleName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal() 
          : null,
      roleName: json['roleName'] ?? json['role'],
    );
  }
}
```

### 🔔 **NotificationModel** (Đã có sẵn)
```dart
class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String type; // "info", "success", "warning", "error", "task_update", "comment"
  final bool isRead;
  final DateTime createdAt;
  final String? relatedTaskId;
  final String? relatedWorkspaceId;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedTaskId,
    this.relatedWorkspaceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId']?.toString() ?? 
                     json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      relatedTaskId: json['relatedTaskId']?.toString(),
      relatedWorkspaceId: json['relatedWorkspaceId']?.toString(),
    );
  }
}
```

### 💬 **CommentModel**
```dart
class CommentModel {
  final String commentId;
  final String content;
  final String authorId;
  final String authorName;
  final String taskId;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.taskId,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId']?.toString() ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName'] ?? '',
      taskId: json['taskId']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

---

## 4️⃣ NOTIFICATION UI

### **Screens:**
- ✅ **`lib/presentation/screens/notifications/notifications_screen.dart`** (540 lines)

**Chức năng hiện tại:**
```dart
class NotificationsScreen extends StatefulWidget {
  // Features:
  // - Load notifications từ API: GET /api/notifications
  // - Filter: Show all / Unread only
  // - Mark as read: PATCH /api/notifications/{id}/read
  // - Mark all as read (bulk)
  // - Delete notification: DELETE /api/notifications/{id}
  // - Navigate to related Task/Workspace
  // - Unread badge count
}

// API Endpoints đang dùng:
_loadNotifications() => GET /api/notifications
_markAsRead(id) => PATCH /api/notifications/{id}/read
_deleteNotification(id) => DELETE /api/notifications/{id}
```

### **UI Components:**

1. **SnackBar** (toàn app):
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text('✅ Thành công')),
   );
   ```

2. **Dialog** (confirmation):
   ```dart
   final confirm = await showDialog<bool>(
     context: context,
     builder: (context) => AlertDialog(
       title: Text('Xác nhận'),
       actions: [
         TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
         ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('OK')),
       ],
     ),
   );
   ```

3. **Notification Badge** (chưa có - cần implement):
   - Hiện tại: Không có badge ở AppBar/TopBar
   - **TODO:** Thêm notification badge với unread count

### **File SignalR đã có (Polling-based):**
- ✅ **`lib/data/services/signalr_service.dart`** (189 lines)

**Code hiện tại (Polling):**
```dart
class SignalRService {
  // Polling every 3 seconds
  Timer? _pollingTimer;
  
  final _commentController = StreamController<CommentNotification>.broadcast();
  final _taskUpdateController = StreamController<TaskUpdateNotification>.broadcast();
  
  Stream<CommentNotification> get onCommentReceived => _commentController.stream;
  Stream<TaskUpdateNotification> get onTaskUpdated => _taskUpdateController.stream;

  Future<void> connect({
    required String baseUrl,
    required String userId,
    required String token,
  }) async {
    // Start polling for updates every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollForUpdates();
    });
  }

  Future<void> _pollForUpdates() async {
    // Poll for new comments
    final commentsResponse = await _dio.get('/api/notifications/comments/new');
    
    // Poll for task updates
    final tasksResponse = await _dio.get('/api/notifications/tasks/new');
  }
}
```

**⚠️ Hiện trạng:** File này dùng **Polling** (fake SignalR), chưa dùng SignalR thật.

---

## 5️⃣ DEPENDENCIES (pubspec.yaml)

```yaml
dependencies:
  flutter_sdk: ^3.9.2
  
  # State Management
  provider: ^6.1.5+1          # Legacy Provider
  flutter_riverpod: ^2.4.9    # ✅ Riverpod (mới)
  
  # HTTP & API
  dio: ^5.4.0                 # ✅ HTTP Client
  
  # Storage
  shared_preferences: ^2.2.2  # Token storage
  flutter_secure_storage: ^9.0.0
  
  # UI & Design
  google_fonts: ^6.1.0
  flutter_animate: ^4.5.0
  fl_chart: ^0.69.0
  percent_indicator: ^4.2.3
  cached_network_image: ^3.3.1
  
  # Utilities
  intl: ^0.20.2              # ✅ Date formatting (vi_VN locale)
  url_launcher: ^6.3.2
  image_picker: ^1.1.2
  file_picker: ^6.1.0
  
  # OAuth
  google_sign_in: ^6.2.0
  flutter_facebook_auth: ^6.0.0
  
  # ⚠️ CHƯA CÓ: signalr_netcore hoặc signalr_flutter
```

**🚨 Cần thêm cho SignalR:**
```yaml
dependencies:
  signalr_netcore: ^1.3.7   # ✅ SignalR client cho .NET Core
  # HOẶC
  signalr_flutter: ^0.3.0   # Alternative
```

---

## 6️⃣ AUTH FLOW

### **File:** `lib/providers/auth_provider.dart` (Riverpod)

**AuthState:**
```dart
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  failure
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
}
```

**AuthNotifier (Riverpod):**
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AuthNotifier(this._apiClient, this._prefs) : super(const AuthState.initial()) {
    _checkAuthStatus(); // ✅ Check token on app start
  }

  Future<void> _checkAuthStatus() async {
    final token = _prefs.getString('auth_token');
    
    if (token != null) {
      await _apiClient.setToken(token);
      
      // Optimistic update (set authenticated immediately)
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: null, // ✅ User will be fetched in background
      );
      
      // Fetch user info in background
      _fetchUserInBackground();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final response = await _apiClient.login(email, password);
      final token = response.token;
      
      await _prefs.setString('auth_token', token);
      await _apiClient.setToken(token);
      
      final user = await _apiClient.getCurrentUser();
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    await _prefs.remove('auth_token');
    state = const AuthState.initial();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(apiClient, prefs);
});
```

**⚠️ Quan trọng cho SignalR:**
- **Token:** `state.token` (JWT Bearer token)
- **UserId:** `state.user?.userId`
- **Listen auth changes:** `ref.watch(authProvider)` để connect/disconnect SignalR khi login/logout

---

## 7️⃣ FOLDER STRUCTURE

```
lib/
├── main.dart                          # ✅ Entry point, ProviderScope
├── core/
│   ├── constants/
│   │   └── app_design_system.dart     # Colors, Typography
│   ├── theme/
│   │   └── theme_provider.dart        # Dark mode (legacy Provider)
│   └── providers/
│       └── legacy_providers.dart      # TaskProvider, WorkspaceProvider
├── data/
│   ├── models/
│   │   ├── models.dart                # ✅ TaskModel, UserModel, NotificationModel
│   │   └── task_assignment_models.dart
│   └── services/
│       ├── api_client.dart            # ✅ Dio HTTP client
│       ├── signalr_service.dart       # ⚠️ Polling-based (fake SignalR)
│       ├── task_assignment_service.dart
│       └── workspace_role_service.dart
├── presentation/
│   ├── screens/
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart  # ✅ Notification UI
│   │   ├── tasks/
│   │   │   ├── create_task_screen.dart
│   │   │   └── enhanced_task_detail_screen.dart
│   │   └── settings/
│   │       └── profile_settings_screen.dart
│   └── widgets/
│       └── tasks/
│           └── task_card.dart
└── providers/                         # ✅ Riverpod providers
    ├── auth_provider.dart             # Authentication
    ├── ai_suggestions_provider.dart   # AI suggestions
    └── create_task_provider.dart      # Create task form
```

---

## 8️⃣ RECOMMENDATIONS CHO SIGNALR IMPLEMENTATION

### **A. Architecture Recommendations**

1. **Tạo SignalR Provider (Riverpod):**
   ```dart
   // lib/providers/signalr_provider.dart
   final signalrProvider = StateNotifierProvider<SignalRNotifier, SignalRState>((ref) {
     return SignalRNotifier(ref);
   });
   ```

2. **Listen Auth State:**
   ```dart
   class SignalRNotifier extends StateNotifier<SignalRState> {
     SignalRNotifier(this.ref) : super(SignalRState.initial()) {
       // Listen auth changes
       ref.listen(authProvider, (previous, next) {
         if (next.status == AuthStatus.authenticated) {
           _connect(next.token!, next.user!.userId);
         } else {
           _disconnect();
         }
       });
     }
   }
   ```

3. **Real-time Updates Flow:**
   ```
   SignalR Hub → SignalRNotifier → Riverpod State → UI Updates
   ```

### **B. Integration Points**

1. **NotificationsScreen:**
   - Listen `signalrProvider.onNotificationReceived`
   - Auto-refresh notification list
   - Show badge count

2. **TaskDetailScreen:**
   - Listen `signalrProvider.onTaskUpdated`
   - Refresh task when updated by others
   - Show "Task updated by X" banner

3. **Dashboard:**
   - Listen `signalrProvider.onCommentReceived`
   - Show real-time comment notifications

### **C. API Endpoints cần Backend:**

```
SignalR Hub: /hubs/notifications
Methods:
  - JoinUserGroup(userId)
  - LeaveUserGroup(userId)
  - SendTaskUpdate(taskId, updateType)
  - SendNewComment(taskId, commentId)
  
REST Fallback:
  - GET /api/notifications/unread-count
  - POST /api/notifications/mark-read/{id}
```

---

## 9️⃣ QUICK REFERENCE

### **Cách lấy current user:**
```dart
final authState = ref.watch(authProvider);
final currentUser = authState.user;
final userId = currentUser?.userId;
final token = authState.token;
```

### **Cách hiện SnackBar:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('🔔 New notification!'),
    backgroundColor: AppColors.primary,
  ),
);
```

### **Cách navigate:**
```dart
// Push
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NotificationsScreen()),
);

// Pop with result
Navigator.pop(context, result);
```

### **DateTime handling:**
```dart
// ✅ Từ API (UTC) → Local
DateTime.parse(json['createdAt']).toLocal()

// ✅ Gửi API (Local) → UTC
DateTime.now().toUtc().toIso8601String()
```

---

## 🎯 NEXT STEPS

1. ✅ Thêm `signalr_netcore: ^1.3.7` vào `pubspec.yaml`
2. ✅ Tạo `lib/providers/signalr_provider.dart` (Riverpod)
3. ✅ Update `signalr_service.dart` để dùng SignalR thật (thay vì polling)
4. ✅ Integrate vào `NotificationsScreen`
5. ✅ Thêm notification badge vào AppBar
6. ✅ Test real-time notifications

---

**📌 File này là Context hoàn chỉnh cho việc implement SignalR Real-time!**
