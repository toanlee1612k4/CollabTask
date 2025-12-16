import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/presentation/widgets/navigation/app_sidebar.dart';
import 'package:todolist/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:todolist/presentation/screens/workspace/workspaces_screen.dart';
import 'package:todolist/presentation/screens/calendar/personal_calendar_screen.dart';
import 'package:todolist/presentation/screens/tasks/completed_tasks_screen.dart';
import 'package:todolist/presentation/screens/tasks/overdue_tasks_screen.dart';
import 'package:todolist/presentation/screens/settings/profile_settings_screen.dart';
import 'package:todolist/presentation/screens/workspace/workspace_invitations_screen.dart';

/// Main layout with responsive sidebar navigation
class AppLayout extends StatefulWidget {
  final int initialIndex;
  
  const AppLayout({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late int _selectedIndex;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const WorkspacesScreen(),
    const PersonalCalendarScreen(),
    const CompletedTasksScreen(),
    const OverdueTasksScreen(),
    const WorkspaceInvitationsScreen(),
    const ProfileSettingsScreen(),
    const HelpPlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? AppSidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context); // Close drawer
        },
        isCollapsed: false,
        onToggleCollapse: () {},
      ) : null,
      body: Row(
        children: [
          // Desktop sidebar
          if (!isMobile)
            AppSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top app bar for mobile
                if (isMobile) _buildMobileAppBar(),
                
                // Screen content
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0747A6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 12),
              Text(
                'CollabTask',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Notifications
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Thông báo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder screens
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpPlaceholderScreen extends StatelessWidget {
  const HelpPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Help & Support',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
