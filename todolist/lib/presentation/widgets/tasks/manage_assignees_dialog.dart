import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

/// Dialog to manage task assignees (add/remove)
class ManageAssigneesDialog extends StatefulWidget {
  final String taskId;
  final String workspaceId;
  final List<String> currentAssigneeIds;

  const ManageAssigneesDialog({
    super.key,
    required this.taskId,
    required this.workspaceId,
    required this.currentAssigneeIds,
  });

  @override
  State<ManageAssigneesDialog> createState() => _ManageAssigneesDialogState();
}

class _ManageAssigneesDialogState extends State<ManageAssigneesDialog> {
  final ApiClient _apiClient = ApiClient();
  List<UserModel> _allMembers = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = Set.from(widget.currentAssigneeIds);
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
          _allMembers = members;
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

  Future<void> _toggleAssignee(String userId, bool isAssigned) async {
    try {
      if (isAssigned) {
        await _apiClient.assignUsersToTask(widget.taskId, [userId]);
      } else {
        await _apiClient.unassignUserFromTask(widget.taskId, userId);
      }

      setState(() {
        if (isAssigned) {
          _selectedUserIds.add(userId);
        } else {
          _selectedUserIds.remove(userId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAssigned ? 'Đã thêm người thực hiện' : 'Đã xóa người thực hiện'),
          ),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Quản lý người thực hiện',
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.titleLarge,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _selectedUserIds.toList()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn thành viên để giao việc',
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodyMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('Lỗi tải thành viên', style: GoogleFonts.inter()),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _allMembers.length,
                  itemBuilder: (context, index) {
                    final member = _allMembers[index];
                    final isAssigned = _selectedUserIds.contains(member.userId);

                    return CheckboxListTile(
                      value: isAssigned,
                      onChanged: (value) {
                        if (value != null) {
                          _toggleAssignee(member.userId, value);
                        }
                      },
                      secondary: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (member.fullName ?? 'U').substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        member.fullName ?? 'Unknown',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        member.email,
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Đã chọn ${_selectedUserIds.length} người',
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.bodySmall,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
