import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/providers/signalr_provider.dart';
import 'package:todolist/data/services/signalr_service.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';

/// Wrapper Widget để lắng nghe SignalR events và hiển thị UI feedback
/// Wrap widget này ở root của app hoặc màn hình chính
class SignalRListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTaskListShouldRefresh;

  const SignalRListenerWrapper({
    super.key,
    required this.child,
    this.onTaskListShouldRefresh,
  });

  @override
  ConsumerState<SignalRListenerWrapper> createState() => _SignalRListenerWrapperState();
}

class _SignalRListenerWrapperState extends ConsumerState<SignalRListenerWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Setup callbacks after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCallbacks();
    });
  }

  void _setupCallbacks() {
    final notifier = ref.read(signalRProvider.notifier);

    // Handle new notifications
    notifier.onNotificationReceived = (notification) {
      _showNotificationSnackBar(notification);
    };

    // Handle task assigned
    notifier.onTaskAssigned = (event) {
      _showTaskAssignedSnackBar(event);
      widget.onTaskListShouldRefresh?.call();
    };

    // Handle task updated
    notifier.onTaskUpdated = (event) {
      _showTaskUpdatedSnackBar(event);
      widget.onTaskListShouldRefresh?.call();
    };

    // Handle comment received
    notifier.onCommentReceived = (event) {
      _showCommentSnackBar(event);
    };
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            _getNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: notification.relatedTaskId != null
            ? SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () => _navigateToTask(notification.relatedTaskId!),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showTaskAssignedSnackBar(TaskAssignedEvent event) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_ind,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Task mới được gán!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.taskTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Từ: ${event.assignedByName} • ${event.workspaceName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Xem Task',
          textColor: Colors.white,
          onPressed: () => _navigateToTask(event.taskId),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showTaskUpdatedSnackBar(TaskUpdatedEvent event) {
    if (!mounted) return;

    String message;
    IconData icon;
    Color color;

    switch (event.updateType.toLowerCase()) {
      case 'status_changed':
        message = '${event.updatedByName} đã cập nhật trạng thái task';
        icon = Icons.sync;
        color = AppColors.info;
        break;
      case 'completed':
        message = '${event.updatedByName} đã hoàn thành task';
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'priority_changed':
        message = '${event.updatedByName} đã thay đổi độ ưu tiên';
        icon = Icons.flag;
        color = AppColors.warning;
        break;
      case 'deadline_changed':
        message = '${event.updatedByName} đã cập nhật deadline';
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case 'deleted':
        message = '${event.updatedByName} đã xóa task';
        icon = Icons.delete;
        color = AppColors.error;
        break;
      default:
        message = '${event.updatedByName} đã cập nhật task';
        icon = Icons.edit;
        color = AppColors.primary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: event.updateType != 'deleted'
            ? SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () => _navigateToTask(event.taskId),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCommentSnackBar(CommentReceivedEvent event) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.comment,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💬 ${event.authorName} đã comment',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    event.content.length > 50 
                        ? '${event.content.substring(0, 50)}...' 
                        : event.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () => _navigateToTask(event.taskId),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (type.toLowerCase()) {
      case 'task_assigned':
        iconData = Icons.assignment_ind;
        break;
      case 'task_completed':
        iconData = Icons.check_circle;
        break;
      case 'comment':
        iconData = Icons.comment;
        break;
      case 'deadline_reminder':
        iconData = Icons.alarm;
        break;
      case 'workspace_invite':
        iconData = Icons.group_add;
        break;
      default:
        iconData = Icons.notifications;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  void _navigateToTask(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedTaskDetailScreen(taskId: taskId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch connection state để có thể hiển thị indicator
    final connectionState = ref.watch(signalRConnectionProvider);
    
    return Stack(
      children: [
        widget.child,
        
        // Connection status indicator (optional - show khi reconnecting)
        if (connectionState == SignalRConnectionState.reconnecting)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang kết nối lại...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== NOTIFICATION BADGE WIDGET ====================

/// Badge hiển thị số thông báo chưa đọc (dùng ở AppBar)
class NotificationBadge extends ConsumerWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final connectionState = ref.watch(signalRConnectionProvider);

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          ),
          onPressed: onTap,
          tooltip: 'Thông báo',
        ),
        
        // Badge count
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // Connection indicator dot
        if (connectionState != SignalRConnectionState.connected)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: connectionState == SignalRConnectionState.reconnecting
                    ? AppColors.warning
                    : AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== CONNECTION STATUS WIDGET ====================

/// Widget hiển thị trạng thái kết nối SignalR
class SignalRConnectionStatus extends ConsumerWidget {
  const SignalRConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signalRProvider);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (state.connectionState) {
      case SignalRConnectionState.connected:
        statusColor = AppColors.success;
        statusText = 'Đã kết nối';
        statusIcon = Icons.cloud_done;
        break;
      case SignalRConnectionState.connecting:
        statusColor = AppColors.warning;
        statusText = 'Đang kết nối...';
        statusIcon = Icons.cloud_upload;
        break;
      case SignalRConnectionState.reconnecting:
        statusColor = AppColors.warning;
        statusText = 'Đang kết nối lại...';
        statusIcon = Icons.cloud_sync;
        break;
      case SignalRConnectionState.error:
        statusColor = AppColors.error;
        statusText = state.lastError ?? 'Lỗi kết nối';
        statusIcon = Icons.cloud_off;
        break;
      case SignalRConnectionState.disconnected:
      default:
        statusColor = Colors.grey;
        statusText = 'Chưa kết nối';
        statusIcon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          if (state.connectionState == SignalRConnectionState.error) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ref.read(signalRProvider.notifier).reconnect(),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
