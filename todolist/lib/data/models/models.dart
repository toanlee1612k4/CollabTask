import 'package:flutter/foundation.dart';

// Paginated Result wrapper
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : totalPages = (totalCount / pageSize).ceil();

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

// Task Model - Map với TaskDto.cs từ Backend
class TaskModel {
  final String taskId;
  final String title;
  final String? description;
  final String status; // "ToDo", "InProgress", "Completed", "Overdue"
  final String priority; // "High", "Medium", "Low"
  final DateTime? deadline;
  final int? estimatedTimeMinutes;
  final double priorityScore; // Điểm gợi ý từ AI (Quan trọng)
  final String? aiReason; // Lý do AI gợi ý (NEW)
  final String? workspaceId;
  final List<String> assigneeUserIds; // Changed from assigneeId to match API response
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt; // Thời điểm hoàn thành task

  TaskModel({
    required this.taskId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.deadline,
    this.estimatedTimeMinutes,
    required this.priorityScore,
    this.aiReason,
    this.workspaceId,
    List<String>? assigneeUserIds,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  }) : assigneeUserIds = assigneeUserIds ?? [];

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'ToDo',
      priority: json['priority'] ?? 'Medium',
      // Convert UTC to local time when receiving from API
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']).toLocal() : null,
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
      priorityScore: (json['priorityScore'] ?? 0.0).toDouble(),
      aiReason: json['aiReason']?.toString() ?? json['reason']?.toString(), // NEW
      workspaceId: json['workspaceId']?.toString(),
      assigneeUserIds: (json['assigneeUserIds'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList(),
      // Convert UTC to local time when receiving from API
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']).toLocal() : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      // Convert local time to UTC when sending to API
      'deadline': deadline?.toUtc().toIso8601String(),
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'priorityScore': priorityScore,
      'workspaceId': workspaceId,
      'assigneeUserIds': assigneeUserIds,
      // Convert local time to UTC when sending to API
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
    };
  }

  // Helper methods
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && status != 'Completed';
  }

  bool get isHighPriority => priorityScore >= 8.0;

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return priority;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'todo':
        return 'Chưa làm';
      case 'inprogress':
        return 'Đang làm';
      case 'completed':
        return 'Hoàn thành';
      case 'overdue':
        return 'Quá hạn';
      default:
        return status;
    }
  }
}

// UserWeights Model - Map với response của UserWeightsController.cs
class UserWeights {
  final double deadlineWeight;
  final double importanceWeight;
  final double effortWeight;
  final DateTime lastUpdated;
  final String message;

  UserWeights({
    required this.deadlineWeight,
    required this.importanceWeight,
    required this.effortWeight,
    required this.lastUpdated,
    required this.message,
  });

