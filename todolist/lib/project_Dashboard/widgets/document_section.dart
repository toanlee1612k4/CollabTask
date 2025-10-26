import 'package:flutter/material.dart';

class DocumentSection extends StatelessWidget {
  const DocumentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final files = [
      {"name": "Thiết kế hệ thống.docx", "uploader": "Minh", "date": "04/10/2025"},
      {"name": "CSDL.sql", "uploader": "Tuấn", "date": "03/10/2025"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tài liệu dự án",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_file),
          label: const Text("Tải lên tài liệu"),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: files
                .map((file) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(file["name"]!),
                subtitle:
                Text("Người đăng: ${file["uploader"]} - Ngày: ${file["date"]}"),
                trailing: const Icon(Icons.download),
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
