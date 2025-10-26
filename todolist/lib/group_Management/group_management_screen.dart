import 'package:flutter/material.dart';
import 'sections/group_list_section.dart';
import 'sections/group_detail_section.dart';
import 'sections/member_management_section.dart';
import 'sections/group_settings_section.dart';
import 'widgets/sidebar_menu.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  int _selectedIndex = 0;

  final List<String> _menuItems = [
    'Danh sách nhóm',
    'Chi tiết nhóm',
    'Thành viên nhóm',
    'Cài đặt nhóm',
  ];

  final List<Widget> _pages = const [
    GroupListSection(),
    GroupDetailSection(),
    MemberManagementSection(),
    GroupSettingsSection(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // đóng Drawer trên mobile
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
        title: Text(_menuItems[_selectedIndex]),
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
          items: _menuItems,
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        ),
      )
          : null,

      body: Row(
        children: [
          if (!isMobile)
            SidebarMenu(
              items: _menuItems,
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Container(
                key: ValueKey(_selectedIndex),
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(12),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
