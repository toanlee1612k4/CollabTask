import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:todolist/data/models/models.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final bool showCompleteButton;
  final int? assigneeCount;
  final String? assignmentStatus;
  final List<String>? assigneeNames;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.showCompleteButton = true,
    this.assigneeCount,
    this.assignmentStatus,
    this.assigneeNames,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getCardGradient(),
            border: task.isOverdue 
                ? Border.all(color: Colors.red.shade300, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với AI Score và Priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: task.status == 'Completed' 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade800,
                        decoration: task.status == 'Completed' 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAIScoreBadge(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description (nếu có)
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  task.description!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Status và Priority badges
              Row(
                children: [
                  _buildStatusBadge(),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(),
                  const Spacer(),
                  if (task.estimatedTimeMinutes != null)
                    _buildTimeEstimate(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Assignment info (nếu có)
              if (assigneeCount != null && assigneeCount! > 0) ...[
                _buildAssignmentInfo(),
                const SizedBox(height: 12),
              ],
              
              // Deadline và Complete button
              Row(
                children: [
                  Expanded(
                    child: _buildDeadlineInfo(),
                  ),
                  if (showCompleteButton && 
                      task.status != 'Completed' && 
                      onComplete != null) ...[
                    const SizedBox(width: 12),
                    _buildCompleteButton(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildAIScoreBadge() {
    final isHighScore = task.isHighPriority;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isHighScore
              ? [Colors.amber.shade400, Colors.orange.shade500]
              : [Colors.blue.shade400, Colors.indigo.shade500],
        ),
        boxShadow: isHighScore ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            task.priorityScore.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => isHighScore ? controller.repeat() : null,
    ).shimmer(
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    IconData statusIcon;
    
    switch (task.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'inprogress':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning_amber;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            task.statusLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color priorityColor;
    
    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Text(
        task.priorityLabel,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: priorityColor,
        ),
      ),
    );
  }

  Widget _buildTimeEstimate() {
    if (task.estimatedTimeMinutes == null) return const SizedBox.shrink();
    
    final hours = task.estimatedTimeMinutes! ~/ 60;
    final minutes = task.estimatedTimeMinutes! % 60;
    
    String timeText;
    if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else {
      timeText = '${minutes}m';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    if (task.deadline == null) {
      return Text(
        'Không có deadline',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    final now = DateTime.now();
    final deadline = task.deadline!;
    final difference = deadline.difference(now);
    
    Color deadlineColor;
    String deadlineText;
    IconData deadlineIcon;
    
    if (task.isOverdue) {
      deadlineColor = Colors.red;
      deadlineText = 'Quá hạn ${_formatDuration(difference.abs())}';
      deadlineIcon = Icons.warning;
    } else if (difference.inDays == 0) {
      deadlineColor = Colors.orange;
      deadlineText = 'Hôm nay';
      deadlineIcon = Icons.today;
    } else if (difference.inDays == 1) {
      deadlineColor = Colors.orange;
      deadlineText = 'Ngày mai';
      deadlineIcon = Icons.event;
    } else if (difference.inDays <= 3) {
      deadlineColor = Colors.orange.shade700;
      deadlineText = 'Còn ${difference.inDays} ngày';
      deadlineIcon = Icons.schedule;
    } else {
      deadlineColor = Colors.grey.shade600;
      deadlineText = 'Còn ${difference.inDays} ngày';
      deadlineIcon = Icons.schedule;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          deadlineIcon,
          size: 16,
          color: deadlineColor,
        ),
        const SizedBox(width: 4),
        Text(
          deadlineText,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: deadlineColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return ElevatedButton(
      onPressed: onComplete,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 16),
          const SizedBox(width: 4),
          Text(
            'Hoàn thành',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 300.ms);
  }

  LinearGradient _getCardGradient() {
    if (task.status == 'Completed') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.shade50,
          Colors.green.shade100,
        ],
      );
    }
    
    if (task.isOverdue) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.shade50,
          Colors.red.shade100,
        ],
      );
    }
    
    if (task.isHighPriority) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber.shade50,
          Colors.orange.shade50,
        ],
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.shade50,
        Colors.indigo.shade50,
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ';
    } else {
      return '${duration.inMinutes} phút';
    }
  }

  Widget _buildAssignmentInfo() {
    if (assigneeCount == null || assigneeCount == 0) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText = assignmentStatus ?? 'Assigned';

    switch (statusText.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Chờ phản hồi';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Đã chấp nhận';
        break;
      case 'inprogress':
        statusColor = Colors.purple;
        statusIcon = Icons.play_circle;
        statusText = 'Đang làm';
        break;
      case 'completionrequested':
        statusColor = Colors.amber;
        statusIcon = Icons.pending_actions;
        statusText = 'Chờ duyệt';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Bị từ chối';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person;
        statusText = 'Đã giao';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar stack
          if (assigneeNames != null && assigneeNames!.isNotEmpty)
            SizedBox(
              width: assigneeCount! > 3 ? 80 : (assigneeCount! * 24.0 + 4),
              height: 28,
              child: Stack(
                children: [
                  for (int i = 0; i < (assigneeCount! > 3 ? 3 : assigneeCount!); i++)
                    Positioned(
                      left: i * 20.0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: _getAvatarColor(i),
                        child: Text(
                          assigneeNames![i].substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (assigneeCount! > 3)
                    Positioned(
                      left: 60,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          '+${assigneeCount! - 3}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Icon(Icons.people, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$assigneeCount người được giao',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.teal,
      Colors.green,
    ];
    return colors[index % colors.length];
  }
}

// Compact version của TaskCard cho danh sách
class CompactTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const CompactTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: task.isHighPriority 
              ? Colors.amber.shade100 
              : Colors.blue.shade100,
          child: Text(
            task.priorityScore.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: task.isHighPriority 
                  ? Colors.amber.shade700 
                  : Colors.blue.shade700,
            ),
          ),
        ),
        title: Text(
          task.title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.status == 'Completed' 
                ? TextDecoration.lineThrough 
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priorityLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getPriorityColor(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (task.deadline != null)
              Text(
                _getDeadlineText(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: task.isOverdue ? Colors.red : Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: task.status == 'Completed'
            ? Icon(Icons.check_circle, color: Colors.green, size: 24)
            : task.isOverdue
                ? Icon(Icons.warning, color: Colors.red, size: 24)
                : null,
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Color _getPriorityColor() {
    switch (task.priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getDeadlineText() {
    if (task.deadline == null) return '';
    
    final now = DateTime.now();
    final deadline = task.deadline!;
    final difference = deadline.difference(now);
    
    if (task.isOverdue) {
      return 'Quá hạn';
    } else if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Ngày mai';
    } else {
      return 'Còn ${difference.inDays} ngày';
    }
  }
}
