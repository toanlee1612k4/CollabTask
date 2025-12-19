import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

class WorkspaceMembersScreen extends StatefulWidget {
  final String workspaceId;
  final String currentUserId;
  final String currentUserRole; // Should be 'Owner' to access this screen

  const WorkspaceMembersScreen({
    super.key,
    required this.workspaceId,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<WorkspaceMembersScreen> createState() => _WorkspaceMembersScreenState();
}

class _WorkspaceMembersScreenState extends State<WorkspaceMembersScreen> {
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;
  final _inviteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await apiClient.getWorkspaceMembers(widget.workspaceId);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteMember() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Vui lòng nhập email', isError: true);
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Email không hợp lệ', isError: true);
      return;
    }

    try {
      await apiClient.addWorkspaceMember(widget.workspaceId, email);
      _inviteEmailController.clear();
      _showSnackBar('Đã gửi lời mời đến $email');
      _loadMembers(); // Refresh list
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _changeRole(UserModel member, String newRole) async {
    if (member.userId == widget.currentUserId) {
      _showSnackBar('Không thể thay đổi role của chính mình', isError: true);
      return;
    }

    try {
      await apiClient.dio.patch(
        '/api/workspaces/${widget.workspaceId}/members/${member.userId}/role',
        data: {'newRole': newRole},
      );
      _showSnackBar('Đã cập nhật role thành $newRole');
      _loadMembers(); // Refresh list
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _removeMember(UserModel member) async {
    if (member.userId == widget.currentUserId) {
      _showSnackBar('Không thể xóa chính mình khỏi workspace', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa ${member.fullName ?? member.email} khỏi workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiClient.removeWorkspaceMember(widget.workspaceId, member.userId);
      _showSnackBar('Đã xóa thành viên');
      _loadMembers(); // Refresh list
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý thành viên',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: widget.currentUserRole == 'Owner'
          ? FloatingActionButton.extended(
              onPressed: _showInviteDialog,
              backgroundColor: Colors.indigo.shade600,
              icon: const Icon(Icons.person_add),
              label: const Text('Mời thành viên'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text('Chưa có thành viên nào'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          return _buildMemberCard(_members[index]);
        },
      ),
    );
  }

  Widget _buildMemberCard(UserModel member) {
    final isCurrentUser = member.userId == widget.currentUserId;
    final isOwner = widget.currentUserRole == 'Owner';
    final memberRole = member.roleName ?? 'Member';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.indigo.shade100,
                  child: member.avatar != null
                      ? ClipOval(
                          child: Image.network(
                            member.avatar!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(member),
                          ),
                        )
                      : _buildDefaultAvatar(member),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName ?? 'Chưa có tên',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bạn',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Role badge
                _buildRoleBadge(memberRole),
              ],
            ),
            
            // Role dropdown for Owner
            if (isOwner && !isCurrentUser) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phân quyền',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: memberRole,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Member',
                                  child: Text('Member'),
                                ),
                                DropdownMenuItem(
                                  value: 'ProjectManager',
                                  child: Text('Project Manager'),
                                ),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null && newRole != memberRole) {
                                  _changeRole(member, newRole);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _removeMember(member),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Xóa thành viên',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(UserModel member) {
    final initial = (member.fullName?.isNotEmpty == true 
        ? member.fullName![0] 
        : member.email[0]).toUpperCase();
    
    return Text(
      initial,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade600,
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    
    switch (role) {
      case 'Owner':
        color = Colors.purple;
        icon = Icons.star;
        break;
      case 'ProjectManager':
        color = Colors.blue;
        icon = Icons.manage_accounts;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            role,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mời thành viên mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email của người bạn muốn mời vào workspace này:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Người được mời sẽ có quyền Member mặc định.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _inviteEmailController.clear();
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _inviteMember();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send),
            label: const Text('Gửi lời mời'),
          ),
        ],
      ),
    );
  }
}
