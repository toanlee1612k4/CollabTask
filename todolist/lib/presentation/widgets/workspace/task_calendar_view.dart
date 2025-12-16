import 'package:flutter/material.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';
import 'package:intl/intl.dart';

/// Calendar view to display tasks by deadline
class TaskCalendarView extends StatefulWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskTap;

  const TaskCalendarView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _showWeekView = false;

  Map<DateTime, List<TaskModel>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _groupTasksByDate();
  }

  @override
  void didUpdateWidget(TaskCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _groupTasksByDate();
    }
  }

  void _groupTasksByDate() {
    _tasksByDate = {};
    for (var task in widget.tasks) {
      if (task.deadline != null) {
        final date = DateTime(
          task.deadline!.year,
          task.deadline!.month,
          task.deadline!.day,
        );
        _tasksByDate.putIfAbsent(date, () => []).add(task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Column(
      children: [
        _buildHeader(context, isMobile),
        const Divider(height: 1),
        Expanded(
          child: _showWeekView
              ? _buildWeekView(context, isMobile)
              : _buildMonthView(context, isMobile),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingM),
      color: AppTheme.backgroundCard,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousPeriod,
            tooltip: 'Trước',
          ),
          Expanded(
            child: Text(
              _showWeekView
                  ? _getWeekRangeText()
                  : DateFormat('MMMM yyyy', 'vi').format(_selectedMonth),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextPeriod,
            tooltip: 'Sau',
          ),
          SizedBox(width: AppConstants.spacingS),
          IconButton(
            icon: Icon(_showWeekView ? Icons.calendar_month : Icons.view_week),
            onPressed: () {
              setState(() {
                _showWeekView = !_showWeekView;
              });
            },
            tooltip: _showWeekView ? 'Xem tháng' : 'Xem tuần',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime.now();
                _selectedDate = DateTime.now();
              });
            },
            tooltip: 'Hôm nay',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, bool isMobile) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Calculate total cells needed (including leading empty cells)
    final leadingEmptyCells = firstWeekday - 1; // Mon=0, Tue=1, etc.
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWeekdayHeader(context),
          ...List.generate(rows, (rowIndex) {
            return _buildWeekRow(
              context,
              rowIndex,
              leadingEmptyCells,
              daysInMonth,
              isMobile,
            );
          }),
          if (_selectedDate != null) _buildTasksForSelectedDate(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, bool isMobile) {
    final startOfWeek = _selectedMonth.subtract(Duration(days: _selectedMonth.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        _buildWeekdayHeader(context),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((date) {
              return Expanded(
                child: _buildDayColumn(context, date, isMobile),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.textTertiary),
        ),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Text(
              day,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: day == 'CN' ? AppTheme.errorColor : AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekRow(
    BuildContext context,
    int rowIndex,
    int leadingEmptyCells,
    int daysInMonth,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (colIndex) {
        final cellIndex = rowIndex * 7 + colIndex;
        final dayNumber = cellIndex - leadingEmptyCells + 1;

        if (cellIndex < leadingEmptyCells || dayNumber > daysInMonth) {
          return Expanded(child: Container());
        }

        final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
        return Expanded(
          child: _buildDayCell(context, date, isMobile),
        );
      }),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, bool isMobile) {
    final tasksForDay = _tasksByDate[date] ?? [];
    final isToday = _isToday(date);
    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        height: isMobile ? 60 : 80,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.1)
              : (isToday ? AppTheme.accentColor.withOpacity(0.05) : null),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : (isToday ? AppTheme.accentColor.withOpacity(0.3) : AppTheme.textTertiary),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: AppConstants.spacingXs),
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday ? AppTheme.accentColor : Colors.black87,
                  ),
            ),
            if (tasksForDay.isNotEmpty) ...[
              SizedBox(height: AppConstants.spacingXs),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  ...tasksForDay.take(isMobile ? 2 : 3).map((task) {
                    return Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getTaskColor(task),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                  if (tasksForDay.length > (isMobile ? 2 : 3))
                    Text(
                      '+${tasksForDay.length - (isMobile ? 2 : 3)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, DateTime date, bool isMobile) {
    final tasksForDay = _tasksByDate[date] ?? [];
    final isToday = _isToday(date);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.textTertiary, width: 0.5),
        ),
        color: isToday ? AppTheme.accentColor.withOpacity(0.05) : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppConstants.spacingS),
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? AppTheme.accentColor : AppTheme.textPrimary,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXs),
              itemCount: tasksForDay.length,
              itemBuilder: (context, index) {
                final task = tasksForDay[index];
                return _buildTaskChip(context, task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksForSelectedDate(BuildContext context, bool isMobile) {
    final tasksForDay = _tasksByDate[_selectedDate!] ?? [];

    return Container(
      margin: EdgeInsets.all(AppConstants.spacingM),
      padding: EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.accentColor, size: AppConstants.iconS),
              SizedBox(width: AppConstants.spacingS),
              Text(
                DateFormat('dd MMMM yyyy', 'vi').format(_selectedDate!),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
          const Divider(),
          if (tasksForDay.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppConstants.spacingL),
              child: Center(
                child: Text(
                  'Không có task nào',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            )
          else
            ...tasksForDay.map((task) {
              return _buildTaskListItem(context, task);
            }),
        ],
      ),
    );
  }

  Widget _buildTaskChip(BuildContext context, TaskModel task) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      child: Container(
        margin: EdgeInsets.only(bottom: AppConstants.spacingXs),
        padding: EdgeInsets.all(AppConstants.spacingXs),
        decoration: BoxDecoration(
          color: _getTaskColor(task).withOpacity(0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getTaskColor(task),
            width: 2,
          ),
        ),
        child: Text(
          task.title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTaskListItem(BuildContext context, TaskModel task) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      child: Container(
        margin: EdgeInsets.only(bottom: AppConstants.spacingS),
        padding: EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: _getTaskColor(task).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getTaskColor(task).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getTaskColor(task),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          decoration: task.status == 'Completed'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingXs),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            _buildPriorityBadge(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    IconData icon;
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppTheme.errorColor;
        icon = Icons.arrow_upward;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.horizontal_rule;
        break;
      default:
        color = AppTheme.successColor;
        icon = Icons.arrow_downward;
    }

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingXs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 12.0),
    );
  }

  Color _getTaskColor(TaskModel task) {
    if (task.status == 'Completed') {
      return AppTheme.successColor;
    } else if (_isOverdue(task)) {
      return AppTheme.errorColor;
    } else if (task.priority.toLowerCase() == 'high') {
      return Colors.orange;
    } else {
      return AppTheme.accentColor;
    }
  }

  bool _isOverdue(TaskModel task) {
    if (task.deadline == null || task.status == 'Completed') return false;
    return task.deadline!.isBefore(DateTime.now());
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousPeriod() {
    setState(() {
      if (_showWeekView) {
        _selectedMonth = _selectedMonth.subtract(const Duration(days: 7));
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_showWeekView) {
        _selectedMonth = _selectedMonth.add(const Duration(days: 7));
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      }
    });
  }

  String _getWeekRangeText() {
    final startOfWeek = _selectedMonth.subtract(Duration(days: _selectedMonth.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${DateFormat('dd/MM', 'vi').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy', 'vi').format(endOfWeek)}';
  }
}


