import 'package:flutter/material.dart';

class MemberManagementSection extends StatefulWidget {
  const MemberManagementSection({super.key});

  @override
  State<MemberManagementSection> createState() => _MemberManagementSectionState();
}

class _MemberManagementSectionState extends State<MemberManagementSection> {
  List<Map<String, String>> members = [
    {'name': 'Nguyễn Văn A', 'role': 'Trưởng nhóm'},
    {'name': 'Trần Thị B', 'role': 'Thành viên'},
    {'name': 'Lê Văn C', 'role': 'Thành viên'},
  ];

  final nameController = TextEditingController();
  String selectedRole = 'Thành viên';

  void _addMember() {
    if (nameController.text.isNotEmpty) {
      setState(() {
        members.add({
          'name': nameController.text,
          'role': selectedRole,
        });
      });
      nameController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm thành viên mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thành viên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Vai trò',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Thành viên', child: Text('Thành viên')),
                DropdownMenuItem(value: 'Trưởng nhóm', child: Text('Trưởng nhóm')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: _addMember, child: const Text('Lưu')),
        ],
      ),
    );
  }

  void _removeMember(int index) {
    setState(() {
      members.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Thêm thành viên'),
        onPressed: _showAddDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách thành viên',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(member['name']!),
                      subtitle: Text('Vai trò: ${member['role']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeMember(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
