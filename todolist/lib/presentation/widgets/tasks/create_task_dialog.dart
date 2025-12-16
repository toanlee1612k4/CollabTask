import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/services/api_client.dart';

/// Create Task Dialog with full fields
class CreateTaskDialog extends StatefulWidget {
  final String workspaceId;
  final VoidCallback onTaskCreated;

  const CreateTaskDialog({
    super.key,
    required this.workspaceId,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form values
  String _priority = 'Medium';
  DateTime? _deadline;
  int _estimatedHours = 1;
  List<String> _selectedAssignees = [];
  
  bool _isLoading = false;
  String? _error;

  // TODO: Fetch from API
  final List<Map<String, String>> _availableMembers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaceData() async {
    try {
      // Load workspace members and tags
      final members = await _apiClient.getWorkspaceMembers(widget.workspaceId);
      // TODO: Load tags
      
      if (mounted) {
        setState(() {
          _availableMembers.clear();
          for (var member in members) {
            _availableMembers.add({
              'id': member.userId,
              'name': member.fullName ?? member.email,
            });
          }
        });
      }
    } catch (e) {
      print('Error loading workspace data: $e');
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _priority,
        'status': 'ToDo', // CRITICAL: Backend requires status field
        'deadline': _deadline?.toIso8601String(),
        'estimatedTimeMinutes': _estimatedHours * 60,
        'assigneeUserIds': _selectedAssignees,
      };
      
      if (kDebugMode) {
        print('\n📝 ========== CREATE TASK ==========');
        print('📝 POST /api/workspaces/${widget.workspaceId}/tasks');
        print('📝 Payload:');
        print(jsonEncode(payload));
      }
      
      // Call API to create task (Section 3.2 of API docs)
      final response = await _apiClient.dio.post(
        '/api/workspaces/${widget.workspaceId}/tasks',
        data: payload,
      );
      
      if (kDebugMode) {
        print('✅ Task created successfully!');
        print('📦 Response:');
        print(jsonEncode(response.data));
        print('📦 Created in workspace: ${widget.workspaceId}');
        print('📦 Task ID: ${response.data['taskId']}');
        print('📦 Task status: ${response.data['status']}');
        print('========================================\n');
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo task thành công'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Tạo Task Mới',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.titleLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Nhập tiêu đề task',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          counter: Text('${_titleController.text.length}/200'),
                        ),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Mô tả chi tiết về task...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Priority
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Độ ưu tiên *',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Urgent',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.priorityUrgent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Khẩn cấp'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'High',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.priorityHigh,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Cao'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.priorityMedium,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Trung bình'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Low',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.priorityLow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Thấp'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _priority = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Deadline
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _deadline = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Deadline',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            _deadline != null
                                ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                : 'Chọn ngày deadline',
                            style: GoogleFonts.inter(
                              color: _deadline != null ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Estimated time
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.textHint),
                          const SizedBox(width: 8),
                          Text(
                            'Thời gian ước tính:',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_estimatedHours > 1) {
                                      setState(() => _estimatedHours--);
                                    }
                                  },
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(
                                  '$_estimatedHours giờ',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_estimatedHours < 100) {
                                      setState(() => _estimatedHours++);
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Assignees
                      Text(
                        'Giao cho',
                        style: GoogleFonts.inter(
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_availableMembers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Chưa có thành viên nào',
                                style: GoogleFonts.inter(
                                  fontSize: AppTypography.bodySmall,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableMembers.map((member) {
                            final isSelected = _selectedAssignees.contains(member['id']);
                            return FilterChip(
                              label: Text(member['name']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAssignees.add(member['id']!);
                                  } else {
                                    _selectedAssignees.remove(member['id']);
                                  }
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),

                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.error,
                                    fontSize: AppTypography.bodySmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTask,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? 'Đang tạo...' : 'Tạo Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
