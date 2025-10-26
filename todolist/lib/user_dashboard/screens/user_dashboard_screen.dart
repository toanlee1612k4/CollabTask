import 'package:flutter/material.dart';
import '../../user_dashboard/sections/home_section.dart';
import '../../user_dashboard/sections/my_group_section.dart';
import '../../user_dashboard/sections/my_project_section.dart';
import '../../user_dashboard/sections/report_section.dart';
import '../../user_dashboard/sections/settings_section.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> menuTitles = [
    'Trang chủ',
    'Nhóm của tôi',
    'Dự án của tôi',
    'Báo cáo',
    'Cài đặt',
  ];

  final List<IconData> menuIcons = [
    Icons.home,
    Icons.group,
    Icons.folder,
    Icons.bar_chart,
    Icons.settings,
  ];

  final List<Widget> pages = const [
    HomeSection(),
    MyGroupSection(),
    MyProjectSection(),
    ReportSection(),
    SettingsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
        title: const Text('Bảng điều khiển người dùng'),
        backgroundColor: Colors.blueAccent,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      )
          : null,
      endDrawer: isMobile
          ? Drawer(
        child: ListView.builder(
          itemCount: menuTitles.length,
          itemBuilder: (context, index) => ListTile(
            leading: Icon(menuIcons[index]),
            title: Text(menuTitles[index]),
            selected: _selectedIndex == index,
            selectedColor: Colors.blue,
            onTap: () {
              setState(() => _selectedIndex = index);
              Navigator.pop(context);
            },
          ),
        ),
      )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              backgroundColor: Colors.grey.shade100,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: List.generate(
                menuTitles.length,
                    (index) => NavigationRailDestination(
                  icon: Icon(menuIcons[index]),
                  selectedIcon:
                  Icon(menuIcons[index], color: Colors.blueAccent),
                  label: Text(menuTitles[index]),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
