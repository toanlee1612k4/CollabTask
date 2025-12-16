import 'package:flutter/material.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';

class TaskNavigationHelper {
  static Future<void> navigateToTaskDetail({
    required BuildContext context,
    required TaskModel task,
    required String currentUserRole,
    required String currentUserId,
    int? initialTab, // Optional: which tab to open (0=Info, 1=Comments, 2=Tags)
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedTaskDetailScreen(
          taskId: task.taskId,
          currentUserId: currentUserId,
          userRole: currentUserRole,
          initialTab: initialTab,
        ),
      ),
    );
  }
}
