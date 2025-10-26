import 'package:flutter/material.dart';

class GroupListSection extends StatefulWidget {
  const GroupListSection({super.key});

  @override
  State<GroupListSection> createState() => _GroupListSectionState();
}

class _GroupListSectionState extends State<GroupListSection> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> groups = [
    {'name': 'Nhóm Flutter', 'leader': 'Nguyễn Văn A', 'members': 5, 'date': '01/09/2025', 'status': 'Hoạt động'},
    {'name': 'Nhóm Web', 'leader': 'Trần Thị B', 'members': 7, 'date': '15/09/2025', 'status': 'Tạm ngưng'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh sách nhóm',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Tìm kiếm nhóm...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tạo nhóm mới'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(group['name']),
                    subtitle: Text('Leader: ${group['leader']} • ${group['members']} thành viên'),
                    trailing: Text(group['status'],
                        style: TextStyle(
                          color: group['status'] == 'Hoạt động'
                              ? Colors.green
                              : Colors.orange,
                        )),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xem chi tiết nhóm: ${group['name']}')),
                      );
                    },
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
