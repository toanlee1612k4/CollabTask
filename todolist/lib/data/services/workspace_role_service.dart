import 'package:dio/dio.dart';

/// Service to get user role in workspace
class WorkspaceRoleService {
  final Dio _dio;
  
  // Cache roles to avoid repeated API calls
  final Map<String, String> _roleCache = {};

  WorkspaceRoleService(this._dio);

  /// Get user role in workspace
  /// Returns: "Owner", "ProjectManager", or "Member"
  Future<String> getUserRole(String workspaceId, String userId) async {
    final cacheKey = '$workspaceId-$userId';
    
    // Check cache first
    if (_roleCache.containsKey(cacheKey)) {
      return _roleCache[cacheKey]!;
    }

    try {
      final response = await _dio.get(
        '/api/workspaces/$workspaceId/members/$userId/role',
      );

      final role = response.data['role'] as String;
      
      // Cache the result
      _roleCache[cacheKey] = role;
      
      return role;
    } catch (e) {
      // Default to Member if API fails
      print('Error getting user role: $e');
      return 'Member';
    }
  }

  /// Clear role cache (call when user leaves workspace)
  void clearCache([String? workspaceId, String? userId]) {
    if (workspaceId != null && userId != null) {
      _roleCache.remove('$workspaceId-$userId');
    } else {
      _roleCache.clear();
    }
  }

  /// Check if user is owner
  Future<bool> isOwner(String workspaceId, String userId) async {
    final role = await getUserRole(workspaceId, userId);
    return role == 'Owner';
  }

  /// Check if user is project manager
  Future<bool> isProjectManager(String workspaceId, String userId) async {
    final role = await getUserRole(workspaceId, userId);
    return role == 'ProjectManager';
  }

  /// Check if user can approve tasks
  Future<bool> canApprove(String workspaceId, String userId) async {
    final role = await getUserRole(workspaceId, userId);
    return role == 'Owner' || role == 'ProjectManager';
  }
}
