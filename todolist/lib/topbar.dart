import 'package:flutter/material.dart';

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const Topbar({super.key, this.title = "Project Dashboard"});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 400; // responsive

    return AppBar(
      backgroundColor: Colors.grey.shade100,
      foregroundColor: Colors.black87,
      elevation: 1,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isNarrow ? 14 : 16,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      centerTitle: false,

      // leading auto ẩn khi không có drawer
      leading: Scaffold.maybeOf(context)?.hasDrawer == true
          ? Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      )
          : null,

      actions: [
        // 🔍 Search
        IconButton(
          onPressed: () {
            // TODO: search
          },
          tooltip: 'Search',
          icon: const Icon(Icons.search),
        ),

        // ➕ New Task
        if (isNarrow)
          IconButton(
            onPressed: () {
              // TODO: thêm task
            },
            tooltip: 'New Task',
            icon: const Icon(Icons.add),
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              // TODO: thêm task
            },
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),

        // 🔔 Notifications
        IconButton(
          onPressed: () {
            // TODO: thông báo
          },
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
