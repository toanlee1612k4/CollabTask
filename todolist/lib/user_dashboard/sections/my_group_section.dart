import 'package:flutter/material.dart';

class MyGroupSection extends StatelessWidget {
  const MyGroupSection({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {'name': 'Nhóm Flutter', 'leader': 'Nguyễn Văn A', 'members': 5, 'status': 'Hoạt động'},
      {'name': 'Nhóm Backend', 'leader': 'Trần Văn B', 'members': 4, 'status': 'Tạm dừng'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhóm của tôi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(group['name'].toString()),
                    subtitle: Text(
                      'Leader: ${group['leader'].toString()} | Thành viên: ${group['members'].toString()}',
                    ),
                    trailing: Text(
                      group['status'].toString(),
                      style: TextStyle(
                        color: group['status'] == 'Hoạt động'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
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
