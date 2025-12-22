import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todolist/data/models/models.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/main.dart';

// ==================== AI SUGGESTIONS STATE ====================

/// State class for AI Suggestions with additional metadata
class AiSuggestionsState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AiSuggestionsState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AiSuggestionsState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AiSuggestionsState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ==================== AI SUGGESTIONS NOTIFIER ====================

/// StateNotifier quản lý logic AI Suggestions
/// - Gọi API /api/tasks/suggested
/// - Xử lý loading/error states
/// - Cache kết quả và timestamp
class AiSuggestionsNotifier extends StateNotifier<AiSuggestionsState> {
  final ApiClient _apiClient;

  AiSuggestionsNotifier(this._apiClient) : super(const AiSuggestionsState()) {
    // Auto-load suggestions when initialized
    loadSuggestions();
  }

  /// Load AI suggested tasks from server
  Future<void> loadSuggestions() async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call API - Endpoint trả về tasks đã sorted by priorityScore DESC
      final response = await _apiClient.dio.get('/api/tasks/suggested');
      
      // Parse response
      final List<dynamic> data = response.data is List 
          ? response.data as List
          : (response.data as Map<String, dynamic>)['tasks'] ?? [];
      
      final tasks = data.map((json) => TaskModel.fromJson(json)).toList();

      // Update state with success
      state = AiSuggestionsState(
        tasks: tasks,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Update state with error
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh suggestions (pull-to-refresh)
  Future<void> refresh() async {
    await loadSuggestions();
  }
}

// ==================== PROVIDER ====================

/// Provider cho AI Suggestions
/// Sử dụng apiClient từ main.dart
final aiSuggestionsProvider = StateNotifierProvider<AiSuggestionsNotifier, AiSuggestionsState>((ref) {
  return AiSuggestionsNotifier(apiClient);
});
