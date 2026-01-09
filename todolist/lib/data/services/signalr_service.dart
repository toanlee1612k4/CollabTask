import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:signalr_netcore/signalr_client.dart';
import 'package:todolist/data/models/models.dart';

/// SignalR Service - Real-time notifications
/// Kết nối tới Backend Hub: /notificationHub
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  bool _isConnected = false;
  String? _currentUserId;
  
  // Stream Controllers cho các events
  final _notificationController = StreamController<NotificationModel>.broadcast();
  final _taskAssignedController = StreamController<TaskAssignedEvent>.broadcast();
  final _taskUpdatedController = StreamController<TaskUpdatedEvent>.broadcast();
  final _commentReceivedController = StreamController<CommentReceivedEvent>.broadcast();
  final _connectionStateController = StreamController<SignalRConnectionState>.broadcast();

  // Public Streams
  Stream<NotificationModel> get onNotificationReceived => _notificationController.stream;
  Stream<TaskAssignedEvent> get onTaskAssigned => _taskAssignedController.stream;
  Stream<TaskUpdatedEvent> get onTaskUpdated => _taskUpdatedController.stream;
  Stream<CommentReceivedEvent> get onCommentReceived => _commentReceivedController.stream;
  Stream<SignalRConnectionState> get onConnectionStateChanged => _connectionStateController.stream;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  /// Initialize và kết nối SignalR Hub
  Future<void> initConnection({
    required String hubUrl,
    required String token,
    required String userId,
  }) async {
    if (_isConnected && _currentUserId == userId) {
      if (kDebugMode) print('📡 SignalR: Already connected for user $userId');
      return;
    }

    // Disconnect nếu đang kết nối với user khác
    if (_isConnected) {
      await disconnect();
    }

    _currentUserId = userId;
    
    try {
      _connectionStateController.add(SignalRConnectionState.connecting);

      // Build hub connection với Auto Reconnect
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              logging: (level, message) {
                if (kDebugMode) print('📡 SignalR [$level]: $message');
              },
            ),
          )
          .withAutomaticReconnect(retryDelays: [
            0,      // Reconnect ngay lập tức
            2000,   // Sau 2 giây
            5000,   // Sau 5 giây
            10000,  // Sau 10 giây
            30000,  // Sau 30 giây
          ])
          .build();

      // Register event handlers
      _registerEventHandlers();
      
      // Register connection lifecycle handlers
      _hubConnection!.onclose(({Exception? error}) {
        _isConnected = false;
        _connectionStateController.add(SignalRConnectionState.disconnected);
        if (kDebugMode) print('📡 SignalR: Connection closed. Error: $error');
      });

      _hubConnection!.onreconnecting(({Exception? error}) {
        _isConnected = false;
        _connectionStateController.add(SignalRConnectionState.reconnecting);
        if (kDebugMode) print('📡 SignalR: Reconnecting... Error: $error');
      });

      _hubConnection!.onreconnected(({String? connectionId}) {
        _isConnected = true;
        _connectionStateController.add(SignalRConnectionState.connected);
        if (kDebugMode) print('📡 SignalR: Reconnected! ConnectionId: $connectionId');
        
        // Re-join user group sau khi reconnect
        _joinUserGroup(userId);
      });

      // Start connection
      await _hubConnection!.start();
      _isConnected = true;
      _connectionStateController.add(SignalRConnectionState.connected);

      // Join user-specific group
      await _joinUserGroup(userId);

      if (kDebugMode) {
        print('📡 SignalR: Connected successfully for user $userId');
        print('📡 SignalR: Hub URL: $hubUrl');
      }

    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(SignalRConnectionState.error);
      if (kDebugMode) print('📡 SignalR: Connection failed - $e');
      rethrow;
    }
  }

  /// Register all SignalR event handlers
  void _registerEventHandlers() {
    if (_hubConnection == null) return;

    // === EVENT: ReceiveNotification ===
    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      
      try {
        final data = arguments[0] as Map<String, dynamic>;
        final notification = NotificationModel.fromJson(data);
        _notificationController.add(notification);
        
        if (kDebugMode) {
          print('📬 Received Notification: ${notification.title}');
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing ReceiveNotification: $e');
      }
    });

    // === EVENT: TaskAssigned ===
    _hubConnection!.on('TaskAssigned', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      
      try {
        final data = arguments[0] as Map<String, dynamic>;
        final event = TaskAssignedEvent.fromJson(data);
        _taskAssignedController.add(event);
        
        if (kDebugMode) {
          print('📋 Task Assigned: ${event.taskTitle} by ${event.assignedBy}');
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing TaskAssigned: $e');
      }
    });

    // === EVENT: TaskUpdated ===
    _hubConnection!.on('TaskUpdated', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      
      try {
        final data = arguments[0] as Map<String, dynamic>;
        final event = TaskUpdatedEvent.fromJson(data);
        _taskUpdatedController.add(event);
        
        if (kDebugMode) {
          print('🔄 Task Updated: ${event.taskId} - ${event.updateType}');
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing TaskUpdated: $e');
      }
    });

    // === EVENT: CommentReceived ===
    _hubConnection!.on('CommentReceived', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      
      try {
        final data = arguments[0] as Map<String, dynamic>;
        final event = CommentReceivedEvent.fromJson(data);
        _commentReceivedController.add(event);
        
        if (kDebugMode) {
          print('💬 Comment Received on task ${event.taskId} by ${event.authorName}');
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing CommentReceived: $e');
      }
    });

    // === EVENT: WorkspaceUpdated ===
    _hubConnection!.on('WorkspaceUpdated', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      
      if (kDebugMode) {
        print('🏢 Workspace Updated: $arguments');
      }
    });
  }

  /// Join user-specific group to receive personal notifications
  Future<void> _joinUserGroup(String userId) async {
    try {
      await _hubConnection?.invoke('JoinUserGroup', args: [userId]);
      if (kDebugMode) print('📡 SignalR: Joined user group: $userId');
    } catch (e) {
      if (kDebugMode) print('❌ SignalR: Failed to join user group - $e');
    }
  }

  /// Join workspace group to receive workspace notifications
  Future<void> joinWorkspaceGroup(String workspaceId) async {
    if (!_isConnected) return;
    
    try {
      await _hubConnection?.invoke('JoinWorkspaceGroup', args: [workspaceId]);
      if (kDebugMode) print('📡 SignalR: Joined workspace group: $workspaceId');
    } catch (e) {
      if (kDebugMode) print('❌ SignalR: Failed to join workspace group - $e');
    }
  }

  /// Leave workspace group
  Future<void> leaveWorkspaceGroup(String workspaceId) async {
    if (!_isConnected) return;
    
    try {
      await _hubConnection?.invoke('LeaveWorkspaceGroup', args: [workspaceId]);
      if (kDebugMode) print('📡 SignalR: Left workspace group: $workspaceId');
    } catch (e) {
      if (kDebugMode) print('❌ SignalR: Failed to leave workspace group - $e');
    }
  }

  /// Disconnect from SignalR Hub
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      // Leave user group trước khi disconnect
      if (_currentUserId != null) {
        await _hubConnection?.invoke('LeaveUserGroup', args: [_currentUserId]);
      }

      await _hubConnection?.stop();
      _isConnected = false;
      _currentUserId = null;
      _connectionStateController.add(SignalRConnectionState.disconnected);
      
      if (kDebugMode) print('📡 SignalR: Disconnected');
    } catch (e) {
      if (kDebugMode) print('❌ SignalR: Error during disconnect - $e');
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _taskAssignedController.close();
    _taskUpdatedController.close();
    _commentReceivedController.close();
    _connectionStateController.close();
  }
}

