import 'package:dio/dio.dart';
import 'package:todolist/data/models/task_assignment_models.dart';

/// Task Assignment API Service
/// Handles all task assignment workflow endpoints
class TaskAssignmentService {
  final Dio _dio;

  TaskAssignmentService(this._dio);

  // ==================== TASK ASSIGNMENT ENDPOINTS ====================

  /// Assign task to users (PM/Owner only)
  /// POST /api/tasks/{taskId}/assign
  Future<List<TaskAssignment>> assignTask({
    required String taskId,
    required List<String> assigneeUserIds,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '/api/tasks/$taskId/assign',
        data: {
          'assigneeUserIds': assigneeUserIds,
          if (note != null) 'note': note,
        },
      );

      final assignments = (response.data['assignments'] as List)
          .map((e) => TaskAssignment.fromJson(e))
          .toList();

      return assignments;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Respond to task assignment (Accept/Reject)
  /// POST /api/tasks/{taskId}/respond
  Future<void> respondToAssignment({
    required String taskId,
    required bool accept,
    String? note,
  }) async {
    try {
      await _dio.post(
        '/api/tasks/$taskId/respond',
        data: {
          'accept': accept,
          if (note != null) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request task completion
  /// POST /api/tasks/{taskId}/request-completion
  Future<void> requestCompletion({
    required String taskId,
    String? note,
  }) async {
    try {
      await _dio.post(
        '/api/tasks/$taskId/request-completion',
        data: {
          if (note != null) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve or reject task completion (PM/Owner only)
  /// POST /api/tasks/{taskId}/approve-completion
  Future<void> approveCompletion({
    required String taskId,
    required bool approve,
    String? note,
  }) async {
    try {
      await _dio.post(
        '/api/tasks/$taskId/approve-completion',
        data: {
          'approve': approve,
          if (note != null) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get task assignments
  /// GET /api/tasks/{taskId}/assignments
  Future<List<TaskAssignment>> getTaskAssignments(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId/assignments');
      
      return (response.data as List)
          .map((e) => TaskAssignment.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get task assignment history
  /// GET /api/tasks/{taskId}/assignment-history
  Future<List<TaskAssignmentHistory>> getAssignmentHistory(String taskId) async {
    try {
      final response = await _dio.get('/api/tasks/$taskId/assignment-history');
      
      return (response.data as List)
          .map((e) => TaskAssignmentHistory.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove assignment (PM/Owner only)
  /// DELETE /api/tasks/{taskId}/assignments/{assigneeUserId}
  Future<void> removeAssignment({
    required String taskId,
    required String assigneeUserId,
  }) async {
    try {
      await _dio.delete('/api/tasks/$taskId/assignments/$assigneeUserId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PRODUCTIVITY DASHBOARD ENDPOINTS ====================

  /// Get personal productivity dashboard
  /// GET /api/productivity/dashboard?startDate=...&endDate=...
  Future<ProductivityDashboard> getPersonalDashboard({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/productivity/dashboard',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      return ProductivityDashboard.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get workspace productivity (PM/Owner only)
  /// GET /api/productivity/workspace/{workspaceId}?startDate=...&endDate=...
  Future<Map<String, dynamic>> getWorkspaceProductivity({
    required String workspaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/productivity/workspace/$workspaceId',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user task history
  /// GET /api/productivity/user/{targetUserId}/history?page=...&pageSize=...
  Future<Map<String, dynamic>> getUserTaskHistory({
    required String targetUserId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/productivity/user/$targetUserId/history',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get workspace leaderboard
  /// GET /api/productivity/leaderboard/{workspaceId}?startDate=...&endDate=...
  Future<List<LeaderboardEntry>> getWorkspaceLeaderboard({
    required String workspaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/productivity/leaderboard/$workspaceId',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      return (response.data['leaderboard'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is String) {
        return data;
      }
      return 'Lỗi: ${error.response!.statusCode}';
    }
    return error.message ?? 'Lỗi kết nối';
  }
}
