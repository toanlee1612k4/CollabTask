import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';

/// Summary card widget for dashboard (Done, Updated, New, Due)
class DashboardSummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap;

  const DashboardSummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.bodySmall,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status pie chart widget
class StatusPieChartCard extends StatelessWidget {
  final Map<String, int> statusData;

  const StatusPieChartCard({
    super.key,
    required this.statusData,
  });

  @override
  Widget build(BuildContext context) {
    final total = statusData.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status summary',
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Get a snapshot of the status of your items',
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                // Pie chart placeholder
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _PieChartPainter(statusData),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Legend
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendItem('Done', statusData['Done'] ?? 0, AppColors.doneColor),
                      _buildLegendItem('In progress', statusData['InProgress'] ?? 0, AppColors.inProgressColor),
                      _buildLegendItem('To do', statusData['ToDo'] ?? 0, AppColors.todoColor),
                      const Divider(),
                      _buildLegendItem('Total', total, AppColors.textPrimary, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: AppTypography.titleMedium,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = data.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) return;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    final colorMap = {
      'Done': AppColors.doneColor,
      'InProgress': AppColors.inProgressColor,
      'ToDo': AppColors.todoColor,
    };

    data.forEach((status, count) {
      final sweepAngle = (count / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colorMap[status] ?? Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    });

    // Draw white center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Team workload horizontal bar chart
class TeamWorkloadCard extends StatelessWidget {
  final List<TeamMemberWorkload> workloads;

  const TeamWorkloadCard({
    super.key,
    required this.workloads,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team workload',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.titleLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Oversee the capacity of your team',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Re-assign tasks',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Table header
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Assignee', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('Work distribution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.centerRight,
                  child: const Text('Count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
            // Workload bars
            ...workloads.map((workload) => _buildWorkloadRow(workload)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadRow(TeamMemberWorkload workload) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    workload.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workload.name,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: workload.percentage / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: workload.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            child: Text(
              '${workload.count}',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamMemberWorkload {
  final String name;
  final int count;
  final double percentage;
  final Color color;

  TeamMemberWorkload({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });
}
