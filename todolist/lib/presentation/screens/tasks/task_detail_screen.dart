import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/models/task_assignment_models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'assign_users_dialog.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  final String currentUserRole; // Owner, ProjectManager, Member
  final String currentUserId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.currentUserRole,
    required this.currentUserId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TaskAssignment> _assignments = [];
  List<TaskAssignmentHistory> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTaskDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignments = await apiClient.taskAssignment.getTaskAssignments(widget.task.taskId);
      final history = await apiClient.taskAssignment.getAssignmentHistory(widget.task.taskId);

      setState(() {
        _assignments = assignments;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _canAssignTasks => 
      widget.currentUserRole == 'Owner' || 
      widget.currentUserRole == 'ProjectManager';

  bool get _canApprove => _canAssignTasks;

  TaskAssignment? get _myAssignment =>
      _assignments.where((a) => a.assigneeUserId == widget.currentUserId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Task'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_canAssignTasks)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAssignDialog,
              tooltip: 'Giao việc',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadTaskDetails,
                  child: CustomScrollView(
                    slivers: [
                      // Task Info Header
                      SliverToBoxAdapter(child: _buildTaskHeader()),
                      
                      // My Assignment Actions (if applicable)
                      if (_myAssignment != null)
                        SliverToBoxAdapter(child: _buildMyAssignmentActions()),
                      
                      // Tabs: Assignments & History
                      SliverToBoxAdapter(child: _buildTabBar()),
                      
                      // Tab Content
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAssignmentsList(),
                            _buildHistoryList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.task.title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildPriorityBadge(),
            ],
          ),
          if (widget.task.description != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.task.description!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                widget.task.deadline != null
                    ? '${widget.task.deadline!.day}/${widget.task.deadline!.month}/${widget.task.deadline!.year}'
                    : 'Không có deadline',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.flag,
                widget.task.statusLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    switch (widget.task.priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.task.priorityLabel,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAssignmentActions() {
    final assignment = _myAssignment!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhiệm vụ của bạn',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trạng thái: ${assignment.status.displayName}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          _buildMyActionButtons(assignment),
        ],
      ),
    );
  }

  Widget _buildMyActionButtons(TaskAssignment assignment) {
    if (assignment.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _respondToAssignment(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check),
              label: const Text('Chấp nhận'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _respondToAssignment(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close),
              label: const Text('Từ chối'),
            ),
          ),
        ],
      );
    }

    if (assignment.isAccepted || assignment.isInProgress) {
      return ElevatedButton.icon(
        onPressed: _requestCompletion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.done_all),
        label: const Text('Yêu cầu duyệt hoàn thành'),
      );
    }

    if (assignment.isAwaitingApproval) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đang chờ PM/Owner duyệt...',
                style: GoogleFonts.inter(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (assignment.isApproved) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'Đã hoàn thành',
              style: GoogleFonts.inter(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.indigo.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('Người làm (${_assignments.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 4),
                Text('Lịch sử (${_history.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có ai được giao việc',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (_canAssignTasks) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAssignDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Giao việc ngay'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        return _buildAssignmentCard(_assignments[index]);
      },
    );
  }

  Widget _buildAssignmentCard(TaskAssignment assignment) {
    Color statusColor;
    IconData statusIcon;

    switch (assignment.status) {
      case TaskAssignmentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case TaskAssignmentStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case TaskAssignmentStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case TaskAssignmentStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.play_circle;
        break;
      case TaskAssignmentStatus.completionRequested:
        statusColor = Colors.amber;
        statusIcon = Icons.pending_actions;
        break;
      case TaskAssignmentStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    assignment.assigneeName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.assigneeName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        assignment.assigneeEmail,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        assignment.status.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (assignment.responseNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.responseNote!,
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ],
            if (assignment.isAwaitingApproval && _canApprove) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCompletion(assignment, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Duyệt'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCompletion(assignment, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Từ chối'),
                    ),
                  ),
                ],
              ),
            ],
            if (_canAssignTasks && !assignment.isApproved) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _removeAssignment(assignment),
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                label: const Text('Gỡ người làm'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lịch sử',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_history[index]);
      },
    );
  }

  Widget _buildHistoryItem(TaskAssignmentHistory item) {
    IconData icon;
    Color color;

    switch (item.action) {
      case 'Assigned':
        icon = Icons.assignment_ind;
        color = Colors.blue;
        break;
      case 'Accepted':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'CompletionRequested':
        icon = Icons.done_all;
        color = Colors.orange;
        break;
      case 'Approved':
        icon = Icons.verified;
        color = Colors.green;
        break;
      case 'Unassigned':
        icon = Icons.person_remove;
        color = Colors.grey;
        break;
      default:
        icon = Icons.history;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          item.action,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.actionByName} → ${item.assigneeName}'),
            Text(
              '${item.actionAt.day}/${item.actionAt.month}/${item.actionAt.year} ${item.actionAt.hour}:${item.actionAt.minute}',
              style: const TextStyle(fontSize: 12),
            ),
            if (item.note != null) Text('"${item.note}"', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Lỗi: $_error',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTaskDetails,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _showAssignDialog() async {
    // Get current assignee IDs
    final currentAssigneeIds = _assignments.map((a) => a.assigneeUserId).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AssignUsersDialog(
        workspaceId: widget.task.workspaceId ?? '',
        taskId: widget.task.taskId,
        currentAssigneeIds: currentAssigneeIds,
      ),
    );

    if (result == true) {
      _loadTaskDetails(); // Reload assignments after successful assignment
    }
  }

  Future<void> _respondToAssignment(bool accept) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Chấp nhận nhiệm vụ' : 'Từ chối nhiệm vụ'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (tùy chọn)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.taskAssignment.respondToAssignment(
        taskId: widget.task.taskId,
        accept: accept,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Đã chấp nhận nhiệm vụ' : 'Đã từ chối nhiệm vụ'),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );
        _loadTaskDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _requestCompletion() async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu duyệt hoàn thành'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn đã hoàn thành công việc này?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'VD: Đã hoàn thành và test xong',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.taskAssignment.requestCompletion(
        taskId: widget.task.taskId,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu duyệt hoàn thành'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTaskDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveCompletion(TaskAssignment assignment, bool approve) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Duyệt hoàn thành' : 'Từ chối hoàn thành'),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: 'Ghi chú${approve ? ' (tùy chọn)' : ' (bắt buộc)'}',
            hintText: approve ? 'VD: Làm tốt lắm!' : 'VD: Cần sửa lại phần...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!approve && noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.taskAssignment.approveCompletion(
        taskId: widget.task.taskId,
        approve: approve,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Đã duyệt hoàn thành' : 'Đã từ chối'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        _loadTaskDetails();
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeAssignment(TaskAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ người làm'),
        content: Text('Bạn có chắc muốn gỡ ${assignment.assigneeName} khỏi task này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gỡ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.taskAssignment.removeAssignment(
        taskId: widget.task.taskId,
        assigneeUserId: assignment.assigneeUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gỡ người làm'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadTaskDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
