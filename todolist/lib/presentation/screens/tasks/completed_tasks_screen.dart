import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/providers/auth_provider.dart';
import 'package:todolist/presentation/widgets/common/task_card.dart';
import 'package:todolist/main.dart';

// ==================== COMPLETED TASKS STATE ====================

class CompletedTasksState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  const CompletedTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  CompletedTasksState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return CompletedTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ==================== COMPLETED TASKS NOTIFIER ====================

class CompletedTasksNotifier extends StateNotifier<CompletedTasksState> {
  final ApiClient _apiClient;

  CompletedTasksNotifier(this._apiClient) : super(const CompletedTasksState()) {
    loadCompletedTasks();
  }

  Future<void> loadCompletedTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ✅ Gọi API /api/tasks với filter status=Done để lấy completed tasks
      final result = await _apiClient.getMyTasks(
        page: 1,
        pageSize: 1000, // Lấy nhiều để hiển thị hết
        status: 'Done', // Filter completed tasks
      );
      
      final completed = result.items;
      
      // Sort by completedAt or updatedAt descending (mới nhất trước)
      completed.sort((a, b) {
        final aDate = a.completedAt ?? a.updatedAt;
        final bDate = b.completedAt ?? b.updatedAt;
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      state = CompletedTasksState(
        tasks: completed,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadCompletedTasks();
  }
}

// ==================== PROVIDER ====================

final completedTasksProvider = StateNotifierProvider<CompletedTasksNotifier, CompletedTasksState>((ref) {
  return CompletedTasksNotifier(apiClient);
});

// ==================== SCREEN ====================

/// Completed Tasks Screen - Hiển thị tất cả task đã hoàn thành
/// Sử dụng Riverpod ConsumerWidget để quản lý state
class CompletedTasksScreen extends ConsumerWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedState = ref.watch(completedTasksProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task đã hoàn thành'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(completedTasksProvider.notifier).refresh(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(context, ref, completedState, authState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CompletedTasksState completedState,
    AuthState authState,
  ) {
    // Loading state
    if (completedState.isLoading && completedState.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (completedState.error != null && completedState.tasks.isEmpty) {
      return _buildErrorState(context, ref, completedState.error!);
    }

    // Empty state
    if (completedState.tasks.isEmpty) {
      return _buildEmptyState();
    }

    // Task list
    return RefreshIndicator(
      onRefresh: () => ref.read(completedTasksProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: completedState.tasks.length,
        itemBuilder: (context, index) {
          final task = completedState.tasks[index];
          return TaskCard(
            key: ValueKey(task.taskId),
            task: task,
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppConstants.iconXl * 2,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: () => ref.read(completedTasksProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppConstants.iconXl * 2,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: AppConstants.spacingM),
          const Text(
            'Chưa có task nào hoàn thành',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Hoàn thành task đầu tiên để xem ở đây! 🎉',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
