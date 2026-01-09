import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/data/services/api_client.dart';

class WorkspaceMember {
  final String userId;
  final String name;
  final String email;
  final String role;

  WorkspaceMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      userId: json['userId'],
      name: json['name'] ?? json['userName'] ?? 'Unknown',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Member',
    );
  }
}

class AssignUsersDialog extends StatefulWidget {
  final String workspaceId;
  final String taskId;
  final List<String> currentAssigneeIds;

  const AssignUsersDialog({
    super.key,
    required this.workspaceId,
    required this.taskId,
    required this.currentAssigneeIds,
  });

  @override
  State<AssignUsersDialog> createState() => _AssignUsersDialogState();
}

class _AssignUsersDialogState extends State<AssignUsersDialog> {
  bool _isLoading = true;
  String? _error;
  List<WorkspaceMember> _members = [];
  Set<String> _selectedUserIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUserIds = Set.from(widget.currentAssigneeIds);
    _loadWorkspaceMembers();
  }

  Future<void> _loadWorkspaceMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Sử dụng API method có sẵn để lấy workspace members
      final users = await apiClient.getWorkspaceMembers(widget.workspaceId);

      setState(() {
        _members = users
            .map(
              (user) => WorkspaceMember(
                userId: user.userId,
                name: user.fullName ?? user.email,
                email: user.email,
                role:
                    'Member', // Default role since UserModel doesn't include workspace role
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // Hiển thị lỗi thực tế, KHÔNG dùng mock data
      setState(() {
        _members = [];
        _isLoading = false;
        _error = 'Không thể tải danh sách thành viên: ${e.toString()}';
      });
    }
  }

  // REMOVED: Mock data method - now using real API only

  List<WorkspaceMember> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;

    return _members.where((member) {
      final query = _searchQuery.toLowerCase();
      return member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _assignSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người')),
      );
      return;
    }

    final newAssignees = _selectedUserIds
        .where((id) => !widget.currentAssigneeIds.contains(id))
        .toList();

    if (newAssignees.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    try {
      // Assign all new users at once
      await apiClient.taskAssignment.assignTask(
        taskId: widget.taskId,
        assigneeUserIds: newAssignees,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã giao việc cho ${newAssignees.length} người'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: Colors.indigo.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giao việc',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chọn thành viên để giao task',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search Bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 16),

            // Selected Count
            if (_selectedUserIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.indigo.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đã chọn ${_selectedUserIds.length} người',
                      style: GoogleFonts.inter(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Members List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMembersList(),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedUserIds.isEmpty
                        ? null
                        : _assignSelectedUsers,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Giao việc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final filteredMembers = _filteredMembers;

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Không có thành viên nào'
                  : 'Không tìm thấy kết quả',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        return _buildMemberTile(filteredMembers[index]);
      },
    );
  }

  Widget _buildMemberTile(WorkspaceMember member) {
    final isSelected = _selectedUserIds.contains(member.userId);
    final isAlreadyAssigned = widget.currentAssigneeIds.contains(member.userId);

    Color roleColor;
    switch (member.role) {
      case 'Owner':
        roleColor = Colors.purple;
        break;
      case 'ProjectManager':
        roleColor = Colors.blue;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.indigo.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: isAlreadyAssigned
            ? null
            : (value) {
                setState(() {
                  if (value == true) {
                    _selectedUserIds.add(member.userId);
                  } else {
                    _selectedUserIds.remove(member.userId);
                  }
                });
              },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.indigo.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: isAlreadyAssigned ? Colors.grey.shade500 : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.role,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              member.email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (isAlreadyAssigned) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đã được giao việc',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor: isAlreadyAssigned
              ? Colors.grey.shade300
              : Colors.indigo.shade100,
          child: Text(
            member.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: isAlreadyAssigned
                  ? Colors.grey.shade600
                  : Colors.indigo.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
