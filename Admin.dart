import 'package:flutter/material.dart';

void main() {
  runApp(TaskManagementApp());
}

class TaskManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Task Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum MenuItem { dashboard, projects, groups, users, reports }

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  MenuItem selectedMenu = MenuItem.dashboard;

  // Slide panel data
  Widget? slidePanelContent;

  void openSlidePanel(Widget content) {
    setState(() {
      slidePanelContent = content;
    });
  }

  void closeSlidePanel() {
    setState(() {
      slidePanelContent = null;
    });
  }

  // Modal helpers
  void showCreateProjectModal() {
    showDialog<void>( // Explicit type argument
      context: context,
      builder: (BuildContext context) => CreateEditProjectModal( // Explicit type argument
        onSave: (String projectName) {
          // Handle save project
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Project "$projectName" created')));
        },
      ),
    );
  }

  void showCreateTaskModal(String projectName) {
    showDialog<void>( // Explicit type argument
      context: context,
      builder: (BuildContext context) => CreateTaskModal( // Explicit type argument
        projectName: projectName,
        onSave: (String taskName) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task "$taskName" added to $projectName')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          // FIX: Wrap NavigationRail in SingleChildScrollView to prevent overflow
          SingleChildScrollView(
            child: ConstrainedBox( // Constrain to screen height, allowing content to scroll within
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: IntrinsicHeight( // Allow NavigationRail to determine its natural height
                child: NavigationRail(
                  selectedIndex: MenuItem.values.indexOf(selectedMenu),
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedMenu = MenuItem.values[index];
                      slidePanelContent = null; // Close slide panel on menu change
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const <NavigationRailDestination>[ // Explicit type argument
                    NavigationRailDestination(
                        icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                    NavigationRailDestination(
                        icon: Icon(Icons.folder), label: Text('Projects')),
                    NavigationRailDestination(
                        icon: Icon(Icons.group), label: Text('Groups')),
                    NavigationRailDestination(
                        icon: Icon(Icons.person), label: Text('Users')),
                    NavigationRailDestination(
                        icon: Icon(Icons.bar_chart), label: Text('Reports')),
                  ],
                ),
              ),
            ),
          ),

          // Vertical divider between sidebar and main content
          const VerticalDivider(thickness: 1, width: 1), // Added const

          // Main content area takes remaining width minus slide panel width
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60,
                  color: Colors.blueGrey[50],
                  padding: const EdgeInsets.symmetric(horizontal: 16), // Added const
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Admin Dashboard - ${selectedMenu.name.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700]),
                  ),
                ),

                // Content body
                Expanded(
                  child: Row(
                    children: [
                      // Left side: list / table / charts
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.white,
                          child: _buildMainContent(selectedMenu),
                        ),
                      ),

                      // Slide panel right side (detail)
                      if (slidePanelContent != null)
                        Container(
                          width: 360,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            boxShadow: const <BoxShadow>[ // Added const
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                color: Colors.blueGrey[100],
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Padding( // Added const
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        'Details',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close), // Added const
                                      onPressed: closeSlidePanel,
                                    )
                                  ],
                                ),
                              ),
                              Expanded(child: slidePanelContent!),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(MenuItem menu) {
    switch (menu) {
      case MenuItem.dashboard:
        return DashboardContent(onTaskTap: (String taskId) {
          openSlidePanel(TaskDetailPanel(taskId: taskId));
        });
      case MenuItem.projects:
        return ProjectsContent(
          onProjectTap: (Project project) {
            openSlidePanel(ProjectDetailPanel(
              projectName: project.name,
              onAddTask: () {
                showCreateTaskModal(project.name);
              },
              onEditProject: () {
                showDialog<void>( // Explicit type argument
                  context: context,
                  builder: (BuildContext context) => CreateEditProjectModal( // Explicit type argument
                    projectName: project.name,
                    onSave: (String newName) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Project "$newName" updated')));
                    },
                  ),
                );
              },
            ));
          },
          onCreateProject: showCreateProjectModal,
        );
      case MenuItem.groups:
        return GroupsContent(
          onGroupTap: (Group group) {
            openSlidePanel(GroupDetailPanel(groupName: group.name));
          },
        );
      case MenuItem.users:
        return UsersContent(
          onUserTap: (User user) {
            openSlidePanel(UserDetailPanel(userName: user.name));
          },
        );
      case MenuItem.reports:
        return ReportsContent();
      default:
        return const Center(child: Text('Not implemented')); // Added const
    }
  }
}

