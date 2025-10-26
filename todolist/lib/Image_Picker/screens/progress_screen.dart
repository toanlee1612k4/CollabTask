// Màn hình Tiến độ (Pie Chart + Gantt Chart placeholder)
import 'package:flutter/material.dart';

import '../../models.dart';
import '../widgets/progress_charts.dart';

class ProgressScreen extends StatelessWidget {
  final Project project;
  const ProgressScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final done = project.tasks.where((t) => t.status == 'Done').length;
    final total = project.tasks.length;
    final todo = total - done;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              Row(
                children: [
                  const Text(
                    'Tiến độ / Báo cáo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    'Tổng: $total',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Thống kê số lượng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Hoàn thành', done, Colors.green),
                  _buildStatCard('Còn lại', todo, Colors.orange),
                ],
              ),
              const SizedBox(height: 16),

              // Pie Chart
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProgressPieChart(done: done, todo: todo),
                ),
              ),

              const SizedBox(height: 20),

              // Placeholder cho Gantt Chart
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text(
                    'Biểu đồ Gantt (đang phát triển...)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget thống kê nhỏ
  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
