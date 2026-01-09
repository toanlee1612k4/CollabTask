import 'package:flutter/material.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:todolist/presentation/widgets/common/loading_overlay.dart';

class WorkspaceInvitationsScreen extends StatefulWidget {
  const WorkspaceInvitationsScreen({Key? key}) : super(key: key);

  @override
  State<WorkspaceInvitationsScreen> createState() => _WorkspaceInvitationsScreenState();
}

class _WorkspaceInvitationsScreenState extends State<WorkspaceInvitationsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use new backend endpoint to get invitations
      final invitations = await _apiClient.getWorkspaceInvitations();
      
      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lời mời: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['invitationID'] as String?;
    if (invitationId == null) return;

    // ✅ OPTIMISTIC UPDATE: Xóa item khỏi UI ngay lập tức
    final workspaceName = invitation['workspaceName'] as String? ?? 'workspace';
    final removedIndex = _invitations.indexWhere(
      (inv) => inv['invitationID'] == invitationId
    );
    final removedInvitation = Map<String, dynamic>.from(invitation);
    
    setState(() {
      _invitations.removeWhere((inv) => inv['invitationID'] == invitationId);
    });

    try {
      // Accept invitation using backend endpoint
      final result = await _apiClient.acceptWorkspaceInvitation(invitationId);

      if (!mounted) return;
      
      final actualWorkspaceName = result['workspace']?['name'] ?? workspaceName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã tham gia "$actualWorkspaceName"! Xem trong Workspaces.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // ✅ ROLLBACK: Nếu API fail, thêm lại item vào list
      if (!mounted) return;
      
      setState(() {
        if (removedIndex >= 0 && removedIndex <= _invitations.length) {
          _invitations.insert(removedIndex, removedInvitation);
        } else {
          _invitations.add(removedInvitation);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Không thể chấp nhận lời mời: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['invitationID'] as String?;
    if (invitationId == null) return;

    // ✅ OPTIMISTIC UPDATE: Xóa item khỏi UI ngay lập tức
    final removedIndex = _invitations.indexWhere(
      (inv) => inv['invitationID'] == invitationId
    );
    final removedInvitation = Map<String, dynamic>.from(invitation);
    
    setState(() {
      _invitations.removeWhere((inv) => inv['invitationID'] == invitationId);
    });

    try {
      // Reject invitation using backend endpoint
      await _apiClient.rejectWorkspaceInvitation(invitationId);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối lời mời'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // ✅ ROLLBACK: Nếu API fail, thêm lại item vào list
      if (!mounted) return;
      
      setState(() {
        if (removedIndex >= 0 && removedIndex <= _invitations.length) {
          _invitations.insert(removedIndex, removedInvitation);
        } else {
          _invitations.add(removedInvitation);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Không thể từ chối lời mời: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời Workspace'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Đang tải lời mời...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return ErrorDisplay(
        message: _errorMessage!,
        onRetry: _loadInvitations,
      );
    }

    if (_invitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có lời mời nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Các lời mời tham gia workspace sẽ hiển thị ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      color: const Color(0xFF6C5CE7),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final workspaceName = invitation['workspaceName'] as String? ?? 'Workspace';
    final role = invitation['role'] as String? ?? 'Member';
    final createdAt = invitation['createdAt'] as String?;
    final message = invitation['message'] as String?;
    final invitedBy = invitation['invitedBy'] as Map<String, dynamic>?;
    final inviterName = invitedBy?['fullName'] as String? ?? 'Someone';
    final inviterEmail = invitedBy?['email'] as String? ?? '';

    DateTime? parsedDate;
    if (createdAt != null) {
      try {
        parsedDate = DateTime.parse(createdAt);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon và thời gian
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Color(0xFF6C5CE7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lời mời tham gia Workspace',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parsedDate != null ? _formatTimeAgo(parsedDate) : 'Vừa xong',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Workspace info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Color(0xFF6C5CE7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          workspaceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Được mời bởi $inviterName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (inviterEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inviterEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getRoleColor(role)),
                    ),
                    child: Text(
                      'Vai trò: $role',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.message, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(invitation),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAcceptDialog(invitation),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Chấp nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'projectmanager':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showAcceptDialog(Map<String, dynamic> invitation) {
    final workspaceName = invitation['workspaceName'] as String? ?? 'workspace';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn tham gia "$workspaceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptInvitation(invitation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> invitation) {
    final workspaceName = invitation['workspaceName'] as String? ?? 'workspace';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn từ chối lời mời tham gia "$workspaceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectInvitation(invitation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