// ---------------------
// Models for demo data

class Project {
  final String name;
  final String owner;
  final int membersCount;
  final int taskCount;
  final int progressPercent;

  Project(this.name, this.owner, this.membersCount, this.taskCount,
      this.progressPercent);
}

class Group {
  final String name;
  final int membersCount;
  final int taskCount;

  Group(this.name, this.membersCount, this.taskCount);
}

class User {
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime lastActive;
  final int taskCount;

  User(this.name, this.email, this.role, this.status, this.lastActive,
      this.taskCount);
}

// ---------------------
// Dashboard content with KPIs, charts, recent activities (simplified)

class DashboardContent extends StatelessWidget {
  final void Function(String taskId) onTaskTap;
  DashboardContent({required this.onTaskTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16), // Added const
      child: Column(
        children: [
          // KPI cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _KpiCard(
                  title: 'Tổng số task',
                  value: '120',
                  onTap: () {
                    // Example filter action
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter tasks: Tổng số task'))); // Added const
                  }),
              _KpiCard(
                  title: 'Task trễ hạn',
                  value: '15',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter tasks: Task trễ hạn'))); // Added const
                  }),
              _KpiCard(
                  title: '% Hoàn thành',
                  value: '85%',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter tasks: % Hoàn thành'))); // Added const
                  }),
              _KpiCard(
                  title: 'Thời gian trung bình',
                  value: '3.2 ngày',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar( // Added const
                        content: Text('Filter tasks: Thời gian trung bình')));
                  }),
            ],
          ),

          const SizedBox(height: 20), // Added const

          // Placeholder charts area
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Card(
                      child: Center(
                          child: Text('Donut chart (Task trạng thái)',
                              style: TextStyle(color: Colors.grey)))),
                ),
                Expanded(
                  child: Card(
                      child: Center(
                          child: Text('Bar chart (Task theo user)',
                              style: TextStyle(color: Colors.grey)))),
                ),
                Expanded(
                  child: Card(
                      child: Center(
                          child: Text('Line chart (Task theo tuần)',
                              style: TextStyle(color: Colors.grey)))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // Added const

          // Recent activities list
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding( // Added const
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Hoạt động gần nhất',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: List.generate(10, (int index) {
                        final String taskId = 'task_$index';
                        return ListTile(
                          title: Text('Hoạt động $index'),
                          subtitle: Text('Mô tả chi tiết hoạt động $index'),
                          onTap: () => onTaskTap(taskId),
                        );
                      }),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  _KpiCard({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(12), // Added const
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Add maxLines and overflow to text to prevent vertical overflow
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), // Added const
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(), // Added const
                // FIX: Add maxLines and overflow to text to prevent vertical overflow
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Added const
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------
// Projects content with list and actions

class ProjectsContent extends StatelessWidget {
  final void Function(Project project) onProjectTap;
  final VoidCallback onCreateProject;

  ProjectsContent({required this.onProjectTap, required this.onCreateProject});

  final List<Project> projects = List.generate(
      10,
      (int index) => Project('Project $index', 'Owner $index', 5 + index, 20 + index,
          (index + 1) * 10));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Added const
      child: Column(
        children: [
          // Search and create button
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm dự án...',
                    prefixIcon: const Icon(Icons.search), // Added const
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Added const
              ElevatedButton.icon(
                icon: const Icon(Icons.add), // Added const
                label: const Text('Tạo dự án'), // Added const
                onPressed: onCreateProject,
              ),
            ],
          ),
          const SizedBox(height: 12), // Added const

          // Projects Table header
          Container(
            color: Colors.blueGrey[50],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Added const
            child: Row(
              children: const <Widget>[ // Added const and explicit type argument
                Expanded(flex: 3, child: Text('Tên dự án', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Chủ dự án', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Thành viên', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Số task', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Tiến độ %', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (BuildContext context, int index) {
                final Project p = projects[index];
                return InkWell(
                  onTap: () => onProjectTap(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Added const
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(p.name)),
                        Expanded(flex: 2, child: Text(p.owner)),
                        Expanded(flex: 1, child: Text('${p.membersCount}')),
                        Expanded(flex: 1, child: Text('${p.taskCount}')),
                        Expanded(flex: 1, child: Text('${p.progressPercent}%')),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20), // Added const
                                onPressed: () {
                                  // Prevent tap propagation by not calling onProjectTap directly here if it opens the same panel
                                  // As per the original code's intent, it first opens the panel, then calls edit modal.
                                  onProjectTap(p);
                                  // then call edit modal
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20), // Added const
                                onPressed: () {
                                  // Show confirm dialog for delete
                                  showDialog<void>( // Explicit type argument
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Xoá dự án'), // Added const
                                          content: Text(
                                              'Bạn có chắc muốn xoá dự án "${p.name}"?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Huỷ')), // Added const
                                            ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'Đã xoá dự án "${p.name}"')));
                                                },
                                                child: const Text('Xoá')), // Added const
                                          ],
                                        );
                                      });
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Modal for Create/Edit Project
class CreateEditProjectModal extends StatefulWidget {
  final String? projectName;
  final void Function(String projectName) onSave;

  CreateEditProjectModal({this.projectName, required this.onSave});

  @override
  _CreateEditProjectModalState createState() => _CreateEditProjectModalState();
}

class _CreateEditProjectModalState extends State<CreateEditProjectModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.projectName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.projectName == null ? 'Tạo dự án' : 'Sửa dự án'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Tên dự án'), // Added const
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên dự án';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(_nameController.text.trim());
              }
            },
            child: const Text('Lưu')), // Added const
      ],
    );
  }
}

