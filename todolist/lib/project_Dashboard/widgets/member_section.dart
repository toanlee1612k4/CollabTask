import 'package:flutter/material.dart';

class MemberSection extends StatelessWidget {
  const MemberSection({super.key});

  @override
  Widget build(BuildContext context) {
    final members = [
      {"name": "Nguyễn Văn A", "role": "Leader"},
      {"name": "Trần Minh B", "role": "Member"},
      {"name": "Lê Văn C", "role": "Member"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thành viên dự án",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: members
                .map((m) => Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(m["name"]!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text(m["role"]!,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
