import 'package:dio/dio.dart';
import 'dart:async';

/// SignalR-like real-time service using polling and WebSocket simulation
/// For production, use signalr_netcore package
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  final Dio _dio = Dio();
  Timer? _pollingTimer;
  final _commentController = StreamController<CommentNotification>.broadcast();
  final _taskUpdateController = StreamController<TaskUpdateNotification>.broadcast();
  
  bool _isConnected = false;
  String? _userId;
  String? _baseUrl;

  Stream<CommentNotification> get onCommentReceived => _commentController.stream;
  Stream<TaskUpdateNotification> get onTaskUpdated => _taskUpdateController.stream;

  bool get isConnected => _isConnected;

  /// Initialize SignalR connection
  Future<void> connect({
    required String baseUrl,
    required String userId,
    required String token,
  }) async {
    if (_isConnected) return;

    _baseUrl = baseUrl;
    _userId = userId;
    
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Authorization'] = 'Bearer $token';

    // Start polling for updates every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollForUpdates();
    });

    _isConnected = true;
    print('📡 SignalR connected for user: $userId');
  }

  /// Poll server for new updates
  Future<void> _pollForUpdates() async {
    if (!_isConnected || _baseUrl == null) return;

    try {
      // Poll for new comments
      final commentsResponse = await _dio.get(
        '/api/notifications/comments/new',
        queryParameters: {'userId': _userId},
      );

      if (commentsResponse.data is List) {
        for (var commentData in commentsResponse.data) {
          final notification = CommentNotification.fromJson(commentData);
          _commentController.add(notification);
        }
      }

      // Poll for task updates
      final tasksResponse = await _dio.get(
        '/api/notifications/tasks/new',
        queryParameters: {'userId': _userId},
      );

      if (tasksResponse.data is List) {
        for (var taskData in tasksResponse.data) {
          final notification = TaskUpdateNotification.fromJson(taskData);
          _taskUpdateController.add(notification);
        }
      }
    } catch (e) {
      print('⚠️ SignalR polling error: $e');
    }
  }

  /// Send comment notification to other users
  Future<void> sendCommentNotification({
    required String taskId,
    required String commentId,
    required String commentText,
    required String authorName,
  }) async {
    if (!_isConnected) return;

    try {
      await _dio.post('/api/notifications/comments/send', data: {
        'taskId': taskId,
        'commentId': commentId,
        'commentText': commentText,
        'authorName': authorName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Failed to send comment notification: $e');
    }
  }

  /// Send task update notification
  Future<void> sendTaskUpdateNotification({
    required String taskId,
    required String updateType,
    required String updatedBy,
  }) async {
    if (!_isConnected) return;

    try {
      await _dio.post('/api/notifications/tasks/send', data: {
        'taskId': taskId,
        'updateType': updateType,
        'updatedBy': updatedBy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Failed to send task update notification: $e');
    }
  }

  /// Disconnect from SignalR
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _isConnected = false;
    print('📡 SignalR disconnected');
  }

  void dispose() {
    _pollingTimer?.cancel();
    _commentController.close();
    _taskUpdateController.close();
  }
}

/// Comment notification model
class CommentNotification {
  final String taskId;
  final String commentId;
  final String commentText;
  final String authorName;
  final DateTime timestamp;

  CommentNotification({
    required this.taskId,
    required this.commentId,
    required this.commentText,
    required this.authorName,
    required this.timestamp,
  });

  factory CommentNotification.fromJson(Map<String, dynamic> json) {
    return CommentNotification(
      taskId: json['taskId'] as String,
      commentId: json['commentId'] as String,
      commentText: json['commentText'] as String,
      authorName: json['authorName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Task update notification model
class TaskUpdateNotification {
  final String taskId;
  final String updateType;
  final String updatedBy;
  final DateTime timestamp;

  TaskUpdateNotification({
    required this.taskId,
    required this.updateType,
    required this.updatedBy,
    required this.timestamp,
  });

  factory TaskUpdateNotification.fromJson(Map<String, dynamic> json) {
    return TaskUpdateNotification(
      taskId: json['taskId'] as String,
      updateType: json['updateType'] as String,
      updatedBy: json['updatedBy'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
