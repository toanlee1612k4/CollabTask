import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:todolist/data/models/models.dart';

class AiStatsChart extends StatefulWidget {
  final UserWeights userWeights;
  final VoidCallback? onResetWeights;

  const AiStatsChart({
    super.key,
    required this.userWeights,
    this.onResetWeights,
  });

  @override
  State<AiStatsChart> createState() => _AiStatsChartState();
}

class _AiStatsChartState extends State<AiStatsChart>
    with TickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildChart(),
            const SizedBox(height: 20),
            _buildLegend(),
            const SizedBox(height: 16),
            _buildInsights(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.blue.shade500],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.psychology,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Learning Stats',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade800,
                ),
              ),
              Text(
                'Trọng số ưu tiên của bạn',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (widget.onResetWeights != null)
          IconButton(
            onPressed: widget.onResetWeights,
            icon: Icon(
              Icons.refresh,
              color: Colors.indigo.shade600,
            ),
            tooltip: 'Reset AI Weights',
          ),
      ],
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              sections: _buildPieChartSections(),
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final weights = widget.userWeights;
    final total = weights.totalWeight;
    
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'Chưa có dữ liệu',
          radius: 80,
          titleStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ];
    }

    return [
      // Deadline Weight
      PieChartSectionData(
        color: Colors.red.shade400,
        value: weights.deadlinePercentage * _animation.value,
        title: touchedIndex == 0 
            ? '${weights.deadlinePercentage.toStringAsFixed(1)}%'
            : '',
        radius: touchedIndex == 0 ? 90 : 80,
        titleStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: touchedIndex == 0 ? _buildBadge(
          Icons.schedule,
          'Deadline',
          Colors.red.shade400,
        ) : null,
        badgePositionPercentageOffset: 1.3,
      ),
      
      // Importance Weight
      PieChartSectionData(
        color: Colors.orange.shade400,
        value: weights.importancePercentage * _animation.value,
        title: touchedIndex == 1 
            ? '${weights.importancePercentage.toStringAsFixed(1)}%'
            : '',
        radius: touchedIndex == 1 ? 90 : 80,
        titleStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: touchedIndex == 1 ? _buildBadge(
          Icons.star,
          'Importance',
          Colors.orange.shade400,
        ) : null,
        badgePositionPercentageOffset: 1.3,
      ),
      
      // Effort Weight
      PieChartSectionData(
        color: Colors.blue.shade400,
        value: weights.effortPercentage * _animation.value,
        title: touchedIndex == 2 
            ? '${weights.effortPercentage.toStringAsFixed(1)}%'
            : '',
        radius: touchedIndex == 2 ? 90 : 80,
        titleStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: touchedIndex == 2 ? _buildBadge(
          Icons.fitness_center,
          'Effort',
          Colors.blue.shade400,
        ) : null,
        badgePositionPercentageOffset: 1.3,
      ),
    ];
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final weights = widget.userWeights;
    
    return Column(
      children: [
        _buildLegendItem(
          'Deadline Priority',
          'Ưu tiên theo thời hạn',
          Colors.red.shade400,
          weights.deadlinePercentage,
          Icons.schedule,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Importance Priority',
          'Ưu tiên theo tầm quan trọng',
          Colors.orange.shade400,
          weights.importancePercentage,
          Icons.star,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Effort Priority',
          'Ưu tiên theo độ khó',
          Colors.blue.shade400,
          weights.effortPercentage,
          Icons.fitness_center,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String title,
    String subtitle,
    Color color,
    double percentage,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (200 * (percentage / 10)).round().ms)
        .slideX(begin: 0.3, end: 0)
        .fadeIn();
  }

  Widget _buildInsights() {
    final weights = widget.userWeights;
    String insight;
    IconData insightIcon;
    Color insightColor;

    if (weights.deadlinePercentage > 50) {
      insight = 'Bạn thường ưu tiên các task có deadline gần';
      insightIcon = Icons.schedule;
      insightColor = Colors.red.shade600;
    } else if (weights.importancePercentage > 50) {
      insight = 'Bạn thường ưu tiên các task quan trọng';
      insightIcon = Icons.star;
      insightColor = Colors.orange.shade600;
    } else if (weights.effortPercentage > 50) {
      insight = 'Bạn thường ưu tiên các task dễ làm trước';
      insightIcon = Icons.fitness_center;
      insightColor = Colors.blue.shade600;
    } else {
      insight = 'AI đang học thói quen làm việc của bạn';
      insightIcon = Icons.psychology;
      insightColor = Colors.indigo.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            insightColor.withOpacity(0.1),
            insightColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insightColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insightColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              insightIcon,
              color: insightColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: insightColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2, end: 0);
  }
}

// Compact version cho dashboard
class CompactAiStatsChart extends StatelessWidget {
  final UserWeights userWeights;
  final VoidCallback? onTap;

  const CompactAiStatsChart({
    super.key,
    required this.userWeights,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade50,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Stats',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 25,
                    sections: _buildCompactSections(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCompactLegend(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  List<PieChartSectionData> _buildCompactSections() {
    final weights = userWeights;
    final total = weights.totalWeight;
    
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          radius: 25,
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.red.shade400,
        value: weights.deadlinePercentage,
        radius: 25,
      ),
      PieChartSectionData(
        color: Colors.orange.shade400,
        value: weights.importancePercentage,
        radius: 25,
      ),
      PieChartSectionData(
        color: Colors.blue.shade400,
        value: weights.effortPercentage,
        radius: 25,
      ),
    ];
  }

  Widget _buildCompactLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactLegendItem(
          'D',
          Colors.red.shade400,
          userWeights.deadlinePercentage,
        ),
        _buildCompactLegendItem(
          'I',
          Colors.orange.shade400,
          userWeights.importancePercentage,
        ),
        _buildCompactLegendItem(
          'E',
          Colors.blue.shade400,
          userWeights.effortPercentage,
        ),
      ],
    );
  }

  Widget _buildCompactLegendItem(String label, Color color, double percentage) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