// ==================== SIGNALR EVENTS ====================

/// Connection state enum
enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Event khi được gán task mới
class TaskAssignedEvent {
  final String taskId;
  final String taskTitle;
  final String workspaceId;
  final String workspaceName;
  final String assignedBy;
  final String assignedByName;
  final DateTime assignedAt;
  final String? priority;
  final DateTime? deadline;

  TaskAssignedEvent({
    required this.taskId,
    required this.taskTitle,
    required this.workspaceId,
    required this.workspaceName,
    required this.assignedBy,
    required this.assignedByName,
    required this.assignedAt,
    this.priority,
    this.deadline,
  });

  factory TaskAssignedEvent.fromJson(Map<String, dynamic> json) {
    return TaskAssignedEvent(
      taskId: json['taskId']?.toString() ?? '',
      taskTitle: json['taskTitle'] ?? '',
      workspaceId: json['workspaceId']?.toString() ?? '',
      workspaceName: json['workspaceName'] ?? '',
      assignedBy: json['assignedBy']?.toString() ?? '',
      assignedByName: json['assignedByName'] ?? '',
      assignedAt: json['assignedAt'] != null 
          ? DateTime.parse(json['assignedAt']).toLocal()
          : DateTime.now(),
      priority: json['priority'],
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']).toLocal() 
          : null,
    );
  }
}

/// Event khi task được cập nhật
class TaskUpdatedEvent {
  final String taskId;
  final String updateType; // "status_changed", "priority_changed", "deadline_changed"
  final String updatedBy;
  final String updatedByName;
  final DateTime updatedAt;
  final Map<String, dynamic>? changes;

  TaskUpdatedEvent({
    required this.taskId,
    required this.updateType,
    required this.updatedBy,
    required this.updatedByName,
    required this.updatedAt,
    this.changes,
  });

  factory TaskUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return TaskUpdatedEvent(
      taskId: json['taskId']?.toString() ?? '',
      updateType: json['updateType'] ?? 'unknown',
      updatedBy: json['updatedBy']?.toString() ?? '',
      updatedByName: json['updatedByName'] ?? '',
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']).toLocal()
          : DateTime.now(),
      changes: json['changes'] as Map<String, dynamic>?,
    );
  }
}

/// Event khi có comment mới
class CommentReceivedEvent {
  final String commentId;
  final String taskId;
  final String taskTitle;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  CommentReceivedEvent({
    required this.commentId,
    required this.taskId,
    required this.taskTitle,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory CommentReceivedEvent.fromJson(Map<String, dynamic> json) {
    return CommentReceivedEvent(
      commentId: json['commentId']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      taskTitle: json['taskTitle'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }
}
