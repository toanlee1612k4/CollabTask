import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'dart:math' as math;

/// AI Stats Chart - Beautiful circular chart showing AI weights
class AIStatsChart extends StatelessWidget {
  final UserWeights weights;
  final VoidCallback? onTap;

  const AIStatsChart({
    super.key,
    required this.weights,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.medium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.accent.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
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
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Task Prioritization',
                          style: GoogleFonts.inter(
                            fontSize: AppTypography.titleMedium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Powered by Machine Learning',
                          style: GoogleFonts.inter(
                            fontSize: AppTypography.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeightCircle(
                    'Deadline',
                    weights.deadlineWeight,
                    AppColors.error,
                    Icons.schedule_rounded,
                  ),
                  _buildWeightCircle(
                    'Importance',
                    weights.importanceWeight,
                    AppColors.warning,
                    Icons.flag_rounded,
                  ),
                  _buildWeightCircle(
                    'Effort',
                    weights.effortWeight,
                    AppColors.primary,
                    Icons.fitness_center_rounded,
                  ),
                  _buildWeightCircle(
                    'Balance',
                    (weights.deadlineWeight + weights.importanceWeight + weights.effortWeight) / 3,
                    AppColors.success,
                    Icons.balance_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'AI learns from your habits to suggest the best tasks',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightCircle(String label, double weight, Color color, IconData icon) {
    final percentage = (weight * 100).toInt();
    
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: weight,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 6.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Smart Task Card with AI Score Circle
class SmartTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const SmartTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // priorityScore from backend is already in points (0-200+)
    // Normalize to 0-100 for display (200+ max score)
    final normalizedScore = (task.priorityScore / 2.0).clamp(0.0, 100.0);
    final aiScore = normalizedScore / 100.0; // Convert to 0-1 for circle
    final scorePercentage = normalizedScore.toInt();
    
    return Card(
      elevation: AppElevation.low,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: _getScoreColor(aiScore).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // AI Score Circle
              _buildAIScoreCircle(aiScore, scorePercentage),
              
              const SizedBox(width: AppSpacing.md),
              
              // Task Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontSize: AppTypography.titleMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildPriorityBadge(task.priority),
                      ],
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
                        _buildStatusChip(task.status),
                        const SizedBox(width: AppSpacing.sm),
                        if (task.deadline != null) ...[
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: task.isOverdue 
                                ? AppColors.error 
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDeadline(task.deadline!),
                            style: GoogleFonts.inter(
                              fontSize: AppTypography.bodySmall,
                              color: task.isOverdue 
                                  ? AppColors.error 
                                  : AppColors.textHint,
                              fontWeight: task.isOverdue 
                                  ? FontWeight.w600 
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              Column(
                children: [
                  if (task.status != 'Completed' && onComplete != null)
                    IconButton(
                      onPressed: onComplete,
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      tooltip: 'Complete task',
                    ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIScoreCircle(double score, int percentage) {
    final color = _getScoreColor(score);
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: score,
                color: color,
                backgroundColor: color.withOpacity(0.2),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: color,
                size: 18,
              ),
              Text(
                '${task.priorityScore.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'pts',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    if (priority == null) return const SizedBox.shrink();
    
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
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            priority,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == null) return const SizedBox.shrink();
    
    Color color;
    String displayText;
    switch (status.toLowerCase()) {
      case 'done':
      case 'completed':
        color = AppColors.doneColor;
        displayText = 'Done';
        break;
      case 'inprogress':
      case 'in progress':
        color = AppColors.inProgressColor;
        displayText = 'In Progress';
        break;
      case 'review':
      case 'codereview':
      case 'code review':
        color = AppColors.codeReviewColor;
        displayText = 'Review';
        break;
      case 'todo':
        color = AppColors.todoColor;
        displayText = 'To Do';
        break;
      default:
        color = AppColors.todoColor;
        displayText = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.primary;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} days';
    } else {
      return '${deadline.day}/${deadline.month}/${deadline.year}';
    }
  }
}
