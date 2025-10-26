import 'package:flutter/material.dart';

class TaskSection extends StatefulWidget {
  const TaskSection({super.key});

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection> {
  List<Map<String, dynamic>> tasks = [
    {
      'title': 'Thiết kế giao diện đăng nhập',
      'assigned': 'Nguyễn Văn A',
      'deadline': '10/10/2025',
      'status': 'Đang làm',
    },
    {
      'title': 'Tạo cơ sở dữ liệu MySQL',
      'assigned': 'Trần Thị B',
      'deadline': '12/10/2025',
      'status': 'Chưa làm',
    },
  ];

  final _titleController = TextEditingController();
  final _assignedController = TextEditingController();
  final _deadlineController = TextEditingController();
  String _selectedStatus = 'Chưa làm';

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm công việc mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công việc',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _assignedController,
                  decoration: const InputDecoration(
                    labelText: 'Người phụ trách',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Hạn hoàn thành (dd/mm/yyyy)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'Chưa làm', child: Text('Chưa làm')),
                    DropdownMenuItem(value: 'Đang làm', child: Text('Đang làm')),
                    DropdownMenuItem(value: 'Hoàn thành', child: Text('Hoàn thành')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _assignedController.text.isNotEmpty &&
                    _deadlineController.text.isNotEmpty) {
                  setState(() {
                    tasks.add({
                      'title': _titleController.text,
                      'assigned': _assignedController.text,
                      'deadline': _deadlineController.text,
                      'status': _selectedStatus,
                    });
                  });
                  _titleController.clear();
                  _assignedController.clear();
                  _deadlineController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
        onPressed: _showAddTaskDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách công việc',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('Chưa có công việc nào'))
                  : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: Text(task['title']),
                      subtitle: Text(
                          'Người phụ trách: ${task['assigned']}\nHạn: ${task['deadline']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task['status'] == 'Hoàn thành'
                              ? Colors.green.shade100
                              : task['status'] == 'Đang làm'
                              ? Colors.orange.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task['status'],
                          style: TextStyle(
                            color: task['status'] == 'Hoàn thành'
                                ? Colors.green.shade700
                                : task['status'] == 'Đang làm'
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
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
