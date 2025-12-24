import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/main.dart';

// ==================== CREATE TASK STATE ====================

class CreateTaskState {
  final String? workspaceId;
  final List<UserModel> workspaceMembers;
  final bool isLoadingMembers;
  final bool isSubmitting;
  final String? error;
  final TaskModel? createdTask; // Task vừa tạo thành công

  const CreateTaskState({
    this.workspaceId,
    this.workspaceMembers = const [],
    this.isLoadingMembers = false,
    this.isSubmitting = false,
    this.error,
    this.createdTask,
  });

  CreateTaskState copyWith({
    String? workspaceId,
    List<UserModel>? workspaceMembers,
    bool? isLoadingMembers,
    bool? isSubmitting,
    String? error,
    TaskModel? createdTask,
  }) {
    return CreateTaskState(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceMembers: workspaceMembers ?? this.workspaceMembers,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      createdTask: createdTask ?? this.createdTask,
    );
  }
}

// ==================== CREATE TASK NOTIFIER ====================

class CreateTaskNotifier extends StateNotifier<CreateTaskState> {
  final ApiClient _apiClient;

  CreateTaskNotifier(this._apiClient) : super(const CreateTaskState());

  /// Load workspace members for assignee dropdown
  Future<void> loadWorkspaceMembers(String workspaceId) async {
    state = state.copyWith(
      workspaceId: workspaceId,
      isLoadingMembers: true,
      error: null,
    );

    try {
      final members = await _apiClient.getWorkspaceMembers(workspaceId);
      state = state.copyWith(
        workspaceMembers: members,
        isLoadingMembers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMembers: false,
        error: 'Không thể tải danh sách thành viên: $e',
      );
    }
  }

  /// Create new task
  Future<bool> createTask({
    required String workspaceId,
    required String title,
    String? description,
    required String priority, // "Urgent", "High", "Medium", "Low"
    DateTime? deadline,
    int? estimatedTimeMinutes,
    required List<String> assigneeUserIds, // Danh sách userId được gán
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      state = state.copyWith(error: 'Tiêu đề không được để trống');
      return false;
    }

    if (deadline != null && deadline.isBefore(DateTime.now())) {
      state = state.copyWith(error: 'Deadline phải lớn hơn thời gian hiện tại');
      return false;
    }

    if (assigneeUserIds.isEmpty) {
      state = state.copyWith(error: 'Phải chọn ít nhất một người thực hiện');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      // Prepare task data - QUAN TRỌNG: Convert deadline sang UTC
      final taskData = {
        'title': title.trim(),
        'description': description?.trim(),
        'priority': priority,
        'status': 'ToDo', // Mặc định status mới tạo là ToDo
        'deadline': deadline?.toUtc().toIso8601String(), // ✅ Convert sang UTC
        'estimatedTimeMinutes': estimatedTimeMinutes,
        'assigneeUserIds': assigneeUserIds,
      };

      final createdTask = await _apiClient.createTask(workspaceId, taskData);

      state = state.copyWith(
        isSubmitting: false,
        createdTask: createdTask,
      );

      return true; // Thành công
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Tạo task thất bại: $e',
      );
      return false; // Thất bại
    }
  }

  /// Reset state (khi đóng screen hoặc tạo task mới)
  void reset() {
    state = const CreateTaskState();
  }
}

// ==================== PROVIDER ====================

final createTaskProvider = StateNotifierProvider<CreateTaskNotifier, CreateTaskState>((ref) {
  return CreateTaskNotifier(apiClient);
});
