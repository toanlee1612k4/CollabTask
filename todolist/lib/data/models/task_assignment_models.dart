// Task Assignment Models theo TASK-ASSIGNMENT-WORKFLOW-GUIDE.md

/// Assignment Status Enum
enum TaskAssignmentStatus {
  pending(0, 'Pending', 'Đang chờ'),
  accepted(1, 'Accepted', 'Đã chấp nhận'),
  rejected(2, 'Rejected', 'Đã từ chối'),
  inProgress(3, 'InProgress', 'Đang làm'),
  completionRequested(4, 'CompletionRequested', 'Chờ duyệt'),
  approved(5, 'Approved', 'Đã duyệt');

  final int value;
  final String name;
  final String displayName;

  const TaskAssignmentStatus(this.value, this.name, this.displayName);

  static TaskAssignmentStatus fromValue(int value) {
    return TaskAssignmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskAssignmentStatus.pending,
    );
  }

  static TaskAssignmentStatus fromString(String name) {
    return TaskAssignmentStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == name.toLowerCase(),
      orElse: () => TaskAssignmentStatus.pending,
    );
  }
}

/// Task Assignment Model
class TaskAssignment {
  final String taskId;
  final String assigneeUserId;
  final String assigneeName;
  final String assigneeEmail;
  final String? assigneeAvatarUrl;
  final String assignerUserId;
  final String? assignerName;
  final TaskAssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? responseAt;
  final String? responseNote;
  final DateTime? completionRequestedAt;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final String? approvedByName;
  final String? approvalNote;

  TaskAssignment({
    required this.taskId,
    required this.assigneeUserId,
    required this.assigneeName,
    required this.assigneeEmail,
    this.assigneeAvatarUrl,
    required this.assignerUserId,
    this.assignerName,
    required this.status,
    required this.assignedAt,
    this.responseAt,
    this.responseNote,
    this.completionRequestedAt,
    this.approvedAt,
    this.approvedByUserId,
    this.approvedByName,
    this.approvalNote,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      taskId: json['taskID'] ?? json['taskId'] ?? '',
      assigneeUserId: json['assigneeUserID'] ?? json['assigneeUserId'] ?? '',
      assigneeName: json['assigneeName'] ?? 'Unknown',
      assigneeEmail: json['assigneeEmail'] ?? '',
      assigneeAvatarUrl: json['assigneeAvatarUrl'],
      assignerUserId: json['assignerUserID'] ?? json['assignerUserId'] ?? '',
      assignerName: json['assignerName'],
      status: json['status'] is int
          ? TaskAssignmentStatus.fromValue(json['status'])
          : TaskAssignmentStatus.fromString(json['status'] ?? 'Pending'),
      assignedAt: DateTime.parse(json['assignedAt']),
      responseAt: json['responseAt'] != null ? DateTime.parse(json['responseAt']) : null,
      responseNote: json['responseNote'],
      completionRequestedAt: json['completionRequestedAt'] != null
          ? DateTime.parse(json['completionRequestedAt'])
          : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      approvedByUserId: json['approvedByUserId'] ?? json['approvedByUserID'],
      approvedByName: json['approvedByName'],
      approvalNote: json['approvalNote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'assigneeUserId': assigneeUserId,
      'assigneeName': assigneeName,
      'assigneeEmail': assigneeEmail,
      'assigneeAvatarUrl': assigneeAvatarUrl,
      'assignerUserId': assignerUserId,
      'assignerName': assignerName,
      'status': status.value,
      'assignedAt': assignedAt.toIso8601String(),
      'responseAt': responseAt?.toIso8601String(),
      'responseNote': responseNote,
      'completionRequestedAt': completionRequestedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedByUserId': approvedByUserId,
      'approvedByName': approvedByName,
      'approvalNote': approvalNote,
    };
  }

  bool get isPending => status == TaskAssignmentStatus.pending;
  bool get isAccepted => status == TaskAssignmentStatus.accepted;
  bool get isRejected => status == TaskAssignmentStatus.rejected;
  bool get isInProgress => status == TaskAssignmentStatus.inProgress;
  bool get isAwaitingApproval => status == TaskAssignmentStatus.completionRequested;
  bool get isApproved => status == TaskAssignmentStatus.approved;
}

/// Task Assignment History Model
class TaskAssignmentHistory {
  final String historyId;
  final String taskId;
  final String taskTitle;
  final String assigneeUserId;
  final String assigneeName;
  final String? previousAssigneeUserId;
  final String? previousAssigneeName;
  final String actionByUserId;
  final String actionByName;
  final String action; // Assigned, Accepted, Rejected, CompletionRequested, Approved, Unassigned
  final String? previousStatus;
  final String? newStatus;
  final String? note;
  final DateTime actionAt;

