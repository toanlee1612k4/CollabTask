import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/widgets/workspace/task_calendar_view.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';
import 'package:todolist/main.dart' show AuthProvider;

/// Personal Calendar Screen - Hiển thị lịch task cá nhân của user
class PersonalCalendarScreen extends StatefulWidget {
  const PersonalCalendarScreen({super.key});

  @override
  State<PersonalCalendarScreen> createState() => _PersonalCalendarScreenState();
}

class _PersonalCalendarScreenState extends State<PersonalCalendarScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<TaskModel> _myTasks = [];

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ FIX: Use getCalendarTasks API instead of getMyTasks
      // Get tasks for current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      final myTasks = await _apiClient.getCalendarTasks(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      if (mounted) {
        setState(() {
          _myTasks = myTasks;
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

  void _showTaskDetails(TaskModel task) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.userId ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedTaskDetailScreen(
          taskId: task.taskId,
          currentUserId: currentUserId,
          userRole: 'Member', // User role from calendar context
        ),
      ),
    ).then((_) => _loadMyTasks()); // Reload tasks after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyTasks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TaskCalendarView(
                  tasks: _myTasks, // Hiển thị calendar ngay cả khi empty
                  onTaskTap: _showTaskDetails,
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
              onPressed: _loadMyTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
