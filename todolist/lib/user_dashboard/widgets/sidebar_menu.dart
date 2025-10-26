import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home, 'label': 'Trang chủ'},
      {'icon': Icons.group, 'label': 'Nhóm của tôi'},
      {'icon': Icons.work, 'label': 'Dự án của tôi'},
      {'icon': Icons.bar_chart, 'label': 'Báo cáo'},
      {'icon': Icons.settings, 'label': 'Cài đặt'},
    ];

    return Container(
      color: Colors.blueGrey.shade50,
      width: 250,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
          const SizedBox(height: 12),
          const Text('Xin chào, Duy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return ListTile(
                  leading: Icon(item['icon'] as IconData,
                      color: isSelected ? Colors.blue : Colors.grey.shade700),
                  title: Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
