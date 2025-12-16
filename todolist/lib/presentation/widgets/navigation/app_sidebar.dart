import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_constants.dart';

/// Responsive navigation sidebar for the entire app
class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    
    // On mobile, sidebar should be a drawer
    if (isMobile) {
      return Drawer(
        child: _buildSidebarContent(context, false),
      );
    }
    
    // On desktop/tablet, permanent sidebar
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 80 : 240,
      child: _buildSidebarContent(context, isCollapsed),
    );
  }

  Widget _buildSidebarContent(BuildContext context, bool collapsed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6C63FF), // Purple
            Color(0xFF5B4FFF), // Darker purple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with logo
          _buildHeader(collapsed),
          
          const SizedBox(height: 24),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.workspaces_rounded,
                  label: 'Workspaces',
                  index: 1,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.calendar_month_rounded,
                  label: 'Lịch của tôi',
                  index: 2,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.check_circle_rounded,
                  label: 'Đã hoàn thành',
                  index: 3,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  label: 'Quá hạn',
                  index: 4,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.mail_outline,
                  label: 'Lời mời',
                  index: 5,
                  collapsed: collapsed,
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                
                _buildNavItem(
                  context: context,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 6,
                  collapsed: collapsed,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.help_rounded,
                  label: 'Help',
                  index: 7,
                  collapsed: collapsed,
                ),
              ],
            ),
          ),
          
          // Collapse toggle button
          _buildCollapseButton(collapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(bool collapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Color(0xFF6C63FF),
              size: 24,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CollabTask',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'AI-Powered',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool collapsed,
  }) {
    final isSelected = selectedIndex == index;
    
    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(bool collapsed) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Tooltip(
        message: collapsed ? 'Mở rộng' : 'Thu gọn',
        child: InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              collapsed 
                  ? Icons.keyboard_arrow_right 
                  : Icons.keyboard_arrow_left,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
