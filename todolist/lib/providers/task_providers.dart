import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'auth_provider.dart'; // Includes AuthState and AuthStatus

/// Provider cho ApiClient singleton
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// ==============================
/// PERSONAL TASKS PROVIDER
/// ==============================
/// Lấy tất cả task của user hiện tại (cho Calendar, Dashboard)

final personalTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final authState = ref.watch(authProvider);
  
  // Chưa đăng nhập thì return empty
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }
  
  final apiClient = ref.read(apiClientProvider);
  
  // Lấy task trong khoảng ±3 tháng cho calendar
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 3, 1);
  final endDate = DateTime(now.year, now.month + 3, 0, 23, 59, 59);
  
  return apiClient.getCalendarTasks(
    startDate: startDate,
    endDate: endDate,
  );
});

/// Provider cho task theo tháng cụ thể
final monthlyTasksProvider = FutureProvider.autoDispose.family<List<TaskModel>, DateTime>((ref, month) async {
  final authState = ref.watch(authProvider);
  
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }
  
  final apiClient = ref.read(apiClientProvider);
  
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  
  return apiClient.getCalendarTasks(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

/// ==============================
/// WORKSPACE TASKS PROVIDER
/// ==============================

final workspaceTasksProvider = FutureProvider.autoDispose.family<List<TaskModel>, String>((ref, workspaceId) async {
  final authState = ref.watch(authProvider);
  
  if (authState.status != AuthStatus.authenticated || workspaceId.isEmpty) {
    return [];
  }
  
  final apiClient = ref.read(apiClientProvider);
  return apiClient.getTasksByWorkspace(workspaceId);
});

/// ==============================
/// TASK DETAIL PROVIDER
/// ==============================

final taskDetailProvider = FutureProvider.autoDispose.family<TaskModel?, String>((ref, taskId) async {
  if (taskId.isEmpty) return null;
  
  final apiClient = ref.read(apiClientProvider);
  return apiClient.getTaskById(taskId);
});

/// ==============================
/// TASK STATISTICS PROVIDER
/// ==============================

class TaskStatistics {
  final int total;
  final int completed;
  final int inProgress;
  final int overdue;
  final int dueToday;
  final int dueThisWeek;
  
  TaskStatistics({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.overdue,
    required this.dueToday,
    required this.dueThisWeek,
  });
  
  double get completionRate => total > 0 ? completed / total : 0;
}

final taskStatisticsProvider = Provider.autoDispose<AsyncValue<TaskStatistics>>((ref) {
  final tasksAsync = ref.watch(personalTasksProvider);
  
  return tasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekEnd = todayStart.add(const Duration(days: 7));
    
    int completed = 0;
    int inProgress = 0;
    int overdue = 0;
    int dueToday = 0;
    int dueThisWeek = 0;
    
    for (final task in tasks) {
      final status = task.status.toLowerCase();
      
      if (status == 'completed' || status == 'done') {
        completed++;
      } else if (status == 'inprogress') {
        inProgress++;
      }
      
      if (task.isOverdue) {
        overdue++;
      }
      
      if (task.deadline != null) {
        final deadline = task.deadline!;
        if (deadline.year == now.year && 
            deadline.month == now.month && 
            deadline.day == now.day) {
          dueToday++;
        }
        if (deadline.isAfter(todayStart) && deadline.isBefore(weekEnd)) {
          dueThisWeek++;
        }
      }
    }
    
    return TaskStatistics(
      total: tasks.length,
      completed: completed,
      inProgress: inProgress,
      overdue: overdue,
      dueToday: dueToday,
      dueThisWeek: dueThisWeek,
    );
  });
});
