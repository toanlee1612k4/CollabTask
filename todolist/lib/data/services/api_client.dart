import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/models/task_assignment_models.dart';
import 'task_assignment_service.dart';
import 'workspace_role_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  late TaskAssignmentService taskAssignment;
  late WorkspaceRoleService workspaceRole;
  String? _token;
  
  // Callback for 401 unauthorized - will be set by AuthProvider
  void Function()? onUnauthorized;

  // Expose Dio instance for custom requests
  Dio get dio => _dio;

  // Base URL cho các platform khác nhau
  String get baseUrl {
    // Web platform
    if (kIsWeb) {
      return 'http://localhost:5131';
    }
    // Mobile/Desktop - có thể thêm logic phức tạp hơn sau
    return 'http://localhost:5131';
  }

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Initialize services
    taskAssignment = TaskAssignmentService(_dio);
    workspaceRole = WorkspaceRoleService(_dio);

    // Interceptor để tự động thêm token vào header và handle 401
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (kDebugMode) {
          print('🚀 ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          print('❌ Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          if (error.response?.data != null) {
            print('📥 ${error.response?.data}');
          }
        }

        // Handle 401 Unauthorized - Token expired or invalid
        if (error.response?.statusCode == 401) {
          if (kDebugMode) {
            print('🚨 401 Unauthorized - Logging out user');
            onUnauthorized?.call();
          }
          
          // Clear token immediately
          await clearToken();
          
          // Trigger logout callback if set
          if (onUnauthorized != null) {
            onUnauthorized!();
          }
        }

        handler.next(error);
      },
    ));
  }

  // Set token directly (used by AuthProvider)
  Future<void> setToken(String token) async {
    _token = token;
    // Also save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Load token từ SharedPreferences
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token vào SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // ==================== AUTH ENDPOINTS ====================

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final loginResponse = LoginResponse.fromJson(response.data);
      await saveToken(loginResponse.token);
      return loginResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<UserModel>> register(String email, String password, String fullName) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      return ApiResponse.fromJson(response.data, (data) => UserModel.fromJson(data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (e) {
      // Ignore logout errors, just clear token
    } finally {
      await clearToken();
    }
  }

  // ==================== USER WEIGHTS ENDPOINTS ====================

  Future<UserWeights> getUserWeights() async {
    try {
      final response = await _dio.get('/api/user-weights');
      return UserWeights.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserWeights> resetUserWeights() async {
    try {
      final response = await _dio.post('/api/user-weights/reset');
      return UserWeights.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== TASKS ENDPOINTS ====================

  Future<List<TaskModel>> getSuggestedTasks({int limit = 20}) async {
    try {
      if (kDebugMode) {
        print('\n🔍 [API] Calling GET /api/productivity/suggested-tasks?limit=$limit');
      }
      
      // Try new endpoint first, fallback to old endpoint if 404
      Response response;
      try {
        response = await _dio.get('/api/productivity/suggested-tasks', queryParameters: {'limit': limit});
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          if (kDebugMode) {
            print('⚠️ [API] New endpoint not found, falling back to /api/suggested');
          }
          response = await _dio.get('/api/suggested');
        } else {
          rethrow;
        }
      }
      
      if (kDebugMode) {
        print('📦 [API] Response type: ${response.data.runtimeType}');
      }
      
      List<dynamic> tasksJson;
      
      // Handle both response formats
      if (response.data is Map) {
        // New format: { "suggestedTasks": [...], "message": "...", "totalCount": X }
        final data = response.data as Map<String, dynamic>;
        tasksJson = data['suggestedTasks'] ?? [];
        
        if (kDebugMode) {
          print('✅ [API] New format - Suggested tasks count: ${tasksJson.length}');
          if (data['message'] != null) {
            print('📋 [API] Message: ${data['message']}');
          }
          // 🔍 DEBUG: In ra raw JSON của task đầu tiên để kiểm tra cấu trúc
          if (tasksJson.isNotEmpty) {
            print('🔍 [DEBUG] Raw JSON of first task:');
            print('   ${jsonEncode(tasksJson.first)}');
          }
        }
      } else if (response.data is List) {
        // Old format: direct array
        tasksJson = response.data as List;
        
        if (kDebugMode) {
          print('✅ [API] Old format - Suggested tasks count: ${tasksJson.length}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [API] Unexpected response format');
        }
        return [];
      }
      
      return tasksJson.map((json) => TaskModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ getSuggestedTasks error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ getSuggestedTasks unexpected error: $e');
      }
      return [];
    }
  }

  // Get my tasks (assigned to current user) with pagination
  Future<PagedResult<TaskModel>> getMyTasks({int page = 1, int pageSize = 100, String? status, String? priority}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      
      if (kDebugMode) {
        print('\n🔍 [API] Calling GET /api/tasks?page=$page&pageSize=$pageSize');
      }
      
      final response = await _dio.get('/api/tasks', queryParameters: queryParams);
      
      if (kDebugMode) {
        print('📦 [API] Response type: ${response.data.runtimeType}');
        print('📦 [API] Full response: ${jsonEncode(response.data)}');
      }
      
      // Handle paginated response
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final tasksData = data['items'] ?? data['data']; // ✅ FIX: Try 'items' first, fallback to 'data'
        
        if (tasksData is List) {
          if (kDebugMode) {
            print('✅ [API] My tasks count: ${tasksData.length}');
            print('✅ [API] totalCount: ${data['totalCount']}');
          }
          
          return PagedResult<TaskModel>(
            items: tasksData.map((json) => TaskModel.fromJson(json)).toList(),
            totalCount: data['totalCount'] ?? tasksData.length,
            currentPage: data['currentPage'] ?? page,
            pageSize: data['pageSize'] ?? pageSize,
          );
        }
      }
      
      // Empty result
      return PagedResult<TaskModel>(
        items: [],
        totalCount: 0,
        currentPage: page,
        pageSize: pageSize,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ getMyTasks error: ${e.response?.statusCode}');
      }
      if (e.response?.statusCode == 404) {
        return PagedResult<TaskModel>(items: [], totalCount: 0, currentPage: page, pageSize: pageSize);
      }
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ getMyTasks unexpected error: $e');
      }
      return PagedResult<TaskModel>(items: [], totalCount: 0, currentPage: page, pageSize: pageSize);
    }
  }

  // Get calendar tasks (assigned to current user) with date range
  Future<List<TaskModel>> getCalendarTasks({DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      
      if (kDebugMode) {
        print('\n🔍 [API] Calling GET /api/tasks/calendar');
        print('🔍 [API] Date range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}');
      }
      
      final response = await _dio.get('/api/tasks/calendar', queryParameters: queryParams);
      
      if (kDebugMode) {
        print('📦 [API] Response type: ${response.data.runtimeType}');
      }
      
      // Backend returns: { "tasks": [...], "dateRange": {...}, "totalCount": X }
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final tasksData = data['tasks'] ?? [];
        
        if (kDebugMode) {
          print('✅ [API] Calendar tasks count: ${(tasksData as List).length}');
        }
        
        return (tasksData as List).map((json) => TaskModel.fromJson(json)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ getCalendarTasks error: ${e.response?.statusCode}');
      }
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ getCalendarTasks unexpected error: $e');
      }
      return [];
    }
  }

  Future<List<TaskModel>> getTasksByWorkspace(String workspaceId, {String? status}) async {
    try {
      if (kDebugMode) {
        print('\n🔍 [API] Calling GET /api/workspaces/$workspaceId/tasks');
        print('🔍 [API] Full URL: ${_dio.options.baseUrl}/api/workspaces/$workspaceId/tasks');
        print('🔍 [API] Workspace ID: $workspaceId');
        if (status != null) print('   Filter: status=$status');
      }
      
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get('/api/workspaces/$workspaceId/tasks', 
          queryParameters: queryParams);
      
      if (kDebugMode) {
        print('📦 [API] Response status: ${response.statusCode}');
        print('📦 [API] Response type: ${response.data.runtimeType}');
        print('📦 [API] Full response JSON:');
        print(jsonEncode(response.data));
        
        // Check if response has pagination (items, totalCount) or is direct array
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          print('\n📊 [API] Paginated response:');
          print('   totalCount: ${data['totalCount']}');
          print('   currentPage: ${data['currentPage']}');
          print('   pageSize: ${data['pageSize']}');
          print('   items count: ${(data['items'] as List?)?.length ?? 0}');
          print('   items key exists: ${data.containsKey('items')}');
          print('   items value: ${data['items']}');
          
          if ((data['items'] as List?)?.isNotEmpty ?? false) {
            print('📋 [API] First task sample:');
            print(jsonEncode((data['items'] as List).first));
          } else {
            print('⚠️ [API] Paginated response has ZERO items!');
            print('⚠️ [API] This is a BACKEND BUG: totalCount=${data['totalCount']} but items=[]');
          }
        } else if (response.data is List) {
          print('📊 [API] Direct array response: ${(response.data as List).length} tasks');
          if ((response.data as List).isNotEmpty) {
            print('📋 [API] First task sample:');
            print(jsonEncode((response.data as List).first));
          } else {
            print('⚠️ [API] Direct array response has ZERO tasks!');
          }
        }
      }
      
      // Handle both paginated and direct array responses per API guide
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] ?? []) as List;
        if (kDebugMode) {
          print('✅ [API] Returning ${items.length} tasks from paginated response');
        }
        return items.map((json) => TaskModel.fromJson(json)).toList();
      } else if (response.data is List) {
        final tasks = (response.data as List).map((json) => TaskModel.fromJson(json)).toList();
        if (kDebugMode) {
          print('✅ [API] Returning ${tasks.length} tasks from direct array');
        }
        if (kDebugMode) {
          print('✅ [API] Returning ${tasks.length} tasks from direct array');
        }
        return tasks;
      }
      
      if (kDebugMode) {
        print('⚠️ [API] Unexpected response format, returning empty list');
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [API] getTasksByWorkspace error: ${e.response?.statusCode} - ${e.message}');
      }
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [API] getTasksByWorkspace unexpected error: $e');
      }
      return [];
    }
  }

  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId');
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskModel> completeTask(String taskId) async {
    try {
      final response = await _dio.patch('/api/tasks/$taskId/complete');
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskModel> createTask(String workspaceId, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/api/workspaces/$workspaceId/tasks', data: taskData);
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.put('/api/tasks/$taskId', data: taskData);
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== WORKSPACES ENDPOINTS ====================

  Future<List<WorkspaceModel>> getWorkspaces() async {
    try {
      final response = await _dio.get('/api/workspaces');
      if (response.data == null || response.data is! List) return [];
      final List<dynamic> workspacesJson = response.data;
      return workspacesJson.map((json) => WorkspaceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  Future<WorkspaceModel> getWorkspaceById(String workspaceId) async {
    try {
      final response = await _dio.get('/api/workspaces/$workspaceId');
      return WorkspaceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<WorkspaceModel> createWorkspace(String name, String? description) async {
    try {
      final response = await _dio.post('/api/workspaces', data: {
        'workspaceName': name, // Backend expects 'workspaceName'
        'description': description,
      });
      return WorkspaceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<WorkspaceModel> updateWorkspace(
    String workspaceId,
    String name,
    String? description,
  ) async {
    try {
      final response = await _dio.put('/api/workspaces/$workspaceId', data: {
        'workspaceName': name,
        'description': description,
      });
      return WorkspaceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      await _dio.delete('/api/workspaces/$workspaceId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get workspace members
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async {
    try {
      final response = await _dio.get('/api/workspaces/$workspaceId/members');
      
      // Handle null or non-list responses
      if (response.data == null) return [];
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }
      
      // Backend returned object instead of array
      if (kDebugMode) {
        print('⚠️ getWorkspaceMembers received object instead of array');
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  // Send workspace invitation (add member directly - backend doesn't have /invite endpoint)
  // Send workspace invitation (NEW backend endpoint)
  Future<Map<String, dynamic>> sendWorkspaceInvitation(String workspaceId, String userEmail, {String role = 'Member', String? message}) async {
    try {
      final response = await _dio.post(
        '/api/workspaces/$workspaceId/invitations',
        data: {
          'email': userEmail,
          'role': role,
          if (message != null) 'message': message,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Remove member from workspace
  Future<void> removeWorkspaceMember(String workspaceId, String userId) async {
    try {
      await _dio.delete('/api/workspaces/$workspaceId/members/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update workspace member role
  Future<void> updateWorkspaceMemberRole(String workspaceId, String userId, String newRole) async {
    try {
      await _dio.put('/api/workspaces/$workspaceId/members/$userId/role', data: {
        'role': newRole,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Leave workspace (current user)
  Future<void> leaveWorkspace(String workspaceId) async {
    try {
      await _dio.post('/api/workspaces/$workspaceId/leave');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign users to task (supports multiple assignees)
  Future<void> assignUsersToTask(String taskId, List<String> userIds, {String? note}) async {
    try {
      await _dio.post('/api/tasks/$taskId/assign', data: {
        'assigneeUserIds': userIds,
        if (note != null) 'note': note,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Unassign user from task
  Future<void> unassignUserFromTask(String taskId, String userId) async {
    try {
      await _dio.delete('/api/tasks/$taskId/assignments/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add tag to task
  Future<void> addTagToTask(String taskId, String tagName, String color) async {
    try {
      await _dio.post('/api/tasks/$taskId/tags', data: {
        'name': tagName,
        'color': color,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Remove tag from task
  Future<void> removeTagFromTask(String taskId, String tagId) async {
    try {
      await _dio.delete('/api/tasks/$taskId/tags/$tagId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update task status with role-based permissions
  Future<TaskModel> updateTaskStatus(String taskId, String newStatus, String userRole) async {
    try {
      final response = await _dio.put('/api/tasks/$taskId/status', data: {
        'NewStatus': newStatus,
      });
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Accept workspace invitation (by invitationId)
  Future<Map<String, dynamic>> acceptWorkspaceInvitation(String invitationId) async {
    try {
      final response = await _dio.post('/api/workspaces/invitations/$invitationId/accept');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reject workspace invitation (by invitationId)
  Future<void> rejectWorkspaceInvitation(String invitationId, {String? reason}) async {
    try {
      await _dio.post(
        '/api/workspaces/invitations/$invitationId/reject',
        data: {
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get pending workspace invitations for current user
  Future<List<Map<String, dynamic>>> getWorkspaceInvitations() async {
    try {
      final response = await _dio.get('/api/workspaces/invitations');
      
      if (response.data == null) return [];
      
      if (response.data is List) {
        return (response.data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      
      if (response.data is Map) {
        if (kDebugMode) {
          print('⚠️ Received object instead of array');
        }
        return [];
      }
      
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  // Get workspace invitations list (for Owner/PM to manage)
  Future<List<Map<String, dynamic>>> getWorkspaceInvitationsList(String workspaceId) async {
    try {
      final response = await _dio.get('/api/workspaces/$workspaceId/invitations');
      
      if (response.data == null || response.data is! List) {
        return [];
      }
      
      final invitations = (response.data as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      return invitations;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  // Cancel workspace invitation (Owner/PM only)
  Future<void> cancelWorkspaceInvitation(String workspaceId, String invitationId) async {
    try {
      await _dio.delete('/api/workspaces/$workspaceId/invitations/$invitationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _dio.delete('/api/tasks/$taskId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  // ==================== TASK ASSIGNMENT WORKFLOW ====================

  Future<List<TaskAssignment>> getTaskAssignments(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId/assignments');
      if (response.data == null || response.data is! List) return [];
      final List<dynamic> assignmentsJson = response.data;
      return assignmentsJson.map((json) => TaskAssignment.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  Future<void> approveCompletion(String taskId, bool approve, {String? note}) async {
    try {
      await _dio.post('/api/tasks/$taskId/approve-completion', data: {
        'approve': approve,
        if (note != null) 'note': note,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  // ==================== TASK ATTACHMENTS ENDPOINTS ====================

  Future<List<TaskAttachment>> getTaskAttachments(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId/attachments');
      if (response.data == null || response.data is! List) return [];
      final List<dynamic> attachmentsJson = response.data;
      return attachmentsJson.map((json) => TaskAttachment.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  Future<TaskAttachment> uploadAttachment(
    String taskId,
    dynamic file, // PlatformFile from file_picker
    {Function(double)? onProgress}
  ) async {
    try {
      // Prepare FormData
      FormData formData;
      
      // Check if file has bytes (web) or path (mobile/desktop)
      if (file.bytes != null) {
        // Web: use bytes
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        });
      } else if (file.path != null) {
        // Mobile/Desktop: use file path
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          ),
        });
      } else {
        throw Exception('File must have either bytes or path');
      }

      final response = await _dio.post(
        '/api/tasks/$taskId/attachments',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) => onProgress(sent / total)
            : null,
      );
      
      return TaskAttachment.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> downloadAttachment(String taskId, String attachmentId, String savePath) async {
    try {
      await _dio.download(
        '/api/tasks/$taskId/attachments/$attachmentId/download',
        savePath,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAttachment(String taskId, String attachmentId) async {
    try {
      await _dio.delete('/api/tasks/$taskId/attachments/$attachmentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== NOTIFICATIONS ENDPOINTS ====================

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('/api/notifications');
      if (response.data == null || response.data is! List) return [];
      final List<dynamic> notificationsJson = response.data;
      return notificationsJson.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  Future<NotificationModel> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dio.put('/api/notifications/$notificationId/read');
      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/api/notifications/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('/api/notifications/read-all');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== COMMENTS ENDPOINTS ====================

  Future<List<CommentModel>> getCommentsByTask(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId/comments');
      if (response.data == null || response.data is! List) return [];
      final List<dynamic> commentsJson = response.data;
      return commentsJson.map((json) => CommentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleError(e);
    } catch (e) {
      return [];
    }
  }

  Future<CommentModel> createComment(String taskId, String content) async {
    try {
      final response = await _dio.post('/api/tasks/$taskId/comments', data: {
        'content': content,
      });
      return CommentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== USERS ENDPOINTS ====================

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/users/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put('/api/users/me', data: userData);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user statistics (total tasks, workspaces count)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (kDebugMode) {
        print('\n🔍 [API] Calling GET /api/productivity/dashboard');
      }
      
      // Use correct productivity endpoint that actually exists in backend
      final response = await _dio.get('/api/productivity/dashboard');
      
      if (kDebugMode) {
        print('📦 [API] Raw response from /api/productivity/dashboard:');
        print(jsonEncode(response.data));
      }
      
      if (response.data == null) {
        if (kDebugMode) {
          print('⚠️ [API] Response data is null, returning defaults');
        }
        return {
          'totalTasksCompleted': 0,
          'averageCompletionTime': 0.0,
          'onTimeCompletionRate': 0.0,
          'currentStreak': 0,
          'longestStreak': 0,
        };
      }
      
      // Backend returns nested structure with 'summary' object per guide
      final data = response.data as Map<String, dynamic>;
      final summary = data['summary'] as Map<String, dynamic>? ?? data;
      
      final result = {
        'totalTasksCompleted': summary['totalCompleted'] ?? summary['completedTasks'] ?? 0,
        'averageCompletionTime': (summary['avgCompletionDays'] ?? summary['averageCompletionTime'] ?? 0.0).toDouble(),
        'onTimeCompletionRate': (summary['completionRate'] ?? summary['onTimeRate'] ?? 0.0).toDouble(),
        'currentStreak': summary['currentStreak'] ?? 0,
        'longestStreak': summary['longestStreak'] ?? 0,
      };
      
      if (kDebugMode) {
        print('✅ [API] Mapped user stats:');
        print('   totalCompleted: ${result['totalTasksCompleted']}');
        print('   onTimeRate: ${result['onTimeCompletionRate']}%');
        print('   avgCompletionTime: ${result['averageCompletionTime']} days');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [API] getUserStats error: $e');
      }
      return {
        'totalTasksCompleted': 0,
        'averageCompletionTime': 0.0,
        'onTimeCompletionRate': 0.0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }
  }

  // ==================== WORKSPACE ROLE SERVICE ====================  // ==================== ERROR HANDLING ====================

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối mạng bị timeout. Vui lòng thử lại.';
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        
        if (statusCode == 401) {
          clearToken(); // Clear invalid token
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }
        
        if (statusCode == 403) {
          return 'Bạn không có quyền thực hiện hành động này.';
        }
        
        if (statusCode == 404) {
          return 'Không tìm thấy dữ liệu yêu cầu.';
        }
        
        if (statusCode == 422 && data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values.expand((e) => e as List).join(', ');
          return errorMessages;
        }
        
        if (data is Map && data['message'] != null) {
          return data['message'];
        }
        
        return 'Lỗi server (${statusCode}). Vui lòng thử lại sau.';
      
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      
      default:
        return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
    }
  }
}

// Singleton instance để sử dụng trong toàn bộ app
final apiClient = ApiClient();
