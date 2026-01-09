import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/providers/task_providers.dart';
import 'package:todolist/presentation/screens/tasks/enhanced_task_detail_screen.dart';
import 'package:todolist/providers/auth_provider.dart';

/// 📅 Personal Calendar Screen (Redesigned with Syncfusion)
/// - Responsive: Schedule view cho mobile, Month cho web/tablet
/// - Color coding theo loại task
/// - Filter sidebar cho Personal/Workspace/Overdue
class PersonalCalendarScreen extends ConsumerStatefulWidget {
  const PersonalCalendarScreen({super.key});

  @override
  ConsumerState<PersonalCalendarScreen> createState() =>
      _PersonalCalendarScreenState();
}

class _PersonalCalendarScreenState
    extends ConsumerState<PersonalCalendarScreen> {
  final CalendarController _calendarController = CalendarController();

  // Filters
  bool _showPersonalTasks = true;
  bool _showWorkspaceTasks = true;
  bool _showOverdueTasks = true;
  bool _showCompletedTasks = false;

  // Current view
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _calendarController.view = _currentView;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Auto-adjust view based on screen size
    if (isMobile && _currentView == CalendarView.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentView = CalendarView.schedule;
            _calendarController.view = CalendarView.schedule;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Sidebar filters (ẩn trên mobile)
          if (!isMobile) _buildFilterSidebar(),

          // Main calendar
          Expanded(
            child: Column(
              children: [
                _buildCalendarHeader(isMobile),
                Expanded(child: _buildCalendarBody()),
              ],
            ),
          ),
        ],
      ),
      // 🎨 NHIỆM VỤ 3: FAB với 2 nút - Tạo Task + Filter (mobile)
      floatingActionButton: _buildCalendarFabs(isMobile),
    );
  }

  /// 🎨 FAB Group cho Calendar - Chỉ Filter (mobile only)
  /// NOTE: Đã xóa nút tạo task vì task bắt buộc phải thuộc workspace
  /// Để tạo task, user cần vào workspace cụ thể
  Widget _buildCalendarFabs(bool isMobile) {
    // Chỉ hiển thị FAB filter trên mobile
    if (!isMobile) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'filter_fab',
      onPressed: _showMobileFilterSheet,
      backgroundColor: Colors.grey.shade700,
      child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
    );
  }

  /// 🎨 Dialog tạo task mới từ Calendar
  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime selectedDeadline =
        _calendarController.selectedDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_task, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 12),
              const Text('Tạo Task Mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề *',
                    hintText: 'Nhập tiêu đề task',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Nhập mô tả task',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Độ ưu tiên',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                  items: ['Low', 'Medium', 'High'].map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: priority == 'High'
                                ? Colors.red
                                : priority == 'Medium'
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(priority),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPriority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calendar_today,
                    color: Colors.indigo.shade600,
                  ),
                  title: const Text('Deadline'),
                  subtitle: Text(
                    '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDeadline = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () => _createTaskFromCalendar(
                ctx,
                titleController.text,
                descController.text,
                selectedPriority,
                selectedDeadline,
              ),
              icon: const Icon(Icons.check),
              label: const Text('Tạo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTaskFromCalendar(
    BuildContext ctx,
    String title,
    String description,
    String priority,
    DateTime deadline,
  ) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tiêu đề'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get workspaces first
      final workspaces = await apiClient.getWorkspaces();

      if (workspaces.isEmpty) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng tạo workspace trước!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final workspaceId = workspaces.first.workspaceId;

      // Lấy userId hiện tại để tự động assign task cho mình
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.userId;

      await apiClient.createTask(workspaceId, {
        'title': title,
        'description': description.isEmpty ? null : description,
        'priority': priority,
        'status': 'ToDo',
        'deadline': deadline.toUtc().toIso8601String(),
        'estimatedTimeMinutes': 60,
        // CRITICAL: Assign cho user hiện tại để task hiện trên calendar cá nhân
        if (currentUserId != null) 'assigneeUserIds': [currentUserId],
      });

      if (ctx.mounted) {
        Navigator.pop(ctx);
        ref.invalidate(personalTasksProvider); // Refresh calendar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Tạo task thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== SIDEBAR FILTERS =====
  Widget _buildFilterSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Bộ lọc',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOẠI TASK',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFilterOption(
                  icon: Icons.person,
                  label: 'Task cá nhân',
                  color: Colors.blue,
                  value: _showPersonalTasks,
                  onChanged: (v) =>
                      setState(() => _showPersonalTasks = v ?? true),
                ),
                _buildFilterOption(
                  icon: Icons.work,
                  label: 'Task workspace',
                  color: Colors.purple,
                  value: _showWorkspaceTasks,
                  onChanged: (v) =>
                      setState(() => _showWorkspaceTasks = v ?? true),
                ),

                const Divider(height: 32),

                Text(
                  'TRẠNG THÁI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFilterOption(
                  icon: Icons.warning_amber,
                  label: 'Quá hạn',
                  color: Colors.red,
                  value: _showOverdueTasks,
                  onChanged: (v) =>
                      setState(() => _showOverdueTasks = v ?? true),
                ),
                _buildFilterOption(
                  icon: Icons.check_circle,
                  label: 'Đã hoàn thành',
                  color: Colors.green,
                  value: _showCompletedTasks,
                  onChanged: (v) =>
                      setState(() => _showCompletedTasks = v ?? false),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Legend
          Padding(padding: const EdgeInsets.all(16), child: _buildLegend()),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHÚ THÍCH MÀU',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildLegendItem(Colors.blue, 'Task cá nhân'),
        _buildLegendItem(Colors.deepPurple, 'Task workspace'),
        _buildLegendItem(Colors.red, 'Quá hạn'),
        _buildLegendItem(Colors.green, 'Đã hoàn thành'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ===== CALENDAR HEADER =====
  Widget _buildCalendarHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📅 Lịch của tôi',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, _) {
                  final tasksAsync = ref.watch(personalTasksProvider);
                  return tasksAsync.when(
                    data: (tasks) {
                      final filtered = _filterTasks(tasks);
                      return Text(
                        '${filtered.length} task',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),

          const Spacer(),

          // View toggles
          if (!isMobile) ...[
            _buildViewToggle(
              CalendarView.schedule,
              'Schedule',
              Icons.view_agenda,
            ),
            const SizedBox(width: 8),
            _buildViewToggle(CalendarView.day, 'Ngày', Icons.today),
            const SizedBox(width: 8),
            _buildViewToggle(CalendarView.week, 'Tuần', Icons.view_week),
            const SizedBox(width: 8),
            _buildViewToggle(
              CalendarView.month,
              'Tháng',
              Icons.calendar_view_month,
            ),
          ] else ...[
            // Dropdown for mobile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<CalendarView>(
                value: _currentView,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: const [
                  DropdownMenuItem(
                    value: CalendarView.schedule,
                    child: Text('Schedule'),
                  ),
                  DropdownMenuItem(
                    value: CalendarView.day,
                    child: Text('Ngày'),
                  ),
                  DropdownMenuItem(
                    value: CalendarView.week,
                    child: Text('Tuần'),
                  ),
                  DropdownMenuItem(
                    value: CalendarView.month,
                    child: Text('Tháng'),
                  ),
                ],
                onChanged: (view) {
                  if (view != null) {
                    setState(() {
                      _currentView = view;
                      _calendarController.view = view;
                    });
                  }
                },
              ),
            ),
          ],

          const SizedBox(width: 16),

          // Today button
          ElevatedButton.icon(
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
            },
            icon: const Icon(Icons.today, size: 18),
            label: Text(isMobile ? '' : 'Hôm nay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(CalendarView view, String label, IconData icon) {
    final isSelected = _currentView == view;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentView = view;
            _calendarController.view = view;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== CALENDAR BODY =====
  Widget _buildCalendarBody() {
    return Consumer(
      builder: (context, ref, _) {
        final tasksAsync = ref.watch(personalTasksProvider);

        return tasksAsync.when(
          data: (tasks) {
            final filteredTasks = _filterTasks(tasks);
            final dataSource = _TaskDataSource(filteredTasks);

            return SfCalendar(
              controller: _calendarController,
              view: _currentView,
              dataSource: dataSource,

              // Appearance
              backgroundColor: Colors.grey.shade50,
              todayHighlightColor: Colors.indigo,
              selectionDecoration: BoxDecoration(
                border: Border.all(color: Colors.indigo, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),

              // Month view settings
              monthViewSettings: MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                showAgenda: true,
                agendaViewHeight: 200,
                agendaStyle: AgendaStyle(
                  appointmentTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  dateTextStyle: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                  dayTextStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                monthCellStyle: MonthCellStyle(
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  todayTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                  trailingDatesTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  leadingDatesTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              // Schedule view settings
              scheduleViewSettings: ScheduleViewSettings(
                appointmentTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                dayHeaderSettings: DayHeaderSettings(
                  dayTextStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                  dateTextStyle: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                monthHeaderSettings: MonthHeaderSettings(
                  height: 60,
                  textAlign: TextAlign.start,
                  monthTextStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              // Time slot settings
              timeSlotViewSettings: TimeSlotViewSettings(
                timeTextStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),

              // Header style
              headerStyle: CalendarHeaderStyle(
                textStyle: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                backgroundColor: Colors.white,
              ),

              // Callbacks
              onTap: (calendarTapDetails) {
                if (calendarTapDetails.appointments != null &&
                    calendarTapDetails.appointments!.isNotEmpty) {
                  final appointment =
                      calendarTapDetails.appointments!.first as Appointment;
                  _showTaskDetails(appointment);
                }
              },

              // Appointment builder
              appointmentBuilder: (context, calendarAppointmentDetails) {
                final appointment =
                    calendarAppointmentDetails.appointments.first
                        as Appointment;
                return _buildAppointmentWidget(
                  appointment,
                  calendarAppointmentDetails.bounds,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải lịch',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(personalTasksProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentWidget(Appointment appointment, Rect bounds) {
    final isSmall = bounds.height < 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isSmall ? 2 : 4),
      decoration: BoxDecoration(
        color: appointment.color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: appointment.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isSmall) ...[
            Icon(
              _getAppointmentIcon(appointment),
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              appointment.subject,
              style: GoogleFonts.inter(
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAppointmentIcon(Appointment appointment) {
    final notes = appointment.notes ?? '';
    if (notes.contains('overdue')) return Icons.warning_amber;
    if (notes.contains('completed')) return Icons.check_circle;
    if (notes.contains('high')) return Icons.priority_high;
    if (notes.contains('workspace')) return Icons.work;
    return Icons.task_alt;
  }

  /// 🎨 NHIỆM VỤ 3: BottomSheet chi tiết task với nút XÓA
  void _showTaskDetails(Appointment appointment) {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.userId ?? '';
    final taskId = appointment.id?.toString() ?? '';

    if (taskId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header với màu task
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: appointment.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.subject,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment.startTime.day}/${appointment.startTime.month}/${appointment.startTime.year}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Xem chi tiết
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnhancedTaskDetailScreen(
                            taskId: taskId,
                            currentUserId: currentUserId,
                            userRole: 'Member',
                          ),
                        ),
                      ).then((_) => ref.invalidate(personalTasksProvider));
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Xem chi tiết'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nút XÓA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _confirmDeleteTask(ctx, taskId, appointment.subject),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Confirm dialog trước khi xóa task
  Future<void> _confirmDeleteTask(
    BuildContext sheetContext,
    String taskId,
    String taskTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa task "$taskTitle"?\n\nHành động này không thể hoàn tác.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTask(sheetContext, taskId);
    }
  }

  /// Gọi API xóa task và refresh calendar
  Future<void> _deleteTask(BuildContext sheetContext, String taskId) async {
    try {
      await apiClient.deleteTask(taskId);

      if (sheetContext.mounted) Navigator.pop(sheetContext); // Đóng BottomSheet

      // Refresh calendar
      ref.invalidate(personalTasksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Đã xóa task thành công'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== MOBILE FILTER FAB =====
  Widget _buildMobileFilterFab() {
    return FloatingActionButton(
      onPressed: _showMobileFilterSheet,
      backgroundColor: Colors.indigo,
      child: const Icon(Icons.filter_list, color: Colors.white),
    );
  }

  void _showMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Bộ lọc',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(),

              // Filters
              Expanded(
                child: ListView(
                  children: [
                    _buildMobileFilterTile(
                      'Task cá nhân',
                      Icons.person,
                      Colors.blue,
                      _showPersonalTasks,
                      (v) {
                        setSheetState(() => _showPersonalTasks = v);
                        setState(() {});
                      },
                    ),
                    _buildMobileFilterTile(
                      'Task workspace',
                      Icons.work,
                      Colors.purple,
                      _showWorkspaceTasks,
                      (v) {
                        setSheetState(() => _showWorkspaceTasks = v);
                        setState(() {});
                      },
                    ),
                    const Divider(),
                    _buildMobileFilterTile(
                      'Quá hạn',
                      Icons.warning_amber,
                      Colors.red,
                      _showOverdueTasks,
                      (v) {
                        setSheetState(() => _showOverdueTasks = v);
                        setState(() {});
                      },
                    ),
                    _buildMobileFilterTile(
                      'Đã hoàn thành',
                      Icons.check_circle,
                      Colors.green,
                      _showCompletedTasks,
                      (v) {
                        setSheetState(() => _showCompletedTasks = v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFilterTile(
    String label,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      activeColor: color,
    );
  }

  // ===== FILTER LOGIC =====
  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks.where((task) {
      // Filter by task type
      if (task.isPersonalTask && !_showPersonalTasks) return false;
      if (!task.isPersonalTask && !_showWorkspaceTasks) return false;

      // Filter by status
      if (task.isOverdue && !_showOverdueTasks) return false;
      final isCompleted =
          task.status.toLowerCase() == 'completed' ||
          task.status.toLowerCase() == 'done';
      if (isCompleted && !_showCompletedTasks) return false;

      // Only show tasks with deadline for calendar
      return task.deadline != null;
    }).toList();
  }
}

// ===== DATA SOURCE =====
class _TaskDataSource extends CalendarDataSource {
  _TaskDataSource(List<TaskModel> tasks) {
    appointments = _convertTasksToAppointments(tasks);
  }

  List<Appointment> _convertTasksToAppointments(List<TaskModel> tasks) {
    return tasks.map((task) {
      // ✅ Determine color based on task properties (Priority: Overdue > Workspace/Personal)
      Color color;
      String notes = task.description ?? '';

      // Priority 1: Overdue tasks -> RED
      if (task.isOverdue) {
        color = Colors.red;
        notes += '|overdue';
      }
      // Priority 2: Completed tasks -> GREEN
      else if (task.status.toLowerCase() == 'completed' ||
          task.status.toLowerCase() == 'done') {
        color = Colors.green.shade600;
        notes += '|completed';
      }
      // Priority 3: Workspace tasks -> DEEP PURPLE
      else if (!task.isPersonalTask) {
        color = Colors.deepPurple;
        notes += '|workspace';
      }
      // Priority 4: Personal tasks -> BLUE
      else {
        color = Colors.blue;
        notes += '|personal';
      }

      // Calculate end time (use estimated time or default 1 hour)
      final startTime = task.deadline!;
      final duration = task.estimatedTimeMinutes != null
          ? Duration(minutes: task.estimatedTimeMinutes!)
          : const Duration(hours: 1);
      final endTime = startTime.add(duration);

      return Appointment(
        id: task.taskId,
        subject: task.title,
        notes: notes,
        startTime: startTime,
        endTime: endTime,
        color: color,
        isAllDay: false,
      );
    }).toList();
  }
}
