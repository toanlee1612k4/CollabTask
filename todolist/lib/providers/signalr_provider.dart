import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/data/services/signalr_service.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/providers/auth_provider.dart';
import 'package:todolist/main.dart';

// ==================== SIGNALR STATE ====================

class SignalRState {
  final SignalRConnectionState connectionState;
  final List<NotificationModel> recentNotifications;
  final int unreadCount;
  final String? lastError;

  const SignalRState({
    this.connectionState = SignalRConnectionState.disconnected,
    this.recentNotifications = const [],
    this.unreadCount = 0,
    this.lastError,
  });

  SignalRState copyWith({
    SignalRConnectionState? connectionState,
    List<NotificationModel>? recentNotifications,
    int? unreadCount,
    String? lastError,
  }) {
    return SignalRState(
      connectionState: connectionState ?? this.connectionState,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      lastError: lastError,
    );
  }

  bool get isConnected => connectionState == SignalRConnectionState.connected;
  bool get isConnecting => connectionState == SignalRConnectionState.connecting;
  bool get isReconnecting => connectionState == SignalRConnectionState.reconnecting;
}

// ==================== SIGNALR NOTIFIER ====================

class SignalRNotifier extends StateNotifier<SignalRState> {
  final Ref _ref;
  final SignalRService _signalRService;
  
  StreamSubscription? _authSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _taskAssignedSubscription;
  StreamSubscription? _taskUpdatedSubscription;
  StreamSubscription? _commentReceivedSubscription;

  // Callbacks cho UI (SnackBar, Refresh, etc.)
  void Function(NotificationModel notification)? onNotificationReceived;
  void Function(TaskAssignedEvent event)? onTaskAssigned;
  void Function(TaskUpdatedEvent event)? onTaskUpdated;
  void Function(CommentReceivedEvent event)? onCommentReceived;

  SignalRNotifier(this._ref)
      : _signalRService = SignalRService(),
        super(const SignalRState()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      _handleAuthStateChange(previous, next);
    }).read() as StreamSubscription?;

    // Subscribe to SignalR events
    _subscribeToSignalREvents();

    // Check current auth state on init
    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && 
        authState.token != null && 
        authState.user != null) {
      _connect(authState.token!, authState.user!.userId);
    }
  }

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (next.status == AuthStatus.authenticated && 
        next.token != null && 
        next.user != null) {
      // User logged in -> Connect SignalR
      _connect(next.token!, next.user!.userId);
    } else if (next.status == AuthStatus.unauthenticated) {
      // User logged out -> Disconnect SignalR
      _disconnect();
    }
  }

  void _subscribeToSignalREvents() {
    // Connection state changes
    _connectionStateSubscription = _signalRService.onConnectionStateChanged.listen(
      (state) {
        this.state = this.state.copyWith(connectionState: state);
        
        if (state == SignalRConnectionState.error) {
          this.state = this.state.copyWith(
            lastError: 'Không thể kết nối real-time',
          );
        }
      },
    );

    // New notifications
    _notificationSubscription = _signalRService.onNotificationReceived.listen(
      (notification) {
        _addNotification(notification);
        onNotificationReceived?.call(notification);
      },
    );

    // Task assigned events
    _taskAssignedSubscription = _signalRService.onTaskAssigned.listen(
      (event) {
        // Create notification from event
        final notification = NotificationModel(
          notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '📋 Task mới được gán',
          message: '${event.assignedByName} đã gán task "${event.taskTitle}" cho bạn',
          type: 'task_assigned',
          isRead: false,
          createdAt: event.assignedAt,
          relatedTaskId: event.taskId,
          relatedWorkspaceId: event.workspaceId,
        );
        _addNotification(notification);
        onTaskAssigned?.call(event);
      },
    );

    // Task updated events
    _taskUpdatedSubscription = _signalRService.onTaskUpdated.listen(
      (event) {
        onTaskUpdated?.call(event);
      },
    );

    // Comment received events
    _commentReceivedSubscription = _signalRService.onCommentReceived.listen(
      (event) {
        // Create notification from event
        final notification = NotificationModel(
          notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '💬 Comment mới',
          message: '${event.authorName} đã comment trên task "${event.taskTitle}"',
          type: 'comment',
          isRead: false,
          createdAt: event.createdAt,
          relatedTaskId: event.taskId,
        );
        _addNotification(notification);
        onCommentReceived?.call(event);
      },
    );
  }

  void _addNotification(NotificationModel notification) {
    final updatedList = [notification, ...state.recentNotifications];
    // Keep only last 50 notifications in memory
    final trimmedList = updatedList.take(50).toList();
    
    state = state.copyWith(
      recentNotifications: trimmedList,
      unreadCount: state.unreadCount + (notification.isRead ? 0 : 1),
    );
  }

  Future<void> _connect(String token, String userId) async {
    if (state.isConnected || state.isConnecting) return;

    try {
      final hubUrl = '${apiClient.baseUrl}/notificationHub';
      
      if (kDebugMode) {
        print('📡 SignalR Provider: Connecting to $hubUrl');
      }

      await _signalRService.initConnection(
        hubUrl: hubUrl,
        token: token,
        userId: userId,
      );

      state = state.copyWith(
        connectionState: SignalRConnectionState.connected,
        lastError: null,
      );

    } catch (e) {
      state = state.copyWith(
        connectionState: SignalRConnectionState.error,
        lastError: 'Kết nối thất bại: $e',
      );
      if (kDebugMode) print('📡 SignalR Provider: Connection failed - $e');
    }
  }

  Future<void> _disconnect() async {
    await _signalRService.disconnect();
    state = state.copyWith(
      connectionState: SignalRConnectionState.disconnected,
      recentNotifications: [],
      unreadCount: 0,
    );
  }

  /// Manual reconnect
  Future<void> reconnect() async {
    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && 
        authState.token != null && 
        authState.user != null) {
      await _disconnect();
      await _connect(authState.token!, authState.user!.userId);
    }
  }

  /// Join workspace group (call when entering workspace)
  Future<void> joinWorkspace(String workspaceId) async {
    await _signalRService.joinWorkspaceGroup(workspaceId);
  }

  /// Leave workspace group (call when leaving workspace)
  Future<void> leaveWorkspace(String workspaceId) async {
    await _signalRService.leaveWorkspaceGroup(workspaceId);
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updatedList = state.recentNotifications.map((n) {
      return NotificationModel(
        notificationId: n.notificationId,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
        relatedTaskId: n.relatedTaskId,
        relatedWorkspaceId: n.relatedWorkspaceId,
      );
    }).toList();

    state = state.copyWith(
      recentNotifications: updatedList,
      unreadCount: 0,
    );
  }

  /// Clear recent notifications
  void clearNotifications() {
    state = state.copyWith(
      recentNotifications: [],
      unreadCount: 0,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _notificationSubscription?.cancel();
    _taskAssignedSubscription?.cancel();
    _taskUpdatedSubscription?.cancel();
    _commentReceivedSubscription?.cancel();
    _signalRService.dispose();
    super.dispose();
  }
}

// ==================== PROVIDER ====================

final signalRProvider = StateNotifierProvider<SignalRNotifier, SignalRState>((ref) {
  return SignalRNotifier(ref);
});

// ==================== HELPER PROVIDERS ====================

/// Provider for connection status only
final signalRConnectionProvider = Provider<SignalRConnectionState>((ref) {
  return ref.watch(signalRProvider).connectionState;
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(signalRProvider).unreadCount;
});

/// Provider for recent notifications list
final recentNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(signalRProvider).recentNotifications;
});
