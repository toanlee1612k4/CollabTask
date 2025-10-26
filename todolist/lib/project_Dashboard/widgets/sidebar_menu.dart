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
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.dashboard, 'title': 'Tổng quan'},
      {'icon': Icons.task_alt, 'title': 'Công việc'},
      {'icon': Icons.group, 'title': 'Thành viên'},
      {'icon': Icons.timeline, 'title': 'Tiến độ'},
      {'icon': Icons.folder, 'title': 'Tài liệu'},
    ];

    return Container(
      width: 230,
      color: Colors.blue.shade700,
      child: Column(
        children: [
          Container(
            height: 90,
            alignment: Alignment.center,
            child: const Text(
              "PROJECT DASHBOARD",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = index == selectedIndex;
                return ListTile(
                  leading: Icon(item['icon'],
                      color: isSelected ? Colors.white : Colors.white70),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.blue.shade600,
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
