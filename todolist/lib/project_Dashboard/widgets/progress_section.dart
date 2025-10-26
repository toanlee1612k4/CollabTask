import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tiến độ & Báo cáo",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text("Tổng quan tiến độ các công việc:"),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: 0.65, minHeight: 10),
        const SizedBox(height: 20),
        const Text("Biểu đồ tỉ lệ hoàn thành (demo):"),
        const SizedBox(height: 10),
        Card(
          color: Colors.blue.shade50,
          child: SizedBox(
            height: 200,
            child: Center(
              child: Icon(Icons.pie_chart, size: 80, color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }
}
