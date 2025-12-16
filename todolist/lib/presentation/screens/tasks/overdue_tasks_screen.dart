import 'package:flutter/material.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/widgets/common/task_card.dart';

/// Overdue Tasks Screen - Hiển thị tất cả task quá hạn
class OverdueTasksScreen extends StatefulWidget {
  const OverdueTasksScreen({super.key});

  @override
  State<OverdueTasksScreen> createState() => _OverdueTasksScreenState();
}

class _OverdueTasksScreenState extends State<OverdueTasksScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<TaskModel> _overdueTasks = [];

  @override
  void initState() {
    super.initState();
    _loadOverdueTasks();
  }

  Future<void> _loadOverdueTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lấy tất cả task rồi filter overdue
      final allTasks = await _apiClient.getSuggestedTasks();
      final now = DateTime.now();
      final overdue = allTasks.where((t) {
        if (t.deadline == null) return false;
        if (t.status == 'Completed') return false;
        return t.deadline!.isBefore(now);
      }).toList();
      
      // Sort by deadline (quá hạn lâu nhất trước)
      overdue.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
      
      if (mounted) {
        setState(() {
          _overdueTasks = overdue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task quá hạn'),
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverdueTasks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _overdueTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(),
    );
  }

  Widget _buildTaskList() {
    return RefreshIndicator(
      onRefresh: _loadOverdueTasks,
      child: Column(
        children: [
          // Warning banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            color: AppTheme.errorColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.errorColor,
                  size: AppConstants.iconM,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    '${_overdueTasks.length} task đang quá hạn',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: _overdueTasks.length,
              itemBuilder: (context, index) {
                final task = _overdueTasks[index];
                return TaskCard(
                  key: ValueKey(task.taskId),
                  task: task,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: _loadOverdueTasks,
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
            'Tuyệt vời! Không có task quá hạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Bạn đang theo kịp tiến độ! 🎉',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
