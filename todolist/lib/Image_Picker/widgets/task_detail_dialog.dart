import 'dart:io';
import 'package:flutter/material.dart';
import '../../models.dart';

class TaskDetailDialog extends StatelessWidget {
  final TaskItem task;
  const TaskDetailDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(task.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mô tả: ${task.description}'),
            const SizedBox(height: 8),
            Text('Người phụ trách: ${task.assignee.name}'),
            const SizedBox(height: 8),
            Text('Deadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}'),
            const SizedBox(height: 12),
            const Text('File đính kèm:'),
            const SizedBox(height: 8),
            if (task.attachments.isEmpty)
              const Text('Không có file đính kèm'),
            if (task.attachments.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: task.attachments.map((f) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(File(f.path), width: 180, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}
