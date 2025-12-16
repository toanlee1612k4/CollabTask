import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/widgets/common/ai_stats_chart.dart';
import 'package:todolist/presentation/widgets/ai/ai_widgets.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/core/utils/task_navigation_helper.dart';
import 'package:todolist/presentation/screens/notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  
  UserModel? _currentUser;
  UserWeights? _userWeights;
  List<TaskModel> _suggestedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load data in parallel
      final futures = await Future.wait([
        apiClient.getCurrentUser(),
        apiClient.getUserWeights(),
        apiClient.getSuggestedTasks(), // AI suggested tasks only
        apiClient.getUserStats(), // Get productivity stats including onTimeCompletionRate
      ]);

      final user = futures[0] as UserModel;
      final weights = futures[1] as UserWeights?;
      var suggestedTasks = futures[2] as List<TaskModel>;
      final stats = futures[3] as Map<String, dynamic>;
      
      if (kDebugMode) {
        print('\n📊 ========== DASHBOARD AI FILTER ==========');
        print('📊 Suggested tasks received: ${suggestedTasks.length}');
        print('📊 User stats:');
        print('   totalCompleted: ${stats['totalTasksCompleted']}');
        print('   onTimeRate: ${stats['onTimeCompletionRate']}%');
        print('   currentStreak: ${stats['currentStreak']}');
      }
      
      // Filter logic: Remove overdue tasks for high-performing users
      // If user has good on-time completion rate (>70%), don't show overdue tasks
      final onTimeRate = (stats['onTimeCompletionRate'] ?? 0.0) / 100.0;
      
      if (kDebugMode) {
        print('📊 Checking overdue tasks:');
        final overdueTasks = suggestedTasks.where((t) => t.isOverdue).toList();
        print('   Overdue count: ${overdueTasks.length}');
        if (overdueTasks.isNotEmpty) {
          print('   Sample overdue: ${overdueTasks.take(2).map((t) => "${t.title} (deadline: ${t.deadline})").toList()}');
        }
      }
      
      if (onTimeRate > 0.7) {
        final beforeFilter = suggestedTasks.length;
        suggestedTasks = suggestedTasks.where((task) => !task.isOverdue).toList();
        if (kDebugMode) {
          print('🎯 User is high-performer (${(onTimeRate * 100).toInt()}% on-time)');
          print('🎯 Filtered out ${beforeFilter - suggestedTasks.length} overdue tasks');
          print('📊 Final suggested tasks: ${suggestedTasks.length}');
          if (suggestedTasks.isNotEmpty) {
            print('📋 Sample tasks after filter:');
            for (var i = 0; i < suggestedTasks.take(3).length; i++) {
              final t = suggestedTasks[i];
              print('   [$i] "${t.title}"');
              print('       priority=${t.priority}, score=${t.priorityScore.toInt()}, deadline=${t.deadline}');
            }
          }
        }
      } else if (kDebugMode) {
        print('📊 User on-time rate ${(onTimeRate * 100).toInt()}% < 70%, showing all ${suggestedTasks.length} tasks');
      }
      
      if (kDebugMode) {
        print('========================================\n');
      }
      
      setState(() {
        _currentUser = user;
        _userWeights = weights;
        _suggestedTasks = suggestedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Dashboard load error: $e');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    try {
      await apiClient.completeTask(task.taskId);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Task "${task.title}" đã hoàn thành! 🎉',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      // Reload data to reflect changes
      _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetAIWeights() async {
    try {
      final newWeights = await apiClient.resetUserWeights();
      setState(() {
        _userWeights = newWeights;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Weights đã được reset thành công!'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              SliverFillRemaining(
                child: _buildLoadingState(),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _buildErrorState(),
              )
            else ...[
              SliverToBoxAdapter(child: _buildAIStatsSection()),
              SliverToBoxAdapter(child: _buildTasksHeader()),
              _buildTasksList(),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo Task'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo Task Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    hintText: 'Nhập tiêu đề task',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Nhập mô tả task',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                  items: ['Low', 'Medium', 'High'].map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPriority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline'),
                  subtitle: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Chưa chọn',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDeadline = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
                  );
                  return;
                }

                try {
                  // Get workspaces first
                  final workspaces = await apiClient.getWorkspaces();
                  
                  if (workspaces.isEmpty) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng tạo workspace trước!')),
                      );
                    }
                    return;
                  }
                  
                  // Use first workspace (or let user select if needed)
                  final workspaceId = workspaces.first.workspaceId;
                  
                  await apiClient.createTask(workspaceId, {
                    'title': titleController.text,
                    'description': descController.text.isEmpty ? null : descController.text,
                    'priority': selectedPriority,
                    'status': 'ToDo', // CRITICAL: Backend requires status field
                    'deadline': selectedDeadline?.toIso8601String(),
                    'estimatedTimeMinutes': 60, // Default 1 hour
                  });

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    _loadDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo task thành công!')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.indigo.shade600,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade600,
                Colors.blue.shade500,
                Colors.cyan.shade400,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          _currentUser?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              _currentUser?.fullName ?? 'User',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIStatsSection() {
    if (_userWeights == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: AIStatsChart(
        weights: _userWeights!,
        onTap: () {
          _showAIStatsDialog();
        },
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildTasksHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Colors.indigo.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'AI Suggested Tasks',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_suggestedTasks.length} tasks',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (_suggestedTasks.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(
          'Không có task được gợi ý',
          'AI sẽ gợi ý task dựa trên độ ưu tiên, deadline và thói quen của bạn',
          Icons.psychology,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final task = _suggestedTasks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SmartTaskCard(
              task: task,
              onTap: () {
                if (_currentUser != null) {
                  TaskNavigationHelper.navigateToTaskDetail(
                    context: context,
                    task: task,
                    currentUserRole: 'Member',
                    currentUserId: _currentUser!.userId,
                  ).then((_) => _loadDashboardData());
                }
              },
              onComplete: () => _completeTask(task),
            ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1, end: 0),
          );
        },
        childCount: _suggestedTasks.length,
      ),
    );
  }



  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Lỗi không xác định',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIStatsDialog() {
    if (_userWeights == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: AiStatsChart(
            userWeights: _userWeights!,
            onResetWeights: () {
              Navigator.of(context).pop();
              _resetAIWeights();
            },
          ),
        ),
      ),
    );
  }
}