// Modal for Create Task (simplified)
class CreateTaskModal extends StatefulWidget {
  final String projectName;
  final void Function(String taskName) onSave;

  CreateTaskModal({required this.projectName, required this.onSave});

  @override
  _CreateTaskModalState createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController(); // Added final

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thêm task cho dự án "${widget.projectName}"'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _taskNameController,
          decoration: const InputDecoration(labelText: 'Tên task'), // Added const
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên task';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(_taskNameController.text.trim());
              }
            },
            child: const Text('Lưu')), // Added const
      ],
    );
  }
}

// Slide panel for Project details
class ProjectDetailPanel extends StatelessWidget {
  final String projectName;
  final VoidCallback onAddTask;
  final VoidCallback onEditProject;

  ProjectDetailPanel(
      {required this.projectName,
      required this.onAddTask,
      required this.onEditProject});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demo
    final List<String> members = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C'];
    final List<String> tasks = ['Task 1', 'Task 2', 'Task 3'];

    // FIX: Wrap Column in SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12), // Added const
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(projectName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Added const
            const SizedBox(height: 10), // Added const
            Text('Mô tả dự án: Đây là mô tả chi tiết về dự án $projectName.'),
            const SizedBox(height: 20), // Added const
            const Text('Thành viên:', style: TextStyle(fontWeight: FontWeight.bold)), // Added const
            ...members.map<Widget>((String m) => ListTile(
                  leading: const Icon(Icons.person), // Added const
                  title: Text(m),
                )).toList(),
            const SizedBox(height: 20), // Added const
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách task', // Added const
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add), // Added const
                  label: const Text('Thêm task'), // Added const
                  onPressed: onAddTask,
                )
              ],
            ),
            ...tasks.map<Widget>((String t) => ListTile(
                  leading: const Icon(Icons.task), // Added const
                  title: Text(t),
                )).toList(),
            const SizedBox(height: 20), // Replaced Spacer with SizedBox
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit), // Added const
                label: const Text('Sửa dự án'), // Added const
                onPressed: onEditProject,
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------
// Groups content example

