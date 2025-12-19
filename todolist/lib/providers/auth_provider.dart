import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/data/models/models.dart';
import '../main.dart'; // Import để lấy biến apiClient global nếu cần

// Auth State
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  failure // Thêm trạng thái lỗi rõ ràng
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  // Constructor mặc định cho trạng thái ban đầu
  const AuthState.initial() 
      : status = AuthStatus.initial, 
        user = null, 
        token = null, 
        errorMessage = null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AuthNotifier(this._apiClient, this._prefs)
      : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  // Check if user is authenticated on app start
  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); 

    print("🚀 [AuthNotifier] Bắt đầu check auth status...");
    // Không set loading ở đây để tránh nháy màn hình nếu check nhanh
    // state = state.copyWith(status: AuthStatus.loading); 

    try {
      final token = _prefs.getString('auth_token');
      print("🎫 [AuthNotifier] Token từ Prefs: $token");

      if (token == null || token.isEmpty) {
        print("⚠️ Token rỗng -> Unauthenticated");
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // 1. Set token vào Client trước
      await _apiClient.setToken(token);

      // 2. QUAN TRỌNG: Set Authenticated NGAY LẬP TỨC (Optimistic)
      // Để App thoát khỏi màn hình Splash và vào Dashboard ngay.
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: null, // User sẽ được fetch sau
      );
      print("✅ Set state -> Authenticated (Optimistic)");

      // 3. Gọi API fetch user info trong background
      // Nếu token hết hạn, Interceptor 401 sẽ bắt và gọi logout sau.
      _fetchUserInBackground();

    } catch (e, stack) {
      print("🔥 [AuthNotifier] Lỗi check auth: $e");
      print(stack);
      // Nếu lỗi file system/prefs -> coi như chưa login
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: "Lỗi khởi động: $e"
      );
    }
  }

  Future<void> _fetchUserInBackground() async {
    try {
      print("🔄 Đang fetch user info ngầm...");
      final user = await _apiClient.getCurrentUser();
      if (mounted) {
        state = state.copyWith(user: user);
        print("👤 Đã cập nhật user info: ${user.fullName}");
      }
    } catch (e) {
      print("⚠️ Fetch user info thất bại (có thể do mạng): $e");
      // Không logout ở đây. Để Interceptor lo việc đó nếu là lỗi 401.
      // Nếu chỉ là lỗi mạng, cho user dùng app offline (nếu có cache) hoặc retry.
    }
  }

  // Login with email/password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _apiClient.login(email, password);
      // Giả sử response trả về object LoginResponse có field token
      // Nếu response là Map thì sửa thành response['token']
      final token = response.token; 

      await _prefs.setString('auth_token', token);
      await _apiClient.setToken(token);

      // Khi login chủ động thì nên đợi lấy user info luôn cho chắc
      final user = await _apiClient.getCurrentUser();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );

      return true;
    } catch (e) {
      print("🔥 Login failed: $e");
      state = state.copyWith(
        status: AuthStatus.unauthenticated, // Hoặc failure để hiện lỗi trên UI
        errorMessage: _getReadableErrorMessage(e),
      );
      return false;
    }
  }

  String _getReadableErrorMessage(dynamic error) {
    // Helper để parse lỗi cho đẹp
    final msg = error.toString();
    if (msg.contains("401")) return "Sai email hoặc mật khẩu";
    if (msg.contains("SocketException")) return "Không có kết nối mạng";
    return "Đăng nhập thất bại: $msg";
  }

  // Logout
  Future<void> logout() async {
    print("👋 Đang đăng xuất...");
    await _clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _clearToken() async {
    await _prefs.remove('auth_token');
    await _apiClient.clearToken();
  }
}

// Providers (Giữ nguyên hoặc chỉnh sửa nhẹ)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  // Tốt nhất nên dùng biến global apiClient đã init ở main
  return apiClient; 
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client, prefs);
});

// Getter tiện ích
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});