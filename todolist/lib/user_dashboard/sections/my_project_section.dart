import 'package:flutter/material.dart';

class MyProjectSection extends StatelessWidget {
  const MyProjectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = [
      {
        'name': 'Ứng dụng Quản lý Công việc',
        'start': '01/09/2025',
        'deadline': '30/10/2025',
        'role': 'Thành viên',
        'progress': 0.75
      },
      {
        'name': 'Website Hỗ trợ Sinh viên',
        'start': '15/08/2025',
        'deadline': '15/10/2025',
        'role': 'Leader',
        'progress': 0.55
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dự án của tôi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      project['name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Bắt đầu: ${project['start'].toString()} | Hạn: ${project['deadline'].toString()} | Vai trò: ${project['role'].toString()}',
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(
                            value: project['progress'] as double,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${((project['progress'] as double) * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
