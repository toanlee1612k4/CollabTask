import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';
import 'package:todolist/presentation/widgets/tasks/create_task_dialog.dart';
import 'package:todolist/presentation/widgets/workspace/workspace_members_dialog.dart';
import 'package:todolist/main.dart' show AuthProvider;

/// Kanban Board Workspace Screen
class KanbanWorkspaceScreen extends StatefulWidget {
  final String workspaceId;
  final String workspaceName;

  const KanbanWorkspaceScreen({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  State<KanbanWorkspaceScreen> createState() => _KanbanWorkspaceScreenState();
}

class _KanbanWorkspaceScreenState extends State<KanbanWorkspaceScreen> {
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = true;
  String? _error;
  String? _userRole; // Cache user role
  
  List<TaskModel> _todoTasks = [];
  List<TaskModel> _inProgressTasks = [];
  List<TaskModel> _reviewTasks = [];
  List<TaskModel> _doneTasks = [];
  List<UserModel> _members = [];

  @override
  void initState() {
    super.initState();
    // Validate workspaceId on init
    if (widget.workspaceId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _error = 'Invalid workspace ID';
          _isLoading = false;
        });
      });
      return;
    }
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    // Double-check workspaceId before API call
    if (widget.workspaceId.isEmpty) {
      setState(() {
        _error = 'Invalid workspace ID';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        print('\n🚀 ========== LOADING WORKSPACE ==========');
        print('🚀 Workspace ID: ${widget.workspaceId}');
      }
      
      // Get current user from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.userId;
      
      if (kDebugMode) {
        print('🚀 Current User ID: ${currentUserId ?? "null"}');
        print('🚀 Starting API calls...');
      }
      
      // Load tasks and members
      final futures = <Future>[
        _apiClient.getTasksByWorkspace(widget.workspaceId),
        _apiClient.getWorkspaceMembers(widget.workspaceId),
      ];
      
      // Only load user role if we have userId (avoid double slash bug)
      if (currentUserId != null && currentUserId.isNotEmpty) {
        futures.add(_apiClient.workspaceRole.getUserRole(widget.workspaceId, currentUserId));
      }
      
      final results = await Future.wait(futures);

      final tasks = results[0] as List<TaskModel>;
      final members = results[1] as List<UserModel>;
      final userRole = results.length > 2 ? (results[2] as String) : 'Member';

      if (kDebugMode) {
        print('\n📋 ========== KANBAN LOADING ==========');
        print('📋 Total tasks loaded: ${tasks.length}');
        print('📋 All task statuses: ${tasks.map((t) => t.status).toSet().toList()}');
        print('📋 Sample tasks (first 3):');
        for (var i = 0; i < tasks.take(3).length; i++) {
          final t = tasks[i];
          print('   [$i] "${t.title}"');
          print('       status="${t.status}" (lowercase: "${t.status.toLowerCase()}")');
          print('       priority=${t.priority}, deadline=${t.deadline}');
        }
      }

      if (mounted) {
        setState(() {
          // Case-insensitive status matching to handle backend variations
          _todoTasks = tasks.where((t) => t.status.toLowerCase() == 'todo').toList();
          _inProgressTasks = tasks.where((t) => 
            t.status.toLowerCase() == 'inprogress' || 
            t.status.toLowerCase() == 'in progress'
          ).toList();
          _reviewTasks = tasks.where((t) => t.status.toLowerCase() == 'review').toList();
          _doneTasks = tasks.where((t) => 
            t.status.toLowerCase() == 'done' || 
            t.status.toLowerCase() == 'completed'
          ).toList();
          _members = members;
          
          if (kDebugMode) {
            print('\n📊 ========== KANBAN FILTER RESULTS ==========');
            print('📊 ToDo: ${_todoTasks.length} tasks');
            if (_todoTasks.isNotEmpty) {
              print('   Sample: ${_todoTasks.take(2).map((t) => t.title).toList()}');
            }
            print('📊 InProgress: ${_inProgressTasks.length} tasks');
            if (_inProgressTasks.isNotEmpty) {
              print('   Sample: ${_inProgressTasks.take(2).map((t) => t.title).toList()}');
            }
            print('📊 Review: ${_reviewTasks.length} tasks');
            print('📊 Done: ${_doneTasks.length} tasks');
            
            final totalFiltered = _todoTasks.length + _inProgressTasks.length + _reviewTasks.length + _doneTasks.length;
            if (totalFiltered != tasks.length) {
              print('⚠️ WARNING: ${tasks.length - totalFiltered} tasks NOT matched to any column!');
              final unmatched = tasks.where((t) => 
                t.status.toLowerCase() != 'todo' &&
                t.status.toLowerCase() != 'inprogress' &&
                t.status.toLowerCase() != 'in progress' &&
                t.status.toLowerCase() != 'review' &&
                t.status.toLowerCase() != 'done' &&
                t.status.toLowerCase() != 'completed'
              ).toList();
              print('⚠️ Unmatched statuses: ${unmatched.map((t) => t.status).toSet().toList()}');
            }
            print('========================================\n');
          }
          _userRole = userRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('\n❌ ========== KANBAN ERROR ==========');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Error message: $e');
        if (e is Exception) {
          print('❌ Stack trace: ${StackTrace.current}');
        }
        print('========================================\n');
      }
      
      if (mounted) {
        setState(() {
          // Parse error for user-friendly message
          String errorMsg = e.toString();
          if (errorMsg.contains('400')) {
            _error = 'Invalid request. Please check workspace ID or try again later.';
          } else if (errorMsg.contains('401') || errorMsg.contains('403')) {
            _error = 'You do not have permission to access this workspace.';
          } else if (errorMsg.contains('404')) {
            _error = 'Workspace not found.';
          } else if (errorMsg.contains('500')) {
            _error = 'Server error. Please try again later.';
          } else if (errorMsg.contains('network') || errorMsg.contains('connect')) {
            _error = 'Network error. Please check your connection.';
          } else {
            _error = 'An error occurred. Please try again.';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 80, color: AppColors.error),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Oops!',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.headlineMedium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodyMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: _loadWorkspaceData,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(child: _buildKanbanBoard()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workspaceName,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.headlineSmall,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Kanban Board',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddMemberDialog(),
                  icon: const Icon(Icons.person_add_rounded),
                  tooltip: 'Add Member',
                ),
                IconButton(
                  onPressed: _loadWorkspaceData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMembersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _members.length + 1,
              itemBuilder: (context, index) {
                if (index == _members.length) {
                  return _buildAddMemberButton();
                }
                final member = _members[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: member.fullName,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (member.fullName ?? 'U').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _showMembersManagement(),
          icon: const Icon(Icons.group_rounded, size: 18),
          label: const Text('Xem tất cả'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMemberButton() {
    return InkWell(
      onTap: () => _showAddMemberDialog(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;
        
        if (isMobile) {
          return _buildMobileKanban();
        } else {
          return _buildDesktopKanban();
        }
      },
    );
  }

  Widget _buildMobileKanban() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildKanbanColumn('TO DO', _todoTasks, AppColors.todoColor, Icons.inbox_rounded),
        const SizedBox(height: AppSpacing.md),
        _buildKanbanColumn('IN PROGRESS', _inProgressTasks, AppColors.inProgressColor, Icons.play_circle_rounded),
        const SizedBox(height: AppSpacing.md),
        _buildKanbanColumn('REVIEW', _reviewTasks, AppColors.codeReviewColor, Icons.rate_review_rounded),
        const SizedBox(height: AppSpacing.md),
        _buildKanbanColumn('DONE', _doneTasks, AppColors.doneColor, Icons.check_circle_rounded),
      ],
    );
  }

  Widget _buildDesktopKanban() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildKanbanColumn('TO DO', _todoTasks, AppColors.todoColor, Icons.inbox_rounded)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildKanbanColumn('IN PROGRESS', _inProgressTasks, AppColors.inProgressColor, Icons.play_circle_rounded)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildKanbanColumn('REVIEW', _reviewTasks, AppColors.codeReviewColor, Icons.rate_review_rounded)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildKanbanColumn('DONE', _doneTasks, AppColors.doneColor, Icons.check_circle_rounded)),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<TaskModel> tasks, Color color, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minHeight: 500),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.titleSmall,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildKanbanCard(tasks[index], color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(TaskModel task, Color columnColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: columnColor.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to enhanced task detail with real user data
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.currentUser?.userId ?? '';
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedTaskDetailScreen(
                taskId: task.taskId,
                currentUserId: currentUserId,
                userRole: _userRole ?? 'Member', // Use cached role
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: GoogleFonts.inter(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.description!,
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildPriorityTag(task.priority),
                  const Spacer(),
                  if (task.deadline != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: task.isOverdue ? AppColors.error : AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.deadline!.day}/${task.deadline!.month}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: task.isOverdue ? AppColors.error : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (task.assigneeUserIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildAssignee(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityTag(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'urgent':
        color = AppColors.priorityUrgent;
        break;
      case 'high':
        color = AppColors.priorityHigh;
        break;
      case 'medium':
        color = AppColors.priorityMedium;
        break;
      default:
        color = AppColors.priorityLow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAssignee() {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            'A',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        workspaceId: widget.workspaceId,
        onTaskCreated: _loadWorkspaceData,
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        workspaceId: widget.workspaceId,
        onMemberAdded: () {
          _loadWorkspaceData();
        },
      ),
    );
  }

  Future<void> _showMembersManagement() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.userId ?? '';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkspaceMembersDialog(
          workspaceId: widget.workspaceId,
          currentUserId: currentUserId,
          currentUserRole: _userRole ?? 'Member',
        ),
      ),
    );

    // If user left workspace, navigate back
    if (result == true && mounted) {
      Navigator.pop(context);
    } else {
      _loadWorkspaceData(); // Refresh members list
    }
  }
}

/// Add Member Dialog
class AddMemberDialog extends StatefulWidget {
  final String workspaceId;
  final VoidCallback onMemberAdded;

  const AddMemberDialog({
    super.key,
    required this.workspaceId,
    required this.onMemberAdded,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final ApiClient _apiClient = ApiClient();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() => _error = 'Please enter an email');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _error = 'Invalid email format');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Send invitation using new backend endpoint
      await _apiClient.sendWorkspaceInvitation(
        widget.workspaceId, 
        email,
        message: 'Mời bạn tham gia làm việc cùng team!',
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi lời mời tới $email!\nUser sẽ nhận được thông báo và có thể chấp nhận lời mời.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Parse error message for user-friendly display
          String errorMsg = e.toString();
          if (errorMsg.contains('does not exist') || errorMsg.contains('not found')) {
            errorMsg = '❌ Email này chưa đăng ký tài khoản.\nVui lòng yêu cầu user đăng ký trước khi gửi lời mời.';
          } else if (errorMsg.contains('already a member')) {
            errorMsg = '⚠️ User đã là thành viên của workspace này rồi.';
          } else if (errorMsg.contains('already has a pending invitation')) {
            errorMsg = '⚠️ Đã có lời mời đang chờ duyệt cho email này.';
          } else if (errorMsg.contains('Only Owner or ProjectManager') || errorMsg.contains('permission')) {
            errorMsg = '🚫 Chỉ Owner hoặc Project Manager mới có quyền gửi lời mời.';
          }
          _error = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gửi Lời Mời',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.titleLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'User sẽ nhận được thông báo và cần chấp nhận lời mời',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chỉ gửi lời mời cho user đã đăng ký. User cần chấp nhận lời mời để tham gia workspace.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email của thành viên',
                hintText: 'member@example.com',
                prefixIcon: const Icon(Icons.email_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                errorText: _error,
                helperText: 'Email phải đã đăng ký trong hệ thống',
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'An invitation email will be sent with a link to join this workspace',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.bodySmall,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send Invitation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