  factory UserWeights.fromJson(Map<String, dynamic> json) {
    return UserWeights(
      deadlineWeight: (json['deadlineWeight'] ?? 0.0).toDouble(),
      importanceWeight: (json['importanceWeight'] ?? 0.0).toDouble(),
      effortWeight: (json['effortWeight'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deadlineWeight': deadlineWeight,
      'importanceWeight': importanceWeight,
      'effortWeight': effortWeight,
      'lastUpdated': lastUpdated.toIso8601String(),
      'message': message,
    };
  }

  // Helper methods
  double get totalWeight => deadlineWeight + importanceWeight + effortWeight;
  
  double get deadlinePercentage => totalWeight > 0 ? (deadlineWeight / totalWeight) * 100 : 0;
  double get importancePercentage => totalWeight > 0 ? (importanceWeight / totalWeight) * 100 : 0;
  double get effortPercentage => totalWeight > 0 ? (effortWeight / totalWeight) * 100 : 0;
}

// User Model
class UserModel {
  final String userId;
  final String email;
  final String? fullName;
  final String? avatar;
  final DateTime? createdAt;
  final String? roleName; // Role in workspace (Owner, ProjectManager, Member)

  UserModel({
    required this.userId,
    required this.email,
    this.fullName,
    this.avatar,
    this.createdAt,
    this.roleName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      avatar: json['avatar'],
      // Convert UTC to local time
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : null,
      roleName: json['roleName'] ?? json['role'], // Support both field names
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

// Workspace Model
class WorkspaceModel {
  final String workspaceId;
  final String name;
  final String? description;
  final String ownerId;
  final List<UserModel> members;
  final int? memberCount; // Added for workspace list display
  final DateTime? createdAt;

  WorkspaceModel({
    required this.workspaceId,
    required this.name,
    this.description,
    required this.ownerId,
    this.members = const [],
    this.memberCount,
    this.createdAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    // Try different possible field names (backend might use different casing)
    final workspaceId = json['workspaceId']?.toString() ?? 
                       json['workspaceID']?.toString() ?? 
                       json['WorkspaceId']?.toString() ?? 
                       json['WorkspaceID']?.toString() ?? 
                       json['id']?.toString() ?? '';
    
    // Debug log if workspaceId is empty
    if (kDebugMode && workspaceId.isEmpty) {
      print('⚠️ WARNING: WorkspaceModel.fromJson received empty workspaceId!');
      print('📥 JSON data: $json');
    }
    
    final membersList = json['members'] != null 
        ? (json['members'] as List).map((m) => UserModel.fromJson(m)).toList()
        : <UserModel>[];
    
    return WorkspaceModel(
      workspaceId: workspaceId,
      name: json['name'] ?? json['workspaceName'] ?? '',
      description: json['description'],
      ownerId: json['ownerId']?.toString() ?? json['ownerUserID']?.toString() ?? '',
      members: membersList,
      memberCount: json['memberCount'] ?? membersList.length,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

// Notification Model
class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedTaskId;
  final String? relatedWorkspaceId;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedTaskId,
    this.relatedWorkspaceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      relatedTaskId: json['relatedTaskId']?.toString(),
      relatedWorkspaceId: json['relatedWorkspaceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'relatedTaskId': relatedTaskId,
      'relatedWorkspaceId': relatedWorkspaceId,
    };
  }
}

// Comment Model
class CommentModel {
  final String commentId;
  final String content;
  final String authorId;
  final String authorName;
  final String taskId;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.taskId,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName'] ?? 'Unknown',
      taskId: json['taskId']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'taskId': taskId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// API Response Models
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}

class LoginResponse {
  final String token;
  final UserModel user;
  final DateTime expiresAt;

  LoginResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : DateTime.now().add(const Duration(days: 7)),
    );
  }
}

// Project Model
class Project {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? deadline; // Added for compatibility
  final int progress;
  final Member? leader; // Added for compatibility
  final List<Member> members;
  final List<TaskItem> tasks;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.deadline,
    required this.progress,
    this.leader,
    this.members = const [],
    this.tasks = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      progress: json['progress'] ?? 0,
      leader: json['leader'] != null ? Member.fromJson(json['leader']) : null,
      members: json['members'] != null 
          ? (json['members'] as List).map((m) => Member.fromJson(m)).toList()
          : [],
      tasks: json['tasks'] != null 
          ? (json['tasks'] as List).map((t) => TaskItem.fromJson(t)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'progress': progress,
      'leader': leader?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }
}

// Member Model
class Member {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  Member({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
    };
  }
}

// TaskItem Model - cho Project Dashboard
class TaskItem {
  final String id;
  final String title;
  final String? description;
  String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime? deadline; // Added for compatibility
  final String? assigneeId;
  final String? assigneeName;
  final Member? assignee; // Added for compatibility
  int progress; // Added for compatibility
  final List<String>? attachments; // Added for compatibility

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.deadline,
    this.assigneeId,
    this.assigneeName,
    this.assignee,
    this.progress = 0,
    this.attachments,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      assigneeId: json['assigneeId']?.toString(),
      assigneeName: json['assigneeName'],
      assignee: json['assignee'] != null ? Member.fromJson(json['assignee']) : null,
      progress: json['progress'] ?? 0,
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assignee': assignee?.toJson(),
      'progress': progress,
      'attachments': attachments,
    };
  }
}

/// Task Attachment Model
class TaskAttachment {
  final String attachmentID;
  final String taskID;
  final String uploadedByUserID;
  final String uploadedByName;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String downloadUrl;

  TaskAttachment({
    required this.attachmentID,
    required this.taskID,
    required this.uploadedByUserID,
    required this.uploadedByName,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.downloadUrl,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      attachmentID: json['attachmentID']?.toString() ?? '',
      taskID: json['taskID']?.toString() ?? '',
      uploadedByUserID: json['uploadedByUserID']?.toString() ?? '',
      uploadedByName: json['uploadedByName'] ?? 'Unknown',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? 'application/octet-stream',
      fileSize: json['fileSize'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt']),
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachmentID': attachmentID,
      'taskID': taskID,
      'uploadedByUserID': uploadedByUserID,
      'uploadedByName': uploadedByName,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'downloadUrl': downloadUrl,
    };
  }
}
