import 'package:flutter/material.dart';

class GroupDetailSection extends StatelessWidget {
  const GroupDetailSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> group = {
      'name': 'Nhóm Flutter',
      'description': 'Nhóm chuyên phát triển ứng dụng Flutter cho đồ án cuối kỳ.',
      'leader': 'Nguyễn Văn A',
      'members': 5,
      'created': '01/09/2025',
      'status': 'Hoạt động',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group['name'] as String,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Trưởng nhóm: ${group['leader']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Thành viên: ${group['members'].toString()}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Ngày tạo: ${group['created']}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Mô tả:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                group['description'] as String,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (group['status'] == 'Hoạt động')
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group['status'] as String,
                  style: TextStyle(
                    color: (group['status'] == 'Hoạt động')
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
