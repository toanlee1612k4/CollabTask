import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';

/// Compact task card for workspace detail view
class WorkspaceTaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel? assignee;
  final VoidCallback? onTap;

  const WorkspaceTaskCard({
    super.key,
    required this.task,
    this.assignee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(task.status);
    final priorityColor = AppTheme.getPriorityColor(task.priority);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppConstants.mobileBreakpoint;

    return Semantics(
      label: 'Nhiệm vụ: ${task.title}, trạng thái: ${_getStatusText(task.status)}, độ ưu tiên: ${task.priority}',
      button: onTap != null,
      child: RepaintBoundary(
        child: Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingS),
                      _buildStatusBadge(context, task.status, statusColor),
                    ],
                  ),
                  
                  // Description
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingS),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  SizedBox(height: AppConstants.spacingM),
                  
                  // Footer
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingS,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildPriorityBadge(context, task.priority, priorityColor),
                      
                      if (task.deadline != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: AppConstants.iconS,
                          color: AppTheme.textTertiary,
                        ),
                        Text(
                          _formatDate(task.deadline!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      
                      if (assignee != null) ...[
                        const Spacer(),
                        if (!isCompact) ...[
                          _buildAssigneeAvatar(assignee!),
                          SizedBox(width: AppConstants.spacingXs),
                        ],
                        Text(
                          assignee!.fullName ?? assignee!.email.split('@')[0],
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildStatusBadge(BuildContext context, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        _getStatusText(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        priority,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssigneeAvatar(UserModel user) {
    final initial = (user.fullName ?? user.email)[0].toUpperCase();
    
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppTheme.accentColor,
      backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
          ? CachedNetworkImageProvider(user.avatar!)
          : null,
      child: user.avatar == null || user.avatar!.isEmpty
          ? Text(
              initial,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  String _getStatusText(String status) {
    const statusMap = {
      'ToDo': 'Chưa làm',
      'InProgress': 'Đang làm',
      'Done': 'Hoàn thành',
      'Pending': 'Chờ duyệt',
    };
    return statusMap[status] ?? status;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
