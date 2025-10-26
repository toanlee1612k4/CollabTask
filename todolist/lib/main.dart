import 'package:flutter/material.dart';
import 'models.dart';
import 'sidebar.dart';
import 'topbar.dart';
import '../../Image_Picker/screens/members_screen.dart';
import '../../Image_Picker/screens/tasks_screen.dart';
import '../../Image_Picker/screens/overview_screen.dart';
import '../../Image_Picker/screens/progress_screen.dart';
// Giả sử LoginScreen của bạn nằm ở đây, hãy chỉnh lại đường dẫn nếu cần
import 'authentications/screens/login_screen.dart';

void main() {
  runApp(const ProjectDashboardApp());
}

class ProjectDashboardApp extends StatelessWidget {
  const ProjectDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Dashboard',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      // Bắt đầu ứng dụng với LoginScreen của bạn
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- ĐỊNH NGHĨA LỚP DASHBOARD SHELL MÀ BẠN ĐANG CẦN ---

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  late Project project;

  // Khởi tạo dữ liệu mẫu cho ứng dụng
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final leader = Member(id: 'm1', name: 'Nguyễn Văn A', role: 'Leader', productivity: 80);
    final mem2 = Member(id: 'm2', name: 'Trần Thị B', role: 'Member', productivity: 60);
    final mem3 = Member(id: 'm3', name: 'Lê Văn C', role: 'Member', productivity: 50);

    final tasks = [
      TaskItem(
        id: 't1',
        title: 'Thiết kế UI',
        description: 'Hoàn thiện mockup, prototype',
        assignee: mem2,
        deadline: DateTime.now().add(const Duration(days: 5)),
        status: 'Todo',
        progress: 20,
      ),
      TaskItem(
        id: 't2',
        title: 'Xây dựng API',
        description: 'Auth & User endpoints',
        assignee: mem3,
        deadline: DateTime.now().add(const Duration(days: 10)),
        status: 'InProgress',
        progress: 50,
      ),
      TaskItem(
        id: 't3',
        title: 'Test e2e',
        description: 'Viết test case cho flows chính',
        assignee: mem2,
        deadline: DateTime.now().add(const Duration(days: 15)),
        status: 'Done',
        progress: 100,
      ),
    ];

    project = Project(
      name: 'GadHub',
      description: 'Ứng dụng quản lý cửa hàng thiết bị công nghệ',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      deadline: DateTime.now().add(const Duration(days: 60)),
      leader: leader,
      members: [leader, mem2, mem3],
      tasks: tasks,
    );
  }

  void _onNavSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      OverviewScreen(project: project, onUpdate: _updateState),
      TasksScreen(project: project, onUpdate: _updateState),
      MembersScreen(project: project, onUpdate: _updateState),
      ProgressScreen(project: project),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(selectedIndex: _selectedIndex, onTap: _onNavSelected, project: project),
            Expanded(
              child: Column(
                children: [
                  const Topbar(),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

