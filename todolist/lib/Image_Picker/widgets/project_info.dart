import 'package:flutter/material.dart';
import '../../models.dart';
import 'dart:io';

class ProjectInfo extends StatelessWidget {
  final Project project;
  const ProjectInfo({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftInfo(),
                  const SizedBox(height: 16),
                  _buildRightInfo(),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(flex: 2, child: _buildLeftInfo()),
                  Expanded(flex: 1, child: _buildRightInfo()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLeftInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(project.description, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text('Bắt đầu: ${_fmt(project.startDate)}')),
            const SizedBox(width: 12),
            Flexible(child: Text('Deadline: ${_fmt(project.deadline)}')),
          ],
        ),
      ],
    );
  }

  Widget _buildRightInfo() {
    return Column(
      children: [
        const Text('Tiến độ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: project.progress / 100, minHeight: 12),
        const SizedBox(height: 8),
        Text('${project.progress.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 36,
          backgroundImage: project.leader.avatar != null ? FileImage(project.leader.avatar!) : null,
          child: project.leader.avatar == null
              ? Text(project.leader.name.split(' ').map((e) => e[0]).take(2).join())
              : null,
        ),
        const SizedBox(height: 8),
        Text(project.leader.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(project.leader.role, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
