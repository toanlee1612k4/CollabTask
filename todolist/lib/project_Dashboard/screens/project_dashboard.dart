import 'package:flutter/material.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/overview_section.dart';
import '../widgets/task_section.dart';
import '../widgets/member_section.dart';
import '../widgets/progress_section.dart';
import '../widgets/document_section.dart';

class ProjectDashboard extends StatefulWidget {
  const ProjectDashboard({super.key});

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

class _ProjectDashboardState extends State<ProjectDashboard> {
  int selectedIndex = 0;

  final List<String> menuItems = [
    "Tổng quan",
    "Công việc",
    "Thành viên",
    "Tiến độ",
    "Tài liệu",
  ];

  void _onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.pop(context); // đóng drawer khi chọn trên mobile
  }

  Widget _buildSelectedContent() {
    switch (selectedIndex) {
      case 0:
        return const OverviewSection();
      case 1:
        return const TaskSection();
      case 2:
        return const MemberSection();
      case 3:
        return const ProgressSection();
      case 4:
        return const DocumentSection();
      default:
        return const OverviewSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
        title: Text(menuItems[selectedIndex]),
        backgroundColor: Colors.blue.shade700,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      )
          : null,
      drawer: isMobile
          ? Drawer(
        child: SidebarMenu(
          selectedIndex: selectedIndex,
          onItemSelected: _onItemSelected,
        ),
      )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SidebarMenu(
              selectedIndex: selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: _buildSelectedContent(),
            ),
          ),
        ],
      ),
    );
  }
}
