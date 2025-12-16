import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'api_client.dart';

class OAuthService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Facebook Sign-In
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  /// Sign in with Google
  /// Returns: {success, token, isNewUser, user, errorMessage}
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // Check if running on web without proper configuration
    if (kIsWeb) {
      return {
        'success': false,
        'errorMessage': 'Google Sign-In chưa được cấu hình cho Web.\n'
            'Vui lòng thêm Google Client ID vào web/index.html:\n'
            '<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">'
      };
    }

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled
        return {'success': false, 'errorMessage': 'Đã hủy đăng nhập'};
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        return {'success': false, 'errorMessage': 'Không lấy được ID token từ Google'};
      }

      // Send to backend
      final response = await _apiClient.dio.post(
        '/api/auth/external-login',
        data: {
          'provider': 'google',
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'fullName': googleUser.displayName ?? googleUser.email,
          'avatarURL': googleUser.photoUrl ?? '',
        },
      );

      // Save token securely
      final token = response.data['token'];
      await _secureStorage.write(key: 'auth_token', value: token);

      return {
        'success': true,
        'token': token,
        'isNewUser': response.data['isNewUser'] ?? false,
        'user': response.data['user'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'errorMessage': e.response?.data['message'] ?? 'Lỗi kết nối server',
        };
      }
      return {'success': false, 'errorMessage': e.toString()};
    }
  }

  /// Sign in with Facebook
  /// Returns: {success, token, isNewUser, user, errorMessage}
  Future<Map<String, dynamic>> signInWithFacebook() async {
    // Check if running on web without proper configuration
    if (kIsWeb) {
      return {
        'success': false,
        'errorMessage': 'Facebook Sign-In chưa được cấu hình cho Web.\n'
            'Vui lòng thêm Facebook App ID vào web/index.html.'
      };
    }

    try {
      // Trigger Facebook Sign-In flow
      final LoginResult result = await _facebookAuth.login();
      
      if (result.status != LoginStatus.success) {
        return {
          'success': false,
          'errorMessage': result.status == LoginStatus.cancelled
              ? 'Đã hủy đăng nhập'
              : 'Lỗi đăng nhập Facebook: ${result.message}',
        };
      }

      // Get user data
      final userData = await _facebookAuth.getUserData();

      // Send to backend
      final response = await _apiClient.dio.post(
        '/api/auth/external-login',
        data: {
          'provider': 'facebook',
          'idToken': result.accessToken!.token,
          'email': userData['email'] ?? '',
          'fullName': userData['name'] ?? 'Facebook User',
          'avatarURL': userData['picture']?['data']?['url'] ?? '',
        },
      );

      // Save token securely
      final token = response.data['token'];
      await _secureStorage.write(key: 'auth_token', value: token);

      return {
        'success': true,
        'token': token,
        'isNewUser': response.data['isNewUser'] ?? false,
        'user': response.data['user'],
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'errorMessage': e.response?.data['message'] ?? 'Lỗi kết nối server',
        };
      }
      return {'success': false, 'errorMessage': e.toString()};
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  /// Sign out from Facebook
  Future<void> signOutFacebook() async {
    await _facebookAuth.logOut();
  }

  /// Sign out from all
  Future<void> signOut() async {
    await signOutGoogle();
    await signOutFacebook();
    await _secureStorage.delete(key: 'auth_token');
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
}