  TaskAssignmentHistory({
    required this.historyId,
    required this.taskId,
    required this.taskTitle,
    required this.assigneeUserId,
    required this.assigneeName,
    this.previousAssigneeUserId,
    this.previousAssigneeName,
    required this.actionByUserId,
    required this.actionByName,
    required this.action,
    this.previousStatus,
    this.newStatus,
    this.note,
    required this.actionAt,
  });

  factory TaskAssignmentHistory.fromJson(Map<String, dynamic> json) {
    return TaskAssignmentHistory(
      historyId: json['historyID'] ?? json['historyId'] ?? '',
      taskId: json['taskID'] ?? json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      assigneeUserId: json['assigneeUserID'] ?? json['assigneeUserId'] ?? '',
      assigneeName: json['assigneeName'] ?? '',
      previousAssigneeUserId: json['previousAssigneeUserID'] ?? json['previousAssigneeUserId'],
      previousAssigneeName: json['previousAssigneeName'],
      actionByUserId: json['actionByUserID'] ?? json['actionByUserId'] ?? '',
      actionByName: json['actionByName'] ?? '',
      action: json['action'] ?? '',
      previousStatus: json['previousStatus'],
      newStatus: json['newStatus'],
      note: json['note'],
      actionAt: DateTime.parse(json['actionAt']),
    );
  }
}

/// Productivity Dashboard Summary Model
class ProductivitySummary {
  final int totalAssigned;
  final int totalCompleted;
  final int totalPending;
  final int totalInProgress;
  final int totalAwaitingApproval;
  final int totalRejected;
  final double completionRate;
  final double avgCompletionDays;

  ProductivitySummary({
    required this.totalAssigned,
    required this.totalCompleted,
    required this.totalPending,
    required this.totalInProgress,
    required this.totalAwaitingApproval,
    required this.totalRejected,
    required this.completionRate,
    required this.avgCompletionDays,
  });

  factory ProductivitySummary.fromJson(Map<String, dynamic> json) {
    return ProductivitySummary(
      totalAssigned: json['totalAssigned'] ?? 0,
      totalCompleted: json['totalCompleted'] ?? 0,
      totalPending: json['totalPending'] ?? 0,
      totalInProgress: json['totalInProgress'] ?? 0,
      totalAwaitingApproval: json['totalAwaitingApproval'] ?? 0,
      totalRejected: json['totalRejected'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      avgCompletionDays: (json['avgCompletionDays'] ?? 0.0).toDouble(),
    );
  }
}

/// Task Priority Count Model
class TaskPriorityCount {
  final String priority;
  final int count;

  TaskPriorityCount({required this.priority, required this.count});

