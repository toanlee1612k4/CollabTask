import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';

/// Dialog to edit task details
class EditTaskDialog extends StatefulWidget {
  final TaskModel task;

  const EditTaskDialog({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedTimeController;
  late String _selectedPriority;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _estimatedTimeController = TextEditingController(
      text: widget.task.estimatedTimeMinutes != null
          ? (widget.task.estimatedTimeMinutes! ~/ 60).toString()
          : '',
    );
    _selectedPriority = widget.task.priority;
    _selectedDeadline = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final estimatedHours = int.tryParse(_estimatedTimeController.text);
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority,
        // Convert local time to UTC before sending to API
        if (_selectedDeadline != null) 'deadline': _selectedDeadline!.toUtc().toIso8601String(),
        if (estimatedHours != null) 'estimatedTimeMinutes': estimatedHours * 60,
      };

      await _apiClient.updateTask(widget.task.taskId, taskData);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật task')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Chỉnh sửa Task',
                      style: GoogleFonts.inter(
                        fontSize: AppTypography.titleLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          prefixIcon: const Icon(Icons.title_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          prefixIcon: const Icon(Icons.description_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Priority
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Độ ưu tiên *',
                          prefixIcon: const Icon(Icons.flag_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        items: ['Low', 'Medium', 'High'].map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getPriorityColor(priority),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(priority),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Deadline
                      InkWell(
                        onTap: _pickDeadline,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Deadline',
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            _selectedDeadline != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDeadline!)
                                : 'Chọn deadline',
                            style: GoogleFonts.inter(
                              color: _selectedDeadline != null ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Estimated Time
                      TextFormField(
                        controller: _estimatedTimeController,
                        decoration: InputDecoration(
                          labelText: 'Thời gian ước tính (giờ)',
                          prefixIcon: const Icon(Icons.access_time_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          hintText: 'Ví dụ: 4',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final hours = int.tryParse(value);
                            if (hours == null || hours <= 0) {
                              return 'Vui lòng nhập số giờ hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Lưu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}
