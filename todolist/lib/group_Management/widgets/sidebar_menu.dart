import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.blueGrey.shade900,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Quản lý nhóm',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...List.generate(items.length, (index) {
            final bool selected = index == selectedIndex;
            return InkWell(
              onTap: () => onItemSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: selected ? Colors.white : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      items[index],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey.shade300,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