  factory TaskPriorityCount.fromJson(Map<String, dynamic> json) {
    return TaskPriorityCount(
      priority: json['priority'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

/// Recent Completed Task Model
class RecentCompletedTask {
  final String taskId;
  final String taskTitle;
  final String priority;
  final DateTime assignedAt;
  final DateTime completedAt;
  final double completionDays;

  RecentCompletedTask({
    required this.taskId,
    required this.taskTitle,
    required this.priority,
    required this.assignedAt,
    required this.completedAt,
    required this.completionDays,
  });

  factory RecentCompletedTask.fromJson(Map<String, dynamic> json) {
    return RecentCompletedTask(
      taskId: json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      priority: json['priority'] ?? '',
      assignedAt: DateTime.parse(json['assignedAt']),
      completedAt: DateTime.parse(json['completedAt']),
      completionDays: (json['completionDays'] ?? 0.0).toDouble(),
    );
  }
}

/// Completion Trend Model
class CompletionTrend {
  final DateTime date;
  final int count;

  CompletionTrend({required this.date, required this.count});

  factory CompletionTrend.fromJson(Map<String, dynamic> json) {
    return CompletionTrend(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

/// Personal Productivity Dashboard Model
class ProductivityDashboard {
  final ProductivitySummary summary;
  final List<TaskPriorityCount> tasksByPriority;
  final List<RecentCompletedTask> recentCompleted;
  final List<CompletionTrend> completionTrend;
  final DateTime startDate;
  final DateTime endDate;

  ProductivityDashboard({
    required this.summary,
    required this.tasksByPriority,
    required this.recentCompleted,
    required this.completionTrend,
    required this.startDate,
    required this.endDate,
  });

  factory ProductivityDashboard.fromJson(Map<String, dynamic> json) {
    return ProductivityDashboard(
      summary: ProductivitySummary.fromJson(json['summary'] ?? {}),
      tasksByPriority: (json['tasksByPriority'] as List?)
              ?.map((e) => TaskPriorityCount.fromJson(e))
              .toList() ??
          [],
      recentCompleted: (json['recentCompleted'] as List?)
              ?.map((e) => RecentCompletedTask.fromJson(e))
              .toList() ??
          [],
      completionTrend: (json['completionTrend'] as List?)
              ?.map((e) => CompletionTrend.fromJson(e))
              .toList() ??
          [],
      startDate: DateTime.parse(json['dateRange']['start']),
      endDate: DateTime.parse(json['dateRange']['end']),
    );
  }
}

/// Member Stats Model (for Workspace Productivity)
class MemberStats {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int totalAssigned;
  final int totalCompleted;
  final int totalPending;
  final int totalInProgress;
  final int totalAwaitingApproval;
  final double completionRate;

  MemberStats({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.totalPending,
    required this.totalInProgress,
    required this.totalAwaitingApproval,
    required this.completionRate,
  });

  factory MemberStats.fromJson(Map<String, dynamic> json) {
    return MemberStats(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      avatarUrl: json['avatarUrl'],
      totalAssigned: json['totalAssigned'] ?? 0,
      totalCompleted: json['totalCompleted'] ?? 0,
      totalPending: json['totalPending'] ?? 0,
      totalInProgress: json['totalInProgress'] ?? 0,
      totalAwaitingApproval: json['totalAwaitingApproval'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }
}

/// Overdue Task Model
class OverdueTask {
  final String taskId;
  final String title;
  final DateTime deadline;
  final double daysOverdue;
  final int assigneeCount;

  OverdueTask({
    required this.taskId,
    required this.title,
    required this.deadline,
    required this.daysOverdue,
    required this.assigneeCount,
  });

  factory OverdueTask.fromJson(Map<String, dynamic> json) {
    return OverdueTask(
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      deadline: DateTime.parse(json['deadline']),
      daysOverdue: (json['daysOverdue'] ?? 0.0).toDouble(),
      assigneeCount: json['assigneeCount'] ?? 0,
    );
  }
}

/// Leaderboard Entry Model
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int tasksCompleted;
  final double avgCompletionDays;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.tasksCompleted,
    required this.avgCompletionDays,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      avatarUrl: json['avatarUrl'],
      tasksCompleted: json['tasksCompleted'] ?? 0,
      avgCompletionDays: (json['avgCompletionDays'] ?? 0.0).toDouble(),
    );
  }
}

/// Workspace Productivity Dashboard Model
class WorkspaceProductivityDashboard {
  final ProductivitySummary summary;
  final List<TaskPriorityCount> tasksByPriority;
  final List<MemberStats> memberStats;
  final List<OverdueTask> overdueTasks;
  final List<LeaderboardEntry> leaderboard;
  final List<CompletionTrend> completionTrend;
  final DateTime startDate;
  final DateTime endDate;

  WorkspaceProductivityDashboard({
    required this.summary,
    required this.tasksByPriority,
    required this.memberStats,
    required this.overdueTasks,
    required this.leaderboard,
    required this.completionTrend,
    required this.startDate,
    required this.endDate,
  });

  factory WorkspaceProductivityDashboard.fromJson(Map<String, dynamic> json) {
    return WorkspaceProductivityDashboard(
      summary: ProductivitySummary.fromJson(json['summary'] ?? {}),
      tasksByPriority: (json['tasksByPriority'] as List?)
              ?.map((e) => TaskPriorityCount.fromJson(e))
              .toList() ??
          [],
      memberStats: (json['memberStats'] as List?)
              ?.map((e) => MemberStats.fromJson(e))
              .toList() ??
          [],
      overdueTasks: (json['overdueTasks'] as List?)
              ?.map((e) => OverdueTask.fromJson(e))
              .toList() ??
          [],
      leaderboard: (json['leaderboard'] as List?)
              ?.map((e) => LeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      completionTrend: (json['completionTrend'] as List?)
              ?.map((e) => CompletionTrend.fromJson(e))
              .toList() ??
          [],
      startDate: DateTime.parse(json['dateRange']['start']),
      endDate: DateTime.parse(json['dateRange']['end']),
    );
  }
}
