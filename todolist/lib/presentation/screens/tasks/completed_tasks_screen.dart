import 'package:flutter/material.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/widgets/common/task_card.dart';

/// Completed Tasks Screen - Hiển thị tất cả task đã hoàn thành
class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<TaskModel> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lấy tất cả task rồi filter completed
      final allTasks = await _apiClient.getSuggestedTasks();
      final completed = allTasks.where((t) => t.status == 'Completed').toList();
      
      // Sort by title alphabetically
      completed.sort((a, b) => a.title.compareTo(b.title));
      
      if (mounted) {
        setState(() {
          _completedTasks = completed;
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
        title: const Text('Task đã hoàn thành'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompletedTasks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _completedTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(),
    );
  }

  Widget _buildTaskList() {
    return RefreshIndicator(
      onRefresh: _loadCompletedTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: _completedTasks.length,
        itemBuilder: (context, index) {
          final task = _completedTasks[index];
          return TaskCard(
            key: ValueKey(task.taskId),
            task: task,
          );
        },
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
              onPressed: _loadCompletedTasks,
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
