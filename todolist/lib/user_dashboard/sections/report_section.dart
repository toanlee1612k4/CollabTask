import 'package:flutter/material.dart';

class ReportSection extends StatelessWidget {
  const ReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Báo cáo tiến độ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Chọn tháng'),
                  items: ['Tháng 9', 'Tháng 10', 'Tháng 11']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Chọn dự án'),
                  items: ['Ứng dụng quản lý công việc', 'Website sinh viên']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '📊 Biểu đồ tiến độ công việc (giả lập)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Danh sách công việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Hoàn thành báo cáo tuần 1'),
                  trailing: Text('Đã hoàn thành'),
                ),
                ListTile(
                  leading: Icon(Icons.timelapse, color: Colors.orange),
                  title: Text('Thiết kế UI cho dashboard'),
                  trailing: Text('Đang thực hiện'),
                ),
                ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Cập nhật API tiến độ'),
                  trailing: Text('Trễ hạn'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
