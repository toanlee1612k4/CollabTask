import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/widgets/tasks/task_attachments_section.dart';
import 'package:todolist/presentation/widgets/tasks/manage_assignees_dialog.dart';
import 'package:todolist/presentation/widgets/tasks/edit_task_dialog.dart';

/// Enhanced Task Detail Screen with Comments, Tags, File Attachments, State Transitions
class EnhancedTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String currentUserId;
  final String userRole; // Owner, ProjectManager, Member
  final int?
  initialTab; // 0=Info, 1=Comments, 2=Tags - for navigation from notifications

  const EnhancedTaskDetailScreen({
    super.key,
    required this.taskId,
    required this.currentUserId,
    required this.userRole,
    this.initialTab,
  });

  @override
  State<EnhancedTaskDetailScreen> createState() =>
      _EnhancedTaskDetailScreenState();
}

class _EnhancedTaskDetailScreenState extends State<EnhancedTaskDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  TaskModel? _task;
  String? _workspaceName; // NEW: Workspace name
  List<dynamic> _comments = []; // Will use CommentModel from API
  List<dynamic> _tags = []; // Will use TagModel from API
  bool _isLoading = true;
  String? _error;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab ?? 0, // Navigate to specific tab
    );
    _loadTaskData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load task details
      final task = await _apiClient.getTaskById(widget.taskId);

      // Load workspace name if task belongs to workspace
      String? workspaceName;
      if (task.workspaceId != null && task.workspaceId!.isNotEmpty) {
        try {
          final workspace = await _apiClient.getWorkspaceById(
            task.workspaceId!,
          );
          workspaceName = workspace.name;
        } catch (e) {
          print('⚠️ Could not load workspace name: $e');
        }
      }

      // Load comments (API available per API-STATUS-REPORT.md)
      List<dynamic> commentsData = [];
      try {
        final comments = await _apiClient.dio.get(
          '/api/tasks/${widget.taskId}/comments',
        );
        commentsData = comments.data as List;
        print('📝 Comments loaded: ${commentsData.length} comments');
        if (commentsData.isNotEmpty) {
          print('📝 First comment: ${commentsData[0]}');
        }
      } catch (e) {
        print('⚠️ Comments endpoint error: $e');
        // Continue with empty comments
      }

      // Load tags (Section 7 of API docs) - handle 404 if not implemented
      List<dynamic> tagsData = [];
      try {
        final tags = await _apiClient.dio.get(
          '/api/tasks/${widget.taskId}/tags',
        );
        tagsData = tags.data as List;
      } catch (e) {
        print('⚠️ Tags endpoint not available: $e');
        // Continue with empty tags
      }

      if (mounted) {
        setState(() {
          _task = task;
          _workspaceName = workspaceName;
          _comments = commentsData;
          _tags = tagsData;
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

  // Check permissions
  bool get _isOwner => widget.userRole == 'Owner';
  bool get _isProjectManager => widget.userRole == 'ProjectManager';
  bool get _canApprove => _isOwner || _isProjectManager;
  bool get _isAssignee =>
      _task?.assigneeUserIds.contains(widget.currentUserId) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết Task',
            style: GoogleFonts.inter(
              fontSize: AppTypography.titleLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_workspaceName != null && _workspaceName!.isNotEmpty)
            Text(
              'Workspace: $_workspaceName',
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _editTask();
                break;
              case 'delete':
                await _deleteTask();
                break;
              case 'assignees':
                await _manageAssignees();
                break;
            }
          },
          itemBuilder: (context) => [
            if (_canApprove) ...[
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Chỉnh sửa task'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'assignees',
                child: Row(
                  children: [
                    Icon(Icons.people_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Quản lý người thực hiện'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Xóa task', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ] else ...[
              const PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Chỉ Owner/PM có thể chỉnh sửa'),
                  ],
                ),
              ),
            ],
          ],
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTaskData),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.info_outline), text: 'Thông tin'),
          Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Bình luận'),
          Tab(icon: Icon(Icons.label_outline), text: 'Nhãn'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không thể tải thông tin task',
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadTaskData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildInfoTab(), _buildCommentsTab(), _buildTagsTab()],
    );
  }

  // TAB 1: THÔNG TIN TASK
  Widget _buildInfoTab() {
    if (_task == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Title Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _task!.title,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.headlineSmall,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildPriorityChip(_task!.priority),
                  ],
                ),
                if (_task!.description != null &&
                    _task!.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _task!.description!,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.bodyMedium,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Status & Deadline
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildStatusChip(_task!.status),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: _task!.isOverdue
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _task!.deadline != null
                                ? '${_task!.deadline!.day}/${_task!.deadline!.month}/${_task!.deadline!.year}'
                                : 'Không có',
                            style: GoogleFonts.inter(
                              fontSize: AppTypography.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: _task!.isOverdue
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Assignees - NEW: With management button
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Người thực hiện (${_task!.assigneeUserIds.length})',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    if (_canApprove)
                      TextButton.icon(
                        onPressed: _manageAssignees,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Quản lý'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
                if (_task!.assigneeUserIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _task!.assigneeUserIds.map((userId) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            'U',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        label: Text(userId.substring(0, 8)),
                      );
                    }).toList(),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Chưa có người thực hiện',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.bodySmall,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Status Management - Show for all, with role-based options
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuyển trạng thái',
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.titleSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _canApprove
                      ? 'Bạn có thể chuyển sang bất kỳ trạng thái nào'
                      : 'Bạn có thể chuyển sang Đang làm hoặc Review',
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_canApprove)
                      _buildStatusButton(
                        'ToDo',
                        'Chưa làm',
                        Icons.radio_button_unchecked,
                        AppColors.textHint,
                      ),
                    _buildStatusButton(
                      'InProgress',
                      'Đang làm',
                      Icons.pending,
                      AppColors.info,
                    ),
                    _buildStatusButton(
                      'Review',
                      'Review',
                      Icons.rate_review,
                      AppColors.warning,
                    ),
                    if (_canApprove)
                      _buildStatusButton(
                        'Done',
                        'Hoàn thành',
                        Icons.check_circle,
                        AppColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Complete Task Button - Show for assignees and owners/PM
        if ((_isAssignee || _canApprove) &&
            _task!.status.toLowerCase() != 'done')
          Card(
            color: AppColors.success.withOpacity(0.1),
            child: InkWell(
              onTap: _completeTask,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoàn thành task',
                            style: GoogleFonts.inter(
                              fontSize: AppTypography.titleMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Đánh dấu task đã hoàn thành và kích hoạt AI học tập',
                            style: GoogleFonts.inter(
                              fontSize: AppTypography.bodySmall,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // File Attachments (Placeholder)
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'File đính kèm',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // File Attachments Section
                TaskAttachmentsSection(
                  taskId: widget.taskId,
                  currentUserId: widget.currentUserId,
                  canDelete: _isOwner || _isProjectManager,
                  isAssignee: _isAssignee,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: BÌNH LUẬN
  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Chưa có bình luận nào',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodyMedium,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _buildCommentCard(comment);
                  },
                ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentCard(dynamic comment) {
    // TODO: Use proper CommentModel
    final commentId = comment['commentId'] ?? comment['id'];
    final userName = comment['userName'] ?? comment['userFullName'] ?? 'User';
    final commentText = comment['commentText'] ?? comment['content'] ?? '';
    final userId = comment['userId']?.toString() ?? '';
    final isMyComment = userId == widget.currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isMyComment)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteComment(commentId);
                      } else if (value == 'edit') {
                        _editComment(commentId, commentText);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              commentText,
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodyMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Nhập bình luận...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _addComment,
            icon: const Icon(Icons.send),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await _apiClient.dio.post(
        '/api/tasks/${widget.taskId}/comments',
        data: {'Content': text},
      );

      _commentController.clear();
      await _loadTaskData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm bình luận')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _editComment(dynamic commentId, String currentText) async {
    final controller = TextEditingController(text: currentText);

    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bình luận'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập nội dung mới...'),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newText != null && newText.trim().isNotEmpty) {
      try {
        await _apiClient.dio.put(
          '/api/comments/$commentId',
          data: {'Content': newText.trim()},
        );
        await _loadTaskData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật bình luận')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(dynamic commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiClient.dio.delete('/api/comments/$commentId');
        await _loadTaskData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa bình luận')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // TAB 3: NHÃN (TAGS)
  Widget _buildTagsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhãn hiện tại',
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.titleMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _tags.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có nhãn nào',
                          style: GoogleFonts.inter(color: AppColors.textHint),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          final tagName =
                              tag['tagName'] ?? tag['name'] ?? 'Tag';
                          final tagColor = tag['color'] ?? '#6C63FF';
                          final tagId = tag['tagId'] ?? tag['id'];

                          return Chip(
                            backgroundColor: _parseColor(tagColor),
                            label: Text(
                              tagName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white70,
                            ),
                            onDeleted: () => _removeTag(tagId),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: _showAddTagDialog,
          icon: const Icon(Icons.add),
          label: const Text('Thêm nhãn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Future<void> _showAddTagDialog() async {
    // TODO: Fetch available tags from workspace and show selection dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tag management coming soon')));
  }

  Future<void> _removeTag(dynamic tagId) async {
    try {
      await _apiClient.dio.delete('/api/tasks/${widget.taskId}/tags/$tagId');
      await _loadTaskData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gỡ nhãn')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // BOTTOM ACTIONS: STATE TRANSITIONS
  Widget? _buildBottomActions() {
    if (_task == null) return null;

    final status = _task!.status.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Member actions
          if (_isAssignee && !_canApprove) ...[
            if (status == 'todo' || status == 'inprogress')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeStatus('InProgress'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (status == 'inprogress') ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeStatus('WaitingForApproval'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Chờ duyệt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],

          // Owner/PM actions
          if (_canApprove) ...[
            if (status == 'waitingforapproval' ||
                status == 'waiting for approval')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveTask(),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Duyệt hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (status == 'waitingforapproval' ||
                status == 'waiting for approval') ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeStatus('InProgress'),
                  icon: const Icon(Icons.undo),
                  label: const Text('Yêu cầu sửa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      // TODO: Call proper API endpoint for status change
      await _apiClient.dio.patch(
        '/api/tasks/${widget.taskId}/status',
        data: {'status': newStatus},
      );

      await _loadTaskData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chuyển trạng thái sang $newStatus')),
        );

        // If changed to WaitingForApproval, send notification to Owner/PM
        if (newStatus == 'WaitingForApproval') {
          // TODO: Send notification via API
          print('📨 Sending notification to project owner/manager');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _approveTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Duyệt task này là hoàn thành?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _changeStatus('Done');
    }
  }

  // Helper widgets
  Widget _buildPriorityChip(String priority) {
    Color color;
    String label;

    switch (priority.toLowerCase()) {
      case 'urgent':
        color = AppColors.priorityUrgent;
        label = 'Khẩn cấp';
        break;
      case 'high':
        color = AppColors.priorityHigh;
        label = 'Cao';
        break;
      case 'medium':
        color = AppColors.priorityMedium;
        label = 'Trung bình';
        break;
      case 'low':
        color = AppColors.priorityLow;
        label = 'Thấp';
        break;
      default:
        color = AppColors.textHint;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'todo':
        color = AppColors.textHint;
        label = 'Chưa làm';
        icon = Icons.radio_button_unchecked;
        break;
      case 'inprogress':
      case 'in progress':
        color = AppColors.info;
        label = 'Đang làm';
        icon = Icons.pending;
        break;
      case 'waitingforapproval':
      case 'waiting for approval':
        color = AppColors.warning;
        label = 'Chờ duyệt';
        icon = Icons.hourglass_empty;
        break;
      case 'done':
      case 'completed':
        color = AppColors.success;
        label = 'Hoàn thành';
        icon = Icons.check_circle;
        break;
      default:
        color = AppColors.textHint;
        label = status;
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTypography.bodyMedium,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // TASK MANAGEMENT METHODS

  Widget _buildStatusButton(
    String status,
    String label,
    IconData icon,
    Color color,
  ) {
    // So sánh không phân biệt hoa thường
    final isCurrentStatus = _task?.status.toLowerCase() == status.toLowerCase();

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isCurrentStatus ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onPressed: () => _updateStatus(status),
      backgroundColor: isCurrentStatus ? color : color.withOpacity(0.1),
      labelStyle: GoogleFonts.inter(
        color: isCurrentStatus ? Colors.white : color,
        fontWeight: isCurrentStatus ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(color: color),
    );
  }

  Future<void> _editTask() async {
    if (_task == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditTaskDialog(task: _task!),
    );

    if (result == true && mounted) {
      await _loadTaskData();
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa task'),
        content: const Text(
          'Bạn có chắc muốn xóa task này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.deleteTask(widget.taskId);
      if (mounted) {
        Navigator.pop(context, true); // Return to previous screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa task')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _manageAssignees() async {
    if (_task == null || _task!.workspaceId == null) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => ManageAssigneesDialog(
        taskId: widget.taskId,
        workspaceId: _task!.workspaceId!,
        currentAssigneeIds: _task!.assigneeUserIds,
      ),
    );

    if (result != null && mounted) {
      await _loadTaskData();
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _apiClient.updateTaskStatus(
        widget.taskId,
        newStatus,
        widget.userRole,
      );
      if (mounted) {
        await _loadTaskData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _completeTask() async {
    try {
      await _apiClient.completeTask(widget.taskId);
      if (mounted) {
        await _loadTaskData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hoàn thành task')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
