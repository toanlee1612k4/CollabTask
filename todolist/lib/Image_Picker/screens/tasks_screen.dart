import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../widgets/task_detail_dialog.dart';

class TasksScreen extends StatefulWidget {
  final Project project;
  final VoidCallback onUpdate;

  const TasksScreen({super.key, required this.project, required this.onUpdate});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ImagePicker _picker = ImagePicker();

  List<DragAndDropList> _buildKanbanLists() {
    final statuses = ['Todo', 'InProgress', 'Done'];
    return statuses.map((status) {
      final items = widget.project.tasks.where((t) => t.status == status).toList();
      return DragAndDropList(
        header: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Center(child: Text(status == 'InProgress' ? 'In Progress' : status)),
        ),
        children: items.map((t) {
          return DragAndDropItem(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                title: Text(t.title, overflow: TextOverflow.ellipsis),
                subtitle: Text('${t.assignee.name} • ${t.progress}%'),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _openTaskDetail(t),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  Future<void> _openTaskDetail(TaskItem t) async {
    await showDialog(context: context, builder: (_) => TaskDetailDialog(task: t));
    widget.onUpdate();
  }

  void _onItemReorder(int oldListIndex, int oldItemIndex, int newListIndex, int newItemIndex) {
    final statuses = ['Todo', 'InProgress', 'Done'];
    final sourceStatus = statuses[oldListIndex];
    final targetStatus = statuses[newListIndex];
    final sourceTasks = widget.project.tasks.where((t) => t.status == sourceStatus).toList();
    final moved = sourceTasks[oldItemIndex];

    setState(() {
      moved.status = targetStatus;
      if (targetStatus == 'Done') moved.progress = 100;
      if (targetStatus == 'Todo') moved.progress = 0;
    });
    widget.onUpdate();
  }

  Future<void> _addTaskWithAttachment() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);

    if (!mounted) return;

    final titleCtr = TextEditingController();
    Member? assignee = widget.project.members.isNotEmpty ? widget.project.members.first : null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm công việc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtr, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              const SizedBox(height: 8),
              DropdownButton<Member>(
                isExpanded: true,
                value: assignee,
                items: widget.project.members
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => assignee = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final newTask = TaskItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtr.text.isEmpty ? 'Task mới' : titleCtr.text,
                description: '',
                assignee: assignee ?? widget.project.leader,
                deadline: DateTime.now().add(const Duration(days: 7)),
                status: 'Todo',
                progress: 0,
                attachments: file != null ? [File(file.path)] : [],
              );
              setState(() => widget.project.tasks.add(newTask));
              widget.onUpdate();
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kanban = DragAndDropLists(
      children: _buildKanbanLists(),
      onItemReorder: _onItemReorder,
      axis: Axis.horizontal,
      listWidth: 280,
      listDraggingWidth: 280,
      listPadding: const EdgeInsets.all(8),
      itemDecorationWhileDragging: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      onListReorder: (oldIndex, newIndex) {},
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Thanh tìm kiếm + nút thêm
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm kiếm task...',
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addTaskWithAttachment,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm công việc'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kanban chiếm toàn bộ phần còn lại
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: kanban,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
