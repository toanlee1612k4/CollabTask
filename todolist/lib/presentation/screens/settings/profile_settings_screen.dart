import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/core/theme/theme_provider.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

/// Profile Settings Screen
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  UserModel? _currentUser;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _error;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUserStats();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _apiClient.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Load both productivity stats and workspace/task counts
      final productivityStats = await _apiClient.getUserStats();
      final workspaces = await _apiClient.getWorkspaces();
      final myTasksResult = await _apiClient.getMyTasks(page: 1, pageSize: 1); // Just get totalCount
      
      // Get current user ID to determine ownership
      final currentUser = await _apiClient.getCurrentUser();
      
      if (mounted) {
        setState(() {
          _userStats = {
            // Productivity stats
            'totalTasksCompleted': productivityStats['totalTasksCompleted'] ?? 0,
            'onTimeCompletionRate': productivityStats['onTimeCompletionRate'] ?? 0.0,
            'currentStreak': productivityStats['currentStreak'] ?? 0,
            
            // Workspace/task counts
            'totalTasks': myTasksResult.totalCount,
            'totalWorkspaces': workspaces.length,
            'ownedWorkspaces': workspaces.where((w) => w.ownerId == currentUser.userId).length,
            'memberWorkspaces': workspaces.where((w) => w.ownerId != currentUser.userId).length,
          };
        });
      }
    } catch (e) {
      print('⚠️ Could not load user stats: $e');
      // Set default values to prevent null errors
      if (mounted) {
        setState(() {
          _userStats = {
            'totalTasksCompleted': 0,
            'onTimeCompletionRate': 0.0,
            'currentStreak': 0,
            'totalTasks': 0,
            'totalWorkspaces': 0,
            'ownedWorkspaces': 0,
            'memberWorkspaces': 0,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Text('Error: $_error'),
              ),
            )
          else if (_currentUser != null) ...[
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverToBoxAdapter(child: _buildProfileInfo()),
            SliverToBoxAdapter(child: _buildPreferences()),
            SliverToBoxAdapter(child: _buildDangerZone()),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Edit profile
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Profile',
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (_currentUser!.fullName ?? 'U').substring(0, (_currentUser!.fullName?.length ?? 1) > 1 ? 2 : 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _currentUser!.fullName ?? 'User',
            style: GoogleFonts.inter(
              fontSize: AppTypography.headlineMedium,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            _currentUser!.email,
            style: GoogleFonts.inter(
              fontSize: AppTypography.bodyMedium,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê',
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Stats Grid
            if (_userStats != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.task_alt,
                      value: (_userStats!['totalTasks'] ?? 0).toString(),
                      label: 'Total Tasks',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      value: (_userStats!['totalTasksCompleted'] ?? 0).toString(),
                      label: 'Completed',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.workspaces,
                      value: (_userStats!['totalWorkspaces'] ?? 0).toString(),
                      label: 'Workspaces',
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      value: (_userStats!['ownedWorkspaces'] ?? 0).toString(),
                      label: 'Owner',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer,
                      value: '${(_userStats!['onTimeCompletionRate'] ?? 0).toInt()}%',
                      label: 'On-Time Rate',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      value: (_userStats!['currentStreak'] ?? 0).toString(),
                      label: 'Day Streak',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ] else
              const Center(
                child: CircularProgressIndicator(),
              ),
              
            const Divider(height: AppSpacing.xl),
            
            Text(
              'Thông tin cá nhân',
              style: GoogleFonts.inter(
                fontSize: AppTypography.titleLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Full Name', _currentUser!.fullName ?? 'N/A', Icons.person_rounded),
            _buildInfoRow('Email', _currentUser!.email, Icons.email_rounded),
            _buildInfoRow('User ID', _currentUser!.userId, Icons.fingerprint_rounded),
            _buildInfoRow(
              'Member Since',
              _currentUser!.createdAt != null 
                ? '${_currentUser!.createdAt!.day}/${_currentUser!.createdAt!.month}/${_currentUser!.createdAt!.year}'
                : 'N/A',
              Icons.calendar_today_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.notifications_rounded, color: AppColors.primary),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.dark_mode_rounded, color: AppColors.primary),
            title: const Text('Dark Mode'),
            subtitle: const Text('Chuyển sang chế độ tối'),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.toggleTheme();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã ${value ? 'bật' : 'tắt'} Dark Mode'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  activeColor: AppColors.primary,
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.language_rounded, color: AppColors.primary),
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _signOut,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'Tiếng Việt',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to $value'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to $value'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _apiClient.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ This action cannot be undone!'),
            const SizedBox(height: 16),
            const Text('Your account and all associated data will be permanently deleted:'),
            const SizedBox(height: 8),
            const Text('• All tasks and workspaces'),
            const Text('• Comments and activity history'),
            const Text('• Profile information'),
            const SizedBox(height: 16),
            const Text(
              'Are you absolutely sure?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // TODO: Call API to delete account
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deletion requested (API pending)'),
            backgroundColor: AppColors.info,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
