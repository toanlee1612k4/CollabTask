// Màn hình Tổng quan dự án
import 'package:flutter/material.dart';
import '../../Image_Picker/screens/overview_screen.dart';
import '../../models.dart';
import '../widgets/project_info.dart';

class OverviewScreen extends StatelessWidget {
  final Project project;
  final VoidCallback onUpdate;

  const OverviewScreen({super.key, required this.project, required this.onUpdate});

  double _calcProgress(Project project) {
    if (project.tasks.isEmpty) return 0;
    final done = project.tasks.where((t) => t.status == 'Done').length;
    return done / project.tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calcProgress(project);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan dự án', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ProjectInfo(project: project),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiến độ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 1 ? Colors.green : Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(0)}% hoàn thành'),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Todo', project.tasks.where((t) => t.status == 'Todo').length, Colors.orange),
                  _statBox('In Progress', project.tasks.where((t) => t.status == 'InProgress').length, Colors.blue),
                  _statBox('Done', project.tasks.where((t) => t.status == 'Done').length, Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

