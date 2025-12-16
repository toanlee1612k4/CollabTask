import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

/// Full-screen Members Management Dialog
class WorkspaceMembersDialog extends StatefulWidget {
  final String workspaceId;
  final String currentUserId;
  final String currentUserRole; // Owner, ProjectManager, Member

  const WorkspaceMembersDialog({
    super.key,
    required this.workspaceId,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<WorkspaceMembersDialog> createState() => _WorkspaceMembersDialogState();
}

class _WorkspaceMembersDialogState extends State<WorkspaceMembersDialog> {
  final ApiClient _apiClient = ApiClient();
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _apiClient.getWorkspaceMembers(widget.workspaceId);
      if (mounted) {
        setState(() {
          _members = members;
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

  bool get _canManageMembers {
    return widget.currentUserRole == 'Owner' || widget.currentUserRole == 'ProjectManager';
  }

  Future<void> _removeMember(UserModel member) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa ${member.fullName} khỏi workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.removeWorkspaceMember(widget.workspaceId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thành viên')),
        );
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateMemberRole(UserModel member, String newRole) async {
    try {
      await _apiClient.updateWorkspaceMemberRole(
        widget.workspaceId,
        member.userId,
        newRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật vai trò')),
        );
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveWorkspace() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời workspace'),
        content: const Text('Bạn có chắc muốn rời khỏi workspace này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rời', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.leaveWorkspace(widget.workspaceId);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate left workspace
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã rời workspace')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Thành viên (${_members.length})',
          style: GoogleFonts.inter(
            fontSize: AppTypography.titleLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.currentUserRole != 'Owner')
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Rời workspace',
              onPressed: _leaveWorkspace,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Lỗi tải thành viên',
                          style: GoogleFonts.inter(
                            fontSize: AppTypography.titleMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: AppTypography.bodyMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: _loadMembers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCurrentUser = member.userId == widget.currentUserId;
                    final memberRole = member.roleName ?? 'Member';

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            (member.fullName ?? 'U').substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.fullName ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'Bạn',
                                  style: GoogleFonts.inter(
                                    fontSize: AppTypography.bodySmall,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          member.email,
                          style: GoogleFonts.inter(
                            fontSize: AppTypography.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Builder(
                          builder: (context) {
                            return !isCurrentUser && _canManageMembers
                            ? SizedBox(
                                width: 200,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Role dropdown
                                    Flexible(
                                      child: DropdownButton<String>(
                                        value: memberRole,
                                        underline: const SizedBox(),
                                        isDense: true,
                                        items: ['Owner', 'ProjectManager', 'Member']
                                            .map((role) => DropdownMenuItem(
                                                  value: role,
                                                  child: Text(
                                                    role == 'ProjectManager' ? 'PM' : role,
                                                    style: GoogleFonts.inter(
                                                      fontSize: AppTypography.bodySmall,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (newRole) {
                                          if (newRole != null && newRole != memberRole) {
                                            _updateMemberRole(member, newRole);
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _removeMember(member),
                                      tooltip: 'Xóa thành viên',
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              )
                            : Chip(
                                label: Text(
                                  memberRole,
                                  style: GoogleFonts.inter(
                                    fontSize: AppTypography.bodySmall,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: _getRoleColor(memberRole).withOpacity(0.1),
                                side: BorderSide(color: _getRoleColor(memberRole)),
                              );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Owner':
        return AppColors.error;
      case 'ProjectManager':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