class GroupsContent extends StatelessWidget {
  final void Function(Group group) onGroupTap;

  GroupsContent({required this.onGroupTap});

  final List<Group> groups = List.generate(
      7, (int index) => Group('Group $index', 3 + index, 10 + index * 2));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Added const
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm nhóm...',
              prefixIcon: const Icon(Icons.search), // Added const
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12), // Added const
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (BuildContext context, int index) {
                final Group g = groups[index];
                return ListTile(
                  title: Text(g.name),
                  subtitle:
                      Text('${g.membersCount} thành viên - ${g.taskCount} task'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18), // Added const
                  onTap: () => onGroupTap(g),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Slide panel for Group details
class GroupDetailPanel extends StatelessWidget {
  final String groupName;

  GroupDetailPanel({required this.groupName});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demo
    final List<Map<String, String>> members = [
      {'name': 'Nguyễn Văn A', 'role': 'Leader'},
      {'name': 'Trần Thị B', 'role': 'Member'}
    ];
    final List<String> tasks = ['Task A', 'Task B'];

    // FIX: Wrap Column in SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12), // Added const
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Added const
            const SizedBox(height: 10), // Added const
            const Text('Danh sách thành viên:', style: TextStyle(fontWeight: FontWeight.bold)), // Added const
            ...members.map<Widget>((Map<String, String> m) => ListTile(
                  leading: const Icon(Icons.person), // Added const
                  title: Text(m['name']!),
                  subtitle: Text('Vai trò: ${m['role']}'),
                )).toList(),
            const SizedBox(height: 20), // Added const
            const Text('Danh sách task:', style: TextStyle(fontWeight: FontWeight.bold)), // Added const
            ...tasks.map<Widget>((String t) => ListTile(
                  leading: const Icon(Icons.task), // Added const
                  title: Text(t),
                )).toList(),
            const SizedBox(height: 20), // Replaced Spacer with SizedBox
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                child: const Text('Giao task cho nhóm'), // Added const
                onPressed: () {
                  showDialog<void>( // Explicit type argument
                      context: context,
                      builder: (BuildContext context) => AssignTaskToGroupModal(groupName: groupName)); // Explicit type argument
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Modal assign task to group
class AssignTaskToGroupModal extends StatefulWidget {
  final String groupName;

  AssignTaskToGroupModal({required this.groupName});

  @override
  _AssignTaskToGroupModalState createState() => _AssignTaskToGroupModalState();
}

class _AssignTaskToGroupModalState extends State<AssignTaskToGroupModal> {
  bool assignToWholeGroup = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Giao task cho nhóm "${widget.groupName}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<bool>(
            title: const Text('Giao task cho cả nhóm (chung 1 task)'), // Added const
            value: true,
            groupValue: assignToWholeGroup,
            onChanged: (bool? val) => setState(() => assignToWholeGroup = val!),
          ),
          RadioListTile<bool>(
            title: const Text('Giao task cho từng thành viên (mỗi người 1 bản copy)'), // Added const
            value: false,
            groupValue: assignToWholeGroup,
            onChanged: (bool? val) => setState(() => assignToWholeGroup = val!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(assignToWholeGroup
                      ? 'Đã giao task cho cả nhóm'
                      : 'Đã giao task cho từng thành viên')));
            },
            child: const Text('Xác nhận')), // Added const
      ],
    );
  }
}

// ---------------------
// Users content example

class UsersContent extends StatelessWidget {
  final void Function(User user) onUserTap;

  UsersContent({required this.onUserTap});

