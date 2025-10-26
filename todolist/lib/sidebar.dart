import 'package:flutter/material.dart';
import 'models.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final Project project;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth < 600; // nếu nhỏ thì thu gọn sidebar

    return Container(
      width: isCollapsed ? 70 : 200,
      color: Colors.blueGrey.shade900,
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Logo / Avatar
          CircleAvatar(
            radius: isCollapsed ? 20 : 30,
            backgroundColor: Colors.blueGrey.shade700,
            child: const Icon(Icons.dashboard, color: Colors.white),
          ),

          const SizedBox(height: 20),

          // Danh sách menu
          Expanded(
            child: ListView(
              children: [
                _buildButton(Icons.dashboard, 'Tổng quan', 0, isCollapsed),
                _buildButton(Icons.task, 'Công việc', 1, isCollapsed),
                _buildButton(Icons.group, 'Thành viên', 2, isCollapsed),
                _buildButton(Icons.bar_chart, 'Tiến độ', 3, isCollapsed),
              ],
            ),
          ),

          // Thông tin dự án
          if (!isCollapsed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                border: Border(
                  top: BorderSide(color: Colors.blueGrey.shade700),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dự án:", style: TextStyle(color: Colors.white70)),
                  Text(
                    project.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String text, int index, bool collapsed) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: collapsed
          ? null
          : Text(text, style: const TextStyle(color: Colors.white)),
      selected: selectedIndex == index,
      selectedTileColor: Colors.blueGrey.shade700,
      onTap: () => onTap(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      horizontalTitleGap: collapsed ? 0 : 16,
    );
  }
}
