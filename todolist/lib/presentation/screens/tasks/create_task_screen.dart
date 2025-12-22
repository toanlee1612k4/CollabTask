import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/providers/create_task_provider.dart';
import 'package:todolist/providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// Create Task Screen - Tạo task mới với Riverpod
class CreateTaskScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final String? workspaceName; // Optional: Hiển thị tên workspace

  const CreateTaskScreen({
    super.key,
    required this.workspaceId,
    this.workspaceName,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPriority = 'Medium';
  DateTime? _selectedDeadline;
  int? _estimatedMinutes;
  List<String> _selectedAssigneeIds = [];

  @override
  void initState() {
    super.initState();
    // Load workspace members khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createTaskProvider.notifier).loadWorkspaceMembers(widget.workspaceId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTaskProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.userId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tạo Task Mới'),
            if (widget.workspaceName != null)
              Text(
                widget.workspaceName!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: state.isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // ✅ Tránh keyboard overflow
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error message
                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề Task *',
                        hintText: 'Nhập tiêu đề task...',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả (tùy chọn)',
                        hintText: 'Nhập mô tả chi tiết...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 16),

                    // Priority dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Độ ưu tiên *',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('🔴 Urgent'),
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
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('🟠 High'),
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
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('🔵 Medium'),
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
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('⚪ Low'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deadline picker
                    InkWell(
                      onTap: () => _pickDeadline(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deadline (tùy chọn)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: _selectedDeadline != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _selectedDeadline = null);
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedDeadline != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDeadline!)
                              : 'Chọn ngày giờ deadline',
                          style: TextStyle(
                            color: _selectedDeadline != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estimated time
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Thời gian ước tính (phút)',
                        hintText: 'VD: 120',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _estimatedMinutes = int.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Assignees dropdown (MultiSelect)
                    _buildAssigneeSelector(state.workspaceMembers, currentUserId),
                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: state.isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Tạo Task',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Widget chọn Assignees (hỗ trợ multi-select)
  Widget _buildAssigneeSelector(List<UserModel> members, String? currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Người thực hiện *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: members.isEmpty
              ? const Text('Không có thành viên nào', style: TextStyle(color: Colors.grey))
              : Column(
                  children: [
                    // Selected assignees chips
                    if (_selectedAssigneeIds.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedAssigneeIds.map((userId) {
                          final user = members.firstWhere(
                            (m) => m.userId == userId,
                            orElse: () => UserModel(userId: userId, email: 'Unknown'),
                          );
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                (user.fullName?.isNotEmpty == true
                                        ? user.fullName![0]
                                        : user.email[0])
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            label: Text(user.fullName ?? user.email),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedAssigneeIds.remove(userId);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    if (_selectedAssigneeIds.isNotEmpty) const Divider(),
                    // Member list with checkboxes
                    ...members.map((member) {
                      final isSelected = _selectedAssigneeIds.contains(member.userId);
                      final isCurrentUser = member.userId == currentUserId;

                      return CheckboxListTile(
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (member.fullName?.isNotEmpty == true
                                        ? member.fullName![0]
                                        : member.email[0])
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName ?? member.email,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (isCurrentUser)
                                    const Text(
                                      '(Bạn)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedAssigneeIds.add(member.userId);
                            } else {
                              _selectedAssigneeIds.remove(member.userId);
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                    // Quick action: Assign to self
                    if (currentUserId != null && !_selectedAssigneeIds.contains(currentUserId))
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedAssigneeIds.add(currentUserId);
                          });
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Gán cho tôi'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Pick deadline with date & time
  Future<void> _pickDeadline(BuildContext context) async {
    final now = DateTime.now();

    // Step 1: Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // Step 2: Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Combine date + time
    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDeadline = combinedDateTime;
    });
  }

  /// Handle submit form
  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn ít nhất một người thực hiện'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Call provider to create task
    final success = await ref.read(createTaskProvider.notifier).createTask(
          workspaceId: widget.workspaceId,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          priority: _selectedPriority,
          deadline: _selectedDeadline, // Provider sẽ convert sang UTC
          estimatedTimeMinutes: _estimatedMinutes,
          assigneeUserIds: _selectedAssigneeIds,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tạo task thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close screen và trả về task vừa tạo
      Navigator.pop(context, ref.read(createTaskProvider).createdTask);
    } else {
      // Error đã được hiển thị ở đầu form
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${ref.read(createTaskProvider).error ?? "Lỗi không xác định"}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
