import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';
import 'package:todolist/presentation/screens/workspace/kanban_workspace_screen.dart';
import 'package:todolist/core/providers/legacy_providers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _apiClient = ApiClient();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _apiClient.getNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
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

  Future<void> _markAsRead(String notificationId) async {
    try {
      // ✅ FIX: Sử dụng PUT (đúng API) thay vì PATCH
      await _apiClient.dio.put('/api/notifications/$notificationId/read');
      
      // ✅ Optimistic update - cập nhật local state ngay lập tức
      setState(() {
        final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          // Tạo bản copy với isRead = true
          final notification = _notifications[index];
          _notifications[index] = NotificationModel(
            notificationId: notification.notificationId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            isRead: true,
            createdAt: notification.createdAt,
            relatedTaskId: notification.relatedTaskId,
            relatedWorkspaceId: notification.relatedWorkspaceId,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đánh dấu đã đọc: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu tất cả đã đọc?'),
        content: const Text('Tất cả thông báo sẽ được đánh dấu là đã đọc.'),
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

    if (confirm != true) return;

    try {
      // Mark all unread as read
      for (var notification in _notifications.where((n) => !n.isRead)) {
        await _apiClient.dio.patch('/api/notifications/${notification.notificationId}/read');
      }
      
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
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

  Future<void> _deleteNotification(String notificationId) async {
    // ✅ Optimistic update - xóa khỏi list local ngay lập tức
    final deletedNotification = _notifications.firstWhere(
      (n) => n.notificationId == notificationId,
      orElse: () => _notifications.first, // fallback
    );
    final deletedIndex = _notifications.indexWhere((n) => n.notificationId == notificationId);
    
    setState(() {
      _notifications.removeWhere((n) => n.notificationId == notificationId);
    });

    try {
      await _apiClient.dio.delete('/api/notifications/$notificationId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thông báo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ✅ Rollback nếu API fail - thêm lại item vào list
      if (mounted) {
        setState(() {
          if (deletedIndex >= 0 && deletedIndex <= _notifications.length) {
            _notifications.insert(deletedIndex, deletedNotification);
          } else {
            _notifications.add(deletedNotification);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa thông báo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final filteredNotifications = _showUnreadOnly
        ? _notifications.where((n) => !n.isRead).toList()
        : _notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông báo',
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount chưa đọc',
                style: GoogleFonts.inter(
                  fontSize: AppTypography.bodySmall,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(
                      _showUnreadOnly ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Chỉ chưa đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Làm mới'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'filter') {
                setState(() => _showUnreadOnly = !_showUnreadOnly);
              } else if (value == 'refresh') {
                _loadNotifications();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(filteredNotifications[index]);
                        },
                      ),
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
              'Không thể tải thông báo',
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
              onPressed: _loadNotifications,
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
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _showUnreadOnly ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
            style: GoogleFonts.inter(
              fontSize: AppTypography.bodyLarge,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.notificationId),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.notificationId),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        color: notification.isRead ? Colors.white : AppColors.info.withOpacity(0.05),
        elevation: notification.isRead ? AppElevation.low : AppElevation.medium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: notification.isRead
                ? Colors.grey.shade300
                : AppColors.info.withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!notification.isRead) {
              await _markAsRead(notification.notificationId);
            }
            
            // Navigate based on notification type
            if (!mounted) return;
            
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUserId = authProvider.currentUser?.userId ?? '';
            
            switch (notification.type) {
              case 'task_assigned':
              case 'task_updated':
              case 'task_completed':
              case 'task_status_changed':
                // Navigate to task detail
                if (notification.relatedTaskId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnhancedTaskDetailScreen(
                        taskId: notification.relatedTaskId!,
                        currentUserId: currentUserId,
                        userRole: 'Member', // Will be loaded from API
                        initialTab: 0, // Info tab
                      ),
                    ),
                  );
                }
                break;
                
              case 'comment':
              case 'mention':
                // Navigate to task detail - Comments tab
                if (notification.relatedTaskId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnhancedTaskDetailScreen(
                        taskId: notification.relatedTaskId!,
                        currentUserId: currentUserId,
                        userRole: 'Member',
                        initialTab: 1, // Comments tab
                      ),
                    ),
                  );
                }
                break;
                
              case 'workspace_invite':
              case 'workspace_updated':
                // Navigate to workspace - need to load workspace name first
                if (notification.relatedWorkspaceId != null) {
                  try {
                    final workspace = await _apiClient.getWorkspaceById(notification.relatedWorkspaceId!);
                    if (!mounted) return;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KanbanWorkspaceScreen(
                          workspaceId: notification.relatedWorkspaceId!,
                          workspaceName: workspace.name,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Không thể mở workspace: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                break;
                
              default:
                // Unknown notification type - just mark as read
                break;
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'task_assigned':
        return Icons.assignment_turned_in;
      case 'comment':
        return Icons.comment;
      case 'mention':
        return Icons.alternate_email;
      case 'status_change':
        return Icons.update;
      case 'deadline':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'task_assigned':
        return AppColors.info;
      case 'comment':
        return AppColors.success;
      case 'mention':
        return AppColors.warning;
      case 'status_change':
        return AppColors.primary;
      case 'deadline':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
