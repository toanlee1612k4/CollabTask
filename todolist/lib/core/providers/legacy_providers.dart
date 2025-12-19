// Temporary legacy providers for backward compatibility
// These will be migrated to Riverpod gradually

import 'package:flutter/material.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

// Legacy AuthProvider for screens that haven't been migrated yet
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;

  void setUser(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await apiClient.getCurrentUser();
      setUser(user);
    } catch (e) {
      // Handle error
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

// Legacy TaskProvider for screens that haven't been migrated yet
class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement getTasks() in ApiClient
      _tasks = [];
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Legacy WorkspaceProvider for screens that haven't been migrated yet
class WorkspaceProvider extends ChangeNotifier {
  List<WorkspaceModel> _workspaces = [];
  bool _isLoading = false;

  List<WorkspaceModel> get workspaces => _workspaces;
  bool get isLoading => _isLoading;

  Future<void> loadWorkspaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      final workspacesList = await apiClient.getWorkspaces();
      
      // Load member count for each workspace
      final workspacesWithCounts = await Future.wait(
        workspacesList.map((workspace) async {
          try {
            final members = await apiClient.getWorkspaceMembers(workspace.workspaceId);
            return WorkspaceModel(
              workspaceId: workspace.workspaceId,
              name: workspace.name,
              description: workspace.description,
              ownerId: workspace.ownerId,
              members: members,
              memberCount: members.length,
              createdAt: workspace.createdAt,
            );
          } catch (e) {
            // If failed to load members, return original workspace
            return workspace;
          }
        }),
      );
      
      _workspaces = workspacesWithCounts;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