  final List<User> users = List.generate(
      10,
      (int index) => User('User $index', 'user$index@example.com', 'Member',
          index % 2 == 0 ? 'Active' : 'Inactive', DateTime.now(), 5 + index));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Added const
      child: Column(
        children: [
          // Search and filter row simplified
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm người dùng...',
              prefixIcon: const Icon(Icons.search), // Added const
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12), // Added const
          Expanded(
            child: ListView(
              children: users
                  .map<Widget>(
                    (User u) => ListTile(
                      leading: CircleAvatar(child: Text(u.name[0])),
                      title: Text(u.name),
                      subtitle: Text('${u.email} - Vai trò: ${u.role}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18), // Added const
                      onTap: () => onUserTap(u),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Slide panel for User details
class UserDetailPanel extends StatelessWidget {
  final String userName;

  UserDetailPanel({required this.userName});

  @override
  Widget build(BuildContext context) {
    // Dummy user task list
    final List<String> tasks = ['Task 1', 'Task 2', 'Task 3'];

    // FIX: Wrap Column in SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12), // Added const
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Added const
            const SizedBox(height: 10), // Added const
            Text('Thông tin cá nhân và vai trò người dùng $userName.'),
            const SizedBox(height: 20), // Added const
            const Text('Task đã giao:', style: TextStyle(fontWeight: FontWeight.bold)), // Added const
            ...tasks.map<Widget>((String t) => ListTile(
                  leading: const Icon(Icons.task), // Added const
                  title: Text(t),
                )).toList(),
            const SizedBox(height: 20), // Added const
            ElevatedButton(
              child: const Text('Đổi vai trò'), // Added const
              onPressed: () {
                showDialog<void>( // Explicit type argument
                    context: context,
                    builder: (BuildContext context) => ChangeUserRoleModal(userName: userName)); // Explicit type argument
              },
            ),
            const SizedBox(height: 10), // Added spacing between buttons
            ElevatedButton(
              child: const Text('Khoá tài khoản'), // Added const
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                showDialog<void>( // Explicit type argument
                    context: context,
                    builder: (BuildContext context) => LockUserConfirmModal(userName: userName)); // Explicit type argument
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Modal change user role
class ChangeUserRoleModal extends StatefulWidget {
  final String userName;

  ChangeUserRoleModal({required this.userName});

  @override
  _ChangeUserRoleModalState createState() => _ChangeUserRoleModalState();
}

class _ChangeUserRoleModalState extends State<ChangeUserRoleModal> {
  String selectedRole = 'Member';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đổi vai trò cho ${widget.userName}'),
      content: DropdownButtonFormField<String>(
        value: selectedRole,
        items: ['Admin', 'Member', 'Guest']
            .map<DropdownMenuItem<String>>((String r) => DropdownMenuItem<String>(value: r, child: Text(r)))
            .toList(),
        onChanged: (String? val) {
          setState(() {
            selectedRole = val!;
          });
        },
        decoration: const InputDecoration(labelText: 'Chọn vai trò'), // Added const
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã đổi vai trò thành $selectedRole')));
            },
            child: const Text('Lưu')), // Added const
      ],
    );
  }
}

// Modal lock user confirm
class LockUserConfirmModal extends StatelessWidget {
  final String userName;

  LockUserConfirmModal({required this.userName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Khoá tài khoản'), // Added const
      content: Text('Bạn có chắc muốn khoá tài khoản "$userName"?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã khoá tài khoản $userName')));
            },
            child: const Text('Xác nhận')), // Added const
      ],
    );
  }
}

// ---------------------
// Reports content example

class ReportsContent extends StatefulWidget {
  @override
  _ReportsContentState createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  // Filters (simplified)
  DateTimeRange? selectedDateRange;
  String? selectedGroup;
  String? selectedUser;
  String? selectedProject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Added const
      child: Column(
        children: [
          // Filter bar simplified
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.date_range), // Added const
                  label: Text(selectedDateRange == null
                      ? 'Chọn ngày'
                      : '${selectedDateRange!.start.toLocal().toIso8601String().split('T')[0]} - ${selectedDateRange!.end.toLocal().toIso8601String().split('T')[0]}'),
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDateRange = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8), // Added const
              // Placeholder dropdowns for group/user/project
              _buildDropdown('Nhóm', ['Nhóm 1', 'Nhóm 2'], selectedGroup,
                  (String? val) {
                setState(() {
                  selectedGroup = val;
                });
              }),
              const SizedBox(width: 8), // Added const
              _buildDropdown('User', ['User 1', 'User 2'], selectedUser, (String? val) {
                setState(() {
                  selectedUser = val;
                });
              }),
              const SizedBox(width: 8), // Added const
              _buildDropdown(
                  'Dự án', ['Dự án 1', 'Dự án 2'], selectedProject, (String? val) {
                setState(() {
                  selectedProject = val;
                });
              }),
            ],
          ),
          const SizedBox(height: 12), // Added const

          // Placeholder charts
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Card(
                        child: Center(
                            child: Text('Biểu đồ cột',
                                style: TextStyle(color: Colors.grey))))),
                Expanded(
                    child: Card(
                        child: Center(
                            child: Text('Biểu đồ đường',
                                style: TextStyle(color: Colors.grey))))),
                Expanded(
                    child: Card(
                        child: Center(
                            child: Text('Biểu đồ tròn',
                                style: TextStyle(color: Colors.grey))))),
              ],
            ),
          ),

          const SizedBox(height: 12), // Added const

          // Data table (simplified)
          Expanded(
            child: Card(
              child: ListView(
                children: List.generate(
                  15,
                  (int index) => ListTile(
                    title: Text('Dữ liệu báo cáo $index'),
                    subtitle: Text('Chi tiết dữ liệu $index'),
                    onTap: () {
                      // On chart column click filter data example
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Lọc dữ liệu theo cột báo cáo $index')));
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12), // Added const

          ElevatedButton.icon(
            icon: const Icon(Icons.download), // Added const
            label: const Text('Xuất báo cáo'), // Added const
            onPressed: () {
              showDialog<void>( // Explicit type argument
                  context: context,
                  builder: (BuildContext context) => ExportReportModal()); // Explicit type argument
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected,
      ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: selected,
        items:
            items.map<DropdownMenuItem<String>>((String e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Export report modal
class ExportReportModal extends StatefulWidget {
  @override
  _ExportReportModalState createState() => _ExportReportModalState();
}

class _ExportReportModalState extends State<ExportReportModal> {
  String? selectedFormat;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xuất báo cáo'), // Added const
      content: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Chọn định dạng file'), // Added const
        items: ['CSV', 'Excel', 'PDF']
            .map<DropdownMenuItem<String>>((String e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: (String? val) {
          setState(() {
            selectedFormat = val;
          });
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')), // Added const
        ElevatedButton(
            onPressed: selectedFormat == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Báo cáo đã được xuất dưới định dạng $selectedFormat')));
                  },
            child: const Text('Xuất')), // Added const
      ],
    );
  }
}

// ---------------------
// Task detail slide panel example (used in Dashboard recent activities)

class TaskDetailPanel extends StatelessWidget {
  final String taskId;

  TaskDetailPanel({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12), // Added const
      child: SingleChildScrollView( // FIX: Added SingleChildScrollView to prevent overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết Task $taskId',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Added const
            const SizedBox(height: 10), // Added const
            const Text('Mô tả chi tiết task...'), // Added const
            const SizedBox(height: 20), // Added const
            const Text('Trạng thái: Đang thực hiện'), // Added const
            const Text('Người phụ trách: Nguyễn Văn A'), // Added const
            const Text('Deadline: 2024-07-01'), // Added const
            const SizedBox(height: 20), // Add some spacing at the bottom
          ],
        ),
      ),
    );
  }
}