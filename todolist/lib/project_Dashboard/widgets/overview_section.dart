import 'package:flutter/material.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tổng quan dự án",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Tên dự án: Ứng dụng Quản lý công việc",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Ngày bắt đầu: 01/10/2025"),
                      Text("Hạn hoàn thành: 30/12/2025"),
                      SizedBox(height: 8),
                      Text(
                        "Leader: Nguyễn Văn A",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tiến độ dự án"),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.7,
                        color: Colors.blue,
                        backgroundColor: Colors.grey.shade300,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 10),
                      const Text("Hoàn thành 70%"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
